# Part 1 — Why Bloomberg Terminals Are Distributed Systems

---

# Building TickerHub

## Part 1: Why Bloomberg Terminals Are Distributed Systems

> Before writing a single line of code, we need to answer one question:

**What exactly are we building?**

Most developers think a financial terminal is a dashboard with:

* charts
* tables
* watchlists
* market data

That assumption is wrong.

A professional financial terminal is one of the most sophisticated desktop applications in existence.

Systems like:

* Bloomberg L.P. Terminal
* London Stock Exchange Group Workspace
* CQG, Inc.
* FactSet Research Systems

are actually distributed systems disguised as desktop applications.

---

# What Does a Financial Terminal Actually Do?

A professional trader's workstation typically provides:

### Real-time market data

```text
Stocks
Futures
Options
Forex
Bonds
Crypto
```

---

### News feeds

```text
Breaking news
Corporate announcements
Economic events
Analyst reports
```

---

### Analytics

```text
PnL
Risk
Exposure
VaR
Factor models
Scenarios
```

---

### Order Management

```text
Orders
Trades
Execution
Position management
```

---

### Collaboration

```text
Messaging
Notes
Alerts
Shared workspaces
```

---

### Historical Data

```text
Tick data
OHLC data
Corporate actions
Economic series
```

---

### Monitoring

```text
Latency
Connectivity
Feed health
Session health
```

---

# This Is Not a Dashboard

A dashboard usually looks like this:

```text
Database
    ↓
Backend
    ↓
Frontend
```

Simple.

A financial terminal looks like this:

```text
Market Feed
      ↓
Kafka
      ↓
Market Services
      ↓
Event Bus
      ↓
Risk Services
      ↓
Portfolio Services
      ↓
Caches
      ↓
UI Components
      ↓
Browser
```

There are many moving parts.

Data is constantly flowing.

Everything changes every second.

---

# Why Financial Systems Become Distributed

Imagine the price of DBS changes.

```text
DBS = 44.10
```

Who needs to know?

Potentially:

* Watchlist
* Charts
* Order Book
* Portfolio
* Risk Engine
* Alerts
* News Correlation Engine
* User Notifications

One event may affect dozens of components.

---

# Naive Architecture

Many beginners write:

```python
watchlist.update()

chart.update()

portfolio.update()

risk.update()

alerts.update()
```

This works for toy applications.

It fails completely in professional systems.

Why?

Because components become tightly coupled.

The market service suddenly knows:

* every chart,
* every table,
* every risk model,
* every notification.

This architecture collapses under complexity.

---

# The Professional Approach

Instead:

```text
MarketService

publishes

PriceUpdated
```

Everyone else subscribes.

```text
PriceUpdated
       ↓
 ┌─────┼─────┐
 │     │     │
Chart Portfolio Alerts
```

This is called:

# Event-Driven Architecture

---

# Everything Is an Event

Professional trading systems think in events.

```text
PriceUpdated
TradeExecuted
OrderPlaced
PositionChanged
RiskCalculated
NewsPublished
```

Systems communicate using events instead of function calls.

This gives us:

### Loose coupling

### Scalability

### Fault isolation

### Better testing

### Easier extension

---

# Why We Are Building TickerHub This Way

TickerHub follows exactly the same principle.

Instead of:

```text
Widgets
```

we build:

```text
Domain
     ↓
State
     ↓
Events
     ↓
Services
     ↓
Infrastructure
     ↓
Workers
     ↓
UI
```

The user interface becomes merely another consumer of data.

---

# The TickerHub Architecture

Our architecture will look like this:

```text
                         INTERNET
                              |
                        Cloudflare
                              |
                       Load Balancer
                              |
                            NGINX
                              |
                   Authentication Gateway
                              |
                    FastAPI API Gateway
                              |
                    ┌─────────┴─────────┐
                    │                   │
                Panel Cluster      REST APIs
                    │                   │
                    └─────────┬─────────┘
                              │
                         Event Bus
                              │
        ┌──────────────┬──────┴─────────┬─────────────┐
        │              │                │             │
   MarketSvc     PortfolioSvc      RiskSvc      AlertSvc
        │              │                │             │
        └──────────────┴────────────────┴─────────────┘
                              │
                           Redis
                              │
                           Kafka
                              │
                        Market Feed
                              │
                        PostgreSQL
```

This may look overwhelming.

By the end of this series, every single box will make sense.

---

# Why Use Panel?

Most tutorials would choose:

* React
* Vue
* Angular

We're deliberately choosing:

Panel

because:

### Python everywhere

No context switching.

---

### Reactive state management

Excellent integration with:

Param

---

### Rapid prototyping

Perfect for analytics applications.

---

### Bokeh server architecture

Provides:

* sessions
* websockets
* server-side state
* streaming updates

which are exactly what professional terminals need.

---

# Why Hybrid Cloud?

Professional infrastructure is heavy.

Running locally:

* Kafka
* PostgreSQL
* Redis
* Monitoring stack

can easily consume:

```text
8GB+
RAM
```

Your laptop becomes:

```text
🐌
```

Instead, we'll use:

* Supabase
* Upstash
* managed Kafka providers

Our laptop becomes:

```text
Editor
+
Panel
+
Python
```

Everything else runs in the cloud.

This mirrors how professional teams work.

---

# Development Philosophy

Throughout this series we will follow six principles.

## 1. Asynchronous First

Everything external is async.

---

## 2. Event-Driven

Everything important becomes an event.

---

## 3. State Is Central

UI is derived from state.

---

## 4. Components Are Independent

No widget talks directly to another widget.

---

## 5. Infrastructure Is Replaceable

Today:

```text
Supabase
```

Tomorrow:

```text
AWS RDS
```

No code changes.

---

## 6. Build for Production From Day One

No throwaway architecture.

No tutorial shortcuts.

---

# What We Will Build

By the end of the series:

✅ Market data streaming

✅ Event bus

✅ Portfolio engine

✅ Risk engine

✅ Real-time dashboards

✅ Background workers

✅ Redis cache

✅ PostgreSQL persistence

✅ Authentication

✅ Monitoring

✅ Docker deployment

✅ Hugging Face deployment

---

# Architecture Lesson #1

Professional applications are not built starting with:

```python
pn.widgets.Button()
```

They are built starting with:

```text
Business Concepts
       ↓
Domain Models
       ↓
Events
       ↓
Services
       ↓
Infrastructure
       ↓
User Interface
```

The UI is the final layer.

Not the first.

---

# In Part 2

We will build our **Hybrid Cloud Development Environment**, connect our laptop to:

* Supabase
* Upstash Redis
* Kafka

and create the infrastructure foundation that everything else in TickerHub will sit on.
