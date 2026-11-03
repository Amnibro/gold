# Helium

Helium is Python 3 with type hints, compiled to native code that runs at C speed. Write an ordinary typed Python script, as you would for `mypy --strict`: top-level code runs in order, function parameters and results need type hints, and local variables are inferred.

```python
from dataclasses import dataclass
from math import sqrt

@dataclass
class Item:
    name: str
    qty: int
    price: float

def value(it: Item) -> float:
    return it.qty * it.price

def is_prime(n: int) -> bool:
    return n > 1 and all(n % d != 0 for d in range(2, int(sqrt(n)) + 1))

stock = [Item("bolt", 120, 0.25), Item("gear", 4, 12.5)]
stock.append(Item("nut", 300, 0.1))
stock.sort(key=lambda it: (-value(it), it.name))
for i, it in enumerate(stock):
    print(f"{i + 1}. {it.name:<5}{value(it):>7.2f}")
counts: dict[str, int] = {}
for w in "the cat and the hat and the bat".split():
    counts[w] = counts.get(w, 0) + 1
print(" ".join(f"{w}={n}" for w, n in sorted(counts.items())))
primes = [p for p in range(2, 30) if is_prime(p)]
print(sum(primes), primes[-1], primes[:3], max(primes, key=lambda p: p % 10))
a, b = 0, 1
for _ in range(10):
    a, b = b, a + b
print(a, 2 ** 10, 17 // 5, -7 % 3, int("42") + 1, 7 / 2)
```

## Differences from Python

- `int` is 64-bit (no big integers); `float` is 64-bit.
- A character taken from a string (`s[i]`, `for c in s`) is a byte: compare it with `'a'`, use `ord(c)`, `chr(n)`, `c.isdigit()`; `print(c)` prints its code.
- Containers hold one type: `list[T]`, `dict[K, V]`, `set[T]`, `tuple[A, B]` (up to 4 values). An empty list, dict or set needs a type: `seen: set[str] = set()`.
- No `None`: start every variable with a value of its type.
- No classes with methods, inheritance, exceptions, generators with `yield`, `*args`, `**kwargs`, `global`, or imports other than `math`, `dataclasses`, `collections` (`defaultdict`, `Counter`, `deque`) and `heapq`.
