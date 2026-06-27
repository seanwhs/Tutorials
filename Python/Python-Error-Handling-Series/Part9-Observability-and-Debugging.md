# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 9)

# Logging, Tracebacks, Observability, and How Production Engineers Actually Debug Failures

> *"Junior developers ask: 'How do I catch the exception?'*
>
> *Senior engineers ask: 'How will I investigate this failure at 3 AM six months from now?'"*

---

# Introduction

Consider this code:

```python
try:
    payment()
except Exception:
    print("payment failed")
```

Looks harmless.

Until you deploy it.

At 2:47 AM, your monitoring system alerts:

```text
Checkout failures increased by 500%
```

Question:

What failed?

```text
Unknown.
```

Where did it fail?

```text
Unknown.
```

Which user?

```text
Unknown.
```

Which server?

```text
Unknown.
```

Can you reproduce it?

```text
Unknown.
```

Congratulations.

You have entered:

# Production Debugging Hell

This is why professional systems spend enormous effort on:

* logging,
* tracebacks,
* observability,
* tracing,
* telemetry,
* diagnostics,
* postmortems.

Because:

> **An exception that cannot be investigated might as well not have been caught.**

---

# Chapter 107 — Why `print()` Is Not Logging

Most beginners start with:

```python
try:
    payment()

except Exception as e:
    print(e)
```

Problem:

```text
Where was it printed?
```

Unknown.

```text
When?
```

Unknown.

```text
Which request?
```

Unknown.

```text
Which server?
```

Unknown.

---

Example:

```python
print("error")
```

produces:

```text
error
```

Professional engineers need:

```text
timestamp
severity
service
request id
user id
hostname
stack trace
metadata
```

---

# Exercise 1

List everything missing from:

```python
print(error)
```

---

# Chapter 108 — Enter Logging

Python provides:

```python
import logging
```

---

Example:

```python
import logging

logging.error(
    "payment failed"
)
```

Output:

```text
ERROR:root:payment failed
```

---

Better:

```python
import logging

logging.basicConfig(
    level=logging.INFO
)

logging.info(
    "starting payment"
)
```

---

# Logging Levels

```text
DEBUG
INFO
WARNING
ERROR
CRITICAL
```

---

# Visualization

```text
DEBUG
   |
INFO
   |
WARNING
   |
ERROR
   |
CRITICAL
```

---

# Exercise 2

Write examples for all five logging levels.

---

# Chapter 109 — Logging Exceptions Correctly

Bad:

```python
try:
    payment()
except Exception as e:
    logging.error(e)
```

---

Output:

```text
connection refused
```

That's it.

You lost:

* traceback,
* stack,
* location,
* context.

---

Correct:

```python
try:
    payment()

except Exception:

    logging.exception(
        "payment failed"
    )
```

Output:

```text
payment failed

Traceback:
...
```

---

# Rule

Use:

```python
logging.exception()
```

inside:

```python
except
```

blocks.

---

# Exercise 3

Compare:

```python
logging.error()
```

versus:

```python
logging.exception()
```

---

# Chapter 110 — Understanding Tracebacks

Example:

```python
def c():
    1/0

def b():
    c()

def a():
    b()

a()
```

Output:

```text
Traceback:

a()
b()
c()

ZeroDivisionError
```

---

Remember:

Tracebacks are:

> **reverse call stacks.**

---

Visualization:

Execution:

```text
a
|
b
|
c
```

Traceback:

```text
c
|
b
|
a
```

---

# Exercise 4

Predict traceback order:

```python
main()
service()
repository()
database()
```

---

# Chapter 111 — Capturing Tracebacks

Python provides:

```python
import traceback
```

---

Example:

```python
try:
    dangerous()

except:

    traceback.print_exc()
```

---

Or:

```python
trace = traceback.format_exc()

print(trace)
```

---

Output:

```text
Traceback...
```

stored as a string.

---

Useful for:

* databases,
* APIs,
* monitoring systems,
* logging infrastructure.

---

# Exercise 5

Store a traceback in a variable.

---

# Chapter 112 — Structured Logging

Bad:

```python
logging.error(
    "payment failed"
)
```

---

Better:

```python
logging.error(
    "payment failed",
    extra={
        "user": 123,
        "order": 456,
        "amount": 99
    }
)
```

---

Best:

```json
{
  "timestamp":"...",
  "service":"payment",
  "user_id":123,
  "order_id":456,
  "error":"timeout"
}
```

---

Why?

Machines can search:

```text
JSON
```

Humans cannot search:

```text
English paragraphs
```

---

# Exercise 6

Convert:

```python
print("login failed")
```

into structured logging.

---

# Chapter 113 — Correlation IDs

Suppose:

```text
Frontend
    |
API
    |
Payment
    |
Database
```

Request fails.

Question:

Which logs belong together?

---

Solution:

```text
Correlation ID
```

Example:

```text
request:
abc123
```

---

Every service logs:

```text
request_id=abc123
```

---

Visualization:

```text
Frontend
   |
abc123
   |
API
   |
abc123
   |
Payment
```

---

# Exercise 7

Add:

```python
request_id
```

to your logs.

---

# Chapter 114 — Distributed Tracing

Logging answers:

```text
What happened?
```

Tracing answers:

```text
Where did it happen?
```

---

Example:

```text
Frontend
    |
50ms
    |
API
    |
200ms
    |
Payment
    |
800ms
    |
Database
```

---

Now we know:

```text
Database slow
```

---

Visualization:

```text
Request
    |
    +--- frontend 20ms
    |
    +--- api 50ms
    |
    +--- payment 300ms
    |
    +--- db 800ms
```

---

# Exercise 8

Draw a trace for:

```text
checkout
```

service.

---

# Chapter 115 — Spans

Distributed traces are composed of:

```text
spans
```

Example:

```text
Request Span
      |
      +--- API Span
      |
      +--- Payment Span
      |
      +--- Database Span
```

---

A span contains:

```text
start
end
duration
metadata
error
```

---

Example:

```json
{
  "span":"database",
  "duration":500,
  "error":"timeout"
}
```

---

# Exercise 9

Define spans for:

```text
login process
```

---

# Chapter 116 — Exception Telemetry

Professional systems collect:

```text
exception type
message
stack trace
host
service
user
request id
timestamp
version
git commit
```

---

Example:

```json
{
  "exception":
    "TimeoutError",

  "service":
    "payment",

  "version":
    "2.3.1",

  "request":
    "abc123"
}
```

---

This allows:

* debugging,
* analytics,
* incident response.

---

# Exercise 10

Design telemetry for:

```text
checkout failure
```

---

# Chapter 117 — Postmortems

Suppose production crashed.

Bad response:

```text
Who caused this?
```

Professional response:

```text
How did the system allow this?
```

---

Good postmortems contain:

* timeline,
* root cause,
* contributing factors,
* blast radius,
* remediation,
* prevention.

---

Example:

```text
12:01 deploy
12:04 latency spike
12:07 retries explode
12:11 database overload
12:14 outage
```

---

# Exercise 11

Write a postmortem for:

```text
payment outage
```

---

# Chapter 118 — Root Cause Analysis

Problem:

```text
Website down
```

Why?

```text
Database unavailable
```

Why?

```text
Connection pool exhausted
```

Why?

```text
Retries exploded
```

Why?

```text
Circuit breaker disabled
```

---

This is called:

# Five Whys

---

Visualization:

```text
Failure
   |
Why?
   |
Why?
   |
Why?
   |
Why?
   |
Root Cause
```

---

# Exercise 12

Perform a Five Whys analysis for:

```text
shopping cart outage
```

---

# Chapter 119 — Error Budgets And Alerting

Not every error deserves a page.

Example:

```text
0.01% failures
```

Maybe acceptable.

---

Example:

```text
40% failures
```

Wake everyone up.

---

Professional systems define:

```text
SLI
SLO
SLA
Error Budget
```

---

Example:

```text
SLO:
99.9%
```

Budget:

```text
0.1%
```

---

# Exercise 13

Calculate error budget for:

```text
1 million requests/day
99.95% reliability
```

---

# Chapter 120 — Observability Is Not Monitoring

Monitoring asks:

```text
Did the system fail?
```

Observability asks:

```text
Why did the system fail?
```

---

# Monitoring

```text
CPU
Memory
Disk
Errors
```

---

# Observability

```text
Logs
Metrics
Traces
Events
Exceptions
```

---

Visualization:

```text
Observability

      Logs
        |
Metrics-+-Traces
        |
    Exceptions
```

---

# The Three Pillars Of Observability

```text
Logs
  |
Metrics
  |
Traces
```

---

Examples:

* Prometheus
* Grafana
* OpenTelemetry
* Jaeger
* Sentry

---

# The Production Incident Lifecycle

```text
Failure
    |
Detect
    |
Alert
    |
Investigate
    |
Root Cause
    |
Fix
    |
Deploy
    |
Postmortem
    |
Prevent
```

---

# The Most Important Diagram In Production Engineering

```text
Exception
     |
     V
Log
     |
     V
Trace
     |
     V
Telemetry
     |
     V
Investigation
     |
     V
Root Cause
     |
     V
Prevention
```

---

# Summary

In this article we learned:

✅ logging
✅ logging levels
✅ `logging.exception()`
✅ tracebacks
✅ structured logging
✅ correlation IDs
✅ distributed tracing
✅ spans
✅ telemetry
✅ postmortems
✅ root-cause analysis
✅ observability

---

# Conclusion

Most developers think:

> Error handling ends when you catch the exception.

Professional engineers understand:

> Error handling only begins when the exception is caught.

Because the real question isn't:

> "Can I handle this error?"

The real question is:

> **"Can I explain this error to another engineer at 3 AM, six months from now, using only the evidence my system preserved?"**

In **Part 10**, we'll conclude the series by building a **production-grade error handling architecture**:

* exception boundaries,
* layered exception design,
* domain exceptions,
* anti-corruption layers,
* resilient service architecture,
* fault containment,
* and how companies like Netflix, Google, and Amazon architect systems around the assumption that **everything eventually fails**. 🚨
