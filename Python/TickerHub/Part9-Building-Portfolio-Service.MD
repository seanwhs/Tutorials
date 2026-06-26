# Building TickerHub

## Part 9: Building the Portfolio Service — Turning Market Data into Financial Reality

> Market data tells us what happened.
>
> Portfolio management tells us what it means.

A professional financial terminal is not built to display prices.

It is built to answer questions like:

* How much money do I have?
* How much did I make?
* How much did I lose?
* What is my exposure?
* What happens if the market crashes?
* Am I breaking my risk limits?

These questions are answered by the:

# Portfolio Service

---

# The Beginner Approach

Most developers initially build portfolios like this:

```python id="2wexwt"
portfolio = {

    "D05": 100,

    "U11": 200
}
```

Then:

```python id="jdfot8"
value = (

    portfolio["D05"]
    * current_price
)
```

This works.

Until you add:

* multiple currencies,
* average price,
* realized PnL,
* unrealized PnL,
* corporate actions,
* dividends,
* leverage,
* borrowing,
* derivatives,
* risk calculations.

Then:

```text id="cmmrwy"
Dictionary Hell
```

begins.

---

# The Professional View

Professional systems think of portfolios as:

```text id="5s0b4z"
Dynamic Financial Models
```

A portfolio is continuously recalculated from:

```text id="kxbrcc"
Trades
       +
Market Prices
       +
Corporate Actions
       +
Risk Models
```

---

# Portfolio Service Architecture

```text id="zjcbaz"
               Trade Events
                     |
                     V

             PortfolioService

        ┌─────────┬──────────┬──────────┐
        │         │          │          │

        ▼         ▼          ▼          ▼

    Portfolio   State      Events     Risk
```

---

# Responsibilities

PortfolioService must:

* maintain positions,
* process trades,
* update market prices,
* compute PnL,
* compute exposure,
* update portfolio state,
* publish portfolio events,
* trigger risk recalculation.

---

# Creating the Service

Create:

```text id="csh0mu"
services/

    portfolio_service.py
```

---

# Dependencies

```python id="axpy2g"
from state.app_state import (
    AppState
)

from events.base import (
    EventBus
)

from repositories.portfolio_repository import (
    PortfolioRepository
)
```

---

# Constructor

```python id="tz57z0"
class PortfolioService:

    def __init__(
        self,
        state,
        bus,
        repository
    ):

        self.state = state

        self.bus = bus

        self.repository = repository
```

---

# Internal Portfolio Cache

Professional systems rarely hit the database.

Store:

```python id="w6l64u"
self.portfolios = {}
```

Example:

```text id="wshn3t"
alice
    |
    V
Portfolio
```

---

# Loading a Portfolio

```python id="c7dz4a"
async def load(
    self,
    user
):

    portfolio = await (
        self.repository.load(
            user
        )
    )

    self.portfolios[
        user
    ] = portfolio

    return portfolio
```

---

# Example

```python id="0ch8ri"
portfolio = await (
    portfolio_service.load(
        "alice"
    )
)
```

---

# The Real Driver of Portfolios

Portfolios are not updated by users.

They are updated by:

```text id="j3s2ui"
Trades
```

and

```text id="bvmvgs"
Market Prices
```

---

# Event Subscription

Subscribe to:

```python id="zbl2p7"
TradeExecuted
```

and:

```python id="syq4e2"
PriceUpdated
```

---

Example:

```python id="40ojd1"
bus.subscribe(

    TradeExecuted,

    self.on_trade
)
```

---

```python id="8p77up"
bus.subscribe(

    PriceUpdated,

    self.on_price
)
```

---

# Processing Trades

Suppose:

```text id="ogjlwm"
BUY
100
DBS
at
40.00
```

---

Example event:

```python id="jlwmvb"
TradeExecuted(

    trade_id="T001",

    symbol="D05",

    quantity=100,

    price=40
)
```

---

# Finding the Position

```python id="9ccpsf"
def find_position(

    self,

    portfolio,

    symbol
):

    for position in portfolio.positions:

        if position.instrument == symbol:

            return position

    return None
```

---

# Processing a New Position

```python id="hzg9f6"
if position is None:

    position = Position(

        instrument=symbol,

        quantity=0,

        average_price=0,

        market_price=price,

        currency="SGD"
    )

    portfolio.positions.append(
        position
    )
```

---

# Updating Quantity

Suppose:

```text id="4wsejh"
Existing:

100 shares
```

New trade:

```text id="3qll8y"
Buy 50
```

Result:

```text id="j3swc5"
150 shares
```

---

Formula:

```python id="4j3frn"
new_quantity = (

    position.quantity

    + trade.quantity
)
```

---

# Updating Average Price

Professional systems use weighted averages.

Formula:

```python id="3e1lm2"
new_average = (

    position.quantity
    * position.average_price

    +

    trade.quantity
    * trade.price

) / new_quantity
```

---

Example:

```text id="svk6pi"
100 @ 40

50 @ 44
```

Result:

```text id="h3mboz"
150 @ 41.33
```

---

Update:

```python id="5rbrwp"
position.quantity = (
    new_quantity
)

position.average_price = (
    new_average
)
```

---

# Save Portfolio

```python id="4mjlwm"
await self.repository.save(
    portfolio
)
```

---

# Publish Event

```python id="ld0a7s"
self.bus.publish(

    PortfolioChanged(
        portfolio.owner
    )
)
```

---

# Why Publish?

Because:

```text id="ybbyj0"
RiskService
```

needs to know.

And:

```text id="t52z2n"
AnalyticsService
```

needs to know.

And:

```text id="b7cb3z"
UI
```

needs to know.

---

# Market Price Changes

The other driver of portfolios is:

```text id="j07v90"
PriceUpdated
```

---

Example:

```text id="vf1w6h"
D05

40

→

43
```

---

Event:

```python id="z6h8gt"
PriceUpdated(

    symbol="D05",

    price=43
)
```

---

# Updating Positions

```python id="5jlwmr"
def on_price(
    self,
    event
):

    for portfolio in (

        self.portfolios.values()
    ):

        for position in (

            portfolio.positions
        ):

            if (

                position.instrument

                ==

                event.symbol
            ):

                position.market_price = (
                    event.price
                )
```

---

# What Happens Next?

Automatically:

```text id="y0i9ti"
market_price changes
        |
        V

position.pnl changes
        |
        V

portfolio.pnl changes
        |
        V

risk changes
```

Because our domain objects contain behavior.

---

# Example

Before:

```text id="wuhkfy"
100
shares

avg = 40

market = 40

PnL = 0
```

---

After:

```text id="a7ld4f"
100
shares

avg = 40

market = 43

PnL = 300
```

No explicit calculation needed.

---

# Computing Portfolio Value

Our domain already has:

```python id="1krr5l"
@property
def market_value(
    self
):
```

which calculates:

```text id="ljlwm6"
sum(
    positions
)
```

---

Example:

```python id="jz1w3o"
portfolio.market_value
```

returns:

```text id="k3pw0w"
43000
```

---

# Exposure

Professional portfolios track exposure.

Formula:

```python id="9k5qoc"
exposure = sum(

    abs(
        p.market_value
    )

    for p in portfolio.positions
)
```

---

Example:

```text id="t5ycjz"
Long:
100,000

Short:
50,000
```

Exposure:

```text id="31w7e2"
150,000
```

---

# Leverage

Formula:

```python id="e12ec2"
leverage = (

    exposure

    /

    equity
)
```

---

Example:

```text id="wni6cc"
Exposure:

500,000

Equity:

100,000
```

Result:

```text id="2hzv66"
5x leverage
```

---

# Concentration Risk

Example:

```text id="v5zjlwm"
Portfolio:

90%
DBS

10%
Everything else
```

This is dangerous.

Calculate:

```python id="0ql7s6"
largest_position = max(

    p.market_value

    for p in positions
)

concentration = (

    largest_position

    /

    portfolio.market_value
)
```

---

# Realized vs Unrealized PnL

Professional systems track both.

---

Unrealized:

```text id="qhsdh0"
Bought @ 40

Current = 43
```

Result:

```text id="i7xv03"
+300
```

---

Realized:

```text id="6jzjlwm"
Bought @ 40

Sold @ 43
```

Result:

```text id="6vwg0d"
+300 cash
```

---

Eventually:

```python id="hqaqht"
position.realized_pnl

position.unrealized_pnl
```

---

# Portfolio Snapshots

Professional systems periodically save:

```text id="zgnjlwm"
Portfolio Value

PnL

Risk

Exposure
```

Example:

```python id="dl7g72"
snapshot = {

    "timestamp": now,

    "value": portfolio.value,

    "pnl": portfolio.pnl,

    "risk": portfolio.var
}
```

---

Why?

For:

* charts,
* analytics,
* attribution,
* auditing.

---

# Event Flow

Suppose DBS rises.

```text id="js4xut"
Market Feed
      |
      V

PriceUpdated
      |
      V

PortfolioService
      |
      V

PortfolioChanged
      |
      V

RiskService
      |
      V

RiskCalculated
      |
      V

Dashboard
```

Nobody explicitly calls anybody.

---

# Portfolio State Update

After recalculation:

```python id="ljlwmw"
self.state.portfolio.total_value = (

    portfolio.market_value
)
```

---

```python id="uwc07n"
self.state.portfolio.total_pnl = (

    portfolio.pnl
)
```

Immediately:

```text id="f0u2e9"
Dashboard updates.
```

---

# Performance Considerations

Professional systems avoid:

```text id="jlwmr7"
Recalculate Everything
```

Instead:

```text id="rh9c1u"
Only Recalculate
What Changed
```

Example:

```text id="m1vjlwm"
D05 updated
```

Recalculate only:

```text id="xjlwm3"
D05 positions
```

---

# Why Portfolio Engines Are Hard

Because portfolios are:

```text id="lhrjlwm"
State Machines
       +
Mathematical Models
       +
Event Processors
       +
Accounting Systems
```

at the same time.

---

# The Updated Architecture

```text id="0djlwm"
               Market Feed
                      |
                      V

                MarketService
                      |
                      V

                 Event Bus

          ┌───────────┼───────────┐
          │           │           │

          ▼           ▼           ▼

      Portfolio     Risk      Alerts
       Service      Service    Service
          |
          V

      PortfolioState
          |
          V

         Panel
```

---

# Architecture Lesson #9

Beginners think:

```text id="bjlwm3"
Portfolio
      =
Table
```

Professionals think:

```text id="jlwmw0"
Portfolio
      =
Continuously Recomputed
Financial Reality
```

The database merely stores snapshots of that reality.

---

# Current Progress

We now have:

✅ Domain Model

✅ State Engine

✅ Event Bus

✅ Repository Layer

✅ Market Service

✅ Portfolio Service

TickerHub has become:

```text id="6jlwmk"
A Reactive Financial Engine
```

We still haven't built a single chart.

And that's exactly why the architecture is healthy.

---

# In Part 10

We will build the **RiskService**, where you'll discover that professional risk systems are not calculators.

They are:

```text id="jlwmv8"
Distributed Simulation Engines
```

that happen to output numbers like:

```text id="jlwmx4"
VaR

CVaR

Exposure

Stress Loss

Greeks
```
