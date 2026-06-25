# Part III — Working with Real SGX Market Data

> **Part Objectives**
>
> By the end of this part, you will be able to:
>
> * Understand where financial market data comes from.
> * Learn how web APIs work.
> * Master HTTP requests using Python.
> * Understand JSON data structures.
> * Learn how to retrieve live SGX stock information.
> * Parse and validate API responses.
> * Handle network errors gracefully.
> * Separate data retrieval from the user interface.
> * Build a reusable market data service.
> * Connect real market data to our Panel application.

---

# Why This Part Matters

Up until now, our SGX Stock Monitor has been displaying placeholder messages.

When the user enters:

```text
DBS
```

our application displays

```text
Searching SGX for DBS...
```

This is useful for learning Panel.

However...

it isn't actually searching anything.

The application knows nothing about:

* DBS
* OCBC
* UOB
* Singtel
* Keppel
* SIA

Everything is still simulated.

That changes in this part.

---

# The Evolution of Our Application

Let's look at how our application has evolved.

## Part I

We learned Python and Panel fundamentals.

```text
Python

↓

Panel

↓

Widgets
```

---

## Part II

We built an interactive interface.

```text
User

↓

TextInput

↓

Button

↓

Markdown Output
```

---

## Part III

Now we'll introduce real-world data.

```text
User

↓

Panel

↓

Internet

↓

Financial API

↓

Live Market Data

↓

Dashboard
```

This is the moment where our project becomes a genuine stock monitoring application.

---

# What You'll Build

By the end of this part, our dashboard will evolve from this:

```text
SGX Stock Monitor

Search ___________

[ Search ]

Searching SGX for DBS...
```

into something much more useful.

```text
SGX Stock Monitor

Search ___________

[ Search ]

----------------------------------

DBS Group Holdings

Current Price:
SGD 41.35

Today's Change:
+0.42%

Volume:
3,250,000

Market:
Singapore Exchange

Last Updated:
09:45 AM

----------------------------------
```

Everything displayed will come from live market data rather than hardcoded strings.

---

# A Major Milestone

Until now,

everything in our application has existed inside Python.

```text
Application

↓

Widgets

↓

Callbacks

↓

Layouts
```

Beginning in this part,

our application starts communicating with external systems.

```text
Python

↓

Internet

↓

Financial API

↓

Market Database
```

This introduces many new concepts that every software developer needs to understand.

---

# New Concepts You'll Learn

This part introduces several important software engineering topics.

## Web APIs

How applications communicate across the Internet.

---

## HTTP

The protocol used to send requests.

---

## JSON

The standard format used by APIs to exchange data.

---

## Data Validation

Ensuring received information is correct.

---

## Error Handling

Handling situations where the Internet,

the server,

or the API fails.

---

## Software Architecture

Separating the user interface from data retrieval.

---

# Why Beginners Often Skip This

Many beginner tutorials use fake data.

For example,

they write

```python
price = 41.35
```

instead of downloading the real market price.

This is easier.

Unfortunately,

students never learn how real applications work.

Professional applications almost always retrieve information from:

* databases
* cloud services
* REST APIs
* external systems

This part teaches those real-world skills.

---

# Our Architecture Is Growing

Previously,

our architecture looked like this.

```text
Browser

↓

Panel

↓

Python
```

Now it becomes

```text
Browser

↓

Panel

↓

Application

↓

Market Data Service

↓

Financial API

↓

SGX Market Data
```

Notice something important.

We're adding a new layer called the **Market Data Service**.

We'll discuss why shortly.

---

# The Software Engineering Perspective

A beginner might write everything inside one callback.

```text
Button Click

↓

Download Data

↓

Parse Data

↓

Update Widgets

↓

Handle Errors

↓

Display Results
```

That quickly becomes difficult to maintain.

Instead,

we'll separate responsibilities.

```text
Button

↓

Callback

↓

Market Data Service

↓

Financial API

↓

Processed Data

↓

Dashboard
```

Each component has one responsibility.

This follows the software engineering principles introduced earlier in the tutorial.

---

# Our Development Philosophy

Throughout this part,

we will continue following the same teaching philosophy as the rest of this tutorial.

For every concept,

we will explain:

* **What** it is.
* **Why** it exists.
* **How** it works.
* **When** to use it.
* **Where** it fits into the application.
* **Common beginner mistakes.**
* **Professional best practices.**

Nothing will be treated as "magic."

---

# Part III Roadmap

This part contains the following lessons.

| Lesson   | Topic                                |
| -------- | ------------------------------------ |
| **3.1**  | Understanding APIs and Market Data   |
| **3.2**  | Introduction to HTTP Requests        |
| **3.3**  | Working with the `requests` Library  |
| **3.4**  | Understanding JSON                   |
| **3.5**  | Parsing API Responses                |
| **3.6**  | Error Handling and Network Failures  |
| **3.7**  | Designing a Market Data Service      |
| **3.8**  | Connecting Panel to Live Data        |
| **3.9**  | Displaying Real Stock Information    |
| **3.10** | Mini Project — Live SGX Stock Lookup |

---

# Prerequisites

Before continuing, you should be comfortable with:

✅ Variables

✅ Functions

✅ Classes (basic understanding)

✅ Lists

✅ Dictionaries

✅ Modules

✅ Panel widgets

✅ Panel layouts

✅ Callbacks

If any of these topics are unfamiliar,

consider reviewing Parts I and II before proceeding.

---

# Teacher's Notes

> Part III represents one of the biggest transitions in the entire course. Up to this point, every piece of information has lived inside our own program. From now on, we'll rely on external services that we do not control. This introduces latency, network failures, changing data formats, authentication, and many other real-world engineering challenges.
>
> Understanding how to interact with external APIs is one of the most valuable skills a Python developer can learn. Whether you're building stock dashboards, weather applications, AI tools, IoT systems, or business software, the concepts introduced in this part are widely applicable.

---

# Coming Up Next

## Lesson 3.1 — Understanding APIs and Market Data

Before writing a single line of code, we'll answer one of the most important questions in software development:

> **Where does stock market data actually come from?**

You'll learn what an API is, why financial data providers exist, how applications communicate over the Internet, and how our SGX Stock Monitor will retrieve live market information. By the end of the lesson, you'll understand the complete journey a stock price takes—from the Singapore Exchange's trading systems to your Python application and finally to the user's browser.
