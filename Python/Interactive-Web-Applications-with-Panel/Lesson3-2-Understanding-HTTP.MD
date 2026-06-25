# Part III — Working with Real SGX Market Data

# Lesson 3.2 — Understanding HTTP: The Language of the Web

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what HTTP is.
> * Learn why HTTP exists.
> * Understand the client-server communication model.
> * Learn how HTTP requests are structured.
> * Understand URLs and their components.
> * Learn common HTTP methods (`GET`, `POST`, `PUT`, `DELETE`).
> * Understand HTTP headers.
> * Learn about HTTP status codes.
> * Understand how HTTP powers every API.
> * Prepare to retrieve SGX market data using Python.

---

# Introduction

In the previous lesson, we learned that our Panel application communicates with a market data provider through an API.

Our application asks a question.

The API returns an answer.

But...

**How do these messages actually travel across the Internet?**

Applications don't invent their own communication language.

Instead,

they use a standardized protocol called **HTTP**.

Today we'll learn that protocol.

---

# Imagine There Were No Rules

Suppose every country invented its own postal system.

One country writes addresses at the top.

Another writes them at the bottom.

Another writes them backwards.

Mail would never arrive correctly.

Computers have the same problem.

Without agreed rules,

applications couldn't communicate.

---

# What Is HTTP?

HTTP stands for

> **HyperText Transfer Protocol**

The name sounds complicated.

Let's break it down.

---

## HyperText

Originally,

the Web connected documents using hyperlinks.

```text
Page A

↓

Link

↓

Page B
```

The "HyperText" part comes from those linked documents.

Today,

HTTP transfers much more than web pages.

It transfers:

* Images
* Videos
* JSON
* Files
* API responses
* Documents

---

## Transfer

HTTP transfers information from one computer to another.

```text
Computer A

↓

Information

↓

Computer B
```

---

## Protocol

A protocol is simply a set of agreed rules.

Imagine playing football.

Everyone agrees:

* Goal size
* Number of players
* Match duration
* Scoring rules

Without those rules,

nobody could play.

HTTP provides similar rules for computers.

---

# A Simple Definition

HTTP is

> **The standard language that web browsers, servers, and APIs use to communicate over the Internet.**

---

# HTTP Is Everywhere

You use HTTP hundreds of times every day.

Opening Google.

↓

HTTP

---

Watching YouTube.

↓

HTTP

---

Checking the weather.

↓

HTTP

---

Reading email.

↓

HTTP (for many webmail services)

---

Using our future SGX Stock Monitor.

↓

HTTP

---

# Our Application Uses HTTP Too

Our future dashboard will look something like this.

```text
User

↓

Search "DBS"

↓

Panel Application

↓

HTTP Request

↓

Market API

↓

HTTP Response

↓

Dashboard Updated
```

Everything travels using HTTP.

---

# The Client Starts the Conversation

HTTP follows the same pattern we learned previously.

```text
Client

↓

Request

↓

Server

↓

Response

↓

Client
```

The client always starts the conversation.

Servers do not randomly send information.

---

# Anatomy of an HTTP Request

An HTTP request contains several parts.

```text
Method

↓

URL

↓

Headers

↓

(Optional Body)
```

Each part has a purpose.

We'll study each one.

---

# Part 1 — The Method

The **method** tells the server what we want to do.

Examples include:

```text
GET

POST

PUT

DELETE
```

Think of it as choosing an action.

---

# GET

The most common method is

```text
GET
```

GET means

> "Please send me some information."

Example:

```text
GET latest DBS stock price
```

Notice that GET **retrieves** information.

It does not change anything.

---

# Real-Life Analogy

Imagine borrowing a book from a library.

```text
Librarian

↓

Please let me read this book.
```

You're asking to read.

You're not changing the book.

That's exactly what GET does.

---

# POST

POST means

> "I'd like to send you some new information."

Example:

Creating a new account.

```text
Username

Password

Email
```

The client sends information to the server.

---

# PUT

PUT usually means

> "Replace or update existing information."

Example:

Updating your profile.

```text
Old Phone Number

↓

New Phone Number
```

---

# DELETE

DELETE means

> "Please remove this information."

For example,

deleting an item from an online shopping cart.

---

# Which Method Will We Use?

Our stock monitor only needs to retrieve information.

We're not creating companies.

We're not deleting trades.

We're simply asking:

```text
What's the current stock price?
```

Therefore,

we'll mainly use

```text
GET
```

---

# Part 2 — The URL

After the method comes the

**URL**.

The URL tells the server exactly where the requested resource lives.

For example,

```text
https://example.com
```

is a URL.

---

# What Is a URL?

URL stands for

> **Uniform Resource Locator**

Think of it as an Internet address.

Just as houses have addresses,

resources on the Internet have URLs.

---

# Example URL

```text
https://api.example.com/stocks/DBS
```

Although we won't use this exact URL,

it illustrates the general structure.

---

# Breaking Down the URL

```text
https://api.example.com/stocks/DBS
```

contains several parts.

```text
https

↓

api.example.com

↓

stocks

↓

DBS
```

Each part has meaning.

---

# The Protocol

```text
https://
```

This tells the browser which communication protocol to use.

Today,

almost every website uses HTTPS,

which is the secure version of HTTP.

---

# The Domain Name

```text
api.example.com
```

This identifies the server.

Think of it as the company's address.

---

# The Path

```text
/stocks/DBS
```

The path identifies a specific resource.

Imagine entering a library.

```text
Library

↓

Science Section

↓

Shelf 3

↓

Book 12
```

The path guides the server to the requested information.

---

# Part 3 — Headers

Headers provide extra information about the request.

Think of them as labels attached to a package.

For example,

a package might say

```text
Fragile

Handle With Care
```

Similarly,

HTTP headers describe the request.

---

Examples include:

```text
Accept: application/json

User-Agent: MyApp

Authorization: API_KEY
```

We'll learn these gradually.

---

# Why Headers Matter

Suppose the server can return information as:

* HTML
* XML
* JSON

How does it know which one we want?

The client tells the server using headers.

---

# Part 4 — The Body

Some HTTP requests also contain a body.

The body contains additional data.

Example:

Creating a new account.

```text
Name

Email

Password
```

These values are placed inside the request body.

---

Will our stock monitor use a body?

Usually,

no.

GET requests rarely include one.

---

# The Complete Request

Putting everything together,

an HTTP request looks conceptually like this.

```text
GET

↓

URL

↓

Headers

↓

(Optional Body)
```

---

# The Server Responds

After receiving the request,

the server sends a response.

The response contains:

```text
Status Code

↓

Headers

↓

Body
```

---

# Status Codes

The status code tells us what happened.

Think of it as the server's answer before sending the data.

---

# 200 OK

The most common status code is

```text
200 OK
```

Meaning:

> Everything worked successfully.

---

# 404 Not Found

You've probably seen this before.

```text
404 Not Found
```

It means

> The requested resource doesn't exist.

---

# 500 Internal Server Error

Sometimes,

the server itself experiences a problem.

```text
500 Internal Server Error
```

The request was valid,

but the server couldn't process it.

---

# Other Common Status Codes

| Code    | Meaning               |
| ------- | --------------------- |
| **200** | Success               |
| **201** | Resource Created      |
| **400** | Bad Request           |
| **401** | Unauthorized          |
| **403** | Forbidden             |
| **404** | Not Found             |
| **429** | Too Many Requests     |
| **500** | Internal Server Error |

You'll encounter these frequently when working with APIs.

---

# Understanding 429

Many financial APIs limit how often you can request data.

Suppose an API allows

100 requests per minute.

If you send

500 requests,

the server might respond

```text
429

Too Many Requests
```

This protects the server from overload.

---

# The Complete Conversation

Let's visualize an entire HTTP exchange.

```text
Panel App

↓

GET Request

↓

Internet

↓

Market API

↓

200 OK

↓

JSON Data

↓

Panel App

↓

Dashboard Updated
```

Everything follows the HTTP protocol.

---

# Why Learn HTTP Before Python?

Many beginners immediately write:

```python
requests.get(...)
```

without understanding what actually happens.

We prefer the opposite approach.

First,

understand the communication.

Then,

learn the Python code that performs it.

This makes the code much easier to understand.

---

# Teacher's Notes

> HTTP is one of the most important protocols in software engineering. Although we'll use it to retrieve stock market data, exactly the same protocol is used for weather services, AI APIs, payment gateways, cloud platforms, mapping services, social media platforms, and countless other applications.
>
> Whenever you see Python code making an API request, remember that the code is simply constructing an HTTP request, sending it over the Internet, waiting for an HTTP response, and then processing the returned data.

---

# Common Mistakes

## ❌ Mistake 1

Thinking HTTP is only for websites.

Modern APIs use HTTP extensively.

---

## ❌ Mistake 2

Confusing HTTP with HTML.

* **HTTP** is a communication protocol.
* **HTML** is a markup language used to create web pages.

They are completely different.

---

## ❌ Mistake 3

Thinking every request is a GET request.

Different methods exist for different purposes.

Use the method that matches the intended action.

---

## ❌ Mistake 4

Ignoring status codes.

Always check whether the request succeeded before using the returned data.

---

# Summary

In this lesson, you learned:

* HTTP is the standard protocol used for communication over the Web.
* HTTP requests consist of a **method**, **URL**, **headers**, and sometimes a **body**.
* The `GET` method retrieves information and is the primary method our SGX Stock Monitor will use.
* URLs identify the location of resources on a server.
* Headers provide additional information about a request.
* HTTP responses contain a **status code**, **headers**, and a **body**.
* Common status codes include **200**, **404**, **429**, and **500**.
* Every API request made by our application will use the HTTP protocol.

We now understand the language spoken by web services. In the next lesson, we'll finally begin writing Python code to communicate using that language with the `requests` library.

---

# Exercises

## Exercise 1 — Identify the Parts of an HTTP Request

Draw a diagram showing the four components of an HTTP request:

* Method
* URL
* Headers
* Body

Explain the purpose of each component in your own words.

---

## Exercise 2 — Match the Method

For each scenario, choose the most appropriate HTTP method:

| Scenario                            | Method |
| ----------------------------------- | ------ |
| Retrieve the latest DBS stock price | ?      |
| Create a new user account           | ?      |
| Update a user's email address       | ?      |
| Delete a saved watchlist            | ?      |

Explain why you chose each method.

---

## Exercise 3 — Interpret Status Codes

A market data API returns the following responses:

* `200 OK`
* `404 Not Found`
* `429 Too Many Requests`
* `500 Internal Server Error`

For each one:

* Describe what happened.
* Explain how your application should respond.
* Decide whether the user should see an error message, retry later, or continue normally.

---

# Coming Up Next

In **Lesson 3.3 — Working with the `requests` Library**, we'll write our first real HTTP request in Python. You'll learn how to install the `requests` package, understand why it's one of the most widely used Python libraries, send `GET` requests, inspect response objects, handle errors, and retrieve data from a real financial API. This is where our SGX Stock Monitor will take its first step toward displaying live market data.
