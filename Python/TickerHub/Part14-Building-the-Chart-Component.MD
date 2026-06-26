# Building TickerHub

## Part 14: Building the Chart Component — Streaming Time-Series as a First-Class System

> Most developers think charts are visualizations.
>
> Professional trading systems know that charts are really:
>
> **Real-time time-series databases with a graphical representation.**

When traders look at a chart, they are not looking at pixels.

They are looking at:

* history,
* trends,
* volatility,
* momentum,
* liquidity,
* market structure.

This means that a chart component is fundamentally a:

```text
Streaming Analytics Engine
```

that happens to render graphics.

---

# The Beginner Chart

Most tutorials build charts like this:

```python
plot(data)
```

Later:

```python
plot(new_data)
```

Or worse:

```python
while True:

    chart.update(
        new_data
    )
```

This works.

Until:

```text
100 ticks/sec
```

becomes:

```text
10,000 ticks/sec
```

Then:

```text
CPU = 100%

Memory = exploding

UI = frozen
```

---

# The Professional Architecture

Professional systems separate:

```text
Market Data
```

from:

```text
Chart Data
```

Architecture:

```text
Market Feed
      |
      V

MarketState
      |
      V

Chart Engine
      |
      V

Time-Series Buffer
      |
      V

Chart Renderer
```

---

# Why Separate Them?

Because market data arrives:

```text
1000/sec
```

while displays update:

```text
30/sec
```

These are fundamentally different workloads.

---

# Creating the Component

Create:

```text
components/

    charts/

        __init__.py

        chart.py
```

---

# Imports

```python
import panel as pn
import pandas as pd
import param
import hvplot.pandas
from collections import deque
from datetime import datetime
```

---

# Why HoloViews?

Professional Panel applications typically use:

* HoloViews
* hvPlot
* Bokeh

because they support:

* streaming,
* dynamic updates,
* WebSocket transport,
* server-side rendering.

---

# Creating the Chart Class

```python
class ChartComponent(

    param.Parameterized
):
```

---

# Parameters

```python
symbol = param.String()

window = param.Integer(
    default=500
)
```

---

# Constructor

```python
def __init__(

    self,

    state,

    **params
):

    super().__init__(
        **params
    )

    self.state = state
```

---

# The First Important Decision

Never store chart history as:

```python
list()
```

Use:

```python
deque()
```

instead.

---

# Why?

Bad:

```python
history = []
```

Appending:

```python
history.append()
```

Removing:

```python
history.pop(0)
```

is:

```text
O(n)
```

---

Good:

```python
history = deque(
    maxlen=500
)
```

Removing becomes:

```text
O(1)
```

---

# Creating the Buffer

```python
self.history = deque(

    maxlen=self.window
)
```

---

# Example

```text
10:00  42.1
10:01  42.3
10:02  42.4
10:03  42.0
```

---

# Listening to Market Updates

Register:

```python
self.state.market.param.watch(

    self.on_market,

    "prices"
)
```

---

# Event Handler

```python
def on_market(

    self,

    event
):
```

---

Get price:

```python
price = (

    event.new
    .get(
        self.symbol
    )
)
```

---

Skip if absent:

```python
if price is None:

    return
```

---

Append:

```python
self.history.append({

    "time":
        datetime.now(),

    "price":
        price
})
```

---

# The Chart Buffer

After a few updates:

```text
09:30  42.1
09:31  42.2
09:32  42.5
09:33  42.0
09:34  42.7
```

---

# Converting to DataFrame

Create:

```python
def dataframe(
    self
):
```

Return:

```python
return pd.DataFrame(

    self.history
)
```

---

# Building the Chart

```python
def chart(
    self
):
```

---

Get data:

```python
df = self.dataframe()
```

---

Return:

```python
return df.hvplot.line(

    x="time",

    y="price",

    responsive=True,

    height=500
)
```

---

# First Result

```text
      ^
Price |
      |
      |        *
      |      *
      |   *
      | *
      +-------------->

             Time
```

Congratulations.

You have built:

```text
The World's Simplest
Market Chart.
```

---

# Why This Is Still Wrong

Because:

```text
1000 ticks/sec
```

will cause:

```text
1000 redraws/sec
```

This is impossible.

---

# Enter Decimation

Instead of:

```text
1000 updates/sec
```

we display:

```text
10 updates/sec
```

---

Create:

```python
self.dirty = False
```

---

When price arrives:

```python
self.dirty = True
```

---

Refresh periodically:

```python
pn.state.add_periodic_callback(

    self.render,

    100
)
```

---

Only redraw:

```python
if self.dirty:

    update()
```

---

Now:

```text
Feed:

1000/sec

Chart:

10/sec
```

Perfect.

---

# Candlestick Charts

Professional charts rarely display ticks.

They display:

```text
OHLC
```

---

Example:

```text
Open
High
Low
Close
```

---

Suppose:

```text
42.0
42.5
41.9
42.3
```

This becomes:

```text
1 candle
```

---

# Aggregating Ticks

Store:

```python
self.current_bar = {

    "open": None,

    "high": None,

    "low": None,

    "close": None
}
```

---

First tick:

```python
open = price
```

---

Update:

```python
high = max(
    high,
    price
)
```

---

Update:

```python
low = min(
    low,
    price
)
```

---

Last tick:

```python
close = price
```

---

# Time Windows

Professional charts aggregate by:

```text
1 second

5 seconds

1 minute

5 minutes

15 minutes

1 hour

1 day
```

---

Example:

```python
bucket = (

    timestamp
    .replace(
        second=0
    )
)
```

---

All ticks inside:

```text
09:30:00
```

produce:

```text
One Candle
```

---

# Multiple Timeframes

Store:

```python
self.series = {

    "1s": deque(),

    "1m": deque(),

    "5m": deque(),

    "1h": deque()
}
```

---

Now:

```text
One Feed
```

produces:

```text
Many Charts
```

simultaneously.

---

# Technical Indicators

Professional terminals compute:

* SMA
* EMA
* RSI
* MACD
* Bollinger Bands
* VWAP

---

Example:

Simple moving average:

```python
df["sma"] = (

    df["price"]

    .rolling(20)

    .mean()
)
```

---

Result:

```text
Price

SMA20
```

---

# Exponential Moving Average

```python
df["ema"] = (

    df["price"]

    .ewm(
        span=20
    )

    .mean()
)
```

---

# Relative Strength Index

```python
RSI
```

measures:

```text
Momentum
```

between:

```text
0
```

and:

```text
100
```

---

# Volume Bars

Store:

```python
{
    "price": 42,

    "volume": 10000
}
```

---

Display:

```text
Price

+

Volume
```

---

# Why Volume Matters

Price tells you:

```text
What happened.
```

Volume tells you:

```text
Whether anyone cared.
```

---

# Chart Synchronization

Suppose the user clicks:

```text
D05
```

in the watchlist.

The chart must change.

---

Connect:

```python
watchlist.selected
```

to:

```python
chart.symbol
```

---

Example:

```python
chart.symbol = (

    watchlist.selected
)
```

---

Immediately:

```text
Chart reloads.
```

---

# Historical Data

When the symbol changes:

```text
D05

↓

U11
```

load history:

```python
history = (

    repository
    .load_prices(
        "U11"
    )
)
```

---

Then:

```python
self.history = deque(
    history
)
```

---

# Live + Historical Merge

Professional systems combine:

```text
Historical Database
```

with:

```text
Live Feed
```

---

Architecture:

```text
Historical Data
          |
          V

      Chart Buffer

          ^
          |

      Live Feed
```

---

# Windowing

Never store:

```text
All History
```

Instead:

```text
Last:

100
500
1000
5000
```

points.

---

Example:

```python
deque(
    maxlen=500
)
```

This prevents:

```text
Memory Explosion
```

---

# Chart Cache

Cache:

```python
chart_cache = {

    "D05":
        history,

    "U11":
        history
}
```

---

Why?

Because:

```text
Loading from database
```

is expensive.

---

# Chart Event Flow

Suppose:

```text
DBS updates
```

The system executes:

```text
Feed Worker
      |
      V

MarketService
      |
      V

MarketState
      |
      V

Chart Buffer
      |
      V

Renderer
      |
      V

Screen
```

Again:

```text
No polling.

No callbacks.

No REST APIs.
```

---

# The Real Chart Architecture

```text
Market Feed
      |
      V

MarketState
      |
      V

Chart Engine
      |
      +------ Buffers
      |
      +------ Aggregation
      |
      +------ Indicators
      |
      +------ Caching
      |
      +------ Windowing
      |
      +------ Rendering
```

---

# Why Bloomberg Charts Feel Instant

Because they are not:

```text
Graphs
```

They are:

```text
Streaming Time-Series Databases
```

with a visualization layer attached.

---

# Architecture Lesson #14

Beginners think:

```text
Chart
     =
Line Graph
```

Professionals think:

```text
Chart
     =
Streaming
Time-Series
Processing Engine
```

The graph itself is merely the final output.

---

# Current Architecture

```text
Feed Worker
      |
      V

Market Service
      |
      V

Portfolio Service
      |
      V

Risk Service
      |
      V

Application State
      |
      ├──── Watchlist
      |
      └──── Chart
```

TickerHub now has:

✅ Live market data

✅ Live watchlist

✅ Live charting

We finally have something that resembles a professional trading terminal.

---

# In Part 15

We will build the **Order Book Component**, where you'll discover that an order book is not:

```text
A table of bids and asks
```

but rather:

```text
A continuously mutating
distributed market microstructure model
rendered as a table.
```
