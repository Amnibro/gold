# File format

A `.gold` file is a few header lines, then paragraphs of plain English separated by blank lines. Each paragraph describes one piece of the program.

```
use waystone
into game/progress.amni

Struct `Progress` holds level, xp into the level, xp the level needs, and the next prestige cost.

`progress_of(xp int, prestige int) Progress` builds it from total xp using the profile's level and prestige rules.

`progress_line(p Progress) byte[>..]` formats it as `Lv 7 (120/450 xp) - next prestige 3000`.
```

## Header lines

Header lines come before the first paragraph.

| Line | Meaning |
|---|---|
| `use a, b` | Packs or Helium library modules whose functions the code may call. |
| `into path` | The file to write, inside the product or as an absolute path. |
| `lang amni` | The Helium flavor to write: `amni`, `he` or `py`. Without it, Gold uses the flavor of the `into` file, then the product's, then `.amni`. |
| `dialect js` | Apply a source language's rules to every paragraph. See [Dialects](/api-library/gold/dialects). |

## Paragraphs

- Write one paragraph per unit: a type, a function, or the program's top level.
- Say what it does: inputs, result, rules, formats and edge cases.
- Put a name or signature in backticks only when other code calls it by exactly that name.
- Edit a paragraph and rebuild: only that paragraph is translated again.

## Exact Helium

When you need exact code, use a fence. Gold keeps it as written.

````
```amni
fn clamp01(x real) real { min(max(x, 0.0), 1.0) }
```
````

Fences can be marked `amni` or `he`.

## Data tables

Rows of data go in a `table` fence. Gold turns the table into Helium itself, with no model call.

````
```table materials Material
steel | 7850 | 200e9
"     | 7870 | 205e9
```
````

This makes a function `materials()` that returns the rows as `Material` values.

| Cell | Meaning |
|---|---|
| Cells split on `|` | Cells follow the struct's field order. |
| `"` or a blank cell | Repeats the cell above. |
| `''` | An empty string. |
| Single quotes | Keeps a cell that looks like a number, or starts with `#`, as text. |
| First `@` row | Column scales added by `gold compact`: `e9` appends an exponent, and `.` marks a real column so `7870` means `7870.0`. |

## Expected output

End a standalone program with `expect:` and the exact lines it must print. Gold runs the program and repairs it until the output matches.

```
expect:
the: 4
cat: 2
```

## Comments

A line that starts with `#` is a comment.
