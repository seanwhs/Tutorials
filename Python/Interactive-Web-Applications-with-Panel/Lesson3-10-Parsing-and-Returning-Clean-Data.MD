# Part III — Working with Real SGX Market Data

# Lesson 3.10 — Completing the `MarketDataService`: Parsing and Returning Clean Data

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Complete the implementation of the `MarketDataService`.
> * Understand the complete lifecycle of an API request.
> * Convert HTTP responses into Python objects.
> * Validate API responses before using them.
> * Normalize raw API data into a consistent structure.
> * Return clean application data instead of raw JSON.
> * Understand why service layers transform external data.
> * Prepare the service for integration with our Panel dashboard.

---

# Introduction

In the previous lesson, our `MarketDataService` learned how to communicate with a financial API.

The workflow currently looks like this.

```text
Panel

↓

MarketDataService

↓

HTTP Request

↓

Financial API

↓

HTTP Response
```

But we're not finished.

Receiving an HTTP response is only the beginning.

The response is still:

* Raw
* Unvalidated
* API-specific
* Unsuitable for the rest of our application

Today's lesson completes the service.

By the end,

our service will return clean,

consistent Python dictionaries that the rest of our application can use immediately.

---

# The Complete Journey of a Stock Request

Let's review everything we've learned so far.

```text
User

↓

Search Button

↓

MarketDataService

↓

HTTP Request

↓

Financial API

↓

HTTP Response

↓

JSON

↓

Python Dictionary

↓

Validated Data

↓

Normalized Data

↓

Panel Dashboard
```

Notice how much work happens before the UI sees anything.

---

# Why Not Return Raw JSON?

Suppose the API returns

```json
{
    "symbol": "D05",
    "companyName": "DBS Group Holdings",
    "lastPrice": 41.35,
    "currencyCode": "SGD",
    "tradeVolume": 3250000
}
```

Should our dashboard use these names?

Probably not.

What happens if another API returns

```json
{
    "ticker": "D05",
    "name": "DBS",
    "price": 41.35,
    "volume": 3250000
}
```

Now every screen in our application must understand multiple formats.

That's a maintenance nightmare.

---

# The Goal of Normalization

Instead,

our service converts every response into one standard format.

Regardless of the API,

the rest of our application always receives:

```python
{
    "symbol": "...",
    "company": "...",
    "price": "...",
    "currency": "...",
    "volume": "..."
}
```

This process is called **normalization**.

---

# What Is Normalization?

Normalization means

> **Converting different data formats into one consistent structure.**

Think about electrical power adapters.

Different countries use different plug shapes.

An adapter converts them into one format your laptop understands.

Our service acts as an adapter between financial APIs and our application.

---

# The Parsing Workflow

Inside

```python
get_stock(symbol)
```

the workflow now becomes

```text
Receive Response

↓

Check Status

↓

Parse JSON

↓

Validate Fields

↓

Normalize Data

↓

Return Dictionary
```

Each step has a purpose.

---

# Step 1 — Check the HTTP Status

Before reading any data,

confirm the request succeeded.

Conceptually,

```text
Status Code

↓

200 ?

↓

Yes → Continue

↓

No → Handle Error
```

Never assume success.

---

# Step 2 — Parse the JSON

Once the response is valid,

convert it into Python objects.

```python
data = response.json()
```

Now,

instead of working with HTTP,

we're working with dictionaries and lists.

---

# Step 3 — Inspect the Structure

Professionals rarely guess.

Instead,

they inspect.

For example,

during development,

they might temporarily write

```python
from pprint import pprint

pprint(data)
```

This reveals exactly what the API returned.

Only after understanding the structure do they begin extracting fields.

---

# Step 4 — Extract the Required Information

Suppose the response contains

```python
{
    "symbol": "D05",
    "companyName": "DBS Group Holdings",
    "lastPrice": 41.35,
    "currencyCode": "SGD",
    "tradeVolume": 3250000,
    "exchange": "SGX",
    "marketCap": 90000000000,
    "industry": "Banking"
}
```

Our dashboard doesn't display everything.

It only needs

* Company
* Symbol
* Price
* Currency
* Volume

Everything else can remain inside the service.

---

# Step 5 — Create a Clean Dictionary

Instead of returning the entire response,

create a simplified version.

Conceptually,

```python
stock = {

    ...

}
```

This new dictionary contains only the fields our application requires.

Notice something important.

The service is no longer merely downloading data.

It is transforming data.

---

# Why Transformation Matters

Imagine changing API providers next year.

Only this transformation code changes.

The Panel dashboard continues receiving exactly the same dictionary.

This dramatically reduces maintenance.

---

# Validation Before Returning

Suppose the API forgot to include the price.

Should we return

```python
{
    "price": None
}
```

Maybe.

Or perhaps we should reject the response entirely.

This depends on our application.

The important point is:

The service makes this decision,

not the user interface.

---

# The UI Receives Clean Data

After all the processing,

our dashboard receives something predictable.

```python
stock = {

    "symbol": "D05",

    "company": "DBS Group Holdings",

    "price": 41.35,

    "currency": "SGD",

    "volume": 3250000

}
```

The dashboard no longer needs to understand APIs.

---

# Separating External Data from Internal Data

Notice the difference.

External data

↓

Controlled by someone else.

Internal data

↓

Controlled by us.

Our service converts external data into internal data.

This is one of its most important responsibilities.

---

# The Service as a Translator

Imagine speaking English in Japan.

A translator sits between both people.

```text
English

↓

Translator

↓

Japanese
```

Neither person changes languages.

The translator performs the conversion.

Similarly,

our service translates API responses into application objects.

---

# The Finished Architecture

Our application now looks like this.

```text
+---------------------------+
|      Panel Dashboard      |
+-------------+-------------+
              |
              |
              ▼
+---------------------------+
|    MarketDataService      |
|                           |
| HTTP Request              |
| JSON Parsing              |
| Validation                |
| Normalization             |
+-------------+-------------+
              |
              |
              ▼
+---------------------------+
|   Financial Data API      |
+---------------------------+
```

Notice how each layer has a clear responsibility.

---

# Why This Architecture Scales

Suppose we later add:

* Historical prices
* Company news
* Financial statements
* Dividends
* ESG ratings

The dashboard doesn't need to know where the data comes from.

Every feature simply asks the service.

This makes future expansion much easier.

---

# Thinking Like an Engineer

Beginners often celebrate when they successfully retrieve JSON.

Professional developers celebrate when the rest of the application **doesn't care** where the data came from.

That is good architecture.

The less your UI knows about external systems,

the easier your software becomes to maintain.

---

# Teacher's Notes

> One subtle but important design decision is that the `MarketDataService` returns **application data**, not **API data**. These are not the same thing. API responses belong to the external provider and may change without notice. Application data belongs to us, and we control its structure. This separation protects the rest of the application from external changes.
>
> Another useful habit is to think of every service as a boundary. Data entering the boundary should be validated and normalized before it leaves. Once data crosses that boundary, the rest of the application should be able to trust its structure.

---

# Common Mistakes

## ❌ Mistake 1

Returning raw API responses directly to the Panel application.

Always normalize the data first.

---

## ❌ Mistake 2

Making the UI understand API field names.

Field mapping belongs inside the service.

---

## ❌ Mistake 3

Skipping validation.

Never assume an external API always returns complete or correct data.

---

## ❌ Mistake 4

Returning unnecessary information.

Only return what the application actually needs.

---

## ❌ Mistake 5

Thinking parsing is the final step.

Parsing converts JSON into Python.

Normalization converts Python objects into application data.

These are different responsibilities.

---

# Summary

In this lesson, you learned:

* A complete API workflow consists of downloading, parsing, validating, transforming, and returning data.
* `response.json()` converts HTTP responses into Python dictionaries and lists.
* Services should inspect and validate external data before using it.
* Normalization converts provider-specific responses into a consistent application format.
* The `MarketDataService` acts as a translator between external APIs and the rest of the application.
* The Panel dashboard receives clean, predictable Python dictionaries without needing to understand HTTP or JSON.
* Separating external data from internal application data makes software more maintainable and resilient to API changes.

At this point, our `MarketDataService` is conceptually complete. It knows how to communicate with financial APIs, validate responses, normalize data, and return clean application objects.

The next stage of the tutorial begins connecting this service to our Panel user interface so users can search for stocks, display live market information, and interact with the application through a professional dashboard.

---

# Exercises

## Exercise 1 — Identify the Transformation Steps

Draw a flowchart showing the complete lifecycle of a stock request from the moment the user clicks **Search** until the Panel dashboard displays the result.

Identify which component performs each step.

---

## Exercise 2 — Raw vs Normalized Data

Given the following API response:

```python
{
    "ticker": "D05",
    "name": "DBS Group Holdings",
    "lastPrice": 41.35,
    "currencyCode": "SGD",
    "tradeVolume": 3250000
}
```

Design the normalized dictionary that your application should use.

Explain why each field was renamed.

---

## Exercise 3 — Why Normalize?

Imagine your application currently supports API Provider A.

Next month,

your company decides to switch to API Provider B.

Explain:

* Which file(s) should require modification?
* Which parts of the application should remain unchanged?
* Why does this architectural design make the migration easier?

---

# Coming Up Next

In **Part IV — Building the Panel User Interface**, we'll shift our focus from backend services to frontend development. You'll learn the fundamentals of **Panel**, including panes, widgets, layouts, reactive programming, and event handling. Starting with a blank application, we'll gradually build a professional SGX Stock Monitor interface that communicates with the `MarketDataService`, allowing users to search for stocks, view live prices, and explore market data through an interactive dashboard. This marks the point where all the concepts from the previous parts come together into a complete, working application.
