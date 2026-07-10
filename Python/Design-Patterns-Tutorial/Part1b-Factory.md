# Part 1b — Factory Method

Delegates object creation to subclasses/functions, so client code depends on an interface, not concrete classes.

```python
from abc import ABC, abstractmethod

class Notifier(ABC):
    @abstractmethod
    def send(self, message: str) -> None:
        ...

class EmailNotifier(Notifier):
    def send(self, message: str) -> None:
        print(f"[EMAIL] {message}")

class SMSNotifier(Notifier):
    def send(self, message: str) -> None:
        print(f"[SMS] {message}")

def notifier_factory(channel: str) -> Notifier:
    """The Factory Method: a single function that decides WHICH class to instantiate.
    Client code never calls EmailNotifier() or SMSNotifier() directly -- it stays decoupled."""
    factories = {
        "email": EmailNotifier,
        "sms": SMSNotifier,
    }
    if channel not in factories:
        raise ValueError(f"Unknown channel: {channel}")
    return factories[channel]()


# Usage -- client only knows about the abstract Notifier interface
notifier = notifier_factory("sms")
notifier.send("Your order has shipped!")
```

**Expected output:**
```
[SMS] Your order has shipped!
```
