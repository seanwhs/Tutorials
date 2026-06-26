# Capstone Project Solution

# Building a Production-Grade SGX Professional Trading Terminal with Panel

> **Capstone Goal**
>
> Build a Bloomberg-style professional trading workstation using:
>
> * Panel
> * Param
> * FastAPI
> * Redis
> * Kafka
> * PostgreSQL
> * Docker
> * Event-driven architecture
> * Component-oriented design
> * Enterprise deployment patterns

---

# Final Architecture

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

---

# Project Structure

```text
sgx-terminal/

├── app/
│
├── components/
│   ├── charts/
│   ├── watchlist/
│   ├── orderbook/
│   ├── portfolio/
│   ├── news/
│   ├── analytics/
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
├── api/
│
├── deployment/
│
├── tests/
│
└── app.py
```

---

# Phase 1 — Domain Model

Professional systems start with business concepts.

---

## domain/position.py

```python
from dataclasses import dataclass


@dataclass
class Position:

    symbol: str
    quantity: int
    average_price: float
    market_price: float

    @property
    def market_value(self):

        return self.quantity * self.market_price

    @property
    def pnl(self):

        return (
            self.market_price
            - self.average_price
        ) * self.quantity
```

---

## domain/portfolio.py

```python
from dataclasses import dataclass, field
from typing import List

from .position import Position


@dataclass
class Portfolio:

    owner: str

    positions: List[Position] = field(
        default_factory=list
    )

    @property
    def value(self):

        return sum(
            p.market_value
            for p in self.positions
        )

    @property
    def pnl(self):

        return sum(
            p.pnl
            for p in self.positions
        )
```

---

## domain/order.py

```python
from dataclasses import dataclass


@dataclass
class Order:

    order_id: str

    symbol: str

    side: str

    quantity: int

    price: float
```

---

## domain/trade.py

```python
from dataclasses import dataclass
from datetime import datetime


@dataclass
class Trade:

    trade_id: str

    symbol: str

    quantity: int

    price: float

    timestamp: datetime
```

---

# Phase 2 — Application State

---

## state/market_state.py

```python
import param


class MarketState(
    param.Parameterized
):

    prices = param.Dict()

    orderbooks = param.Dict()

    trades = param.List()

    news = param.List()
```

---

## state/portfolio_state.py

```python
import param


class PortfolioState(
    param.Parameterized
):

    portfolios = param.Dict()
```

---

## state/session_state.py

```python
import param


class SessionState(
    param.Parameterized
):

    user = param.String()

    permissions = param.List()
```

---

# Phase 3 — Event Bus

---

## events/base.py

```python
from collections import defaultdict


class EventBus:

    def __init__(self):

        self.handlers = defaultdict(list)

    def subscribe(
        self,
        event,
        handler
    ):

        self.handlers[event].append(
            handler
        )

    def publish(
        self,
        event
    ):

        for handler in self.handlers[
            type(event)
        ]:

            handler(event)
```

---

## events/market_events.py

```python
from dataclasses import dataclass


@dataclass
class PriceUpdated:

    symbol: str

    price: float
```

---

# Phase 4 — Repository Layer

---

## repositories/market_repository.py

```python
class MarketRepository:

    def get_price(
        self,
        symbol
    ):

        ...
```

---

## repositories/portfolio_repository.py

```python
class PortfolioRepository:

    def load(
        self,
        user
    ):

        ...

    def save(
        self,
        portfolio
    ):

        ...
```

---

# Phase 5 — Service Layer

---

## services/market_service.py

```python
class MarketService:

    def __init__(
        self,
        state,
        bus
    ):

        self.state = state

        self.bus = bus

    def update_price(
        self,
        symbol,
        price
    ):

        self.state.prices[
            symbol
        ] = price

        self.bus.publish(

            PriceUpdated(
                symbol,
                price
            )
        )
```

---

## services/portfolio_service.py

```python
class PortfolioService:

    def __init__(
        self,
        state
    ):

        self.state = state

    def get_portfolio(
        self,
        user
    ):

        return self.state.portfolios[
            user
        ]
```

---

## services/risk_service.py

```python
class RiskService:

    def calculate_var(
        self,
        portfolio
    ):

        return portfolio.value * 0.03
```

---

# Phase 6 — Dashboard Components

---

## components/watchlist.py

```python
import panel as pn


class Watchlist:

    def __init__(self):

        self.stocks = pn.widgets.MultiSelect(

            options=[
                "D05",
                "U11",
                "O39",
                "C6L"
            ]
        )

    def panel(self):

        return self.stocks
```

---

## components/chart.py

```python
import panel as pn


class ChartComponent:

    def __init__(self):

        self.symbol = pn.widgets.Select(

            options=[
                "D05",
                "U11",
                "O39"
            ]
        )

        self.chart = pn.pane.Markdown(

            "Chart"
        )

    def panel(self):

        return pn.Column(

            self.symbol,

            self.chart
        )
```

---

## components/orderbook.py

```python
import panel as pn


class OrderBook:

    def __init__(self):

        self.table = pn.widgets.Tabulator()

    def panel(self):

        return self.table
```

---

## components/portfolio.py

```python
import panel as pn


class PortfolioPanel:

    def __init__(self):

        self.table = pn.widgets.Tabulator()

    def panel(self):

        return self.table
```

---

# Phase 7 — Dashboard Layout

---

```python
import panel as pn

template = pn.template.FastListTemplate(

    title="SGX Terminal"
)
```

---

```python
watchlist = Watchlist()

chart = ChartComponent()

orderbook = OrderBook()

portfolio = PortfolioPanel()
```

---

```python
template.sidebar.append(

    watchlist.panel()
)

template.main.append(

    pn.Row(

        chart.panel(),

        orderbook.panel()
    )
)

template.main.append(

    portfolio.panel()
)
```

---

# Phase 8 — Market Feed

---

## workers/feed_worker.py

```python
import asyncio
import random


async def market_feed():

    while True:

        yield {

            "symbol": "D05",

            "price": random.randint(
                20,
                50
            )
        }

        await asyncio.sleep(
            0.1
        )
```

---

## feed processor

```python
async for tick in market_feed():

    market_service.update_price(

        tick["symbol"],

        tick["price"]
    )
```

---

# Phase 9 — Caching

---

## Redis cache

```python
import redis


cache = redis.Redis(
    host="redis"
)
```

---

```python
def get_price(
    symbol
):

    cached = cache.get(
        symbol
    )

    if cached:

        return cached

    value = database.fetch(
        symbol
    )

    cache.set(
        symbol,
        value
    )

    return value
```

---

# Phase 10 — Background Workers

---

```text
Dashboard

↓

Redis Queue

↓

Risk Worker

↓

Database

↓

Dashboard
```

---

## workers/risk_worker.py

```python
while True:

    portfolio = queue.get()

    risk = calculate_var(
        portfolio
    )

    save(risk)
```

---

# Phase 11 — FastAPI

---

## api/main.py

```python
from fastapi import FastAPI

app = FastAPI()
```

---

```python
@app.get(
    "/prices/{symbol}"
)
def get_price(
    symbol
):

    return {

        "price":

        market_service.get_price(
            symbol
        )
    }
```

---

# Phase 12 — Authentication

---

```text
User

↓

OAuth2

↓

JWT

↓

Panel Session
```

---

Example:

```python
def authenticate(
    token
):

    return jwt.decode(
        token
    )
```

---

# Phase 13 — Docker

---

## Dockerfile

```dockerfile
FROM python:3.12

WORKDIR /app

COPY . .

RUN pip install -r requirements.txt

EXPOSE 5006

CMD [
    "panel",
    "serve",
    "app.py",
    "--address",
    "0.0.0.0"
]
```

---

# docker-compose.yml

```yaml
services:

  panel:

    build: .

    ports:
      - "5006:5006"

  redis:

    image: redis

  postgres:

    image: postgres

  kafka:

    image: apache/kafka
```

---

# Phase 14 — Reverse Proxy

---

## nginx.conf

```nginx
server {

    listen 443 ssl;

    location / {

        proxy_pass
            http://panel:5006;

        proxy_http_version 1.1;

        proxy_set_header Upgrade
            $http_upgrade;

        proxy_set_header Connection
            "upgrade";
    }
}
```

---

# Phase 15 — Monitoring

---

```text
Panel

↓

Prometheus

↓

Grafana
```

---

Metrics:

```text
Users            : 1254
Sessions         : 1198
CPU              : 41%
Memory           : 8.2GB
Latency          : 72ms
WebSockets       : 1120
Feed Rate        : 35,000/sec
```

---

# Phase 16 — Deployment

---

```text
                       INTERNET
                            |
                       Cloudflare
                            |
                    AWS Load Balancer
                            |
                         NGINX
                            |
                     Authentication
                            |
                         FastAPI
                            |
                  Kubernetes Cluster
                            |
            ┌────────────┬────────────┐
            │            │            │
         Panel        Panel       Panel
          Pod          Pod         Pod
            │            │            │
            └────────────┴────────────┘
                            |
                         Redis
                            |
                         Kafka
                            |
                     Worker Pool
                            |
                      PostgreSQL
                            |
                      Market Feed
```

---

# Kubernetes

```text
cluster/

├── panel-deployment.yaml
├── panel-service.yaml
├── redis.yaml
├── kafka.yaml
├── postgres.yaml
└── ingress.yaml
```

---

# Final Architecture Diagram

```text
                          USER
                            |
                      Panel UI
                            |
                      Components
                            |
                    Shared State
                            |
                       Event Bus
                            |
          ┌─────────────────┼─────────────────┐
          │                 │                 │
     MarketSvc        PortfolioSvc      RiskSvc
          │                 │                 │
          └─────────────────┼─────────────────┘
                            |
                      Repositories
                            |
          ┌─────────────────┼─────────────────┐
          │                 │                 │
        Redis            Kafka          PostgreSQL
          │                 │                 │
          └─────────────────┼─────────────────┘
                            |
                       Market Feed
```

---

# Final Enterprise Lessons

The capstone demonstrates that professional Panel applications are not:

```text
Widgets

+

Charts
```

They are:

```text
Distributed Systems

+

State Machines

+

Event Systems

+

Service Architectures

+

Infrastructure Platforms

+

User Interfaces
```

---

# Final Repository Structure

```text
sgx-terminal/

├── app/
├── api/
├── components/
├── state/
├── domain/
├── services/
├── repositories/
├── events/
├── workers/
├── infrastructure/
├── deployment/
├── tests/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── app.py
```

This architecture is effectively the minimum viable blueprint for building a Bloomberg-style professional trading terminal using the Panel ecosystem.
