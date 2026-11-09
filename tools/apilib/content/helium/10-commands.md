# Commands and options

The compiler is one command, `hc`. Run `hc help` to print this list in short form.

```
hc <command> file [options] [-- program args...]
hc file [options] [-- program args...]
```

## Commands

| Command | What it does |
|---|---|
| `hc run` | Compile natively into the cache and run the program. `hc file` does the same. |
| `hc build` | Build an executable: `-o out` for native, `-o out.c` for C, `--web` for WebAssembly. |
| `hc check` | Parse and typecheck only. |
| `hc fetch` | Clone the git packages the program declares. |
| `hc lsp` | Run the language server: diagnostics, hover, definition, references, rename, symbols, completion, signature help and inlay hints. |
| `hc version` | Print the version. |
| `hc help` | Print the short help. |

## Options

| Option | Meaning |
|---|---|
| `-o path` | Output path for `build`. The default is the file's name without its extension. |
| `--debug` | Add overflow, range and tag checks that name the source line. |
| `-DNAME=V` | Set a runtime define. |
| `--offline` | Fetch no packages. A package missing from the cache is an error. |
| `--include file.h` | Build the C that the program's extern functions come from into a shared library with `cc`. |
| `--c` | Build C instead of a native executable. |
| `--web` | Build WebAssembly, and write the `helium.js` host beside it. |
| `--v3` | Target x86-64-v3 (Haswell and later): AVX2 vector code and three-operand scalar floats. |
| `--v4` | Target x86-64-v4: `--v3` plus AVX-512 integer-lane vector code. |
| `--vhost` | Pick `--v4`, `--v3` or neither from this machine's CPU, like `-march=native`. |
| `--all` | With `check`: also check every typed function nothing calls. |
| `--update` | With `fetch`: fetch tags and branches again. |

## Packages

A program declares a git package right in its import line:

```amni
import name from "owner/repo@ref";
```

`hc fetch file` clones what a program declares, and a build fetches anything missing unless you pass `--offline`.

## Environment variables

| Variable | Meaning |
|---|---|
| `HC_LIB` | The library folder. By default, `lib` beside `hc`, then `hc/lib`. |
| `HELIUM_HOME` | Where saved lookup tables live, instead of `~/.helium`. |
| `HELIUM_GPU` | `off` keeps lookup-table fills on the CPU. `discrete` prefers the discrete GPU. |
| `HELIUM_GPU_MIN_MS` | How long a CPU fill must take before the GPU takes over. The default is 30 ms. |
| `HELIUM_GPU_LOG` | `1` reports what ran where. `2` also writes each table's compute shader. |
