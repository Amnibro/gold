# Commands

Run `gold` with no arguments to print this list in short form. Options use the form `name=value`.

| Command | What it does |
|---|---|
| `gold build` | Translate, check and write the Helium. |
| `gold run` | Build, then run the program. |
| `gold show` | Build, then print the Helium. |
| `gold test` | Build, then run the test commands of every pack it uses. |
| `gold port` | Write Gold for existing code in any language, then build it. |
| `gold pack` | Index a product's Helium functions so Gold can call them. |
| `gold packs` | List the indexed packs. |
| `gold find` | Show which functions a sentence would retrieve. |
| `gold compact` | Pack data tables without a model call. |
| `gold squeeze` | Shorten the Gold and keep it only if it still passes. |

## Build and run

### gold build

```
gold build file.gold
```

Translates the paragraphs that changed, checks the whole file with the Helium compiler, and writes the Helium next to the Gold file, or to the `into` path from its header. Results are cached in `file.gold.lock`, so an unchanged paragraph never calls the model again. Commit the lock file with your code.

### gold run

```
gold run file.gold [-- program arguments]
```

Builds the file, then runs the program. Everything after `--` goes to your program.

### gold show

```
gold show file.gold
```

Builds the file, then prints the Helium it produced.

### gold test

```
gold test file.gold
```

Builds the file, then runs the test command of every pack named on its `use` line.

## Bring in existing code

### gold port

```
gold port source [use=pack,pack] [into=file] [lang=amni|he|py] [ns=name] [gold=out.gold]
```

Reads code in any language, writes the Gold that describes it, and builds that Gold.

| Option | Meaning |
|---|---|
| `use=` | Packs the new code may call, separated by commas. |
| `into=` | The Helium file to write. |
| `lang=` | The Helium flavor to write: `amni`, `he` or `py`. |
| `ns=` | The namespace for the new code. |
| `gold=` | Where to save the Gold. By default it sits beside the source, named after it. |

### gold squeeze

```
gold squeeze file.gold check='command' [rounds=4]
```

Shortens the Gold as far as it will go. Each shorter version is rebuilt from scratch and kept only when your check command exits with 0. Use a check that also watches speed, so a shorter version can never make your program slower.

### gold compact

```
gold compact file.gold
```

Packs the data tables in a file, with no model call. It adds a first `@` row of column scales, and a blank cell repeats the cell above. See [data tables](/api-library/gold/format#data-tables).

## Work with packs

### gold pack

```
gold pack name folder [lang=] [main=] [test=] [skip=]
```

Indexes every top-level function, type and global in a Helium folder into `packs/name`, so Gold can find and call them. See [Packs](/api-library/gold/packs).

| Option | Meaning |
|---|---|
| `lang=` | The product's Helium flavor. |
| `main=` | The product's root file, used to check new code in place. |
| `test=` | The command `gold test` runs. |
| `skip=` | A regular expression of files to leave out. |

### gold packs

```
gold packs
```

Lists each pack with its language, symbol count and folder.

### gold find

```
gold find pack,pack words to look up
```

Shows which functions a sentence would retrieve. Use it to check that a paragraph points Gold at the code you meant.
