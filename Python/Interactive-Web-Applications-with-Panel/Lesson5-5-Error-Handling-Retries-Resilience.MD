# Part V — Working with Live SGX Market Data

# Lesson 5.5 — Error Handling, Retries, and Resilience: Building Reliable Financial Applications

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why failures are normal in distributed systems.
> * Learn the different types of network and API failures.
> * Understand exceptions in Python.
> * Learn defensive programming techniques.
> * Understand retry strategies.
> * Learn exponential backoff.
> * Understand graceful degradation.
> * Learn timeout strategies.
> * Build a resilient `MarketDataService`.
> * Think like a production software engineer.

---

# Introduction

So far, our SGX Stock Monitor has worked perfectly.

Our mental model looks like this.

```text
User

↓

Dashboard

↓

MarketDataService

↓

Financial API

↓

Stock Data

↓

Dashboard
```

Unfortunately,

the real world doesn't work this way.

Real systems fail.

Constantly.

Consider the following situations.

```text
Internet disconnects.

API server crashes.

API responds slowly.

API rate limit exceeded.

Stock symbol not found.

JSON malformed.

DNS unavailable.

Authentication expired.
```

Every one of these situations occurs regularly in production systems.

Today's lesson introduces one of the most important ideas in software engineering:

> **Building software that continues working even when things go wrong.**

---

# Failure Is Normal

Beginners often think:

```text
Success

↓

Success

↓

Success

↓

Success
```

Professional engineers think:

```text
Failure

↓

Failure

↓

Success

↓

Failure

↓

Retry

↓

Success
```

This difference in mindset is fundamental.

---

# The Fallacy of Perfect Networks

Suppose we write:

```python
price = api.get_price("D05")
```

A beginner might assume:

```text
Call API

↓

Receive Price

↓

Done
```

In reality:

```text
Call API

↓

Network Failure

↓

Retry

↓

Timeout

↓

Retry

↓

Server Recovery

↓

Receive Price
```

Networks are unreliable.

Always.

---

# Understanding Exceptions

When something goes wrong,

Python raises an

> **Exception**

An exception is simply Python's way of saying:

> "I cannot continue normally."

---

# Example

```python
1 / 0
```

Produces:

```text
ZeroDivisionError
```

Similarly,

network operations may raise exceptions.

---

# Common Networking Exceptions

Examples include:

```text
ConnectionError

Timeout

HTTPError

RequestException

SSLError

TooManyRedirects
```

These represent different failure conditions.

---

# Visualizing Exceptions

```text
Normal Flow

↓

Problem Occurs

↓

Python Raises Exception

↓

Program Must Decide

    Recover?

    Retry?

    Stop?
```

---

# Why Exceptions Exist

Imagine if Python silently ignored errors.

```python
price = api.get_price("D05")
```

might return:

```python
None
```

without explanation.

Finding bugs would become nearly impossible.

Exceptions force us to handle failures explicitly.

---

# Exception Handling

Python provides:

```python
try:
    ...

except:
    ...
```

This means:

```text
Attempt Operation

↓

If Failure Occurs

↓

Handle Failure
```

---

# Example

```python
try:

    response = requests.get(url)

except Exception:

    print("Request failed")
```

This prevents the application from crashing.

---

# Visualizing Try/Except

Success:

```text
Try

↓

Success

↓

Continue
```

Failure:

```text
Try

↓

Exception

↓

Except

↓

Recovery
```

---

# Why Not Catch Everything?

Beginners often write:

```python
except:
    pass
```

This is dangerous.

It means:

```text
Ignore Every Problem
```

Imagine ignoring:

* authentication failures
* network failures
* corrupted data

The application might appear to work while actually being broken.

---

# Understanding Timeouts

Consider this scenario.

```text
Dashboard

↓

API Request

↓

Server Never Responds
```

Without protection:

```text
Wait Forever
```

This is unacceptable.

---

# Setting Timeouts

Professional software always sets timeouts.

Example:

```python
requests.get(
    url,
    timeout=10
)
```

Meaning:

```text
Wait Maximum

↓

10 Seconds
```

---

# Why Timeouts Matter

Suppose:

```text
User Searches DBS

↓

Server Crashes

↓

Application Freezes

↓

User Closes Application
```

Timeouts prevent this experience.

---

# Different Types of Failure

Failures generally fall into several categories.

| Failure        | Example                   |
| -------------- | ------------------------- |
| Network        | Internet unavailable      |
| DNS            | Server address unresolved |
| Timeout        | Server too slow           |
| Authentication | Invalid API key           |
| Rate Limit     | Too many requests         |
| Server         | Internal API error        |
| Data           | Invalid JSON              |

Each type requires different handling.

---

# Understanding Rate Limiting

Financial APIs often restrict usage.

Example:

```text
Maximum

↓

100 Requests

↓

Per Minute
```

If exceeded:

```text
429 Too Many Requests
```

---

# Why APIs Rate Limit

Without rate limits:

```text
Bad Client

↓

Millions Of Requests

↓

Server Collapse
```

Rate limiting protects infrastructure.

---

# Handling Rate Limits

Suppose we receive:

```text
429
```

Should we immediately retry?

No.

Instead:

```text
Wait

↓

Retry Later
```

---

# The Retry Pattern

Temporary failures often disappear.

Example:

```text
Request

↓

Failure

↓

Retry

↓

Success
```

This is called:

> **Retry Logic**

---

# Example Retry Flow

```text
Attempt 1

↓

Failure

↓

Attempt 2

↓

Failure

↓

Attempt 3

↓

Success
```

Many production systems work this way.

---

# Why Not Retry Forever?

Suppose:

```text
Server Down

↓

Retry

↓

Retry

↓

Retry

↓

Retry

↓

Retry
```

This never ends.

Unlimited retries create additional problems.

---

# Bounded Retries

Professional systems limit retries.

Example:

```text
Maximum Retries

↓

3
```

After that:

```text
Return Error
```

---

# Fixed Delay Retries

Simple retry logic:

```text
Fail

↓

Wait 1 Second

↓

Retry
```

This works,

but creates another problem.

---

# The Retry Storm Problem

Imagine:

```text
10,000 Applications

↓

All Fail

↓

All Retry Simultaneously
```

The server becomes overloaded.

---

# Exponential Backoff

Instead,

systems use:

> **Exponential Backoff**

---

# Example

```text
Retry 1

↓

Wait 1 Second

Retry 2

↓

Wait 2 Seconds

Retry 3

↓

Wait 4 Seconds

Retry 4

↓

Wait 8 Seconds
```

This reduces server pressure.

---

# Visualizing Exponential Backoff

```text
1

↓

2

↓

4

↓

8

↓

16
```

The delay grows exponentially.

---

# Why Exponential Backoff Works

Suppose a server is temporarily overloaded.

Giving it more time to recover increases the probability of success.

This strategy is used throughout:

* cloud computing
* databases
* distributed systems
* financial systems

---

# Graceful Degradation

Suppose news retrieval fails.

Should the entire dashboard crash?

Absolutely not.

Instead:

```text
Price

✓

Chart

✓

News

✗
```

The dashboard continues functioning.

This is called:

> **Graceful Degradation**

---

# Example

Instead of:

```text
APPLICATION ERROR
```

show:

```text
News temporarily unavailable.
```

The user can still continue working.

---

# Partial Failure

Distributed systems often experience:

> **Partial Failure**

Example:

```text
Stock Price

✓

History

✓

News

✗
```

Not everything fails simultaneously.

Professional software handles each component independently.

---

# Fallback Values

Suppose volume information is unavailable.

Instead of:

```text
ERROR
```

display:

```text
N/A
```

or:

```text
Unavailable
```

Fallback values improve reliability.

---

# Circuit Breakers (Conceptual)

Large systems often use:

> **Circuit Breakers**

---

# Real-Life Analogy

Consider a home's electrical circuit breaker.

```text
Too Much Current

↓

Breaker Trips

↓

Protect House
```

Software systems do something similar.

---

# Circuit Breaker Flow

```text
API Failing

↓

Stop Sending Requests

↓

Wait

↓

Test Recovery

↓

Resume Service
```

This prevents overwhelming failing systems.

---

# Defensive Programming

Professional developers assume:

```text
Everything Can Fail
```

Therefore they:

* validate input
* validate output
* validate network responses
* validate JSON
* validate business rules

This philosophy is called:

> **Defensive Programming**

---

# Building a Resilient MarketDataService

Our service layer might perform:

```text
Request

↓

Timeout

↓

Retry

↓

Validate Status

↓

Parse JSON

↓

Validate Data

↓

Normalize

↓

Return Result
```

Every stage protects the application.

---

# Example Failure Pipeline

```text
Request

↓

Timeout

↓

Retry

↓

Success

↓

JSON Invalid

↓

Fallback Value

↓

Dashboard Continues
```

Notice how failure never crashes the application.

---

# Our Dashboard Architecture

```text
Panel Dashboard

↓

MarketDataService

    ↓

    Retry

    Timeout

    Validation

    Normalization

    Error Handling

↓

Financial API
```

The dashboard remains simple.

The service layer handles complexity.

---

# Thinking Like a Production Engineer

Beginners optimize for:

```text
Happy Path
```

Professionals optimize for:

```text
Failure Path
```

Because in production,

failure paths occur every day.

---

# Teacher's Notes

> One of the most important transitions in a developer's career occurs when they stop assuming that systems work and start assuming that systems fail. This mindset shift fundamentally changes how software is designed. Production engineering is largely the discipline of managing failure rather than avoiding it entirely.
>
> Another key lesson is that resilience is achieved through layers of protection. Timeouts alone are insufficient. Retries alone are insufficient. Validation alone is insufficient. Reliable systems emerge when multiple defensive mechanisms work together.

---

# Common Mistakes

## ❌ Mistake 1

Assuming network requests always succeed.

They do not.

---

## ❌ Mistake 2

Not using timeouts.

Applications may freeze indefinitely.

---

## ❌ Mistake 3

Retrying forever.

Retries should always have limits.

---

## ❌ Mistake 4

Crashing the entire dashboard because one API call failed.

Use graceful degradation.

---

## ❌ Mistake 5

Ignoring exceptions.

All external systems can fail.

---

# Summary

In this lesson, you learned:

* Failure is normal in distributed systems.
* Python uses exceptions to signal errors.
* Network requests require exception handling.
* Timeouts prevent applications from hanging indefinitely.
* Financial APIs often impose rate limits.
* Retry logic helps recover from temporary failures.
* Exponential backoff reduces server overload.
* Graceful degradation allows applications to continue operating during partial failures.
* Defensive programming improves reliability.
* Our `MarketDataService` acts as the resilience layer for the entire dashboard.

We now know how to communicate safely with financial APIs. The next step is choosing and integrating actual financial data providers that support SGX market data.

---

# Exercises

## Exercise 1 — Identify Failure Points

Consider:

```text
Dashboard

↓

API Request

↓

Internet

↓

Financial API

↓

JSON

↓

Dashboard
```

List every stage where failure may occur.

---

## Exercise 2 — Retry Strategy

Suppose an API fails twice before succeeding.

Draw the sequence of:

* requests
* failures
* retry delays
* final success

using exponential backoff.

---

## Exercise 3 — Graceful Degradation

Suppose your dashboard contains:

* current price
* historical chart
* company news
* analyst ratings

If the analyst rating API fails, explain how the dashboard should continue operating.

---

# Coming Up Next

In **Lesson 5.6 — Evaluating Financial Data Providers: Choosing APIs for SGX Market Data**, we'll investigate the practical challenge of sourcing Singapore stock market data. You'll learn about free versus paid financial APIs, delayed versus real-time market feeds, API quotas, authentication, reliability, licensing restrictions, and how to architect `MarketDataService` so that your SGX Stock Monitor can switch providers without requiring changes to the user interface.
