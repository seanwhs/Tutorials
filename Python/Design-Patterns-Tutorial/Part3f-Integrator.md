# Part 3f — Iterator

Provides a uniform way to traverse a collection's elements **without exposing its internal structure** — Python bakes this pattern directly into the language via `__iter__`/`__next__` and generators.

```python
class OddNumberCollection:
    """A custom collection exposing ONLY iteration -- the internal storage
    (a plain list here) is hidden from the client entirely."""
    def __init__(self, limit: int):
        self._numbers = [n for n in range(limit) if n % 2 == 1]

    def __iter__(self) -> "OddNumberIterator":
        # __iter__ must return an iterator object -- a fresh one each time,
        # so multiple independent loops over the same collection don't interfere
        return OddNumberIterator(self._numbers)


class OddNumberIterator:
    """The Iterator -- tracks traversal position independently of the collection."""
    def __init__(self, numbers: list):
        self._numbers = numbers
        self._index = 0

    def __iter__(self) -> "OddNumberIterator":
        return self

    def __next__(self) -> int:
        if self._index >= len(self._numbers):
            raise StopIteration  # signals "no more items" to for-loops
        value = self._numbers[self._index]
        self._index += 1
        return value


# Usage -- works with a standard Python for-loop, exactly like a list or dict
odds = OddNumberCollection(10)
for n in odds:
    print(n)
```

**Expected output:**
```
1
3
5
7
9
```

**Pythonic alternative:** Python's `yield` keyword builds an iterator automatically — no manual `__iter__`/`__next__`/`StopIteration` bookkeeping needed:

```python
def odd_numbers(limit: int):
    """A generator function -- calling it returns an iterator for free.
    Each `yield` pauses execution and hands control back to the caller."""
    for n in range(limit):
        if n % 2 == 1:
            yield n


# Usage -- identical client-side behavior, far less boilerplate
for n in odd_numbers(10):
    print(n)
```

**Expected output:**
```
1
3
5
7
9
```

---

# Part 3 — Recap Table

| Pattern | Analogy | When to Reach For It |
|---|---|---|
| Strategy | Choosing a route on a GPS | Swappable algorithms/behavior selected at runtime |
| Observer | Newsletter subscribers | Multiple objects need to react to one object's state changes |
| Command | A restaurant order ticket | Queueing, logging, or undoing discrete actions |
| State | A traffic light cycling colors | Behavior changes based on internal state, avoiding if/elif sprawl |
| Template Method | A recipe with customizable steps | Fixed algorithm skeleton, variable individual steps |
| Iterator | Flipping through a book page by page | Uniform traversal over a collection, hiding internal structure |

**Part 3 is now complete** across sub-parts 3a–3f (Strategy, Observer, Command, State, Template Method, Iterator), each individually verified.

---

