# Writing Gold

Gold is how you write Helium for Anthony's products: describe the code in plain English and run `gold build`. Gold finds the product's API, writes the Helium, checks it with hc, fixes compiler errors itself, and caches the result in `<file>.gold.lock`.

```
use waystone
into game/progress.amni

`Progress` holds the level, the xp into it, the xp it needs and the next prestige cost.

`progress_of(xp, prestige)` builds it from total xp using the profile's level and prestige rules.

`progress_line(p)` writes it as "Lv 7 (120/450 xp) - next prestige 3000".
```

- Header lines first: `use <pack|std module>`, `into <path in the product>`, optional `lang amni|he|py`. Packs: `gold packs`.
- One blank-line-separated block per unit, in dense plain English: what it does, not how (inputs, result, rules, formats, edge cases). No operators, signatures or Helium types in the prose; say comparisons in words. `gold build` refuses changed lines that read as code, and `gold lint f.gold` lists them.
- Put names in backticks only when other code calls them; put exact text in quotes.
- Say which existing behavior to reuse ("using the profile's level rules"); Gold finds the functions. Check with `gold find <pack> <words>`.
- Name another language's built-in instead of describing it. Helium's `tiles/` modules copy them exactly and are tested against the real language: `tiles/py.he` has Python's int(), float(), str() and truth of JSON values, datetime.fromisoformat and email.utils.getaddresses; `tiles/js.he` has String(x), toFixed and en-US toLocaleString. Write "Python's int() of the value" and Gold calls `py::int_of`. A `dialect` header keeps the matching tiles in view.
- Standalone programs: end with `expect:` and the exact output lines; Gold runs and repairs until it matches.
- Exact Helium when you need it: a ```` ```amni ```` or ```` ```he ```` fence.
- `dialect rust` (or python, js, java, kotlin, numpy) in the header: the source language's conventions (float sums from -0.0, how numbers print, rounding, casts) apply to every block, so never restate them.
- Data rows go in a ```` ```table <fn> <Type> ```` fence: one row per line, cells split by `|` in field order, a lone `"` or a blank cell repeats the cell above. Gold turns it into Helium itself. Write tables in full: `gold compact f.gold` packs them (a first `@` row of column marks, short rows), and `gold compact f.gold wide` spells every cell out again before you edit one.
- Edit a block and rebuild: only that block is retranslated.

Commands: `gold build|run|show|test f.gold`, `gold squeeze f.gold check='<cmd>'` (rewrites it as shorter plain English; kept only if a fresh rebuild passes the check), `gold lint f.gold`, `gold port <source file> use=<pack> into=<file>` (any language → Gold → Helium), `gold pack <name> <dir> main=<root file>`, `gold find <pack> <words>`.

When a build fails after its repair rounds, read the errors it prints, then make the failing block more specific (name the function or type to use) rather than writing Helium by hand.

## Porting tips (from the six product ports)

- Verify every port against the original on a few hundred real cases (`bench/rewrite/percase.py`); fix a mismatch by making the Gold sentence more exact, never by editing the Helium.
- Short wording can lose which operation is meant. Write "Python's int() of x", not "x is an int"; "Python's float of the value's str", not "the value as a float". Define a term once ("An email's attachments are the ones the case lists under its id") and reuse it.
- State a fact several blocks share once, at the top. Name the Helium constants a block needs (`json::K_STR`) when the API listing might not show them.
- A behavior two products both need belongs in a tile: write it in Helium's `hc/lib/tiles/<name>.gold`, with a test in `hc/test/tiles_<name>.gold` whose expected output comes from the real language.
- Floats: write formulas in the source's grouping, name `powi`/`fabs`/`tanh` instead of defining them, and state quirks (saturating casts, sums starting at -0.0, NaN/inf text, `e+16` exponents).
- Big literal tables go in a ```he fence.
- Keep the source's cost model: say that regexes and tables are built once into a module `var`. Say how a hot table is laid out when the layout is what makes it fast.
- After a rule change that touches many blocks, delete the `.gold.lock` and rebuild the whole file.
