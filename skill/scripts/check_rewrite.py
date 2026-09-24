#!/usr/bin/env python3
"""Rosetta Prompt eval checker.

Checks one rewritten prompt against the success criteria in reference/rewrite-evals.md.
Code checks run first; the Sonnet 5 judge runs only if they pass. Verdicts use the
harness L1 verdict format. Stdlib only, so /usr/bin/python3 can run it from the app.

  check_rewrite.py check --target opus --original O.txt --rewrite R.txt [--context C.txt] [--no-judge]
  check_rewrite.py replay                 run evals/cases through the code checks (L5 gate)
  check_rewrite.py calibrate [--runs 3]   score the judge on evals/calibration, write a report
  check_rewrite.py status                 say whether the judge is armed
  check_rewrite.py save-case --target ... --original ... --rewrite ... --expected Rejected --why "..."

check exit codes: 0 approved, 1 rejected, 2 usage or input error.
"""

import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(SKILL_DIR, "reference", "rewrite-evals.md")
EVALS_DIR = os.path.join(SKILL_DIR, "evals")
CASES_DIR = os.path.join(EVALS_DIR, "cases")
CALIB_DIR = os.path.join(EVALS_DIR, "calibration")
REPORTS_DIR = os.path.join(EVALS_DIR, "reports")

TARGET_LABELS = {
    "fable": "Claude Fable 5.1", "opus": "Claude Opus 5.5", "sonnet": "Claude Sonnet 5",
    "haiku": "Claude Haiku 4.5", "sol": "GPT-6 Sol",
    "luna": "GPT-6 Luna", "astra": "GPT-6 Astra",
}

DEFAULT_LIMITS = {
    "short_words": "60", "overbuilt_words": "350", "dropped_min_words": "150",
    "dropped_ratio": "0.2", "max_attempts": "3", "judge_model": "sonnet",
    "judge_effort": "low", "armed_min_cases": "20", "armed_min_rate": "0.9", "armed_runs": "3",
}

DEFAULT_JUDGE = [
    ("intent_kept", "Does the rewrite ask for the same task, deliverable and audience as the original, without narrowing, widening or swapping what is being asked?"),
    ("constraints_kept", "Does the rewrite keep every explicit requirement, constraint, prohibition and preference stated in the original?"),
    ("nothing_invented", "Is every specific in the rewrite (names, numbers, dates, files, tools, facts, decisions) present in the original or the established context, or plainly framed as an assumption or a question for the reader?"),
    ("success_defined", "Does the rewrite make clear what a finished, successful response looks like (the deliverable, plus its format, length or done condition) to the degree this task needs?"),
    ("proportionate", "Is the amount of structure (tags, role, examples, sections) proportionate to the task, with no technique added only for show?"),
    ("uncertainty_allowed", "If the task asks for facts, research, analysis of material or advice, does the rewrite let the model say it lacks the information and ask it to ground claims in the given material or sources?"),
    ("format_fixed", "If the output must follow a fixed or repeatable shape, does the rewrite define that shape precisely, with a template or an example?"),
    ("no_needless_secrets", "Does the rewrite avoid adding credentials, keys or private personal details the task doesn't need, and if the original asks to keep something from end users, does it keep that instruction in one plain line rather than elaborate leak-proofing?"),
]

REQUEST_TAGS = ["messy_prompt", "prompting_guidance", "house_style", "established_context",
                "suggested_effort", "target_model", "previous_attempt_feedback"]


# ---------------------------------------------------------------- spec file

def load_tables():
    """Parse ```rubric fences in the spec. Same format as model-selection.md."""
    tables = {}
    try:
        with open(SPEC_PATH, encoding="utf-8") as fh:
            lines = fh.read().split("\n")
    except OSError:
        return tables
    in_fence, current = False, None
    for raw in lines:
        line = raw.strip()
        if not in_fence:
            if line.startswith("```rubric"):
                in_fence, current = True, None
            continue
        if line.startswith("```"):
            in_fence, current = False, None
            continue
        if line.startswith("@table "):
            current = line[len("@table "):].strip()
            tables[current] = []
            continue
        if current is None or not line or line.startswith("#"):
            continue
        cut = min([i for i in (line.find("|"), line.find("=")) if i >= 0], default=-1)
        if cut >= 0:
            tables[current].append((line[:cut].strip(), line[cut + 1:].strip()))
    return tables


TABLES = load_tables()


def limit(key):
    rows = dict(TABLES.get("limits", []))
    return rows.get(key) or DEFAULT_LIMITS[key]


def judge_questions():
    return TABLES.get("judge") or DEFAULT_JUDGE


def judge_fingerprint():
    blob = json.dumps({"q": judge_questions(), "model": limit("judge_model"),
                       "effort": limit("judge_effort")}, sort_keys=True)
    return hashlib.sha256(blob.encode()).hexdigest()[:16]


# ---------------------------------------------------------------- helpers

def words(text):
    return re.findall(r"[A-Za-z0-9']+", text)


def finding(rule, text, fix_hint, span=None):
    return {"rule": rule, "span": span, "text": text[:200], "fix_hint": fix_hint}


def verdict(eval_id, findings, kind, attempt, judge_model=None, runs=1, blocking=True):
    return {
        "eval_id": eval_id,
        "eval_version": f"{eval_id}.v1",
        "attempt": attempt,
        "verdict": "Rejected" if findings else "Approved",
        "reason": "; ".join(f["rule"] for f in findings) if findings else "All checks passed.",
        "findings": findings,
        "kind": kind,
        "judge_model": judge_model,
        "runs": runs,
        "blocking": blocking,
    }


# ---------------------------------------------------------------- code checks

# U+2013 en dash and U+2014 em dash.
LONG_DASH_RE = re.compile("[\\u2013\\u2014]")
PREAMBLE = re.compile(r"^\s*(here('s| is| are)\b|sure\b|certainly\b|of course\b|below is\b|okay\b|"
                      r"rewritten prompt\b|the rewritten prompt\b|i('ve| have) rewritten\b)", re.I)
TRAILING = re.compile(r"^\s*(note:|notes:|changes made|what i changed|i('ve| have) (added|kept|removed|changed)|"
                      r"this rewrite\b|let me know\b)", re.I)
PLACEHOLDER = re.compile(r"\[[A-Z][A-Z0-9 _/\-]{2,}\]|\bTBD\b|\bTODO\b|<insert[^>]*>|\{\{[^}]+\}\}")
OPUS_VERIFY = re.compile(r"double[- ]check|re-?verify|verification step|verify your (answer|work|output)|"
                         r"subagent to (verify|double)", re.I)
REVIEW_FILTER = re.compile(r"only report (high|critical)[- ]severity|\bbe conservative\b|don'?t nitpick", re.I)
HAIKU_EFFORT = re.compile(r"--effort\b|\beffort\b[^.\n]{0,40}\b(low|medium|high|xhigh|max)\b|"
                          r"\b(low|medium|high|xhigh|max)\b[- ]effort\b", re.I)
ANTIFORMAT = re.compile(r"(do not|don'?t|never|avoid)( use)? (any )?(markdown|bullet|lists|headers|headings|bold)", re.I)
FIGURE = re.compile("(?<![\\w.])(?:[$\\u20ac\\u00a3]\\s?\\d[\\d.,]*|\\d[\\d.,]*\\s?%|\\d{2,}(?:[.,]\\d+)*)")


def code_checks(target, original, rewrite, context):
    blocking, advisory = [], []
    source = original + "\n" + context
    text = rewrite.strip()

    if not text:
        blocking.append(finding("output.empty", "", "Return the rewritten prompt."))
        return blocking, advisory

    m = LONG_DASH_RE.search(rewrite)
    if m:
        blocking.append(finding("punct.long_dash", rewrite[max(0, m.start() - 30):m.end() + 30],
                                "Replace with a comma, colon or full stop, or recast the sentence.",
                                [m.start(), m.end()]))

    if text.startswith("```") and text.endswith("```"):
        blocking.append(finding("output.fence_wrapper", text[:40], "Return the prompt without a code fence around it."))

    first_line = text.split("\n", 1)[0]
    if PREAMBLE.search(first_line):
        blocking.append(finding("output.preamble", first_line, "Start with the prompt itself, no lead-in."))

    last_para = re.split(r"\n\s*\n", text)[-1]
    if TRAILING.search(last_para) and not TRAILING.search(original):
        blocking.append(finding("output.trailing_note", last_para, "Drop commentary about the rewrite."))

    for tag in REQUEST_TAGS:
        if re.search(rf"</?{tag}\b", rewrite) and not re.search(rf"</?{tag}\b", source):
            blocking.append(finding("output.leaked_tag", f"<{tag}>", "Remove tags from the rewrite request."))
            break

    for m in PLACEHOLDER.finditer(rewrite):
        token = m.group(0)
        if token.lower() in source.lower():
            continue
        blocking.append(finding("grounding.placeholder", token,
                                "Fill it from the original or context, or state it as an explicit assumption or question.",
                                [m.start(), m.end()]))
        break

    n_orig, n_new = len(words(original)), len(words(rewrite))
    if n_orig <= int(limit("short_words")) and n_new > int(limit("overbuilt_words")):
        blocking.append(finding("length.overbuilt", f"{n_orig} words in, {n_new} out",
                                "A short ask needs a short, clear prompt. Cut structure the task doesn't need."))
    if n_orig >= int(limit("dropped_min_words")) and n_new < float(limit("dropped_ratio")) * n_orig:
        blocking.append(finding("length.dropped", f"{n_orig} words in, {n_new} out",
                                "Content was likely dropped. Keep every requirement from the original."))

    if target == "opus":
        m = OPUS_VERIFY.search(rewrite)
        if m:
            blocking.append(finding("target.opus5_verify", m.group(0),
                                    "Opus 5.5 already verifies its work. Remove the verification instruction.",
                                    [m.start(), m.end()]))
    if target in ("opus", "sonnet"):
        m = REVIEW_FILTER.search(rewrite)
        if m:
            blocking.append(finding("target.review_filter", m.group(0),
                                    "Ask it to report every issue with confidence and severity, or give a concrete bar.",
                                    [m.start(), m.end()]))
    if target == "haiku":
        m = HAIKU_EFFORT.search(rewrite)
        if m:
            blocking.append(finding("target.haiku_effort", m.group(0),
                                    "Haiku 4.5 has no effort setting. Remove the effort line.",
                                    [m.start(), m.end()]))
    if target == "fable":
        m = ANTIFORMAT.search(rewrite)
        if m and not ANTIFORMAT.search(source):
            blocking.append(finding("target.fable_antiformat", m.group(0),
                                    "Fable 5.1 under-formats already. Say when structure is appropriate instead.",
                                    [m.start(), m.end()]))

    new_figures = sorted({f.strip() for f in FIGURE.findall(rewrite)} - {f.strip() for f in FIGURE.findall(source)})
    if new_figures:
        advisory.append(finding("grounding.new_figures", ", ".join(new_figures[:12]),
                                "Check each figure is from the original or context."))
    return blocking, advisory


# ---------------------------------------------------------------- judge

def claude_bin():
    env = os.environ.get("ROSETTA_CLAUDE_BIN")
    if env and os.path.exists(env):
        return env
    for path in (os.path.expanduser("~/.local/bin/claude"), "/opt/homebrew/bin/claude", "/usr/local/bin/claude"):
        if os.path.exists(path):
            return path
    return shutil.which("claude")


def judge_prompt(target, original, rewrite, context, hint):
    qs = "\n".join(f'<question id="{qid}">{q}</question>' for qid, q in judge_questions())
    ctx = f"\n<established_context>\n{context.strip()}\n</established_context>\n" if context.strip() else ""
    hints = f"\n<hints>Figures in the rewrite that are not in the original or context: {hint}</hints>\n" if hint else ""
    return f"""You are grading a rewritten prompt against the messy original it was made from. You did not write it. Someone will paste the rewrite into {TARGET_LABELS.get(target, target)}.

<original_prompt>
{original.strip()}
</original_prompt>
{ctx}
<rewritten_prompt>
{rewrite.strip()}
</rewritten_prompt>
{hints}
<questions>
{qs}
</questions>

Answer every question yes or no. A question that starts with "If" is answered yes when its condition does not apply to this task. A "no" needs a concrete reason that quotes or names the passage at fault, and a one-line fix. Judge only what is on the page, and do not reward length or technique count.

First reason briefly inside <analysis> tags. Then output only a JSON object inside <result> tags, in this shape:
{{"answers": [{{"id": "intent_kept", "answer": "yes", "reason": "", "fix_hint": ""}}]}}"""


def run_judge_once(prompt):
    exe = claude_bin()
    if not exe:
        raise RuntimeError("claude CLI not found")
    env = dict(os.environ)
    env["PATH"] = ":".join([os.path.expanduser("~/.local/bin"), "/opt/homebrew/bin", "/usr/local/bin",
                            "/usr/bin", "/bin", env.get("PATH", "")])
    # Run outside ~/Documents for the same reason the app does: no project discovery,
    # no macOS protected-folder prompt.
    tmp = tempfile.gettempdir()
    env["PWD"] = tmp
    env.pop("OLDPWD", None)
    # No tools for a grader (harness L3): no built-ins, no plugin MCP servers, and no claude.ai
    # connectors such as Gmail. No personal context either: no auto-memory, and no settings
    # sources, so the user's CLAUDE.md and prompt hooks never reach the judge.
    env["ENABLE_CLAUDEAI_MCP_SERVERS"] = "false"
    env["CLAUDE_CODE_DISABLE_AUTO_MEMORY"] = "1"
    proc = subprocess.run(
        [exe, "-p", prompt, "--model", limit("judge_model"), "--effort", limit("judge_effort"),
         "--output-format", "text", "--no-session-persistence", "--tools", "", "--strict-mcp-config",
         "--setting-sources", ""],
        capture_output=True, text=True, timeout=240, cwd=tmp, env=env, stdin=subprocess.DEVNULL)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.strip() or f"claude exited {proc.returncode}")
    m = re.search(r"<result>\s*(\{.*\})\s*</result>", proc.stdout, re.S)
    if not m:
        raise RuntimeError("judge returned no <result> JSON")
    answers = {a.get("id"): a for a in json.loads(m.group(1)).get("answers", [])}
    missing = [qid for qid, _ in judge_questions() if qid not in answers]
    if missing:
        raise RuntimeError("judge skipped: " + ", ".join(missing))
    return answers


def judge(target, original, rewrite, context, hint, runs):
    prompt = judge_prompt(target, original, rewrite, context, hint)
    all_runs = [run_judge_once(prompt) for _ in range(runs)]
    findings = []
    for qid, _ in judge_questions():
        noes = [r[qid] for r in all_runs if str(r[qid].get("answer", "")).strip().lower() != "yes"]
        if len(noes) * 2 > runs:
            findings.append(finding(f"judge.{qid}", noes[0].get("reason", ""), noes[0].get("fix_hint", "")))
    return findings


# ---------------------------------------------------------------- calibration state

def latest_report():
    try:
        paths = [os.path.join(REPORTS_DIR, n) for n in os.listdir(REPORTS_DIR) if n.startswith("calibration-")]
    except OSError:
        return None
    if not paths:
        return None
    with open(max(paths, key=os.path.getmtime), encoding="utf-8") as fh:
        return json.load(fh)


def armed_state():
    report = latest_report()
    if not report:
        return False, "No calibration report yet. Judge is advisory."
    if report.get("fingerprint") != judge_fingerprint():
        return False, "Judge questions or model changed since the last calibration. Judge is advisory."
    if not report.get("armed"):
        return False, f"Last calibration ({report.get('date')}) did not meet the bar. Judge is advisory."
    return True, f"Armed by calibration of {report.get('date')}."


# ---------------------------------------------------------------- commands

def read(path):
    if not path:
        return ""
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def feedback_text(findings):
    lines = []
    for f in findings:
        hint = f" Fix: {f['fix_hint']}" if f.get("fix_hint") else ""
        lines.append(f"- {f['rule']}: {f['text']}{hint}")
    return "\n".join(lines)


def cmd_check(args):
    try:
        original, rewrite, context = read(args.original), read(args.rewrite), read(args.context)
    except OSError as exc:
        print(json.dumps({"error": str(exc)}))
        return 2
    blocking, advisory = code_checks(args.target, original, rewrite, context)
    verdicts = [verdict("code", blocking, "deterministic", args.attempt)]
    armed, armed_note = armed_state()
    judge_findings, notes = [], [armed_note]

    if blocking:
        notes.append("Judge skipped: code checks failed.")
    elif not args.no_judge:
        runs = int(limit("armed_runs")) if armed else 1
        hint = next((f["text"] for f in advisory if f["rule"] == "grounding.new_figures"), "")
        try:
            judge_findings = judge(args.target, original, rewrite, context, hint, runs)
            verdicts.append(verdict("judge", judge_findings, "model", args.attempt,
                                    judge_model=f"{limit('judge_model')}/{limit('judge_effort')}",
                                    runs=runs, blocking=armed))
        except Exception as exc:  # judge trouble never blocks a rewrite
            notes.append(f"Judge unavailable: {exc}")

    judge_blocks = judge_findings if armed else []
    result = {
        "approved": not blocking and not judge_blocks,
        # Only what can fail a draft may bounce it. An unarmed judge blocks nothing (harness rule),
        # and bouncing on its notes threw away drafts that had passed every code check.
        "retry": bool(blocking or judge_blocks),
        "max_attempts": int(limit("max_attempts")),
        "judge_armed": armed,
        "blocking": blocking + judge_blocks,
        "advisory": advisory + ([] if armed else judge_findings),
        "feedback": feedback_text(blocking + judge_findings),
        "notes": notes,
        "verdicts": verdicts,
    }
    print(json.dumps(result, indent=2, ensure_ascii=True))
    return 0 if result["approved"] else 1


def load_json_dir(path):
    out = []
    try:
        names = sorted(n for n in os.listdir(path) if n.endswith(".json"))
    except OSError:
        return out
    for name in names:
        with open(os.path.join(path, name), encoding="utf-8") as fh:
            data = json.load(fh)
        # A file holds one case, or a list of cases each carrying its own "id".
        if isinstance(data, list):
            out.extend((f"{name}#{c.get('id', i)}", c) for i, c in enumerate(data))
        else:
            out.append((name, data))
    return out


def cmd_replay(args):
    cases = load_json_dir(CASES_DIR)
    if not cases:
        print("No cases in evals/cases.")
        return 1
    failed = 0
    for name, case in cases:
        blocking, _ = code_checks(case["target"], case["original"], case["rewrite"], case.get("context", ""))
        got = "Rejected" if blocking else "Approved"
        fired = {f["rule"] for f in blocking}
        missing = [r for r in case.get("must_fail", []) if r not in fired]
        ok = got == case["expected"] and not missing
        failed += not ok
        detail = f"fired {sorted(fired)}" if fired else "no findings"
        if missing:
            detail += f", missing {missing}"
        print(f"{'PASS' if ok else 'FAIL'}  {name}  expected {case['expected']}, got {got}, {detail}")
    print(f"\n{len(cases) - failed}/{len(cases)} passed")
    return 0 if failed == 0 else 1


def cmd_calibrate(args):
    approved = load_json_dir(os.path.join(CALIB_DIR, "approved"))
    rejected = load_json_dir(os.path.join(CALIB_DIR, "rejected"))
    need = int(limit("armed_min_cases"))
    rate_bar = float(limit("armed_min_rate"))
    results = {"approved": [], "rejected": []}
    for side, cases, want_reject in (("approved", approved, False), ("rejected", rejected, True)):
        for name, case in cases:
            try:
                f = judge(case["target"], case["original"], case["rewrite"], case.get("context", ""), "", args.runs)
                results[side].append({"case": name, "ok": bool(f) == want_reject, "findings": [x["rule"] for x in f]})
            except Exception as exc:
                results[side].append({"case": name, "ok": False, "error": str(exc)})

    def rate(rows):
        return sum(r["ok"] for r in rows) / len(rows) if rows else 0.0

    report = {
        "date": datetime.date.today().isoformat(),
        "fingerprint": judge_fingerprint(),
        "runs_per_case": args.runs,
        "approved_rate": rate(results["approved"]),
        "rejected_rate": rate(results["rejected"]),
        "counts": {"approved": len(approved), "rejected": len(rejected)},
        "armed": (len(approved) >= need and len(rejected) >= need and args.runs >= int(limit("armed_runs"))
                  and rate(results["approved"]) >= rate_bar and rate(results["rejected"]) >= rate_bar),
        "results": results,
    }
    os.makedirs(REPORTS_DIR, exist_ok=True)
    path = os.path.join(REPORTS_DIR, f"calibration-{report['date']}-{report['fingerprint']}.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2, ensure_ascii=True)
    print(f"approved {report['approved_rate']:.0%} of {len(approved)}, rejected {report['rejected_rate']:.0%} "
          f"of {len(rejected)}. Armed: {report['armed']}. Report: {path}")
    return 0 if report["armed"] else 1


def cmd_status(args):
    armed, note = armed_state()
    counts = {s: len(load_json_dir(os.path.join(CALIB_DIR, s))) for s in ("approved", "rejected")}
    print(f"{'ARMED' if armed else 'ADVISORY'}: {note}")
    print(f"Calibration cases: {counts['approved']} approved, {counts['rejected']} rejected "
          f"(need {limit('armed_min_cases')} each). Replay cases: {len(load_json_dir(CASES_DIR))}.")
    return 0


def cmd_save_case(args):
    case = {
        "target": args.target,
        "original": read(args.original),
        "context": read(args.context),
        "rewrite": read(args.rewrite),
        "expected": args.expected,
        "must_fail": [r for r in (args.must_fail or "").split(",") if r],
        "why": args.why,
        "created_at": datetime.date.today().isoformat(),
    }
    folder = CASES_DIR if args.dest == "replay" else os.path.join(CALIB_DIR, args.expected.lower())
    os.makedirs(folder, exist_ok=True)
    stem = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    path = os.path.join(folder, f"{stem}-{args.target}.json")
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(case, fh, indent=2, ensure_ascii=True)
    print(path)
    return 0


def main():
    parser = argparse.ArgumentParser(description="Rosetta Prompt eval checker")
    sub = parser.add_subparsers(dest="cmd", required=True)

    def io_args(p):
        p.add_argument("--target", required=True, choices=sorted(TARGET_LABELS))
        p.add_argument("--original", required=True)
        p.add_argument("--rewrite", required=True)
        p.add_argument("--context")

    p = sub.add_parser("check")
    io_args(p)
    p.add_argument("--no-judge", action="store_true")
    p.add_argument("--attempt", type=int, default=1)
    p.set_defaults(fn=cmd_check)

    sub.add_parser("replay").set_defaults(fn=cmd_replay)

    p = sub.add_parser("calibrate")
    p.add_argument("--runs", type=int, default=int(limit("armed_runs")))
    p.set_defaults(fn=cmd_calibrate)

    sub.add_parser("status").set_defaults(fn=cmd_status)

    p = sub.add_parser("save-case")
    io_args(p)
    p.add_argument("--expected", required=True, choices=["Approved", "Rejected"])
    p.add_argument("--why", required=True)
    p.add_argument("--must-fail")
    p.add_argument("--dest", choices=["replay", "calibration"], default="replay")
    p.set_defaults(fn=cmd_save_case)

    args = parser.parse_args()
    sys.exit(args.fn(args))


if __name__ == "__main__":
    main()
