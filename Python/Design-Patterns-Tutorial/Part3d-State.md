# Part 3d — State

Lets an object change its behavior when its internal state changes, without giant `if/elif` chains — the object appears to change its class at runtime.

```python
from abc import ABC, abstractmethod

class OrderState(ABC):
    @abstractmethod
    def next(self, order: "Order") -> None: ...
    @abstractmethod
    def cancel(self, order: "Order") -> None: ...
    @abstractmethod
    def name(self) -> str: ...

class PendingState(OrderState):
    def next(self, order: "Order") -> None:
        order.state = ShippedState()  # transition delegated to the state itself
    def cancel(self, order: "Order") -> None:
        order.state = CancelledState()
    def name(self) -> str:
        return "Pending"

class ShippedState(OrderState):
    def next(self, order: "Order") -> None:
        order.state = DeliveredState()
    def cancel(self, order: "Order") -> None:
        # Business rule: shipped orders can no longer be cancelled
        print("Cannot cancel -- order already shipped")
    def name(self) -> str:
        return "Shipped"

class DeliveredState(OrderState):
    def next(self, order: "Order") -> None:
        print("Order already delivered -- no further transitions")
    def cancel(self, order: "Order") -> None:
        print("Cannot cancel -- order already delivered")
    def name(self) -> str:
        return "Delivered"

class CancelledState(OrderState):
    def next(self, order: "Order") -> None:
        print("Order is cancelled -- no further transitions")
    def cancel(self, order: "Order") -> None:
        print("Order is already cancelled")
    def name(self) -> str:
        return "Cancelled"


class Order:
    """The 'Context' -- holds a reference to its current state object
    and delegates ALL state-dependent behavior to it."""
    def __init__(self):
        self.state: OrderState = PendingState()

    def next(self) -> None:
        self.state.next(self)

    def cancel(self) -> None:
        self.state.cancel(self)

    def status(self) -> str:
        return self.state.name()


# Usage -- Order never contains if/elif on status strings; each state knows its own rules
order = Order()
print(order.status())   # Pending

order.next()
print(order.status())   # Shipped

order.cancel()           # blocked -- prints business rule message
print(order.status())    # Shipped (unchanged)

order.next()
print(order.status())    # Delivered
```

**Expected output:**
```
Pending
Shipped
Cannot cancel -- order already shipped
Shipped
Delivered
```

---

