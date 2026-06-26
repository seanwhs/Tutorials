# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.7 — Performance Engineering: Caching, Memoization, Virtualization, Asynchronous Updates, and Scaling Panel Applications

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why dashboard performance matters.
> * Learn where Panel applications become slow.
> * Master caching and memoization.
> * Understand lazy evaluation.
> * Learn virtualization techniques.
> * Implement asynchronous processing.
> * Build scalable real-time dashboards.
> * Optimize browser rendering.
> * Understand enterprise dashboard architecture.
> * Think like a performance engineer rather than a dashboard developer.

---

# Introduction

Most beginner Panel applications look like this:

```python
dashboard = pn.Column(

    controls,

    chart,

    table
)
```

and perform perfectly.

Then one day management says:

> Connect this dashboard to live SGX market feeds.

Suddenly:

* 1000 stocks
* 500 charts
* 50 tables
* live updates
* multiple users

must run simultaneously.

And the dashboard becomes:

```text
Very Slow
```

---

# The First Rule Of Performance Engineering

> Computers are fast.

But:

```text
Data

+

Networks

+

Browsers

+

Humans
```

are slow.

---

# Where Does Time Go?

Most developers believe:

```text
Python
```

is the bottleneck.

Usually it isn't.

---

# Typical Dashboard Costs

| Operation          | Cost      |
| ------------------ | --------- |
| Python calculation | Tiny      |
| Database query     | Medium    |
| API call           | Large     |
| Browser rendering  | Huge      |
| Network transfer   | Huge      |
| DOM update         | Very Huge |

---

# Example

Suppose:

```python
price = get_price()
```

takes:

```text
2 ms
```

But:

```text
Browser Render
```

takes:

```text
150 ms
```

---

# The Real Bottleneck

In most dashboards:

```text
Browser Rendering
```

is the enemy.

---

# Example

Suppose:

```text
10000 Rows
```

must be displayed.

---

# Developer Thinking

```text
10000 Rows

=

Easy
```

---

# Browser Thinking

```text
10000 DOM Objects

=

Panic
```

---

# Understanding Performance Layers

```text
Application

↓

Python

↓

Network

↓

Serialization

↓

Browser

↓

DOM

↓

GPU
```

---

# Performance Engineering Means

Optimizing:

* computation
* communication
* rendering

simultaneously.

---

# Understanding Caching

Suppose we calculate:

```python
calculate_rsi("D05")
```

---

# First Execution

```text
Calculate

↓

Return Result
```

---

# Second Execution

Normally:

```text
Calculate Again
```

---

# Better

```text
Cache

↓

Reuse Result
```

---

# Example

```python
from functools import cache

@cache
def calculate_rsi(symbol):

    ...
```

---

# Visualizing

```text
Function Call

↓

Cache?

├── Yes → Return
└── No  → Compute
```

---

# Why Caching Matters

Suppose:

```text
100 Users
```

request:

```text
DBS RSI
```

Without cache:

```text
100 Calculations
```

---

# With cache:

```text
1 Calculation
```

---

# Understanding Memoization

Memoization means:

> Remember previous results.

---

# Example

```python
from functools import lru_cache

@lru_cache
def expensive_function():

    ...
```

---

# Visualizing

```text
Input

↓

Lookup

↓

Result
```

---

# Example

First call:

```python
compute(100)
```

takes:

```text
2 seconds
```

---

# Second call:

```python
compute(100)
```

takes:

```text
0 milliseconds
```

---

# Why Financial Systems Use Memoization

Examples:

* moving averages
* RSI
* MACD
* portfolio risk
* covariance matrices

are expensive.

---

# Example

Without cache:

```text
1000 Users

×

100 ms
```

---

# With cache:

```text
1 User

×

100 ms
```

---

# Understanding Lazy Evaluation

Suppose:

```text
500 Charts
```

exist.

Do we render:

```text
500 Charts?
```

---

# Wrong Answer

```text
Yes
```

---

# Correct Answer

```text
Only Visible Charts
```

---

# Visualizing

```text
Dashboard

├── Visible
├── Visible
├── Hidden
├── Hidden
└── Hidden
```

---

# Why Lazy Evaluation Works

Users only view:

```text
One Small Part
```

of dashboards at a time.

---

# Example

Bad:

```python
for chart in charts:

    chart.render()
```

---

# Better:

```python
render_when_visible()
```

---

# Understanding Virtualization

Suppose:

```text
100000 Rows
```

exist.

---

# Traditional Rendering

```text
100000 DOM Nodes
```

---

# Browser Response

```text
No.
```

---

# Virtualization

Render:

```text
Only Visible Rows
```

---

# Example

User sees:

```text
Rows 100-120
```

Render:

```text
21 Rows
```

instead of:

```text
100000 Rows
```

---

# Visualizing

Without virtualization:

```text
100000 Rows

↓

Browser Crash
```

---

# With virtualization:

```text
20 Rows

↓

Smooth
```

---

# Financial Applications Depend On Virtualization

Examples:

* order books
* trades
* market history
* portfolio positions
* audit logs

---

# Example

```text
10 Million Trades
```

displayed as:

```text
30 Visible Rows
```

---

# Understanding Browser Rendering Cost

Suppose:

```text
1000 Widgets
```

exist.

Each update causes:

```text
DOM Recalculation
```

---

# Visualizing

```text
Widget Change

↓

Layout Engine

↓

Paint Engine

↓

GPU
```

---

# Browser Rendering Is Expensive

Sometimes:

```text
1 DOM Update

>

1000 Python Operations
```

---

# Reducing DOM Updates

Bad:

```python
price.value = 10

price.value = 11

price.value = 12
```

---

# Better:

```python
price.value = 12
```

once.

---

# Understanding Batch Updates

Suppose:

```text
1000 Stocks
```

update.

---

# Bad

```text
1000 Browser Messages
```

---

# Better

```text
1 Batch Message
```

---

# Visualizing

Bad:

```text
Update

Update

Update

Update
```

---

# Better:

```text
Batch

↓

Update
```

---

# Asynchronous Programming

Suppose:

```python
get_market_data()
```

takes:

```text
5 seconds
```

---

# Traditional Programming

```text
Wait

Wait

Wait
```

---

# Async Programming

```text
Start Task

↓

Continue Working
```

---

# Example

```python
import asyncio

async def get_data():

    ...
```

---

# Why Async Matters

Suppose:

```text
10 APIs
```

must be queried.

---

# Sequential

```text
1 sec × 10

=

10 sec
```

---

# Parallel

```text
1 sec

=

1 sec
```

---

# Example

```python
results = await asyncio.gather(

    api1(),

    api2(),

    api3()
)
```

---

# Visualizing

Sequential:

```text
A

↓

B

↓

C
```

---

# Async:

```text
A
B
C

↓

Result
```

---

# Real-Time Dashboards

Suppose SGX sends:

```text
10000 Messages/Sec
```

---

# Bad Architecture

```text
Feed

↓

UI

↓

Feed

↓

UI
```

---

# Better Architecture

```text
Feed

↓

Buffer

↓

Aggregator

↓

UI
```

---

# Example

Instead of:

```text
10000 Updates/Sec
```

display:

```text
10 Updates/Sec
```

---

# Humans Cannot See Faster Anyway

Human perception:

```text
≈10 FPS
```

---

# Therefore

Updating:

```text
1000 FPS
```

is wasteful.

---

# Understanding Debouncing

Suppose user types:

```text
S
SG
SGX
```

---

# Without Debouncing

```text
API

API

API
```

---

# With Debouncing

```text
Wait

↓

Single API Call
```

---

# Example

```text
Typing...

↓

Pause

↓

Search
```

---

# Understanding Throttling

Suppose:

```text
1000 Events
```

arrive.

---

# Throttling:

```text
Allow

10 Events
```

---

# Visualizing

```text
1000 Updates

↓

Throttle

↓

10 Updates
```

---

# Memory Optimization

Suppose:

```text
1 Million Rows
```

exist.

---

# Bad

```python
everything = dataframe
```

---

# Better

```python
window = dataframe.tail(100)
```

---

# Streaming Windows

Financial systems often maintain:

```text
Sliding Windows
```

---

# Example

Keep:

```text
Latest 1000 Trades
```

rather than:

```text
Entire History
```

---

# Performance Monitoring

Professional applications measure:

* latency
* throughput
* memory
* rendering
* network traffic

---

# Example Metrics

```text
API: 50 ms

Calculation: 10 ms

Render: 200 ms

Total: 260 ms
```

---

# Why Measurement Matters

Without measurement:

```text
Optimization

=

Guessing
```

---

# Example

Many developers optimize:

```text
10 ms Python
```

while ignoring:

```text
500 ms Browser
```

---

# Enterprise Dashboard Architecture

```text
User

↓

Browser

↓

Panel

↓

Cache

↓

Analytics

↓

Database

↓

Market Feed
```

---

# Multi-Level Caching

```text
Browser Cache

↓

Application Cache

↓

Database Cache
```

---

# Example

```text
SGX Feed

↓

Redis Cache

↓

Analytics

↓

Panel
```

---

# Scaling To Multiple Users

Suppose:

```text
1000 Users
```

connect.

---

# Bad

```text
1000 Calculations
```

---

# Better

```text
1 Calculation

↓

1000 Broadcasts
```

---

# Professional Dashboard Strategy

```text
Compute Once

Reuse Everywhere
```

---

# Performance Pyramid

```text
Avoid Work

↓

Cache Work

↓

Batch Work

↓

Parallelize Work

↓

Optimize Work
```

---

# Why This Order Matters

Most developers do:

```text
Optimize
```

first.

Professionals do:

```text
Avoid
```

first.

---

# Example

Bad:

```python
optimize(
    huge_algorithm
)
```

---

# Better:

```text
Don't Run

Huge Algorithm
```

---

# Thinking Like A Performance Engineer

Beginners ask:

> How can I make this faster?

Intermediate developers ask:

> Which algorithm is faster?

Performance engineers ask:

> Why am I doing this work at all?

Because the fastest code is:

```text
Code That Never Executes.
```

---

# The Hidden Secret

Large-scale dashboard engineering is mostly:

```text
Avoiding Work
```

rather than:

```text
Performing Work Efficiently.
```

---

# Teacher's Notes

> One of the biggest misconceptions in software engineering is that performance problems are primarily algorithmic problems. In reality, performance problems are often architectural problems.
>
> Another important lesson is that optimization should occur only after measurement. Guessing performance bottlenecks almost always leads to optimizing the wrong thing.

---

# Common Mistakes

## ❌ Mistake 1

Rendering everything.

---

## ❌ Mistake 2

Ignoring browser costs.

---

## ❌ Mistake 3

Updating too frequently.

---

## ❌ Mistake 4

Avoiding caching.

---

## ❌ Mistake 5

Optimizing before measuring.

---

# Summary

In this lesson, you learned:

* Browser rendering is often the bottleneck.
* Caching eliminates repeated computation.
* Memoization stores previous results.
* Lazy evaluation avoids unnecessary work.
* Virtualization reduces rendering costs.
* Async programming improves throughput.
* Debouncing and throttling reduce event storms.
* Batch updates improve performance.
* Performance requires measurement.
* Enterprise systems optimize architecture before algorithms.

You now understand the performance engineering principles used by professional real-time dashboard systems.

---

# Exercises

## Exercise 1 — Design A Caching Strategy

Design caching layers for:

```text
SGX Trading Dashboard
```

including:

* market data
* indicators
* portfolios
* analytics

---

## Exercise 2 — Optimize A Dashboard

Given:

```text
100 Charts

100 Tables

1000 Widgets
```

identify:

* caching opportunities
* virtualization opportunities
* async opportunities

---

## Exercise 3 — Design A Real-Time Architecture

Design a dashboard capable of processing:

```text
100000 Market Updates/Sec
```

using:

* buffering
* throttling
* batching
* caching
* async processing

---

# Coming Up Next

In **Lesson 6.8 — Deployment Architecture: Bokeh Server, Panel Serve, FastAPI Integration, Docker, Reverse Proxies, Authentication, and Production Panel Systems**, we'll learn how professional Panel applications are deployed into production environments, including cloud deployments, authentication systems, containers, reverse proxies, and enterprise architecture patterns.
