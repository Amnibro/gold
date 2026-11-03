# Gold phrase packs (gold-phase0)

Every entry in these shards has been run through the hc harness: `goldc check`, then `goldc harness`, then `hcn build`, then a bwrap run, then a byte-exact compare of every `expect:` line. `index.tsv` holds one row per phrase shape: shape, kind, shard, entry id. It has 0 duplicate shapes, including against the live index.

| shard | context | entries | golden data |
|---|---|---|---|
| basic-0001..0004.gold | (core list/scalar/aggregate/query/…) | 1718 | exact report lines |
| scene-0001.gold | scene: lights, cameras, materials, shapes/placement, tracks, actions, timeline | 100 | exact Amni-Form doc lines, plus golden/scene_e2e.tsv mesh stats from form_build |
| env-0001.gold | env: terrain, scatter, water, roads | 19 | as scene |
| char-0001.gold | char: bones, IK/constraints | 15 | as scene |
| cad-0001.gold | cad: parts (plate, holes, gear, lathe, bevel) | 13 | as scene |
| texture-0001.gold | texture: grey 32x32 max image buffer generators and filters | 24 | `=> img:` stats line (min/max/8-bit sum/rolling hash) from an independent awk model |

## Regenerate
```
# basic pack: tools/gen (see tools/gen/README or the Phase-0 report)
gawk -f tools/pack/scene.awk tools/pack/scene.spec > /tmp/scene_all.gold       # scene/env/char/cad
gawk -f tools/pack/texture.awk tools/pack/texture.spec > /tmp/texture_all.gold # texture
INDEX=lib/pack/index.tsv tools/verify_entries.sh /tmp/scene_all.gold WORK/scene  # -> WORK/scene/ok.gold
tools/pack/shard_domains.sh WORK/scene/ok.gold                                   # scene env char cad shards + index rows
INDEX=lib/pack/index.tsv tools/verify_entries.sh /tmp/texture_all.gold WORK/tex
DOMAINS=texture tools/pack/shard_domains.sh WORK/tex/ok.gold
tools/scene_e2e.sh verify      # all scene/env/char/cad test docs -> form_build check+build, compare golden/scene_e2e.tsv
tools/scene_chains.sh verify   # tests/scene_chains/*.gold -> compose -> run -> .form -> glb/stl/png, compare golden.tsv
```
The generator writes an entry's Helium code and its awk reference model from the same template. The model alone produces the expected output, and the harness confirms that the compiled Helium code prints exactly the same text. A tampered expect fails as `wrong_output`; this negative control was checked for both scene and texture.
