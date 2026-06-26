# Building TickerHub

## Part 30: Building the Market Microstructure & Order Book Engine — Modeling Continuous Financial Auctions

> Most people think markets look like this:
>
> ```text
> Price
> ```
>
> Professional traders know markets actually look like this:
>
> ```text
> Buyers
>
> versus
>
> Sellers
> ```
>
> because markets are not charts.
>
> Markets are:
>
> ```text
> Continuous Auctions
> ```

At this point, TickerHub has:

* market feeds,
* portfolios,
* risk engines,
* charting,
* analytics,
* reactive state.

However, there is still one enormous simplification remaining.

Our system currently assumes:

```text id="0alj4r"
Price Exists
```

Professional systems understand:

```text id="n06v5e"
Price Emerges
```

from:

```text id="u2v1ii"
Competition
```

between buyers and sellers.

---

# The Beginner View of Markets

Most tutorials assume:

```python id="oq4d4v"
price = 42.50
```

But professional trading systems ask:

```text id="jlwm8w"
Why
is the price
42.50?
```

The answer is:

```text id="v3kvc0"
Order Flow
```

---

# Market Microstructure

Market microstructure studies:

```text id="k91l2a"
How Prices Form
```

through:

* bids,
* asks,
* liquidity,
* spreads,
* queue priority,
* order matching.

---

# The Market Equation

Professional systems think:

```text id="q54pj0"
Price
    =
Supply
    +
Demand
    +
Liquidity
    +
Time
```

---

# What Is An Order Book?

An order book is:

```text id="gttn9e"
The Current State
of Market Intentions
```

Example:

```text id="ocpgre"
SELL
41.20  1000

41.15  500

41.10  200

----------
MARKET
41.05  300

41.00  800

40.95  1200
BUY
```

---

# Best Bid

The highest buyer:

```text id="i0ut8n"
41.05
```

---

# Best Ask

The lowest seller:

```text id="znm7ab"
41.10
```

---

# Mid Price

Formula:

```text id="dkqaqa"
(Bid + Ask)/2
```

---

Example:

```text id="4hl00u"
41.05

+

41.10
```

equals:

```text id="29l7t7"
41.075
```

---

# Spread

Formula:

```text id="gkhqkh"
Ask

-

Bid
```

---

Example:

```text id="gwpx2h"
41.10

-

41.05
```

equals:

```text id="p9wplv"
0.05
```

---

# Why Spreads Matter

Because spreads represent:

```text id="5kzvkr"
Liquidity Cost
```

---

Example:

```text id="k4nmz7"
Buy:
41.10

Sell:
41.05
```

Immediate loss:

```text id="c9vvqr"
0.05
```

---

# Market Depth

Question:

```text id="l05qzi"
How much can I trade?
```

Example:

```text id="e5wznh"
41.10  200

41.15  500

41.20  1000
```

---

Total liquidity:

```text id="wl5pmg"
1700 shares
```

---

# Order Book Model

Create:

```text id="y0w1is"
domain/

    orderbook.py
```

---

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class BookLevel:

    price: float

    quantity: int
```

---

```python
@dataclass
class OrderBook:

    symbol: str

    bids: list

    asks: list
```

---

# Why Separate Levels?

Because:

```text id="4osjct"
Price
```

and:

```text id="g6w06l"
Liquidity
```

are independent dimensions.

---

# Example Order Book

```python
book = OrderBook(

    symbol="D05",

    bids=[

        BookLevel(41.05,300),

        BookLevel(41.00,800)
    ],

    asks=[

        BookLevel(41.10,200),

        BookLevel(41.15,500)
    ]
)
```

---

# Level 1 Market Data

Contains:

```text id="kvt3uq"
Best Bid

Best Ask

Last Trade
```

---

Example:

```text id="fs1h5u"
Bid:
41.05

Ask:
41.10

Last:
41.08
```

---

# Level 2 Market Data

Contains:

```text id="w3bpp0"
Entire Order Book
```

---

Example:

```text id="mhgslz"
10 Bid Levels

10 Ask Levels
```

---

# Level 3 Market Data

Contains:

```text id="7fjlwm"
Individual Orders
```

---

Example:

```text id="sbx0jx"
Trader A:
100

Trader B:
200

Trader C:
300
```

---

# Why Level 3 Matters

Because it reveals:

```text id="r3k1o8"
Market Behavior
```

rather than:

```text id="svv3uv"
Market Price
```

---

# Market Orders

Example:

```text id="t7ifw9"
BUY
1000
MARKET
```

---

Effect:

```text id="jbrkzd"
Consumes Liquidity
```

---

# Limit Orders

Example:

```text id="7ujz1f"
BUY

1000

@

41.00
```

---

Effect:

```text id="hk26gi"
Provides Liquidity
```

---

# Stop Orders

Example:

```text id="h8xfxu"
SELL

if

Price < 40
```

---

# Iceberg Orders

Display:

```text id="p01t6e"
100
```

Actual:

```text id="ajcbcz"
10,000
```

---

Purpose:

```text id="z0mib8"
Hide Intent
```

---

# Fill-Or-Kill Orders

Rule:

```text id="wkkghg"
Execute Everything

or

Cancel Everything
```

---

# Immediate-Or-Cancel

Rule:

```text id="7uv0je"
Execute Available

Cancel Remainder
```

---

# Queue Priority

Professional exchanges use:

```text id="iqdfjl"
Price-Time Priority
```

---

Example:

```text id="0eq6di"
Trader A:
09:00:01
```

---

```text id="6jlwmj"
Trader B:
09:00:02
```

---

Result:

```text id="md4l4w"
Trader A Executes First
```

---

# Matching Engine

Create:

```text id="9nzyoe"
services/

    matching_engine.py
```

---

Initialize:

```python
class MatchingEngine:
```

---

Maintain:

```python
self.books = {}
```

---

Receive:

```python
def process(
    self,
    order
):
```

---

# Buy Matching Logic

Algorithm:

```text id="zy1a1l"
Best Ask

↓

Match

↓

Next Ask

↓

Match
```

---

Example:

```text id="kxv3od"
BUY

1000
```

---

Order Book:

```text id="0zz4x5"
41.10  200

41.15  300

41.20  500
```

---

Result:

```text id="mw6o5h"
200

+

300

+

500
```

---

Execution price:

```text id="f9r5ie"
Weighted Average
```

---

# Partial Fill

Example:

```text id="h5qbbq"
BUY:
1000
```

---

Liquidity:

```text id="wcg9n4"
600
```

---

Result:

```text id="25yn4x"
Partial Fill:
600
```

---

Remaining:

```text id="3xk8fc"
400
```

---

# Slippage

Question:

```text id="q4gr8r"
How much worse
was execution?
```

---

Example:

```text id="6jvqsw"
Expected:
41.10
```

---

Actual:

```text id="ccar1f"
41.22
```

---

Slippage:

```text id="ty1h4j"
0.12
```

---

# Liquidity Metrics

Compute:

```text id="3xjlwm"
Bid Size

Ask Size

Spread

Depth

Imbalance
```

---

# Order Imbalance

Formula:

```text id="s1yemv"
Bid Volume

/

Total Volume
```

---

Example:

```text id="bnn9pz"
1000

/

1200
```

---

Result:

```text id="f1ww9h"
83%
```

---

Interpretation:

```text id="jq74mw"
Strong Buying Pressure
```

---

# Volume Profile

Question:

```text id="hn0rbn"
Where did trading occur?
```

---

Example:

```text id="cnll2v"
41.00  ███████

41.10  █████████

41.20  ██
```

---

# Time And Sales

Display:

```text id="x7yv7l"
Trade History
```

---

Example:

```text id="8zw11l"
09:01 BUY 100

09:02 SELL 500

09:03 BUY 300
```

---

# Tape Reading

Professional traders analyze:

```text id="8k0h3w"
Execution Flow
```

---

Question:

```text id="e9o77k"
Who is aggressive?
```

---

Example:

```text id="1o8qae"
BUY BUY BUY BUY
```

means:

```text id="1vud8g"
Buyer Dominance
```

---

# Market Impact

Question:

```text id="p5hvkp"
What happens if we trade?
```

---

Example:

```text id="pdhy0d"
Order:
10M
```

---

Book:

```text id="52d8yb"
5M liquidity
```

---

Result:

```text id="wr8qu0"
Price Moves
```

---

# Synthetic Market

TickerHub can generate:

```text id="0ig5fu"
Artificial Order Books
```

---

Example:

```python
spread = random.uniform(
    0.01,
    0.05
)
```

---

Generate:

```text id="2ffxg5"
Liquidity

Spread

Depth

Trades
```

---

# Order Book State

Create:

```text id="a74m4d"
state/

    orderbook_state.py
```

---

```python
class OrderBookState(
    param.Parameterized
):
```

---

Store:

```python
books = param.Dict()
```

---

Store:

```python
trades = param.List()
```

---

Store:

```python
spreads = param.Dict()
```

---

Store:

```python
depth = param.Dict()
```

---

# Order Book Component

Display:

```text id="b7ktgd"
Bids

Price

Asks
```

---

Example:

```text id="d0ew8w"
1000   41.00

500    41.05

----------

41.10  300

41.15  800
```

---

# Heatmap

Display:

```text id="03gbck"
Liquidity Density
```

---

Example:

```text id="w91s1q"
█
██
██████
██████████
```

---

# Order Flow Architecture

```text id="iqx3hh"
Market Feed
        |
        V

Order Book
        |
        V

Matching Engine
        |
        V

Trades
        |
        V

Portfolio
        |
        V

Risk
        |
        V

Panel
```

---

# Why Market Microstructure Matters

Because:

```text id="0xpp7k"
Charts
```

show:

```text id="rhn3zm"
What Happened
```

while:

```text id="k7h3wd"
Order Books
```

show:

```text id="vmgc8v"
What Is About To Happen
```

---

# Architecture Lesson #30

Beginners think:

```text id="s7e8vb"
Markets
    =
Prices
```

Professionals think:

```text id="jjlwm1"
Markets
    =
Continuous Auctions
between competing agents
under liquidity constraints
```

---

# Current Architecture

```text id="cjlwm9"
Market Feed
        |
        V

Order Book
        |
        V

Matching Engine
        |
        +------ Trades
        |
        +------ Liquidity
        |
        +------ Spread
        |
        +------ Depth
        |
        +------ Imbalance
        |
        V

Portfolio
        |
        V

Risk
        |
        V

Panel
```

TickerHub now contains:

✅ Level 1 market data

✅ Level 2 order books

✅ Level 3 order flow

✅ Matching engine

✅ Market orders

✅ Limit orders

✅ Stop orders

✅ Liquidity analysis

✅ Slippage estimation

✅ Volume profiles

✅ Time and sales

✅ Market impact analysis

At this point, TickerHub no longer resembles a charting application or portfolio manager.

It resembles:

```text
A Continuous Financial Auction Simulator
capable of modeling
how prices emerge
from competition,
liquidity,
and time.
```

---

# In Part 31

We will build the **News Intelligence & Event Processing Engine**, where you'll discover that markets are not driven solely by prices or order books, but by:

```text
Information,
belief,
and the propagation
of human expectations.
```
