# Settings

Gold reads these environment variables.

| Variable | Default | Meaning |
|---|---|---|
| `GOLD_HELIUM` | `~/ai/amni-lang/helium` | Which Helium checkout to check against. |
| `GOLD_HC` | `build/hc` in `GOLD_HELIUM` | The Helium compiler to use. |
| `GOLD_HC_LIB` | `hc/lib` in `GOLD_HELIUM` | The Helium library folder to use. |
| `GOLD_ROOT` | The resource folder, if it has a `packs` folder; otherwise `~/ai/amni-lang/gold` | Where Gold's files are found. |
| `GOLD_MODEL` | `sonnet` | The model that writes the Helium. `granite` or `local:<name>` uses a local llama-server instead. |
| `GOLD_MODEL_HARD` | `opus` | The model for the last repair round. |
| `GOLD_MODEL_PORT` | `opus` | The model that writes Gold from existing code. |
| `GOLD_MODEL_FALLBACK` | `sonnet` | Takes over from a local model after its repair rounds, or when it is unavailable. |
| `GOLD_LOCAL_URL` | `http://127.0.0.1:18790` | Where the local llama-server listens. |
| `GOLD_LOCAL_UNIT` | `amni-bonsai.service` | The service that starts the local llama-server. |
| `GOLD_LOCAL_WAIT` | `120` | Seconds to wait for the GPU before using the local model. |
| `GOLD_LOCAL_ROUNDS` | `2` | How many repair rounds the local model gets. |
| `GOLD_TRIES` | `4` | Repair rounds. This extends up to 10 while each round changes the errors. |
| `GOLD_K` | `70` | How many product functions the model sees per build. |
| `GOLD_CACHE` | `~/.cache/gold` | The cache folder. |
| `GOLD_VERBOSE` | Off | Print each step. Set it to any non-empty value to turn it on. |
| `GOLD_LINT` | Off | Set it to `warn` to build lines that still read as code instead of stopping. |
