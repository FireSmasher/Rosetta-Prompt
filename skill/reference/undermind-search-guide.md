# Undermind.ai search guidance, distilled

Undermind is a deep-search tool for scientific papers, not a chat model. A "prompt" for it is a research request. Read 30 September 2026:
- https://www.undermind.ai/ (home: how it works, vendor claims)
- https://www.undermind.ai/pricing (plans)
- https://www.undermind.ai/mcp (agent setup page)
- Undermind's own MCP tool orientation, the `get_orientation` text returned by the connected Undermind server (the only first-party description of when to use deep search versus a quick search)

Confidence: 55%. Pricing, the flow and the tool orientation are first party. Not found: a published guide to writing a good request (undermind.ai/faq, /docs and /how-it-works return 404), a changelog, result counts, credit costs, coverage limits, or any independent verification. Advice on query wording that appeared only in a search-engine summary was not read at source and is left out. Vendor benchmark claims on the home page are the vendor's and were not checked.

This file grounds `/rosetta-prompt` before rewriting a messy research request for Undermind. Use "General principles" plus the Undermind section.

## Model facts

Not a model: no model name, context window, output limit or effort setting is published, and none applies. The facts that exist are the flow and the limits in the Undermind section below: a deep search generally takes 2 to 5 minutes, relevance is judged on titles and abstracts, open-access PDFs are fetched automatically. Result counts, coverage limits and a knowledge cutoff: not published.

## Migration notes

None published: no changelog or version history was found (30 Sep 2026), so there is nothing to migrate a request from.

## Cost

See Plans in the Undermind section below. Credit costs per search: not published.

## General principles (writing a search request)

1. **Make the request self-contained.** Deep search is for a goal that can be judged without the conversation around it: state the topic, what counts as relevant, and what does not. (MCP orientation: for "self-contained queries that demand comprehensive, carefully ranked results".)
2. **One research question per request.** Undermind runs one long agentic search per request, so several topics in one request dilute it. (Inference from the tool's design, not a published rule.)
3. **Expect follow-up questions.** The home page says Undermind "asks follow-up questions to understand exactly what you need", so a request need not anticipate everything, but should not hide the goal.
4. **Judged on abstracts.** Deep search evaluates papers from titles and abstracts, so name criteria an abstract can show (population, method, outcome, date range). A need that only full texts can answer is a later step. (MCP orientation: "paper relevance can be evaluated without reading the full texts".)
5. **Plan to iterate.** The home page describes iterating on reports, diving into full texts, extracting details and refining. A first request does not have to be final.

## Undermind-specific notes

**Flow** (home, 30 Sep 2026): describe, explore, build, keep up (alerts on an area). Undermind says it reads and evaluates hundreds of papers and follows citation trails.

**Quick versus deep** (MCP orientation): a deep search generally takes 2 to 5 minutes and "one well-aimed deep search usually covers a task". A quick semantic search over titles and abstracts suits exploration, a few top results, or when the goal is not yet self-contained. A narrow or empty quick result does not mean the literature is absent.

**Plans** (pricing, 30 Sep 2026): Free at $0 with standard rate limits. Pro $16 per month billed annually, with 10x higher usage limits and deeper analysis of full texts. Team $15 per person per month billed annually. Enterprise is custom. No numeric search or credit counts are published on the page read.

**Full texts:** open-access PDFs are retrieved automatically. Paywalled PDFs need the user to upload them.

## What NOT to over-apply

A rewrite is a research request, not a model instruction. Do not add a role, XML structure, examples or an effort level: none of it has a published effect on Undermind. Do not promise result counts, timings or coverage beyond the 2 to 5 minute note above, and do not invent date ranges, populations or databases the original did not state.
