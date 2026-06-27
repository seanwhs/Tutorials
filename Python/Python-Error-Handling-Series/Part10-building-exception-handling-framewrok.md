# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 11)

# Building Your Own Exception Framework: Custom Exceptions, Metadata, Error Codes, and Production Error Models

> *"Beginners throw strings.*
>
> *Intermediate developers throw exceptions.*
>
> *Professional engineers design error systems."*

---

# Introduction

Most developers eventually discover custom exceptions:

```python
class PaymentError(Exception):
    pass
```

and think:

> "Great. I've built a custom error."

Not really.

In production systems, an error isn't just:

```text
something bad happened
```

An error is often:

* an event,
* a diagnostic record,
* a recovery instruction,
* a monitoring signal,
* a business decision,
* an audit artifact.

Consider:

```text
Payment Failed
```

Questions:

* Which customer?
* Which payment method?
* Which region?
* Retryable?
* User-visible?
* Alert-worthy?
* SLA violation?
* Compensation required?
* Root cause?

Professional systems therefore don't merely raise exceptions.

They build:

# Error Models

---

# Chapter 137 — Why String Exceptions Are Terrible

Suppose:

```python
raise Exception(
    "payment failed"
)
```

Question:

What failed?

```text
Unknown.
```

Can we retry?

```text
Unknown.
```

Can we alert?

```text
Unknown.
```

Can we recover?

```text
Unknown.
```

---

Another example:

```python
raise Exception(
    "timeout"
)
```

Which timeout?

* database?
* API?
* DNS?
* payment gateway?

Nobody knows.

---

# Exercise 1

List everything missing from:

```python
raise Exception(
    "something failed"
)
```

---

# Chapter 138 — Your First Custom Exception

Basic example:

```python
class PaymentError(Exception):
    pass
```

Usage:

```python
raise PaymentError(
    "payment declined"
)
```

Catch:

```python
except PaymentError:
    recover()
```

---

Visualization:

```text
Exception
     |
PaymentError
```

---

# Exercise 2

Create:

```python
InventoryError
```

---

# Chapter 139 — Exceptions Can Have State

Exceptions are objects.

Example:

```python
class PaymentError(
    Exception
):

    def __init__(
        self,
        order_id,
        amount
    ):

        self.order_id = order_id
        self.amount = amount

        super().__init__(
            f"payment failed"
        )
```

---

Usage:

```python
raise PaymentError(
    order_id=123,
    amount=500
)
```

Catch:

```python
except PaymentError as e:

    print(e.order_id)
```

---

# Visualization

```text
Exception
    |
Message
Metadata
State
Methods
```

---

# Exercise 3

Add:

* user id
* payment method
* region

to:

```python
PaymentError
```

---

# Chapter 140 — Error Codes

Large systems rarely depend on messages.

Bad:

```python
if "timeout" in str(e):
```

---

Good:

```python
class ErrorCode:

    PAYMENT_TIMEOUT = 1001

    CARD_DECLINED = 1002
```

---

Example:

```python
class PaymentError(
    Exception
):

    def __init__(
        self,
        code
    ):

        self.code = code
```

---

Usage:

```python
raise PaymentError(
    ErrorCode.CARD_DECLINED
)
```

---

# Visualization

```text
Human Message
       |
Machine Code
```

---

# Exercise 4

Design error codes for:

* login
* checkout
* inventory

---

# Chapter 141 — Retryable Exceptions

Professional systems classify failures.

Example:

```python
class AppError(
    Exception
):

    retryable = False
```

---

Subclass:

```python
class DatabaseTimeout(
    AppError
):

    retryable = True
```

---

Usage:

```python
except AppError as e:

    if e.retryable:

        retry()
```

---

Visualization:

```text
Failure
   |
Retryable?
 /       \
yes       no
```

---

# Exercise 5

Mark these:

* timeout
* bad password
* DNS failure
* invalid email

as retryable or not.

---

# Chapter 142 — User Visible Errors

Not all exceptions should be shown.

Example:

```python
class AppError(
    Exception
):

    user_visible = False
```

---

Example:

```python
class InvalidEmail(
    AppError
):

    user_visible = True
```

---

Usage:

```python
if error.user_visible:

    show(error)
```

---

Visualization:

```text
Internal Error
      |
Visible?
   /     \
yes      no
```

---

# Exercise 6

Classify:

* timeout
* insufficient funds
* invalid password
* database crash

---

# Chapter 143 — Severity Levels

Production systems classify impact.

Example:

```python
class Severity:

    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4
```

---

Example:

```python
class AppError(
    Exception
):

    severity = Severity.LOW
```

---

Subclass:

```python
class DatabaseCorruption(
    AppError
):

    severity = Severity.CRITICAL
```

---

Usage:

```python
if e.severity == CRITICAL:

    page_engineer()
```

---

# Exercise 7

Assign severities:

* typo
* payment failure
* database corruption
* memory exhaustion

---

# Chapter 144 — Alertable Errors

Example:

```python
class AppError(
    Exception
):

    alert = False
```

---

Subclass:

```python
class SecurityBreach(
    AppError
):

    alert = True
```

---

Usage:

```python
if e.alert:

    send_page()
```

---

Visualization:

```text
Error
   |
Alert?
 /    \
Y      N
```

---

# Exercise 8

Decide which errors require paging.

---

# Chapter 145 — Domain Exception Trees

Example:

```python
class BankingError(Exception):
    pass


class AccountError(
    BankingError
):
    pass


class PaymentError(
    BankingError
):
    pass


class TransferError(
    BankingError
):
    pass


class InsufficientFunds(
    TransferError
):
    pass
```

---

Visualization:

```text
BankingError
      |
      +---Account
      |
      +---Payment
      |
      +---Transfer
               |
               +---InsufficientFunds
```

---

# Exercise 9

Build a hierarchy for:

```text
Airline Reservation
```

---

# Chapter 146 — Error Context Objects

Instead of:

```python
raise PaymentError()
```

do:

```python
raise PaymentError(
    context={
        "user":123,
        "order":456,
        "region":"SG"
    }
)
```

---

Example:

```python
class AppError(
    Exception
):

    def __init__(
        self,
        message,
        context=None
    ):

        self.context = context or {}

        super().__init__(message)
```

---

Usage:

```python
except AppError as e:

    log(e.context)
```

---

# Exercise 10

Add context to:

```text
CheckoutFailed
```

---

# Chapter 147 — Serialization

Errors often cross process boundaries.

Example:

```python
class AppError(Exception):

    def to_dict(self):

        return {

            "type":
                type(self).__name__,

            "message":
                str(self),

            "context":
                self.context
        }
```

---

Usage:

```python
json.dumps(
    error.to_dict()
)
```

---

Output:

```json
{
  "type":"PaymentError",
  "message":"failed",
  "context":{
    "order":123
  }
}
```

---

# Exercise 11

Implement:

```python
from_dict()
```

---

# Chapter 148 — Exception Factories

Example:

```python
class Errors:

    @staticmethod
    def payment_timeout():

        return PaymentError(
            code=1001
        )
```

---

Usage:

```python
raise Errors.payment_timeout()
```

---

Benefits:

* consistency,
* centralization,
* localization,
* maintainability.

---

# Exercise 12

Build an error factory.

---

# Chapter 149 — Production Error Envelopes

Modern systems often wrap errors.

Example:

```python
{
    "timestamp":
        "...",

    "service":
        "payment",

    "error":
        "timeout",

    "retryable":
        true,

    "severity":
        "high",

    "correlation":
        "abc123"
}
```

---

Visualization:

```text
Exception
      |
Metadata
      |
Telemetry
      |
Envelope
```

---

# Exercise 13

Design an error envelope for:

```text
Food Delivery App
```

---

# Chapter 150 — Building A Real Error Framework

Example:

```python
from enum import Enum


class Severity(Enum):

    LOW=1
    MEDIUM=2
    HIGH=3
    CRITICAL=4


class AppError(
    Exception
):

    retryable=False
    user_visible=False
    severity=Severity.LOW

    def __init__(
        self,
        message,
        code=None,
        context=None
    ):

        self.code=code
        self.context=context or {}

        super().__init__(message)
```

---

Example:

```python
class PaymentTimeout(
    AppError
):

    retryable=True

    severity=Severity.HIGH
```

---

Usage:

```python
raise PaymentTimeout(

    "gateway timeout",

    code=1001,

    context={

        "user":123,
        "order":456
    }
)
```

---

# Visualization

```text
Exception
     |
Metadata
     |
Severity
     |
Retry Policy
     |
Observability
     |
Recovery
```

---

# Exercise 14

Extend the framework with:

* alerting
* tracing
* correlation IDs
* compensation hints

---

# The Professional Error Model

```text
Failure
    |
Exception
    |
Classification
    |
Metadata
    |
Observability
    |
Recovery
    |
Learning
```

---

# The Error Object Lifecycle

```text
Failure
    |
Raise
    |
Annotate
    |
Translate
    |
Observe
    |
Recover
    |
Archive
    |
Learn
```

---

# The Most Important Diagram In Error Engineering

```text
Error
   |
Context
   |
Classification
   |
Translation
   |
Recovery
   |
Telemetry
   |
Observability
   |
Resilience
```

---

# Summary

In this article we learned:

✅ custom exceptions
✅ exception metadata
✅ error codes
✅ retryable exceptions
✅ user-visible exceptions
✅ severity levels
✅ alertable exceptions
✅ domain exception trees
✅ context objects
✅ serialization
✅ exception factories
✅ production error envelopes

---

# Conclusion

Most developers think:

> Exceptions are error messages.

Professional engineers understand:

> **Exceptions are structured models of failure.**

Because in production systems, an exception is not merely:

```text
something went wrong
```

It is:

* a diagnostic artifact,
* a recovery instruction,
* an observability event,
* a business decision,
* and a learning opportunity.

And that's perhaps the deepest lesson of software engineering:

> **Software isn't about building systems that never fail.**
>
> It's about building systems that **fail predictably, observably, and recoverably.** 🚨

---

# Series Epilogue — Where To Go Next

Now that you've mastered Python error handling, the natural next deep dives are:

* **Concurrency Error Handling**

  * threads
  * futures
  * thread pools
  * deadlocks
  * cancellation

* **Async Error Handling**

  * `asyncio`
  * task groups
  * cancellation propagation
  * structured concurrency

* **Distributed Systems Failures**

  * CAP theorem
  * sagas
  * consensus
  * split brain
  * eventual consistency

* **Reliability Engineering**

  * SRE
  * SLIs/SLOs
  * chaos engineering
  * fault injection
  * disaster recovery

Because ultimately:

> **Software engineering is the study of controlled failure.** 🚨
