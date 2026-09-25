# Model selection guidance, distilled

Sourced 5 September 2026. Confidence 95% for the Anthropic material: every directive in
"The order of levers" and "Effort levels" is a quote or a close paraphrase of a primary
Anthropic document, each listed under Sources. Confidence 60% for the numbers in the
Rubric tables: those are this app's own calibration, not published by anyone, and they are
marked as such where they appear.

The GPT tiers are covered here too, because Rosetta Prompt targets them. Anthropic
publishes nothing about OpenAI models, so their facts come from `openai-prompting-guide.md`
in this same folder. What carries across is the method, not the vendor facts: cost per
completed task, and effort before model. Both are stated as general principles.

## Sources

- Effort parameter, levels, defaults and per-model recommendations:
  https://platform.claude.com/docs/en/build-with-claude/effort
- Choosing between models, cost per completed task, the order of experiments:
  https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
- Model overview and context windows:
  https://platform.claude.com/docs/en/about-claude/models/overview
- Prices below are the Anthropic first-party API rates as carried in the bundled
  `claude-api` skill's model table, cached 2026-06-24. Partner platforms (Bedrock,
  Vertex) price separately.

## The order of levers

This is the part worth reading twice, because the intuitive order is the wrong one.
Anthropic's guidance is that **effort is the first lever and model is the second**.

> "Sweep effort on your current model first. It is the cheapest experiment on this page,
> and most workloads end there."

> "If the sweep shows a gap, price the stronger model alone at low effort. That is the
> number an advisor pairing has to beat."

> "For most agent workloads, start with Claude Fable 5.1 at `low` effort and raise effort
> where it misses."

So when a task looks over-provisioned, the documented first move is to keep the model and
drop the effort, not to drop a tier. Dropping a tier is for a genuine mismatch of two
classes or more.

The reason is how cost is actually measured:

> "Price lists are written per token, and per token the frontier model looks expensive:
> Claude Fable 5.1's per-token price is several times Claude Sonnet 5's. You pay for
> completed tasks, though, so compare models on cost per completed task."

> "Price the tail of your workload, not the median: compare models on the hardest tenth of
> your tasks, not the typical one."

A cheaper model that needs two attempts is not cheaper. Two supporting data points from the
same document:

> "Claude Opus 5 at `low` beats Opus 4.8 for about 30% of the cost per solved task"

(Both quotes are from the 16 September 2026 read. The 24 September read adds: on the same
subset, "Opus 5.5 at its default matched Fable 5.1 at its default ... for about a fifth of the
cost per solved task.")

> "On the SWE-bench Pro subset ... Claude Opus 5 alone matched Claude Fable 5.1 alone at
> the default (91.7% compared with 92.1%, inside run-to-run noise) at about 15% less per
> solved task"

And on when splitting work across tiers is worth it at all:

> "When your traffic mixes routine work that a smaller model handles reliably with harder
> steps that need frontier capability, splitting the work keeps frontier intelligence where
> it matters while most tokens bill at smaller-model rates. When a workload lacks that mix,
> because its difficulty is uniform or it is one dependent chain, a single well-tuned model
> is usually the better choice."

A single prompt being rewritten is one dependent chain. So the default answer for one prompt
is one well-tuned model, tuned by effort.

## Effort levels

Five levels. `high` is the API default, and setting `high` is identical to omitting the
parameter. Effort applies to every output token, including tool calls and thinking.

> "Effort is a behavioral signal, not a strict token budget. At lower effort levels, Claude
> still thinks on sufficiently difficult problems, but thinks less than it would at higher
> effort levels for the same problem."

| Level | Anthropic's stated use case |
|---|---|
| `low` | "Simpler tasks that need the best speed and lowest costs, such as subagents" |
| `medium` | "Agentic tasks that require a balance of speed, cost, and performance" |
| `high` | "Complex reasoning, difficult coding problems, agentic tasks" (the default) |
| `xhigh` | "Long-running agentic and coding tasks (over 30 minutes) with token budgets in the millions" |
| `max` | "Tasks requiring the deepest possible reasoning and most thorough analysis" |

Per model:

- **Opus 5.5** (24 Sep 2026): the default is `medium`, one level below Opus 5's `high`. "Start at
  `medium`... set it explicitly, and test several levels against your own evals rather than
  carrying over the setting you used on Claude Opus 5." Thinking is always on and cannot be
  disabled. The Opus 5 advice it replaces: "Start with `high`, the default ... use `low` and
  `medium` liberally as your primary control for token cost and response time wherever your
  evals show quality holds."
- **Sonnet 5**: defaults to `high`. `medium` is the "Cost-saving step-down from the default.
  Comparable to Claude Sonnet 4.6 at high effort." `low` is "For high-volume or
  latency-sensitive workloads. Suitable for chat and non-coding use cases."
- **Fable 5.1**: "Start with `high`, the default. Step up to `xhigh` or `max` for the most
  capability-sensitive agentic and coding work, and step down to `medium` or `low` for
  routine or latency-sensitive work once your evals show quality holds."

One correction this app has to respect, because it affects the token estimate shown:

> "Effort controls thinking volume, not visible response length: on Claude Opus 5, changing
> effort does not reliably shorten responses, so prompt for length instead."

So a lower effort level saves thinking tokens, and should not be presented as shortening the
answer. The app's output estimate is driven by task shape, never by effort.

## The ladder and what each tier is for

Lowest to highest cost and capability: Haiku 4.5, Sonnet 5, Opus 5.5, Fable 5.1.

| Model | Input $/1M | Output $/1M | Documented positioning |
|---|---|---|---|
| Claude Haiku 4.5 | $1 | $5 | "It fits high-volume work with checkable outputs, not long agentic loops." |
| Claude Sonnet 5 | $2 | $10 | Mid tier. Its `medium` effort matches Sonnet 4.6 at `high`. |
| Claude Opus 5.5 | $4 | $20 | Anthropic's default for most workloads. At `medium` it matched Fable 5.1 on the SWE-bench Pro subset for about a fifth of the cost per solved task. |
| Claude Fable 5.1 | $10 | $50 | Frontier. "Use Claude Fable 5.1 for demanding reasoning and long-horizon agentic work, or when your evals on Claude Opus 5.5 at higher effort still fall short." (24 Sep 2026; until then Anthropic advised starting agent work on Fable 5.1 at `low`.) |

Haiku 4.5 became a rewrite target on 16 September 2026 (the app was renamed from
PromptTranslator to Rosetta Prompt the same day), so class 1 on the Anthropic ladder now
recommends `haiku`. Until then `sonnet` occupied both of the two lowest classes.

GPT tiers, from `openai-prompting-guide.md` in this folder, not from Anthropic:

| Model | Input $/1M | Output $/1M | Positioning |
|---|---|---|---|
| GPT-6 Luna | $0.10 | $0.50 | "For cost-sensitive, high-volume workloads." Classification, extraction, formatting. |
| GPT-6 Sol | $2 | $10 | "To balance intelligence and cost." Covers both middle classes, because GPT-6 has no Terra. |
| GPT-6 Astra | $10 | $50 | Most capable. OpenAI's own starting point: "If you're not sure where to start, use GPT-6 Astra." |

Since 24 September 2026 the app offers GPT-6 only. GPT-6 Sol and Luna were
released 22 September 2026 and OpenAI's models page now recommends them over GPT-5.6 Sol,
Terra and Luna, which still work but are no longer offered here. There is no GPT-6 Terra, so
the GPT ladder has three rungs and Sol takes classes 2 and 3.

## What the app does with this

1. Score the task locally. No model is called to decide which model to call.
2. Compare the score's weight class against the selected target's class.
3. **Gap of one class**: keep the model, lower the effort. This is the documented first
   lever, and it costs nothing to act on because the rewrite is unchanged.
4. **Gap of two or more**: recommend the other model, and stop before spending. The rewrite
   is built from the target's own prompting guidance, so a rewrite aimed at the wrong target
   is thrown away entirely.
5. **Below the needed class**: recommend stepping up, and stop before spending.
6. **Stakes override**: money, legal standing, immigration status and security floor the
   recommendation at class 3 and effort at `high`, whatever the difficulty score says. This
   one is not from Anthropic. It is this app's own rule, recorded here because the app
   enforces it and the reason should be visible: the cost of being wrong there is not
   measured in tokens. Which words count as stakes is yours to set (see "Your own data").

## Effort for the rewrite call itself

The app runs the rewrite through Claude Code's `opus` alias, which since 22 September 2026
resolves to Claude Opus 5.5 (it was Opus 5 when the choice was made). Until 5 September 2026 that call was pinned to
`high` effort. It now follows the assessed difficulty, capped at `high`:

| Assessed task effort | Rewrite runs at |
|---|---|
| `low` | `low` |
| `medium` | `medium` |
| `high` | `high` |
| `xhigh` | `high`, capped |

Since 25 September 2026 a class 3 task that is not high stakes assesses at `medium` (the
`effort-by-model` table), so its rewrite runs Opus 5.5 at `medium`. Anthropic measured Opus 5.5 at
`medium` matching or beating Opus 5 at `high`, which is the setting the 4 September comparison
chose, so this should not cost rewrite quality. It is still a claim from Anthropic's evals, not a
re-run of that comparison.

Two reasons for the cap, both from the effort doc:

> "`xhigh` ... Long-running agentic and coding tasks (over 30 minutes) with token budgets in
> the millions"

A rewrite is one bounded generation, so `xhigh` is the wrong shape of setting for it. And
capping is what makes the change safe: the rewrite can now only ever match or undercut what
it used to cost, never exceed it.

What the change actually saves is thinking tokens, not output length:

> "The effort parameter affects all tokens in the response, including ... Thinking (when
> active)."

It is worth being precise about what is not established. The `rosetta-prompt` skill records
a 4 September 2026 comparison that picked Opus 5 at `high` as the best rewriter of five
candidates. That test did not cover Opus 5 at `low` or `medium`, and has not been re-run on
Opus 5.5. So "quality holds at lower
effort on simple prompts" is an assumption here, not a measured finding. If a rewrite of a
simple prompt looks thin, raise the effort and re-test before looking elsewhere.

One more caveat worth keeping visible: the effort a task needs and the effort that rewriting
its prompt needs are two different numbers. The app derives the second from the first because
they correlate, not because they are the same thing.

## Your own data

The tables below are neutral defaults. To make the guide speak about your own work, create
`model-selection.local.md` in this folder, next to this file. It uses the same fenced
`rubric` format. Any table you put there replaces the default table of the same name, whole,
so copy a table in full before editing it. The file never leaves your machine: the app and the
skill only read it locally, it is never sent to a model, and `.gitignore` keeps it out of the
repository. `model-selection.local.example.md` is a starting point.

The tables most worth making your own:

- `detail`: the hover lines per rung. Use jobs you really run, so each effort level reads as
  something you recognise.
- `stakes`: the words that floor a task at class 3 and `high` effort. Add what is costly to get
  wrong in your life or work (a permit, a medical question, a client name).
- `not-stakes`: phrases that contain a stakes word without the stakes, if your work produces
  false alarms.
- `heavy` and `light`: vocabulary from your own domain that marks hard or mechanical work.

## Rubric tables

Everything below is read by Rosetta Prompt at launch. Editing a table changes the app's
behaviour on the next run, with no rebuild. If a table is missing or malformed the app falls
back to the same values compiled in as defaults, so a broken edit degrades rather than
breaks.

The weights and thresholds are calibration, not documentation. Anthropic publishes no
numeric difficulty rubric. Treat them as a starting point that earns changes from use.

```rubric
@table ladder
anthropic = haiku, sonnet, opus, fable
openai = luna, sol, sol, astra
```

```rubric
@table effort
1 = low
2 = medium
3 = high
4 = xhigh
```

Effort names do not mean the same amount of thinking on every model. Since 25 September 2026 a
row here overrides the class default for one model: "Claude Opus 5.5 at medium matches or exceeds
Claude Opus 5 at high on coding and knowledge-work evaluations" (`prompting-claude-opus-5-5`), and
`medium` is its default, so a class 3 task on Opus 5.5 gets `medium`. Stakes still floor it at
`high`.

```rubric
@table effort-by-model
opus.3 = medium
```

```rubric
@table thresholds
class2from = -1
class3from = 4
class4from = 10
wordcap = 6
verylongbrief = 4000
longbrief = 1200
shortask = 220
```

Until 25 September 2026 these read `class2from = 2` and `class3from = 6`, so a score of 0 meant
class 1. A spoken or dictated prompt is nearly always under `shortask`, takes the -1, and
rarely uses the jargon in `heavy`, so 27 of 30 test prompts (a cover letter, a debugging job, an
app build, a landlord dispute) landed on Haiku. Now an unremarkable prompt lands on class 2,
the family's sensible default, and Haiku has to be earned by a light signal: "summarise this"
scores -3, "fix the grammar" -2, "write a LinkedIn post" -1. The `heavy` table gained everyday
phrasings of judgement work the same day, so three of them, not five, reach class 3.

Heavy signals mark work that needs real reasoning. A needle with a space or a hyphen matches
anywhere in the text; a single word matches as a word prefix, so "optimi" catches optimise
and optimize without "prove" catching "improve".

```rubric
@table heavy
architect | architecture work
trade-off | weighing trade-offs
tradeoff | weighing trade-offs
refactor | refactoring
debug | debugging
root cause | root-cause work
why does | diagnosis
why is | diagnosis
diagnos | diagnosis
prove | proof or derivation
derive | proof or derivation
optimi | optimisation
migrat | migration
strategy | strategy
strategi | strategy
evaluate | evaluation
critique | evaluation
pressure-test | evaluation
compare | comparison
decide | a decision
recommend | a recommendation
figure out | open-ended
work out | open-ended
help me think | open-ended
edge case | edge cases
across multiple | multi-part
end to end | multi-part
bug | debugging
crash | debugging
broken | debugging
timeout | debugging
traceback | debugging
stack trace | debugging
keeps dying | debugging
keeps failing | debugging
keeps crashing | debugging
not working | debugging
doesn't work | debugging
stops working | debugging
wrong | debugging
slow | performance work
faster | performance work
review | a review
feedback | a review
best way | a judgement call
should i | a judgement call
advice | a judgement call
plan | planning
planning | planning
explain how | explanation
explain why | explanation
step by step | a walkthrough
cover letter | writing for a reader
reply to | writing for a reader
in my voice | writing in a voice
sound like me | writing in a voice
persuad | persuasive writing
agent | agentic work
go through | a multi-item sweep
app | building software
website | building software
landing page | building software
dashboard | building software
sync | integration
```

Light signals mark mechanical, well-scoped work. Anthropic's phrase for the bottom of the
ladder is "high-volume work with checkable outputs", which is what these detect.

```rubric
@table light
extract | extraction
classify | classification
classifies | classification
categor | classification
format | formatting
reformat | formatting
tidy | tidying
clean up | tidying
spell | proofreading
grammar | proofreading
proofread | proofreading
shorten | trimming
summar | summarising
list of | listing
bullet | listing
rename | renaming
convert | conversion
translate | translation
tag | tagging
pull out | extraction
out of this | extraction
sort | sorting
```

Until 16 September 2026 this list also held `json`, `csv` and `table`. They name the data, not
the work, so "fix my script that syncs a bank csv" scored as light and landed on Haiku. The
transform verbs above already catch real conversion jobs. The debugging rows in `heavy` were
added the same day, after "my app crashes on launch, find the bug" also landed on Haiku.

Stakes are not difficulty. They floor the class and the effort regardless of score.

```rubric
@table stakes
legal | legal standing at stake
contract | contract terms
tax | tax exposure
taxes | tax exposure
negotiat | a negotiation
salary | money at stake
compensation | money at stake
invoice | money at stake
visa | immigration status at stake
immigration | immigration status at stake
security | security exposure
vulnerab | security exposure
credential | security exposure
residence permit | residence at stake
work permit | residence at stake
blue card | residence at stake
landlord | a dispute with money at stake
deposit | money at stake
lease | contract terms
```

Phrases that contain a stakes word without the stakes. They are blanked out before the stakes
list is matched, so "schema contracts" no longer floors a prompt at Opus (found 16 September 2026).

```rubric
@table not-stakes
schema contract
data contract
api contract
interface contract
code contract
contract test
```

Generative signals mean the answer is written rather than transformed, which drives the
output token estimate and nothing else.

```rubric
@table generative
write
draft
compose
essay
article
blog
memo
proposal
build
implement
generate
create
outline
```

Needles too short to match as a prefix safely. "tax" as a prefix also claims "taxonomy".

```rubric
@table exact
tax
taxes
plan
plans
app
apps
lease
tag
```

One line per tier, shown in the app's guide panel so the price of the recommendation is on
screen next to it.

```rubric
@table positioning
sonnet | Mid tier, $2 in / $10 out per million. Its medium effort matches Sonnet 4.6 at high.
opus | $4 in / $20 out per million. Anthropic's default for most work; at medium it matched Fable 5.1 for about a fifth of the cost per solved task.
fable | Frontier, $10 in / $50 out per million. For demanding reasoning and long agentic runs, or when Opus 5.5 falls short.
luna | Cheapest GPT-6 model, $0.10 in / $0.50 out per million. Cost-sensitive, high-volume work.
sol | Balanced GPT-6 model, $2 in / $10 out per million. Everyday coding through hard reasoning.
astra | Most capable GPT-6 model, $10 in / $50 out per million. Fewer output tokens, so cost per task can land lower.
```

## Ultracode is not an effort level

Worth writing down because it is easy to file next to `max`. In Claude Code, `ultracode` is the
opt-in keyword for multi-agent workflow orchestration: it authorises the Workflow tool to fan
work out across many agents at once. It is not a value of `output_config.effort` and it does
not appear on the effort ladder, so it is deliberately absent from the panel.

The two levers behave differently. Effort scales the tokens inside one response, and `max` is
its ceiling. Ultracode scales the number of responses, and its ceiling is however many agents
the workflow spawns, each with its own context. That is the larger multiplier by a wide margin.

## The ladder shown in the app

The guide panel draws a ladder for whichever family is selected (four rungs for Claude, three
for GPT-6), brightening as
capability rises. `guide-ladder` is the display order and is not the same as `ladder` above:
that one maps a difficulty class to a rewrite target. Since 16 September 2026 the two match
for the Anthropic family, because Haiku 4.5 is now a rewrite target as well as a rung.

```rubric
@table guide-ladder
anthropic = haiku, sonnet, opus, fable
openai = luna, sol, astra
```

```rubric
@table rung-label
haiku | Haiku 4.5
sonnet | Sonnet 5
opus | Opus 5.5
fable | Fable 5.1
luna | Luna
sol | Sol
astra | Astra
```

```rubric
@table price
haiku | $1 / $5 per M
sonnet | $2 / $10 per M
opus | $4 / $20 per M
fable | $10 / $50 per M
luna | $0.10 / $0.50 per M
sol | $2 / $10 per M
astra | $10 / $50 per M
```

Up to five lines of hover detail per rung, written as concrete jobs rather than restatements
of the docs. No line states a model's default effort, because the panel is short. Claude rungs
give one example job per effort level, all five, each chosen to illustrate that level's
published description. Since 25 September 2026 a key may repeat (`opus.2` twice): the repeats form a pool, and the app shows one per turn, starting at random on launch and moving on with every assessment, so the examples rotate instead of freezing. The shipped rows are generic everyday jobs. They read best when they
are jobs you actually run, so replace them with your own (see "Your own data"). Since
16 September 2026 each of those rows is `job; worth it: when`, and the app shows the second half
as a dimmer line under the first. Fable at `low` and `medium` lean on two findings in
`anthropic-prompting-guide.md`: `low` is often competitive with Opus on cost per task while
scoring higher, and `medium` roughly matches Fable 5 at lower cost. GPT rungs give four example jobs for the tier as a whole,
because OpenAI publishes no per level behavioural guidance and inventing one example per GPT
effort level would be fabrication dressed as a reference.

Haiku 4.5 is the one rung with no effort ladder at all: it is absent from the supported model
list on https://platform.claude.com/docs/en/build-with-claude/effort and sending `effort` to
it returns an error.

```rubric
@table detail
haiku.1 | Extract fields from 1000 emails
haiku.2 | Tag, label, reformat, convert
haiku.3 | Bulk translate short strings
haiku.4 | Not for judgement calls
haiku.5 | No effort parameter, it errors
sonnet.1 | low · tag 300 support tickets by topic; worth it: bulk sorting you spot-check
sonnet.2 | medium · tailor a CV to one job posting; worth it: everyday writing, low risk
sonnet.2 | medium · plan a week of meals to a calorie target; worth it: routine, you check the numbers
sonnet.3 | high · fix a script that crashes; worth it: one bug you can test fast
sonnet.3 | high · fix a web route that returns errors; worth it: reproducible, one file
sonnet.4 | xhigh · add an app screen end to end; worth it: a 30+ min run you won't watch
sonnet.5 | max · last try before moving up to Opus; worth it: Sonnet stalls, stakes are low
opus.1 | low · rename and file 40 scanned documents; worth it: fixed rules, a misfile costs you
opus.2 | medium · draft a cover letter; worth it: a human reads it, tone matters
opus.2 | medium · write outreach to someone you want to meet; worth it: one shot at a first impression
opus.3 | high · find why a pipeline keeps retrying; worth it: cause unknown, spans several files
opus.3 | high · find why a scheduled job fails silently; worth it: no error message, cause unknown
opus.4 | xhigh · build a feature across 20 files; worth it: 30+ min run, rework costs more
opus.5 | max · check a contract clause before signing; worth it: a wrong answer is expensive
opus.5 | max · check a job offer against your visa's work limits; worth it: residence rides on it
fable.1 | low · run a broad research sweep; worth it: only after Opus 5.5 missed sources
fable.2 | medium · plan a multi-step data migration; worth it: close to high, for less
fable.3 | high · design an encrypted data model; worth it: a wrong call means months of rework
fable.4 | xhigh · rebuild a data pipeline overnight; worth it: hours unattended, one review at the end
fable.5 | max · stress-test a research argument; worth it: one answer you'd stake a grade on
luna.1 | Classify 1000 support tickets
luna.2 | Pull fields into a CSV
luna.3 | Reformat to a fixed template
luna.4 | Bulk translate short strings
luna.5 | Not for open ended judgement
sol.1 | Day to day coding work
sol.2 | Summarise a 40 page PDF
sol.3 | Debug across several services
sol.4 | Long multi step research
sol.5 | Six effort levels, none to max
astra.1 | Frontier reasoning, fewest tokens
astra.2 | Deep multi file refactors
astra.3 | Long horizon autonomous runs
astra.4 | Costliest, use when Sol misses
astra.5 | low through max, no none
```

Haiku 4.5 sits at class 1 on the Anthropic ladder so the ring lands on the right rung.

```rubric
@table class
haiku = 1
luna = 1
sonnet = 2
opus = 3
sol = 3
fable = 4
astra = 4
```
