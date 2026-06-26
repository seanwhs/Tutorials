# Building TickerHub

## Part 32: Building the Alerting, Surveillance & Complex Event Processing Engine — Detecting Meaning Before Humans Can

> Professional traders do not watch markets.
>
> Professional traders watch:
>
> ```text
> Alerts
> ```
>
> because humans cannot monitor:
>
> * 10,000 instruments,
> * millions of ticks,
> * thousands of news articles,
> * hundreds of portfolios,
> * dozens of risk models,
> * continuous order flow.
>
> Modern financial systems exist because:
>
> ```text
> Human attention is scarce.
> ```

At this point, TickerHub can process:

* market data,
* portfolios,
* risk,
* charts,
* order books,
* news,
* sentiment,
* events.

But professional systems do not merely:

```text id="n1xqte"
Display Information
```

They:

```text id="rk6l1d"
Detect Meaning
```

---

# The Beginner Alert System

Most tutorials build alerts like this:

```python id="2n01pp"
if price > 100:
    alert()
```

Or:

```python id="umx8a6"
if pnl < -1000:
    notify()
```

This works.

Until:

* thousands of symbols,
* multiple timeframes,
* correlated events,
* market anomalies,
* portfolio interactions,
* risk interactions.

Then:

```text id="24slmv"
Alerts
```

become:

```text id="tjlwm0"
Complex Event Processing
```

---

# What Is Complex Event Processing?

CEP asks:

```text id="jlwm01"
What patterns emerge
from streams of events?
```

---

Example:

```text id="jlwm02"
Price Spike
```

alone:

```text id="jlwm03"
Uninteresting
```

---

But:

```text id="jlwm04"
Price Spike

+

Volume Spike

+

Negative News

+

Sell Imbalance
```

means:

```text id="jlwm05"
Potential Market Event
```

---

# Professional Alert Architecture

```text id="jlwm06"
Event Streams
        |
        V

Rules Engine
        |
        V

Pattern Engine
        |
        V

Alert Engine
        |
        V

Notification System
```

---

# Event Sources

TickerHub already generates:

```text id="jlwm07"
Price Events

Trade Events

Risk Events

News Events

Portfolio Events

Order Events
```

---

# Why Event Streams?

Because:

```text id="jlwm08"
Meaning
```

exists in:

```text id="jlwm09"
Relationships
```

between events.

---

# Alert Domain Model

Create:

```text id="jlwm10"
domain/

    alert.py
```

---

```python
from dataclasses import dataclass
from datetime import datetime
```

---

```python
@dataclass
class Alert:

    id: str

    timestamp: datetime

    severity: str

    category: str

    message: str

    symbol: str | None

    source: str

    acknowledged: bool = False
```

---

# Severity Levels

Professional systems classify:

```text id="jlwm11"
INFO

WARNING

ERROR

CRITICAL
```

---

Example:

```text id="jlwm12"
Price crossed MA50
```

equals:

```text id="jlwm13"
INFO
```

---

Example:

```text id="jlwm14"
Portfolio VaR exceeded
```

equals:

```text id="jlwm15"
CRITICAL
```

---

# Alert Categories

Examples:

```text id="jlwm16"
Market

Execution

Risk

News

Compliance

Infrastructure
```

---

# Price Alerts

Question:

```text id="jlwm17"
Did price cross
a threshold?
```

---

Example:

```python
if price > 50:
```

---

Publish:

```text id="jlwm18"
PriceAlert
```

---

# Percentage Move Alerts

Question:

```text id="jlwm19"
Did price move unusually?
```

---

Example:

```text id="jlwm20"
+5%
in
10 minutes
```

---

Raise:

```text id="jlwm21"
MomentumAlert
```

---

# Volume Alerts

Question:

```text id="jlwm22"
Did volume spike?
```

---

Formula:

```text id="jlwm23"
Current Volume

/

Average Volume
```

---

Example:

```text id="jlwm24"
8x normal
```

---

Generate:

```text id="jlwm25"
VolumeAlert
```

---

# Spread Alerts

Question:

```text id="jlwm26"
Did liquidity disappear?
```

---

Example:

```text id="jlwm27"
Spread:

0.02

→

0.50
```

---

Raise:

```text id="jlwm28"
LiquidityAlert
```

---

# Order Book Imbalance

Question:

```text id="jlwm29"
Are buyers or sellers dominating?
```

---

Example:

```text id="jlwm30"
Bid:
90%

Ask:
10%
```

---

Generate:

```text id="jlwm31"
OrderFlowAlert
```

---

# News Alerts

Question:

```text id="jlwm32"
Did important news arrive?
```

---

Example:

```text id="jlwm33"
Importance:
0.95
```

---

Generate:

```text id="jlwm34"
BreakingNewsAlert
```

---

# Sentiment Alerts

Example:

```text id="jlwm35"
Sentiment

+0.7

↓

-0.8
```

---

Generate:

```text id="jlwm36"
SentimentShift
```

---

# Risk Alerts

Example:

```text id="jlwm37"
VaR exceeded
```

---

Generate:

```text id="jlwm38"
RiskAlert
```

---

Example:

```text id="jlwm39"
Drawdown > 20%
```

---

Generate:

```text id="jlwm40"
DrawdownAlert
```

---

# Margin Alerts

Question:

```text id="jlwm41"
Will liquidation occur?
```

---

Example:

```text id="jlwm42"
Maintenance:
20%
```

---

Current:

```text id="jlwm43"
18%
```

---

Generate:

```text id="jlwm44"
MarginCall
```

---

# Infrastructure Alerts

Example:

```text id="jlwm45"
Kafka Down
```

---

Generate:

```text id="jlwm46"
SystemAlert
```

---

# Composite Alerts

Professional systems combine events.

---

Example:

```text id="jlwm47"
Price Drop
```

*

```text id="jlwm48"
Negative News
```

*

```text id="jlwm49"
Volume Spike
```

=

```text id="jlwm50"
High Confidence Alert
```

---

# Example CEP Rule

```text id="jlwm51"
IF

price_down

AND

volume_up

AND

negative_news

WITHIN

5 minutes
```

---

Generate:

```text id="jlwm52"
MarketPanicAlert
```

---

# Another Example

```text id="jlwm53"
IF

large_order

AND

spread_widening

AND

volatility_up
```

---

Generate:

```text id="jlwm54"
LiquidityStress
```

---

# Event Windows

Professional systems maintain:

```text id="jlwm55"
Sliding Windows
```

---

Example:

```text id="jlwm56"
Last 10 seconds

Last minute

Last hour
```

---

Because:

```text id="jlwm57"
Time
```

changes meaning.

---

# Alert Service

Create:

```text id="jlwm58"
services/

    alert_service.py
```

---

Initialize:

```python
class AlertService:
```

---

Maintain:

```python
self.rules = []
```

---

Register:

```python
def register(
    self,
    rule
):
```

---

Evaluate:

```python
def process(
    self,
    event
):
```

---

# Rule Objects

Create:

```text id="jlwm59"
rules/
```

---

Example:

```python
class PriceRule:
```

---

Implement:

```python
def evaluate(
    self,
    event
):
```

---

Return:

```text id="jlwm60"
Alert
```

or:

```text id="jlwm61"
None
```

---

# Pattern Matching

Maintain:

```text id="jlwm62"
Recent Events
```

inside:

```text id="jlwm63"
Redis
```

---

Example:

```text id="jlwm64"
Last 1000
events
```

---

Search:

```text id="jlwm65"
Patterns
```

---

# Alert Deduplication

Suppose:

```text id="jlwm66"
1000
identical alerts
```

arrive.

---

Do not show:

```text id="jlwm67"
1000 alerts
```

---

Instead:

```text id="jlwm68"
Aggregate
```

---

Example:

```text id="jlwm69"
DBS exceeded
risk limit

(127 times)
```

---

# Alert Escalation

Example:

```text id="jlwm70"
WARNING
```

for:

```text id="jlwm71"
5 minutes
```

becomes:

```text id="jlwm72"
CRITICAL
```

---

# Alert Persistence

Store:

```text id="jlwm73"
Alerts
```

inside:

```text id="jlwm74"
PostgreSQL
```

---

Example:

```sql
CREATE TABLE alerts
(
    id TEXT,

    timestamp TIMESTAMP,

    severity TEXT,

    category TEXT,

    message TEXT
)
```

---

# Alert State

Create:

```text id="jlwm75"
state/

    alert_state.py
```

---

```python
class AlertState(
    param.Parameterized
):
```

---

Store:

```python
alerts = param.List()
```

---

Store:

```python
critical = param.List()
```

---

Store:

```python
history = param.List()
```

---

# Alert Dashboard

Display:

```text id="jlwm76"
Severity

Category

Message

Time
```

---

Example:

```text id="jlwm77"
CRITICAL

Risk

VaR exceeded

09:32
```

---

# Alert Heatmap

Display:

```text id="jlwm78"
Market

Risk

News

System
```

---

Visualize:

```text id="jlwm79"
Frequency
```

---

# Notifications

Generate:

```text id="jlwm80"
Popup

Email

SMS

Webhook

Slack
```

---

# Alert Workflow

Example:

```text id="jlwm81"
NEW
```

↓

```text id="jlwm82"
ACKNOWLEDGED
```

↓

```text id="jlwm83"
RESOLVED
```

↓

```text id="jlwm84"
ARCHIVED
```

---

# Surveillance

Professional systems monitor:

```text id="jlwm85"
Spoofing

Layering

Wash Trades

Manipulation
```

---

Example:

```text id="jlwm86"
Large fake orders
```

↓

```text id="jlwm87"
Cancellation
```

↓

```text id="jlwm88"
Price move
```

↓

```text id="jlwm89"
Manipulation Alert
```

---

# Predictive Alerts

Question:

```text id="jlwm90"
Will something happen?
```

---

Example:

```text id="jlwm91"
Probability:

85%
```

of:

```text id="jlwm92"
Margin Call
```

---

Generate:

```text id="jlwm93"
Predictive Alert
```

---

# CEP Architecture

```text id="jlwm94"
Market
        |
News    |
        |
Orders  |
        |
Risk    |
        V

Event Bus
        |
        V

CEP Engine
        |
        V

Alert Engine
        |
        V

Notification System
```

---

# Why Professional Alerts Matter

Because humans cannot detect:

```text id="jlwm95"
Patterns
```

across:

```text id="jlwm96"
Millions of events
```

in real time.

---

# Architecture Lesson #32

Beginners think:

```text id="jlwm97"
Alert
   =
Notification
```

Professionals think:

```text id="jlwm98"
Alert
   =
A Real-Time Inference
about the meaning
of multiple correlated events
```

---

# Current Architecture

```text id="jlwm99"
Market Feed
        |
        +------ Order Flow
        |
        +------ News
        |
        +------ Portfolio
        |
        +------ Risk
        |
        V

Event Bus
        |
        V

CEP Engine
        |
        V

Alert Engine
        |
        V

Panel
```

TickerHub now contains:

✅ Price alerts

✅ Volume alerts

✅ Liquidity alerts

✅ Risk alerts

✅ News alerts

✅ Composite alerts

✅ CEP rules

✅ Sliding windows

✅ Deduplication

✅ Escalation

✅ Surveillance

✅ Predictive alerting

At this point, TickerHub no longer resembles a market terminal.

It resembles:

```text
A Real-Time Event Inference System
capable of detecting,
correlating,
and predicting
meaningful phenomena
within financial markets.
```

---

# In Part 33

We will build the **Observability, Telemetry & Distributed Tracing Platform**, where you'll discover that professional financial systems are not merely designed to:

```text
Process events
```

but to:

```text
Explain,
measure,
and reconstruct
everything that happened,
everywhere,
at any point in time.
```
