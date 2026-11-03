# Gold conversational grammar

Gold turns plain sentences into Helium. Each sentence names a **function** as
`verb noun modifier context`, for example `run function until` in context `core`.
Every function is a verified Helium template, often dozens of lines long, so one
word in a script expands to real code. A multi-line script expands into a single
Helium program that compiles with `hc` and runs.

```
x = collatz step
y = reaches one
sub = digit sum
input = 27
Run function x until y.
Check errors and cache results.
Run subfunction.
Return results.
```

`goldc compose demo.gold <gold_root> demo.amni` writes one Helium program. It
holds the shared runtime (`runtime/prelude.amni`), one function per binding
(`gold_x`, `gold_y`, `gold_sub`), one function per step (`gold_s0` … `gold_s4`)
and a `main` that threads state through them. Build it with
`hcn build demo.amni -o demo` and run it.

## 1. Vocabulary (spec/vocab.txt)

| axis | size | examples |
|---|---|---|
| verb | 40 | run, repeat, check, cache, return, count, filter, sort, retry, fold … |
| noun | 53 | function, subfunction, results, errors, list, digits, words, window, streak … |
| modifier | 25 | none, until, while, each, times, first, last, up_to, with_cache, with_retry … |
| context | 16 | core, math, list, text, stats, search, sort, cache, error, retry, loop … |

That gives 40 × 53 × 25 × 16 ≈ 848k combos. Each combo can be any of three kinds,
so there is room for several hundred thousand distinct, verified functions.

## 2. Entries (lib/*.gold)

```
@entry <id>
kind: step | fn | pred
verb: run
noun: function
modifier: until
context: core
phrase: run function {x} until {y}      # 2+ phrase variants, each globally unique
phrase: keep running {x} until {y}
slot: x fn                              # slot kinds: fn, pred, int, text
slot: y pred
test: input=6 x=collatz y=is_one        # 2+ tests, outputs must differ
expect: => i=1 r=0.0 ok=true s="ran 8 times" errors=0 n=9 res=[6,3,10,5,16,8,4,2,1] cache=0 hits=0
test: ...
expect: ...
code:
fn ${ID}(g Gold&, v Val) Val { ... }    # Helium template; ${slot} placeholders
@end
```

* **step** has the signature `fn ${ID}(g Gold&, v Val) Val`. `Val` is the value
  flowing between steps (`i int, r real, ok bool, s text`). `Gold` is the shared
  state: the results list `res`/`n`, the error count and message, a key→value
  cache with hit and miss counters, and a step counter.
* **fn** has the signature `fn ${ID}(n int) int`. **pred** has `fn ${ID}(n int) bool`.
  These are what names are bound to (`x = collatz step`).
* Slots: `fn` and `pred` slots take a bound name, `int` takes a number or a
  numeric binding, and `text` takes a quoted string or a text binding.
* `id` is a 64-bit hash of the normalized code plus its phrase shapes.

## 3. Script grammar

```
script   := line*
line     := binding | action | '#' comment
binding  := NAME '=' rhs | 'let' NAME 'be' rhs
          | 'input' '=' NUMBER | 'text' '=' "QUOTED" | 'list' '=' NUMBER (',' NUMBER)*
rhs      := NUMBER | "QUOTED" | phrase           # phrase resolves to a fn/pred entry
action   := clause (JOIN clause)*                 # JOIN = 'and' | 'then' | ',' | ';'
clause   := phrase                                # resolves to a step entry
```

**Normalization.** Text is lowercased. A word is a run of `[a-z0-9_]` (a leading `-`
is kept before a digit). `"quoted text"` and `{slot}` are single tokens. The
fillers please, the, a, an, now, just, my, some, can, you, go and ahead are
dropped. Trailing punctuation is ignored.

**Shapes.** In a clause, every bound name, number and quoted string becomes `{}`
and is captured in order. The resulting shape (e.g. `run function {} until {}`)
is looked up in `lib/index.tsv` (`shape  kind  file  id  slot-order`). Each shape
is globally unique, so a sentence maps to exactly one function.

**Binding and passing results.**
* `x = <phrase>` instantiates that fn/pred entry as `gold_x`. A later clause that
  mentions `x` fills a slot with `gold_x`.
* A slot the clause does not mention is filled by the binding with the same
  name. This is how a bare `run subfunction` picks up `sub`: the entry's `{sub}`
  slot binds implicitly.
* Steps run in order: `v = gold_sK(g, v)`. Each step reads and writes the shared
  `Gold` state (results, errors, cache) and the flowing `Val`, so results pass
  from one step to the next without wiring.
* Subfunctions nest. A step's fn slot can be a bound phrase, and fn/pred entries
  can take `int`/`text` slots (`above {limit}`), so `big = above 100` then
  `keep running x until big` composes three levels.
* The program ends with `gold_report`, which prints the final state on one line
  (`=> i=… r=… ok=… s="…" errors=… n=… res=[…] cache=… hits=…`).

## 4. Verification (every accepted entry)

1. `goldc check`:
   * structure and signature; 3–220 code lines; at least 2 phrases, each with a
     real word and no literals or joiners; at least 2 tests whose outputs differ;
   * forbidden patterns (python, subprocess, run_command, system(, popen, exec,
     extern, import, file I/O, ffi, threads, lut/gpu fns);
   * answer-table heuristics (array literals with 16+ elements, string literals
     with 3+ digits).
2. Dedup on the exact key (normalized code + phrase shapes), the near key
   (code without digits, whitespace or case), the combo
   (kind|verb|noun|modifier|context), and every phrase shape against the index.
3. `goldc harness` fills the slots per test (with the prelude's `core_*` fns and
   preds). The real compiler builds each program under nice/ionice with a
   timeout, and it runs sandboxed in `bwrap` (no network, read-only fs) with a
   CPU and memory limit. Stdout must equal `expect` exactly. A step that leaves
   both `Val` and `Gold` unchanged is rejected as a no-op.
4. Expected outputs are written by the model and checked only by running the
   compiled Helium. Nothing is computed outside Helium.
