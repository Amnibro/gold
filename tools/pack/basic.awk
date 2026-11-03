# Gold basic phrase pack generator (phase0).
# Emits short verb-noun entries in the normal Gold entry format. Each test's expected output is
# computed here by an independent awk reference model (not by the Helium code), then the whole
# entry is hc-verified by tools/verify_entries.sh; entries where the two disagree are dropped.
# usage: gawk -f basic.awk > all.gold
function fmtr(x,   p, s) {
	if (x == int(x) && x < 1e15 && x > -1e15) return sprintf("%d.0", x)
	for (p = 1; p <= 17; p++) { s = sprintf("%." p "g", x); if (s + 0 == x) break }
	if (s !~ /[.e]/) s = s ".0"
	return s
}
function sha16(k,   c, h) { c = "printf %s '" k "' | sha1sum"; c | getline h; close(c); return substr(h, 1, 16) }
function joinl(a, n,   i, s) { s = ""; for (i = 0; i < n; i++) s = s (i ? "," : "") a[i]; return s }
function rep(i, r, ok, s, err, L, n) { return "=> i=" i " r=" fmtr(r) " ok=" (ok ? "true" : "false") " s=\"" s "\" errors=" err " n=" n " res=[" joinl(L, n) "] cache=0 hits=0" }
function tr_(x) { return (x < 0) ? -int(-x) : int(x) }
function iabs(x) { return x < 0 ? -x : x }
function dsum(x,  s) { x = iabs(x); s = 0; while (x > 0) { s += x % 10; x = int(x / 10) } return s }
function rdig(x,  r) { x = iabs(x); r = 0; while (x > 0) { r = r * 10 + x % 10; x = int(x / 10) } return r }
function isprime(n,  d) { if (n < 2) return 0; for (d = 2; d * d <= n; d++) if (n % d == 0) return 0; return 1 }
function issq(n,  r) { if (n < 0) return 0; r = 0; while (r * r < n) r++; return r * r == n }
# ---- maps: name | helium expr on X (and ${k}) | label
function mapv(op, x, k) {
	if (op == "double") return x * 2;   if (op == "triple") return x * 3;  if (op == "quadruple") return x * 4
	if (op == "tenfold") return x * 10; if (op == "halve") return tr_(x / 2); if (op == "square") return x * x
	if (op == "cube") return x * x * x; if (op == "negate") return -x;    if (op == "abs") return iabs(x)
	if (op == "inc") return x + 1;      if (op == "dec") return x - 1;     if (op == "digitsum") return dsum(x)
	if (op == "revdigits") return rdig(x); if (op == "sign") return (x > 0) ? 1 : ((x < 0) ? -1 : 0)
	if (op == "collatz") return (x % 2 == 0) ? tr_(x / 2) : 3 * x + 1
	if (op == "addk") return x + k;     if (op == "subk") return x - k;    if (op == "mulk") return x * k
	if (op == "divk") return tr_(x / k); if (op == "modk") { r_ = x % k; if (r_ < 0) r_ += (k < 0 ? -k : k); return r_ }   if (op == "capk") return (x > k) ? k : x
	if (op == "floork") return (x < k) ? k : x
	print "bad map " op > "/dev/stderr"; exit 1
}
function predv(op, x, t, lo, hi) {
	if (op == "even") return x % 2 == 0;  if (op == "odd") return x % 2 != 0; if (op == "positive") return x > 0
	if (op == "negative") return x < 0;   if (op == "zero") return x == 0;    if (op == "nonzero") return x != 0
	if (op == "prime") return isprime(x); if (op == "square") return issq(x); if (op == "palindrome") return rdig(x) == iabs(x)
	if (op == "single") return x > -10 && x < 10; if (op == "twodigit") return iabs(x) >= 10 && iabs(x) <= 99
	if (op == "overhundred") return x > 100;  if (op == "under10") return x < 10
	if (op == "mult3") return x % 3 == 0; if (op == "mult5") return x % 5 == 0; if (op == "mult10") return x % 10 == 0
	if (op == "above") return x > t;      if (op == "below") return x < t;   if (op == "atleast") return x >= t
	if (op == "atmost") return x <= t;    if (op == "divby") return t != 0 && x % t == 0
	if (op == "between") return x >= lo && x <= hi
	print "bad pred " op > "/dev/stderr"; exit 1
}
function setup() {
	NM = split("double triple quadruple tenfold halve square cube negate abs inc dec digitsum revdigits sign collatz addk subk mulk divk modk capk floork", MO, " ")
	# helium expressions (X = the element)
	MH["double"] = "X * 2"; MH["triple"] = "X * 3"; MH["quadruple"] = "X * 4"; MH["tenfold"] = "X * 10"; MH["halve"] = "X / 2"
	MH["square"] = "X * X"; MH["cube"] = "X * X * X"; MH["negate"] = "-X"; MH["abs"] = "core_abs_val(X)"; MH["inc"] = "X + 1"
	MH["dec"] = "X - 1"; MH["digitsum"] = "core_digit_sum(X)"; MH["revdigits"] = "core_reverse_digits(X)"
	MH["sign"] = "if X > 0 { 1 } else if X < 0 { -1 } else { 0 }"; MH["collatz"] = "core_collatz(X)"
	MH["addk"] = "X + ${k}"; MH["subk"] = "X - ${k}"; MH["mulk"] = "X * ${k}"; MH["divk"] = "X / ${k}"; MH["modk"] = "X % ${k}"
	MH["capk"] = "if X > ${k} { ${k} } else { X }"; MH["floork"] = "if X < ${k} { ${k} } else { X }"
	# phrase templates (O = object). two per map
	MP1["double"] = "double O"; MP2["double"] = "multiply O by two"
	MP1["triple"] = "triple O"; MP2["triple"] = "multiply O by three"
	MP1["quadruple"] = "quadruple O"; MP2["quadruple"] = "multiply O by four"
	MP1["tenfold"] = "multiply O by ten"; MP2["tenfold"] = "scale O by ten"
	MP1["halve"] = "halve O"; MP2["halve"] = "divide O by two"
	MP1["square"] = "square O"; MP2["square"] = "raise O to the second power"
	MP1["cube"] = "cube O"; MP2["cube"] = "raise O to the third power"
	MP1["negate"] = "negate O"; MP2["negate"] = "flip the sign of O"
	MP1["abs"] = "take the absolute value of O"; MP2["abs"] = "make O absolute"
	MP1["inc"] = "increment O"; MP2["inc"] = "add one to O"
	MP1["dec"] = "decrement O"; MP2["dec"] = "subtract one from O"
	MP1["digitsum"] = "replace O with digit sums"; MP2["digitsum"] = "take the digit sum of O"
	MP1["revdigits"] = "reverse the digits of O"; MP2["revdigits"] = "mirror the digits of O"
	MP1["sign"] = "replace O with their signs"; MP2["sign"] = "take the sign of O"
	MP1["collatz"] = "apply a collatz step to O"; MP2["collatz"] = "advance O one collatz step"
	MP1["addk"] = "add {k} to O"; MP2["addk"] = "increase O by {k}"
	MP1["subk"] = "subtract {k} from O"; MP2["subk"] = "decrease O by {k}"
	MP1["mulk"] = "multiply O by {k}"; MP2["mulk"] = "scale O by {k}"
	MP1["divk"] = "divide O by {k}"; MP2["divk"] = "split O by a factor of {k}"
	MP1["modk"] = "take O modulo {k}"; MP2["modk"] = "reduce O mod {k}"
	MP1["capk"] = "cap O at {k}"; MP2["capk"] = "limit O to at most {k}"
	MP1["floork"] = "raise O to at least {k}"; MP2["floork"] = "floor O at {k}"
	# adjective for reducer-of-map phrases
	MA["double"] = "doubled"; MA["triple"] = "tripled"; MA["halve"] = "halved"; MA["square"] = "squared"; MA["cube"] = "cubed"
	MA["negate"] = "negated"; MA["abs"] = "absolute"; MA["inc"] = "incremented"; MA["dec"] = "decremented"
	MA["digitsum"] = "digit summed"; MA["revdigits"] = "digit reversed"
	NP = split("even odd positive negative zero nonzero prime square palindrome single twodigit overhundred under10 mult3 mult5 mult10 above below atleast atmost divby between", PO, " ")
	PH["even"] = "X % 2 == 0"; PH["odd"] = "X % 2 != 0"; PH["positive"] = "X > 0"; PH["negative"] = "X < 0"; PH["zero"] = "X == 0"
	PH["nonzero"] = "X != 0"; PH["prime"] = "core_is_prime(X)"; PH["square"] = "core_is_square(X)"; PH["palindrome"] = "core_is_palindrome(X)"
	PH["single"] = "X > -10 && X < 10"; PH["twodigit"] = "core_abs_val(X) >= 10 && core_abs_val(X) <= 99"; PH["overhundred"] = "X > 100"
	PH["under10"] = "X < 10"; PH["mult3"] = "X % 3 == 0"; PH["mult5"] = "X % 5 == 0"; PH["mult10"] = "X % 10 == 0"
	PH["above"] = "X > ${t}"; PH["below"] = "X < ${t}"; PH["atleast"] = "X >= ${t}"; PH["atmost"] = "X <= ${t}"
	PH["divby"] = "${t} != 0 && X % ${t} == 0"; PH["between"] = "X >= ${lo} && X <= ${hi}"
	# noun phrases (R = results noun) and adjective for "is it ..." forms
	PN1["even"] = "even R"; PN2["even"] = "R that are even"; PA["even"] = "even"
	PN1["odd"] = "odd R"; PN2["odd"] = "R that are odd"; PA["odd"] = "odd"
	PN1["positive"] = "positive R"; PN2["positive"] = "R above zero"; PA["positive"] = "positive"
	PN1["negative"] = "negative R"; PN2["negative"] = "R below zero"; PA["negative"] = "negative"
	PN1["zero"] = "zero R"; PN2["zero"] = "R equal to zero"; PA["zero"] = "zero"
	PN1["nonzero"] = "nonzero R"; PN2["nonzero"] = "R that are not zero"; PA["nonzero"] = "nonzero"
	PN1["prime"] = "prime R"; PN2["prime"] = "R that are prime"; PA["prime"] = "prime"
	PN1["square"] = "perfect square R"; PN2["square"] = "R that are perfect squares"; PA["square"] = "a perfect square"
	PN1["palindrome"] = "palindromic R"; PN2["palindrome"] = "R that read the same reversed"; PA["palindrome"] = "a palindrome"
	PN1["single"] = "single digit R"; PN2["single"] = "R with one digit"; PA["single"] = "a single digit"
	PN1["twodigit"] = "two digit R"; PN2["twodigit"] = "R with two digits"; PA["twodigit"] = "two digits long"
	PN1["overhundred"] = "R over a hundred"; PN2["overhundred"] = "R greater than one hundred"; PA["overhundred"] = "over a hundred"
	PN1["under10"] = "R under ten"; PN2["under10"] = "R less than ten"; PA["under10"] = "under ten"
	PN1["mult3"] = "R divisible by three"; PN2["mult3"] = "R that are multiples of three"; PA["mult3"] = "divisible by three"
	PN1["mult5"] = "R divisible by five"; PN2["mult5"] = "R that are multiples of five"; PA["mult5"] = "divisible by five"
	PN1["mult10"] = "R divisible by ten"; PN2["mult10"] = "R that are multiples of ten"; PA["mult10"] = "divisible by ten"
	PN1["above"] = "R above {t}"; PN2["above"] = "R greater than {t}"; PA["above"] = "above {t}"
	PN1["below"] = "R below {t}"; PN2["below"] = "R less than {t}"; PA["below"] = "below {t}"
	PN1["atleast"] = "R at least {t}"; PN2["atleast"] = "R no smaller than {t}"; PA["atleast"] = "at least {t}"
	PN1["atmost"] = "R at most {t}"; PN2["atmost"] = "R no larger than {t}"; PA["atmost"] = "at most {t}"
	PN1["divby"] = "R divisible by {t}"; PN2["divby"] = "R that are multiples of {t}"; PA["divby"] = "divisible by {t}"
	PN1["between"] = "R between {lo} and {hi}"; PN2["between"] = "R from {lo} to {hi}"; PA["between"] = "between {lo} and {hi}"
	NR = split("sum product max min count average median range first last", RO, " ")
	RP1["sum"] = "sum of O"; RP2["sum"] = "add up O"; RP3["sum"] = "total of O"
	RP1["product"] = "product of O"; RP2["product"] = "multiply together O"; RP3["product"] = "find the product of O"
	RP1["max"] = "maximum of O"; RP2["max"] = "largest of O"; RP3["max"] = "find the maximum of O"
	RP1["min"] = "minimum of O"; RP2["min"] = "smallest of O"; RP3["min"] = "find the minimum of O"
	RP1["count"] = "count O"; RP2["count"] = "how many O"; RP3["count"] = "number of O"
	RP1["average"] = "average of O"; RP2["average"] = "mean of O"; RP3["average"] = "find the average of O"
	RP1["median"] = "median of O"; RP2["median"] = "middle value of O"; RP3["median"] = "find the median of O"
	RP1["range"] = "range of O"; RP2["range"] = "spread of O"; RP3["range"] = "gap from smallest to largest of O"
	RP1["first"] = "first of O"; RP2["first"] = "earliest of O"; RP3["first"] = "find the first of O"
	RP1["last"] = "last of O"; RP2["last"] = "latest of O"; RP3["last"] = "find the last of O"
	# tests: list, slot values
	TL[1] = "3,-4,10,7,121,0,25,8,13"; TK[1] = 3; TT[1] = 10; TLO[1] = 0; THI[1] = 20; TI[1] = 7
	TL[2] = "2,9,-15,36,100,11,5,1,44"; TK[2] = 4; TT[2] = 7; TLO[2] = 5; THI[2] = 40; TI[2] = 12
	TL[3] = "150,-7,22,49,6,33,101,-20"; TK[3] = 5; TT[3] = 30; TLO[3] = -10; THI[3] = 25; TI[3] = -5
	TL[4] = "1,4,9,16,0,-3,55,200"; TK[4] = 2; TT[4] = 3; TLO[4] = 1; THI[4] = 9; TI[4] = 0
	TL[5] = "11,13,17,19,23"; TK[5] = 6; TT[5] = 15; TLO[5] = 12; THI[5] = 18; TI[5] = 121
	TL[6] = "-2,-8,-6,40,30,10"; TK[6] = 7; TT[6] = -3; TLO[6] = -8; THI[6] = -2; TI[6] = 30
	TL[7] = "64,81,45,3"; TK[7] = 9; TT[7] = 50; TLO[7] = 40; THI[7] = 70; TI[7] = 45
	NC = 7; NENT = 0; SKIP = 0
}
function slotdecl(txt,   s) {
	s = ""
	if (txt ~ /\$\{k\}|\{k\}/) s = s "slot: k " (SLOTREAL ? "real" : "int") "\n"
	if (txt ~ /\$\{t\}|\{t\}/) s = s "slot: t int\n"
	if (txt ~ /\$\{lo\}|\{lo\}/) s = s "slot: lo int\nslot: hi int\n"
	if (txt ~ /\$\{w\}|\{w\}/) s = s "slot: w text\n"
	if (txt ~ /\$\{x\}|\{x\}/) s = s "slot: x fn\n"
	if (txt ~ /\$\{n\}|\{n\}/) s = s "slot: n int\n"
	if (txt ~ /\$\{p\}|\{p\}/) s = s "slot: p pred\n"
	return s
}
function slotvals(txt, j,   s) {
	s = ""
	if (txt ~ /\{k\}/) s = s " k=" TK[j]
	if (txt ~ /\{t\}/) s = s " t=" TT[j]
	if (txt ~ /\{lo\}/) s = s " lo=" TLO[j] " hi=" THI[j]
	return s
}
function sub_x(tpl, x,   s) { s = tpl; gsub(/X/, x, s); return s }
function emit(key, verb, noun, mod, ctx, p1, p2, p3, tests, code,   id, all) {
	id = sha16("gold-basic|" key)
	if (SEEN[id]++) { print "dup key " key > "/dev/stderr"; return }
	all = p1 p2 p3 code
	tests = picktests(); if (tests == "") { SKIP++; print "skip constant " key > "/dev/stderr"; return }
	printf "@entry %s\nkind: step\nverb: %s\nnoun: %s\nmodifier: %s\ncontext: %s\n", id, verb, noun, mod, ctx
	printf "phrase: %s\nphrase: %s\n", p1, p2
	if (p3 != "") printf "phrase: %s\n", p3
	printf "%s%s", slotdecl(all), tests
	printf "code:\nfn ${ID}(g Gold&, v Val) Val {\n%s\tout\n}\n@end\n\n", code
	NENT++
}
function loadl(j, L,   a, n, i) { n = split(TL[j], a, ","); for (i = 0; i < n; i++) L[i] = a[i + 1] + 0; return n }
function lbl(s) { return s }
# ---- families
function fam_map(op, pr,   j, L, n, i, k, t, lo, hi, out, tests, code, P1, P2, lab, tv) {
	lab = (pr == "") ? op : op " " pr
	tests = ""
	delete TS; for (j = 1; j <= NC; j++) {
		n = loadl(j, L); k = TK[j]; t = TT[j]; lo = TLO[j]; hi = THI[j]
		for (i = 0; i < n; i++) if (pr == "" || predv(pr, L[i], t, lo, hi)) L[i] = mapv(op, L[i], k)
		tv = "list=" TL[j] slotvals(MP1[op] (pr == "" ? "" : PN1[pr]), j)
		TS[j] = "test: " tv "\nexpect: " rep(0, 0, 1, lab, 0, L, n) "\n"
	}
	code = "\tvar out = v;\n"
	if (op == "divk" || op == "modk") code = code "\tif ${k} == 0 { gold_fail(g, \"divide by zero\"); out.ok = false; return out; }\n"
	code = code "\tfor q in g.n {\n\t\tlet x = g.res[q];\n"
	if (pr == "") code = code "\t\tg.res[q] = " sub_x(MH[op], "x") ";\n"
	else code = code "\t\tif " sub_x(PH[pr], "x") " { g.res[q] = " sub_x(MH[op], "x") "; }\n"
	code = code "\t}\n\tout.s.clear();\n\tformat(out.s, \"" lab "\");\n"
	if (pr == "") { P1 = MP1[op]; sub(/O/, "each result", P1); P2 = MP2[op]; sub(/O/, "every number", P2) }
	else { P1 = MP1[op]; sub(/O/, "the " PN1[pr], P1); sub(/R/, "results", P1); P2 = MP2[op]; sub(/O/, "only " PN2[pr], P2); sub(/R/, "numbers", P2) }
	emit("map|" op "|" pr, op, "results", pr == "" ? "each" : pr, "list", P1, P2, "", tests, code)
}
function fam_filter(keep, pr,   j, L, n, i, m, M, t, lo, hi, tests, code, P1, P2, lab, w) {
	lab = (keep ? "kept " : "removed ") pr
	tests = ""
	delete TS; for (j = 1; j <= NC; j++) {
		n = loadl(j, L); t = TT[j]; lo = TLO[j]; hi = THI[j]; m = 0
		for (i = 0; i < n; i++) { w = predv(pr, L[i], t, lo, hi); if ((keep && w) || (!keep && !w)) M[m++] = L[i] }
		TS[j] = "test: list=" TL[j] slotvals(PN1[pr], j) "\nexpect: " rep(0, 0, 1, lab, 0, M, m) "\n"
	}
	code = "\tvar out = v;\n\tvar m = 0;\n\tfor q in g.n {\n\t\tlet x = g.res[q];\n\t\tif " (keep ? "" : "!(") sub_x(PH[pr], "x") (keep ? "" : ")") " { g.res[m] = x; m++; }\n\t}\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"" lab "\");\n"
	if (keep) { P1 = "keep " PN1[pr]; P2 = "keep only " PN2[pr] } else { P1 = "remove " PN1[pr]; P2 = "throw away " PN2[pr] }
	sub(/R/, "results", P1); sub(/R/, "numbers", P2)
	emit("filter|" keep "|" pr, keep ? "keep" : "remove", "results", pr, "filter", P1, P2, "", tests, code)
}
# reducer over results, optionally only P, optionally after map M
function fam_red(rd, pr, mp,   j, L, n, i, t, lo, hi, k, X, c, acc, tot, tests, code, P1, P2, P3, lab, fail, x, S, a, b, mx, mn, ii, jj, tmp, rr, obj1, obj2) {
	lab = rd; if (mp != "") lab = lab " " mp; if (pr != "") lab = lab " " pr
	fail = (rd != "sum" && rd != "product" && rd != "count")
	tests = ""
	delete TS; for (j = 1; j <= NC; j++) {
		n = loadl(j, L); t = TT[j]; lo = TLO[j]; hi = THI[j]; k = TK[j]; c = 0; tot = 0
		for (i = 0; i < n; i++) if (pr == "" || predv(pr, L[i], t, lo, hi)) { x = (mp == "") ? L[i] : mapv(mp, L[i], k); X[c++] = x; tot += x }
		rr = 0
		if (c == 0 && fail) { TS[j] = "test: list=" TL[j] slotvals(PN1[pr], j) "\nexpect: " rep(0, 0, 0, lab " none", 1, L, n) "\n"; continue }
		if (rd == "sum") acc = tot
		else if (rd == "product") { acc = 1; for (i = 0; i < c; i++) acc *= X[i] }
		else if (rd == "max") { acc = X[0]; for (i = 1; i < c; i++) if (X[i] > acc) acc = X[i] }
		else if (rd == "min") { acc = X[0]; for (i = 1; i < c; i++) if (X[i] < acc) acc = X[i] }
		else if (rd == "count") acc = c
		else if (rd == "average") { acc = tr_(tot / c); rr = tot / c }
		else if (rd == "median") {
			for (ii = 0; ii < c; ii++) for (jj = 0; jj < c - 1 - ii; jj++) if (X[jj] > X[jj + 1]) { tmp = X[jj]; X[jj] = X[jj + 1]; X[jj + 1] = tmp }
			acc = X[int((c - 1) / 2)]; rr = (c % 2 == 1) ? X[int(c / 2)] : (X[c / 2 - 1] + X[c / 2]) / 2
		}
		else if (rd == "range") { mx = X[0]; mn = X[0]; for (i = 1; i < c; i++) { if (X[i] > mx) mx = X[i]; if (X[i] < mn) mn = X[i] } acc = mx - mn }
		else if (rd == "first") acc = X[0]
		else if (rd == "last") acc = X[c - 1]
		S[0] = acc
		TS[j] = "test: list=" TL[j] slotvals(PN1[pr] MP1[mp], j) "\nexpect: " rep(acc, rr, 1, lab, 0, S, 1) "\n"
	}
	code = "\tvar out = v;\n\tvar cnt = 0;\n\tvar acc = 0;\n\tvar tot = 0;\n"
	if (rd == "median" || rd == "range") code = code "\tvar tmp = [0; 512];\n"
	if (mp == "divk" || mp == "modk") code = code "\tif ${k} == 0 { gold_fail(g, \"divide by zero\"); out.ok = false; return out; }\n"
	code = code "\tfor q in g.n {\n\t\tlet x0 = g.res[q];\n"
	code = code "\t\tif " (pr == "" ? "true" : sub_x(PH[pr], "x0")) " {\n\t\t\tlet x = " (mp == "" ? "x0" : sub_x(MH[mp], "x0")) ";\n"
	if (rd == "sum") code = code "\t\t\tacc += x;\n"
	else if (rd == "product") code = code "\t\t\tif cnt == 0 { acc = x; } else { acc *= x; }\n"
	else if (rd == "max") code = code "\t\t\tif cnt == 0 || x > acc { acc = x; }\n"
	else if (rd == "min") code = code "\t\t\tif cnt == 0 || x < acc { acc = x; }\n"
	else if (rd == "first") code = code "\t\t\tif cnt == 0 { acc = x; }\n"
	else if (rd == "last") code = code "\t\t\tacc = x;\n"
	else if (rd == "median" || rd == "range") code = code "\t\t\ttmp[cnt] = x;\n"
	code = code "\t\t\ttot += x;\n\t\t\tcnt++;\n\t\t}\n\t}\n"
	if (fail) code = code "\tif cnt == 0 { gold_fail(g, \"no matching results\"); out.ok = false; out.s.clear(); format(out.s, \"" lab " none\"); return out; }\n"
	if (rd == "product") code = code "\tif cnt == 0 { acc = 1; }\n"
	if (rd == "count") code = code "\tacc = cnt;\n"
	if (rd == "average") code = code "\tacc = tot / cnt;\n\tout.r = tot as real / cnt as real;\n"
	if (rd == "median") code = code "\tfor a in cnt { for b in cnt - 1 - a { if tmp[b] > tmp[b + 1] { let s = tmp[b]; tmp[b] = tmp[b + 1]; tmp[b + 1] = s; } } }\n\tacc = tmp[(cnt - 1) / 2];\n\tout.r = if cnt % 2 == 1 { tmp[cnt / 2] as real } else { (tmp[cnt / 2 - 1] + tmp[cnt / 2]) as real / 2.0 };\n"
	if (rd == "range") code = code "\tvar mx = tmp[0];\n\tvar mn = tmp[0];\n\tfor a in cnt { if tmp[a] > mx { mx = tmp[a]; } if tmp[a] < mn { mn = tmp[a]; } }\n\tacc = mx - mn;\n"
	code = code "\tgold_clear(g);\n\tgold_push(g, acc);\n\tout.i = acc;\n\tout.s.clear();\n\tformat(out.s, \"" lab "\");\n"
	obj1 = "results"; obj2 = "the numbers"
	if (pr != "") { obj1 = PN1[pr]; sub(/R/, "results", obj1); obj2 = "the " PN2[pr]; sub(/R/, "numbers", obj2) }
	if (mp != "") { obj1 = MA[mp] " " obj1; obj2 = "the " MA[mp] " values of " obj2 }
	P1 = RP1[rd]; sub(/O/, obj1, P1); P2 = RP2[rd]; sub(/O/, obj2, P2); P3 = ""
	if (pr == "" && mp == "") { P3 = RP3[rd]; sub(/ of O$/, "", P3); sub(/ O$/, "", P3); if (rd == "count") P3 = "tally results"; if (rd == "sum") P3 = "sum results" }
	emit("red|" rd "|" pr "|" mp, rd, "results", (pr == "" ? "all" : pr) (mp == "" ? "" : " " mp), "aggregate", P1, P2, P3, tests, code)
}
# value ops: map / check on v.i, optionally only when P
function fam_val(op, pr,   j, x, tests, code, P1, P2, lab, E) {
	lab = "value " op (pr == "" ? "" : " " pr); tests = ""
	delete TS; for (j = 1; j <= NC; j++) {
		x = TI[j]; if (pr == "" || predv(pr, x, TT[j], TLO[j], THI[j])) x = mapv(op, x, TK[j])
		TS[j] = "test: input=" TI[j] slotvals(MP1[op] (pr == "" ? "" : PA[pr]), j) "\nexpect: " rep(x, 0, 1, lab, 0, E, 0) "\n"
	}
	code = "\tvar out = v;\n"
	if (op == "divk" || op == "modk") code = code "\tif ${k} == 0 { gold_fail(g, \"divide by zero\"); out.ok = false; return out; }\n"
	code = code "\tlet x = v.i;\n"
	if (pr == "") code = code "\tout.i = " sub_x(MH[op], "x") ";\n"
	else code = code "\tif " sub_x(PH[pr], "x") " { out.i = " sub_x(MH[op], "x") "; }\n"
	code = code "\tout.s.clear();\n\tformat(out.s, \"" lab "\");\n"
	P1 = MP1[op]; P2 = MP2[op]
	if (pr == "") { sub(/O/, "it", P1); sub(/O/, "the value", P2) }
	else { sub(/O/, "it", P1); P1 = P1 " if it is " PA[pr]; sub(/O/, "the value", P2); P2 = P2 " when it is " PA[pr] }
	emit("val|" op "|" pr, op, "value", pr == "" ? "plain" : pr, "scalar", P1, P2, "", tests, code)
}
function fam_valcheck(pr,   j, x, w, tests, code, lab, E) {
	lab = "is " pr; tests = ""
	delete TS; for (j = 1; j <= NC; j++) {
		x = TI[j]; w = predv(pr, x, TT[j], TLO[j], THI[j])
		TS[j] = "test: input=" TI[j] slotvals(PA[pr], j) "\nexpect: " rep(w ? 1 : 0, 0, w, lab, 0, E, 0) "\n"
	}
	code = "\tvar out = v;\n\tlet x = v.i;\n\tout.ok = " sub_x(PH[pr], "x") ";\n\tout.i = if out.ok { 1 } else { 0 };\n\tout.s.clear();\n\tformat(out.s, \"" lab "\");\n"
	emit("valcheck|" pr, "check", "value", pr, "scalar", "check if it is " PA[pr], "is the value " PA[pr], "", tests, code)
}
# any / all / index-of-first / replace / first k matching
function fam_q(q, pr,   j, L, n, i, c, w, idx, tests, code, P1, P2, lab, M, m, E, all, k) {
	lab = q " " pr; tests = ""
	delete TS; for (j = 1; j <= NC; j++) {
		n = loadl(j, L); c = 0; idx = -1; all = 1; m = 0; k = TK[j]
		for (i = 0; i < n; i++) { w = predv(pr, L[i], TT[j], TLO[j], THI[j]); if (w) { c++; if (idx < 0) idx = i } else all = 0 }
		if (q == "any") line = rep(c > 0 ? 1 : 0, 0, c > 0, lab, 0, L, n)
		else if (q == "all") line = rep(all ? 1 : 0, 0, all, lab, 0, L, n)
		else if (q == "index") { E[0] = idx; line = rep(idx, 0, 1, lab, 0, E, 1) }
		else if (q == "replace") { for (i = 0; i < n; i++) if (predv(pr, L[i], TT[j], TLO[j], THI[j])) L[i] = k; line = rep(0, 0, 1, lab, 0, L, n) }
		else if (q == "firstk") { for (i = 0; i < n && m < k; i++) if (predv(pr, L[i], TT[j], TLO[j], THI[j])) M[m++] = L[i]; line = rep(0, 0, 1, lab, 0, M, m) }
		TS[j] = "test: list=" TL[j] slotvals(PN1[pr] (q == "replace" || q == "firstk" ? "{k}" : ""), j) "\nexpect: " line "\n"
	}
	code = "\tvar out = v;\n"
	if (q == "any" || q == "all") {
		code = code "\tvar c = 0;\n\tfor q in g.n { let x = g.res[q]; if " sub_x(PH[pr], "x") " { c++; } }\n"
		code = code "\tout.ok = " (q == "any" ? "c > 0" : "c == g.n") ";\n\tout.i = if out.ok { 1 } else { 0 };\n"
	} else if (q == "index") {
		code = code "\tvar at = -1;\n\tfor q in g.n { let x = g.res[q]; if at < 0 && " sub_x(PH[pr], "x") " { at = q; } }\n\tgold_clear(g);\n\tgold_push(g, at);\n\tout.i = at;\n"
	} else if (q == "replace") {
		code = code "\tfor q in g.n { let x = g.res[q]; if " sub_x(PH[pr], "x") " { g.res[q] = ${k}; } }\n"
	} else {
		code = code "\tvar m = 0;\n\tfor q in g.n { let x = g.res[q]; if m < ${k} && " sub_x(PH[pr], "x") " { g.res[m] = x; m++; } }\n\tg.n = m;\n"
	}
	code = code "\tout.s.clear();\n\tformat(out.s, \"" lab "\");\n"
	if (q == "any") { P1 = "are there any " PN1[pr]; P2 = "check if any " PN2[pr] }
	if (q == "all") { P1 = "are all results " PA[pr]; P2 = "check whether every number is " PA[pr] }
	if (q == "index") { P1 = "index of the first " PN1[pr]; P2 = "position of the first of the " PN2[pr] }
	if (q == "replace") { P1 = "replace " PN1[pr] " with {k}"; P2 = "set " PN2[pr] " to {k}" }
	if (q == "firstk") { P1 = "take the first {k} " PN1[pr]; P2 = "keep the first {k} of the " PN2[pr] }
	sub(/R/, "results", P1); sub(/R/, "numbers", P2)
	if (q == "all") { sub(/R/, "results", P1); sub(/R/, "numbers", P2) }
	emit("q|" q "|" pr, q, "results", pr, "query", P1, P2, "", tests, code)
}
END {
	setup()
	for (a = 1; a <= NM; a++) fam_map(MO[a], "")
	for (a = 1; a <= NM; a++) for (b = 1; b <= NP; b++) {
		# slot maps only with no-slot preds; no-slot maps with all preds
		if (MO[a] ~ /k$/ && PO[b] ~ /^(above|below|atleast|atmost|divby|between)$/) continue
		fam_map(MO[a], PO[b])
	}
	for (b = 1; b <= NP; b++) { fam_filter(1, PO[b]); fam_filter(0, PO[b]) }
	for (r = 1; r <= NR; r++) { fam_red(RO[r], "", ""); for (b = 1; b <= NP; b++) fam_red(RO[r], PO[b], "") }
	for (r = 1; r <= NR; r++) { if (RO[r] == "count" || RO[r] == "product") continue; for (m in MA) fam_red(RO[r], "", m) }
	split("sum max min average", R4, " ")
	split("square double abs digitsum cube", M5, " ")
	for (r = 1; r <= 4; r++) for (m = 1; m <= 5; m++) for (b = 1; b <= NP; b++) { if (PO[b] ~ /^(atleast|atmost|single|twodigit|mult10)$/) continue; fam_red(R4[r], PO[b], M5[m]) }
	for (a = 1; a <= NM; a++) fam_val(MO[a], "")
	for (a = 1; a <= NM; a++) for (b = 1; b <= NP; b++) { if (MO[a] ~ /k$/ || PO[b] ~ /^(atleast|atmost|single|twodigit|mult10|between)$/) continue; fam_val(MO[a], PO[b]) }
	for (b = 1; b <= NP; b++) fam_valcheck(PO[b])
	split("any all index replace firstk", QQ, " ")
	for (q = 1; q <= 5; q++) for (b = 1; b <= NP; b++) { if ((QQ[q] == "replace" || QQ[q] == "firstk") && PO[b] ~ /^(above|below|atleast|atmost|divby|between)$/) {} fam_q(QQ[q], PO[b]) }
	setx(); lists(); texts(); controls(); fnpreds(); v2s()
	print NENT " entries, " SKIP " skipped" > "/dev/stderr"
}
function exp_of(b) { return substr(b, index(b, "\nexpect: ")) }
function picktests(   j, a, b) {
	for (a = 1; a <= NC; a++) for (b = a + 1; b <= NC; b++) if ((a in TS) && (b in TS) && exp_of(TS[a]) != exp_of(TS[b])) return TS[a] TS[b]
	return ""
}
