# Building TickerHub

## Part 19: Building the Workspace & Layout Engine — Creating an Operating System for Traders

> New traders use applications.
>
> Professional traders use workspaces.

If you observe a professional trader's monitor setup, you'll notice something unusual.

They don't have:

```text
One Dashboard
```

They have:

```text
Multiple Screens

+

Multiple Workspaces

+

Multiple Views

+

Multiple Contexts
```

A professional terminal is not designed around:

```text
Pages
```

It is designed around:

```text
Workspaces
```

---

# The Beginner Dashboard

Most dashboard tutorials build:

```python
template = pn.template.FastListTemplate()

template.main.append(chart)

template.main.append(table)

template.main.append(news)
```

This creates:

```text
A Static Dashboard
```

But professional traders need:

* multiple watchlists,
* multiple charts,
* multiple portfolios,
* multiple monitors,
* multiple trading strategies,
* multiple layouts.

---

# What Is a Workspace?

A workspace is:

```text
A Saved Financial Environment
```

containing:

```text
Layout
     +
Windows
     +
Subscriptions
     +
Filters
     +
Preferences
     +
State
```

---

# Example

A trader might create:

```text
Workspace:

SGX Equities
```

containing:

```text
Watchlist
Chart
Order Book
Portfolio
News
Risk
```

---

Another workspace:

```text
Global Macro
```

containing:

```text
FX
Rates
Commodities
Economic Calendar
News
```

---

Another:

```text
Options Trading
```

containing:

```text
Volatility Surface
Greeks
Option Chain
Risk
```

---

# Workspace Architecture

```text
User
     |
     V

Workspace Manager
     |
     V

Layout Engine
     |
     V

Component Registry
     |
     V

Panel Components
```

---

# Creating Workspace Domain

Create:

```text
domain/

    workspace.py
```

---

```python
from dataclasses import dataclass
from typing import List
```

---

```python
@dataclass
class Workspace:

    workspace_id: str

    name: str

    components: List[str]

    layout: dict
```

---

# Example

```python
Workspace(

    workspace_id="sgx",

    name="SGX Trading",

    components=[

        "watchlist",

        "chart",

        "portfolio",

        "risk"
    ],

    layout={}
)
```

---

# Workspace State

Create:

```text
state/

    workspace_state.py
```

---

```python
import param
```

---

```python
class WorkspaceState(

    param.Parameterized
):

    workspaces = param.Dict()

    current = param.String()
```

---

# Workspace Manager

Create:

```text
services/

    workspace_service.py
```

---

```python
class WorkspaceService:

    def __init__(

        self,

        state
    ):

        self.state = state
```

---

# Create Workspace

```python
def create(

    self,

    workspace
):
```

---

Store:

```python
self.state.workspaces[
    workspace.workspace_id
] = workspace
```

---

Activate:

```python
self.state.current = (
    workspace.workspace_id
)
```

---

# Switch Workspace

```python
def switch(

    self,

    workspace_id
):
```

---

Update:

```python
self.state.current = (
    workspace_id
)
```

---

# Why State?

Because switching workspaces means:

```text
Entire UI Reconstruction
```

---

# Component Registry

Professional systems never hardcode:

```python
if name == "chart":
```

Instead:

```text
Everything
is
registered.
```

---

Create:

```text
infrastructure/

    registry.py
```

---

```python
class ComponentRegistry:
```

---

Initialize:

```python
def __init__(self):

    self.components = {}
```

---

Register:

```python
def register(

    self,

    name,

    component
):
```

---

Store:

```python
self.components[
    name
] = component
```

---

Retrieve:

```python
def get(

    self,

    name
):
```

---

Return:

```python
return self.components[
    name
]
```

---

# Register Components

Example:

```python
registry.register(

    "watchlist",

    Watchlist
)
```

---

```python
registry.register(

    "chart",

    ChartComponent
)
```

---

```python
registry.register(

    "portfolio",

    PortfolioPanel
)
```

---

```python
registry.register(

    "risk",

    RiskDashboard
)
```

---

# Dynamic Construction

Suppose:

```python
workspace.components
```

contains:

```text
chart

portfolio

risk
```

---

Build:

```python
widgets = []
```

---

Loop:

```python
for component in (
    workspace.components
):
```

---

Instantiate:

```python
widgets.append(

    registry
    .get(
        component
    )()
)
```

---

Now:

```text
Workspace
```

creates:

```text
Entire Application
```

dynamically.

---

# Layout Engine

Professional systems separate:

```text
Data
```

from:

```text
Presentation
```

---

Example layout:

```python
layout = {

    "left": [

        "watchlist"
    ],

    "top": [

        "chart",

        "orderbook"
    ],

    "bottom": [

        "portfolio",

        "risk"
    ]
}
```

---

# Rendering

Example:

```python
sidebar = []
```

---

Loop:

```python
for item in layout[
    "left"
]:
```

---

Append:

```python
sidebar.append(

    registry
    .get(item)
    .panel()
)
```

---

Repeat for:

```text
top

bottom

center
```

---

# Result

```text
+------------------------------------+
| Watchlist                          |
+------------+-----------------------+
| Chart      | Order Book            |
+------------+-----------------------+
| Portfolio  | Risk                  |
+------------+-----------------------+
```

---

# Saving Workspaces

Professional traders save everything.

---

Example:

```python
import json
```

---

Serialize:

```python
json.dumps(

    workspace.__dict__
)
```

---

Example:

```json
{
    "workspace_id":"sgx",

    "name":"SGX Trading",

    "components":[
        "chart",
        "risk"
    ]
}
```

---

# Database Storage

Save:

```text
workspace_id

user_id

json_layout
```

---

Example schema:

```sql
CREATE TABLE workspaces (

    id TEXT,

    user_id TEXT,

    layout JSONB
);
```

---

# Auto Save

Professional terminals constantly save.

---

Example:

```python
pn.state.add_periodic_callback(

    autosave,

    30000
)
```

---

Meaning:

```text
Every 30 seconds
```

save workspace state.

---

# Multi Monitor Support

Professional traders often use:

```text
2

4

6

8
```

monitors.

---

Represent:

```python
layout = {

    "monitor1": {},

    "monitor2": {},

    "monitor3": {}
}
```

---

Example:

```text
Monitor 1

Watchlist
Chart
OrderBook
```

---

```text
Monitor 2

Portfolio
Risk
News
```

---

# User Preferences

Store:

```python
preferences = {

    "theme": "dark",

    "font": 12,

    "currency": "SGD"
}
```

---

# Symbol Context

Professional terminals maintain context.

Example:

```text
Selected Symbol:

D05
```

---

Changing:

```text
D05

↓

U11
```

updates:

* chart,
* order book,
* news,
* analytics,
* risk.

---

# Global Context State

Create:

```python
class ContextState(

    param.Parameterized
):

    symbol = param.String()
```

---

Subscribe:

```python
context.param.watch(

    callback,

    "symbol"
)
```

---

Now:

```text
One Click
```

updates:

```text
Entire Terminal
```

---

# Workspace Templates

Provide presets:

---

## Equity Trading

```text
Watchlist
Chart
OrderBook
Portfolio
News
```

---

## Portfolio Manager

```text
Portfolio
Risk
News
Analytics
```

---

## Macro Trading

```text
FX
Rates
Economic Calendar
News
```

---

## Quant Research

```text
Charts
Statistics
Models
Backtests
```

---

# Workspace Search

Professional terminals allow:

```text
CTRL+P
```

style navigation.

---

Example:

```text
Open:

Portfolio
```

---

Result:

```text
Portfolio Window
```

opens instantly.

---

# Workspace Event Flow

Suppose:

```text
User clicks:

"Risk Workspace"
```

The system executes:

```text
User
     |
     V

Workspace Service
     |
     V

Workspace State
     |
     V

Layout Engine
     |
     V

Component Registry
     |
     V

Panel Rendering
```

---

# The Real Workspace Architecture

```text
Workspace
      |
      +------ Layout
      |
      +------ Components
      |
      +------ Context
      |
      +------ Preferences
      |
      +------ State
      |
      +------ Persistence
      |
      +------ Multi Monitor
      |
      +------ Templates
      |
      +------ Rendering
```

---

# Why Bloomberg Feels Different

Because Bloomberg is not:

```text
An Application
```

It is:

```text
A User-Programmable
Financial Operating System
```

where traders construct their own environment.

---

# Architecture Lesson #19

Beginners think:

```text
Dashboard
     =
Page
```

Professionals think:

```text
Dashboard
     =
Persistent
Interactive
Workspace
```

The widgets are merely tools inside that workspace.

---

# Current Architecture

```text
Feed Workers
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
      +------ Workspace
      |
      V

Application State
      |
      +------ Watchlist
      |
      +------ Chart
      |
      +------ OrderBook
      |
      +------ Portfolio
      |
      +------ Risk
      |
      +------ News
      |
      +------ Workspace
```

TickerHub now contains:

✅ Market engine

✅ Portfolio engine

✅ Risk engine

✅ News engine

✅ Alert engine

✅ Workspace engine

✅ Dynamic layouts

✅ Component registry

✅ Persistent state

At this point, TickerHub no longer resembles a dashboard framework.

It resembles:

```text
A Financial Operating System
```

---

# In Part 20

We will build the **FastAPI Gateway & Authentication Layer**, where you'll discover that enterprise applications are not:

```text
Frontend applications with APIs
```

but rather:

```text
Distributed systems with security boundaries.
```
