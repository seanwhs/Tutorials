# Building TickerHub

## Part 36: Building the Quantitative Research, Factor Modeling & Portfolio Construction Platform — Teaching TickerHub Why Markets Move

> Amateur traders ask:
>
> ```text
> Which stock should I buy?
> ```
>
> Professional traders ask:
>
> ```text
> Which risks am I buying?
> ```
>
> because:
>
> ```text
> Assets do not generate returns.
>
> Risk factors generate returns.
> ```

At this point, TickerHub can:

* process markets,
* store history,
* replay events,
* simulate trading,
* backtest strategies,
* analyze performance.

However, professional trading systems do not stop at:

```text id="a1"
Did this strategy make money?
```

They ask:

```text id="a2"
Why did it make money?
```

and:

```text id="a3"
Will it continue to make money?
```

---

# The Beginner View of Investing

Most beginners think:

```text id="a4"
Buy Good Stocks
```

---

Professionals think:

```text id="a5"
Acquire
Desired Risk Exposure
```

---

Example:

Suppose:

```text id="a6"
Technology stocks rise
```

Question:

```text id="a7"
Was it:

The company?

The sector?

The economy?

Momentum?

Interest rates?

Luck?
```

---

# Quantitative Research Architecture

```text
Historical Data
        |
        V

Feature Engine
        |
        V

Factor Engine
        |
        V

Signal Engine
        |
        V

Portfolio Optimizer
        |
        V

Risk Attribution
        |
        V

Execution
```

---

# What Is A Factor?

A factor is:

```text id="a8"
A systematic source
of returns
```

---

Examples:

```text id="a9"
Market

Value

Momentum

Size

Quality

Volatility

Carry
```

---

# Example

Suppose:

```text id="a10"
DBS returns:
10%
```

Question:

```text id="a11"
Why?
```

---

Possible answer:

```text id="a12"
6%
Market

2%
Financial Sector

1%
Momentum

1%
Alpha
```

---

# Factor Models

Professional finance often uses:

```text id="a13"
CAPM
```

---

Then:

```text id="a14"
Fama-French
```

---

Then:

```text id="a15"
Multi-Factor Models
```

---

# Capital Asset Pricing Model

Formula:

```text
Return

=

Risk Free

+

Beta
×
Market Premium
```

---

Question:

```text id="a16"
How sensitive
is an asset
to the market?
```

---

# Example

Market:

```text
+10%
```

---

Asset:

```text
+15%
```

---

Beta:

```text
1.5
```

---

Interpretation:

```text id="a17"
More Risk
```

---

# Feature Engineering

Create:

```text
services/

    feature_engine.py
```

---

Generate:

```text id="a18"
Returns
```

---

Generate:

```text id="a19"
Volatility
```

---

Generate:

```text id="a20"
Momentum
```

---

Generate:

```text id="a21"
Volume
```

---

Generate:

```text id="a22"
Spread
```

---

# Example Features

```python
features = {

    "return_1d": ...,

    "return_5d": ...,

    "volatility": ...,

    "momentum": ...
}
```

---

# Momentum Factor

Formula:

```text
Price Today

/

Price N Days Ago
```

---

Example:

```text
+22%
```

---

Question:

```text id="a23"
Is the trend
persistent?
```

---

# Value Factor

Formula:

```text
Price

/

Book Value
```

---

Question:

```text id="a24"
Is the asset cheap?
```

---

# Size Factor

Formula:

```text
Market Cap
```

---

Question:

```text id="a25"
Large or small?
```

---

# Quality Factor

Examples:

```text
ROE

ROA

Margins

Debt
```

---

Question:

```text id="a26"
Is the company good?
```

---

# Volatility Factor

Formula:

```text
StdDev(Returns)
```

---

Question:

```text id="a27"
How dangerous
is the asset?
```

---

# Signal Engine

Create:

```text
services/

    signal_engine.py
```

---

Combine:

```text
Momentum

+

Value

+

Quality
```

---

Produce:

```text
Signal Score
```

---

Example:

```python
score = (

    momentum * 0.4 +

    value * 0.3 +

    quality * 0.3
)
```

---

# Ranking

Sort:

```text
Entire Universe
```

---

Example:

```text
DBS:
92

UOB:
88

OCBC:
81
```

---

Question:

```text id="a28"
What should we buy?
```

---

# Portfolio Construction

Question:

```text id="a29"
How much
should we buy?
```

---

This is much harder than:

```text
What should we buy?
```

---

# Equal Weight

Example:

```text
25%

25%

25%

25%
```

---

Simple.

---

Usually bad.

---

# Market Weight

Example:

```text
Large companies
receive
more capital.
```

---

# Risk Parity

Goal:

```text
Equal Risk
Contribution
```

---

Example:

```text
Volatile asset:
small weight

Stable asset:
large weight
```

---

# Mean Variance Optimization

Invented by:

Harry Markowitz

---

Goal:

```text
Maximum Return

for

Minimum Risk
```

---

Optimization:

```text
maximize:

Return

-

λ Risk
```

---

# Efficient Frontier

Question:

```text id="a30"
What portfolios
are optimal?
```

---

Example:

```text
Return
      *
    *
  *
*
------------ Risk
```

---

# Constraints

Real portfolios have:

```text
Maximum Position

Minimum Position

Sector Limits

Country Limits

Liquidity Limits
```

---

# Example Constraint

```text
No stock

>

10%
```

---

# Portfolio Optimizer

Create:

```text
services/

    optimizer.py
```

---

Input:

```text
Expected Returns
```

---

Input:

```text
Covariance Matrix
```

---

Input:

```text
Constraints
```

---

Output:

```text
Portfolio Weights
```

---

# Covariance Matrix

Question:

```text id="a31"
How do assets
move together?
```

---

Example:

```text
DBS/UOB:
0.85

DBS/SIA:
0.21
```

---

# Diversification

Question:

```text id="a32"
Can risk disappear?
```

---

Answer:

```text
Partially
```

---

Because:

```text
Correlation
matters
more than
asset count
```

---

# Risk Attribution

Question:

```text id="a33"
Where does risk
come from?
```

---

Example:

```text
Market:
60%

Sector:
20%

Currency:
10%

Specific:
10%
```

---

# Return Attribution

Question:

```text id="a34"
Where did profits
come from?
```

---

Example:

```text
Momentum:
40%

Value:
30%

Selection:
30%
```

---

# Factor Exposure

Portfolio:

```text
Tech:
0.7
```

---

Market:

```text
1.2
```

---

Momentum:

```text
0.5
```

---

Question:

```text id="a35"
What risks
are we carrying?
```

---

# Scenario Testing

Suppose:

```text
Interest rates:
+2%
```

---

Question:

```text
Portfolio effect?
```

---

Suppose:

```text
Oil:
-40%
```

---

Question:

```text
Portfolio effect?
```

---

# Stress Testing

Replay:

```text
1987
```

---

Replay:

```text
2008
```

---

Replay:

```text
2020
```

---

Question:

```text id="a36"
Will the portfolio survive?
```

---

# Black-Litterman

Question:

```text id="a37"
Can human opinions
be combined
with statistics?
```

---

Answer:

```text
Yes
```

---

Combine:

```text
Market Equilibrium

+

Human Views
```

---

Generate:

```text
Optimal Allocation
```

---

# Portfolio Dashboard

Display:

```text
Weights
```

---

Display:

```text
Risk
```

---

Display:

```text
Returns
```

---

Display:

```text
Factor Exposure
```

---

Display:

```text
Efficient Frontier
```

---

# Research Database

Store:

```text
Features
```

---

Store:

```text
Factors
```

---

Store:

```text
Signals
```

---

Store:

```text
Optimizations
```

---

Store:

```text
Experiments
```

---

# Research Workflow

```text
Historical Data
        |
        V

Features
        |
        V

Factors
        |
        V

Signals
        |
        V

Portfolio
        |
        V

Risk
        |
        V

Backtest
```

---

# Why Quantitative Research Matters

Because markets are not:

```text
Collections of Stocks
```

They are:

```text
Collections of Risks
```

---

Professional systems ask:

```text
Which risks
do we want
to own?
```

---

# Architecture Lesson #36

Beginners think:

```text
Portfolio
    =
List of Stocks
```

Professionals think:

```text
Portfolio
    =
A constrained
optimization problem
over
risk,
return,
correlation,
and uncertainty
```

---

# Current Architecture

```text
Historical Data
        |
        V

Feature Engine
        |
        V

Factor Engine
        |
        V

Signal Engine
        |
        V

Portfolio Optimizer
        |
        V

Risk Attribution
        |
        V

Execution
```

TickerHub now contains:

✅ Feature engineering

✅ Factor models

✅ Signal generation

✅ Asset ranking

✅ Portfolio optimization

✅ Efficient frontiers

✅ Risk attribution

✅ Return attribution

✅ Factor exposure analysis

✅ Stress testing

✅ Scenario analysis

✅ Black-Litterman optimization

At this point, TickerHub no longer resembles a trading terminal.

It resembles:

```text
A Quantitative Research Laboratory
capable of discovering,
measuring,
optimizing,
and allocating
financial risk
across entire markets.
```

---

# In Part 37

We will build the **Machine Learning, Forecasting & Alpha Discovery Platform**, where you'll discover that professional trading systems are not merely designed to ask:

```text
Why did markets move?
```

but:

```text
What will markets
probably do next,
and how confident
are we
that we're wrong?
```
