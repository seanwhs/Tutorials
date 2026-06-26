# Part V — Working with Live SGX Market Data

# Lesson 5.4 — Parsing API Responses: Converting JSON into Python Objects

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what happens after an HTTP request succeeds.
> * Learn how Python converts JSON into native objects.
> * Understand the `response.json()` method.
> * Navigate dictionaries and lists returned by APIs.
> * Work with nested JSON structures.
> * Handle missing or invalid fields safely.
> * Normalize API responses into consistent application data.
> * Design a robust `MarketDataService` layer.

---

# Introduction

In the previous lesson, we learned how to send HTTP requests.

Our workflow currently looks like this:

```text
User

↓

Panel Dashboard

↓

MarketDataService

↓

requests.get()

↓

Financial API

↓

HTTP Response
```

But what exactly do we receive?

Suppose the API returns:

```json
{
    "symbol": "D05",
    "company": "DBS Group Holdings",
    "price": 41.35,
    "volume": 2810000
}
```

This information arrives as JSON.

Our application cannot directly display JSON.

Instead, we must convert it into Python objects.

Today's lesson focuses on this critical step.

---

# Revisiting the Request Lifecycle

Recall our complete workflow.

```text
User

↓

Search Button

↓

Callback

↓

MarketDataService

↓

HTTP Request

↓

Financial API

↓

JSON Response

↓

Python Objects

↓

Panel Dashboard
```

Today we focus on:

```text
JSON

↓

Python Objects
```

---

# Understanding the Response Object

Suppose we write:

```python
import requests

response = requests.get(url)
```

The variable:

```python
response
```

contains much more than just stock data.

It contains:

* status code
* headers
* metadata
* response body
* cookies
* timing information

---

# Visualizing the Response Object

```text
Response

├── Status Code

├── Headers

├── Body

└── Metadata
```

The stock information is usually stored inside the response body.

---

# Response Body

Suppose the API returns:

```json
{
    "symbol": "D05",
    "price": 41.35
}
```

Initially,

this is simply text.

```text
"{\"symbol\":\"D05\",\"price\":41.35}"
```

Python must convert this text into actual objects.

---

# Introducing `response.json()`

The easiest way to convert JSON into Python objects is:

```python
data = response.json()
```

This performs:

```text
JSON Text

↓

Python Conversion

↓

Python Object
```

automatically.

---

# Why Is This Useful?

Without `response.json()`,

we would have to manually parse the text.

For example:

```text
Find {

Find :

Find ,

Extract Value

Convert Number
```

This would be extremely tedious.

Fortunately,

the library performs all of this work for us.

---

# What Does `response.json()` Return?

Suppose the API sends:

```json
{
    "symbol": "D05",
    "price": 41.35
}
```

Python converts it into:

```python
{
    "symbol": "D05",
    "price": 41.35
}
```

The result is usually:

* a dictionary
* a list
* or a combination of both

---

# Example 1 — Simple Dictionary

JSON:

```json
{
    "company": "DBS",
    "price": 41.35
}
```

Python:

```python
data = response.json()

print(data)
```

Result:

```python
{
    "company": "DBS",
    "price": 41.35
}
```

This is a normal Python dictionary.

---

# Accessing Values

Once converted,

we use ordinary dictionary syntax.

```python
company = data["company"]

price = data["price"]
```

Nothing special is required.

---

# Visualizing Dictionary Access

```text
Dictionary

├── company

│       DBS

└── price

        41.35
```

Python simply retrieves the requested value.

---

# Example 2 — Nested Objects

Real financial APIs often return nested data.

Example:

```json
{
    "company": {
        "name": "DBS Group Holdings",
        "sector": "Banking"
    }
}
```

Python converts this into:

```python
{
    "company": {
        "name": "DBS Group Holdings",
        "sector": "Banking"
    }
}
```

---

# Accessing Nested Data

To access nested values:

```python
company = data["company"]

name = company["name"]
```

Or:

```python
name = data["company"]["name"]
```

---

# Visualizing Nested Access

```text
Dictionary

↓

company

↓

name

↓

DBS Group Holdings
```

We progressively move deeper into the structure.

---

# Example 3 — Lists

Suppose the API returns:

```json
{
    "history": [
        41.00,
        41.10,
        41.20,
        41.35
    ]
}
```

Python converts it into:

```python
{
    "history": [
        41.00,
        41.10,
        41.20,
        41.35
    ]
}
```

---

# Accessing Lists

We use normal Python indexing.

```python
prices = data["history"]

latest = prices[-1]
```

or:

```python
latest = data["history"][-1]
```

---

# Example 4 — Lists of Dictionaries

This is extremely common in APIs.

JSON:

```json
{
    "stocks": [
        {
            "symbol": "D05",
            "price": 41.35
        },
        {
            "symbol": "U11",
            "price": 30.15
        }
    ]
}
```

---

# Visualizing the Structure

```text
stocks

│

├── stock 1

│      ├── symbol

│      └── price

│

└── stock 2

       ├── symbol

       └── price
```

---

# Accessing List Elements

Example:

```python
stocks = data["stocks"]

first = stocks[0]

price = first["price"]
```

Or:

```python
price = data["stocks"][0]["price"]
```

---

# Real Financial APIs Are Often Deeply Nested

A realistic response may resemble:

```json
{
    "quote": {
        "symbol": "D05",
        "market": {
            "exchange": "SGX",
            "currency": "SGD"
        },
        "price": {
            "current": 41.35,
            "high": 41.60,
            "low": 40.95
        }
    }
}
```

---

# Visualizing Deep Nesting

```text
quote

├── symbol

├── market

│      ├── exchange

│      └── currency

└── price

       ├── current

       ├── high

       └── low
```

Modern APIs frequently use structures like this.

---

# The Problem with Direct Access

Suppose we write:

```python
price = data["quote"]["price"]["current"]
```

What happens if:

```text
price
```

doesn't exist?

Python raises:

```text
KeyError
```

and our application crashes.

---

# Example Failure

Suppose the API returns:

```json
{
    "quote": {}
}
```

Then:

```python
data["quote"]["price"]
```

produces:

```text
KeyError: price
```

This is dangerous.

---

# Safe Access with `get()`

Python dictionaries provide:

```python
dictionary.get()
```

Example:

```python
price = data.get("price")
```

If the key doesn't exist,

Python returns:

```python
None
```

instead of crashing.

---

# Nested Safe Access

Example:

```python
quote = data.get("quote", {})

price = quote.get("price", {})
```

This approach is much safer.

---

# Why Defensive Programming Matters

Real APIs are messy.

Fields may:

* disappear
* change names
* contain null values
* contain invalid values

Professional applications assume data may be incomplete.

---

# Handling Missing Data

Suppose price information is unavailable.

Instead of crashing,

we might write:

```python
price = data.get("price", "N/A")
```

Result:

```text
N/A
```

The dashboard continues functioning.

---

# Normalization

A major responsibility of our `MarketDataService` is:

> **Normalization**

---

# What Is Normalization?

Normalization means:

> converting inconsistent external data into a consistent internal format.

---

# Example

Suppose API A returns:

```json
{
    "price": 41.35
}
```

But API B returns:

```json
{
    "currentPrice": 41.35
}
```

Our dashboard should not care.

Instead:

```text
API

↓

Normalize

↓

Application Format
```

---

# Normalized Output

Regardless of the provider,

our service returns:

```python
{
    "symbol": "D05",
    "price": 41.35
}
```

Now the dashboard always receives the same structure.

---

# Why Normalize?

Without normalization:

```text
Dashboard

↓

API A Logic

↓

API B Logic

↓

API C Logic
```

The dashboard becomes complicated.

With normalization:

```text
Dashboard

↓

MarketDataService

↓

Any API
```

The dashboard stays simple.

---

# Designing Our MarketDataService

Our service layer might perform:

```text
HTTP Request

↓

Status Check

↓

JSON Conversion

↓

Validation

↓

Normalization

↓

Python Dictionary

↓

Return Result
```

Every API response passes through this pipeline.

---

# The Golden Rule

The user interface should never see:

* raw JSON
* HTTP status codes
* API-specific fields
* malformed responses

The service layer handles everything.

---

# Thinking Like a Software Engineer

Beginners often believe:

```text
API

↓

Dashboard
```

Professionals build:

```text
API

↓

Validation

↓

Normalization

↓

Application Model

↓

Dashboard
```

This extra work dramatically improves reliability.

---

# Teacher's Notes

> One of the most important habits professional developers develop is distrust of external systems. External APIs are outside your control. Providers change field names, remove endpoints, return malformed data, and occasionally fail entirely. Robust software assumes that external systems are unreliable and validates all incoming data.
>
> Another key concept introduced in this lesson is normalization. Large software systems rarely expose raw third-party data directly to the rest of the application. Instead, they create an internal representation that remains stable even if external providers change.

---

# Common Mistakes

## ❌ Mistake 1

Accessing nested values directly.

```python
data["quote"]["price"]["current"]
```

This may crash.

---

## ❌ Mistake 2

Allowing raw JSON into the user interface.

Convert and normalize data first.

---

## ❌ Mistake 3

Assuming API fields always exist.

External APIs change.

---

## ❌ Mistake 4

Treating API responses as trustworthy.

Always validate.

---

## ❌ Mistake 5

Coupling the dashboard to a specific API provider.

Normalize responses into a consistent format.

---

# Summary

In this lesson, you learned:

* `response.json()` converts JSON text into Python objects.
* API responses usually become dictionaries, lists, or combinations of both.
* Nested structures require progressively deeper access.
* Direct dictionary access may raise exceptions.
* `.get()` provides safer access to potentially missing fields.
* Real-world APIs often return incomplete or inconsistent data.
* `MarketDataService` performs validation and normalization.
* The dashboard should work only with clean, normalized Python objects.

We can now retrieve and parse market data. The next challenge is handling the fact that real-world networks and APIs fail.

---

# Exercises

## Exercise 1 — Trace the Structure

Given:

```json
{
    "stock": {
        "symbol": "D05",
        "price": {
            "current": 41.35,
            "high": 41.60
        }
    }
}
```

Draw the tree structure and identify how to retrieve:

* symbol
* current price
* daily high

---

## Exercise 2 — Safe vs Unsafe Access

Compare:

```python
data["price"]
```

and

```python
data.get("price")
```

Explain:

* what happens when the key exists
* what happens when the key does not exist
* why professional code prefers one approach

---

## Exercise 3 — Why Normalize?

Suppose two financial APIs return:

```json
{
    "price": 41.35
}
```

and

```json
{
    "currentPrice": 41.35
}
```

Explain how `MarketDataService` should normalize these responses so that the dashboard remains unchanged.

---

# Coming Up Next

In **Lesson 5.5 — Error Handling, Retries, and Resilience: Building Reliable Financial Applications**, we'll explore one of the most important topics in professional software engineering: dealing with failure. You'll learn about network timeouts, connection errors, rate limiting, retries, exponential backoff, graceful degradation, fallback strategies, and defensive programming techniques that prevent our SGX Stock Monitor from crashing when the real world behaves unexpectedly.
