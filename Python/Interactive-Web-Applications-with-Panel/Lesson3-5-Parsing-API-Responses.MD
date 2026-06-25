# Part III — Working with Real SGX Market Data

# Lesson 3.5 — Parsing Real API Responses

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what it means to parse an API response.
> * Learn a systematic approach to exploring unfamiliar JSON structures.
> * Extract useful stock information from API responses.
> * Use dictionary methods safely.
> * Handle missing or incomplete data.
> * Validate API responses before using them.
> * Separate raw API data from application data.
> * Prepare to build a reusable Market Data Service.

---

# Introduction

In the previous lesson, we learned how APIs return data using JSON.

We also learned that

```python
response.json()
```

converts JSON into normal Python objects.

For example,

```python
data = response.json()
```

might produce

```python
{
    "company": "DBS",
    "price": 41.35
}
```

That's useful.

But real APIs are rarely this simple.

Today's lesson teaches one of the most valuable skills every software developer needs:

> **Learning how to understand and extract information from unfamiliar API responses.**

---

# What Does "Parsing" Mean?

The word **parse** appears everywhere in programming.

Beginners often think it means something complicated.

It doesn't.

Parsing simply means:

> **Reading structured information and extracting the parts you need.**

Imagine receiving this document.

```text
Company: DBS

Price: 41.35

Currency: SGD

Volume: 3,200,000
```

You don't need the entire document.

Perhaps you only need

```text
Price
```

Extracting that value is parsing.

---

# Parsing Is Like Reading a Form

Imagine completing a registration form.

```text
Name

Address

Phone

Email

Age
```

A receptionist doesn't memorize the entire form.

Instead,

they extract the required fields.

Programs do exactly the same thing.

---

# Why Parsing Matters

Our API might return

50 pieces of information.

Our dashboard only displays

* Company Name
* Stock Symbol
* Current Price
* Daily Change
* Volume

Everything else can be ignored.

Parsing allows us to retrieve only what we need.

---

# Step 1 — Never Guess the Structure

One of the biggest beginner mistakes is writing code before understanding the data.

Suppose someone tells you

> "The API returns stock information."

Should you immediately write

```python
data["price"]
```

No.

You don't even know if the API uses the key

```text
price
```

It might use

```text
lastPrice
```

or

```text
current_price
```

Always inspect the response first.

---

# Step 2 — Print the Entire Response

When working with a new API,

the first thing professionals do is

```python
print(data)
```

or

```python
from pprint import pprint

pprint(data)
```

The goal is simple.

Understand the structure.

Don't start extracting values yet.

---

# Why Use `pprint`?

Python includes a module called

```python
pprint
```

which stands for

> Pretty Print

Instead of displaying everything on one long line,

it formats nested dictionaries and lists neatly.

Example:

```python
from pprint import pprint

pprint(data)
```

Output becomes much easier to read.

---

# A Sample Response

Suppose our API returns

```python
{
    "symbol": "D05",
    "companyName": "DBS Group Holdings",
    "currency": "SGD",
    "market": "SGX",
    "price": {
        "current": 41.35,
        "open": 41.10,
        "high": 41.60,
        "low": 41.00
    },
    "volume": 3250000
}
```

At first,

this may look intimidating.

Let's break it down.

---

# Looking for the Top-Level Keys

The first question is

> **What keys exist?**

We identify

```text
symbol

companyName

currency

market

price

volume
```

These are our entry points.

---

# Notice Something Interesting

The value of

```text
price
```

isn't a number.

Instead,

it's another dictionary.

```python
"price": {
    "current": 41.35,
    "open": 41.10,
    "high": 41.60,
    "low": 41.00
}
```

This means we must go one level deeper.

---

# Navigating the Structure

Visualizing helps.

```text
Dictionary

├── symbol

├── companyName

├── currency

├── market

├── price

│      ├── current

│      ├── open

│      ├── high

│      └── low

└── volume
```

Now the hierarchy is clear.

---

# Extracting Values

Suppose we want the company name.

```python
company = data["companyName"]
```

Current price

```python
price = data["price"]["current"]
```

Volume

```python
volume = data["volume"]
```

Notice that each level is accessed separately.

---

# Think Before You Code

Professionals don't memorize JSON.

Instead,

they ask themselves:

1. What is the current object?
2. What keys does it contain?
3. Which key leads to the value I want?

This simple process prevents many errors.

---

# What If a Key Doesn't Exist?

Suppose we write

```python
price = data["lastPrice"]
```

but the API actually contains

```python
"current"
```

Python raises an error.

```text
KeyError
```

Our application crashes.

Not ideal.

---

# A Safer Approach

Instead of

```python
data["price"]
```

we can write

```python
data.get("price")
```

The `get()` method returns the value if the key exists.

If it doesn't,

it returns

```python
None
```

instead of raising an exception.

---

# Example

```python
company = data.get("companyName")
```

If the key exists

```text
DBS Group Holdings
```

is returned.

If it doesn't,

```python
None
```

is returned.

No crash occurs.

---

# Providing a Default Value

We can even specify a default.

```python
price = data.get("price", {})
```

Meaning

> If `"price"` doesn't exist,

use an empty dictionary instead.

---

Another example

```python
currency = data.get("currency", "Unknown")
```

If the API doesn't provide a currency,

our application displays

```text
Unknown
```

instead of crashing.

---

# Parsing Nested Data Safely

Consider

```python
price = data["price"]["current"]
```

What if

```python
price
```

doesn't exist?

We can write

```python
price_data = data.get("price", {})

current_price = price_data.get("current")
```

Notice how each level is validated separately.

---

# Missing Data Happens

Beginners often assume APIs always return complete information.

Real APIs don't.

Sometimes:

* Markets are closed.
* Trading is suspended.
* A company is delisted.
* The provider has incomplete information.

Your application must handle missing values gracefully.

---

# Validating Before Displaying

Suppose

```python
current_price
```

is

```python
None
```

Should we display

```text
Price: None
```

No.

Instead,

our application might display

```text
Price unavailable
```

This creates a better user experience.

---

# Building a Cleaner Object

Notice something.

The API might return

30 fields.

Our dashboard needs only

5.

Instead of passing the entire response around,

we can create a smaller dictionary.

Example

```python
stock = {
    "symbol": data.get("symbol"),
    "company": data.get("companyName"),
    "price": data.get("price", {}).get("current"),
    "volume": data.get("volume"),
    "currency": data.get("currency")
}
```

Now our UI receives only the information it needs.

---

# Why Is This Better?

Imagine six different APIs.

Each returns different field names.

API A

```text
companyName
```

API B

```text
name
```

API C

```text
company
```

Our dashboard shouldn't need to know this.

Instead,

our parsing code converts every response into one consistent format.

```python
{
    "company": "...",
    "price": "...",
    "volume": "...",
    "currency": "..."
}
```

The UI becomes independent of the API.

---

# This Is Data Transformation

Notice what's happening.

```text
Raw API Response

↓

Parse

↓

Extract

↓

Rename Fields

↓

Clean Python Dictionary

↓

Dashboard
```

This process is called

**data transformation**.

Professional applications perform this constantly.

---

# Separation of Responsibilities

A beginner might write

```text
Button Click

↓

API Request

↓

JSON Parsing

↓

Formatting

↓

Display
```

inside one callback.

A professional separates these tasks.

```text
Button Click

↓

Market Data Service

↓

Download Data

↓

Parse Data

↓

Return Clean Dictionary

↓

Panel UI
```

Each layer has one responsibility.

---

# Our Future Workflow

Soon,

our application will look like this.

```text
HTTP Request

↓

JSON Response

↓

Parse JSON

↓

Validate Data

↓

Create Stock Dictionary

↓

Panel Dashboard
```

The dashboard never sees the raw API response.

---

# Teacher's Notes

> One habit that distinguishes experienced developers is that they never assume an API response will match their expectations. They inspect the response, validate its contents, and extract only the fields their application requires.
>
> Another important principle is **separation of concerns**. Parsing API data is not the responsibility of the user interface. The UI should receive clean, consistent Python objects that are ready to display. This makes applications easier to maintain and allows the underlying API to change without forcing major changes to the interface.

---

# Common Mistakes

## ❌ Mistake 1

Writing extraction code before inspecting the API response.

Always print or pretty-print the response first.

---

## ❌ Mistake 2

Using

```python
data["key"]
```

for every lookup.

Prefer

```python
data.get("key")
```

when keys may be missing.

---

## ❌ Mistake 3

Passing raw API responses directly to the UI.

Instead,

convert them into a simplified data structure tailored to your application's needs.

---

## ❌ Mistake 4

Ignoring missing values.

Real-world APIs frequently omit fields.

Plan for incomplete data.

---

## ❌ Mistake 5

Combining networking, parsing, and UI code in a single function.

Keep each responsibility separate.

---

# Summary

In this lesson, you learned:

* Parsing means extracting useful information from structured data.
* Always inspect an unfamiliar API response before writing extraction code.
* Use `pprint` to visualize complex dictionaries and lists.
* Navigate nested dictionaries one level at a time.
* Prefer the `get()` method when working with optional fields.
* Handle missing data gracefully instead of allowing your application to crash.
* Transform raw API responses into clean Python dictionaries before passing them to the UI.
* Parsing and data transformation belong in a dedicated service layer, not inside the Panel interface.

Our SGX Stock Monitor can now communicate with APIs, understand JSON, and extract meaningful information. The next step is making our application resilient by learning how to handle network failures, invalid responses, rate limits, and other real-world problems.

---

# Exercises

## Exercise 1 — Explore Before Extracting

Given the following response:

```python
data = {
    "symbol": "D05",
    "companyName": "DBS Group Holdings",
    "price": {
        "current": 41.35,
        "high": 41.60,
        "low": 41.00
    },
    "volume": 3250000
}
```

Without writing extraction code immediately:

1. List every top-level key.
2. Identify which values are dictionaries.
3. Draw the hierarchy of the data structure.

---

## Exercise 2 — Safe Data Extraction

Using the same dictionary, write Python code to safely retrieve:

* Company name
* Current price
* Daily high
* Daily low
* Volume

Use `get()` wherever appropriate.

---

## Exercise 3 — Normalize API Data

Suppose three different APIs return company names using different keys:

```python
# API A
{
    "companyName": "DBS"
}

# API B
{
    "name": "DBS"
}

# API C
{
    "company": "DBS"
}
```

Design a normalized Python dictionary that always uses the same key names for your application.

Explain why this approach makes your Panel dashboard easier to maintain.

---

# Coming Up Next

In **Lesson 3.6 — Error Handling and Building Reliable Network Applications**, we'll explore what happens when things go wrong. You'll learn how to handle connection failures, invalid JSON, missing fields, API rate limits, HTTP error responses, and unexpected exceptions. We'll introduce defensive programming techniques that ensure our SGX Stock Monitor remains stable and user-friendly even when external services fail. This is a critical step toward building a production-quality application rather than a simple demonstration.
