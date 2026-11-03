#!/usr/bin/env bash
# Split verified scene entries (verify_entries.sh ok.gold) into per-context shards and append their index rows.
# usage: [DOMAINS="scene env char cad"] shard_domains.sh OK.gold   (run from the repo root; replaces those shards and their index rows)
set -eu
OK=$1; DOMAINS=${DOMAINS:-scene env char cad}; RE=$(tr " " "|" <<<"$DOMAINS"); T=$(mktemp -d -p build); trap 'rm -rf $T' EXIT
grep -v -E "lib/pack/($RE)-" lib/pack/index.tsv > $T/base.tsv || true; cp $T/base.tsv lib/pack/index.tsv
for d in $DOMAINS; do
  awk -v c=$d '/^@entry/{buf=""; keep=0} {buf=buf $0 "\n"} /^context: /{keep=($2==c)} /^@end/{if(keep) printf "%s\n", buf; buf=""}' $OK > lib/pack/$d-0001.gold
  mkdir -p $T/e; rm -f $T/e/*
  awk -v t=$T/e '/^@entry /{f=t"/"$2".gold"} f!=""{print > f} /^@end/{close(f); f=""}' lib/pack/$d-0001.gold
  for e in $T/e/*.gold; do build/goldc index $e lib/pack/$d-0001.gold $(basename $e .gold); done >> lib/pack/index.tsv
  echo "$d $(grep -c '^@entry' lib/pack/$d-0001.gold) entries"
done
echo "index rows $(wc -l < lib/pack/index.tsv), duplicate shapes $(cut -f1 lib/pack/index.tsv | sort | uniq -d | wc -l)"
