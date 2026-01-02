# 🐍 **Key Python Concepts**

## 1. Object-Oriented "Magic": Dunder Methods

**Dunder (Double Underscore)** methods let your custom classes emulate **built-in Python behavior**, such as arithmetic, iteration, and length operations.

| Dunder Method          | Purpose                      |
| ---------------------- | ---------------------------- |
| `__init__`             | Initialize object state      |
| `__str__` / `__repr__` | Pretty-print vs debug output |
| `__add__`              | Operator overloading for `+` |
| `__len__`              | Allow `len(obj)`             |
| `__getitem__`          | Enable indexing `obj[0]`     |

```python
class Vector:
    def __init__(self, x: float, y: float):
        self.x, self.y = x, y

    def __add__(self, other: "Vector") -> "Vector":
        return Vector(self.x + other.x, self.y + other.y)

    def __len__(self):
        return int((self.x**2 + self.y**2)**0.5)  # vector magnitude

    def __repr__(self):
        return f"Vector({self.x}, {self.y})"
```

---

## 2. Dynamic Arguments: `*args` and `**kwargs`

Functions can be **variadic**, meaning they accept any number of arguments. Essential for decorators and wrappers.

```python
def log_event(event: str, *tags: str, **metadata):
    print(f"Event: {event}")
    print(f"Tags: {tags}")          # tuple of extra positional args
    print(f"Meta: {metadata}")     # dict of keyword args
```

---

## 3. Decorators: Logic Injection

Decorators wrap a function to **extend behavior** without touching the source.

```python
import functools

def auth_required(func):
    @functools.wraps(func)
    def wrapper(self, *args, **kwargs):
        if not getattr(self, "_authenticated", False):
            raise Exception("Unauthorized")
        return func(self, *args, **kwargs)
    return wrapper
```

---

## 4. Resource & Memory Management

### 4.1 Context Managers

Context managers ensure **resources are cleaned up**, even on exceptions. Example: logging to a file or handling database connections.

```python
class FileLogger:
    def __init__(self, filename: str):
        self.filename = filename

    def __enter__(self):
        self.file = open(self.filename, "a")
        return self

    def log(self, message: str):
        self.file.write(message + "\n")

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.file.close()
```

Usage:

```python
with FileLogger("transactions.log") as logger:
    logger.log("Transaction completed")
```

### 4.2 Generators & Lazy Evaluation

Generators allow **lazy computation**, saving memory for large datasets.

```python
def fibonacci(n: int):
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b
```

---

## 5. Type Hinting & Safety

Type hints signal **intent**, helping teams avoid errors.

```python
from typing import Final

MAX_USERS: Final[int] = 100  # constant

def add(a: int, b: int) -> int:
    return a + b
```

---

## 6. Property Decorators (`@property`)

Use `@property` to create **getters and setters** with optional validation.

```python
class Person:
    def __init__(self, name: str, age: int):
        self.name = name
        self._age = age

    @property
    def age(self) -> int:
        return self._age

    @age.setter
    def age(self, value: int):
        if value < 0:
            raise ValueError("Age cannot be negative")
        self._age = value
```

---

## 7. Comprehensions

Python has **concise, expressive ways** to build collections.

```python
# List comprehension
squares = [x**2 for x in range(10) if x % 2 == 0]

# Dict comprehension
user_map = {user.id: user.name for user in users}

# Set comprehension
unique_tags = {tag.lower() for tag in ["Python", "python", "PYTHON"]}
```

---

## 8. Real-World Example: Bank System

This example combines **all the concepts**:

```python
from typing import Generator, Final
import functools

# ------------------------
# Decorator: Auth Check
# ------------------------
def auth_required(func):
    @functools.wraps(func)
    def wrapper(self, *args, **kwargs):
        if not getattr(self, "_authenticated", False):
            raise Exception("Unauthorized")
        return func(self, *args, **kwargs)
    return wrapper

# ------------------------
# Context Manager for Logging
# ------------------------
class TransactionLogger:
    def __init__(self, file: str):
        self.file = file

    def __enter__(self):
        self._f = open(self.file, "a")
        return self

    def log(self, msg: str):
        self._f.write(msg + "\n")

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._f.close()

# ------------------------
# Bank Account Class
# ------------------------
class BankAccount:
    INTEREST_RATE: Final[float] = 0.02  # Constant

    def __init__(self, owner: str, balance: float = 0.0):
        self.owner = owner
        self._balance = balance
        self._authenticated = False
        self.transactions = []

    def login(self, password: str):
        self._authenticated = password == "secret"
        return self._authenticated

    # ------------------------
    # Dunder Methods
    # ------------------------
    def __str__(self):
        return f"BankAccount({self.owner}, Balance: ${self._balance:.2f})"

    def __add__(self, other: "BankAccount"):
        return BankAccount(f"{self.owner}&{other.owner}", self._balance + other._balance)

    def __len__(self):
        return len(self.transactions)

    # ------------------------
    # Property Decorators
    # ------------------------
    @property
    def balance(self) -> float:
        return self._balance

    @balance.setter
    def balance(self, value: float):
        if value < 0:
            raise ValueError("Balance cannot be negative")
        self._balance = value

    # ------------------------
    # Core Methods with Auth
    # ------------------------
    @auth_required
    def deposit(self, amount: float, *tags: str, **metadata):
        self._balance += amount
        self.transactions.append((amount, tags, metadata))
        print(f"Deposited ${amount:.2f}")

    @auth_required
    def withdraw(self, amount: float):
        if amount > self._balance:
            raise ValueError("Insufficient funds")
        self._balance -= amount
        self.transactions.append((-amount, (), {}))
        print(f"Withdrew ${amount:.2f}")

    # ------------------------
    # Generator for Transaction History
    # ------------------------
    def transaction_history(self) -> Generator[str, None, None]:
        for idx, (amount, tags, meta) in enumerate(self.transactions, 1):
            yield f"Txn {idx}: ${amount:.2f}, Tags: {tags}, Meta: {meta}"

    # ------------------------
    # Lazy Interest Calculation
    # ------------------------
    def calculate_interest(self) -> Generator[float, None, None]:
        for txn, *_ in self.transactions:
            if txn > 0:
                yield txn * self.INTEREST_RATE

# ------------------------
# Usage
# ------------------------
if __name__ == "__main__":
    acc1 = BankAccount("Alice", 1000)
    acc2 = BankAccount("Bob", 500)

    acc1.login("secret")
    acc1.deposit(200, "salary", "bonus", user_id=101)
    acc1.withdraw(150)

    # Combine accounts
    joint_acc = acc1 + acc2
    print(joint_acc)

    # Log transactions to file using context manager
    with TransactionLogger("transactions.log") as logger:
        for txn in acc1.transaction_history():
            logger.log(txn)

    # Lazy interest calculation
    print("Interest earned on deposits:")
    print([round(i, 2) for i in acc1.calculate_interest()])

    # List comprehension example
    squared_txns = [txn[0]**2 for txn in acc1.transactions if txn[0] > 0]
    print(f"Squared positive transactions: {squared_txns}")
```

---

## ✅ Concepts Illustrated

| Concept          | Example in Code                    | Use Case                                |
| ---------------- | ---------------------------------- | --------------------------------------- |
| Dunder Methods   | `__str__`, `__add__`, `__len__`    | Make custom objects feel like built-ins |
| Variadic Args    | `*tags, **metadata`                | Flexible APIs, logging extra info       |
| Decorators       | `auth_required`                    | Inject authentication logic             |
| Property         | `@property balance`                | Safe access & validation                |
| Generators       | `transaction_history()`            | Lazy evaluation                         |
| Context Managers | `TransactionLogger`                | Safe resource handling                  |
| Type Hints       | `def deposit(self, amount: float)` | IDE & team safety                       |
| Lazy Computation | `calculate_interest()`             | Compute values only when needed         |
| Comprehensions   | `[txn[0]**2 for txn in ...]`       | Concise, readable collection creation   |

---


Do you want me to make that diagram?
