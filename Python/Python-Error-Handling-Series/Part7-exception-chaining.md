# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 7)

# Exception Chaining, `raise from`, `__cause__`, and Root Cause Analysis

> *"Most developers see a traceback and ask: 'What failed?'*
>
> *Professional engineers ask: 'What failed first?'"*

---

# Introduction

Imagine this application:

```text
Web API
   |
   V
Business Service
   |
   V
Repository
   |
   V
Database Driver
   |
   V
TCP Socket
```

Now suppose the network cable gets unplugged.

What should the user see?

Certainly not:

```text
ConnectionResetError:
errno 104
socket.c line 847
```

Instead:

```text
PaymentProcessingError:
Unable to process payment
```

But there's a problem.

If we hide the original error:

```text
ConnectionResetError
```

we destroy the root cause.

This is why Python has:

# Exception Chaining

Because in real systems:

> Failures don't occur in isolation.

They occur as a chain of causes.

---

# Chapter 77 — The Problem Exception Chaining Solves

Consider:

```python
def load_user():

    try:
        int(None)

    except Exception:

        raise RuntimeError(
            "user load failed"
        )
```

Run:

```python
load_user()
```

Output:

```text
RuntimeError:
user load failed
```

Question:

Where did:

```text
TypeError
```

go?

It disappeared.

---

# Visualization

```text
Original Failure

TypeError
    |
    V
RuntimeError


After translation

RuntimeError
```

We lost information.

---

# Exercise 1

Run:

```python
try:
    int(None)
except:
    raise RuntimeError()
```

What happened to the original exception?

---

# Chapter 78 — Python's Implicit Exception Chaining

Python actually preserves exceptions automatically.

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
TypeError

During handling of the above exception,
another exception occurred:

RuntimeError
```

---

Python secretly stores:

```python
exception.__context__
```

---

# Visualization

```text
TypeError
      |
      V
__context__
      |
      V
RuntimeError
```

---

# Exercise 2

Inspect:

```python
try:

    int(None)

except Exception:

    raise RuntimeError()
```

using:

```python
except Exception as e:

    print(e.__context__)
```

---

# Chapter 79 — Understanding `__context__`

Example:

```python
try:

    raise ValueError()

except:

    raise RuntimeError()
```

Internally:

```text
ValueError
       |
       V
stored in
__context__
       |
       V
RuntimeError
```

---

Let's inspect:

```python
try:

    raise ValueError(
        "bad"
    )

except:

    try:

        raise RuntimeError(
            "worse"
        )

    except Exception as e:

        print(e.__context__)
```

Output:

```text
ValueError('bad')
```

---

# Exercise 3

Print:

```python
type(
    e.__context__
)
```

---

# Chapter 80 — Why Implicit Chaining Isn't Enough

Suppose:

```python
try:

    database.connect()

except ConnectionError:

    raise PaymentFailed()
```

Question:

Did:

```text
PaymentFailed
```

occur during handling?

Or did:

```text
ConnectionError
```

actually cause it?

Python can't know.

---

Implicit chaining means:

```text
Occurred During Handling
```

not:

```text
Caused By
```

---

# Visualization

```text
ConnectionError
        |
        ?
        |
PaymentFailed
```

Relationship unclear.

---

# Exercise 4

Why is this ambiguous?

```python
except:
    cleanup()
    raise NewError()
```

---

# Chapter 81 — Enter `raise from`

Python provides:

```python
raise NewException() from old_exception
```

---

Example:

```python
try:

    int(None)

except Exception as e:

    raise RuntimeError(
        "processing failed"
    ) from e
```

Output:

```text
TypeError

The above exception was
the direct cause of:

RuntimeError
```

---

This changes everything.

---

# Visualization

```text
TypeError
      |
 CAUSED BY
      |
      V
RuntimeError
```

---

# Exercise 5

Convert:

```python
except Exception:
    raise RuntimeError()
```

to:

```python
raise from
```

---

# Chapter 82 — Understanding `__cause__`

When you use:

```python
raise X from Y
```

Python stores:

```python
exception.__cause__
```

---

Example:

```python
try:

    int(None)

except Exception as e:

    try:

        raise RuntimeError() from e

    except Exception as x:

        print(x.__cause__)
```

Output:

```text
TypeError(...)
```

---

Visualization:

```text
__cause__

RuntimeError
      |
      V
TypeError
```

---

# Exercise 6

Inspect:

```python
e.__cause__
```

for:

```python
raise RuntimeError() from e
```

---

# Chapter 83 — Difference Between `__cause__` and `__context__`

This confuses almost everyone.

---

## Implicit

```python
raise X
```

creates:

```text
__context__
```

---

## Explicit

```python
raise X from Y
```

creates:

```text
__cause__
```

---

Visualization:

```text
Implicit

A
|
V
B

stored in:
__context__


Explicit

A
|
CAUSED BY
|
V
B

stored in:
__cause__
```

---

# Rule

Use:

```python
raise from
```

whenever:

> the previous exception actually caused the new exception.

---

# Exercise 7

Determine whether these should use:

```text
__context__
```

or:

```text
__cause__
```

* payment timeout
* validation failure
* cleanup failure

---

# Chapter 84 — Suppressing Exception Context

Sometimes you don't want:

```text
During handling...
```

Example:

```python
try:

    int(None)

except:

    raise RuntimeError() from None
```

Output:

```text
RuntimeError
```

No original exception.

---

This disables:

```python
__context__
```

---

# Visualization

```text
TypeError

X

RuntimeError
```

---

# When Should You Use This?

Examples:

* hiding internal implementation details,
* security boundaries,
* public APIs,
* SDK abstraction layers.

---

# Exercise 8

Compare:

```python
raise RuntimeError()
```

versus:

```python
raise RuntimeError() from None
```

---

# Chapter 85 — Exception Chains Form Graphs

Consider:

```python
try:

    network()

except Exception as e:

    raise DatabaseError() from e
```

Later:

```python
except Exception as e:

    raise RepositoryError() from e
```

Later:

```python
except Exception as e:

    raise ServiceError() from e
```

---

Result:

```text
NetworkError
        |
        V
DatabaseError
        |
        V
RepositoryError
        |
        V
ServiceError
```

---

This is a:

# Causal Graph

---

# Exercise 9

Draw:

```text
SocketTimeout
        |
PaymentGatewayError
        |
CheckoutFailed
```

---

# Chapter 86 — Modern Observability Uses Exception Chains

Tools like:

* Sentry
* Datadog
* Honeycomb
* OpenTelemetry

use exception chains to reconstruct failures.

---

Example:

```text
Request Failed
      |
      V
Payment Failed
      |
      V
Database Failed
      |
      V
Network Failed
      |
      V
DNS Failed
```

---

This enables:

* root-cause analysis,
* distributed tracing,
* failure correlation,
* incident investigation.

---

# Exercise 10

Trace this failure:

```text
DNS lookup failed
```

through:

```text
API Gateway
Payment Service
Checkout Service
Frontend
```

---

# Chapter 87 — Building Domain Exception Chains

Bad:

```python
try:

    payment()

except:

    raise CheckoutFailed()
```

---

Good:

```python
try:

    payment()

except PaymentError as e:

    raise CheckoutFailed(
        "checkout failed"
    ) from e
```

---

Now:

```text
Customer Layer
       |
CheckoutFailed
       |
PaymentError
       |
CardDeclined
```

---

# Visualization

```text
Business Failure
       |
       V
Service Failure
       |
       V
Infrastructure Failure
       |
       V
Root Cause
```

---

# Exercise 11

Design an exception chain for:

```text
User Login
```

including:

* DNS failure
* database timeout
* authentication failure

---

# Chapter 88 — Walking The Exception Chain

You can traverse exception chains.

Example:

```python
def root_cause(exc):

    while exc.__cause__:

        exc = exc.__cause__

    return exc
```

---

Usage:

```python
try:

    application()

except Exception as e:

    print(
        root_cause(e)
    )
```

---

This finds:

```text
the original failure
```

---

# Exercise 12

Implement:

```python
print_exception_chain()
```

---

# Chapter 89 — Exception Chaining Is Failure Compression

Suppose:

```text
DNS Failure
      |
Socket Failure
      |
HTTP Failure
      |
Payment Failure
      |
Checkout Failure
```

Without chaining:

```text
Checkout Failure
```

---

With chaining:

```text
Checkout Failure
        |
Payment Failure
        |
HTTP Failure
        |
Socket Failure
        |
DNS Failure
```

---

The entire history survives.

---

# Chapter 90 — The Professional Rule

When translating exceptions:

```python
except X as e:

    raise Y() from e
```

Never:

```python
except X:

    raise Y()
```

unless you intentionally want to destroy the causal history.

---

# The Exception Causality Graph

```text
Root Failure
      |
      V
Infrastructure Error
      |
      V
Repository Error
      |
      V
Service Error
      |
      V
Business Error
      |
      V
User Error
```

---

# The Most Important Diagram In Root Cause Analysis

```text
Failure
    |
    V
Exception
    |
    V
Translation
    |
    V
Chaining
    |
    V
Preserved Cause
    |
    V
Root Cause Analysis
```

---

# Summary

In this article we learned:

✅ implicit exception chaining
✅ `__context__`
✅ explicit exception chaining
✅ `raise from`
✅ `__cause__`
✅ `raise from None`
✅ causal graphs
✅ root-cause analysis
✅ observability systems
✅ domain exception chains

---

# Conclusion

Most developers look at an exception and ask:

> "What failed?"

Professional engineers ask:

> **"What failed first?"**

Because the exception you see is almost never the exception that matters.

The exception that matters is usually buried:

* three services away,
* four abstraction layers below,
* and six exception translations deep.

In **Part 8**, we'll tackle one of the hardest topics in production systems:

* retries,
* transient failures,
* exponential backoff,
* circuit breakers,
* idempotency,
* compensating transactions,
* and how to build systems that don't merely handle failure —

but **expect failure as a normal operating condition**. 🚨
