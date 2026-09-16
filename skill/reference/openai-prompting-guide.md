# OpenAI prompting guidance, distilled

Primary sources, OpenAI's own official docs, re-verified and expanded 4 September 2026:
- https://developers.openai.com/api/docs/guides/prompt-engineering (general prompting principles)
- https://developers.openai.com/api/docs/guides/reasoning (reasoning effort levels, prompting reasoning models)
- https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6 (GPT-5.6 family prompting guide, applies to Sol, Terra, and Luna alike, no per-tier behavioral split published)
- https://developers.openai.com/api/docs/models/gpt-5.6-sol, .../gpt-5.6-terra, .../gpt-5.6-luna (pricing, context window, reasoning effort levels, knowledge cutoff, per tier)
- https://developers.openai.com/api/docs/guides/latest-model (GPT-6 Astra prompting and migration guidance)
- https://developers.openai.com/api/docs/models/gpt-6-astra (GPT-6 Astra pricing, context window, availability)

Confidence: developers.openai.com carries genuine per-model prompting guidance, pricing, and specs, all primary; openai.com/index/* and help.openai.com return HTTP 403 (still blocked, checked 4 September 2026), so they are not usable sources. No documented behavioral split between Sol, Terra, and Luna exists anywhere, including OpenAI's own docs, since their family-wide guide explicitly covers all three without differentiating. That is a real gap in what OpenAI has published, not a gap in this research. Net: 85% for Sol, Terra, and Luna, primary sourced on everything except tier-to-tier behavioral differentiation, which nobody has published. GPT-6 Astra is new (announced 3 September 2026, limited Trusted Access rollout) but thoroughly documented with concrete guidance and sample prompt text: 85% as well, the discount being it is one day old with no independent field verification, not a sourcing weakness.

This file grounds `/rosetta-prompt` before rewriting a messy prompt aimed at a ChatGPT model: GPT-5.6 Sol, Terra, or Luna (released 9 July 2026, still current), or GPT-6 Astra (announced 3 September 2026, rolling out, not a replacement for GPT-5.6, both exist side by side). Use "General principles" for any target, plus only the section matching the chosen target.

## General principles (current GPT models)

1. **Structure a system or developer message in this order:** identity (purpose, tone, goals), instructions (rules, dos and don'ts), examples (diverse input/output pairs), then context (reference material, proprietary data, task-specific info). Put stable content that repeats across calls early, it improves prompt caching.
2. **Reasoning models want a goal and constraints, not a script.** Give a clear objective, real constraints, and an explicit output contract (format, length, what counts as done), let the model work out intermediate steps itself rather than prescribing each one.
3. **Reasoning effort is a real, named parameter**, not a vibe. Up to six levels: `none` (not on every model, GPT-6 Astra dropped it), `low`, `medium` (common default), `high`, `xhigh`, `max`. Treat it as a tuning knob, not the primary way to recover a weak prompt: fix the task, constraints, and output format first. Before raising effort, check whether the prompt is missing a success criterion, a dependency rule, a tool-routing rule, or a verification loop, that's a more common cause of weak output than insufficient reasoning depth.
4. **For agentic or long-running work,** state explicitly that the model should resolve the whole request before yielding control, breaking it into sub-tasks and checking completeness after each tool call rather than stopping partway. Ask for a brief preamble at meaningful tool-use decisions, not every call; for long/complex work, ask it to track progress with a structured list so nothing gets dropped.
5. **Use Markdown and XML together for structure.** Markdown headers/lists for hierarchy and scanability; XML tags for clean boundaries around distinct content and to carry metadata.
6. **Few-shot examples work the same way as elsewhere:** diverse input/output pairs teach a pattern the model applies to new input, no fine-tuning needed.
7. **A leaner prompt usually beats a longer one.** OpenAI's own measurement on GPT-5.6: leaner system prompts improved evaluation scores by roughly 10 to 15 percent while cutting tokens by 41 to 66 percent and cost by 33 to 67 percent. Cutting repeated rules, redundant style instructions, non-differentiating examples, and irrelevant tool descriptions is not a trade-off against quality, it tends to improve it. Keep: the user-visible outcome, success criteria and stopping conditions, and any safety, business, evidence, or permission constraint.
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

## Sol-specific notes

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-5.6-sol): $4 input / $0.40 cached input / $20 output per million tokens (promotional pricing through 21 November 2026; inputs past 272k tokens incur a 2x input, 1.5x output multiplier). 1,050,000 token context window, 922,000 max input, 128,000 max output. Knowledge cutoff 16 February 2026. Supports all six reasoning effort levels, `medium` default.

**Positioning:** frontier capability, the heavyweight reasoning tier for long-horizon agentic work and genuinely hard problems. When rewriting a Sol prompt, name plainly that the task needs its strongest reasoning, so the caller doesn't reach for it out of habit on something Terra would handle for a fraction of the cost.

**Prompting guidance:** use the outcome-first, leaner-prompt approach from General principles. Two patterns worth applying directly:

*Autonomy boundaries*, since Sol will otherwise sometimes over-ask or under-ask for permission:
```
For requests to answer, explain, review, diagnose, or plan, inspect the relevant materials and
report the result. Do not implement changes unless the request also asks for them.

For requests to change, build, or fix, make the requested in-scope changes and run relevant
non-destructive validation without asking first.

Require confirmation for external writes, destructive actions, or a material expansion of scope.
```

*Conciseness*: GPT-5.6 defaults to more concise output than GPT-5.5. A blanket "be concise" instruction carried over from an older prompt may no longer do anything useful, check whether it's still needed.

## Terra-specific notes

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-5.6-terra): $2 input / $0.20 cached input / $12 output per million tokens (same 272k-token multiplier rule as Sol). Same 1,050,000 token context window, six reasoning effort levels, `medium` default, 16 February 2026 knowledge cutoff.

**Positioning:** the balanced, general-purpose middle tier, the default choice for most production and developer work, standard coding, document processing, and data analysis, everyday work that doesn't need Sol's depth. A Terra-aimed prompt usually needs no special hedging; if the task turns out unusually hard, naming that plainly (so the caller can consider Sol instead) is more useful than compensating in the prompt text.

**Prompting guidance:** same outcome-first, leaner-prompt approach as Sol. The reusable template in General principles item 10 is a good default for a Terra-targeted rewrite of real complexity; skip it for a short, simple ask.

## Luna-specific notes

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-5.6-luna): $0.20 input / $0.02 cached input / $1.20 output per million tokens, by far the cheapest of the three. Same context window, reasoning levels, and knowledge cutoff as Sol/Terra.

**Positioning:** fastest, most affordable tier, for efficient high-volume work: classification, extraction, basic transformations, formatting. Well-scoped, mechanical tasks rather than open-ended reasoning. Keep the task narrow and the output contract explicit (exact format, exact fields), that's what this tier is good at, rather than open-ended judgment better suited to Terra or Sol.

**Prompting guidance:** outcome-first still applies, but lean hard into item 7 (leaner prompt) and a tight output contract. A verbose, heavily scaffolded prompt on a simple extraction task fights against what this tier is built for.

## GPT-6 Astra-specific notes

Announced 3 September 2026, rolling out to enterprises in OpenAI's Trusted Access Program, broader plan/API access "coming soon." Not a replacement for GPT-5.6 Sol, Terra, or Luna, all exist side by side. A single model, no tiers.

**Pricing and specs** (developers.openai.com/api/docs/models/gpt-6-astra): $10 input / $1 cached input / $12.50 cache writes / $50 output per million tokens, higher per-token than Sol, but OpenAI states it achieves strong results using fewer output tokens, so estimated total cost per task can still come out lower. 1,050,000 token context window, 922,000 max input, 128,000 max output. Supports `low`, `medium`, `high`, `xhigh`, `max`, not `none`.

**Behavioral differences worth encoding into a rewritten prompt** (developers.openai.com/api/docs/guides/latest-model):

- **Asks for clarification more readily than predecessors.** For an autonomous task, bias toward completion: "You should infer the user's intent and task scope from instructions and prior conversation context. Your job is to bias towards action and carry the user's intended task to completion."
- **More sensitive to instructions in contextual files** (skills, AGENTS.md-style files), can pause or change direction if those disagree with the user's own instructions. Make precedence explicit: "The user's instructions take precedence over guidelines provided in a skill."
- **Defaults to lists, tables, and Markdown.** For prose, say so: "Default to using clear, concise paragraphs, each developing one main idea."
- **May under-delegate to subagents** when a harness supports them. If parallel delegation is wanted: "If at any point you can parallelize work by delegating tasks to another agent, you should do so using collaboration tools."
- **Writes thorough tests by default**, more than a small change may need. For low-impact changes: "Do not write tests for reversible, low-impact changes that mirror the implementation."
- **Supports async tool calling** (continuing to reason or calling other tools while a slow tool runs) and mid-turn steering, integration-level features more relevant to an app builder than a single rewritten prompt, worth knowing about but usually not worth mentioning in the prompt itself.
- **Migration note:** when moving a prompt from an earlier model to Astra, preserve the current reasoning effort as a baseline (Astra dropped `none`, start at `low` if migrating from a prompt that used it), and remove obsolete or contradictory scaffolding rather than layering new instructions on top of old ones.

## What NOT to over-apply

A short, well-scoped ask doesn't need the full role/personality/goal/constraints/tools/output/stop template, a named reasoning-effort discussion, or an autonomy-boundary block. That structure earns its place on a prompt that's genuinely long, reused, agentic, or judgment-heavy. Match scaffolding to what the task needs; for GPT-5.6 specifically, a leaner prompt measurably outperforms a longer one on OpenAI's own evaluations, so cutting is often the improvement, not a compromise.
