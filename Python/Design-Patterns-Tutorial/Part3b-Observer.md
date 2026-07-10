# Part 3b — Observer

Lets objects (**observers**) subscribe to and get notified of state changes in another object (**subject**) — the backbone of event systems, pub/sub, and reactive UIs.

```python
from abc import ABC, abstractmethod

class Observer(ABC):
    @abstractmethod
    def on_update(self, event: str, data: dict) -> None: ...

class EmailAlertObserver(Observer):
    def on_update(self, event: str, data: dict) -> None:
        print(f"[Email] Alert: {event} -> {data}")

class LoggingObserver(Observer):
    def on_update(self, event: str, data: dict) -> None:
        print(f"[Log] {event}: {data}")

class StockTicker:
    """The Subject -- maintains a list of observers and notifies them
    without knowing WHAT they do with the notification (loose coupling)."""

    def __init__(self):
        self._observers: list[Observer] = []

    def subscribe(self, observer: Observer) -> None:
        self._observers.append(observer)

    def unsubscribe(self, observer: Observer) -> None:
        self._observers.remove(observer)

    def set_price(self, symbol: str, price: float) -> None:
        # Any state change triggers notification to ALL subscribers
        for observer in self._observers:
            observer.on_update("price_change", {"symbol": symbol, "price": price})


# Usage
ticker = StockTicker()
email_observer = EmailAlertObserver()
log_observer = LoggingObserver()

ticker.subscribe(email_observer)
ticker.subscribe(log_observer)
ticker.set_price("AAPL", 187.32)

# Unsubscribing removes that observer from future notifications
ticker.unsubscribe(email_observer)
ticker.set_price("AAPL", 190.10)
```

**Expected output:**
```
[Email] Alert: price_change -> {'symbol': 'AAPL', 'price': 187.32}
[Log] price_change: {'symbol': 'AAPL', 'price': 187.32}
[Log] price_change: {'symbol': 'AAPL', 'price': 190.1}
```

**Pythonic alternative:** for simple cases, observers can just be plain callables stored in a list — no `Observer` base class required:

```python
class SimpleEventEmitter:
    def __init__(self):
        self._callbacks: list[callable] = []

    def on(self, callback) -> None:
        self._callbacks.append(callback)

    def emit(self, *args, **kwargs) -> None:
        for callback in self._callbacks:
            callback(*args, **kwargs)


emitter = SimpleEventEmitter()
emitter.on(lambda price: print(f"Price is now {price}"))
emitter.emit(200.5)
```

**Expected output:**
```
Price is now 200.5
```

---

