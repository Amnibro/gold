# Gold basic pack part 3: text, control, bare fn/pred, runtime-v2 (reals, words, vectors, map, records).
function revs(s,   i, r) { r = ""; for (i = length(s); i >= 1; i--) r = r substr(s, i, 1); return r }
function nvow(s,   i, c, ch) { c = 0; for (i = 1; i <= length(s); i++) { ch = tolower(substr(s, i, 1)); if (index("aeiou", ch)) c++ } return c }
function capw(s,   i, r, prev, ch) { r = ""; prev = " "; for (i = 1; i <= length(s); i++) { ch = substr(s, i, 1); r = r ((prev == " " && ch ~ /[a-z]/) ? toupper(ch) : ch); prev = ch } return r }
function top(op, j,   s, W, n, i, M, m, iv, okv, pr, best, t) {
	s = TX[j]; n = split(s, W, " "); m = 0; iv = 0; okv = 1; pr = ""; clr()
	if (op == "countwords") { M[m++] = n; iv = n }
	else if (op == "countchars") { M[m++] = length(s); iv = length(s) }
	else if (op == "countvowels") { iv = nvow(s); M[m++] = iv }
	else if (op == "wordlens") { for (i = 1; i <= n; i++) M[m++] = length(W[i]) }
	else if (op == "upper") s = toupper(s)
	else if (op == "lower") s = tolower(s)
	else if (op == "revtext") s = revs(s)
	else if (op == "split") { for (i = 1; i <= n; i++) WL[WN++] = W[i] }
	else if (op == "longest") { best = W[1]; for (i = 2; i <= n; i++) if (length(W[i]) > length(best)) best = W[i]; s = best; iv = length(best) }
	else if (op == "shortest") { best = W[1]; for (i = 2; i <= n; i++) if (length(W[i]) < length(best)) best = W[i]; s = best; iv = length(best) }
	else if (op == "firstword") s = W[1]
	else if (op == "lastword") s = W[n]
	else if (op == "capitalize") s = capw(s)
	else if (op == "nospaces") gsub(/ /, "", s)
	else if (op == "textpal") { t = tolower(s); gsub(/ /, "", t); okv = (t == revs(t)); iv = okv ? 1 : 0 }
	else if (op == "printtext") pr = "text: " s "\nexpect: "
	else if (op == "initials") { t = ""; for (i = 1; i <= n; i++) t = t substr(W[i], 1, 1); s = t }
	else { print "bad top " op > "/dev/stderr"; exit 1 }
	return "test: text=\"" TX[j] "\"\nexpect: " pr rep(iv, 0, okv, s, 0, M, m) rep2()
}
function TOP(op, verb, P, code,   j) { delete TS; for (j = 1; j <= NC; j++) TS[j] = top(op, j) "\n"; H("text|" op, verb, "text", op, "text", P, code) }
function texts() {
	TOP("countwords", "count", "count the words|how many words in the text|word count", "\tvar out = v;\n\tvar c = 0;\n\tfor w in words(v.s) { if w.len > 0 { c++; } }\n\tgold_push(g, c);\n\tout.i = c;\n")
	TOP("countchars", "count", "count the characters|length of the text", "\tvar out = v;\n\tlet c = v.s.len;\n\tgold_push(g, c);\n\tout.i = c;\n")
	TOP("countvowels", "count", "count the vowels|how many vowels in the text", "\tvar out = v;\n\tvar c = 0;\n\tfor b in v.s { let l = if b >= 'A' && b <= 'Z' { b + 32 } else { b }; if l == 'a' || l == 'e' || l == 'i' || l == 'o' || l == 'u' { c++; } }\n\tgold_push(g, c);\n\tout.i = c;\n")
	TOP("wordlens", "measure", "word lengths into results|length of each word", "\tvar out = v;\n\tfor w in words(v.s) { if w.len > 0 { gold_push(g, w.len); } }\n\tout.i = 0;\n")
	TOP("upper", "uppercase", "uppercase the text|make the text capital letters", "\tvar out = v;\n\tfor q in out.s.len { let b = out.s[q]; if b >= 'a' && b <= 'z' { out.s[q] = b - 32; } }\n\tout.i = 0;\n")
	TOP("lower", "lowercase", "lowercase the text|make the text small letters", "\tvar out = v;\n\tfor q in out.s.len { let b = out.s[q]; if b >= 'A' && b <= 'Z' { out.s[q] = b + 32; } }\n\tout.i = 0;\n")
	TOP("revtext", "reverse", "reverse the text|spell the text backwards", "\tvar out = v;\n\tlet n = out.s.len;\n\tfor q in n / 2 { let b = out.s[q]; out.s[q] = out.s[n - 1 - q]; out.s[n - 1 - q] = b; }\n\tout.i = 0;\n")
	TOP("split", "split", "split the text into words|break the text into a word list", "\tvar out = v;\n\tgold_words_of(g, v.s);\n\tout.i = 0;\n")
	TOP("longest", "find", "find the longest word|longest word in the text", "\tvar out = v;\n\tvar best byte[>..] = [];\n\tfor w in words(v.s) { if w.len > best.len { best.clear(); best.append(w); } }\n\tgold_text(out, best);\n\tout.i = best.len;\n")
	TOP("shortest", "find", "find the shortest word|shortest word in the text", "\tvar out = v;\n\tvar best byte[>..] = [];\n\tvar have = false;\n\tfor w in words(v.s) { if w.len > 0 && (!have || w.len < best.len) { best.clear(); best.append(w); have = true; } }\n\tgold_text(out, best);\n\tout.i = best.len;\n")
	TOP("firstword", "take", "first word of the text|take the opening word", "\tvar out = v;\n\tvar best byte[>..] = [];\n\tfor w in words(v.s) { if best.len == 0 && w.len > 0 { best.append(w); } }\n\tgold_text(out, best);\n")
	TOP("lastword", "take", "last word of the text|take the final word", "\tvar out = v;\n\tvar best byte[>..] = [];\n\tfor w in words(v.s) { if w.len > 0 { best.clear(); best.append(w); } }\n\tgold_text(out, best);\n")
	TOP("capitalize", "capitalize", "capitalize each word|title case the text", "\tvar out = v;\n\tvar prev = ' ';\n\tfor q in out.s.len { let b = out.s[q]; if prev == ' ' && b >= 'a' && b <= 'z' { out.s[q] = b - 32; } prev = b; }\n\tout.i = 0;\n")
	TOP("nospaces", "remove", "remove the spaces|strip spaces from the text", "\tvar out = v;\n\tvar t byte[>..] = [];\n\tfor b in v.s { if b != ' ' { t.push(b); } }\n\tgold_text(out, t);\n")
	TOP("textpal", "check", "check if the text is a palindrome|does the text read the same backwards", "\tvar out = v;\n\tvar t byte[>..] = [];\n\tfor b in v.s { if b != ' ' { t.push(if b >= 'A' && b <= 'Z' { b + 32 } else { b }); } }\n\tvar same = true;\n\tfor q in t.len / 2 { if t[q] != t[t.len - 1 - q] { same = false; } }\n\tout.ok = same;\n\tout.i = if same { 1 } else { 0 };\n")
	TOP("printtext", "print", "print the text|show the text", "\tvar out = v;\n\tprint(\"text: \", v.s);\n\tout.i = 0;\n")
	TOP("initials", "abbreviate", "initials of the text|first letters of each word", "\tvar out = v;\n\tvar t byte[>..] = [];\n\tfor w in words(v.s) { if w.len > 0 { t.push(w[0]); } }\n\tgold_text(out, t);\n")
}
# ----- control / value -----
function corefn(f, x) { if (f == "abs_val") return iabs(x); if (f == "digit_sum") return dsum(x); if (f == "reverse_digits") return rdig(x); if (f == "inc") return x + 1; if (f == "dec") return x - 1; return mapv(f, x, 0) }
function corepred(p, x) { if (p == "is_one") return x == 1; if (p == "is_zero") return x == 0; if (p == "is_even") return x % 2 == 0; if (p == "is_odd") return x % 2 != 0; if (p == "is_negative") return x < 0; if (p == "over_100") return x > 100; if (p == "under_10") return x < 10; if (p == "is_prime") return isprime(x); if (p == "is_square") return issq(x); if (p == "is_palindrome") return rdig(x) == iabs(x) }
function ctl(op, j,   F, P, L, n, M, m, i, x, iv, pr, c, fx, px, s) {
	split("collatz double inc square negate triple digit_sum", F, " "); split("is_even is_odd is_prime over_100 under_10 is_square is_negative", P, " ")
	fx = F[j]; px = P[j]; m = 0; iv = 0; pr = ""; clr()
	if (op == "runn") { x = TI[j]; c = (j % 4) + 2; for (i = 0; i < c; i++) { x = corefn(fx, x); M[m++] = x } return "test: input=" TI[j] " x=" fx " n=" c "\nexpect: " rep(x, 0, 1, "ran " c, 0, M, m) }
	if (op == "printit") { return "test: input=" TI[j] "\nexpect: value: " TI[j] "\nexpect: " rep(TI[j], 0, 1, "printed value", 0, M, 0) }
	n = loadl(j, L)
	if (op == "keepwhere") { for (i = 0; i < n; i++) if (corepred(px, L[i])) M[m++] = L[i]; return "test: list=" TL[j] " p=" px "\nexpect: " rep(0, 0, 1, "kept", 0, M, m) }
	if (op == "countwhere") { for (i = 0; i < n; i++) if (corepred(px, L[i])) c++; M[0] = c + 0; return "test: list=" TL[j] " p=" px "\nexpect: " rep(c + 0, 0, 1, "counted", 0, M, 1) }
	if (op == "applyeach") { for (i = 0; i < n; i++) M[m++] = corefn(fx, L[i]); return "test: list=" TL[j] " x=" fx "\nexpect: " rep(0, 0, 1, "applied", 0, M, m) }
	if (op == "pushit") { cpy(L, M, n); m = n; M[m++] = TI[j]; return "test: list=" TL[j] " input=" TI[j] "\nexpect: " rep(TI[j], 0, 1, "pushed", 0, M, m) }
	if (op == "sumit") { c = 0; for (i = 0; i < n; i++) c += L[i]; return "test: list=" TL[j] "\nexpect: " rep(c, 0, 1, "total", 0, L, n) }
	if (op == "lenit") { return "test: list=" TL[j] "\nexpect: " rep(n, 0, 1, "length", 0, L, n) }
	print "bad ctl " op > "/dev/stderr"; exit 1
}
function CTL(op, verb, noun, P, code,   j) { delete TS; for (j = 1; j <= NC; j++) TS[j] = ctl(op, j) "\n"; H("ctl|" op, verb, noun, op, "control", P, code) }
function controls() {
	CTL("runn", "run", "function", "run {x} {n} times|apply {x} repeatedly {n} times", "\tvar out = v;\n\tvar x = v.i;\n\tfor q in max(${n}, 0) { x = ${x}(x); gold_push(g, x); }\n\tout.i = x;\n\tout.s.clear();\n\tformat(out.s, \"ran \", ${n});\n")
	CTL("printit", "print", "value", "print it|print the value|show the value", "\tvar out = v;\n\tprint(\"value: \", v.i);\n\tout.s.clear();\n\tformat(out.s, \"printed value\");\n")
	CTL("keepwhere", "keep", "matching", "keep results where {p}|keep only results that satisfy {p}", "\tvar out = v;\n\tvar m = 0;\n\tfor q in g.n { if ${p}(g.res[q]) { g.res[m] = g.res[q]; m++; } }\n\tg.n = m;\n\tout.s.clear();\n\tformat(out.s, \"kept\");\n")
	CTL("countwhere", "count", "matching", "count results where {p}|how many results satisfy {p}", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { if ${p}(g.res[q]) { c++; } }\n\tgold_clear(g);\n\tgold_push(g, c);\n\tout.i = c;\n\tout.s.clear();\n\tformat(out.s, \"counted\");\n")
	CTL("applyeach", "apply", "function", "map {x} over the results|transform every result with {x}|run {x} on each number", "\tvar out = v;\n\tfor q in g.n { g.res[q] = ${x}(g.res[q]); }\n\tout.s.clear();\n\tformat(out.s, \"applied\");\n")
	CTL("pushit", "push", "value", "push it onto results|add the value to the list", "\tvar out = v;\n\tgold_push(g, v.i);\n\tout.s.clear();\n\tformat(out.s, \"pushed\");\n")
	CTL("sumit", "total", "value", "give me the total|store the total in the value", "\tvar out = v;\n\tvar c = 0;\n\tfor q in g.n { c += g.res[q]; }\n\tout.i = c;\n\tout.s.clear();\n\tformat(out.s, \"total\");\n")
	CTL("lenit", "measure", "list", "length of the list|how long is the list", "\tvar out = v;\n\tout.i = g.n;\n\tout.s.clear();\n\tformat(out.s, \"length\");\n")
}
# ----- bare fn / pred entries -----
function fact(n,   r, i) { r = 1; for (i = 2; i <= n; i++) r *= i; return r }
function fib(n,   a, b, t, i) { a = 0; b = 1; for (i = 0; i < n; i++) { t = a + b; a = b; b = t } return a }
function nextprime(n) { n++; while (!isprime(n)) n++; return n }
function fnv(f, x) {
	if (f == "lastdigit") return iabs(x) % 10; if (f == "ndigits") { x = iabs(x); if (x == 0) return 1; c = 0; while (x > 0) { c++; x = int(x / 10) } return c }
	if (f == "fact") return (x < 0 || x > 20) ? 0 : fact(x); if (f == "fib") return (x < 0 || x > 90) ? 0 : fib(x); if (f == "nextprime") return nextprime(x)
	if (f == "tri") return tr_(x * (x + 1) / 2); if (f == "halfup") return (x >= 0) ? tr_((x + 1) / 2) : tr_(x / 2)
	return mapv(f, x, 0)
}
function FN(f, P, body,   a, s, i, n, e, args, k) {
	split("3,-4,10|12,0,5,250", a, "|"); s = ""
	for (k = 1; k <= 2; k++) { n = split(a[k], args, ","); s = s "test: arg=" a[k] "\n"; for (i = 1; i <= n; i++) s = s "expect: " fnv(f, args[i] + 0) "\n" }
	n = split(P, args, "|")
	e = sha16("gold-basic|fn|" f); if (SEEN[e]++) return
	printf "@entry %s\nkind: fn\nverb: %s\nnoun: number\nmodifier: plain\ncontext: function\n", e, f
	for (i = 1; i <= n; i++) printf "phrase: %s\n", args[i]
	printf "%scode:\nfn ${ID}(n int) int {\n%s}\n@end\n\n", s, body; NENT++
}
function PR(p, P, expr,   a, s, i, n, e, args, k) {
	split("3,-4,10,121|7,0,25", a, "|"); s = ""
	for (k = 1; k <= 2; k++) { n = split(a[k], args, ","); s = s "test: arg=" a[k] "\n"; for (i = 1; i <= n; i++) s = s "expect: " (predv(p, args[i] + 0, 0, 0, 0) ? "true" : "false") "\n" }
	n = split(P, args, "|")
	e = sha16("gold-basic|pred|" p); if (SEEN[e]++) return
	printf "@entry %s\nkind: pred\nverb: test\nnoun: number\nmodifier: %s\ncontext: predicate\n", e, p
	for (i = 1; i <= n; i++) printf "phrase: %s\n", args[i]
	printf "%scode:\nfn ${ID}(n int) bool {\n\tlet x = n;\n\tlet r = %s;\n\tr\n}\n@end\n\n", s, sub_x(expr, "x"); NENT++
}
function fnpreds() {
	FN("double", "double|times two", "\tlet r = n * 2;\n\tr\n"); FN("triple", "triple|times three", "\tlet r = n * 3;\n\tr\n")
	FN("halve", "halve|half of it", "\tlet r = n / 2;\n\tr\n"); FN("square", "square|squared", "\tlet r = n * n;\n\tr\n")
	FN("cube", "cube|cubed", "\tlet r = n * n * n;\n\tr\n"); FN("negate", "negate|opposite sign", "\tlet r = -n;\n\tr\n")
	FN("inc", "increment|plus one", "\tlet r = n + 1;\n\tr\n"); FN("dec", "decrement|minus one", "\tlet r = n - 1;\n\tr\n")
	FN("abs", "absolute value|magnitude", "\tlet r = if n < 0 { -n } else { n };\n\tr\n"); FN("sign", "sign of it|signum", "\tlet r = if n > 0 { 1 } else if n < 0 { -1 } else { 0 };\n\tr\n")
	FN("lastdigit", "last digit|ones digit", "\tlet a = if n < 0 { -n } else { n };\n\ta % 10\n"); FN("ndigits", "number of digits|digit count", "\tvar x = if n < 0 { -n } else { n };\n\tvar c = 1;\n\twhile x >= 10 { x /= 10; c++; }\n\tc\n")
	FN("fact", "factorial|factorial of it", "\tif n < 0 || n > 20 { return 0; }\n\tvar r = 1;\n\tfor i in n { r *= i + 1; }\n\tr\n")
	FN("fib", "fibonacci number|nth fibonacci", "\tif n < 0 || n > 90 { return 0; }\n\tvar a = 0;\n\tvar b = 1;\n\tfor i in n { let t = a + b; a = b; b = t; }\n\ta\n")
	FN("nextprime", "next prime|following prime", "\tvar x = n + 1;\n\twhile !core_is_prime(x) { x++; }\n\tx\n"); FN("tri", "triangular number|triangle number of it", "\tlet r = n * (n + 1) / 2;\n\tr\n")
	FN("halfup", "half rounded up|ceiling half", "\tlet r = if n >= 0 { (n + 1) / 2 } else { n / 2 };\n\tr\n")
	FN("quadruple", "quadruple|times four", "\tlet r = n * 4;\n\tr\n"); FN("tenfold", "times ten|tenfold", "\tlet r = n * 10;\n\tr\n")
	PR("even", "even|is even", PH["even"]); PR("odd", "odd|is odd", PH["odd"]); PR("prime", "prime|is prime", PH["prime"])
	PR("positive", "positive|is positive", PH["positive"]); PR("negative", "negative|is negative", PH["negative"]); PR("zero", "zero|is zero", PH["zero"])
	PR("nonzero", "nonzero|is not zero", PH["nonzero"]); PR("square", "perfect square|is a perfect square", PH["square"]); PR("palindrome", "palindrome|is a palindrome", PH["palindrome"])
	PR("single", "single digit|has one digit", PH["single"]); PR("overhundred", "big|over a hundred", PH["overhundred"]); PR("under10", "small|under ten", PH["under10"])
	PR("mult3", "multiple of three|divisible by three", PH["mult3"]); PR("mult5", "multiple of five|divisible by five", PH["mult5"]); PR("twodigit", "two digit|has two digits", PH["twodigit"])
}
