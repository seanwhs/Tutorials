# Building TickerHub

## Part 21: Building the Kafka Event Backbone — Turning TickerHub into a Distributed Event System

> Beginners build applications by calling functions.
>
> Professionals build systems by publishing events.

Up until now, our architecture has looked deceptively simple:

```text
Market Service
        |
        V
Portfolio Service
        |
        V
Risk Service
```

This works.

Until you need:

* multiple servers,
* background workers,
* horizontal scaling,
* fault tolerance,
* replay,
* audit trails,
* asynchronous processing.

At that point:

```text
Function Calls
```

become:

```text
System Coupling
```

And coupling is the enemy of distributed systems.

---

# The Beginner Architecture

Most applications do this:

```python
market_service.update_price()

portfolio_service.update()

risk_service.update()

alert_service.update()
```

This creates:

```text
Market
   |
   +---- Portfolio
   |
   +---- Risk
   |
   +---- Alert
   |
   +---- News
```

Problems:

* everyone knows everyone,
* every change breaks something,
* scaling becomes impossible,
* failures cascade.

---

# Professional Architecture

Instead:

```text
Market Service

        |

        V

     Event Bus

        |

        +------ Portfolio

        |

        +------ Risk

        |

        +------ Alerts

        |

        +------ News
```

Now:

```text
Nobody knows anybody.
```

They only know:

```text
Events.
```

---

# Why Kafka?

Professional systems require:

* millions of messages,
* durable storage,
* replay,
* partitioning,
* consumer groups,
* fault tolerance.

This is exactly what Kafka provides.

---

# Kafka Changes Everything

Instead of:

```python
risk.calculate()
```

you publish:

```python
PriceUpdated()
```

and:

```text
Risk decides
whether to react.
```

---

# Event Architecture

```text
Market Feed
      |
      V

Kafka

      |

      +------ Market Service

      |

      +------ Portfolio Service

      |

      +------ Risk Service

      |

      +------ Alert Service

      |

      +------ Analytics Service
```

---

# Local Development

Because TickerHub uses Hybrid Cloud:

```text
Laptop
      |
      V

Cloud Kafka
```

Examples:

```text
Upstash Kafka

CloudAMQP

Confluent Cloud
```

---

# Environment Variables

Add:

```bash
KAFKA_BROKER=
KAFKA_USERNAME=
KAFKA_PASSWORD=
```

---

# Configuration

Create:

```text
infrastructure/

    config.py
```

---

```python
import os
```

---

```python
KAFKA_BROKER = os.getenv(
    "KAFKA_BROKER"
)
```

---

# Install Client

```bash
pip install aiokafka
```

---

# Producer

Create:

```text
infrastructure/

    kafka_producer.py
```

---

```python
from aiokafka import (
    AIOKafkaProducer
)
```

---

Create:

```python
producer = AIOKafkaProducer(

    bootstrap_servers=
        KAFKA_BROKER
)
```

---

Start:

```python
await producer.start()
```

---

# Publish Event

Example:

```python
await producer.send(

    "prices",

    payload
)
```

---

# Consumer

Create:

```text
infrastructure/

    kafka_consumer.py
```

---

```python
from aiokafka import (
    AIOKafkaConsumer
)
```

---

Create:

```python
consumer = (

    AIOKafkaConsumer(

        "prices",

        bootstrap_servers=
            KAFKA_BROKER
    )
)
```

---

Start:

```python
await consumer.start()
```

---

Receive:

```python
async for msg in consumer:
```

---

Process:

```python
handle(msg)
```

---

# First Topic

Create:

```text
prices
```

---

Example event:

```json
{
    "symbol":"D05",
    "price":42.50
}
```

---

# Market Feed Worker

Previously:

```python
market_service.update()
```

Now:

```python
await producer.send(

    "prices",

    event
)
```

---

# Portfolio Consumer

Subscribe:

```python
consumer = (

    AIOKafkaConsumer(
        "prices"
    )
)
```

---

Receive:

```python
async for event in consumer:
```

---

Update:

```python
portfolio.update(
    event
)
```

---

# Risk Consumer

Subscribe:

```python
consumer = (

    AIOKafkaConsumer(
        "prices"
    )
)
```

---

Calculate:

```python
risk.compute(
    event
)
```

---

# Alert Consumer

Subscribe:

```python
consumer = (

    AIOKafkaConsumer(
        "prices"
    )
)
```

---

Trigger:

```python
alerts.check(
    event
)
```

---

# One Event

Suppose:

```text
DBS

42

↓

43
```

Produces:

```json
{
    "symbol":"D05",
    "price":43
}
```

---

Kafka distributes to:

```text
Portfolio

Risk

Alerts

Analytics

Charts
```

simultaneously.

---

# Event Replay

Suppose:

```text
Risk Service crashes.
```

After restart:

```text
Kafka
```

still contains:

```text
Every Event
```

---

Replay:

```python
consumer.seek_to_beginning()
```

---

Now:

```text
Risk Engine
```

can reconstruct:

```text
Entire System State
```

---

# Why Replay Matters

Suppose regulators ask:

> What happened yesterday at 09:31:42?

Without Kafka:

```text
Unknown.
```

With Kafka:

```text
Replay Everything.
```

---

# Event Sourcing

Professional systems often treat:

```text
Events
```

as:

```text
The Database
```

---

Instead of storing:

```text
Position:
100 shares
```

store:

```text
Bought 50

Bought 25

Bought 25
```

---

State becomes:

```text
Result of Event History
```

---

# Event Types

Create:

```text
events/

    market_events.py

    portfolio_events.py

    risk_events.py

    news_events.py

    alert_events.py
```

---

Example:

```python
@dataclass
class PriceUpdated:

    symbol: str

    price: float
```

---

Example:

```python
@dataclass
class TradeExecuted:

    trade_id: str

    symbol: str

    quantity: int
```

---

Example:

```python
@dataclass
class RiskUpdated:

    var: float
```

---

# Topic Design

Professional systems separate topics.

---

Example:

```text
prices
```

contains:

```text
Market prices
```

---

Example:

```text
trades
```

contains:

```text
Executed trades
```

---

Example:

```text
risk
```

contains:

```text
Risk updates
```

---

Example:

```text
alerts
```

contains:

```text
Alert events
```

---

# Consumer Groups

Suppose:

```text
Risk Worker #1
Risk Worker #2
Risk Worker #3
```

All subscribe to:

```text
risk
```

---

Kafka distributes:

```text
Event 1 -> Worker 1

Event 2 -> Worker 2

Event 3 -> Worker 3
```

---

Result:

```text
Horizontal Scaling
```

---

# Partitioning

Professional systems partition by:

```text
Symbol
```

---

Example:

```text
D05 -> Partition 1

U11 -> Partition 2

C6L -> Partition 3
```

---

Benefits:

```text
Ordering

Scalability

Performance
```

---

# Dead Letter Queue

Suppose:

```text
Bad Event
```

arrives.

Instead of crashing:

```text
Move Event
```

to:

```text
dead-letter
```

topic.

---

Example:

```python
await producer.send(

    "dead-letter",

    bad_event
)
```

---

# Event Monitoring

Track:

```text
Messages/sec

Consumer lag

Partitions

Errors

Latency
```

---

Example:

```text
Messages/sec:

35000
```

---

Example:

```text
Consumer Lag:

5ms
```

---

# Event Flow

Suppose:

```text
DBS rises.
```

System executes:

```text
Feed Worker
      |
      V

Kafka

      |

      +------ Market Service

      |

      +------ Portfolio Service

      |

      +------ Risk Service

      |

      +------ Alert Service

      |

      +------ Analytics Service
```

Nobody calls anybody.

---

# The Real Event Architecture

```text
Events
      |
      +------ Persistence
      |
      +------ Replay
      |
      +------ Distribution
      |
      +------ Partitioning
      |
      +------ Monitoring
      |
      +------ Recovery
      |
      +------ Scaling
      |
      +------ Analytics
```

---

# Why Professional Systems Feel Magical

Because professional systems do not execute:

```text
Functions.
```

They execute:

```text
Streams
of
Events.
```

---

# Architecture Lesson #21

Beginners think:

```text
Application
      =
Functions
```

Professionals think:

```text
Application
      =
Distributed
Event
Processing
System
```

Functions are merely event handlers.

---

# Current Architecture

```text
Panel UI
      |
      V

FastAPI Gateway
      |
      V

Kafka Event Backbone
      |
      +------ Market Service
      |
      +------ Portfolio Service
      |
      +------ Risk Service
      |
      +------ News Service
      |
      +------ Alert Service
      |
      +------ Workspace Service
      |
      +------ Analytics Service
```

TickerHub now contains:

✅ Distributed event bus

✅ Kafka topics

✅ Event replay

✅ Event sourcing foundations

✅ Horizontal scaling

✅ Consumer groups

✅ Partitioning

✅ Dead letter queues

✅ Event-driven services

At this point, TickerHub is no longer a web application.

It is:

```text
A Distributed Real-Time Event Processing Platform
with a Trading Terminal attached.
```

---

# In Part 22

We will build the **Redis Real-Time State Layer**, where you'll discover that high-performance systems are not:

```text
Applications that read databases
```

but rather:

```text
Systems that maintain continuously synchronized,
in-memory views of reality.
```
