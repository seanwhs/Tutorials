# Building TickerHub

## Part 28: Building the Panel State Management & Reactive UI Layer — Visualizing Distributed System State

> Traders do not interact with databases.
>
> Traders do not interact with APIs.
>
> Traders interact with:
>
> ```text
> Reality.
> ```

At this point, TickerHub has:

* market feeds,
* event buses,
* order management,
* portfolio management,
* risk management,
* distributed state.

Ironically, we have not yet built the thing most people think is the application:

```text
The UI
```

This is because professional trading terminals do not begin with screens.

They begin with:

```text
State
```

The UI is merely:

```text
A Visualization of State
```

---

# The Beginner UI Architecture

Most tutorials build applications like this:

```text
Button

↓

Callback

↓

Database

↓

Update Widget
```

Example:

```python
button.on_click(
    calculate
)
```

This works.

Until:

* 100 widgets,
* 20 services,
* background workers,
* WebSockets,
* market feeds,
* multiple users,
* asynchronous updates.

Then:

```text
UI Programming
```

becomes:

```text
Distributed State Synchronization
```

---

# Professional UI Architecture

Professional trading terminals invert the relationship:

```text
System State

↓

UI Projection
```

instead of:

```text
UI Event

↓

Application Logic
```

---

# TickerHub State Architecture

```text
Market Feed
        |
        V

Market Service
        |
        V

Shared State
        |
        V

Panel Components
```

---

# Why Shared State?

Because:

```text
Price
```

appears in:

* watchlists,
* charts,
* portfolios,
* risk views,
* alerts,
* news.

Updating:

```text
Six Widgets
```

is wrong.

Updating:

```text
One State Object
```

is correct.

---

# State Layers

TickerHub will contain:

```text
state/

    market_state.py

    portfolio_state.py

    risk_state.py

    order_state.py

    session_state.py
```

---

# Market State

Create:

```text
state/

    market_state.py
```

---

```python
import param
```

---

```python
class MarketState(

    param.Parameterized
):
```

---

Define:

```python
prices = param.Dict()
```

---

Define:

```python
orderbooks = param.Dict()
```

---

Define:

```python
trades = param.List()
```

---

Define:

```python
news = param.List()
```

---

# Why Param?

Because:

```text
param
```

provides:

```text
Observable State
```

---

Example:

```python
market.prices["D05"] = 42
```

automatically triggers:

```text
UI Updates
```

---

# Portfolio State

Create:

```text
state/

    portfolio_state.py
```

---

```python
class PortfolioState(

    param.Parameterized
):
```

---

Store:

```python
portfolios = param.Dict()
```

---

Store:

```python
cash = param.Dict()
```

---

Store:

```python
exposure = param.Dict()
```

---

Store:

```python
performance = param.Dict()
```

---

# Risk State

Create:

```text
state/

    risk_state.py
```

---

```python
class RiskState(

    param.Parameterized
):
```

---

Store:

```python
var = param.Number()
```

---

Store:

```python
cvar = param.Number()
```

---

Store:

```python
volatility = param.Number()
```

---

Store:

```python
drawdown = param.Number()
```

---

Store:

```python
alerts = param.List()
```

---

# Order State

Create:

```text
state/

    order_state.py
```

---

```python
class OrderState(

    param.Parameterized
):
```

---

Store:

```python
active_orders = param.List()
```

---

Store:

```python
fills = param.List()
```

---

Store:

```python
executions = param.List()
```

---

# Session State

Create:

```text
state/

    session_state.py
```

---

```python
class SessionState(

    param.Parameterized
):
```

---

Store:

```python
user = param.String()
```

---

Store:

```python
permissions = param.List()
```

---

Store:

```python
workspace = param.Dict()
```

---

# Why Separate States?

Because:

```text
Market

≠

Portfolio

≠

Risk

≠

Session
```

Each has:

```text
Different Lifecycles
```

---

# Singleton State Registry

Create:

```text
state/

    registry.py
```

---

```python
market_state = MarketState()

portfolio_state = (
    PortfolioState()
)

risk_state = (
    RiskState()
)

order_state = (
    OrderState()
)

session_state = (
    SessionState()
)
```

---

# Architecture

```text
Services
      |
      V

Shared State
      |
      V

Panel Components
```

---

# Watchlist Component

Create:

```text
components/

    watchlist/
```

---

```python
import panel as pn
```

---

```python
class Watchlist:
```

---

Create:

```python
self.table = (
    pn.widgets.Tabulator()
)
```

---

Observe:

```python
market_state.param.watch(

    self.update,

    "prices"
)
```

---

Implement:

```python
def update(
    self,
    event
):
```

---

Load:

```python
prices = event.new
```

---

Refresh:

```python
self.table.value = (
    prices
)
```

---

# Why Observe?

Because:

```text
Watchlist
```

should not know:

```text
Kafka

Redis

Market Feed

OMS
```

It only knows:

```text
State
```

---

# Chart Component

Create:

```text
components/

    charts/
```

---

Initialize:

```python
self.symbol = (
    pn.widgets.Select()
)
```

---

Observe:

```python
market_state.param.watch(

    self.update_chart,

    "prices"
)
```

---

Update:

```python
def update_chart(
    self,
    event
):
```

---

Fetch:

```python
price = event.new.get(
    self.symbol.value
)
```

---

Redraw.

---

# Portfolio Widget

Observe:

```python
portfolio_state.param.watch(

    self.refresh,

    "portfolios"
)
```

---

Display:

```text
Positions

PnL

Cash

Exposure
```

---

# Risk Dashboard

Observe:

```python
risk_state.param.watch(

    self.refresh,

    "var"
)
```

---

Observe:

```python
risk_state.param.watch(

    self.refresh,

    "cvar"
)
```

---

Observe:

```python
risk_state.param.watch(

    self.refresh,

    "drawdown"
)
```

---

Display:

```text
VaR

CVaR

Volatility

Drawdown
```

---

# Order Blotter

Observe:

```python
order_state.param.watch(

    self.refresh,

    "active_orders"
)
```

---

Display:

```text
Submitted

Partial

Filled

Cancelled
```

---

# State Flow

Suppose:

```text
Price Update
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

Market Service
       |
       V

Market State
       |
       +------ Watchlist
       |
       +------ Charts
       |
       +------ Portfolio
       |
       +------ Risk
```

---

Nobody calls:

```python
update_widget()
```

---

Instead:

```python
update_state()
```

---

# Reactive Functions

Panel supports:

```python
pn.bind()
```

---

Example:

```python
price_view = pn.bind(

    render,

    market_state.param.prices
)
```

---

Whenever:

```python
prices
```

changes:

```python
render()
```

runs automatically.

---

# Derived State

Suppose:

```text
Portfolio Value
```

depends on:

```text
Cash

+

Positions
```

---

Create:

```python
@param.depends(

    "cash",

    "positions"
)
```

---

Calculate:

```python
def value(self):
```

---

Return:

```python
cash + positions
```

---

# UI Composition

Professional terminals are built from:

```text
Independent Components
```

---

Example:

```text
Watchlist

Chart

OrderBook

Portfolio

Risk

News

Alerts
```

---

Each component:

```text
Consumes State
```

---

# Workspace Layout

Create:

```python
pn.template.FastListTemplate(
```

---

Add:

```python
sidebar
```

---

Add:

```python
main
```

---

Example:

```python
template.sidebar.append(
    watchlist
)
```

---

Example:

```python
template.main.append(
    chart
)
```

---

# Multi-Panel Layout

```text
+----------------------+
| Watchlist            |
+----------------------+

+---------+------------+
| Chart   | OrderBook  |
+---------+------------+

+----------------------+
| Portfolio            |
+----------------------+

+----------------------+
| Risk                 |
+----------------------+
```

---

# Dynamic Tabs

Example:

```text
Chart:
DBS

Chart:
UOB

Chart:
SIA
```

---

Create:

```python
pn.Tabs()
```

---

Append:

```python
tabs.append(
    chart
)
```

---

# Notification System

Create:

```text
alerts
```

---

Example:

```python
pn.state.notifications.success(
    "Order Filled"
)
```

---

Example:

```python
pn.state.notifications.error(
    "Risk Limit"
)
```

---

# Session Persistence

Store:

```text
Workspace
```

inside:

```text
Redis
```

---

Example:

```json
{
    "tabs":[
        "DBS",
        "UOB"
    ],

    "layout":"trading"
}
```

---

# Why Persist UI?

Because professional users expect:

```text
Tomorrow's Terminal

=

Today's Terminal
```

---

# Background Updates

Panel runs:

```text
Bokeh Server
```

---

Push updates:

```python
pn.state.execute(
    update
)
```

---

This allows:

```text
Async Worker

↓

UI Refresh
```

---

# Thread Safety

Never do:

```python
widget.value = x
```

from:

```text
Background Thread
```

---

Instead:

```python
pn.state.curdoc.add_next_tick_callback()
```

---

# WebSocket Architecture

```text
Browser
      |
      V

WebSocket
      |
      V

Panel Server
      |
      V

Shared State
```

---

# UI Performance

Suppose:

```text
10,000 ticks/sec
```

arrive.

---

Do not render:

```text
10,000 times/sec
```

---

Instead:

```python
pn.state.add_periodic_callback(
```

---

Refresh:

```text
5 FPS
```

---

# Component Isolation

Professional systems ensure:

```text
Chart Crash
```

does not crash:

```text
Portfolio
```

---

Each component:

```text
Fails Independently
```

---

# UI Event Flow

Suppose:

```text
BUY D05
```

---

Flow:

```text
Button
     |
     V

OMS
     |
     V

Kafka
     |
     V

Portfolio
     |
     V

Risk
     |
     V

Shared State
     |
     V

Panel
```

---

Notice:

```text
Button
```

does not update:

```text
Portfolio
```

The:

```text
System State
```

does.

---

# The Real Panel Architecture

```text
Panel UI
      |
      +------ Watchlist
      |
      +------ Charts
      |
      +------ OrderBook
      |
      +------ Portfolio
      |
      +------ Risk
      |
      +------ News
      |
      +------ Alerts
      |
      V

Shared State
      |
      V

Distributed Services
```

---

# Why Professional UIs Are Difficult

Because they are not:

```text
Collections of Widgets
```

They are:

```text
Visual Representations
of
Distributed System State
```

---

# Architecture Lesson #28

Beginners think:

```text
UI
   =
Widgets
```

Professionals think:

```text
UI
   =
Reactive Projections
of
Continuously Evolving State
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

Services
       |
       V

Shared State
       |
       +------ Watchlist
       |
       +------ Charts
       |
       +------ Portfolio
       |
       +------ Risk
       |
       +------ Orders
       |
       +------ Alerts
       |
       V

Panel UI
```

TickerHub now contains:

✅ Shared state architecture

✅ Reactive state binding

✅ Component isolation

✅ State observers

✅ Dynamic workspaces

✅ Session persistence

✅ Background UI updates

✅ WebSocket synchronization

✅ Multi-component composition

✅ Reactive rendering

At this point, TickerHub no longer resembles a dashboard framework.

It resembles:

```text
A Distributed State Visualization Engine
capable of rendering
the real-time evolution
of a financial system.
```

---

# In Part 29

We will build the **Professional Charting & Time-Series Analytics Engine**, where you'll discover that trading charts are not:

```text
Pictures of prices
```

but rather:

```text
Interactive visual databases
for exploring
the temporal structure
of financial reality.
```
