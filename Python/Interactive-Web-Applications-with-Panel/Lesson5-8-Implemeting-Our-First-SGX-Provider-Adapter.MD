# Part V — Working with Live SGX Market Data

# Lesson 5.8 — Implementing Our First SGX Provider Adapter

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Implement a real provider adapter.
> * Understand how provider classes encapsulate API logic.
> * Learn how to design a provider interface.
> * Understand adapter implementation details.
> * Learn dependency injection.
> * Implement normalization.
> * Add validation and error handling.
> * Add caching support.
> * Integrate providers with `MarketDataService`.
> * Retrieve real SGX market data for the first time.

---

# Introduction

In the previous lesson, we designed our architecture.

Our system now looks like this:

```text
Panel Dashboard

        ↓

MarketDataService

        ↓

MarketProvider Interface

        ↓

Financial Provider
```

Today, we finally begin implementing this architecture.

This lesson is important because we transition from:

> Architecture diagrams

to:

> Actual software engineering.

---

# Step 1 — Choosing Our First Provider

For this tutorial, our requirements are:

| Requirement     | Need       |
| --------------- | ---------- |
| SGX support     | Yes        |
| Historical data | Yes        |
| Free tier       | Preferably |
| Simple API      | Yes        |
| Educational use | Yes        |

Remember:

> The purpose of this lesson is not choosing the perfect provider.

The purpose is learning how to architect providers.

---

# Why We Build an Adapter

Suppose a provider returns:

```json
{
    "symbol": "D05",
    "currentPrice": 41.35
}
```

But our application expects:

```python
{
    "symbol": "D05",
    "price": 41.35
}
```

The adapter acts as a translator.

---

# Visualizing the Adapter

```text
Provider Response

↓

Provider Adapter

↓

Application Model
```

---

# Step 2 — Creating the Provider Interface

Let's define the contract.

```python
# providers/base.py

from abc import ABC, abstractmethod


class MarketProvider(ABC):

    @abstractmethod
    def get_stock(self, symbol):
        pass


    @abstractmethod
    def get_history(self, symbol):
        pass


    @abstractmethod
    def get_news(self, symbol):
        pass
```

---

# Understanding `ABC`

`ABC` stands for:

> Abstract Base Class

It allows us to define interfaces.

---

# What Is an Interface?

An interface specifies:

> What methods must exist,

without specifying:

> How they work.

---

# Real-Life Analogy

Consider a wall socket.

The wall socket defines:

```text
Plug Here
```

It does not care whether electricity comes from:

* solar power
* hydroelectricity
* nuclear power

Interfaces work similarly.

---

# Why Use Abstract Classes?

Without interfaces:

```python
provider.getStock()

provider.stock()

provider.fetchPrice()

provider.lookup()
```

Every provider behaves differently.

Interfaces force consistency.

---

# Step 3 — Creating Our First Provider

Suppose we create:

```text
providers/

    base.py

    sgx_provider.py
```

---

# Creating the Provider Class

```python
# providers/sgx_provider.py

from providers.base import MarketProvider


class SGXProvider(MarketProvider):

    def get_stock(self, symbol):
        pass

    def get_history(self, symbol):
        pass

    def get_news(self, symbol):
        pass
```

Notice that Python forces us to implement every method.

---

# Why This Is Useful

Now our application can say:

```python
provider.get_stock("D05")
```

without caring which provider is being used.

---

# Step 4 — Adding Dependencies

Our provider needs several tools.

```python
import requests
import time
```

Why?

| Library  | Purpose            |
| -------- | ------------------ |
| requests | HTTP communication |
| time     | caching timestamps |

---

# Step 5 — Constructor Injection

Let's create a constructor.

```python
class SGXProvider(MarketProvider):

    def __init__(self, api_key):

        self.api_key = api_key
```

---

# What Is `self`?

Recall:

```python
self
```

refers to:

> the current object instance.

---

# Why Store API Keys?

Suppose we do:

```python
provider = SGXProvider(
    api_key="SECRET"
)
```

The provider remembers the credential.

---

# Visualizing Object State

```text
SGXProvider

├── api_key

├── cache

└── configuration
```

Objects combine:

* data
* behavior

---

# Step 6 — Adding Configuration

Professional applications avoid hardcoding.

Instead:

```python
class SGXProvider(MarketProvider):

    def __init__(

        self,
        api_key,
        base_url
    ):

        self.api_key = api_key
        self.base_url = base_url
```

---

# Why Configuration Matters

Tomorrow:

```text
Old Provider URL

↓

New Provider URL
```

We simply change configuration.

No code changes are required.

---

# Step 7 — Building URLs

Suppose our provider expects:

```text
https://provider.com/stock/D05
```

We construct:

```python
url = (
    f"{self.base_url}/stock/{symbol}"
)
```

---

# Understanding f-Strings

Python f-strings perform string interpolation.

Example:

```python
symbol = "D05"

url = f"/stock/{symbol}"
```

Produces:

```text
/stock/D05
```

---

# Step 8 — Sending Requests

Now we retrieve data.

```python
response = requests.get(
    url,
    timeout=10
)
```

---

# Why Add a Timeout?

Without:

```python
timeout=10
```

our application could freeze indefinitely.

Professional software always uses timeouts.

---

# Step 9 — Checking Status Codes

Never trust the response.

```python
if response.status_code != 200:

    raise Exception(
        "Provider Error"
    )
```

---

# Why Validate?

Suppose the provider returns:

```text
500 Internal Server Error
```

Attempting to parse data would fail.

Validation catches problems early.

---

# Step 10 — Parsing JSON

Now we retrieve the data.

```python
data = response.json()
```

Remember:

```text
JSON

↓

Python Dictionary
```

---

# Example Provider Response

Suppose we receive:

```json
{
    "ticker": "D05",
    "currentPrice": 41.35,
    "companyName": "DBS"
}
```

Unfortunately,

this is not our internal format.

---

# Step 11 — Normalization

We normalize.

```python
normalized = {

    "symbol":
        data["ticker"],

    "price":
        data["currentPrice"],

    "company":
        data["companyName"]
}
```

---

# Why Normalize?

Without normalization:

```text
Dashboard

↓

Provider A Logic

↓

Provider B Logic

↓

Provider C Logic
```

With normalization:

```text
Dashboard

↓

Standard Model
```

Much simpler.

---

# Step 12 — Returning Application Models

Our provider returns:

```python
return {

    "symbol": "D05",

    "price": 41.35,

    "company": "DBS"
}
```

The dashboard now sees:

```text
One Consistent Structure
```

---

# Implementing Error Handling

Real networks fail.

```python
try:

    response = requests.get(
        url,
        timeout=10
    )

except requests.RequestException:

    return None
```

---

# Why Catch Exceptions?

Possible failures include:

* internet outage
* DNS failure
* timeout
* SSL failure
* connection reset

All of these happen in production.

---

# Adding Validation

Suppose the provider returns:

```json
{
    "ticker": "D05"
}
```

Price is missing.

Instead of:

```python
data["currentPrice"]
```

we write:

```python
price = data.get(
    "currentPrice"
)
```

This is defensive programming.

---

# Step 13 — Adding Caching

Suppose users search:

```text
D05
```

ten times.

Without caching:

```text
API

API

API

API
```

---

# Cache Architecture

Instead:

```text
Request

↓

Cache

↓

API
```

---

# Simple Cache Design

```python
self.cache = {}
```

Example:

```python
{
    "D05":
        {...}
}
```

---

# Cache Lookup

Before calling the API:

```python
if symbol in self.cache:

    return self.cache[symbol]
```

---

# Cache Population

After retrieving:

```python
self.cache[symbol] = result
```

Future requests become instantaneous.

---

# Step 14 — Adding Cache Expiration

Stock prices change.

Therefore:

```text
Cache Forever

✗
```

Instead:

```text
Cache

↓

Expire

↓

Refresh
```

---

# Example Cache Structure

```python
self.cache = {

    "D05": {

        "timestamp": 1719450000,

        "data": {
            ...
        }
    }
}
```

---

# Cache Validation

```python
now = time.time()

if now - timestamp < 60:

    return cached_data
```

Meaning:

```text
Reuse Data

↓

For 60 Seconds
```

---

# Step 15 — Integrating With MarketDataService

Our service becomes:

```python
class MarketDataService:

    def __init__(self, provider):

        self.provider = provider
```

---

# What Is Dependency Injection?

Notice:

```python
provider
```

is passed into the constructor.

This technique is called:

> Dependency Injection

---

# Why Use Dependency Injection?

Bad:

```python
service = MarketDataService()

service.provider =
    SGXProvider()
```

Good:

```python
provider = SGXProvider()

service = MarketDataService(
    provider
)
```

The service does not create dependencies.

Dependencies are provided externally.

---

# Visualizing Dependency Injection

```text
Application

↓

Create Provider

↓

Inject Provider

↓

MarketDataService
```

---

# Delegating Work

Our service becomes simple.

```python
def get_stock(
    self,
    symbol
):

    return self.provider.get_stock(
        symbol
    )
```

---

# Complete Architecture

```text
User

↓

Panel

↓

MarketDataService

↓

SGXProvider

↓

HTTP Request

↓

Financial API

↓

JSON

↓

Normalization

↓

Return
```

---

# Why This Architecture Scales

Tomorrow we can add:

```text
YahooProvider

TwelveDataProvider

AlphaVantageProvider

BloombergProvider
```

without changing:

```text
Panel Dashboard
```

---

# Thinking Like a Software Architect

Beginners ask:

> "How do I get stock prices?"

Architects ask:

> "How do I ensure I can change providers five years from now?"

This difference in thinking separates:

```text
Programming
```

from:

```text
Software Engineering
```

---

# Teacher's Notes

> One of the major goals of object-oriented architecture is not code reuse, but change management. Provider adapters exist because external systems are inherently unstable. By isolating that instability behind interfaces and adapters, the rest of the application remains stable.
>
> Another important lesson is that caching, validation, normalization, retries, and error handling are not optional features. They are core architectural responsibilities of a production-quality service layer.

---

# Common Mistakes

## ❌ Mistake 1

Allowing Panel widgets to call APIs directly.

---

## ❌ Mistake 2

Returning raw provider JSON.

---

## ❌ Mistake 3

Hardcoding API URLs.

---

## ❌ Mistake 4

Not implementing caching.

---

## ❌ Mistake 5

Creating dependencies inside service classes.

---

# Summary

In this lesson, you learned:

* Provider adapters isolate external APIs.
* Interfaces enforce consistent contracts.
* Abstract base classes define required methods.
* Providers normalize external data.
* Validation protects applications.
* Caching improves performance.
* Dependency injection reduces coupling.
* `MarketDataService` delegates to providers.
* Proper architecture allows providers to be replaced without affecting the dashboard.

We now have the complete architecture for retrieving market data. The next step is implementing a working SGX provider and displaying our first live stock prices inside our Panel dashboard.

---

# Exercises

## Exercise 1 — Responsibility Mapping

Assign the following tasks:

* build URLs
* call APIs
* cache responses
* normalize JSON
* display prices
* handle retries

to the appropriate component.

---

## Exercise 2 — Draw the Request Flow

Draw the complete flow:

```text
Panel

↓

MarketDataService

↓

Provider

↓

Financial API

↓

Provider

↓

MarketDataService

↓

Panel
```

Explain each stage.

---

## Exercise 3 — Dependency Injection

Explain why this is better:

```python
provider = SGXProvider()

service = MarketDataService(
    provider
)
```

than:

```python
service = MarketDataService()

service.provider =
    SGXProvider()
```

Discuss:

* coupling
* testing
* maintainability

---

# Coming Up Next

In **Lesson 5.9 — Connecting Panel to Live SGX Market Data**, we'll integrate our `MarketDataService` with our Panel dashboard, wire up event callbacks, display real-time stock information, update tables and charts dynamically, manage loading states, handle API failures gracefully, and finally transform our static educational project into a functioning SGX market monitoring application.
