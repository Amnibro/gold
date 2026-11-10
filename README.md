# Gold

Gold is plain English that compiles to checked Helium. You describe what a program or a product feature does, block by block; Gold finds the product's existing Helium API, has a model write the Helium, checks it with `hc` (types, lifetimes, and the expected output when you give one), repairs it from the compiler's errors, and locks the result so the same Gold always builds the same Helium.

```
use waystone
into game/progress.amni

A climber's progress card. Struct `Progress` holds level, xp into the level, xp the level needs, and the cost of the next prestige.

`progress_of(xp int, prestige int) Progress` builds it from total xp and the current prestige count using the profile's level and prestige rules.
```

`gold build progress.gold` writes `game/progress.amni` inside Waystone, calling Waystone's own `game::level_of`, `game::xp_for_level` and `game::prestige_cost`.

## Quick start

Gold needs a [Helium](https://github.com/Amnibro/helium) checkout (built with `BUILD=build hc/bootstrap.sh`) and the [Claude Code](https://claude.com/claude-code) CLI signed in; the model calls go through `claude -p`.

```
HC_LIB=../helium/hc/lib ../helium/build/hc build gold.amni -o gold_bin
GOLD_HELIUM=../helium ./gold build demos/wordfreq.gold
./gold run demos/wordfreq.gold
```

A build prints what it did:

```
$ gold build units.gold
gold: translating 6 of 6 blocks with sonnet
gold: repairing 1 block(s), round 1
gold: units.amni ok (6 blocks, 294 Gold words -> 846 Helium words; 2 model calls, $0.19, 36 s)
```

`bench/rewrite/cad/he/units.gold` is a complete real example: 33 lines of Gold that replace Amni-CAD's `units.js` (`bench/rewrite/cad/ref/units.js`) and build to `units.amni`, matching the JavaScript on all 1,298 test inputs.

## Commands

| Command | What it does |
|---|---|
| `gold build f.gold` | translate, check, write the Helium (next to the Gold file, or `into` a product) |
| `gold run f.gold [-- args]` | build, then run |
| `gold show f.gold` | build, then print the Helium |
| `gold test f.gold` | build, then run the used packs' test commands |
| `gold port src.rs [use=…] [into=…] [lang=…] [ns=…] [gold=…]` | write Gold for existing code in any language, then build it |
| `gold pack <name> <dir> [lang=] [main=] [test=] [skip=]` | index a product's Helium API into `packs/<name>` |
| `gold packs` | list packs |
| `gold find <pack,…> <words>` | show which API a sentence retrieves |
| `gold compact f.gold [wide]` | pack the data tables with no model call: a first `@` row of column marks (`.` real column, `.2` point two places left, `e9` appended exponent, `+` text that changes only in its first number), and blank cells or short rows repeat the cells above; `wide` writes every cell back out in full |
| `gold squeeze f.gold check='cmd' [rounds=4]` | rewrite the Gold as shorter plain English, rebuild it from scratch and keep it only if the check command passes (failures are fed back, the original is the reference) |
| `gold lint f.gold` | list lines that read as code (operators, signatures, Helium types); `gold build` refuses them in changed blocks unless `GOLD_LINT=warn` |

## A Gold file

- **Header** (before the first block): `use <pack or std module>…`, `into <file>` (a path inside the product, or absolute), `lang amni|he|py`, `dialect rust|python|js|java|kotlin|numpy` (the source language's conventions, from `dialects/*.md`, apply to every block).
- **Blocks**, separated by blank lines: each one describes one unit (a type, a function, the program's top level). Name things in backticks when other code depends on the exact name.
- ```` ```amni ```` / ```` ```he ```` fences: literal Helium, kept as written.
- ```` ```table <fn> <Type> ```` fences: data rows, `|` between cells in field order, `"` repeats the cell above, numbers kept as written, other cells become strings (single-quote one that looks like a number or starts with `#`). A blank cell also repeats the cell above (`''` is an empty string), and an optional first `@` row gives column scales: `e9` appends that exponent to a cell without one, `.` makes a whole number real (`7870` → `7870.0`). `gold compact` writes these for you. Expanded to a `<fn>() <Type>[>..]` function without a model call.
- `expect:` then lines: the exact output a standalone program must print. Gold runs it and repairs until it matches.
- **Tiles**: Helium's `tiles/` modules are exact copies of other languages' built-ins, tested against the real language: `tiles/py` has Python's int(), float(), str() and truth of JSON values, datetime.fromisoformat and email.utils.getaddresses; `tiles/js` has String(x), toFixed and en-US toLocaleString. A block that names one ("Python's int() of the value") gets that tile.
- `#` lines are comments.

Without `lang`, Gold writes the language of the `into` file, else the product's language, else `.amni`.

## How a build works

1. Each block's text (plus `lang` and `use`) is hashed. A block found in `f.gold.lock` reuses its Helium; edited blocks are retranslated, nothing else.
2. For the rest, Gold retrieves the most relevant signatures from the used packs and `std` (BM25-style over names, files and doc comments), lists every function of each `use`d std module in full, adds the product's `notes.md` and up to three real function bodies as style samples, and asks the model (`GOLD_MODEL`, default `sonnet`) for all pending blocks in one call.
3. The file is assembled (imports hoisted and deduplicated) and checked: `hc --query` diagnostics with every error mapped back to its block, then `hc check` through a small harness root so product-relative imports resolve, then, with `expect:`, a real run. Lifetime checks are on for `.he` (`HC_HEPROV=1`).
4. Missing std imports are added without a model call. Other errors go back to the model for the failing blocks only; the last round uses `GOLD_MODEL_HARD` (default `opus`). `GOLD_TRIES` rounds in all (default 4).
5. On success the lock is saved and, when writing into a product, its pack is re-indexed so the new code is callable by the next Gold file.

## Packs

`packs/<name>/` holds `pack.conf` (dir, lang, main, test, skip), `api.tsv` (every top-level function, type and global with file, line and doc comment) and an optional hand-written `notes.md` of conventions. Current packs: `std` (hc/lib), `waystone`, `pomling`, `mail` (Amni-Mail core), `prayer`. Re-run `gold pack <name>` after the product changes; Gold does it itself after writing into a product.

## Environment

`GOLD_MODEL` (sonnet), `GOLD_MODEL_HARD` (opus, last repair round), `GOLD_MODEL_PORT` (opus), `GOLD_TRIES` (4, extended up to 10 while each round changes the errors), `GOLD_K` (70 retrieved symbols), `GOLD_HELIUM` (Helium checkout, default `~/ai/amni-lang/helium`), `GOLD_HC`, `GOLD_HC_LIB`, `GOLD_CACHE` (`~/.cache/gold`), `GOLD_VERBOSE`.

## Build Gold

Gold is written in Helium (see Quick start): `HC_LIB=<helium>/hc/lib <helium>/build/hc build gold.amni -o gold_bin`. Point `GOLD_HELIUM` at the same checkout, and run `gold pack std <helium>/hc/lib lang=he` once so Gold can see the library.

## Results so far

| Task | Gold | Helium | Model calls | Cost | Check |
|---|---|---|---|---|---|
| word-frequency program | 72 words | 216 words | 1 | $0.02 | expected output matched |
| Waystone progress module | 73 words | 70 words | 1 | $0.05 | hc + numbers verified by hand |
| Amni-Calc `springs.rs` port (Rust → Gold → Helium) | 1227 words | 1956 words | 1 | $0.32 | 43/43 cases match the Rust exactly |
| Amni-CAD `units.js` formatting port (JS → Gold → Helium) | 764 words | 921 words | 2 | $0.21 | 1298/1298 cases match Node exactly |

Six product engines rewritten through Gold (`bench/rewrite`, numbers from `bench.py`, 2026-11-10, AMD Ryzen 9 9950X3D):

| Product | Original | Same answers | Tokens original → Gold | Speed vs original |
|---|---|---|---|---|
| Amni-Calc calculators | Rust | 687/687 | 95,993 → 41,255 (57% fewer) | about even (also with Rust built for this CPU) |
| Amni-Price tag parser | Kotlin | 400/400 | 5,376 → 3,040 (43% fewer) | 2.3× faster |
| Amni-Type swipe decoder | Java | 400/400 | 3,618 → 1,507 (58% fewer) | 1.4× faster |
| Amni-Mail rules engine | Python | 400/400 | 6,053 → 3,369 (44% fewer) | 3.7× faster |
| Amni-Crypt Reffelt layer | numpy (C kernel) | 80/80 | 6,155 → 1,287 (79% fewer) | 1,691× faster; C kernel below |
| Amni-CAD unit text | JS | 1298/1298 | 1,148 → 924 (20% fewer) | 58× faster |

All together: 118,343 → 51,382 tokens (57% fewer). 30 of the 3,265 answers differ only in the wording of an invalid-input error. Only the Price and CAD sources are public, so only those two ports are in this repository with their originals; the others keep their cases, results and `meta.json`.

Amni-Crypt also ships a hand-tuned C kernel for the same layer (AVX-512, GFNI and AES instructions). Over 300 passes of the whole job the Helium rewrite is 3.5× faster than that C built the way the app builds it (gcc -O3) and 1.14× faster than clang -O3 -march=native, mostly because the C driver reads hex and text with plain loops. On the cipher alone (`KERNEL=1`: cases decoded first, only encrypt, decrypt and shadow walk timed) Helium is 1.11× faster than the gcc build and 1.07× slower than the clang build.

What closed the speed gaps, all in Helium: shortest float digits from one 128-bit multiply instead of three (the zmij method) and exact fixed-point digits from one multiply, number text written 8 digits at a time, cheaper string escaping, a regex search that backtracks with a visited bitmap on small inputs, AVX-512 kernels for word splitting and hex text, a resize that no longer fills one byte at a time, and the `gf` library: GF(2^8) dot products and the AES S-box/MixColumns step run with the CPU's GFNI and VAES instructions when it has them (`gf::dot64`, `gf::dot16` for a whole 1 KiB block, `gf::mix`, `gf::mix_inv`, `gf::mul`), plus `hex_encode`, `hex_decode`, `order16` and `xor_bytes` in `std`. Crypt's Gold calls `gf::dot16` and `order16`, library calls that each do one whole step of this cipher. The token savings come from `dialect` headers, packed ```` ```table ```` data (`gold compact`), `gold squeeze` (checked against every case and a speed limit, `guard.py`), and Gold that calls those library functions instead of spelling out S-boxes and tables. Published on [amni-scient.com/gold](https://amni-scient.com/gold.html).

The first ports live in `demos/port-*` with their reference outputs and drivers (`port-units` is in the public repository). Each port surfaced a real gap that is now fixed in hc: self-relative copies in `.he`, unchecked lifetimes in `.he` (`HC_HEPROV`), uncalled functions skipping checks (`hc check --all`), a dangling `os.args`, and JS-style tie rounding (`format_flt(..., away = true)`).

## Also here

`goldc.amni`, `lib/`, `spec/` and `tools/` are the older deterministic phrase composer and its generated phrase library (`gold-gen`); they are separate from the `gold` command above.
