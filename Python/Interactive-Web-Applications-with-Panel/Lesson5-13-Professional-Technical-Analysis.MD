# Part V — Working with Live SGX Market Data

# Lesson 5.13 — Professional Technical Analysis: EMA, RSI, MACD, Bollinger Bands, and Momentum Indicators

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what technical analysis is.
> * Learn why traders use technical indicators.
> * Implement Exponential Moving Averages (EMA).
> * Calculate Relative Strength Index (RSI).
> * Build MACD indicators.
> * Create Bollinger Bands.
> * Understand momentum indicators.
> * Visualize technical indicators using Panel.
> * Combine multiple indicators into trading dashboards.
> * Think like a market analyst rather than simply a software developer.

---

# Introduction

In the previous lesson, we introduced:

* returns
* moving averages
* volatility
* comparative performance

These indicators answer questions such as:

```text
How much did the stock move?

How risky is the stock?

What trend exists?
```

Professional traders ask more advanced questions:

```text
Is the stock overbought?

Is momentum increasing?

Is the trend accelerating?

Is volatility expanding?

Is a reversal likely?
```

To answer these questions, markets developed:

> Technical Indicators.

---

# What Is Technical Analysis?

Technical analysis is:

> The study of market behavior using mathematical transformations of price and volume data.

---

# Important Clarification

Technical analysis does NOT attempt to determine:

```text
What a company is worth.
```

Instead, it attempts to determine:

```text
What market participants are doing.
```

---

# Fundamental vs Technical Analysis

| Fundamental      | Technical       |
| ---------------- | --------------- |
| Revenue          | Price           |
| Profit           | Volume          |
| Cash Flow        | Momentum        |
| Valuation        | Trend           |
| Business Quality | Market Behavior |

---

# Why Technical Indicators Exist

Suppose we observe:

```text
40

41

42

43

44

45
```

Humans naturally see:

```text
Uptrend
```

Suppose we observe:

```text
40

42

39

44

38

46
```

Now the pattern becomes unclear.

Technical indicators help us identify patterns mathematically.

---

# Categories of Technical Indicators

Most indicators belong to one of four categories:

| Category   | Purpose       |
| ---------- | ------------- |
| Trend      | Direction     |
| Momentum   | Speed         |
| Volatility | Risk          |
| Volume     | Participation |

---

# Technical Indicator Architecture

```text
Historical Prices

↓

Mathematical Formula

↓

Indicator

↓

Signal

↓

Decision
```

---

# Our First Professional Indicator: EMA

Recall the simple moving average:

```text
SMA

=

Average Of Previous Prices
```

The problem?

Old prices receive the same weight as recent prices.

---

# Example

Suppose:

```text
40

40

40

40

60
```

The average:

```text
44
```

fails to reflect the recent price jump.

---

# Enter the Exponential Moving Average

EMA assigns:

```text
Recent Prices

↓

More Weight

Old Prices

↓

Less Weight
```

---

# Why Is EMA Popular?

Because markets care more about:

```text
Yesterday
```

than:

```text
Three Months Ago
```

---

# Visualizing SMA vs EMA

```text
Price

      /
     /
    /

SMA
    -----

EMA
      ----
```

EMA reacts faster.

---

# Calculating EMA With Pandas

Fortunately:

```python
import pandas as pd
```

already provides EMA support.

---

# Example

```python
df["ema20"] = (

    df["price"]

    .ewm(span=20)

    .mean()
)
```

---

# Understanding `.ewm()`

`ewm` means:

> Exponentially Weighted Moving

---

# Understanding `span`

```python
span=20
```

means:

```text
20 Trading Periods
```

---

# Why EMA Matters

Traders often compare:

```text
Short EMA

versus

Long EMA
```

---

# Example

```python
ema10

ema50
```

If:

```text
EMA10

>

EMA50
```

many traders interpret this as:

```text
Bullish Trend
```

---

# Visualizing EMA Crossovers

```text
EMA10

    /
   /

EMA50

---------
```

This event is called:

> A crossover.

---

# Introducing Momentum

Momentum answers:

> How quickly are prices changing?

---

# Example

Stock A:

```text
40
41
42
43
44
```

Stock B:

```text
40
45
50
55
60
```

Both rise.

But:

```text
Stock B
```

has stronger momentum.

---

# Relative Strength Index (RSI)

One of the world's most popular indicators is:

> RSI

---

# What Does RSI Measure?

RSI measures:

```text
Buying Pressure

versus

Selling Pressure
```

---

# RSI Scale

RSI ranges between:

```text
0

and

100
```

---

# Interpretation

| RSI    | Interpretation |
| ------ | -------------- |
| 0-30   | Oversold       |
| 30-70  | Neutral        |
| 70-100 | Overbought     |

---

# Visualizing RSI

```text
100 ─────────

70  ─ Overbought

50  ─ Neutral

30  ─ Oversold

0   ─────────
```

---

# Why RSI Matters

Suppose:

```text
RSI = 85
```

This suggests:

```text
Strong Buying Pressure
```

Some traders may expect:

```text
A Pullback
```

---

# Calculating RSI

The complete RSI formula is complex.

Fortunately, Pandas simplifies the process.

---

# Step 1 — Price Changes

```python
delta = (
    df["price"]
    .diff()
)
```

---

# Understanding `.diff()`

Example:

```text
40
42
45
44
```

becomes:

```text
+2
+3
-1
```

---

# Step 2 — Gains

```python
gain = delta.clip(
    lower=0
)
```

---

# Step 3 — Losses

```python
loss = (

    -delta.clip(
        upper=0
    )
)
```

---

# Step 4 — Average Gains

```python
avg_gain = (

    gain

    .rolling(14)

    .mean()
)
```

---

# Step 5 — Average Losses

```python
avg_loss = (

    loss

    .rolling(14)

    .mean()
)
```

---

# Step 6 — Relative Strength

```python
rs = (

    avg_gain

    /

    avg_loss
)
```

---

# Step 7 — Final RSI

```python
rsi = (

    100

    -

    (

        100

        /

        (1 + rs)
    )
)
```

---

# Visualizing RSI

```text
Price

      /
     /
    /

RSI

85
```

Potential warning signal.

---

# Introducing MACD

MACD stands for:

> Moving Average Convergence Divergence

---

# Why Is It Called MACD?

Because it measures:

```text
Distance

Between

Moving Averages
```

---

# MACD Formula

```text
EMA12

-

EMA26
```

---

# Example

```python
ema12 = (

    df["price"]

    .ewm(span=12)

    .mean()
)

ema26 = (

    df["price"]

    .ewm(span=26)

    .mean()
)

macd = ema12 - ema26
```

---

# What Does MACD Measure?

MACD measures:

```text
Trend Strength

+

Momentum
```

---

# Interpreting MACD

Positive:

```text
Bullish Momentum
```

Negative:

```text
Bearish Momentum
```

---

# Visualizing MACD

```text
 2 ──────

 1 ────

 0 ─────────

-1
```

Crossing zero is important.

---

# Introducing Bollinger Bands

Bollinger Bands measure:

> Price volatility.

---

# Components

A Bollinger Band contains:

```text
Upper Band

Middle Band

Lower Band
```

---

# Formula

Middle:

```text
Moving Average
```

Upper:

```text
MA + 2σ
```

Lower:

```text
MA - 2σ
```

---

# Visualizing Bollinger Bands

```text
Upper

────────

Price
   /\/\

Middle

────────

Lower

────────
```

---

# Why Bollinger Bands Matter

Narrow bands indicate:

```text
Low Volatility
```

Wide bands indicate:

```text
High Volatility
```

---

# Calculating Bollinger Bands

```python
mean = (

    df["price"]

    .rolling(20)

    .mean()
)

std = (

    df["price"]

    .rolling(20)

    .std()
)

upper = mean + 2*std

lower = mean - 2*std
```

---

# What Does "Band Expansion" Mean?

Suppose:

```text
Upper

          /

Lower

         /
```

The bands widen.

This indicates:

```text
Increasing Volatility
```

---

# Combining Indicators

Professional analysts rarely use:

```text
One Indicator
```

Instead:

```text
Price

+

EMA

+

RSI

+

MACD

+

Volatility
```

---

# Example Dashboard Layout

```text
Price Metrics

EMA Trend Chart

RSI Chart

MACD Chart

Volatility Chart
```

---

# Visualizing Multi-Indicator Analysis

```text
Price
────────

EMA
--------

RSI
====

MACD
++++
```

---

# Creating Indicator Tables

```python
analytics = pd.DataFrame({

    "Indicator": [

        "RSI",

        "MACD",

        "EMA20"
    ],

    "Value": [

        rsi,

        macd,

        ema20
    ]
})
```

---

# Displaying Using Panel

```python
table = pn.widgets.Tabulator(
    analytics
)
```

---

# Creating Technical Charts

Suppose we create:

```python
price_chart

rsi_chart

macd_chart
```

Our dashboard becomes:

```python
dashboard = pn.Column(

    price_chart,

    rsi_chart,

    macd_chart
)
```

---

# Understanding Multi-Panel Charts

Professional trading terminals separate indicators.

Example:

```text
Price Chart

────────────

RSI

────────────

MACD
```

This improves readability.

---

# Building Trading Signals

Suppose:

```text
EMA20 > EMA50

AND

RSI < 70

AND

MACD > 0
```

We might generate:

```text
Bullish Signal
```

---

# Visualizing Signal Generation

```text
Indicators

↓

Rules

↓

Signal

↓

Dashboard Alert
```

---

# Important Warning

Technical indicators:

```text
DO NOT

Predict The Future
```

They only summarize:

```text
Past Market Behavior
```

---

# Thinking Like a Market Analyst

Beginners ask:

> "What indicator should I use?"

Professionals ask:

> "What market behavior am I trying to measure?"

Examples:

| Question        | Indicator       |
| --------------- | --------------- |
| Trend?          | EMA             |
| Momentum?       | RSI             |
| Trend strength? | MACD            |
| Volatility?     | Bollinger Bands |

---

# Our Technical Analytics Architecture

```text
Historical Data

↓

Pandas

↓

Technical Indicators

↓

Trading Signals

↓

Panel Dashboard
```

---

# Teacher's Notes

> One of the biggest misconceptions among beginners is that technical indicators are prediction machines. They are not. Technical indicators are statistical summaries of market behavior. Their value lies in helping humans recognize patterns that would otherwise be difficult to observe.
>
> Another important lesson is that most professional market analysis uses multiple indicators simultaneously because no single indicator adequately describes market behavior.

---

# Common Mistakes

## ❌ Mistake 1

Using only one indicator.

---

## ❌ Mistake 2

Treating RSI as a buy/sell signal.

---

## ❌ Mistake 3

Assuming EMA predicts prices.

---

## ❌ Mistake 4

Ignoring volatility.

---

## ❌ Mistake 5

Believing technical indicators guarantee profits.

---

# Summary

In this lesson, you learned:

* Technical indicators transform prices into signals.
* EMA reacts faster than SMA.
* RSI measures momentum.
* MACD measures trend strength.
* Bollinger Bands measure volatility.
* Professional analysis combines multiple indicators.
* Technical indicators summarize market behavior.
* Panel can visualize complex analytics.
* Financial dashboards integrate many indicators simultaneously.

Our SGX dashboard now supports professional technical analysis. The next step is building portfolio management, watchlists, alerting systems, and multi-stock comparative analytics to transform our dashboard into a complete market monitoring platform.

---

# Exercises

## Exercise 1 — Indicator Classification

Classify the following:

| Indicator       | Category |
| --------------- | -------- |
| EMA             | ?        |
| RSI             | ?        |
| MACD            | ?        |
| Bollinger Bands | ?        |

---

## Exercise 2 — RSI Interpretation

Interpret:

```text
RSI = 20

RSI = 50

RSI = 85
```

---

## Exercise 3 — Multi-Indicator Analysis

Suppose:

```text
EMA20 > EMA50

RSI = 65

MACD > 0
```

Describe what this combination suggests.

---

# Coming Up Next

In **Lesson 5.14 — Building Professional Market Workstations: Watchlists, Portfolios, Alerts, Multi-Stock Comparison, and Market Intelligence Dashboards**, we'll combine everything we've learned to build a Bloomberg-style SGX market workstation using Panel, complete with watchlists, portfolio tracking, alerts, ranking engines, sector comparisons, market breadth indicators, and professional dashboard layouts.
