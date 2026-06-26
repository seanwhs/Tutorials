# Part V — Working with Live SGX Market Data

# Lesson 5.3 — Making HTTP Requests with Python: Communicating with Financial APIs

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what an HTTP request actually is.
> * Learn how Python communicates with web APIs.
> * Understand URLs and endpoints.
> * Learn the purpose of the `requests` library.
> * Understand HTTP methods.
> * Learn about status codes.
> * Understand query parameters and headers.
> * Learn about timeouts and error handling.
> * Make your first real API request.
> * Understand how `MarketDataService` retrieves financial data.

---

# Introduction

In the previous lesson, we learned that financial APIs return information using JSON.

However, one important question remains:

> How do we actually ask the API for information?

Consider our dashboard.

The user enters:

```text
D05
```

Then clicks:

```text
Search
```

What happens next?

The application must somehow send a message across the internet that says:

```text
Please give me information about D05.
```

This process is called making an

> **HTTP Request**

Today's lesson introduces one of the most important skills in modern software engineering:

> **communicating with web APIs using Python.**

---

# Revisiting Our Architecture

Recall our architecture.

```text
User

↓

Panel Widget

↓

Callback

↓

MarketDataService

↓

Financial API

↓

JSON

↓

Dashboard
```

Today we focus on this section.

```text
MarketDataService

↓

Financial API
```

This is where networking occurs.

---

# What Is an HTTP Request?

An HTTP request is simply a message sent from one computer to another.

For example:

```text
Hello Server,

Please give me information about DBS stock.

Thank you.
```

Of course,

real HTTP requests follow a standard format.

---

# Client and Server Communication

Remember our client-server model.

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

Our Panel application is the client.

The financial provider is the server.

---

# Understanding URLs

Every API resource has an address.

This address is called a

> **URL**

For example:

```text
https://api.example.com/stocks
```

A URL tells the internet:

* where the server is
* what resource we want

---

# Breaking Down a URL

Consider:

```text
https://api.example.com/stocks/D05
```

We can break it into pieces.

```text
https://

↓

Protocol

------------------

api.example.com

↓

Server

------------------

stocks/D05

↓

Resource
```

Each part has a specific purpose.

---

# Real-Life Analogy

Imagine mailing a letter.

A postal address contains:

```text
Country

City

Street

House Number
```

Similarly,

a URL tells computers exactly where to deliver a request.

---

# What Is an Endpoint?

An API usually exposes many resources.

Examples:

```text
/stocks

/company

/news

/history

/volume
```

These individual locations are called

> **Endpoints**

Think of endpoints as individual service counters.

---

# Example Endpoints

```text
/stocks/D05

↓

Current stock information

-------------------------

/history/D05

↓

Historical prices

-------------------------

/news/D05

↓

Company news
```

Each endpoint provides different information.

---

# Why Python Needs a Library

Could Python create HTTP requests itself?

Yes.

But networking protocols are extremely complicated.

Instead,

Python programmers usually use a library.

The most popular library is:

```python
requests
```

---

# What Is a Library?

A library is simply:

> **code written by other programmers that we reuse.**

Instead of writing networking software ourselves,

we reuse the work of experts.

This is one of the most important ideas in software engineering.

---

# Installing Requests

Most Python environments already include:

```bash
pip install requests
```

This installs the library.

---

# Importing Requests

Before using it,

we import it.

```python
import requests
```

This tells Python:

> "I want to use the requests library."

---

# Making Our First Request

The simplest request looks like this.

```python
import requests

response = requests.get(
    "https://api.example.com/stocks/D05"
)
```

Let's examine this carefully.

---

# Understanding `requests.get()`

The function:

```python
requests.get()
```

means:

> "Send an HTTP GET request."

The word "GET" means:

> "Retrieve information."

---

# Visualizing the Request

```text
Python Program

↓

requests.get()

↓

Internet

↓

Financial API

↓

Response
```

This entire process may take only milliseconds.

---

# What Does `response` Contain?

After the request finishes,

Python stores the server's reply.

```python
response = requests.get(...)
```

The variable:

```python
response
```

contains:

* status code
* headers
* response body
* metadata

---

# Understanding HTTP Methods

HTTP supports several methods.

| Method | Purpose       |
| ------ | ------------- |
| GET    | Retrieve data |
| POST   | Create data   |
| PUT    | Update data   |
| PATCH  | Modify data   |
| DELETE | Remove data   |

For stock market applications,

we mostly use:

```text
GET
```

because we retrieve information.

---

# Why GET?

Our application never changes the stock market.

It simply asks questions.

Examples:

```text
What is DBS price?

What is SGX volume?

What is today's high?
```

These are all retrieval operations.

---

# Understanding Status Codes

After processing a request,

the server returns a status code.

Think of it as a report card.

---

# Status Code 200

```text
200 OK
```

means:

> Everything succeeded.

Example:

```python
response.status_code
```

returns:

```python
200
```

---

# Status Code 404

```text
404 Not Found
```

means:

> The requested resource does not exist.

Example:

```text
Stock XYZ123 not found.
```

---

# Status Code 500

```text
500 Internal Server Error
```

means:

> The server itself experienced a problem.

This is usually not our fault.

---

# Common Status Codes

| Code | Meaning           |
| ---- | ----------------- |
| 200  | Success           |
| 201  | Created           |
| 400  | Bad Request       |
| 401  | Unauthorized      |
| 403  | Forbidden         |
| 404  | Not Found         |
| 429  | Too Many Requests |
| 500  | Server Error      |

You do not need to memorize all of them.

Over time,

you will recognize them naturally.

---

# Checking Status Codes

Professional code always checks the response.

Example:

```python
if response.status_code == 200:
    print("Success")
else:
    print("Error")
```

Never assume requests succeed.

---

# Understanding Query Parameters

Sometimes,

information is sent as parameters.

Example:

```text
https://api.example.com/stocks?symbol=D05
```

Here,

```text
symbol=D05
```

is called a query parameter.

---

# Visualizing Query Parameters

```text
Base URL

↓

https://api.example.com/stocks

---------------------

Parameters

↓

symbol=D05
```

Parameters modify the request.

---

# Requests Handles Parameters

Instead of manually building URLs,

we write:

```python
params = {
    "symbol": "D05"
}

response = requests.get(
    url,
    params=params
)
```

The library constructs the URL automatically.

---

# What Are Headers?

Headers contain additional information about the request.

Examples include:

```text
Authentication

Content Type

User Agent

API Key
```

Think of headers as metadata.

---

# Example Header

```python
headers = {
    "Authorization": "Bearer TOKEN"
}
```

Some financial APIs require authentication.

We'll learn about API keys later.

---

# Understanding Timeouts

Imagine a server never responds.

Without protection,

our application freezes forever.

This is bad.

---

# Setting Timeouts

Professional applications always specify timeouts.

Example:

```python
response = requests.get(
    url,
    timeout=10
)
```

This means:

```text
Wait at most 10 seconds.
```

After that,

raise an error.

---

# Why Timeouts Matter

Imagine:

```text
User clicks Search

↓

Server crashes

↓

Application freezes forever
```

Users hate frozen applications.

Timeouts prevent this.

---

# Exception Handling

Networks fail.

Servers crash.

Internet connections disappear.

Professional code assumes failure.

---

# Example

```python
try:

    response = requests.get(
        url,
        timeout=10
    )

except Exception:

    print("Request failed")
```

This prevents our program from crashing.

---

# The Complete Request Lifecycle

Let's follow a request.

```text
User clicks Search

↓

Callback

↓

MarketDataService

↓

requests.get()

↓

Internet

↓

Financial API

↓

HTTP Response

↓

Status Code

↓

JSON

↓

Python Dictionary

↓

Dashboard
```

Everything we've learned now fits together.

---

# Building Our MarketDataService

Eventually,

our service may contain methods like:

```python
class MarketDataService:

    def get_stock():

        ...

    def get_history():

        ...

    def get_news():

        ...
```

Each method will:

* create requests
* check status codes
* handle failures
* convert JSON
* return Python objects

---

# Separation of Responsibilities

Notice what the dashboard never does.

The dashboard never:

* builds URLs
* performs HTTP requests
* parses JSON
* handles status codes
* handles timeouts

Instead:

```text
Dashboard

↓

MarketDataService

↓

API
```

This architecture remains clean and maintainable.

---

# Thinking Like a Software Engineer

Beginners often think:

```text
Get Data

↓

Display Data
```

Professional engineers think:

```text
Request

↓

Validate

↓

Handle Errors

↓

Parse

↓

Normalize

↓

Return
```

Retrieving data reliably is much more important than retrieving it quickly.

---

# Teacher's Notes

> Networking code is one of the first places where beginners encounter the unpredictability of real-world software engineering. Unlike local code execution, network operations depend on external systems that may be slow, unavailable, or malfunctioning. For this reason, production-quality networking code always includes validation, error handling, timeouts, retries, and fallback mechanisms.
>
> Another important observation is that the `requests` library intentionally hides enormous complexity. Behind a single line of Python code lies DNS resolution, TCP connection establishment, TLS encryption, HTTP message construction, packet routing, response parsing, and connection teardown. Libraries exist to abstract this complexity so developers can focus on solving business problems.

---

# Common Mistakes

## ❌ Mistake 1

Assuming network requests always succeed.

Networks fail constantly.

---

## ❌ Mistake 2

Not specifying timeouts.

Applications may freeze indefinitely.

---

## ❌ Mistake 3

Ignoring status codes.

Always validate server responses.

---

## ❌ Mistake 4

Putting API code inside the Panel dashboard.

Keep networking inside the service layer.

---

## ❌ Mistake 5

Constructing URLs manually.

Use parameters whenever possible.

---

# Summary

In this lesson, you learned:

* HTTP requests allow applications to communicate with APIs.
* URLs identify resources on remote servers.
* API endpoints provide access to different services.
* Python uses the `requests` library to communicate with APIs.
* The GET method retrieves information.
* Status codes indicate the success or failure of requests.
* Query parameters and headers provide additional information.
* Timeouts prevent applications from freezing.
* Exception handling protects applications from network failures.
* Our `MarketDataService` is responsible for all API communication.

We now know how to send requests. The next step is learning how to process real responses and convert them into useful Python objects.

---

# Exercises

## Exercise 1 — Trace the Request Lifecycle

Draw a diagram showing the complete flow of a request beginning with:

```text
User clicks Search
```

and ending with:

```text
Dashboard displays stock price
```

Include every major component.

---

## Exercise 2 — Explain the Purpose

Explain why each of the following exists:

* URL
* Endpoint
* GET request
* Status code
* Timeout
* Exception handling

---

## Exercise 3 — Why Use a Service Layer?

Suppose a beginner places this code inside a Panel button callback:

```python
requests.get(...)
```

Discuss:

* Why this may become difficult to maintain.
* How `MarketDataService` improves the design.
* Which software engineering principles are being applied.

---

# Coming Up Next

In **Lesson 5.4 — Parsing API Responses: Converting JSON into Python Objects**, we'll learn how to process real API responses using Python's built-in `json` capabilities. You'll learn how `response.json()` works, how to navigate nested dictionaries and lists, how to safely access missing values, and how to normalize complex financial API responses into clean data structures that our SGX Stock Monitor can display reliably. This lesson bridges the gap between raw API communication and usable application data.
