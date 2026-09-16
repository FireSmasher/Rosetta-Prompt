# Rewrite evals: success criteria and checks

Written 16 September 2026. Read by `scripts/check_rewrite.py` on every run, so editing a table
below changes the checks with no code change. If a table is missing, the script falls back to
the same values compiled in.

Sources:
- https://platform.claude.com/docs/en/test-and-evaluate/develop-tests (success criteria, eval design, grading)
- https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/reduce-hallucinations
- https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/increase-consistency
- https://platform.claude.com/docs/en/test-and-evaluate/strengthen-guardrails/reduce-prompt-leak
- A five-layer agent harness: L1 evals, L2 schema contracts, L3 least-privilege tools, L4 a
  deterministic bounce loop, L5 failure replay. The table below maps each onto this checker.

## What "a good rewrite" means

The develop-tests page says success criteria must be specific, measurable, achievable and
relevant, and that most tasks need several of them. For a rewritten prompt those are:

| Criterion (develop-tests name) | For a rewrite, measured as |
|---|---|
| Task fidelity | Same task, deliverable and audience as the original; every explicit constraint kept |
| Context utilization | Specifics filled from the original or established context; nothing invented; no placeholders |
| Relevance and coherence | Structure proportionate to the task; output is the prompt alone, no preamble or wrapper |
| Tone and style | The house style: zero em or en dashes |
| Consistency (guardrail page) | Where output must repeat a fixed shape, the format is defined precisely |
| Hallucination (guardrail page) | Where facts are asked for, uncertainty is allowed and claims are grounded |
| Privacy / prompt leak (guardrail page) | No secrets the task doesn't need; confidentiality handled plainly if asked |
| Target fit | No instruction the target's own docs say to remove |

## How the checks map onto the harness

| Harness layer | In Rosetta Prompt |
|---|---|
| L1 deterministic evals | Code checks below. Run first. Any failure rejects the draft. |
| L1 model evals | One Sonnet 5 judge call at `low` effort, yes/no questions, never scores. Runs only if the code checks pass. The judge sees the original, the context and the rewrite, never the rewriter's guidance or reasoning. |
| L2 contract | The output must be exactly one prompt: the preamble, wrapper, leaked-tag and placeholder checks. |
| L4 bounce loop | A draft with a code failure, or a judge "no" once the judge is armed, goes back to the rewriter with the check IDs and reasons. At most 3 attempts. After the third, the last draft is shown with its open failures listed, never silently. |
| L5 replay | `evals/cases/` holds known failures and known-good rewrites. `check_rewrite.py replay` must pass 100% after any change to the checks, the guidance or the rewrite request. |

**The judge is advisory until calibrated** (harness rule: a model eval blocks nothing until its
calibration arms it). Advisory means its "no" answers are shown next to the result but neither retry nor fail
the draft. Until 16 September 2026 they did trigger a retry, which in testing re-billed drafts
that had passed every code check on three of four instrumented runs. It is armed when `evals/calibration/approved/` and `rejected/` each hold at
least 20 real cases, `check_rewrite.py calibrate` scores at least 18 of 20 right on each side
(3 runs per case, majority), and the questions and judge model haven't changed since that
report. Armed, it runs 3 times per check with the majority deciding, and a "no" blocks.
`check_rewrite.py status` says which state it is in. On 16 September 2026 the calibration sets
are empty, so the judge is advisory.

## Code checks

| ID | Rejects when |
|---|---|
| `output.empty` | The rewrite is blank |
| `punct.long_dash` | Any U+2013 or U+2014 character |
| `output.fence_wrapper` | The whole output is wrapped in a code fence |
| `output.preamble` | The output opens with "Here is", "Sure", "Below is" and the like |
| `output.trailing_note` | The last paragraph is commentary about the rewrite ("I've added", "Changes made", "Let me know") |
| `output.leaked_tag` | A tag from the rewrite request (`<messy_prompt>`, `<house_style>` ...) appears and wasn't in the original |
| `grounding.placeholder` | `[ALL CAPS]` slots, `TBD`, `TODO`, `<insert ...>` or `{{VAR}}` that the original and context don't already contain |
| `length.overbuilt` | Original at most `short_words` words, rewrite over `overbuilt_words` words |
| `length.dropped` | Original at least `dropped_min_words` words, rewrite under `dropped_ratio` of its length |
| `target.opus5_verify` | Opus 5 target and the rewrite adds "double-check", "re-verify", "verification step" and similar |
| `target.review_filter` | Opus 5 or Sonnet 5 target and the rewrite says "only report high-severity", "be conservative" or "don't nitpick" |
| `target.haiku_effort` | Haiku 4.5 target and the rewrite names an effort level |
| `target.fable_antiformat` | Fable 5.1 target and the rewrite adds a blanket no-markdown/no-lists rule the original didn't ask for |

Advisory only, never rejects: `grounding.new_figures` lists numbers in the rewrite that appear in
neither the original nor the context. They are passed to the judge as a hint for
`nothing_invented`.

```rubric
@table limits
short_words = 60
overbuilt_words = 350
dropped_min_words = 150
dropped_ratio = 0.2
max_attempts = 3
judge_model = sonnet
judge_effort = low
armed_min_cases = 20
armed_min_rate = 0.9
armed_runs = 3
```

## Judge questions

Binary, all must be yes. A question that starts with "If" is answered yes when its condition
doesn't apply, so the guardrails are only demanded where the task carries that risk.

```rubric
@table judge
intent_kept | Does the rewrite ask for the same task, deliverable and audience as the original, without narrowing, widening or swapping what is being asked?
constraints_kept | Does the rewrite keep every explicit requirement, constraint, prohibition and preference stated in the original?
nothing_invented | Is every specific in the rewrite (names, numbers, dates, files, tools, facts, decisions) present in the original or the established context, or plainly framed as an assumption or a question for the reader?
success_defined | Does the rewrite make clear what a finished, successful response looks like (the deliverable, plus its format, length or done condition) to the degree this task needs?
proportionate | Is the amount of structure (tags, role, examples, sections) proportionate to the task, with no technique added only for show?
uncertainty_allowed | If the task asks for facts, research, analysis of material or advice, does the rewrite let the model say it lacks the information and ask it to ground claims in the given material or sources?
format_fixed | If the output must follow a fixed or repeatable shape, does the rewrite define that shape precisely, with a template or an example?
no_needless_secrets | Does the rewrite avoid adding credentials, keys or private personal details the task doesn't need, and if the original asks to keep something from end users, does it keep that instruction in one plain line rather than elaborate leak-proofing?
```
