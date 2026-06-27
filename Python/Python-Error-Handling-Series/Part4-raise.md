# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 4)

# Mastering `raise`, Re-Raising, Exception Chaining, and Custom Exceptions

> *"Most developers learn how to catch exceptions.*
>
> *Professional engineers spend far more time deciding which exceptions to throw."*

---

# Introduction

Consider this code:

```python
try:
    database.save(user)
except:
    print("failed")
```

Question:

> What failed?

Was it:

* the network?
* the database?
* the authentication layer?
* invalid data?
* disk corruption?
* serialization?
* a timeout?

Nobody knows.

This is why exception design matters.

Because exceptions are not merely error messages.

They are:

> **contracts for communicating failure.**

In this chapter we'll learn:

* `raise`
* re-raising
* exception propagation
* exception translation
* exception chaining
* `raise from`
* custom exceptions
* exception hierarchies
* domain-driven exception design

---

# Chapter 35 — What Does `raise` Actually Do?

The simplest example:

```python
raise Exception("boom")
```

Execution:

```text
Create Exception Object
           |
           V
Capture Current Stack
           |
           V
Stop Execution
           |
           V
Begin Stack Unwinding
```

---

Example:

```python
print("A")

raise Exception()

print("B")
```

Output:

```text
A
Traceback...
```

---

# Exercise 1

Predict:

```python
x = 10

raise ValueError()

x = 20

print(x)
```

What executes?

---

# Chapter 36 — Raising Existing Exceptions

You can raise exception instances:

```python
error = ValueError(
    "bad input"
)

raise error
```

Equivalent:

```python
raise ValueError(
    "bad input"
)
```

---

Exceptions are objects:

```python
e = RuntimeError()

print(type(e))
```

Output:

```text
<class 'RuntimeError'>
```

---

# Exercise 2

Create:

```python
AuthenticationError(
    "invalid password"
)
```

and raise it.

---

# Chapter 37 — Raising Built-In Exceptions

Python provides hundreds of exception types.

Examples:

```python
raise ValueError()
raise TypeError()
raise KeyError()
raise RuntimeError()
raise LookupError()
raise TimeoutError()
raise PermissionError()
```

---

# Example

Bad:

```python
raise Exception(
    "invalid age"
)
```

Better:

```python
raise ValueError(
    "age must be positive"
)
```

---

Why?

Because:

```text
specificity improves recovery
```

---

# Exercise 3

Which exception would you use?

* user age negative
* file missing
* timeout
* permission denied

---

# Chapter 38 — Exceptions Are Contracts

Consider:

```python
def withdraw(
    amount
):
    ...
```

Possible failures:

```text
negative amount
insufficient funds
account locked
bank offline
```

Bad:

```python
raise Exception(
    "withdraw failed"
)
```

Good:

```python
raise NegativeAmount()

raise InsufficientFunds()

raise AccountLocked()

raise BankOffline()
```

---

# Why?

Because callers can now recover intelligently.

Example:

```python
try:

    withdraw(100)

except InsufficientFunds:

    notify_user()

except BankOffline:

    retry()
```

---

# Exercise 4

Design exceptions for:

```text
Shopping Cart Checkout
```

Possible failures:

* payment declined
* inventory unavailable
* address invalid
* coupon expired

---

# Chapter 39 — Re-Raising Exceptions

Suppose:

```python
try:

    dangerous()

except Exception:

    print("failed")

    raise
```

Question:

Why use:

```python
raise
```

instead of:

```python
raise e
```

?

---

# Example

```python
try:

    1/0

except Exception:

    print("logging")

    raise
```

Output:

```text
logging
ZeroDivisionError
```

---

# Visualization

```text
catch
   |
log
   |
rethrow
```

---

# Exercise 5

Add logging to:

```python
process_order()
```

without swallowing exceptions.

---

# Chapter 40 — `raise` vs `raise e`

This is one of Python's biggest interview questions.

---

## Correct

```python
try:

    dangerous()

except Exception:

    raise
```

Result:

```text
original traceback preserved
```

---

## Wrong

```python
try:

    dangerous()

except Exception as e:

    raise e
```

Result:

```text
new traceback created
```

---

# Visualization

### raise

```text
Original
A
B
C
```

Preserved:

```text
A
B
C
```

---

### raise e

```text
Original
A
B
C
```

Becomes:

```text
A
B
C
handler
raise e
```

---

# Rule

Always prefer:

```python
raise
```

unless you intentionally want a new traceback.

---

# Exercise 6

Run both examples and compare the tracebacks.

---

# Chapter 41 — Exception Translation

Suppose:

```python
def get_user():

    try:
        db.fetch()

    except ConnectionError:
        ...
```

Should your business logic know about:

```text
database connection failures?
```

Usually:

```text
No.
```

---

Instead:

```python
def get_user():

    try:

        db.fetch()

    except ConnectionError:

        raise UserStoreError()
```

---

This is called:

# Exception Translation

---

# Architecture

```text
Database Layer
       |
ConnectionError
       |
       V
Repository Layer
       |
UserStoreError
       |
       V
Business Layer
```

---

# Exercise 7

Translate:

```text
requests.Timeout
```

into:

```text
PaymentGatewayTimeout
```

---

# Chapter 42 — Exception Chaining

Problem:

```python
try:

    db.connect()

except ConnectionError:

    raise DatabaseError()
```

Question:

Where did:

```text
ConnectionError
```

go?

It disappeared.

---

Example:

```python
try:

    int(None)

except Exception:

    raise RuntimeError(
        "processing failed"
    )
```

Output:

```text
RuntimeError
```

Original cause:

```text
gone
```

---

# Exercise 8

Demonstrate losing an exception cause.

---

# Chapter 43 — `raise from`

Python solves this with:

```python
raise X from Y
```

Example:

```python
try:

    int(None)

except Exception as e:

    raise RuntimeError(
        "processing failed"
    ) from e
```

---

Output:

```text
TypeError

The above exception was
the direct cause of:

RuntimeError
```

---

# Visualization

```text
TypeError
      |
      V
RuntimeError
```

---

# Why?

Because failures have causes.

---

# Exercise 9

Convert:

```python
requests.Timeout
```

to:

```python
PaymentTimeout
```

using:

```python
raise from
```

---

# Chapter 44 — Exception Causal Graphs

Example:

```python
NetworkTimeout
        |
        V
DatabaseTimeout
        |
        V
RepositoryError
        |
        V
ApplicationError
```

This forms a graph:

```text
Root Cause
      |
      V
Infrastructure
      |
      V
Service Layer
      |
      V
Application Layer
```

---

Modern observability systems rely on this.

Examples:

* distributed tracing
* OpenTelemetry
* Sentry
* Datadog
* Honeycomb

---

# Exercise 10

Draw the causal chain for:

```text
DNS failure
```

causing:

```text
payment service outage
```

---

# Chapter 45 — Creating Custom Exceptions

Example:

```python
class PaymentError(
    Exception
):
    pass
```

Usage:

```python
raise PaymentError(
    "card declined"
)
```

---

# Exercise 11

Create:

```python
UserNotFound
```

exception.

---

# Chapter 46 — Exception Hierarchies

Bad:

```python
class CardExpired(Exception):
    pass

class CardDeclined(Exception):
    pass

class Fraud(Exception):
    pass
```

---

Better:

```python
class PaymentError(
    Exception
):
    pass


class CardExpired(
    PaymentError
):
    pass


class CardDeclined(
    PaymentError
):
    pass


class FraudDetected(
    PaymentError
):
    pass
```

---

Now:

```python
try:

    pay()

except PaymentError:
    rollback()
```

handles all payment failures.

---

# Visualization

```text
Exception
     |
PaymentError
     |
     +--- CardExpired
     |
     +--- CardDeclined
     |
     +--- FraudDetected
```

---

# Exercise 12

Design a hierarchy for:

```text
Authentication System
```

---

# Chapter 47 — Exceptions As Domain Models

Consider banking:

```text
BankingError
     |
     +--- InsufficientFunds
     |
     +--- AccountLocked
     |
     +--- DailyLimitExceeded
     |
     +--- CurrencyMismatch
```

---

Consider ecommerce:

```text
CheckoutError
     |
     +--- OutOfStock
     |
     +--- CouponExpired
     |
     +--- PaymentDeclined
```

---

Exceptions model:

> **business failure states.**

---

# Chapter 48 — Designing Recoverable Exceptions

Ask:

```text
Can caller recover?
```

If yes:

```python
raise RetryableError()
```

If no:

```python
raise FatalError()
```

---

Example:

```python
class RetryableError(
    Exception
):
    pass


class FatalError(
    Exception
):
    pass
```

---

Usage:

```python
except RetryableError:

    retry()

except FatalError:

    abort()
```

---

# Exercise 13

Categorize:

* timeout
* bad password
* corrupted database
* insufficient memory

---

# The Exception Design Pyramid

```text
Hardware Failure
        |
Infrastructure Error
        |
Service Error
        |
Business Error
        |
User Error
```

---

# The Most Important Diagram In Exception Design

```text
Failure
    |
    V
Root Cause
    |
    V
Exception Object
    |
    V
Exception Translation
    |
    V
Domain Exception
    |
    V
Recovery Decision
```

---

# Summary

In this article we learned:

✅ `raise` creates exceptions
✅ exceptions are contracts
✅ `raise` vs `raise e`
✅ re-raising
✅ exception translation
✅ exception chaining
✅ `raise from`
✅ custom exceptions
✅ exception hierarchies
✅ domain-driven exceptions

---

# Conclusion

Most developers think:

> Exceptions are error messages.

Professional engineers think:

> Exceptions are APIs for communicating failure.

Because the real question isn't:

> "What went wrong?"

The real question is:

> **"How can the next layer make the correct recovery decision?"**

In **Part 5**, we'll reverse engineer Python's entire exception hierarchy:

* `BaseException`
* `Exception`
* `RuntimeError`
* `LookupError`
* `ArithmeticError`
* `OSError`
* `SystemExit`
* `KeyboardInterrupt`

and discover why:

```python
except Exception:
```

does **not** catch everything.

Because Python's exception hierarchy is actually a failure taxonomy. 🚨
