# Building TickerHub

## Part 3: Designing the Repository Structure and Engineering Architecture

> Most software projects fail long before they fail in production.
>
> They fail in the filesystem.

A surprising amount of software engineering complexity comes not from algorithms, databases, or cloud infrastructure.

It comes from this question:

> **Where should the code go?**

Many tutorials teach architecture like this:

```text
frontend/
backend/
database/
```

or worse:

```text
utils.py
helpers.py
common.py
misc.py
```

This works for projects with:

* 2 files,
* 1 developer,
* 0 future requirements.

TickerHub is not one of those projects.

We are building:

* a real-time system,
* an event-driven system,
* a distributed system,
* a financial system,
* a collaborative system.

This requires architectural boundaries.

---

# The Fundamental Principle

The most important rule of TickerHub is:

> Code is organized around business responsibilities, not technologies.

Bad:

```text
models/
controllers/
services/
views/
```

Good:

```text
market/
portfolio/
risk/
orders/
alerts/
```

because businesses think in domains, not frameworks.

---

# The Four Architectural Layers

TickerHub follows a layered architecture.

```text
Presentation
       ↓
Application
       ↓
Domain
       ↓
Infrastructure
```

Let's define them.

---

## Layer 1 — Presentation

Presentation is everything the user sees.

Examples:

```text
Panel
Charts
Tables
Watchlists
Order Books
Forms
Dashboards
```

Directory:

```text
components/
app/
```

---

## Layer 2 — Application

Application code orchestrates workflows.

Examples:

```text
MarketService
PortfolioService
RiskService
AlertService
```

Directory:

```text
services/
workers/
api/
```

---

## Layer 3 — Domain

The domain layer contains the business itself.

Examples:

```text
Position
Portfolio
Order
Trade
Risk
Exposure
```

Directory:

```text
domain/
events/
```

---

## Layer 4 — Infrastructure

Infrastructure connects us to the outside world.

Examples:

```text
PostgreSQL
Redis
Kafka
HTTP APIs
Cloud Services
```

Directory:

```text
repositories/
infrastructure/
deployment/
```

---

# The Complete Repository

Our repository now becomes:

```text
tickerhub/

├── app/
│
├── api/
│
├── components/
│   ├── charts/
│   ├── watchlist/
│   ├── orderbook/
│   ├── portfolio/
│   ├── analytics/
│   ├── news/
│   └── alerts/
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
├── workers/
│
├── infrastructure/
│
├── deployment/
│
├── tests/
│
├── docs/
│
├── scripts/
│
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── app.py
```

---

# Why Not MVC?

Most tutorials teach:

```text
Models
Views
Controllers
```

MVC works well for:

* forms,
* CRUD,
* websites.

Financial terminals are not CRUD applications.

Consider:

```text
Price Tick Arrives
        ↓
Market Service Updates
        ↓
Event Published
        ↓
Portfolio Recalculated
        ↓
Risk Updated
        ↓
Alert Triggered
        ↓
UI Updated
```

Where does this fit in MVC?

It doesn't.

Instead, we use:

```text
Domain
     ↓
Events
     ↓
Services
     ↓
State
     ↓
UI
```

---

# Modular Monolith Architecture

TickerHub will initially be built as a:

# Modular Monolith

Meaning:

```text
One repository
One deployment
Multiple modules
```

rather than:

```text
100 microservices
100 repos
100 deployments
100 problems
```

---

# Why Not Microservices?

Beginners often assume:

```text
Professional
      =
Microservices
```

This is false.

Microservices introduce:

* networking,
* service discovery,
* retries,
* authentication,
* tracing,
* deployment complexity,
* operational overhead.

For TickerHub, we instead build:

```text
              TickerHub

    ┌──────────┬──────────┬──────────┐
    │          │          │          │
 Market    Portfolio    Risk     Alert
 Module     Module     Module    Module
```

Each module behaves like a microservice internally.

---

# The Domain Layer

The domain layer contains business concepts.

Create:

```text
domain/

    __init__.py

    position.py
    portfolio.py
    order.py
    trade.py
    quote.py
    instrument.py
    risk.py
```

---

# Example Domain Relationships

```text
Instrument
      |
      |
      V
   Position
      |
      |
      V
  Portfolio
      |
      |
      V
     Risk
```

---

# The State Layer

Panel applications are state machines.

Create:

```text
state/

    market_state.py
    portfolio_state.py
    risk_state.py
    session_state.py
    workspace_state.py
```

---

# State Responsibilities

### MarketState

```text
prices
quotes
orderbooks
trades
news
```

---

### PortfolioState

```text
positions
pnl
portfolio_value
exposure
```

---

### RiskState

```text
VaR
CVaR
stress_tests
limits
```

---

### SessionState

```text
user
permissions
authentication
preferences
```

---

### WorkspaceState

```text
layouts
watchlists
open_windows
themes
```

---

# The Events Layer

Events are the backbone of TickerHub.

Create:

```text
events/

    base.py

    market_events.py

    portfolio_events.py

    risk_events.py

    order_events.py
```

---

Example:

```text
PriceUpdated
PortfolioChanged
TradeExecuted
RiskCalculated
OrderPlaced
AlertTriggered
```

---

# The Services Layer

Services implement business workflows.

Create:

```text
services/

    market_service.py

    portfolio_service.py

    risk_service.py

    order_service.py

    alert_service.py
```

---

Example:

```text
MarketService

receives:

    market tick

produces:

    PriceUpdated event
```

---

# The Repository Layer

Repositories isolate infrastructure.

Create:

```text
repositories/

    market_repository.py

    portfolio_repository.py

    risk_repository.py

    order_repository.py
```

---

The service never knows:

```text
PostgreSQL
Redis
REST API
CSV file
```

It only knows:

```python
repository.load()
repository.save()
```

This principle is called:

# Dependency Inversion

---

# The Workers Layer

Workers perform background computation.

Create:

```text
workers/

    feed_worker.py

    risk_worker.py

    alert_worker.py

    analytics_worker.py
```

---

Example:

```text
Market Feed
       |
       V
Feed Worker
       |
       V
Market Service
       |
       V
Event Bus
```

---

# The Components Layer

UI components remain isolated.

Create:

```text
components/

    charts/

    watchlist/

    orderbook/

    portfolio/

    analytics/

    news/

    alerts/
```

---

Rule:

```text
Watchlist
      X
cannot call
      X
Portfolio
```

Instead:

```text
Watchlist
     ↓
State
     ↓
Portfolio
```

This eliminates component coupling.

---

# The Infrastructure Layer

Create:

```text
infrastructure/

    config.py

    postgres.py

    redis.py

    kafka.py

    logging.py

    security.py
```

---

This layer owns:

```text
networking
authentication
database connections
cache connections
message brokers
configuration
```

---

# The Deployment Layer

Create:

```text
deployment/

    docker/

    kubernetes/

    nginx/

    terraform/
```

---

Eventually:

```text
deployment/

    docker/
        Dockerfile

    kubernetes/
        panel.yaml
        redis.yaml
        postgres.yaml
        kafka.yaml

    nginx/
        nginx.conf

    terraform/
        main.tf
```

---

# The Tests Layer

Testing mirrors the application.

```text
tests/

    test_domain/

    test_services/

    test_events/

    test_repositories/

    test_workers/

    test_components/
```

---

Example:

```text
services/

    market_service.py

tests/

    test_services/
        test_market_service.py
```

---

# Dependency Direction

Our dependency graph always flows downward.

```text
Components
      ↓
Services
      ↓
Domain
      ↓
Repositories
      ↓
Infrastructure
```

Never:

```text
Infrastructure
      ↑
Services
      ↑
Components
```

This single rule prevents architectural collapse.

---

# The Golden Rule

Every file in TickerHub must answer one question:

> Who owns this responsibility?

For example:

### Wrong

```text
helpers.py
utils.py
misc.py
shared.py
common.py
```

These are architecture graveyards.

---

### Correct

```text
portfolio_service.py

owns

portfolio business logic
```

```text
risk_worker.py

owns

risk calculations
```

```text
market_repository.py

owns

market persistence
```

Ownership creates maintainability.

---

# Our Architecture After Part 3

```text
User
  |
Panel
  |
Components
  |
State
  |
Services
  |
Events
  |
Repositories
  |
Infrastructure
  |
Cloud Services
```

Notice something important.

We still haven't built:

* a chart,
* a watchlist,
* a table,
* a dashboard.

Because professional systems are built:

```text
Architecture First
        ↓
Features Second
```

---

# Architecture Lesson #3

Bad architecture asks:

> Where should I put this file?

Good architecture asks:

> Which business responsibility owns this behavior?

---

# In Part 4

We begin building the actual business engine of TickerHub by implementing:

* `Position`
* `Portfolio`
* `Order`
* `Trade`
* `Instrument`
* `Quote`

and introducing **Domain-Driven Design for financial systems**.
