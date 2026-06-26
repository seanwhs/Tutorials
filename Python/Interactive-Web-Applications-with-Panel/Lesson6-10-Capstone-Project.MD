# Part VI — Advanced Panel: Templates, Reactive Programming, Param, Custom Components, and Enterprise Dashboard Architecture

# Lesson 6.10 — Capstone Project: Building a Production-Grade SGX Professional Trading Terminal with Panel

> **Learning Objectives**
>
> By the end of this capstone project, you will be able to:
>
> * Architect a Bloomberg-style financial terminal.
> * Apply component-oriented design.
> * Implement centralized state management.
> * Build service and repository layers.
> * Design event-driven systems.
> * Apply performance engineering principles.
> * Build scalable Panel applications.
> * Design production deployment architectures.
> * Think like a systems architect.
> * Understand how enterprise dashboard ecosystems are engineered.

---

# Introduction

Throughout this course, we have learned:

* Panel widgets
* layouts
* templates
* Param
* reactive programming
* custom components
* performance engineering
* deployment
* enterprise architecture

Now we will assemble everything into a single system.

---

# Our Goal

Build a professional:

```text
SGX Professional Trading Terminal
```

inspired by:

* Bloomberg Terminal
* Refinitiv Workspace
* CQG
* Interactive Brokers TWS
* TradingView Professional

---

# The Terminal

Our system will contain:

```text
SGX Terminal

├── Authentication
├── Watchlists
├── Charts
├── Market Depth
├── Portfolio
├── Positions
├── Orders
├── Alerts
├── News
├── Analytics
├── Risk
├── Audit
└── Administration
```

---

# System Architecture

```text
Users

↓

NGINX

↓

Authentication

↓

FastAPI

↓

Panel

↓

Services

↓

Events

↓

Repositories

↓

Redis

↓

Database

↓

Market Feed
```

---

# Layered Architecture

```text
Presentation

↓

Application Services

↓

Domain

↓

Infrastructure
```

---

# Project Structure

```text
sgx-terminal/

├── app/
│
├── components/
│
├── templates/
│
├── state/
│
├── domain/
│
├── services/
│
├── repositories/
│
├── events/
│
├── infrastructure/
│
├── api/
│
├── workers/
│
├── deployment/
│
└── tests/
```

---

# Component Architecture

```text
components/

├── charts/
├── indicators/
├── portfolio/
├── watchlist/
├── orderbook/
├── analytics/
├── news/
├── alerts/
└── trading/
```

---

# Step 1 — Domain Modeling

Professional systems begin with:

```text
Business Concepts
```

not:

```text
Widgets
```

---

# Domain Model

```text
Trader

Portfolio

Position

Order

Trade

Market

Risk

Alert
```

---

# Example

```python
from dataclasses import dataclass

@dataclass
class Position:

    symbol: str

    quantity: int

    average_price: float

    market_price: float
```

---

# Portfolio Model

```python
@dataclass
class Portfolio:

    owner: str

    positions: list[Position]
```

---

# Order Model

```python
@dataclass
class Order:

    symbol: str

    quantity: int

    price: float

    side: str
```

---

# Step 2 — State Management

Instead of:

```python
global market
```

we build:

```text
Centralized State
```

---

# Market State

```python
import param

class MarketState(

    param.Parameterized
):

    prices = param.Dict()

    orderbooks = param.Dict()

    news = param.List()
```

---

# Portfolio State

```python
class PortfolioState(

    param.Parameterized
):

    portfolios = param.Dict()
```

---

# Session State

```python
class SessionState(

    param.Parameterized
):

    user = param.String()

    permissions = param.List()
```

---

# State Architecture

```text
Market State

├── Charts
├── Alerts
├── Portfolio
├── News
└── Analytics
```

---

# Step 3 — Event Architecture

Everything communicates through events.

---

# Event Bus

```text
Market Feed

↓

Event Bus

├── Charts
├── Portfolio
├── Risk
├── Alerts
└── Analytics
```

---

# Event Example

```python
@dataclass
class PriceUpdated:

    symbol: str

    price: float
```

---

# Subscriber Example

```python
class PortfolioService:

    def handle(

        self,

        event
    ):
        ...
```

---

# Event Categories

```text
events/

├── market_events.py
├── order_events.py
├── portfolio_events.py
├── risk_events.py
└── alert_events.py
```

---

# Step 4 — Service Layer

Business logic lives here.

---

# Service Architecture

```text
services/

├── MarketService
├── PortfolioService
├── OrderService
├── RiskService
├── AlertService
└── AnalyticsService
```

---

# Example

```python
class MarketService:

    def get_price(

        self,

        symbol
    ):

        ...
```

---

# Risk Service

```python
class RiskService:

    def calculate_var(

        self,

        portfolio
    ):

        ...
```

---

# Step 5 — Repository Layer

Repositories isolate storage.

---

# Repository Architecture

```text
repositories/

├── MarketRepository
├── PortfolioRepository
├── OrderRepository
├── TradeRepository
└── UserRepository
```

---

# Example

```python
class TradeRepository:

    def load_trades(

        self,

        trader
    ):

        ...
```

---

# Step 6 — Dashboard Components

Our dashboard contains:

```text
Dashboard

├── Watchlist
├── Chart
├── Order Book
├── Portfolio
├── News
├── Analytics
└── Alerts
```

---

# Watchlist Component

```text
Watchlist

├── DBS
├── UOB
├── OCBC
└── SIA
```

---

# Chart Component

```text
Chart

├── Symbol
├── Timeframe
├── Indicators
└── Figure
```

---

# Order Book Component

```text
Order Book

BUY

41.20   5000

41.15   3000

SELL

41.25   7000
```

---

# Portfolio Component

```text
Portfolio

├── Positions
├── P&L
├── Exposure
└── Risk
```

---

# News Component

```text
News

├── Headline
├── Time
└── Summary
```

---

# Step 7 — Layout Architecture

Our terminal layout:

```text
+------------------------------------------------+
| MENU BAR                                       |
+------------------------------------------------+
| WATCHLIST | CHART               | NEWS         |
|           |                     |              |
|           |                     |              |
+------------------------------------------------+
| ORDERBOOK | PORTFOLIO           | ANALYTICS    |
+------------------------------------------------+
| STATUS BAR                                     |
+------------------------------------------------+
```

---

# Panel Template

```python
template = pn.template.FastListTemplate(
    title="SGX Terminal"
)
```

---

# Component Registration

```python
template.main.append(chart)

template.main.append(portfolio)

template.sidebar.append(watchlist)
```

---

# Step 8 — Real-Time Market Feed

Architecture:

```text
SGX Feed

↓

Kafka

↓

Market Service

↓

Event Bus

↓

Dashboard
```

---

# Update Pipeline

```text
Market Tick

↓

Event

↓

State

↓

Component Update
```

---

# Example

```python
market_state.prices[
    symbol
] = price
```

---

# Step 9 — Performance Engineering

Apply:

* caching
* batching
* throttling
* virtualization
* async processing

---

# Market Updates

Bad:

```text
10000 UI Updates/Sec
```

---

# Better:

```text
100 Updates/Sec
```

---

# Example

```text
Feed

↓

Buffer

↓

Aggregator

↓

Dashboard
```

---

# Step 10 — Background Workers

Heavy computations:

```text
VaR

Monte Carlo

Optimization
```

run outside Panel.

---

# Architecture

```text
Dashboard

↓

Redis Queue

↓

Workers

↓

Database
```

---

# Worker Example

```text
Portfolio

↓

Risk Worker

↓

Result

↓

Dashboard
```

---

# Step 11 — Authentication

Users:

```text
Trader

Manager

Administrator
```

---

# Authentication Flow

```text
Login

↓

OAuth

↓

JWT

↓

Dashboard
```

---

# Authorization

```text
Trader

↓

Own Portfolio
```

---

```text
Administrator

↓

Everything
```

---

# Step 12 — Monitoring

Monitor:

* users
* sessions
* memory
* CPU
* latency
* WebSockets

---

# Architecture

```text
Panel

↓

Prometheus

↓

Grafana
```

---

# Example Metrics

```text
Users: 1240

CPU: 45%

Memory: 8 GB

Latency: 75 ms

Market Feed: 25,000 msg/sec
```

---

# Step 13 — Deployment

Production architecture:

```text
Internet

↓

Cloudflare

↓

Load Balancer

↓

NGINX

↓

Authentication

↓

FastAPI

↓

Panel Cluster

↓

Redis

↓

Kafka

↓

Workers

↓

Database
```

---

# High Availability

```text
Panel

├── Node A
├── Node B
├── Node C
└── Node D
```

---

# Disaster Recovery

```text
Singapore Region

↓

Backup Region

↓

Recovery
```

---

# Project Directory

```text
sgx-terminal/

├── components/
│
├── services/
│
├── repositories/
│
├── domain/
│
├── state/
│
├── events/
│
├── infrastructure/
│
├── workers/
│
├── deployment/
│
├── tests/
│
└── app.py
```

---

# Component Dependency Graph

```text
Dashboard

↓

Components

↓

State

↓

Services

↓

Repositories

↓

Infrastructure
```

---

# Data Flow

```text
Market Feed

↓

Event Bus

↓

State

↓

Services

↓

Components

↓

User
```

---

# Control Flow

```text
User Action

↓

Panel

↓

Service

↓

Domain

↓

Repository

↓

Database
```

---

# Thinking Like A Bloomberg Engineer

Beginners think:

```text
Widget
```

---

Intermediate developers think:

```text
Dashboard
```

---

Architects think:

```text
System
```

---

Platform engineers think:

```text
Ecosystem
```

---

# The Hidden Secret

Bloomberg Terminal is not:

```text
One Dashboard
```

It is:

```text
Thousands

Of Components

Running On

Hundreds

Of Services
```

---

# Capstone Summary

Throughout this course, you learned:

### Foundations

* Panel widgets
* layouts
* panes
* templates

### Reactivity

* Param
* dependencies
* watchers
* state management

### Architecture

* components
* services
* repositories
* domain models

### Enterprise Engineering

* events
* CQRS
* event sourcing
* distributed systems

### Performance

* caching
* memoization
* virtualization
* async programming

### Operations

* deployment
* authentication
* Docker
* Kubernetes
* monitoring

---

# Final Mental Model

Panel applications evolve as follows:

```text
Script

↓

Dashboard

↓

Application

↓

Platform

↓

Distributed System
```

---

# Teacher's Final Notes

> The biggest lesson of this course is that dashboards are rarely about charts and widgets. At scale, dashboards become distributed systems problems involving state management, synchronization, architecture, performance, deployment, and organizational boundaries.
>
> The second lesson is that tools like Panel are not merely visualization libraries. They are application frameworks that sit at the intersection of software engineering, systems architecture, and human-computer interaction.

---

# Final Exercise

Design a complete:

```text
Bloomberg Terminal for ASEAN Markets
```

including:

* SGX
* HKEX
* SET
* Bursa Malaysia
* IDX
* PSE
* derivatives
* FX
* commodities
* portfolios
* analytics
* risk
* news
* messaging
* alerts
* monitoring
* deployment
* disaster recovery

using everything you have learned throughout this course.

---

# End of Part VI — Advanced Panel

Congratulations.

You now understand not only **how to build Panel dashboards**, but also **how professional organizations engineer large-scale, real-time, production dashboard ecosystems**.
