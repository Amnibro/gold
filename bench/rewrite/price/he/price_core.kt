import java.math.BigDecimal
import java.math.RoundingMode
import java.text.NumberFormat
import java.util.Locale

/** A single line of recognized text with its bounding box, independent of the OCR engine. */
data class OcrLine(
    val text: String,
    val left: Int = 0,
    val top: Int = 0,
    val right: Int = 0,
    val bottom: Int = 0,
) {
    val height: Int get() = bottom - top
    val centerY: Float get() = (top + bottom) / 2f
}


/** All prices are stored as integer cents to avoid floating point drift. */
object Money {
    fun format(cents: Long): String = NumberFormat.getCurrencyInstance().format(cents / 100.0)

    /** Parses user/OCR text like "$3.99", "3,99", "1,299.00" into cents. */
    fun parse(text: String): Long? {
        var cleaned = text.replace(Regex("[^0-9.,-]"), "")
        if (cleaned.isEmpty()) return null
        cleaned = when {
            cleaned.contains('.') && cleaned.contains(',') -> cleaned.replace(",", "")
            cleaned.contains(',') -> cleaned.replace(',', '.')
            else -> cleaned
        }
        val value = cleaned.toBigDecimalOrNull() ?: return null
        return value.movePointRight(2).setScale(0, RoundingMode.HALF_UP).toLong()
    }

    fun toPlain(cents: Long): String = BigDecimal(cents).movePointLeft(2).setScale(2).toPlainString()
}


enum class BaseUnit { GRAM, MILLILITER, COUNT }

/** A package size converted to a base unit (grams, milliliters or item count). */
data class Quantity(val amount: Double, val base: BaseUnit, val sourceText: String)

object UnitParser {
    private val pattern = Regex(
        """(\d+(?:[.,]\d+)?)\s*(fl\.?\s*oz|oz|lbs?|kg|g|gr|mg|ml|l|ltr|liters?|litres?|gal|qt|pt|ct|count|pk|pack|ea)\b""",
        RegexOption.IGNORE_CASE,
    )

    // To support a new unit, add it to the regex above and a factor here.
    private fun factor(unit: String): Pair<Double, BaseUnit>? {
        val u = unit.lowercase(Locale.ROOT).replace(".", "").replace(" ", "")
        return when (u) {
            "floz" -> 29.5735 to BaseUnit.MILLILITER
            "oz" -> 28.3495 to BaseUnit.GRAM
            "lb", "lbs" -> 453.592 to BaseUnit.GRAM
            "kg" -> 1000.0 to BaseUnit.GRAM
            "g", "gr" -> 1.0 to BaseUnit.GRAM
            "mg" -> 0.001 to BaseUnit.GRAM
            "ml" -> 1.0 to BaseUnit.MILLILITER
            "l", "ltr", "liter", "liters", "litre", "litres" -> 1000.0 to BaseUnit.MILLILITER
            "gal" -> 3785.41 to BaseUnit.MILLILITER
            "qt" -> 946.353 to BaseUnit.MILLILITER
            "pt" -> 473.176 to BaseUnit.MILLILITER
            "ct", "count", "pk", "pack", "ea" -> 1.0 to BaseUnit.COUNT
            else -> null
        }
    }

    fun parse(text: String?): Quantity? {
        if (text.isNullOrBlank()) return null
        val match = pattern.find(text) ?: return null
        val amount = match.groupValues[1].replace(',', '.').toDoubleOrNull() ?: return null
        if (amount <= 0) return null
        val (f, base) = factor(match.groupValues[2]) ?: return null
        return Quantity(amount * f, base, match.value.trim())
    }

    /**
     * "$0.25 / oz", "$1.06 / qt", "$0.88 / 100 ml", "$0.50 / ea". Steps up to a larger unit when the
     * small one would round to a few cents (a gallon of milk per fl oz is useless for comparing).
     */
    fun unitPriceLabel(priceCents: Long, quantity: Quantity, imperial: Boolean = defaultImperial()): String {
        val ladder: List<Pair<Double, String>> = when (quantity.base) {
            BaseUnit.GRAM -> if (imperial) listOf(28.3495 to "oz", 453.592 to "lb") else listOf(100.0 to "100 g", 1000.0 to "kg")
            BaseUnit.MILLILITER -> if (imperial) listOf(29.5735 to "fl oz", 946.353 to "qt") else listOf(100.0 to "100 ml", 1000.0 to "L")
            BaseUnit.COUNT -> listOf(1.0 to "ea")
        }
        val (perAmount, label) = ladder.firstOrNull { (amount, _) -> priceCents * amount / quantity.amount >= MIN_UNIT_CENTS }
            ?: ladder.last()
        val cents = Math.round(priceCents * perAmount / quantity.amount)
        return "${Money.format(cents)} / $label"
    }

    private const val MIN_UNIT_CENTS = 10

    fun defaultImperial(locale: Locale = Locale.getDefault()): Boolean = locale.country in setOf("US", "LR", "MM")

    /** Price per base unit, used to compare different package sizes of the same product. */
    fun pricePerBase(priceCents: Long, quantity: Quantity): Double = priceCents / quantity.amount
}

data class PriceCandidate(
    val cents: Long,
    val score: Float,
    val isUnitPrice: Boolean,
    val line: String,
)

/** What we could read off a shelf tag / price label. */
data class ShelfTagResult(
    val priceCents: Long?,
    val productName: String?,
    val sizeText: String?,
    val onSale: Boolean,
    val candidates: List<PriceCandidate> = emptyList(),
)

/**
 * Heuristics for shelf tags: the main price is usually the biggest text on the tag,
 * unit prices ("$0.21 / oz") are small and labelled, and the product name is the
 * largest mostly-alphabetic line.
 */
object PriceParser {
    private val opts = setOf(RegexOption.IGNORE_CASE)
    private val amount = """(\d{1,4}(?:[.,]\d{2})?)"""
    private val multiBuyFor = Regex("""(?<!\d)(\d{1,2})\s*for\s*\$?\s*$amount(?!\d)""", opts)
    private val multiBuySlash = Regex("""(?<!\d)(\d{1,2})\s*/\s*\$\s*$amount(?!\d)""", opts)
    private val decimal = Regex("""(?<![\d.,])\$?\s*(\d{1,4})\s?[.,]\s?(\d{2})(?![\d%])""")
    private val dollarSpaceCents = Regex("""\$\s*(\d{1,3})\s+(\d{2})(?!\d)""")
    private val dollarWhole = Regex("""\$\s*(\d{1,4})(?![\d.,])""")
    private val bareSpaced = Regex("""^\s*(\d{1,2})\s+(\d{2})\s*$""")
    private val bareRun = Regex("""^\s*(\d{3,4})\s*$""")
    private val splitDollars = Regex("""^\s*\$?\s*(\d{1,2})\s*$""")
    private val splitCents = Regex("""^\s*(\d{2})\s*[¢c]?\s*$""", opts)
    private val nameNoise = Regex("""\b(price|everyday|rewards?|you pay|with card|limit|guiding stars?|each|ea|per|retail|aisle|shelf)\b""", opts)
    private val cents = Regex("""(?<![\d.])(\d{1,2})\s*[¢c](?![a-z])""", opts)
    private val unitPriceHint = Regex(
        """(\bper\b|/\s*(oz|lb|kg|g|ml|l|ct|each|ea|100\s?g|100\s?ml|fl\s?oz|qt|gal)\b|unit\s*price)""",
        opts,
    )
    private val saleHint = Regex("""\b(sale|save|savings|special|deal|clearance|rollback|bogo|promo|\d+%\s*off)\b""", opts)
    private val noiseHint = Regex("""\b(sku|upc|plu|item\s*#|reg(ular)?\s*price|was)\b""", opts)
    private val barcodeStripes = Regex("""^[IlL1|!iNMHVWUJ\[\]]{6,}$""")

    fun parse(raw: List<OcrLine>): ShelfTagResult {
        if (raw.isEmpty()) return ShelfTagResult(null, null, null, false)
        val lines = joinSuperscript(raw)
        val maxHeight = lines.maxOf { it.height }.coerceAtLeast(1).toFloat()
        val candidates = lines.flatMap { line ->
            val relHeight = if (line.height > 0) line.height / maxHeight else 0.5f
            candidatesIn(line.text).map { (c, bonus) ->
                val unit = unitPriceHint.containsMatchIn(line.text)
                val noise = noiseHint.containsMatchIn(line.text)
                PriceCandidate(
                    cents = c,
                    score = relHeight + bonus - (if (unit) 1f else 0f) - (if (noise) 0.6f else 0f),
                    isUnitPrice = unit,
                    line = line.text,
                )
            }
        }.filter { it.cents in 1..999_999 }

        val best = candidates.filterNot { it.isUnitPrice }.maxByOrNull { it.score }
        val anchor = best?.let { b -> lines.firstOrNull { it.text == b.line } }
        val name = guessName(anchor?.let { a -> lines.filter { a.height <= 0 || kotlin.math.abs(it.centerY - a.centerY) <= a.height * 3.5f } } ?: lines, best?.line)
        val size = lines.firstNotNullOfOrNull { UnitParser.parse(it.text)?.sourceText }
        val onSale = lines.any { saleHint.containsMatchIn(it.text) }
        return ShelfTagResult(best?.cents, name, size, onSale, candidates.sortedByDescending { it.score })
    }

    fun parseText(text: String): ShelfTagResult =
        parse(text.lines().filter { it.isNotBlank() }.map { OcrLine(it) })

    /** Returns (cents, score bonus) for every price-looking token on a line. */
    internal fun candidatesIn(text: String): List<Pair<Long, Float>> {
        val out = mutableListOf<Pair<Long, Float>>()
        val consumed = mutableListOf<IntRange>()
        fun free(r: IntRange) = consumed.none { it.first <= r.last && r.first <= it.last }

        for (re in listOf(multiBuyFor, multiBuySlash)) {
            re.findAll(text).forEach { m ->
                val qty = m.groupValues[1].toInt()
                val total = Money.parse(m.groupValues[2])
                if (qty > 0 && total != null && free(m.range)) {
                    out += ((total + qty / 2) / qty) to 0.4f
                    consumed += m.range
                }
            }
        }
        decimal.findAll(text).forEach { m ->
            if (free(m.range)) {
                val c = m.groupValues[1].toLong() * 100 + m.groupValues[2].toLong()
                out += c to (if (m.value.contains('$')) 0.3f else 0.1f)
                consumed += m.range
            }
        }
        dollarSpaceCents.findAll(text).forEach { m ->
            if (free(m.range)) {
                out += (m.groupValues[1].toLong() * 100 + m.groupValues[2].toLong()) to 0.25f
                consumed += m.range
            }
        }
        dollarWhole.findAll(text).forEach { m ->
            if (free(m.range)) {
                out += (if (m.groupValues[1].length >= 3) m.groupValues[1].toLong() else m.groupValues[1].toLong() * 100) to 0.15f
                consumed += m.range
            }
        }
        bareSpaced.find(text)?.takeIf { free(it.range) }?.let { m -> out += (m.groupValues[1].toLong() * 100 + m.groupValues[2].toLong()) to 0.2f; consumed += m.range }
        bareRun.find(text)?.takeIf { free(it.range) }?.let { m -> out += m.groupValues[1].toLong() to -0.05f; consumed += m.range }
        cents.findAll(text).forEach { m ->
            if (free(m.range)) {
                out += m.groupValues[1].toLong() to 0.1f
                consumed += m.range
            }
        }
        return out
    }

    internal fun joinSuperscript(lines: List<OcrLine>): List<OcrLine> {
        val used = mutableSetOf<OcrLine>()
        val joined = lines.mapNotNull { a ->
            if (a in used) return@mapNotNull null
            val d = splitDollars.find(a.text)?.groupValues?.get(1) ?: return@mapNotNull a
            val b = lines.filter { it !== a && it !in used && a.height > 0 && it.height in 1 until (a.height * 0.8f).toInt().coerceAtLeast(2) && it.left >= a.right - a.height / 3 && it.left - a.right <= a.height && it.centerY in (a.top - a.height * 0.3f)..(a.centerY + a.height * 0.15f) }.firstNotNullOfOrNull { c -> splitCents.find(c.text)?.let { c to it.groupValues[1] } } ?: return@mapNotNull a
            used += b.first
            OcrLine("$$d.${b.second}", a.left, a.top, b.first.right, a.bottom)
        }
        return joined.filter { it !in used }
    }
    private fun guessName(lines: List<OcrLine>, priceLine: String?): String? {
        return lines
            .asSequence()
            .filter { it.text != priceLine }
            .filterNot { unitPriceHint.containsMatchIn(it.text) || noiseHint.containsMatchIn(it.text) || nameNoise.containsMatchIn(it.text) }
            .filterNot { saleHint.matches(it.text.trim()) || barcodeStripes.matches(it.text.trim()) }
            .map { it to it.text.count(Char::isLetter) }
            .filter { (line, letters) -> letters >= 3 && letters.toFloat() / line.text.length > 0.5f }
            .maxByOrNull { (line, letters) -> (line.height.coerceAtLeast(1)) * 10 + letters }
            ?.first?.text?.trim()
    }
}
