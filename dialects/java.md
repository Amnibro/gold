The original is Java. Unless a block says otherwise:
- `double` is `real`, `int`/`long` are `int` (but `int` arithmetic wraps at 32 bits where the source relies on it: say so), `(int) x` from a double truncates toward zero and saturates, NaN -> 0.
- `Math.abs` is `fabs`, `Math.exp/log/sqrt/atan2/hypot` keep their names, `Math.round` is `floor(x + 0.5)` as an int, `Math.max/min` with NaN return NaN.
- `Double.toString`: shortest digits that round-trip, always with a `.`, exponent form `1.0E10` from 1e7 up and below 1e-3.
- `String.format("%.Nf")` rounds half up on the decimal digits: `format_flt(out, v, N, away = true)`.
- `char` is a UTF-16 unit; inputs here are ASCII, so `Character.isLetter`/`toLowerCase` are the ASCII versions.
- `ArrayList`/arrays are `T[>..]`; `HashMap` order is never relied on; `Arrays.sort` on objects is stable.
