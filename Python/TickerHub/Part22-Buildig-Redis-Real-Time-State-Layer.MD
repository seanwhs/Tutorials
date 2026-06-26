# Building TickerHub

## Part 22: Building the Redis Real-Time State Layer — Creating an In-Memory Model of the Market

> Databases store history.
>
> Traders need reality.

One of the biggest misconceptions in software engineering is:

```text
Database
    =
Application State
```

This is almost never true in real-time systems.

Professional trading terminals cannot wait for:

* disk access,
* SQL queries,
* transaction locks,
* network latency.

A trader expects:

```text
Price Update

↓

Screen Update

↓

Milliseconds
```

This means that professional systems maintain:

```text
A Real-Time In-Memory Model
of the Entire System
```

---

# The Beginner Architecture

Most applications do this:

```text
UI
 |
 V

API
 |
 V

Database
 |
 V

Response
```

For example:

```python
price = db.query(
    "SELECT price..."
)
```

Then:

```python
display(price)
```

This works.

Until:

* 10,000 symbols,
* 100 users,
* 50,000 ticks/sec,
* hundreds of updates per second.

At that point:

```text
Database
```

becomes:

```text
The Bottleneck
```

---

# Professional Architecture

Instead:

```text
Market Feed
       |
       V

Kafka
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

Notice:

```text
Database
```

has disappeared from the hot path.

---

# Why Redis?

Redis provides:

* in-memory storage,
* pub/sub,
* streams,
* sorted sets,
* atomic operations,
* microsecond reads.

For trading systems:

```text
Redis
    =
System Memory
```

---

# Two Kinds of Data

Professional systems separate:

## Hot Data

```text
Current price

Current positions

Current risk

Current alerts

Current news
```

from:

## Cold Data

```text
Trade history

Audit logs

Historical prices

Archived portfolios
```

---

# Storage Strategy

```text
Redis
      |
      +---- Current State

PostgreSQL
      |
      +---- Historical State
```

---

# Example

Instead of:

```sql
SELECT price
FROM prices
WHERE symbol='D05'
```

we use:

```python
redis.get(
    "price:D05"
)
```

---

# Result

Typical latency:

```text
PostgreSQL:
5-20 ms

Redis:
0.1 ms
```

---

# Hybrid Cloud Redis

For TickerHub:

```text
Laptop
     |
     V

Upstash Redis
```

Examples:

```text
Upstash

Redis Cloud

ElastiCache
```

---

# Environment Variables

Add:

```bash
REDIS_URL=
REDIS_PASSWORD=
```

---

# Install Redis Client

```bash
pip install redis
```

---

# Async Redis

Install:

```bash
pip install redis[hiredis]
```

---

# Configuration

Create:

```text
infrastructure/

    redis_client.py
```

---

```python
import redis.asyncio as redis
```

---

Create:

```python
client = redis.Redis(

    host=HOST,

    password=PASSWORD,

    decode_responses=True
)
```

---

# Test

```python
await client.set(

    "test",

    "hello"
)
```

---

Retrieve:

```python
await client.get(
    "test"
)
```

---

Result:

```text
hello
```

---

# Price Cache

Store:

```python
await client.set(

    "price:D05",

    42.5
)
```

---

Retrieve:

```python
price = await client.get(
    "price:D05"
)
```

---

# Why Cache Prices?

Because prices are read:

```text
Millions of Times
```

but written:

```text
Thousands of Times
```

---

# Order Book Cache

Store:

```text
orderbook:D05
```

---

Example:

```json
{
  "bid":42.0,
  "ask":42.1
}
```

---

Update:

```python
await redis.set(

    "orderbook:D05",

    json_data
)
```

---

# Portfolio Cache

Store:

```text
portfolio:user123
```

---

Example:

```json
{
  "cash":100000,
  "equities":250000
}
```

---

# Risk Cache

Store:

```text
risk:user123
```

---

Example:

```json
{
  "var":5400,
  "cvar":8300
}
```

---

# News Cache

Store:

```text
news:D05
```

---

Example:

```json
[
   "DBS beats earnings",
   "DBS raises dividend"
]
```

---

# Alert Cache

Store:

```text
alerts:user123
```

---

Example:

```json
[
   "VAR exceeded",
   "Price target hit"
]
```

---

# Redis Hashes

Instead of:

```text
portfolio:user123
```

store:

```python
await redis.hset(

    "portfolio:user123",

    mapping={
        "cash":10000,
        "equity":25000
    }
)
```

---

Retrieve:

```python
await redis.hgetall(
    "portfolio:user123"
)
```

---

# Redis Lists

Store recent trades:

```python
await redis.lpush(

    "trades:D05",

    trade
)
```

---

Retrieve:

```python
await redis.lrange(

    "trades:D05",

    0,

    50
)
```

---

# Redis Sorted Sets

Professional systems rank everything.

---

Example:

```python
await redis.zadd(

    "top_gainers",

    {
        "D05": 4.2
    }
)
```

---

Retrieve:

```python
await redis.zrevrange(

    "top_gainers",

    0,

    10
)
```

---

# Example Result

```text
DBS +4.2%

UOB +3.9%

SIA +2.1%
```

---

# Redis Pub/Sub

Redis can also broadcast.

---

Publisher:

```python
await redis.publish(

    "prices",

    event
)
```

---

Subscriber:

```python
sub = redis.pubsub()
```

---

Subscribe:

```python
await sub.subscribe(
    "prices"
)
```

---

Receive:

```python
async for msg in sub.listen():
```

---

# Why Pub/Sub?

Because:

```text
Kafka
```

is excellent for:

```text
Durability
```

while:

```text
Redis
```

is excellent for:

```text
Low Latency
```

---

# Professional Architecture

```text
Kafka
      |
      +------ Persistence

Redis
      |
      +------ Speed
```

---

# Event Flow

Suppose:

```text
D05

42

↓

43
```

---

Process:

```text
Feed Worker
       |
       V

Kafka
       |
       V

Market Service
       |
       +------ Redis Cache
       |
       +------ Redis PubSub
       |
       +------ PostgreSQL
```

---

# Panel Subscription

The UI subscribes:

```python
await redis.subscribe(
    "prices"
)
```

---

Receive:

```python
D05

43
```

---

Update:

```python
market_state.prices[
    "D05"
] = 43
```

---

Result:

```text
Screen updates
immediately.
```

---

# Distributed State

Suppose:

```text
Panel Server #1

Panel Server #2

Panel Server #3
```

all subscribe.

---

Redis broadcasts:

```text
Price Event
```

to:

```text
Every Server
```

---

Result:

```text
Perfect State Synchronization
```

---

# Presence Tracking

Store:

```python
await redis.sadd(

    "users",

    "user123"
)
```

---

Retrieve:

```python
await redis.smembers(
    "users"
)
```

---

Result:

```text
Currently Online
```

---

# Session Storage

Store:

```text
session:abc123
```

---

Example:

```json
{
    "user":"trader",
    "role":"admin"
}
```

---

# Leaderboards

Store:

```text
top_traders
```

---

Example:

```python
await redis.zadd(

    "leaderboard",

    {
        "alice": 10000
    }
)
```

---

# Expiration

Professional systems expire stale data.

---

Example:

```python
await redis.setex(

    "price:D05",

    30,

    value
)
```

---

Meaning:

```text
Delete after
30 seconds.
```

---

# Circuit Breakers

Suppose:

```text
Redis goes offline.
```

The system should:

```text
Fall Back
```

to:

```text
In-Memory Cache
```

---

Example:

```python
try:

    redis.get()

except:

    local_cache.get()
```

---

# Monitoring

Track:

```text
Memory

Latency

Connections

Evictions

Pub/Sub Throughput
```

---

Example:

```text
Memory:
4.1GB

Latency:
0.3ms

Subscribers:
1200
```

---

# The Real State Architecture

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
       +------ Prices
       |
       +------ Portfolios
       |
       +------ Risk
       |
       +------ News
       |
       +------ Alerts
       |
       +------ Sessions
       |
       +------ Presence
```

---

# Why Professional Terminals Feel Instant

Because they do not ask:

```text
What is the state?
```

They maintain:

```text
The state
continuously.
```

---

# Architecture Lesson #22

Beginners think:

```text
Application
      |
      V
Database
```

Professionals think:

```text
Events
      |
      V
In-Memory State
      |
      V
Views
```

The database is merely long-term storage.

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
      +------ Analytics
      |
      V

PostgreSQL
```

TickerHub now contains:

✅ Distributed event backbone

✅ Real-time state layer

✅ In-memory caching

✅ Pub/sub synchronization

✅ Distributed sessions

✅ Presence tracking

✅ Leaderboards

✅ Hot/cold storage separation

✅ Multi-node synchronization

At this point, TickerHub no longer resembles a dashboard, an API, or even a traditional web application.

It resembles:

```text
A Real-Time Distributed State Machine
for Financial Markets.
```

---

# In Part 23

We will build the **PostgreSQL Persistence Layer & Event Store**, where you'll discover that enterprise databases are not:

```text
Places to store rows
```

but rather:

```text
Historical reconstruction engines
for distributed systems.
```
