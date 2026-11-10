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
| `gold compact` | Pack data tables into fewer tokens, or write them back out in full. No model call. |
| `gold squeeze` | Rewrite the Gold as shorter plain English and keep it only if it still passes. |
| `gold lint` | List lines that read as code instead of English. |

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

Rewrites the Gold as shorter plain English. Each shorter version is rebuilt from scratch and kept only when it rebuilds and your check command exits with 0. Use a check that also watches speed, so a shorter version can never make your program slower.

### gold lint

```
gold lint file.gold
```

Lists every line that reads as code: operators such as `==` or `&&`, function signatures and Helium types. `gold build` refuses these lines in paragraphs that changed. Set `GOLD_LINT=warn` to build anyway.

### gold compact

```
gold compact file.gold
gold compact file.gold wide
```

Packs the data tables in a file into fewer tokens, with no model call. It adds a first `@` row of column marks and leaves out cells that repeat the row above. With `wide`, it writes every table back out in full, ready to edit. See [packed tables](/api-library/gold/format#packed-tables).

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

## Environment variables

Environment variables change which models Gold uses and where it finds its tools.

### Models

| Variable | Default | Meaning |
|---|---|---|
| `GOLD_MODEL` | `sonnet` | The model that translates and repairs. `granite` or `local:<name>` uses the local llama-server. |
| `GOLD_MODEL_HARD` | `opus` | The model used for the last repair. |
| `GOLD_MODEL_PORT` | `opus` | The model used by `gold port`. |
| `GOLD_MODEL_FALLBACK` | `sonnet` | The model that takes over after the local model's repair rounds. |
| `GOLD_TRIES` | `4` | How many repair rounds to try. The limit extends up to 10 while each round changes the errors. |
| `GOLD_K` | `70` | An integer setting read at startup. |

### Local model

| Variable | Default | Meaning |
|---|---|---|
| `GOLD_LOCAL_URL` | `http://127.0.0.1:18790` | The address of the local llama-server. |
| `GOLD_LOCAL_UNIT` | `amni-bonsai.service` | The unit used to start the local server. |
| `GOLD_LOCAL_WAIT` | `120` | Seconds to wait for the GPU. |
| `GOLD_LOCAL_ROUNDS` | `2` | How many repair rounds the local model gets before `GOLD_MODEL_FALLBACK` takes over. |

If the local model is unavailable, the whole build falls back to `GOLD_MODEL_FALLBACK`.

### Paths and tools

| Variable | Default | Meaning |
|---|---|---|
| `GOLD_CACHE` | `~/.cache/gold` | The cache folder. |
| `GOLD_ROOT` | The installed resource folder if it contains `packs`, otherwise `~/ai/amni-lang/gold` | The Gold root folder. |
| `GOLD_HELIUM` | `~/ai/amni-lang/helium` | The Helium folder. |
| `GOLD_HC` | `$GOLD_HELIUM/build/hc` | The Helium compiler. |
| `GOLD_HC_LIB` | `$GOLD_HELIUM/hc/lib` | The compiler's library folder. |
| `GOLD_VERBOSE` | unset | Set to any non-empty value for verbose output. |
| `GOLD_LINT` | unset | Set to `warn` to build paragraphs that still read as code. |
