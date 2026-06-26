# Building TickerHub

## Part 7: The Repository Pattern — Separating Business Logic from Infrastructure

> One of the fastest ways to destroy a large software system is to allow business logic to know too much about infrastructure.

Many developers write code like this:

```python
def get_portfolio(user):

    conn = psycopg.connect(...)

    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM positions"
    )

    return cursor.fetchall()
```

This works.

Until:

* you add caching,
* you add retries,
* you add connection pooling,
* you add auditing,
* you add replicas,
* you add cloud migration,
* you add failover.

Now your business logic is trapped inside your infrastructure.

Professional systems avoid this.

---

# The Core Principle

The domain layer should never know:

* PostgreSQL
* Redis
* Kafka
* HTTP APIs
* Cloud providers
* File systems

The domain should only know:

```text
I need data.
```

This idea is called:

# Dependency Inversion

Instead of:

```text
Business
     ↓
Database
```

we build:

```text
Business
     ↓
Repository
     ↓
Database
```

---

# What Is a Repository?

A repository is:

> An abstraction that makes external data sources appear as in-memory collections.

Instead of:

```python
price = postgres.execute(
    "SELECT ..."
)
```

we write:

```python
price = repository.get_price(
    "D05"
)
```

The service no longer cares:

* where the data came from,
* how it was cached,
* how it was retrieved,
* how long it took.

---

# TickerHub Repository Architecture

Our architecture becomes:

```text
Services
     |
     V
Repositories
     |
     V
Infrastructure
     |
     V
Cloud Services
```

---

# Repository Structure

Create:

```text
repositories/

    __init__.py

    market_repository.py

    portfolio_repository.py

    risk_repository.py

    order_repository.py

    cache_repository.py
```

---

# Repository Responsibilities

| Repository          | Responsibility              |
| ------------------- | --------------------------- |
| MarketRepository    | quotes, prices, order books |
| PortfolioRepository | positions, portfolios       |
| RiskRepository      | risk analytics              |
| OrderRepository     | orders, trades              |
| CacheRepository     | Redis access                |

---

# Market Repository

Create:

## repositories/market_repository.py

```python
from infrastructure.redis import cache


class MarketRepository:

    async def get_price(
        self,
        symbol: str
    ):

        ...
```

---

# Why Async?

Remember:

```text
Laptop
     |
Internet
     |
Cloud Redis
```

Every operation is remote.

Therefore:

```python
await repository.get_price()
```

instead of:

```python
repository.get_price()
```

---

# Step 1 — Check Cache

```python
async def get_price(
    self,
    symbol
):

    cached = await cache.get(
        symbol
    )

    if cached:

        return float(
            cached
        )
```

---

# Step 2 — Fallback to Database

```python
price = await self.fetch_db(
    symbol
)
```

---

# Step 3 — Update Cache

```python
await cache.set(

    symbol,

    price,

    ex=60
)
```

---

# Final Method

```python
async def get_price(
    self,
    symbol
):

    cached = await cache.get(
        symbol
    )

    if cached:

        return float(
            cached
        )

    price = await self.fetch_db(
        symbol
    )

    await cache.set(

        symbol,

        price,

        ex=60
    )

    return price
```

---

# What Did We Gain?

The caller simply writes:

```python
price = await repo.get_price(
    "D05"
)
```

They don't know:

* Redis exists,
* PostgreSQL exists,
* caching exists.

This is architectural isolation.

---

# Portfolio Repository

Create:

## repositories/portfolio_repository.py

```python
from domain.portfolio import (
    Portfolio
)


class PortfolioRepository:

    async def load(
        self,
        user: str
    ) -> Portfolio:

        ...

    async def save(
        self,
        portfolio: Portfolio
    ):

        ...
```

---

# Example Load

```python
portfolio = await repo.load(
    "alice"
)
```

No SQL appears in the service layer.

Ever.

---

# Example Save

```python
await repo.save(
    portfolio
)
```

Again:

No SQL.

No ORM.

No infrastructure leakage.

---

# Why Hide SQL?

Suppose today we use:

```text
PostgreSQL
```

Tomorrow:

```text
Snowflake
```

Or:

```text
BigQuery
```

Or:

```text
DuckDB
```

The service code remains unchanged.

Only the repository changes.

---

# Risk Repository

Create:

## repositories/risk_repository.py

```python
from domain.risk import Risk


class RiskRepository:

    async def save(
        self,
        risk: Risk
    ):

        ...

    async def load(
        self,
        portfolio_id: str
    ) -> Risk:

        ...
```

---

# Order Repository

Create:

## repositories/order_repository.py

```python
from domain.order import Order
from domain.trade import Trade


class OrderRepository:

    async def save_order(
        self,
        order: Order
    ):

        ...

    async def save_trade(
        self,
        trade: Trade
    ):

        ...

    async def load_order(
        self,
        order_id: str
    ):

        ...
```

---

# The Repository Pattern in Practice

Without repositories:

```text
MarketService
      |
      +---- Redis
      |
      +---- PostgreSQL
      |
      +---- Kafka
      |
      +---- REST APIs
```

With repositories:

```text
MarketService
      |
      V
MarketRepository
      |
      +---- Redis
      |
      +---- PostgreSQL
      |
      +---- Kafka
```

Complexity moves downward.

---

# Building a Base Repository

Eventually we'll create:

## repositories/base.py

```python
class Repository:

    async def retry(
        self,
        fn,
        retries=3
    ):

        for _ in range(
            retries
        ):

            try:

                return await fn()

            except Exception:

                continue

        raise Exception(
            "failed"
        )
```

---

# Why Retries Matter

Cloud infrastructure fails.

Example:

```text
Redis timeout
```

Should not become:

```text
Application crash
```

Instead:

```text
Redis timeout
       ↓
Retry
       ↓
Success
```

---

# Connection Pooling

Never do this:

```python
async def load():

    connection = connect()

    ...
```

Professional systems create pools.

Example:

```python
engine = create_async_engine(

    url,

    pool_size=20,

    max_overflow=50,

    pool_pre_ping=True
)
```

Benefits:

* lower latency,
* fewer connections,
* higher throughput.

---

# Repository Caching

Professional systems almost always implement:

```text
Cache Aside
```

Pattern:

```text
Request
    |
    V
Redis
    |
miss?
    |
    V
Database
    |
    V
Redis
    |
    V
Response
```

This is exactly what we'll use.

---

# Read Repository vs Write Repository

As systems grow, repositories often split.

Example:

```text
PortfolioReadRepository

PortfolioWriteRepository
```

This concept is called:

# CQRS

(Command Query Responsibility Segregation)

---

# Example

Reads:

```python
portfolio = await read_repo.load(
    user
)
```

Writes:

```python
await write_repo.save(
    portfolio
)
```

Benefits:

* independent scaling,
* independent optimization,
* independent caching.

---

# Repository Interfaces

Professional systems often define interfaces.

Example:

```python
from abc import ABC
from abc import abstractmethod


class PortfolioRepository(
    ABC
):

    @abstractmethod
    async def load(
        self,
        user
    ):
        pass

    @abstractmethod
    async def save(
        self,
        portfolio
    ):
        pass
```

---

# Implementations

```text
PortfolioRepository
          |
          |
          +------ PostgreSQLPortfolioRepository

          +------ RedisPortfolioRepository

          +------ MockPortfolioRepository
```

---

# Why Mock Repositories Matter

Testing becomes easy.

Example:

```python
repo = MockPortfolioRepository()

portfolio = await repo.load(
    "alice"
)
```

No database.

No Redis.

No network.

This is why enterprise systems love repositories.

---

# Graceful Degradation

Professional systems expect failure.

Bad:

```python
price = await redis.get(
    symbol
)
```

Good:

```python
try:

    price = await redis.get(
        symbol
    )

except Exception:

    price = await database.fetch(
        symbol
    )
```

Better:

```text
Redis
    ↓
PostgreSQL
    ↓
Local Cache
    ↓
Default Value
```

---

# The Repository Layer Architecture

Our system now looks like:

```text
                Services
                     |
                     |
          ┌──────────┼──────────┐
          │          │          │

          ▼          ▼          ▼

      Market     Portfolio    Risk
     Repository Repository Repository

          │          │          │

          └──────────┼──────────┘
                     |
                     ▼

              Infrastructure

                     |
                     ▼

        Redis + PostgreSQL + Kafka
```

Notice:

Services never talk to infrastructure directly.

---

# Why Bloomberg-Style Systems Use Repositories

Because infrastructure changes.

Business rules rarely do.

Example:

Today:

```text
Redis
```

Tomorrow:

```text
Valkey
```

No business changes.

Today:

```text
PostgreSQL
```

Tomorrow:

```text
CockroachDB
```

No business changes.

Today:

```text
Kafka
```

Tomorrow:

```text
Redpanda
```

No business changes.

The repository layer protects the business from technological churn.

---

# Architecture Lesson #7

Beginners write:

```python
service
    .execute_sql()
```

Professionals write:

```python
service
    .repository
    .load()
```

The database is an implementation detail.

The business is not.

---

# Current Architecture

After Part 7, our architecture has become:

```text
Panel UI
      |
      V
State
      |
      V
Services
      |
      V
Event Bus
      |
      V
Repositories
      |
      V
Infrastructure
      |
      V
Redis
Kafka
PostgreSQL
```

At this point, we have built:

✅ Domain model

✅ State engine

✅ Event bus

✅ Repository layer

But we still don't have a working application.

That's because we have been building:

```text
The Engine
```

before building:

```text
The Dashboard
```

which is exactly how professional systems are constructed.

---

# In Part 8

We will build the first real service in TickerHub:

# MarketService

where you'll discover that a professional market feed handler is actually:

```text
State Machine
        +
Event Producer
        +
Cache Manager
        +
Synchronization Engine
```

all hidden behind a deceptively simple class called:

```python
MarketService
```
