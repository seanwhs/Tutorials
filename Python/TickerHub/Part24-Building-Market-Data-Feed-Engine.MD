# Building TickerHub

## Part 24: Building the Market Data Feed Engine — Creating a Real-Time Market Data Acquisition Platform

> Traders do not buy terminals.
>
> They buy data.

Everything we have built so far:

* the Panel UI,
* the portfolio engine,
* the risk engine,
* the event backbone,
* the Redis state layer,
* the PostgreSQL event store,

is worthless without one thing:

```text
Market Data
```

In fact, most professional trading terminals are fundamentally:

```text
Market Data Distribution Systems
```

with analytics and visualization attached.

---

# The Beginner View of Market Data

Most tutorials treat market data as:

```python
price = requests.get(
    "/price"
)
```

or:

```python
while True:

    price = get_price()

    update_chart(price)
```

This works.

Until:

* thousands of symbols,
* multiple exchanges,
* multiple asset classes,
* network failures,
* stale ticks,
* out-of-order messages,
* duplicate events.

Then:

```text
API Consumption
```

becomes:

```text
Market Data Engineering
```

---

# What Is a Market Feed?

A market feed is a continuously flowing stream of:

```text
Trades

Quotes

Order Books

News

Reference Data

Corporate Actions
```

---

# Professional Market Data Architecture

```text
Exchanges
      |
      V

Feed Handlers
      |
      V

Normalization
      |
      V

Validation
      |
      V

Kafka
      |
      V

Services
      |
      V

Redis
      |
      V

Panel
```

Notice:

```text
UI
```

never talks to:

```text
Exchange APIs
```

directly.

---

# Example Data Sources

TickerHub MVP can support:

```text
Yahoo Finance

Alpha Vantage

Polygon

TwelveData

IEX

Binance

CoinGecko

SGX
```

Later:

```text
Bloomberg BPIPE

Refinitiv Elektron

ICE

NASDAQ TotalView
```

---

# Why Feed Handlers Exist

Every provider sends:

```text
Different Formats
```

Example:

Provider A:

```json
{
    "ticker":"D05",
    "price":42.1
}
```

---

Provider B:

```json
{
    "symbol":"D05",
    "last":42.1
}
```

---

Provider C:

```json
{
    "ric":"D05.SI",
    "trade_price":42.1
}
```

---

Your application cannot consume:

```text
Everything
```

directly.

Instead:

```text
Normalize
Everything
```

---

# Feed Architecture

```text
Provider
     |
     V

Feed Adapter
     |
     V

Normalized Tick
     |
     V

Kafka
```

---

# Domain Model

Create:

```text
domain/

    market_tick.py
```

---

```python
from dataclasses import dataclass
from datetime import datetime
```

---

```python
@dataclass
class MarketTick:

    symbol: str

    price: float

    volume: int

    exchange: str

    timestamp: datetime
```

---

# Example

Regardless of source:

```python
MarketTick(

    symbol="D05",

    price=42.10,

    volume=10000,

    exchange="SGX",

    timestamp=now()
)
```

---

# Feed Handler Interface

Create:

```text
services/

    feeds/

        base.py
```

---

```python
from abc import ABC
from abc import abstractmethod
```

---

```python
class FeedHandler(ABC):

    @abstractmethod
    async def connect(self):
        pass

    @abstractmethod
    async def subscribe(
        self,
        symbols
    ):
        pass

    @abstractmethod
    async def stream(self):
        pass
```

---

# Example Yahoo Feed

Create:

```text
services/

    feeds/

        yahoo_feed.py
```

---

```python
class YahooFeed(

    FeedHandler
):
```

---

Connect:

```python
async def connect(self):

    self.session = (
        aiohttp.ClientSession()
    )
```

---

Subscribe:

```python
async def subscribe(
    self,
    symbols
):
    self.symbols = symbols
```

---

# Stream

Example:

```python
async def stream(self):

    while True:

        for symbol in self.symbols:
```

---

Generate:

```python
yield MarketTick(

    symbol=symbol,

    price=random(),

    volume=random(),

    exchange="SGX",

    timestamp=now()
)
```

---

# Feed Worker

Create:

```text
workers/

    feed_worker.py
```

---

Initialize:

```python
feed = YahooFeed()
```

---

Connect:

```python
await feed.connect()
```

---

Subscribe:

```python
await feed.subscribe(

    [
        "D05",
        "U11",
        "C6L"
    ]
)
```

---

Consume:

```python
async for tick in feed.stream():
```

---

Publish:

```python
await kafka.publish(
    tick
)
```

---

# Why Workers?

Because market feeds never stop.

---

Professional architecture:

```text
Feed Worker
     |
     V

Kafka
```

rather than:

```text
UI
     |
     V

Exchange
```

---

# Tick Validation

Professional systems validate every tick.

---

Example:

```python
if tick.price <= 0:
```

Reject.

---

Example:

```python
if tick.volume < 0:
```

Reject.

---

Example:

```python
if tick.timestamp > now():
```

Reject.

---

# Duplicate Detection

Suppose:

```text
42.10

42.10

42.10

42.10
```

arrive.

---

Store:

```python
last_tick[symbol]
```

---

Check:

```python
if tick == last_tick:
```

Ignore.

---

# Sequence Numbers

Professional exchanges send:

```text
1
2
3
4
5
```

---

Suppose:

```text
1
2
4
5
```

arrive.

---

Then:

```text
Sequence 3
Missing
```

---

Raise:

```text
Feed Gap Alert
```

---

# Timestamp Normalization

Exchange:

```text
09:30:00.123456789
```

Convert:

```python
datetime.utcnow()
```

format.

---

# Symbol Normalization

Exchange A:

```text
D05
```

---

Exchange B:

```text
D05.SI
```

---

Exchange C:

```text
DBS
```

---

Map:

```text
All

↓

D05
```

---

# Reference Data

Create:

```text
reference/

    symbols.json
```

---

Example:

```json
{
    "D05": {
        "name":"DBS",
        "exchange":"SGX"
    }
}
```

---

# Corporate Actions

Professional systems adjust for:

```text
Stock Splits

Dividends

Rights Issues

Mergers
```

---

Example:

```text
2:1 split
```

---

Convert:

```text
100 shares

↓

200 shares
```

---

# Feed Multiplexing

Suppose:

```text
Yahoo
Polygon
Binance
```

all publish.

---

Architecture:

```text
Yahoo
     |

Polygon
     |------ Feed Engine
     |

Binance
```

---

Output:

```text
Unified Tick Stream
```

---

# Feed Priorities

Example:

```text
Bloomberg
    =
Priority 1

Yahoo
    =
Priority 2
```

---

If Bloomberg fails:

```text
Fallback
```

to:

```text
Yahoo
```

---

# Market Sessions

Markets have states.

---

Example:

```text
PREOPEN

OPEN

LUNCH

CLOSE

AFTERHOURS
```

---

Create:

```python
class MarketSession:

    status = "OPEN"
```

---

# Trading Calendar

Store:

```text
Holidays

Half Days

Closures
```

---

Example:

```python
if today in holidays:

    market_closed()
```

---

# Tick Aggregation

Convert:

```text
Thousands of ticks
```

into:

```text
OHLC bars
```

---

Example:

```python
bar = {

    "open":40,

    "high":42,

    "low":39,

    "close":41
}
```

---

# Candlestick Generator

Create:

```text
workers/

    candle_worker.py
```

---

Input:

```text
Ticks
```

---

Output:

```text
1m candles

5m candles

15m candles

1h candles
```

---

# Order Book Feed

Professional feeds include:

```text
Bid

Ask

Depth
```

---

Example:

```json
{
    "bids":[
        [42.0,1000]
    ],

    "asks":[
        [42.1,500]
    ]
}
```

---

# Market Depth

Example:

```text
42.00  1000

41.99  2000

41.98  3000
```

---

# Throughput Monitoring

Track:

```text
Ticks/sec

Latency

Dropped Ticks

Duplicates

Feed Gaps
```

---

Example:

```text
Feed Rate:

35000/sec
```

---

Example:

```text
Latency:

3ms
```

---

# Feed Recovery

Suppose:

```text
Connection Lost
```

---

Reconnect:

```python
while True:

    try:

        connect()

        break

    except:

        sleep()
```

---

# Circuit Breaker

Suppose:

```text
Feed fails
```

---

Switch:

```text
Primary

↓

Secondary
```

feed automatically.

---

# Feed Event Flow

Suppose:

```text
DBS

42

↓

43
```

The system executes:

```text
Exchange
      |
      V

Feed Handler
      |
      V

Normalizer
      |
      V

Validator
      |
      V

Kafka
      |
      V

Services
      |
      V

Redis
      |
      V

Panel
```

---

# The Real Feed Architecture

```text
Feed Engine
      |
      +------ Adapters
      |
      +------ Validation
      |
      +------ Normalization
      |
      +------ Recovery
      |
      +------ Multiplexing
      |
      +------ Monitoring
      |
      +------ Aggregation
      |
      +------ Distribution
```

---

# Why Bloomberg Feels Fast

Because Bloomberg does not:

```text
Query APIs.
```

Bloomberg:

```text
Acquires

Normalizes

Caches

Distributes

Synchronizes

Monitors

Repairs

Market Data
```

continuously.

---

# Architecture Lesson #24

Beginners think:

```text
Trading Terminal
      =
API Consumer
```

Professionals think:

```text
Trading Terminal
      =
Market Data
Distribution Platform
```

The charts are merely one consumer of that platform.

---

# Current Architecture

```text
Exchange Feeds
      |
      V

Feed Engine
      |
      V

Kafka Event Backbone
      |
      V

Services
      |
      +------ Market
      |
      +------ Portfolio
      |
      +------ Risk
      |
      +------ News
      |
      +------ Alerts
      |
      +------ Analytics
      |
      V

Redis State Layer
      |
      V

Panel UI
```

TickerHub now contains:

✅ Feed handlers

✅ Feed normalization

✅ Tick validation

✅ Sequence tracking

✅ Gap detection

✅ Symbol mapping

✅ Feed multiplexing

✅ Failover feeds

✅ Candlestick generation

✅ Order book ingestion

At this point, TickerHub no longer resembles a dashboard framework or a web application.

It resembles:

```text
A Real-Time Market Data Operating System
capable of acquiring, transforming,
and distributing financial reality.
```

---

# In Part 25

We will build the **Order Management System (OMS)**, where you'll discover that professional trading systems are not:

```text
Applications that submit orders
```

but rather:

```text
Distributed state machines
that govern the lifecycle
of financial intent.
```
