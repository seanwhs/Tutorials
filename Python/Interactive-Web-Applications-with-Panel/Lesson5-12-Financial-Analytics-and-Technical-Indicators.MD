# Part V — Working with Live SGX Market Data

# Lesson 5.12 — Financial Analytics and Technical Indicators: Moving Averages, Volatility, Returns, and Market Metrics

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what financial analytics is.
> * Learn why raw prices alone are insufficient.
> * Calculate stock returns.
> * Compute percentage changes.
> * Implement moving averages.
> * Understand rolling windows.
> * Calculate volatility.
> * Measure stock performance.
> * Compare multiple SGX stocks.
> * Visualize financial indicators using Panel.
> * Think like a financial analyst rather than simply a dashboard developer.

---

# Introduction

Our SGX dashboard currently shows:

```text
DBS (D05)

Price:

$41.35
```

This tells us something.

But not much.

Suppose someone asks:

> Is DBS performing well?

Can we answer?

No.

Why?

Because:

> A price without context is meaningless.

---

# The Problem With Raw Prices

Suppose we observe:

| Stock | Price |
| ----- | ----- |
| DBS   | 41.35 |
| OCBC  | 15.40 |
| UOB   | 30.15 |

Which stock is performing better?

We cannot know.

Price alone does not measure performance.

---

# Real Financial Questions

Investors ask questions such as:

* Is the stock trending upward?
* Is the stock volatile?
* Is today's move unusual?
* Is the stock outperforming competitors?
* Is momentum increasing?
* Is the trend weakening?

These questions require:

> Financial analytics.

---

# What Is Financial Analytics?

Financial analytics means:

> Transforming raw market data into useful information.

---

# Visualizing Financial Analytics

```text
Raw Prices

↓

Calculations

↓

Indicators

↓

Insights

↓

Decisions
```

---

# Categories of Financial Analytics

Most financial indicators fall into several categories:

| Category             | Purpose             |
| -------------------- | ------------------- |
| Returns              | Measure performance |
| Trend                | Measure direction   |
| Volatility           | Measure risk        |
| Momentum             | Measure speed       |
| Relative Performance | Compare assets      |
| Technical Indicators | Predict behavior    |

---

# Our First Metric: Returns

Suppose DBS moves:

```text
Yesterday:

40.00

Today:

41.35
```

The return equals:

```text
Profit

÷

Original Investment
```

---

# Absolute Return

Formula:

```text
Return

=

Current Price

−

Previous Price
```

---

# Example

```text
41.35

−

40.00

=

1.35
```

DBS gained:

```text
$1.35
```

---

# Why Absolute Return Is Not Enough

Compare:

| Stock       | Gain  |
| ----------- | ----- |
| DBS         | +1.35 |
| Penny Stock | +1.35 |

The gains are identical.

But their importance differs.

---

# Percentage Return

Financial markets prefer:

> Percentage returns.

Formula:

```text
(Current − Previous)

÷

Previous

×

100
```

---

# Example

```text
(41.35 − 40)

÷

40

×

100
```

Result:

```text
3.375%
```

---

# Implementing Percentage Returns

```python
def calculate_return(
    previous,
    current
):

    return (
        current - previous
    ) / previous * 100
```

---

# Testing the Function

```python
calculate_return(
    40,
    41.35
)
```

Produces:

```text
3.375
```

---

# Why Create Functions?

Bad:

```python
result = (
    current - previous
) / previous * 100
```

repeated everywhere.

Good:

```python
calculate_return()
```

Functions provide:

* reusability
* readability
* maintainability

---

# Understanding Historical Data

Financial analytics requires:

```text
Many Prices

Not

One Price
```

Example:

| Date      | Price |
| --------- | ----- |
| Monday    | 40    |
| Tuesday   | 41    |
| Wednesday | 42    |
| Thursday  | 41    |
| Friday    | 43    |

---

# Loading Historical Data

Suppose our provider returns:

```python
history = (
    market_service
    .get_history("D05")
)
```

Result:

```python
[
    40,
    41,
    42,
    41,
    43
]
```

---

# Introducing Pandas

Financial analysis is largely built around:

```python
import pandas as pd
```

---

# What Is Pandas?

Pandas provides:

> Structured data manipulation.

Think of it as:

```text
Excel

+

SQL

+

Python
```

---

# Creating a DataFrame

Example:

```python
import pandas as pd

df = pd.DataFrame({

    "price":

    [40,41,42,41,43]
})
```

---

# Visual Result

```text
   price

0     40
1     41
2     42
3     41
4     43
```

---

# Why DataFrames Matter

Nearly every financial calculation operates on:

```text
Rows

+

Columns
```

---

# Introducing Moving Averages

A moving average answers:

> What is the average price over recent periods?

---

# Example

Suppose prices are:

```text
40

41

42
```

Average:

```text
41
```

---

# What Makes It "Moving"?

Suppose we move forward:

```text
41

42

43
```

New average:

```text
42
```

The calculation window moves.

---

# Visualizing Moving Windows

```text
40 41 42 41 43

^^^^

↓

   ^^^^

↓

      ^^^^
```

---

# Why Moving Averages Matter

They smooth:

* noise
* fluctuations
* short-term randomness

allowing us to see:

> Trends.

---

# Creating Moving Averages

Pandas provides:

```python
df["ma3"] = (

    df["price"]

    .rolling(3)

    .mean()
)
```

---

# Understanding `.rolling()`

This creates:

```text
A Moving Window
```

Example:

```python
rolling(3)
```

means:

```text
Look At

Three Observations
```

---

# Understanding `.mean()`

`.mean()` computes:

```text
Average Value
```

---

# Result

| Price | MA3   |
| ----- | ----- |
| 40    | NaN   |
| 41    | NaN   |
| 42    | 41    |
| 41    | 41.33 |
| 43    | 42    |

---

# Why Are There Missing Values?

The first rows lack enough data.

Example:

```text
40

?

Need 3 Values
```

This produces:

```text
NaN
```

meaning:

> Not A Number.

---

# Short-Term vs Long-Term Averages

Financial analysts often compare:

| Indicator | Period  |
| --------- | ------- |
| Short     | 5 days  |
| Medium    | 20 days |
| Long      | 50 days |

---

# Example

```python
df["ma5"] = (
    df["price"]
    .rolling(5)
    .mean()
)

df["ma20"] = (
    df["price"]
    .rolling(20)
    .mean()
)
```

---

# Why Compare Moving Averages?

Suppose:

```text
MA5

>

MA20
```

This often suggests:

```text
Uptrend
```

---

# Visualizing Trend Detection

```text
Price

      /
     /
----/
```

versus:

```text
Price

\
 \
  \____
```

---

# Understanding Volatility

Volatility measures:

> How much prices move.

---

# Example

Stock A:

```text
40
40
40
40
40
```

Stock B:

```text
20
60
15
70
10
```

---

# Which Is More Risky?

Obviously:

```text
Stock B
```

because prices fluctuate more.

---

# Measuring Volatility

Volatility is usually measured using:

```text
Standard Deviation
```

---

# What Is Standard Deviation?

It measures:

> Distance from the average.

---

# Visual Example

```text
Average

↓

50

45 48 50 52 55
```

Small spread:

```text
Low Volatility
```

versus:

```text
10 40 50 80 95
```

Large spread:

```text
High Volatility
```

---

# Calculating Volatility

Pandas provides:

```python
volatility = (

    df["price"]

    .std()
)
```

---

# Rolling Volatility

Markets change.

Therefore:

```python
df["volatility"] = (

    df["price"]

    .rolling(20)

    .std()
)
```

---

# Why Rolling Volatility?

This measures:

```text
Current Risk

Not

Historical Risk
```

---

# Measuring Performance

Suppose DBS moves:

```text
40

↓

44
```

while UOB moves:

```text
30

↓

31
```

Which performed better?

---

# Percentage Comparison

```text
DBS

=

10%

UOB

=

3.3%
```

DBS outperformed.

---

# Creating Comparative Returns

```python
dbs_return = calculate_return(
    40,
    44
)

uob_return = calculate_return(
    30,
    31
)
```

---

# Building Relative Performance Tables

| Stock | Return |
| ----- | ------ |
| DBS   | 10.0%  |
| UOB   | 3.3%   |
| OCBC  | 5.2%   |

---

# Visualizing Performance

Charts make comparisons easier.

```text
DBS   ██████████

OCBC  █████

UOB   ███
```

---

# Understanding Technical Indicators

Technical indicators are:

> Mathematical transformations of prices.

Examples:

| Indicator       | Purpose        |
| --------------- | -------------- |
| SMA             | Trend          |
| EMA             | Trend          |
| RSI             | Momentum       |
| MACD            | Trend strength |
| Bollinger Bands | Volatility     |

---

# Why Technical Indicators Exist

Humans struggle to identify patterns manually.

Indicators automate pattern detection.

---

# Displaying Analytics in Panel

Suppose we calculate:

```python
price

ma20

volatility

returns
```

We can create:

```python
metrics = pn.Row(

    price_card,

    return_card,

    volatility_card
)
```

---

# Creating Analytics Tables

```python
analytics = pd.DataFrame({

    "Metric": [

        "Price",

        "Return",

        "Volatility"
    ],

    "Value": [

        price,

        returns,

        volatility
    ]
})
```

---

# Displaying Results

```python
table = pn.widgets.Tabulator(
    analytics
)
```

---

# Creating Moving Average Charts

Suppose:

```python
df
```

contains:

```text
Price

MA20

MA50
```

Our chart becomes:

```text
Price

MA20

MA50
```

displayed simultaneously.

---

# Visualizing Trend Analysis

```text
Price     ──────

MA20      -----

MA50      _____
```

This reveals market structure immediately.

---

# Our Financial Analytics Architecture

```text
Historical Data

↓

Pandas

↓

Analytics

↓

Indicators

↓

Panel Dashboard
```

---

# Thinking Like a Financial Analyst

Beginners ask:

> "What is the stock price?"

Analysts ask:

> "What does the stock price mean?"

That question creates:

* returns
* volatility
* trends
* momentum
* technical indicators

Financial analytics transforms:

```text
Data

↓

Meaning
```

---

# Teacher's Notes

> One of the most important lessons in financial analytics is that raw market prices contain very little useful information. Almost all professional financial analysis involves transforming prices into derived metrics that reveal trends, risk, momentum, and relative performance.
>
> Another important lesson is that Pandas functions such as `.rolling()`, `.mean()`, and `.std()` are not merely programming tools. They represent decades of statistical and financial modeling practice embedded within software libraries.

---

# Common Mistakes

## ❌ Mistake 1

Comparing stock prices directly.

---

## ❌ Mistake 2

Using absolute returns instead of percentages.

---

## ❌ Mistake 3

Ignoring volatility.

---

## ❌ Mistake 4

Calculating averages without rolling windows.

---

## ❌ Mistake 5

Assuming trends can be identified visually without indicators.

---

# Summary

In this lesson, you learned:

* Raw prices provide limited information.
* Returns measure performance.
* Percentage returns enable comparisons.
* Moving averages identify trends.
* Rolling windows create dynamic indicators.
* Volatility measures risk.
* Relative performance compares assets.
* Technical indicators transform prices into insights.
* Financial analytics converts market data into decision-making information.

Our SGX dashboard can now perform financial analysis. The next step is implementing professional technical indicators such as RSI, EMA, MACD, and Bollinger Bands to build a true financial analytics platform.

---

# Exercises

## Exercise 1 — Calculate Returns

Calculate the percentage returns for:

| Previous | Current |
| -------- | ------- |
| 40       | 44      |
| 15       | 18      |
| 30       | 27      |

---

## Exercise 2 — Moving Average

Calculate the 3-day moving average manually:

```text
20
22
24
26
28
```

---

## Exercise 3 — Volatility

Determine which stock is more volatile:

```text
Stock A

40
41
42
41
40
```

or:

```text
Stock B

20
60
15
80
10
```

Explain your reasoning.

---

# Coming Up Next

In **Lesson 5.13 — Professional Technical Analysis: EMA, RSI, MACD, Bollinger Bands, and Momentum Indicators**, we'll implement the technical indicators used by traders and financial analysts worldwide, learn the mathematical intuition behind them, visualize them in Panel dashboards, and transform our SGX monitoring application into a professional-grade market analysis platform.
