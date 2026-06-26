# Building TickerHub

## Part 15: Building the Order Book Component — Visualizing Market Microstructure

> Most people think an order book is a table.
>
> Traders know an order book is the market itself.

When you buy a stock, you don't buy it from "the exchange."

You buy it from:

```text
Someone willing to sell.
```

And when you sell a stock, you don't sell it to "the market."

You sell it to:

```text
Someone willing to buy.
```

The order book is the real-time representation of this supply and demand.

Professional traders spend more time watching order books than charts because:

```text
Charts show the past.

Order books show the present.
```

---

# The Beginner Order Book

Most tutorials build order books like this:

```python
bids = [
    [42.10, 100],
    [42.09, 200]
]

asks = [
    [42.11, 100],
    [42.12, 300]
]
```

Then:

```python
table.value = bids + asks
```

This works.

Until:

* updates arrive thousands of times per second,
* prices disappear,
* orders move,
* quantities change,
* users switch symbols,
* market depth grows.

Then:

```text
Table UI
```

becomes:

```text
Real-Time State Synchronization Problem
```

---

# What Is an Order Book?

An order book is a continuously mutating data structure:

```text
BUY SIDE

42.10    1000
42.09    2000
42.08     500

----------------

42.11    1200
42.12    1800
42.13     300

SELL SIDE
```

Each price level represents:

```text
Price

+

Aggregated Quantity

+

Queue Position
```

---

# Order Book Architecture

```text
Exchange Feed
        |
        V

Feed Worker
        |
        V

MarketService
        |
        V

MarketState
        |
        V

OrderBook Component
        |
        V

Panel UI
```

Again:

```text
The UI never talks
to the exchange.
```

---

# Creating the Component

Create:

```text
components/

    orderbook/

        __init__.py

        orderbook.py
```

---

# Imports

```python
import panel as pn
import pandas as pd
import param
```

---

# Creating the Component

```python
class OrderBook(

    param.Parameterized
):
```

---

# Parameters

```python
symbol = param.String()

depth = param.Integer(
    default=10
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

# Internal Order Book

Store:

```python
self.bids = {}

self.asks = {}
```

Example:

```python
bids = {

    42.10: 1000,

    42.09: 2000,

    42.08: 500
}
```

---

# Why Dictionaries?

Because updates are:

```text
Price Level
    →
Replace Quantity
```

Example:

```python
bids[42.10] = 3000
```

This is:

```text
O(1)
```

operations.

---

# Market State Subscription

Register:

```python
self.state.market.param.watch(

    self.on_orderbook,

    "orderbooks"
)
```

---

# Receiving Updates

Example:

```python
{
    "symbol": "D05",

    "bids": [

        [42.10, 1000],

        [42.09, 2000]
    ],

    "asks": [

        [42.11, 500],

        [42.12, 700]
    ]
}
```

---

# Handler

```python
def on_orderbook(

    self,

    event
):
```

---

Load:

```python
book = (

    event.new
    .get(
        self.symbol
    )
)
```

---

Skip:

```python
if book is None:

    return
```

---

Update bids:

```python
for price, qty in book["bids"]:

    self.bids[
        price
    ] = qty
```

---

Update asks:

```python
for price, qty in book["asks"]:

    self.asks[
        price
    ] = qty
```

---

# The Hidden Problem

Suppose:

```text
42.10
```

disappears.

The exchange sends:

```python
[
    [42.10, 0]
]
```

This means:

```text
DELETE
```

not:

```text
SET TO ZERO
```

---

Handle deletes:

```python
if qty == 0:

    self.bids.pop(
        price,
        None
    )
```

---

Likewise:

```python
if qty == 0:

    self.asks.pop(
        price,
        None
    )
```

---

# Sorting

Order books are ordered.

Bids:

```text
Highest First
```

Asks:

```text
Lowest First
```

---

Example:

```python
bids = sorted(

    self.bids.items(),

    reverse=True
)
```

---

Example:

```python
asks = sorted(

    self.asks.items()
)
```

---

# Limiting Depth

Professional terminals usually show:

```text
Top 5

Top 10

Top 20
```

levels.

Example:

```python
bids = bids[
    :self.depth
]
```

---

# Building the Table

Create:

```python
rows = []
```

---

Add bids:

```python
for price, qty in bids:

    rows.append({

        "Side": "Bid",

        "Price": price,

        "Quantity": qty
    })
```

---

Separator:

```python
rows.append({

    "Side": "",

    "Price": "",

    "Quantity": ""
})
```

---

Add asks:

```python
for price, qty in asks:

    rows.append({

        "Side": "Ask",

        "Price": price,

        "Quantity": qty
    })
```

---

Convert:

```python
df = pd.DataFrame(
    rows
)
```

---

Render:

```python
self.table.value = df
```

---

# First Result

```text
------------------------
Bid  42.10     1000
Bid  42.09     2000
Bid  42.08      500
------------------------
Ask  42.11      500
Ask  42.12      700
Ask  42.13      300
------------------------
```

---

# Best Bid / Best Ask

The most important values are:

```text
Best Bid

Best Ask
```

---

Compute:

```python
best_bid = max(
    self.bids
)
```

---

Compute:

```python
best_ask = min(
    self.asks
)
```

---

Example:

```text
Bid:

42.10

Ask:

42.11
```

---

# Spread

The spread is:

```python
spread = (

    best_ask

    -

    best_bid
)
```

---

Example:

```text
42.11

-

42.10

=

0.01
```

---

# Mid Price

Professional systems use:

```python
mid = (

    best_bid

    +

    best_ask
) / 2
```

---

Example:

```text
42.105
```

This is often more useful than:

```text
Last Traded Price
```

---

# Market Depth

Calculate:

```python
bid_depth = sum(

    self.bids.values()
)
```

---

Calculate:

```python
ask_depth = sum(

    self.asks.values()
)
```

---

Example:

```text
Bid:

50,000 shares

Ask:

20,000 shares
```

This indicates:

```text
Buying Pressure
```

---

# Order Imbalance

Formula:

```python
imbalance = (

    bid_depth

    /

    (

        bid_depth

        +

        ask_depth
    )
)
```

---

Example:

```text
0.75
```

Meaning:

```text
75%

of liquidity
is on the buy side.
```

---

# Heatmap Visualization

Professional terminals often display:

```text
Large Quantity
```

as:

```text
Darker Color
```

Example:

```text
100      light

1000     medium

10000    dark
```

---

Calculate:

```python
max_qty = max(

    self.bids.values()
)
```

---

Intensity:

```python
intensity = (

    qty

    /

    max_qty
)
```

---

# Price Ladder

Professional order books are often rendered as:

```text
      Qty     Price      Qty

      500     42.13
      700     42.12
              42.11      1000
              42.10      3000
```

This is called:

```text
A Price Ladder
```

---

# Tick-by-Tick Updates

Suppose:

```text
10000 updates/sec
```

You cannot render:

```text
10000 frames/sec
```

---

Apply throttling:

```python
self.dirty = True
```

---

Periodic refresh:

```python
pn.state.add_periodic_callback(

    self.refresh,

    100
)
```

---

Now:

```text
Feed:

10000/sec

Display:

10/sec
```

---

# Level 1 vs Level 2 Data

## Level 1

```text
Best Bid

Best Ask

Last Trade
```

---

## Level 2

```text
Entire Order Book
```

---

TickerHub implements:

```text
Level 2
```

market depth.

---

# Full Depth Books

Institutional systems may track:

```text
1000+

price levels
```

Example:

```python
depth = 1000
```

---

Display:

```text
Top 20
```

while storing:

```text
Top 1000
```

---

# Market Microstructure Analytics

Professional order books compute:

* spread,
* imbalance,
* liquidity,
* order flow,
* queue position,
* depth,
* market pressure.

---

Example:

```python
pressure = (

    bid_depth

    -

    ask_depth
)
```

---

Positive:

```text
Bullish
```

Negative:

```text
Bearish
```

---

# Event Flow

Suppose:

```text
Someone places
a buy order.
```

The system executes:

```text
Exchange
     |
     V

Feed Worker
     |
     V

MarketService
     |
     V

MarketState
     |
     V

OrderBook
     |
     V

Screen
```

Again:

```text
No polling.

No REST calls.

No widget callbacks.
```

---

# The Real Order Book Architecture

```text
Exchange Feed
        |
        V

Feed Worker
        |
        V

MarketService
        |
        V

Order Book State
        |
        +----- Bid Tree
        |
        +----- Ask Tree
        |
        +----- Spread
        |
        +----- Imbalance
        |
        +----- Liquidity
        |
        +----- Pressure
        |
        +----- Rendering
```

---

# Why Professional Traders Love Order Books

Because charts answer:

```text
What happened?
```

Order books answer:

```text
What might happen next?
```

---

# Architecture Lesson #15

Beginners think:

```text
Order Book
      =
Table
```

Professionals think:

```text
Order Book
      =
Real-Time
Market
Microstructure
Model
```

The table is merely the visualization.

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
      ├── Watchlist
      |
      ├── Chart
      |
      └── OrderBook
```

TickerHub now contains:

✅ Market feed

✅ Portfolio engine

✅ Risk engine

✅ Watchlist

✅ Charts

✅ Order book

We now have the beginnings of a professional trading workstation.

---

# In Part 16

We will build the **Portfolio Dashboard Component**, where you'll discover that portfolios are not:

```text
Tables of positions
```

but rather:

```text
Real-time financial balance sheets
continuously recalculated
from market events.
```
