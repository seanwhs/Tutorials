# Part III — Working with Real SGX Market Data

# Lesson 3.3 — Working with the `requests` Library

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what the `requests` library is.
> * Learn why Python needs a networking library.
> * Install and import `requests`.
> * Send your first HTTP GET request.
> * Understand the `Response` object.
> * Inspect HTTP status codes.
> * Read response headers.
> * Retrieve response bodies.
> * Handle common network errors.
> * Prepare to connect our SGX Stock Monitor to a live market data API.

---

# Introduction

In the previous lesson, we learned about HTTP.

We now understand that our application communicates with APIs using HTTP requests and responses.

However,

knowing HTTP isn't enough.

We need Python code that can actually send those requests.

That's exactly what the `requests` library does.

Today we'll learn one of the most popular Python libraries ever created.

---

# What Is `requests`?

`requests` is a third-party Python library for sending HTTP requests.

It allows Python programs to communicate with:

* Web APIs
* Websites
* Cloud services
* AI services
* Financial data providers
* Internal company systems

If an application exposes an HTTP API,

`requests` can usually communicate with it.

---

# Why Doesn't Python Do This Automatically?

A common beginner question is:

> "Why do we need another library? Doesn't Python already know how to use the Internet?"

Actually,

Python already includes networking modules in its standard library.

For example:

```python
urllib.request
```

However,

they are relatively low-level and can be more verbose to use.

The `requests` library provides a simpler,

cleaner,

and more readable interface.

---

# Without `requests`

Older Python networking code often looks intimidating.

```python
import urllib.request

response = urllib.request.urlopen(url)
data = response.read()
```

This works,

but it quickly becomes more complicated as applications grow.

---

# With `requests`

The same operation becomes

```python
import requests

response = requests.get(url)
```

Much simpler.

This simplicity is one reason why `requests` has become one of Python's most widely used libraries.

---

# Why Professionals Love `requests`

The `requests` library is:

* Easy to learn
* Easy to read
* Reliable
* Well documented
* Widely supported
* Used in countless production systems

Many web services provide examples using `requests` because it has become the de facto standard for making HTTP requests in Python.

---

# Installing `requests`

Unlike Panel,

`requests` is not part of the Python standard library.

If it is not already installed,

open a terminal and run:

```bash
pip install requests
```

---

If you're using a virtual environment,

install it there instead.

```bash
pip install requests
```

Always install project dependencies inside your project's virtual environment whenever possible.

---

# Importing the Library

Like every Python module,

we must import it.

```python
import requests
```

Once imported,

we gain access to all of its functions.

---

# Our First HTTP Request

Let's send our first request.

```python
import requests

response = requests.get("https://example.com")
```

Don't worry about the website itself.

We're focusing on understanding the code.

---

# Understanding the Code

Let's examine each line.

```python
import requests
```

Imports the library.

---

```python
requests.get(...)
```

Calls the `get()` function.

This sends an HTTP GET request.

---

```python
response =
```

Stores the server's reply inside a variable named `response`.

---

# Visualizing What Happens

```text
Python Program

↓

requests.get()

↓

Internet

↓

Web Server

↓

Response

↓

Python Variable
```

Notice that `requests.get()` communicates across the Internet.

---

# What Is the Response Object?

The server doesn't simply return text.

Instead,

it returns a **Response object**.

```python
response = requests.get(...)
```

Think of this object as a package containing everything the server sent back.

---

# Inside the Response Object

Conceptually,

the object contains:

```text
Response

├── Status Code

├── Headers

├── Body

├── Encoding

├── URL

└── Other Information
```

We'll explore each part.

---

# Checking the Status Code

One of the first things we should inspect is

```python
response.status_code
```

Example:

```python
print(response.status_code)
```

Output

```text
200
```

Remember from the previous lesson,

`200` means

> The request succeeded.

---

# Why Check the Status Code?

Imagine ordering food online.

The restaurant replies:

```text
Sorry,

we're closed.
```

You wouldn't expect food to arrive.

Similarly,

if an API returns

```text
404
```

or

```text
500
```

we shouldn't assume valid data exists.

Always verify the request succeeded before processing the response.

---

# Viewing the Response Headers

Earlier,

we learned that HTTP responses contain headers.

We can inspect them.

```python
print(response.headers)
```

Output might resemble

```text
{
    "Content-Type": "text/html",
    "Server": "...",
    ...
}
```

Headers describe the response.

---

# What Is the Response Body?

The **body** contains the actual information we requested.

For a webpage,

the body usually contains HTML.

For an API,

the body often contains JSON.

We'll study JSON in the next lessons.

---

# Reading Text Responses

If the server returns text,

we can access it using

```python
response.text
```

Example

```python
print(response.text)
```

This displays the body as a Python string.

---

# Example Flow

```python
import requests

response = requests.get("https://example.com")

print(response.status_code)

print(response.text)
```

Execution flow:

```text
Send Request

↓

Receive Response

↓

Check Status

↓

Display Body
```

---

# Understanding the Request Lifecycle

Whenever we call

```python
requests.get(...)
```

the following occurs:

```text
Python

↓

Create HTTP Request

↓

Internet

↓

Server

↓

Server Processes Request

↓

HTTP Response

↓

Python
```

Although this usually happens in milliseconds,

many things occur behind the scenes.

---

# Requests Can Fail

The Internet isn't perfect.

Sometimes:

* Your Wi-Fi disconnects.
* The server is offline.
* The API is overloaded.
* A firewall blocks the connection.
* The request takes too long.

Applications must handle these situations gracefully.

---

# Example Problem

Suppose we write

```python
response = requests.get(url)
```

What if the server never replies?

Should our application wait forever?

Of course not.

That's why timeouts exist.

---

# Using a Timeout

A good habit is to specify a timeout.

```python
response = requests.get(

    url,

    timeout=10

)
```

Meaning:

> Wait at most 10 seconds.

If no response arrives,

raise an exception.

---

# Why Timeouts Matter

Imagine our SGX dashboard.

The user clicks

```text
Search
```

If the market data provider stops responding,

the application shouldn't freeze forever.

Timeouts improve user experience.

---

# Handling Exceptions

Whenever network communication is involved,

errors are possible.

We should use

```python
try
```

and

```python
except
```

Example:

```python
import requests

try:

    response = requests.get(

        "https://example.com",

        timeout=10

    )

    print(response.status_code)

except requests.RequestException as error:

    print(error)
```

---

# Understanding the Code

```python
try:
```

Attempt the request.

---

If everything succeeds,

the code continues normally.

---

If something fails,

Python jumps to

```python
except
```

instead of crashing.

---

# What Is `RequestException`?

`RequestException` is the base exception used by the `requests` library.

Many network-related errors inherit from it.

Examples include:

* Connection failures
* Timeouts
* Invalid URLs
* SSL errors

Catching `RequestException` is often a good starting point for beginners.

---

# Thinking Like an Engineer

A beginner often writes:

```python
response = requests.get(url)
```

A professional writes:

```python
try:

    response = requests.get(

        url,

        timeout=10

    )

except requests.RequestException:

    ...
```

Professionals assume that networks can and will fail.

---

# Our Future SGX Workflow

Soon,

our application will follow this sequence.

```text
User

↓

Search Button

↓

requests.get()

↓

Financial API

↓

Response

↓

Extract Stock Data

↓

Update Dashboard
```

Today's lesson introduced the first step.

---

# Should We Call `requests.get()` Inside the UI?

Technically,

yes.

But should we?

Not really.

Later,

we'll build a **Market Data Service**.

Instead of writing

```text
Button

↓

requests.get()
```

we'll use

```text
Button

↓

Market Data Service

↓

requests.get()

↓

API
```

This separation makes the application easier to test,

reuse,

and maintain.

---

# Teacher's Notes

> The `requests` library is one of the most important tools in a Python developer's toolkit. Although today's examples use simple websites, the same library is commonly used to interact with AI APIs, cloud services, payment gateways, weather providers, IoT devices, business systems, and financial data providers.
>
> One habit worth developing early is defensive programming. Never assume that a network request will always succeed. Always consider timeouts, unavailable servers, invalid responses, and unexpected errors. Applications that handle failures gracefully are significantly more reliable.

---

# Common Mistakes

## ❌ Mistake 1

Forgetting to install the library.

```bash
pip install requests
```

---

## ❌ Mistake 2

Ignoring the status code.

Always verify that the request succeeded before using the returned data.

---

## ❌ Mistake 3

Omitting a timeout.

Without a timeout,

your application may appear to hang if the server stops responding.

---

## ❌ Mistake 4

Allowing network exceptions to crash the program.

Wrap network calls in `try` / `except` blocks whenever appropriate.

---

## ❌ Mistake 5

Placing HTTP requests directly throughout the user interface code.

Instead,

centralize networking logic inside a dedicated service layer.

We'll build this later in Part III.

---

# Summary

In this lesson, you learned:

* The `requests` library simplifies HTTP communication in Python.
* Install it using `pip install requests`.
* Import it with `import requests`.
* Send HTTP GET requests using `requests.get()`.
* The returned `Response` object contains the status code, headers, and body.
* Always inspect `response.status_code` before processing data.
* Use `response.text` to access text responses.
* Specify a `timeout` to prevent indefinitely waiting for a server.
* Handle network problems with `try` / `except` and `requests.RequestException`.
* Networking logic should eventually be separated from the user interface into its own service layer.

Our SGX Stock Monitor now has the ability to communicate with the outside world. The next step is learning how to understand the data that APIs actually return.

---

# Exercises

## Exercise 1 — Your First Request

Write a Python program that:

* Imports the `requests` library.
* Sends a `GET` request to `https://example.com`.
* Prints the response status code.
* Prints the first few lines of the response body.

Observe what the server returns.

---

## Exercise 2 — Experiment with Timeouts

Modify your request to include:

```python
timeout=5
```

Then research and explain:

* Why timeouts are important.
* What could happen if no timeout is specified.
* Why financial applications should always use sensible timeout values.

---

## Exercise 3 — Explore the Response Object

Create a request and inspect:

* `response.status_code`
* `response.headers`
* `response.text`
* `response.url`

For each attribute, describe:

* What information it contains.
* Why it might be useful in a real application.

---

# Coming Up Next

In **Lesson 3.4 — Understanding JSON: The Language of APIs**, we'll learn the data format used by almost every modern web service. You'll discover why APIs rarely return plain text, understand JSON objects and arrays, learn how JSON maps naturally to Python dictionaries and lists, and use `response.json()` to convert API responses into Python data structures. This is the lesson where we'll begin turning raw API responses into meaningful stock information for our SGX Stock Monitor.
