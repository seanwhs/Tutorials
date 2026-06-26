# Building TickerHub

## Part 8: Building the Market Service — The Heartbeat of the Terminal

> If there is one component that turns TickerHub from a collection of classes into a living system, it is the market service.

Every professional trading terminal revolves around a single question:

> What is happening in the market right now?

The answer to that question drives:

* prices,
* charts,
* portfolios,
* risk,
* alerts,
* news,
* analytics,
* dashboards.

Everything.

---

# The Beginner Architecture

Most beginners build market data like this:

```python
while True:

    price = api.get_price()

    chart.update(price)
```

This works for:

```text
1 symbol
```

Then:

```text
10 symbols
```

Then:

```text
100 symbols
```

Then:

```text
1000 symbols
```

Eventually:

```text
CPU: 100%
Memory: exhausted
UI: frozen
Developer: crying
```

---

# The Professional Architecture

Professional market systems think differently.

Instead of:

```text
UI
   |
   V
Market Feed
```

they build:

```text
Market Feed
      |
      V
Market Service
      |
      V
Event Bus
      |
      V
Application State
      |
      V
UI
```

The market service becomes the single authority for market data.

---

# The Responsibilities of MarketService

Our MarketService must:

* receive market ticks,
* update cache,
* update application state,
* publish events,
* maintain subscriptions,
* handle reconnections,
* validate data,
* manage feed status,
* recover from failures.

That's a lot more than:

```python
price = api.get()
```

---

# Market Service Architecture

```text
                    Market Feed
                          |
                          V

                   MarketService

          ┌──────────┬──────────┬──────────┐
          │          │          │          │

          ▼          ▼          ▼          ▼

      Cache      EventBus    State    Persistence
```

---

# Creating the Service

Create:

```text
services/

    market_service.py
```

---

# Dependencies

Our market service depends upon:

* AppState
* EventBus
* MarketRepository

---

## services/market_service.py

```python
from state.app_state import (
    AppState
)

from events.base import (
    EventBus
)

from repositories.market_repository import (
    MarketRepository
)
```

---

# Building the Constructor

```python
class MarketService:

    def __init__(
        self,
        state: AppState,
        bus: EventBus,
        repository: MarketRepository
    ):

        self.state = state

        self.bus = bus

        self.repository = repository
```

---

# Why Dependency Injection?

Bad:

```python
class MarketService:

    def __init__(self):

        self.redis = Redis()

        self.kafka = Kafka()

        self.database = Postgres()
```

Good:

```python
service = MarketService(

    state,

    bus,

    repository
)
```

Benefits:

* testability,
* replacement,
* mocking,
* flexibility.

---

# Maintaining Symbol Subscriptions

The market service owns subscriptions.

Add:

```python
self.subscriptions = set()
```

---

# Subscribe

```python
def subscribe(
    self,
    symbol
):

    self.subscriptions.add(
        symbol
    )
```

---

# Unsubscribe

```python
def unsubscribe(
    self,
    symbol
):

    self.subscriptions.discard(
        symbol
    )
```

---

Example:

```python
market.subscribe("D05")

market.subscribe("U11")
```

Now:

```text
Subscribed Symbols:

D05
U11
```

---

# Processing a Tick

The heart of the market service:

```python
async def process_tick(
    self,
    tick
):

    ...
```

---

Suppose we receive:

```python
tick = {

    "symbol": "D05",

    "price": 43.15
}
```

---

# Step 1 — Validate

```python
symbol = tick["symbol"]

price = tick["price"]
```

---

Validation:

```python
if price <= 0:

    return
```

---

Why?

Because production systems receive garbage.

Examples:

```text
0

-100

NULL

NaN

999999999
```

Never trust feeds.

---

# Step 2 — Update State

```python
self.state.market.prices[
    symbol
] = price
```

Immediately:

* charts update,
* watchlists update,
* portfolios update.

No direct calls.

---

# Step 3 — Update Cache

```python
await self.repository.set_price(

    symbol,

    price
)
```

This updates:

```text
Redis
```

---

# Step 4 — Publish Event

```python
from events.market_events import (
    PriceUpdated
)
```

---

```python
self.bus.publish(

    PriceUpdated(

        symbol,

        price
    )
)
```

Now:

```text
PortfolioService

RiskService

AlertService

AnalyticsService
```

all receive updates.

---

# Complete Tick Processor

```python
async def process_tick(
    self,
    tick
):

    symbol = tick["symbol"]

    price = tick["price"]

    if price <= 0:

        return

    self.state.market.prices[
        symbol
    ] = price

    await self.repository.set_price(

        symbol,

        price
    )

    self.bus.publish(

        PriceUpdated(
            symbol,
            price
        )
    )
```

---

# What Actually Happened?

One market tick produced:

```text
Market Feed
      |
      V

Market Service
      |
      +----- State
      |
      +----- Redis
      |
      +----- Event Bus
```

This is why the market service is the heart of the system.

---

# Market Feed Status

Professional systems always monitor feed health.

Add:

```python
self.connected = False

self.last_tick = None
```

---

# Connection Events

Create:

```python
@dataclass
class FeedConnected:
    pass


@dataclass
class FeedDisconnected:
    pass
```

---

Example:

```python
self.connected = True

self.bus.publish(
    FeedConnected()
)
```

---

UI:

```text
🟢 LIVE
```

---

Failure:

```python
self.connected = False

self.bus.publish(
    FeedDisconnected()
)
```

UI:

```text
🔴 DISCONNECTED
```

---

# Feed State Machine

Professional feed handlers are state machines.

```text
DISCONNECTED
        |
        V

CONNECTING
        |
        V

CONNECTED
        |
        V

STREAMING
        |
        V

ERROR
        |
        V

RECONNECTING
```

---

Representing State

```python
from enum import Enum


class FeedState(
    Enum
):

    DISCONNECTED = 0

    CONNECTING = 1

    CONNECTED = 2

    STREAMING = 3

    ERROR = 4

    RECONNECTING = 5
```

---

Initialize:

```python
self.feed_state = (
    FeedState.DISCONNECTED
)
```

---

# Why State Machines?

Without them:

```python
if connected:

    if streaming:

        if reconnecting:

            ...
```

Eventually:

```text
Impossible to understand.
```

State machines prevent illegal transitions.

---

# Detecting Stale Feeds

Professional systems monitor heartbeat.

Example:

```python
from datetime import datetime


self.last_tick = datetime.now()
```

---

Check:

```python
if (
    datetime.now()
    - self.last_tick
).seconds > 5:

    raise FeedTimeout()
```

---

This allows:

```text
Market Feed
       |
dies silently
       |
TickerHub notices
       |
Reconnects
```

---

# Batch Processing

Real feeds produce:

```text
100,000+
ticks/sec
```

Updating UI every tick is impossible.

Instead:

```text
Tick
Tick
Tick
Tick
Tick
      |
      V

Batch
      |
      V

Update UI
```

---

Example:

```python
async def process_batch(
    self,
    ticks
):

    for tick in ticks:

        await self.process_tick(
            tick
        )
```

---

Later:

```python
await asyncio.gather(
    *tasks
)
```

for concurrency.

---

# Tick Deduplication

Exchanges sometimes repeat ticks.

Example:

```text
43.15
43.15
43.15
43.15
```

Store:

```python
self.last_prices = {}
```

---

Check:

```python
if self.last_prices.get(
    symbol
) == price:

    return
```

---

Benefits:

* less CPU,
* less network,
* less UI refresh.

---

# Market Data Snapshot

Sometimes clients reconnect.

Instead of replaying millions of events:

```text
Event
Event
Event
Event
Event
```

we send:

```text
Snapshot
```

Example:

```python
def snapshot(self):

    return dict(

        self.state.market.prices
    )
```

---

# Market Service Metrics

Professional systems measure everything.

Example:

```python
self.tick_count = 0

self.dropped_ticks = 0

self.latency = 0
```

---

Dashboard:

```text
Feed Rate:

35,212 ticks/sec


Dropped:

0


Latency:

4ms
```

---

# Error Isolation

Bad:

```python
process_tick()

crash
```

Good:

```python
try:

    await process_tick()

except Exception:

    log()
```

One bad tick should never stop the feed.

---

# Testing MarketService

Because of dependency injection:

```python
market = MarketService(

    mock_state,

    mock_bus,

    mock_repo
)
```

Now test:

```python
await market.process_tick(
    tick
)
```

without:

* Redis,
* PostgreSQL,
* Kafka,
* Panel.

---

# The Real Architecture

Our market service now looks like:

```text
                    Market Feed
                          |
                          V

                   MarketService

                          |
      ┌──────────┬────────┼────────┬──────────┐
      │          │        │        │          │

      ▼          ▼        ▼        ▼          ▼

   State      Redis    Events   Metrics   Snapshot
```

Notice something.

The actual business logic:

```python
price = tick["price"]
```

is perhaps:

```text
5%
```

of the code.

The remaining:

```text
95%
```

is engineering.

This is why enterprise systems are hard.

---

# Architecture Lesson #8

Beginners think:

```text
Market Feed
      ↓
Price
```

Professionals think:

```text
Market Feed
      ↓
Validation
      ↓
State Machine
      ↓
Caching
      ↓
Events
      ↓
State
      ↓
Metrics
      ↓
Recovery
      ↓
Observability
```

Because production systems don't fail due to business logic.

They fail due to everything around the business logic.

---

# Current Architecture

```text
Panel UI
     |
     V
State Engine
     |
     V
Services
     |
     +------ MarketService
     |
     V
Event Bus
     |
     V
Repositories
     |
     V
Redis
Kafka
PostgreSQL
```

TickerHub is finally becoming alive.

---

# In Part 9

We will build the **PortfolioService**, where you'll discover that:

```text
Portfolio
```

is not a table,

not a widget,

and not a database row.

It is actually a continuously recomputed mathematical model driven entirely by market events.
