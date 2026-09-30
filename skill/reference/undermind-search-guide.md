# Undermind.ai search guidance, distilled

Undermind is a deep-search tool for scientific papers, not a chat model. A "prompt" for it is a research request. Read 30 September 2026:
- https://www.undermind.ai/ (home: how it works, plans, vendor claims; FAQ answers did not render)
- https://www.undermind.ai/pricing (plans)
- https://www.undermind.ai/mcp (agent setup page)
- https://www.undermind.ai/whitepaper.pdf (Undermind's own whitepaper, 5 January 2024, with Topic and Additional context request templates)
- Undermind's own MCP tool orientation, the `get_orientation` text returned by the connected Undermind server, read in the main session 30 September 2026
- Secondary, library and practitioner sources, used only where marked: Musings about Librarianship (Aaron Tay, April 2024, edited April 2025), Aaron Tay on Substack (12 April 2026), SMU Libraries on the Projects revamp (page undated, images May 2026), Deakin Library evaluation (April 2026)

Confidence: 65%. Pricing, the flow, the whitepaper templates and the tool orientation are first party. The query length limits (1000 characters maximum, 15 minimum), the clarifying-question advice and the scope advice are from secondary sources and may have changed since 2024. Not found: a first-party guide to writing a request (undermind.ai/faq, /blog, /docs and /how-it-works return 404), a changelog, credit costs, coverage limits, any Undermind post on X, LinkedIn or YouTube, or independent verification of the vendor's benchmarks. The timing is a conflict: the MCP orientation says generally 2 to 5 minutes, SMU says around 8 to 10 minutes for the Classic flow, so this file says 2 to 10.

This file grounds `/rosetta-prompt` before rewriting a messy research request for Undermind. Use "General principles" plus the Undermind section.

## Model facts

Not a model: no model name, context window, output limit or effort setting is published, and none applies. The facts that exist are the flow and the limits in the Undermind section below: a deep search takes roughly 2 to 10 minutes, open-access PDFs are fetched automatically. Whether relevance is judged on abstracts only is unconfirmed for 2026 (the MCP orientation says relevance "can be evaluated without reading the full texts"; Pro advertises "deepest analysis of full texts"). Result counts, coverage limits and a knowledge cutoff: not published.

## Migration notes

None published: no changelog or version history was found (30 Sep 2026), so there is nothing to migrate a request from.

## Cost

See Plans in the Undermind section below. Credit costs per search: not published.

## General principles (writing a search request)

1. **Write it as you would explain it to a colleague.** Plain sentences, not keywords. Long is fine: the 2024 review measured a 1000 character maximum and a 15 character minimum (Musings, secondary, unconfirmed for 2026). Do not compress a detailed goal into a keyword string.
2. **Use Topic, then Additional context.** Undermind's whitepaper templates are a one line topic ("Routing trapped ions in a quantum computer") and an additional context that carries the conditions ("I care most about results which use light in the visible spectrum, so between 400 nm and 800 nm wavelength"; "any recent papers (2019 or later) which demonstrate ..."). Put the subject first and every condition after it.
3. **State what you want and what you do not.** Inclusion and exclusion written as sentences ("I am only interested in ...", "I don't want specific implementations") is how the review describes good requests. Do not write Boolean operators: the search is semantic.
4. **Say what you care about most.** A priority sentence ("I care most about ...") tells the ranking what to favour. A date floor is stated the same way, in words.
5. **One focused question per request.** Aim for a topic that would return roughly 10 to 50 relevant papers (Tay, SMU, secondary). A broad request such as "how are LLMs used in evidence synthesis" is too unfocused; split it into sub-questions and run one search each.
6. **Expect the clarifying questions, and answer them fully.** Undermind "asks follow-up questions to understand exactly what you need" (home). Deakin warns that thin answers give weaker results, and that replies like "1A, 2C" work. A request need not anticipate everything, but should not hide the goal.
7. **Make it self-contained.** Deep search is for a goal that can be judged without the conversation around it: state the topic, what counts as relevant, and what does not. (MCP orientation: for "self-contained queries that demand comprehensive, carefully ranked results".)
8. **Do not ask for set logic or exclusions by citation.** A plain search cannot run two searches and compare the overlap, and it cannot drop papers you already cite (SMU, Tay, secondary). Put those as a later step, not in the request.
9. **Plan to iterate.** Extend the search if the report says coverage is low, and use the chat after the report to recover papers it missed (Musings, Deakin). A first request does not have to be final.

## Undermind-specific notes

**Flow** (home, 30 Sep 2026): describe, explore, build, keep up (alerts on an area). Undermind says it reads and evaluates hundreds of papers and follows citation trails. The whitepaper (vendor benchmark, not checked) reports finding about 10 times more relevant results than the top 50 Google Scholar hits, and says to treat it as a high recall search, not a complete database: Deakin advises combining it with Boolean and citation searching.

**Quick versus deep** (MCP orientation): a deep search takes roughly 2 to 10 minutes (MCP 2 to 5, SMU 8 to 10) and "one well-aimed deep search usually covers a task". A quick semantic search over titles and abstracts suits exploration, a few top results, or when the goal is not yet self-contained. A narrow or empty quick result does not mean the literature is absent.

**Projects agents** (SMU, secondary): Search Architect asks clarifying questions and proposes a deep search, Report Writer asks again, and the Generalist agent usually proceeds without clarifying questions, so a fully written request suits it. Papers can be referenced by Paper Key ID, for example "find me papers similar to [Wan22]". At most three agents run at once.

**Plans** (pricing, 30 Sep 2026): Free at $0 with standard rate limits. Pro $16 per month billed annually, with 10x higher usage limits and deeper analysis of full texts. Team $15 per person per month billed annually. Enterprise is custom. No numeric search or credit counts are published on the page read. Institutional subscriptions exist (SMU since November 2024).

**Full texts:** open-access PDFs are retrieved automatically. Paywalled PDFs need the user to upload them.

## What NOT to over-apply

A rewrite is a research request, not a model instruction. Do not add a role, XML structure, examples or an effort level: none of it has a published effect on Undermind. The Topic and Additional context labels come from Undermind's own whitepaper and are the only structure to use. Do not promise result counts, timings beyond the 2 to 10 minute range, or coverage, and do not invent date ranges, populations or databases the original did not state. The 1000 character limit is from 2024, so keep a request well under it unless the user's own text is longer.
