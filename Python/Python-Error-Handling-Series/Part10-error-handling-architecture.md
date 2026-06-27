# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 10)

# Designing Production-Grade Error Handling Architectures: Exception Boundaries, Domain Errors, and Fault Containment

> *"Junior developers write code that handles errors.*
>
> *Senior engineers design systems that contain failures."*

---

# Introduction

Consider this application:

```text
Frontend
    |
API Gateway
    |
Order Service
    |
Payment Service
    |
Inventory Service
    |
Database
```

Now imagine the database fails.

Question:

Where should the error be handled?

```text
Database?
```

Maybe.

```text
Payment Service?
```

Perhaps.

```text
Order Service?
```

Possibly.

```text
Frontend?
```

Definitely.

The hardest question in software engineering isn't:

> "How do I catch an exception?"

It's:

> **"Where should this exception stop?"**

Because every software system is really:

> **a network of failure boundaries.**

---

# Chapter 121 — The Beginner Error Handling Architecture

Most applications start like this:

```python
try:

    everything()

except Exception as e:

    print(e)
```

---

Visualization:

```text
Entire Application
        |
        V
except Exception
```

---

Problems:

* catches too much,
* loses context,
* destroys architecture,
* hides bugs,
* impossible to maintain.

---

# Exercise 1

Find five problems with:

```python
except Exception:
    pass
```

---

# Chapter 122 — Exceptions Are Part Of Your Architecture

Consider:

```text
UI
 |
Service
 |
Repository
 |
Database
```

Failures travel upward.

```text
DatabaseError
      |
RepositoryError
      |
BusinessError
      |
UserVisibleError
```

---

Visualization:

```text
Infrastructure
       |
Application
       |
Business
       |
Presentation
```

---

This means:

> Exception hierarchies should mirror system architecture.

---

# Exercise 2

Design exception layers for:

```text
Online Banking
```

---

# Chapter 123 — Infrastructure Exceptions

Examples:

```python
ConnectionError

TimeoutError

PermissionError

FileNotFoundError
```

These belong to:

```text
Infrastructure Layer
```

---

Example:

```python
def query():

    raise ConnectionError()
```

---

Question:

Should users ever see:

```text
ConnectionError: errno 104
```

?

No.

---

# Exercise 3

List infrastructure failures in:

* ecommerce
* social media
* banking

---

# Chapter 124 — Application Exceptions

Application layer exceptions translate infrastructure failures.

Example:

```python
class PaymentGatewayUnavailable(
    Exception
):
    pass
```

---

Implementation:

```python
try:

    gateway.pay()

except ConnectionError as e:

    raise PaymentGatewayUnavailable(
        "gateway offline"
    ) from e
```

---

Visualization:

```text
ConnectionError
       |
       V
PaymentGatewayUnavailable
```

---

# Exercise 4

Translate:

```text
Database timeout
```

into:

```text
Business exception
```

---

# Chapter 125 — Domain Exceptions

Domain exceptions model business failures.

Examples:

```python
class InsufficientFunds(
    Exception
):
    pass


class UserSuspended(
    Exception
):
    pass


class InventoryUnavailable(
    Exception
):
    pass
```

---

These are not bugs.

They are:

> valid business outcomes.

---

Example:

```python
if balance < amount:

    raise InsufficientFunds()
```

---

Visualization:

```text
Technical Failure
        |
Business Meaning
        |
Domain Exception
```

---

# Exercise 5

Design domain exceptions for:

```text
Airline Booking
```

---

# Chapter 126 — Presentation Exceptions

Users should never see:

```text
ConnectionRefusedError
```

Instead:

```text
Unable to process payment.
Please try again later.
```

---

Example:

```python
try:

    checkout()

except PaymentFailed:

    return {
        "error":
        "payment unavailable"
    }
```

---

Visualization:

```text
Internal Error
       |
Translate
       |
User Message
```

---

# Exercise 6

Convert:

```text
DatabaseDeadlockError
```

into a user-facing message.

---

# Chapter 127 — Exception Boundaries

Every architectural layer should define:

```text
what enters
what exits
```

---

Example:

```text
Frontend
   |
Boundary
   |
Service
   |
Boundary
   |
Repository
   |
Boundary
```

---

Rule:

Exceptions crossing a boundary should be translated.

---

Bad:

```text
SQL Error
        |
Frontend
```

---

Good:

```text
SQL Error
      |
RepositoryError
      |
ServiceError
      |
UserError
```

---

# Exercise 7

Draw exception boundaries for:

```text
Ecommerce Checkout
```

---

# Chapter 128 — Fault Containment

Suppose:

```text
Recommendation Engine
```

fails.

Should:

```text
Payment System
```

fail?

No.

---

Visualization:

```text
Recommendations X

Payments ✓
Inventory ✓
Checkout ✓
```

---

This principle is called:

# Fault Containment

---

Example:

```python
try:

    recommendations()

except Exception:

    return []
```

---

# Exercise 8

Design fault containment for:

```text
Netflix
```

---

# Chapter 129 — Graceful Degradation

Suppose:

```text
AI Recommendation
```

fails.

Instead of:

```text
Website unavailable
```

serve:

```text
Popular products
```

---

Example:

```python
try:

    return ai_recommend()

except:

    return popular_items()
```

---

Visualization:

```text
Primary
   |
Fail
   |
Fallback
```

---

# Exercise 9

Design fallback systems for:

* search
* maps
* payment

---

# Chapter 130 — Anti-Corruption Layers

External systems are dangerous.

Example:

```text
Stripe API
```

returns:

```python
StripeCardError
```

Your application should not expose:

```python
StripeCardError
```

internally.

---

Instead:

```python
class PaymentDeclined(
    Exception
):
    pass
```

---

Translation:

```python
except StripeCardError:

    raise PaymentDeclined()
```

---

Visualization:

```text
External System
        |
Anti-Corruption Layer
        |
Internal Domain
```

---

# Exercise 10

Design an anti-corruption layer for:

```text
PayPal
```

---

# Chapter 131 — Global Exception Handlers

Eventually:

```text
unexpected things happen
```

You need:

```text
last line of defense
```

---

Example:

```python
try:

    application()

except Exception:

    logging.exception(
        "fatal"
    )
```

---

This handler should:

* log,
* alert,
* preserve context,
* terminate safely.

---

It should NOT:

```python
except:
    pass
```

---

# Exercise 11

Design a global exception handler.

---

# Chapter 132 — Exception Hierarchies

Professional applications build exception trees.

Example:

```python
class AppError(Exception):
    pass


class InfrastructureError(AppError):
    pass


class BusinessError(AppError):
    pass


class ValidationError(AppError):
    pass


class PaymentError(BusinessError):
    pass


class CheckoutError(BusinessError):
    pass
```

---

Visualization:

```text
AppError
    |
    +-- Infrastructure
    |
    +-- Validation
    |
    +-- Business
            |
            +-- Payment
            |
            +-- Checkout
```

---

# Exercise 12

Build an exception hierarchy for:

```text
Food Delivery App
```

---

# Chapter 133 — Failure Domains

Large systems isolate failures.

Example:

```text
Search
Payments
Messaging
Analytics
Notifications
```

Each has:

* own database,
* own queue,
* own retry policy,
* own exceptions.

---

Visualization:

```text
+---------+
|Payment  |
+---------+

+---------+
|Search   |
+---------+

+---------+
|Email    |
+---------+
```

---

Failure remains local.

---

# Exercise 13

Partition failures for:

```text
Ride Sharing App
```

---

# Chapter 134 — The Recovery Ladder

Professional systems attempt recovery in stages.

```text
Retry
   |
Fallback
   |
Cache
   |
Graceful Degradation
   |
Compensation
   |
Abort
```

---

Example:

```python
try:

    primary()

except:

    try:

        fallback()

    except:

        cache()
```

---

# Exercise 14

Design a recovery ladder for:

```text
Online Banking
```

---

# Chapter 135 — Exception Architecture In Microservices

Example:

```text
Frontend
      |
GatewayError
      |
CheckoutError
      |
PaymentError
      |
DatabaseError
      |
SocketError
```

---

Notice:

```text
higher abstraction
as we move upward
```

---

Visualization:

```text
Low-Level Failure
        |
Translate
        |
Translate
        |
Translate
        |
Business Failure
```

---

# Chapter 136 — The Golden Rule

Never expose:

```text
implementation exceptions
```

to higher layers.

Always expose:

```text
semantic exceptions
```

---

Bad:

```python
ConnectionResetError
```

---

Good:

```python
PaymentServiceUnavailable
```

---

Bad:

```python
KeyError
```

---

Good:

```python
CustomerNotFound
```

---

# Exercise 15

Translate:

* FileNotFoundError
* ConnectionError
* TimeoutError
* KeyError

into domain exceptions.

---

# The Failure Containment Architecture

```text
Infrastructure
        |
Translate
        |
Application
        |
Translate
        |
Domain
        |
Translate
        |
Presentation
```

---

# The Production Exception Pipeline

```text
Failure
    |
Detect
    |
Translate
    |
Contain
    |
Recover
    |
Observe
    |
Learn
```

---

# The Most Important Diagram In Production Software Engineering

```text
Failure
    |
    V
Exception
    |
    V
Boundary
    |
    V
Translation
    |
    V
Containment
    |
    V
Recovery
    |
    V
Observability
    |
    V
Resilience
```

---

# Summary

In this article we learned:

✅ exception boundaries
✅ layered exception architectures
✅ infrastructure exceptions
✅ application exceptions
✅ domain exceptions
✅ presentation exceptions
✅ fault containment
✅ graceful degradation
✅ anti-corruption layers
✅ exception hierarchies
✅ recovery ladders
✅ failure domains

---

# Final Conclusion: The Philosophy Of Error Handling

At the beginning of this series, error handling looked like:

```python
try:
    something()
except:
    fix()
```

Now we understand that error handling is actually about:

```text
Failure Modeling
        |
Failure Classification
        |
Failure Translation
        |
Failure Containment
        |
Failure Recovery
        |
Failure Observation
        |
Failure Learning
```

Most developers believe:

> Error handling is about preventing crashes.

Professional engineers understand:

> **Error handling is the science of designing systems that continue to behave predictably in the presence of unavoidable failure.**

Because software engineering is not the study of:

> how systems work.

It is ultimately the study of:

> **how systems fail.** 🚨
