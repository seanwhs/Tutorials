# Part II — Widgets: Building Interactive User Interfaces

# Lesson 2.11 — Serving and Running Panel Applications

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what happens when a Panel application runs.
> * Learn the role of the Bokeh Server.
> * Understand the client-server architecture of Panel.
> * Learn how `panel serve` works.
> * Understand browser sessions.
> * Learn the Panel application lifecycle.
> * Organize a Panel project for development.
> * Run the SGX Stock Monitor as a real web application.

---

# Introduction

Throughout this tutorial, we've been writing code like this:

```python
dashboard.servable()
```

or

```python
template.servable()
```

But...

have you ever wondered:

> **How does this Python program become a webpage?**

After all,

Python normally runs in a terminal.

Yet somehow,

our browser displays a beautiful dashboard.

Today's lesson explains the magic behind the scenes.

---

# A Common Beginner Misunderstanding

Many beginners imagine something like this.

```text
Python

↓

HTML

↓

Browser
```

Unfortunately,

that's not how Panel works.

Instead,

Panel uses a web server.

---

# The Real Architecture

When you launch a Panel application,

the architecture looks like this.

```text
Browser

        ⇅

Panel Server (Bokeh Server)

        ⇅

Python Application
```

Notice something important.

The browser and Python are continuously communicating.

This communication allows the application to remain interactive.

---

# Why Do We Need a Server?

Imagine a calculator.

You type

```text
2 + 2
```

Someone has to perform the calculation.

Should the browser execute our Python code?

No.

Browsers understand:

* HTML
* CSS
* JavaScript

Browsers do **not** execute Python directly.

Instead,

they send requests to a Python server.

---

# What Is a Server?

A **server** is simply a program that waits for requests from other programs.

Think of a waiter in a restaurant.

```text
Customer

↓

Order

↓

Waiter

↓

Kitchen

↓

Waiter

↓

Customer
```

The waiter doesn't cook.

The waiter carries messages.

A web server works similarly.

---

# The Panel Server

Panel applications run on top of the **Bokeh Server**.

Think of the Bokeh Server as the bridge between:

Python

and

your web browser.

```text
Python

↓

Bokeh Server

↓

Browser
```

Panel builds on top of Bokeh, adding higher-level widgets, layouts, templates, and reactive programming.

---

# Starting the Server

Instead of running

```bash
python app.py
```

we usually run

```bash
panel serve app.py
```

Notice the difference.

We're no longer simply executing Python.

We're starting a web server.

---

# What Happens Internally?

When you run

```bash
panel serve app.py
```

Panel performs several steps.

```text
Read app.py

↓

Execute Python Code

↓

Create Widgets

↓

Create Layout

↓

Start Bokeh Server

↓

Wait For Browser Connections
```

The application is now ready to receive users.

---

# Opening the Browser

After the server starts,

you'll see something similar to:

```text
Launching server at:

http://localhost:5006/app
```

You open that address in your browser.

The browser then connects to the running server.

---

# Understanding `localhost`

Many beginners are confused by

```text
localhost
```

It simply means:

> **This computer.**

Imagine mailing a letter to yourself.

The letter never leaves your house.

Similarly,

requests sent to

```text
localhost
```

never leave your computer.

---

# Understanding Port Numbers

Notice this part.

```text
5006
```

This is called a **port**.

Think of a large office building.

```text
Building

↓

Room 5006
```

Many applications can live on the same computer,

each listening on a different port.

Example

```text
localhost:5006

localhost:8000

localhost:8080
```

Each port belongs to a different application.

---

# What Happens When You Click Search?

Suppose the user types

```text
DBS
```

and clicks Search.

The sequence looks like this.

```text
Browser

↓

Button Click

↓

Panel Server

↓

Python Callback

↓

Update Markdown Pane

↓

Browser Updates
```

Notice something.

The callback executes **inside Python**,

not inside the browser.

---

# Following the Complete Journey

Let's trace every step.

```text
User

↓

Browser

↓

Button Click

↓

Server Receives Event

↓

Callback Executes

↓

results.object Changes

↓

Server Sends Update

↓

Browser Refreshes Display
```

This entire process usually takes only milliseconds.

---

# Browser Sessions

Suppose two people visit your application.

Person A

opens the dashboard.

Person B

also opens the dashboard.

Do they share the same widgets?

No.

Each user gets a separate **session**.

---

# Understanding Sessions

Imagine visiting a library.

Each visitor gets their own desk.

```text
Library

├── Desk A

├── Desk B

├── Desk C
```

Everyone works independently.

Panel works the same way.

Each browser receives its own copy of the application state.

---

# Why Sessions Matter

Suppose Person A searches

```text
DBS
```

while Person B searches

```text
Singtel
```

If sessions didn't exist,

both users would constantly overwrite each other's data.

Sessions prevent this.

---

# Application Lifecycle

Every Panel application follows roughly the same lifecycle.

```text
Application Starts

↓

Server Starts

↓

Browser Connects

↓

Session Created

↓

Widgets Created

↓

User Interacts

↓

Callbacks Execute

↓

Browser Disconnects

↓

Session Destroyed
```

Understanding this lifecycle is extremely helpful when debugging applications.

---

# What Does `servable()` Do?

Earlier,

we wrote

```python
dashboard.servable()
```

What exactly does this do?

It tells Panel:

> **Expose this object to the web server.**

Without calling

```python
.servable()
```

the server has nothing to display.

---

# Multiple Servable Objects

Interestingly,

more than one object can be servable.

```python
title.servable()

controls.servable()

results.servable()
```

However,

this is uncommon.

Most applications expose a single top-level layout or template.

```python
template.servable()
```

---

# Typical Project Structure

As projects grow,

it's useful to organize files.

```text
sgx-monitor/

│

├── app.py

├── data.py

├── charts.py

├── widgets.py

├── layouts.py

├── services.py

├── requirements.txt

└── README.md
```

Rather than putting everything into one enormous file,

each module has a clear responsibility.

---

# Running the Project

Open a terminal.

Navigate to your project folder.

```bash
cd sgx-monitor
```

Then start the server.

```bash
panel serve app.py
```

Panel starts the application.

Open your browser.

Visit

```text
http://localhost:5006/app
```

Your dashboard appears.

---

# Development Workflow

Most Panel developers follow this cycle.

```text
Write Code

↓

Save File

↓

Restart Server (or Auto Reload)

↓

Refresh Browser

↓

Test Application

↓

Repeat
```

This iterative workflow is common across web development.

---

# Auto Reload During Development

While developing,

you can use:

```bash
panel serve app.py --autoreload
```

Now,

whenever you save your Python file,

Panel automatically reloads the application.

This saves a tremendous amount of time.

---

# Running Multiple Applications

Panel can even serve several applications simultaneously.

Example:

```bash
panel serve stocks.py portfolio.py news.py
```

Each application receives its own URL.

```text
localhost:5006/stocks

localhost:5006/portfolio

localhost:5006/news
```

This is useful for larger projects.

---

# Thinking Like a Web Developer

Earlier in the tutorial,

we viewed our application like this.

```text
Python Script
```

Now,

we should think of it as

```text
Web Application

↓

Server

↓

Browser

↓

Users
```

This mental shift is important.

You are no longer writing scripts.

You are building interactive web applications.

---

# Teacher's Notes

> One of the biggest conceptual shifts for beginners is understanding that Panel applications remain alive after they start. Unlike traditional Python programs that execute from top to bottom and terminate, a Panel application continues running inside the server, waiting for user interactions. Every click, text entry, or slider movement generates events that the server processes before updating the browser. This event-driven lifecycle is fundamental to nearly all modern web frameworks.

---

# Common Mistakes

## ❌ Mistake 1

Running:

```bash
python app.py
```

instead of:

```bash
panel serve app.py
```

Remember,

Panel applications are served,

not merely executed.

---

## ❌ Mistake 2

Thinking the browser runs Python.

It doesn't.

Python runs on the server.

The browser displays the user interface.

---

## ❌ Mistake 3

Forgetting to call:

```python
.servable()
```

Without a servable object,

the server has nothing to display.

---

## ❌ Mistake 4

Putting every feature into one giant `app.py`.

As applications grow,

split functionality into logical modules.

Your future self—and your teammates—will thank you.

---

# Summary

In this lesson, you learned:

* Panel applications run using the **Bokeh Server**.
* `panel serve app.py` starts a web server.
* Browsers communicate with the server rather than running Python directly.
* Each connected browser receives its own application session.
* `.servable()` exposes objects to the server.
* Panel applications follow a continuous event-driven lifecycle.
* Organizing your project into modules makes larger applications easier to maintain.

Our SGX Stock Monitor is now a **true web application**. It is no longer just a collection of widgets—it runs on a server, communicates with browsers, manages user sessions, and responds to user interactions in real time.

---

# Exercises

## Exercise 1 — Serve Your Application

Start your SGX Stock Monitor using:

```bash
panel serve app.py
```

Open the application in your browser.

Verify that:

* The page loads successfully.
* The Search button works.
* The results pane updates correctly.

---

## Exercise 2 — Experiment with Auto Reload

Run:

```bash
panel serve app.py --autoreload
```

Make a small change to your application, such as updating the page title.

Save the file and observe how the server automatically reloads the application.

---

## Exercise 3 — Draw the Architecture

Without referring to the lesson, sketch the architecture of a Panel application.

Include:

* Browser
* Panel/Bokeh Server
* Python Application
* Callback
* User Interaction

Show how information flows between each component.

---

# Coming Up Next

In **Part III — Data Sources and Market Data**, we'll shift our focus from building the user interface to working with **real SGX stock data**. You'll learn how to retrieve financial information from external APIs, understand JSON responses, work with the `requests` library, and transform raw market data into Python objects. By the end of Part III, our SGX Stock Monitor will move beyond placeholder messages and begin displaying live stock information from real-world data sources.
