#!/bin/sh
set -e
g=$(cd "$(dirname "$0")/.." && pwd); o=${1:?out dir}; mkdir -p "$o"
cd "$g"
find "$o" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
f=$(git ls-files README.md GOLD.md gold gold.amni goldc.amni .gitignore dialects primers spec lib runtime examples tools tests/scene_chains tests/texture_chains tests/test_gold.amni packs/std demos/wordfreq.gold demos/wordfreq.amni demos/port-units bench/rewrite/price bench/rewrite/cad; git ls-files codex | grep -v '^codex/dyn/'; git ls-files bench/rewrite | grep -E '^bench/rewrite/[^/]+$|^bench/rewrite/[^/]+/meta\.json$')
rsync -a --exclude "*.log" --files-from=- . "$o" <<L
$f
L
sed -i "s|^dir .*|dir ../helium/hc/lib|" "$o/packs/std/pack.conf"
