# Building TickerHub

## Part 33: Building the Observability, Telemetry & Distributed Tracing Platform — Making Distributed Systems Explain Themselves

> One of the first lessons every production engineer learns is:
>
> ```text
> Every system works perfectly
> until it doesn't.
> ```
>
> The second lesson is:
>
> ```text
> If you cannot explain
> why it failed,
> you do not have
> a production system.
> ```

At this point, TickerHub contains:

* market feeds,
* event buses,
* order books,
* portfolios,
* risk engines,
* news systems,
* alert engines,
* background workers,
* asynchronous services.

Unfortunately, distributed systems introduce a new problem:

```text
Everything is happening
everywhere
all at once.
```

---

# The Beginner View of Debugging

Most developers debug using:

```python
print("here")
print("there")
print("why?")
```

or:

```python
try:
    ...
except:
    print("error")
```

This works.

Until:

* multiple servers,
* multiple services,
* asynchronous workers,
* message queues,
* retries,
* caching,
* event streams.

Then:

```text
Debugging
```

becomes:

```text
Forensic Investigation
```

---

# The Three Pillars of Observability

Modern distributed systems rely on:

```text
Metrics

+

Logs

+

Traces
```

---

# Metrics Answer

```text
What is happening?
```

Example:

```text
CPU:
82%

Latency:
35 ms

Users:
2150
```

---

# Logs Answer

```text
What happened?
```

Example:

```text
09:01:03

Price Update

D05

41.25
```

---

# Traces Answer

```text
Why did it happen?
```

---

# Example Problem

User clicks:

```text
BUY
```

---

Five seconds later:

```text
Order rejected
```

Question:

```text
Why?
```

---

Possible path:

```text
Panel

↓

FastAPI

↓

Order Service

↓

Kafka

↓

Risk Service

↓

Portfolio Service

↓

Database

↓

Response
```

---

Without tracing:

```text
Good Luck
```

---

With tracing:

```text
You Know Exactly
```

what happened.

---

# Observability Architecture

```text
Panel
   |
   V

FastAPI
   |
   V

Services
   |
   V

Workers
   |
   V

OpenTelemetry
   |
   V

Metrics
Logs
Traces
```

---

# Why Observe Everything?

Because distributed systems fail through:

```text
Interactions
```

rather than:

```text
Components
```

---

# Logging Architecture

Create:

```text
infrastructure/

    logging.py
```

---

Initialize:

```python
import logging
```

---

Configure:

```python
logging.basicConfig(

    level=logging.INFO
)
```

---

Create:

```python
logger = logging.getLogger(
    "tickerhub"
)
```

---

# Why Not print()?

Because logs require:

```text
Timestamp

Severity

Context

Source

Correlation
```

---

Example Log

```text
2026-06-26
09:15:02

INFO

MarketService

D05 updated
41.20
```

---

# Structured Logging

Bad:

```python
print(
    "price updated"
)
```

---

Good:

```python
logger.info(

    "price_update",

    extra={

        "symbol":"D05",

        "price":41.20
    }
)
```

---

# Why Structured Logs?

Because machines can search:

```text
JSON
```

but not:

```text
English
```

---

Example

```json
{
    "service":"market",

    "symbol":"D05",

    "price":41.2,

    "timestamp":"..."
}
```

---

# Metrics

Question:

```text
How healthy
is the system?
```

---

Examples:

```text
CPU

Memory

Latency

Errors

Queue Depth

Feed Rate
```

---

# Metrics Service

Create:

```text
infrastructure/

    metrics.py
```

---

Define:

```python
class Metrics:
```

---

Track:

```python
feed_count = 0
```

---

Track:

```python
error_count = 0
```

---

Track:

```python
latencies = []
```

---

# Example

Record:

```python
metrics.feed_count += 1
```

---

Measure:

```python
start = time.time()
```

---

Process:

```python
...
```

---

Record:

```python
latency = (
    time.time() - start
)
```

---

# Service Level Indicators

Professional systems define:

```text
SLIs
```

---

Examples:

```text
Latency

Availability

Throughput

Correctness
```

---

# Service Level Objectives

Example:

```text
99.9%

requests

under

50 ms
```

---

Question:

```text
Did we achieve it?
```

---

# Market Feed Metrics

Measure:

```text
Ticks/sec
```

---

Example:

```text
35,000
ticks/sec
```

---

Measure:

```text
Feed Delay
```

---

Example:

```text
15 ms
```

---

# Kafka Metrics

Measure:

```text
Messages/sec
```

---

Measure:

```text
Consumer Lag
```

---

Example:

```text
Lag:
5000
```

---

Question:

```text
Are consumers
falling behind?
```

---

# Redis Metrics

Measure:

```text
Cache Hits
```

---

Example:

```text
95%
```

---

Measure:

```text
Memory Usage
```

---

# PostgreSQL Metrics

Measure:

```text
Connections
```

---

Measure:

```text
Query Latency
```

---

Measure:

```text
Lock Waits
```

---

# Panel Metrics

Measure:

```text
Sessions
```

---

Measure:

```text
Users
```

---

Measure:

```text
WebSocket Count
```

---

# Risk Metrics

Measure:

```text
VaR Compute Time
```

---

Example:

```text
4 ms
```

---

Measure:

```text
Risk Queue Size
```

---

# Tracing

Question:

```text
What path
did this request take?
```

---

Example:

```text
BUY
```

---

Create:

```text
Trace
```

---

Example:

```text
trace_id:

ABC123
```

---

# Child Spans

Create:

```text
Panel
```

↓

```text
FastAPI
```

↓

```text
OrderSvc
```

↓

```text
RiskSvc
```

↓

```text
PortfolioSvc
```

---

Each creates:

```text
Span
```

---

# Example Trace

```text
TRACE:

ABC123

Panel:
5 ms

FastAPI:
2 ms

Order:
4 ms

Risk:
50 ms

Database:
3 ms
```

---

Problem:

```text
Risk
```

---

Solution:

```text
Optimize Risk Engine
```

---

# OpenTelemetry

Professional systems use:

```text
OpenTelemetry
```

---

Install:

```bash
pip install opentelemetry-sdk
```

---

Create tracer:

```python
from opentelemetry import trace
```

---

Initialize:

```python
tracer = trace.get_tracer(
    "tickerhub"
)
```

---

Create span:

```python
with tracer.start_as_current_span(
    "risk"
):
```

---

Execute:

```python
calculate_var()
```

---

# Correlation IDs

Every event gets:

```text
request_id
```

and:

```text
trace_id
```

---

Example:

```text
D05

trace:

ABC123
```

---

Question:

```text
What happened
to this event?
```

---

Answer:

```text
Everything
```

---

# Health Checks

Create:

```text
/health
```

endpoint.

---

Return:

```json
{
    "database":"ok",

    "redis":"ok",

    "kafka":"ok"
}
```

---

# Liveness Checks

Question:

```text
Is the process alive?
```

---

Example:

```text
200 OK
```

---

# Readiness Checks

Question:

```text
Can it serve traffic?
```

---

Example:

```text
Kafka unavailable
```

---

Return:

```text
503
```

---

# Dashboard

Display:

```text
CPU

Memory

Users

Latency

Errors
```

---

Example:

```text
CPU:
34%

Memory:
4.2GB

Latency:
22ms
```

---

# Error Dashboard

Display:

```text
Top Errors
```

---

Example:

```text
Risk Timeout:
142

Kafka Error:
27
```

---

# Event Replay

Question:

```text
Can we reconstruct
yesterday?
```

---

Store:

```text
Events
```

---

Replay:

```text
Timeline
```

---

Result:

```text
System Reconstruction
```

---

# Root Cause Analysis

Question:

```text
Why did the system fail?
```

---

Investigate:

```text
Trace
```

↓

```text
Logs
```

↓

```text
Metrics
```

---

Find:

```text
Root Cause
```

---

# Observability Pipeline

```text
Applications
        |
        V

OpenTelemetry
        |
        +------ Metrics
        |
        +------ Logs
        |
        +------ Traces
        |
        V

Storage
        |
        V

Dashboards
```

---

# Why Observability Matters

Because production failures are usually:

```text
Unknown Unknowns
```

---

The question is not:

```text
Will the system fail?
```

The question is:

```text
Can we explain
why it failed?
```

---

# Architecture Lesson #33

Beginners think:

```text
Logging
    =
Debugging
```

Professionals think:

```text
Observability
    =
The ability
to reconstruct
the complete history
of a distributed system
after reality diverges
from expectations
```

---

# Current Architecture

```text
Panel
        |
        V

FastAPI
        |
        V

Services
        |
        V

Workers
        |
        V

OpenTelemetry
        |
        +------ Metrics
        |
        +------ Logs
        |
        +------ Traces
        |
        V

Observability Platform
```

TickerHub now contains:

✅ Structured logging

✅ Metrics

✅ SLIs

✅ SLOs

✅ Distributed tracing

✅ Correlation IDs

✅ Health checks

✅ Readiness checks

✅ Event replay

✅ Root cause analysis

✅ OpenTelemetry

✅ Full observability

At this point, TickerHub no longer resembles a financial application.

It resembles:

```text
A Self-Describing Distributed System
capable of explaining,
measuring,
and reconstructing
its own behavior
across time,
space,
and failure.
```

---

# In Part 34

We will build the **Historical Market Data Lake & Time-Series Analytics Platform**, where you'll discover that professional trading systems are not designed merely to:

```text
Observe the present
```

but to:

```text
Store,
compress,
query,
and learn
from decades
of market history.
```
