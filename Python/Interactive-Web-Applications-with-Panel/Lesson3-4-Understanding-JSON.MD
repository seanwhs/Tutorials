# Part III — Working with Real SGX Market Data

# Lesson 3.4 — Understanding JSON: The Language of APIs

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what JSON is.
> * Learn why almost every modern API uses JSON.
> * Understand JSON objects and arrays.
> * Learn how JSON maps naturally to Python dictionaries and lists.
> * Use `response.json()` to convert API responses into Python objects.
> * Navigate nested JSON structures.
> * Extract stock information from API responses.
> * Understand common JSON parsing mistakes.
> * Prepare to build our Market Data Service.

---

# Introduction

In the previous lesson, we successfully sent an HTTP request using the `requests` library.

```python
import requests

response = requests.get(url)
```

We also learned that the server sends back a **Response**.

But...

what exactly is inside that response?

For a normal website,

the response might contain HTML.

For a financial API,

the response usually contains **JSON**.

Today's lesson introduces one of the most important data formats in modern software development.

---

# Why Do APIs Need a Data Format?

Imagine two people speaking different languages.

```text
Person A

↓

English

↓

???

↓

Japanese

↓

Person B
```

Communication becomes difficult.

Computers face the same problem.

Applications written in:

* Python
* Java
* JavaScript
* Go
* C#
* Rust

must all communicate with one another.

They need a common language.

That language is usually **JSON**.

---

# What Is JSON?

JSON stands for

> **JavaScript Object Notation**

Despite the name,

JSON is **not limited to JavaScript**.

Today,

it is used by almost every programming language.

Python,

Java,

Go,

Rust,

Swift,

C#,

Kotlin,

and many others all understand JSON.

---

# A Simple Definition

JSON is

> **A lightweight text format used to exchange structured data between applications.**

Notice the word

**text**.

JSON is just text.

You can open a JSON file in any text editor.

---

# Why Not Invent Our Own Format?

Imagine if every company invented its own way of representing stock prices.

Company A

```text
Price = 41.35
```

Company B

```text
CurrentPrice -> SGD41.35
```

Company C

```text
StockValue(DBS)=41.35
```

Applications would constantly need custom code for every provider.

JSON solves this problem.

Everyone agrees on one format.

---

# JSON Looks Like This

Here's a simple example.

```json
{
    "company": "DBS",
    "price": 41.35,
    "currency": "SGD"
}
```

Even if you've never seen JSON before,

it's surprisingly readable.

---

# JSON Is Built from Two Main Structures

Almost every JSON document is built using only two structures.

* Objects
* Arrays

Everything else is built from these.

---

# JSON Objects

A JSON object stores information as

**key-value pairs**.

Example

```json
{
    "company": "DBS",
    "price": 41.35,
    "volume": 3200000
}
```

Think of it as a labeled container.

```text
Company → DBS

Price → 41.35

Volume → 3,200,000
```

Each label is called a **key**.

Each associated value is called a **value**.

---

# JSON Arrays

Sometimes,

we need to store multiple items.

JSON uses arrays.

Example

```json
[
    "DBS",
    "OCBC",
    "UOB"
]
```

Arrays preserve order.

Item 1

↓

DBS

Item 2

↓

OCBC

Item 3

↓

UOB

---

# Arrays Can Contain Objects

Real APIs often return arrays of objects.

Example

```json
[
    {
        "symbol": "D05",
        "company": "DBS"
    },
    {
        "symbol": "O39",
        "company": "OCBC"
    }
]
```

This is extremely common.

---

# JSON Values

JSON supports several value types.

| JSON Type | Example   |
| --------- | --------- |
| String    | `"DBS"`   |
| Number    | `41.35`   |
| Boolean   | `true`    |
| Null      | `null`    |
| Object    | `{ ... }` |
| Array     | `[ ... ]` |

These should look familiar.

Python supports similar data types.

---

# JSON vs Python

This is where learning becomes easier.

JSON maps naturally to Python.

| JSON   | Python      |
| ------ | ----------- |
| Object | Dictionary  |
| Array  | List        |
| String | String      |
| Number | int / float |
| true   | True        |
| false  | False       |
| null   | None        |

This similarity is one reason JSON became so popular.

---

# Converting JSON into Python

Remember our response object?

```python
response = requests.get(url)
```

Instead of using

```python
response.text
```

we usually write

```python
response.json()
```

---

# What Does `response.json()` Do?

Suppose the server sends

```json
{
    "company": "DBS",
    "price": 41.35
}
```

Calling

```python
data = response.json()
```

converts the JSON into a Python dictionary.

```python
{
    "company": "DBS",
    "price": 41.35
}
```

Notice how similar they look.

---

# Understanding the Conversion

Conceptually,

the process is

```text
JSON Text

↓

response.json()

↓

Python Dictionary
```

Once converted,

we work entirely with Python objects.

---

# Accessing Values

Suppose

```python
data = response.json()
```

contains

```python
{
    "company": "DBS",
    "price": 41.35
}
```

We retrieve values exactly like any other dictionary.

```python
print(data["company"])
```

Output

```text
DBS
```

---

Likewise,

```python
print(data["price"])
```

Output

```text
41.35
```

---

# A Realistic Stock Response

Many APIs return something like this.

```json
{
    "symbol": "D05",
    "company": "DBS Group Holdings",
    "price": 41.35,
    "currency": "SGD",
    "volume": 3250000,
    "change": 0.42
}
```

After

```python
response.json()
```

we can access individual values.

```python
data["company"]

data["price"]

data["volume"]
```

---

# Nested JSON

Real APIs are often more complicated.

Example

```json
{
    "company": {
        "symbol": "D05",
        "name": "DBS"
    },
    "market": {
        "currency": "SGD",
        "exchange": "SGX"
    }
}
```

Notice that objects can contain other objects.

---

# Accessing Nested Data

Suppose

```python
data = response.json()
```

To access the company name,

we write

```python
data["company"]["name"]
```

Execution

```text
Dictionary

↓

company

↓

Nested Dictionary

↓

name

↓

DBS
```

---

# Arrays Inside Objects

APIs frequently combine objects and arrays.

Example

```json
{
    "prices": [
        41.20,
        41.30,
        41.35,
        41.40
    ]
}
```

Accessing the first price

```python
data["prices"][0]
```

Accessing the last price

```python
data["prices"][-1]
```

---

# A More Complex Example

```json
{
    "company": "DBS",
    "prices": [
        {
            "date": "2026-06-25",
            "close": 41.20
        },
        {
            "date": "2026-06-26",
            "close": 41.35
        }
    ]
}
```

To retrieve today's closing price,

we write

```python
data["prices"][1]["close"]
```

Notice how we move through the structure one level at a time.

---

# Visualizing Nested Structures

```text
Dictionary

├── company

└── prices

      ├── Item 0

      │      ├── date

      │      └── close

      └── Item 1

             ├── date

             └── close
```

Understanding the hierarchy is essential.

---

# Thinking Like a Python Developer

When beginners see JSON,

they often think

> "This is some strange new format."

Instead,

remember this rule.

> **JSON becomes normal Python objects after calling `response.json()`.**

From that point onward,

you work with:

* dictionaries
* lists
* strings
* numbers

Nothing magical remains.

---

# What Happens If the Response Isn't JSON?

Not every response contains JSON.

Some servers return:

* HTML
* XML
* Images
* PDFs
* Plain text

If you call

```python
response.json()
```

on a response that isn't valid JSON,

Python raises an exception.

We'll learn how to handle this safely in a later lesson.

---

# Our Future SGX Workflow

Soon,

our application will work like this.

```text
User

↓

Search Button

↓

requests.get()

↓

HTTP Response

↓

response.json()

↓

Python Dictionary

↓

Extract Price

↓

Update Dashboard
```

We're almost ready to display live market data.

---

# Teacher's Notes

> One of the biggest advantages of JSON is its simplicity. Once converted into Python objects, there's very little new syntax to learn. Focus on understanding the hierarchy of dictionaries and lists rather than memorizing JSON itself.
>
> When working with unfamiliar APIs, it's common to print the entire JSON response first. This allows you to inspect its structure before writing code to extract specific values. As we'll see in the next lesson, learning to explore API responses is an essential debugging skill.

---

# Common Mistakes

## ❌ Mistake 1

Using

```python
response.text
```

when you actually want structured data.

For JSON APIs,

prefer

```python
response.json()
```

---

## ❌ Mistake 2

Thinking JSON is a Python dictionary.

JSON is text.

`response.json()` converts that text into Python objects.

---

## ❌ Mistake 3

Confusing objects and arrays.

Remember:

* Objects use keys.
* Arrays use indexes.

---

## ❌ Mistake 4

Trying to access nested values without understanding the structure.

Print the entire response first and identify each level before writing extraction code.

---

## ❌ Mistake 5

Assuming every API returns the same JSON structure.

Each API defines its own response format.

Always read the API documentation or inspect the returned data.

---

# Summary

In this lesson, you learned:

* JSON is the most common format used by modern APIs to exchange structured data.
* JSON is built primarily from **objects** and **arrays**.
* JSON objects map naturally to Python dictionaries.
* JSON arrays map naturally to Python lists.
* Use `response.json()` to convert JSON responses into Python data structures.
* Access JSON values using standard dictionary keys and list indexes.
* Real-world APIs often return nested objects and arrays.
* Understanding the structure of a JSON response is the first step toward extracting useful information.

Our SGX Stock Monitor can now communicate with APIs and understand the language they speak. In the next lesson, we'll learn how to **inspect, explore, and parse real API responses**, turning raw JSON into meaningful stock information that can be displayed on our dashboard.

---

# Exercises

## Exercise 1 — Convert JSON to Python

Given the following JSON:

```json
{
    "company": "DBS",
    "price": 41.35,
    "currency": "SGD"
}
```

Answer the following:

* Which Python data type will `response.json()` return?
* How would you access:

  * The company name?
  * The stock price?
  * The currency?

---

## Exercise 2 — Explore a Nested Structure

Given:

```json
{
    "company": {
        "symbol": "D05",
        "name": "DBS Group Holdings"
    },
    "market": {
        "exchange": "SGX",
        "currency": "SGD"
    }
}
```

Write the Python expressions needed to retrieve:

* The company symbol
* The company name
* The exchange
* The currency

---

## Exercise 3 — Objects and Arrays

Given:

```json
{
    "watchlist": [
        {
            "symbol": "D05",
            "price": 41.35
        },
        {
            "symbol": "O39",
            "price": 16.72
        }
    ]
}
```

Determine the Python expressions needed to retrieve:

* The first company's symbol
* The first company's price
* The second company's symbol
* The second company's price

Draw the hierarchy of dictionaries and lists before writing your answers.

---

# Coming Up Next

In **Lesson 3.5 — Parsing Real API Responses**, we'll move beyond simple examples and begin working with actual financial API responses. You'll learn how to inspect unknown JSON structures, identify useful fields, safely extract stock information using dictionary methods, handle missing values, and transform raw API data into clean Python objects that our SGX Stock Monitor can display. This lesson bridges the gap between understanding JSON and building a robust, production-quality market data service.
