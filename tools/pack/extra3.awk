# Gold basic pack part 4: runtime v2 entries (reals, words, vectors, map, records).
function rnd(x) { return (x >= 0) ? int(x + 0.5) : -int(-x + 0.5) }
function flo(x) { return (x == int(x)) ? x : ((x >= 0) ? int(x) : int(x) - 1) }
function v2op(op, j,   M, m, i, iv, rv, okv, s, k, t, tv, n, a, b, c, mx, mn, L, sx, sy, sz, tmp, ln, cnt, w, ks, o, key) {
	clr(); m = 0; iv = 0; rv = 0; okv = 1; s = op; err = 0; k = TRK[j]; tv = ""
	if (op ~ /^r/ && op != "rfromres") { ldr(j); tv = "reals=" TR[j] }
	if (op ~ /^w/) { ldw(j); tv = "words=" TW[j] }
	if (op ~ /^v/) { ldv(j); tv = "vecs=" TV[j] }
	if (op ~ /^m/) { ldm(j); tv = "map=" TM[j] }
	if (op ~ /^k/) { ldk(j); tv = "recs=" TK_[j] }
	# ---- reals
	if (op == "rsum") { for (i = 0; i < RN; i++) rv += RL[i] }
	else if (op == "rmean") { for (i = 0; i < RN; i++) rv += RL[i]; rv = rv / RN }
	else if (op == "rmax") { rv = RL[0]; for (i = 1; i < RN; i++) if (RL[i] > rv) rv = RL[i] }
	else if (op == "rmin") { rv = RL[0]; for (i = 1; i < RN; i++) if (RL[i] < rv) rv = RL[i] }
	else if (op == "rsort") sortn(RL, RN)
	else if (op == "rrev") { for (i = 0; i < RN; i++) tmp[i] = RL[RN - 1 - i]; cpy(tmp, RL, RN) }
	else if (op == "rscale") { for (i = 0; i < RN; i++) RL[i] = RL[i] * k; tv = tv " k=" fmtr(k) }
	else if (op == "roffset") { for (i = 0; i < RN; i++) RL[i] = RL[i] + k; tv = tv " k=" fmtr(k) }
	else if (op == "rsquare") { for (i = 0; i < RN; i++) RL[i] = RL[i] * RL[i] }
	else if (op == "rround") { for (i = 0; i < RN; i++) M[m++] = rnd(RL[i]) }
	else if (op == "rfloor") { for (i = 0; i < RN; i++) M[m++] = flo(RL[i]) }
	else if (op == "rnorm") { mx = RL[0]; mn = RL[0]; for (i = 1; i < RN; i++) { if (RL[i] > mx) mx = RL[i]; if (RL[i] < mn) mn = RL[i] } for (i = 0; i < RN; i++) RL[i] = (mx == mn) ? 0 : (RL[i] - mn) / (mx - mn) }
	else if (op == "rcount") { iv = RN }
	else if (op == "rabs") { for (i = 0; i < RN; i++) if (RL[i] < 0) RL[i] = -RL[i] }
	else if (op == "rhalf") { for (i = 0; i < RN; i++) RL[i] = RL[i] / 2 }
	else if (op == "rabove") { tv = tv " k=" fmtr(k); n = 0; for (i = 0; i < RN; i++) if (RL[i] > k) tmp[n++] = RL[i]; RN = n; delete RL; cpy(tmp, RL, n) }
	else if (op == "rsqrt") { for (i = 0; i < RN; i++) if (RL[i] < 0) { okv = 0; err = 1; s = "rsqrt negative"; break } if (okv) for (i = 0; i < RN; i++) RL[i] = sqrt(RL[i]) }
	else if (op == "rfromres") { n = loadl(j, L); tv = "list=" TL[j]; for (i = 0; i < n; i++) RL[RN++] = L[i]; cpy(L, M, n); m = n }
	# ---- words
	else if (op == "wsort") sorts(WL, WN)
	else if (op == "wrev") { for (i = 0; i < WN; i++) tmp[i] = WL[WN - 1 - i]; cpy(tmp, WL, WN) }
	else if (op == "wdedupe") { n = 0; delete ks; for (i = 0; i < WN; i++) if (!(WL[i] in ks)) { ks[WL[i]] = 1; tmp[n++] = WL[i] } WN = n; delete WL; cpy(tmp, WL, n) }
	else if (op == "wcount") { iv = WN; M[m++] = WN }
	else if (op == "wlens") { for (i = 0; i < WN; i++) M[m++] = length(WL[i]) }
	else if (op == "wlongest") { s = WL[0]; for (i = 1; i < WN; i++) if (length(WL[i]) > length(s)) s = WL[i]; iv = length(s) }
	else if (op == "wjoin") { s = joins(WL, WN, " ") }
	else if (op == "wlonger") { tv = tv " k=" TK[j]; n = 0; for (i = 0; i < WN; i++) if (length(WL[i]) > TK[j]) tmp[n++] = WL[i]; WN = n; delete WL; cpy(tmp, WL, n) }
	else if (op == "wupper") { for (i = 0; i < WN; i++) WL[i] = toupper(WL[i]) }
	else if (op == "winitials") { s = ""; for (i = 0; i < WN; i++) s = s substr(WL[i], 1, 1) }
	else if (op == "wdistinct") { delete ks; for (i = 0; i < WN; i++) if (!(WL[i] in ks)) { ks[WL[i]] = 1; iv++ } M[m++] = iv }
	else if (op == "wcontains") { tv = tv " w=\"" TKW[j] "\""; okv = 0; for (i = 0; i < WN; i++) if (WL[i] == TKW[j]) okv = 1; iv = okv }
	else if (op == "wfreq") { delete ks; for (i = 0; i < WN; i++) ks[WL[i]]++; for (i = 0; i < WN; i++) M[m++] = ks[WL[i]] }
	# ---- vectors
	else if (op == "vlens") { for (i = 0; i < VN; i++) RL[RN++] = sqrt(VX[i] * VX[i] + VY[i] * VY[i] + VZ[i] * VZ[i]) }
	else if (op == "vsum") { sx = 0; sy = 0; sz = 0; for (i = 0; i < VN; i++) { sx += VX[i]; sy += VY[i]; sz += VZ[i] } VN = 1; VX[0] = sx; VY[0] = sy; VZ[0] = sz }
	else if (op == "vcentroid") { sx = 0; sy = 0; sz = 0; for (i = 0; i < VN; i++) { sx += VX[i]; sy += VY[i]; sz += VZ[i] } n = VN; VN = 1; VX[0] = sx / n; VY[0] = sy / n; VZ[0] = sz / n }
	else if (op == "vscale") { tv = tv " k=" fmtr(k); for (i = 0; i < VN; i++) { VX[i] *= k; VY[i] *= k; VZ[i] *= k } }
	else if (op == "vnorm") { for (i = 0; i < VN; i++) { ln = sqrt(VX[i] * VX[i] + VY[i] * VY[i] + VZ[i] * VZ[i]); if (ln == 0) { okv = 0; err = 1; s = "vnorm zero"; break } } if (okv) for (i = 0; i < VN; i++) { ln = sqrt(VX[i] * VX[i] + VY[i] * VY[i] + VZ[i] * VZ[i]); VX[i] /= ln; VY[i] /= ln; VZ[i] /= ln } }
	else if (op == "vdot") { if (VN < 2) { okv = 0; err = 1; s = "vdot needs two" } else rv = VX[0] * VX[1] + VY[0] * VY[1] + VZ[0] * VZ[1] }
	else if (op == "vcross") { if (VN < 2) { okv = 0; err = 1; s = "vcross needs two" } else { a = VY[0] * VZ[1] - VZ[0] * VY[1]; b = VZ[0] * VX[1] - VX[0] * VZ[1]; c = VX[0] * VY[1] - VY[0] * VX[1]; VX[VN] = a; VY[VN] = b; VZ[VN] = c; VN++ } }
	else if (op == "vdist") { if (VN < 2) { okv = 0; err = 1; s = "vdist needs two" } else { a = VX[0] - VX[1]; b = VY[0] - VY[1]; c = VZ[0] - VZ[1]; rv = sqrt(a * a + b * b + c * c) } }
	else if (op == "vbbox") { a = VX[0]; b = VY[0]; c = VZ[0]; sx = VX[0]; sy = VY[0]; sz = VZ[0]; for (i = 1; i < VN; i++) { if (VX[i] < a) a = VX[i]; if (VY[i] < b) b = VY[i]; if (VZ[i] < c) c = VZ[i]; if (VX[i] > sx) sx = VX[i]; if (VY[i] > sy) sy = VY[i]; if (VZ[i] > sz) sz = VZ[i] } VN = 2; VX[0] = a; VY[0] = b; VZ[0] = c; VX[1] = sx; VY[1] = sy; VZ[1] = sz }
	else if (op == "vcount") { iv = VN }
	else if (op == "vflat") { for (i = 0; i < VN; i++) VZ[i] = 0 }
	else if (op == "vlift") { tv = tv " k=" fmtr(k); for (i = 0; i < VN; i++) VZ[i] += k }
	# ---- map
	else if (op == "mhist") { n = loadl(j, L); tv = "list=" TL[j]; clr(); for (i = 0; i < n; i++) MV[L[i]]++; for (t in MV) MN++; cpy(L, M, n); m = n }
	else if (op == "mget") { key = (j == 1) ? 3 : ((j == 2) ? 2 : 99); tv = tv " k=" key; if (key in MV) { iv = MV[key] } else { okv = 0; err = 1; s = "mget missing" } }
	else if (op == "mkeys") { o = 0; for (t in MV) ks[o++] = t + 0; sortn(ks, o); for (i = 0; i < o; i++) M[m++] = ks[i] }
	else if (op == "mvals") { o = 0; for (t in MV) ks[o++] = t + 0; sortn(ks, o); for (i = 0; i < o; i++) M[m++] = MV[ks[i]] }
	else if (op == "minc") { key = TK[j]; tv = tv " k=" key; if (!(key in MV)) { MV[key] = 0; MN++ } MV[key]++ }
	else if (op == "msize") { iv = MN }
	else if (op == "msum") { for (t in MV) iv += MV[t] }
	else if (op == "margmax") { c = ""; for (t in MV) if (c == "" || MV[t] > MV[c] || (MV[t] == MV[c] && t + 0 < c + 0)) c = t; iv = c + 0 }
	else if (op == "mclear") { iv = MN; clr() }
	else if (op == "mset") { key = TK[j]; tv = tv " k=" key " t=" TT[j]; if (!(key in MV)) MN++; MV[key] = TT[j] }
	# ---- records
	else if (op == "ksort") { for (a = 0; a < KN; a++) for (b = 0; b < KN - 1 - a; b++) if (KX[b] > KX[b + 1]) { t = KX[b]; KX[b] = KX[b + 1]; KX[b + 1] = t; t = KI[b]; KI[b] = KI[b + 1]; KI[b + 1] = t; t = KT[b]; KT[b] = KT[b + 1]; KT[b + 1] = t } }
	else if (op == "kids") { for (i = 0; i < KN; i++) M[m++] = KI[i] }
	else if (op == "kmean") { for (i = 0; i < KN; i++) rv += KX[i]; rv = rv / KN }
	else if (op == "ktotal") { for (i = 0; i < KN; i++) rv += KX[i] }
	else if (op == "kabove") { tv = tv " k=" fmtr(k); n = 0; for (i = 0; i < KN; i++) if (KX[i] > k) { KI[n] = KI[i]; KX[n] = KX[i]; KT[n] = KT[i]; n++ } KN = n }
	else if (op == "ktagcount") { tv = tv " w=\"" TKW[j] "\""; for (i = 0; i < KN; i++) if (KT[i] == TKW[j]) iv++ }
	else if (op == "ktagdrop") { tv = tv " w=\"" TKW[j] "\""; n = 0; for (i = 0; i < KN; i++) if (KT[i] != TKW[j]) { KI[n] = KI[i]; KX[n] = KX[i]; KT[n] = KT[i]; n++ } KN = n }
	else if (op == "kmaxid") { c = 0; for (i = 1; i < KN; i++) if (KX[i] > KX[c]) c = i; iv = KI[c] }
	else if (op == "kxs") { for (i = 0; i < KN; i++) RL[RN++] = KX[i] }
	else { print "bad v2 " op > "/dev/stderr"; exit 1 }
	return "test: " tv "\nexpect: " rep(iv, rv, okv, s, err, M, m) rep2()
}
function V2(op, verb, noun, ctx, P, code,   j) { SLOTREAL = (op ~ /^(rscale|roffset|rabove|vscale|vlift|kabove)$/); delete TS; for (j = 1; j <= NC; j++) TS[j] = v2op(op, j) "\n"; H("v2|" op, verb, noun, op, ctx, P, "\tvar out = v;\n" code "\tout.s.clear();\n\tformat(out.s, \"" op "\");\n"); SLOTREAL = 0 }
function v2s() {
	V2("rsum", "sum", "reals", "reals", "sum of the reals|add up the real numbers", "\tvar t = 0.0;\n\tfor q in g.rn { t += g.rl[q]; }\n\tout.r = t;\n")
	V2("rmean", "average", "reals", "reals", "average of the reals|mean of the real numbers", "\tif g.rn == 0 { gold_fail(g, \"no reals\"); out.ok = false; return out; }\n\tvar t = 0.0;\n\tfor q in g.rn { t += g.rl[q]; }\n\tout.r = t / g.rn as real;\n")
	V2("rmax", "max", "reals", "reals", "largest real|maximum of the real numbers", "\tif g.rn == 0 { gold_fail(g, \"no reals\"); out.ok = false; return out; }\n\tvar t = g.rl[0];\n\tfor q in g.rn { if g.rl[q] > t { t = g.rl[q]; } }\n\tout.r = t;\n")
	V2("rmin", "min", "reals", "reals", "smallest real|minimum of the real numbers", "\tif g.rn == 0 { gold_fail(g, \"no reals\"); out.ok = false; return out; }\n\tvar t = g.rl[0];\n\tfor q in g.rn { if g.rl[q] < t { t = g.rl[q]; } }\n\tout.r = t;\n")
	V2("rsort", "sort", "reals", "reals", "sort the reals|order the real numbers ascending", "\tfor a in g.rn { for b in g.rn - 1 - a { if g.rl[b] > g.rl[b + 1] { let s = g.rl[b]; g.rl[b] = g.rl[b + 1]; g.rl[b + 1] = s; } } }\n")
	V2("rrev", "reverse", "reals", "reals", "reverse the reals|flip the real number list", "\tfor a in g.rn / 2 { let s = g.rl[a]; g.rl[a] = g.rl[g.rn - 1 - a]; g.rl[g.rn - 1 - a] = s; }\n")
	V2("rscale", "scale", "reals", "reals", "scale the reals by {k}|multiply each real by {k}", "\tfor q in g.rn { g.rl[q] = g.rl[q] * ${k}; }\n")
	V2("roffset", "offset", "reals", "reals", "offset the reals by {k}|add {k} to each real", "\tfor q in g.rn { g.rl[q] = g.rl[q] + ${k}; }\n")
	V2("rsquare", "square", "reals", "reals", "square each real|square the real numbers", "\tfor q in g.rn { g.rl[q] = g.rl[q] * g.rl[q]; }\n")
	V2("rround", "round", "reals", "reals", "round the reals into results|round each real to a whole number", "\tfor q in g.rn { gold_push(g, round(g.rl[q]) as! int); }\n")
	V2("rfloor", "floor", "reals", "reals", "floor the reals into results|round each real down", "\tfor q in g.rn { gold_push(g, floor(g.rl[q]) as! int); }\n")
	V2("rnorm", "normalize", "reals", "reals", "normalize the reals to unit range|rescale the real numbers into the unit interval", "\tif g.rn == 0 { return out; }\n\tvar mx = g.rl[0];\n\tvar mn = g.rl[0];\n\tfor q in g.rn { if g.rl[q] > mx { mx = g.rl[q]; } if g.rl[q] < mn { mn = g.rl[q]; } }\n\tfor q in g.rn { g.rl[q] = if mx == mn { 0.0 } else { (g.rl[q] - mn) / (mx - mn) }; }\n")
	V2("rcount", "count", "reals", "reals", "count the reals|how many real numbers", "\tout.i = g.rn;\n")
	V2("rabs", "abs", "reals", "reals", "absolute value of each real|make the reals positive", "\tfor q in g.rn { if g.rl[q] < 0.0 { g.rl[q] = -g.rl[q]; } }\n")
	V2("rhalf", "halve", "reals", "reals", "halve the reals|divide each real by two", "\tfor q in g.rn { g.rl[q] = g.rl[q] / 2.0; }\n")
	V2("rabove", "keep", "reals", "reals", "keep reals above {k}|drop reals not greater than {k}", "\tvar m = 0;\n\tfor q in g.rn { if g.rl[q] > ${k} { g.rl[m] = g.rl[q]; m++; } }\n\tg.rn = m;\n")
	V2("rsqrt", "root", "reals", "reals", "square root of each real|take the root of the real numbers", "\tfor q in g.rn { if g.rl[q] < 0.0 { gold_fail(g, \"negative real\"); out.ok = false; out.s.clear(); format(out.s, \"rsqrt negative\"); return out; } }\n\tfor q in g.rn { g.rl[q] = sqrt(g.rl[q]); }\n")
	V2("rfromres", "convert", "reals", "reals", "convert results to reals|copy the results into the real list", "\tfor q in g.n { gold_rpush(g, g.res[q] as real); }\n")
	V2("wsort", "sort", "words", "words", "sort the words|alphabetize the word list", "\tfor a in g.wn { for b in g.wn - 1 - a {\n\t\tlet p = g.wl[b];\n\t\tlet r = g.wl[b + 1];\n\t\tvar d = 0;\n\t\twhile d < p.len && d < r.len && p[d] == r[d] { d++; }\n\t\tlet sw = if d < p.len && d < r.len { p[d] > r[d] } else { p.len > r.len };\n\t\tif sw { g.wl[b] = r; g.wl[b + 1] = p; }\n\t} }\n")
	V2("wrev", "reverse", "words", "words", "reverse the words|flip the word list", "\tfor a in g.wn / 2 { let s = g.wl[a]; g.wl[a] = g.wl[g.wn - 1 - a]; g.wl[g.wn - 1 - a] = s; }\n")
	V2("wdedupe", "dedupe", "words", "words", "remove duplicate words|keep each word once", "\tvar m = 0;\n\tfor q in g.wn { var dup = false; for p in m { if g.wl[p] == g.wl[q] { dup = true; } } if !dup { g.wl[m] = g.wl[q]; m++; } }\n\tg.wn = m;\n")
	V2("wcount", "count", "words", "words", "count the word list|how many words are listed", "\tgold_push(g, g.wn);\n\tout.i = g.wn;\n")
	V2("wlens", "measure", "words", "words", "lengths of the listed words|word list lengths into results", "\tfor q in g.wn { gold_push(g, g.wl[q].len); }\n")
	V2("wlongest", "find", "words", "words", "longest listed word|find the longest word in the list", "\tvar b = 0;\n\tfor q in g.wn { if g.wl[q].len > g.wl[b].len { b = q; } }\n\tif g.wn == 0 { return out; }\n\tgold_text(out, g.wl[b]);\n\tout.i = g.wl[b].len;\n\treturn out;\n")
	V2("wjoin", "join", "words", "words", "join the words|combine the word list into text", "\tvar t byte[>..] = [];\n\tfor q in g.wn { if q > 0 { t.push(' '); } t.append(g.wl[q]); }\n\tgold_text(out, t);\n\treturn out;\n")
	V2("wlonger", "keep", "words", "words", "keep words longer than {k}|drop words of {k} letters or fewer", "\tvar m = 0;\n\tfor q in g.wn { if g.wl[q].len > ${k} { g.wl[m] = g.wl[q]; m++; } }\n\tg.wn = m;\n")
	V2("wupper", "uppercase", "words", "words", "uppercase the words|capitalize every listed word fully", "\tfor q in g.wn { for c in g.wl[q].len { let b = g.wl[q][c]; if b >= 'a' && b <= 'z' { g.wl[q][c] = b - 32; } } }\n")
	V2("winitials", "abbreviate", "words", "words", "initials of the words|first letter of each listed word", "\tvar t byte[>..] = [];\n\tfor q in g.wn { if g.wl[q].len > 0 { t.push(g.wl[q][0]); } }\n\tgold_text(out, t);\n\treturn out;\n")
	V2("wdistinct", "count", "words", "words", "count distinct words|how many different words are listed", "\tvar c = 0;\n\tfor q in g.wn { var dup = false; for p in q { if g.wl[p] == g.wl[q] { dup = true; } } if !dup { c++; } }\n\tgold_push(g, c);\n\tout.i = c;\n")
	V2("wcontains", "check", "words", "words", "check if the words contain {w}|is {w} in the word list", "\tvar c = 0;\n\tfor q in g.wn { if g.wl[q] == ${w} { c = 1; } }\n\tout.ok = c == 1;\n\tout.i = c;\n")
	V2("wfreq", "count", "words", "words", "frequency of each listed word|how often each word appears", "\tfor q in g.wn { var c = 0; for p in g.wn { if g.wl[p] == g.wl[q] { c++; } } gold_push(g, c); }\n")
	V2("vlens", "measure", "vectors", "vectors", "lengths of the vectors|vector magnitudes into reals", "\tfor q in g.vn { gold_rpush(g, gold_vlen(g.vl[q])); }\n")
	V2("vsum", "sum", "vectors", "vectors", "sum of the vectors|add the vectors together", "\tvar t = gold_v3(0.0, 0.0, 0.0);\n\tfor q in g.vn { t = t + g.vl[q]; }\n\tg.vl[0] = t;\n\tg.vn = 1;\n")
	V2("vcentroid", "average", "vectors", "vectors", "centroid of the vectors|average position of the points", "\tif g.vn == 0 { gold_fail(g, \"no vectors\"); out.ok = false; return out; }\n\tvar t = gold_v3(0.0, 0.0, 0.0);\n\tfor q in g.vn { t = t + g.vl[q]; }\n\tlet n = g.vn as real;\n\tg.vl[0] = gold_v3(t.x / n, t.y / n, t.z / n);\n\tg.vn = 1;\n")
	V2("vscale", "scale", "vectors", "vectors", "scale the vectors by {k}|multiply each vector by {k}", "\tfor q in g.vn { g.vl[q] = gold_v3(g.vl[q].x * ${k}, g.vl[q].y * ${k}, g.vl[q].z * ${k}); }\n")
	V2("vnorm", "normalize", "vectors", "vectors", "normalize the vectors|make each vector unit length", "\tfor q in g.vn { if gold_vlen(g.vl[q]) == 0.0 { gold_fail(g, \"zero vector\"); out.ok = false; out.s.clear(); format(out.s, \"vnorm zero\"); return out; } }\n\tfor q in g.vn { let l = gold_vlen(g.vl[q]); g.vl[q] = gold_v3(g.vl[q].x / l, g.vl[q].y / l, g.vl[q].z / l); }\n")
	V2("vdot", "dot", "vectors", "vectors", "dot product of the first two vectors|dot the first vector with the second", "\tif g.vn < 2 { gold_fail(g, \"need two vectors\"); out.ok = false; out.s.clear(); format(out.s, \"vdot needs two\"); return out; }\n\tout.r = gold_vdot(g.vl[0], g.vl[1]);\n")
	V2("vcross", "cross", "vectors", "vectors", "cross product of the first two vectors|cross the first vector with the second", "\tif g.vn < 2 { gold_fail(g, \"need two vectors\"); out.ok = false; out.s.clear(); format(out.s, \"vcross needs two\"); return out; }\n\tgold_vpush(g, cross(g.vl[0], g.vl[1]));\n")
	V2("vdist", "distance", "vectors", "vectors", "distance between the first two vectors|how far apart are the first two points", "\tif g.vn < 2 { gold_fail(g, \"need two vectors\"); out.ok = false; out.s.clear(); format(out.s, \"vdist needs two\"); return out; }\n\tlet d = g.vl[0] - g.vl[1];\n\tout.r = gold_vlen(d);\n")
	V2("vbbox", "bound", "vectors", "vectors", "bounding box of the vectors|corners enclosing the points", "\tif g.vn == 0 { return out; }\n\tvar lo = g.vl[0];\n\tvar hi = g.vl[0];\n\tfor q in g.vn { let p = g.vl[q]; lo = gold_v3(min(lo.x, p.x), min(lo.y, p.y), min(lo.z, p.z)); hi = gold_v3(max(hi.x, p.x), max(hi.y, p.y), max(hi.z, p.z)); }\n\tg.vl[0] = lo;\n\tg.vl[1] = hi;\n\tg.vn = 2;\n")
	V2("vcount", "count", "vectors", "vectors", "count the vectors|how many points are there", "\tout.i = g.vn;\n")
	V2("vflat", "flatten", "vectors", "vectors", "flatten the vectors onto the ground|drop the height of each point", "\tfor q in g.vn { g.vl[q] = gold_v3(g.vl[q].x, g.vl[q].y, 0.0); }\n")
	V2("vlift", "lift", "vectors", "vectors", "lift the vectors by {k}|raise each point by {k}", "\tfor q in g.vn { g.vl[q] = gold_v3(g.vl[q].x, g.vl[q].y, g.vl[q].z + ${k}); }\n")
	V2("mhist", "count", "map", "map", "histogram of results|tally the results into the map", "\tfor q in g.n { gold_madd(g, g.res[q], 1); }\n")
	V2("mget", "lookup", "map", "map", "look up key {k} in the map|value stored for key {k}", "\tlet x, ok = gold_mget(g, ${k});\n\tif !ok { gold_fail(g, \"missing key\"); out.ok = false; out.s.clear(); format(out.s, \"mget missing\"); return out; }\n\tout.i = x;\n")
	V2("mkeys", "list", "map", "map", "keys of the map into results|map keys as a list", "\tvar last = 0;\n\tfor c in g.mn { var best = -1; for i in 128 { if g.mu[i] && (c == 0 || g.mk[i] > last) && (best < 0 || g.mk[i] < g.mk[best]) { best = i; } } if best >= 0 { gold_push(g, g.mk[best]); last = g.mk[best]; } }\n")
	V2("mvals", "list", "map", "map", "values of the map into results|map values in key order", "\tvar last = 0;\n\tfor c in g.mn { var best = -1; for i in 128 { if g.mu[i] && (c == 0 || g.mk[i] > last) && (best < 0 || g.mk[i] < g.mk[best]) { best = i; } } if best >= 0 { gold_push(g, g.mv[best]); last = g.mk[best]; } }\n")
	V2("minc", "increment", "map", "map", "increment key {k} in the map|bump the count for key {k}", "\tgold_madd(g, ${k}, 1);\n")
	V2("msize", "count", "map", "map", "size of the map|how many keys in the map", "\tout.i = g.mn;\n")
	V2("msum", "sum", "map", "map", "sum of the map values|total of the stored values", "\tvar t = 0;\n\tfor i in 128 { if g.mu[i] { t += g.mv[i]; } }\n\tout.i = t;\n")
	V2("margmax", "find", "map", "map", "key with the largest value|which key has the biggest value", "\tvar best = -1;\n\tfor i in 128 { if g.mu[i] && (best < 0 || g.mv[i] > g.mv[best] || (g.mv[i] == g.mv[best] && g.mk[i] < g.mk[best])) { best = i; } }\n\tif best < 0 { return out; }\n\tout.i = g.mk[best];\n")
	V2("mclear", "clear", "map", "map", "clear the map|empty the dictionary", "\tout.i = g.mn;\n\tgold_mclear(g);\n")
	V2("mset", "set", "map", "map", "set key {k} to {t} in the map|store {t} under key {k}", "\tgold_mput(g, ${k}, ${t});\n")
	V2("ksort", "sort", "records", "records", "sort the records by value|order the records by their x", "\tfor a in g.kn { for b in g.kn - 1 - a { if g.kl[b].x > g.kl[b + 1].x { let s = g.kl[b]; g.kl[b] = g.kl[b + 1]; g.kl[b + 1] = s; } } }\n")
	V2("kids", "list", "records", "records", "ids of the records into results|record ids as a list", "\tfor q in g.kn { gold_push(g, g.kl[q].id); }\n")
	V2("kmean", "average", "records", "records", "average value of the records|mean x across records", "\tif g.kn == 0 { gold_fail(g, \"no records\"); out.ok = false; return out; }\n\tvar t = 0.0;\n\tfor q in g.kn { t += g.kl[q].x; }\n\tout.r = t / g.kn as real;\n")
	V2("ktotal", "sum", "records", "records", "total value of the records|sum the x of every record", "\tvar t = 0.0;\n\tfor q in g.kn { t += g.kl[q].x; }\n\tout.r = t;\n")
	V2("kabove", "keep", "records", "records", "keep records with value above {k}|drop records at or below {k}", "\tvar m = 0;\n\tfor q in g.kn { if g.kl[q].x > ${k} { g.kl[m] = g.kl[q]; m++; } }\n\tg.kn = m;\n")
	V2("ktagcount", "count", "records", "records", "count records tagged {w}|how many records have tag {w}", "\tvar c = 0;\n\tfor q in g.kn { if g.kl[q].tag == ${w} { c++; } }\n\tout.i = c;\n")
	V2("ktagdrop", "remove", "records", "records", "remove records tagged {w}|drop every record with tag {w}", "\tvar m = 0;\n\tfor q in g.kn { if !(g.kl[q].tag == ${w}) { g.kl[m] = g.kl[q]; m++; } }\n\tg.kn = m;\n")
	V2("kmaxid", "find", "records", "records", "id of the record with the largest value|which record has the biggest x", "\tif g.kn == 0 { return out; }\n\tvar b = 0;\n\tfor q in g.kn { if g.kl[q].x > g.kl[b].x { b = q; } }\n\tout.i = g.kl[b].id;\n")
	V2("kxs", "list", "records", "records", "record values into reals|copy each record x to the real list", "\tfor q in g.kn { gold_rpush(g, g.kl[q].x); }\n")
}
