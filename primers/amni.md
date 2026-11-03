# Helium

Helium's source files are `.amni` (this page) or `.he` (the same language with layout instead of braces, see `hc/TODO.md` §0). Coming from Goose (github.com/aardappel/goose), a `.amni` file differs from a `.goose` file in three ways:

- Word types: `int`=i64, `uint`=u64, `byte`=u8, `real`=f64. The others stay: `i8 i16 i32 u16 u32 f32 bool varint`.
- No `:` before a type in declarations and no `->` before results: `fn f(a int, b real) int, bool`, `struct P { x real, y real }`, `var n int = 0`. Literals and named arguments keep `:` (`P { x: 1.0, y: 2.0 }`).
- `import std;` is implicit. Other modules are imported: `import dictionary;`, `import os;`, `import math;`.

Run: `hc file.amni` (native, cached). `hc check file.amni` typechecks. `hc build file.amni` makes an executable (`-o out.c` writes C, `--web` WebAssembly). `tools/amni/goose2amni.py` converts Goose source.

## Core

No heap, no GC, no destructors, no lifetime annotations. Every value lives on the native stack, in static data, or on a compiler-managed data stack, and is freed when its owning scope ends. References can never dangle; the compiler infers each reference's root and rejects code that could outlive it. Statements end in `;` except block-ended ones (`if`, `match`, loops, `block`, `guard ... else {}`). Blocks are expressions; a function's value is its last expression. `//` and nesting `/* */` comments.

```amni
struct Point { x real, y real }
fn total(xs int[:]) int { var t = 0; for x in xs { t += x; } t }
fn divide(a int, b int) int, bool {
	if b == 0 { return 0, false; }
	return a / b, true;
}
fn larger(a, b) { if a > b { a } else { b } }
fn main() {
	let answer = 42;
	var count i32 = 0;
	count++;
	let q, ok = divide(7, 2);
	let p = Point { 1.5, 2.0 };
	print("answer=", answer, " q=", q, " ok=", ok, " ", p, " ", larger(3, 9), " ", total([1, 2, 3]));
}
```

- `let` cannot be reassigned (contents still writable); `var` can; `const` is read-only contents.
- Integer literals adapt to their destination and default to `int`. Arithmetic is at the operands' width; implicit widening only; narrowing needs `x as T` (checked in `--debug`) or `x as! T` (wraps). Ints convert to floats implicitly; floats to ints only by cast.
- `%` is Euclidean (never negative). Integer `/` truncates. Unsigned math wraps; signed overflow aborts in `--debug`.
- `print(a, b, ...)` writes the args with nothing between them, then a newline. `str(...)` makes a `byte[>..]`; `format(out, ...)` appends to one. Structs print as `Point { 1.5, 2.0 }`.
- Several results are a calling convention (`let a, b = f();`), not a tuple. Untyped params make a function generic. `x.f(a)` is `f(x, a)` for any function.

## Arrays and strings

| Type | Size behavior |
|---|---|
| `T[k]` | fixed, k elements |
| `T[]`, `T[varint]` | sized at construction, then frozen |
| `T[..k]` | inline capacity k, grows/shrinks within it |
| `T[..]` | capacity chosen at construction (`[..16]`) |
| `T[>..]` | grow-only, the default growable array; elements never move |
| `T[>..<]` | grow-shrink: stacks, queues, heaps |
| `T[:]` | slice: a view of any array kind, never a copy |

Members: `.len .cap .push(v) .append(xs) .pop() .pop_n(n) .resize(n, v) .clear() .index_of(ref)`. `push` returns a reference to the new element. Slicing `a[x..y]`, `a[..y]`, `a[^2..]` (last two). Literals: `[1, 2, 3]`, `[0; 16]`, `[]`. `var out = [];` takes its element type from the first push.

A string is any `byte` array: `byte[>..]` builder, `byte[]` finished, `byte[..16]` small inline, `const byte[:]` view (string literals). `'a'` is an integer. Strings compare with `==`.

```amni
fn main() {
	var s byte[>..] = [];
	s.append("hello");
	s.push(',');
	format(s, " world ", 6 * 7);
	var stack int[>..<] = [];
	for i in 5 { stack.push(i * i); }
	let top = stack.pop();
	let parts = split("alice,30,paris", ',');
	let n, ok = parse_int(trim(" 30 "));
	print(s, " ", stack, " ", top, " ", parts, " ", n, " ", ok, " ", s[..5], " ", words(" go  north "));
}
```

Rules that cause most errors:
- Only one resizable array (`T[>..]`, `T[>..<]`) per struct, as its last field; never as an array element. Use `T[]` or `T[..k]` inside elements: `byte[][>..]` is a list of strings.
- Arrays of variable-size elements (`byte[][>..]`, `Shape..[>..]`) can be iterated but not indexed.
- Non-fixed values never copy implicitly: `let c = xs;` aliases; `copy(xs)` copies. Fixed-size values copy on assignment.
- A `T[>..]` may `pop`/`clear`/`resize` only where no reference or slice into it is still used afterwards.
- Assigning a whole growable array clears it first, so `xs = f(xs)` is an error; build into another variable and `xs = copy(tmp)`.

## Control flow

```amni
fn grade(n int) const byte[:] {
	match n {
		0 => "zero",
		1..10 => "small",
		10, 20, 30 => "round",
		_ => "big",
	}
}
fn half(n int) int { guard n % 2 == 0 else { return -1; } n / 2 }
fn main() {
	let kind = if half(8) > 3 { "big" } else { "small" };
	let found = block {
		guard half(8) > 0 else { break -1; }
		half(8) * 10
	};
	var n = 0;
	let k = loop { n += 7; if n % 5 == 0 { break n; } };
	for x, i in [10, 20, 30] { if i == 1 { continue; } print(i, ":", x); }
	for i in 2..5 { n += i; }
	var xs int[>..] = [1, 2, 3];
	for &x in xs { x *= 10; }
	while n > 100 { n /= 2; }
	print(kind, " ", found, " ", k, " ", xs, " ", grade(15), " ", n);
}
```

`for i in n` is `0..n`; ranges are half-open. `for x in xs` copies fixed-size elements; `for &x in xs` binds references. `if` used as a value needs `else`. `guard c else { ... }` continues only if `c`. `break value` works only in `loop` and `block { }`, not in `for` or `while`. No labels; `break`/`continue` act on the innermost loop.

## Structs, enums, match

```amni
struct Unit { kind i32, hp i32 = 100, name byte[..12] }
enum Shape { Circle { r real }, Rect { w real, h real }, Dot }
fn area(s Shape.Circle) real { 3.14159 * s.r * s.r }
fn area(s Shape.Rect) real { s.w * s.h }
fn area(s Shape.Dot) real { 0.0 }
fn name(s Shape) const byte[:] {
	match s {
		Circle c => if c.r > 1.0 { "big circle" } else { "circle" },
		Rect, Dot => "other",
	}
}
fn main() {
	let a = Unit { kind: 1, name: "scout" };
	let b = Unit { 2, 50, "tank" };
	let c = Unit { kind: 3, .. };
	var shapes Shape[>..] = [];
	shapes.push(Shape.Circle { r: 2.0 });
	shapes.push(Shape.Rect { w: 2.0, h: 3.0 });
	shapes.push(Shape.Dot);
	var total = 0.0;
	for s in shapes { total += area(s); }
	print(a, " ", b.hp, " ", c.hp, " ", total, " ", name(shapes[0]));
}
```

- Struct literals are all named or all positional; defaulted fields may be omitted; `..` defaults the rest. Structs are packed, nominal, compare with `==`, and support memberwise `+ - * /`.
- `Shape` (fixed mode) is tag + largest payload: indexable, variant replaceable, `match` binds payload by value. `Shape..` (variable mode) is exact-size: sequential arrays, `match` may bind `Rect &r =>` by reference to edit in place.
- `match` on enums is exhaustive; on integers needs `_`. Several statements in an arm: `Rect r => { ...; },`.
- Case functions (one overload per variant type, called with the enum) replace virtual calls.
- Generic structs: `struct Pair<T> { a T, b T }`, `Pair<int> { 1, 2 }`.

## References and optionals

```amni
struct Node { v int, next Node? }
fn inc(n int&) { n += 1; }
fn first_at_least(xs int[:], min int) int? {
	for &x in xs { if x >= min { return x; } }
	return null;
}
fn main() {
	var count = 0;
	inc(count);
	var xs int[>..] = [10, 20, 30];
	var r .= xs[0];
	r = 11;
	r .= xs[2];
	r += 1;
	let big = first_at_least(xs, 15);
	if big { print("found ", big); }
	var c = Node { v: 3, next: null };
	var b = Node { v: 2, next: c };
	var cur Node? = b;
	var sum = 0;
	while cur { sum += cur.v; cur .= cur.next; }
	print(count, " ", xs, " ", sum, " ", r .== xs[2]);
}
```

- `T&` is transparent: it reads and writes as its target. `x .= e` binds or rebinds a reference; `.==` compares addresses. A reference parameter binds an lvalue without `&`.
- `T?` is a nullable reference; narrow it with `if`, `while`, `guard` or `assert` before use.
- An inferred `let x = r;` of a fixed-size target copies; use `let x .= r;` to keep the reference (e.g. `let e .= pool.push(v);`).
- `T&<u32>` is a self-relative 4-byte link inside one array (position-independent, serializable); `T&<u32 in pool>` is relative to a global array `pool`. `T&<u32>?` is optional.
- Nothing may outlive the variable it points into, and a view of a temporary cannot be stored (`let s = f()[..];` is an error; bind `f()` first).

## Functions, generics, blocks

```amni
fn scale<T>(x T, by T = 2) T { x * by }
fn each_step<F>(lo int, hi int, step int = 1) {
	var i = lo;
	while i < hi { F(i); i += step; }
}
fn first_multiple_of_7(lo int, hi int) int {
	each_step(lo, hi, 3) { if it % 7 == 0 { return it; } };
	return -1;
}
fn main() {
	let xs int[5] = [4, 8, 15, 16, 23];
	let evens = xs.filter() { it % 2 == 0 };
	let doubled = xs.map() { it * 2 };
	let total = fold(xs, 0) { acc, x => acc + x };
	var gaps int[>..] = [];
	for i in xs.len - 1 { gaps.push(xs[i + 1] - xs[i]); }
	sort(gaps) { a, b => a > b };
	var budget = 0;
	fn spend(n int) { budget += n; }
	spend(5);
	print(scale(21), " ", evens, " ", doubled, " ", total, " ", gaps, " ", first_multiple_of_7(10, 40), " ", budget);
}
```

- Overloading by parameter types. Defaults on trailing parameters. Generics are monomorphized with no trait bounds.
- Function values are compile-time only (no closures stored, no function pointers). A trailing block `{ it ... }` or `{ a, b => ... }` is the last argument; one per call. `return` inside a block returns from the enclosing named function.
- Nested functions read and write the enclosing locals.
- Recursion must be marked: `recursive fn` on the cycle's entry, all signatures explicit, and no growable local in scope at a recursive call (pass storage in by reference).
- `return value from f` returns from the innermost active call of `f`, any depth up (checked statically). No exceptions or Result type; use trailing `bool` results or optionals.

## Lookup-table functions

`lut fn` turns a pure function of small inputs into a lookup table:

```amni
fn steps(n int) int { var x = n; var c = 0; while x > 1 { x = if x % 2 == 0 { x / 2 } else { 3 * x + 1 }; c++; } c }
lut fn fast_steps(n u16) int { steps(n) }
fn main() { print(fast_steps(27), " ", fast_steps(27)); }
```

- Parameters are `bool`, `byte`/`u8`, `i8`, `u16` or `i16`, 24 bits in all; the result is any fixed-size flat type.
- Each entry is computed on its first call and then looked up. The table is sparse: 4096-entry tiles exist only once something in them is asked for, so an unvisited range costs nothing.
- Tables in the root file are saved to `~/.goose/lut/<name>-<hash>.lut` when `main` returns and loaded on first use, so a later run starts with every entry already computed. Editing the function changes the hash.
- The body must be pure: same inputs, same result, no output.
- `lut fn` works in `.amni` files.
- A table of 10 to 20 bits whose body is integer code (ints, bools, `if`, loops, calls, `min`/`max`/`abs`/`clamp`) can fill on the GPU. On its first run the program times 64 sample entries; when a whole CPU fill would take over 30 ms, the GPU computes every entry at once. An entry the GPU cannot finish (division by zero, a very long loop) stays unset and is computed on the CPU when first used, so results never change. `HELIUM_GPU=off` keeps everything on the CPU, `HELIUM_GPU=discrete` prefers the discrete GPU over the integrated one, `HELIUM_GPU_MIN_MS` sets the 30 ms bar, and `HELIUM_GPU_LOG=1` reports what ran where (`=2` also writes each table's compute shader to `<name>.comp`).

## Program, modules, threads

- One root file; `import a.b;` loads `a/b.amni` (or `.goose`) relative to the root, then the standard library. `namespace geo;` scopes a file: `geo::Pt`. `fn main()` in the root is the entry.
- Globals: `var log byte[>..];` starts empty; `let SIZE = 16;` is a named constant usable as an array size.
- `fn format(out byte[>..]&, p Point) { format(out, "(", p.x, ",", p.y, ")"); }` customizes how a type prints.
- Threads share nothing: `thread_fn worker() { let j = qget<Job>(); qput(Result { ... }); }`, `thread_spawn(worker)`, `thread_wait(id)`. Only flat (reference-free) values cross queues.
- `assert(c)`, `abort(msg)`, `exit(code)`. `copy(x)`, `default<T>()`, `to_bytes(a)`, `from_bytes<T[>..]>(b)`, `bytes_of(a)`, `embed_file("path")`.
- `extern fn hypot(x real, y real) real;` binds C; `extern "SDL2" { fn SDL_Quit(); }` binds a shared library; `extern "vulkan?" { ... }` is optional: if the library or a symbol is missing, those functions return -1.

## Standard library (std is implicit)

- Scalars: `min max clamp abs sign lerp swap rem div_euclid next_pow2 popcount clz ctz`.
- Arrays (take slices): `find(xs){pred}` gives `T?`, `find_index position contains any all count min max min_by max_by last lower_bound binary_search find(xs, sub) rfind starts_with ends_with each_rev each_chunk map filter fold sum concat fill copy_into reverse sort stable_sort` (`sort(xs) { a, b => a > b }`).
- Length changes (take `&`): `push_n insert_at remove_at swap_remove retain dedup heap_push heap_pop make_heap`.
- Strings: `trim trim_start trim_end split(s, ',') each_split words each_word join(out, parts, sep) compare to_lower to_upper parse_int(s, base) parse_flt format_int(out, v, base, width, pad) format_flt(out, v, decimals) format_replaced each_utf8 push_utf8`.
- `import dictionary;`: `var d = dictionary<const byte[:], int> {};` with `insert get(gives V?) contains get_or_insert update(d, k, v0) { it += 1; } remove each(d) { k, v => ... } count`.
- `import math;`: `sqrt sin cos tan atan2 exp log pow floor ceil round PI TAU`. `import os;`: `read_file(path, out) write_file append_file file_exists list_dir read_line args() arg_count clock time sleep_ms random_seed`.
- Also `vec` (`float2 float3 float4`), `json`, `csv`, `regex`, `base64`, `binary`, `ffi`, `exception`; `gfx`, `audio`, `ui`, `physics` packages.

## Web

`hc build --web app.amni -o app.wasm` writes `app.wasm` and the `helium.js` host beside it. A page starts it with `<script type="module">import {start} from './helium.js'; start({wasm: 'app.wasm'});</script>`. `main` runs once and globals stay alive; the host then calls the program's `export fn he_frame(t real)` every animation frame after `web::frames(true)`, and `export fn he_event(tag i32, kind i32)` for each listener, timer, fetch and JS result, by the tag the program gave (`kind` is `web::EV_DOM`, `EV_TIMER`, `EV_FETCH`, `EV_PROGRESS`, `EV_JS`, `EV_CALLBACK`).

- `import web;` (`web::`): elements are `i32` handles: `el(id) query(h, sel) query_all list_at create append insert_before remove clear text html attr get_attr style cls has_cls prop prop_num get_prop get_num call scroll_into rect listen(h, "click", TAG, flags)`; event fields while `he_event` runs: `ev_x ev_y ev_dx ev_dy ev_button ev_buttons ev_mods ev_key(out) ev_value(out) ev_touches ev_touch_x ev_target ev_prevent ev_id ev_status`; `fetch(url, TAG)` / `request(...)` then `fetch_take(ev_id(), out)`; `timer(ms, TAG)`, `now`, `win_w win_h dpr param(name, out) store_get store_set log`; `js_import js_call js_result` for other JS libraries.
- `import webgl;` (`gl::`): WebGL2 on a canvas handle: `init(canvas, aa, alpha) create_shader shader_source compile_shader create_program link_program uniform_loc uniform1f uniform_mat4 create_buffer buffer_data(target, bytes_of(xs), usage) create_vao attrib_ptr draw_arrays`, and the GL constants.
- No threads or files on the web; `print` goes to the browser console. See `samples_web/demo`.

