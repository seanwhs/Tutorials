# Building TickerHub

## Part 35: Building the Backtesting, Simulation & Strategy Research Platform — Teaching TickerHub to Ask "What If?"

> Trading is one of the few professions where:
>
> ```text
> You can never know
> whether your idea works
> until after
> you have already lost money.
> ```
>
> Professional trading systems solve this problem by building:
>
> ```text
> Alternate Histories
> ```
>
> and asking:
>
> ```text
> What would have happened
> if we had traded differently?
> ```

At this point, TickerHub can:

* process real-time markets,
* build order books,
* calculate risk,
* process news,
* generate alerts,
* store historical data,
* reconstruct entire market states.

However, professional systems do not stop at:

```text id="bw6um4"
What Happened?
```

They ask:

```text id="ewjlwm"
What Would Have Happened?
```

---

# The Beginner Backtest

Most tutorials implement:

```python
if ma50 > ma200:
    buy()
```

Then:

```python
profit = ending_cash
```

and declare:

```text
Strategy Works
```

Unfortunately:

```text
It Doesn't
```

---

# Why?

Because real markets contain:

* slippage,
* commissions,
* spreads,
* latency,
* liquidity constraints,
* market impact,
* partial fills,
* risk limits.

Ignoring these means:

```text id="jlwm01"
Fantasy Trading
```

rather than:

```text id="jlwm02"
Financial Simulation
```

---

# Professional Research Architecture

```text
Historical Data
        |
        V

Replay Engine
        |
        V

Market Simulator
        |
        V

Strategy Engine
        |
        V

Execution Simulator
        |
        V

Portfolio Engine
        |
        V

Performance Analytics
```

---

# The Fundamental Question

A professional backtest asks:

```text
What information
was available
at time T?
```

Not:

```text
What do we know now?
```

---

# Why?

Because using future information creates:

```text id="jlwm03"
Lookahead Bias
```

---

# Example

Suppose:

```text
Jan 1:
price = 100
```

---

Suppose:

```text
Jan 2:
price = 120
```

---

A bad backtest does:

```python
buy_if(
    tomorrow_price > today
)
```

---

Profit:

```text
Infinite
```

---

Reality:

```text
Impossible
```

---

# Event Replay

TickerHub already stores:

```text
Ticks

News

Order Books

Trades
```

---

The replay engine reconstructs:

```text
Market Reality
```

at:

```text
T
```

---

Example:

```python
market = replay.at(
    "2024-03-15 09:31:00"
)
```

---

# Strategy Interface

Create:

```text
strategies/

    base.py
```

---

```python
class Strategy:
```

---

Implement:

```python
def on_tick(
    self,
    tick
):
```

---

Implement:

```python
def on_news(
    self,
    event
):
```

---

Implement:

```python
def on_bar(
    self,
    bar
):
```

---

Return:

```text
Orders
```

---

# Example Strategy

Create:

```text
strategies/

    moving_average.py
```

---

```python
class MovingAverageStrategy(
    Strategy
):
```

---

Maintain:

```python
self.fast
```

---

Maintain:

```python
self.slow
```

---

Signal:

```python
if fast > slow:
```

---

Generate:

```text
BUY
```

---

# Strategy Engine

Create:

```text
services/

    strategy_engine.py
```

---

Loop:

```python
for event in replay:
```

---

Call:

```python
strategy.process(
    event
)
```

---

Receive:

```text
Orders
```

---

# Execution Simulator

Question:

```text
Can we actually trade?
```

---

Suppose:

```text
BUY

10 million shares
```

---

Order book:

```text
500 thousand shares
```

---

Result:

```text
Partial Fill
```

---

# Slippage Model

Expected:

```text
41.00
```

---

Actual:

```text
41.25
```

---

Slippage:

```text
0.25
```

---

Formula:

```text
Execution Price

-

Expected Price
```

---

# Commission Model

Example:

```text
0.1%
```

---

Trade:

```text
100,000
```

---

Cost:

```text
100
```

---

# Spread Model

Buy:

```text
41.10
```

---

Sell:

```text
41.00
```

---

Cost:

```text
0.10
```

---

# Latency Model

Question:

```text
What if our order
arrives late?
```

---

Example:

```text
Signal:
09:00:00
```

---

Execution:

```text
09:00:01
```

---

Price:

```text
Different
```

---

# Market Impact

Question:

```text
Did our trade
move the market?
```

---

Example:

```text
Trade:
50 million
```

---

Liquidity:

```text
10 million
```

---

Result:

```text
Price moves
```

---

# Portfolio Simulator

Track:

```text
Cash
```

---

Track:

```text
Positions
```

---

Track:

```text
PnL
```

---

Track:

```text
Risk
```

---

Example:

```python
portfolio.buy(
    symbol,
    qty,
    price
)
```

---

# Portfolio Evolution

```text
Cash
        |
        V

Trade
        |
        V

Position
        |
        V

PnL
```

---

# Performance Metrics

Compute:

```text
Return
```

---

Compute:

```text
Volatility
```

---

Compute:

```text
Sharpe Ratio
```

---

Compute:

```text
Sortino Ratio
```

---

Compute:

```text
Drawdown
```

---

# Example

Return:

```text
18%
```

---

Volatility:

```text
12%
```

---

Sharpe:

```text
1.5
```

---

# Drawdown

Question:

```text
How bad
did things get?
```

---

Example:

```text
Peak:
100
```

---

Valley:

```text
75
```

---

Drawdown:

```text
-25%
```

---

# Win Rate

Formula:

```text
Winning Trades

/

Total Trades
```

---

Example:

```text
62%
```

---

# Profit Factor

Formula:

```text
Gross Profit

/

Gross Loss
```

---

Example:

```text
2.3
```

---

# Benchmark Comparison

Question:

```text
Was the strategy
actually good?
```

---

Compare against:

```text
Buy & Hold
```

---

Example:

```text
Strategy:
18%
```

---

Benchmark:

```text
12%
```

---

Alpha:

```text
6%
```

---

# Factor Attribution

Question:

```text
Where did profits
come from?
```

---

Examples:

```text
Momentum

Value

Carry

Volatility
```

---

# Monte Carlo Simulation

Question:

```text
Was performance
just luck?
```

---

Run:

```text
10,000
simulations
```

---

Generate:

```text
Distribution
```

---

Result:

```text
Probability
of ruin
```

---

# Walk Forward Analysis

Train:

```text
2010-2015
```

---

Test:

```text
2016
```

---

Repeat:

```text
2011-2016
```

---

Question:

```text
Does it generalize?
```

---

# Parameter Optimization

Test:

```text
MA:
10
```

---

Test:

```text
MA:
20
```

---

Test:

```text
MA:
50
```

---

Find:

```text
Best Parameters
```

---

# Optimization Danger

Question:

```text
Can we overfit?
```

---

Answer:

```text
Absolutely
```

---

Example:

```text
Sharpe:
8.0
```

---

Reality:

```text
Suspicious
```

---

# Regime Testing

Evaluate:

```text
Bull Market
```

---

Evaluate:

```text
Bear Market
```

---

Evaluate:

```text
Crash
```

---

Question:

```text
Does strategy survive?
```

---

# Stress Testing

Simulate:

```text
1987
```

---

Simulate:

```text
2008
```

---

Simulate:

```text
2020
```

---

Question:

```text
Does strategy die?
```

---

# Scenario Analysis

Suppose:

```text
Interest rates
+5%
```

---

Suppose:

```text
Oil
-50%
```

---

Question:

```text
What happens?
```

---

# Research Notebook

Store:

```text
Parameters
```

---

Store:

```text
Results
```

---

Store:

```text
Trades
```

---

Store:

```text
Charts
```

---

Purpose:

```text
Reproducibility
```

---

# Backtest State

Create:

```text
state/

    backtest_state.py
```

---

Store:

```python
results
```

---

Store:

```python
equity_curve
```

---

Store:

```python
drawdowns
```

---

Store:

```python
statistics
```

---

# Dashboard

Display:

```text
Equity Curve
```

---

Display:

```text
Drawdowns
```

---

Display:

```text
Trades
```

---

Display:

```text
Metrics
```

---

# Research Architecture

```text
Historical Data
        |
        V

Replay Engine
        |
        V

Strategy Engine
        |
        V

Execution Simulator
        |
        V

Portfolio Simulator
        |
        V

Performance Analytics
```

---

# Why Backtesting Matters

Because trading is fundamentally:

```text
Counterfactual Reasoning
```

---

Question:

```text
What would have happened
if we had acted differently?
```

---

Professional systems answer:

```text
Precisely
```

---

# Architecture Lesson #35

Beginners think:

```text
Backtesting
    =
Running Strategies
```

Professionals think:

```text
Backtesting
    =
Constructing
an alternate financial reality
under a controlled simulation
of market history
```

---

# Current Architecture

```text
Historical Data
        |
        V

Replay Engine
        |
        V

Market Simulator
        |
        V

Strategy Engine
        |
        V

Execution Simulator
        |
        V

Portfolio Simulator
        |
        V

Analytics
```

TickerHub now contains:

✅ Event replay

✅ Strategy framework

✅ Execution simulation

✅ Slippage modeling

✅ Commission modeling

✅ Market impact

✅ Portfolio simulation

✅ Performance analytics

✅ Monte Carlo analysis

✅ Walk-forward testing

✅ Optimization

✅ Stress testing

✅ Scenario analysis

At this point, TickerHub no longer resembles a trading terminal.

It resembles:

```text
A Financial Reality Simulator
capable of constructing,
replaying,
and evaluating
alternate histories
of market behavior.
```

---

# In Part 36

We will build the **Quantitative Research, Factor Modeling & Portfolio Construction Platform**, where you'll discover that professional trading systems are not merely designed to ask:

```text
What would have happened?
```

but:

```text
Why did it happen,
and how should capital
be allocated
because of it?
```
