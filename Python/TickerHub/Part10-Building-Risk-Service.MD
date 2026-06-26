# Building TickerHub

## Part 10: Building the Risk Service — From Arithmetic to Distributed Simulation

> Most developers think risk management means calculating a few percentages.
>
> Professional financial systems know that risk management is really about answering one question:
>
> **What happens if we are wrong?**

The purpose of a trading terminal is not to tell you:

```text
You made money.
```

Its purpose is to tell you:

```text
You may lose money.
```

This responsibility belongs to the:

# Risk Service

---

# The Beginner Approach

Most developers start with:

```python
risk = portfolio.value * 0.03
```

Or perhaps:

```python
risk = max_loss
```

This works.

Until someone asks:

* What is my 95% VaR?
* What is my 99% VaR?
* What is my expected shortfall?
* What happens if SGD rises 5%?
* What happens if rates increase 200bps?
* What happens if oil drops 30%?
* What happens if correlations break?

At this point:

```text
Spreadsheet Risk
```

becomes:

```text
Real Risk
```

---

# What Is Risk?

Risk is not:

```text
A Number
```

Risk is:

```text
A Model
```

A model answering:

```text
What could happen next?
```

---

# TickerHub Risk Architecture

```text
Portfolio
      |
      V

Risk Service

      |
      +------ VaR
      |
      +------ CVaR
      |
      +------ Exposure
      |
      +------ Stress Tests
      |
      +------ Limits
      |
      +------ Alerts
```

---

# Responsibilities

The RiskService must:

* consume portfolio changes,
* compute exposure,
* compute leverage,
* compute VaR,
* compute CVaR,
* run stress tests,
* monitor limits,
* publish risk events,
* update application state.

---

# Creating the Service

Create:

```text
services/

    risk_service.py
```

---

# Dependencies

```python
from state.app_state import (
    AppState
)

from events.base import (
    EventBus
)

from repositories.risk_repository import (
    RiskRepository
)
```

---

# Constructor

```python
class RiskService:

    def __init__(
        self,
        state,
        bus,
        repository
    ):

        self.state = state

        self.bus = bus

        self.repository = repository
```

---

# Event Subscription

Risk engines don't run continuously.

They react to:

```text
PortfolioChanged
```

events.

Subscribe:

```python
bus.subscribe(

    PortfolioChanged,

    self.on_portfolio_changed
)
```

---

# Event Flow

```text
Trade
   |
   V

PortfolioChanged
        |
        V

RiskService
        |
        V

RiskCalculated
        |
        V

Dashboard
```

---

# Step 1 — Compute Exposure

Exposure answers:

> How much market risk do I currently hold?

Formula:

```python
def exposure(
    portfolio
):

    return sum(

        abs(
            p.market_value
        )

        for p in portfolio.positions
    )
```

---

Example:

```text
DBS      +100,000

SIA      -50,000
```

Exposure:

```text
150,000
```

---

# Step 2 — Compute Leverage

Formula:

```python
def leverage(

    exposure,

    equity
):

    return (

        exposure

        /

        equity
    )
```

---

Example:

```text
Exposure:

500,000

Equity:

100,000
```

Result:

```text
5x leverage
```

---

# Why Leverage Matters

A portfolio with:

```text
100,000 assets
```

can only lose:

```text
100,000
```

A portfolio with:

```text
1,000,000 exposure
```

can lose:

```text
1,000,000
```

even if equity is only:

```text
100,000
```

Leverage kills more traders than bad trades.

---

# Step 3 — Historical Value at Risk

The simplest VaR model:

```text
Historical Simulation
```

---

Example:

```text
Portfolio Value:

100,000
```

Historical daily returns:

```text
-5%
-2%
+1%
-3%
+2%
...
```

---

Sort:

```text
Worst

↓

Best
```

Take:

```text
95th percentile
```

---

Implementation:

```python
import numpy as np


def calculate_var(

    returns,

    confidence=0.95
):

    percentile = (

        100

        * (1 - confidence)
    )

    return abs(

        np.percentile(

            returns,

            percentile
        )
    )
```

---

Example:

```text
VaR95

=

3%
```

Meaning:

```text
There is a 5% chance
of losing more than 3%
in one day.
```

---

# Conditional VaR

VaR asks:

```text
Where is the cliff?
```

CVaR asks:

```text
What happens after we fall off?
```

---

Implementation:

```python
def calculate_cvar(

    returns,

    confidence=0.95
):

    threshold = np.percentile(

        returns,

        100*(1-confidence)
    )

    losses = [

        r

        for r in returns

        if r <= threshold
    ]

    return abs(

        np.mean(
            losses
        )
    )
```

---

Example:

```text
VaR:

3%
```

---

But:

```text
CVaR:

8%
```

Meaning:

```text
Once things become bad,
they become very bad.
```

---

# Position Concentration

Risk systems hate concentration.

Example:

```text
Portfolio:

90%
DBS

10%
Others
```

Calculate:

```python
def concentration(
    portfolio
):

    largest = max(

        p.market_value

        for p in portfolio.positions
    )

    return (

        largest

        /

        portfolio.market_value
    )
```

---

Result:

```text
90%
```

This should probably trigger:

```text
ALERT
```

---

# Stress Testing

Professional systems ask:

> What if reality changes dramatically?

Example scenarios:

| Scenario            | Shock |
| ------------------- | ----- |
| Market Crash        | -20%  |
| Banking Crisis      | -35%  |
| Oil Shock           | -30%  |
| Currency Crisis     | +15%  |
| Interest Rate Shock | +2%   |

---

Example:

```python
def stress_test(

    portfolio,

    shock
):

    loss = 0

    for position in portfolio.positions:

        loss += (

            position.market_value

            * shock
        )

    return loss
```

---

Example:

```text
Portfolio:

100,000
```

Shock:

```text
-20%
```

Result:

```text
Stress Loss:

20,000
```

---

# Risk Limits

Professional systems define:

```text
Maximum Exposure

Maximum VaR

Maximum Leverage

Maximum Concentration
```

---

Example:

```python
LIMITS = {

    "var": 10000,

    "leverage": 5,

    "concentration": 0.30
}
```

---

Check:

```python
if risk.var > LIMITS["var"]:

    alert()
```

---

# Publishing Alerts

Create:

```python
@dataclass
class RiskLimitBreached:

    metric: str

    actual: float

    limit: float
```

---

Example:

```python
self.bus.publish(

    RiskLimitBreached(

        "VaR",

        12000,

        10000
    )
)
```

---

# Building the Risk Object

Create:

```python
risk = Risk(

    portfolio_id=portfolio.owner,

    var=var,

    cvar=cvar,

    exposure=exposure,

    leverage=leverage
)
```

---

# Persisting Risk

Save:

```python
await self.repository.save(
    risk
)
```

---

Why?

Because risk history matters.

Example:

```text
9:00

VaR = 2000


10:00

VaR = 5000


11:00

VaR = 12000
```

This trend is often more important than the current value.

---

# Updating State

```python
self.state.risk.var = (
    risk.var
)

self.state.risk.cvar = (
    risk.cvar
)

self.state.risk.exposure = (
    risk.exposure
)

self.state.risk.leverage = (
    risk.leverage
)
```

---

The dashboard updates automatically.

No UI code required.

---

# Publishing Risk Events

```python
self.bus.publish(

    RiskCalculated(

        portfolio.owner,

        risk.var,

        risk.cvar
    )
)
```

---

# Why Risk Is Expensive

A professional portfolio may contain:

```text
10,000 positions
```

And:

```text
1,000,000 scenarios
```

This becomes:

```text
10 billion calculations
```

You cannot run this inside a dashboard callback.

---

# Enter Background Workers

Instead:

```text
Portfolio Changed
        |
        V

Redis Queue
        |
        V

Risk Worker Pool
        |
        V

Risk Result
        |
        V

Dashboard
```

---

Example:

```python
await risk_queue.put(

    portfolio
)
```

Worker:

```python
while True:

    portfolio = await queue.get()

    risk = calculate(
        portfolio
    )

    publish(risk)
```

---

# Why This Matters

Without workers:

```text
Button Click

↓

Wait 45 seconds

↓

Dashboard Freezes
```

With workers:

```text
Button Click

↓

Dashboard Continues

↓

Risk Appears Later
```

---

# Risk Service Architecture

Our service now becomes:

```text
PortfolioChanged
         |
         V

    RiskService

         |
         +------ Exposure
         |
         +------ VaR
         |
         +------ CVaR
         |
         +------ Stress
         |
         +------ Limits
         |
         +------ Alerts
         |
         +------ Repository
         |
         +------ State
```

---

# Why Financial Firms Spend Billions on Risk

Because:

```text
Trading
```

creates profits.

But:

```text
Risk Management
```

prevents bankruptcy.

The greatest financial disasters in history were not caused by bad trading systems.

They were caused by inadequate risk systems.

---

# Architecture Lesson #10

Beginners think:

```text
Risk
    =
Formula
```

Professionals think:

```text
Risk
    =
Simulation
      +
Statistics
      +
Distributed Computing
      +
Real-Time Monitoring
      +
Operational Controls
```

The actual formula is often the easiest part.

---

# Current Architecture

```text
Panel
   |
   V

State Engine
   |
   V

Services

   +------ MarketService

   +------ PortfolioService

   +------ RiskService

          |
          V

       Event Bus

          |
          V

      Repositories

          |
          V

Redis
Kafka
PostgreSQL
```

TickerHub now has:

✅ Market engine

✅ Portfolio engine

✅ Risk engine

We have built the backend of a professional financial terminal.

And we still haven't created a single chart.

---

# In Part 11

We will build the **Feed Worker**, where you'll discover that market data systems are really:

```text
Distributed Streaming Systems
```

and that a Bloomberg terminal spends far more time moving data than displaying it.
