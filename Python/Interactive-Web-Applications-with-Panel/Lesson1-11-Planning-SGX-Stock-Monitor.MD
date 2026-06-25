# Part I — Foundations

# Lesson 1.11 — Planning the SGX Stock Monitor

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why software should be designed before it is implemented.
> * Learn how to break a large application into smaller components.
> * Identify the major features of the SGX Stock Monitor.
> * Understand the concept of software architecture.
> * Learn the principle of Separation of Concerns.
> * Design the overall structure of our application before writing more code.
> * Understand the roadmap for the remainder of this tutorial.

---

# Introduction

So far we've learned how to:

* Create Panel objects
* Build layouts
* Display applications
* Run the Panel server

We've built something that looks like this.

```text
-----------------------------------

SGX Stock Monitor

Welcome!

-----------------------------------
```

It's a working application.

But...

It doesn't actually monitor stocks.

There are:

* no search box
* no charts
* no market data
* no watchlist
* no portfolio
* no news

Before we start adding these features, we need to answer a more important question.

> **What exactly are we building?**

Professional developers rarely jump straight into coding.

Instead, they first design the system.

---

# Why Planning Matters

Imagine being asked to build a house.

Would builders start by randomly laying bricks?

Of course not.

They first create:

* architectural drawings
* floor plans
* electrical plans
* plumbing layouts

Only after the design is complete does construction begin.

Software engineering works exactly the same way.

---

# The Cost of Poor Planning

Suppose we immediately start writing code.

Day 1

```text
Search Box
```

Day 2

```text
Chart
```

Day 3

```text
News
```

Day 4

```text
Portfolio
```

Eventually we discover:

* duplicated code
* confusing structure
* difficult maintenance
* hard-to-find bugs

This often happens because the software wasn't designed first.

---

# Our Goal

By the end of this tutorial, we'll have an application similar to this.

```text
+--------------------------------------------------------------+

                 SGX Stock Monitor

---------------------------------------------------------------

 Search: [ DBS____________ ] [ Search ]

---------------------------------------------------------------

 Price Summary

 Current Price

 Daily Change

 Market Status

---------------------------------------------------------------

                Interactive Price Chart

---------------------------------------------------------------

 Company Information

---------------------------------------------------------------

 Historical Prices

---------------------------------------------------------------

 Watchlist

---------------------------------------------------------------

 Portfolio

---------------------------------------------------------------

 Market News

---------------------------------------------------------------
```

This may look like one application.

In reality,

it's many smaller applications working together.

---

# Thinking Like an Engineer

Beginners often ask:

> "How do I build this screen?"

Experienced engineers ask:

> "What smaller pieces make up this screen?"

This change in thinking is extremely important.

Instead of one huge application,

we'll build many small components.

---

# Step 1 — Identify the Features

Let's list everything we eventually want.

Our application should be able to:

* Search SGX stocks
* Display company information
* Show live prices
* Display historical prices
* Draw interactive charts
* Manage a watchlist
* Track a portfolio
* Display market news
* Refresh market data
* Save user preferences

Already,

we have ten major features.

---

# Step 2 — Group Similar Features

Instead of treating these as ten separate problems,

we group related functionality.

```text
Market Data

↓

Search

↓

Charts

↓

Portfolio

↓

Watchlist

↓

News

↓

Settings
```

Each group becomes a separate component.

---

# What Is a Component?

A component is a self-contained piece of an application that performs one well-defined job.

Think of a car.

A car contains:

* engine
* wheels
* brakes
* steering
* seats

Each component has its own responsibility.

Together,

they create a complete vehicle.

Applications are built the same way.

---

# Our Components

Our SGX Stock Monitor will eventually consist of components like these.

```text
Search Component

↓

Market Data Component

↓

Chart Component

↓

Portfolio Component

↓

Watchlist Component

↓

News Component

↓

Settings Component
```

Each component focuses on one responsibility.

---

# Separation of Concerns

This is one of the most important principles in software engineering.

The idea is simple.

> **Each part of the application should have one primary responsibility.**

For example:

The Search component

should search.

It should not:

* draw charts
* save portfolios
* display news

Likewise,

the Chart component

should display charts.

It should not:

* download news
* manage watchlists
* calculate portfolio values

Each component has a clear purpose.

---

# Why Is This Important?

Imagine one Python file containing:

* search
* charts
* portfolio
* news
* watchlist
* settings
* networking
* databases

Eventually,

that file becomes thousands of lines long.

Finding bugs becomes difficult.

Adding new features becomes risky.

Separating responsibilities keeps software manageable.

---

# Thinking in Layers

Professional applications are often divided into layers.

For our project,

we'll use something similar.

```text
User Interface

↓

Business Logic

↓

Data Layer

↓

External Services
```

Let's understand each layer.

---

# Layer 1 — User Interface

This is everything the user sees.

Examples:

* Buttons
* Tables
* Charts
* Search boxes
* Watchlists
* Menus

We'll build this layer using Panel.

---

# Layer 2 — Business Logic

Business logic answers questions like:

* Which stock was selected?
* How is portfolio value calculated?
* How should prices be formatted?
* Should the watchlist allow duplicates?

These rules belong here.

Notice something.

Business logic doesn't care whether we're using Panel.

It simply performs calculations.

---

# Layer 3 — Data Layer

The data layer manages information.

Examples:

* Loading stock prices
* Reading databases
* Saving watchlists
* Reading configuration files

This layer knows where data comes from.

The user interface shouldn't need to know.

---

# Layer 4 — External Services

Eventually,

our application will communicate with external systems.

For example:

```text
SGX Data Provider

↓

Financial APIs

↓

News APIs
```

These services live outside our application.

---

# Visualizing the Architecture

Our application will roughly look like this.

```text
+----------------------------------------------------+

              User Interface (Panel)

------------------------------------------------------

           Business Logic

------------------------------------------------------

              Data Layer

------------------------------------------------------

        APIs • SQLite • Files

+----------------------------------------------------+
```

Each layer depends on the layer below it.

---

# Why Not Put Everything in `app.py`?

At the moment,

our project contains only one file.

```text
sgx-stock-monitor/

├── app.py
```

That's perfectly fine for a tiny example.

But imagine adding:

* 20 widgets
* 15 charts
* portfolio management
* API downloads
* watchlists
* databases

Soon,

`app.py`

might contain

3,000 lines of code.

That becomes difficult to navigate.

---

# Our Future Project Structure

Over the coming Parts,

our project will gradually evolve.

```text
sgx-stock-monitor/

│

├── app.py

│

├── ui/

│   ├── dashboard.py

│   ├── sidebar.py

│   ├── charts.py

│   └── widgets.py

│

├── services/

│   ├── market_data.py

│   ├── portfolio.py

│   └── news.py

│

├── models/

│

├── database/

│

├── assets/

│

└── config/
```

Don't worry about every folder yet.

We'll create them one at a time.

---

# Incremental Development

Notice something important.

We're not going to build everything today.

Instead,

we'll grow the application gradually.

```text
Lesson 1

↓

Heading

--------------------

Lesson 2

↓

Layouts

--------------------

Part II

↓

Widgets

--------------------

Part III

↓

Market Data

--------------------

Part IV

↓

Charts

--------------------

Part V

↓

Portfolio

--------------------

Part VI

↓

News
```

Each Part builds upon the previous one.

---

# Our Development Strategy

Throughout this tutorial,

we'll follow the same engineering process repeatedly.

```text
Plan

↓

Build

↓

Test

↓

Improve

↓

Refactor

↓

Repeat
```

This cycle is used in professional software development around the world.

---

# Thinking Ahead

Although today's application is small,

we're designing it as if it were going to become much larger.

This has several advantages.

Later,

adding features becomes much easier because the architecture already supports growth.

Good software architecture is about preparing for change—not predicting every future requirement, but making future changes easier to accommodate.

---

# Teacher's Notes

> One of the biggest differences between beginner programmers and experienced software engineers is that experienced engineers spend more time thinking before they start coding.
>
> Planning isn't about delaying implementation—it is about reducing unnecessary rework. A few minutes spent identifying responsibilities, defining components, and organizing the project can save hours of debugging and refactoring later.
>
> As this tutorial progresses, you'll notice that every new feature naturally fits into the architecture we've designed here. That is one of the hallmarks of a well-structured system.

---

# Common Mistakes

### ❌ Mistake 1

Trying to build the entire application in one file.

Small examples may fit comfortably in a single file, but larger applications benefit from being divided into modules with clear responsibilities.

---

### ❌ Mistake 2

Adding features before deciding where they belong.

Every new feature should have a natural home within the application's architecture.

---

### ❌ Mistake 3

Mixing user interface code with business logic.

Whenever possible, keep calculations and decision-making separate from code that creates buttons, layouts, and charts.

---

### ❌ Mistake 4

Thinking architecture is only for large companies.

Even personal projects become easier to understand and maintain when they have a clear structure.

---

# Summary

In this lesson, you learned:

* Professional software is designed before it is implemented.
* Large applications should be broken into smaller, reusable components.
* Separation of Concerns helps keep code organized and maintainable.
* Layered architecture separates the user interface, business logic, data management, and external services.
* Our SGX Stock Monitor will grow incrementally while maintaining a clean architecture.
* Good architecture makes future enhancements easier rather than harder.

With our architecture planned, we're ready to move beyond static pages and begin building **interactive applications**.

---

# Exercises

## Exercise 1 — Feature Decomposition

Take the following feature:

> **Portfolio Tracking**

Break it into smaller responsibilities.

For example:

* Calculate total portfolio value
* Record purchases
* Record sales
* Display holdings
* Calculate profit/loss

Can you think of additional responsibilities?

---

## Exercise 2 — Identify the Layer

For each task below, identify which architectural layer it belongs to.

1. Display a stock price on the screen.
2. Download market data from an API.
3. Calculate the percentage gain of a portfolio.
4. Save the user's watchlist.
5. Display a line chart.

---

## Exercise 3 — Design Your Own Component

Choose one of these features:

* Watchlist
* News
* Company Information

Describe:

* What its responsibility should be.
* What information it needs.
* What it should **not** be responsible for.

---

# End of Part I

Congratulations!

You have completed **Part I — Foundations**.

You now understand:

* How web applications work.
* Why Panel exists.
* The HoloViz ecosystem.
* The Panel object model.
* Layouts.
* The Panel server.
* `.servable()`.
* Software architecture and planning.

More importantly, you've developed the **mental model** needed to understand everything that follows.

---

# Coming Up Next

## **Part II — Widgets: Building Interactive User Interfaces**

Until now, our SGX Stock Monitor has been static.

In Part II, it finally becomes **interactive**.

You'll learn:

* Every major Panel widget in depth
* Widget properties and methods
* User input
* Events and callbacks
* Reactive programming
* Validation
* Dynamic interfaces
* Building the complete search panel for our SGX Stock Monitor

By the end of Part II, users will be able to interact with the application, enter stock symbols, click buttons, adjust settings, and trigger real application behavior—laying the foundation for connecting live SGX market data in the Parts that follow.
