# Gold basic pack, hand-written families: reorders, list ops, text, control, bare fn/pred, runtime v2.
# Expected outputs come from the awk models below (independent of the Helium code); verified by hc.
# usage: gawk -f basic.awk -f extra.awk  (uses fmtr/rep/emit/picktests helpers from basic.awk; END there is skipped via MODE)
function sortn(A, n,   i, j, t) { for (i = 0; i < n; i++) for (j = 0; j < n - 1 - i; j++) if (A[j] > A[j + 1]) { t = A[j]; A[j] = A[j + 1]; A[j + 1] = t } }
function sorts(A, n,   i, j, t) { for (i = 0; i < n; i++) for (j = 0; j < n - 1 - i; j++) if (A[j] > A[j + 1]) { t = A[j]; A[j] = A[j + 1]; A[j + 1] = t } }
function cpy(A, B, n,   i) { for (i = 0; i < n; i++) B[i] = A[i] }
function gcd(a, b,   t) { a = iabs(a); b = iabs(b); while (b) { t = a % b; a = b; b = t } return a }
function joins(A, n, sep,   i, s) { s = ""; for (i = 0; i < n; i++) s = s (i ? sep : "") A[i]; return s }
function joinr(A, n,   i, s) { s = ""; for (i = 0; i < n; i++) s = s (i ? "," : "") fmtr(A[i]); return s }
# report2 line from global side state (RL/RN WL/WN VX..VN MK/MV/MN KI/KX/KT/KN)
function rep2(   s, i, o, t, ks) {
	if (RN + WN + VN + MN + KN == 0) return ""
	s = "\nexpect: =>"
	if (RN) s = s " reals=[" joinr(RL, RN) "]"
	if (WN) s = s " words=[" joins(WL, WN, ",") "]"
	if (VN) { s = s " vecs=["; for (i = 0; i < VN; i++) s = s (i ? "," : "") "(" fmtr(VX[i]) " " fmtr(VY[i]) " " fmtr(VZ[i]) ")"; s = s "]" }
	if (MN) { o = 0; for (t in MV) ks[o++] = t + 0; sortn(ks, o); s = s " map={"; for (i = 0; i < o; i++) s = s (i ? "," : "") ks[i] ":" MV[ks[i]]; s = s "}" }
	if (KN) { s = s " recs=["; for (i = 0; i < KN; i++) s = s (i ? "," : "") "{" KI[i] " " fmtr(KX[i]) " " KT[i] "}"; s = s "]" }
	return s
}
function clr() { RN = 0; WN = 0; VN = 0; MN = 0; KN = 0; delete RL; delete WL; delete VX; delete VY; delete VZ; delete MV; delete KI; delete KX; delete KT }
function setx() {
	TX[1] = "the quick brown fox"; TX[2] = "hello world"; TX[3] = "a man a plan a canal"; TX[4] = "gold makes code from words"; TX[5] = "sky"; TX[6] = "level eye noon"; TX[7] = "Big Red Barn"
	TR[1] = "1.5,2.0,-3.25,4.0"; TR[2] = "0.5,0.25,8.0"; TR[3] = "10.0,2.5,7.75,-1.0,3.0"; TR[4] = "9.0,16.0"; TR[5] = "-2.0,-0.5"; TR[6] = "6.25,1.0,100.0"; TR[7] = "3.0"
	TRK[1] = 2.5; TRK[2] = 0.5; TRK[3] = 3; TRK[4] = -1; TRK[5] = 4; TRK[6] = 1.5; TRK[7] = 10
	TW[1] = "apple,kiwi,banana,kiwi"; TW[2] = "zeta,alpha,mu"; TW[3] = "sun,moon,star,sun,sky"; TW[4] = "a,bb,ccc"; TW[5] = "pear"; TW[6] = "dog,cat,dog,dog"; TW[7] = "oak,elm,ash,yew,fir"
	TV[1] = "1:2:2,3:4:0,0:0:5"; TV[2] = "1:0:0,0:1:0,2:2:1"; TV[3] = "3:0:4,6:8:0"; TV[4] = "0:0:1,0:2:0,-1:0:0"; TV[5] = "2:2:2"; TV[6] = "1:1:0,-1:1:0,0:0:3"; TV[7] = "4:4:2,0:3:4"
	TM[1] = "1:2,3:4,5:6"; TM[2] = "7:1,2:9"; TM[3] = "10:10,20:5,30:1"; TM[4] = "4:0"; TM[5] = "1:1,2:2,3:3,4:4"; TM[6] = "9:3,8:2"; TM[7] = "5:50"
	TK_[1] = "1:2.5:ab,2:0.5:cd,3:7.25:ab"; TK_[2] = "4:1.0:x,5:3.5:y"; TK_[3] = "7:-2.0:ab,8:4.0:ab,9:0.0:zz"; TK_[4] = "1:10.0:q"; TK_[5] = "2:6.0:a,3:6.0:b,4:1.0:a"; TK_[6] = "5:0.25:cd,6:0.75:cd"; TK_[7] = "9:9.0:x,8:8.0:y,7:7.0:z"
	TKW[1] = "ab"; TKW[2] = "y"; TKW[3] = "ab"; TKW[4] = "q"; TKW[5] = "a"; TKW[6] = "zz"; TKW[7] = "z"
}
function ldr(j,   a, n, i) { n = split(TR[j], a, ","); RN = n; for (i = 0; i < n; i++) RL[i] = a[i + 1] + 0 }
function ldw(j,   a, n, i) { n = split(TW[j], a, ","); WN = n; for (i = 0; i < n; i++) WL[i] = a[i + 1] }
function ldv(j,   a, b, n, i) { n = split(TV[j], a, ","); VN = n; for (i = 0; i < n; i++) { split(a[i + 1], b, ":"); VX[i] = b[1] + 0; VY[i] = b[2] + 0; VZ[i] = b[3] + 0 } }
function ldm(j,   a, b, n, i) { n = split(TM[j], a, ","); MN = n; for (i = 0; i < n; i++) { split(a[i + 1], b, ":"); MV[b[1] + 0] = b[2] + 0 } }
function ldk(j,   a, b, n, i) { n = split(TK_[j], a, ","); KN = n; for (i = 0; i < n; i++) { split(a[i + 1], b, ":"); KI[i] = b[1] + 0; KX[i] = b[2] + 0; KT[i] = b[3] } }
function upc(s) { return toupper(s) }
# generic emitter for hand entries: P = phrases joined by "|"
function H(key, verb, noun, mod, ctx, P, code,   p, n) { n = split(P, p, "|"); emit("x|" key, verb, noun, mod, ctx, p[1], p[2], (n > 2 ? p[3] : ""), "", code) }
# ---------- list ops: model ----------
function lop(op, j,   L, n, M, m, i, k, t, lo, hi, s, mx, mn, c, seen, line, E, sv, iv, okv, pr) {
	n = loadl(j, L); k = TK[j]; t = TT[j]; lo = TLO[j]; hi = THI[j]; m = 0; iv = 0; okv = 1; s = op; pr = ""; sv = ""
	if (op == "sortasc") { cpy(L, M, n); m = n; sortn(M, m) }
	else if (op == "sortdesc") { cpy(L, E, n); sortn(E, n); for (i = 0; i < n; i++) M[i] = E[n - 1 - i]; m = n }
	else if (op == "reverse") { for (i = 0; i < n; i++) M[i] = L[n - 1 - i]; m = n }
	else if (op == "dedupe") { for (i = 0; i < n; i++) if (!((L[i] "") in seen)) { seen[L[i] ""] = 1; M[m++] = L[i] } }
	else if (op == "takefirst") { for (i = 0; i < n && i < k; i++) M[m++] = L[i] }
	else if (op == "takelast") { for (i = (n > k ? n - k : 0); i < n; i++) M[m++] = L[i] }
	else if (op == "dropfirst") { for (i = k; i < n; i++) M[m++] = L[i] }
	else if (op == "droplast") { for (i = 0; i < n - k; i++) M[m++] = L[i] }
	else if (op == "rotl") { m = n; for (i = 0; i < n; i++) M[i] = L[(i + k) % n] }
	else if (op == "rotr") { m = n; for (i = 0; i < n; i++) M[(i + k) % n] = L[i] }
	else if (op == "prefix") { c = 0; m = n; for (i = 0; i < n; i++) { c += L[i]; M[i] = c } }
	else if (op == "diffs") { for (i = 1; i < n; i++) M[m++] = L[i] - L[i - 1] }
	else if (op == "adjsum") { for (i = 1; i < n; i++) M[m++] = L[i] + L[i - 1] }
	else if (op == "runmax") { m = n; for (i = 0; i < n; i++) { if (i == 0 || L[i] > c) c = L[i]; M[i] = c } }
	else if (op == "runmin") { m = n; for (i = 0; i < n; i++) { if (i == 0 || L[i] < c) c = L[i]; M[i] = c } }
	else if (op == "normalize") { mx = L[0]; mn = L[0]; for (i = 1; i < n; i++) { if (L[i] > mx) mx = L[i]; if (L[i] < mn) mn = L[i] } m = n; for (i = 0; i < n; i++) M[i] = (mx == mn) ? lo : lo + tr_((L[i] - mn) * (hi - lo) / (mx - mn)) }
	else if (op == "clear") { m = 0; iv = n }
	else if (op == "swappairs") { cpy(L, M, n); m = n; for (i = 0; i + 1 < n; i += 2) { c = M[i]; M[i] = M[i + 1]; M[i + 1] = c } }
	else if (op == "everyother") { for (i = 0; i < n; i += 2) M[m++] = L[i] }
	else if (op == "oddpos") { for (i = 1; i < n; i += 2) M[m++] = L[i] }
	else if (op == "append") { cpy(L, M, n); m = n; M[m++] = k }
	else if (op == "prepend") { M[m++] = k; for (i = 0; i < n; i++) M[m++] = L[i] }
	else if (op == "removeall") { for (i = 0; i < n; i++) if (L[i] != k) M[m++] = L[i] }
	else if (op == "countocc") { c = 0; for (i = 0; i < n; i++) if (L[i] == k) c++; M[m++] = c; iv = c }
	else if (op == "contains") { c = 0; for (i = 0; i < n; i++) if (L[i] == k) c = 1; cpy(L, M, n); m = n; okv = c; iv = c }
	else if (op == "indexof") { c = -1; for (i = 0; i < n; i++) if (L[i] == k && c < 0) c = i; M[m++] = c; iv = c }
	else if (op == "weightidx") { m = n; for (i = 0; i < n; i++) M[i] = L[i] * i }
	else if (op == "gcd") { c = 0; for (i = 0; i < n; i++) c = gcd(c, L[i]); M[m++] = c; iv = c }
	else if (op == "countdistinct") { c = 0; for (i = 0; i < n; i++) if (!((L[i] "") in seen)) { seen[L[i] ""] = 1; c++ } M[m++] = c; iv = c }
	else if (op == "sortabs") { cpy(L, M, n); m = n; for (i = 0; i < n; i++) for (c = 0; c < n - 1 - i; c++) if (iabs(M[c]) > iabs(M[c + 1])) { mx = M[c]; M[c] = M[c + 1]; M[c + 1] = mx } }
	else if (op == "minmax") { mx = L[0]; mn = L[0]; for (i = 1; i < n; i++) { if (L[i] > mx) mx = L[i]; if (L[i] < mn) mn = L[i] } M[0] = mn; M[1] = mx; m = 2 }
	else if (op == "second") { cpy(L, E, n); sortn(E, n); c = E[n - 1]; mx = ""; for (i = n - 2; i >= 0; i--) if (E[i] < c) { mx = E[i]; break } if (mx == "") { okv = 0; s = op " none"; m = n; cpy(L, M, n); return "test: list=" TL[j] slotsx(op, j) "\nexpect: " rep(0, 0, 0, s, 1, M, m) } M[m++] = mx; iv = mx }
	else if (op == "mode") { delete seen; for (i = 0; i < n; i++) seen[L[i] ""]++; c = -1; mx = 0; for (i = 0; i < n; i++) if (seen[L[i] ""] > c || (seen[L[i] ""] == c && L[i] < mx)) { c = seen[L[i] ""]; mx = L[i] } M[m++] = mx; iv = mx }
	else if (op == "doublelist") { cpy(L, M, n); m = n; for (i = 0; i < n; i++) M[m++] = L[i] }
	else if (op == "sortdigits") { cpy(L, M, n); m = n; for (i = 0; i < n; i++) for (c = 0; c < n - 1 - i; c++) if (dsum(M[c]) > dsum(M[c + 1])) { mx = M[c]; M[c] = M[c + 1]; M[c + 1] = mx } }
	else if (op == "clampall") { m = n; for (i = 0; i < n; i++) M[i] = (L[i] < lo) ? lo : ((L[i] > hi) ? hi : L[i]) }
	else if (op == "countrange") { m = 0; for (i = lo; i <= hi && m < 512; i++) M[m++] = i; n = 0 }
	else if (op == "rangeto") { m = 0; for (i = 1; i <= k; i++) M[m++] = i }
	else if (op == "fill") { m = 0; for (i = 0; i < t && i < 512; i++) M[m++] = k }
	else if (op == "replaceval") { cpy(L, M, n); m = n; for (i = 0; i < n; i++) if (M[i] == k) M[i] = t }
	else if (op == "insertat") { if (k > n) { okv = 0; s = op " out of range"; cpy(L, M, n); return "test: list=" TL[j] slotsx(op, j) "\nexpect: " rep(0, 0, 0, s, 1, M, n) } for (i = 0; i < k; i++) M[m++] = L[i]; M[m++] = t; for (i = k; i < n; i++) M[m++] = L[i] }
	else if (op == "removeat") { if (k >= n) { okv = 0; s = op " out of range"; cpy(L, M, n); return "test: list=" TL[j] slotsx(op, j) "\nexpect: " rep(0, 0, 0, s, 1, M, n) } for (i = 0; i < n; i++) if (i != k) M[m++] = L[i] }
	else if (op == "getat") { if (k >= n) { okv = 0; s = op " out of range"; cpy(L, M, n); return "test: list=" TL[j] slotsx(op, j) "\nexpect: " rep(0, 0, 0, s, 1, M, n) } iv = L[k]; cpy(L, M, n); m = n }
	else if (op == "printres") { cpy(L, M, n); m = n; pr = "results: " joinl(L, n) "\nexpect: "; s = "printed results" }
	else { print "bad lop " op > "/dev/stderr"; exit 1 }
	return "test: list=" TL[j] slotsx(op, j) "\nexpect: " pr rep(iv, 0, okv, s, (s ~ /out of range|none/) ? 1 : 0, M, m)
}
function slotsx(op, j) {
	if (op ~ /^(takefirst|takelast|dropfirst|droplast|rotl|rotr|append|prepend|removeall|countocc|contains|indexof|rangeto|getat|removeat)$/) return " k=" TK[j]
	if (op ~ /^(fill|replaceval|insertat)$/) return " k=" TK[j] " t=" TT[j]
	if (op ~ /^(normalize|clampall|countrange)$/) return " lo=" TLO[j] " hi=" THI[j]
	return ""
}
function LOP(op, verb, mod, P, code,   j) { delete TS; for (j = 1; j <= NC; j++) TS[j] = lop(op, j) "\n"; H("lop|" op, verb, "results", mod, "list", P, code) }
function lists() {
	LOP("sortasc", "sort", "ascending", "sort results|sort the numbers ascending|sort in ascending order", "\tvar out = v;\n\tfor a in g.n { for b in g.n - 1 - a { if g.res[b] > g.res[b + 1] { let s = g.res[b]; g.res[b] = g.res[b + 1]; g.res[b + 1] = s; } } }\n\tout.s.clear();\n\tformat(out.s, \"sortasc\");\n")
	LOP("sortdesc", "sort", "descending", "sort results descending|sort the numbers from largest to smallest|sort in descending order", "\tvar out = v;\n\tfor a in g.n { for b in g.n - 1 - a { if g.res[b] < g.res[b + 1] { let s = g.res[b]; g.res[b] = g.res[b + 1]; g.res[b + 1] = s; } } }\n\tout.s.clear();\n\tformat(out.s, \"sortdesc\");\n")
	LOP("reverse", "reverse", "list", "reverse results|flip the list backwards", "\tvar out = v;\n\tfor a in g.n / 2 { let s = g.res[a]; g.res[a] = g.res[g.n - 1 - a]; g.res[g.n - 1 - a] = s; }\n\tout.s.clear();\n\tformat(out.s, \"reverse\");\n")
	LOP("dedupe", "dedupe", "results", "remove duplicates|dedupe results|keep only unique values", "\tvar out = v;\n\tvar m = 0;\n\tfor q in g.n {\n\t\tvar dup = false;\n\t\tfor p in m { if g.res[p] == g.res[q] { dup = true; } }\n\t\tif !dup { g.res[m] = g.res[q]; m++; }\n\t}\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"dedupe\");\n")
	LOP("takefirst", "take", "first", "take the first {k}|keep the first {k} results", "\tvar out = v;\n\tif ${k} < g.n { g.n = max(${k}, 0); }\n\tout.s.clear();\n\tformat(out.s, \"takefirst\");\n")
	LOP("takelast", "take", "last", "take the last {k}|keep the last {k} results", "\tvar out = v;\n\tlet st = if g.n > ${k} { g.n - ${k} } else { 0 };\n\tfor q in g.n - st { g.res[q] = g.res[q + st]; }\n\tg.n = g.n - st;\n\tout.s.clear();\n\tformat(out.s, \"takelast\");\n")
	LOP("dropfirst", "drop", "first", "drop the first {k}|skip the first {k} results", "\tvar out = v;\n\tlet st = min(max(${k}, 0), g.n);\n\tfor q in g.n - st { g.res[q] = g.res[q + st]; }\n\tg.n = g.n - st;\n\tout.s.clear();\n\tformat(out.s, \"dropfirst\");\n")
	LOP("droplast", "drop", "last", "drop the last {k}|cut the last {k} results", "\tvar out = v;\n\tg.n = max(g.n - max(${k}, 0), 0);\n\tout.s.clear();\n\tformat(out.s, \"droplast\");\n")
	LOP("rotl", "rotate", "left", "rotate results left by {k}|shift the list left {k} places", "\tvar out = v;\n\tif g.n == 0 { return out; }\n\tvar tmp = [0; 512];\n\tlet n = g.n;\n\tfor q in n { tmp[q] = g.res[(q + ${k}) % n]; }\n\tfor q in n { g.res[q] = tmp[q]; }\n\tout.s.clear();\n\tformat(out.s, \"rotl\");\n")
	LOP("rotr", "rotate", "right", "rotate results right by {k}|shift the list right {k} places", "\tvar out = v;\n\tif g.n == 0 { return out; }\n\tvar tmp = [0; 512];\n\tlet n = g.n;\n\tfor q in n { tmp[(q + ${k}) % n] = g.res[q]; }\n\tfor q in n { g.res[q] = tmp[q]; }\n\tout.s.clear();\n\tformat(out.s, \"rotr\");\n")
	LOP("prefix", "accumulate", "running total", "running total of results|prefix sums of the numbers|cumulative sum", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { c += g.res[q]; g.res[q] = c; }\n\tout.s.clear();\n\tformat(out.s, \"prefix\");\n")
	LOP("diffs", "difference", "neighbours", "differences between neighbours|pairwise differences of results", "\tvar out = v;\n\tif g.n == 0 { return out; }\n\tfor q in g.n - 1 { g.res[q] = g.res[q + 1] - g.res[q]; }\n\tg.n = g.n - 1;\n\tout.s.clear();\n\tformat(out.s, \"diffs\");\n")
	LOP("adjsum", "sum", "neighbours", "sums of neighbouring results|pairwise sums of adjacent numbers", "\tvar out = v;\n\tvar tmp = [0; 512];\n\tvar m = 0;\n\tfor q in g.n { if q > 0 { tmp[m] = g.res[q] + g.res[q - 1]; m++; } }\n\tfor q in m { g.res[q] = tmp[q]; }\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"adjsum\");\n")
	LOP("runmax", "accumulate", "running max", "running maximum of results|running max", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { if q == 0 || g.res[q] > c { c = g.res[q]; } g.res[q] = c; }\n\tout.s.clear();\n\tformat(out.s, \"runmax\");\n")
	LOP("runmin", "accumulate", "running min", "running minimum of results|running min", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { if q == 0 || g.res[q] < c { c = g.res[q]; } g.res[q] = c; }\n\tout.s.clear();\n\tformat(out.s, \"runmin\");\n")
	LOP("normalize", "normalize", "results", "normalize results between {lo} and {hi}|rescale the numbers from {lo} to {hi}", "\tvar out = v;\n\tif g.n == 0 { out.s.clear(); format(out.s, \"normalize\"); return out; }\n\tvar mx = g.res[0];\n\tvar mn = g.res[0];\n\tfor q in g.n { if g.res[q] > mx { mx = g.res[q]; } if g.res[q] < mn { mn = g.res[q]; } }\n\tfor q in g.n { g.res[q] = if mx == mn { ${lo} } else { ${lo} + (g.res[q] - mn) * (${hi} - ${lo}) / (mx - mn) }; }\n\tout.s.clear();\n\tformat(out.s, \"normalize\");\n")
	LOP("clear", "clear", "results", "clear results|empty the list", "\tvar out = v;\n\tout.i = g.n;\n\tgold_clear(g);\n\tout.s.clear();\n\tformat(out.s, \"clear\");\n")
	LOP("swappairs", "swap", "pairs", "swap adjacent pairs|swap neighbouring results", "\tvar out = v;\n\tvar q = 0;\n\twhile q + 1 < g.n { let s = g.res[q]; g.res[q] = g.res[q + 1]; g.res[q + 1] = s; q += 2; }\n\tout.s.clear();\n\tformat(out.s, \"swappairs\");\n")
	LOP("everyother", "keep", "every other", "keep every other result|take alternate numbers", "\tvar out = v;\n\tvar m = 0;\n\tvar q = 0;\n\twhile q < g.n { g.res[m] = g.res[q]; m++; q += 2; }\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"everyother\");\n")
	LOP("oddpos", "keep", "odd positions", "keep results at odd positions|take every second number", "\tvar out = v;\n\tvar m = 0;\n\tvar q = 1;\n\twhile q < g.n { g.res[m] = g.res[q]; m++; q += 2; }\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"oddpos\");\n")
	LOP("append", "append", "value", "append {k}|add {k} to the end", "\tvar out = v;\n\tgold_push(g, ${k});\n\tout.s.clear();\n\tformat(out.s, \"append\");\n")
	LOP("prepend", "prepend", "value", "prepend {k}|put {k} at the front", "\tvar out = v;\n\tif g.n < 512 { var q = g.n; while q > 0 { g.res[q] = g.res[q - 1]; q--; } g.res[0] = ${k}; g.n++; } else { gold_fail(g, \"results full\"); }\n\tout.s.clear();\n\tformat(out.s, \"prepend\");\n")
	LOP("removeall", "remove", "value", "remove every {k}|delete all copies of {k}", "\tvar out = v;\n\tvar m = 0;\n\tfor q in g.n { if g.res[q] != ${k} { g.res[m] = g.res[q]; m++; } }\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"removeall\");\n")
	LOP("countocc", "count", "occurrences", "count occurrences of {k}|how many times {k} appears", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { if g.res[q] == ${k} { c++; } }\n\tgold_clear(g);\n\tgold_push(g, c);\n\tout.i = c;\n\tout.s.clear();\n\tformat(out.s, \"countocc\");\n")
	LOP("contains", "check", "contains", "check if results contain {k}|is {k} in the list", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { if g.res[q] == ${k} { c = 1; } }\n\tout.ok = c == 1;\n\tout.i = c;\n\tout.s.clear();\n\tformat(out.s, \"contains\");\n")
	LOP("indexof", "find", "index", "index of {k}|position of {k} in results", "\tvar out = v;\n\tvar at = -1;\n\tfor q in g.n { if at < 0 && g.res[q] == ${k} { at = q; } }\n\tgold_clear(g);\n\tgold_push(g, at);\n\tout.i = at;\n\tout.s.clear();\n\tformat(out.s, \"indexof\");\n")
	LOP("weightidx", "weight", "position", "multiply each result by its position|weight results by index", "\tvar out = v;\n\tfor q in g.n { g.res[q] = g.res[q] * q; }\n\tout.s.clear();\n\tformat(out.s, \"weightidx\");\n")
	LOP("gcd", "gcd", "results", "greatest common divisor of results|gcd of the numbers", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { var a = core_abs_val(c); var b = core_abs_val(g.res[q]); while b != 0 { let t = a % b; a = b; b = t; } c = a; }\n\tgold_clear(g);\n\tgold_push(g, c);\n\tout.i = c;\n\tout.s.clear();\n\tformat(out.s, \"gcd\");\n")
	LOP("countdistinct", "count", "distinct", "count distinct results|how many unique numbers", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { var dup = false; for p in q { if g.res[p] == g.res[q] { dup = true; } } if !dup { c++; } }\n\tgold_clear(g);\n\tgold_push(g, c);\n\tout.i = c;\n\tout.s.clear();\n\tformat(out.s, \"countdistinct\");\n")
	LOP("sortabs", "sort", "magnitude", "sort results by absolute value|sort the numbers by size ignoring sign", "\tvar out = v;\n\tfor a in g.n { for b in g.n - 1 - a { if core_abs_val(g.res[b]) > core_abs_val(g.res[b + 1]) { let s = g.res[b]; g.res[b] = g.res[b + 1]; g.res[b + 1] = s; } } }\n\tout.s.clear();\n\tformat(out.s, \"sortabs\");\n")
	LOP("sortdigits", "sort", "digit sum", "sort results by digit sum|order the numbers by their digit sums", "\tvar out = v;\n\tfor a in g.n { for b in g.n - 1 - a { if core_digit_sum(g.res[b]) > core_digit_sum(g.res[b + 1]) { let s = g.res[b]; g.res[b] = g.res[b + 1]; g.res[b + 1] = s; } } }\n\tout.s.clear();\n\tformat(out.s, \"sortdigits\");\n")
	LOP("minmax", "find", "extremes", "extremes of results|outer bounds of the numbers", "\tvar out = v;\n\tif g.n == 0 { gold_fail(g, \"no results\"); out.ok = false; return out; }\n\tvar mx = g.res[0];\n\tvar mn = g.res[0];\n\tfor q in g.n { if g.res[q] > mx { mx = g.res[q]; } if g.res[q] < mn { mn = g.res[q]; } }\n\tgold_clear(g);\n\tgold_push(g, mn);\n\tgold_push(g, mx);\n\tout.s.clear();\n\tformat(out.s, \"minmax\");\n")
	LOP("second", "find", "second largest", "second largest result|find the runner up value", "\tvar out = v;\n\tvar mx = 0;\n\tvar have = false;\n\tfor q in g.n { if !have || g.res[q] > mx { mx = g.res[q]; have = true; } }\n\tvar sc = 0;\n\tvar hs = false;\n\tfor q in g.n { if g.res[q] < mx && (!hs || g.res[q] > sc) { sc = g.res[q]; hs = true; } }\n\tif !hs { gold_fail(g, \"no second value\"); out.ok = false; out.s.clear(); format(out.s, \"second none\"); return out; }\n\tgold_clear(g);\n\tgold_push(g, sc);\n\tout.i = sc;\n\tout.s.clear();\n\tformat(out.s, \"second\");\n")
	LOP("mode", "find", "mode", "most common result|mode of the numbers|find the mode", "\tvar out = v;\n\tvar best = 0;\n\tvar bc = -1;\n\tfor q in g.n { var c = 0; for p in g.n { if g.res[p] == g.res[q] { c++; } } if c > bc || (c == bc && g.res[q] < best) { bc = c; best = g.res[q]; } }\n\tgold_clear(g);\n\tgold_push(g, best);\n\tout.i = best;\n\tout.s.clear();\n\tformat(out.s, \"mode\");\n")
	LOP("doublelist", "repeat", "list", "repeat the list twice|append a copy of results", "\tvar out = v;\n\tlet n = g.n;\n\tfor q in n { gold_push(g, g.res[q]); }\n\tout.s.clear();\n\tformat(out.s, \"doublelist\");\n")
	LOP("clampall", "clamp", "results", "clamp results between {lo} and {hi}|keep the numbers inside {lo} to {hi} by clipping", "\tvar out = v;\n\tfor q in g.n { let x = g.res[q]; g.res[q] = if x < ${lo} { ${lo} } else if x > ${hi} { ${hi} } else { x }; }\n\tout.s.clear();\n\tformat(out.s, \"clampall\");\n")
	LOP("countrange", "count", "range", "count from {lo} to {hi}|list the numbers from {lo} up to {hi}", "\tvar out = v;\n\tgold_clear(g);\n\tvar x = ${lo};\n\twhile x <= ${hi} && g.n < 512 { gold_push(g, x); x++; }\n\tout.s.clear();\n\tformat(out.s, \"countrange\");\n")
	LOP("rangeto", "count", "up to", "count up to {k}|numbers from one to {k}", "\tvar out = v;\n\tgold_clear(g);\n\tvar x = 1;\n\twhile x <= ${k} && g.n < 512 { gold_push(g, x); x++; }\n\tout.s.clear();\n\tformat(out.s, \"rangeto\");\n")
	LOP("fill", "fill", "list", "fill the list with {k} repeated {t} times|make {t} copies of {k}", "\tvar out = v;\n\tgold_clear(g);\n\tfor q in max(${t}, 0) { if g.n < 512 { gold_push(g, ${k}); } }\n\tout.s.clear();\n\tformat(out.s, \"fill\");\n")
	LOP("replaceval", "replace", "value", "replace {k} with {t}|change every {k} into {t}", "\tvar out = v;\n\tfor q in g.n { if g.res[q] == ${k} { g.res[q] = ${t}; } }\n\tout.s.clear();\n\tformat(out.s, \"replaceval\");\n")
	LOP("insertat", "insert", "position", "insert {t} at position {k}|put {t} into slot {k}", "\tvar out = v;\n\tif ${k} < 0 || ${k} > g.n || g.n >= 512 { gold_fail(g, \"position out of range\"); out.ok = false; out.s.clear(); format(out.s, \"insertat out of range\"); return out; }\n\tvar q = g.n;\n\twhile q > ${k} { g.res[q] = g.res[q - 1]; q--; }\n\tg.res[${k}] = ${t};\n\tg.n++;\n\tout.s.clear();\n\tformat(out.s, \"insertat\");\n")
	LOP("removeat", "remove", "position", "remove the result at position {k}|delete slot {k}", "\tvar out = v;\n\tif ${k} < 0 || ${k} >= g.n { gold_fail(g, \"position out of range\"); out.ok = false; out.s.clear(); format(out.s, \"removeat out of range\"); return out; }\n\tfor q in g.n - 1 - ${k} { g.res[${k} + q] = g.res[${k} + q + 1]; }\n\tg.n--;\n\tout.s.clear();\n\tformat(out.s, \"removeat\");\n")
	LOP("getat", "get", "position", "get the result at position {k}|value in slot {k}", "\tvar out = v;\n\tif ${k} < 0 || ${k} >= g.n { gold_fail(g, \"position out of range\"); out.ok = false; out.s.clear(); format(out.s, \"getat out of range\"); return out; }\n\tout.i = g.res[${k}];\n\tout.s.clear();\n\tformat(out.s, \"getat\");\n")
	LOP("printres", "print", "results", "print results|show the results|list results", "\tvar out = v;\n\tvar o byte[>..] = [];\n\to.append(\"results: \");\n\tfor q in g.n { if q > 0 { o.append(\",\"); } format(o, g.res[q]); }\n\tprint(o);\n\tout.s.clear();\n\tformat(out.s, \"printed results\");\n")
}
