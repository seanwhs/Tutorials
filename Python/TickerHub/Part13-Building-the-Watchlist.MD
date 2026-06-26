# Building TickerHub

## Part 13: Building the Watchlist — Your First Real-Time Market View

> The watchlist is the most underestimated component in a financial terminal.
>
> Beginners see a table of prices.
>
> Professionals see a real-time market projection engine.

Open any professional terminal:

* Bloomberg
* Refinitiv
* CQG
* FactSet
* Trading Technologies

The first thing you'll usually see is:

```text
A Watchlist
```

Not because it's simple.

But because it answers the most important question:

> What do I need to pay attention to right now?

---

# The Beginner Watchlist

Most tutorials build watchlists like this:

```python
table = pn.widgets.Tabulator(
    dataframe
)
```

Then:

```python
table.value = new_data
```

This works.

Until:

* prices update 100 times/sec,
* there are thousands of instruments,
* multiple users exist,
* sorting changes,
* filtering changes,
* subscriptions change.

Then:

```text
Table Widget
```

becomes:

```text
Streaming State Management Problem
```

---

# What Is a Professional Watchlist?

A watchlist is actually:

```text
Market State
        +
Subscriptions
        +
Filtering
        +
Sorting
        +
Caching
        +
Presentation
```

---

# Watchlist Architecture

```text
MarketState
      |
      V

Watchlist Model
      |
      V

Watchlist Component
      |
      V

Panel UI
```

Notice:

```text
The watchlist
does not talk
to MarketService.
```

It only observes:

```text
State
```

---

# Creating the Component

Create:

```text
components/

    watchlist/

        __init__.py

        watchlist.py
```

---

# Imports

```python
import panel as pn
import pandas as pd
import param
```

---

# Creating the Class

```python
class Watchlist(

    param.Parameterized
):
```

Why `Parameterized`?

Because the watchlist itself contains state.

---

# Defining Parameters

```python
symbols = param.List()

selected = param.String()

filter_text = param.String()
```

---

Example:

```text
symbols:

D05
U11
O39
C6L
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

# Creating Internal Data

```python
self.data = pd.DataFrame(
    columns=[
        "Symbol",
        "Price",
        "Change",
        "Volume"
    ]
)
```

---

# Why Internal Data?

Because:

```text
MarketState
```

contains:

```python
{
    "D05": 42.3,
    "U11": 31.8
}
```

But:

```text
Tabulator
```

expects:

```python
DataFrame
```

The watchlist becomes:

```text
A Translator
```

---

# Creating the Grid

```python
self.table = pn.widgets.Tabulator(

    self.data,

    pagination=None,

    selectable=1,

    sizing_mode="stretch_width",

    height=500
)
```

---

# Why Tabulator?

Because it supports:

* virtualization,
* sorting,
* filtering,
* selection,
* large datasets.

Professional terminals rarely use:

```text
HTML tables.
```

---

# Initial Symbols

Let's add:

```python
self.symbols = [

    "D05",

    "U11",

    "O39",

    "C6L"
]
```

---

# Refreshing the Data

Create:

```python
def refresh(
    self
):
```

---

Build rows:

```python
rows = []
```

---

Iterate:

```python
for symbol in self.symbols:

    price = (

        self.state.market.prices
        .get(
            symbol,
            0
        )
    )
```

---

Append:

```python
rows.append({

    "Symbol":
        symbol,

    "Price":
        price,

    "Change":
        0,

    "Volume":
        0
})
```

---

Convert:

```python
self.data = pd.DataFrame(
    rows
)
```

---

Update:

```python
self.table.value = (
    self.data
)
```

---

# First Result

```text
--------------------------------
Symbol     Price
--------------------------------
D05        42.10
U11        31.20
O39        15.60
C6L        21.90
--------------------------------
```

---

# Connecting to Market State

We don't want:

```python
while True:

    refresh()
```

We want:

```text
Reactive Updates
```

---

Use:

```python
self.state.market.param.watch(

    self.on_market_update,

    "prices"
)
```

---

Create:

```python
def on_market_update(

    self,

    event
):

    self.refresh()
```

---

Now:

```python
state.market.prices[
    "D05"
] = 43
```

immediately updates:

```text
Watchlist
```

without polling.

---

# Why This Matters

The flow becomes:

```text
Feed
   |
   V

MarketService
   |
   V

MarketState
   |
   V

Watchlist
```

Nobody manually updates the UI.

---

# Row Selection

Users select symbols.

Create:

```python
self.table.on_click(

    self.on_select
)
```

---

Example:

```python
def on_select(
    self,
    event
):

    row = self.data.iloc[
        event.row
    ]

    self.selected = (

        row["Symbol"]
    )
```

---

Result:

```text
User clicks:

D05
```

Then:

```python
watchlist.selected
```

becomes:

```text
D05
```

---

# Why Selection Is State

Because:

```text
Chart
```

needs to know.

And:

```text
OrderBook
```

needs to know.

And:

```text
News
```

needs to know.

Therefore:

```text
Selection
```

is application state.

---

# Filtering

Create:

```python
self.search = pn.widgets.TextInput()
```

---

Bind:

```python
self.search.param.watch(

    self.on_filter,

    "value"
)
```

---

Filter:

```python
def on_filter(
    self,
    event
):

    self.filter_text = (
        event.new
    )

    self.refresh()
```

---

Update refresh:

```python
if self.filter_text:

    if (

        self.filter_text
        not in symbol
    ):

        continue
```

---

Example:

```text
Input:

D
```

Results:

```text
D05
```

---

# Sorting

Tabulator provides:

```text
Sort by:

Price

Volume

Change
```

automatically.

No extra code required.

---

# Color Coding

Professional terminals color prices.

Example:

| Change   | Color |
| -------- | ----- |
| Positive | Green |
| Negative | Red   |
| Zero     | White |

---

Create:

```python
def price_color(
    value
):
```

---

Example:

```python
if value > 0:

    return "green"

if value < 0:

    return "red"

return "white"
```

---

# Flashing Prices

Professional terminals flash when prices change.

Example:

```text
42.10

↓

42.20
```

becomes:

```text
FLASH GREEN
```

---

Store:

```python
self.previous_prices = {}
```

---

Compare:

```python
old = self.previous_prices.get(
    symbol
)
```

---

If:

```python
price > old
```

then:

```text
flash green
```

---

If:

```python
price < old
```

then:

```text
flash red
```

---

# Subscription Management

A watchlist shouldn't subscribe to:

```text
Entire Market
```

Instead:

```python
self.symbols
```

defines:

```text
Subscription Set
```

---

Example:

```text
Watchlist:

D05
U11
C6L
```

MarketService subscribes only to:

```text
D05
U11
C6L
```

This reduces:

```text
Bandwidth

CPU

Memory
```

---

# Caching

Suppose:

```text
D05
```

updates:

```text
1000 times/sec
```

The UI cannot redraw:

```text
1000 times/sec
```

---

Instead:

```text
Market Feed:

1000/sec


Watchlist:

10/sec
```

---

Create:

```python
self.pending = {}
```

---

Update:

```python
self.pending[
    symbol
] = price
```

---

Flush:

```python
pn.state.add_periodic_callback(

    self.refresh,

    100
)
```

This refreshes:

```text
every 100 ms
```

---

# Virtualization

Suppose:

```text
5000 symbols
```

Rendering:

```text
5000 rows
```

is expensive.

Tabulator solves this using:

```text
Virtual DOM
```

Only visible rows render.

---

# Multi-Watchlist Support

Professional terminals support:

```text
Equities

FX

Commodities

Crypto

Favorites
```

Model:

```python
watchlists = {

    "equities": [...],

    "fx": [...],

    "crypto": [...]
}
```

---

# Persistence

Save:

```python
watchlist_config = {

    "symbols":
        self.symbols,

    "sorting":
        "price",

    "filters":
        self.filter_text
}
```

Store:

```text
Redis

Postgres

Local Storage
```

---

# Watchlist Event Flow

Suppose:

```text
DBS rises
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

Watchlist
      |
      V

Screen Updates
```

Notice:

```text
No callbacks.

No API calls.

No polling.
```

---

# The Real Watchlist Architecture

```text
Market Feed
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

Watchlist Model
      |
      V

Tabulator View
```

---

# Why Bloomberg Watchlists Feel Fast

Because they do NOT:

```text
Query APIs

Refresh pages

Reload tables
```

They simply:

```text
Project
the current state
of the market.
```

---

# Architecture Lesson #13

Beginners think:

```text
Watchlist
      =
Table
```

Professionals think:

```text
Watchlist
      =
Real-Time
State Projection
```

The table itself is merely the final rendering step.

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
      V

Watchlist
```

For the first time:

```text
TickerHub
```

actually displays:

```text
Live market data.
```

---

# In Part 14

We will build the **Chart Component**, where you'll discover that professional charts are not:

```text
Lines on a graph
```

but rather:

```text
Streaming data structures
with buffering,
aggregation,
windowing,
and time-series processing.
```
