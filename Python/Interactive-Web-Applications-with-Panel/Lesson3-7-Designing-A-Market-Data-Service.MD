# Part III — Working with Real SGX Market Data

# Lesson 3.7 — Designing a Market Data Service

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what a service layer is.
> * Learn why professional applications separate responsibilities.
> * Understand the concept of abstraction.
> * Learn what encapsulation means in software engineering.
> * Design a reusable `MarketDataService`.
> * Understand the responsibilities of the service.
> * Learn why the UI should never directly call APIs.
> * Prepare the foundation for the rest of our SGX Stock Monitor.

---

# Introduction

Over the last few lessons, we've learned many individual skills.

We now know how to:

* Send HTTP requests
* Parse JSON
* Extract values
* Handle missing fields
* Validate responses
* Handle network errors

Everything works.

But there's a problem.

Where should all of this code live?

Should our Panel button callback contain hundreds of lines of networking code?

Professional software says:

**No.**

Instead,

we organize our code into logical components.

Today,

we'll build the first major component of our application:

> **The Market Data Service**

---

# The Problem with Beginner Applications

Many beginner applications grow like this.

```text
Button Click

↓

Download Data

↓

Check Status

↓

Parse JSON

↓

Extract Price

↓

Validate Data

↓

Format Data

↓

Update Widgets
```

Everything happens inside one function.

As the application grows,

this function becomes:

* Longer
* Harder to read
* Harder to debug
* Harder to reuse
* Harder to test

Eventually,

it becomes difficult to maintain.

---

# Imagine Adding More Features

Suppose we later add:

* Watchlists
* Historical charts
* Portfolio tracking
* News headlines
* Price alerts
* Technical indicators

Will each feature write its own HTTP requests?

Its own JSON parsing?

Its own error handling?

That would create enormous duplication.

---

# The Principle of Separation of Concerns

Professional software follows an important design principle.

> **Each component should have one primary responsibility.**

This is called

**Separation of Concerns**.

---

Instead of one giant function,

we divide the application.

```text
User Interface

↓

Market Data Service

↓

Financial API
```

Each layer has a specific job.

---

# What Is a Service?

A service is simply a class (or module)

whose job is to perform one specific task.

Examples include:

* Authentication Service
* Email Service
* Payment Service
* Weather Service
* Notification Service

Our application needs a

**Market Data Service**.

---

# Responsibilities of the Market Data Service

Its responsibilities include:

* Sending HTTP requests
* Handling timeouts
* Handling errors
* Parsing JSON
* Validating data
* Transforming API responses
* Returning clean Python objects

Notice what is **not** on the list.

* Displaying widgets
* Updating buttons
* Changing layouts

Those belong to the UI.

---

# Responsibilities of the Panel UI

The Panel interface should focus on:

* User interaction
* Buttons
* Text inputs
* Tables
* Charts
* Displaying results

It should **not** know:

* Which API we're using
* How HTTP works
* How JSON is parsed
* Which fields the API returns

---

# Visualizing the Architecture

Instead of this:

```text
Panel

↓

HTTP

↓

JSON

↓

Validation

↓

Widgets
```

We build this:

```text
Panel

↓

MarketDataService

↓

HTTP

↓

API

↓

JSON

↓

Validated Data

↓

Panel
```

Notice how the networking details are hidden from the UI.

---

# What Is Abstraction?

This design introduces another important concept:

> **Abstraction**

Abstraction means

> **Hiding unnecessary complexity behind a simple interface.**

---

Imagine driving a car.

You press

```text
Accelerator
```

The car moves.

You don't need to know:

* Fuel injection
* Spark plugs
* Engine timing
* Transmission gears

All of that complexity is hidden.

That's abstraction.

---

# Applying Abstraction

Our Panel dashboard shouldn't care about:

```text
HTTP

↓

JSON

↓

Headers

↓

Status Codes

↓

Retries
```

Instead,

it simply asks

```text
MarketDataService

↓

Get DBS Stock
```

The service handles everything else.

---

# What Is Encapsulation?

Another important principle is

**Encapsulation**.

Encapsulation means

> **Keeping related data and behavior together inside one component.**

For example,

our service should contain:

* API URL
* Request logic
* Parsing logic
* Validation logic

All of these belong together.

---

# The Public Interface

Every well-designed class exposes a small,

simple interface.

Conceptually,

our service might provide methods like:

```text
get_stock(symbol)

get_market_summary()

get_watchlist(symbols)
```

Notice how these methods describe **what** the service does,

not **how** it does it.

---

# Thinking Like the UI

Imagine you're writing the dashboard.

Would you rather write:

```text
HTTP Request

↓

Parse JSON

↓

Extract Price

↓

Validate Fields

↓

Return Result
```

or simply:

```text
market_service.get_stock("D05")
```

The second option is much easier to understand.

---

# A Conceptual Class Design

Our service might look like this.

```python
class MarketDataService:

    def get_stock(self, symbol):

        ...

    def get_market_summary(self):

        ...

    def search_company(self, keyword):

        ...
```

Don't worry about the implementation yet.

Today,

we're designing the architecture.

---

# What Happens Inside the Service?

When the UI calls

```text
get_stock("D05")
```

the service performs many steps.

```text
Receive Symbol

↓

Build URL

↓

Send HTTP Request

↓

Check Status

↓

Parse JSON

↓

Validate Data

↓

Transform Response

↓

Return Clean Dictionary
```

The UI doesn't see any of these details.

---

# The UI Becomes Simpler

Without a service,

our button callback might look like this.

```text
Button

↓

HTTP

↓

JSON

↓

Validation

↓

Transformation

↓

Widgets
```

With a service,

the callback becomes

```text
Button

↓

MarketDataService

↓

Display Result
```

That's much easier to understand.

---

# Why Reusability Matters

Suppose we later build:

* A command-line application
* A web API
* A mobile application
* A desktop application

Should each one implement HTTP requests again?

No.

They can all reuse the same

`MarketDataService`.

This is one of the biggest advantages of good architecture.

---

# Easier Testing

Imagine you want to test

price extraction.

If networking,

JSON,

and UI are mixed together,

testing becomes difficult.

With a service,

we can test

```text
MarketDataService

↓

Input

↓

Output
```

without starting the entire Panel application.

This makes automated testing much easier.

---

# Easier Maintenance

Suppose the API provider changes.

Yesterday,

the response contained

```text
companyName
```

Today,

it contains

```text
name
```

Without a service,

we might need to update many files.

With a service,

we change one place.

The UI remains unchanged.

---

# Supporting Multiple APIs

Imagine our original API becomes unavailable.

We switch providers.

The new API uses different URLs,

different JSON,

and different field names.

Does the dashboard change?

Ideally,

no.

Only the service changes.

The rest of the application continues working.

---

# Our Application Architecture

By the end of Part III,

our application will resemble this.

```text
+-----------------------------+
|       Panel Dashboard       |
+-------------+---------------+
              |
              |
              ▼
+-----------------------------+
|     MarketDataService       |
+-------------+---------------+
              |
              |
              ▼
+-----------------------------+
|     Financial Data API      |
+-----------------------------+
```

Each layer has a clearly defined responsibility.

---

# Looking Ahead

As our project grows,

we'll add more services.

```text
Panel

├── MarketDataService

├── PortfolioService

├── AlertService

├── ChartService

└── ExportService
```

Each service solves one problem well.

---

# Thinking Like a Software Architect

Beginners often think about

**writing code**.

Architects think about

**organizing code**.

Good architecture makes future development easier.

Poor architecture makes every new feature more difficult.

Today's lesson is the beginning of thinking like an architect.

---

# Teacher's Notes

> One of the biggest differences between tutorial code and production software is organization. Small examples can often get away with placing everything in a single file, but real applications quickly become difficult to maintain unless responsibilities are clearly separated.
>
> The `MarketDataService` acts as a boundary between our application and the outside world. If the external API changes, only this service should need modification. The rest of the application—including the Panel interface—should remain largely unaffected. This loose coupling is one of the defining characteristics of maintainable software systems.

---

# Common Mistakes

## ❌ Mistake 1

Putting HTTP requests directly inside button callbacks.

Networking belongs in the service layer.

---

## ❌ Mistake 2

Allowing the UI to know API field names.

The service should transform raw API responses into application-friendly data.

---

## ❌ Mistake 3

Duplicating networking code across multiple files.

Centralize API communication inside one reusable service.

---

## ❌ Mistake 4

Confusing abstraction with hiding information.

Abstraction hides unnecessary complexity while exposing a simple interface.

---

## ❌ Mistake 5

Thinking architecture only matters for large projects.

Good architectural habits are easiest to develop on small projects and scale naturally to larger ones.

---

# Summary

In this lesson, you learned:

* A **service layer** separates business logic from the user interface.
* **Separation of Concerns** assigns each component a clear responsibility.
* **Abstraction** hides complex implementation details behind a simple interface.
* **Encapsulation** keeps related data and behavior together.
* The `MarketDataService` will handle networking, parsing, validation, and data transformation.
* The Panel UI should focus solely on presenting information and responding to user interactions.
* A well-designed service is reusable, maintainable, and easier to test.
* Good architecture reduces duplication and makes future enhancements easier.

We have now completed the conceptual design of our Market Data Service. In the next lesson, we'll begin implementing it, starting with a simple version that can retrieve stock information from a financial API and return clean Python dictionaries for our Panel application.

---

# Exercises

## Exercise 1 — Identify Responsibilities

Classify each task as belonging to either the **Panel UI** or the **MarketDataService**:

* Sending an HTTP request
* Displaying a stock price
* Parsing JSON
* Updating a chart
* Handling API timeouts
* Validating response data
* Responding to a button click
* Formatting raw API data

Explain your reasoning.

---

## Exercise 2 — Draw the Architecture

Draw a diagram showing the interaction between:

* User
* Panel Dashboard
* MarketDataService
* Financial API

Label the direction of data flow and describe the responsibility of each component.

---

## Exercise 3 — Benefits of a Service Layer

Imagine your application needs to support **two different financial APIs**.

Explain:

* Which part of the application should change?
* Which parts should remain unchanged?
* Why does the service layer make this transition easier?

---

# Coming Up Next

In **Lesson 3.8 — Implementing the `MarketDataService`**, we'll write our first production-style service class. You'll learn how to organize the project into modules, initialize service objects, construct API requests, retrieve market data, validate responses, normalize the returned information, and expose a clean `get_stock()` method that our Panel dashboard can use. This marks the transition from software architecture to software implementation.
