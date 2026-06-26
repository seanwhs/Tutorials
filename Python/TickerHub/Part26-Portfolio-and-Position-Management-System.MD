# Building TickerHub

## Part 26: Building the Portfolio & Position Management System (PMS) — Modeling Financial Reality as a Continuous State Machine

> Orders express intent.
>
> Trades create reality.

After building the OMS, TickerHub can now:

* receive orders,
* validate risk,
* execute trades,
* track order lifecycles,
* replay execution history.

But trading systems have a fundamental problem:

```text
Orders are temporary.

Portfolios are permanent.
```

A professional trading terminal is not primarily an order-entry system.

It is a:

```text
Portfolio State Management System
```

because traders ultimately care about:

* what they own,
* what they owe,
* what they are exposed to,
* how much money they are making,
* how much money they are losing.

---

# The Beginner Portfolio Model

Most tutorials implement portfolios like this:

```python
portfolio = {
    "D05": 100,
    "U11": 50
}
```

Or:

```sql
SELECT *
FROM positions
```

This works.

Until:

* partial fills,
* short positions,
* FX conversions,
* corporate actions,
* margin requirements,
* realized PnL,
* unrealized PnL,
* multi-account portfolios,
* portfolio attribution.

Then:

```text
Holdings
```

becomes:

```text
Financial State Modeling
```

---

# Professional Architecture

Professional systems model:

```text
Trades

↓

Positions

↓

Portfolios

↓

Accounts

↓

Firms
```

---

# Financial Hierarchy

Example:

```text
Firm
   |
   +---- Portfolio
             |
             +---- Account
                        |
                        +---- Position
```

---

# Core Principle

Professional systems never store:

```text
Current Position
```

They store:

```text
Position Evolution
```

---

# Example

Suppose:

```text
BUY 100 D05 @ 40
```

Position:

```text
100 shares
```

---

Later:

```text
BUY 50 D05 @ 42
```

Position becomes:

```text
150 shares
```

---

Later:

```text
SELL 75 D05 @ 45
```

Position becomes:

```text
75 shares
```

---

The position is:

```text
A State Machine
```

---

# Position Domain Model

Create:

```text
domain/

    position.py
```

---

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class Position:

    symbol: str

    quantity: int

    average_price: float

    market_price: float

    realized_pnl: float

    unrealized_pnl: float
```

---

# Market Value

Add:

```python
@property
def market_value(self):

    return (
        self.quantity
        * self.market_price
    )
```

---

# Unrealized PnL

Add:

```python
@property
def unrealized(self):

    return (

        self.market_price

        -

        self.average_price

    ) * self.quantity
```

---

# Example

Suppose:

```text
Bought:
100 @ 40
```

Current:

```text
45
```

---

Then:

```text
(45-40) * 100
```

equals:

```text
$500 profit
```

---

# Portfolio Domain

Create:

```text
domain/

    portfolio.py
```

---

```python
from dataclasses import field
```

---

```python
@dataclass
class Portfolio:

    owner: str

    positions: dict = field(
        default_factory=dict
    )
```

---

# Portfolio Value

Add:

```python
@property
def value(self):

    return sum(

        p.market_value

        for p

        in self.positions.values()
    )
```

---

# Portfolio PnL

Add:

```python
@property
def pnl(self):

    return sum(

        p.unrealized

        for p

        in self.positions.values()
    )
```

---

# Why Derived State?

Professional systems avoid storing:

```text
Portfolio Value
```

because:

```text
Portfolio Value

=

Function(Position State)
```

---

# Portfolio Service

Create:

```text
services/

    portfolio_service.py
```

---

Initialize:

```python
class PortfolioService:

    def __init__(

        self,

        repository,

        market_state
    ):
```

---

Store:

```python
self.repo = repository
```

---

Store:

```python
self.market = market_state
```

---

# Process Trade

Create:

```python
async def process_trade(

    self,

    trade
):
```

---

Load:

```python
portfolio = (
    await self.repo.load(
        trade.user
    )
)
```

---

Find position:

```python
position = (
    portfolio.positions.get(
        trade.symbol
    )
)
```

---

# New Position

If:

```python
position is None
```

Create:

```python
Position(

    symbol=trade.symbol,

    quantity=0,

    average_price=0,

    market_price=trade.price,

    realized_pnl=0,

    unrealized_pnl=0
)
```

---

# Buy Logic

Example:

```text
100 @ 40

+

50 @ 50
```

---

Average:

```text
(100×40)+(50×50)
----------------
150
```

---

Implement:

```python
new_avg = (

    old_qty*old_price

    +

    qty*price

) / total_qty
```

---

# Sell Logic

Example:

```text
Buy:
100 @ 40
```

Sell:

```text
50 @ 45
```

---

Profit:

```text
(45-40)*50
```

equals:

```text
250
```

---

Add:

```python
position.realized_pnl += (
    realized
)
```

---

Reduce:

```python
position.quantity -= (
    trade.quantity
)
```

---

# Short Selling

Suppose:

```text
SELL 100
```

before buying.

Position:

```text
-100
```

---

Example:

```text
Quantity:

-100
```

means:

```text
Short
```

---

# Portfolio State

Store:

```text
Portfolio
```

inside:

```text
Redis
```

---

Example:

```text
portfolio:user123
```

---

Store:

```json
{
    "cash":100000,

    "positions":[]
}
```

---

# Cash Ledger

Create:

```text
cash_balance
```

---

Example:

```text
Initial:

100000
```

---

Buy:

```text
100 @ 40
```

---

Cash:

```text
96000
```

---

Sell:

```text
50 @ 45
```

---

Cash:

```text
98250
```

---

# Multi-Currency

Suppose:

```text
USD Position

SGD Account
```

---

Convert:

```text
USD

↓

SGD
```

---

Store:

```text
FX Rates
```

inside Redis.

---

Example:

```python
usd_value * fx_rate
```

---

# Margin Accounts

Professional accounts support leverage.

---

Example:

```text
Cash:
100k

Buying Power:
500k
```

---

Formula:

```text
Buying Power

=

Cash × Leverage
```

---

# Position Limits

Check:

```text
Max Quantity

Max Exposure

Max Sector Weight
```

---

Example:

```text
Technology

40%
```

---

Attempt:

```text
60%
```

Reject.

---

# Sector Exposure

Store:

```text
Technology

Banking

Healthcare
```

weights.

---

Example:

```text
Technology:
45%
```

---

# Concentration Risk

Example:

```text
DBS:

80%
```

of portfolio.

---

Raise:

```text
Concentration Alert
```

---

# Portfolio Attribution

Compute:

```text
PnL
```

by:

```text
Sector

Strategy

Asset Class
```

---

Example:

```text
Banking:
+1000

Technology:
-200
```

---

# Time Series

Store:

```text
Portfolio Value
```

over time.

---

Example:

```text
09:00

100000
```

---

Later:

```text
09:01

100200
```

---

Later:

```text
09:02

100150
```

---

# Equity Curve

Generate:

```text
Portfolio Value

vs

Time
```

---

Example:

```text
100k

102k

101k

105k
```

---

# Drawdown

Compute:

```text
Peak

-

Current
```

---

Example:

```text
Peak:
120k

Current:
100k
```

---

Drawdown:

```text
16.7%
```

---

# Portfolio Snapshot

Store periodically:

```text
Every Minute
```

---

Example:

```json
{
    "value":100000,

    "cash":50000,

    "positions":[]
}
```

---

# Why Snapshots?

Because replaying:

```text
20 million trades
```

every restart is expensive.

---

Instead:

```text
Snapshot

+

Recent Trades
```

---

# Performance Metrics

Calculate:

```text
Return

Volatility

Sharpe

Sortino

Beta

Alpha
```

---

# Example

```text
Annual Return:
12%

Volatility:
8%

Sharpe:
1.5
```

---

# Portfolio Event Flow

Suppose:

```text
BUY

100 D05
```

---

OMS produces:

```text
TradeExecuted
```

---

Flow:

```text
OMS
    |
    V

Trade Event
    |
    V

Portfolio Service
    |
    +------ Redis
    |
    +------ PostgreSQL
    |
    +------ Analytics
```

---

Update:

```text
Position
```

---

Update:

```text
Portfolio
```

---

Update:

```text
PnL
```

---

Update:

```text
Risk
```

---

Broadcast:

```text
Panel UI
```

---

# Portfolio Recovery

Suppose:

```text
System Crash
```

---

Recovery:

```text
Snapshot
      |
      V

Trade Replay
      |
      V

Portfolio State
```

---

# The Real PMS Architecture

```text
Portfolio System
        |
        +------ Positions
        |
        +------ Cash
        |
        +------ Margin
        |
        +------ Exposure
        |
        +------ Attribution
        |
        +------ Analytics
        |
        +------ History
        |
        +------ Recovery
```

---

# Why Professional Portfolio Systems Are Difficult

Because:

```text
Portfolio
```

is not:

```text
A Table
```

A portfolio is:

```text
A Continuously Evolving
Financial State Machine
representing
ownership,
obligations,
and economic exposure.
```

---

# Architecture Lesson #26

Beginners think:

```text
Portfolio
      =
Holdings
```

Professionals think:

```text
Portfolio
      =
A Derived State Machine
constructed from
trades,
prices,
cash,
risk,
and time.
```

---

# Current Architecture

```text
Market Feed
      |
      V

Kafka
      |
      V

OMS
      |
      V

Trade Events
      |
      V

Portfolio Service
      |
      +------ Positions
      |
      +------ Cash
      |
      +------ Exposure
      |
      +------ Margin
      |
      +------ Analytics
      |
      V

Redis State
      |
      V

PostgreSQL History
      |
      V

Panel UI
```

TickerHub now contains:

✅ Position management

✅ Portfolio management

✅ Realized PnL

✅ Unrealized PnL

✅ Cash ledgers

✅ Short positions

✅ Margin accounts

✅ Exposure tracking

✅ Sector attribution

✅ Performance analytics

✅ Portfolio snapshots

✅ Recovery mechanisms

At this point, TickerHub no longer resembles a trading application.

It resembles:

```text
A Real-Time Financial Accounting Engine
capable of continuously modeling
ownership,
capital,
and economic reality.
```

---

# In Part 27

We will build the **Risk Management Engine**, where you'll discover that professional risk systems are not:

```text
Calculators
```

but rather:

```text
Predictive simulation engines
designed to estimate
the future distribution
of financial pain.
```
