# Building TickerHub

## Part 31: Building the News Intelligence & Event Processing Engine — Modeling the Propagation of Financial Information

> Markets do not react to reality.
>
> Markets react to:
>
> ```text
> Perceived Reality
> ```
>
> and perceived reality is transmitted through:
>
> ```text
> Information
> ```

At this point, TickerHub can model:

* market prices,
* order flow,
* portfolios,
* risk,
* market microstructure,
* liquidity,
* execution.

However, there is still one critical input missing.

Professional traders know that prices do not move because of:

```text id="a1o31"
Mathematics
```

alone.

They move because:

```text id="5gk7qm"
People Learn Something New
```

---

# The Beginner View of News

Most trading tutorials treat news like this:

```text id="9o2n6r"
Headline
```

↓

```text id="t6yk5w"
Display Widget
```

---

Example:

```python id="ut9iyv"
news.append(
    headline
)
```

This works.

Until:

* thousands of headlines,
* multiple sources,
* duplicate stories,
* breaking news,
* sentiment analysis,
* event correlation,
* impact analysis.

Then:

```text id="jlwmqu"
News
```

becomes:

```text id="mmpm8n"
A Distributed Information Processing Problem
```

---

# Professional News Architecture

Professional terminals separate:

```text id="5p4rrr"
Collection

↓

Normalization

↓

Classification

↓

Enrichment

↓

Distribution

↓

Visualization
```

---

# TickerHub News Pipeline

```text id="h97zva"
News Source
       |
       V

Collector
       |
       V

Parser
       |
       V

Classifier
       |
       V

Sentiment
       |
       V

Event Bus
       |
       V

Panel UI
```

---

# Why?

Because:

```text id="zpqoz8"
Raw News
```

is not:

```text id="7j6cws"
Tradable Information
```

---

# News Domain Model

Create:

```text id="awkrj4"
domain/

    news.py
```

---

```python id="uazk5a"
from dataclasses import dataclass
from datetime import datetime
```

---

```python id="n1ixv2"
@dataclass
class NewsEvent:

    id: str

    timestamp: datetime

    source: str

    headline: str

    body: str

    symbols: list

    category: str

    sentiment: float

    importance: float
```

---

# Why Add Metadata?

Because:

```text id="c6lf5f"
Headline Text
```

is not enough.

Professional systems need:

```text id="1h8wxh"
Context
```

---

# Example News Event

```text id="h1u7ti"
DBS reports
record earnings
```

Metadata:

```text id="8uqn2v"
Symbol:
DBS

Category:
Earnings

Sentiment:
Positive

Importance:
High
```

---

# News Sources

Examples:

```text id="gk6p84"
Reuters

Bloomberg

Dow Jones

SEC

MAS

Company Filings

Social Media
```

---

# News Collector

Create:

```text id="5y2dhu"
workers/

    news_collector.py
```

---

Example:

```python id="gx7wzr"
async def collect():
```

---

Fetch:

```text id="hxtl5f"
RSS

API

WebSocket
```

---

Publish:

```text id="siyvti"
RawNews
```

events.

---

# Why Event Driven?

Because news arrives:

```text id="eyad3l"
Unexpectedly
```

---

# News Parser

Receive:

```text id="7a3y3i"
Raw Article
```

---

Extract:

```text id="z5xkk6"
Headline

Body

Time

Source
```

---

Normalize:

```text id="1fw8aq"
Common Schema
```

---

Example:

```text id="vs3x4m"
Reuters
```

and:

```text id="lgyvow"
Bloomberg
```

become:

```text id="eg7d4x"
NewsEvent
```

---

# Symbol Extraction

Question:

```text id="nkz4m7"
What does this affect?
```

---

Example:

```text id="7y6t1l"
DBS acquires
regional bank
```

Extract:

```text id="d5eqwp"
DBS
```

---

Store:

```python id="ltx6k2"
symbols = [
    "D05"
]
```

---

# Event Classification

Question:

```text id="79b9ha"
What type of event
is this?
```

---

Examples:

```text id="9gmqyh"
Earnings

M&A

Bankruptcy

Regulation

Macro

Geopolitics

Litigation
```

---

# Example Classifier

```python id="2xvkt5"
if "earnings" in text:
```

---

Classify:

```text id="0g17uq"
Earnings
```

---

Later:

```text id="lkn47k"
LLM
```

classification.

---

# Importance Scoring

Question:

```text id="3b9dvm"
Should traders care?
```

---

Example:

```text id="j1iqaa"
CEO Interview
```

Importance:

```text id="dbqjvl"
0.2
```

---

Example:

```text id="v7avih"
Bankruptcy Filing
```

Importance:

```text id="x6w6al"
0.95
```

---

# Sentiment Analysis

Question:

```text id="tmu98v"
Is this positive
or negative?
```

---

Range:

```text id="8cbcn8"
-1

↓

+1
```

---

Example:

```text id="fiz7an"
Massive losses
```

---

Result:

```text id="2qtrxy"
-0.9
```

---

Example:

```text id="oaqjxb"
Record profits
```

---

Result:

```text id="glrjlwm"
+0.8
```

---

# Why Sentiment?

Because markets trade:

```text id="2zm22q"
Expectations
```

rather than:

```text id="wzcc3f"
Facts
```

---

# Event Correlation

Question:

```text id="xubn9e"
What happened
after similar news?
```

---

Example:

```text id="xq4gq0"
Past earnings surprises
```

---

Calculate:

```text id="pt2fyc"
Average Return
```

---

Result:

```text id="fg22d9"
+3.2%
```

---

# News Impact Model

Compute:

```text id="qcr92l"
Price Change

Volume Change

Volatility Change
```

after:

```text id="obtkrl"
News Event
```

---

Example:

```text id="wte3ct"
DBS Earnings
```

↓

```text id="6cqq5f"
+4.5%
```

↓

```text id="j0hfph"
Volume × 6
```

---

# Event Study Engine

Create:

```text id="ntf35d"
services/

    event_study.py
```

---

Calculate:

```text id="1yyxje"
T-1

T+1

T+5

T+20
```

returns.

---

Question:

```text id="kx5jwk"
Did the event matter?
```

---

# News Clustering

Suppose:

```text id="jlwmzc"
50 articles
```

appear.

---

Actually:

```text id="6njlwm"
One story
```

---

Group:

```text id="txpdru"
Similar Headlines
```

---

Example:

```text id="mpuhkg"
DBS beats expectations

DBS reports earnings

DBS Q2 results
```

---

Cluster:

```text id="v0u4eh"
One Event
```

---

# Breaking News Detection

Question:

```text id="u9pnm6"
Is this unusual?
```

---

Example:

```text id="fjlwmh"
1000 articles/hour
```

Normally:

```text id="mpvvj5"
10 articles/hour
```

---

Raise:

```text id="lrwlf3"
BreakingNews
```

event.

---

# News Event Bus

Publish:

```text id="7ev2ar"
NewsArrived
```

---

Publish:

```text id="mmqkbc"
BreakingNews
```

---

Publish:

```text id="khyjlwm"
HighImpactEvent
```

---

Publish:

```text id="6p8jsk"
SentimentChanged
```

---

# News State

Create:

```text id="89jw0z"
state/

    news_state.py
```

---

```python id="7o1p6e"
class NewsState(
    param.Parameterized
):
```

---

Store:

```python id="vjlwm1"
articles = param.List()
```

---

Store:

```python id="k5e8dv"
breaking = param.List()
```

---

Store:

```python id="u9jt9i"
sentiment = param.Dict()
```

---

Store:

```python id="rkl7pf"
impact = param.Dict()
```

---

# News Component

Display:

```text id="cjlwm8"
Timestamp

Headline

Source

Sentiment
```

---

Example:

```text id="jlwmg4"
09:15

DBS beats earnings

Reuters

+0.8
```

---

# Heatmap

Display:

```text id="y0uk4x"
Market Sentiment
```

---

Example:

```text id="e0lpxh"
Banks:
+0.8

Tech:
-0.4

Airlines:
-0.7
```

---

# News Timeline

Display:

```text id="jlwm89"
News
```

together with:

```text id="phljw0"
Price
```

---

Example:

```text id="jlwm92"
10:00 News

↓

10:02 Price Spike
```

---

# News Alerts

Example:

```text id="jlwm88"
High Impact

Negative

DBS
```

---

Generate:

```text id="jlwm93"
Notification
```

---

# Economic Calendar

Store:

```text id="jlwm94"
Fed

MAS

Inflation

GDP

Employment
```

events.

---

Display:

```text id="jlwm95"
Countdown
```

until release.

---

# Why Economic Calendars Matter

Because markets often move:

```text id="jlwm96"
Before
```

the event occurs.

---

# Social Sentiment

Sources:

```text id="jlwm97"
Twitter/X

Reddit

Forums
```

---

Compute:

```text id="jlwm98"
Crowd Sentiment
```

---

Question:

```text id="jlwm99"
What do people believe?
```

---

# Information Flow Architecture

```text id="jlwma0"
News Sources
        |
        V

Collectors
        |
        V

Parsers
        |
        V

Classifiers
        |
        V

Sentiment
        |
        V

Event Bus
        |
        V

Portfolio
        |
        V

Risk
        |
        V

Panel
```

---

# Why Information Matters

Because markets react to:

```text id="jlwma1"
Beliefs
```

and beliefs spread through:

```text id="jlwma2"
Information Networks
```

---

# Architecture Lesson #31

Beginners think:

```text id="jlwma3"
News
   =
Text
```

Professionals think:

```text id="jlwma4"
News
   =
A Real-Time
Information Propagation System
that modifies
market expectations
```

---

# Current Architecture

```text id="jlwma5"
Market Feed
        |
        +------ Order Flow
        |
        +------ News
        |
        +------ Economic Events
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
        +------ Analytics
        |
        V

Panel
```

TickerHub now contains:

✅ News ingestion

✅ Event classification

✅ Symbol extraction

✅ Sentiment analysis

✅ Importance scoring

✅ Event studies

✅ News clustering

✅ Breaking news detection

✅ Economic calendar

✅ Social sentiment

✅ Information propagation

At this point, TickerHub no longer resembles a trading terminal.

It resembles:

```text
A Real-Time Information Processing System
designed to model
how beliefs,
expectations,
and information
propagate through financial markets.
```

---

# In Part 32

We will build the **Alerting, Surveillance & Complex Event Processing Engine**, where you'll discover that professional trading systems are not designed merely to:

```text
Observe markets
```

but to:

```text
Detect,
predict,
and react
to meaningful patterns
before humans can.
```
