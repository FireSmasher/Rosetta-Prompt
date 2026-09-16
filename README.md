# Rosetta Prompt

A small macOS app that rewrites a messy prompt into a clear one for a specific target model,
using that model's own published prompting guidance, then checks the rewrite before showing it.

Targets: Claude Fable 5.1, Opus 5, Sonnet 5 and Haiku 4.5; GPT-5.6 Sol, Terra and Luna; GPT-6 Astra.

## What it does

1. **Picks the model and effort first, for free.** A local scoring program reads your prompt and
   says whether the selected target is the right size. If it suggests a lower or higher model,
   **Switch to {model}** selects it and starts the rewrite in one click. Nothing is sent to a
   model until you choose.
2. **Rewrites** the prompt with Claude Opus 5, fed the general and model-specific sections of
   the distilled guides in `skill/reference/`.
3. **Checks** the rewrite: code checks (no em or en dashes, no placeholders, no preamble or code
   fence, length sanity, target-specific rules), then an advisory Sonnet 5 judge. A failed code
   check sends the draft back, up to three attempts.
4. **Learns from misses.** "This rewrite was wrong" files the result as a calibration case on
   your machine.

The same workflow is available inside Claude Code as the `rosetta-prompt` skill.

## Requirements

- macOS 13 or later
- Swift 5.9 or later (Xcode or the Command Line Tools)
- The [Claude Code](https://claude.com/claude-code) CLI, logged in (`claude` on your `PATH`, or
  in `~/.local/bin`, `/opt/homebrew/bin` or `/usr/local/bin`)
- `/usr/bin/python3` for the checker (standard library only)

## Install

```sh
git clone https://github.com/FireSmasher/Rosetta-Prompt.git
cd Rosetta-Prompt
./scripts/install.sh
```

The script builds a release binary, installs `~/Applications/RosettaPrompt.app`, signs it ad
hoc, and links `~/.claude/skills/rosetta-prompt` to the `skill/` folder, which is where the app
reads its guides and checker. To pin an SDK, set `SDK=/path/to/MacOSX.sdk`.

The app is not notarized. On first launch, right-click it and choose Open.

## Your own data

The model and effort pick is driven by the tables in `skill/reference/model-selection.md`. They
ship with neutral defaults. To tune them to your own work:

```sh
cp skill/reference/model-selection.local.example.md skill/reference/model-selection.local.md
```

Edit the copy. Any table in it replaces the default table of the same name. The ones worth
making your own are `detail` (the example jobs shown per model and effort level), `stakes`
(words that always get a top-tier model at high effort) and `heavy` / `light` (your domain's
vocabulary for hard and mechanical work). Changes apply the next time the app launches.

Your data stays local:

- `*.local.md`, saved calibration cases and calibration reports are gitignored.
- The local file is read only by the in-app scorer. It is never sent to a model.
- Rewrite and judge calls run `claude -p` with no tools, no MCP servers, no claude.ai
  connectors, no auto-memory and no settings sources, so your CLAUDE.md, memory and prompt
  hooks are not sent with them. What is sent is the prompt you paste, any extra context you
  add, and the reference guidance.
- The app has no telemetry and makes no other network calls.

## Checks

```sh
python3 skill/scripts/check_rewrite.py replay   # must pass every case after any change
python3 skill/scripts/check_rewrite.py status   # is the judge armed?
```

Criteria and thresholds live in `skill/reference/rewrite-evals.md`. The judge stays advisory
until at least 20 approved and 20 rejected calibration cases score 90% or better
(`check_rewrite.py calibrate`).

## Keeping the guides current

The guides are dated caches of each provider's docs, not live fetches. `skill/SKILL.md`
describes how to refresh them. Each target's source date and confidence are shown in the app.

## License

MIT
