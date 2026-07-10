# Part 3a — Strategy

Encapsulates interchangeable algorithms behind a common interface, selected at runtime.

```python
from abc import ABC, abstractmethod

class DiscountStrategy(ABC):
    @abstractmethod
    def apply(self, total: float) -> float: ...

class NoDiscount(DiscountStrategy):
    def apply(self, total: float) -> float:
        return total

class PercentageDiscount(DiscountStrategy):
    def __init__(self, percent: float):
        self.percent = percent
    def apply(self, total: float) -> float:
        return total * (1 - self.percent / 100)

class FlatDiscount(DiscountStrategy):
    def __init__(self, amount: float):
        self.amount = amount
    def apply(self, total: float) -> float:
        return max(0, total - self.amount)

class ShoppingCart:
    def __init__(self, strategy: DiscountStrategy):
        # The cart depends on the ABSTRACT strategy, not a concrete discount class
        self._strategy = strategy
        self._items: list[float] = []

    def add_item(self, price: float) -> None:
        self._items.append(price)

    def set_strategy(self, strategy: DiscountStrategy) -> None:
        # Strategy can be swapped at runtime -- e.g. applying a coupon mid-checkout
        self._strategy = strategy

    def total(self) -> float:
        return self._strategy.apply(sum(self._items))


# Usage
cart = ShoppingCart(NoDiscount())
cart.add_item(50)
cart.add_item(30)
print(cart.total())  # 80.0

cart.set_strategy(PercentageDiscount(10))
print(cart.total())  # 72.0
```

**Expected output:**
```
80.0
72.0
```

**Pythonic alternative:** since these strategies hold no state, plain functions/closures work just as well and avoid the class boilerplate entirely:

```python
def no_discount(total: float) -> float:
    return total

def percentage_discount(percent: float):
    # returns a closure -- the strategy IS a function, no class hierarchy needed
    return lambda total: total * (1 - percent / 100)

apply_discount = percentage_discount(10)
print(apply_discount(80))  # 72.0
```

**Expected output:**
```
72.0
```

---

