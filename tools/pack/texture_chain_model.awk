# Independent awk model for a texture chain: run with texture.awk, e.g.
#   gawk -f tools/pack/texture.awk -f tools/pack/texture_chain_model.awk -v OPS="canvas w=32 h=32;fbm n=3 c=16 u=5" /dev/null
END { W = 0; H = 0; n = split(OPS, S, ";")
	for (j = 1; j <= n; j++) { m = split(S[j], T, " "); delete V; for (i = 2; i <= m; i++) { split(T[i], q, "="); V[q[1]] = q[2] + 0 }; FAILED = 0; r = model(T[1]); if (!r) { print "fail at " T[1]; exit 1 } }
	print "=> i=" OI " r=0.0 ok=true s=\"" T[1] "\" errors=0 n=0 res=[] cache=0 hits=0"; print imgline() }
