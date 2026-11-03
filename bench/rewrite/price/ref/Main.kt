fun main() {
    val reps = (System.getenv("REPS") ?: "0").toInt()
    val cases = generateSequence(::readLine).map { c -> c.split('\u001e').filter { it.isNotEmpty() }.map { l -> val f = l.split('\u001f'); OcrLine(f[0], f[1].toInt(), f[2].toInt(), f[3].toInt(), f[4].toInt()) } }.toList()
    fun show(r: ShelfTagResult) = "${r.priceCents}|${r.productName}|${r.sizeText}|${r.onSale}|" + r.candidates.joinToString(",") { "${it.cents}:${Math.round(it.score * 100)}:${it.isUnitPrice}" }
    if (reps == 0) { val sb = StringBuilder(); for (c in cases) sb.append(show(PriceParser.parse(c))).append('\n'); print(sb); return }
    var t = 0L; repeat(reps) { for (c in cases) t += show(PriceParser.parse(c)).length }; println(t)
}
