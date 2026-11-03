#!/usr/bin/env bash
# Verify a file of Gold entries through the standard hc harness, one at a time, sequentially and niced.
# usage: verify_entries.sh ENTRIES.gold OUTDIR   -> OUTDIR/ok.gold OUTDIR/report.tsv
# env: GOLDC PRE HCN HC_LIB INDEX (existing lib index; entries whose phrase shapes collide are trimmed)
set -u
IN=$1; W=$2
P0=$(cd "$(dirname "$0")/.." && pwd)
GOLDC=${GOLDC:-$P0/build/goldc}; PRE=${PRE:-$P0/runtime/prelude.amni}
HCN=${HCN:-$HOME/ai/amni-lang/helium-gpu/build/hcn}; export HC_LIB=${HC_LIB:-$HOME/ai/amni-lang/helium-gpu/hc/lib}
INDEX=${INDEX:-$P0/lib/index.tsv}
mkdir -p $W/e; rm -f $W/e/*.gold; : > $W/report.tsv; : > $W/ok.gold
awk -v d=$W/e '/^@entry /{k=$2; f=d"/"k".gold"} f!=""{print > f} /^@end/{close(f); f=""}' "$IN"
# existing shapes
cut -f1 "$INDEX" 2>/dev/null | sort -u > $W/old-shapes.txt
for e in $W/e/*.gold; do
  k=$(basename $e .gold); res=ok
  # trim phrases whose shape is already taken by the live index
  if [ -s $W/old-shapes.txt ]; then
    $GOLDC index $e x.gold $k > $W/idx.tmp 2>/dev/null || true
    if [ -s $W/idx.tmp ]; then
      awk -F'\t' 'NR==FNR{old[$1]=1; next} ($1 in old){print $1}' $W/old-shapes.txt $W/idx.tmp > $W/clash.tmp
      if [ -s $W/clash.tmp ]; then
        # drop phrase lines whose own index shape clashes (index writes one row per phrase, in order)
        awk -F'\t' 'NR==FNR{c[$1]=1; next} {print ($1 in c) ? 1 : 0}' $W/clash.tmp $W/idx.tmp > $W/drop.tmp
        awk 'NR==FNR{d[NR]=$1; next} /^phrase: /{p++; if (d[p]==1) next} {print}' $W/drop.tmp $e > $e.t && mv $e.t $e
        echo -e "$k\ttrimmed\t$(paste -sd'|' $W/clash.tmp)" >> $W/report.tsv
      fi
    fi
  fi
  if ! out=$($GOLDC check $e 2>&1); then res="check:$(head -1 <<<"$out" | cut -c1-80)"
  else
    t=$W/h-$k; rm -rf $t; mkdir -p $t
    if ! n=$($GOLDC harness $e $PRE $t 2>&1); then res="harness:$(head -1 <<<"$n"|cut -c1-80)"
    else
      for ((i=0;i<n;i++)); do b=$t/t$i
        timeout 60 nice -n 15 ionice -c3 $HCN build $b.amni -o $b.bin > $b.cerr 2>&1 || { res=compile_error; break; }
        ( ulimit -t 10; exec timeout 10 bwrap --ro-bind / / --tmpfs /tmp --proc /proc --dev /dev --unshare-all --die-with-parent $b.bin ) > $b.out 2>/dev/null; rc=$?
        if [ $rc != 0 ] && [ $rc != 3 ]; then res=runtime_rc$rc; break; fi
        cmp -s $b.out $b.expect || { res=wrong_output; break; }
      done
    fi
    [ "$res" = ok ] && rm -rf $t
  fi
  [ "$res" = ok ] && { cat $e >> $W/ok.gold; echo >> $W/ok.gold; }
  printf '%s\t%s\n' "$k" "$res" >> $W/report.tsv
done
grep -v $'\ttrimmed\t' $W/report.tsv | cut -f2 | sed 's/:.*//' | sort | uniq -c
