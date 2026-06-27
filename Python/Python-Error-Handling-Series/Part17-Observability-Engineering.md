# 🚨 Python Error Handling Explained Like a Systems Engineer (Part 17)

# Observability Engineering: Logging, Metrics, Tracing, Correlation IDs, and Why Debugging Evolved into Distributed Forensics

> *"Debugging is what developers do."*
>
> *"Observability is what engineers do when debugging becomes impossible."*

---

# Introduction

Imagine this program:

```python
def process_payment():

    charge_card()

    reserve_inventory()

    send_receipt()
```

The program crashes:

```text
ValueError
```

Easy.

Read the stack trace.

Fix the bug.

---

Now consider:

```text
Browser
    |
API Gateway
    |
Auth Service
    |
Payment Service
    |
Inventory Service
    |
Notification Service
    |
Kafka
    |
Email Service
```

A customer reports:

> "My money was deducted but I never received my order."

Question:

Where is the bug?

Answer:

> You don't know.

Because modern systems don't fail in one place.

They fail:

* across machines,
* across networks,
* across services,
* across time.

Welcome to:

# Observability Engineering

The discipline of reconstructing truth from incomplete evidence.

---

# Chapter 231 — Monitoring Is Not Observability

Many engineers think:

```text
Monitoring = Observability
```

Wrong.

---

Monitoring asks:

> Is something wrong?

Example:

```text
CPU = 95%
```

---

Observability asks:

> Why is it wrong?

Example:

```text
CPU = 95%
because
payment retries increased
because
inventory database slowed
because
replication lag increased
because
network partition occurred
```

---

Visualization:

```text
Monitoring

Metric
   |
Alert


Observability

Metric
   |
Investigation
   |
Explanation
```

---

# Exercise 1

Describe the difference between:

* monitoring,
* debugging,
* observability.

---

# Chapter 232 — The Three Pillars Of Observability

Modern observability uses three signals:

```text
Logs
Metrics
Traces
```

---

Visualization:

```text
System
   |
---------
|   |   |
L   M   T
```

---

Each answers different questions.

| Signal  | Question             |
| ------- | -------------------- |
| Logs    | What happened?       |
| Metrics | How much happened?   |
| Traces  | Where did it happen? |

---

# Exercise 2

Classify:

* stack traces,
* request latency,
* database queries,
* CPU usage.

---

# Chapter 233 — Logging

The oldest observability signal:

```python
print("something broke")
```

---

Professional logging:

```python
import logging

logging.error(
    "payment failed"
)
```

---

Example:

```python
logging.info(
    "user login",
    extra={
        "user_id":123,
        "country":"SG"
    }
)
```

---

Output:

```json
{
    "event":"user login",
    "user_id":123,
    "country":"SG"
}
```

---

Visualization:

```text
Application
     |
     V
    Log
```

---

# Exercise 3

Replace all:

```python
print()
```

with:

```python
logging
```

---

# Chapter 234 — Structured Logging

Bad:

```python
print(
    "user 123 failed"
)
```

---

Good:

```python
logger.error(

    "payment_failed",

    extra={

        "user":123,
        "payment":"abc",
        "amount":100
    }
)
```

---

Why?

Because machines can search:

```json
{
    "payment":"abc"
}
```

but cannot reliably search:

```text
"user abc maybe failed"
```

---

Visualization:

```text
Text Log

"something happened"


Structured Log

{
  event
  user
  amount
}
```

---

# Exercise 4

Convert text logs into JSON logs.

---

# Chapter 235 — Log Levels

Python defines:

```text
DEBUG
INFO
WARNING
ERROR
CRITICAL
```

---

Example:

```python
logging.debug()

logging.info()

logging.warning()

logging.error()

logging.critical()
```

---

Visualization:

```text
DEBUG
  |
INFO
  |
WARN
  |
ERROR
  |
FATAL
```

---

# Exercise 5

Classify:

* user login,
* database timeout,
* disk corruption,
* startup message.

---

# Chapter 236 — Metrics

Metrics answer:

> How many?

Examples:

```text
Requests/sec
Latency
CPU
Memory
Error rate
```

---

Example:

```python
counter += 1
```

---

Visualization:

```text
Request
   |
Counter
```

---

Common metric types:

### Counter

```text
Only increases
```

---

### Gauge

```text
Moves up/down
```

---

### Histogram

```text
Measures distributions
```

---

# Exercise 6

Classify:

* memory,
* login count,
* request duration.

---

# Chapter 237 — Percentiles

Average latency:

```text
100 ms
```

Question:

Good?

Maybe.

---

Example:

```text
99 requests:
1ms

1 request:
10 seconds
```

Average:

```text
101 ms
```

Misleading.

---

Instead:

```text
P50
P95
P99
```

---

Visualization:

```text
P50
 |
P95
 |
P99
```

---

# Exercise 7

Calculate:

* average,
* median,
* p95.

---

# Chapter 238 — Tracing

Question:

Which service is slow?

Answer:

Use traces.

---

Example:

```text
Browser
   |
API
   |
Auth
   |
Payment
   |
Database
```

---

Trace:

```text
API         10ms
Auth        30ms
Payment    500ms
DB         480ms
```

---

Visualization:

```text
Request
    |
Service
    |
Service
    |
Database
```

---

Tracing answers:

> Where did the time go?

---

# Exercise 8

Trace a checkout flow.

---

# Chapter 239 — Spans

A trace contains:

```text
spans
```

Example:

```text
Trace
   |
   +---API
   |
   +---Auth
   |
   +---Payment
```

---

Example:

```json
{
  "span":"payment",
  "duration":"500ms"
}
```

---

Visualization:

```text
Trace
 |
 +---Span
 |
 +---Span
 |
 +---Span
```

---

# Exercise 9

Design spans for:

```text
Food Delivery App
```

---

# Chapter 240 — Correlation IDs

Suppose:

```text
User clicks BUY
```

This creates:

```text
200 logs
100 metrics
50 traces
```

Question:

How do we connect them?

Answer:

# Correlation IDs

---

Example:

```text
request_id:

abc123
```

---

Log:

```json
{
    "request_id":"abc123"
}
```

---

Trace:

```json
{
    "trace_id":"abc123"
}
```

---

Visualization:

```text
Request
   |
abc123
   |
-----------------
|       |       |
Log    Metric Trace
```

---

# Exercise 10

Add correlation IDs to a Flask API.

---

# Chapter 241 — Distributed Tracing

Example:

```text
Frontend
     |
Gateway
     |
Payment
     |
Inventory
     |
Kafka
     |
Email
```

---

One request becomes:

```text
one trace
```

---

Visualization:

```text
TraceID
    |
    +---Gateway
    |
    +---Payment
    |
    +---Inventory
    |
    +---Email
```

---

This allows engineers to reconstruct:

```text
history
```

of a request.

---

# Exercise 11

Design a distributed trace.

---

# Chapter 242 — Sampling

Question:

Should we store:

```text
100 million traces/day?
```

No.

---

Instead:

```text
sample
```

---

Example:

```python
if random() < 0.01:
    trace()
```

---

Visualization:

```text
1000 requests

||||||||||||

↓

10 traces
```

---

# Exercise 12

Calculate sampling rates.

---

# Chapter 243 — OpenTelemetry

Modern observability standard:

# OpenTelemetry

Provides:

* logs,
* metrics,
* traces,
* context propagation.

---

Example:

```python
from opentelemetry import trace

tracer = trace.get_tracer(
    __name__
)
```

---

Visualization:

```text
Application
     |
OpenTelemetry
     |
Backend
```

---

Common backends:

* Jaeger
* Grafana Tempo
* Prometheus
* Grafana

---

# Exercise 13

Instrument a Python API using OpenTelemetry.

---

# Chapter 244 — Observability Is Distributed Forensics

Traditional debugging:

```text
Bug
 |
Debugger
 |
Fix
```

Modern debugging:

```text
Logs
Metrics
Traces
Events
Deployments
Infrastructure
```

---

Visualization:

```text
Incident
    |
Collect Evidence
    |
Correlate
    |
Reconstruct
    |
Explain
```

---

This resembles:

```text
forensics
```

more than:

```text
programming
```

---

# Exercise 14

Perform a post-incident investigation.

---

# Chapter 245 — The Observability Feedback Loop

```text
Deploy
   |
Observe
   |
Detect
   |
Investigate
   |
Understand
   |
Improve
```

---

Without observability:

```text
Failure
   |
Guessing
```

---

With observability:

```text
Failure
   |
Evidence
   |
Explanation
```

---

# The Observability Model

```text
System
   |
Logs
Metrics
Traces
   |
Correlation
   |
Understanding
```

---

# The Incident Investigation Pipeline

```text
Alert
   |
Metrics
   |
Trace
   |
Logs
   |
Root Cause
   |
Fix
```

---

# The Most Important Diagram In Modern Engineering

```text
Request
    |
Trace ID
    |
Logs
Metrics
Traces
    |
Correlation
    |
Explanation
    |
Knowledge
```

---

# Summary

In this article we learned:

✅ monitoring vs observability
✅ logs
✅ structured logging
✅ log levels
✅ metrics
✅ percentiles
✅ traces
✅ spans
✅ correlation IDs
✅ distributed tracing
✅ sampling
✅ OpenTelemetry
✅ observability as forensics

---

# Conclusion

Most developers think:

> Debugging means finding bugs.

Systems engineers understand:

> **Debugging at scale means reconstructing reality from incomplete evidence.**

Because once your system consists of:

* hundreds of services,
* thousands of containers,
* millions of requests,
* billions of events,

you can no longer ask:

> "What happened?"

You must ask:

> **"What is the most likely explanation supported by the available evidence?"**

And that question is no longer about programming.

It is about:

> **observability, inference, and engineering truth under uncertainty.** 🚨
