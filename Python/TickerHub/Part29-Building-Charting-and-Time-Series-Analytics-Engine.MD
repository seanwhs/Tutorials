# Building TickerHub

## Part 29: Building the Professional Charting & Time-Series Analytics Engine — Exploring the Temporal Structure of Financial Reality

> Traders do not look at charts to see prices.
>
> Traders look at charts to see:
>
> ```text
> Time
> ```
>
> because markets are not collections of numbers.
>
> Markets are:
>
> ```text
> Time-Evolving Systems
> ```

At this point, TickerHub has:

* market feeds,
* order management,
* portfolio management,
* risk management,
* reactive state,
* professional UI components.

But there is still one component missing from every serious trading terminal:

```text
Charts
```

Ironically, charts are one of the most misunderstood parts of financial software.

Most people think charts display:

```text
Prices
```

Professional traders understand charts display:

```text
Behavior Through Time
```

---

# The Beginner Chart

Most tutorials build charts like this:

```python
plt.plot(prices)
```

Or:

```python
df.plot()
```

This works.

Until:

* millions of ticks,
* multiple timeframes,
* indicators,
* overlays,
* streaming data,
* synchronized charts,
* replay systems,
* historical analysis.

Then:

```text
Charting
```

becomes:

```text
Time-Series Database Visualization
```

---

# Professional Chart Architecture

Professional terminals separate:

```text
Storage

↓

Aggregation

↓

Indicators

↓

Rendering

↓

Interaction
```

---

# TickerHub Chart Pipeline

```text
Market Feed
       |
       V

Tick Store
       |
       V

OHLC Engine
       |
       V

Indicator Engine
       |
       V

Chart Engine
       |
       V

Panel Component
```

---

# Why Separate Layers?

Because:

```text
Raw Ticks
```

and:

```text
Charts
```

are different things.

Example:

```text
10,000 ticks/sec
```

may become:

```text
1 candle/minute
```

---

# Tick Model

Create:

```text
domain/

    tick.py
```

---

```python
from dataclasses import dataclass
from datetime import datetime
```

---

```python
@dataclass
class Tick:

    symbol: str

    price: float

    volume: int

    timestamp: datetime
```

---

# Candle Model

Create:

```text
domain/

    candle.py
```

---

```python
@dataclass
class Candle:

    timestamp: datetime

    open: float

    high: float

    low: float

    close: float

    volume: int
```

---

# Why Candles?

Because humans cannot interpret:

```text
10 million ticks
```

But humans can interpret:

```text
Aggregated Behavior
```

---

# Example Tick Stream

```text
09:00:01 40
09:00:02 41
09:00:05 39
09:00:08 42
09:00:59 41
```

---

Convert to:

```text
Open  = 40
High  = 42
Low   = 39
Close = 41
```

---

Result:

```text
One Candle
```

---

# OHLC Engine

Create:

```text
services/

    candle_service.py
```

---

Initialize:

```python
class CandleService:
```

---

Maintain:

```python
self.current = {}
```

---

Receive:

```python
async def process_tick(
    self,
    tick
):
```

---

Compute:

```text
Open

High

Low

Close

Volume
```

---

Publish:

```text
CandleCreated
```

events.

---

# Timeframes

Professional terminals support:

```text
1 second

5 seconds

1 minute

5 minute

15 minute

1 hour

1 day
```

---

Example:

```text
Tick

↓

1s Candle

↓

1m Candle

↓

1h Candle
```

---

# Why Multiple Timeframes?

Because:

```text
Investors
```

see:

```text
Years
```

while:

```text
Traders
```

see:

```text
Milliseconds
```

---

# Time-Series Storage

Create:

```text
repositories/

    market_history.py
```

---

Store:

```text
Symbol

Timestamp

Price

Volume
```

---

Example:

```sql
CREATE TABLE ticks
(
    symbol TEXT,

    ts TIMESTAMP,

    price FLOAT,

    volume INT
)
```

---

# Partitioning

Never store:

```text
10 years
```

in one table.

---

Instead:

```text
ticks_2026_06

ticks_2026_07

ticks_2026_08
```

---

# Why Partition?

Because:

```text
Time
```

is the primary query dimension.

---

# Chart State

Create:

```text
state/

    chart_state.py
```

---

```python
class ChartState(
    param.Parameterized
):
```

---

Store:

```python
symbol = param.String()
```

---

Store:

```python
timeframe = param.String()
```

---

Store:

```python
candles = param.List()
```

---

Store:

```python
indicators = param.Dict()
```

---

# Professional Chart Component

Create:

```text
components/

    charts/
```

---

Initialize:

```python
class TradingChart:
```

---

Create:

```python
self.symbol = (
    pn.widgets.Select()
)
```

---

Create:

```python
self.timeframe = (
    pn.widgets.Select()
)
```

---

Observe:

```python
chart_state.param.watch(
```

---

Update:

```python
self.redraw
```

---

# Candlestick Chart

Display:

```text
Open

High

Low

Close
```

---

Example:

```text
     |
     |
  ┌──┴──┐
  │     │
  └─────┘
     |
```

---

# Why Candlesticks?

Because they encode:

```text
Price

+

Direction

+

Volatility

+

Range
```

in a single visual object.

---

# Volume Bars

Display:

```text
Price
```

together with:

```text
Volume
```

---

Example:

```text
Price
------
||||||
|||||||
||||

Volume
```

---

# Moving Average

Formula:

```text
Average(
    Last N Prices
)
```

---

Example:

```python
df["ma20"] = (
    df.close
    .rolling(20)
    .mean()
)
```

---

# Why Moving Averages?

Because traders seek:

```text
Trend
```

rather than:

```text
Noise
```

---

# Exponential Moving Average

Formula:

```text
Recent Prices

>

Older Prices
```

---

Example:

```python
df["ema"] = (
    df.close
    .ewm()
    .mean()
)
```

---

# Bollinger Bands

Compute:

```text
Moving Average

±

Standard Deviation
```

---

Result:

```text
Upper Band

Middle Band

Lower Band
```

---

Purpose:

```text
Volatility Visualization
```

---

# Relative Strength Index (RSI)

Question:

```text
How overbought
or oversold
is the market?
```

---

Range:

```text
0

↓

100
```

---

Example:

```text
RSI > 70
```

means:

```text
Potentially Overbought
```

---

Example:

```text
RSI < 30
```

means:

```text
Potentially Oversold
```

---

# MACD

Compute:

```text
Fast EMA

-

Slow EMA
```

---

Display:

```text
Trend Momentum
```

---

# VWAP

Formula:

```text
Price × Volume

----------------

Volume
```

---

Purpose:

```text
Institutional Benchmark
```

---

# Order Book Overlay

Display:

```text
Bid Levels

Ask Levels
```

---

Example:

```text
ASK 41.10

ASK 41.05

PRICE

BID 40.95

BID 40.90
```

---

# Trade Overlay

Display:

```text
BUY
```

and:

```text
SELL
```

events.

---

Example:

```text
▲ BUY

▼ SELL
```

---

# Portfolio Overlay

Show:

```text
Entry Price
```

---

Example:

```text
BUY
      |
      V

-----X-------
```

---

Display:

```text
PnL
```

since entry.

---

# Risk Overlay

Display:

```text
Stop Loss
```

---

Display:

```text
Take Profit
```

---

Display:

```text
Margin Levels
```

---

# News Overlay

Display:

```text
News Events
```

---

Example:

```text
Earnings

Fed Announcement

Market Halt
```

---

# Time Synchronization

Professional terminals synchronize:

```text
Charts

News

Trades

Orders
```

---

Example:

```text
10:15:31

↓

Price Spike

↓

News Release
```

---

# Crosshair Synchronization

Suppose:

```text
Chart A
```

moves.

---

Automatically update:

```text
Chart B

Chart C

Chart D
```

---

# Zooming

Load:

```text
1 Day
```

---

Zoom:

```text
1 Hour
```

---

Zoom:

```text
1 Minute
```

---

Without:

```text
Reloading Everything
```

---

# Historical Replay

Professional systems support:

```text
Market Replay
```

---

Example:

```text
Flash Crash

↓

Replay Timeline

↓

Observe Behavior
```

---

# Replay Architecture

```text
Historical DB
        |
        V

Replay Engine
        |
        V

Kafka
        |
        V

Panel
```

---

# Streaming Charts

Suppose:

```text
1000 ticks/sec
```

arrive.

---

Do not redraw:

```text
1000 times/sec
```

---

Instead:

```text
Buffer
```

---

Then:

```text
Render
```

at:

```text
10 FPS
```

---

# Chart Cache

Store:

```text
OHLC
```

inside:

```text
Redis
```

---

Example:

```text
D05:1m

D05:5m

D05:1h
```

---

# GPU Acceleration

Professional terminals often use:

```text
GPU Rendering
```

for:

```text
Millions
of points
```

---

# Chart Event Flow

Suppose:

```text
Price Tick
```

arrives.

---

Flow:

```text
Market Feed
        |
        V

Kafka
        |
        V

Tick Store
        |
        V

OHLC Engine
        |
        V

Indicators
        |
        V

Chart State
        |
        V

Panel Chart
```

---

# Why Professional Charting Is Difficult

Because charts are not:

```text
Pictures
```

Charts are:

```text
Interactive Visual Databases
for Exploring
Time-Evolving Systems
```

---

# Architecture Lesson #29

Beginners think:

```text
Chart
   =
Graph
```

Professionals think:

```text
Chart
   =
Interactive
Time-Series
Analytics Engine
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

Tick Store
        |
        V

OHLC Engine
        |
        V

Indicator Engine
        |
        V

Chart State
        |
        +------ Charts
        |
        +------ Portfolio
        |
        +------ Risk
        |
        +------ Orders
        |
        V

Panel UI
```

TickerHub now contains:

✅ Tick storage

✅ OHLC aggregation

✅ Multi-timeframe charts

✅ Technical indicators

✅ Trade overlays

✅ Portfolio overlays

✅ Risk overlays

✅ Historical replay

✅ Streaming charts

✅ Chart synchronization

✅ Time-series analytics

At this point, TickerHub no longer resembles a charting application.

It resembles:

```text
A Real-Time Temporal Analytics Platform
capable of exploring
the evolution
of financial reality
through time.
```

---

# In Part 30

We will build the **Market Microstructure & Order Book Engine**, where you'll discover that financial markets are not:

```text
Price Charts
```

but rather:

```text
Continuous auctions
executed by
distributed matching systems.
```
