# Part V — Working with Live SGX Market Data

# Lesson 5.10 — Building Financial Dashboards with Panel: Indicators, Tables, Charts, and Real-Time Visualization

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what makes a financial dashboard effective.
> * Learn how to build professional dashboards using Panel.
> * Understand Panel panes, indicators, widgets, and layouts.
> * Display SGX stock data using multiple visual components.
> * Build KPI indicators.
> * Create interactive data tables.
> * Create stock price charts.
> * Design responsive dashboard layouts.
> * Organize dashboards using tabs and cards.
> * Think like a dashboard designer rather than merely a programmer.

---

# Introduction

Our SGX Stock Monitor currently works.

A user enters:

```text
D05
```

presses:

```text
Search
```

and sees:

```json
{
    "symbol": "D05",
    "price": 41.35
}
```

Technically, this is correct.

Professionally, this is terrible.

No real financial dashboard looks like this.

Our goal is to transform:

```text
Raw Data
```

into:

```text
Information

↓

Insights

↓

Decisions
```

---

# What Is a Dashboard?

A dashboard is:

> A visual system for monitoring important information.

Examples include:

* stock trading terminals
* airline operations centers
* hospital monitoring systems
* manufacturing control rooms
* cybersecurity monitoring platforms

---

# Why Dashboards Exist

Humans are poor at reading large amounts of text.

Consider:

```json
{
    "price": 41.35,
    "change": 1.25,
    "volume": 3500000
}
```

versus:

```text
┌─────────────┐
│ DBS (D05)   │
├─────────────┤
│ $41.35      │
│ ▲ +1.25%    │
│ 3.5M shares │
└─────────────┘
```

The second version communicates information much faster.

---

# Principles of Financial Dashboard Design

Professional dashboards optimize for:

| Principle      | Goal                       |
| -------------- | -------------------------- |
| Clarity        | Easy to understand         |
| Speed          | Fast information retrieval |
| Consistency    | Predictable layout         |
| Density        | Maximum useful information |
| Responsiveness | Immediate feedback         |
| Reliability    | Always operational         |

---

# What Components Do Financial Dashboards Use?

Typical components include:

```text
Price Indicators

Market Tables

Price Charts

News Feeds

Volume Charts

Sector Heatmaps

Watchlists

Alerts
```

---

# Panel's Dashboard Building Blocks

Panel provides several categories of components.

```text
Widgets

Panes

Indicators

Layouts

Templates

Charts

Tables
```

Each serves a different purpose.

---

# Understanding Panel Panes

Recall:

```python
pn.pane.Markdown()
```

A pane displays:

> Existing content.

Examples include:

* text
* HTML
* JSON
* images
* charts
* dataframes

---

# Pane Architecture

```text
Python Object

↓

Pane

↓

Browser Display
```

---

# Example

```python
import panel as pn

price = pn.pane.Markdown(
    "# $41.35"
)
```

Result:

```text
$41.35
```

---

# Understanding Indicators

Indicators display:

> Important metrics.

Examples:

* stock price
* percentage change
* trading volume
* market capitalization

---

# Real Financial Dashboard Example

```text
Price:

$41.35

Change:

+1.25%

Volume:

3.5M
```

Each value acts as an indicator.

---

# Panel Indicators

Panel provides:

```text
Number

Trend

Gauge

Progress

Boolean

Dial
```

---

# Number Indicators

Example:

```python
import panel as pn

price_indicator = pn.indicators.Number(

    name="DBS",

    value=41.35,

    format="${value}"
)
```

---

# Visual Result

```text
DBS

$41.35
```

This immediately looks more professional.

---

# Understanding the `name` Parameter

The parameter:

```python
name="DBS"
```

creates the label.

```text
DBS

41.35
```

---

# Understanding the `value` Parameter

```python
value=41.35
```

defines the displayed metric.

---

# Understanding Formatting

Panel supports formatting.

Example:

```python
format="${value}"
```

produces:

```text
$41.35
```

instead of:

```text
41.35
```

---

# Updating Indicators

Indicators are reactive.

Example:

```python
price_indicator.value = 42.10
```

Panel automatically updates the display.

---

# Reactive Architecture

```text
Python Variable Changes

↓

Panel Detects Change

↓

Browser Updates
```

No page refresh is required.

---

# Displaying Price Changes

Suppose DBS rises:

```text
41.35

↓

42.10
```

We calculate:

```python
change = 42.10 - 41.35
```

Result:

```text
+0.75
```

---

# Building Multiple Indicators

Financial dashboards rarely display one metric.

Example:

```python
price_indicator

change_indicator

volume_indicator
```

---

# Visualizing KPI Cards

```text
┌──────────┐
│ Price    │
│ $41.35   │
└──────────┘

┌──────────┐
│ Change   │
│ +1.25%   │
└──────────┘

┌──────────┐
│ Volume   │
│ 3.5M     │
└──────────┘
```

---

# Creating Horizontal Layouts

Panel provides:

```python
pn.Row()
```

Example:

```python
metrics = pn.Row(

    price_indicator,

    change_indicator,

    volume_indicator
)
```

---

# Understanding `pn.Row`

Recall:

```text
Left → Right
```

layout.

---

# Building Tables

Financial applications depend heavily upon tables.

Examples:

* watchlists
* market movers
* historical prices
* portfolios

---

# Creating DataFrames

Suppose we have:

```python
import pandas as pd

df = pd.DataFrame({

    "Symbol": ["D05", "U11"],

    "Price": [41.35, 30.15]
})
```

---

# Displaying DataFrames

Simple approach:

```python
table = pn.pane.DataFrame(df)
```

---

# Visual Result

```text
Symbol    Price

D05       41.35

U11       30.15
```

---

# Why DataFrames Matter

Most financial information eventually becomes:

```text
Rows

+

Columns
```

Understanding tables is essential.

---

# Introducing Tabulator

Panel provides:

```python
pn.widgets.Tabulator()
```

This is a professional interactive table component.

---

# Example

```python
table = pn.widgets.Tabulator(
    df
)
```

---

# Features of Tabulator

It supports:

* sorting
* filtering
* pagination
* selection
* resizing
* editing

---

# Why Use Tabulator?

Compare:

Basic table:

```text
Static
```

Tabulator:

```text
Interactive
```

---

# Example Financial Table

```text
Symbol    Price    Change

D05       41.35    +1.25%

U11       30.15    -0.75%

O39       15.40    +0.50%
```

Users can:

* sort by price
* sort by change
* search symbols

---

# Understanding Financial Charts

Humans understand trends visually.

Compare:

```text
41.0
41.2
41.4
41.6
41.8
```

versus:

```text
      /
     /
    /
   /
__/
```

The chart communicates immediately.

---

# Chart Architecture

```text
Historical Data

↓

DataFrame

↓

Chart

↓

Dashboard
```

---

# Creating Historical Data

Example:

```python
df = pd.DataFrame({

    "date": dates,

    "price": prices
})
```

---

# Plotting in Panel

Panel can display:

* Matplotlib
* Plotly
* Bokeh
* HoloViews

---

# Why Multiple Chart Libraries?

Different libraries optimize for different goals.

| Library    | Strength                 |
| ---------- | ------------------------ |
| Matplotlib | Scientific plotting      |
| Plotly     | Interactive charts       |
| Bokeh      | Dashboards               |
| HoloViews  | High-level visualization |

---

# Example Plotly Chart

```python
import plotly.express as px

fig = px.line(

    df,

    x="date",

    y="price"
)
```

---

# Displaying Charts

Simply:

```python
chart = pn.pane.Plotly(
    fig
)
```

---

# Visual Result

```text
Price

45 ────
44 ──╮
43 ─╮│
42 ╮││
41 │││
```

---

# Why Charts Matter

Charts answer questions like:

* Is the stock rising?
* Is volatility increasing?
* Is momentum changing?
* Is support forming?

Without requiring users to analyze numbers manually.

---

# Combining Components

A professional dashboard combines:

```text
Indicators

↓

Tables

↓

Charts
```

---

# Example Dashboard Structure

```text
SGX Dashboard

Indicators

Price Chart

Watchlist

Recent Activity
```

---

# Building Dashboard Sections

Panel provides:

```python
pn.Card()
```

---

# What Is a Card?

A card groups related information.

Example:

```python
price_card = pn.Card(

    metrics,

    title="Stock Metrics"
)
```

---

# Visualizing Cards

```text
┌──────────────────────┐
│ Stock Metrics        │
├──────────────────────┤
│ Price                │
│ Change               │
│ Volume               │
└──────────────────────┘
```

---

# Organizing With Tabs

Large dashboards become crowded.

Panel provides:

```python
pn.Tabs()
```

---

# Example

```python
tabs = pn.Tabs(

    ("Overview", overview),

    ("History", history),

    ("News", news)
)
```

---

# Visual Result

```text
Overview | History | News
```

This improves organization.

---

# Dashboard Layout Architecture

Our SGX dashboard might become:

```text
Title

Metrics Row

Price Chart

Tabs

    Overview

    History

    News
```

---

# Implementing The Layout

```python
dashboard = pn.Column(

    title,

    metrics,

    chart,

    tabs
)
```

---

# Responsive Design

Users may have:

* laptops
* tablets
* ultrawide monitors

Panel layouts automatically adapt.

---

# Why Layout Matters

Bad dashboard:

```text
Everything Everywhere
```

Good dashboard:

```text
Information Hierarchy
```

The most important information appears first.

---

# Visual Hierarchy

Example:

```text
Current Price

↓

Daily Change

↓

Chart

↓

Historical Data

↓

News
```

This ordering guides user attention.

---

# Our SGX Dashboard Architecture

```text
SGX Dashboard

├── Search Controls

├── KPI Indicators

├── Price Chart

├── Watchlist Table

└── News Tabs
```

---

# Thinking Like a Dashboard Designer

Beginners think:

> "How do I display this data?"

Professionals think:

> "What decisions should the user be able to make?"

This shift changes everything.

Dashboards exist to support decision-making.

---

# Teacher's Notes

> Dashboard development is not simply about programming widgets. It is a combination of software engineering, user experience design, visual communication, and information architecture. The best dashboards minimize cognitive load while maximizing actionable information.
>
> Another important lesson is that visualization is a form of abstraction. Charts, indicators, and tables transform raw numerical data into patterns that humans can understand quickly.

---

# Common Mistakes

## ❌ Mistake 1

Displaying raw JSON.

---

## ❌ Mistake 2

Showing too much information simultaneously.

---

## ❌ Mistake 3

Ignoring visual hierarchy.

---

## ❌ Mistake 4

Using tables when charts communicate better.

---

## ❌ Mistake 5

Building dashboards around data rather than user decisions.

---

# Summary

In this lesson, you learned:

* Financial dashboards communicate information visually.
* Panel provides panes, indicators, tables, charts, and layouts.
* Indicators display important metrics.
* Tabulator creates interactive financial tables.
* Charts reveal trends and patterns.
* Cards organize related information.
* Tabs structure large dashboards.
* Layouts create visual hierarchy.
* Dashboard design focuses on decision-making rather than data display.

We now have all the building blocks required for a professional financial dashboard. The next step is implementing real-time updates, automatic refreshes, periodic callbacks, and live market monitoring.

---

# Exercises

## Exercise 1 — Dashboard Design

Design a dashboard for:

* DBS (D05)
* UOB (U11)
* OCBC (O39)

List:

* indicators
* charts
* tables
* tabs

that you would include.

---

## Exercise 2 — Component Selection

Choose the best Panel component for:

* current stock price
* watchlist
* historical price trend
* company news
* sector performance

Explain your reasoning.

---

## Exercise 3 — Visual Hierarchy

Arrange the following in order of importance:

* historical chart
* stock symbol
* current price
* trading volume
* company news
* percentage change

Explain why.

---

# Coming Up Next

In **Lesson 5.11 — Real-Time Updates and Live Market Monitoring: Periodic Callbacks, Auto Refresh, and Streaming Data**, we'll transform our dashboard into a true market monitoring system by implementing automatic refresh intervals, periodic callbacks, streaming updates, watchlists, market timers, live indicators, and real-time dashboard synchronization using Panel's reactive and scheduling capabilities.
