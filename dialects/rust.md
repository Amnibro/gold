The original is Rust. Unless a block says otherwise:
- Numbers are f64 (`real`) and `i64`/`usize` (`int`). `x as i64`/`as u32` from a float truncates toward zero and saturates (NaN -> 0): write `sat_int(x)` style code with explicit clamps, never a checked `as`.
- Float sums with `.iter().sum()` start at -0.0, so an empty sum is -0.0. `f64::abs` is `fabs`. `powi(n)` is `powi(x, n)`, `powf` is `pow`, `x.max(y)`/`x.min(y)` are `max`/`min` (NaN-ignoring: if one side is NaN return the other).
- Keep the source's arithmetic grouping exactly; floats are not reassociated.
- JSON in and out is serde_json: read with `json` (missing optional fields are absent, `null` counts as absent), write numbers with `json::format_number` (serde's shortest round-trip form: `1.0`, `1e16`, `-0.0`, NaN/inf as `null`), keys in struct field order, `Option` fields that are `None` are written as `null` unless the block says they are skipped.
- `{}` in format strings is Rust `Display` for f64: shortest round-trip digits, no exponent, `.0` dropped (`1`, `0.1`, `1e-7` prints `0.0000001`); `{:.N}` rounds half to even on the binary value like `format_flt(out, v, N)`.
- Errors are returned as `Err(String)`; a solver that fails returns a JSON object `{"error": "<text>"}` with the exact text.
- `Vec<T>` is `T[>..]`, `&str`/`String` fields are `byte[]`, `HashMap` iteration order is never relied on.
