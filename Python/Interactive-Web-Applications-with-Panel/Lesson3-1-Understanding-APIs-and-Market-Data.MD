# Part III — Working with Real SGX Market Data

# Lesson 3.1 — Understanding APIs and Market Data

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what an API is.
> * Learn why APIs exist.
> * Understand how applications communicate over the Internet.
> * Learn where stock market data comes from.
> * Understand the complete journey of a stock price.
> * Learn the client-server model.
> * Understand requests and responses.
> * Prepare to retrieve real SGX market data.

---

# Introduction

Our SGX Stock Monitor is finally beginning to look like a real application.

Users can:

* Enter a stock symbol
* Click **Search**
* See results displayed on the dashboard

For example,

they might enter

```text
DBS
```

and click

```text
[ Search ]
```

The dashboard responds with

```text
Searching SGX for DBS...
```

That looks convincing.

But...

there's one important question.

> **Where does the actual stock price come from?**

Our application doesn't know.

It isn't connected to the Singapore Exchange.

It doesn't have a giant database of every listed company.

So where does the information originate?

Today's lesson answers that question.

---

# Imagine Building Google

Suppose someone asked you to build Google.

You create a search box.

```text
Search

_____________________

[ Search ]
```

The user types

```text
Python
```

How do you know which websites contain information about Python?

You don't.

Instead,

your application asks another system.

---

The same thing happens in our stock monitor.

```text
User

↓

DBS

↓

Our Application

↓

???
```

Our application must ask another system for the answer.

---

# Where Does Stock Data Come From?

Imagine a trade taking place on the Singapore Exchange.

Someone buys

100 shares

of DBS.

Immediately,

the exchange records:

* Price
* Quantity
* Time
* Buyer
* Seller

That information becomes official market data.

```text
Singapore Exchange

↓

Trade Occurs

↓

Market Database Updated
```

The Singapore Exchange continuously records millions of events like these.

---

# Can Our App Connect Directly to SGX?

A beginner might think:

```text
My App

↓

Singapore Exchange
```

Unfortunately,

it isn't that simple.

Most exchanges do **not** allow every application in the world to connect directly.

Why?

Because millions of applications doing this simultaneously would overwhelm their systems.

Instead,

specialized companies distribute market data.

---

# Market Data Providers

Between our application and the exchange,

there is usually another layer.

```text
Singapore Exchange

↓

Market Data Provider

↓

Our Application
```

These providers collect,

process,

organize,

and distribute market information.

---

# Examples of Market Data Providers

Many companies provide financial market data.

Examples include:

* Alpha Vantage
* Twelve Data
* Finnhub
* Polygon.io
* Financial Modeling Prep
* Yahoo Finance (unofficial APIs)
* IEX Cloud (for supported markets)

Each provider offers different:

* markets
* features
* pricing
* rate limits
* historical data

Later,

we'll choose one suitable for our tutorial.

---

# Why Use a Market Data Provider?

Imagine buying bottled water.

The water originally comes from a source.

However,

you don't visit the source every time you need water.

Instead,

a company bottles,

filters,

and distributes it.

Market data providers do something similar.

They make complex financial information easier to access.

---

# What Is an API?

Now we arrive at one of the most important concepts in software development.

**API** stands for

> **Application Programming Interface**

The name sounds complicated.

The idea is surprisingly simple.

An API is a way for one application to communicate with another application.

---

# A Restaurant Analogy

Imagine visiting a restaurant.

You don't walk into the kitchen.

Instead,

you interact with the waiter.

```text
Customer

↓

Waiter

↓

Kitchen

↓

Waiter

↓

Customer
```

The waiter is the interface between you and the kitchen.

An API works exactly the same way.

---

# Mapping the Analogy

Restaurant

↓

Software

```text
Customer

↓

Our Panel Application

----------------------------

Waiter

↓

API

----------------------------

Kitchen

↓

Market Data Provider
```

The API carries messages between two systems.

---

# Why Not Access the Database Directly?

Suppose every application connected directly to a company's database.

Applications might:

* delete records
* modify prices
* overload the database
* retrieve confidential information

Instead,

the API controls exactly what applications can do.

It acts like a security guard.

---

# APIs Define Rules

An API tells us:

* What information we can request.
* How to request it.
* What format the response uses.
* What errors may occur.

Without these rules,

applications couldn't communicate reliably.

---

# The Client-Server Model

Most APIs follow the **client-server model**.

Our application is the **client**.

The market data provider is the **server**.

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

This pattern appears throughout modern software.

---

# Who Is the Client?

Our SGX Stock Monitor.

```text
Panel Application

↓

Client
```

The client asks questions.

---

# Who Is the Server?

The market data provider.

```text
Market Data Provider

↓

Server
```

The server answers questions.

---

# Understanding Requests

Suppose the user searches

```text
DBS
```

Our application sends a request.

Conceptually,

it says

```text
Hello.

Please send me the latest information for DBS.
```

This message is called a **request**.

---

# Understanding Responses

The server replies.

Conceptually,

it says

```text
DBS

Price:
41.35

Change:
+0.42%

Volume:
3,200,000
```

This message is called a **response**.

---

# Visualizing the Conversation

```text
Panel App

↓

Request

↓

Market Data API

↓

Response

↓

Panel App
```

Notice that communication goes in both directions.

---

# Requests Are Questions

Think of every API request as asking a question.

Examples:

```text
"What is the latest DBS price?"

"What is today's trading volume?"

"What companies are listed on SGX?"

"What was yesterday's closing price?"
```

Every request asks for specific information.

---

# Responses Are Answers

Every request produces a response.

Example

```text
Question

↓

Current price of DBS?

↓

Answer

↓

41.35 SGD
```

Simple.

---

# The Journey of a Stock Price

Let's follow a stock price from the exchange to our dashboard.

```text
Trade Happens

↓

Singapore Exchange

↓

Market Data Provider

↓

API

↓

Internet

↓

Python Application

↓

Panel Dashboard

↓

User
```

This entire process often takes less than one second.

---

# What Does the Internet Do?

The Internet acts like a global delivery network.

```text
Application

↓

Internet

↓

API Server

↓

Internet

↓

Application
```

Every API request travels across the Internet.

---

# Does the API Push Data?

Another beginner misconception is that APIs constantly send information.

Usually,

they don't.

Instead,

our application requests data only when needed.

```text
User Clicks Search

↓

Application Sends Request

↓

Server Responds
```

The client starts the conversation.

---

# One Request, One Response

Most API interactions follow this simple pattern.

```text
Request

↓

Response
```

Then the conversation ends.

If we want updated prices,

we send another request.

---

# Can Many Applications Use the Same API?

Yes.

Imagine thousands of applications.

```text
Trading App

↓

Portfolio App

↓

News App

↓

Our SGX Monitor

↓

Same API
```

All of them communicate with the same server.

The server handles many clients simultaneously.

---

# Why APIs Are Everywhere

Although we're learning about stock data,

the same concept appears everywhere.

Weather apps

↓

Weather API

---

Maps

↓

Map API

---

Currency converters

↓

Exchange Rate API

---

AI assistants

↓

AI API

---

Online shopping

↓

Payment API

Once you understand APIs,

you'll recognize them throughout software engineering.

---

# Teacher's Notes

> APIs are one of the foundational concepts of modern software development. Most real-world applications don't store all the information they need locally. Instead, they communicate with dozens—or even hundreds—of external services.
>
> Don't think of an API as "a stock thing." Think of it as a standardized way for software systems to communicate. Whether you're building financial dashboards, weather applications, AI tools, healthcare systems, or e-commerce platforms, you'll encounter APIs everywhere.

---

# Common Mistakes

## ❌ Mistake 1

Thinking an API is a database.

It isn't.

An API is the interface used to access information.

The database usually sits behind the API.

---

## ❌ Mistake 2

Thinking applications communicate directly with databases on the Internet.

In most professional systems,

applications communicate through APIs.

---

## ❌ Mistake 3

Assuming the server continuously sends data.

Most APIs respond only after receiving a request.

---

## ❌ Mistake 4

Confusing the client and the server.

Remember:

* Our Panel application is the **client**.
* The market data provider is the **server**.

---

# Summary

In this lesson, you learned:

* Market data originates from stock exchanges such as SGX.
* Market data providers distribute that information through APIs.
* An API (Application Programming Interface) enables applications to communicate with one another.
* Our SGX Stock Monitor acts as the **client**, while the market data provider acts as the **server**.
* Communication follows a request-response model.
* Stock prices travel from the exchange, through a market data provider, over the Internet, into our Python application, and finally to the user's browser.
* APIs are a general software engineering concept used across many industries, not just finance.

We now understand **where** the data comes from. In the next lesson, we'll learn **how** our application actually communicates with an API using the **HTTP protocol**, the language spoken by almost every web service on the Internet.

---

# Exercises

## Exercise 1 — Draw the Journey of a Stock Price

Without referring to the lesson, draw a diagram showing how a stock price travels from the Singapore Exchange to your Panel application.

Include:

* Singapore Exchange
* Market Data Provider
* API
* Internet
* Python Application
* Browser
* User

---

## Exercise 2 — Identify the Client and Server

For each of the following, identify which is the **client** and which is the **server**:

* SGX Stock Monitor and a market data API
* Weather app and weather service
* Currency converter and exchange-rate service
* Online shopping website and payment gateway

Explain your reasoning.

---

## Exercise 3 — Think Beyond Stocks

List five applications that you use regularly (for example, a weather app, maps application, streaming service, or messaging platform).

For each one, answer:

* What information does the application need?
* Which APIs might it use?
* What requests do you think it sends?
* What responses does it likely receive?

This exercise helps you recognize that APIs are a fundamental building block of modern software.

---

# Coming Up Next

In **Lesson 3.2 — Understanding HTTP: The Language of the Web**, we'll learn the protocol that makes API communication possible. You'll discover what HTTP is, how URLs are structured, what GET and POST requests mean, how status codes like **200 OK** and **404 Not Found** work, and how every API request follows a standardized format. Before writing any Python code, you'll gain a solid understanding of the language spoken by web browsers, servers, and APIs around the world.
