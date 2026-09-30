# Google Gemini prompting guidance, distilled

Primary sources, Google's own official docs, read 30 September 2026:
- https://ai.google.dev/gemini-api/docs/prompting-strategies (prompt design, with a "Gemini 3" section; the page shows no date and some examples still use gemini-2.5-flash)
- https://ai.google.dev/gemini-api/docs/models (models overview, updated 24 September 2026)
- https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash (spec page, updated 2 September 2026)
- https://ai.google.dev/gemini-api/docs/latest-model ("What's new in Gemini 3.8 Flash", migration checklist, updated 23 September 2026)
- https://ai.google.dev/gemini-api/docs/thinking (thinking levels, updated 25 September 2026)
- https://ai.google.dev/gemini-api/docs/pricing (updated 24 September 2026)
- https://ai.google.dev/gemini-api/docs/changelog (updated 23 September 2026)

Confidence: 78%. All seven pages are first party and dated within a month. Not found or not read: the Gemini app's own prompt guide (the one URL tried returned 404), Vertex AI and Workspace prompt guides, any knowledge cutoff for any model, and any independent verification. Pricing for models other than 3.8 Flash could not be attributed reliably, so it is left out.

This file grounds `/rosetta-prompt` before rewriting a messy prompt aimed at Google Gemini, using the Gemini API docs. Gemini 3.8 Flash, the newest current model, stands in for the family. The Gemini app's own model lineup was not researched. Use "General principles" plus the Gemini section.

## Model facts

`gemini-3.8-flash` (models/gemini-3.8-flash, latest-model, pricing, 30 Sep 2026): GA 2 September 2026, the newest general text model. 1,048,576 token input limit, 65,536 max output. Input text, image, video, audio and PDF, output text. Thinking levels `low`, `medium` (default) and `high`, no `minimal`. Other stable models listed: 3.7 Flash, 3.6 Flash, 3.5 Flash, 3.5 Flash-Lite, 3.1 Flash-Lite. 3.1 Pro and 3 Flash are preview. Knowledge cutoff: not published on any page read.

## Migration notes

From the `latest-model` migration checklist (30 Sep 2026): temperature, top_p and top_k are API settings to strip for 3.8 Flash, so never write sampling advice into prompt text. 3.7 Flash remains fully supported. No other prompt-text changes are published.

## Cost

Price per million tokens: introductory $0.75 input and $3.75 output through 31 December 2026, then $1.50 and $7.50, output price including thinking tokens. 3.8 Flash "can use more tokens on longer running and complex tasks, by design", so for everyday tasks lower the thinking level first. Prices for other models: not attributed, left out.

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

## Gemini-specific notes

**Positioning:** Google calls 3.8 Flash "engineered for long-horizon software engineering, autonomous agents, and complex enterprise workflows". Specs, migration and price are in the sections above.

**Prompting guidance:** the Gemini 3 section of the prompting page offers three optional system-instruction clauses tuned for Gemini 3 Flash: a current-date accuracy line, a knowledge-cutoff line and a strict-grounding line. They are meant to be edited, not pasted into every prompt. Planning is internal, so a rewrite should state the goal and constraints, not a procedure. Sampling settings are covered under Migration notes.

## What NOT to over-apply

A short, clear ask needs none of the three system-instruction clauses, few-shot examples or a thinking-level discussion. The strict-grounding clause forbids any use of the model's own knowledge, so add it only when the answer must come from supplied material. Step-by-step "think aloud" scaffolding is unnecessary for a thinking model. The older generic page text (always few-shot, chain tasks into steps, adjust temperature) predates Gemini 3. Match structure to the task.
