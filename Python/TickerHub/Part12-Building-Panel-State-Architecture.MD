# Building TickerHub

## Part 12: Building the Panel State Architecture — The UI as a Projection of State

> One of the biggest mistakes developers make when building dashboards is believing that the UI contains the application's state.
>
> Professional systems know the opposite:
>
> **The UI contains no state at all.**

If you remember only one architectural principle from this entire series, remember this:

```text
State lives in the application.

The UI merely observes it.
```

This principle is why Bloomberg, Refinitiv, trading terminals, and modern reactive systems can scale to thousands of screens and millions of updates.

---

# The Beginner Architecture

Most dashboard applications look like this:

```text
Button
   |
   V
Widget
   |
   V
Chart
```

Example:

```python
button.on_click(
    update_chart
)
```

Or:

```python
table.value = data
```

This works.

Until:

* multiple widgets need the same data,
* multiple windows need the same state,
* background workers update data,
* remote events arrive,
* live feeds update thousands of values.

Then:

```text
UI Logic Hell
```

begins.

---

# The Professional Architecture

Professional systems reverse the relationship.

Instead of:

```text
UI
   |
   V
State
```

we build:

```text
State
   |
   V
UI
```

The UI becomes:

```text
A Projection
of Application State
```

---

# TickerHub State Architecture

```text
Market Feed
      |
      V

Services
      |
      V

Application State
      |
      V

Panel Components
      |
      V

User
```

Notice:

```text
The user never talks
to the services.
```

The user only manipulates:

```text
State
```

---

# Why Panel + Param?

Panel itself is:

```text
A UI Framework
```

The real magic is:

```text
param
```

Because `param` gives us:

* reactive state,
* dependency tracking,
* change notifications,
* validation,
* synchronization.

In other words:

```text
A State Machine Framework
```

---

# Creating the State Package

Create:

```text
state/

    __init__.py

    market_state.py

    portfolio_state.py

    risk_state.py

    session_state.py

    app_state.py
```

---

# Market State

Create:

## state/market_state.py

```python
import param


class MarketState(

    param.Parameterized
):

    prices = param.Dict()

    orderbooks = param.Dict()

    trades = param.List()

    connected = param.Boolean()

    latency = param.Number()

    feed_rate = param.Integer()
```

---

# Why Param?

Suppose:

```python
market.prices["D05"] = 42
```

Param automatically notifies:

```text
Charts

Watchlists

Portfolios

Analytics
```

No callbacks required.

---

# Portfolio State

Create:

## state/portfolio_state.py

```python
import param


class PortfolioState(

    param.Parameterized
):

    portfolios = param.Dict()

    total_value = param.Number()

    total_pnl = param.Number()

    exposure = param.Number()
```

---

# Risk State

Create:

## state/risk_state.py

```python
import param


class RiskState(

    param.Parameterized
):

    var = param.Number()

    cvar = param.Number()

    leverage = param.Number()

    exposure = param.Number()

    concentration = param.Number()
```

---

# Session State

Create:

## state/session_state.py

```python
import param


class SessionState(

    param.Parameterized
):

    user = param.String()

    authenticated = param.Boolean()

    permissions = param.List()
```

---

# Why Separate States?

Because:

```text
Market Data
```

changes:

```text
1000 times/sec
```

while:

```text
Authentication
```

changes:

```text
once/day
```

We isolate update frequencies.

---

# Creating the Root State

Create:

## state/app_state.py

```python
from .market_state import (
    MarketState
)

from .portfolio_state import (
    PortfolioState
)

from .risk_state import (
    RiskState
)

from .session_state import (
    SessionState
)
```

---

```python
class AppState:

    def __init__(self):

        self.market = (
            MarketState()
        )

        self.portfolio = (
            PortfolioState()
        )

        self.risk = (
            RiskState()
        )

        self.session = (
            SessionState()
        )
```

---

Now:

```python
state.market.prices
```

and:

```python
state.portfolio.total_pnl
```

live in one application-wide state tree.

---

# The State Tree

Our application now looks like:

```text
AppState

    |
    +------ MarketState

    |
    +------ PortfolioState

    |
    +------ RiskState

    |
    +------ SessionState
```

This is essentially:

```text
Redux

+

MobX

+

Vue Reactivity

+

Elm Architecture
```

inside Python.

---

# State Updates

Suppose market data changes:

```python
state.market.prices[
    "D05"
] = 43.20
```

Immediately:

```text
Watchlist updates.

Chart updates.

Portfolio updates.

Risk updates.
```

Nobody calls anybody.

---

# Watching State Changes

Param allows:

```python
state.market.param.watch(

    callback,

    "prices"
)
```

---

Example:

```python
def on_price(event):

    print(
        event.new
    )
```

---

Whenever:

```python
prices
```

changes:

```text
callback fires
```

---

# Reactive Dependencies

Param also supports:

```python
@param.depends(
    "prices",
    watch=True
)
```

Example:

```python
class Dashboard(

    param.Parameterized
):

    prices = param.Dict()

    @param.depends(
        "prices",
        watch=True
    )
    def update(self):

        print(
            "updated"
        )
```

---

# Derived State

Professional systems rarely store everything.

Example:

Don't store:

```text
Portfolio Value
```

Compute it.

---

Example:

```python
@param.depends(
    "positions"
)
def total_value(
    self
):

    return sum(

        p.market_value

        for p in self.positions
    )
```

This is called:

```text
Computed State
```

---

# Immutable vs Mutable State

Frontend frameworks often require:

```text
Immutable State
```

Panel doesn't.

We can safely do:

```python
state.market.prices[
    "D05"
] = 42
```

This greatly simplifies our architecture.

---

# The Single Source of Truth

Suppose:

```text
Watchlist:
42
```

and:

```text
Chart:
43
```

Who is correct?

Nobody knows.

---

Instead:

```text
AppState:

43
```

Every component reads:

```text
43
```

This principle is called:

# Single Source of Truth

---

# State Ownership

Professional systems assign ownership.

Example:

| State          | Owner            |
| -------------- | ---------------- |
| MarketState    | MarketService    |
| PortfolioState | PortfolioService |
| RiskState      | RiskService      |
| SessionState   | AuthService      |

---

Rule:

```text
Only the owner
may mutate state.
```

Everybody else:

```text
Reads only.
```

---

# Why Ownership Matters

Without ownership:

```python
chart.update_price()

portfolio.update_price()

watchlist.update_price()
```

Eventually:

```text
Nobody knows
who changed what.
```

---

With ownership:

```text
MarketService
        |
        V
MarketState
```

Problem solved.

---

# Session Isolation

Panel applications are multi-user.

Suppose:

```text
User A
```

changes:

```text
watchlist
```

Should:

```text
User B
```

see it?

No.

---

Therefore:

```text
Global State
```

and:

```text
Session State
```

must be separate.

---

Example:

```text
Global

    MarketState

    RiskState


Session

    User

    Layout

    Preferences
```

---

# Event Flow

Suppose DBS updates:

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

Panel Components
```

Notice:

```text
No direct UI calls.
```

---

# Why This Is Important

Because:

```text
UI
```

is now:

```text
Replaceable
```

Today:

```text
Panel
```

Tomorrow:

```text
React
```

or:

```text
Flutter
```

The business logic remains unchanged.

---

# State Serialization

Eventually we'll persist state.

Example:

```python
snapshot = {

    "prices":

        state.market.prices,

    "risk":

        state.risk.var
}
```

Save:

```text
Redis

PostgreSQL

S3
```

---

# Time Travel Debugging

Once state becomes explicit:

```text
State A
        |
        V

State B
        |
        V

State C
```

We can replay:

```text
A → B → C
```

This is how many professional trading systems debug production incidents.

---

# State Synchronization

Suppose:

```text
Panel Instance #1
```

changes state.

How do we update:

```text
Panel Instance #2?
```

Answer:

```text
Redis Pub/Sub

Kafka

WebSockets
```

This is why state architecture comes before UI architecture.

---

# The Complete State Architecture

```text
                    AppState

      ┌──────────────┼──────────────┐
      │              │              │

      ▼              ▼              ▼

  MarketState   PortfolioState   RiskState

      │              │              │

      ▼              ▼              ▼

    Panel         Panel          Panel
```

---

# What We Have Built

Without writing a single widget, we now have:

✅ Reactive state

✅ Event propagation

✅ Dependency tracking

✅ Single source of truth

✅ Ownership rules

✅ Session isolation

✅ State synchronization

This is the real foundation of the UI.

---

# Architecture Lesson #12

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
A Visualization
of State
```

The screen itself contains no business logic.

It simply renders the current state of the system.

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

Panel UI
```

For the first time in this series:

```text
We are finally ready
to build a dashboard.
```

---

# In Part 13

We will build the first actual UI component:

# The Watchlist

where you'll discover that a professional watchlist is not:

```text
A Table
```

but rather:

```text
A Real-Time Projection
of Market State
with Filtering,
Subscriptions,
Caching,
and Event Synchronization.
```
