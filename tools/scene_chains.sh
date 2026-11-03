#!/usr/bin/env bash
# End to end: Gold sentences -> goldc compose -> hcn build -> sandboxed run -> Amni-Form doc -> form_build check/build
# -> .glb (Y-up, meters) + .stl, then GLB header/JSON checks with bash+jq (no Python) and a golden-data compare.
# usage: scene_chains.sh record|verify   chains: tests/scene_chains/*.gold   golden: tests/scene_chains/golden.tsv
set -u
P0=$(cd "$(dirname "$0")/.." && pwd); MODE=${1:-verify}
GOLDC=${GOLDC:-$P0/build/goldc}; HCN=${HCN:-$HOME/ai/amni-lang/helium-gpu/build/hcn}; export HC_LIB=${HC_LIB:-$HOME/ai/amni-lang/helium-gpu/hc/lib}
FB=${FB:-$HOME/ai/mosaic/mosaic/form_build.mjs}; CAD=${CAD:-$HOME/.cache/mosaic/amni-cad}
W=$P0/build/scene_chains; mkdir -p $W; G=$P0/tests/scene_chains/golden.tsv; : > $W/now.tsv; bad=0
glbjson() { local n; n=$(od -An -tu4 -j12 -N4 "$1" | tr -d ' '); dd if="$1" bs=1 skip=20 count=$n status=none; }
for s in $P0/tests/scene_chains/*.gold; do c=$(basename ${s%.gold}); b=$W/$c
  if ! $GOLDC compose $s $P0 $b.amni > $b.compose 2>&1; then echo "$c unresolved: $(grep -m1 error $b.compose)"; bad=1; continue; fi
  if ! timeout 120 nice -n 15 $HCN build $b.amni -o $b.bin > $b.cerr 2>&1; then echo "$c compile_error: $(head -1 $b.cerr)"; bad=1; continue; fi
  ( ulimit -t 10; exec timeout 10 bwrap --ro-bind / / --tmpfs /tmp --proc /proc --dev /dev --unshare-all --die-with-parent $b.bin ) > $b.out 2>&1 || { echo "$c run failed"; bad=1; continue; }
  sed -n 's/^=> doc: //p' $b.out > $b.form
  jq -n --rawfile t $b.form --arg id $c --arg g $b.glb --arg s $b.stl '{op:"build",jobs:[{id:$id,text:$t,res:112,glb:$g,stl:$s}]}' | nice -n 15 node $FB $CAD > $b.build.json
  r=$(jq -c '.results[0]' $b.build.json)
  ok=$(jq -r '.ok' <<<"$r"); ne=$(jq '.errors|length' <<<"$r")
  [ "$ok" = true ] && [ "$ne" = 0 ] || { echo "$c form errors: $(jq -c .errors <<<"$r" | cut -c1-200)"; bad=1; continue; }
  magic=$(head -c4 $b.glb); ver=$(od -An -tu4 -j4 -N4 $b.glb | tr -d ' '); len=$(od -An -tu4 -j8 -N4 $b.glb | tr -d ' ')
  [ "$magic" = glTF ] && [ "$ver" = 2 ] && [ "$len" = "$(stat -c%s $b.glb)" ] || { echo "$c bad glb header"; bad=1; continue; }
  gj=$(glbjson $b.glb)
  # POSITION accessor bounds of the first mesh primitive; glTF is Y-up so doc Z extent must show up on glTF Y
  pmin=$(jq -c '[.meshes[0].primitives[0].attributes.POSITION as $a | .accessors[$a].min[] | .*100|round/100]' <<<"$gj")
  pmax=$(jq -c '[.meshes[0].primitives[0].attributes.POSITION as $a | .accessors[$a].max[] | .*100|round/100]' <<<"$gj")
  zext=$(jq '(.bbox.max[2]-.bbox.min[2])*100|round/100' <<<"$r"); yext=$(jq -n "$pmax[1]-$pmin[1] | .*100|round/100")
  nodes=$(jq '.nodes|length' <<<"$gj"); anims=$(jq '(.animations//[])|length' <<<"$gj"); skins=$(jq '(.skins//[])|length' <<<"$gj")
  stlb=$(stat -c%s $b.stl); stlt=$(od -An -tu4 -j80 -N4 $b.stl | tr -d ' ')
  yup=no; awk -v a=$zext -v b=$yext 'BEGIN{exit !((a-b)<0.05 && (b-a)<0.05)}' && yup=yes
  [ "$stlt" = "$(jq .tris <<<"$r")" ] && [ $stlb = $((84 + 50 * stlt)) ] || { echo "$c stl mismatch"; bad=1; }
  # golden image: Mosaic review render (4 views) of the exported glb, hashed
  jq -nc --arg g $b.glb --arg o $b.review.png '{op:"review",jobs:[{glb:$g,out:$o,size:256}]}' | nice -n 15 timeout 120 node $FB $CAD > $b.review.json
  png=$( [ -s $b.review.png ] && [ "$(head -c8 $b.review.png | od -An -tx1 | tr -d " \n")" = 89504e470d0a1a0a ] && sha256sum < $b.review.png | cut -c1-16 || echo none)
  [ $png != none ] || { echo "$c review png missing"; bad=1; }
  printf '%s\t%s\t%s\n' $c "$(jq -r '[.items,.verts,.tris,.bones,(.anim_clips|map(.len)|join("/")),(.materials|join("/"))]|map(tostring)|join("\t")' <<<"$r")" "nodes=$nodes skins=$skins anims=$anims yup=$yup docZ=$zext glbY=$yext png_sha=$png doc_sha=$(sha256sum < $b.form | cut -c1-16)" >> $W/now.tsv
done
cat $W/now.tsv
if [ "$MODE" = record ]; then cp $W/now.tsv $G; echo "recorded $G"
elif diff $G $W/now.tsv; then echo "golden match"; else echo "GOLDEN MISMATCH"; bad=1; fi
exit $bad
