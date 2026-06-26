# Part V — Working with Live SGX Market Data

# Lesson 5.2 — Understanding JSON: The Language of Modern APIs

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what JSON is.
> * Learn why JSON is used by almost every web API.
> * Understand JSON syntax.
> * Learn JSON objects, arrays, values, and nesting.
> * Compare JSON with Python dictionaries and lists.
> * Learn how API responses become Python objects.
> * Understand serialization and deserialization.
> * Prepare to process real SGX market data.

---

# Introduction

In the previous lesson,

we learned that our dashboard communicates with a financial API.

The workflow looked like this.

```text
User

↓

Panel Dashboard

↓

HTTP Request

↓

Financial API

↓

HTTP Response

↓

Dashboard
```

But one important question remains.

How does the server actually send stock information?

Certainly not like this.

```text
Price = 41.35

Volume = 2,150,000

Company = DBS
```

Computers need a structured format that every programming language understands.

That format is

> **JSON**

JSON is one of the most important technologies in modern software development.

If you understand JSON,

you can communicate with almost any web service.

---

# What Is JSON?

JSON stands for

> **JavaScript Object Notation**

Despite its name,

JSON is **not limited to JavaScript**.

Today,

almost every programming language supports JSON.

Including:

* Python
* Java
* C#
* Go
* Rust
* PHP
* JavaScript

---

# Why Was JSON Created?

Imagine two programs trying to communicate.

One is written in Python.

The other is written in Java.

How should they exchange information?

If Python sends

```python
{
    "price": 41.35
}
```

Java must understand exactly the same structure.

JSON became the common language that every programming language understands.

---

# A Real-Life Analogy

Imagine people from different countries meeting.

One speaks English.

Another speaks Chinese.

Another speaks French.

Instead of everyone learning every language,

they agree to communicate using one common language.

JSON plays exactly that role for software.

---

# Why APIs Use JSON

Suppose a financial API wants to send this information.

```text
Company

DBS Group Holdings

Price

41.35

Volume

2,150,000
```

Instead,

it sends

```json
{
    "company": "DBS Group Holdings",
    "price": 41.35,
    "volume": 2150000
}
```

This format is:

* structured
* readable
* compact
* language-independent

---

# JSON Is Just Text

One of the biggest beginner misconceptions is that JSON is a special programming language.

It isn't.

JSON is simply

> **plain text**

For example,

this is perfectly valid JSON.

```json
{
    "hello": "world"
}
```

If you opened a JSON file with Notepad,

you would see ordinary text.

---

# The Four Building Blocks of JSON

JSON is built from only four fundamental concepts.

```text
Objects

Arrays

Values

Key-Value Pairs
```

Everything else is built from these.

---

# Understanding Key-Value Pairs

The smallest unit in JSON is a

**key-value pair**.

Example

```json
{
    "price": 41.35
}
```

Here,

```text
Key

↓

price
```

and

```text
Value

↓

41.35
```

Think of a key as a label.

The value is the information stored under that label.

---

# Real-Life Analogy

Imagine a filing cabinet.

```text
Drawer Label

↓

Price

Contents

↓

41.35
```

The drawer label is the key.

The contents are the value.

---

# JSON Objects

A JSON object groups multiple key-value pairs together.

Objects use

```text
{
}
```

curly braces.

Example

```json
{
    "symbol": "D05",
    "price": 41.35,
    "currency": "SGD"
}
```

Everything inside the braces belongs to one object.

---

# Visualizing an Object

```text
Stock

├── Symbol

│      D05

├── Price

│      41.35

└── Currency

       SGD
```

Objects are similar to records in a database.

---

# JSON Arrays

Sometimes,

we need multiple items.

JSON uses

```text
[
]
```

square brackets.

Example

```json
[
    "D05",
    "U11",
    "O39"
]
```

This is called an

**array**.

---

# Thinking About Arrays

An array is simply

> **a collection of values**

Like a shopping list.

```text
Milk

Eggs

Bread

Coffee
```

JSON stores lists the same way.

---

# Arrays Can Store Objects

Arrays become much more useful when they contain objects.

Example

```json
[
    {
        "symbol": "D05",
        "price": 41.35
    },
    {
        "symbol": "U11",
        "price": 30.12
    }
]
```

This represents multiple stocks.

---

# Nested JSON

JSON objects can contain other objects.

Example

```json
{
    "company": {
        "name": "DBS Group Holdings",
        "country": "Singapore"
    }
}
```

This is called

> **Nested JSON**

---

# Visualizing Nested Objects

```text
Company

├── Name

│      DBS Group Holdings

└── Country

       Singapore
```

The company object exists inside another object.

---

# Combining Everything

A real API response might look like this.

```json
{
    "symbol": "D05",
    "company": {
        "name": "DBS Group Holdings",
        "sector": "Banking"
    },
    "price": {
        "current": 41.35,
        "open": 41.10,
        "high": 41.60
    },
    "history": [
        40.80,
        41.00,
        41.20,
        41.35
    ]
}
```

Notice that it contains:

* objects
* arrays
* nested objects
* numbers
* strings

Real APIs often look like this.

---

# JSON Value Types

JSON supports only a few value types.

| JSON Type | Example   |
| --------- | --------- |
| String    | `"DBS"`   |
| Number    | `41.35`   |
| Boolean   | `true`    |
| Null      | `null`    |
| Object    | `{ ... }` |
| Array     | `[ ... ]` |

That's all.

The simplicity of JSON is one reason it became so popular.

---

# JSON vs Python

JSON looks very similar to Python.

Consider this JSON.

```json
{
    "price": 41.35
}
```

Python represents the same information as

```python
{
    "price": 41.35
}
```

They look nearly identical.

But they are **not** the same thing.

---

# Important Differences

JSON

```json
{
    "price": 41.35
}
```

is **text**.

Python

```python
{
    "price": 41.35
}
```

is a **dictionary object**.

One is plain text.

The other is an actual Python data structure.

This distinction is extremely important.

---

# Converting JSON into Python

When an API responds,

it sends

```text
JSON Text
```

Python cannot directly use JSON text.

Instead,

it converts the JSON into Python objects.

The process looks like this.

```text
HTTP Response

↓

JSON Text

↓

Python

↓

Dictionary

↓

Application
```

---

# Serialization and Deserialization

Two terms appear frequently in software engineering.

## Serialization

Converting Python objects into JSON.

```text
Python

↓

JSON
```

---

## Deserialization

Converting JSON into Python objects.

```text
JSON

↓

Python
```

Our application performs deserialization much more often than serialization.

---

# Why Convert to Dictionaries?

Suppose the API sends

```json
{
    "price": 41.35
}
```

Python converts it into

```python
{
    "price": 41.35
}
```

Now we can write

```python
stock["price"]
```

This is much easier than manually parsing text.

---

# Our MarketDataService

The conversion happens inside our service layer.

```text
HTTP Response

↓

JSON

↓

MarketDataService

↓

Python Dictionary

↓

Panel Dashboard
```

Notice that the dashboard never sees raw JSON.

This keeps the user interface clean.

---

# Why Hide JSON?

Imagine every widget reading JSON directly.

The code would become messy.

Instead,

our architecture becomes

```text
API

↓

JSON

↓

MarketDataService

↓

Dictionary

↓

Dashboard
```

Each layer has one responsibility.

---

# A Typical Data Flow

When the user searches for

```text
D05
```

the application performs this sequence.

```text
User

↓

Search Button

↓

HTTP Request

↓

Financial API

↓

JSON

↓

Python Dictionary

↓

Panel Panes
```

Everything now fits together.

---

# Thinking Like a Software Engineer

JSON is an **exchange format**.

Python dictionaries are an **in-memory data structure**.

These are different concepts.

Good software converts between them as early as possible.

After conversion,

the rest of the application works entirely with Python objects.

This is exactly what our `MarketDataService` will do.

---

# Teacher's Notes

> One of the most common beginner misunderstandings is believing that JSON and Python dictionaries are identical because they look similar. They are not. JSON is a text format designed for exchanging data between systems, while a Python dictionary is a native object living inside the Python interpreter. The similarity is intentional—it makes JSON easy for Python programmers to read—but remembering the distinction is essential when working with APIs.
>
> Another point worth emphasizing is that JSON intentionally supports only a small number of data types. This simplicity makes it easy for different programming languages to exchange information without ambiguity.

---

# Common Mistakes

## ❌ Mistake 1

Thinking JSON is a programming language.

JSON is a text format.

---

## ❌ Mistake 2

Confusing JSON with Python dictionaries.

JSON is text.

Dictionaries are Python objects.

---

## ❌ Mistake 3

Trying to manually parse JSON.

Use Python's JSON library instead.

---

## ❌ Mistake 4

Expecting APIs to return Python objects.

APIs return JSON text.

Python performs the conversion.

---

## ❌ Mistake 5

Allowing the user interface to work directly with raw JSON.

Convert JSON into Python objects inside the service layer first.

---

# Summary

In this lesson, you learned:

* JSON is the standard data exchange format used by most web APIs.
* JSON is plain text, not a programming language.
* JSON consists of objects, arrays, key-value pairs, and values.
* JSON supports strings, numbers, booleans, nulls, arrays, and objects.
* JSON objects closely resemble Python dictionaries, but they are fundamentally different.
* API responses are deserialized into Python objects before the application uses them.
* Our `MarketDataService` is responsible for converting JSON into Python dictionaries, shielding the rest of the application from implementation details.

We now understand the format used by financial APIs. The next step is learning how Python actually sends HTTP requests to retrieve that JSON.

---

# Exercises

## Exercise 1 — Identify the JSON Components

Given the following JSON:

```json
{
    "symbol": "D05",
    "price": 41.35,
    "history": [
        41.10,
        41.20,
        41.35
    ]
}
```

Identify:

* Every key
* Every value
* The object
* The array

---

## Exercise 2 — JSON or Python?

For each example, determine whether it is:

* JSON
* A Python dictionary
* A Python list

Explain your reasoning.

---

## Exercise 3 — Trace the Data Flow

Draw a diagram showing how market data travels through the following stages:

```text
Financial API

↓

HTTP Response

↓

JSON

↓

MarketDataService

↓

Python Dictionary

↓

Panel Dashboard
```

Explain why each conversion is necessary.

---

# Coming Up Next

In **Lesson 5.3 — Making HTTP Requests with Python**, you'll learn how Python communicates with web APIs using the `requests` library. We'll explore URLs, HTTP methods, status codes, request headers, query parameters, timeouts, and error handling. By the end of the lesson, you'll make your first real API request and retrieve live SGX market data from a financial service, bringing our dashboard one step closer to real-time operation.
