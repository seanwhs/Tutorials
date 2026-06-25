# Part III — Working with Real SGX Market Data

# Lesson 3.8 — Implementing the `MarketDataService`

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Create the `MarketDataService` class.
> * Organize application code into modules.
> * Understand Python classes in a real-world context.
> * Learn why constructors (`__init__`) are used.
> * Configure a service with API settings.
> * Implement the `get_stock()` method.
> * Separate configuration from implementation.
> * Understand dependency management.
> * Build the foundation for the remainder of our SGX Stock Monitor.

---

# Introduction

In the previous lesson, we designed our application architecture.

We introduced a new component:

> **MarketDataService**

Today,

we begin implementing it.

This is an important milestone.

Until now,

we have been learning concepts.

Starting with this lesson,

we begin building production-style software.

---

# From Design to Code

Previously,

our architecture looked like this.

```text
Panel Dashboard

↓

MarketDataService

↓

Financial API
```

Now we'll begin writing the middle layer.

---

# Why Start with the Service?

Many beginners immediately start building user interfaces.

Professional developers often do the opposite.

They first build the application's

* logic
* services
* data access
* business rules

Only then do they connect the UI.

Why?

Because user interfaces change frequently.

Business logic changes much less often.

---

# Our Project Structure

Our project is gradually becoming larger.

Instead of placing everything into one file,

we'll organize our code.

```
sgx_stock_monitor/

│

├── app.py

├── services/

│      └── market_data_service.py

├── models/

├── utils/

├── config.py

└── requirements.txt
```

Don't worry if some folders are currently empty.

We'll fill them throughout the tutorial.

---

# Why Multiple Files?

Imagine a book.

Would you place every chapter on one giant page?

Of course not.

Instead,

we divide it into chapters.

Software works the same way.

Each file should focus on one responsibility.

---

# The `services` Folder

Our networking code belongs here.

```
services/

    market_data_service.py
```

Later,

other services may appear.

```
services/

    market_data_service.py

    portfolio_service.py

    alert_service.py

    export_service.py
```

Each service performs one job well.

---

# Creating the Class

Inside

```
market_data_service.py
```

we begin with

```python
class MarketDataService:
    pass
```

---

# Understanding the Code

Let's examine it carefully.

```python
class
```

This tells Python

> "We're creating a class."

A class is a blueprint for creating objects.

---

The name

```python
MarketDataService
```

describes the purpose of the class.

Notice the naming convention.

* Starts with a capital letter.
* Uses PascalCase.
* Describes a noun.

This follows Python's style guide (PEP 8).

---

# What Is a Class?

Think of a class as an architectural blueprint.

```
Blueprint

↓

House
```

A blueprint isn't the house.

It describes how to build one.

Similarly,

a class isn't the object.

It describes how objects should behave.

---

# Objects from Classes

Later,

we'll create an object.

```python
service = MarketDataService()
```

Now we have an actual service object that our application can use.

---

# Why Not Use Functions?

A beginner might ask:

> "Why not just create lots of functions?"

That's a good question.

Functions work well for small programs.

However,

our service needs to store information,

such as:

* Base URL
* Timeout
* API key
* Session object

Classes allow us to keep this information together.

---

# The Constructor

Most classes begin with a constructor.

```python
class MarketDataService:

    def __init__(self):

        pass
```

---

# What Is `__init__`?

The constructor runs automatically

when an object is created.

```python
service = MarketDataService()
```

Python automatically executes

```python
__init__()
```

before returning the object.

---

# Why Is It Called a Constructor?

Imagine buying a new smartphone.

The manufacturer installs:

* Operating system
* Settings
* Default apps

before you use it.

Similarly,

a constructor prepares an object

before the rest of the application uses it.

---

# Initializing Configuration

Suppose every API request should wait

10 seconds before timing out.

Instead of writing

```python
timeout=10
```

everywhere,

we store it once.

```python
class MarketDataService:

    def __init__(self):

        self.timeout = 10
```

---

# Understanding `self`

This is one of the biggest topics for beginners.

```python
self
```

refers to

**the current object**.

Imagine we create

```python
service = MarketDataService()
```

Internally,

Python treats

```python
self.timeout
```

as

```text
service.timeout
```

The object stores its own data.

---

# Instance Variables

Variables stored inside an object are called

**instance variables**.

Example

```python
self.timeout

self.base_url
```

Every MarketDataService object has its own copy.

---

# Adding the Base URL

Every request will use the same API.

Instead of repeating the URL,

store it once.

```python
class MarketDataService:

    def __init__(self):

        self.base_url = "https://..."

        self.timeout = 10
```

Notice the benefit.

If the API changes,

we modify one location.

---

# Why Centralize Configuration?

Imagine the API URL appears in

25 different files.

One day,

the provider changes domains.

You now have to edit

25 files.

Instead,

store configuration in one place.

---

# Adding a Method

Our service needs to retrieve stock data.

We define a method.

```python
class MarketDataService:

    def get_stock(self, symbol):

        pass
```

---

# Understanding the Parameters

```python
self
```

The current object.

---

```python
symbol
```

The stock code requested by the user.

Examples

```text
D05

O39

U11
```

---

# Calling the Method

Once an object exists,

we can call it.

```python
service = MarketDataService()

service.get_stock("D05")
```

Execution flow

```text
Panel

↓

MarketDataService

↓

get_stock()

↓

Return Stock Data
```

---

# What Should `get_stock()` Do?

Eventually,

it will perform many tasks.

```text
Receive Symbol

↓

Build URL

↓

HTTP Request

↓

Check Status

↓

Parse JSON

↓

Validate Data

↓

Normalize Data

↓

Return Dictionary
```

Notice that the UI doesn't need to know any of these details.

---

# Returning Data

Our goal is for

```python
get_stock()
```

to return something simple.

Example

```python
{
    "symbol": "D05",
    "company": "DBS Group Holdings",
    "price": 41.35,
    "currency": "SGD"
}
```

The UI can display this immediately.

---

# Why Return a Dictionary?

A dictionary is:

* Easy to understand
* Easy to print
* Easy to serialize
* Easy to pass between functions

Later,

we may introduce custom model classes,

but dictionaries are an excellent starting point.

---

# Configuration vs Logic

Notice the difference.

Configuration

```python
self.base_url

self.timeout
```

Logic

```python
get_stock()
```

Keeping configuration separate from logic improves readability.

---

# Thinking About Responsibilities

Our service now has two kinds of responsibilities.

Configuration

↓

Stores information needed by the service.

Behavior

↓

Performs useful actions.

This is one of the core ideas behind object-oriented programming.

---

# Our Growing Architecture

Our application now looks like this.

```text
Panel Dashboard

↓

MarketDataService

    ├── base_url

    ├── timeout

    └── get_stock()

↓

Financial API
```

The service is beginning to take shape.

---

# Teacher's Notes

> Today's code may seem surprisingly simple, but that's intentional. Professional software is often built incrementally. We first create the structure—the class, its responsibilities, and its public interface—before filling in the implementation. This approach makes the code easier to reason about and avoids the temptation to solve too many problems at once.
>
> Another important habit is centralizing configuration. Values such as API URLs and timeout durations should not be scattered throughout your code. Keeping them together makes the application easier to configure, test, and maintain.

---

# Common Mistakes

## ❌ Mistake 1

Putting networking code directly inside the Panel application.

Keep networking inside the service.

---

## ❌ Mistake 2

Confusing a class with an object.

A class is a blueprint.

An object is an instance created from that blueprint.

---

## ❌ Mistake 3

Forgetting to use `self` when accessing instance variables.

Inside a class, use:

```python
self.timeout
```

not

```python
timeout
```

---

## ❌ Mistake 4

Hardcoding configuration values throughout the project.

Store them in one place.

---

## ❌ Mistake 5

Trying to implement every feature immediately.

Build the class structure first.

Add functionality gradually.

---

# Summary

In this lesson, you learned:

* How to organize a growing Python project into modules.
* Why services belong in their own `services` folder.
* How to define the `MarketDataService` class.
* The role of the `__init__()` constructor.
* How `self` refers to the current object.
* The purpose of instance variables such as `base_url` and `timeout`.
* How to define a public method like `get_stock()`.
* Why configuration should be centralized and separated from application logic.
* Why incremental development leads to cleaner, more maintainable software.

Our `MarketDataService` now has a solid structure. In the next lesson, we'll begin implementing its behavior by integrating the `requests` library, constructing API URLs, making HTTP requests, and retrieving live market data from an external financial API.

---

# Exercises

## Exercise 1 — Design the Class

Create a diagram showing the `MarketDataService` class.

Include:

* Instance variables
* Methods
* Their responsibilities

Explain why each belongs inside the service.

---

## Exercise 2 — Understanding Objects

Suppose the following code exists:

```python
service = MarketDataService()
```

Answer the following:

* What is the class?
* What is the object?
* When is `__init__()` executed?
* What does `self` refer to?

---

## Exercise 3 — Project Organization

Explain why the following structure is preferable to placing every file in the project root.

```text
sgx_stock_monitor/

├── app.py
├── services/
├── models/
├── utils/
└── config.py
```

Discuss how this organization supports maintainability as the application grows.

---

# Coming Up Next

In **Lesson 3.9 — Connecting the `MarketDataService` to a Live Financial API**, we'll replace placeholder methods with real functionality. You'll learn how to construct request URLs, send HTTP requests using `requests`, handle query parameters, retrieve live SGX market data, validate responses, and return normalized Python dictionaries. This will be the first lesson where our service communicates with an actual external data provider, bringing our SGX Stock Monitor to life.
