# Building TickerHub

## Part 17: Building the Risk Dashboard — Predicting Loss Before It Happens

> Professional traders don't lose money because markets move.
>
> They lose money because they failed to understand how much they could lose before the market moved.

This is why every professional trading system contains a dedicated:

```text
Risk Engine
```

that continuously answers questions such as:

* How much can I lose today?
* What happens if the market falls 5%?
* What happens if volatility doubles?
* Which position is contributing most to risk?
* Which positions are correlated?
* How much capital should I reserve?

The portfolio tells you:

```text
Where you are.
```

The risk system tells you:

```text
Where you might end up.
```

---

# The Beginner Risk Calculator

Most tutorials implement risk like this:

```python
risk = portfolio.value * 0.03
```

This is not risk management.

This is:

```text
Making up a number.
```

Professional risk systems model:

* uncertainty,
* probability,
* correlation,
* volatility,
* concentration,
* stress.

---

# Risk Architecture

```text
Market Feed
       |
       V

Market Service
       |
       V

Portfolio Service
       |
       V

Risk Service
       |
       V

Risk State
       |
       V

Risk Dashboard
```

Notice:

```text
The UI never calculates risk.
```

Risk computation belongs to:

```text
Background Services
```

---

# Why?

Because risk calculations are expensive.

Suppose:

```text
1000 positions
```

and:

```text
10000 simulations
```

This becomes:

```text
10 million calculations
```

You cannot do this inside:

```python
button.on_click()
```

---

# Creating Risk State

Create:

```text
state/

    risk_state.py
```

---

```python
import param


class RiskState(
    param.Parameterized
):

    var = param.Number()

    cvar = param.Number()

    exposure = param.Number()

    leverage = param.Number()

    stress = param.Dict()

    attribution = param.Dict()
```

---

# Creating Risk Service

Create:

```text
services/

    risk_service.py
```

---

```python
class RiskService:

    def __init__(

        self,

        portfolio_state,

        risk_state
    ):

        self.portfolio_state = (
            portfolio_state
        )

        self.risk_state = (
            risk_state
        )
```

---

# What Is VaR?

Value-at-Risk asks:

> What is the worst loss we expect with X% confidence?

Example:

```text
Portfolio:

100,000 SGD
```

95% VaR:

```text
5,000 SGD
```

Meaning:

```text
There is a 95% chance
you will lose less than
5,000 SGD.
```

---

# Simple VaR

Implement:

```python
def calculate_var(
    self,
    portfolio
):
```

---

Example:

```python
return (

    portfolio.value

    * 0.03
)
```

---

Portfolio:

```text
100,000
```

Result:

```text
3,000 SGD
```

---

# Why This Is Wrong

Because:

```text
A bank stock

and

a biotech stock

do not have
the same risk.
```

---

# Historical Simulation

Suppose:

```text
Yesterday:

-1%

Two days ago:

-2%

Three days ago:

+1%
```

---

Store:

```python
returns = [

    -0.01,

    -0.02,

    0.01,

    -0.03,

    0.02
]
```

---

Calculate losses:

```python
losses = [

    portfolio.value * r

    for r

    in returns
]
```

---

Sort:

```python
losses.sort()
```

---

95% VaR:

```python
index = int(

    len(losses)

    * 0.05
)
```

---

Example:

```text
Losses:

-7000
-5000
-3000
-1000
 1000
```

Result:

```text
VaR:

7000 SGD
```

---

# Conditional VaR

CVaR asks:

> If things go wrong, how bad can they become?

---

Example:

```text
Worst losses:

-7000
-6000
-5000
```

Average:

```text
-6000
```

---

Implementation:

```python
tail = losses[:index]
```

---

Calculate:

```python
cvar = abs(

    sum(tail)

    /

    len(tail)
)
```

---

Result:

```text
CVaR:

6000 SGD
```

---

# Position Contribution

Which position contributes most to risk?

Example:

```text
D05:

40%

U11:

20%

C6L:

10%
```

---

Calculate:

```python
risk = (

    position.market_value

    /

    portfolio.value
)
```

---

Store:

```python
contributions[
    position.symbol
] = risk
```

---

# Concentration Risk

Suppose:

```text
Portfolio:

100,000
```

and:

```text
DBS:

80,000
```

Then:

```text
80%
```

of risk comes from:

```text
One Position
```

---

Calculate:

```python
max_weight = max(
    weights
)
```

---

Example:

```text
0.80
```

Danger:

```text
Extreme Concentration
```

---

# Leverage

Formula:

```python
leverage = (

    exposure

    /

    equity
)
```

---

Example:

```text
Exposure:

200,000
```

---

Example:

```text
Equity:

100,000
```

---

Result:

```text
2x leverage
```

---

# Stress Testing

Professional systems ask:

> What if everything goes wrong?

---

Scenario:

```text
Market:

-10%
```

---

Calculate:

```python
stress = (

    portfolio.value

    * 0.10
)
```

---

Example:

```text
100,000

↓

90,000
```

Loss:

```text
10,000
```

---

# Multiple Stress Scenarios

Store:

```python
scenarios = {

    "Crash": -0.10,

    "Recession": -0.20,

    "Pandemic": -0.30
}
```

---

Run:

```python
for name, shock in scenarios.items():

    losses[name] = (

        portfolio.value

        * shock
    )
```

---

Result:

```text
Crash:

-10000

Recession:

-20000

Pandemic:

-30000
```

---

# Correlation Risk

Suppose:

```text
DBS
```

and:

```text
OCBC
```

move together.

Then:

```text
Owning both
doesn't diversify.
```

---

Example:

```text
Correlation:

0.95
```

Meaning:

```text
Almost identical risk.
```

---

# Correlation Matrix

```text
          D05    U11    C6L

D05       1.0    .90    .20

U11       .90    1.0    .10

C6L       .20    .10    1.0
```

---

# Volatility

Volatility measures uncertainty.

Formula:

```python
returns.std()
```

---

Example:

```text
Annualized Volatility:

22%
```

---

# Drawdown

Question:

> How much have I lost from the peak?

---

Example:

```text
Peak:

100000

Current:

85000
```

---

Compute:

```python
drawdown = (

    peak

    -

    current
)
```

---

Result:

```text
15%
```

---

# Building Risk Dashboard

Create:

```text
components/

    risk/

        risk_dashboard.py
```

---

Create indicators:

```python
var = pn.indicators.Number()
```

---

Example:

```text
VaR

5000 SGD
```

---

Create:

```python
cvar = pn.indicators.Number()
```

---

Example:

```text
CVaR

7000 SGD
```

---

Create:

```python
stress = pn.widgets.Tabulator()
```

---

Example:

```text
Crash       -10000
Recession   -20000
Pandemic    -30000
```

---

Create:

```python
exposure = pn.indicators.Number()
```

---

Example:

```text
Exposure

150000 SGD
```

---

Create:

```python
leverage = pn.indicators.Number()
```

---

Example:

```text
Leverage

2.1x
```

---

# Heatmaps

Professional terminals display:

```text
Low Risk

↓

Green
```

and:

```text
High Risk

↓

Red
```

---

Example:

```text
D05    ████████

U11    ██

C6L    ████
```

---

# Background Workers

Risk calculations belong here:

```text
Dashboard

      |

      V

Redis Queue

      |

      V

Risk Worker

      |

      V

Risk State

      |

      V

Dashboard
```

---

# Example Worker

```python
while True:

    portfolio = queue.get()

    risk = calculate_risk(
        portfolio
    )

    state.var = risk
```

---

# Why?

Because:

```text
Monte Carlo

can take:

100ms
500ms
2 seconds
```

The UI must never wait.

---

# Event Flow

Suppose:

```text
DBS drops 5%.
```

The system executes:

```text
Market Feed
      |
      V

Market Service
      |
      V

Portfolio Service
      |
      V

Risk Service
      |
      V

Risk State
      |
      V

Risk Dashboard
```

Again:

```text
No polling.

No REST refresh.

No button presses.
```

---

# The Real Risk Architecture

```text
Portfolio
      |
      V

Risk Engine
      |
      +------ VaR
      |
      +------ CVaR
      |
      +------ Stress
      |
      +------ Correlation
      |
      +------ Volatility
      |
      +------ Drawdown
      |
      +------ Attribution
      |
      +------ Leverage
      |
      +------ Exposure
      |
      +------ Rendering
```

---

# Why Professional Risk Systems Feel Instant

Because they do not calculate:

```text
When you ask.
```

They calculate:

```text
Continuously.
```

---

# Architecture Lesson #17

Beginners think:

```text
Risk
    =
Ratios
```

Professionals think:

```text
Risk
    =
Continuous
Probabilistic
Simulation
```

The dashboard merely displays the results.

---

# Current Architecture

```text
Feed Worker
      |
      V

Market Service
      |
      V

Portfolio Service
      |
      V

Risk Service
      |
      V

Application State
      |
      ├── Watchlist
      ├── Chart
      ├── OrderBook
      ├── Portfolio
      └── Risk
```

TickerHub now has:

✅ Market feed

✅ Portfolio engine

✅ Risk engine

✅ Watchlist

✅ Charts

✅ Order book

✅ Portfolio dashboard

✅ Risk dashboard

At this point, TickerHub resembles the architecture of a real institutional trading platform.

---

# In Part 18

We will build the **News & Alerts System**, where you'll discover that market news is not:

```text
A list of headlines
```

but rather:

```text
A real-time event intelligence system
that transforms external information
into actionable market signals.
```
