# Model selection guidance, distilled

Last verified 30 September 2026. Sections were sourced on different dates: "Effort levels" and
"The order of levers" on 5 September (the lever order corrected 24 September), the ladder table
on 24 and 25 September, the Sonnet 5.5 row on 30 September. Confidence 95% for the Anthropic
material: every directive in "The order of levers" and "Effort levels" is a quote or a close
paraphrase of a primary Anthropic document, each listed under Sources. Confidence 60% for the numbers in the
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
  https://platform.claude.com/docs/en/models/overview
- Prices below are the Anthropic first-party API rates from the models overview page, last
  read 24 September 2026 (the same rates the Anthropic prompting guide cites). Partner
  platforms (Bedrock, Vertex) price separately.

## The order of levers

This is the part worth reading twice, because the intuitive order is the wrong one.
Anthropic's guidance is that **effort is the first lever and model is the second**.

> "Sweep effort on your current model first. It is the cheapest experiment on this page,
> and most workloads end there."

> "If the sweep shows a gap, price the stronger model alone at low effort. That is the
> number an advisor pairing has to beat."

> "For most agent workloads, start with Claude Fable 5.1 at `low` effort and raise effort
> where it misses." (Superseded on 24 September 2026: Anthropic now says to start agent work
> on Claude Opus 5.5 at `medium` and move to Fable 5.1 only when evals at higher effort still
> fall short. See the ladder table below.)

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
- **Sonnet 5.5** (30 Sep 2026): defaults to `high`, levels recalibrated against Sonnet 5, so re-sweep. The quotes below are from the Sonnet 5 read of 16 Sep and are not restated for 5.5.  `medium` is the "Cost-saving step-down from the default.
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

Lowest to highest cost and capability: Haiku 4.5, Sonnet 5.5, Opus 5.5, Fable 5.1.

| Model | Input $/1M | Output $/1M | Documented positioning |
|---|---|---|---|
| Claude Haiku 4.5 | $1 | $5 | "It fits high-volume work with checkable outputs, not long agentic loops." |
| Claude Sonnet 5.5 | $2 | $10 | Mid tier. Effort levels recalibrated against Sonnet 5, so re-sweep. Anthropic publishes no Sonnet 5.5 cost-per-task figure. |
| Claude Opus 5.5 | $4 | $20 | Anthropic's default for most workloads. At `medium` it matched Fable 5.1 on the SWE-bench Pro subset for about a fifth of the cost per solved task. |
| Claude Fable 5.1 | $10 | $50 | Frontier. "Use Claude Fable 5.1 for demanding reasoning and long-horizon agentic work, or when your evals on Claude Opus 5.5 at higher effort still fall short." (24 Sep 2026; until then Anthropic advised starting agent work on Fable 5.1 at `low`.) |

Haiku 4.5 became a rewrite target on 16 September 2026 (the app was renamed from
Translate Prompt to Rosetta Prompt the same day), so class 1 on the Anthropic ladder now
recommends `haiku`. Until then `sonnet` occupied both of the two lowest classes.

GPT tiers, from `openai-prompting-guide.md` in this folder, not from Anthropic:

| Model | Input $/1M | Output $/1M | Positioning |
|---|---|---|---|
| GPT-6 Luna | $0.10 | $0.50 | "For cost-sensitive, high-volume workloads." Classification, extraction, formatting. |
| GPT-6.1 Sol | $2 | $10 | "To balance intelligence and cost", "near-Astra performance at a lower cost" (30 Sep 2026). Covers both middle classes, because GPT-6 has no Terra. Replaced GPT-6 Sol on 29 Sep 2026. |
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

- `lab`: the example job for every model and effort level, shown in the guide panel and the
  Effort lab. Use jobs you really run, so each effort level reads as something you recognise.
  Unlike the other tables it merges row by row, so a level you leave out keeps the shipped job.
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

House style switches. `no_long_dash = on` makes the app tell the rewriter never to use an em or
en dash, and makes `check_rewrite.py` reject one (`punct.long_dash`). It is one writer's
preference, so it ships off; set `on` in `model-selection.local.md` to keep it on your machine only.

```rubric
@table style
no_long_dash = off
```

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
wrong answer | debugging
wrong result | debugging
wrong output | debugging
wrong total | debugging
wrong number | debugging
went wrong | debugging
goes wrong | debugging
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
and heavy lists are matched, so "schema contracts" no longer floors a prompt at Opus (found 16
September 2026), "contractions" does not read as a contract, and "provenance" does not read as
"prove" (both found 30 September 2026). The bare word "wrong" is no longer a debugging signal
on its own, since "what is wrong with my essay intro" is a critique, not a bug; the phrases
"wrong answer", "wrong total", "went wrong" and similar still are.

```rubric
@table not-stakes
contraction
provenance
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
haiku | Cheapest Claude model, $1 in / $5 out per million. High-volume work with checkable outputs; no effort setting.
sonnet | Mid tier, $2 in / $10 out per million. Everyday coding and agent work; effort levels recalibrated, so re-sweep.
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
sonnet | Sonnet 5.5
opus | Opus 5.5
fable | Fable 5.1
luna | Luna
sol | Sol 6.1
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

Every rung of the ladder has an example job for every effort level the maker documents, in the
`lab` table, keyed `model.level`. Each row is `job ;; why it is worth it`. The shipped rows are
neutral everyday jobs. Your own, from your own week, go in `model-selection.local.md` (see "Your own
data"), which overrides them row by row and never leaves your machine. The hover block in the
guide panel shows one line per level from this table, and the Effort lab (the button under the
ladder) shows the full card for one level at a time: the job, what it is worth, a quote or fact from
the maker's own page with its link, what goes wrong there, and a cost meter.

The sourced half is public and is not meant to be overridden: `lab-fact` is the maker's own sentence
for that level, `lab-break` is the maker's own caveat for it (a level with no published caveat has
no row, and the card says so rather than inventing one), `lab-cost` is Anthropic's measured cost
of Opus 5.5 at each effort level against `high`, and `lab-race` is Anthropic's Haiku 4.5 against
Opus 5.5 figure. Every quote was checked against the fetched maker page on 30 September 2026, and
every link must land on the maker's own domain (the self test enforces that).

Levels are what each target really has, from `lab-levels`: Claude Fable, Opus and Sonnet have
`low` to `max`. Haiku 4.5 has none. GPT-6 Luna has `none` to `max`, GPT-6.1 Sol and Astra `low` to
`max`. The Gemini 3.8 Flash row uses its three thinking levels. The ChatGPT app uses its model
picker (Instant, Medium, High, Extra High, Pro Standard, Pro Extended), set by the user. The Claude
app and Undermind have no effort setting; the Claude app has one row, and Undermind has its two
depths, quick and deep search. OpenAI's effort table is stated once for the parameter, so the same
level sentence appears under Luna, Sol and Astra where the model page adds nothing level specific.
(Until 30 September 2026 this file said OpenAI publishes no per level guidance. The reasoning guide
has carried a per level table, so that statement was wrong and is corrected here.)

```rubric
@table lab-levels
fable = low, medium, high, xhigh, max
opus = low, medium, high, xhigh, max
sonnet = low, medium, high, xhigh, max
haiku = none
luna = none, low, medium, high, xhigh, max
sol = low, medium, high, xhigh, max
astra = low, medium, high, xhigh, max
claudeapp = app
chatgpt = instant, medium, high, extrahigh, prostandard, proextended
gemini = low, medium, high
undermind = quick, deep
```

```rubric
@table lab-level-label
none | none
app | in a project
instant | Instant
extrahigh | Extra High
prostandard | Pro Standard
proextended | Pro Extended
quick | Quick search
deep | Deep search
```

```rubric
@table lab-fact
fable.low | Claude Fable 5.1 at low effort solved 88.6% of tasks for $0.54 per solved task, against 77.4% for $0.84 from Claude Sonnet 5 at its default ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
fable.medium | medium matched the default's accuracy at about 70% to 87% of its cost ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
fable.high | Start with high, the default. ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
fable.xhigh | Step up to xhigh or max for the most capability-sensitive agentic and coding work ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
fable.max | Absolute maximum capability with no constraints on token spending. ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
opus.low | on several coding evaluations low comes close to it at much lower cost ;; prompting-claude-opus-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
opus.medium | Claude Opus 5.5 at medium matches or exceeds Claude Opus 5 at high on coding and knowledge-work evaluations ;; prompting-claude-opus-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
opus.high | Spends as many tokens as the task needs for excellent results. ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
opus.xhigh | Long-running agentic and coding tasks (over 30 minutes) with token budgets in the millions ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
opus.max | Claude Opus 5.5 completed noticeably more of them correctly with this instruction, at both medium and max effort ;; prompting-claude-opus-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
sonnet.low | At low, it skips thinking on most simple requests. ;; prompting-claude-sonnet-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5
sonnet.medium | Balanced approach with moderate token savings. ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
sonnet.high | Complex reasoning, difficult coding problems, agentic tasks ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
sonnet.xhigh | Extended capability for long-horizon work. ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
sonnet.max | Tasks requiring the deepest possible reasoning and most thorough analysis ;; build-with-claude/effort ;; https://platform.claude.com/docs/en/build-with-claude/effort
haiku.none | at about a fifth of Claude Opus 5.5's cost per question, with 63% accuracy compared with 92% for Opus 5.5 ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
luna.none | Common use cases include voice, fast information retrieval, and classification. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.low | Common use cases include data analysis, drafting, execution-oriented coding, and customer support / chat assistant workflows. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.medium | GPT-6 Luna is our most efficient model for focused, high-volume tasks. ;; models/gpt-6-luna ;; https://developers.openai.com/api/docs/models/gpt-6-luna
luna.high | Hard reasoning, complex debugging, deep planning, and high-value tasks where quality and intelligence matters more than latency. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.xhigh | Deep research, asynchronous workflows and agentic tasks that require long runs. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.max | Maximum reasoning for your most complex tasks. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.low | Efficient reasoning with a modest latency increase. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.medium | GPT-6.1 Sol delivers near-Astra performance at a lower cost for complex coding, computer use, and professional work. ;; models/gpt-6.1-sol ;; https://developers.openai.com/api/docs/models/gpt-6.1-sol
sol.high | Hard reasoning, complex debugging, deep planning, and high-value tasks where quality and intelligence matters more than latency. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.xhigh | Common use cases include security and code review, enterprise productivity, deeper research tasks, and challenging coding workflows. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.max | Maximum reasoning for your most complex tasks. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
astra.low | GPT-6 Astra and GPT-6.1 Sol do not support none; use low instead. ;; guides/latest-model ;; https://developers.openai.com/api/docs/guides/latest-model
astra.medium | GPT-6 Astra is our most capable model for the most demanding work. Use it for complex reasoning, coding, computer use, research, and document creation. ;; models/gpt-6-astra ;; https://developers.openai.com/api/docs/models/gpt-6-astra
astra.high | Recommended for complex workflows and agentic tasks. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
astra.xhigh | Deep research, asynchronous workflows and agentic tasks that require long runs. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
astra.max | Maximum reasoning for your most complex tasks. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
claudeapp.app | Project instructions help Claude understand the specific context and requirements for a particular project. These instructions only apply to chats within that project. ;; support: personalization features ;; https://support.claude.com/en/articles/10185728-understanding-claude-s-personalization-features
chatgpt.instant | Users have the ability to decide whether Instant auto-switches to Medium for higher reasoning when required. ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.medium | Thinking Standard is now Medium ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.high | Thinking Extended is now High ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.extrahigh | Thinking Heavy is now Extra High. ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.prostandard | Pro Standard and Pro Extended remain available under Pro. ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.proextended | Pro Standard and Pro Extended remain available under Pro. ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
gemini.low | Simple tasks: Use minimal or low thinking for fact retrieval or classification ;; gemini-api/docs/thinking ;; https://ai.google.dev/gemini-api/docs/thinking
gemini.medium | Moderate tasks: Use default thinking for comparing concepts or creative reasoning ;; gemini-api/docs/thinking ;; https://ai.google.dev/gemini-api/docs/thinking
gemini.high | Complex tasks: Use maximum thinking for advanced coding, math, or multi-step planning ;; gemini-api/docs/thinking ;; https://ai.google.dev/gemini-api/docs/thinking
undermind.quick | search_papers is your main workhorse. It performs direct semantic search against titles and abstracts. ;; Undermind tool orientation ;; https://www.undermind.ai/mcp
undermind.deep | Use it for self-contained queries that demand comprehensive, carefully ranked results ;; Undermind tool orientation ;; https://www.undermind.ai/mcp
```

```rubric
@table lab-break
fable.low | at low, Claude Fable 5.1 calls search and retrieval tools less often ;; prompting-claude-fable-5-1 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
fable.xhigh | Long deliverables at xhigh or max effort take a long time or hit max_tokens ;; prompting-claude-fable-5-1 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
fable.max | it may draft much of that deliverable in its thinking and then write it out again as the reply, which means a longer wait and more output tokens ;; prompting-claude-fable-5-1 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
opus.low | With Claude Opus 5.5 at low, 13% of tasks failed ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
opus.medium | Claude Opus 5.5 scored about 2.5 points lower at its default, medium ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
opus.high | At a given level, Claude Opus 5.5 tends to think more per turn than Claude Opus 5 ;; prompting-claude-opus-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
opus.xhigh | xhigh scored about 1.4 points higher for 2.5 times the cost of high ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
opus.max | especially at xhigh and max. If you keep the effort value you set for Claude Opus 5, expect longer turns and more output tokens. ;; prompting-claude-opus-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5
sonnet.low | At low effort, though, it sometimes reports a change as done without running a check that exercises it. ;; prompting-claude-sonnet-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5
sonnet.xhigh | At these levels the model is especially thorough. After it finishes a task, it can start its own rounds of review and verification ;; prompting-claude-sonnet-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5
sonnet.max | At these levels the model is especially thorough. After it finishes a task, it can start its own rounds of review and verification ;; prompting-claude-sonnet-5-5 ;; https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5
haiku.none | fell much further behind on long coding tasks. It fits high-volume work with checkable outputs, not long agentic loops. ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
luna.none | Latency-critical tasks that do not benefit from any reasoning or multi-chained tool calls. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.high | Depending on the complexity of the task, evaluate both medium and high. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.xhigh | Only use when your evals show a clear benefit that justifies the extra latency and cost. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
luna.max | If you are currently using xhigh, evaluate if max results in stronger performance ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.medium | Compare it with Astra on your tasks to assess the tradeoff between quality and cost. ;; models/gpt-6.1-sol ;; https://developers.openai.com/api/docs/models/gpt-6.1-sol
sol.high | Depending on the complexity of the task, evaluate both medium and high. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.xhigh | Only use when your evals show a clear benefit that justifies the extra latency and cost. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
sol.max | If you are currently using xhigh, evaluate if max results in stronger performance ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
astra.high | Depending on the complexity of the task, evaluate both medium and high. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
astra.xhigh | Only use when your evals show a clear benefit that justifies the extra latency and cost. ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
astra.max | If you are currently using xhigh, evaluate if max results in stronger performance ;; guides/reasoning (effort table) ;; https://developers.openai.com/api/docs/guides/reasoning
claudeapp.app | Context is not shared across chats within a project unless the information is added into the project knowledge base. ;; support: create and manage projects ;; https://support.claude.com/en/articles/9519177-how-can-i-create-and-manage-projects
chatgpt.instant | We're retiring automatic switching from Instant to Thinking (reasoning) for ChatGPT Plus and Pro users globally. ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.extrahigh | Extra High [Pro plans only] ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.prostandard | Pro Standard [Pro plans only] ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
chatgpt.proextended | Pro Extended [Pro plans only] ;; ChatGPT release notes ;; https://help.openai.com/en/articles/6825453-chatgpt-release-notes
gemini.low | Gemini 3.8 Flash can use more tokens on longer running and complex tasks, by design. ;; gemini-api/docs/latest-model ;; https://ai.google.dev/gemini-api/docs/latest-model
gemini.high | If the model hits this limit while reasoning, it stops generating with status "incomplete" and returns truncated or empty output (while still billing for any thinking tokens generated). ;; gemini-api/docs/thinking ;; https://ai.google.dev/gemini-api/docs/thinking
undermind.quick | A narrow or empty search_papers result does not mean the relevant literature is absent. ;; Undermind tool orientation ;; https://www.undermind.ai/mcp
undermind.deep | for which paper relevance can be evaluated without reading the full texts. It generally takes 2-5 minutes. ;; Undermind tool orientation ;; https://www.undermind.ai/mcp
```

```rubric
@table lab-cost
opus.low | 33 ;; about a third of the cost of high, about 8 points lower on SWE-bench Pro
opus.medium | 70 ;; about 70% of the cost of high, about 2.5 points lower on SWE-bench Pro
opus.high | 100 ;; the baseline
opus.xhigh | 250 ;; 2.5 times the cost of high, about 1.4 points higher on SWE-bench Pro
source | scored about 2.5 points lower at its default, medium, for about 70% of the cost, and about 8 points lower at low for about a third of the cost; xhigh scored about 1.4 points higher for 2.5 times the cost of high ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
```

```rubric
@table lab-race
accuracy | 63 ;; 92
cost | 20 ;; 100
source | at about a fifth of Claude Opus 5.5's cost per question, with 63% accuracy compared with 92% for Opus 5.5 ;; optimizing-for-cost-and-intelligence ;; https://platform.claude.com/docs/en/about-claude/models/optimizing-for-cost-and-intelligence
```

```rubric
@table lab
fable.low | Sweep fifty job boards for roles nobody advertises ;; a cheap wide sweep, and you read the shortlist
fable.medium | Sort sixty papers into themes before a supervisor meeting ;; near high quality for less when a cheaper model loses the thread
fable.high | Redesign how three of your tools hand work to each other ;; several things depend on the answer
fable.xhigh | Rebuild a data pipeline overnight while you sleep ;; hours unattended, one review in the morning
fable.max | Stress-test your argument the night before submitting ;; the one answer you would stake a grade on
opus.low | File forty scanned documents by fixed rules ;; fixed rules, and a misfile costs you later
opus.medium | Write a first note to someone who could open a door ;; one shot at a first impression
opus.high | Find why a scheduled job dies silently at night ;; a silent failure, the cause could be anywhere
opus.xhigh | Wire an application flow end to end, submit button included ;; a bad submit is public
opus.max | Check a job offer against the limits of your permit ;; a wrong answer puts your residence at risk
sonnet.low | Sort a week of time blocks into categories ;; you glance over the result anyway
sonnet.medium | Turn a training week into a shopping list at your calories ;; routine, and you check the numbers
sonnet.high | Fix the web route that returns errors on empty rows ;; one file, and a test tells you fast
sonnet.xhigh | Build a waitlist page while you are at the gym ;; many small steps, nothing irreversible
sonnet.max | One last pass at a stubborn bug before you pay for Opus ;; cheaper than Opus if it lands
haiku.none | Label a backlog of thousands of emails by sender ;; checkable output, and a wrong label costs nothing
luna.none | Turn a shop receipt into rows for a spending log ;; speed beats thought when the rows are fixed
luna.low | Tag 300 job postings as part time or full time ;; a quick, cheap sort
luna.medium | Pull dates and amounts out of a month of bank exports ;; cheap, and you check the totals
luna.high | Reconcile a bank export against a workbook and explain the gaps ;; rarely, Sol is the next rung
luna.xhigh | Find near duplicates across 500 tags ;; only if your evals show a gain
luna.max | Re-check a finished relabel, label by label ;; usually a waste, try Sol first
sol.low | Fix a typo level bug in a small script ;; a quick loop
sol.medium | Summarise a 40 page reading before class ;; the default, balanced
sol.high | Debug why a chain of steps breaks across three files ;; complex debugging, deep planning
sol.xhigh | Review your own diff for security holes before you push ;; a public repo is forever
sol.max | Plan a storage migration with every edge case ;; only if xhigh missed something
astra.low | Sanity-check a meal plan against a protein target ;; rarely, Astra price for a simple job
astra.medium | Plan a move across six periods in two cities ;; frontier model at its default effort
astra.high | Pressure-test a permit plan against its conditions ;; a wrong answer costs residence
astra.xhigh | Audit a whole register for contradictions overnight ;; a long run with one review
astra.max | Decide the next city with every assumption attacked ;; it decides where you live
claudeapp.app | Put a project's method rules into its instructions once ;; every chat in that project starts informed
chatgpt.instant | Ask what a term on a payslip means ;; quick, and a wrong answer is cheap
chatgpt.medium | Draft a short email to a parent: only the ask ;; balanced, and you edit it anyway
chatgpt.high | Read a lease clause for what it lets the landlord do ;; a hard read, a wrong read costs a deposit
chatgpt.extrahigh | Sanity-check a training block against your health flags ;; Pro plans only, use it when the answer touches your body
chatgpt.prostandard | Read a 30 page letter and list every deadline ;; a missed deadline costs more than the wait
chatgpt.proextended | Lay out a full launch plan with its risks in one sitting ;; the slowest setting, for the plan you would argue about for a week
gemini.low | Classify a pile of time labels ;; retrieval grade work
gemini.medium | Compare two hoodie suppliers side by side ;; moderate work, the default
gemini.high | Work out unit economics with returns and VAT ;; multi step planning
undermind.quick | Check what exists on graduates moving into work ;; a few top results in seconds
undermind.deep | Find every paper on post-study retention for a thesis ;; 2 to 5 minutes, one well-aimed search usually covers it
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
