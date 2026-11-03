The original is Python with numpy. Unless a block says otherwise:
- `np.uint8`/`uint32`/`uint64` arithmetic wraps; write it with Helium `u8`/`u32`/`u64` (wrapping), not `int`.
- Vectorized expressions over arrays become plain loops over `byte[]`/`u32[]` slices in the same element order; broadcasting a scalar means using it for every element.
- `np.roll(a, k)` moves element i to (i + k) mod n; `a[::-1]` reverses; `np.bitwise_xor`, `&`, `|`, `<<`, `>>` act per element with the dtype's width.
- `int.from_bytes(b, "little")` / `.to_bytes(n, "little")` are little-endian loads and stores (`load_u64le`/`store_u64le` for 8 bytes).
- Keep table lookups as tables (precomputed once into a module `var`), not recomputed per block.
