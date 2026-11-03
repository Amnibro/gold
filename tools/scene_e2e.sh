#!/usr/bin/env bash
# Golden-data check for Gold scene/env/char/cad entries: every test's expected `=> doc:` lines are fed to
# Mosaic's form_build (Amni-CAD/Amni-Form, read-only) as `check` (must have 0 errors) and `build` (mesh stats).
# usage: scene_e2e.sh record|verify [SHARDS...]   golden: lib/pack/golden/scene_e2e.tsv
# columns: entry test ok items errors verts tris bones clips bbox(2dp)
set -u
P0=$(cd "$(dirname "$0")/.." && pwd); MODE=${1:-verify}; shift || true
FB=${FB:-$HOME/ai/mosaic/mosaic/form_build.mjs}; CAD=${CAD:-$HOME/.cache/mosaic/amni-cad}
G=$P0/lib/pack/golden/scene_e2e.tsv; mkdir -p $(dirname $G)
[ $# -gt 0 ] || set -- $P0/lib/pack/scene-0001.gold $P0/lib/pack/env-0001.gold $P0/lib/pack/char-0001.gold $P0/lib/pack/cad-0001.gold
W=$(mktemp -d -p ${TMPW:-$P0/build}); trap 'rm -rf $W' EXIT
# one job per test with a non-empty doc: id = entry:testno, text = doc lines
awk '/^@entry /{e=$2; t=0} /^test:/{flush(); t++; d=""; okv=""} /^expect: => i=/{okv=($0 ~ /ok=true/)?"T":"F"}
     /^expect: => doc: /{sub(/^expect: => doc: /,""); d=d (d==""?"":"\n") $0}
     /^@end/{flush()}
     function flush(){ if (t>0 && d!="") { gsub(/\\/,"\\\\",d); gsub(/"/,"\\\"",d); gsub(/\n/,"\\n",d); printf "{\"id\":\"%s:%d:%s\",\"text\":\"%s\",\"res\":96}\n", e, t, okv, d }; d="" }' "$@" > $W/jobs.jsonl
n=$(wc -l < $W/jobs.jsonl)
jq -s '{op:"check",jobs:.}' $W/jobs.jsonl | nice -n 15 node $FB $CAD > $W/check.json
jq -s '{op:"build",jobs:.}' $W/jobs.jsonl | nice -n 15 node $FB $CAD > $W/build.json
jq -r --slurpfile c $W/check.json '.results[] as $b | ($c[0].results[] | select(.id==$b.id)) as $k |
  ($b.id|split(":")) as $p |
  [$p[0], $p[1], $p[2], ($k.items|tostring), (($k.errors|length)|tostring), ($b.verts//0|tostring), ($b.tris//0|tostring), ($b.bones//0|tostring),
   (($b.anim_clips//[])|map(.len)|map(tostring)|join("/")),
   (if $b.bbox then ([$b.bbox.min[],$b.bbox.max[]]|map(.*100|round/100|tostring)|join(",")) else "-" end)] | @tsv' $W/build.json | sort > $W/now.tsv
errs=$(awk -F'\t' '$5!=0' $W/now.tsv | wc -l)
echo "jobs=$n check_errors_jobs=$errs"
[ $errs = 0 ] || { jq -r '.results[] | select((.errors|length)>0) | "\(.id)\t\(.errors|tostring)"' $W/check.json | cut -c1-240 | head -40; }
# mesh sanity: a doc with an additive shape line must mesh to verts > 0
jq -r --slurpfile b $W/build.json '. as $j | ($j.text|split("\n")|map(split(" "))|map(select(length>1 and (.[1]|IN("sphere","ellipsoid","box","capsule","cyl","torus","cone","prism","pyramid","wedge","tube","lathe","extrude")) and (index("-")==null) and (index("&")==null)))|length) as $ns |
  ($b[0].results[]|select(.id==$j.id)) as $r | select($ns>0 and (($r.verts//0)==0)) | "\($j.id)\tempty_mesh"' $W/jobs.jsonl > $W/empty.txt
emp=$(wc -l < $W/empty.txt); echo "empty_mesh_jobs=$emp"; [ $emp = 0 ] || head -20 $W/empty.txt
errs=$((errs + emp))
# self-reference lint (form check accepts a bone parented to itself): ^name or @name equal to the line's own name
jq -r '.id as $i | .text | split("\n")[] | split(" ") | select(length>1) | .[0] as $n | select(any(.[1:][]; . == ("^"+$n) or . == ("@"+$n))) | "\($i)\tself_ref \($n)"' $W/jobs.jsonl > $W/self.txt
sr=$(wc -l < $W/self.txt); echo "self_ref_jobs=$sr"; [ $sr = 0 ] || head -20 $W/self.txt
errs=$((errs + sr))
if [ "$MODE" = record ]; then cp $W/now.tsv $G; echo "recorded $(wc -l < $G) golden rows -> $G"
else if diff <(sort $G) $W/now.tsv > $W/diff.txt; then echo "golden match ($n)"; else echo "GOLDEN MISMATCH"; head -20 $W/diff.txt; exit 1; fi; fi
[ $errs = 0 ]
