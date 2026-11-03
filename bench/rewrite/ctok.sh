#!/bin/sh
f=${1:?file}; c=$HOME/.cache/gold/ctok; mkdir -p $c; k=$(sha1sum "$f" | cut -c1-16)
[ -s $c/$k ] && { cat $c/$k; exit 0; }
n() { claude -p --model haiku --setting-sources '' --strict-mcp-config --tools '' --no-session-persistence --output-format json --system-prompt 'Reply with OK.' | python3 -c 'import json,sys;u=json.load(sys.stdin)["usage"];print(u["input_tokens"]+u["cache_creation_input_tokens"]+u["cache_read_input_tokens"])'; }
b=$(printf 'x' | n); t=$( (printf 'x'; cat "$f") | n); echo $((t-b)) | tee $c/$k
