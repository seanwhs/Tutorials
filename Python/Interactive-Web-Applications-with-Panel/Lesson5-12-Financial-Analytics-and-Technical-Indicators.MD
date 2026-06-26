# Part V — Working with Live SGX Market Data

# Lesson 5.11 — Real-Time Updates and Live Market Monitoring: Periodic Callbacks, Auto Refresh, and Streaming Data

> **Learning Objectives**
>
> By the end of this lesson, you will be able to:
>
> * Understand what real-time applications are.
> * Learn how Panel supports periodic execution.
> * Understand polling versus streaming architectures.
> * Implement automatic dashboard refreshes.
> * Build live market watchlists.
> * Create market timers and countdowns.
> * Understand application synchronization.
> * Learn how to manage refresh intervals.
> * Build live-updating financial dashboards.
> * Think like a real-time systems engineer.

---

# Introduction

Our SGX Stock Monitor currently works like this:

```text
User

↓

Enter Symbol

↓

Press Search

↓

Retrieve Data

↓

Display Result
```

This is called:

> **Manual Refresh**

The problem?

Financial markets don't wait for users.

Suppose DBS moves:

```text
41.35

↓

41.50

↓

41.65

↓

41.80
```

while the user is reading the screen.

Our dashboard becomes stale.

Real financial dashboards continuously update.

---

# What Is a Real-Time Application?

A real-time application continuously receives and processes new information.

Examples include:

* stock terminals
* aircraft tracking systems
* hospital monitors
* security systems
* industrial control systems
* weather monitoring systems

---

# Manual vs Automatic Refresh

## Manual

```text
User

↓

Refresh Button

↓

Update
```

---

## Automatic

```text
Timer

↓

Refresh

↓

Update

↓

Wait

↓

Refresh
```

---

# Real-Life Example

Imagine driving a car.

Would you prefer:

```text
Speedometer

↓

Update Every 10 Minutes
```

or:

```text
Speedometer

↓

Update Continuously
```

Financial dashboards work the same way.

---

# How Do Real-Time Dashboards Work?

There are two major approaches:

## Polling

```text
Dashboard

↓

Request Data

↓

Wait

↓

Request Data

↓

Wait

↓

Request Data
```

---

## Streaming

```text
Server

↓

Push Data

↓

Dashboard

↓

Push Data

↓

Dashboard
```

---

# Which Approach Will We Use?

For our educational SGX dashboard:

```text
Polling

✓
```

because:

* simpler
* easier to understand
* widely supported
* works with most APIs

---

# Understanding Polling

Polling means:

> Asking for new data repeatedly.

Example:

```text
Every 10 Seconds

↓

Get Latest Stock Price
```

---

# Visualizing Polling

```text
0 sec

↓

Request

↓

10 sec

↓

Request

↓

20 sec

↓

Request
```

---

# Why Not Poll Every Millisecond?

Suppose we poll:

```text
1000 Times Per Second
```

Problems include:

* API quota exhaustion
* server overload
* wasted bandwidth
* poor performance

---

# Choosing Refresh Intervals

Typical intervals:

| Application         | Refresh   |
| ------------------- | --------- |
| Trading Terminal    | 100 ms    |
| Market Dashboard    | 5–30 sec  |
| Analytics Dashboard | 1–5 min   |
| Reporting Dashboard | 10–60 min |

---

# Our SGX Dashboard Strategy

We'll choose:

```text
10 Seconds
```

because it balances:

* responsiveness
* API quotas
* performance

---

# Introducing Periodic Callbacks

Panel provides:

```python
pn.state.add_periodic_callback()
```

This is one of the most important features for building real-time applications.

---

# What Is a Periodic Callback?

A periodic callback means:

```text
Execute Function

↓

Wait

↓

Execute Function

↓

Wait

↓

Execute Function
```

automatically.

---

# Basic Example

```python
def update():

    print("Updating...")


callback = pn.state.add_periodic_callback(

    update,

    period=5000
)
```

---

# Understanding `period`

The value:

```python
period=5000
```

means:

```text
5000 milliseconds

=

5 seconds
```

---

# Visualizing Periodic Execution

```text
Time

0 sec

↓

Run

5 sec

↓

Run

10 sec

↓

Run

15 sec

↓

Run
```

---

# Why This Is Powerful

Without periodic callbacks:

```text
User

↓

Click Refresh
```

With periodic callbacks:

```text
System

↓

Refresh Automatically
```

---

# Building Our First Live Stock Monitor

Suppose we already have:

```python
market_service
```

and:

```python
price_indicator
```

---

# Creating Update Logic

```python
def update_stock():

    stock = market_service.get_stock(
        "D05"
    )

    price_indicator.value = (
        stock["price"]
    )
```

---

# Adding Automatic Updates

```python
callback = (
    pn.state
      .add_periodic_callback(

        update_stock,

        period=10000
    )
)
```

Now our dashboard refreshes every ten seconds.

---

# Visualizing the Workflow

```text
Timer

↓

update_stock()

↓

MarketDataService

↓

Provider

↓

API

↓

Price Indicator
```

---

# What Happens Internally?

Panel creates:

```text
Background Scheduler

↓

Execute Callback

↓

Update Components

↓

Wait

↓

Repeat
```

This occurs automatically.

---

# Understanding State Synchronization

Suppose we display:

* current price
* volume
* percentage change

All values must update together.

---

# Bad Approach

```text
Price

↓

Update

↓

5 Seconds Later

↓

Volume Update
```

The dashboard becomes inconsistent.

---

# Good Approach

```text
Retrieve Data

↓

Update Everything

↓

Render Dashboard
```

---

# Example

```python
def update_stock():

    stock = market_service.get_stock(
        "D05"
    )

    price.value = stock["price"]

    volume.value = stock["volume"]

    change.value = stock["change"]
```

Everything updates simultaneously.

---

# Building Live Watchlists

Suppose users monitor:

```text
D05

U11

O39
```

Our workflow becomes:

```text
Watchlist

↓

Loop

↓

Retrieve Prices

↓

Update Table
```

---

# Example Watchlist

```python
watchlist = [

    "D05",

    "U11",

    "O39"
]
```

---

# Updating Multiple Stocks

```python
rows = []

for symbol in watchlist:

    stock = (
        market_service
        .get_stock(symbol)
    )

    rows.append(stock)
```

---

# Updating Tables

```python
table.value = rows
```

Panel automatically redraws the table.

---

# Building Market Clocks

Financial dashboards often display:

```text
Current Time

Market Status

Countdown To Close
```

---

# Why Market Clocks Matter

Users need to know:

```text
Market Open?

Market Closed?

Opening Soon?

Closing Soon?
```

---

# Example Market Status

```text
Singapore Exchange

OPEN

02:14:35 Remaining
```

---

# Getting Current Time

Python provides:

```python
from datetime import datetime
```

Example:

```python
now = datetime.now()
```

---

# Updating Time Displays

```python
clock.object = (
    now.strftime(
        "%H:%M:%S"
    )
)
```

Produces:

```text
14:35:12
```

---

# Combining Market Data and Time

Our callback becomes:

```python
def update_dashboard():

    update_stock()

    update_watchlist()

    update_clock()
```

---

# Visualizing Dashboard Synchronization

```text
Periodic Callback

↓

Stock Update

↓

Watchlist Update

↓

Clock Update

↓

Dashboard Refresh
```

---

# Understanding Refresh Costs

Every refresh requires:

```text
API Requests

↓

CPU

↓

Memory

↓

Network
```

Refreshing too frequently creates problems.

---

# Example Calculation

Suppose:

```text
10 Stocks

↓

10 Seconds
```

This produces:

```text
6 Requests/Minute

↓

360 Requests/Hour

↓

8640 Requests/Day
```

API quotas suddenly become important.

---

# Optimizing Refreshes

Strategies include:

* caching
* batching
* selective updates
* staggered refreshes

---

# Selective Updates

Instead of:

```text
Refresh Everything
```

we may do:

```text
Prices

↓

Every 10 Seconds

Charts

↓

Every Minute

News

↓

Every Hour
```

---

# Starting and Stopping Updates

Panel callbacks can be controlled.

Example:

```python
callback.start()
```

and:

```python
callback.stop()
```

---

# Why Stop Updates?

Suppose:

```text
Market Closed
```

There is no reason to:

```text
Continue Polling
```

---

# Building Pause Buttons

Example:

```python
pause = pn.widgets.Button(
    name="Pause"
)
```

---

# Pause Logic

```python
def pause_updates(event):

    callback.stop()
```

---

# Resume Logic

```python
def resume_updates(event):

    callback.start()
```

---

# Error Handling During Updates

Suppose:

```text
Network Failure
```

occurs during polling.

Bad:

```text
Dashboard Crash
```

Good:

```text
Status:

Connection Lost

Retrying...
```

---

# Example

```python
try:

    update_stock()

except Exception:

    status.object = (
        "Retrying..."
    )
```

---

# Building Resilient Real-Time Systems

Professional systems assume:

```text
Refreshes Will Fail
```

Therefore they:

* retry
* cache
* degrade gracefully
* continue operating

---

# Understanding Streaming

Large financial systems often use:

```text
Exchange

↓

WebSocket

↓

Streaming Data

↓

Dashboard
```

rather than polling.

---

# Why We Are Not Using Streaming Yet

Streaming introduces:

* sockets
* subscriptions
* connection management
* reconnection logic
* buffering
* synchronization

Polling is easier for beginners.

---

# Our Complete Real-Time Architecture

```text
Panel Dashboard

↓

Periodic Callback

↓

MarketDataService

↓

Provider

↓

Financial API

↓

Normalized Data

↓

Dashboard Update
```

---

# Thinking Like a Real-Time Systems Engineer

Beginners think:

> "How do I update the dashboard?"

Professionals think:

> "How often should the dashboard update, and what happens when updates fail?"

This distinction matters enormously.

Real-time systems engineering is largely:

> Managing change over time.

---

# Teacher's Notes

> One of the most important concepts introduced in this lesson is that time itself becomes part of your application architecture. Traditional programs execute once and terminate. Real-time applications execute continuously, requiring developers to reason about synchronization, refresh intervals, state consistency, and failure recovery.
>
> Another important lesson is that "real-time" is relative. Most business applications do not require microsecond updates. Choosing an appropriate refresh interval is an engineering tradeoff involving cost, performance, reliability, and user experience.

---

# Common Mistakes

## ❌ Mistake 1

Refreshing too frequently.

---

## ❌ Mistake 2

Ignoring API quotas.

---

## ❌ Mistake 3

Updating dashboard components independently.

---

## ❌ Mistake 4

Not handling refresh failures.

---

## ❌ Mistake 5

Continuing updates after markets close.

---

# Summary

In this lesson, you learned:

* Real-time applications continuously update information.
* Polling repeatedly requests new data.
* Panel supports automatic updates through periodic callbacks.
* Refresh intervals involve engineering tradeoffs.
* Dashboard components should update synchronously.
* Watchlists require repeated retrieval and rendering.
* Market clocks improve usability.
* Real-time systems require failure handling.
* Professional dashboards optimize update frequency carefully.

Our SGX dashboard is now capable of real-time monitoring. The next step is building advanced financial analytics features, including moving averages, volatility indicators, performance metrics, and technical analysis visualizations.

---

# Exercises

## Exercise 1 — Calculate API Usage

Suppose:

* 20 stocks
* refresh every 15 seconds

Calculate:

* requests per minute
* requests per hour
* requests per day

---

## Exercise 2 — Polling vs Streaming

Create a comparison table for:

* complexity
* cost
* latency
* implementation difficulty
* reliability

---

## Exercise 3 — Dashboard Synchronization

Explain why this approach is problematic:

```text
Price Update

↓

10 Seconds Later

↓

Volume Update

↓

5 Seconds Later

↓

Chart Update
```

Describe a better architecture.

---

# Coming Up Next

In **Lesson 5.12 — Financial Analytics and Technical Indicators: Moving Averages, Volatility, Returns, and Market Metrics**, we'll begin transforming our SGX Stock Monitor from a market viewer into a market analysis platform by implementing moving averages, percentage returns, volatility calculations, trend indicators, rolling windows, comparative performance analysis, and interactive financial visualizations using Panel and Python's data science ecosystem.
