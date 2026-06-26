# Part V — Working with Live SGX Market Data

# Lesson 5.1 — Understanding APIs: Where Does Stock Market Data Come From?

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what an API is.
> * Learn why APIs exist.
> * Understand how modern applications communicate.
> * Learn the client-server architecture.
> * Understand HTTP requests and responses.
> * Learn why stock applications depend on APIs.
> * Understand REST APIs.
> * Learn the overall architecture of our SGX Stock Monitor.
> * Prepare for retrieving real-time stock market data.

---

# Introduction

Our dashboard is now complete.

Users can:

* enter a stock symbol
* click **Search**
* interact with a professional user interface

However,

there is still one major problem.

Where does the stock information come from?

If a user searches for

```text
D05
```

how does our application know:

* the latest price?
* the day's high?
* the trading volume?
* the company name?

The answer is

> **An API**

Before writing any networking code,

we first need to understand what APIs are and why they exist.

---

# What Is an API?

API stands for

> **Application Programming Interface**

Although the name sounds intimidating,

the idea is surprisingly simple.

An API is

> **a way for one program to ask another program for information or services.**

---

# A Real-Life Analogy

Imagine visiting a restaurant.

You do not enter the kitchen.

Instead,

you speak to the waiter.

```text
Customer

↓

Waiter

↓

Kitchen

↓

Chef

↓

Food

↓

Waiter

↓

Customer
```

The waiter acts as an intermediary.

An API plays exactly the same role.

---

# The API Analogy

Our application does **not** communicate directly with the stock exchange.

Instead,

it communicates with an API.

```text
SGX Dashboard

↓

Financial API

↓

Stock Exchange Data
```

The API acts like the waiter.

---

# Why Don't We Connect Directly to SGX?

A beginner might wonder,

> "Why not connect directly to the Singapore Exchange?"

There are several reasons.

Stock exchanges are extremely complex systems.

They must:

* authenticate users
* enforce permissions
* validate requests
* manage enormous trading volumes
* protect sensitive infrastructure

APIs provide a safe,

simplified interface.

---

# Modern Applications Depend on APIs

Today's software rarely works alone.

Consider your smartphone.

A weather app

↓

Weather API

A maps app

↓

Maps API

A banking app

↓

Bank API

A messaging app

↓

Messaging API

Our SGX Stock Monitor

↓

Financial Market API

Modern software is built by connecting services together.

---

# Client and Server

To understand APIs,

we first need to understand two important concepts.

## Client

The program requesting information.

## Server

The program providing information.

---

# In Our Application

Our dashboard is the client.

```text
Panel Dashboard

↓

Client
```

The financial data provider is the server.

```text
Financial API

↓

Server
```

---

# Visualizing Client-Server Communication

```text
Panel Application

↓

Request

↓

Financial Server

↓

Response

↓

Panel Application
```

Notice that communication happens in two directions.

---

# Understanding Requests

A **request** asks the server for something.

Examples include:

```text
Give me DBS stock price.

Give me SGX trading volume.

Give me historical prices.

Give me company information.
```

The client initiates every request.

The server never sends data unless asked.

---

# Understanding Responses

The server answers with a response.

For example,

our application might ask

```text
Price for D05?
```

The server replies

```text
Price = SGD 41.35

Volume = 2,810,000

Company = DBS Group Holdings Ltd
```

This information becomes the dashboard.

---

# Communication Happens Over HTTP

Most modern APIs use

> **HTTP**

HTTP stands for

> **HyperText Transfer Protocol**

Although originally designed for webpages,

HTTP now powers most APIs.

---

# Visualizing HTTP

```text
Panel Dashboard

↓

HTTP Request

↓

Financial API

↓

HTTP Response

↓

Panel Dashboard
```

This happens in milliseconds.

---

# What Does HTTP Carry?

HTTP transports information.

For example,

our request might ask

```text
Stock Symbol = D05
```

The response might contain

```text
Price

High

Low

Volume

Currency

Exchange
```

HTTP doesn't understand stock prices.

It simply transports data.

---

# REST APIs

Most financial APIs are

> **REST APIs**

REST stands for

> **Representational State Transfer**

Don't worry about memorizing the name.

The important idea is this:

A REST API exposes information using URLs and HTTP requests.

---

# A REST API Analogy

Imagine a library.

Instead of asking the librarian,

you walk directly to a shelf.

Each shelf contains one category.

```text
History

Science

Programming

Finance
```

REST APIs organize information similarly.

Different URLs provide different resources.

---

# Resources

REST APIs expose

> **Resources**

Examples include:

```text
Companies

Stocks

Prices

Historical Data

News
```

Each resource usually has its own URL.

---

# Example Workflow

Suppose our dashboard searches for

```text
D05
```

The overall process becomes

```text
User

↓

Search Button

↓

Callback

↓

HTTP Request

↓

Financial API

↓

JSON Response

↓

Dashboard
```

We'll learn JSON in the next lesson.

---

# APIs Hide Complexity

Imagine retrieving stock prices manually.

You would need to know:

* exchange protocols
* networking
* authentication
* binary market feeds
* message formats

Instead,

the API gives us a much simpler interface.

```text
Ask for Stock

↓

Receive Stock Data
```

That's the beauty of APIs.

---

# APIs Don't Care About Panel

An important observation.

The API has no idea that we're using Panel.

It simply receives an HTTP request.

Likewise,

our Panel application doesn't care how the server stores data.

This separation allows both systems to evolve independently.

---

# Understanding the Big Picture

Our architecture now expands.

```text
User

↓

Panel Widgets

↓

Callbacks

↓

MarketDataService

↓

HTTP Request

↓

Financial API

↓

HTTP Response

↓

MarketDataService

↓

Panel Panes

↓

Browser
```

Notice that only the service layer communicates with the API.

The user interface remains unchanged.

---

# Thinking Like a Software Engineer

One of the most important architectural decisions we've made is placing all API communication inside

```text
MarketDataService
```

Imagine if every button,

every chart,

and every pane made its own API requests.

The application would quickly become difficult to maintain.

Instead,

we centralize all networking inside one service.

This follows the principle of **Separation of Concerns**.

---

# Looking Ahead

So far,

we've talked about requests and responses.

But what exactly does the server send back?

Most modern APIs return information using a format called

> **JSON**

Understanding JSON is essential because nearly every web API uses it.

We'll explore JSON in the next lesson.

---

# Teacher's Notes

> Students often think APIs are unique to web development, but APIs exist throughout computing. Operating systems expose APIs, databases expose APIs, machine learning libraries expose APIs, and cloud services expose APIs. An API is simply a contract that allows one piece of software to communicate with another without needing to understand its internal implementation.
>
> Another important point is that our dashboard is only one possible client. The same financial API could also serve a mobile application, another website, or even another company's software. Because APIs separate the client from the server, many different applications can reuse the same backend services.

---

# Common Mistakes

## ❌ Mistake 1

Thinking an API is a database.

An API provides access to information.

It is not necessarily where the information is stored.

---

## ❌ Mistake 2

Believing APIs are specific to Panel.

Panel is simply one client.

Any programming language can call the same API.

---

## ❌ Mistake 3

Thinking HTTP is only for websites.

HTTP is also the standard communication protocol for most web APIs.

---

## ❌ Mistake 4

Mixing networking code into the user interface.

Keep all API communication inside the service layer.

---

## ❌ Mistake 5

Assuming APIs always return webpages.

Most modern APIs return structured data such as JSON rather than HTML.

---

# Summary

In this lesson, you learned:

* An **API** allows software applications to communicate.
* Our Panel dashboard acts as the **client**, while the financial data provider acts as the **server**.
* Communication occurs through **HTTP requests** and **HTTP responses**.
* Most financial APIs follow the **REST** architectural style.
* APIs simplify access to complex systems such as stock exchanges.
* All networking responsibilities should remain inside the `MarketDataService`.
* APIs return structured data that our application will process and display.

We now understand where market data comes from. The next step is learning the language most APIs use to exchange that data.

---

# Exercises

## Exercise 1 — Identify the Client and Server

For each scenario, identify the client and the server:

* A weather application retrieving today's forecast.
* An online banking application checking your account balance.
* Our SGX Stock Monitor retrieving the latest stock price.

Explain your answers.

---

## Exercise 2 — Trace the API Request

Draw a diagram showing the complete journey of a request from the moment the user clicks **Search** until the dashboard receives market data.

Label every component involved.

---

## Exercise 3 — Why Use an API?

Suppose you were asked to build an application that retrieves SGX stock prices.

Explain why using a financial API is preferable to connecting directly to the stock exchange.

Consider:

* complexity
* security
* maintainability
* ease of development

---

# Coming Up Next

In **Lesson 5.2 — Understanding JSON: The Language of Modern APIs**, you'll learn how APIs represent structured data using JSON. We'll explore JSON objects, arrays, nested structures, and key-value pairs, compare JSON with Python dictionaries and lists, and learn how our `MarketDataService` converts API responses into Python objects that the rest of our application can use. This is one of the most important lessons in the entire tutorial because JSON is the universal language of modern web services.
