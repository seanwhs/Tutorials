# Building TickerHub

## Part 6: Building the Event Bus

> If state is the nervous system of TickerHub, then the event bus is the circulatory system.

Most developers learn programming using this model:

```python
function_a()

function_b()

function_c()
```

This is called:

```text
Direct Invocation
```

One piece of code explicitly calls another piece of code.

This works beautifully until your application becomes large.

Professional financial systems do not work this way.

Instead, they work like this:

```text
Something Happened
        ↓
     Event
        ↓
    Event Bus
        ↓
Many Consumers
```

This architectural pattern powers:

* trading systems,
* market data systems,
* banking platforms,
* payment networks,
* real-time analytics systems.

And now, TickerHub.

---

# Why Function Calls Fail

Suppose DBS price changes.

A beginner writes:

```python
def update_price(symbol, price):

    chart.update(
        symbol,
        price
    )

    watchlist.update(
        symbol,
        price
    )

    portfolio.update(
        symbol,
        price
    )

    risk.update(
        symbol,
        price
    )

    alerts.update(
        symbol,
        price
    )
```

Initially:

```text
Works
```

Six months later:

```python
def update_price(symbol, price):

    chart.update()

    watchlist.update()

    portfolio.update()

    risk.update()

    alerts.update()

    news.update()

    analytics.update()

    websocket.update()

    cache.update()

    persistence.update()

    audit.update()
```

Eventually:

```text
One function owns the universe.
```

This architecture collapses.

---

# Event-Driven Thinking

Instead, professionals think differently.

The system does not ask:

> Who should I notify?

It asks:

> What happened?

Example:

```text
DBS price changed.
```

This becomes:

```text
PriceUpdated
```

Now:

```text
Market Service

publishes

PriceUpdated
```

The service doesn't care who receives it.

---

# The Event Architecture

```text
               PriceUpdated
                      |
                      V

                Event Bus

      ┌────────┬────────┬────────┐
      │        │        │        │
      ▼        ▼        ▼        ▼

   Chart   Portfolio  Risk   Alerts
```

This gives us:

* loose coupling,
* scalability,
* testability,
* maintainability.

---

# What Is an Event?

An event is:

> A fact describing something that already happened.

Good events:

```text
PriceUpdated

TradeExecuted

PortfolioChanged

RiskCalculated

OrderPlaced
```

Bad events:

```text
UpdatePrice()

RefreshChart()

CalculateRisk()
```

Notice the difference.

Good:

```text
Past tense.
```

Bad:

```text
Commands.
```

---

# Commands vs Events

Commands:

```text
Do something.
```

Events:

```text
Something happened.
```

Example:

```text
BUY 100 DBS
```

This is a command.

After execution:

```text
TradeExecuted
```

This is an event.

Professional systems separate these concepts.

---

# Creating the Events Package

Create:

```text
events/

    __init__.py

    base.py

    market_events.py

    portfolio_events.py

    risk_events.py

    order_events.py
```

---

# Building the Event Bus

Create:

## events/base.py

```python
from collections import defaultdict


class EventBus:

    def __init__(self):

        self.handlers = defaultdict(
            list
        )
```

---

# Subscribing

Add:

```python
def subscribe(
    self,
    event_type,
    handler
):

    self.handlers[
        event_type
    ].append(
        handler
    )
```

---

# Publishing

Add:

```python
def publish(
    self,
    event
):

    handlers = self.handlers[
        type(event)
    ]

    for handler in handlers:

        handler(event)
```

---

# The Simplest Event Bus

Our entire event system currently fits into:

```python
subscribe()

publish()
```

Yet this tiny abstraction powers some of the world's largest systems.

---

# Building Our First Event

Create:

## events/market_events.py

```python
from dataclasses import dataclass


@dataclass
class PriceUpdated:

    symbol: str

    price: float
```

---

Example:

```python
event = PriceUpdated(

    symbol="D05",

    price=43.15
)
```

---

# Creating Subscribers

Suppose we have:

```python
def chart_handler(event):

    print(
        "chart updated"
    )
```

---

And:

```python
def portfolio_handler(event):

    print(
        "portfolio updated"
    )
```

---

Register them:

```python
bus = EventBus()

bus.subscribe(
    PriceUpdated,
    chart_handler
)

bus.subscribe(
    PriceUpdated,
    portfolio_handler
)
```

---

Publish:

```python
bus.publish(

    PriceUpdated(
        "D05",
        43.15
    )
)
```

Result:

```text
chart updated

portfolio updated
```

---

# Notice Something Important

The market service never knew about:

* charts,
* portfolios,
* risk,
* alerts.

It only knew:

```text
PriceUpdated
```

This is called:

# Decoupling

---

# Building Additional Events

Create:

## events/order_events.py

```python
from dataclasses import dataclass


@dataclass
class OrderPlaced:

    order_id: str

    symbol: str

    quantity: int
```

---

```python
@dataclass
class OrderCancelled:

    order_id: str
```

---

```python
@dataclass
class TradeExecuted:

    trade_id: str

    symbol: str

    quantity: int

    price: float
```

---

# Portfolio Events

Create:

## events/portfolio_events.py

```python
from dataclasses import dataclass


@dataclass
class PortfolioChanged:

    user: str
```

---

```python
@dataclass
class PositionUpdated:

    symbol: str

    quantity: int
```

---

# Risk Events

Create:

## events/risk_events.py

```python
from dataclasses import dataclass


@dataclass
class RiskCalculated:

    portfolio: str

    var: float

    cvar: float
```

---

# Event Flow Example

Suppose a trade occurs.

```text
Trade Executed
```

The system flow becomes:

```text
TradeExecuted
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

Notice:

No service directly calls another service.

---

# Event Cascades

Professional systems often produce chains of events.

Example:

```text
PriceUpdated
       ↓
PortfolioChanged
       ↓
RiskCalculated
       ↓
AlertTriggered
       ↓
NotificationSent
```

This is called an:

# Event Cascade

---

# Synchronous vs Asynchronous Events

Our current bus is:

```text
Synchronous
```

Meaning:

```python
publish()

wait

handler()

wait

handler()

wait

handler()
```

This works initially.

Eventually we'll build:

```text
Kafka
```

which becomes:

```text
Asynchronous
```

```text
Producer
      |
      V
    Kafka
      |
      V
Consumers
```

---

# Upgrading to Async Events

Future version:

```python
import asyncio


class EventBus:

    async def publish(
        self,
        event
    ):

        tasks = []

        for handler in self.handlers[
            type(event)
        ]:

            tasks.append(
                handler(event)
            )

        await asyncio.gather(
            *tasks
        )
```

Now events execute concurrently.

---

# Event Persistence

Professional systems often store events.

Example:

```text
12:00:00
PriceUpdated

12:00:01
TradeExecuted

12:00:03
PortfolioChanged

12:00:04
RiskCalculated
```

Benefits:

* auditing,
* replay,
* debugging,
* analytics,
* compliance.

This concept is called:

# Event Sourcing

---

# Event Replay

Suppose production crashes.

If events are stored:

```text
Event #1
Event #2
Event #3
Event #4
```

we can rebuild state:

```text
Initial State
       +
Events
       =
Current State
```

This is one of the reasons financial institutions love event-driven systems.

---

# Event Naming Rules

Professional systems follow strict naming.

Good:

```text
PriceUpdated

TradeExecuted

RiskCalculated

OrderCancelled

PortfolioChanged
```

Bad:

```text
UpdatePrice

RefreshRisk

DoCalculation

HandlePortfolio
```

Rule:

> Events describe facts, not intentions.

---

# Where Does Kafka Fit?

Our in-memory event bus becomes:

```text
Market Service
       |
       V
Local Event Bus
       |
       V
Panel State
```

Later:

```text
Market Service
       |
       V
Kafka
       |
       V
Workers
       |
       V
Risk Service
       |
       V
Panel
```

Kafka becomes a distributed event bus.

---

# TickerHub Event Architecture

We now have:

```text
                 Event Bus

        ┌────────┬─────────┬─────────┐
        │        │         │         │

        ▼        ▼         ▼         ▼

    Market   Portfolio   Risk    Alert
    Service   Service   Service  Service
        │        │         │         │
        └────────┼─────────┼─────────┘
                 │
                 ▼

              State

                 │

                 ▼

              Panel
```

This is beginning to resemble a professional financial system.

---

# Why Financial Systems Love Events

Because markets themselves are events.

```text
Trade
Quote
Order
News
Earnings
Dividend
Economic Release
Interest Rate Decision
```

A financial terminal is fundamentally:

```text
An Event Processing Machine
```

---

# Architecture Lesson #6

Beginners build:

```python
service_a.call(
    service_b
)
```

Professionals build:

```text
service_a

publishes

Event
```

and allow the system to decide who cares.

That single architectural decision determines whether your application scales from:

```text
100 lines
```

to:

```text
10 million lines.
```

---

# In Part 7

We will build the **Repository Layer**, where you'll discover why professional systems never allow services to talk directly to:

* PostgreSQL,
* Redis,
* Kafka,
* APIs,

and instead communicate through one of the most important patterns in enterprise software:

# The Repository Pattern.
