# Building TickerHub

## Part 38: Building the Real-Time Execution Management System (EMS) & Smart Order Routing Platform — Executing Without Revealing Intent

> In retail trading, execution is often treated as:
>
> ```text
> Click Buy
>
> Receive Shares
> ```
>
> In professional trading, execution is treated as:
>
> ```text
> Adversarial Optimization
> ```
>
> because:
>
> ```text
> The market is watching you
> while you trade.
> ```

At this point, TickerHub can:

* analyze markets,
* construct portfolios,
* generate alpha,
* forecast probabilities,
* simulate strategies,
* estimate risk.

Unfortunately, none of that matters if:

```text id="ems1"
You cannot execute.
```

In professional trading:

```text id="ems2"
Execution
```

is often more important than:

```text id="ems3"
Prediction.
```

---

# The Beginner Execution Model

Most tutorials execute:

```python
broker.buy(
    "D05",
    100
)
```

Then:

```text
Position Updated
```

---

Real markets work like:

```text
Order
        |
        V

Validation
        |
        V

Risk Check
        |
        V

Routing
        |
        V

Exchange
        |
        V

Partial Fill
        |
        V

Settlement
```

---

# Why Execution Is Hard

Suppose your model predicts:

```text
BUY

10 million shares
```

Question:

```text id="ems4"
How do you buy
without moving
the market?
```

---

Answer:

```text id="ems5"
Very carefully.
```

---

# Professional Execution Architecture

```text
Portfolio
        |
        V

Order Generator
        |
        V

Execution Management System
        |
        V

Smart Order Router
        |
        V

Execution Algorithms
        |
        V

Exchange Gateway
        |
        V

Market
```

---

# Order Management vs Execution Management

OMS:

```text id="ems6"
What should we trade?
```

---

EMS:

```text id="ems7"
How should we trade?
```

---

# Order Domain Model

Create:

```text
domain/

    execution_order.py
```

---

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class ExecutionOrder:

    order_id: str

    symbol: str

    side: str

    quantity: int

    limit_price: float | None

    strategy: str
```

---

# Order Lifecycle

Professional orders transition through:

```text
NEW
```

↓

```text
VALIDATED
```

↓

```text
ROUTED
```

↓

```text
PARTIAL_FILL
```

↓

```text
FILLED
```

↓

```text
SETTLED
```

---

# Example

Suppose:

```text
BUY
100,000
```

---

Exchange fills:

```text
30,000
```

---

State:

```text
PARTIAL_FILL
```

---

Remaining:

```text
70,000
```

---

# Execution State Machine

```text
NEW
 |
 V
VALIDATED
 |
 V
ROUTED
 |
 +------ REJECTED
 |
 V
FILLED
 |
 V
SETTLED
```

---

# Execution Service

Create:

```text
services/

    execution_service.py
```

---

Initialize:

```python
class ExecutionService:
```

---

Methods:

```python
submit()
```

---

```python
cancel()
```

---

```python
modify()
```

---

```python
fill()
```

---

# Pre-Trade Risk Checks

Before trading:

Verify:

```text
Position Limits
```

---

Verify:

```text
Exposure Limits
```

---

Verify:

```text
Margin
```

---

Verify:

```text
Liquidity
```

---

Example:

```text
Portfolio Limit:

10M
```

---

Trade:

```text
20M
```

---

Result:

```text
Rejected
```

---

# Smart Order Routing

Question:

```text id="ems8"
Where should
we trade?
```

---

Possible venues:

```text
SGX

Dark Pool

ECN

Broker Internalizer
```

---

# Smart Router Architecture

```text
Order
      |
      V

Venue Scanner
      |
      V

Cost Model
      |
      V

Liquidity Model
      |
      V

Router
```

---

# Venue Selection

Evaluate:

```text
Price
```

---

Evaluate:

```text
Liquidity
```

---

Evaluate:

```text
Latency
```

---

Evaluate:

```text
Fees
```

---

Choose:

```text
Best Venue
```

---

# Execution Algorithms

Professional systems rarely execute:

```text
Everything
Immediately
```

---

Instead they use:

```text
TWAP

VWAP

POV

Iceberg
```

---

# TWAP

Time Weighted Average Price.

Example:

```text
100,000 shares
```

---

Split into:

```text
10,000
every
minute
```

---

Goal:

```text
Hide Intent
```

---

# VWAP

Volume Weighted Average Price.

Example:

```text
Trade with
market volume.
```

---

Morning:

```text
High volume
```

---

Afternoon:

```text
Low volume
```

---

Goal:

```text
Blend In
```

---

# Participation (POV)

Example:

```text
Trade
10%
of market volume.
```

---

Market:

```text
100,000
```

---

We trade:

```text
10,000
```

---

Goal:

```text
Avoid Detection
```

---

# Iceberg Orders

Display:

```text
1000
```

---

Actually trade:

```text
100,000
```

---

Question:

```text id="ems9"
Can we hide
our size?
```

---

Answer:

```text
Yes.
```

---

# Execution Scheduling

Question:

```text id="ems10"
When should we trade?
```

---

Possibilities:

```text
Now

Later

Gradually

Conditionally
```

---

# Market Impact Models

Question:

```text id="ems11"
How much
will our trade
move price?
```

---

Formula:

```text
Impact

≈

Size
/
Liquidity
```

---

Example:

```text
Trade:
10M
```

---

Liquidity:

```text
1M
```

---

Result:

```text
High Impact
```

---

# Temporary Impact

Price moves:

```text
Now
```

---

Then:

```text
Returns
```

---

# Permanent Impact

Price moves:

```text
Now
```

---

And:

```text
Stays moved
```

---

# Transaction Cost Analysis (TCA)

Question:

```text id="ems12"
Did execution
perform well?
```

---

Compute:

```text
Arrival Price
```

---

Compute:

```text
Execution Price
```

---

Difference:

```text
Slippage
```

---

# Example

Signal:

```text
41.00
```

---

Execution:

```text
41.25
```

---

Cost:

```text
0.25
```

---

# Implementation Shortfall

Formula:

```text
Decision Price

-

Execution Price
```

---

Question:

```text id="ems13"
How much alpha
did execution destroy?
```

---

# Real-Time Execution Dashboard

Display:

```text
Orders
```

---

Display:

```text
Fills
```

---

Display:

```text
Slippage
```

---

Display:

```text
Latency
```

---

Display:

```text
Market Impact
```

---

# Fill Events

Create:

```text
events/

    fill_events.py
```

---

Example:

```python
@dataclass
class OrderFilled:

    order_id: str

    quantity: int

    price: float
```

---

# Execution Analytics

Track:

```text
Fill Rate
```

---

Track:

```text
Latency
```

---

Track:

```text
Slippage
```

---

Track:

```text
Impact
```

---

Track:

```text
Venue Performance
```

---

# Execution Replay

Question:

```text id="ems14"
Can we replay
the trade?
```

---

Replay:

```text
Orders
```

↓

```text
Quotes
```

↓

```text
Fills
```

↓

```text
Market Response
```

---

# Algorithm Selection

Question:

```text id="ems15"
Which execution
algorithm
should we use?
```

---

Examples:

| Situation       | Algorithm  |
| --------------- | ---------- |
| Small order     | Market     |
| Large order     | VWAP       |
| Illiquid market | TWAP       |
| Hidden intent   | Iceberg    |
| High urgency    | Aggressive |

---

# Execution Pipeline

```text
Signal
      |
      V

Portfolio
      |
      V

Order
      |
      V

Risk Check
      |
      V

EMS
      |
      V

SOR
      |
      V

Execution Algo
      |
      V

Exchange
```

---

# Why Execution Matters

Because:

```text
Prediction
```

creates:

```text
Potential Profit
```

---

Execution determines:

```text
Actual Profit
```

---

Professional firms know:

```text
Good execution
can rescue
bad alpha.

Bad execution
can destroy
good alpha.
```

---

# Architecture Lesson #38

Beginners think:

```text
Trading
    =
Buying
and
Selling
```

Professionals think:

```text
Trading
    =
An adversarial optimization problem
under uncertainty,
latency,
liquidity constraints,
and strategic information leakage
```

---

# Current Architecture

```text
Alpha Engine
        |
        V

Portfolio Construction
        |
        V

Order Generator
        |
        V

Execution Management System
        |
        V

Smart Order Router
        |
        V

Execution Algorithms
        |
        V

Market
```

TickerHub now contains:

✅ Order management

✅ Execution management

✅ Smart order routing

✅ Pre-trade risk

✅ TWAP execution

✅ VWAP execution

✅ POV execution

✅ Iceberg orders

✅ Market impact models

✅ Transaction cost analysis

✅ Execution replay

✅ Execution analytics

✅ Venue selection

At this point, TickerHub no longer resembles a trading terminal.

It resembles:

```text
A Real-Time Market Interaction Engine
capable of translating
probabilistic beliefs
into strategic market actions
while minimizing
information leakage,
market impact,
and execution cost.
```

---

# In Part 39

We will build the **Distributed Risk, Margin & Real-Time Portfolio Analytics Platform**, where you'll discover that professional financial systems are not designed merely to ask:

```text
How much money
can we make?
```

but:

```text
How much money
can we lose
before somebody
forces us to stop?
```
