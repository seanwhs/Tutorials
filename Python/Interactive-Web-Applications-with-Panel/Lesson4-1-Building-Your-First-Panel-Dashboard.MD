# Part IV — Building the Panel User Interface

# Lesson 4.1 — Introduction to Panel and Building Your First Dashboard

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what Panel is.
> * Learn why Panel was created.
> * Understand where Panel fits in the Python ecosystem.
> * Compare Panel with other Python web frameworks.
> * Install Panel.
> * Understand how a Panel application works.
> * Create your first Panel application.
> * Learn how Panel serves web applications.
> * Understand the basic architecture of every Panel project.
> * Build your first working dashboard.

---

# Introduction

So far,

we've spent a lot of time building the **backend** of our application.

We've designed:

* the project architecture
* the `MarketDataService`
* networking
* JSON parsing
* error handling
* data normalization

All of this code works behind the scenes.

But users can't see any of it.

Today's lesson changes that.

We're finally going to build something users can interact with.

We'll begin learning one of Python's most powerful dashboard frameworks:

> **Panel**

---

# What Is Panel?

Panel is a Python library for building

* dashboards
* data applications
* monitoring tools
* reporting systems
* interactive web applications

using **only Python**.

Unlike many web frameworks,

you don't need to write JavaScript,

HTML,

or CSS to build useful applications.

---

# Why Was Panel Created?

Imagine you're a data scientist.

You've written a Python program that analyzes thousands of stock prices.

Now your manager asks:

> "Can you turn this into a web application?"

Without Panel,

you might need to learn:

* HTML
* CSS
* JavaScript
* React
* Vue
* Angular

That's an enormous amount of additional knowledge.

Panel solves this problem.

It allows Python developers to create modern web applications without becoming frontend specialists.

---

# Where Does Panel Fit?

Consider the Python ecosystem.

```text
                Python

                   │

    ┌──────────────┼──────────────┐

    │              │              │

 NumPy          Pandas         Requests

    │              │              │

    └──────────────┼──────────────┘

                   │

                Panel

                   │

          Interactive Dashboard
```

Notice something important.

Panel doesn't replace libraries like

* Pandas
* NumPy
* Requests

Instead,

it works **with** them.

This makes Panel an excellent choice for data applications.

---

# Why We're Using Panel

There are many dashboard frameworks.

Why choose Panel?

Because it offers several advantages.

* Pure Python development
* Excellent integration with data science libraries
* Interactive widgets
* Beautiful layouts
* Reactive programming
* Easy deployment
* Rich visualization support

Most importantly,

it's beginner-friendly while remaining powerful enough for professional applications.

---

# Comparing Popular Python Web Frameworks

| Framework | Primary Purpose                           |
| --------- | ----------------------------------------- |
| Flask     | Build web applications                    |
| Django    | Large web systems                         |
| FastAPI   | REST APIs                                 |
| Streamlit | Simple data apps                          |
| Dash      | Interactive dashboards                    |
| **Panel** | Flexible dashboards and data applications |

Notice that each framework solves different problems.

We're building an interactive stock dashboard,

so Panel is an excellent fit.

---

# What Can You Build with Panel?

Panel is surprisingly versatile.

Examples include:

* Stock monitoring dashboards
* Business intelligence dashboards
* Machine learning applications
* Scientific visualization tools
* IoT monitoring systems
* Data exploration tools
* Financial analytics platforms
* Internal company dashboards

Our SGX Stock Monitor belongs to this family of applications.

---

# How Does a Panel Application Work?

At a high level,

a Panel application follows this workflow.

```text
Python Code

↓

Panel Components

↓

Web Server

↓

Browser
```

Unlike traditional desktop applications,

Panel runs a web server.

Users interact through their web browser.

---

# Understanding the Architecture

Our application now looks like this.

```text
+------------------------------+
|         Web Browser          |
+--------------▲---------------+
               │
               │
+--------------┴---------------+
|        Panel Application     |
+--------------▲---------------+
               │
               │
+--------------┴---------------+
|     MarketDataService        |
+--------------▲---------------+
               │
               │
+--------------┴---------------+
|     Financial API            |
+------------------------------+
```

Notice where Panel fits.

It sits between the browser and our application logic.

---

# Installing Panel

Panel is installed using `pip`.

```bash
pip install panel
```

If you're using a virtual environment,

install Panel inside that environment.

---

# What Does `pip` Do?

Earlier in this tutorial,

we learned that

`pip`

is Python's package manager.

When you install Panel,

`pip` downloads:

* Panel
* Its dependencies
* Supporting libraries

into your Python environment.

---

# Importing Panel

Like every Python library,

we begin with an import statement.

```python
import panel as pn
```

Let's examine it carefully.

---

`import`

tells Python

> "Load another module."

---

`panel`

is the package we're importing.

---

`as pn`

creates an alias.

Instead of writing

```python
panel.Column(...)
```

we can simply write

```python
pn.Column(...)
```

This is the convention used throughout the Panel documentation.

---

# Initializing Panel

Before using many Panel features,

we initialize the library.

```python
pn.extension()
```

This may look simple,

but it performs important setup behind the scenes.

It prepares:

* JavaScript resources
* CSS resources
* widgets
* themes
* rendering engines

Think of it as turning on the Panel engine before driving the car.

---

# Our First Panel Object

The simplest Panel application displays text.

```python
import panel as pn

pn.extension()

pn.panel("Hello, Panel!")
```

Let's understand what happens.

---

# What Is `pn.panel()`?

One of Panel's most useful functions is

```python
pn.panel()
```

It converts ordinary Python objects into displayable Panel objects.

For example,

```python
pn.panel("Hello")
```

creates a text pane.

Later,

we'll discover it can also display:

* DataFrames
* Images
* Charts
* Markdown
* HTML
* Matplotlib figures
* Plotly charts
* Bokeh plots

One function,

many object types.

---

# Displaying the Application

To display our application,

we use

```python
pn.panel("Hello, Panel!").servable()
```

---

# What Does `.servable()` Mean?

This is an important concept.

`.servable()`

tells Panel:

> "Make this object available to the web server."

Without it,

the object exists,

but isn't automatically displayed when the application runs.

---

# Understanding the Flow

When we execute our script,

the following happens.

```text
Python Starts

↓

pn.extension()

↓

Create Panel Object

↓

Mark as Servable

↓

Panel Web Server

↓

Browser Displays Page
```

Each step plays a role.

---

# Running the Application

Unlike normal Python scripts,

Panel applications are launched differently.

Instead of

```bash
python app.py
```

we use

```bash
panel serve app.py
```

---

# Why Not Use `python`?

When we execute

```bash
python app.py
```

Python simply runs the script and exits.

A dashboard needs something different.

It needs a web server that remains running,

waiting for users to connect.

That's exactly what

```bash
panel serve
```

does.

---

# What Happens Internally?

When we run

```bash
panel serve app.py
```

Panel performs several tasks.

```text
Read Python Script

↓

Start Web Server

↓

Build Application

↓

Wait for Browser Requests

↓

Serve Dashboard
```

Notice that the program continues running.

---

# Opening the Dashboard

Once the server starts,

Panel displays something similar to:

```text
Launching server...

http://localhost:5006/app
```

Opening that address in your browser displays your dashboard.

---

# What Does `localhost` Mean?

Beginners often find this confusing.

`localhost`

refers to

**your own computer**.

The browser communicates with the Panel server running locally.

Nothing is uploaded to the Internet.

---

# Understanding Ports

Notice the address.

```text
http://localhost:5006
```

The number

```text
5006
```

is called a **port**.

Think of a computer as an apartment building.

The IP address identifies the building.

The port identifies a specific apartment.

Many applications can share the same computer by listening on different ports.

---

# Our First Working Application

At this point,

our architecture looks like this.

```text
Browser

↓

Panel Server

↓

Hello Panel
```

It may be simple,

but it's a complete web application.

---

# Looking Ahead

Our application currently displays static text.

Soon,

we'll replace it with:

* buttons
* text boxes
* tables
* stock prices
* charts
* layouts
* interactive widgets

Each lesson builds upon this foundation.

---

# Teacher's Notes

> Many beginners assume that building a web application requires learning multiple frontend technologies. Panel demonstrates a different philosophy: let Python developers remain productive in Python. While understanding HTML, CSS, and JavaScript is valuable, many internal dashboards and analytical applications can be built entirely with Panel.
>
> It's also worth emphasizing that Panel is not a replacement for frameworks like Django or Flask. Those frameworks focus on general-purpose web development. Panel specializes in interactive analytical applications, making it particularly well suited for monitoring dashboards like the SGX Stock Monitor we'll build throughout this tutorial.

---

# Common Mistakes

## ❌ Mistake 1

Trying to run a Panel application using:

```bash
python app.py
```

Use:

```bash
panel serve app.py
```

instead.

---

## ❌ Mistake 2

Forgetting to call:

```python
pn.extension()
```

Many Panel features require initialization.

---

## ❌ Mistake 3

Forgetting:

```python
.servable()
```

Without it,

your objects may not appear in the application.

---

## ❌ Mistake 4

Confusing Panel with a desktop GUI framework.

Panel creates web applications that run inside a browser.

---

## ❌ Mistake 5

Thinking `localhost` means "the Internet."

`localhost` refers to your own computer.

---

# Summary

In this lesson, you learned:

* Panel is a Python framework for building interactive dashboards and web applications.
* Panel integrates naturally with Python libraries such as Pandas, NumPy, Requests, and visualization libraries.
* Every Panel application begins by importing the library and calling `pn.extension()`.
* `pn.panel()` converts ordinary Python objects into displayable Panel components.
* `.servable()` marks components for display by the Panel server.
* Panel applications are started using `panel serve`, not `python`.
* The Panel server runs locally and serves the application through your web browser.
* Our SGX Stock Monitor now has the foundation of a real web application.

This lesson marks the beginning of our frontend journey. Over the next several lessons, we'll replace simple text with professional layouts, interactive widgets, and live market data.

---

# Exercises

## Exercise 1 — Draw the Architecture

Draw a diagram showing the complete execution flow of a simple Panel application, beginning with the command:

```bash
panel serve app.py
```

and ending with the browser displaying the page.

---

## Exercise 2 — Explain Each Statement

Given the following code:

```python
import panel as pn

pn.extension()

pn.panel("Hello, Panel!").servable()
```

Explain the purpose of each line.

Do not simply describe what it does—explain **why** it is needed.

---

## Exercise 3 — Why Does Panel Use a Web Server?

Compare the following commands:

```bash
python app.py
```

and

```bash
panel serve app.py
```

Explain:

* What each command does.
* Why a dashboard needs a web server.
* Why the program continues running after launching the browser.

---

# Coming Up Next

In **Lesson 4.2 — Understanding Panes: Displaying Information in Panel**, we'll explore one of Panel's core building blocks: **panes**. You'll learn how Panel displays different types of Python objects—including text, Markdown, images, DataFrames, HTML, and charts—using specialized pane classes. We'll explain how automatic pane selection works, when to use specific pane types, and how panes form the visual foundation of every Panel dashboard we build.
