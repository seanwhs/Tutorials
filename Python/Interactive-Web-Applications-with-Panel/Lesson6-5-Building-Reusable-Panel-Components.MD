# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.5 — Building Reusable Panel Components: Composite Widgets, Custom Views, Encapsulation, and Component-Oriented Dashboard Architecture

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand component-oriented architecture.
> * Learn why reusable components matter.
> * Build composite widgets.
> * Create custom Panel components.
> * Encapsulate UI and business logic.
> * Design reusable financial dashboard widgets.
> * Understand component composition.
> * Build enterprise dashboard component libraries.
> * Learn how modern UI frameworks organize software.
> * Think like a UI systems architect rather than a dashboard programmer.

---

# Introduction

Throughout this tutorial, we have built dashboards using:

```python
pn.widgets.Select()

pn.indicators.Number()

pn.pane.Markdown()

pn.Column()
```

For example:

```python
dashboard = pn.Column(
    symbol_selector,
    chart,
    table
)
```

This works.

Until we build our second dashboard.

---

# The Problem

Suppose we build:

```text
SGX Dashboard
```

containing:

```text
Price Widget
```

Then management requests:

```text
Portfolio Dashboard
```

which also needs:

```text
Price Widget
```

Then:

```text
Analytics Dashboard
```

also requires:

```text
Price Widget
```

Soon:

```text
Price Widget
```

exists in:

```text
dashboard.py

portfolio.py

analytics.py

alerts.py
```

---

# This Is Duplication

Duplication causes:

* bugs
* inconsistency
* maintenance problems
* scaling problems

---

# Professional Engineers Solve This With Components

Instead of:

```text
Copy

Paste

Copy

Paste
```

we build:

```text
Reusable Components
```

---

# What Is A Component?

A component is:

> A self-contained piece of functionality.

---

# Example

Instead of:

```python
price = pn.indicators.Number()

chart = pn.pane.Matplotlib()

button = pn.widgets.Button()
```

everywhere,

we build:

```python
StockCard()
```

---

# Visualizing Components

```text
StockCard

├── Symbol
├── Price
├── Change
└── Chart
```

---

# Why Components Matter

Suppose we fix a bug.

Without components:

```text
Fix

↓

10 Files
```

---

# With components:

```text
Fix

↓

1 Component
```

---

# Component-Oriented Architecture

Modern frameworks use:

* React Components
* Vue Components
* Angular Components
* Flutter Widgets
* Panel Components

---

# Example Architecture

```text
Application

├── Header
├── Sidebar
├── Dashboard
│
├── StockCard
├── PriceChart
├── Watchlist
└── NewsPanel
```

---

# Building Our First Component

Suppose we repeatedly build:

```text
Stock Symbol

Price

Daily Change
```

---

# Traditional Approach

```python
symbol = pn.pane.Markdown()

price = pn.indicators.Number()

change = pn.indicators.Number()

card = pn.Column(
    symbol,
    price,
    change
)
```

---

# Component Approach

```python
class StockCard:
    pass
```

---

# Example

```python
import panel as pn

class StockCard:

    def __init__(
        self,
        symbol
    ):

        self.symbol = symbol

        self.price = pn.indicators.Number()

        self.change = pn.indicators.Number()

        self.view = pn.Column(

            symbol,

            self.price,

            self.change
        )
```

---

# Using The Component

```python
dbs = StockCard("D05")

uob = StockCard("U11")
```

---

# Visualizing

```text
StockCard

↓

D05

↓

Price

↓

Change
```

---

# Why This Is Better

Instead of:

```text
Widgets
```

we now have:

```text
Objects
```

---

# Understanding Encapsulation

Encapsulation means:

> Keep related things together.

---

# Example

Bad:

```python
price_widget

price_callback

price_data

price_chart
```

spread throughout the application.

---

# Better:

```python
StockCard

├── Widget
├── Data
├── Callback
└── Chart
```

---

# Composite Components

A component can contain components.

---

# Example

```text
Dashboard

├── StockCard
├── StockCard
├── StockCard
└── StockCard
```

---

# Visualizing Hierarchies

```text
Application

↓

Dashboard

↓

StockCard

↓

PriceWidget
```

---

# Example

```python
dashboard = pn.Row(

    StockCard("D05").view,

    StockCard("U11").view,

    StockCard("O39").view
)
```

---

# Building Financial Components

Suppose we repeatedly display:

```text
Symbol

Price

Volume

Market Cap

Chart
```

---

# Component Design

```text
MarketCard

├── Symbol
├── Price
├── Volume
├── Market Cap
└── Chart
```

---

# Example

```python
class MarketCard:

    def __init__(

        self,

        symbol
    ):

        self.symbol = symbol

        self.price = pn.indicators.Number()

        self.volume = pn.indicators.Number()

        self.market_cap = pn.indicators.Number()

        self.chart = pn.pane.Matplotlib()

        self.view = pn.Column(

            symbol,

            self.price,

            self.volume,

            self.market_cap,

            self.chart
        )
```

---

# Why Components Scale

Suppose we need:

```text
100 Stocks
```

Without components:

```text
100 Copies
```

---

# With components:

```python
stocks = [

    MarketCard(s)

    for s in symbols
]
```

---

# Understanding Component State

Components contain:

```text
UI

+

Data

+

Behavior
```

---

# Example

```text
StockCard

├── Symbol
├── Price
├── Update Method
└── Chart
```

---

# Adding Behavior

Example:

```python
class StockCard:

    def update(

        self,

        price
    ):

        self.price.value = price
```

---

# Visualizing

```text
Market Data

↓

Component

↓

UI Update
```

---

# Components And Param

The best Panel components inherit:

```python
param.Parameterized
```

---

# Example

```python
import param

class StockCard(

    param.Parameterized
):

    symbol = param.String()

    price = param.Number()
```

---

# Why?

Because components become:

```text
Reactive
```

automatically.

---

# Example

```python
class StockCard(

    param.Parameterized
):

    symbol = param.String()

    price = param.Number()

    @param.depends(
        "price"
    )
    def view(self):

        return pn.indicators.Number(

            value=self.price
        )
```

---

# Visualizing

```text
Price

↓

Component State

↓

Component View
```

---

# Component Lifecycle

Components experience:

```text
Create

↓

Initialize

↓

Render

↓

Update

↓

Destroy
```

---

# Why Lifecycle Matters

Suppose:

```text
500 Components
```

exist.

If components never disappear:

```text
Memory Leak
```

results.

---

# Component Communication

How do components communicate?

---

# Bad Solution

```python
global price
```

---

# Better Solution

```text
Shared State
```

---

# Example

```python
class MarketState(

    param.Parameterized
):

    symbol = param.String()

    price = param.Number()
```

---

# Component A

```python
market.price
```

---

# Component B

```python
market.price
```

---

# Visualizing

```text
Market State

├── Chart
├── Table
├── Alert
└── Portfolio
```

---

# Building A Watchlist Component

Example:

```text
Watchlist

├── DBS
├── UOB
├── OCBC
└── SIA
```

---

# Component

```python
class Watchlist(

    param.Parameterized
):

    stocks = param.List()
```

---

# Rendering

```python
def panel(self):

    return pn.Column(

        *self.stocks
    )
```

---

# Building A News Component

```text
NewsPanel

├── Headline
├── Timestamp
└── Summary
```

---

# Example

```python
class NewsPanel:

    def __init__(

        self,

        articles
    ):

        self.articles = articles
```

---

# Building A Chart Component

```text
ChartComponent

├── Symbol
├── Period
├── Indicator
└── Figure
```

---

# Example

```python
class ChartComponent(

    param.Parameterized
):

    symbol = param.String()

    period = param.Integer()
```

---

# Component Composition

Suppose:

```text
Dashboard
```

contains:

```text
Watchlist

Chart

Portfolio

News
```

---

# Architecture

```text
Dashboard

├── Watchlist
├── Chart
├── Portfolio
└── News
```

---

# Example

```python
class Dashboard:

    def __init__(self):

        self.watchlist = Watchlist()

        self.chart = ChartComponent()

        self.news = NewsPanel()
```

---

# Why Composition Is Powerful

Instead of:

```text
One Giant Dashboard
```

we build:

```text
Small Reusable Pieces
```

---

# Component Libraries

Large companies build:

```text
Internal Component Libraries
```

---

# Example

```text
components/

├── charts/
├── indicators/
├── tables/
├── cards/
├── layouts/
└── widgets/
```

---

# Benefits

Component libraries provide:

* consistency
* reuse
* maintainability
* testing
* scalability

---

# Example Directory Structure

```text
components/

├── stock_card.py
├── watchlist.py
├── news_panel.py
├── price_chart.py
├── portfolio_card.py
├── alert_panel.py
└── market_table.py
```

---

# Enterprise Dashboard Architecture

```text
Application

├── Templates
├── Views
├── Components
├── State
├── Services
└── APIs
```

---

# Example

```text
User

↓

Template

↓

Dashboard

↓

Components

↓

State

↓

Services

↓

API
```

---

# Component Testing

Components are easier to test.

---

# Example

Instead of testing:

```text
Entire Dashboard
```

we test:

```text
StockCard
```

alone.

---

# Example

```python
card = StockCard()

card.update(50)

assert card.price.value == 50
```

---

# Why Testing Matters

Large dashboards may contain:

```text
Thousands Of Components
```

Testing entire systems becomes impossible.

---

# Thinking Like A Component Architect

Beginners ask:

> How do I build this page?

Intermediate developers ask:

> How do I build this dashboard?

Component architects ask:

> What reusable building blocks exist?

Because modern applications are not:

```text
Pages
```

They are:

```text
Component Systems
```

---

# React, Vue, Flutter, And Panel

All modern UI frameworks converge on:

```text
Component

↓

Composition

↓

Application
```

---

# The Hidden Secret

Bloomberg Terminal is not:

```text
One Application
```

It is:

```text
Thousands

Of Components
```

working together.

---

# Teacher's Notes

> One of the biggest transitions from beginner to professional UI engineering is moving from page-oriented thinking to component-oriented thinking. Large applications survive because they are decomposed into reusable, independently maintainable units.
>
> Another important lesson is that components are not merely UI elements. They encapsulate state, behavior, rendering, validation, and communication.

---

# Common Mistakes

## ❌ Mistake 1

Building giant dashboard files.

---

## ❌ Mistake 2

Copy-pasting widgets.

---

## ❌ Mistake 3

Using global variables.

---

## ❌ Mistake 4

Mixing state and presentation.

---

## ❌ Mistake 5

Building pages instead of components.

---

# Summary

In this lesson, you learned:

* Components encapsulate functionality.
* Encapsulation improves maintainability.
* Composite components enable reuse.
* Param makes components reactive.
* Components communicate through shared state.
* Component libraries improve scalability.
* Enterprise applications organize around components.
* Testing becomes easier with components.
* Modern UI frameworks are fundamentally component systems.
* Dashboard engineering is increasingly component engineering.

You now understand the architectural foundation used by modern UI frameworks and enterprise dashboard systems.

---

# Exercises

## Exercise 1 — Build A StockCard Component

Create a component containing:

* symbol
* price
* volume
* daily change
* mini chart

---

## Exercise 2 — Build A Watchlist Component

Create a component that manages:

* adding stocks
* removing stocks
* displaying stocks
* sorting stocks

---

## Exercise 3 — Design A Component Library

Design the component hierarchy for:

```text
SGX Trading Terminal
```

Include:

* charts
* indicators
* watchlists
* portfolios
* alerts
* news
* analytics

---

# Coming Up Next

In **Lesson 6.6 — Custom Panel Components, JavaScript Integration, ESM Components, and Extending Panel Beyond Python**, we'll learn how Panel communicates with JavaScript, how to build entirely new Panel widgets, how ESM components work, and how professional developers extend Panel beyond its built-in capabilities.
