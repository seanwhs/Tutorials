# Part I — Foundations

# Lesson 1.2 — How Web Applications Work

## Learning Objectives

By the end of this lesson, you will be able to:

* Explain the client-server architecture.
* Describe the role of the browser.
* Describe the role of the server.
* Understand what happens when you click a button in a web application.
* Explain the concepts of requests and responses.
* Understand why Panel applications still use client-server communication even though they are written entirely in Python.

---

# Before We Write Code...

Imagine opening your future SGX Stock Monitor.

You type:

```text
DBS
```

into the search box.

Almost immediately, the application displays information about DBS Group Holdings.

It might even display:

* Current price
* Daily gain/loss
* Trading volume
* Historical chart
* Company information

Have you ever wondered...

> **How did the application know what to display?**

Did it already know everything?

Did it magically know the stock price?

Where did the information come from?

To answer these questions, we need to understand how modern web applications work.

---

# The Two Main Players

Almost every web application consists of two major parts.

```text
          Web Application

        ┌──────────────┐
        │   Browser    │
        └──────┬───────┘
               │
        Internet
               │
        ┌──────▼───────┐
        │    Server    │
        └──────────────┘
```

These two computers continuously communicate with one another.

Let's understand each one.

---

# What Is the Browser?

## What?

A browser is the software you use to access websites and web applications.

Examples include:

* Google Chrome
* Microsoft Edge
* Mozilla Firefox
* Safari
* Opera

The browser is responsible for displaying everything the user sees.

---

## What Does the Browser Do?

The browser displays:

* Text
* Images
* Buttons
* Charts
* Tables
* Forms
* Menus
* Widgets

Think of the browser as the **presentation layer**.

Its job is to display information and collect user input.

For example:

```text
Search

[ DBS____________ ]

[ Search ]
```

The browser knows:

* what you typed
* which button you clicked
* which table row you selected

However...

The browser usually **does not know the answer**.

It simply asks another computer.

---

# What Is the Server?

## What?

A server is another computer running somewhere else.

Sometimes:

* your laptop

Sometimes:

* your office computer

Sometimes:

* a cloud service

Examples:

* AWS
* Azure
* Google Cloud

For this tutorial, your own computer will initially act as the server.

---

## What Does the Server Do?

The server performs the heavy work.

Examples include:

* Searching databases
* Downloading SGX prices
* Performing calculations
* Saving portfolios
* Creating charts
* Returning results

Think of the server as the **brain** of the application.

---

# A Restaurant Analogy

Imagine visiting a restaurant.

Who do you interact with?

The waiter.

The waiter brings food.

The waiter collects your order.

But...

Does the waiter cook?

No.

The kitchen does.

Think of it like this.

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

Now compare that to a web application.

```text
User

↓

Browser

↓

Server

↓

Browser

↓

User
```

The browser is like the waiter.

The server is like the kitchen.

---

# What Happens When You Search for DBS?

Let's walk through every step.

---

## Step 1

The application starts.

Nothing has happened yet.

```text
+--------------------------------------+

Search

[______________]

+--------------------------------------+
```

---

## Step 2

The user types:

```text
DBS
```

The browser now knows what the user typed.

The server still knows nothing.

---

## Step 3

The user presses Search.

Now something important happens.

The browser sends a **request**.

```text
Browser

Search "DBS"

────────────►

Server
```

---

# What Is a Request?

## What?

A request is simply a message asking another computer to perform some work.

Think of it like asking someone a question.

Example:

> Can you tell me the current price of DBS?

That is essentially what the browser is asking.

---

# What Information Does a Request Contain?

Suppose we search for DBS.

The request might contain:

```text
Search Term

DBS
```

Or

```text
Ticker

D05
```

The exact format is unimportant for now.

The important idea is this:

A request contains information the server needs.

---

# Step 4

The server receives the request.

```text
Browser

Search DBS

────────────►

Server
```

Now the server starts working.

It may:

* query a database
* call a stock market API
* calculate values
* prepare data

---

# Step 5

Suppose the server downloads:

```text
Company

DBS Group Holdings

Price

48.23 SGD

Change

+1.21%
```

The server now prepares a response.

---

# What Is a Response?

## What?

A response is the answer returned by the server.

The browser asked:

> Tell me about DBS.

The server replies:

```text
Company

DBS Group Holdings

Price

48.23

Change

+1.21%
```

That answer is called the response.

---

# Step 6

The response travels back.

```text
Browser

◄────────────

DBS

48.23

+1.21%

Server
```

---

# Step 7

The browser updates the screen.

```text
+------------------------------------+

DBS Group Holdings

Price

48.23

Change

+1.21%

+------------------------------------+
```

The user sees the new information.

The interaction is complete.

---

# The Complete Cycle

Everything happens surprisingly quickly.

```text
User

↓

Types DBS

↓

Clicks Search

↓

Browser Sends Request

↓

Server Processes Request

↓

Server Sends Response

↓

Browser Updates Screen

↓

Wait for Next User Action
```

This process repeats every time you interact with a web application.

---

# Where Does Panel Fit In?

Now let's relate this to Panel.

Many beginners imagine that because Panel is written in Python, everything happens in one place.

Not quite.

A Panel application still follows a client-server architecture.

```text
               Panel Application

        Browser (User Interface)

                 │

         WebSocket Connection

                 │

        Python Panel Server

                 │

        Stock Data Service

                 │

          SGX Market Data
```

The difference is that **Panel hides much of the complexity**.

You don't have to manually write:

* HTML
* CSS
* JavaScript
* Browser event handlers
* AJAX requests
* DOM manipulation

Instead, you write Python, and Panel coordinates the communication between the browser and your Python application.

---

# Teacher's Notes

> **A common misunderstanding is that Panel "runs inside the browser."**
>
> It does not.
>
> Your Python code runs on the server (which may simply be your own computer during development). The browser displays the interface and communicates with the Python process behind the scenes.
>
> Panel manages this communication for you, allowing you to focus on writing Python rather than web infrastructure.

---

# Common Mistakes

### ❌ Mistake 1

Thinking the browser downloads stock prices directly.

Usually, it asks the server to do it.

---

### ❌ Mistake 2

Thinking Python runs inside Chrome.

Normally it doesn't.

Python runs in a separate process.

---

### ❌ Mistake 3

Thinking every click reloads the entire webpage.

Modern web applications—including Panel applications—typically update only the parts of the interface that have changed.

---

# Summary

In this lesson, you learned that:

* A web application is built around communication between a **browser** and a **server**.
* The browser displays the interface and collects user input.
* The server performs calculations, retrieves data, and prepares responses.
* User actions generate **requests**, and the server answers with **responses**.
* Panel applications follow the same client-server model, but Panel hides much of the underlying web complexity, allowing you to build interactive applications using Python alone.

In the next lesson, we'll build on this foundation by exploring **traditional web development** in more detail. Understanding the complexity of HTML, CSS, JavaScript, and backend frameworks will make it much clearer why Panel—and the broader HoloViz ecosystem—provide such a compelling alternative for Python developers.
