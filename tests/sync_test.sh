#!/bin/bash
# gold sync end to end, offline: a stand-in Helium checkout whose library renames demo::twice to demo::double, a
# product that calls it from a Gold literal block and a hand-written file, and a stand-in `claude` that answers each
# repair with the rename. Checks: a first sync commits to helium-sync; after the rename a failing test leaves the
# product exactly as it was; with the test fixed the repairs are committed to the branch and the working branch is
# untouched; a second run finds the branch already up to date.
# Usage: tests/sync_test.sh <real hc> <helium lib>   (e.g. ../helium/build/hc ../helium/hc/lib)
set -u
HCR=$(realpath "${1:?usage: sync_test.sh <hc> <helium lib>}"); LIB=$(realpath "${2:?}")
G=$(cd "$(dirname "$0")/.." && pwd); GB="$G/gold_bin"
W=$(mktemp -d); [ -n "${KEEP:-}" ] && echo "work: $W" || trap 'rm -rf "$W"' EXIT
export HOME="$W/home" GOLD_CACHE="$W/cache" PATH="$W/bin:$PATH" GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p "$HOME" "$W/bin"
pass=0; fail=0; ok() { if [ "$1" = 0 ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $2"; fi; }

# the model: fixes whichever file the prompt is about by renaming the call
cat > "$W/bin/claude" <<'EOF'
#!/usr/bin/env python3
import json, re, sys
p = sys.stdin.read(); f = re.search(r'^# File (\S+)', p, re.M).group(1)
line = next(l.split('| ', 1)[1] for l in p.split('\n') if re.match(r'^\d+\| .*demo::twice', l))
print(json.dumps({'result': '<<<<<<< SEARCH\n%s\n=======\n%s\n>>>>>>> REPLACE\n' % (line, line.replace('demo::twice', 'demo::double')), 'input_tokens': 1, 'output_tokens': 1, 'total_cost_usd': 0}))
EOF
chmod +x "$W/bin/claude"

# Helium: hc/lib is the real library plus demo.he; bootstrap installs a wrapper around the real hc
mkdir -p "$W/hel/hc/lib" && cd "$W/hel" && for f in "$LIB"/*; do ln -s "$f" hc/lib/; done
printf 'namespace demo\ntwice(x int) int: x * 2\n' > hc/lib/demo.he
printf '#!/bin/sh\nmkdir -p build && printf "#!/bin/sh\\nexec %s \\"\\$@\\"\\n" > build/hc && chmod +x build/hc\n' "$HCR" > hc/bootstrap.sh
mkdir -p hc/seed && echo seed > hc/seed/hc.c && printf 'build/\n' > .gitignore
git init -q -b main && git add -A && git commit -qm v1 && git clone -q --bare . "$W/hel-up.git" && git remote add origin "$W/hel-up.git" && git fetch -q && git branch -q -u origin/main
bash hc/bootstrap.sh

# the product (its build step stages files, so a failed sync must also undo the index)
mkdir -p "$W/prod" && cd "$W/prod" && git init -q -b main
cat > util.gold <<'EOF'
into util.amni

```amni
import demo;
fn half_answer() int { demo::twice(10) + 1 }
```
EOF
printf 'import demo;\nimport util;\nfn main() { print("answer ", demo::twice(half_answer())); }\n' > main.amni
printf 'helium ../hel\ngold *.gold\nbuild main.amni main\nstep git add -A .\ntest ./main | grep -qx "answer 42"\n' > helium.sync
printf 'main\n' > .gitignore
git add -A && git commit -qm product

# 1. first sync: builds with v1 and commits to helium-sync
"$GB" sync > "$W/o1" 2>&1; r=$?; ok $r "first sync: $(cat "$W/o1")"
git show helium-sync:helium.lock | grep -q "helium $(git -C "$W/hel" rev-parse HEAD)"; ok $? "first sync wrote helium.lock on the branch"
[ "$(git rev-parse --abbrev-ref HEAD)" = main ] && [ -z "$(git status --porcelain --untracked-files=no)" ]; ok $? "first sync left main clean and checked out"
git merge -q --ff-only helium-sync

# 2. Helium renames twice to double; with a wrong test the repairs are thrown away
cd "$W/hel" && printf 'namespace demo\ndouble(x int) int: x * 2\n' > hc/lib/demo.he && git commit -qam v2 && git push -q origin main
cd "$W/prod" && sed -i 's/answer 42/answer 43/' helium.sync && git commit -qam "wrong test"
before=$(git rev-parse helium-sync)
"$GB" sync > "$W/o2" 2>&1; r=$?; [ $r = 1 ]; ok $? "sync with a failing test exits 1: $(cat "$W/o2")"
grep -q "repaired util.gold" "$W/o2" && grep -q "repaired main.amni" "$W/o2"; ok $? "both files were repaired before the test ran"
grep -q demo::twice util.gold && grep -q demo::twice main.amni && [ -z "$(git status --porcelain)" ]; ok $? "the failed sync left the product exactly as it was"
[ "$(git rev-parse helium-sync)" = "$before" ]; ok $? "the failed sync did not move helium-sync"

# 3. right test: the repairs land on helium-sync, main is untouched
sed -i 's/answer 43/answer 42/' helium.sync && git commit -qam "right test"
"$GB" sync > "$W/o3" 2>&1; r=$?; ok $r "sync after the rename: $(cat "$W/o3")"
git show helium-sync:util.gold | grep -q demo::double && git show helium-sync:main.amni | grep -q demo::double; ok $? "the branch has both repairs"
git show helium-sync:helium.lock | grep -q "helium $(git -C "$W/hel" rev-parse HEAD)"; ok $? "the branch's helium.lock names the new Helium"
git log -1 --format=%B helium-sync | grep -q "Repaired for the new compiler" ; ok $? "the commit message lists the repairs"
grep -q demo::twice main.amni && [ "$(git rev-parse --abbrev-ref HEAD)" = main ] && [ -z "$(git status --porcelain)" ]; ok $? "main is untouched"

# 4. nothing new: the branch already has this Helium
"$GB" sync > "$W/o4" 2>&1; r=$?; ok $r "repeat sync" ; grep -q "already has" "$W/o4"; ok $? "repeat sync says the branch is ready: $(cat "$W/o4")"
"$GB" sync all > "$W/o5" 2>&1; ok $? "sync all: $(cat "$W/o5")"

echo "sync_test: $pass pass, $fail fail"; [ $fail = 0 ]
