The original is Python 3. Unless a block says otherwise:
- `int` is `int`, `float` is `real`. `/` is `truediv`, `//` and `%` round down (`floor_div`, `pydivmod`), `round()` is half-to-even (`pyround`).
- `str(x)` is `pyfmt(x)` (floats print shortest round-trip with `.0`, `1e-05`, `inf`, `nan`, `True`/`False`), `repr(s)` is `pyrepr(s)`.
- Truthiness: empty string, empty list, 0, 0.0 and None are false (`truthy`).
- `s.lower()`/`upper()`/`strip()`/`split()` work on ASCII here; `split()` with no argument splits on runs of whitespace and drops empty parts; `split(sep)` keeps empty parts.
- `json.dumps` default separators are `", "` and `": "`, `ensure_ascii` escapes non-ASCII as `\uXXXX`, keys keep insertion order; `json.loads` gives dicts, lists, str, int, float, bool, None.
- `re` patterns are used verbatim with Helium `regex` (search = first match anywhere, match = anchored at start, fullmatch = whole string); `re.I` is `regex::compile_ignore_case`.
- dict iteration is insertion order; `sorted` is stable; `min`/`max` return the first of equal items.
- Exceptions caught by the source become explicit error results with the exact message text the source prints.
