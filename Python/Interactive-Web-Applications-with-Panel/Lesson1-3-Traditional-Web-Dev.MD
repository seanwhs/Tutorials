# Part I — Foundations

# Lesson 1.3 — Traditional Web Development

## Learning Objectives

By the end of this lesson, you will be able to:

* Understand how web applications are traditionally built.
* Explain the purpose of HTML, CSS, JavaScript, backend frameworks, and databases.
* Understand why web development often feels overwhelming to Python beginners.
* Explain why Panel was created.
* Appreciate how much complexity Panel removes.

---

# Before We Learn Panel...

Imagine someone asks you to build a stock monitoring application.

Something similar to this:

```text
┌───────────────────────────────────────────────────────┐
│                 SGX Stock Monitor                     │
├───────────────────────────────────────────────────────┤
│ Search: [ DBS__________________ ] [Search]            │
│                                                       │
│ Price: S$48.23                                        │
│ Change: +1.21%                                        │
│                                                       │
│                📈 Price Chart                         │
│                                                       │
│ Watchlist                                             │
│ ✓ DBS                                                 │
│ ✓ OCBC                                                │
│ ✓ UOB                                                 │
└───────────────────────────────────────────────────────┘
```

It looks fairly simple.

A search box.

Some numbers.

A chart.

A watchlist.

Surely that can't require very much work...

Unfortunately...

Using traditional web technologies, it requires far more than most beginners expect.

Before we appreciate what Panel does for us, we need to understand **what Panel is replacing.**

---

# The Traditional Web Stack

Modern web applications are usually built using multiple technologies.

A simplified architecture looks like this.

```text
                   User

                    │

             Web Browser

                    │

      ┌─────────────┼─────────────┐
      │             │             │
     HTML          CSS      JavaScript
      │             │             │
      └─────────────┼─────────────┘

                    │

             HTTP Requests

                    │

          Backend Application

                    │

              Business Logic

                    │

               Database/API
```

Instead of learning one programming language,

developers traditionally learn several.

Let's examine each one carefully.

---

# HTML

## What is HTML?

HTML stands for

> **HyperText Markup Language**

Notice something important.

It is **not** a programming language.

It is a **markup language**.

---

## What is a Markup Language?

A markup language describes the structure of a document.

Think of it as a blueprint.

Imagine constructing a house.

Before electricians arrive...

Before painters arrive...

Before furniture arrives...

An architect creates a blueprint.

HTML serves a similar purpose.

It answers questions like:

* Where is the heading?
* Where is the button?
* Where is the table?
* Where is the image?

It defines **what exists**.

---

## HTML Example

A simplified HTML page might look like this.

```html
<h1>SGX Stock Monitor</h1>

<input>

<button>Search</button>

<table>

</table>
```

Even if you've never seen HTML before,

you can probably guess what it creates.

A heading.

A text box.

A button.

A table.

HTML is usually quite readable.

---

## What HTML Does NOT Do

HTML cannot:

* Calculate stock prices
* Download SGX data
* Draw interactive charts
* Perform calculations
* Connect to databases

It only describes the page structure.

---

# CSS

## What is CSS?

CSS stands for

> **Cascading Style Sheets**

Its purpose is to control appearance.

---

Imagine two houses.

House A

```text
□
```

House B

```text
🏡
```

Both houses have:

* walls
* roof
* windows

The structure is similar.

What makes them different is the decoration.

CSS is the decoration.

---

## CSS Controls

CSS controls things like:

* Colours
* Fonts
* Borders
* Shadows
* Margins
* Padding
* Width
* Height
* Animations
* Responsive layouts

Without CSS,

every website would look extremely plain.

---

## Example

Without CSS

```text
Search

Button

Table
```

With CSS

```text
╔══════════════════════╗
║ Search: [__________] ║
║                      ║
║  🔍 Search           ║
╚══════════════════════╝
```

The functionality hasn't changed.

Only the appearance has.

---

# JavaScript

Now comes the most important piece.

---

## What is JavaScript?

JavaScript is the programming language that runs inside the browser.

Unlike HTML and CSS,

JavaScript performs actions.

---

Imagine clicking

```text
Search
```

Something has to happen.

Questions include:

* What happens after the click?
* How do we know what the user typed?
* How does the chart update?
* How do we show loading indicators?
* How do we display errors?

JavaScript answers those questions.

---

## JavaScript Makes Pages Interactive

Without JavaScript

```text
Button

↓

Nothing
```

With JavaScript

```text
Button

↓

Run Code

↓

Update Screen

↓

Display New Data
```

JavaScript controls behavior.

---

## Examples

JavaScript can:

* Validate forms
* Animate menus
* Update tables
* Fetch stock prices
* Display notifications
* Draw charts
* Open dialogs

Nearly every interactive feature in a traditional web application depends on JavaScript.

---

# The Backend

The browser cannot do everything itself.

Some tasks require another computer.

That computer runs the backend.

---

## What Does the Backend Do?

The backend performs tasks like:

* Download SGX market prices
* Calculate portfolio values
* Store user accounts
* Save watchlists
* Generate reports
* Authenticate users

Popular backend languages include:

* Python
* Java
* C#
* Go
* PHP
* JavaScript (Node.js)

---

## In Our Application

Later in this tutorial,

our backend will download market data.

Conceptually:

```text
User

↓

Search DBS

↓

Backend Downloads Market Data

↓

Returns Price

↓

Screen Updates
```

---

# The Database

Many applications need permanent storage.

Imagine closing your SGX Stock Monitor.

Tomorrow,

you open it again.

Wouldn't you expect your watchlist to still be there?

Without storage,

everything disappears.

---

Databases store information such as:

* Watchlists
* Portfolios
* User settings
* Price history
* Notes

Later,

we'll use SQLite.

---

# Putting Everything Together

A traditional web application might look like this.

```text
                 Browser

        HTML

        CSS

        JavaScript

              │

      HTTP Requests

              │

     Python Backend

              │

      Business Logic

              │

        SQLite Database

              │

       External APIs

        SGX Market Data
```

Notice how many different technologies are involved.

---

# Why This Is Difficult for Beginners

Suppose you only know Python.

To build an SGX Stock Monitor traditionally,

you would need to learn:

✓ HTML

✓ CSS

✓ JavaScript

✓ Python

✓ Backend Framework

✓ Database

✓ APIs

✓ Deployment

That is a tremendous amount of information.

Many beginners spend months learning web technologies before building anything useful.

---

# An Example of Traditional Development

Suppose we simply want to display

```
DBS Price

48.23
```

The process might look like this.

### HTML

Create a page.

### CSS

Style the page.

### JavaScript

Handle button clicks.

### Python

Download market data.

### Database

Save user preferences.

### API

Retrieve stock prices.

### Browser

Update the display.

That's a lot of moving parts for such a small feature.

---

# Where Does Panel Fit?

Panel dramatically simplifies this process.

Instead of writing four or five different technologies,

you write Python.

Conceptually,

this:

```text
HTML

+

CSS

+

JavaScript

+

Backend

+

UI Framework
```

becomes:

```text
Python

↓

Panel

↓

Interactive Web Application
```

Panel takes care of much of the plumbing behind the scenes.

You focus on:

* the user interface
* your application logic
* your data

rather than worrying about browser mechanics.

---

# A Sneak Peek

Don't worry if you don't understand this code yet.

```python
import panel as pn

pn.extension()

pn.pane.Markdown("# SGX Stock Monitor")
```

With just three lines of Python,

Panel can already generate a web page.

There is:

* no HTML
* no CSS
* no JavaScript

Everything is written in Python.

Over the next few lessons, we'll explain **every line** of code in detail.

---

# Teacher's Notes

> Beginners often believe that learning web development means learning "one thing."
>
> In reality, traditional web development combines several different technologies, each with its own syntax, tools, and concepts. This is one reason many Python developers hesitate to build web applications.
>
> Panel doesn't eliminate the underlying concepts—there is still a browser, a server, and communication between them—but it lets you work at a higher level of abstraction using Python as your primary language. Understanding the traditional stack helps you appreciate what Panel automates on your behalf.

---

# Common Mistakes

### ❌ Mistake 1

Thinking HTML is a programming language.

It isn't.

It describes structure.

---

### ❌ Mistake 2

Thinking CSS controls application logic.

It doesn't.

It controls appearance.

---

### ❌ Mistake 3

Thinking JavaScript and Java are the same language.

They are completely different languages that happen to have similar names.

---

### ❌ Mistake 4

Thinking Panel replaces Python.

Panel is **a Python library**. It extends Python's capabilities for building web applications; it does not replace the language itself.

---

# Summary

In this lesson, you learned:

* HTML defines the **structure** of a web page.
* CSS controls the **appearance** of the interface.
* JavaScript adds **behavior** and interactivity in traditional web applications.
* The backend performs calculations, accesses databases, and communicates with external services.
* Databases provide persistent storage for application data.
* Building a traditional web application often requires mastering multiple technologies.
* Panel simplifies this workflow by allowing you to build interactive web applications primarily with Python, while handling much of the underlying web infrastructure for you.

---

## Exercises

### Exercise 1 — Identify the Technology

For each task, identify which traditional technology is primarily responsible:

1. Displaying a heading titled "SGX Stock Monitor".
2. Making the heading blue.
3. Updating a chart after a button is clicked.
4. Downloading the latest stock prices.
5. Saving a user's watchlist between sessions.

---

### Exercise 2 — Reflection

Imagine you were asked to build an application that monitors SGX stocks without using Panel.

List the technologies you think you would need to learn and briefly describe the role each would play. Compare your list with the traditional web stack presented in this lesson.

---

## Coming Up Next

In **Lesson 1.4 — Why Panel?**, we'll answer a key question:

> **If frameworks like Flask and Django already exist, why was Panel created?**

We'll compare Panel with other Python web frameworks, introduce the HoloViz ecosystem, and explain why Panel is especially well-suited for data dashboards, scientific applications, and interactive tools like the SGX Stock Monitor we're about to build.
