# Built-in functions

The compiler provides these directly. They work in every program with no import, and they do not appear in any library module.

## Output and text

| Function | What it does |
|---|---|
| `print(a, b, ...)` | Writes its arguments with nothing between them, then a newline. |
| `str(a, b, ...)` | Builds a `byte[>..]` string from its arguments. |
| `format(out, a, b, ...)` | Appends its arguments to the string `out`. Define your own `format(out, value)` to control how a type prints. |

## Stopping and checking

| Function | What it does |
|---|---|
| `assert(c)` | Stops the program when `c` is false. It also narrows an optional. |
| `abort(msg)` | Stops the program with a message. |
| `exit(code)` | Ends the program with an exit code. |

## Values and bytes

| Function | What it does |
|---|---|
| `copy(x)` | Makes a copy of a value that would otherwise alias, such as a growable array. |
| `default<T>()` | Makes the default value of a type. |
| `to_bytes(a)` | Serializes a value to bytes. |
| `from_bytes<T>(b)` | Reads a value back from bytes. |
| `bytes_of(a)` | Views a value's memory as bytes, without copying. |
| `embed_file("path")` | Puts a file's contents into the program at compile time. |
| `embed_shader("x.frag")` | Compiles a shader file into the program at compile time. `embed_shader("frag", source)` takes the stage and source instead. |

## Threads and queues

Threads share nothing. They talk through queues, one per type, and only flat values with no references can cross.

| Function | What it does |
|---|---|
| `thread_spawn(worker)` | Starts a `thread_fn` and returns its id. |
| `thread_spawn_contained(worker)` | Starts a `thread_fn` whose failure ends only that thread, not the whole program. |
| `thread_wait(id)` | Waits for a thread to finish. |
| `hardware_threads()` | Returns how many threads the machine can run at once. |
| `qput(value)` | Puts a value on the queue for its type. |
| `qget<T>()` | Waits for the next value of type `T` and returns it. |
| `qget<T>(ms)` | Waits up to `ms` milliseconds. Returns the value and a `bool` that says whether one arrived. |
| `qpoll<T>()` | Returns the next value and `true` if one is ready, without waiting. |
| `qlimit<T>(n)` | Sets the most values the queue for `T` can hold. |

## Array members

Every array kind has these. See [Arrays and strings](/api-library/helium/language/arrays-and-strings).

| Member | What it does |
|---|---|
| `.len` | The number of elements. |
| `.cap` | The capacity. |
| `.push(v)` | Adds one element and returns a reference to it. |
| `.append(xs)` | Adds every element of `xs`. |
| `.pop()` | Removes the last element and returns it. |
| `.pop_n(n)` | Removes the last `n` elements. |
| `.resize(n, v)` | Changes the length, filling new elements with `v`. |
| `.clear()` | Removes every element. |
| `.index_of(ref)` | Returns the position of an element from a reference to it. |

Any function can also be called like a member: `x.f(a)` is `f(x, a)`.
