# Building TickerHub

## Part 18: Building the News & Alerts System — Turning Information into Market Events

> Markets do not move because prices change.
>
> Prices change because information changes.

Professional traders understand that market data is only half the story.

The other half is:

* news,
* announcements,
* earnings,
* analyst reports,
* economic releases,
* social sentiment,
* breaking events.

A professional trading terminal treats information itself as a:

```text id="yj3vfk"
Real-Time Event Stream
```

rather than:

```text id="v4ezhz"
A News Feed
```

---

# The Beginner News Feed

Most tutorials build news like this:

```python id="pfjlwm"
news = requests.get(
    "/news"
).json()
```

Then:

```python id="jlwmwi"
for article in news:

    display(article)
```

This works.

Until:

* hundreds of stories arrive,
* multiple symbols are tracked,
* alerts need triggering,
* sentiment changes,
* users customize subscriptions.

Then:

```text id="ojmv8u"
News Reader
```

becomes:

```text id="0rjn3f"
Event Intelligence Platform
```

---

# Professional News Architecture

```text id="b7okfx"
News Sources
        |
        V

Feed Workers
        |
        V

News Service
        |
        V

Event Bus
        |
        V

Alert Service
        |
        V

News State
        |
        V

Panel Components
```

Notice:

```text id="7om8mw"
News never goes
directly to the UI.
```

---

# News Sources

Professional terminals aggregate:

```text id="2e99wn"
Reuters

Bloomberg

Dow Jones

SEC

SGX

MAS

Twitter/X

Reddit

Company Filings
```

TickerHub's MVP will simulate:

```text id="b48g5w"
Institutional News Feed
```

---

# Domain Model

Create:

```text id="kmw3o0"
domain/

    news.py
```

---

```python id="ihn2lh"
from dataclasses import dataclass
from datetime import datetime
```

---

```python id="3chjlwm"
@dataclass
class NewsItem:

    news_id: str

    symbol: str

    headline: str

    source: str

    sentiment: float

    timestamp: datetime
```

---

# Example

```text id="5o7a6m"
ID:
    123

Symbol:
    D05

Headline:
    DBS beats estimates

Source:
    Reuters

Sentiment:
    +0.8
```

---

# News State

Create:

```text id="g9fwax"
state/

    news_state.py
```

---

```python id="8msrhh"
import param
```

---

```python id="c0jvzl"
class NewsState(

    param.Parameterized
):

    news = param.List()

    alerts = param.List()
```

---

# News Service

Create:

```text id="vvfj9g"
services/

    news_service.py
```

---

```python id="whp6mr"
class NewsService:

    def __init__(

        self,

        state,

        bus
    ):

        self.state = state

        self.bus = bus
```

---

# Publishing News

Create:

```python id="nvj3r0"
def publish(

    self,

    item
):
```

---

Append:

```python id="h2dxxa"
self.state.news.append(
    item
)
```

---

Publish event:

```python id="w3zkq4"
self.bus.publish(

    NewsArrived(
        item
    )
)
```

---

# Why Event Bus?

Because:

```text id="9wq9em"
One news item
may affect:

Charts

Alerts

Portfolio

Risk

Watchlists

Analytics
```

---

# Example Event

Create:

```python id="cwltzj"
@dataclass
class NewsArrived:

    news: NewsItem
```

---

# Example News Flow

Suppose:

```text id="79ik8s"
Reuters publishes:

DBS beats expectations
```

Then:

```text id="8z7qgj"
Reuters
     |
     V

Feed Worker
     |
     V

News Service
     |
     V

Event Bus
```

---

# Simulating News Feed

Create:

```text id="r5m4t4"
workers/

    news_worker.py
```

---

```python id="okjrgw"
import asyncio
import random
```

---

Example:

```python id="y29jq1"
HEADLINES = [

    "DBS beats estimates",

    "UOB misses forecasts",

    "MAS cuts rates",

    "Oil prices surge"
]
```

---

Worker:

```python id="d9gb4m"
while True:

    headline = random.choice(
        HEADLINES
    )
```

---

Create:

```python id="ckk20a"
item = NewsItem(

    news_id=str(uuid4()),

    symbol="D05",

    headline=headline,

    source="Reuters",

    sentiment=0.8,

    timestamp=datetime.now()
)
```

---

Publish:

```python id="31w5lm"
news_service.publish(
    item
)
```

---

Sleep:

```python id="0xhggh"
await asyncio.sleep(5)
```

---

# News Component

Create:

```text id="yxyq83"
components/

    news/

        news_panel.py
```

---

Create:

```python id="w6pc9a"
class NewsPanel(

    param.Parameterized
):
```

---

Subscribe:

```python id="p2wnj4"
state.news.param.watch(

    self.refresh,

    "news"
)
```

---

Refresh:

```python id="pqwwv4"
def refresh(

    self,

    *events
):
```

---

Build:

```python id="6h8mch"
rows = []
```

---

Loop:

```python id="p9qlch"
for item in reversed(

    self.state.news.news
):
```

---

Append:

```python id="wg0tjh"
rows.append({

    "Time":
        item.timestamp,

    "Symbol":
        item.symbol,

    "Headline":
        item.headline,

    "Source":
        item.source
})
```

---

Render:

```python id="q3fxwe"
self.table.value = (
    pd.DataFrame(
        rows
    )
)
```

---

# First Result

```text id="v0jxbo"
----------------------------------
09:30  D05  DBS beats estimates

09:31  U11  UOB misses forecasts

09:32  MAS  Rates reduced
----------------------------------
```

---

# Why This Is Still Wrong

Because traders don't read:

```text id="0gk85n"
Everything.
```

They read:

```text id="rr5ycm"
Relevant Things.
```

---

# Filtering

Example:

```python id="xhljlwm"
watchlist = [

    "D05",

    "U11"
]
```

---

Filter:

```python id="jvry5m"
if item.symbol in watchlist:

    display(item)
```

---

# Sentiment

Assign:

```python id="vdf80u"
sentiment
```

between:

```text id="q2yjlwm"
-1.0

and

+1.0
```

---

Example:

```text id="z44prg"
DBS beats estimates

+0.8
```

---

Example:

```text id="26vgrl"
DBS under investigation

-0.9
```

---

# Sentiment Heatmap

Display:

```text id="x75nmp"
Positive

↓

Green
```

---

Display:

```text id="prk6v2"
Negative

↓

Red
```

---

Example:

```text id="gkz2c0"
D05    +0.8

U11    -0.6
```

---

# Alert Service

Professional terminals don't wait for traders.

They proactively notify.

---

Create:

```text id="4kx0n5"
services/

    alert_service.py
```

---

```python id="jlwmfd"
class AlertService:
```

---

Register:

```python id="njlwmu"
bus.subscribe(

    NewsArrived,

    self.on_news
)
```

---

# Example Rule

```python id="bwwc2z"
if abs(

    news.sentiment

) > 0.7:
```

Create alert:

```python id="jlwm9a"
alert = {

    "type":
        "NEWS",

    "symbol":
        news.symbol,

    "message":
        news.headline
}
```

---

Save:

```python id="l4y8tq"
state.alerts.append(
    alert
)
```

---

# Example Alert

```text id="jlwm0q"
ALERT

D05

DBS beats estimates
```

---

# Price Alerts

Store:

```python id="jlwmj8"
alerts = {

    "D05": 45
}
```

---

Market update:

```python id="jlwmc9"
if price >= 45:

    trigger()
```

---

# Volume Alerts

Example:

```python id="jlwm42"
if volume > 100000:
```

Trigger:

```text id="jlwmrl"
Unusual Volume
```

---

# Risk Alerts

Example:

```python id="jlwmse"
if var > limit:
```

Trigger:

```text id="jlwm18"
Risk Limit Breach
```

---

# Portfolio Alerts

Example:

```python id="jlwm52"
if pnl < -5000:
```

Trigger:

```text id="jlwmub"
Stop Loss Alert
```

---

# Economic Calendar

Professional terminals monitor:

```text id="jlwm2e"
Fed

MAS

ECB

BOJ
```

events.

---

Example:

```text id="jlwmge"
14:00

US CPI
```

---

Store:

```python id="jlwm4t"
calendar = [

    {
        "event":
            "US CPI",

        "time":
            "14:00"
    }
]
```

---

# Breaking News Banner

Display:

```text id="jlwmr6"
BREAKING

DBS ANNOUNCES
SPECIAL DIVIDEND
```

---

Condition:

```python id="jlwm80"
if sentiment > 0.9:
```

---

# Sound Alerts

Professional terminals often use:

```text id="jlwmvd"
Bell

Chime

Alarm
```

depending on severity.

---

# News Analytics

Calculate:

```text id="jlwmz8"
News per hour
```

---

Example:

```python id="jlwmhj"
counts = (

    df.groupby(
        "hour"
    )
)
```

---

Calculate:

```text id="jlwm3x"
Most Mentioned Symbol
```

---

Example:

```python id="jlwmby"
top = (

    df.symbol
    .value_counts()
)
```

---

# Event Correlation

Question:

> Does bad news produce price drops?

Example:

```text id="jlwmk7"
News:

09:30

↓

Price:

09:31
```

---

Store:

```python id="jlwm8r"
event_study = {

    "news":
        time1,

    "price":
        time2
}
```

---

# News Event Flow

Suppose:

```text id="jlwm54"
Reuters publishes:

DBS misses earnings.
```

The system executes:

```text id="jlwmme"
Reuters
     |
     V

News Worker
     |
     V

News Service
     |
     V

Event Bus
     |
     +----- News Panel
     |
     +----- Alert Service
     |
     +----- Portfolio
     |
     +----- Risk
```

---

# The Real News Architecture

```text id="jlwmmt"
News Feed
      |
      V

News Service
      |
      +----- Storage
      |
      +----- Sentiment
      |
      +----- Filtering
      |
      +----- Correlation
      |
      +----- Alerts
      |
      +----- Event Bus
      |
      +----- Rendering
```

---

# Why Bloomberg News Feels Magical

Because Bloomberg does not show:

```text id="jlwmw8"
News Articles.
```

It shows:

```text id="jlwmr2"
Market-Relevant
Events
```

that are continuously filtered and prioritized.

---

# Architecture Lesson #18

Beginners think:

```text id="jlwm6g"
News
    =
Articles
```

Professionals think:

```text id="jlwm4v"
News
    =
Real-Time
Event
Intelligence
```

The article itself is simply the raw material.

---

# Current Architecture

```text id="jlwmof"
Feed Workers
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

News Service
      |
      V

Alert Service
      |
      V

Application State
      |
      ├── Watchlist
      ├── Chart
      ├── OrderBook
      ├── Portfolio
      ├── Risk
      └── News
```

TickerHub now contains:

✅ Market feed

✅ Portfolio engine

✅ Risk engine

✅ News engine

✅ Alert engine

✅ Watchlist

✅ Charts

✅ Order book

✅ Portfolio dashboard

✅ Risk dashboard

✅ News dashboard

At this point, TickerHub has evolved into:

```text id="jlwmdb"
A Real-Time Event Processing System
with a Trading Terminal attached.
```

---

# In Part 19

We will build the **Workspace & Layout Engine**, where you'll discover that professional trading screens are not:

```text id="jlwmx9"
Dashboards
```

but rather:

```text id="jlwmja"
User-programmable operating systems
for financial decision making.
```
