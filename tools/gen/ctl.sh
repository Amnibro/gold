#!/usr/bin/env bash
# Gold generator controller v2: a supervisor plus N parallel Gemini rooms (Braid rooms rikku-gold-gen-1..N).
# Plumbing only. Gemini writes entries as plain-text replies; goldc (Helium) validates/indexes/composes;
# the real Helium compiler builds; a bwrap sandbox runs. Only this verifier writes into the repo.
#   ctl.sh                 supervisor (systemd): snapshots, deletion guard, Tidus fair share, spawns workers
#   ctl.sh worker N        one room's loop (spawned by the supervisor)
#   ctl.sh snapshot        take a snapshot now (git commit + tag + state tar + full tarball)
#   ctl.sh restore [TAG]   restore lib/ data/ and state from a snapshot tag (default: latest)
#   ctl.sh reverify DIR..  re-run verification on saved turn dirs
set -u
G=${GOLD_G:-$HOME/.cache/rikku/gold-gen}
ROOT=${GOLD_ROOT:-$HOME/ai/amni-lang/gold}
export HC_LIB=$HOME/ai/amni-lang/helium-gpu/hc/lib
HCN=$HOME/ai/amni-lang/helium-gpu/build/hcn
GOLDC=$G/bin/goldc
PRE=$ROOT/runtime/prelude.amni
IDX=$ROOT/lib/index.tsv
API=http://127.0.0.1:12100
ROOM_PREFIX=rikku-gold-gen
ST=$G/state            # GLOBAL dedup + accept/reject logs (shared by all rooms, guarded by flock)
RUN=$G/run             # supervisor <-> worker signals: active, pause, others
SNAP=${GOLD_SNAP:-$HOME/.cache/rikku/snapshots/gold}   # outside every room's folder; read-only
LOCK=$G/locks/accept.lock
PER_TURN=${PER_TURN:-14}
MIN_GAP=${MIN_GAP:-30}
SHARE_GAP=${SHARE_GAP:-120}
NMAX=${NMAX:-3}               # rooms when Tidus/others are idle
HOLD=${HOLD:-600}             # treat Tidus as active for this long after his agy was last seen
SNAP_EVERY=${SNAP_EVERY:-1800}   # git commit + tag + state tar
TAR_EVERY=${TAR_EVERY:-3600}     # full working-tree tarball
KEEP=${KEEP:-48}
mkdir -p $ST $RUN $G/rooms $G/logs $G/locks $ROOT/lib/gen $ROOT/data/conversational
touch $ST/keys $ST/nkeys $ST/combos $ST/accepts.log $ST/rejects.log $ST/scripts.keys $LOCK
[ -f $ST/shard ] || echo 1 > $ST/shard
[ -f $ST/started ] || date +%s > $ST/started
STOP=0; trap 'STOP=1' TERM INT
WHO=sup
log() { echo "$(date '+%F %T') [$WHO] $*" >> $G/logs/ctl.log; }
rej() { echo "$(date +%s) $1 $2" >> $ST/rejects.log; }
mapfile -t CONTEXTS < <(awk '/^\[/{s=$0;next} !/^#/&&NF&&s=="[contexts]"' $ROOT/spec/vocab.txt)
mapfile -t VERBS < <(awk '/^\[/{s=$0;next} !/^#/&&NF&&s=="[verbs]"' $ROOT/spec/vocab.txt)
mapfile -t NOUNS < <(awk '/^\[/{s=$0;next} !/^#/&&NF&&s=="[nouns]"' $ROOT/spec/vocab.txt)
mapfile -t MODS < <(awk '/^\[/{s=$0;next} !/^#/&&NF&&s=="[modifiers]"' $ROOT/spec/vocab.txt)
GIT() { git -C $ROOT -c user.name="Amnibro" -c user.email="99765883+Amnibro@users.noreply.github.com" "$@"; }

# ---------------------------------------------------------------- snapshots + deletion guard
snap_w() { chmod u+w $SNAP 2>/dev/null; }
snap_ro() { chmod -R a-w $SNAP 2>/dev/null; }
GUARD_FILES() { find $ROOT/lib $ROOT/data -type f 2>/dev/null; ls $ST/keys $ST/combos $ST/accepts.log 2>/dev/null; }
counts() { # files bytes [lines]: lines only when $1=1 (reads everything; done every LINES_EVERY s)
  local f b l=-1; f=$(GUARD_FILES | wc -l)
  b=$(GUARD_FILES | xargs -r stat -c %s 2>/dev/null | awk '{s+=$1} END{print s+0}')
  [ "${1:-0}" = 1 ] && l=$(GUARD_FILES | xargs -r cat 2>/dev/null | wc -l)
  echo "$f $b $l"; }
snapshot() { # $1 = 1 to force the full tarball too
  local tag n acc now
  mkdir -p $SNAP; now=$(date +%s)
  exec 9>$LOCK; flock 9
  acc=$(wc -l < $ST/accepts.log)
  GIT add lib data spec runtime goldc.amni examples tools 2>/dev/null
  GIT diff --cached --quiet || GIT commit -q -m "Gold gen snapshot: $acc verified conversational entries, $(wc -l < $ST/scripts.keys) scripts"
  tag=snap-$(date +%Y%m%d-%H%M); n=2; while GIT rev-parse -q --verify refs/tags/$tag >/dev/null; do tag=snap-$(date +%Y%m%d-%H%M)-$n; n=$((n+1)); done
  GIT tag $tag
  snap_w
  tar czf $SNAP/.state-$tag.tar.gz -C $G state && mv $SNAP/.state-$tag.tar.gz $SNAP/state-$tag.tar.gz
  if [ "${1:-0}" = 1 ] || (( now - $(cat $ST/last_tar 2>/dev/null || echo 0) >= TAR_EVERY )); then
    tar czf $SNAP/.full-$tag.tar.gz -C / "${ROOT#/}" "${ST#/}" \
      && mv $SNAP/.full-$tag.tar.gz $SNAP/full-$tag.tar.gz && echo $now > $ST/last_tar
  fi
  counts 1 > $ST/guard
  flock -u 9; exec 9>&-
  ls -1t $SNAP/state-*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
  ls -1t $SNAP/full-*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
  snap_ro
  echo $now > $ST/last_snap
  log "snapshot $tag commit $(GIT rev-parse --short HEAD) acc=$acc guard=$(cat $ST/guard)"
}
restore() { # $1 tag (default latest). Never resets history: restores files from the tag as a new working-tree state.
  local tag=${1:-} inc t
  touch $RUN/pause
  exec 9>$LOCK; flock 9
  inc=$SNAP-incidents/$(date +%Y%m%d-%H%M%S); mkdir -p $inc
  cp -a $ROOT/lib $ROOT/data $inc/ 2>/dev/null; cp -a $ST $inc/state 2>/dev/null
  if [ -d $ROOT/.git ] && GIT rev-parse -q --verify HEAD >/dev/null; then
    [ -n "$tag" ] || tag=$(GIT tag -l 'snap-*' --sort=-creatordate | head -1)
    if [ -n "$tag" ] && [ -f $SNAP/state-$tag.tar.gz ]; then
      GIT checkout $tag -- lib data
      GIT ls-files --others --exclude-standard -z lib data | (cd $ROOT && xargs -0 -r rm -f --)   # files born after the tag (copies kept in $inc)
      t=$(mktemp -d $G/locks/r.XXXXXX); tar xzf $SNAP/state-$tag.tar.gz -C $t && cp -a $t/state/. $ST/; rm -rf $t
      log "RESTORE from git tag $tag + state-$tag.tar.gz (damaged copy kept in $inc)"
    else tag=""; fi
  fi
  if [ -z "$tag" ]; then # git itself damaged: fall back to the newest full tarball
    t=$(ls -1t $SNAP/full-*.tar.gz 2>/dev/null | head -1)
    if [ -n "$t" ]; then
      local x; x=$(mktemp -d $G/locks/r.XXXXXX); tar xzf $t -C $x
      cp -a "$x/${ROOT#/}/." $ROOT/; cp -a "$x/${ST#/}/." $ST/; rm -rf $x
      log "RESTORE from tarball $t (damaged copy kept in $inc)"
    else log "RESTORE FAILED: no snapshot found; rooms stay paused"; flock -u 9; exec 9>&-; return 1; fi
  fi
  counts 1 > $ST/guard
  flock -u 9; exec 9>&-
  rm -f $RUN/pause
}
guard_check() { # mass deletion: file/byte/line count in lib/ data/ (or global dedup state) dropped below high-water mark
  local f0 b0 l0 f b l full=0
  [ -s $ST/guard ] || { counts 1 > $ST/guard; return; }
  read -r f0 b0 l0 < $ST/guard
  (( $(date +%s) - ${LAST_LINES:-0} >= ${LINES_EVERY:-600} )) && { full=1; LAST_LINES=$(date +%s); }
  read -r f b l < <(counts $full)
  if (( f < f0 || b < b0 || (full && l < l0) )) || [ ! -d $ROOT/.git ]; then
    log "DELETION DETECTED files $f0->$f bytes $b0->$b lines $l0->$l git=$([ -d $ROOT/.git ] && echo ok || echo missing); pausing all rooms and restoring"
    restore
  else
    (( full )) || l=$l0
    (( f != f0 || b != b0 || l != l0 )) && echo "$f $b $l" > $ST/guard
  fi
}

# ---------------------------------------------------------------- fair share
braid_pid() { pgrep -u "$USER" -f 'python3 delve_server.py' | head -1; }
others_seen() { # 0 if someone else (Tidus or another room) is using agy right now
  local bp p pp ours braid=0 busy
  bp=$(braid_pid)
  for p in $(pgrep -u "$USER" -x agy); do
    pp=$(ps -o ppid= -p $p | tr -d ' '); [ -n "$pp" ] || continue
    [ "$(ps -o comm= -p $pp)" = agy ] && continue           # agy's own children
    if [ -n "$bp" ] && [ "$pp" = "$bp" ]; then braid=$((braid+1)); else return 0; fi   # direct agy (Tidus)
  done
  busy=$(curl -s -m 10 -H "X-Braid-Room: $ROOM_PREFIX-1" $API/api/state | jq -r --arg p "$ROOM_PREFIX-" \
         '([.rooms[]?|select(.busy and ((.room|startswith($p))|not))]|length), ([.rooms[]?|select(.busy and (.room|startswith($p)))]|length)' 2>/dev/null | tr '\n' ' ')
  read -r ob ours <<<"$busy"
  (( ${ob:-0} > 0 && braid > ${ours:-0} )) && return 0      # another Braid room has agy running
  return 1
}

# ---------------------------------------------------------------- worker side
braid_state() { curl -s -m 20 -H "X-Braid-Room: $ROOM" $API/api/state; }
ask() { # $1 prompt file -> reply on stdout
  local before st busy who total i
  st=$(braid_state); [ "$(jq -r .room <<<"$st")" = "$ROOM" ] || { log "room not granted (got $(jq -r .room <<<"$st")); refusing to send"; return 1; }
  if (( TURN % 4 == 0 )); then curl -s -m 20 -X POST -H "X-Braid-Room: $ROOM" $API/api/clear >/dev/null; sleep 2; st=$(braid_state); fi
  before=$(jq '.transcript|length' <<<"$st")
  jq -n --rawfile t "$1" '{target:"google",text:$t}' | curl -s -m 30 -X POST -H "X-Braid-Room: $ROOM" -H 'Content-Type: application/json' --data @- $API/api/send >/dev/null
  for ((i=0;i<150;i++)); do
    sleep 10; [ $STOP = 1 ] && return 1
    st=$(braid_state) || continue
    busy=$(jq -r '.busy' <<<"$st"); total=$(jq '.transcript|length' <<<"$st"); who=$(jq -r '.transcript[-1].who' <<<"$st")
    if [ "$busy" = false ] && [ "$total" -ge $((before+2)) ] && [ "$who" = Google ]; then
      jq -r '.transcript[-1].text' <<<"$st"; return 0
    fi
  done
  return 1
}
dupcheck() { # key nkey combo shapes-file -> reason or empty
  grep -qxF "$1" $ST/keys && { echo dup_exact; return; }
  grep -qxF "$2" $ST/nkeys && { echo near_dup; return; }
  grep -qxF "$3" $ST/combos && { echo dup_combo; return; }
  local sh; while IFS= read -r sh; do cut -f1 $IDX | grep -qxF "$sh" && { echo dup_phrase; return; }; done < "$4"
}
verify_and_accept() { # $1 entry file, $2 turn dir
  local e=$1 td=$2 out key nkey combo b n rc shard rel kind ctx t r
  out=$($GOLDC check "$e" 2>&1) || { rej "$(cut -d' ' -f2 <<<"${out%%$'\n'*}")" "$e"; return; }
  key=$(awk '$1=="key"{print $2}' <<<"$out"); nkey=$(awk '$1=="nkey"{print $2}' <<<"$out")
  combo=$(awk '$1=="combo"{print $2}' <<<"$out"); kind=$(awk '$1=="ok"{print $2}' <<<"$out")
  sed -n 's/^shape //p' <<<"$out" > $e.shapes
  r=$(dupcheck "$key" "$nkey" "$combo" $e.shapes); [ -n "$r" ] && { rej $r "$e"; return; }
  t=$(mktemp -d $TMPD/h.XXXXXX)
  n=$($GOLDC harness "$e" $PRE $t) || { rej "$(cut -d' ' -f2 <<<"$n")" "$e"; rm -rf $t; return; }
  for ((k=0;k<n;k++)); do
    b=$t/t$k
    if ! timeout 60 nice -n 15 ionice -c3 $HCN build $b.amni -o $b.bin > $b.cerr 2>&1; then
      rej compile_error "$e"; cp $b.cerr $td/$(basename $e).cerr 2>/dev/null; rm -rf $t; return
    fi
    ( ulimit -t 10; exec timeout 10 bwrap --ro-bind / / --tmpfs /tmp --proc /proc --dev /dev --unshare-all --die-with-parent $b.bin ) > $b.out 2> $b.err
    rc=$?
    if [ $rc = 3 ] && [ "$(wc -l < $b.out)" -le 1 ]; then rej noop_step "$e"; rm -rf $t; return; fi
    if [ $rc != 0 ] && [ $rc != 3 ]; then rej runtime_error "$e"; rm -rf $t; return; fi
    if ! cmp -s $b.out $b.expect; then
      rej wrong_output "$e"; { echo "--- got"; cat $b.out; echo "--- expected"; cat $b.expect; } > $td/$(basename $e).diff; rm -rf $t; return
    fi
    [ -s $b.expect ] || { rej empty_output "$e"; rm -rf $t; return; }
  done
  rm -rf $t
  # accept: global dedup re-checked under the lock so parallel rooms can never both add the same thing
  exec 9>$LOCK; flock 9
  r=$(dupcheck "$key" "$nkey" "$combo" $e.shapes)
  if [ -n "$r" ]; then rej $r "$e"; flock -u 9; exec 9>&-; return; fi
  shard=$(cat $ST/shard); rel=$(printf 'lib/gen/shard-%04d.gold' $shard)
  if [ -f $ROOT/$rel ] && [ "$(grep -c '^@entry ' $ROOT/$rel)" -ge 2000 ]; then shard=$((shard+1)); echo $shard > $ST/shard; rel=$(printf 'lib/gen/shard-%04d.gold' $shard); fi
  { echo "@entry $key"; tail -n +2 "$e"; } >> $ROOT/$rel
  $GOLDC index "$e" $rel $key >> $IDX
  echo "$key" >> $ST/keys; echo "$nkey" >> $ST/nkeys; echo "$combo" >> $ST/combos
  ctx=$(cut -d'|' -f1,5 <<<"$combo")
  echo "$(date +%s) $key $ctx $RID" >> $ST/accepts.log
  jq -cn --arg id "$key" --arg combo "$combo" --arg rel "$rel" \
     --rawfile src "$e" '{id:$id, combo:$combo, file:$rel,
        phrases:([$src|split("\n")[]|select(startswith("phrase:"))|sub("^phrase:\\s*";"")]),
        code:($src|split("\ncode:\n")[1]|sub("@end\\s*$";""))}' >> $ROOT/data/conversational/entries.jsonl
  flock -u 9; exec 9>&-
}
verify_script() { # $1 script file (body), $2 expect file
  local s=$1 x=$2 t key rc
  key=$(tr 'A-Z' 'a-z' < $s | tr -s ' \t' ' ' | md5sum | cut -c1-16)
  grep -qxF "$key" $ST/scripts.keys && { rej script_dup "$s"; return; }
  t=$(mktemp -d $TMPD/s.XXXXXX)
  $GOLDC compose $s $ROOT $t/p.amni > $t/c.out 2>&1 || { rej script_unresolved "$s"; cp $t/c.out $s.err; rm -rf $t; return; }
  timeout 60 nice -n 15 ionice -c3 $HCN build $t/p.amni -o $t/p.bin > $t/cerr 2>&1 || { rej script_compile "$s"; rm -rf $t; return; }
  ( ulimit -t 10; exec timeout 10 bwrap --ro-bind / / --tmpfs /tmp --proc /proc --dev /dev --unshare-all --die-with-parent $t/p.bin ) > $t/out 2>/dev/null
  rc=$?
  [ $rc != 0 ] && { rej script_runtime "$s"; rm -rf $t; return; }
  cmp -s $t/out $x || { rej script_wrong_output "$s"; { echo "--- got"; cat $t/out; echo "--- expected"; cat $x; } > $s.diff; rm -rf $t; return; }
  exec 9>$LOCK; flock 9
  if grep -qxF "$key" $ST/scripts.keys; then rej script_dup "$s"
  else echo "$key" >> $ST/scripts.keys
    jq -cn --rawfile script $s --rawfile output $t/out '{script:$script, output:$output}' >> $ROOT/data/conversational/scripts.jsonl; fi
  flock -u 9; exec 9>&-
  rm -rf $t
}
pick_combos() { # $1 kind  $2 context $3 slice index $4 slice count -> "verb noun modifier"
  local c=0 tries=0 v nn m vs=() i
  for ((i=0;i<${#VERBS[@]};i++)); do (( i % $4 == $3 )) && vs+=("${VERBS[i]}"); done
  while (( c < PER_TURN + 4 && tries < 400 )); do
    tries=$((tries+1))
    v=${vs[RANDOM % ${#vs[@]}]}; nn=${NOUNS[RANDOM % ${#NOUNS[@]}]}; m=${MODS[RANDOM % ${#MODS[@]}]}
    grep -qxF "$1|$v|$nn|$m|$2" $ST/combos && continue
    echo "$v $nn $m"; c=$((c+1))
  done
}
script_prompt() {
  echo "REPLY WITH PLAIN TEXT ONLY. Do NOT run any tools, shell commands, file reads or edits. Do not create, change or delete any file."
  echo "Gold turns conversational scripts into Helium programs. Write 4 different scripts using ONLY the phrases listed below ({} = a bound name, a number, or a \"quoted\" string)."
  echo "Bindings: 'name = <fn/pred phrase>' (e.g. x = collatz step), 'input = 27', 'list = 3,1,2', 'text = \"hello world\"'. Action lines: step phrases joined by 'and' / 'then' / ','. A step slot not mentioned in the sentence is filled by the binding with the same slot name (e.g. bare 'run subfunction' uses 'sub')."
  echo "The program starts with v.i=0 v.r=0.0 ok=true s=\"\" and an empty results list, applies input/list/text, runs the steps in order and finally prints the gold_report line. Trace every step by hand and give the exact stdout as expect: lines."
  echo; echo "Example:"; echo "@script"; cat $ROOT/examples/demo.gold | grep -v '^#'
  sed 's/^/expect: /' $ROOT/examples/demo.out; echo "@end"
  echo; echo "Step phrases (entry code shown so you can trace it):"
  shuf -n 6 <(awk -F'\t' '$2=="step"{print $4}' $IDX | sort -u) | while read -r id; do
    awk -v id="$id" '$0=="@entry " id{p=1} p{print} p&&$0=="@end"{exit}' $ROOT/lib/core.gold $ROOT/lib/gen/*.gold 2>/dev/null | grep -v '^test:\|^expect:'
  done
  echo; echo "Fn/pred phrases for bindings (name = phrase):"
  shuf -n 6 <(awk -F'\t' '$2!="step"{print $4}' $IDX | sort -u) | while read -r id; do
    awk -v id="$id" '$0=="@entry " id{p=1} p{print} p&&$0=="@end"{exit}' $ROOT/lib/core.gold $ROOT/lib/gen/*.gold 2>/dev/null | grep -v '^test:\|^expect:'
  done
  echo; echo "Core step phrases always available: run function {x} until {y}; check errors; cache results; run subfunction / run subfunction {sub} / apply {sub} to each result; return results. Core fn: collatz step, digit sum. Core preds: reaches one, above {limit}."
  echo "Output only @script blocks (script lines, then expect: lines, then @end). No commentary, no fences. Keep each script 3-8 lines and results lists short (under 40 values)."
}
others_active() { [ -f $RUN/others ] && (( $(date +%s) - $(cat $RUN/others) < HOLD )); }
worker() {
  RID=$1; ROOM=$ROOM_PREFIX-$RID; WHO=room$RID
  W=$G/rooms/$RID; TMPD=$W/tmp; mkdir -p $W/turns $TMPD
  [ -f $W/turn ] || echo 0 > $W/turn
  local backoff=0 gap s td ctx mode kinds active slot
  log "worker start pid $$ room $ROOM"
  while [ $STOP = 0 ]; do
    if [ -f $RUN/pause ]; then sleep 5; continue; fi
    active=$(cat $RUN/active 2>/dev/null || echo 1)
    if (( RID > active )); then sleep 15; continue; fi
    gap=$MIN_GAP; others_active && gap=$SHARE_GAP
    (( backoff > 0 )) && gap=$backoff
    for ((s=0;s<gap && STOP==0;s+=5)); do sleep 5; done
    [ $STOP = 1 ] && break
    [ -f $RUN/pause ] && continue
    active=$(cat $RUN/active 2>/dev/null || echo 1); (( RID > active )) && continue
    while [ "$(braid_state | jq -r .busy)" = true ] && [ $STOP = 0 ]; do sleep 15; done
    [ -s $G/per_turn ] && PER_TURN=$(cat $G/per_turn)
    TURN=$(( $(cat $W/turn) + 1 )); echo $TURN > $W/turn
    td=$W/turns/$(printf '%06d' $TURN); mkdir -p $td
    ctx=${CONTEXTS[(TURN + (RID-1)*5) % ${#CONTEXTS[@]}]}
    slot=$((RID-1)); (( slot >= active )) && slot=$((slot % active))
    if (( TURN % 10 == 5 )) && [ -f $ROOT/examples/demo.out ]; then mode=script; script_prompt > $td/prompt.txt
    else
      if (( TURN % 5 == 0 )); then mode=prim; kinds="fn or pred"; else mode=step; kinds=step; fi
      { cat $G/prompt/head.txt; echo; echo "=== YOUR TASK ==="
        echo "Write $PER_TURN entries of kind: $kinds, context: $ctx."
        echo "Pick from these suggested (verb noun modifier) combos; use the given words for the verb/noun/modifier fields:"
        pick_combos "$( [ $mode = step ] && echo step || echo fn)" "$ctx" $slot $active | sed 's/^/- /'
        [ $mode = prim ] && echo "For fn/pred entries the phrase is what a user binds a name to, e.g. 'x = <phrase>' (like 'collatz step', 'above {limit}')."
        echo "Make the code meaningful for the '$ctx' context and between 6 and 60 lines where it fits."
      } > $td/prompt.txt
    fi
    log "turn $TURN mode=$mode ctx=$ctx slice=$slot/$active n=$PER_TURN"; local t0=$(date +%s) a0=$(awk -v r=$RID "\$4==r" $ST/accepts.log | wc -l)
    if ! ask $td/prompt.txt > $td/reply.txt; then log "turn $TURN: no reply"; rej no_reply $ROOM/turn$TURN; backoff=300; continue; fi
    if head -c 300 $td/reply.txt | grep -qiE '^\[[^]]*(limited|unavailable|error)|rate.?limit|quota|resource.?exhausted'; then
      log "turn $TURN: limited: $(head -c 160 $td/reply.txt | tr '\n' ' ')"; rej limited $ROOM/turn$TURN
      backoff=$(( backoff ? backoff*2 : 600 )); (( backoff > 3600 )) && backoff=3600; date +%s > $RUN/limited; continue
    fi
    backoff=0
    if [ $mode = script ]; then
      awk -v d=$td 'BEGIN{n=-1} /^@script/{n++; f=d"/s"n".gold"; x=d"/s"n".expect"; printf "" > f; printf "" > x; next} /^@end/{f="";next} f!=""{ if ($0 ~ /^expect:/){ sub(/^expect: ?/,""); print > x } else print > f }' $td/reply.txt
      for s in $td/s*.gold; do [ -f "$s" ] && verify_script $s ${s%.gold}.expect; done
    else
      $GOLDC split $td/reply.txt $td > $td/split.out
      for e in $td/e*.gold; do [ -f "$e" ] && verify_and_accept $e $td; done
    fi
    log "turn $TURN done: accepted=$(wc -l < $ST/accepts.log) rejected=$(wc -l < $ST/rejects.log) turn_mode=$mode n=$PER_TURN acc=$(( $(awk -v r=$RID "\$4==r" $ST/accepts.log | wc -l) - a0 )) rej=$(grep -c "rooms/$RID/turns/$(printf %06d $TURN)/" $ST/rejects.log) dur=$(( $(date +%s) - t0 ))s"
  done
  log "worker stop"
}

# ---------------------------------------------------------------- progress
progress() {
  local now acc started h1 m30
  now=$(date +%s); started=$(cat $ST/started)
  acc=$(wc -l < $ST/accepts.log)
  h1=$(awk -v t=$((now-3600)) '$1>=t' $ST/accepts.log | wc -l); m30=$(awk -v t=$((now-1800)) '$1>=t' $ST/accepts.log | wc -l)
  jq -n --argjson acc "$acc" --argjson h1 "$h1" --argjson m30 "$m30" --argjson rej "$(wc -l < $ST/rejects.log)" \
     --argjson started "$started" --argjson now "$now" --argjson active "$(cat $RUN/active 2>/dev/null || echo 0)" \
     --argjson scripts "$(wc -l < $ST/scripts.keys)" --arg status "$1" --arg others "$(others_active && echo yes || echo no)" \
     --rawfile r <(awk '{print $2}' $ST/rejects.log | sed 's/:.*//' | sort | uniq -c | awk '{printf "%s\t%s\n",$2,$1}') \
     --rawfile rooms <(awk -v t=$((now-3600)) '$1>=t{print ($4==""?"0":$4)}' $ST/accepts.log | sort | uniq -c | awk '{printf "%s\t%s\n",$2,$1}') \
     --rawfile ctx <(awk '{print $3}' $ST/accepts.log | sort | uniq -c | awk '{printf "%s\t%s\n",$2,$1}') '
    def tsv: split("\n") | map(select(length>0) | split("\t") | {(.[0]): (.[1]|tonumber)}) | add // {};
    {status:$status, updated:(now|todate), rooms_active:$active, others_using_agy:$others,
     accepted:$acc, rejected:$rej,
     accept_rate:(if ($acc+$rej)>0 then (($acc/($acc+$rej))*1000|round/1000) else 0 end),
     accepted_last_hour:$h1, accepted_last_30m:$m30,
     rate_per_hour_overall:(if $now>$started then (($acc*3600/($now-$started))|round) else 0 end),
     eta_300k_hours:(if $h1>0 then (((300000-$acc)/$h1)*10|round/10) else null end),
     accepted_last_hour_by_room:($rooms|tsv),
     scripts_accepted:$scripts, rejected_by_reason:($r|tsv), accepted_by_kind_context:($ctx|tsv)}' \
     > $G/progress.json.tmp && mv $G/progress.json.tmp $G/progress.json
}

# ---------------------------------------------------------------- entry points
case "${1:-}" in
  worker) worker $2; exit 0;;
  snapshot) snapshot 1; exit 0;;
  guard) LINES_EVERY=0; guard_check; exit 0;;
  restore) restore "${2:-}"; exit $?;;
  reverify) RID=0; TMPD=$G/rooms/reverify; mkdir -p $TMPD; for td in "${@:2}"; do for e in $td/e*.gold; do [ -f "$e" ] && verify_and_accept $e $td; done; done; exit 0;;
esac

log "supervisor start pid $$ NMAX=$NMAX"
rm -f $RUN/pause
others_seen && date +%s > $RUN/others
others_active && echo 1 > $RUN/active || echo $NMAX > $RUN/active
[ -f $ST/last_snap ] || snapshot 1
declare -A WPID
last_active=$(cat $RUN/active)
while [ $STOP = 0 ]; do
  for ((i=1;i<=NMAX;i++)); do
    if [ -z "${WPID[$i]:-}" ] || ! kill -0 ${WPID[$i]} 2>/dev/null; then
      bash $0 worker $i & WPID[$i]=$!
    fi
  done
  guard_check
  others_seen && date +%s > $RUN/others
  if others_active; then a=1; elif [ -f $RUN/limited ] && (( $(date +%s) - $(cat $RUN/limited) < 1800 )); then a=1; else a=$NMAX; fi
  echo $a > $RUN/active
  [ "$a" != "$last_active" ] && { log "rooms active $last_active -> $a (others_using_agy=$(others_active && echo yes || echo no))"; last_active=$a; }
  (( $(date +%s) - $(cat $ST/last_snap 2>/dev/null || echo 0) >= SNAP_EVERY )) && snapshot
  progress running
  for ((s=0;s<15 && STOP==0;s++)); do sleep 1; done
done
log "supervisor stopping workers"
for p in "${WPID[@]}"; do kill -TERM $p 2>/dev/null; done
wait
progress stopped
snapshot
log "supervisor stop"
