The original is Kotlin (JVM). Unless a block says otherwise:
- `Double` is `real`, `Int`/`Long` are `int`; `toInt()` from a Double truncates toward zero and saturates, NaN -> 0.
- `Regex` patterns are used verbatim with Helium `regex` (`find` = first match anywhere, `matches` = whole string, `containsMatchIn` = any match; `RegexOption.IGNORE_CASE` = case-insensitive).
- `toDoubleOrNull`/`toIntOrNull` return absent on anything that is not a full valid number (no surrounding spaces).
- `String.format("%.2f")` rounds half up on the decimal digits: `format_flt(out, v, 2, away = true)`; `Double.toString` is Java's (shortest digits, always a `.`, `1.0E10` from 1e7 up and below 1e-3).
- `?.`/`?:` chains become explicit has-value checks; data classes print as `Name(a=1, b=x)` only where the source prints them.
- `trim()`, `lowercase()`, `split()` on ASCII text; `split(",")` keeps empty parts.
