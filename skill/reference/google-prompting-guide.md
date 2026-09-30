# Google Gemini prompting guidance, distilled

Primary sources, Google's own official docs, read 30 September 2026:
- https://ai.google.dev/gemini-api/docs/prompting-strategies (prompt design, with a "Gemini 3" section; Jina header shows it published 17 September 2026; some examples still use gemini-2.5-flash)
- https://ai.google.dev/gemini-api/docs/models (models overview, updated 24 September 2026)
- https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash (spec page, updated 2 September 2026)
- https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite (spec page, updated 30 July 2026)
- https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview (spec page, updated 18 August 2026)
- https://deepmind.google/models/model-cards/gemini-3-5-flash-lite/ (model card, published 21 July 2026)
- https://ai.google.dev/gemini-api/docs/latest-model ("What's new in Gemini 3.8 Flash", migration checklist, updated 23 September 2026)
- https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.5 (thinking level meanings, updated 23 September 2026)
- https://ai.google.dev/gemini-api/docs/gemini-3 (Gemini 3 guide, updated 23 September 2026)
- https://ai.google.dev/gemini-api/docs/thinking (thinking levels, updated 25 September 2026)
- https://ai.google.dev/gemini-api/docs/deep-research (Deep Research agent, updated 23 September 2026)
- https://ai.google.dev/gemini-api/docs/pricing (updated 24 September 2026)
- https://ai.google.dev/gemini-api/docs/changelog (updated 23 September 2026)
- https://support.google.com/gemini/answer/14517446 (Gemini app models, no date shown)
- https://support.google.com/gemini/answer/15719111 (Deep Research in the Gemini app, no date shown)
- https://gemini.google/subscriptions/ (plans, no date shown)

Confidence: per target, in the app. Flash 82%, Pro 75%, Flash-Lite 70%, Deep Research 72%, extended thinking 50%. All pages are first party and dated within seven weeks. Not found: any Flash-Lite specific prompting page (the Flash-Lite notes below are marked as inference where they are), any definition of the app's Thinking mode or Deep Think levels, app quotas for Deep Research, a knowledge cutoff for 3.8 Flash or 3.1 Pro, and any independent verification. A blog.google page teaser dated 30 September 2026 announces "Gemini 4 Argon ... rolling out soon"; it is not on the models page, so it is not a target yet.

This file grounds `/rosetta-prompt` before rewriting a messy prompt aimed at Google Gemini. Five targets share the General principles: three models (Gemini 3.5 Flash-Lite, 3.8 Flash, 3.1 Pro) and two Gemini functions that work on top of the models, extended thinking and Deep Research. A function is not a model: write the request for the function, and expect it to run on whichever model the Gemini app or API gives it. Use "General principles" plus the one notes section for the target.

## Model facts

`gemini-3.8-flash` (models/gemini-3.8-flash, latest-model, pricing, 30 Sep 2026): GA 2 September 2026, the newest general text model. 1,048,576 token input limit, 65,536 max output. Input text, image, video, audio and PDF, output text. Thinking levels `low`, `medium` (default) and `high`, no `minimal`.

`gemini-3.5-flash-lite` (models/gemini-3.5-flash-lite, model card, 30 Sep 2026): stable, GA 21 July 2026, based on 3.1 Flash-Lite. Same 1,048,576 and 65,536 limits. Thinking levels `minimal` (default), `low`, `medium`, `high`. Knowledge cutoff March 2026 per its model card. There is no 3.8 Flash-Lite text model; `gemini-3.8-flash-lite-tts` is text to speech only. The Gemini app lists "Flash-Lite", "Flash" and "Pro" without version numbers, so which version backs each is unconfirmed.

`gemini-3.1-pro-preview` (models/gemini-3.1-pro-preview, changelog, 30 Sep 2026): PREVIEW, released 19 February 2026, the newest Pro. Same limits. Thinking levels `low`, `medium`, `high` (default, dynamic), no `minimal`. `thinking_level` and the older `thinking_budget` in one request return a 400 error. Keep temperature at 1.0. Google's Pro page says "3.5 Pro coming soon"; a `gemini-3.8-pro` string appears only in code samples and is unconfirmed.

Gemini app plans (gemini.google/subscriptions, 30 Sep 2026, German page, euro prices): Free has varying access to 3.1 Pro, AI Plus 4,99, AI Pro 21,99 (3.1 Pro, Deep Research, 1 million token context), AI Ultra 99,99 and 219,99 (higher limits, Deep Think).

## Migration notes

From the `latest-model` migration checklist (30 Sep 2026): temperature, top_p and top_k are API settings to strip for Gemini 3.x models, so never write sampling advice into prompt text. 3.7 Flash remains fully supported. No other prompt-text changes are published.

## Cost

Price per million tokens (pricing, 24 Sep 2026), output price including thinking tokens. 3.8 Flash: introductory $0.75 input and $3.75 output through 31 December 2026, then $1.50 and $7.50. 3.5 Flash-Lite: $0.30 and $2.50. 3.1 Pro: $2 and $12 for prompts up to 200k tokens, $4 and $18 above, no free tier. Deep Research agent: about $1 to $3 a task, Max about $3 to $7 (estimates on its page, subject to change). 3.8 Flash "can use more tokens on longer running and complex tasks, by design"; lowering the thinking level is the stated remedy.

## General principles (current Gemini models)

1. **Be precise and direct.** Gemini 3 models respond best to prompts that are direct, well-structured and clearly define the task and any constraints. Drop unnecessary or persuasive language.
2. **Use one delimiter style per prompt.** XML-style tags or Markdown headings, not a mix.
3. **Put role, behavioural constraints and output format first**, in the system instruction or at the very start of the user prompt.
4. **For large context, supply the context first and the question last**, bridged with a phrase such as "Based on the information above...".
5. **Define ambiguous terms and parameters explicitly.**
6. **Default answers are direct and efficient.** Ask explicitly for a chattier or more detailed answer when one is wanted.
7. **Few-shot examples help, with identical formatting across them.** The page recommends always including them and warns that too many can cause overfitting. This advice predates Gemini 3, so keep them few.
8. **Do not script chain of thought.** The models think internally. Set the thinking level, or write "Think very hard before answering" when a nudge is needed, rather than demanding visible step lists.
9. **Match thinking to the task.** `minimal` or `low` for retrieval and classification, the default for moderate work, `high` for advanced coding, maths and multi-step planning.
10. **Supply needed facts as context**, and use Google Search grounding or code execution for recent facts or arithmetic, rather than trusting recall.

## Gemini 3.8 Flash notes

**Positioning:** Google calls 3.8 Flash "engineered for long-horizon software engineering, autonomous agents, and complex enterprise workflows". Medium is the default and is "recommended for complex code and agentic use cases". Low suits "latency-critical tasks like incident response pipelines, real-time chat, writing drafts, and fast data analysis"; high suits deep reasoning and mathematics.

**Prompting guidance:** the Gemini 3 section of the prompting page offers three optional system-instruction clauses tuned for Gemini 3 Flash: a current-date accuracy line, a knowledge-cutoff line and a strict-grounding line. They are meant to be edited, not pasted into every prompt, and the cutoff clause quotes January 2025, which conflicts with the March 2026 cutoff on the Flash-Lite card, so never paste it as fact. Planning is internal, so a rewrite should state the goal and constraints, not a procedure. Lower the thinking level for everyday tasks, since 3.8 Flash verifies its work by design.

## Gemini 3.5 Flash-Lite notes

**Positioning:** "a low-latency, cost-effective multimodal model optimized for high-throughput, low-cost execution for subagent tasks and document parsing", built for translation, classification, simple extraction and high-volume agent steps. Default thinking is minimal.

**Prompting guidance:** Google publishes no Flash-Lite specific page, so what follows is inference from the general pages and the role. Keep one narrow task per call. Name the exact output format or schema and show one or two examples with identical formatting. Because minimal thinking does not reason much, raise `thinking_level` for anything that needs reasoning instead of asking for written steps. Do not set a small `max_output_tokens` to save cost; Google says to lower the thinking level instead. `minimal` is documented for 3.5 Flash and does not guarantee thinking is off.

## Gemini 3.1 Pro notes

**Positioning:** "better thinking, improved token efficiency, and a more grounded, factually consistent experience ... optimized for software engineering behavior and usability, as well as agentic workflows requiring precise tool usage and reliable multi-step execution". It is a preview model, so the advice can change.

**Prompting guidance:** high thinking is the default, so a rewrite only needs to lower it (`low` for simple instruction following and chat, `medium` for balanced work) and never to raise it. State the goal, constraints and output format first, put long context before the question, and do not script reasoning steps. The prompting page's own template contains a "Plan" step, which conflicts with its thinking advice; prefer the thinking advice. Ask for a chattier answer explicitly, since the default is direct.

## Gemini extended thinking notes

**What this target is:** a function, not a model, and two things Google documents separately. In the API, extended thinking is `thinking_level` set to `high` ("maximum thinking for advanced coding, math, or multi-step planning"). In the Gemini app, Deep Think is listed as an Ultra plan feature. Google's pages give no definition of the app's Thinking mode, no Deep Think limits and no prompt guidance for it, so those are unconfirmed.

**Prompting guidance:** for a thinking model, write the goal, the constraints and what a correct answer looks like, then let it think. "Think very hard before answering" is the one documented nudge. Do not ask it to list its steps or plan in the answer. Send the hardest version of the question in one message rather than a chain of small ones. Review the thought summaries to see why an answer failed.

## Gemini Deep Research notes

**What it is:** a function of Gemini, not a model: an agent that "autonomously plans, executes, and synthesizes multi-step research tasks". In the Gemini app it shows a research plan first; the user can click Edit plan, then Start research, and the report takes about 5 to 10 minutes. In the API it is in preview, runs only through the Interactions API, takes up to 60 minutes (most finish within 20) and offers a Max version.

**Prompting guidance (Google's words):** define the output format explicitly in the request, such as sections, data tables and the audience's tone. Give background information and constraints directly in the prompt. Tell the agent how to handle missing data, for example to state that 2025 figures are projections or unavailable rather than estimating them. Ask for visuals explicitly if you want them. For complex requests, use the plan step to steer. A short goal is fine for a simple request, and Google's own blog says not to overthink the first prompt. Not documented: date range or exclusion syntax, so write those as plain sentences. Structured output and custom function tools are not supported. The default sources are Google Search, URL context and code execution in the API; in the app, Gmail, Drive, uploaded files and NotebookLM notebooks can be added.

## What NOT to over-apply

A short, clear ask needs none of the three system-instruction clauses, few-shot examples or a thinking-level discussion. The strict-grounding clause forbids any use of the model's own knowledge, so add it only when the answer must come from supplied material. Step-by-step "think aloud" scaffolding is unnecessary for a thinking model. The older generic page text (always few-shot, chain tasks into steps, adjust temperature) predates Gemini 3. Match structure to the task.
