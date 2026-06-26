# Building TickerHub

## Part 27: Building the Risk Management Engine — Estimating the Future Distribution of Financial Pain

> Traders ask:
>
> **"How much money can I make?"**
>
> Risk managers ask:
>
> **"How much money can I lose?"**

At this point, TickerHub can:

* acquire market data,
* execute trades,
* maintain portfolios,
* calculate PnL,
* manage exposure.

But professional financial systems are not designed primarily to maximize profits.

They are designed to:

```text
Prevent Catastrophic Loss
```

This is why every professional trading system contains a dedicated:

```text
Risk Management Engine
```

because a portfolio is not merely a collection of assets.

It is:

```text
A Distribution of Possible Future Outcomes
```

---

# The Beginner View of Risk

Most tutorials implement risk like this:

```python
risk = portfolio.value * 0.03
```

Or:

```python
if position > limit:
    reject()
```

This works.

Until:

* multiple asset classes,
* correlated positions,
* leverage,
* derivatives,
* stressed markets,
* liquidity shocks,
* volatility spikes.

Then:

```text
Risk Checking
```

becomes:

```text
Risk Modeling
```

---

# Professional Risk Architecture

Professional systems separate:

```text
Realized Risk

from

Potential Risk
```

---

# Realized Risk

Questions:

```text
How much did we lose?
```

Examples:

* realized PnL,
* drawdown,
* exposure,
* concentration.

---

# Potential Risk

Questions:

```text
How much could we lose?
```

Examples:

* VaR,
* CVaR,
* stress tests,
* scenarios,
* simulations.

---

# Risk Architecture

```text
Portfolio
      |
      V

Risk Engine
      |
      +------ Exposure
      |
      +------ VaR
      |
      +------ CVaR
      |
      +------ Stress
      |
      +------ Limits
      |
      +------ Alerts
```

---

# Why Separate Risk?

Because:

```text
Trading
```

must remain:

```text
Fast
```

while:

```text
Risk
```

can be:

```text
Computationally Expensive
```

---

# Create Risk Domain

Create:

```text
domain/

    risk_metrics.py
```

---

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class RiskMetrics:

    exposure: float

    var: float

    cvar: float

    volatility: float

    drawdown: float
```

---

# Exposure

The simplest risk metric.

---

Formula:

```text
Position Size
    ×
Market Price
```

---

Example:

```text
1000 shares

×

$42
```

equals:

```text
$42,000
```

---

# Portfolio Exposure

Example:

```text
DBS      50k
UOB      30k
SIA      20k
```

---

Total:

```text
100k
```

---

# Gross Exposure

Formula:

```text
SUM(
    ABS(position)
)
```

---

Example:

```text
+100k

-50k

+30k
```

---

Gross:

```text
180k
```

---

# Net Exposure

Formula:

```text
Long

-

Short
```

---

Example:

```text
130k

-

50k
```

equals:

```text
80k
```

---

# Concentration Risk

Question:

```text
How much depends
on one position?
```

---

Example:

```text
Portfolio:

100k
```

---

DBS:

```text
70k
```

---

Concentration:

```text
70%
```

---

Raise:

```text
Concentration Alert
```

---

# Sector Exposure

Example:

```text
Banking:
60%

Technology:
30%

Healthcare:
10%
```

---

Limit:

```text
Banking <= 40%
```

---

Violation:

```text
Risk Event
```

---

# Value at Risk (VaR)

Professional systems ask:

```text
What is the maximum loss
expected under normal conditions?
```

---

Example:

```text
95% VaR

=

$50,000
```

Meaning:

```text
95% of the time

losses should be less than

$50,000
```

---

# Historical VaR

Suppose:

```text
1000
historical returns
```

exist.

---

Sort:

```text
Worst

↓

Best
```

---

Take:

```text
5th percentile
```

---

Example:

```python
returns.sort()

var = returns[50]
```

---

# Example Distribution

```text
-10%

-9%

-8%

...

+7%

+8%
```

---

VaR:

```text
-6%
```

---

# Portfolio VaR

Formula:

```text
Portfolio Value

×

VaR %
```

---

Example:

```text
$1M

×

5%
```

equals:

```text
$50,000
```

---

# Conditional VaR (CVaR)

Question:

```text
What if things become worse
than VaR?
```

---

Example:

```text
Worst
5%
```

average:

```text
$80,000
```

---

Then:

```text
CVaR = $80,000
```

---

# Why CVaR?

Because:

```text
VaR
```

ignores:

```text
Catastrophic Events
```

---

# Volatility

Formula:

```text
Standard Deviation
of Returns
```

---

Example:

```text
Daily Returns:

1%

-2%

3%

-1%
```

---

Compute:

```python
np.std(
    returns
)
```

---

Result:

```text
Volatility
```

---

# Annualized Volatility

Formula:

```text
Daily Vol

×

sqrt(252)
```

---

Example:

```text
1%

×

15.87
```

---

Result:

```text
15.9%
```

---

# Drawdown

Question:

```text
How far have we fallen
from our peak?
```

---

Example:

```text
Peak:
120k
```

---

Current:

```text
90k
```

---

Drawdown:

```text
25%
```

---

# Maximum Drawdown

Compute:

```text
Largest historical loss
from a peak
```

---

Example:

```text
Peak:

200k
```

---

Trough:

```text
100k
```

---

Maximum drawdown:

```text
50%
```

---

# Beta

Question:

```text
How sensitive are we
to the market?
```

---

Example:

```text
Beta:

1.5
```

means:

```text
Market +10%

↓

Portfolio +15%
```

---

# Stress Testing

Professional systems ask:

```text
What if disaster occurs?
```

---

Scenario:

```text
Market Crash:
-20%
```

---

Recompute:

```text
Portfolio Value
```

---

Example:

```text
Before:
100k
```

---

After:

```text
75k
```

---

Loss:

```text
25k
```

---

# Historical Scenarios

Examples:

```text
2008

COVID

Dot-com

Flash Crash
```

---

Store:

```text
scenarios/
```

---

Example:

```json
{
    "DBS":-15,
    "UOB":-20
}
```

---

# Monte Carlo Simulation

Professional systems generate:

```text
Thousands of Futures
```

---

Example:

```text
Portfolio
```

---

Simulate:

```text
10,000
possible outcomes
```

---

Result:

```text
Probability Distribution
```

---

Example:

```python
for i in range(
    10000
):
```

---

Generate:

```text
Random Market Path
```

---

Compute:

```text
Portfolio Value
```

---

Store:

```text
Distribution
```

---

# Liquidity Risk

Question:

```text
Can we sell?
```

---

Example:

```text
Position:
$10M
```

---

Daily Volume:

```text
$500K
```

---

Risk:

```text
High
```

---

# Counterparty Risk

Question:

```text
Who owes us money?
```

---

Example:

```text
Broker A:
5M

Broker B:
2M
```

---

# Leverage Risk

Formula:

```text
Assets

/

Equity
```

---

Example:

```text
500k

/

100k
```

equals:

```text
5x
```

---

# Margin Risk

Compute:

```text
Maintenance Margin
```

---

Example:

```text
Required:
20%
```

---

Current:

```text
15%
```

---

Result:

```text
Margin Call
```

---

# Risk Limits

Examples:

```text
Max Position

Max Exposure

Max Drawdown

Max Leverage

Max Sector Weight
```

---

# Risk Engine

Create:

```text
services/

    risk_service.py
```

---

Initialize:

```python
class RiskService:

    def __init__(
        self,
        portfolio
    ):
```

---

Calculate:

```python
async def calculate_var(
    self,
    portfolio
):
```

---

Calculate:

```python
async def calculate_cvar(
    self,
    portfolio
):
```

---

Calculate:

```python
async def stress_test(
    self,
    scenario
):
```

---

# Why Async?

Because:

```text
Monte Carlo
```

may require:

```text
Millions
of calculations
```

---

Architecture:

```text
Panel
     |
     V

Risk Request
     |
     V

Redis Queue
     |
     V

Risk Worker Pool
```

---

# Risk Worker

Create:

```text
workers/

    risk_worker.py
```

---

Receive:

```text
Portfolio
```

---

Compute:

```text
VaR

CVaR

Stress

Scenarios
```

---

Store:

```text
Redis
```

---

Persist:

```text
PostgreSQL
```

---

# Risk Alerts

Examples:

```text
VaR exceeded

Drawdown exceeded

Concentration exceeded

Margin call

Exposure exceeded
```

---

Publish:

```text
RiskAlert
```

events.

---

# Risk Dashboard

Display:

```text
Portfolio Value

VaR

CVaR

Exposure

Volatility

Drawdown
```

---

Example:

```text
Value:
1.2M

VaR:
50k

CVaR:
75k

Vol:
18%

DD:
12%
```

---

# Recovery

Suppose:

```text
Risk Service
```

crashes.

---

Recover:

```text
Portfolio Snapshot
       |
       V

Historical Returns
       |
       V

Risk Recalculation
```

---

# The Real Risk Architecture

```text
Risk Engine
      |
      +------ Exposure
      |
      +------ VaR
      |
      +------ CVaR
      |
      +------ Volatility
      |
      +------ Drawdown
      |
      +------ Stress
      |
      +------ Monte Carlo
      |
      +------ Liquidity
      |
      +------ Margin
      |
      +------ Alerts
```

---

# Why Professional Risk Systems Exist

Because markets do not fail by:

```text
Making small mistakes.
```

Markets fail by:

```text
Experiencing rare,
extreme,
and correlated events.
```

Professional systems exist to estimate:

```text
The Future Distribution
of Pain.
```

---

# Architecture Lesson #27

Beginners think:

```text
Risk
    =
Rules
```

Professionals think:

```text
Risk
    =
Predictive Simulation
under uncertainty
```

The limits are merely one output of the simulation.

---

# Current Architecture

```text
Market Feed
      |
      V

OMS
      |
      V

Portfolio Engine
      |
      V

Risk Engine
      |
      +------ VaR
      |
      +------ CVaR
      |
      +------ Stress
      |
      +------ Monte Carlo
      |
      +------ Exposure
      |
      +------ Margin
      |
      V

Redis
      |
      V

PostgreSQL
      |
      V

Panel UI
```

TickerHub now contains:

✅ Exposure analysis

✅ Concentration risk

✅ Sector risk

✅ VaR

✅ CVaR

✅ Volatility

✅ Drawdown analysis

✅ Stress testing

✅ Monte Carlo simulation

✅ Liquidity risk

✅ Margin risk

✅ Risk alerts

At this point, TickerHub no longer resembles a portfolio application or a trading system.

It resembles:

```text
A Predictive Financial Simulation Engine
designed to estimate
the probability distribution
of future economic outcomes.
```

---

# In Part 28

We will build the **Panel State Management & Reactive UI Layer**, where you'll discover that professional trading UIs are not:

```text
Collections of widgets
```

but rather:

```text
Distributed visualizations
of continuously evolving
system state.
```
