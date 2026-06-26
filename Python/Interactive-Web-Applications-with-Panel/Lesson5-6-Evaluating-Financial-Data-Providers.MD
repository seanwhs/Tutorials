# Part V — Working with Live SGX Market Data

# Lesson 5.6 — Evaluating Financial Data Providers: Choosing APIs for SGX Market Data

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a financial data provider is.
> * Learn why stock market data is not free.
> * Understand the differences between exchanges, brokers, and data vendors.
> * Learn about delayed and real-time market data.
> * Evaluate financial APIs for SGX.
> * Understand API quotas and rate limits.
> * Learn authentication and API keys.
> * Understand vendor lock-in.
> * Design a provider-independent architecture.
> * Choose an appropriate API strategy for our SGX Stock Monitor.

---

# Introduction

So far, we've learned:

* what APIs are
* how HTTP requests work
* how JSON works
* how to parse responses
* how to handle failures

But we still have one major unanswered question:

> Where do we actually get SGX stock data?

This question turns out to be much more complicated than most beginners expect.

Many new developers assume:

```text
Stock Exchange

↓

API

↓

Application
```

Unfortunately,

the real world looks more like this:

```text
Stock Exchange

↓

Market Data Vendors

↓

Financial Platforms

↓

APIs

↓

Applications
```

Understanding this ecosystem is one of the most important lessons in financial software engineering.

---

# What Is a Financial Data Provider?

A financial data provider is a company that collects, processes, and distributes financial market information.

Examples include:

* stock prices
* company information
* financial statements
* news
* analyst ratings
* historical market data
* options data
* currency exchange rates

---

# Real-World Analogy

Suppose you want weather information.

You probably don't build your own weather satellites.

Instead:

```text
Meteorological Agency

↓

Weather Company

↓

Weather App
```

Financial applications work similarly.

---

# Why Not Connect Directly to SGX?

A common beginner question is:

> "Why can't we simply connect directly to the Singapore Exchange?"

The answer is:

Because stock exchanges are designed primarily for:

* brokers
* banks
* institutional investors
* market makers
* trading systems

Not hobby applications.

---

# What SGX Actually Provides

The Singapore Exchange provides:

* trading infrastructure
* market matching engines
* market data feeds
* regulatory systems

These systems are:

* complex
* expensive
* heavily regulated

---

# The Financial Data Ecosystem

The ecosystem usually looks like this:

```text
Singapore Exchange

↓

Licensed Market Vendors

↓

Financial Data Companies

↓

API Providers

↓

Applications
```

Each layer adds value.

---

# Understanding Market Data Vendors

Market data vendors:

* collect exchange feeds
* normalize data
* clean data
* redistribute data
* provide APIs

Examples include:

* Bloomberg
* Refinitiv
* FactSet
* Morningstar
* various API providers

---

# Why Financial Data Is Expensive

Many beginners assume:

```text
Stock Price

↓

Free
```

Unfortunately:

```text
Stock Price

↓

Licensed Asset
```

Market data has economic value.

Exchanges charge fees because:

* infrastructure is expensive
* market data is a commercial product
* redistribution requires licensing

---

# Real-Time vs Delayed Data

One of the most important distinctions is:

## Real-Time Data

```text
Market Trade

↓

Immediately Visible
```

---

## Delayed Data

```text
Market Trade

↓

15 Minutes Later

↓

Visible
```

---

# Why Delayed Data Exists

Exchanges often allow:

```text
Delayed Data

↓

Cheap

or

Free
```

while:

```text
Real-Time Data

↓

Licensed

↓

Expensive
```

---

# Example

Suppose DBS trades at:

```text
09:00 AM

41.35 SGD
```

Real-time feed:

```text
09:00 AM

41.35 SGD
```

Delayed feed:

```text
09:15 AM

41.35 SGD
```

---

# Which Do We Need?

Our dashboard is intended for:

* education
* learning
* visualization
* analysis

Therefore:

```text
Delayed Data

✓ Sufficient
```

We do not need institutional-grade market feeds.

---

# Evaluating API Providers

When evaluating APIs, we should consider:

* cost
* SGX coverage
* reliability
* rate limits
* historical data
* documentation
* authentication
* licensing

---

# Evaluation Criteria

Let's define a scorecard.

| Criteria          | Importance |
| ----------------- | ---------- |
| SGX Coverage      | Very High  |
| Reliability       | Very High  |
| Cost              | High       |
| Documentation     | High       |
| Historical Data   | Medium     |
| Real-Time Support | Medium     |
| Ease of Use       | High       |
| Free Tier         | High       |

---

# Free APIs vs Paid APIs

## Free APIs

Advantages:

```text
Free

Easy To Start

Good For Learning
```

Disadvantages:

```text
Limited Data

Rate Limits

Less Reliable
```

---

## Paid APIs

Advantages:

```text
Reliable

Professional

Real-Time

Support
```

Disadvantages:

```text
Expensive
```

---

# Common Financial APIs

Developers frequently encounter:

* Alpha Vantage
* Twelve Data
* Financial Modeling Prep
* Polygon
* Finnhub
* Yahoo Finance wrappers

Each has different strengths and weaknesses.

---

# The Challenge of SGX Coverage

A major problem for Singapore developers is:

> Many popular financial APIs primarily support US markets.

For example:

```text
NYSE

✓

NASDAQ

✓

SGX

?
```

This makes provider evaluation extremely important.

---

# Understanding API Quotas

Most APIs restrict usage.

Example:

```text
500 Requests

↓

Per Day
```

or:

```text
60 Requests

↓

Per Minute
```

---

# Why Quotas Exist

Without quotas:

```text
One User

↓

Millions Of Requests

↓

Service Failure
```

Quotas ensure fair usage.

---

# Example Quota Problem

Suppose our dashboard refreshes every second.

```text
1 Request/Second

↓

3600 Requests/Hour

↓

86,400 Requests/Day
```

Many free APIs would block us immediately.

---

# Understanding API Keys

Most APIs require:

> API Keys

An API key acts like an identification card.

Example:

```text
Application

↓

API Key

↓

Financial Provider
```

---

# Why API Keys Exist

API keys allow providers to:

* identify users
* enforce quotas
* bill customers
* revoke access
* monitor abuse

---

# Example API Request

Conceptually:

```text
GET /stocks

API-Key: XXXXX
```

The provider checks:

```text
Who are you?

↓

Are you authorized?

↓

How many requests have you used?
```

---

# Never Hardcode API Keys

Beginners often write:

```python
API_KEY = "my_secret_key"
```

This is dangerous.

Reasons include:

* source control exposure
* accidental publication
* credential theft

---

# Better Approach

Store secrets separately.

Example:

```text
Environment Variables

↓

Configuration Layer

↓

Application
```

This improves security.

---

# Vendor Lock-In

Suppose we build:

```text
Dashboard

↓

Specific API
```

Later,

the provider:

* raises prices
* shuts down
* changes endpoints

Now we have a problem.

---

# Example of Vendor Lock-In

Bad architecture:

```text
Panel Widgets

↓

API A
```

Switching providers requires rewriting everything.

---

# Better Architecture

Instead:

```text
Panel

↓

MarketDataService

↓

Provider Adapter

↓

API Provider
```

Now we can swap providers.

---

# Provider Abstraction

Suppose we have:

```python
get_stock()

get_history()

get_news()
```

Internally,

these methods may call:

* Provider A
* Provider B
* Provider C

The dashboard never knows.

---

# Why Abstraction Matters

Today:

```text
Provider A
```

Tomorrow:

```text
Provider B
```

Our dashboard remains unchanged.

This principle is called:

> Abstraction

---

# Designing Our MarketDataService

Our architecture should become:

```text
Dashboard

↓

MarketDataService

↓

Provider Interface

↓

Financial Provider
```

This design provides:

* flexibility
* maintainability
* portability
* reliability

---

# Example Provider Interface

Conceptually:

```python
class MarketDataProvider:

    get_stock()

    get_history()

    get_news()
```

Different providers implement the same interface.

---

# Caching

Financial APIs often impose quotas.

To reduce requests:

```text
API Response

↓

Store Locally

↓

Reuse
```

This technique is called:

> Caching

---

# Example

Suppose the user requests:

```text
D05
```

three times.

Without caching:

```text
API

↓

API

↓

API
```

With caching:

```text
API

↓

Cache

↓

Cache
```

This saves money and improves performance.

---

# Building for Change

Professional engineers assume:

```text
APIs Change
```

Therefore:

* providers may disappear
* pricing may change
* endpoints may change
* quotas may change

Our architecture must survive these changes.

---

# Selecting an API for This Tutorial

For educational purposes, our ideal provider should have:

| Requirement       | Desired   |
| ----------------- | --------- |
| Free Tier         | Yes       |
| SGX Support       | Yes       |
| Historical Data   | Yes       |
| Simple API        | Yes       |
| Documentation     | Excellent |
| Educational Usage | Allowed   |

The exact provider matters less than the architecture we build around it.

---

# Thinking Like a Software Architect

Beginners ask:

> "Which API should I use?"

Professional engineers ask:

> "How do I ensure I can replace the API later?"

This distinction is crucial.

Good architecture survives changes in vendors, technologies, and business requirements.

---

# Teacher's Notes

> One of the biggest mistakes beginners make is tightly coupling their application to a single third-party provider. Third-party services are outside your control. They may change pricing, features, licensing, or availability at any time. Professional software systems isolate external dependencies behind abstraction layers so that they can be replaced with minimal disruption.
>
> Another important lesson is that market data is not simply "data." It is a regulated commercial product with licensing, redistribution, and compliance implications. Financial software engineering involves business and legal constraints in addition to technical constraints.

---

# Common Mistakes

## ❌ Mistake 1

Assuming stock market data is free.

Most market data is licensed.

---

## ❌ Mistake 2

Building directly against one API provider.

Use abstraction layers.

---

## ❌ Mistake 3

Hardcoding API keys.

Store secrets securely.

---

## ❌ Mistake 4

Ignoring API quotas.

Rate limits will eventually occur.

---

## ❌ Mistake 5

Assuming every financial API supports SGX.

Always verify market coverage first.

---

# Summary

In this lesson, you learned:

* Financial data providers distribute market information.
* SGX data usually arrives through intermediaries.
* Real-time market data is often expensive.
* Delayed data is sufficient for educational applications.
* APIs differ in coverage, pricing, quotas, and reliability.
* API keys identify and authenticate applications.
* Vendor lock-in creates long-term maintenance problems.
* Abstraction layers protect applications from provider changes.
* Caching reduces costs and improves performance.
* Professional architectures assume external providers will eventually change.

We now understand how to evaluate market data providers. The next step is implementing our own provider abstraction layer and building the first version of our `MarketDataService`.

---

# Exercises

## Exercise 1 — Compare Providers

Create a comparison table evaluating three hypothetical providers using:

* SGX support
* price
* quotas
* reliability
* historical data
* ease of use

---

## Exercise 2 — Draw the Architecture

Draw the following architecture:

```text
Panel Dashboard

↓

MarketDataService

↓

Provider Interface

↓

Financial API
```

Explain why each layer exists.

---

## Exercise 3 — Vendor Lock-In

Suppose your dashboard directly calls:

```python
requests.get(provider_a_url)
```

Explain:

* why this creates vendor lock-in
* what problems may occur later
* how abstraction solves the problem

---

# Coming Up Next

In **Lesson 5.7 — Designing the `MarketDataService`: Service Layers, Abstraction, and Provider Adapters**, we'll build one of the most important components in our entire SGX Stock Monitor application. You'll learn about service layers, interfaces, adapters, dependency inversion, provider abstraction, caching strategies, and how to design a flexible architecture that allows us to swap financial data providers without changing a single line of Panel user interface code.
