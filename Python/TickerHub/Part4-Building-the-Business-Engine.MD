# Building TickerHub

## Part 4: Domain-Driven Design for Financial Systems

> Before we build services, databases, APIs, or dashboards, we must build the thing that actually matters:
>
> **the business itself.**

Many software projects begin with:

```python
class User(Model):
    ...
```

Financial systems do not.

Professional financial systems begin by asking:

> What are the core business concepts of the market?

This approach is called **Domain-Driven Design (DDD)**.

DDD is not a framework.

DDD is a way of thinking:

```text
Business Reality
       ↓
Domain Model
       ↓
Software
```

instead of:

```text
Framework
      ↓
Database
      ↓
Business Logic
```

---

# What Is a Domain?

A domain is simply:

> The real-world business system we are trying to model.

For TickerHub, our domain is:

```text
Financial Markets
```

Inside that domain, we have:

```text
Instruments
Positions
Portfolios
Orders
Trades
Quotes
Risk
Alerts
News
```

These become our domain objects.

---

# Why Domain Models Matter

Consider this beginner approach:

```python
portfolio = {
    "owner": "alice",
    "value": 100000,
    "pnl": 500
}
```

This works.

Until:

* you need risk,
* you need exposure,
* you need leverage,
* you need Greeks,
* you need VaR,
* you need attribution,
* you need scenarios.

Now your dictionary becomes:

```python
portfolio["var"]
portfolio["cvar"]
portfolio["delta"]
portfolio["gamma"]
portfolio["stress"]
portfolio["sector_exposure"]
portfolio["country_exposure"]
portfolio["currency_exposure"]
```

Eventually:

```text
Chaos
```

Instead, professional systems build domain objects.

---

# The Financial Domain Model

Our first domain model looks like this:

```text
                    Instrument
                         |
                         |
                         V
                      Quote
                         |
                         |
                         V
                      Position
                         |
                         |
                         V
                     Portfolio
                         |
                         |
                         V
                        Risk
```

---

# Domain Folder Structure

Create:

```text
domain/

    __init__.py

    instrument.py
    quote.py
    position.py
    portfolio.py
    order.py
    trade.py
    risk.py
```

---

# Domain Object #1 — Instrument

An instrument represents a tradable asset.

Examples:

```text
D05
U11
C6L
AAPL
MSFT
BTCUSD
ESU26
```

Create:

## domain/instrument.py

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class Instrument:

    symbol: str

    name: str

    exchange: str

    asset_class: str

    currency: str
```

---

Example:

```python
dbs = Instrument(
    symbol="D05",
    name="DBS Group",
    exchange="SGX",
    asset_class="Equity",
    currency="SGD"
)
```

---

# Why frozen=True?

Professional systems treat instruments as immutable.

This:

```python
dbs.symbol = "AAPL"
```

should never happen.

Financial entities should not mutate unexpectedly.

---

# Domain Object #2 — Quote

A quote represents the current market state.

Create:

## domain/quote.py

```python
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Quote:

    symbol: str

    bid: float

    ask: float

    last: float

    volume: int

    timestamp: datetime
```

---

Example:

```python
Quote(
    symbol="D05",
    bid=43.15,
    ask=43.16,
    last=43.15,
    volume=120000,
    timestamp=datetime.now()
)
```

---

# Why Separate Instrument and Quote?

Many beginners write:

```python
class Stock:
    symbol
    price
```

This is wrong.

Why?

Because:

```text
Instrument
```

is static.

While:

```text
Quote
```

changes thousands of times per second.

Separating them prevents architectural pain later.

---

# Domain Object #3 — Position

A position represents ownership.

Create:

## domain/position.py

```python
from dataclasses import dataclass


@dataclass
class Position:

    instrument: str

    quantity: int

    average_price: float

    market_price: float

    currency: str
```

---

Add calculated properties.

```python
@property
def market_value(self):

    return (
        self.quantity
        * self.market_price
    )
```

---

```python
@property
def cost_basis(self):

    return (
        self.quantity
        * self.average_price
    )
```

---

```python
@property
def pnl(self):

    return (
        self.market_price
        - self.average_price
    ) * self.quantity
```

---

Example:

```python
position = Position(
    instrument="D05",
    quantity=1000,
    average_price=40.0,
    market_price=43.0,
    currency="SGD"
)
```

Results:

```text
Market Value = 43000

Cost Basis = 40000

PnL = 3000
```

---

# Why Put Logic Inside the Domain?

Beginners often write:

```python
def calculate_pnl(position):
    ...
```

Professional systems write:

```python
position.pnl
```

because:

> Behavior belongs with the thing that owns the behavior.

This principle is fundamental to DDD.

---

# Domain Object #4 — Portfolio

A portfolio is an aggregate.

It owns positions.

Create:

## domain/portfolio.py

```python
from dataclasses import (
    dataclass,
    field,
)

from typing import List

from .position import Position


@dataclass
class Portfolio:

    owner: str

    positions: List[Position] = field(
        default_factory=list
    )
```

---

Add properties.

```python
@property
def market_value(self):

    return sum(
        p.market_value
        for p in self.positions
    )
```

---

```python
@property
def cost_basis(self):

    return sum(
        p.cost_basis
        for p in self.positions
    )
```

---

```python
@property
def pnl(self):

    return sum(
        p.pnl
        for p in self.positions
    )
```

---

Example:

```python
portfolio = Portfolio(
    owner="alice"
)

portfolio.positions.append(
    position
)
```

Results:

```text
Portfolio Value

43000
```

---

# Aggregate Roots

In DDD, some objects own other objects.

Example:

```text
Portfolio
     |
     +---- Position
     |
     +---- Position
     |
     +---- Position
```

The owner is called an:

# Aggregate Root

In TickerHub:

| Aggregate Root | Owns      |
| -------------- | --------- |
| Portfolio      | Positions |
| OrderBook      | Orders    |
| Workspace      | Panels    |

---

# Domain Object #5 — Order

An order represents intent.

Create:

## domain/order.py

```python
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Order:

    order_id: str

    symbol: str

    side: str

    quantity: int

    price: float

    timestamp: datetime
```

---

Example:

```python
Order(
    order_id="ORD001",
    symbol="D05",
    side="BUY",
    quantity=100,
    price=43.50,
    timestamp=datetime.now()
)
```

---

# Orders Are Not Trades

Many beginners confuse these.

Order:

```text
"I want to buy."
```

Trade:

```text
"You bought."
```

---

# Domain Object #6 — Trade

Create:

## domain/trade.py

```python
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Trade:

    trade_id: str

    order_id: str

    symbol: str

    quantity: int

    price: float

    timestamp: datetime
```

---

Flow:

```text
Order
    ↓
Exchange
    ↓
Execution
    ↓
Trade
```

---

# Domain Object #7 — Risk

Risk is another aggregate.

Create:

## domain/risk.py

```python
from dataclasses import dataclass


@dataclass
class Risk:

    portfolio_id: str

    var: float

    cvar: float

    exposure: float

    leverage: float
```

---

Example:

```python
Risk(
    portfolio_id="P001",
    var=3500,
    cvar=5200,
    exposure=250000,
    leverage=1.4
)
```

---

# Domain Services

Sometimes behavior belongs to no object.

Example:

```text
Portfolio
      +
Market Data
      +
Scenarios
      +
Correlations
      =
VaR
```

Who owns this?

Not:

* Portfolio
* Position
* Trade

Instead:

```text
RiskService
```

This is called a:

# Domain Service

---

# Value Objects

Some objects have no identity.

Example:

```text
Money
Currency
Price
Percentage
```

Create:

## domain/money.py

```python
from dataclasses import dataclass


@dataclass(frozen=True)
class Money:

    amount: float

    currency: str
```

---

Examples:

```python
Money(
    amount=100,
    currency="SGD"
)
```

These are:

```text
Value Objects
```

because:

```text
100 SGD
     ==
100 SGD
```

Identity does not matter.

---

# Entity vs Value Object

| Entity    | Value Object |
| --------- | ------------ |
| Trade     | Money        |
| Order     | Price        |
| Position  | Currency     |
| Portfolio | Percentage   |

---

# Building the Domain Graph

Our domain model now looks like:

```text
                   Instrument
                        |
                        |
                        V
                     Quote
                        |
                        |
                        V
                    Position
                        |
                        |
                        V
                   Portfolio
                        |
                        |
                        V
                       Risk


Order
   |
   |
   V
Trade
```

---

# Why Build the Domain First?

Because everything else depends on it.

Next week we might replace:

```text
Redis
```

with:

```text
Memcached
```

No problem.

We might replace:

```text
Panel
```

with:

```text
React
```

No problem.

We might replace:

```text
PostgreSQL
```

with:

```text
Snowflake
```

No problem.

But if we replace:

```text
Portfolio
```

the business itself changes.

The domain is the only truly stable part of the system.

---

# Our Architecture Now

```text
Domain
   |
   +---- Instrument
   |
   +---- Quote
   |
   +---- Position
   |
   +---- Portfolio
   |
   +---- Order
   |
   +---- Trade
   |
   +---- Risk
```

Everything else in TickerHub will eventually sit on top of this foundation.

---

# Architecture Lesson #4

Beginners build:

```text
Database
     ↓
Models
     ↓
Business Logic
```

Professionals build:

```text
Business
     ↓
Domain Model
     ↓
Application
     ↓
Database
```

The database stores the business.

It does not define the business.

---

# In Part 5

We will build the **TickerHub State Engine** using:

* `param`
* reactive programming
* state machines
* application state
* session state
* workspace state

and you'll discover that a professional Panel application is really a distributed **state synchronization engine** disguised as a dashboard.
