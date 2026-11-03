# Gold texture starter pack generator: texture.spec -> entries whose expects come from this awk reference model.
# Each entry edits the runtime grey image buffer (g.img, <=32x32, values in [0,1]); the golden data is the
# `=> img: WxH min= max= sum8= hash=` line printed by gold_report3 (8-bit quantised sum + rolling hash).
# usage: gawk -f texture.awk texture.spec > texture_all.gold
BEGIN { FS = " ;; "; init_code() }
function sha16(k,   c, h) { c = "printf %s '" k "' | sha1sum"; c | getline h; close(c); return substr(h, 1, 16) }
function rnd(x) { return (x >= 0) ? int(x + 0.5) : -int(-x + 0.5) }
function fnum(x,   q, s, f) { q = rnd(x * 1000); s = ""; if (q < 0) { s = "-"; q = -q }; s = s int(q / 1000); f = q % 1000; if (f != 0) { f = sprintf("%03d", f); sub(/0+$/, "", f); s = s "." f }; return s }
function emod(a, m,  r) { r = a % m; if (r < 0) r += m; return r }
function hash01(x, y, s,  h) { h = emod(x * 374761393 + y * 668265263 + s * 2147483647, 1000003); h = emod(h * h + 12345, 1000003); return h / 1000003.0 }
function clamp(x) { return x < 0 ? 0.0 : (x > 1 ? 1.0 : x) }
function absr(x) { return x < 0 ? 0 - x : x }
function vnoise(x, y, cell, per, seed,   cx, cy, fx, fy, sx, sy, a, b, c, d, top, bot) {
	cx = int(x / cell); cy = int(y / cell); fx = (x % cell) / cell; fy = (y % cell) / cell
	sx = fx * fx * (3.0 - 2.0 * fx); sy = fy * fy * (3.0 - 2.0 * fy)
	a = hash01(cx % per, cy % per, seed); b = hash01((cx + 1) % per, cy % per, seed)
	c = hash01(cx % per, (cy + 1) % per, seed); d = hash01((cx + 1) % per, (cy + 1) % per, seed)
	top = a + (b - a) * sx; bot = c + (d - c) * sx
	return top + (bot - top) * sy
}
function worley(x, y, cell, per, seed,   cx, cy, best, dx, dy, gx, gy, wx, wy, px, py, ddx, ddy, d) {
	cx = int(x / cell); cy = int(y / cell); best = 1000000.0
	for (dy = 0; dy < 3; dy++) for (dx = 0; dx < 3; dx++) {
		gx = cx + dx - 1; gy = cy + dy - 1; wx = emod(gx, per); wy = emod(gy, per)
		px = (gx + hash01(wx, wy, seed)) * cell; py = (gy + hash01(wx, wy, seed + 1)) * cell
		ddx = px - x; ddy = py - y; d = ddx * ddx + ddy * ddy
		if (d < best) best = d
	}
	return clamp(sqrt(best) / cell)
}
function wrap(x, y) { return IMG[emod(y, H) * W + emod(x, W)] }
function fail(m) { FAILED = 1; return 0 }
function ok_img() { if (W == 0) return fail("no texture yet"); return 1 }
function square(c) { if (!ok_img()) return 0; if (W != H) return fail("square"); if (c < 1 || W % c != 0) return fail("cell"); return 1 }
# ---- reference model: returns 1 on success; sets OI (out.i)
function model(k,   x, y, i, n, p, t, amp, norm, cc, o, mn, mx, S2, e, ne, inn, ni, r, d, a, b, cxr, cyr, rr) {
	n = W * H; OI = n
	if (k == "canvas") { if (V["w"] < 1 || V["h"] < 1 || V["w"] * V["h"] > 1024) return fail("big"); W = V["w"]; H = V["h"]; for (i = 0; i < 1024; i++) IMG[i] = 0.0; OI = W * H; return 1 }
	if (k == "fill") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = clamp(V["a"]); return 1 }
	if (k == "noise") { if (!square(V["c"])) return 0; for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = vnoise(x, y, V["c"], W / V["c"], V["u"]); return 1 }
	if (k == "fbm") {
		if (!ok_img()) return 0; if (V["n"] < 1 || V["n"] > 5) return fail("oct")
		cc = V["c"]; for (o = 0; o < V["n"]; o++) { if (!square(cc)) return 0; cc = int(cc / 2) }
		for (y = 0; y < H; y++) for (x = 0; x < W; x++) { t = 0.0; amp = 1.0; norm = 0.0; cc = V["c"]
			for (o = 0; o < V["n"]; o++) { t += amp * vnoise(x, y, cc, W / cc, V["u"] + o); norm += amp; amp *= 0.5; cc = int(cc / 2) }
			IMG[y * W + x] = t / norm }
		return 1 }
	if (k == "worley") { if (!square(V["c"])) return 0; for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = worley(x, y, V["c"], W / V["c"], V["u"]); return 1 }
	if (k == "checker") { if (!ok_img()) return 0; if (V["c"] < 1) return fail("c"); for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = (int(x / V["c"]) + int(y / V["c"])) % 2; return 1 }
	if (k == "stripes") { if (!ok_img()) return 0; if (V["c"] < 1) return fail("c"); for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = int(x / V["c"]) % 2; return 1 }
	if (k == "hgrad") { if (!ok_img()) return 0; if (W < 2) return fail("w"); for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = x / (W - 1); return 1 }
	if (k == "vgrad") { if (!ok_img()) return 0; if (H < 2) return fail("h"); for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = y / (H - 1); return 1 }
	if (k == "radial") { if (!ok_img()) return 0; cxr = (W - 1) / 2.0; cyr = (H - 1) / 2.0; rr = (W < H ? W : H) / 2.0
		for (y = 0; y < H; y++) for (x = 0; x < W; x++) { a = x - cxr; b = y - cyr; IMG[y * W + x] = clamp(1.0 - sqrt(a * a + b * b) / rr) }; return 1 }
	if (k == "invert") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = 1.0 - IMG[i]; return 1 }
	if (k == "threshold") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = (IMG[i] >= V["a"]) ? 1.0 : 0.0; return 1 }
	if (k == "contrast") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = clamp((IMG[i] - 0.5) * V["a"] + 0.5); return 1 }
	if (k == "brighten") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = clamp(IMG[i] + V["a"]); return 1 }
	if (k == "darken") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = clamp(IMG[i] - V["a"]); return 1 }
	if (k == "scale") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = clamp(IMG[i] * V["a"]); return 1 }
	if (k == "blur" || k == "slope") { if (!ok_img()) return 0
		for (y = 0; y < H; y++) for (x = 0; x < W; x++) {
			if (k == "blur") { t = 0.0; for (d = -1; d <= 1; d++) for (o = -1; o <= 1; o++) t += wrap(x + o, y + d); S2[y * W + x] = t / 9.0 }
			else S2[y * W + x] = clamp((absr(wrap(x + 1, y) - wrap(x - 1, y)) + absr(wrap(x, y + 1) - wrap(x, y - 1))) * 0.5) }
		for (i = 0; i < n; i++) IMG[i] = S2[i]; return 1 }
	if (k == "normalize") { if (!ok_img()) return 0; mn = IMG[0]; mx = IMG[0]; for (i = 0; i < n; i++) { if (IMG[i] < mn) mn = IMG[i]; if (IMG[i] > mx) mx = IMG[i] }
		if (mx - mn < 0.000001) return fail("flat"); for (i = 0; i < n; i++) IMG[i] = (IMG[i] - mn) / (mx - mn); return 1 }
	if (k == "quantize") { if (!ok_img()) return 0; if (V["n"] < 2 || V["n"] > 16) return fail("n")
		for (i = 0; i < n; i++) { t = int(IMG[i] * V["n"]); if (t > V["n"] - 1) t = V["n"] - 1; IMG[i] = t / (V["n"] - 1) }; return 1 }
	if (k == "mirror" || k == "flip") { if (!ok_img()) return 0
		for (y = 0; y < H; y++) for (x = 0; x < W; x++) S2[y * W + x] = (k == "mirror") ? IMG[y * W + (W - 1 - x)] : IMG[(H - 1 - y) * W + x]
		for (i = 0; i < n; i++) IMG[i] = S2[i]; return 1 }
	if (k == "remap") { if (!ok_img()) return 0; for (i = 0; i < n; i++) IMG[i] = clamp(V["a"] + (V["b"] - V["a"]) * IMG[i]); return 1 }
	if (k == "seam") { if (!ok_img()) return 0; e = 0.0; ne = 0; inn = 0.0; ni = 0
		for (y = 0; y < H; y++) for (x = 0; x < W; x++) { p = IMG[y * W + x]; r = wrap(x + 1, y); d = wrap(x, y + 1)
			if (x == W - 1) { e += absr(r - p); ne++ } else { inn += absr(r - p); ni++ }
			if (y == H - 1) { e += absr(d - p); ne++ } else { inn += absr(d - p); ni++ } }
		t = (inn <= 0.0) ? 0.0 : (e / ne) / (inn / ni); OI = rnd(t * 100.0); return 1 }
	print "unknown key " k > "/dev/stderr"; exit 1
}
function imgline(   i, mn, mx, s, hs, q) {
	mn = IMG[0]; mx = IMG[0]; s = 0; hs = 0
	for (i = 0; i < W * H; i++) { if (IMG[i] < mn) mn = IMG[i]; if (IMG[i] > mx) mx = IMG[i]; q = rnd(IMG[i] * 255.0); if (q < 0) q = 0; if (q > 255) q = 255; s += q; hs = (hs * 31 + q + 1) % 1000003 }
	return "=> img: " W "x" H " min=" fnum(mn) " max=" fnum(mx) " sum8=" s " hash=" hs
}
# ---- Helium code bodies (between the validation prologue and the out.i/out.s epilogue); PIX loops over x,y
function init_code() {
	PIX = "\tfor y in g.ih {\n\t\tfor x in g.iw {\n"
	C["canvas"] = "\tif !gold_img_new(g, ${w}, ${h}) { out.ok = false; return out; }\n"
	C["fill"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = gold_clamp01(${a}); }\n"
	C["noise"] = "\tif !gold_img_square(g, ${c}) { out.ok = false; return out; }\n" PIX "\t\t\tg.img[y * g.iw + x] = gold_vnoise(x, y, ${c}, g.iw / ${c}, ${u});\n\t\t}\n\t}\n"
	C["fbm"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tif ${n} < 1 || ${n} > 5 { gold_fail(g, \"octaves must be in range\"); out.ok = false; return out; }\n\tvar c0 = ${c};\n\tfor o in ${n} { if !gold_img_square(g, c0) { out.ok = false; return out; } c0 = c0 / 2; }\n" PIX "\t\t\tvar t = 0.0;\n\t\t\tvar amp = 1.0;\n\t\t\tvar norm = 0.0;\n\t\t\tvar cc = ${c};\n\t\t\tfor o in ${n} { t += amp * gold_vnoise(x, y, cc, g.iw / cc, ${u} + o); norm += amp; amp *= 0.5; cc = cc / 2; }\n\t\t\tg.img[y * g.iw + x] = t / norm;\n\t\t}\n\t}\n"
	C["worley"] = "\tif !gold_img_square(g, ${c}) { out.ok = false; return out; }\n" PIX "\t\t\tg.img[y * g.iw + x] = gold_worley(x, y, ${c}, g.iw / ${c}, ${u});\n\t\t}\n\t}\n"
	C["checker"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tif ${c} < 1 { gold_fail(g, \"cell must be positive\"); out.ok = false; return out; }\n" PIX "\t\t\tg.img[y * g.iw + x] = ((x / ${c} + y / ${c}) % 2) as real;\n\t\t}\n\t}\n"
	C["stripes"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tif ${c} < 1 { gold_fail(g, \"width must be positive\"); out.ok = false; return out; }\n" PIX "\t\t\tg.img[y * g.iw + x] = ((x / ${c}) % 2) as real;\n\t\t}\n\t}\n"
	C["hgrad"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tif g.iw < 2 { gold_fail(g, \"texture too narrow\"); out.ok = false; return out; }\n" PIX "\t\t\tg.img[y * g.iw + x] = (x as real) / ((g.iw - 1) as real);\n\t\t}\n\t}\n"
	C["vgrad"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tif g.ih < 2 { gold_fail(g, \"texture too short\"); out.ok = false; return out; }\n" PIX "\t\t\tg.img[y * g.iw + x] = (y as real) / ((g.ih - 1) as real);\n\t\t}\n\t}\n"
	C["radial"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tlet cx = ((g.iw - 1) as real) / 2.0;\n\tlet cy = ((g.ih - 1) as real) / 2.0;\n\tvar rr = (g.iw as real) / 2.0;\n\tif g.ih < g.iw { rr = (g.ih as real) / 2.0; }\n" PIX "\t\t\tlet a = (x as real) - cx;\n\t\t\tlet b = (y as real) - cy;\n\t\t\tg.img[y * g.iw + x] = gold_clamp01(1.0 - sqrt(a * a + b * b) / rr);\n\t\t}\n\t}\n"
	C["invert"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = 1.0 - g.img[k]; }\n"
	C["threshold"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { if g.img[k] >= ${a} { g.img[k] = 1.0; } else { g.img[k] = 0.0; } }\n"
	C["contrast"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = gold_clamp01((g.img[k] - 0.5) * ${a} + 0.5); }\n"
	C["brighten"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = gold_clamp01(g.img[k] + ${a}); }\n"
	C["darken"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = gold_clamp01(g.img[k] - ${a}); }\n"
	C["scale"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = gold_clamp01(g.img[k] * ${a}); }\n"
	C["blur"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tvar s2 = g.img;\n" PIX "\t\t\tvar t = 0.0;\n\t\t\tfor dy in 3 { for dx in 3 { t += gold_img_wrap(g, x + dx - 1, y + dy - 1); } }\n\t\t\ts2[y * g.iw + x] = t / 9.0;\n\t\t}\n\t}\n\tg.img = s2;\n"
	C["slope"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tvar s2 = g.img;\n" PIX "\t\t\tlet gx = gold_absr(gold_img_wrap(g, x + 1, y) - gold_img_wrap(g, x - 1, y));\n\t\t\tlet gy = gold_absr(gold_img_wrap(g, x, y + 1) - gold_img_wrap(g, x, y - 1));\n\t\t\ts2[y * g.iw + x] = gold_clamp01((gx + gy) * 0.5);\n\t\t}\n\t}\n\tg.img = s2;\n"
	C["normalize"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tvar mn = g.img[0];\n\tvar mx = g.img[0];\n\tfor k in g.iw * g.ih { if g.img[k] < mn { mn = g.img[k]; } if g.img[k] > mx { mx = g.img[k]; } }\n\tif mx - mn < 0.000001 { gold_fail(g, \"flat texture\"); out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = (g.img[k] - mn) / (mx - mn); }\n"
	C["quantize"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tif ${n} < 2 || ${n} > 16 { gold_fail(g, \"levels must be in range\"); out.ok = false; return out; }\n\tfor k in g.iw * g.ih {\n\t\tvar t = (g.img[k] * (${n} as real)) as! int;\n\t\tif t > ${n} - 1 { t = ${n} - 1; }\n\t\tg.img[k] = (t as real) / ((${n} - 1) as real);\n\t}\n"
	C["mirror"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tvar s2 = g.img;\n" PIX "\t\t\ts2[y * g.iw + x] = g.img[y * g.iw + (g.iw - 1 - x)];\n\t\t}\n\t}\n\tg.img = s2;\n"
	C["flip"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tvar s2 = g.img;\n" PIX "\t\t\ts2[y * g.iw + x] = g.img[(g.ih - 1 - y) * g.iw + x];\n\t\t}\n\t}\n\tg.img = s2;\n"
	C["remap"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tfor k in g.iw * g.ih { g.img[k] = gold_clamp01(${a} + (${b} - ${a}) * g.img[k]); }\n"
	C["seam"] = "\tif !gold_img_ok(g) { out.ok = false; return out; }\n\tvar e = 0.0;\n\tvar ne = 0;\n\tvar inn = 0.0;\n\tvar ni = 0;\n" PIX "\t\t\tlet p = g.img[y * g.iw + x];\n\t\t\tlet r = gold_img_wrap(g, x + 1, y);\n\t\t\tlet d = gold_img_wrap(g, x, y + 1);\n\t\t\tif x == g.iw - 1 { e += gold_absr(r - p); ne++; } else { inn += gold_absr(r - p); ni++; }\n\t\t\tif y == g.ih - 1 { e += gold_absr(d - p); ne++; } else { inn += gold_absr(d - p); ni++; }\n\t\t}\n\t}\n\tvar t = 0.0;\n\tif inn > 0.0 { t = (e / (ne as real)) / (inn / (ni as real)); }\n\tout.i = round(t * 10.0 * 10.0) as! int;\n\tout.s.clear();\n\tformat(out.s, \"seam\");\n\treturn out;\n"
}
/^#/ || NF < 7 { next }
{
	key = $1; slots = $5; np = split($6, P, " // ")
	delete TY; ns = 0; if (slots != "-") { m = split(slots, SL, " "); for (i = 1; i <= m; i++) { split(SL[i], q, ":"); TY[q[1]] = q[2]; SN[++ns] = q[1] } }
	ent = "@entry " sha16("gold-texture|" key) "\nkind: step\nverb: " $2 "\nnoun: " $3 "\nmodifier: " $4 "\ncontext: texture\n"
	for (i = 1; i <= np; i++) ent = ent "phrase: " P[i] "\n"
	for (i = 1; i <= ns; i++) ent = ent "slot: " SN[i] " " TY[SN[i]] "\n"
	delete SEEN; dupe = 0
	for (f = 7; f <= NF; f++) {
		t = $f; if (t == "-") t = ""
		delete V; W = 0; H = 0; delete IMG; FAILED = 0
		m = split(t, KV, " "); for (i = 1; i <= m; i++) { split(KV[i], q, "="); V[q[1]] = q[2] + 0 }
		if ("img" in V) { W = V["img"]; H = W; for (y = 0; y < H; y++) for (x = 0; x < W; x++) IMG[y * W + x] = ((x * 7 + y * 13) % 17) / 17.0 }
		r = model(key)
		ex = (r ? "expect: => i=" OI " r=0.0 ok=true s=\"" key "\" errors=0 n=0 res=[] cache=0 hits=0" : "expect: => i=0 r=0.0 ok=false s=\"\" errors=1 n=0 res=[] cache=0 hits=0") "\n"
		if (W > 0) ex = ex "expect: " imgline() "\n"
		if (ex in SEEN) dupe = 1; SEEN[ex] = 1
		ent = ent "test:" (t == "" ? "" : " " t) "\n" ex
	}
	if (dupe) { print "skip constant output: " key > "/dev/stderr"; next }
	body = C[key]
	if (key != "seam") body = body "\tout.i = g.iw * g.ih;\n\tout.s.clear();\n\tformat(out.s, \"" key "\");\n"
	ent = ent "code:\nfn ${ID}(g Gold&, v Val) Val {\n\tvar out = v;\n" body (key == "seam" ? "" : "\tout\n") "}\n@end\n"
	printf "%s", ent; cnt++
}
END { print cnt " texture entries" > "/dev/stderr" }
