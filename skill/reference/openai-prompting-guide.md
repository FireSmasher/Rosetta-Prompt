# OpenAI prompting guidance, distilled

Primary sources, OpenAI's own official docs, re-verified 24 September 2026:
- https://developers.openai.com/api/docs/guides/latest-model ("Using GPT-6", the one prompting and migration guide for the whole GPT-6 family; `?model=gpt-6-sol` and `?model=gpt-6-luna` return the same text)
- https://developers.openai.com/api/docs/guides/reasoning (reasoning effort levels and defaults)
- https://developers.openai.com/api/docs/guides/prompt-engineering (general prompting principles)
- https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6 (GPT-5.6 guide, 4 Sep 2026; the source of general principles 7 to 10, which OpenAI has not restated for GPT-6)
- https://developers.openai.com/api/docs/models/gpt-6-sol, .../gpt-6-luna, .../gpt-6-astra (pricing, context window, reasoning levels, knowledge cutoff)
- https://developers.openai.com/api/docs/models (the models page: "If you're not sure where to start, use GPT-6 Astra... Choose GPT-6 Sol to balance intelligence and cost, or GPT-6 Luna for cost-sensitive, high-volume workloads.")
- https://developers.openai.com/api/docs/changelog (release dates: GPT-6 Astra 3 September 2026, GPT-6 Sol and Luna 22 September 2026)

Fetch check, 30 September 2026: help.openai.com and developers.openai.com both read through r.jina.ai (`curl -s https://r.jina.ai/<url>`) without a wall; the HTTP 403 seen on 4 September 2026 no longer applies. The GPT-6 sections below were last read in full on 24 September 2026; on 30 September only the models page, the changelog, `guides/latest-model` and the ChatGPT release notes were re-read, for the release changes listed under Model facts.

Confidence: developers.openai.com carries genuine per-model specs and one family-wide prompting guide, all primary. OpenAI publishes no per-tier behaviour split for GPT-6, and says the guide's behaviour notes were observed on Astra. Net: 85% for Astra, 80% for Sol and Luna (GPT-6.1 Sol was released 29 September 2026 and Luna on 22 September, guidance not observed on them directly).

This file grounds `/rosetta-prompt` before rewriting a messy prompt aimed at a GPT-6 model: Luna, Sol or Astra (cheapest to most capable). Which surface offers which model, as of 30 September 2026: the API offers the GPT-6 tiers (`gpt-6-luna`, `gpt-6-sol`, `gpt-6-astra`, plus `gpt-6.1-sol`, see Model facts); GPT-5.6 Sol, Terra and Luna still work there but OpenAI no longer recommends them, and there is no GPT-6 Terra. The ChatGPT app is a different surface with its own model list, set out in the ChatGPT app section below (Chat, Work and Codex differ). Use "General principles" for any target, plus only the section matching the chosen target.

## Model facts

| Model | Context window | Max output | Input / cached / output $ per MTok | Reasoning levels | Released |
|---|---|---|---|---|---|
| GPT-6 Luna | 1,050,000 | 128,000 | $0.10 / $0.01 / $0.50 | `none` to `max`, `medium` default | 22 Sep 2026 |
| GPT-6.1 Sol (current Sol) | 1,050,000 | 128,000 | $2 / $0.10 / $10 | `low` to `max`, `medium` default, no `none` | 29 Sep 2026 |
| GPT-6 Sol (legacy, still served) | 1,050,000 | 128,000 | $2 / $0.20 / $10 | `none` to `max`, `medium` default | 22 Sep 2026 |
| GPT-6 Astra | 1,050,000 (922,000 max input) | 128,000 | $10 / $1 / $50 | `low` to `max`, no `none` | 3 Sep 2026 |

Specs from the three model pages (24 Sep 2026). Changes seen 30 Sep 2026 (changelog, `guides/latest-model`, models page): GPT-6.1 Sol (`gpt-6.1-sol`) was released 29 September 2026, priced at $2 input and $10 output, described as near-Astra performance at lower cost, with `low` to `max` effort and no `none`; the models page now names GPT-6.1 Sol as the balanced choice. This skill's Sol target now means GPT-6.1 Sol (retargeted 30 September 2026, read from the 6.1 Sol model page and `guides/latest-model`); GPT-6 Sol keeps working and is listed above as legacy. Astra also gained Ultrafast mode in the Responses API on 29 September 2026 (US residency only). Knowledge cutoff is published only for Astra (30 April 2026).

## Migration notes

From `guides/latest-model` (30 Sep 2026): GPT-6 prompts should preserve the current effective reasoning effort where supported; Astra and GPT-6.1 Sol have no `none`, so use `low`; an old `minimal` becomes `low` as a start. Remove obsolete or contradictory scaffolding rather than layering new instructions on top. Tool calling needs the Responses API, and with reasoning on, `temperature` and `top_p` must not be set, so never write sampling advice into prompt text. From GPT-5.5 or earlier, prompt caching settings changed. The rest is integration work, out of scope here.

## Cost

Compare cost per task, not per token: OpenAI says Astra reached stronger results with substantially fewer output tokens, so its per-task cost can land below what its price suggests. Luna is the cheapest tier for narrow high-volume work; Sol balances the two. Lowering reasoning effort is the first lever before changing model. Fast mode and Ultrafast mode trade price for speed and are not prompt choices.

## General principles (current GPT models)

1. **Structure a system or developer message in this order:** identity (purpose, tone, goals), instructions (rules, dos and don'ts), examples (diverse input/output pairs), then context (reference material, proprietary data, task-specific info). Put stable content that repeats across calls early, it improves prompt caching.
2. **Reasoning models want a goal and constraints, not a script.** Give a clear objective, real constraints, and an explicit output contract (format, length, what counts as done), let the model work out intermediate steps itself rather than prescribing each one.
3. **Reasoning effort is a real, named parameter**, not a vibe. Up to six levels: `none` (GPT-6 Sol and Luna have it, GPT-6 Astra does not), `low`, `medium` (the default on Sol and Luna), `high`, `xhigh`, `max`. Treat it as a tuning knob, not the primary way to recover a weak prompt: fix the task, constraints, and output format first. The reasoning guide (read 30 Sep 2026) carries a "Best for" table with one line per level, `none` to `max`, written once for the parameter and not per model; the Effort lab quotes it. Before raising effort, check whether the prompt is missing a success criterion, a dependency rule, a tool-routing rule, or a verification loop, that's a more common cause of weak output than insufficient reasoning depth.
4. **For agentic or long-running work,** state explicitly that the model should resolve the whole request before yielding control, breaking it into sub-tasks and checking completeness after each tool call rather than stopping partway. Ask for a brief preamble at meaningful tool-use decisions, not every call; for long/complex work, ask it to track progress with a structured list so nothing gets dropped.
5. **Use Markdown and XML together for structure.** Markdown headers/lists for hierarchy and scanability; XML tags for clean boundaries around distinct content and to carry metadata.
6. **Few-shot examples work the same way as elsewhere:** diverse input/output pairs teach a pattern the model applies to new input, no fine-tuning needed.
7. **A leaner prompt usually beats a longer one.** OpenAI's own measurement on GPT-5.6 (not re-measured for GPT-6): leaner system prompts improved evaluation scores by roughly 10 to 15 percent while cutting tokens by 41 to 66 percent and cost by 33 to 67 percent. Cutting repeated rules, redundant style instructions, non-differentiating examples, and irrelevant tool descriptions is not a trade-off against quality, it tends to improve it. Keep: the user-visible outcome, success criteria and stopping conditions, and any safety, business, evidence, or permission constraint.
8. **Outcome-first prompting.** State the desired outcome, real constraints, available evidence, and the bar for completion, then leave the model room to choose its own path rather than scripting each step. Example shape:
   ```
   Resolve the request end to end.

   Success means:
   - make the decision from available evidence
   - complete any allowed action before responding
   - return the result in the specified shape
   - if required evidence is missing, ask for the smallest missing piece
   ```
9. **Avoid unnecessary absolute rules.** Reserve ALWAYS, NEVER, must, and only for true invariants like safety rules or required fields. Overusing them for ordinary preferences makes the real invariants harder to spot.
10. **A reusable prompt template**, from OpenAI's own guidance, a default shape for a messy prompt complex enough to warrant full structure:
    ```
    Role: [the model's function and context]
    Personality: [tone and collaboration style, be specific, not a vague label like "friendly"]
    Goal: [user-visible outcome]
    Success criteria: [what must be true before the final answer]
    Constraints: [policy, safety, business, evidence, and side-effect limits]
    Tools: [which tools to use, when, and what not to use]
    Output: [sections, length, format, and tone]
    Stop rules: [when to retry, fall back, abstain, ask, or stop]
    ```

### GPT-6 family behaviour (from `guides/latest-model`, 24 Sep 2026)

OpenAI publishes one guide for all three GPT-6 models and says its prompts "address behavior observed with GPT-6 Astra; evaluate them with your chosen model and workload." So these are strong defaults for Astra and reasonable starting points for Sol and Luna, not confirmed Sol or Luna behaviour.

- **Asks for clarification more readily than predecessors.** For an autonomous task, bias toward completion: "You should infer the user's intent and task scope from instructions and prior conversation context. Your job is to bias towards action and carry the user's intended task to completion."
- **Sensitive to instructions in contextual files** (skills, AGENTS.md-style files), and can pause or change direction if those disagree with the user. Make precedence explicit: "The user's instructions take precedence over guidelines provided in a skill."
- **Defaults to lists, tables and Markdown.** For prose, say so: "Default to using clear, concise paragraphs, each developing one main idea."
- **May under-delegate to subagents** when a harness supports them. If parallel delegation is wanted: "If at any point you can parallelize work by delegating tasks to another agent, you should do so using collaboration tools."
- **Writes thorough tests by default**, more than a small change may need. For low-impact changes: "Do not write tests for reversible, low-impact changes that mirror the implementation."
- **Async tool calling, mid-turn steering and mid-conversation effort changes** exist across the family. They are integration features for an app builder, usually not worth mentioning in a single rewritten prompt.

## GPT-6.1 Sol-specific notes

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-6.1-sol, read 30 Sep 2026): $2 input / $0.10 cached input / $10 output per million tokens, cache writes $2.50, prompts over 272K input tokens priced at 2x input and 1.5x output. 1,050,000 token context window, 128,000 max output, knowledge cutoff 30 April 2026. Reasoning levels `low`, `medium` (default), `high`, `xhigh`, `max`; `none` and `minimal` are not supported, so a rewrite must never tell it to skip reasoning. Released 29 September 2026. It supersedes GPT-6 Sol (`gpt-6-sol`, which did support `none`).

**Positioning:** OpenAI's choice "to balance intelligence and cost" and described as "near-Astra performance at a lower cost" for complex coding, computer use and professional work. With no GPT-6 Terra it covers everything from everyday coding and document work to hard multi-step reasoning. When rewriting a Sol prompt for a routine task, flag a lower effort level rather than a different model; name plainly when a task is hard enough that Astra may be worth its price.

**Prompting guidance:** outcome-first and lean, per General principles. The GPT-6 behaviour notes apply as starting points. One pattern carried over from the GPT-5.6 guide, useful when an agentic prompt leaves permission unclear:
```
For requests to answer, explain, review, diagnose, or plan, inspect the relevant materials and
report the result. Do not implement changes unless the request also asks for them.

For requests to change, build, or fix, make the requested in-scope changes and run relevant
non-destructive validation without asking first.

Require confirmation for external writes, destructive actions, or a material expansion of scope.
```

## GPT-6 Luna-specific notes

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-6-luna, 24 Sep 2026): $0.10 input / $0.01 cached input / $0.50 output per million tokens, cache writes $0.125, by far the cheapest GPT-6 model. Same 1,050,000 token context window and 128,000 max output as Sol. Reasoning levels `none` through `max`, `medium` default. Released 22 September 2026.

**Positioning:** "for cost-sensitive, high-volume workloads": classification, extraction, basic transformations, formatting. Well-scoped, mechanical tasks rather than open-ended judgement.

**Prompting guidance:** keep the task narrow and the output contract exact (format, fields, what to do with a missing value). Lean hard into General principles item 7; a heavily scaffolded prompt on a simple extraction task fights against what this model is for.

## GPT-6 Astra-specific notes

Released 3 September 2026 as a general API model (the changelog lists it as "Released", with standard pricing). The most capable GPT-6 model and OpenAI's suggested starting point when unsure.

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-6-astra, 24 Sep 2026): $10 input / $1 cached input / $12.50 cache writes / $50 output per million tokens. OpenAI states it reaches strong results with fewer output tokens, so cost per task can land below what the per-token price suggests. 1,050,000 token context window, 922,000 max input, 128,000 max output. Knowledge cutoff 30 April 2026. Reasoning levels `low`, `medium`, `high`, `xhigh`, `max`, no `none`.

**Notes specific to Astra** (`guides/latest-model`, changelog):
- The GPT-6 family behaviour notes in General principles were observed on Astra itself, so apply them with full confidence here.
- Astra runs asynchronous misalignment monitoring during agent work, which can raise safety alerts or stop a conversation. A prompt for an autonomous run should state its purpose and limits plainly rather than leave intent to inference.
- **Migrating a prompt to Astra:** keep the current reasoning effort as the baseline (Astra has no `none`, so start at `low` if the old prompt used it), and remove obsolete or contradictory scaffolding rather than layering new instructions on top.

## What NOT to over-apply

A short, well-scoped ask doesn't need the full role/personality/goal/constraints/tools/output/stop template, a named reasoning-effort discussion, or an autonomy-boundary block. That structure earns its place on a prompt that's genuinely long, reused, agentic, or judgment-heavy. Match scaffolding to what the task needs; on GPT-5.6, a leaner prompt measurably outperformed a longer one on OpenAI's own evaluations, so cutting is often the improvement, not a compromise.
