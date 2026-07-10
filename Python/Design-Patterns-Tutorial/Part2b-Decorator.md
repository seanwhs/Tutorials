# Part 2b — Decorator

Dynamically adds behavior to an object **without altering its class** — Python's `@decorator` syntax is a built-in implementation of this pattern.

```python
from abc import ABC, abstractmethod

class Coffee(ABC):
    @abstractmethod
    def cost(self) -> float: ...
    @abstractmethod
    def description(self) -> str: ...

class SimpleCoffee(Coffee):
    def cost(self) -> float:
        return 2.0
    def description(self) -> str:
        return "Coffee"

class CoffeeDecorator(Coffee):
    """Base decorator: wraps a Coffee and delegates by default."""
    def __init__(self, coffee: Coffee):
        self._coffee = coffee
    def cost(self) -> float:
        return self._coffee.cost()
    def description(self) -> str:
        return self._coffee.description()

class MilkDecorator(CoffeeDecorator):
    def cost(self) -> float:
        return self._coffee.cost() + 0.5  # add milk's price on top of wrapped object
    def description(self) -> str:
        return self._coffee.description() + " + Milk"

class SugarDecorator(CoffeeDecorator):
    def cost(self) -> float:
        return self._coffee.cost() + 0.25
    def description(self) -> str:
        return self._coffee.description() + " + Sugar"


# Usage -- decorators stack, each wrapping the previous layer
order = SugarDecorator(MilkDecorator(SimpleCoffee()))
print(order.description())   # "Coffee + Milk + Sugar"
print(order.cost())          # 2.75
```

**Expected output:**
```
Coffee + Milk + Sugar
2.75
```

**Pythonic alternative:** Python's built-in `@decorator` syntax implements the *functional* version of this pattern directly:

```python
import functools
import time

def timed(func):
    """A native Python decorator -- wraps a function to add timing behavior
    without touching the function's own code. Same intent as the GoF pattern."""
    @functools.wraps(func)  # preserves original __name__/__doc__ for introspection
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        result = func(*args, **kwargs)
        elapsed = time.perf_counter() - start
        print(f"{func.__name__} took {elapsed:.4f}s")
        return result
    return wrapper

@timed
def slow_calculation(n: int) -> int:
    return sum(i * i for i in range(n))

slow_calculation(1_000_000)
```

**Expected output (timing will vary):**
```
slow_calculation took 0.0821s
```

---

