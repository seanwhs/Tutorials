# Building TickerHub

## Part 11: Building the Feed Worker — Creating the Real-Time Data Pipeline

> A financial terminal is fundamentally a machine for moving data.
>
> Everything else—charts, watchlists, portfolios, analytics, alerts—is merely a consequence of that data movement.

When people imagine a trading terminal, they think about:

* charts,
* heat maps,
* watchlists,
* flashing prices.

Professional engineers think about:

* throughput,
* latency,
* buffering,
* serialization,
* backpressure,
* retries,
* failover.

Because if the data pipeline stops:

```text
Everything stops.
```

---

# The Beginner Architecture

Most tutorials build market feeds like this:

```python
while True:

    price = get_price()

    market_service.update(
        price
    )

    time.sleep(1)
```

This works.

Until:

```text
100 symbols
```

Then:

```text
1000 symbols
```

Then:

```text
10000 symbols
```

Then:

```text
Market opens.
```

And suddenly:

```text
Messages lost.

UI freezes.

CPU spikes.

Everything dies.
```

---

# The Professional Architecture

Professional systems treat market feeds as streaming systems.

Instead of:

```text
Feed
   |
   V
Dashboard
```

we build:

```text
Feed
   |
   V
Feed Worker
   |
   V
Message Bus
   |
   V
Services
   |
   V
State
   |
   V
UI
```

---

# What Is a Feed Worker?

A feed worker is responsible for:

* connecting to exchanges,
* receiving ticks,
* validating messages,
* normalizing formats,
* batching data,
* publishing events,
* handling disconnects,
* managing backpressure,
* recovering from failures.

In other words:

```text
Everything.
```

---

# Feed Worker Architecture

```text
Market Feed
      |
      V

Feed Worker

      |
      +----- Validation
      |
      +----- Normalization
      |
      +----- Buffering
      |
      +----- Event Publishing
      |
      +----- Recovery
```

---

# Creating the Worker

Create:

```text
workers/

    feed_worker.py
```

---

# The Simplest Feed

Let's simulate SGX data.

```python
import asyncio
import random
```

---

```python
SYMBOLS = [

    "D05",
    "U11",
    "O39",
    "C6L",
    "Z74"
]
```

---

# Simulating a Tick

```python
def generate_tick():

    return {

        "symbol":

            random.choice(
                SYMBOLS
            ),

        "price":

            round(

                random.uniform(
                    10,
                    100
                ),

                2
            )
    }
```

---

Example:

```python
{
    "symbol": "D05",

    "price": 42.37
}
```

---

# Infinite Feed

```python
async def market_feed():

    while True:

        yield generate_tick()

        await asyncio.sleep(
            0.01
        )
```

This produces:

```text
100 ticks/sec
```

---

# Consuming the Feed

```python
async for tick in market_feed():

    print(tick)
```

Example:

```text
D05 42.12

U11 31.89

C6L 22.50
```

---

# Why This Is Wrong

Because our feed worker should never know about:

```text
UI

State

Portfolio

Risk
```

It only knows:

```text
Messages
```

---

# Publishing to the Event Bus

Inject:

```python
class FeedWorker:

    def __init__(

        self,

        bus
    ):

        self.bus = bus
```

---

Now:

```python
async for tick in market_feed():

    self.bus.publish(
        MarketTick(
            tick
        )
    )
```

---

# Creating MarketTick

Create:

## events/feed_events.py

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class MarketTick:

    payload: dict
```

---

Now our architecture becomes:

```text
Feed Worker
      |
      V

MarketTick Event
      |
      V

MarketService
```

---

# Why Events?

Because:

```text
Feed Worker
```

does not know:

* MarketService,
* PortfolioService,
* RiskService,
* AlertService.

It only knows:

```text
EventBus
```

This is called:

# Loose Coupling

---

# Message Validation

Never trust market data.

Bad:

```python
price = tick["price"]
```

Good:

```python
if "price" not in tick:

    return
```

---

Validate:

```python
if tick["price"] <= 0:

    return
```

---

Validate:

```python
if tick["symbol"] == "":

    return
```

---

Why?

Real exchanges occasionally produce:

```text
NULL

NaN

0

Negative prices

Corrupted packets
```

---

# Message Normalization

Exchanges all use different formats.

Example:

```python
SGX:

{
    "symbol": "D05",
    "last": 42.5
}
```

---

NASDAQ:

```python
{
    "ticker": "AAPL",
    "price": 210
}
```

---

Bloomberg:

```python
{
    "security": "IBM",
    "px_last": 110
}
```

---

Normalize:

```python
{
    "symbol": "...",

    "price": ...
}
```

---

Example:

```python
def normalize(raw):

    return {

        "symbol":
            raw["ticker"],

        "price":
            raw["price"]
    }
```

---

# Message Buffering

Professional feeds don't process one tick at a time.

Instead:

```text
Tick
Tick
Tick
Tick
Tick
```

becomes:

```text
Batch
```

---

Create buffer:

```python
self.buffer = []
```

---

Append:

```python
self.buffer.append(
    tick
)
```

---

Flush:

```python
if len(
    self.buffer
) > 100:

    publish_batch()
```

---

Why?

Because:

```text
100 network calls
```

becomes:

```text
1 network call
```

---

# Time-Based Flushing

Suppose markets become quiet.

Then:

```python
len(buffer)
```

may never reach:

```text
100
```

Therefore:

```text
Flush every:

100ms
```

---

Example:

```python
if elapsed > 0.1:

    flush()
```

---

# Backpressure

One of the hardest problems in streaming systems.

Suppose:

```text
Feed:

100,000 msgs/sec
```

But:

```text
Consumers:

10,000 msgs/sec
```

Eventually:

```text
Memory explodes.
```

---

Solutions:

```text
Drop Messages

Slow Producer

Increase Consumers

Persist Queue
```

---

# Queue-Based Processing

Instead of:

```text
Feed
   |
   V
Process
```

Use:

```text
Feed
   |
   V
Queue
   |
   V
Processor
```

---

Example:

```python
queue = asyncio.Queue()
```

---

Producer:

```python
await queue.put(
    tick
)
```

---

Consumer:

```python
while True:

    tick = await queue.get()

    process(tick)
```

---

Benefits:

* buffering,
* flow control,
* isolation.

---

# Multiple Consumers

Professional feeds use:

```python
await asyncio.gather(

    consumer(),

    consumer(),

    consumer()
)
```

Now:

```text
1 consumer
```

becomes:

```text
N consumers
```

---

# Measuring Throughput

Always measure.

Add:

```python
self.tick_count = 0
```

---

Update:

```python
self.tick_count += 1
```

---

Metrics:

```text
Feed Rate:

25,000/sec
```

---

# Measuring Latency

Timestamp:

```python
tick["timestamp"] = (
    time.time()
)
```

---

Later:

```python
latency = (

    time.time()

    -

    tick["timestamp"]
)
```

---

Dashboard:

```text
Latency:

3.2 ms
```

---

# Detecting Feed Failure

Professional feeds use heartbeats.

Example:

```python
self.last_message = (
    time.time()
)
```

---

Check:

```python
if (

    time.time()

    -

    self.last_message

) > 5:

    reconnect()
```

---

# Reconnection Logic

Bad:

```python
connect()
```

crashes.

Good:

```python
while True:

    try:

        connect()

        break

    except:

        await asyncio.sleep(
            5
        )
```

---

# Exponential Backoff

Better:

```python
delay = 1
```

---

Retry:

```python
delay *= 2
```

---

Sequence:

```text
1 sec

2 sec

4 sec

8 sec

16 sec
```

This prevents:

```text
Reconnect storms
```

---

# Publishing to Kafka

Eventually:

```python
await producer.send(

    "market",

    tick
)
```

Architecture:

```text
Feed Worker
      |
      V
Kafka
      |
      V
MarketService
```

---

# Why Kafka?

Because:

```text
Feed
```

can run at:

```text
100,000 msg/sec
```

while:

```text
Dashboard
```

runs at:

```text
30 fps
```

Kafka absorbs the difference.

---

# Snapshot Recovery

Suppose:

```text
Dashboard disconnects.
```

Should we replay:

```text
5 million ticks?
```

No.

Instead:

```text
Load Snapshot
```

Example:

```python
snapshot = {

    "D05": 42.1,

    "U11": 31.4
}
```

---

# Feed Worker Architecture

Our worker now becomes:

```text
Exchange Feed
        |
        V

    Feed Worker

        |
        +------ Validation
        |
        +------ Normalization
        |
        +------ Buffering
        |
        +------ Queue
        |
        +------ Metrics
        |
        +------ Recovery
        |
        +------ Event Publishing
```

---

# Why Bloomberg Has Thousands of Feed Engineers

Because market data systems are:

```text
Distributed Systems
```

disguised as:

```text
Price Feeds
```

The hard part is never:

```text
price = 42
```

The hard part is:

```text
How do we move
42

everywhere,

reliably,

in real time,

without breaking?
```

---

# Architecture Lesson #11

Beginners think:

```text
Market Data
      =
API Call
```

Professionals think:

```text
Market Data
      =
Streaming Infrastructure
```

The price itself is often the least interesting part of the system.

---

# Current Architecture

```text
Exchange Feed
        |
        V

    Feed Worker
        |
        V

      Kafka
        |
        V

    Event Bus
        |
        V

Services

    +------ Market

    +------ Portfolio

    +------ Risk

        |
        V

       State
        |
        V

      Panel
```

TickerHub now has:

✅ Domain Model

✅ State Engine

✅ Event Bus

✅ Repository Layer

✅ Market Engine

✅ Portfolio Engine

✅ Risk Engine

✅ Feed Engine

We now have the entire backend of a professional trading terminal.

---

# In Part 12

We will finally begin building the frontend by constructing the **Panel State Architecture**, where you'll discover that:

```text
The UI
```

is not actually:

```text
Buttons
+
Widgets
```

but rather:

```text
A distributed projection
of the application's state machine.
```
