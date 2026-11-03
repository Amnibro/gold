# Writing Gold

Gold is how you write Helium for Anthony's products: describe the code in plain English and run `gold build`. Gold finds the product's API, writes the Helium, checks it with hc, fixes compiler errors itself, and caches the result in `<file>.gold.lock`.

```
use waystone
into game/progress.amni

Struct `Progress` holds level, xp into the level, xp the level needs, and the next prestige cost.

`progress_of(xp int, prestige int) Progress` builds it from total xp using the profile's level and prestige rules.

`progress_line(p Progress) byte[>..]` formats it as `Lv 7 (120/450 xp) - next prestige 3000`.
```

- Header lines first: `use <pack|std module>`, `into <path in the product>`, optional `lang amni|he|py`. Packs: `gold packs`.
- One blank-line-separated block per unit. Say what it does, not how: inputs, result, rules, formats, edge cases.
- Put exact names and signatures in backticks only when other code calls them.
- Say which existing behavior to reuse ("using the profile's level rules"); Gold finds the functions. Check with `gold find <pack> <words>`.
- Standalone programs: end with `expect:` and the exact output lines; Gold runs and repairs until it matches.
- Exact Helium when you need it: a ```` ```amni ```` or ```` ```he ```` fence.
- `dialect rust` (or python, js, java, kotlin, numpy) in the header: the source language's conventions (float sums from -0.0, how numbers print, rounding, casts) apply to every block, so never restate them.
- Data rows go in a ```` ```table <fn> <Type> ```` fence: one row per line, cells split by `|` in field order, a lone `"` or a blank cell repeats the cell above. Gold turns it into Helium itself; `gold compact f.gold` packs a table further (column scales in a first `@` row).
- Edit a block and rebuild: only that block is retranslated.

Commands: `gold build|run|show|test f.gold`, `gold squeeze f.gold check='<cmd>'` (shorten the Gold; kept only if a fresh rebuild passes the check), `gold port <source file> use=<pack> into=<file>` (any language → Gold → Helium), `gold pack <name> <dir> main=<root file>`, `gold find <pack> <words>`.

When a build fails after its repair rounds, read the errors it prints, then make the failing block more specific (name the function or type to use) rather than writing Helium by hand.

## Porting tips (from the six product ports)

- Verify every port against the original on a few hundred real cases (`bench/rewrite/percase.py`); fix a mismatch by making the Gold sentence more exact, never by editing the Helium.
- Floats: write formulas in the source's grouping, name `powi`/`fabs`/`tanh` instead of defining them, and state quirks (saturating casts, sums starting at -0.0, NaN/inf text, `e+16` exponents).
- Big literal tables go in a ```he fence.
- Keep the source's cost model: say that regexes and tables are built once into a module `var`. Say how a hot table is laid out when the layout is what makes it fast.
- After a rule change that touches many blocks, delete the `.gold.lock` and rebuild the whole file.
