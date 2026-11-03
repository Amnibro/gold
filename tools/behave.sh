#!/usr/bin/env bash
# Behavioural tools for Gold entries (not wired into the live generator).
#   behave.sh probe ENTRIES.gold OUTDIR   run every entry on a fixed probe set -> OUTDIR/sig.tsv (id kind verb modifier sig in out)
#   behave.sh dup   OUTDIR                group entries whose probe behaviour is identical -> dups.tsv (exit 1 if any)
#   behave.sh mods  OUTDIR                check that verb/modifier claims hold on the probe outputs -> mods.tsv (exit 1 if any)
# Probes ignore the entry's own tests: every step runs on the same lists/slots, so two entries that differ only in
# wording collapse to one signature, and an entry whose behaviour contradicts its modifier is flagged.
set -u
P0=$(cd "$(dirname "$0")/.." && pwd)
GOLDC=${GOLDC:-$P0/build/goldc}; PRE=${PRE:-$P0/runtime/prelude.amni}
HCN=${HCN:-$HOME/ai/amni-lang/helium-gpu/build/hcn}; export HC_LIB=${HC_LIB:-$HOME/ai/amni-lang/helium-gpu/hc/lib}
V2A='reals=1.5,-2.0,3.25,0.5 words=pear,fig,pear,kiwi vecs=1:2:2,3:4:0,0:0:5 map=1:2,3:4 recs=1:2.5:ab,2:0.5:cd,3:7.25:ab text="the quick brown fox"'
V2B='reals=10.0,-0.25 words=zeta,alpha vecs=1:0:0,0:1:0 map=7:1,2:9,4:4 recs=4:1.0:x,5:3.5:y,6:-1.0:x text="level"'
PROBES=("list=5,3,9,3,1,-2,12,7,30,15 input=7 $V2A" "list=4,4,0,11,22,-6,121 input=-6 $V2B" "list=8 input=9" "list=2,4,6,10 input=12" "list=-3,-5,25,1 input=121" "list=0,100,200,9 input=30" "list=13,31,7 input=0")
IN1="5,3,9,3,1,-2,12,7,30,15|4,4,0,11,22,-6,121|8|2,4,6,10|-3,-5,25,1|0,100,200,9|13,31,7"
SLOTS="k=2 t=4 lo=0 hi=10 w=\"a\" x=double p=is_even n=3"
ARGS="-7,-1,0,1,2,3,7,10,12,121"
mode=$1
probe() { IN=$1; W=$2; mkdir -p $W/e $W/h; rm -f $W/e/*; : > $W/sig.tsv
  awk -v d=$W/e '/^@entry /{k=$2; f=d"/"k".gold"} f!=""{print > f} /^@end/{close(f); f=""}' "$IN"
  for e in $W/e/*.gold; do k=$(basename $e .gold)
    kind=$(awk '/^kind:/{print $2; exit}' $e); verb=$(awk '/^verb:/{print $2; exit}' $e); mod=$(sed -n 's/^modifier: //p' $e | head -1 | tr ' ' _)
    ctx=$(awk '/^context:/{print $2; exit}' $e)
    slots=""; for s in $(awk '/^slot:/{print $2}' $e); do for kv in $SLOTS; do [ "${kv%%=*}" = $s ] && slots="$slots $kv"; done; done
    tl=""; if [ "$kind" = step ]; then for p in "${PROBES[@]}"; do tl+="test: $p$slots"$'\n'"expect: x"$'\n'; done
    else tl="test: arg=$ARGS"$'\n'; for i in $(seq 10); do tl+="expect: x"$'\n'; done; fi
    awk -v tl="$tl" '/^(test|expect):/{next} /^code:/{printf "%s", tl} {print}' $e > $W/p.gold
    t=$W/h/$k; rm -rf $t; mkdir -p $t; outs=""
    if n=$($GOLDC harness $W/p.gold $PRE $t 2>/dev/null); then
      for ((i=0;i<n;i++)); do b=$t/t$i
        if timeout 60 nice -n 15 ionice -c3 $HCN build $b.amni -o $b.bin > /dev/null 2>&1; then
          o=$( ( ulimit -t 10; exec timeout 10 bwrap --ro-bind / / --tmpfs /tmp --proc /proc --dev /dev --unshare-all --die-with-parent $b.bin ) 2>/dev/null | sed 's/ s="[^"]*"//' | tr '\n' '~')
        else o=BUILD_FAIL; fi; outs+="$o|"
      done
    else outs=HARNESS_FAIL; fi
    rm -rf $t
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$k" "$kind" "$verb" "$mod" "$ctx" "$(printf '%s' "$outs" | sha1sum | cut -c1-16)" "$outs" >> $W/sig.tsv
  done; wc -l < $W/sig.tsv; }
dup() { W=$1
  awk -F'\t' '$7 !~ /FAIL/{g[$6]=g[$6] " " $1; c[$6]++} END{for (s in g) if (c[s] > 1) print s "\t" c[s] "\t" g[s]}' $W/sig.tsv | sort -k2,2nr > $W/dups.tsv
  echo "groups=$(wc -l < $W/dups.tsv) redundant=$(awk -F'\t' '{r += $2 - 1} END{print r+0}' $W/dups.tsv)"; [ ! -s $W/dups.tsv ]; }
mods() { W=$1; export IN1
  # res=[...] lists of the three probes vs the probe inputs; checks: sort asc/desc ordered, permutation for sort/reverse,
  # dedupe unique, keep/remove honour the predicate modifier.
  awk -F'\t' '
  function resl(o, A,   m, s) { if (!match(o, /res=\[[^]]*\]/)) return -1; s = substr(o, RSTART + 5, RLENGTH - 6); if (s == "") return 0; return split(s, A, ",") }
  function pred(p, x,   d, r, q) { if (p == "even") return x % 2 == 0; if (p == "odd") return x % 2 != 0; if (p == "positive") return x > 0; if (p == "negative") return x < 0
    if (p == "zero") return x == 0; if (p == "nonzero") return x != 0; if (p == "prime") { if (x < 2) return 0; for (d = 2; d * d <= x; d++) if (x % d == 0) return 0; return 1 }
    if (p == "square") { if (x < 0) return 0; r = int(sqrt(x) + 0.5); return r * r == x } if (p == "mult3") return x % 3 == 0; if (p == "mult5") return x % 5 == 0
    if (p == "under10") return x < 10; if (p == "overhundred") return x > 100; return -1 }
  BEGIN { NI = split(ENVIRON["IN1"], IN, "|") }
  $2 == "step" && $7 !~ /FAIL/ && $5 !~ /^(reals|words|vectors|map|records|text)$/ { n = split($7, O, "|"); bad = ""; perm = ($3 ~ /^(sort|reverse|order|arrange|shuffle)$/ || $4 ~ /^(sorted|ascending|descending|reversed)$/); ord = ($3 == "sort" || $4 ~ /^(sorted|ascending|descending)$/) && $4 !~ /(magnitude|digit|abs)/
    for (j = 1; j <= NI && j <= n; j++) { m = resl(O[j], R); if (m < 0) continue; ni = split(IN[j], I, ","); delete ci; delete co
      if (perm) { if (m != ni) bad = bad "len "; else { for (i = 1; i <= ni; i++) { ci[I[i]]++; co[R[i]]++ } for (x in ci) if (ci[x] != co[x]) bad = bad "notperm " }
        if (ord) for (i = 2; i <= m; i++) { if ($4 != "descending" && R[i] + 0 < R[i-1] + 0) bad = bad "unordered "; if ($4 == "descending" && R[i] + 0 > R[i-1] + 0) bad = bad "unordered " } }
      if ($3 == "dedupe") { delete u; for (i = 1; i <= m; i++) { if (R[i] in u) bad = bad "dup "; u[R[i]] = 1 } }
      if (($3 == "keep" || $3 == "remove") && pred($4, 0) >= 0) for (i = 1; i <= m; i++) { if ($3 == "keep" && !pred($4, R[i] + 0)) bad = bad "keepviol "; if ($3 == "remove" && pred($4, R[i] + 0)) bad = bad "removeviol " } }
    if (bad != "") print $1 "\t" $3 "\t" $4 "\t" bad }' $W/sig.tsv | awk -F'\t' '{split($4, a, " "); delete s; o = ""; for (i in a) if (!(a[i] in s)) { s[a[i]] = 1; o = o a[i] " " } print $1 "\t" $2 "\t" $3 "\t" o}' > $W/mods.tsv
  echo "violations=$(wc -l < $W/mods.tsv)"; [ ! -s $W/mods.tsv ]; }
case $mode in probe) probe $2 $3;; dup) dup $2;; mods) mods $2;; *) echo "usage: behave.sh probe|dup|mods ..."; exit 2;; esac
