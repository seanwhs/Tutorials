# Building TickerHub

## Part 43: Building the Data Platform, Event Sourcing & Time-Travel Architecture — Teaching TickerHub to Remember Everything

> There is a dangerous assumption hidden inside almost every beginner application:
>
> ```text
> Current state
> is enough.
> ```
>
> Professional financial systems know this is false.
>
> Because eventually someone will ask:
>
> ```text
> Why did we lose $50 million
> on Tuesday at 09:37:14?
> ```
>
> And the worst possible answer is:
>
> ```text
> We don't know.
> ```

At this point, TickerHub can:

* process markets,
* execute trades,
* manage risk,
* survive failures,
* secure access,
* observe itself.

Unfortunately:

```text
It still forgets.
```

And in finance:

```text
Forgetting
is unacceptable.
```

---

# The Beginner Data Model

Most applications store:

```text
Current State
```

Example:

```sql
portfolio
```

| symbol | qty |
| ------ | --- |
| DBS    | 100 |

---

Later:

```sql
UPDATE portfolio
SET qty = 150
```

---

Question:

```text
What was the quantity
yesterday?
```

---

Answer:

```text
Gone.
```

---

# Professional Systems Store Events

Instead of:

```text
Current State
```

Store:

```text
Everything
that happened.
```

---

Example:

```text
09:00 BUY 100 DBS
```

---

Then:

```text
09:05 BUY 50 DBS
```

---

Then:

```text
09:07 SELL 20 DBS
```

---

Question:

```text
Current position?
```

---

Answer:

```text
Replay history.
```

---

# Event Sourcing

Principle:

```text
State
=
Events
```

---

Not:

```text
State
=
Database Rows
```

---

# Event Store Architecture

```text
User Action
       |
       V

Command
       |
       V

Validation
       |
       V

Event
       |
       V

Event Store
       |
       V

Read Models
```

---

# Example

Trader submits:

```text
BUY DBS 100
```

---

Generate:

```json
{
  "event":"OrderSubmitted",

  "symbol":"DBS",

  "qty":100,

  "timestamp":"09:00"
}
```

---

Store forever.

---

Then:

```json
{
  "event":"TradeExecuted",

  "symbol":"DBS",

  "qty":100,

  "price":34.15
}
```

---

Store forever.

---

# Why Events Matter

Question:

```text
What happened?
```

---

Answer:

```text
Replay events.
```

---

Question:

```text
Why did it happen?
```

---

Answer:

```text
Replay events.
```

---

Question:

```text
Who did it?
```

---

Answer:

```text
Replay events.
```

---

# Event Store

Create:

```text
events/

    event_store.py
```

---

Interface:

```python
class EventStore:

    async def append(
        self,
        event
    ):
        ...

    async def load(
        self,
        stream
    ):
        ...
```

---

# Event Structure

```python
@dataclass
class Event:

    event_id: str

    aggregate_id: str

    event_type: str

    timestamp: datetime

    payload: dict

    version: int
```

---

# Example Event

```json
{
    "event_id":"123",

    "aggregate_id":"portfolio_1",

    "type":"TradeExecuted",

    "timestamp":"2026-06-26",

    "payload":{
        "symbol":"D05",
        "qty":100
    },

    "version":7
}
```

---

# Aggregate Roots

Professional systems organize around:

```text
Aggregates
```

Examples:

```text
Portfolio
```

---

```text
Order
```

---

```text
Trade
```

---

```text
Account
```

---

Each aggregate owns:

```text
Its own history.
```

---

# Event Streams

Example:

```text
portfolio_1
```

contains:

```text
Event 1
```

↓

```text
Event 2
```

↓

```text
Event 3
```

↓

```text
Event N
```

---

# Reconstructing State

Example:

```python
portfolio = Portfolio()

for event in events:
    portfolio.apply(event)
```

---

Result:

```text
Current State
```

---

# Snapshotting

Question:

```text
Must we replay
10 million events?
```

---

Answer:

```text
No.
```

---

Instead:

```text
Snapshot
```

---

Example:

```text
Event 1
```

↓

```text
Event 5000
```

↓

```text
Snapshot
```

↓

```text
Event 5001
```

↓

```text
Event 7000
```

---

Rebuild:

```text
Snapshot
+
Remaining Events
```

---

# CQRS

Professional systems separate:

```text
Writes
```

from:

```text
Reads
```

---

Architecture:

```text
Commands
      |
      V

Event Store
      |
      V

Projections
      |
      V

Read Models
```

---

# Why?

Because:

```text
Writing
```

and:

```text
Reading
```

have different requirements.

---

# Command Side

Responsible for:

```text
Validation
```

---

Responsible for:

```text
Consistency
```

---

Responsible for:

```text
Event Creation
```

---

# Query Side

Responsible for:

```text
Performance
```

---

Responsible for:

```text
Reporting
```

---

Responsible for:

```text
Analytics
```

---

# Example

Command:

```text
BUY DBS 100
```

---

Produces:

```text
TradeExecuted
```

---

Updates:

```text
Portfolio Projection
```

---

Updates:

```text
PnL Projection
```

---

Updates:

```text
Risk Projection
```

---

Updates:

```text
Analytics Projection
```

---

# Materialized Views

Store:

```text
Current Portfolio
```

---

Store:

```text
Current Risk
```

---

Store:

```text
Current Exposure
```

---

Store:

```text
Current PnL
```

---

Benefit:

```text
Fast Reads
```

---

# Time Travel

Question:

```text
What did the portfolio
look like
at 09:32:17?
```

---

Answer:

```python
portfolio = replay(
    until="09:32:17"
)
```

---

# Historical Market Replay

Question:

```text
What did the market
look like
on March 18, 2020?
```

---

Replay:

```text
Market Events
```

---

Result:

```text
Historical Reality
```

---

# Backtesting

Question:

```text
Can we test
our strategy
against history?
```

---

Answer:

```text
Replay market events.
```

---

# Simulation

Question:

```text
Can we replay
our mistakes?
```

---

Answer:

```text
Yes.
```

---

Example:

```text
2020 Crash
```

↓

```text
Replay Portfolio
```

↓

```text
Replay Trades
```

↓

```text
Replay Risk
```

↓

```text
Analyze Failure
```

---

# Audit Trails

Question:

```text
Who changed
the risk limit?
```

---

Replay:

```text
Risk Events
```

---

Question:

```text
Who approved
the trade?
```

---

Replay:

```text
Approval Events
```

---

Question:

```text
Who disabled
the kill switch?
```

---

Replay:

```text
Security Events
```

---

# Event Versioning

Problem:

```text
Events evolve.
```

---

Example:

Version 1:

```json
{
  "symbol":"D05"
}
```

---

Version 2:

```json
{
  "symbol":"D05",

  "exchange":"SGX"
}
```

---

Solution:

```text
Version Events
```

---

# Event Schema Registry

Store:

```text
Event Type
```

---

Store:

```text
Version
```

---

Store:

```text
Schema
```

---

Benefits:

```text
Compatibility
```

---

# Immutable Data

Rule:

```text
Never modify history.
```

---

Instead:

```text
Append New Events.
```

---

Example:

Wrong:

```sql
UPDATE trades
```

---

Correct:

```text
TradeCorrected
```

event.

---

# Event Bus Integration

```text
Command
     |
     V

Event Store
     |
     V

Kafka
     |
     V

Consumers
```

---

Consumers:

```text
Portfolio
```

---

Consumers:

```text
Risk
```

---

Consumers:

```text
Analytics
```

---

Consumers:

```text
Audit
```

---

# Data Lake

Store:

```text
Events
```

↓

```text
Kafka
```

↓

```text
Object Storage
```

↓

```text
Analytics
```

---

Examples:

```text
Parquet
```

---

```text
Iceberg
```

---

```text
Delta Lake
```

---

# Event Replay Engine

Create:

```text
workers/

    replay_worker.py
```

---

Functions:

```text
Replay Portfolio
```

---

Functions:

```text
Replay Market
```

---

Functions:

```text
Replay Trades
```

---

Functions:

```text
Replay Risk
```

---

Functions:

```text
Replay Entire System
```

---

# Dashboard Features

Display:

```text
Current State
```

---

Display:

```text
Historical State
```

---

Display:

```text
Event Timeline
```

---

Display:

```text
Portfolio Replay
```

---

Display:

```text
Trade Replay
```

---

Display:

```text
Risk Replay
```

---

# Time Machine Architecture

```text
Commands
      |
      V

Events
      |
      V

Event Store
      |
      +-------> Projections
      |
      +-------> Analytics
      |
      +-------> Replay
      |
      +-------> Audit
      |
      +-------> Simulation
```

---

# Why Event Sourcing Matters

Because eventually someone asks:

```text
What happened?
```

---

Then:

```text
Why?
```

---

Then:

```text
Can you prove it?
```

---

Professional systems answer:

```text
Yes.

Replay the history.
```

---

# Architecture Lesson #43

Beginners think:

```text
Database
    =
Current State
```

Professionals think:

```text
Database
    =
A permanent,
immutable,
replayable history
of everything
that has ever happened
inside the system
```

---

# Current Architecture

```text
Commands
      |
      V

Validation
      |
      V

Events
      |
      V

Event Store
      |
      +-------> Read Models
      |
      +-------> Analytics
      |
      +-------> Audit
      |
      +-------> Replay
      |
      +-------> Simulation
```

TickerHub now contains:

✅ Event sourcing

✅ Event stores

✅ Aggregate roots

✅ Event streams

✅ Snapshots

✅ CQRS

✅ Projections

✅ Materialized views

✅ Time travel

✅ Historical replay

✅ Simulation

✅ Immutable audit trails

✅ Event versioning

✅ Schema registries

✅ Event replay engines

At this point, TickerHub no longer resembles a trading terminal.

It resembles:

```text
A Financial Time Machine
capable of reconstructing,
replaying,
auditing,
simulating,
and explaining
every state transition
that has ever occurred.
```

---

# In Part 44

We will build the **AI Copilot, Knowledge Graph & Financial Intelligence Platform**, where you'll discover that professional financial systems are not designed merely to answer:

```text
What happened?
```

but:

```text
What is happening,
why is it happening,
what will probably happen next,
and what should we do about it?
```
