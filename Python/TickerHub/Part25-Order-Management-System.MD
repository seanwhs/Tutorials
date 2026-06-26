# Building TickerHub

## Part 25: Building the Order Management System (OMS) — Governing the Lifecycle of Financial Intent

> Market data tells you what happened.
>
> Orders determine what will happen.

At this point, TickerHub can:

* acquire market data,
* normalize feeds,
* distribute events,
* maintain distributed state,
* persist history.

But there is one thing it still cannot do:

```text
Trade
```

And trading is much more complicated than:

```python
buy("D05", 100)
```

In fact, professional trading systems do not think in terms of:

```text
Buttons
```

They think in terms of:

```text
Intent
```

because an order is not a command.

An order is:

```text
A Financial Intent
with a Lifecycle
```

---

# The Beginner Architecture

Most tutorials implement:

```python
place_order()
```

which immediately:

```text
UI
    |
    V

Broker API
    |
    V

Done
```

Example:

```python
broker.buy(
    symbol="D05",
    qty=100
)
```

This works.

Until:

* partial fills,
* rejected orders,
* canceled orders,
* exchange disconnects,
* duplicate submissions,
* market halts,
* risk limits.

Then:

```text
Submit Order
```

becomes:

```text
Manage Order State
```

---

# Professional Architecture

Professional trading systems treat every order as:

```text
A Distributed State Machine
```

---

# Order Lifecycle

```text
NEW

↓

VALIDATED

↓

SUBMITTED

↓

ACKNOWLEDGED

↓

PARTIALLY_FILLED

↓

FILLED

or

CANCELLED

or

REJECTED
```

---

# OMS Architecture

```text
UI
     |
     V

Order Service
     |
     V

Risk Checks
     |
     V

Kafka
     |
     V

Execution Gateway
     |
     V

Exchange
```

---

# Create Order Domain

Create:

```text
domain/

    order.py
```

---

```python
from dataclasses import dataclass
from datetime import datetime
```

---

```python
@dataclass
class Order:

    order_id: str

    user_id: str

    symbol: str

    side: str

    quantity: int

    price: float

    status: str

    created_at: datetime
```

---

# Order Status Enum

Create:

```text
domain/

    order_status.py
```

---

```python
from enum import Enum
```

---

```python
class OrderStatus(Enum):

    NEW = "NEW"

    VALIDATED = "VALIDATED"

    SUBMITTED = "SUBMITTED"

    ACKNOWLEDGED = "ACKNOWLEDGED"

    PARTIAL = "PARTIAL"

    FILLED = "FILLED"

    CANCELLED = "CANCELLED"

    REJECTED = "REJECTED"
```

---

# Why Enums?

Because:

```text
"filled"

"Filled"

"FILLED"

"done"
```

should never exist.

Professional systems have:

```text
Finite States
```

---

# Order Events

Create:

```text
events/

    order_events.py
```

---

```python
from dataclasses import dataclass
```

---

```python
@dataclass
class OrderSubmitted:

    order_id: str
```

---

```python
@dataclass
class OrderAcknowledged:

    order_id: str
```

---

```python
@dataclass
class OrderFilled:

    order_id: str

    quantity: int
```

---

```python
@dataclass
class OrderRejected:

    order_id: str

    reason: str
```

---

# Why Events?

Because:

```text
Orders
```

change state over time.

Example:

```text
NEW

↓

SUBMITTED

↓

ACKNOWLEDGED

↓

FILLED
```

Every transition is:

```text
An Event
```

---

# Order Repository

Create:

```text
repositories/

    order_repository.py
```

---

```python
class OrderRepository:
```

---

Save:

```python
async def save(
    self,
    order
):
    ...
```

---

Load:

```python
async def load(
    self,
    order_id
):
    ...
```

---

Update:

```python
async def update(
    self,
    order
):
    ...
```

---

# OMS Service

Create:

```text
services/

    order_service.py
```

---

Initialize:

```python
class OrderService:

    def __init__(

        self,

        repository,

        event_bus
    ):
```

---

Store:

```python
self.repo = repository
```

---

Store:

```python
self.bus = event_bus
```

---

# Create Order

```python
async def create_order(

    self,

    user,

    symbol,

    side,

    quantity,

    price
):
```

---

Create:

```python
order = Order(
```

---

Assign:

```python
status=
    OrderStatus.NEW
```

---

Persist:

```python
await self.repo.save(
    order
)
```

---

Publish:

```python
await self.bus.publish(

    OrderSubmitted(
        order.order_id
    )
)
```

---

Return:

```python
return order
```

---

# Why Save Before Send?

Because:

```text
Broker API
```

might fail.

But:

```text
Intent
```

must survive.

---

# Validation Layer

Before sending:

```text
Order
```

must pass:

```text
Risk Controls
```

---

Example checks:

```text
Max Position

Max Exposure

Cash Available

Trading Hours

Permissions
```

---

Example:

```python
if quantity <= 0:

    raise InvalidOrder()
```

---

Example:

```python
if not market_open():

    raise MarketClosed()
```

---

Example:

```python
if exposure > limit:

    raise RiskLimitExceeded()
```

---

# Position Limits

Suppose:

```text
User:

1000 shares
```

tries:

```text
Buy:

5000 shares
```

---

Check:

```python
if total_position > limit:
```

Reject.

---

# Exposure Limits

Example:

```text
Portfolio:

$1M
```

Maximum:

```text
$1.2M
```

---

Attempt:

```text
Buy:

$500K
```

Reject.

---

# Margin Check

Compute:

```text
Cash

-

Required Margin
```

---

If:

```text
Negative
```

Reject.

---

# Risk Approval Flow

```text
Order
     |
     V

Risk Service
     |
     +---- APPROVED
     |
     +---- REJECTED
```

---

# Execution Gateway

Create:

```text
services/

    execution_gateway.py
```

---

Interface:

```python
class ExecutionGateway:
```

---

Submit:

```python
async def submit(
    self,
    order
):
```

---

Cancel:

```python
async def cancel(
    self,
    order
):
```

---

# Simulated Exchange

Create:

```text
workers/

    exchange_simulator.py
```

---

Receive:

```python
order
```

---

Wait:

```python
await asyncio.sleep(
    0.2
)
```

---

Generate:

```python
OrderAcknowledged
```

---

Later:

```python
OrderFilled
```

---

# State Transition

Initial:

```text
NEW
```

---

After validation:

```text
VALIDATED
```

---

After send:

```text
SUBMITTED
```

---

After exchange:

```text
ACKNOWLEDGED
```

---

After fill:

```text
FILLED
```

---

# Partial Fill

Example:

```text
Order:

1000 shares
```

---

Exchange fills:

```text
200
```

---

State:

```text
PARTIAL
```

---

Remaining:

```text
800
```

---

Example:

```text
200

+

300

+

500
```

---

Eventually:

```text
FILLED
```

---

# Order Cancel

Create event:

```python
OrderCancelled
```

---

Flow:

```text
User
     |
     V

Cancel Request
     |
     V

Exchange
     |
     V

Cancel Confirmed
```

---

# Rejections

Example reasons:

```text
Invalid Symbol

Market Closed

Insufficient Funds

Risk Limit

Exchange Reject
```

---

Store:

```python
order.reason
```

---

# Idempotency

Suppose:

```text
Network Timeout
```

occurs.

User presses:

```text
BUY
```

again.

---

Without protection:

```text
BUY

BUY
```

---

Double execution.

---

Solution:

```python
client_order_id
```

---

Check:

```python
if exists(
    client_order_id
):
```

Ignore.

---

# Order Book

Store:

```text
Active Orders
```

in Redis.

---

Example:

```text
orders:user123
```

---

Contains:

```text
BUY D05 100

SELL U11 50
```

---

# PostgreSQL History

Persist:

```text
All Orders
```

---

Table:

```sql
CREATE TABLE orders
```

---

Store:

```text
Creation

Validation

Submission

Execution

Cancel

Reject
```

---

# OMS Event Flow

Suppose:

```text
BUY

100 D05
```

---

Flow:

```text
Panel
     |
     V

Order Service
     |
     V

Risk Service
     |
     V

Kafka
     |
     V

Execution Gateway
     |
     V

Exchange
```

---

Return:

```text
ACKNOWLEDGED
```

---

Update:

```text
Redis
```

---

Persist:

```text
PostgreSQL
```

---

Broadcast:

```text
Panel
```

---

# Latency Metrics

Track:

```text
Order Submit

Exchange Ack

Fill Time

Cancel Time
```

---

Example:

```text
Submit:
3ms

Ack:
22ms

Fill:
58ms
```

---

# Circuit Breakers

Suppose:

```text
Exchange Down
```

---

Automatically:

```text
Stop Trading
```

---

Example:

```python
if exchange_unhealthy:

    reject_all_orders()
```

---

# Kill Switch

Professional systems implement:

```text
EMERGENCY STOP
```

---

Example:

```python
kill_switch = True
```

---

Result:

```text
No Orders Accepted
```

---

# Order Replay

Suppose:

```text
System Crash
```

---

Recovery:

```text
PostgreSQL
      |
      V

Order Events
      |
      V

Redis
      |
      V

OMS State
```

---

# The Real OMS Architecture

```text
OMS
    |
    +------ Validation
    |
    +------ Risk
    |
    +------ Execution
    |
    +------ State Machine
    |
    +------ Persistence
    |
    +------ Replay
    |
    +------ Monitoring
    |
    +------ Recovery
```

---

# Why Professional Trading Systems Are Difficult

Because:

```text
Trading
```

is not:

```text
Submitting Orders
```

Trading is:

```text
Managing
the lifecycle
of financial intent
across
distributed systems.
```

---

# Architecture Lesson #25

Beginners think:

```text
Order
     =
API Call
```

Professionals think:

```text
Order
     =
Distributed
Finite
State
Machine
```

The button merely starts the state transition.

---

# Current Architecture

```text
Panel UI
      |
      V

OMS
      |
      V

Risk Engine
      |
      V

Kafka Event Backbone
      |
      V

Execution Gateway
      |
      V

Exchange Simulator
      |
      V

Redis State Layer
      |
      V

PostgreSQL Event Store
```

TickerHub now contains:

✅ Order lifecycle management

✅ Order state machines

✅ Risk validation

✅ Exposure controls

✅ Position controls

✅ Partial fills

✅ Cancel flows

✅ Rejection handling

✅ Idempotency

✅ Order replay

✅ Kill switches

At this point, TickerHub no longer resembles a dashboard, a web application, or a CRUD system.

It resembles:

```text
A Distributed Financial Intent Engine
capable of governing the lifecycle
of capital allocation decisions.
```

---

# In Part 26

We will build the **Portfolio & Position Management System (PMS)**, where you'll discover that professional portfolio systems are not:

```text
Tables of holdings
```

but rather:

```text
Continuously evolving
financial state machines
that model ownership,
risk, exposure,
and economic reality.
```
