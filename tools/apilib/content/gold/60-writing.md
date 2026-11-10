# Writing good Gold

## The basics

- **Say what, not how.** Describe the result you need. Gold picks the loops and data structures.
- **Show the format.** "Two decimals with a dollar sign" beats a format string, and an `expect:` line beats both.
- **Name the edges.** Ties, empty input, capital letters: one short sentence each, and Gold handles them.
- **Reuse what exists.** Say which behavior to reuse, such as "using the profile's level rules". Check it with [`gold find`](/api-library/gold/commands#gold-find).
- **Use backticks sparingly.** Only names that other code depends on need them.
- **Write English, not code.** Say "returns the text" or "a list of rows", not types or operators. Formulas are fine.
- **Name the built-in you mean.** For a port, "Python's int() of the text" or "JavaScript's toFixed" calls a tile: a tested copy of that built-in in Helium, so the paragraph needs no further detail.

## When a build fails

Read the errors Gold prints, then make the failing paragraph more specific: name the function or type it should use. Do not edit the generated Helium by hand, because the next build would overwrite it.

## Porting existing code

- Check every port against the original on a few hundred real inputs. Fix a mismatch by making the Gold sentence more exact.
- Floats: write formulas in the source's grouping, name `powi`, `fabs` or `tanh` instead of defining them, and state quirks such as saturating casts, sums that start at -0.0, NaN text and `e+16` exponents.
- Put big tables in a `table` fence or an `he` fence, not in sentences. Write the rows in full, then run `gold compact` to pack them.
- Keep the original's cost model. Say that regular expressions and tables are built once into a module `var`, and say how a hot table is laid out when the layout is what makes it fast.
- After a rule change that touches many paragraphs, delete the `.gold.lock` file and rebuild the whole thing.
- Use a [dialect](/api-library/gold/dialects) so number and rounding rules come along without restating them.

## Keep it short

Once a port passes, run [`gold squeeze`](/api-library/gold/commands#gold-squeeze) with a check that also watches speed. A first squeeze without a speed check once made one program twice as slow while its answers stayed right.
