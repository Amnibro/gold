# scene.awk: Gold entries that write Amni-Form (Amni-CAD's model language) lines into the scene document.
# One spec line per entry (scene.spec): key ;; verb ;; noun ;; modifier ;; context ;; slots ;; phrases (//) ;; template ;; tests...
# The same template drives the Helium code and the awk reference model that writes the golden expects.
# Template modes: plain (new lines, " / " between lines), "+ " append to the last item, "* " append to every shape,
# "- " delete the last item, "G " group every shape, "S " scatter (n, a, u slots), "K " bone chain (n, a, b slots).
# Placeholders: {N:pfx} {NL:pfx} new name, {L} last item at start, {P} newest name, {HEX} from cr cg cb, {C:pfx} pfx+current item count (name of the item made by the previous line),
# {slot} or {slot*F}, {X} {Y} scatter point, {Z0} {Z1} {PQ} chain heights and parent.
BEGIN {
	FS = " ;; "
	MAC["DS"] = "ground box 0,0,-.5 20,20,1|crate box 1,2,.5 1,1,1"
	MAC["DS2"] = "rock sphere -2,1,.4 r.4|post cyl 0,0,0 0,0,2 r.1"
	MAC["DL"] = "key light point 2,-2,3 w300"
	MAC["DL2"] = "floor box 0,0,-.5 8,8,1|sun1 light sun 0,0,10 w3"
	MAC["DC"] = "shot camera 0,-6,2 0,0,1"
	MAC["DC2"] = "floor box 0,0,-.5 8,8,1|wide camera 4,-8,3 0,0,0 mm24"
	MAC["DB"] = "hip bone 0,0,1 0,0,1.4"
	MAC["DB2"] = "body capsule 0,0,.5 0,0,1.3 r.35|armL bone .3,0,1.3 .8,0,1"
	MAC["DK"] = "hip bone 0,0,1 0,0,1.4|reach ik hip 1,0,1"
	MAC["DK2"] = "armL bone .3,0,1.3 .8,0,1|aim trackto armL 0,-1,1"
	MAC["DI"] = "block box 0,0,.5 1,1,1|ball sphere .3,0,.6 r.5"
	MAC["DI2"] = "slab box 0,0,0 2,2,.4|pin cyl 0,0,-1 0,0,1 r.2"
	MAC["DA"] = "hip bone 0,0,1 0,0,1.4|crate box 1,2,.5 1,1,1"
	MAC["DA2"] = "armL bone .3,0,1.3 .8,0,1|post cyl 0,0,0 0,0,2 r.1"
	MAC["DR"] = "armL bone .3,0,1.3 .8,0,1|hip bone 0,0,1 0,0,1.4"
	MAC["DR2"] = "hip bone 0,0,1 0,0,1.4|armL bone .3,0,1.3 .8,0,1"
	MAC["DW"] = "hip bone 0,0,1 0,0,1.4|walk:hip.rot anim 0:0,0,0 1:20,0,0"
	MAC["DW2"] = "armL bone .3,0,1.3 .8,0,1|wave:armL.rot anim 0:0,0,0 1:0,0,40|run:armL.rot anim 0:0,0,0 .5:30,0,0"
	MAC["DE"] = ""
	split("sphere ellipsoid box capsule cyl torus cone prism pyramid wedge tube lathe extrude", SH, " ")
	for (i in SH) ISSHAPE[SH[i]] = 1
}
function sha16(k,   c, h) { c = "printf %s '" k "' | sha1sum"; c | getline h; close(c); return substr(h, 1, 16) }
function rnd(x) { return (x >= 0) ? int(x + 0.5) : -int(-x + 0.5) }
function fnum(x,   q, s, f) {
	q = rnd(x * 1000); s = ""
	if (q < 0) { s = "-"; q = -q }
	s = s int(q / 1000); f = q % 1000
	if (f != 0) { f = sprintf("%03d", f); sub(/0+$/, "", f); s = s "." f }
	return s
}
function emod(a, m,  r) { r = a % m; if (r < 0) r += m; return r }
function hash01(x, y, s,  h) { h = emod(x * 374761393 + y * 668265263 + s * 2147483647, 1000003); h = emod(h * h + 12345, 1000003); return h / 1000003.0 }
function hex2(c,  x) { x = c + 0; if (x < 0) x = 0; if (x > 255) x = 255; return sprintf("%02x", x) }
function trim(s) { gsub(/^ +| +$/, "", s); return s }
function hl(x) { x = x ""; if (x ~ /^-?\./) sub(/\./, "0.", x); if (x !~ /\./) x = x ".0"; return x }
# ---- template tokens: TK[i] (type L=literal P=placeholder), TV[i]
function tok(t,   n, p, q) {
	n = 0
	while (length(t) > 0) {
		p = index(t, "{")
		if (p == 0) { TK[++n] = "L"; TV[n] = t; break }
		if (p > 1) { TK[++n] = "L"; TV[n] = substr(t, 1, p - 1) }
		q = index(t, "}"); TK[++n] = "P"; TV[n] = substr(t, p + 1, q - p - 1); t = substr(t, q + 1)
	}
	return n
}
# ---- model: evaluate one template line
function mline(t,   n, i, v, a, s) {
	n = tok(t); s = ""
	for (i = 1; i <= n; i++) {
		if (TK[i] == "L") { s = s TV[i]; continue }
		v = TV[i]
		if (v ~ /^NL?:/) { split(v, a, ":"); DNAME = a[2] (DN + 1) (v ~ /^NL/ ? "L" : ""); s = s DNAME }
		else if (v ~ /^CL?:/) { split(v, a, ":"); s = s a[2] DN (v ~ /^CL/ ? "L" : "") }
		else if (v == "L") s = s LAST
		else if (v == "P") s = s DNAME
		else if (v == "HEX") s = s "#" hex2(VAL["cr"]) hex2(VAL["cg"]) hex2(VAL["cb"])
		else if (v == "X") s = s fnum(MX)
		else if (v == "Y") s = s fnum(MY)
		else if (v == "Z0") s = s fnum(MZ0)
		else if (v == "Z1") s = s fnum(MZ1)
		else if (v == "PQ") s = s (MQ > 0 ? " ^" MPREV : "")
		else if (v ~ /\*/) { split(v, a, "*"); s = s fnum(VAL[a[1]] * (a[2] + 0)) }
		else if (TY[v] == "real") s = s fnum(VAL[v])
		else s = s VAL[v]
	}
	return s
}
function mdoc(l) { DOC[++DN] = l }
function firstw(l) { return substr(l, 1, index(l " ", " ") - 1) }
function isshape(l,  w) { if (substr(l, 1, 1) == "@") return 0; split(l, w, " "); return (w[2] in ISSHAPE) }
function findlast(  k, hit) { if (DNAME == "") return 0; hit = 0; for (k = 1; k <= DN; k++) if (index(DOC[k], DNAME " ") == 1) hit = k; return hit }
function model(mode, body,   L_, i, k, c, nm, q, ln) {
	FAIL = 0; OUTI = 0
	if (mode == "") {
		if (body ~ /\{L\}/) { if (DNAME == "") { FAIL = 1; return } }
		LAST = DNAME
		ln = split(body, L_, " / ")
		for (i = 1; i <= ln; i++) mdoc(mline(L_[i]))
		OUTI = DN
	} else if (mode == "+") {
		k = findlast(); if (!k) { FAIL = 1; return }
		DOC[k] = DOC[k] " " mline(body); OUTI = DN
	} else if (mode == "*") {
		nm = " " mline(body); c = 0
		for (k = 1; k <= DN; k++) if (isshape(DOC[k])) { DOC[k] = DOC[k] nm; c++ }
		if (!c) { FAIL = 1; return }
		OUTI = c
	} else if (mode == "-") {
		k = findlast(); if (!k) { FAIL = 1; return }
		for (i = k; i < DN; i++) DOC[i] = DOC[i + 1]
		DN--; DNAME = ""; OUTI = DN
	} else if (mode == "G") {
		nm = ""; c = 0
		for (k = 1; k <= DN; k++) if (isshape(DOC[k])) { nm = nm (c ? "," : "") firstw(DOC[k]); c++ }
		if (!c) { FAIL = 1; return }
		DNAME = "grp" (DN + 1); mdoc(DNAME " group " nm); OUTI = c
	} else if (mode == "S") {
		if (VAL["n"] < 1 || VAL["n"] > 24) { FAIL = 1; return }
		for (q = 0; q < VAL["n"]; q++) {
			MX = (hash01(q, 1, VAL["u"]) * 2.0 - 1.0) * VAL["a"]; MY = (hash01(q, 2, VAL["u"]) * 2.0 - 1.0) * VAL["a"]
			mdoc(mline(body))
		}
		OUTI = VAL["n"]
	} else if (mode == "K") {
		if (VAL["n"] < 1 || VAL["n"] > 12) { FAIL = 1; return }
		MPREV = ""
		for (q = 0; q < VAL["n"]; q++) {
			MQ = q; MZ0 = VAL["a"] + (VAL["b"] - VAL["a"]) * q / VAL["n"]; MZ1 = VAL["a"] + (VAL["b"] - VAL["a"]) * (q + 1) / VAL["n"]
			mdoc(mline(body)); MPREV = DNAME
		}
		OUTI = VAL["n"]
	}
}
# ---- code: Helium that appends one template line into o
function lit(s,   out, d, z) {
	out = ""
	while (length(s) > 0) {
		if (match(s, /^#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/)) {
			out = out sprintf("\tgold_hex(o, %d, %d, %d);\n", strtonum("0x" substr(s, 2, 2)), strtonum("0x" substr(s, 4, 2)), strtonum("0x" substr(s, 6, 2)))
			s = substr(s, 8); continue
		}
		if (match(s, /^[0-9]+/)) {
			d = substr(s, 1, RLENGTH); s = substr(s, RLENGTH + 1)
			if (length(d) <= 2) out = out "\to.append(\"" d "\");\n"
			else { while (substr(d, 1, 1) == "0" && length(d) > 1) { out = out "\to.push('0');\n"; d = substr(d, 2) } out = out "\tformat(o, " d ");\n" }
			continue
		}
		match(s, /^[^#0-9]+|^#/); out = out "\to.append(\"" substr(s, 1, RLENGTH) "\");\n"; s = substr(s, RLENGTH + 1)
	}
	return out
}
function cline(t, ind,   n, i, v, a, c) {
	n = tok(t); c = ""
	for (i = 1; i <= n; i++) {
		if (TK[i] == "L") { c = c lit(TV[i]); continue }
		v = TV[i]
		if (v ~ /^NL?:/) { split(v, a, ":"); c = c "\tgold_dnews(g, \"" a[2] "\", \"" (v ~ /^NL/ ? "L" : "") "\", o);\n" }
		else if (v ~ /^CL?:/) { split(v, a, ":"); c = c "\to.append(\"" a[2] "\"); format(o, g.dn);\n" (v ~ /^CL/ ? "\to.push('L');\n" : "") }
		else if (v == "L") c = c "\to.append(last);\n"
		else if (v == "P") c = c "\to.append(g.dname);\n"
		else if (v == "HEX") c = c "\tgold_hex(o, ${cr}, ${cg}, ${cb});\n"
		else if (v == "X") c = c "\tgold_fnum(o, px);\n"
		else if (v == "Y") c = c "\tgold_fnum(o, py);\n"
		else if (v == "Z0") c = c "\tgold_fnum(o, z0);\n"
		else if (v == "Z1") c = c "\tgold_fnum(o, z1);\n"
		else if (v == "PQ") c = c "\tif q > 0 { o.append(\" ^\"); o.append(prev); }\n"
		else if (v ~ /\*/) { split(v, a, "*"); c = c "\tgold_fnum(o, ${" a[1] "} * " hl(a[2]) ");\n" }
		else if (TY[v] == "real") c = c "\tgold_fnum(o, ${" v "});\n"
		else if (TY[v] == "int") c = c "\tformat(o, ${" v "});\n"
		else c = c "\to.append(${" v "});\n"
	}
	if (ind != "") gsub(/\n\t/, "\n\t" ind, c)
	if (ind != "") c = ind substr(c, 1)
	return c
}
function failc(msg) { return "{ gold_fail(g, \"" msg "\"); out.ok = false; return out; }" }
function code(mode, body, key,   c, L_, ln, i) {
	c = "\tvar out = v;\n\tvar o byte[>..] = [];\n"
	if (mode == "") {
		if (body ~ /\{L\}/) c = c "\tvar last byte[>..] = [];\n\tif !gold_dlast(g, last) { out.ok = false; return out; }\n"
		ln = split(body, L_, " / ")
		for (i = 1; i <= ln; i++) c = c (i > 1 ? "\to.clear();\n" : "") cline(L_[i], "") "\tgold_doc(g, o);\n"
		c = c "\tout.i = g.dn;\n"
	} else if (mode == "+") {
		c = c "\tlet k = gold_dfind(g);\n\tif k < 0 " failc("no item yet") "\n\to.push(' ');\n" cline(body, "") "\tgold_dappend(g, k, o);\n\tout.i = g.dn;\n"
	} else if (mode == "*") {
		c = c "\to.push(' ');\n" cline(body, "") "\tvar c = 0;\n\tfor k in g.dn { if gold_dshape(g, k) { gold_dappend(g, k, o); c++; } }\n\tif c == 0 " failc("no shapes yet") "\n\tout.i = c;\n"
	} else if (mode == "-") {
		c = c "\tlet k = gold_dfind(g);\n\tif k < 0 " failc("no item yet") "\n\tgold_ddelete(g, k);\n\tout.i = g.dn;\n"
	} else if (mode == "G") {
		c = c "\tvar names byte[>..] = [];\n\tvar c = 0;\n\tfor k in g.dn { if gold_dshape(g, k) { if c > 0 { names.push(','); } gold_dword(g, k, names); c++; } }\n\tif c == 0 " failc("no shapes yet") "\n\tgold_dnew(g, \"grp\", o);\n\to.append(\" group \");\n\to.append(names);\n\tgold_doc(g, o);\n\tout.i = c;\n"
	} else if (mode == "S") {
		c = c "\tif ${n} < 1 || ${n} > 24 " failc("count out of range") "\n\tfor q in ${n} {\n\t\tlet px = (gold_hash01(q, 1, ${u}) * 2.0 - 1.0) * ${a};\n\t\tlet py = (gold_hash01(q, 2, ${u}) * 2.0 - 1.0) * ${a};\n\t\to.clear();\n" cline(body, "\t") "\t\tgold_doc(g, o);\n\t}\n\tout.i = ${n};\n"
	} else if (mode == "K") {
		c = c "\tif ${n} < 1 || ${n} > 12 " failc("count out of range") "\n\tvar prev byte[>..] = [];\n\tfor q in ${n} {\n\t\tlet z0 = ${a} + (${b} - ${a}) * q as real / ${n} as real;\n\t\tlet z1 = ${a} + (${b} - ${a}) * (q + 1) as real / ${n} as real;\n\t\to.clear();\n" cline(body, "\t") "\t\tgold_doc(g, o);\n\t\tprev.clear();\n\t\tprev.append(g.dname);\n\t}\n\tout.i = ${n};\n"
	}
	return c "\tout.s.clear();\n\tformat(out.s, \"" key "\");\n\tout\n"
}
function rep(i, ok, s, err) { return "=> i=" i " r=0.0 ok=" (ok ? "true" : "false") " s=\"" s "\" errors=" err " n=0 res=[] cache=0 hits=0" }
function runtest(t, mode, body, key,   d, a, n, i, kv, e, out, k, tl) {
	delete VAL; delete DOC; DN = 0; DNAME = ""
	tl = t
	if (match(t, /doc=@[A-Z0-9]+/)) { d = MAC[substr(t, RSTART + 5, RLENGTH - 5)]; t = substr(t, 1, RSTART - 1) substr(t, RSTART + RLENGTH); tl = trim(t) (d == "" ? "" : " doc=\"" d "\"") }
	if (d != "") { n = split(d, a, "|"); for (i = 1; i <= n; i++) { mdoc(a[i]); if (substr(a[i], 1, 1) != "@" && index(a[i], " ")) DNAME = firstw(a[i]) } }
	n = split(trim(t), a, " ")
	for (i = 1; i <= n; i++) { split(a[i], kv, "="); e = kv[2]; gsub(/"/, "", e); VAL[kv[1]] = e }
	model(mode, body)
	out = FAIL ? rep(0, 0, "", 1) : rep(OUTI, 1, key, 0)
	for (k = 1; k <= DN; k++) out = out "\nexpect: => doc: " DOC[k]
	return "test: " trim(tl) "\nexpect: " out "\n"
}
/^#/ || NF < 10 { next }
{
	key = trim($1); verb = trim($2); noun = trim($3); mod = trim($4); ctx = trim($5); sl = trim($6); ph = trim($7); tp = trim($8)
	delete TY; slots = ""
	if (sl != "-") { n = split(sl, a, " "); for (i = 1; i <= n; i++) { split(a[i], b, ":"); TY[b[1]] = b[2]; slots = slots "slot: " b[1] " " b[2] "\n" } }
	mode = ""
	if (tp ~ /^[-+*GSK] /) { mode = substr(tp, 1, 1); tp = substr(tp, 3) }
	tests = ""; seen = ""; bad = 0
	for (j = 9; j <= NF; j++) {
		tt = runtest(trim($j), mode, tp, key); tests = tests tt
		o_ = tt; sub(/^[^\n]*\n/, "", o_); if (index(seen, "\x01" o_ "\x01")) bad = 1; seen = seen "\x01" o_ "\x01"
	}
	if (bad) { print "constant output " key > "/dev/stderr"; next }
	id = sha16("gold-scene|" key)
	np = split(ph, P, " // ")
	printf "@entry %s\nkind: step\nverb: %s\nnoun: %s\nmodifier: %s\ncontext: %s\n", id, verb, noun, mod, ctx
	for (i = 1; i <= np; i++) printf "phrase: %s\n", trim(P[i])
	printf "%s%s", slots, tests
	printf "code:\nfn ${ID}(g Gold&, v Val) Val {\n%s}\n@end\n\n", code(mode, tp, key)
	NENT++
}
END { print NENT " entries" > "/dev/stderr" }
