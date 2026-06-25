# Building Interactive Python Web Applications with Panel

## A Complete Beginner's Guide to Building an SGX Stock Monitor

**Version 1.0**

---

# Part I — Foundations

> **Theme**
>
> Before we build our first Panel application, we must first understand **why Panel exists**, **how web applications work**, and **how Panel simplifies Python web development**.
>
> This Part contains **no assumptions**. Even if you have never built a web application before, everything will be explained from first principles.

---

# Learning Objectives

By the end of this Part, you will be able to:

* Explain what a web application is.
* Distinguish between websites and web applications.
* Understand the client-server architecture.
* Explain why traditional web development is complex.
* Describe the HoloViz ecosystem.
* Explain where Panel fits into the ecosystem.
* Install Panel correctly.
* Build and run your first Panel application.
* Understand how a Panel application works internally.
* Understand the event-driven programming model.
* Understand the basics of reactive programming.

---

# What We Will Build

Throughout this tutorial, we will gradually build a professional **SGX Stock Monitor**.

This is not a toy application.

It resembles software that an investor or analyst might actually use.

By the end of the tutorial, your application will include:

```text
┌──────────────────────────────────────────────────────────────────────┐
│                     SGX Stock Monitor                                │
├──────────────────────────────────────────────────────────────────────┤
│ Search: [ DBS Group Holdings                           🔍 ]          │
├──────────────┬───────────────────────────────────────────────────────┤
│ Watchlist    │ Company Information                                   │
│              │                                                       │
│ ✓ DBS        │ Current Price      S$48.23                            │
│ ✓ OCBC       │ Daily Change       +1.25%                             │
│ ✓ UOB        │ Volume             5,482,300                          │
│ ✓ Singtel    │                                                       │
│              │ Price Chart                                         📈 │
│ Portfolio    │                                                       │
│              │                                                       │
│ Alerts       │                                                       │
│              │                                                       │
└──────────────┴───────────────────────────────────────────────────────┘
```

Don't worry if this looks complicated.

When we begin, our application will contain only a single line of text.

Every lesson adds one new capability.

---

# How This Tutorial Is Different

Many programming tutorials look like this:

Lesson 1

```python
print("Hello World")
```

Lesson 2

```python
Button()
```

Lesson 3

```python
Slider()
```

Lesson 4

```python
DataFrame()
```

Eventually you end up with dozens of disconnected examples.

Unfortunately, this rarely teaches how real software is built.

---

This tutorial follows a different philosophy.

Instead of memorizing APIs, we will **build one application** from beginning to end.

Every new concept immediately improves our SGX Stock Monitor.

For every new concept, we will always answer the same five questions.

---

## What?

What exactly is this concept?

Example:

> What is a widget?

---

## Why?

Why does it exist?

What problem does it solve?

---

## How?

How does it work internally?

Not just "how to use it."

---

## Where?

Where should we use it?

Where should we **not** use it?

---

## When?

When is it the right solution?

What alternatives exist?

---

Only after answering these questions will we write code.

---

# Prerequisites

This tutorial assumes only basic Python knowledge.

You should already understand:

* Variables
* Data types
* Functions
* Lists
* Dictionaries
* Loops
* Conditional statements

Helpful, but **not required**:

* Classes
* Modules
* Exceptions

You do **not** need experience with:

* HTML
* CSS
* JavaScript
* Flask
* Django
* React
* Vue
* Angular
* Web development

Everything will be taught from scratch.

---

# Software Used Throughout This Tutorial

| Software | Purpose                   |
| -------- | ------------------------- |
| Python   | Programming language      |
| Panel    | Build web applications    |
| Param    | Reactive state management |
| Pandas   | Data manipulation         |
| Plotly   | Interactive charts        |
| SQLite   | Local database            |
| aiohttp  | Download stock data       |
| asyncio  | Asynchronous programming  |
| Docker   | Deployment                |

Do not worry if you have never heard of these libraries.

We will introduce them only when we need them.

---

# The Journey Ahead

Our project will evolve gradually.

Instead of writing one enormous program, we will repeatedly improve it.

Our application's evolution looks like this:

```text
Part 1

Hello Panel

↓

Part 2

Simple User Interface

↓

Part 3

Professional Layout

↓

Part 4

Interactive Widgets

↓

Part 5

Reactive Updates

↓

Part 6

Live SGX Data

↓

Part 7

Charts

↓

Part 8

Portfolio

↓

Part 9

Persistence

↓

Part 10

Production Deployment
```

Each Part builds naturally upon the previous one.

---

# Lesson 1.1 — What Is a Web Application?

Before learning Panel, we first need to answer a seemingly simple question.

> **What exactly is a web application?**

Many people confuse **websites** and **web applications**.

Although they both run in a web browser, they are designed for different purposes.

Understanding this distinction is the first step toward understanding why Panel exists.

---

## What Is a Website?

A website primarily **presents information**.

You visit it to read or view content.

Examples include:

* Company homepages
* Personal blogs
* News websites
* Documentation sites
* Online magazines

The information flows mainly in one direction:

```text
Website

Server

↓

Browser

↓

User Reads Information
```

The user is mostly a passive consumer.

For example, when you visit a restaurant's website, you might:

* Read the menu
* Check the opening hours
* View the address
* Look at photos

The website displays information, but you are not actively changing its state.

---

## What Is a Web Application?

A web application is different.

Instead of simply presenting information, it allows users to interact with data and perform tasks.

Examples include:

* Online banking
* Email services
* Project management tools
* Online shopping carts
* Video conferencing platforms
* Stock trading dashboards

A web application continuously responds to user actions.

The interaction looks like this:

```text
User

↓

Clicks Button

↓

Application Processes Request

↓

Screen Updates

↓

User Performs Another Action

↓

Application Responds Again

↓

Repeat
```

Unlike a traditional website, a web application is always waiting for the next user interaction.

---

## Our SGX Stock Monitor Is a Web Application

Throughout this tutorial, we will build an application that users can interact with.

For example, users will be able to:

* Search for SGX-listed companies
* Build a personal watchlist
* View live market prices
* Display interactive price charts
* Manage a virtual portfolio
* Configure price alerts

Every action changes what is displayed on the screen.

This is exactly what makes it a web application.

---

## Comparing Websites and Web Applications

The differences become clearer when placed side by side.

| Website                 | Web Application             |
| ----------------------- | --------------------------- |
| Presents information    | Processes user interactions |
| Mostly static           | Dynamic and interactive     |
| Limited user input      | Continuous user input       |
| Read-only in many cases | Read and write data         |
| Simple navigation       | Complex workflows and state |

Neither is better than the other—they solve different problems.

---

## A Simple Mental Model

Imagine a printed newspaper.

Once it is printed, the content never changes.

A traditional website is similar.

Now imagine an online banking application.

Every time you transfer money, pay a bill, or check your balance, the screen updates based on your actions.

That is a web application.

Our SGX Stock Monitor behaves the same way:

* Searching for a company updates the results.
* Selecting a stock displays different information.
* Refreshing downloads new prices.
* Editing a watchlist changes the displayed data.
* Updating a portfolio recalculates gains and losses.

The application is constantly reacting to the user's actions.

---

## Teacher's Notes

> **A common misconception is that any page viewed in a browser is automatically a "web application."**
>
> This is not true.
>
> The browser is simply the environment in which both websites and web applications run.
>
> What distinguishes a web application is **interaction and state**. A web application remembers information, reacts to user input, performs computations, and updates its interface dynamically.

---

## Common Mistakes

❌ Thinking that HTML pages and web applications are the same thing.

❌ Assuming that every browser-based system requires JavaScript to be interactive.

❌ Believing that Python cannot build modern web interfaces.

By the end of this tutorial, you will see that Panel enables highly interactive applications using primarily Python.

---

## Knowledge Check

Before continuing, make sure you can answer the following questions:

1. What is the primary difference between a website and a web application?
2. Why is our SGX Stock Monitor considered a web application rather than a website?
3. Can you identify three web applications you use regularly and explain what makes them interactive?

If you can answer these confidently, you're ready for the next lesson.

---

**Next Lesson (Lesson 1.2): How Web Applications Work — Understanding the Browser, the Server, HTTP, and the Client–Server Architecture.** In that lesson, we'll trace what happens behind the scenes when a user clicks a button, laying the foundation for understanding how Panel applications communicate with the browser.
