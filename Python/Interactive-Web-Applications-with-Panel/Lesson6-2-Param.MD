# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.2 — Mastering Param: Reactive Variables, Parameterized Classes, Dependencies, Watchers, and State Management

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand why Param exists.
> * Learn what reactive variables are.
> * Create Parameterized classes.
> * Understand Parameters.
> * Use Param watchers.
> * Create dependency graphs.
> * Build computed properties.
> * Validate application state.
> * Design enterprise state management architectures.
> * Think like a reactive systems engineer.

---

# Introduction

In the previous lesson, we learned:

> Panel is fundamentally a state synchronization framework.

This immediately creates a problem.

Suppose we write:

```python
price = 41.35

price = 42.10
```

How does Panel know:

```text
Price Changed?
```

The answer is:

> It doesn't.

---

# The Fundamental Problem

Normal Python variables have no memory.

Example:

```python
x = 5

x = 10
```

Python simply executes:

```text
Okay.
```

No event occurs.

No notification occurs.

No callback occurs.

---

# Why Is This A Problem?

Suppose we have:

```text
Price

↓

Chart

↓

Indicator

↓

Alert

↓

Portfolio
```

If:

```python
price = 42
```

changes, how do we notify everything?

Standard Python provides no mechanism.

---

# Enter Param

Param is a library that provides:

> Reactive variables.

---

# What Is A Reactive Variable?

A reactive variable is a variable that says:

```text
I changed.
```

when its value changes.

---

# Traditional Variable

```python
price = 41

price = 42
```

Result:

```text
No notification.
```

---

# Reactive Variable

```text
price = 41

↓

price = 42

↓

EVENT GENERATED
```

---

# Why Param Exists

Param solves four major problems:

| Problem      | Solution        |
| ------------ | --------------- |
| State        | Parameters      |
| Validation   | Parameter Types |
| Notification | Watchers        |
| Dependencies | Reactive Graphs |

---

# Installing Param

```bash
pip install param
```

---

# Importing Param

```python
import param
```

---

# Your First Parameterized Class

Consider:

```python
class Stock:

    price = 41
```

Nothing special exists here.

Instead:

```python
import param

class Stock(

    param.Parameterized
):

    price = param.Number(
        default=41
    )
```

---

# What Is Parameterized?

`Parameterized` is:

> The base class for all reactive objects.

---

# Visualizing Parameterized Objects

```text
Python Object

↓

Parameterized

↓

Reactive Object

↓

Panel
```

---

# Creating An Object

```python
dbs = Stock()
```

---

# Accessing Values

```python
print(dbs.price)
```

Output:

```text
41
```

---

# Updating Values

```python
dbs.price = 45
```

Unlike Python variables:

```text
An Event Is Generated.
```

---

# Visualizing State Changes

```text
Price = 41

↓

Price = 45

↓

Notify Observers
```

---

# Understanding Parameters

A Parameter is:

> A reactive attribute.

---

# Example

```python
class Stock(

    param.Parameterized
):

    symbol = param.String()

    price = param.Number()

    volume = param.Integer()
```

---

# Why Not Use Python Types?

Python types provide:

```text
Storage
```

Param types provide:

```text
Storage

+

Validation

+

Events

+

Metadata
```

---

# Understanding Metadata

Example:

```python
price = param.Number(

    default=41,

    bounds=(0,1000),

    doc="Stock price"
)
```

---

# What Did We Add?

We added:

* default value
* validation
* documentation

---

# Visualizing Parameter Metadata

```text
Parameter

├── Value
├── Type
├── Bounds
├── Documentation
└── Events
```

---

# Parameter Types

Param provides many parameter types.

---

# String

```python
symbol = param.String()
```

---

# Integer

```python
volume = param.Integer()
```

---

# Number

```python
price = param.Number()
```

---

# Boolean

```python
market_open = param.Boolean()
```

---

# Date

```python
trade_date = param.Date()
```

---

# List

```python
watchlist = param.List()
```

---

# Dictionary

```python
portfolio = param.Dict()
```

---

# Object Selector

```python
exchange = param.ObjectSelector(

    default="SGX",

    objects=[
        "SGX",
        "NYSE",
        "NASDAQ"
    ]
)
```

---

# Why ObjectSelector Matters

Suppose:

```text
SGX

NYSE

NASDAQ
```

are valid.

This becomes impossible:

```python
exchange = "MARS"
```

---

# Validation

Suppose:

```python
price = param.Number(
    bounds=(0,100)
)
```

---

# Valid

```python
stock.price = 50
```

---

# Invalid

```python
stock.price = -100
```

Result:

```text
Validation Error
```

---

# Why Validation Matters

Without validation:

```text
Garbage Input

↓

Garbage Output
```

---

# Understanding Watchers

A watcher is:

> A function that executes when a parameter changes.

---

# Example

```python
def changed(event):

    print(
        "Price changed"
    )
```

---

# Registering A Watcher

```python
stock.param.watch(

    changed,

    "price"
)
```

---

# Visualizing Watchers

```text
Price Changes

↓

Watcher Executes

↓

Action Occurs
```

---

# Example

```python
stock.price = 50
```

Output:

```text
Price changed
```

---

# Understanding Event Objects

Watchers receive:

```python
event
```

---

# Example

```python
def changed(event):

    print(event.old)

    print(event.new)
```

---

# Example Output

```text
41

50
```

---

# Event Structure

```text
Event

├── old
├── new
├── name
├── type
└── object
```

---

# Example

```python
def changed(event):

    print(event.name)
```

Output:

```text
price
```

---

# Watching Multiple Parameters

```python
stock.param.watch(

    callback,

    [

        "price",

        "volume"
    ]
)
```

---

# Visualizing

```text
Price

↓

Callback

Volume

↓
```

---

# Automatic Watchers

Param provides decorators.

---

# Example

```python
class Stock(

    param.Parameterized
):

    price = param.Number()

    @param.depends(
        "price",
        watch=True
    )
    def changed(self):

        print(
            self.price
        )
```

---

# What Does `watch=True` Mean?

It means:

```text
Automatically Execute

When Dependencies Change
```

---

# Understanding Dependencies

Suppose:

```text
Price

↓

Moving Average

↓

Signal
```

---

# Dependency Graph

```text
Price

├── EMA
│
└── RSI
     │
     └── Signal
```

---

# Why Dependency Graphs Matter

When:

```text
Price Changes
```

Panel knows:

```text
Exactly What To Update
```

---

# Computed Parameters

Suppose:

```text
Shares = 100

Price = 40
```

Then:

```text
Value = 4000
```

should update automatically.

---

# Example

```python
class Position(

    param.Parameterized
):

    shares = param.Integer()

    price = param.Number()

    @param.depends(
        "shares",
        "price"
    )
    def value(self):

        return (

            self.shares *

            self.price
        )
```

---

# Visualizing Computed Values

```text
Shares

↓

Price

↓

Computed Value
```

---

# Example

```python
p = Position(

    shares=100,

    price=40
)
```

---

# Output

```python
p.value()
```

returns:

```text
4000
```

---

# Updating Price

```python
p.price = 45
```

Now:

```python
p.value()
```

returns:

```text
4500
```

---

# Building Reactive Models

Suppose we build:

```python
class MarketState(

    param.Parameterized
):

    symbol = param.String()

    price = param.Number()

    volume = param.Integer()

    market_open = param.Boolean()
```

---

# Visualizing State

```text
MarketState

├── Symbol
├── Price
├── Volume
└── Market Open
```

---

# Why This Matters

Instead of:

```python
price

volume

market_open

symbol
```

floating everywhere,

we now have:

```python
market
```

---

# Encapsulation

This concept is called:

> Encapsulation.

---

# Example

Bad:

```python
global price

global volume

global market
```

---

# Better:

```python
market.price

market.volume
```

---

# Enterprise State Architecture

Large systems organize state into models.

Example:

```text
Application

├── MarketState
├── PortfolioState
├── AlertState
├── UserState
└── AnalyticsState
```

---

# Example

```python
class PortfolioState(

    param.Parameterized
):

    cash = param.Number()

    positions = param.Dict()

    pnl = param.Number()
```

---

# Why Separate State?

Without separation:

```text
One Giant Object
```

results.

---

# Problems With Giant Objects

```text
Huge Memory

Complex Dependencies

Difficult Testing

Poor Maintenance
```

---

# State Hierarchies

Professional applications build:

```text
ApplicationState

├── User
├── Market
├── Portfolio
└── Analytics
```

---

# Example

```python
class AppState(

    param.Parameterized
):

    market = param.ClassSelector(

        class_=MarketState
    )

    portfolio = param.ClassSelector(

        class_=PortfolioState
    )
```

---

# Why Hierarchies Matter

Hierarchies create:

* isolation
* maintainability
* scalability
* testability

---

# Param and Panel

Panel automatically understands Param.

Example:

```python
pn.Param(stock)
```

---

# What Happens?

Panel generates:

```text
Widgets

↓

Bindings

↓

Callbacks

↓

Synchronization
```

automatically.

---

# Example

```python
class Stock(

    param.Parameterized
):

    symbol = param.String()

    price = param.Number()
```

---

# Then:

```python
pn.Param(
    Stock()
)
```

creates:

```text
Symbol Widget

Price Widget
```

automatically.

---

# Visualizing Param + Panel

```text
Param

↓

Metadata

↓

Panel

↓

Automatic UI
```

---

# Why Param Is Brilliant

Param turns:

```python
class Stock:
```

into:

```text
Data Model

+

Validation

+

Events

+

Dependencies

+

Documentation

+

UI Definition
```

simultaneously.

---

# Real Architecture Of Enterprise Panel Applications

```text
Panel

↓

Views

↓

Param

↓

State Models

↓

Services

↓

Database/APIs
```

---

# Thinking Like A Reactive Systems Engineer

Beginners ask:

> How do I create widgets?

Intermediate developers ask:

> How do I synchronize widgets?

Professionals ask:

> How should application state be modeled?

Because once state is modeled correctly:

```text
Everything Else

Becomes Easier.
```

---

# Teacher's Notes

> One of the biggest mistakes beginners make is thinking Param is merely a helper library for Panel. In reality, Param is a state modeling framework. Panel is essentially a visualization and synchronization layer built on top of Param.
>
> Another important lesson is that enterprise software architecture is largely a state management problem. The complexity of large applications often comes not from algorithms, but from managing changing state correctly.

---

# Common Mistakes

## ❌ Mistake 1

Using global variables.

---

## ❌ Mistake 2

Building one giant state object.

---

## ❌ Mistake 3

Ignoring validation.

---

## ❌ Mistake 4

Using callbacks everywhere.

---

## ❌ Mistake 5

Treating Param as a UI library.

---

# Summary

In this lesson, you learned:

* Param provides reactive variables.
* Parameterized classes create reactive objects.
* Parameters provide validation and metadata.
* Watchers respond to changes.
* Dependencies create reactive graphs.
* Computed properties derive state.
* State models encapsulate data.
* State hierarchies improve scalability.
* Panel automatically integrates with Param.
* Enterprise applications are fundamentally state management systems.

You now understand the most important abstraction layer underneath Panel.

---

# Exercises

## Exercise 1 — Create A Stock Model

Create a Param class containing:

* symbol
* company_name
* price
* volume
* market_cap

---

## Exercise 2 — Create A Portfolio Model

Create a Param class containing:

* cash
* holdings
* total_value

---

## Exercise 3 — Build A Dependency Graph

Construct the dependency graph for:

```text
Price

↓

EMA

↓

MACD

↓

Signal

↓

Alert
```

---

# Coming Up Next

In **Lesson 6.3 — Reactive Expressions, `pn.bind()`, `@param.depends()`, and Functional Reactive Programming in Panel**, we'll learn how Panel constructs reactive computation graphs using bindings, dependencies, functional reactive programming, and declarative programming patterns that eliminate most callbacks entirely.
