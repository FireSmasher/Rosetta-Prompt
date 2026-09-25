#!/usr/bin/env python3
"""Model and effort pick for a messy prompt, the same scoring Advisor.assess() runs in the app.

Reads the rubric tables in reference/model-selection.md, with any table in
model-selection.local.md replacing the default of the same name. Costs nothing: no model call.

    score_prompt.py --text "messy prompt" [--context ctx.txt] [--family anthropic|openai]
    score_prompt.py --file messy.txt
    score_prompt.py test cases.json    # [["prompt", "haiku|sonnet|sonnet+|opus|fable"], ...]

Keep this in step with Advisor.assess() in Sources/RosettaPrompt/main.swift.
"""
import argparse, json, os, re, sys

REF = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "reference")


def parse(path):
    tables, cur, fence = {}, None, False
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except FileNotFoundError:
        return tables
    for raw in lines:
        line = raw.strip()
        if not fence:
            if line.startswith("```rubric"):
                fence, cur = True, None
            continue
        if line.startswith("```"):
            fence, cur = False, None
            continue
        if line.startswith("@table "):
            cur = line[7:].strip()
            tables[cur] = []
            continue
        if not cur or not line or line.startswith("#"):
            continue
        m = re.search(r"[|=]", line)
        if m:
            key = line[:m.start()].strip()
            if key:
                tables[cur].append((key, line[m.end():].strip()))
        else:
            tables[cur].append((line, ""))
    return tables


def load_tables():
    tables = parse(os.path.join(REF, "model-selection.md"))
    tables.update(parse(os.path.join(REF, "model-selection.local.md")))
    return tables


def words(text):
    return [w for w in re.split(r"[^0-9a-zA-ZÀ-￿]+", text) if w]


def assess(task, tables, context="", family="anthropic"):
    th = dict(tables["thresholds"])
    num = lambda k: int(th[k])
    raw = (task + "\n\n" + context).strip()
    text = raw.lower()
    exact = {k for k, _ in tables.get("exact", [])}
    score, signals = 0, []

    def match(needle, hay, ws):
        if " " in needle or "-" in needle:
            return needle in hay
        if needle in exact:
            return needle in ws
        return any(w.startswith(needle) for w in ws)

    if len(raw) > num("verylongbrief"):
        score += 2; signals.append("very long brief")
    elif len(raw) > num("longbrief"):
        score += 1; signals.append("long brief")
    elif len(raw) < num("shortask"):
        score -= 1; signals.append("short ask")
    symbols = sum(c in "{}[]();<>=" for c in text)
    if "```" in text or (len(raw) > 200 and symbols / len(raw) > 0.03):
        score += 2; signals.append("contains code")
    steps = sum(1 for l in raw.split("\n")
                if len(l.strip()) > 2 and l.strip()[0].isdigit() and l.strip()[1] in ".)")
    if steps >= 3:
        score += 2; signals.append(f"multi-step, {steps} steps")
    elif " then " in text or "step 1" in text or "first," in text:
        score += 1; signals.append("sequenced work")
    if text.count("?") >= 3:
        score += 1; signals.append(f"{text.count('?')} separate questions")
    ws = words(text)
    heavy = 0
    for needle, label in tables["heavy"]:
        if match(needle, text, ws):
            heavy += 2; signals.append(label)
    score += min(heavy, num("wordcap"))
    for needle, label in tables["light"]:
        if match(needle, text, ws):
            score -= 1; signals.append(label)
    stakes_text = text
    for phrase, _ in tables.get("not-stakes", []):
        stakes_text = stakes_text.replace(phrase, " ")
    sws = words(stakes_text)
    stakes = sorted({label for needle, label in tables["stakes"] if match(needle, stakes_text, sws)})
    c2, c3, c4 = num("class2from"), num("class3from"), num("class4from")
    needed = 1 if score < c2 else 2 if score < c3 else 3 if score < c4 else 4
    if stakes:
        needed = max(needed, 3)
    ladder = [x.strip() for x in dict(tables["ladder"])[family].split(",")]
    model = ladder[min(max(needed, 1), len(ladder)) - 1]
    effort = dict(tables.get("effort-by-model", [])).get(f"{model}.{needed}") or dict(tables["effort"])[str(needed)]
    if stakes and effort in ("low", "medium"):
        effort = "high"
    rewrite_effort = effort if effort in ("low", "medium") else "high"
    return {"model": model, "effort": None if model == "haiku" else effort,
            "rewrite_effort": rewrite_effort, "class": needed, "score": score,
            "stakes": stakes, "signals": list(dict.fromkeys(signals))}


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "test":
        rank = {"haiku": 1, "luna": 1, "sonnet": 2, "opus": 3, "fable": 4}
        tables, ok, cases = load_tables(), 0, json.load(open(sys.argv[2], encoding="utf-8"))
        for prompt, want in cases:
            got = assess(prompt, tables)["model"]
            good = rank[got] >= 2 if want == "sonnet+" else got == want
            ok += good
            if not good:
                print(f"MISS got {got}, want {want}: {prompt[:70]}")
        print(f"{ok}/{len(cases)} passed")
        sys.exit(0 if ok == len(cases) else 1)
    ap = argparse.ArgumentParser()
    ap.add_argument("--text")
    ap.add_argument("--file")
    ap.add_argument("--context", help="file holding the established-context paragraph")
    ap.add_argument("--family", default="anthropic", choices=["anthropic", "openai"])
    a = ap.parse_args()
    task = a.text if a.text is not None else open(a.file, encoding="utf-8").read()
    ctx = open(a.context, encoding="utf-8").read() if a.context else ""
    print(json.dumps(assess(task, load_tables(), ctx, a.family), indent=2))


if __name__ == "__main__":
    main()
