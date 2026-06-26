# Building TickerHub

## Part 5: Building the State Engine with Param

> If the domain model is the brain of TickerHub, then the state engine is its nervous system.

Most developers think Panel applications look like this:

```python
button = pn.widgets.Button()

button.on_click(
    callback
)
```

This is how small applications work.

Professional applications work differently.

They look like this:

```text
Market Feed
      ↓
Market State
      ↓
Reactive Engine
      ↓
UI Components
```

The UI doesn't own the data.

The UI observes the data.

This architectural inversion is one of the most important concepts in professional application design.

---

# Why State Matters

Suppose DBS stock moves:

```text
D05
43.15
    ↓
43.20
```

What needs updating?

Potentially:

* Watchlist
* Chart
* Order Book
* Portfolio
* PnL
* Risk
* Alerts
* News Correlation
* Heatmap
* Dashboard

A beginner writes:

```python
watchlist.update()

chart.update()

portfolio.update()

risk.update()

alerts.update()
```

This creates:

```text
Everything
     |
depends on
     |
Everything
```

Eventually:

```text
CHAOS
```

---

# The Professional Solution

Professional systems separate:

```text
State
```

from

```text
Presentation
```

Instead:

```text
Price Feed
     ↓
MarketState
     ↓
Watchlist

MarketState
     ↓
Chart

MarketState
     ↓
Portfolio

MarketState
     ↓
Risk
```

Nobody talks to each other.

Everyone talks to state.

---

# TickerHub State Architecture

Our application state will look like this:

```text
                    Application State

       ┌─────────────┬─────────────┬─────────────┐
       │             │             │             │
       ▼             ▼             ▼             ▼

  MarketState   PortfolioState   RiskState   SessionState
       │             │             │             │
       └─────────────┼─────────────┼─────────────┘
                     │
                     ▼
                Panel UI
```

---

# Why Use Param?

We are using:

Param

because Param provides:

* reactive state,
* dependency tracking,
* observers,
* computed properties,
* event propagation,
* synchronization.

Think of Param as:

```text
Python React State
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
    workspace_state.py
```

---

# State #1 — MarketState

This represents the current market.

Create:

## state/market_state.py

```python
import param


class MarketState(
    param.Parameterized
):

    prices = param.Dict()

    quotes = param.Dict()

    orderbooks = param.Dict()

    trades = param.List()

    news = param.List()
```

---

# What Does This Mean?

Instead of:

```python
prices = {}
```

we now have:

```python
prices = param.Dict()
```

This means Param can observe changes.

Example:

```python
market = MarketState()

market.prices["D05"] = 43.15
```

The state changes become observable events.

---

# Adding Reactive Handlers

```python
import param


class MarketState(
    param.Parameterized
):

    prices = param.Dict()

    @param.depends(
        "prices",
        watch=True
    )
    def on_prices_changed(
        self
    ):

        print(
            "prices updated"
        )
```

Now:

```python
market.prices["D05"] = 43.50
```

produces:

```text
prices updated
```

automatically.

---

# State #2 — PortfolioState

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

Example:

```python
portfolio_state.total_pnl = 3200
```

Every observer immediately receives updates.

---

# State #3 — RiskState

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

    alerts = param.List()
```

---

Example:

```python
risk.var = 12000
```

All dashboards update automatically.

---

# State #4 — SessionState

This represents the user session.

Create:

## state/session_state.py

```python
import param


class SessionState(
    param.Parameterized
):

    user = param.String()

    permissions = param.List()

    authenticated = param.Boolean()

    theme = param.String(
        default="dark"
    )
```

---

Example:

```python
session.user = "alice"

session.authenticated = True
```

---

# State #5 — WorkspaceState

Professional terminals save workspaces.

Create:

## state/workspace_state.py

```python
import param


class WorkspaceState(
    param.Parameterized
):

    active_symbol = param.String()

    watchlists = param.Dict()

    layouts = param.Dict()

    open_windows = param.List()
```

---

Example:

```python
workspace.active_symbol = "D05"
```

Immediately:

* charts update,
* order books update,
* news updates,
* analytics update.

---

# The Global State Container

We now create the application state container.

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

from .workspace_state import (
    WorkspaceState
)


class AppState:

    def __init__(self):

        self.market = MarketState()

        self.portfolio = PortfolioState()

        self.risk = RiskState()

        self.session = SessionState()

        self.workspace = WorkspaceState()
```

---

Instantiate it:

```python
app_state = AppState()
```

Now we have:

```text
app_state.market

app_state.portfolio

app_state.risk

app_state.session

app_state.workspace
```

---

# State Ownership

One of the most important architectural rules:

> Every piece of state has exactly one owner.

Bad:

```text
Chart
     owns price

Watchlist
     owns price

Portfolio
     owns price
```

This produces:

```text
Three truths
```

which means:

```text
No truth
```

---

Good:

```text
MarketState
      owns price
```

Everyone else reads from it.

---

# State Flow

Our architecture now becomes:

```text
Market Feed
      |
      V
MarketState
      |
      |
      +---- Watchlist
      |
      +---- Chart
      |
      +---- Portfolio
      |
      +---- Risk
      |
      +---- Alerts
```

This pattern is called:

# Single Source of Truth

---

# Derived State

Many values should never be stored.

Example:

Bad:

```python
portfolio_value

portfolio_pnl

portfolio_return
```

all stored separately.

Instead:

```python
portfolio_value

portfolio_pnl
```

are derived.

---

Example:

```python
@property
def portfolio_return(
    self
):

    return (
        self.total_pnl
        / self.total_value
    )
```

---

Rule:

```text
Store facts.

Compute everything else.
```

---

# State Synchronization

Suppose a trade executes.

```text
Trade
   ↓
Position
   ↓
Portfolio
   ↓
PnL
   ↓
Risk
   ↓
UI
```

Notice something:

The UI never updates itself.

The UI merely observes state changes.

---

# Event-Driven State

Soon our architecture will become:

```text
Market Feed
      ↓
MarketService
      ↓
Event Bus
      ↓
MarketState
      ↓
Panel Components
```

The state engine becomes the bridge between:

```text
Backend
      ↓
Frontend
```

---

# State and Session Isolation

Panel applications are multi-user systems.

Therefore:

```text
Alice
   |
SessionState
```

and

```text
Bob
   |
SessionState
```

must be separate.

But:

```text
MarketState
```

may be shared globally.

This distinction is critical.

---

# Shared vs Session State

| State     | Shared?    |
| --------- | ---------- |
| Market    | Yes        |
| Portfolio | Usually No |
| Risk      | Usually No |
| Session   | No         |
| Workspace | No         |

---

# Why Professional Applications Are State Machines

A professional trading terminal isn't:

```text
Buttons
+
Charts
```

It is:

```text
Current State
       +
Transitions
```

Example:

```text
DISCONNECTED
        ↓
CONNECTING
        ↓
CONNECTED
        ↓
STREAMING
        ↓
ERROR
        ↓
RECONNECTING
```

This is a state machine.

Professional systems are full of them.

---

# The Emerging Architecture

After Part 5, our architecture now looks like:

```text
                 Domain
                     |
                     V

                Application
                     |
                     V

                 AppState
                     |
       ┌─────────────┼──────────────┐
       │             │              │
       ▼             ▼              ▼

   Market       Portfolio       Risk
    State         State         State
       │             │              │
       └─────────────┼──────────────┘
                     │
                     ▼

                  Panel UI
```

Notice:

We still have:

* no charts,
* no widgets,
* no dashboards.

And yet we now possess the most important part of the entire application:

```text
The Truth
```

Because everything else in TickerHub will eventually become:

```text
A View
of
State
```

---

# Architecture Lesson #5

Beginners build:

```text
UI
   ↓
Business Logic
```

Professionals build:

```text
State
   ↓
UI
```

The user interface does not own reality.

The state engine owns reality.

---

# In Part 6

We will build the **TickerHub Event Bus**, where you'll discover that professional systems do not communicate using:

```python
foo.bar()
```

They communicate using:

```text
Events
```

and that almost every large-scale financial system is fundamentally an event-processing machine.
