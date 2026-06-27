# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 8)

# Retries, Timeouts, Circuit Breakers, and Why Production Systems Assume Failure

> *"Beginners write code assuming success.*
>
> *Professional engineers write systems assuming failure."*

---

# Introduction

Consider this code:

```python
response = payment_service.charge()
```

Question:

What happens if the network drops for 200 milliseconds?

```text
FAIL
```

What if the database restarts?

```text
FAIL
```

What if DNS temporarily fails?

```text
FAIL
```

What if the payment gateway is overloaded?

```text
FAIL
```

In production systems, failures are not rare events.

They are:

> **normal operating conditions.**

Professional systems therefore do not ask:

> "How do we prevent failure?"

Instead they ask:

> **"How do we survive failure?"**

In this article we'll learn:

* transient failures
* permanent failures
* retries
* timeouts
* exponential backoff
* jitter
* circuit breakers
* bulkheads
* idempotency
* compensating transactions
* failure budgets

---

# Chapter 91 — Not All Failures Are Equal

Consider:

```python
raise ConnectionError()
```

Can we recover?

Maybe.

Consider:

```python
raise ValueError()
```

Can we recover?

Probably not.

---

Failures generally fall into two categories.

## Transient Failures

Temporary.

Examples:

* network congestion
* timeout
* DNS failure
* overloaded service
* database restart
* temporary lock contention

---

## Permanent Failures

Persistent.

Examples:

* bad password
* invalid input
* corrupted file
* permission denied
* missing record
* syntax error

---

# Visualization

```text
Failure
    |
    +---- Temporary
    |
    +---- Permanent
```

---

# Exercise 1

Classify:

* timeout
* file missing
* DNS failure
* invalid email
* connection reset
* insufficient funds

---

# Chapter 92 — The Simplest Retry

Example:

```python
def fetch():

    for _ in range(3):

        try:
            return api_call()

        except ConnectionError:
            continue

    raise RuntimeError(
        "all retries failed"
    )
```

---

Execution:

```text
Attempt 1
     |
     X
Attempt 2
     |
     X
Attempt 3
     |
     SUCCESS
```

---

# Exercise 2

Implement:

```python
retry(operation, attempts=5)
```

---

# Chapter 93 — Why Immediate Retries Are Bad

Suppose:

```text
Server overloaded
```

and every client does:

```text
Retry immediately
```

Result:

```text
Server overloaded
      |
      V
Retry storm
      |
      V
Server dies
```

---

Example:

```python
for _ in range(1000):
    retry()
```

This creates:

```text
thundering herd
```

---

# Exercise 3

Simulate 100 clients retrying immediately.

---

# Chapter 94 — Exponential Backoff

Instead of:

```text
1
1
1
1
```

we do:

```text
1
2
4
8
16
```

seconds.

---

Implementation:

```python
import time

def retry():

    delay = 1

    for attempt in range(5):

        try:
            return work()

        except ConnectionError:

            time.sleep(delay)

            delay *= 2
```

---

Visualization:

```text
Attempt
   |
1 sec
   |
2 sec
   |
4 sec
   |
8 sec
```

---

# Exercise 4

Implement exponential backoff.

---

# Chapter 95 — Why Exponential Backoff Still Fails

Suppose:

```text
1000 clients
```

all do:

```text
1
2
4
8
```

seconds.

Result:

```text
all clients retry together
```

Again.

---

Visualization:

```text
Client1 ---- retry
Client2 ---- retry
Client3 ---- retry
Client4 ---- retry
```

Boom.

---

# Chapter 96 — Enter Jitter

Instead:

```python
import random

sleep = delay + random.random()
```

Now:

```text
Client1 1.2 sec
Client2 1.8 sec
Client3 1.4 sec
Client4 1.6 sec
```

---

Visualization:

```text
Before:

|||||||||||


After:

| | ||  | | ||  |
```

---

# Exercise 5

Add random jitter to exponential backoff.

---

# Chapter 97 — Timeouts Are Mandatory

This code:

```python
response = requests.get(url)
```

is dangerous.

Why?

Because:

```text
wait forever
```

is a valid behavior.

---

Always:

```python
response = requests.get(
    url,
    timeout=5
)
```

---

Similarly:

```python
await asyncio.wait_for(
    task(),
    timeout=5
)
```

---

# Visualization

```text
Start
   |
Wait
   |
Timeout?
 /    \
No    Yes
 |      |
Done   Fail
```

---

# Exercise 6

Add timeout protection to:

```python
async def fetch():
```

---

# Chapter 98 — Retry + Timeout

Production systems combine both.

Example:

```python
for attempt in range(3):

    try:

        return requests.get(
            url,
            timeout=3
        )

    except TimeoutError:

        continue
```

---

Visualization:

```text
Attempt
   |
Timeout
   |
Retry
   |
Timeout
   |
Retry
```

---

# Exercise 7

Implement:

```python
retry_with_timeout()
```

---

# Chapter 99 — When Retries Become Dangerous

Consider:

```python
bank.transfer(
    100
)
```

Network fails.

Question:

Did transfer happen?

Unknown.

Retry:

```python
bank.transfer(
    100
)
```

Now:

```text
$100 transferred twice
```

Oops.

---

# Exercise 8

Identify operations that should never be blindly retried.

---

# Chapter 100 — Idempotency

An operation is idempotent if:

```text
executing twice
=
executing once
```

---

Examples:

## Idempotent

```python
user.name = "John"
```

---

```python
cache.delete()
```

---

```python
PUT /users/123
```

---

## Non-Idempotent

```python
balance += 100
```

---

```python
charge_credit_card()
```

---

```python
POST /payment
```

---

# Visualization

```text
Do Once
    |
Same Result
    |
Do Again
```

---

# Exercise 9

Classify:

* create user
* delete user
* increment counter
* send email

---

# Chapter 101 — Idempotency Keys

Payment APIs solve this using:

```text
idempotency keys
```

Example:

```python
charge(
    amount=100,
    key="abc123"
)
```

Retry:

```python
charge(
    amount=100,
    key="abc123"
)
```

Server returns:

```text
same result
```

instead of charging twice.

---

# Visualization

```text
Request
    |
Key Exists?
   / \
 yes no
 |    |
reuse execute
```

---

# Exercise 10

Design an idempotent payment API.

---

# Chapter 102 — Circuit Breakers

Suppose service B is down.

Service A does:

```text
retry
retry
retry
retry
retry
```

Result:

```text
everything collapses
```

---

Circuit breakers stop this.

States:

```text
CLOSED
OPEN
HALF-OPEN
```

---

# Visualization

```text
Failure Count
       |
Threshold?
     /    \
No       Yes
 |         |
Closed    Open
```

---

Example:

```python
if breaker.is_open():

    raise ServiceUnavailable()

return service.call()
```

---

# Exercise 11

Implement a simple circuit breaker.

---

# Chapter 103 — Bulkheads

Ships have bulkheads.

Why?

Because flooding one compartment should not sink the ship.

---

Software does the same.

Example:

```text
Payment Pool
Notification Pool
Search Pool
Analytics Pool
```

---

If analytics dies:

```text
payments survive
```

---

Visualization:

```text
+----+
|Pay |
+----+

+----+
|Mail|
+----+

+----+
|Logs|
+----+
```

---

# Exercise 12

Design bulkheads for an ecommerce system.

---

# Chapter 104 — Compensating Transactions

Distributed transactions rarely exist.

Instead:

```text
Reserve Inventory
      |
Charge Payment
      |
Book Shipping
```

If shipping fails:

```text
Refund Payment
Release Inventory
```

---

This is:

# Compensation

---

Visualization:

```text
Forward
    |
Inventory
    |
Payment
    |
Shipping
    X
    |
Undo Payment
    |
Undo Inventory
```

---

# Exercise 13

Design compensation for:

```text
Hotel Booking
```

---

# Chapter 105 — Failure Budgets

Professional systems accept failure.

Example:

```text
99.9% uptime
```

Means:

```text
0.1% failure allowed
```

---

Why?

Because:

```text
100% reliability
```

is usually impossible.

---

Examples:

| SLA     | Allowed Downtime |
| ------- | ---------------- |
| 99%     | 3.65 days/year   |
| 99.9%   | 8.7 hours/year   |
| 99.99%  | 52 minutes/year  |
| 99.999% | 5 minutes/year   |

---

# Exercise 14

Calculate annual downtime for:

```text
99.95%
```

---

# Chapter 106 — The Failure Handling Pyramid

```text
Prevent
     |
Detect
     |
Timeout
     |
Retry
     |
Backoff
     |
Circuit Break
     |
Compensate
     |
Recover
```

---

# The Production Failure Lifecycle

```text
Failure
    |
    V
Detect
    |
    V
Classify
    |
    +--- Permanent
    |        |
    |      Abort
    |
    +--- Temporary
             |
             V
         Retry
             |
             V
         Backoff
             |
             V
         Recover
```

---

# The Most Important Diagram In Reliability Engineering

```text
Request
    |
    V
Timeout
    |
    V
Retry
    |
    V
Backoff
    |
    V
Circuit Breaker
    |
    V
Compensation
    |
    V
Recovery
```

---

# Summary

In this article we learned:

✅ transient failures
✅ permanent failures
✅ retries
✅ timeouts
✅ exponential backoff
✅ jitter
✅ idempotency
✅ idempotency keys
✅ circuit breakers
✅ bulkheads
✅ compensating transactions
✅ failure budgets

---

# Conclusion

Most developers think:

> Failure is an exceptional event.

Professional engineers understand:

> **Failure is the normal state of distributed systems.**

Because the question is never:

> "Will this system fail?"

The question is:

> **"When it fails, what happens next?"**

In **Part 9**, we'll dive into production-grade debugging and observability:

* structured logging,
* exception telemetry,
* stack traces,
* correlation IDs,
* distributed tracing,
* postmortems,
* debugging production incidents,
* and how companies like Google and Netflix investigate failures.

Because handling failures is only half the battle.

The other half is understanding why they happened. 🚨
