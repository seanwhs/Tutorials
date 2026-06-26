# Part V — Working with Live SGX Market Data

# Lesson 5.7 — Designing the `MarketDataService`: Service Layers, Abstraction, and Provider Adapters

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a service layer is.
> * Learn why applications require architectural layers.
> * Understand separation of concerns.
> * Learn the Provider Adapter pattern.
> * Understand abstraction and interfaces.
> * Learn dependency inversion.
> * Design a provider-independent market data architecture.
> * Understand how caching fits into the service layer.
> * Build the architecture for our SGX Stock Monitor.
> * Think like a software architect rather than just a programmer.

---

# Introduction

So far, our architecture looks like this:

```text
Panel Dashboard

↓

Financial API
```

This seems simple.

Unfortunately, it creates enormous problems.

Suppose our dashboard directly calls:

```python
requests.get(...)
```

inside button callbacks.

What happens when:

* the API changes?
* the provider shuts down?
* we need caching?
* we need retries?
* we need authentication?
* we want to switch providers?

Suddenly, every dashboard component must be rewritten.

This is why professional software systems introduce:

> **Service Layers**

---

# The Problem With Direct API Access

Imagine writing code like this:

```python
def search_stock():

    response = requests.get(...)

    data = response.json()

    price_pane.object = data["price"]
```

At first glance, this seems reasonable.

However, this single function is performing many jobs.

It:

* builds URLs
* sends HTTP requests
* handles failures
* parses JSON
* validates responses
* transforms data
* updates the user interface

This violates one of the most important software engineering principles:

> **Separation of Concerns**

---

# What Is Separation of Concerns?

Separation of concerns means:

> Each part of the system should have one primary responsibility.

---

# Real-Life Analogy

Consider a restaurant.

```text
Customer

↓

Waiter

↓

Kitchen

↓

Chef
```

Imagine if the waiter also:

* cooked food
* cleaned dishes
* managed inventory
* processed payroll

The restaurant would become chaotic.

Software works exactly the same way.

---

# Dividing Responsibilities

Our application should separate responsibilities.

```text
User Interface

↓

Business Logic

↓

Data Access

↓

External Services
```

Each layer performs one task.

---

# Introducing the Service Layer

The service layer sits between:

```text
User Interface

↓

Service Layer

↓

External Systems
```

It acts as an intermediary.

---

# Why Use a Service Layer?

The service layer centralizes:

* API communication
* authentication
* retries
* caching
* validation
* normalization
* business rules

This keeps the user interface simple.

---

# Visualizing Our Architecture

Instead of:

```text
Panel

↓

Financial API
```

we build:

```text
Panel

↓

MarketDataService

↓

Financial API
```

---

# The User Interface Should Not Know

The dashboard should never know:

* API URLs
* authentication methods
* JSON formats
* rate limits
* provider details

The dashboard should simply ask:

```text
Give me DBS stock information.
```

---

# Example

Instead of writing:

```python
requests.get(...)
```

inside Panel,

we write:

```python
market_service.get_stock("D05")
```

This is dramatically simpler.

---

# What Is Abstraction?

Abstraction means:

> hiding complexity behind a simpler interface.

---

# Real-Life Analogy

Consider a television remote.

You press:

```text
Power
```

You do not care about:

* voltage
* transistors
* signal encoding
* hardware protocols

The remote hides complexity.

---

# Our Service Layer Is An Abstraction

Instead of:

```text
HTTP

↓

JSON

↓

Validation

↓

Retry

↓

Parsing
```

the dashboard sees:

```python
get_stock()
```

This is abstraction.

---

# Designing MarketDataService

Let's begin designing our service.

```python
class MarketDataService:

    def get_stock(self, symbol):
        pass

    def get_history(self, symbol):
        pass

    def get_news(self, symbol):
        pass
```

Notice that we expose business operations rather than networking operations.

---

# Why This Is Important

The dashboard thinks in terms of:

```text
Stocks

History

News
```

It does not think in terms of:

```text
URLs

Headers

JSON

HTTP
```

The service layer translates between these worlds.

---

# Example Application Flow

```text
User

↓

Search Button

↓

Dashboard

↓

MarketDataService

↓

Financial Provider

↓

JSON

↓

MarketDataService

↓

Python Objects

↓

Dashboard
```

---

# What Happens If We Change Providers?

Suppose we use:

```text
Provider A
```

today.

Tomorrow:

```text
Provider A

↓

Discontinued
```

Now we must switch to:

```text
Provider B
```

Will our dashboard break?

It shouldn't.

---

# The Provider Adapter Pattern

Professional software introduces another layer.

```text
Dashboard

↓

MarketDataService

↓

Provider Adapter

↓

Financial API
```

---

# What Is an Adapter?

An adapter converts one interface into another.

---

# Real-Life Example

Suppose you travel overseas.

Your laptop plug:

```text
Singapore Plug
```

doesn't fit.

You use:

```text
Power Adapter
```

The adapter translates between systems.

---

# Software Adapters Work Similarly

Suppose:

Provider A returns:

```json
{
    "price": 41.35
}
```

Provider B returns:

```json
{
    "currentPrice": 41.35
}
```

The adapter converts both into:

```python
{
    "price": 41.35
}
```

---

# Visualizing Provider Adapters

```text
Provider A

↓

Adapter A

↓

Standard Format

-----------------

Provider B

↓

Adapter B

↓

Standard Format
```

The dashboard sees only the standard format.

---

# Designing a Provider Interface

We can define a common contract.

```python
class MarketProvider:

    def get_stock(self):
        pass

    def get_history(self):
        pass

    def get_news(self):
        pass
```

This describes what every provider must do.

---

# Why Use Interfaces?

Interfaces allow us to swap implementations.

For example:

```text
MarketProvider

├── YahooProvider

├── TwelveDataProvider

└── AlphaVantageProvider
```

All providers obey the same contract.

---

# Dependency Inversion

This design implements a major software engineering principle:

> Dependency Inversion Principle (DIP)

---

# What Is Dependency Inversion?

Bad architecture:

```text
Dashboard

↓

Specific Provider
```

Good architecture:

```text
Dashboard

↓

Abstraction

↓

Provider
```

We depend on abstractions,

not implementations.

---

# Visualizing Dependency Inversion

Without DIP:

```text
Panel

↓

Yahoo API
```

With DIP:

```text
Panel

↓

MarketProvider

↓

Yahoo API
```

Tomorrow:

```text
Panel

↓

MarketProvider

↓

Another Provider
```

No dashboard changes are required.

---

# Example Architecture

```text
Panel Dashboard

↓

MarketDataService

↓

MarketProvider Interface

↓

YahooProvider
```

or:

```text
Panel Dashboard

↓

MarketDataService

↓

MarketProvider Interface

↓

TwelveDataProvider
```

---

# Adding Caching

Recall that APIs have quotas.

Therefore:

```text
API Response

↓

Cache

↓

Future Requests
```

---

# Where Should Caching Live?

Not here:

```text
Panel

↓

Cache
```

Instead:

```text
Panel

↓

MarketDataService

↓

Cache

↓

Provider
```

The service layer owns caching.

---

# Adding Retries

Similarly:

```text
Panel

↓

Retry Logic
```

is bad.

Instead:

```text
Panel

↓

MarketDataService

↓

Retry Logic
```

The dashboard remains simple.

---

# Adding Validation

Again:

Bad:

```text
Panel

↓

Validate JSON
```

Good:

```text
Panel

↓

MarketDataService

↓

Validation
```

---

# The Service Layer Pipeline

Our service layer now becomes:

```text
Request

↓

Cache

↓

Provider

↓

Retry

↓

Timeout

↓

Validation

↓

Normalization

↓

Return Result
```

This pipeline protects the entire application.

---

# Designing the Internal Workflow

Suppose the user searches:

```text
D05
```

The workflow becomes:

```text
User

↓

Dashboard

↓

MarketDataService

↓

Cache Check

↓

Provider

↓

HTTP Request

↓

JSON

↓

Validation

↓

Normalization

↓

Dashboard
```

---

# Single Responsibility Principle

Our architecture now follows:

> Single Responsibility Principle (SRP)

Each component performs one job.

| Component         | Responsibility      |
| ----------------- | ------------------- |
| Panel             | User interface      |
| MarketDataService | Business logic      |
| Provider          | External API access |
| Cache             | Performance         |
| Validator         | Data correctness    |

---

# Why This Matters

Imagine a bug in:

```text
JSON Parsing
```

Where do we look?

Without architecture:

```text
Everywhere
```

With architecture:

```text
MarketDataService
```

Good architecture reduces debugging complexity.

---

# Thinking Like a Software Architect

Beginners design:

```text
Feature

↓

Feature

↓

Feature
```

Architects design:

```text
Responsibility

↓

Abstraction

↓

Boundary

↓

Dependency
```

The goal is not merely to make software work.

The goal is to make software changeable.

---

# Proposed SGX Stock Monitor Architecture

```text
Panel Dashboard

        ↓

MarketDataService

        ↓

MarketProvider Interface

        ↓
 ┌─────────────┬─────────────┬─────────────┐
 │             │             │
Yahoo      TwelveData   FutureProvider
Provider     Provider      Provider
 │             │             │
 API           API           API
```

This architecture can survive future changes.

---

# Teacher's Notes

> One of the defining characteristics of professional software engineering is the recognition that requirements always change. Beginners often optimize for getting the current feature working. Architects optimize for minimizing the cost of future changes. Service layers, interfaces, and dependency inversion exist primarily to reduce the cost of change.
>
> Another important observation is that abstractions are not about hiding code. They are about hiding volatility. We introduce abstractions around components that are likely to change, such as external APIs, databases, and third-party services.

---

# Common Mistakes

## ❌ Mistake 1

Calling APIs directly from Panel callbacks.

---

## ❌ Mistake 2

Coupling the dashboard to one provider.

---

## ❌ Mistake 3

Mixing validation, networking, and UI code.

---

## ❌ Mistake 4

Ignoring abstraction layers.

---

## ❌ Mistake 5

Designing only for today's requirements.

---

# Summary

In this lesson, you learned:

* Service layers separate business logic from the user interface.
* Separation of concerns improves maintainability.
* Abstraction hides implementation complexity.
* Provider adapters normalize different APIs.
* Interfaces enable provider substitution.
* Dependency inversion reduces coupling.
* Caching, retries, and validation belong in the service layer.
* Good architecture optimizes for future change.
* Our `MarketDataService` becomes the central integration point for all financial data.

We now have the architecture for our SGX Stock Monitor. The next step is implementing our first concrete provider adapter and retrieving actual SGX stock market data.

---

# Exercises

## Exercise 1 — Responsibility Assignment

Assign each responsibility to the correct component:

* display stock price
* send HTTP request
* cache responses
* validate JSON
* normalize data
* render charts

---

## Exercise 2 — Draw the Architecture

Draw:

```text
Panel

↓

MarketDataService

↓

MarketProvider

↓

Financial API
```

Then explain why each layer exists.

---

## Exercise 3 — Provider Replacement

Suppose:

```text
YahooProvider
```

is replaced by:

```text
NewProvider
```

Explain why the dashboard code does not need to change.

---

# Coming Up Next

In **Lesson 5.8 — Implementing Our First SGX Provider Adapter**, we'll build our first real `MarketProvider` implementation. You'll learn how to structure provider classes, authenticate requests, retrieve SGX stock data, normalize responses, implement caching, and integrate the provider into our `MarketDataService`, finally allowing our Panel dashboard to display live Singapore stock market information.
