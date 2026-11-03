The original is JavaScript. Unless a block says otherwise:
- Every number is a double (`real`); integers stay exact below 2^53. `Math.round` rounds half up (toward +inf): `floor(x + 0.5)`. `toFixed(n)` rounds half away from zero on the decimal digits: `format_flt(out, v, n, away = true)`. `parseFloat` reads the longest numeric prefix, `Number("")` is 0, `Number("x")` is NaN.
- `String(x)` / template `${x}` of a number: shortest round-trip digits, no `.0` for integers, exponent form `1e+21` from 1e21 up and `1e-7` below 1e-6, `-0` prints `0`, `NaN`, `Infinity`.
- `||` returns the first truthy operand (0, "", NaN, null, undefined are falsy); `??` only skips null/undefined.
- String methods are UTF-16 but inputs here are ASCII: `slice`, `padStart`, `toUpperCase`, `trim` as usual; regex literals are used verbatim with Helium `regex`.
- Objects keep insertion order for string keys.
