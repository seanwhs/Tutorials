# Part III — Working with Real SGX Market Data

# Lesson 3.6 — Error Handling and Building Reliable Network Applications

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why network applications fail.
> * Learn the principles of defensive programming.
> * Handle HTTP errors gracefully.
> * Handle connection failures and timeouts.
> * Detect invalid API responses.
> * Validate data before using it.
> * Build user-friendly error messages.
> * Understand logging versus displaying errors.
> * Learn why robust error handling is a hallmark of professional software.
> * Prepare our SGX Stock Monitor for real-world usage.

---

# Introduction

So far, everything has worked perfectly.

Our application:

* Sends a request
* Receives a response
* Converts JSON into Python
* Extracts stock information

It seems easy.

Unfortunately...

the real world isn't perfect.

Consider these situations:

* Your Wi-Fi disconnects.
* The API server crashes.
* The stock symbol doesn't exist.
* The server returns invalid data.
* The request takes too long.
* The API limit has been exceeded.
* The Internet connection is unstable.

What should our application do?

Should it crash?

Of course not.

Today's lesson is about making our application reliable.

---

# The Reality of Software Engineering

Many beginner tutorials look like this.

```python
response = requests.get(url)

data = response.json()

price = data["price"]
```

Everything assumes success.

Professional software never makes this assumption.

Instead,

professionals ask

> **"What could go wrong?"**

This mindset is called

**defensive programming**.

---

# What Is Defensive Programming?

Defensive programming means

> **Writing software that expects mistakes, failures, and unexpected situations.**

Instead of assuming everything works,

we assume something eventually won't.

---

# Why Defensive Programming Matters

Imagine our SGX dashboard is running on a teacher's computer.

A student asks,

> "What's the current DBS price?"

The teacher clicks

```text
Search
```

At exactly that moment,

the school's Wi-Fi disconnects.

Should the application suddenly close?

Should Python display a frightening traceback?

No.

The application should explain the problem politely and continue running.

---

# Types of Failures

Let's explore the kinds of failures we may encounter.

---

## Failure 1 — No Internet Connection

The computer cannot reach the server.

```text
Panel App

↓

Internet

❌

Server
```

The request never arrives.

---

## Failure 2 — Server Offline

The Internet works,

but the server has crashed.

```text
Panel App

↓

Internet

↓

Server

❌ Offline
```

Again,

no useful response arrives.

---

## Failure 3 — Request Timeout

The server is still running.

However,

it responds too slowly.

```text
Request

↓

Waiting...

↓

Waiting...

↓

Waiting...

↓

Timeout
```

We don't want users waiting forever.

---

## Failure 4 — Invalid Stock Symbol

Suppose the user searches

```text
ABCDEFG123456
```

The company doesn't exist.

The server replies

```text
404

Not Found
```

This isn't a programming error.

It's a valid situation our application should handle.

---

## Failure 5 — API Rate Limit

Many APIs limit requests.

Example:

100 requests per minute.

If we exceed the limit,

the server responds

```text
429

Too Many Requests
```

Our application should explain this clearly.

---

## Failure 6 — Invalid JSON

Sometimes,

servers return unexpected data.

Instead of JSON,

the response might contain

```html
<html>

Server Error

</html>
```

Calling

```python
response.json()
```

would fail.

---

# Our Goal

Instead of this:

```text
User

↓

Application Crashes
```

we want

```text
User

↓

Friendly Message

↓

Application Continues Running
```

---

# Step 1 — Catch Network Errors

We already learned

```python
try:
    ...
except:
    ...
```

Now we'll apply it properly.

```python
import requests

try:

    response = requests.get(

        url,

        timeout=10

    )

except requests.RequestException as error:

    print(error)
```

This catches many networking problems.

---

# Why Catch Exceptions?

Suppose

```python
requests.get()
```

fails.

Without

```python
try
```

Python stops immediately.

The user sees something like

```text
Traceback...

ConnectionError...
```

Most users don't understand tracebacks.

Professional applications hide these technical details.

---

# Understanding Specific Exceptions

The `requests` library provides several specialized exceptions.

Examples include:

| Exception          | Meaning                           |
| ------------------ | --------------------------------- |
| `ConnectionError`  | Cannot connect to server          |
| `Timeout`          | Server took too long              |
| `HTTPError`        | HTTP request failed               |
| `TooManyRedirects` | Redirect loop                     |
| `RequestException` | Base class for all request errors |

Notice that

```python
RequestException
```

is the parent class.

Catching it handles many networking problems at once.

---

# Step 2 — Check the Status Code

Receiving a response

doesn't automatically mean success.

Example

```python
response = requests.get(...)
```

may return

```text
404
```

The request succeeded.

But the requested resource doesn't exist.

---

Always check

```python
response.status_code
```

Example

```python
if response.status_code == 200:

    print("Success")

else:

    print("Something went wrong.")
```

---

# Step 3 — Validate JSON

Even if

```text
200 OK
```

is returned,

the response might not contain valid JSON.

Therefore,

calling

```python
response.json()
```

may still fail.

Wrap JSON parsing inside

```python
try
```

as well.

Conceptually,

our program becomes

```text
Download Response

↓

Try Parsing JSON

↓

Success?

↓

Yes → Continue

↓

No → Display Error
```

---

# Step 4 — Validate Required Fields

Suppose the API returns

```python
{
    "company": "DBS"
}
```

Where is the price?

It's missing.

Should we display

```text
Price: None
```

No.

Instead,

we validate before displaying.

Example logic:

```text
Does price exist?

↓

Yes

↓

Display Price

──────────────

No

↓

Display

"Price unavailable"
```

---

# Never Trust External Data

One of the most important principles in software engineering is:

> **Never trust data you don't control.**

External systems can:

* omit fields
* rename fields
* return incorrect values
* return incomplete responses

Always validate.

---

# User-Friendly Error Messages

Consider these two messages.

---

Message A

```text
ConnectionError:
HTTPSConnectionPool...
```

---

Message B

```text
Unable to retrieve market data.

Please check your Internet connection
and try again.
```

Which one helps the user?

Obviously,

Message B.

---

# Logging vs Displaying Errors

Professional applications often do two things.

They display a friendly message.

AND

they log the technical details.

```text
User

↓

Friendly Message

────────────

Developer

↓

Detailed Log
```

The user doesn't need to see stack traces.

Developers do.

---

# Example Workflow

Imagine this sequence.

```text
Search Button

↓

Download Data

↓

Connection Failed

↓

Catch Exception

↓

Log Error

↓

Display Friendly Message

↓

Application Continues
```

Notice that the application never crashes.

---

# Thinking Like a Professional

Beginners often ask:

> "How do I make this code work?"

Professionals ask:

> "How will this behave when something goes wrong?"

This small change in mindset produces dramatically more reliable software.

---

# Error Handling Layers

Notice how many opportunities exist for failure.

```text
User

↓

Button Click

↓

HTTP Request

↓

Network

↓

Server

↓

Response

↓

JSON Parsing

↓

Data Validation

↓

Panel Dashboard
```

Every layer should be prepared for failure.

---

# Our Future Market Data Service

Soon,

our service will look something like this.

```text
MarketDataService

↓

Download

↓

Validate Status

↓

Parse JSON

↓

Validate Fields

↓

Create Clean Dictionary

↓

Return Result
```

If anything fails,

the service—not the user interface—handles the problem.

---

# Separation of Concerns

Notice something important.

Should the Panel dashboard know about

* ConnectionError
* Timeout
* HTTPError
* Invalid JSON

Not really.

Instead,

the service layer should deal with those problems.

The dashboard simply displays either:

```text
Stock Information
```

or

```text
Unable to retrieve market data.
```

This keeps the user interface clean.

---

# Preparing for Production

Many beginner applications work well in demonstrations.

They fail immediately in production because they assume:

* Internet is always available.
* APIs never change.
* Servers never crash.
* Data is always complete.

Real software cannot make these assumptions.

---

# Teacher's Notes

> Error handling is often overlooked in beginner tutorials because it makes examples longer. However, experienced software engineers spend a significant portion of their time designing systems that continue working even when external services fail.
>
> One useful mental model is to imagine every external dependency as unreliable. Networks disconnect, APIs change, servers restart, and users make mistakes. Good software anticipates these situations and responds gracefully instead of crashing. Throughout the rest of this tutorial, we'll continue applying this philosophy whenever we interact with external systems.

---

# Common Mistakes

## ❌ Mistake 1

Assuming every HTTP request succeeds.

Always prepare for network failures.

---

## ❌ Mistake 2

Ignoring HTTP status codes.

A response with status `404` or `500` should not be treated as valid data.

---

## ❌ Mistake 3

Trusting every JSON response.

Always validate the contents before using them.

---

## ❌ Mistake 4

Displaying raw Python exceptions to users.

Technical details belong in logs, not in the user interface.

---

## ❌ Mistake 5

Mixing error handling with UI code.

Networking code should detect and handle errors before returning results to the Panel dashboard.

---

## ❌ Mistake 6

Thinking defensive programming is pessimistic.

It's not.

It's realistic.

Professional software assumes failures will happen eventually.

---

# Summary

In this lesson, you learned:

* Real-world network applications encounter many types of failures.
* Defensive programming means anticipating and handling those failures gracefully.
* Catch network exceptions using `try` / `except`.
* Always inspect HTTP status codes before processing responses.
* Validate JSON before extracting data.
* Check that required fields exist before displaying them.
* Show users friendly error messages while keeping technical details in logs.
* Keep networking and error handling inside the service layer rather than the Panel UI.
* Building reliable software is about more than making it work—it's about making it continue working when things go wrong.

Our SGX Stock Monitor is now designed with reliability in mind. The next step is to organize all of this networking, parsing, validation, and error handling into a reusable component that follows sound software engineering principles.

---

# Exercises

## Exercise 1 — Identify Possible Failures

Consider the following workflow:

```text
User

↓

Search Button

↓

HTTP Request

↓

API

↓

JSON

↓

Dashboard
```

For each step, list one thing that could go wrong and explain how your application should respond.

---

## Exercise 2 — Friendly Error Messages

Write user-friendly messages for each of the following situations:

* No Internet connection
* API server unavailable
* Invalid stock symbol
* API rate limit exceeded
* Market data temporarily unavailable

Avoid using technical jargon or Python exception names.

---

## Exercise 3 — Defensive Programming Review

Review the following sequence:

1. Send an HTTP request.
2. Receive a response.
3. Parse the JSON.
4. Extract the stock price.
5. Display it on the dashboard.

For each step, identify:

* What assumptions are being made.
* What validation should occur.
* What should happen if validation fails.

---

# Coming Up Next

In **Lesson 3.7 — Designing a Market Data Service**, we'll combine everything we've learned so far into a well-structured Python component. We'll design a dedicated `MarketDataService` class that encapsulates HTTP communication, JSON parsing, validation, data transformation, and error handling behind a clean interface. This lesson introduces important software engineering concepts such as **abstraction**, **encapsulation**, **separation of concerns**, and **service-oriented design**, while preparing our Panel application for future enhancements like watchlists, historical charts, and real-time market updates.
