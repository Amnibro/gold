# Gold generator tooling

`ctl.sh` is the controller that runs as the systemd user service `rikku-gold-gen.service`
(Nice=15, idle IO, CPUWeight=20, MemoryMax=4G). It is installed at `~/.cache/rikku/gold-gen/ctl.sh`.

- **Supervisor** (the service's main process): spawns `NMAX` room workers, decides how many are
  active, takes snapshots, runs the mass-deletion guard, writes `progress.json`.
- **Workers** (`ctl.sh worker N`): one Braid room each (`rikku-gold-gen-N`, header `X-Braid-Room`),
  own folder `~/.cache/rikku/gold-gen/rooms/N/{turns,tmp}`. Gemini only ever returns plain text;
  the verifier (goldc check -> global dedup -> `hcn build` at nice 15 with a 60s timeout -> run in a
  bwrap sandbox with no network, read-only root, 10s CPU -> byte-exact output compare) is the only
  thing that writes to `lib/gen`, `lib/index.tsv` and `data/conversational`.
- **Vocabulary slices**: with K rooms active, room i only suggests verbs whose index % K == i-1.
  Global dedup (`state/keys`, `nkeys`, `combos`, phrase shapes in `lib/index.tsv`) is re-checked
  under an flock right before an entry is appended.
- **Fair share for Tidus**: every 15s the supervisor looks for agy processes that Braid did not start
  (Tidus running agy directly) or more Braid-spawned agy processes than our busy rooms (another room
  using Google). If seen in the last `HOLD`=600s, only room 1 runs, with a 120s gap between turns.
  A rate-limit reply also drops to 1 room for 30 minutes.
- **Snapshots** (`~/.cache/rikku/snapshots/gold/`, read-only): every 30 min a normal git commit plus
  tag `snap-YYYYMMDD-HHMM` and `state-<tag>.tar.gz`; hourly `full-<tag>.tar.gz` (repo incl. .git +
  controller state). Last 48 tarballs of each kind are kept. History is append-only (no resets).
- **Deletion guard**: if the file count or byte count (or, every 10 min, the line count) of `lib/`,
  `data/` or the dedup state drops, or `.git` disappears, all rooms pause, the damaged tree is copied
  to `~/.cache/rikku/snapshots/gold-incidents/<time>/`, and the latest snapshot is restored.

Manual: `ctl.sh snapshot`, `ctl.sh restore [snap-tag]`, `ctl.sh guard`.
