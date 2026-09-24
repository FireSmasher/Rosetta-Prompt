# Model selection, personal overrides (example)

Copy this file to `model-selection.local.md` in the same folder and edit it. The copy stays on
your machine: it is gitignored and only ever read locally. Any table below replaces the default
table of the same name in `model-selection.md`, whole, so keep every row you still want.

Delete any table you do not want to override.

```rubric
@table detail
haiku.1 | Extract fields from 1000 emails
haiku.2 | Tag, label, reformat, convert
haiku.3 | Bulk translate short strings
haiku.4 | Not for judgement calls
haiku.5 | No effort parameter, it errors
sonnet.1 | low · a bulk sorting job you run; worth it: when you spot-check the output
sonnet.2 | medium · an everyday writing job; worth it: when the risk is low
sonnet.3 | high · a bug you can test fast; worth it: when the cause is local
sonnet.4 | xhigh · a 30+ minute build you won't watch; worth it: when rework is cheap
sonnet.5 | max · last try before Opus; worth it: when Sonnet stalls and stakes are low
opus.1 | low · a filing job with fixed rules; worth it: when a misfile costs you
opus.2 | medium · a letter a human will read; worth it: when tone matters
opus.3 | high · a failure with an unknown cause; worth it: when it spans several files
opus.4 | xhigh · a feature across many files; worth it: when rework costs more
opus.5 | max · a check where a wrong answer is costly; worth it: when the stakes are yours
fable.1 | low · a broad research sweep; worth it: often beats Opus per dollar
fable.2 | medium · a plan with many moving parts; worth it: close to high, for less
fable.3 | high · a design that is hard to undo; worth it: when a wrong call means rework
fable.4 | xhigh · an overnight rebuild; worth it: hours unattended, one review at the end
fable.5 | max · the one answer you would stake the most on; worth it: rarely
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
# add your own, for example:
# mortgage | money at stake
```
