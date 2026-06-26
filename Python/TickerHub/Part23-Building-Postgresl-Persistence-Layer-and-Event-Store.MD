# Building TickerHub

## Part 23: Building the PostgreSQL Persistence Layer & Event Store — Turning History into a First-Class System Component

> Redis remembers what is happening.
>
> PostgreSQL remembers what happened.

Up until now, TickerHub has become a sophisticated real-time system:

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

Redis
      |
      V

Panel
```

This architecture gives us:

* speed,
* scalability,
* responsiveness,
* real-time synchronization.

But it has one major weakness:

```text
Memory is not history.
```

If Redis crashes:

```text
Current state disappears.
```

If Kafka retention expires:

```text
Old events disappear.
```

If regulators ask:

> What happened last Tuesday at 09:32:14?

we need something else.

That something is:

```text
Persistence
```

---

# The Beginner Database

Most developers think of databases as:

```text
Storage
```

Example:

```sql
SELECT *
FROM portfolio
```

or:

```sql
UPDATE position
SET quantity=100
```

This works.

Until you need:

* audit trails,
* replay,
* regulatory compliance,
* historical analysis,
* disaster recovery,
* forensic investigation.

Then the database becomes:

```text
System Memory
```

---

# Professional Architecture

Professional financial systems separate:

```text
Current Truth

from

Historical Truth
```

---

# Current Truth

Stored in:

```text
Redis
```

Contains:

```text
Current Prices
Current Positions
Current Risk
Current Alerts
```

---

# Historical Truth

Stored in:

```text
PostgreSQL
```

Contains:

```text
Trades
Orders
Events
Risk History
News History
Audit Logs
```

---

# Storage Architecture

```text
Market Feed
       |
       V

Kafka
       |
       V

Services
       |
       +------ Redis
       |
       +------ PostgreSQL
```

---

# Why PostgreSQL?

Because PostgreSQL provides:

* ACID transactions,
* consistency,
* JSON support,
* indexing,
* partitioning,
* analytics,
* reliability.

For financial systems:

```text
PostgreSQL
=
Legal Record
```

---

# Hybrid Cloud

For TickerHub:

```text
Laptop
      |
      V

Supabase PostgreSQL
```

Examples:

```text
Supabase

Neon

AWS RDS
```

---

# Environment Variables

Add:

```bash
DATABASE_URL=
DATABASE_USER=
DATABASE_PASSWORD=
```

---

# Install Async Driver

```bash
pip install asyncpg
```

---

# Configuration

Create:

```text
infrastructure/

    postgres.py
```

---

```python
import asyncpg
```

---

Create pool:

```python
pool = await asyncpg.create_pool(

    DATABASE_URL
)
```

---

# Why Pools?

Without pooling:

```text
Open Connection

↓

Query

↓

Close Connection
```

For every request.

---

With pooling:

```text
Connection Pool

↓

Reuse Connections
```

---

# First Table

Create:

```sql
CREATE TABLE prices (

    symbol TEXT,

    price NUMERIC,

    timestamp TIMESTAMP
);
```

---

# Insert

```python
await conn.execute(

    """
    INSERT INTO prices
    VALUES($1,$2,$3)
    """,

    symbol,

    price,

    timestamp
)
```

---

# Query

```python
rows = await conn.fetch(

    """
    SELECT *
    FROM prices
    """
)
```

---

# But This Is Wrong

Professional systems rarely store:

```text
Current State
```

Instead they store:

```text
Events
```

---

# Event Store

Create:

```sql
CREATE TABLE events (

    event_id UUID,

    event_type TEXT,

    aggregate_id TEXT,

    payload JSONB,

    created_at TIMESTAMP
);
```

---

# Example Event

```json
{
    "event_type":
        "PriceUpdated",

    "aggregate_id":
        "D05",

    "payload":
    {
        "price":42.5
    }
}
```

---

# Another Event

```json
{
    "event_type":
        "TradeExecuted",

    "aggregate_id":
        "trade123",

    "payload":
    {
        "symbol":"D05",
        "qty":100
    }
}
```

---

# Why Events?

Suppose portfolio state becomes:

```text
100 shares
```

Question:

> How did we get here?

Traditional database:

```text
Impossible.
```

Event store:

```text
Buy 50

Buy 25

Buy 25
```

Everything is reconstructable.

---

# Event Sourcing

Instead of:

```sql
UPDATE positions
SET quantity=100
```

we do:

```sql
INSERT INTO events
```

---

Current state becomes:

```text
Function(
    Event History
)
```

---

# Example

Store:

```text
BUY 100

SELL 20

BUY 40
```

---

Compute:

```text
100

-

20

+

40
```

---

Result:

```text
120 shares
```

---

# Trade Table

Create:

```sql
CREATE TABLE trades (

    trade_id TEXT,

    symbol TEXT,

    quantity INTEGER,

    price NUMERIC,

    timestamp TIMESTAMP
);
```

---

# Order Table

Create:

```sql
CREATE TABLE orders (

    order_id TEXT,

    user_id TEXT,

    symbol TEXT,

    quantity INTEGER,

    status TEXT,

    created_at TIMESTAMP
);
```

---

# Portfolio Snapshot

Create:

```sql
CREATE TABLE portfolios (

    user_id TEXT,

    snapshot JSONB,

    created_at TIMESTAMP
);
```

---

# Why Snapshots?

Suppose:

```text
1 million events
```

exist.

Replaying:

```text
1 million events
```

every startup is expensive.

---

Instead:

```text
Snapshot

+

Recent Events
```

---

Example:

```text
Snapshot:

900000 events
```

plus:

```text
Last:

100000 events
```

---

# Audit Table

Create:

```sql
CREATE TABLE audit_log (

    id UUID,

    user_id TEXT,

    action TEXT,

    payload JSONB,

    timestamp TIMESTAMP
);
```

---

Example:

```json
{
    "user":"alice",

    "action":"BUY",

    "symbol":"D05",

    "qty":100
}
```

---

# Why Audit?

Because regulators ask:

> Who did what?

and:

> When?

---

# News History

Create:

```sql
CREATE TABLE news (

    id UUID,

    symbol TEXT,

    headline TEXT,

    sentiment NUMERIC,

    timestamp TIMESTAMP
);
```

---

# Risk History

Create:

```sql
CREATE TABLE risk (

    user_id TEXT,

    var NUMERIC,

    cvar NUMERIC,

    timestamp TIMESTAMP
);
```

---

# Market History

Create:

```sql
CREATE TABLE market_ticks (

    symbol TEXT,

    price NUMERIC,

    volume BIGINT,

    timestamp TIMESTAMP
);
```

---

# Partitioning

Professional systems partition.

---

Instead of:

```text
One Giant Table
```

use:

```text
market_ticks_2026_01

market_ticks_2026_02

market_ticks_2026_03
```

---

Example:

```sql
PARTITION BY RANGE(
    timestamp
)
```

---

Benefits:

```text
Speed

Scalability

Archiving
```

---

# Indexing

Create:

```sql
CREATE INDEX
idx_symbol
ON market_ticks(
    symbol
);
```

---

Create:

```sql
CREATE INDEX
idx_timestamp
ON market_ticks(
    timestamp
);
```

---

Result:

```text
Milliseconds
instead of
seconds.
```

---

# JSONB

Professional systems often store:

```text
Semi Structured Data
```

---

Example:

```sql
CREATE TABLE alerts (

    payload JSONB
);
```

---

Store:

```json
{
    "type":"PRICE",

    "symbol":"D05",

    "threshold":45
}
```

---

Query:

```sql
SELECT *

FROM alerts

WHERE payload->>'symbol'
    = 'D05'
```

---

# Materialized Views

Suppose:

```text
10 million trades
```

exist.

Computing:

```text
Daily PnL
```

becomes expensive.

---

Create:

```sql
CREATE MATERIALIZED VIEW
daily_pnl AS
SELECT ...
```

---

Refresh:

```sql
REFRESH MATERIALIZED VIEW
```

---

Result:

```text
Fast Analytics
```

---

# Backup Strategy

Professional systems implement:

```text
Daily

Hourly

Incremental
```

backups.

---

Store:

```text
Snapshots

WAL Logs

Archives
```

---

# Disaster Recovery

Suppose:

```text
Primary Database
```

fails.

Promote:

```text
Replica
```

to:

```text
Primary
```

---

# Database Monitoring

Track:

```text
Connections

Latency

Transactions

Locks

Disk

Replication
```

---

Example:

```text
TPS:
12000

Latency:
3ms

Connections:
250
```

---

# Event Persistence Flow

Suppose:

```text
DBS price changes.
```

System executes:

```text
Feed
   |
   V

Kafka
   |
   V

Market Service
   |
   +------ Redis
   |
   +------ PostgreSQL
```

---

Redis stores:

```text
Current Price
```

while PostgreSQL stores:

```text
Permanent History
```

---

# Rebuilding the System

Suppose everything crashes.

Recovery:

```text
PostgreSQL
      |
      V

Snapshots
      |
      V

Events
      |
      V

Redis
      |
      V

Services
      |
      V

UI
```

---

# The Real Persistence Architecture

```text
PostgreSQL
      |
      +------ Orders
      |
      +------ Trades
      |
      +------ Events
      |
      +------ News
      |
      +------ Risk
      |
      +------ Audit
      |
      +------ Snapshots
      |
      +------ Analytics
```

---

# Why Professional Systems Feel Reliable

Because they never ask:

```text
What is the current state?
```

They ask:

```text
How do we reconstruct
the current state
from history?
```

---

# Architecture Lesson #23

Beginners think:

```text
Database
      =
Storage
```

Professionals think:

```text
Database
      =
Historical
Reconstruction
Engine
```

Rows are merely compressed history.

---

# Current Architecture

```text
Panel UI
      |
      V

Redis State Layer
      |
      V

FastAPI Gateway
      |
      V

Kafka Event Backbone
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

PostgreSQL Event Store
```

TickerHub now contains:

✅ Event sourcing foundations

✅ Historical event store

✅ Audit logging

✅ Trade history

✅ Order history

✅ Snapshots

✅ Materialized views

✅ Partitioning

✅ Disaster recovery foundations

At this point, TickerHub is no longer just a real-time system.

It is:

```text
A Historical Reconstruction System
capable of replaying and rebuilding
its entire reality.
```

---

# In Part 24

We will build the **Market Data Feed Engine**, where you'll discover that professional trading systems are not:

```text
Applications that consume APIs
```

but rather:

```text
Real-time data acquisition,
normalization, and distribution
platforms.
```
