# Part 4 — Pythonic Notes

Python's language features often make certain GoF patterns unnecessary — or replace a class-heavy implementation with a simpler idiom. This section is a direct **side-by-side comparison**.

## 4.1 Singleton → Modules

Python modules are singletons by construction: the interpreter caches a module in `sys.modules` after its first import, so every subsequent `import` returns the exact same object.

```python
# config.py — this module IS the singleton; no class needed at all
_settings: dict = {"env": "production"}

def get(key: str) -> str:
    return _settings.get(key, "")

def set(key: str, value: str) -> None:
    _settings[key] = value
```

```python
# main.py
import config

config.set("env", "staging")

# other_file.py (imported elsewhere in the same run) sees the SAME state:
import config
print(config.get("env"))  # "staging" — proves it's a true singleton
```

| GoF Singleton | Pythonic Module |
|---|---|
| Requires `__new__` override + class-level guard | Just define variables/functions at module scope |
| Needs explicit thread-safety handling | Import machinery already handles this safely |
| Verbose, easy to misuse (subclassing breaks it) | Zero boilerplate, always correct |

---

## 4.2 Strategy → First-Class Functions

Since Python functions are objects that can be passed as parameters, an entire class hierarchy of "Strategy" objects often collapses into a single higher-order function.

```python
from typing import Callable

# The "strategy" is just the function signature: (float) -> float
DiscountFn = Callable[[float], float]

def no_discount(total: float) -> float:
    return total

def percent_off(percent: float) -> DiscountFn:
    return lambda total: total * (1 - percent / 100)

def checkout(total: float, discount: DiscountFn) -> float:
    # No abstract base class, no subclassing — just call the function
    return discount(total)


print(checkout(100, no_discount))          # 100.0
print(checkout(100, percent_off(20)))      # 80.0
```

| GoF Strategy | Pythonic Function |
|---|---|
| `ABC` + one subclass per algorithm | One function per algorithm |
| Swap via `set_strategy(ConcreteStrategy())` | Swap via passing a different function/lambda |
| Needed in languages without first-class functions | Rarely needed in Python unless strategies carry heavy internal state |

---

## 4.3 Iterator → Generators (`yield`)

Covered in 3f, but worth restating as a general principle: **any time you'd write a custom `__iter__`/`__next__` class, consider a generator function first.**

```python
# Custom Iterator class version (GoF-style) — verbose
class RangeIterator:
    def __init__(self, start, stop):
        self.current = start
        self.stop = stop
    def __iter__(self):
        return self
    def __next__(self):
        if self.current >= self.stop:
            raise StopIteration
        value = self.current
        self.current += 1
        return value

# Generator version — same behavior, 4 lines instead of 12
def range_iterator(start, stop):
    while start < stop:
        yield start
        start += 1
```

Generators also compose naturally for **streaming/lazy pipelines**, which is much more verbose with class-based iterators:

```python
def read_lines(path: str):
    with open(path) as f:
        for line in f:
            yield line.rstrip("\n")

def filter_errors(lines):
    for line in lines:
        if "ERROR" in line:
            yield line

def parse_timestamps(lines):
    for line in lines:
        yield line.split(" ")[0]

# Each stage is lazy — nothing is read into memory until consumed downstream
# pipeline = parse_timestamps(filter_errors(read_lines("app.log")))
```

---

## 4.4 Observer → Event Libraries / Callback Lists

The GoF `Observer` ABC is often replaced by a plain list of callables (shown in 3b) or a dedicated library like **Blinker** for larger apps.

```python
# Minimal Pythonic pub/sub without any Observer base class
class Signal:
    def __init__(self):
        self._subscribers: list[Callable] = []

    def connect(self, fn: Callable) -> None:
        self._subscribers.append(fn)

    def send(self, *args, **kwargs) -> None:
        for fn in self._subscribers:
            fn(*args, **kwargs)


order_shipped = Signal()
order_shipped.connect(lambda order_id: print(f"Emailing customer about order {order_id}"))
order_shipped.connect(lambda order_id: print(f"Logging shipment for order {order_id}"))

order_shipped.send(order_id=1001)
```

**Expected output:**
```
Emailing customer about order 1001
Logging shipment for order 1001
```

> For production apps with many decoupled listeners across modules, consider **Blinker** (`pip install blinker`) — it provides named signals, weak references (no memory leaks from forgotten subscribers), and is the same pattern used internally by Flask.

---

## 4.5 Decorator (Structural) → Native `@decorator` Syntax

Already demonstrated in 2b — the language-level takeaway:

| GoF Decorator (class-based) | Native Python Decorator |
|---|---|
| Wraps an *object*, requires matching interface | Wraps a *function*, via `functools.wraps` |
| Used for runtime composition of behavior on instances | Used for cross-cutting concerns: logging, timing, caching, auth checks |
| Still essential for wrapping objects/instances dynamically | The go-to tool for wrapping *functions/methods* |

```python
# functools.lru_cache is a real-world built-in decorator — memoization "for free"
from functools import lru_cache

@lru_cache(maxsize=128)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)

print(fibonacci(30))  # fast, thanks to cached results
```

---

## Part 4 — Recap Table

| Classic GoF Pattern | Pythonic Replacement | Still Use GoF Version When... |
|---|---|---|
| Singleton | Module-level state | You need lazy initialization tied to a class, or subclass-based variants |
| Strategy | First-class functions/closures | Strategies carry significant internal state or need polymorphic hierarchies |
| Iterator | Generators (`yield`) | You need an iterator that's also reusable as a full object with extra methods |
| Observer | Callback lists / `Blinker` signals | Observers need a rich, typed interface with multiple distinct callback methods |
| Decorator | `@decorator` + `functools.wraps` | You're wrapping objects/instances, not functions |

---

# 🎉 Series Complete

| Part | Topic | Status |
|---|---|---|
| 1 | Creational Patterns (Singleton, Factory Method, Abstract Factory, Builder, Prototype) | ✅ Complete |
| 2 | Structural Patterns (Adapter, Decorator, Facade, Composite, Proxy) | ✅ Complete |
| 3 | Behavioral Patterns (Strategy, Observer, Command, State, Template Method, Iterator) | ✅ Complete |
| 4 | Pythonic Notes (idiomatic replacements for classic patterns) | ✅ Complete |
