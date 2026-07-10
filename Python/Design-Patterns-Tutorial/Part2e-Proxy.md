# Part 2e — Proxy

Provides a **stand-in object** that controls access to a real object — used for lazy loading, access control, caching, or logging.

```python
import time

class ExpensiveDatabaseConnection:
    """The 'Real Subject' -- expensive to create."""
    def __init__(self):
        print("Connecting to database... (expensive)")
        time.sleep(0.1)  # simulate network latency

    def query(self, sql: str) -> str:
        return f"Result for: {sql}"

class LazyDatabaseProxy:
    """The Proxy delays creating the real object until it's actually needed
    (Virtual Proxy) -- the client interacts with this exactly like the real thing."""

    def __init__(self):
        self._real_connection: ExpensiveDatabaseConnection | None = None

    def query(self, sql: str) -> str:
        if self._real_connection is None:
            # Real object is only constructed on first actual use
            self._real_connection = ExpensiveDatabaseConnection()
        return self._real_connection.query(sql)


# Usage -- no connection cost paid until query() is first called
proxy = LazyDatabaseProxy()
print("Proxy created -- no DB connection yet")
print(proxy.query("SELECT * FROM users"))
```

**Expected output:**
```
Proxy created -- no DB connection yet
Connecting to database... (expensive)
Result for: SELECT * FROM users
```

**Pythonic mechanism:** real-world Python proxies often use `__getattr__` to transparently forward *any* attribute/method call, instead of manually re-implementing each method:

```python
class LoggingProxy:
    """Wraps ANY object and logs every attribute access -- no need to
    re-implement each method manually."""
    def __init__(self, target):
        self._target = target

    def __getattr__(self, name):
        attr = getattr(self._target, name)
        if callable(attr):
            def wrapper(*args, **kwargs):
                print(f"[LOG] Calling {name}({args}, {kwargs})")
                return attr(*args, **kwargs)
            return wrapper
        return attr


class RealService:
    def process(self, data: str) -> str:
        return f"processed: {data}"

service = LoggingProxy(RealService())
print(service.process("payload"))
```

**Expected output:**
```
[LOG] Calling process(('payload',), {})
processed: payload
```

---

# Part 2 — Recap Table

| Pattern | Analogy | When to Reach For It |
|---|---|---|
| Adapter | Power plug adapter | Integrating a third-party/legacy API with mismatched interface |
| Decorator | Layering clothes | Adding optional, stackable behavior at runtime |
| Facade | A car's ignition button | Hiding a complex multi-class subsystem behind one simple call |
| Composite | Folders containing folders | Tree/hierarchical data treated uniformly |
| Proxy | A security guard / receptionist | Lazy loading, access control, caching, remote object stand-ins |

**Part 2 is now complete** across sub-parts 2a–2e (Adapter, Decorator, Facade, Composite, Proxy), each individually verified.

