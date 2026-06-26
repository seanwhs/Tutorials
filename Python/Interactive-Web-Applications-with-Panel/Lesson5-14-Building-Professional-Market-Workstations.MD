# Part V — Working with Live SGX Market Data

# Lesson 5.14 — Building Professional Market Workstations: Watchlists, Portfolios, Alerts, Multi-Stock Comparison, and Market Intelligence Dashboards

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what professional market workstations are.
> * Learn how financial professionals organize information.
> * Build watchlists using Panel.
> * Create portfolio monitoring systems.
> * Implement alert engines.
> * Build stock comparison dashboards.
> * Design market intelligence dashboards.
> * Understand dashboard information architecture.
> * Create Bloomberg-style layouts using Panel.
> * Think like a financial systems architect.

---

# Introduction

Our SGX dashboard now supports:

* live prices
* charts
* indicators
* technical analysis
* real-time updates

This is already useful.

But professional traders don't monitor:

```text
One Stock
```

They monitor:

```text
Entire Markets
```

---

# What Is a Market Workstation?

A market workstation is:

> A system that allows users to monitor, analyze, compare, and react to financial markets in real time.

Examples include:

* Bloomberg Terminal
* Reuters Eikon
* TradingView
* Interactive Brokers Trader Workstation
* Refinitiv Workspace

---

# What Makes These Systems Powerful?

Not better charts.

Not prettier dashboards.

Instead:

```text
Information Density

+

Organization

+

Speed
```

---

# Visualizing a Professional Market Terminal

```text
Market Overview

Watchlist

Portfolio

Charts

Technical Indicators

News

Alerts

Market Breadth
```

---

# Thinking Beyond Single Stocks

Beginners ask:

> What is DBS doing?

Professionals ask:

> What is the Singapore market doing?

---

# Our Professional SGX Workstation

We will build:

```text
SGX Workstation

├── Market Overview
├── Watchlists
├── Portfolio
├── Alerts
├── Comparison Engine
├── Technical Analysis
├── Market Intelligence
└── News
```

---

# Section 1 — Building Watchlists

---

# What Is A Watchlist?

A watchlist is:

> A collection of securities that users monitor regularly.

Example:

| Symbol |
| ------ |
| D05    |
| U11    |
| O39    |
| Z74    |

---

# Why Watchlists Matter

Without watchlists:

```text
Search

↓

Search

↓

Search
```

With watchlists:

```text
One Dashboard

↓

Everything Visible
```

---

# Creating A Watchlist

```python
watchlist = [

    "D05",
    "U11",
    "O39",
    "Z74"
]
```

---

# Loading Watchlist Data

```python
rows = []

for symbol in watchlist:

    stock = market_service.get_stock(
        symbol
    )

    rows.append(stock)
```

---

# Creating A DataFrame

```python
import pandas as pd

df = pd.DataFrame(rows)
```

---

# Example Result

| Symbol | Price | Change |
| ------ | ----- | ------ |
| D05    | 41.35 | +1.20  |
| U11    | 30.15 | +0.40  |
| O39    | 15.20 | -0.15  |
| Z74    | 3.65  | +0.05  |

---

# Displaying Watchlists

```python
watchlist_table = (
    pn.widgets.Tabulator(df)
)
```

---

# Why Tabulator?

Tabulator provides:

* sorting
* searching
* filtering
* resizing
* pagination

automatically.

---

# Visualizing Watchlists

```text
Symbol   Price   Change

D05      41.35   +1.20

U11      30.15   +0.40

O39      15.20   -0.15
```

---

# Section 2 — Portfolio Monitoring

---

# What Is A Portfolio?

A portfolio represents:

> Assets owned by an investor.

Example:

| Symbol | Shares |
| ------ | ------ |
| D05    | 100    |
| U11    | 200    |
| O39    | 500    |

---

# Why Portfolios Matter

Investors care about:

```text
My Holdings

Not

The Entire Market
```

---

# Creating Portfolio Data

```python
portfolio = {

    "D05": 100,

    "U11": 200,

    "O39": 500
}
```

---

# Calculating Position Value

Formula:

```text
Shares

×

Current Price
```

---

# Example

```python
position_value = (

    shares *

    stock["price"]
)
```

---

# Calculating Portfolio Value

```python
total = 0

for symbol, shares in portfolio.items():

    stock = market_service.get_stock(
        symbol
    )

    total += (
        stock["price"] *
        shares
    )
```

---

# Example Output

| Symbol | Shares | Price | Value |
| ------ | ------ | ----- | ----- |
| D05    | 100    | 41.35 | 4135  |
| U11    | 200    | 30.15 | 6030  |
| O39    | 500    | 15.20 | 7600  |

---

# Portfolio Dashboard

```text
Portfolio Value

$17,765

Today's Gain

+$420

Return

+3.5%
```

---

# Section 3 — Building Alert Systems

---

# What Is An Alert?

An alert is:

> A rule that notifies users when conditions occur.

Examples:

```text
DBS > 45

RSI < 30

MACD Cross

Volume Spike
```

---

# Why Alerts Matter

Humans cannot monitor:

```text
100 Stocks

24 Hours

Per Day
```

Computers can.

---

# Example Alert Rule

```python
if price > 45:

    alert()
```

---

# Building Alert Objects

```python
alerts = [

    {

        "symbol": "D05",

        "condition": ">",

        "value": 45
    }
]
```

---

# Alert Evaluation

```python
for alert in alerts:

    stock = (
        market_service
        .get_stock(
            alert["symbol"]
        )
    )

    if stock["price"] > 45:

        notify()
```

---

# Displaying Alerts

```text
ALERT

DBS exceeded $45
```

---

# Visual Alert Indicators

Panel provides:

```python
pn.indicators.BooleanStatus()
```

---

# Example

```python
alert_status = (
    pn.indicators.BooleanStatus(

        value=True,

        color="danger"
    )
)
```

---

# Section 4 — Multi-Stock Comparison

---

# Why Compare Stocks?

Suppose we ask:

> Which bank performed best?

We compare:

* DBS
* UOB
* OCBC

---

# Comparison Architecture

```text
Stock A

Stock B

Stock C

↓

Metrics

↓

Ranking
```

---

# Example Comparison Table

| Stock | Return | RSI | Volatility |
| ----- | ------ | --- | ---------- |
| DBS   | 10%    | 65  | 0.20       |
| UOB   | 5%     | 55  | 0.15       |
| OCBC  | 7%     | 70  | 0.18       |

---

# Ranking Stocks

```python
df.sort_values(
    "Return",
    ascending=False
)
```

---

# Example Result

```text
DBS

OCBC

UOB
```

---

# Why Ranking Matters

Markets contain:

```text
Thousands

Of Stocks
```

Ranking helps identify:

```text
Best

and

Worst
```

performers.

---

# Section 5 — Market Breadth

---

# What Is Market Breadth?

Market breadth measures:

> How many stocks participate in market movement.

---

# Example

Suppose:

```text
500 Stocks

350 Up

150 Down
```

This indicates:

```text
Strong Market
```

---

# Another Example

```text
500 Stocks

50 Up

450 Down
```

This indicates:

```text
Weak Market
```

---

# Calculating Breadth

```python
advancers = 350

decliners = 150

ratio = (

    advancers /

    decliners
)
```

---

# Visualizing Breadth

```text
Advancers

████████

Decliners

███
```

---

# Section 6 — Market Intelligence

---

# What Is Market Intelligence?

Market intelligence means:

> Understanding the market as a system.

---

# Components

Examples include:

* top gainers
* top losers
* most active
* strongest sectors
* weakest sectors
* volatility leaders

---

# Example Dashboard

```text
Top Gainers

Top Losers

Most Active

Highest Volume

Highest RSI
```

---

# Creating Top Gainers

```python
df.sort_values(

    "change",

    ascending=False
)
```

---

# Creating Top Losers

```python
df.sort_values(

    "change",

    ascending=True
)
```

---

# Creating Most Active

```python
df.sort_values(

    "volume",

    ascending=False
)
```

---

# Section 7 — Building Professional Layouts

---

# Information Architecture

Professional dashboards prioritize:

```text
Important

↓

Useful

↓

Interesting
```

---

# Example Layout

```text
Header

Market Summary

Portfolio

Watchlist

Technical Charts

Alerts

Market Breadth

News
```

---

# Building Dashboard Sections

```python
portfolio_card

watchlist_card

alert_card

breadth_card
```

---

# Combining Sections

```python
dashboard = pn.Column(

    summary_card,

    portfolio_card,

    watchlist_card,

    alert_card,

    breadth_card
)
```

---

# Organizing With Tabs

```python
tabs = pn.Tabs(

    ("Portfolio", portfolio),

    ("Watchlist", watchlist),

    ("Analytics", analytics),

    ("Alerts", alerts),

    ("Market", market)
)
```

---

# Visualizing Dashboard Structure

```text
Portfolio

Watchlist

Analytics

Alerts

Market
```

---

# Section 8 — Creating Bloomberg-Style Layouts

---

# Bloomberg Philosophy

Bloomberg terminals optimize for:

```text
Maximum Information

Minimum Time
```

---

# Example Layout

```text
Market Summary

------------------

Watchlist

Portfolio

------------------

Price Chart

RSI

MACD

------------------

Alerts

News
```

---

# Panel Layout Components

Panel provides:

```python
pn.Row()

pn.Column()

pn.GridBox()

pn.Tabs()

pn.Card()
```

---

# Example Grid

```python
grid = pn.GridBox(

    card1,

    card2,

    card3,

    ncols=3
)
```

---

# Why Grid Layouts Matter

They maximize:

```text
Information Density
```

while maintaining:

```text
Readability
```

---

# Our Final Architecture

```text
Panel Dashboard

↓

Market Service

↓

Analytics Engine

↓

Portfolio Engine

↓

Alert Engine

↓

Market Intelligence

↓

Visualization Layer
```

---

# Thinking Like A Financial Systems Architect

Beginners ask:

> How do I display a stock?

Intermediate developers ask:

> How do I display many stocks?

Professionals ask:

> How do users make decisions about markets?

That question determines:

* architecture
* layout
* analytics
* alerts
* workflows

---

# Teacher's Notes

> One of the most important lessons in financial software engineering is that users rarely want data. They want decisions. Professional financial systems therefore organize information around decision-making workflows rather than around databases or APIs.
>
> Another important lesson is that dashboards are software architecture problems as much as they are UI problems. Information hierarchy, latency, refresh frequency, alerting, and analytics all become architectural concerns.

---

# Common Mistakes

## ❌ Mistake 1

Building dashboards around APIs.

---

## ❌ Mistake 2

Displaying too much information.

---

## ❌ Mistake 3

Ignoring portfolio context.

---

## ❌ Mistake 4

Using charts without rankings.

---

## ❌ Mistake 5

Building dashboards without alerts.

---

# Summary

In this lesson, you learned:

* Professional market systems monitor many assets simultaneously.
* Watchlists organize market monitoring.
* Portfolios track owned assets.
* Alert systems automate monitoring.
* Comparison engines rank securities.
* Market breadth measures participation.
* Market intelligence summarizes markets.
* Dashboard architecture determines usability.
* Professional financial systems optimize decision-making.

We have now built a professional SGX market workstation architecture.

---

# Exercises

## Exercise 1 — Watchlist Design

Create a watchlist containing:

* DBS
* UOB
* OCBC
* Singtel
* Keppel

List the metrics you would display.

---

## Exercise 2 — Portfolio Calculation

Given:

| Symbol | Shares | Price |
| ------ | ------ | ----- |
| D05    | 100    | 41    |
| U11    | 200    | 30    |
| O39    | 500    | 15    |

Calculate:

* position values
* total portfolio value

---

## Exercise 3 — Alert Rules

Design alert rules for:

* RSI oversold
* price breakout
* high volatility
* unusual volume

---

# Coming Up Next

In **Lesson 5.15 — Deploying Panel Applications: Serving, Packaging, Authentication, Cloud Deployment, and Production Architecture**, we'll learn how to transform our SGX Market Workstation from a local development project into a production-ready application by exploring Panel servers, deployment architectures, authentication, Docker containers, reverse proxies, cloud hosting, scalability, monitoring, and operational concerns.
