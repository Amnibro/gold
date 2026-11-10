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
| A short row | Cells left off the end repeat the cells above. A row that repeats every cell is a lone `"`. |
| `''` | An empty string. |
| Single quotes | Keeps a cell that looks like a number, or starts with `#`, as text. |

### Packed tables

Write a table in full. `gold compact file.gold` then packs it into fewer tokens, and Gold reads both forms the same way. A packed table starts with an `@` row that holds one mark per column.

````
```table bolts Bolt
@+|.2|.1|.|.1
M8 coarse|125|70|15000|88
10|150|85|24000
12|175|102|35000
14|200|120|48000
18|250|155|79000|109
20||175|101000
```
````

The second row reads `M10 coarse | 1.5 | 8.5 | 24000.0 | 8.8`.

| Mark | Meaning |
|---|---|
| `.` | A real column: `24000` means `24000.0`. |
| `.2` | The decimal point moves two places left: `125` means `1.25`. |
| `e9` | Every number gets the exponent: `200` means `200e9`. |
| `.1e9` | Both, the point first: `205` means `20.5e9`. |
| `+` | A text column whose rows differ in their first number. A cell that is only a number replaces that number in the cell above: `10` under `M8 coarse` means `M10 coarse`. |
| No mark | The cells are read as written. |

A number that carries its own exponent is read as written. `gold compact file.gold wide` writes every table back out in full, ready to edit. Packing it again gives the same packed table.

## Expected output

End a standalone program with `expect:` and the exact lines it must print. Gold runs the program and repairs it until the output matches.

```
expect:
the: 4
cat: 2
```

## Comments

A line that starts with `#` is a comment.
