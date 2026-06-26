# APPENDIX B — DOMAIN MODEL REFERENCE

# TickerHub Canonical Domain Model

> *"Software architecture is ultimately the organization of business concepts."*

---

# Purpose

This appendix defines the **canonical business domain model** of TickerHub.

The goals of this document are:

* establish a ubiquitous language
* define ownership boundaries
* define invariants
* define aggregate roots
* define state transitions
* define relationships
* prevent domain leakage

---

# Domain Overview

TickerHub consists of nine major business domains.

```text id="xsk1ic"
Identity
Market
Trading
Portfolio
Risk
Research
Analytics
Alerting
AI
```

---

# High-Level Domain Map

```text id="bcjlwm"
                    USER
                      |
        --------------------------------
        |              |              |
        V              V              V

   PORTFOLIO      WORKSPACE        ALERTS
        |
        |
        V

     POSITION
        |
        V

      TRADE
        |
        V

      ORDER
        |
        V

   EXECUTION
        |
        V

    INSTRUMENT
        |
        V

      MARKET
        |
        V

       RISK
        |
        V

    ANALYTICS
        |
        V

         AI
```

---

# Domain: Identity

---

## User

### Description

Represents an authenticated person using TickerHub.

---

### Attributes

```text id="m0kz97"
user_id
username
email
status
created_at
last_login
```

---

### Invariants

```text id="nhpvqq"
email unique

username unique

user_id immutable
```

---

### States

```text id="j2zq0q"
Created

Active

Suspended

Disabled

Deleted
```

---

### Aggregate Root

```text id="p71w0g"
YES
```

---

## Role

Represents authorization groups.

---

### Examples

```text id="jv0esn"
Trader
Analyst
Administrator
RiskOfficer
Researcher
```

---

## Session

Represents authenticated access.

---

### Attributes

```text id="2w3m8k"
session_id
jwt_id
user_id
created_at
expires_at
ip_address
```

---

# Domain: Market

---

## Exchange

Represents a trading venue.

---

### Examples

```text id="5j2ef8"
SGX
NYSE
NASDAQ
HKEX
LSE
```

---

### Attributes

```text id="jtd1qo"
exchange_id
code
name
timezone
country
```

---

## Instrument

Represents a tradable asset.

---

### Types

```text id="xjlwm6"
Stock
ETF
Bond
Option
Future
FX
Commodity
Crypto
```

---

### Attributes

```text id="cbjlwm"
instrument_id
symbol
name
currency
exchange
sector
industry
```

---

### Invariants

```text id="v1olq0"
symbol unique within exchange
```

---

### Aggregate Root

```text id="mjlwmv"
YES
```

---

## Quote

Represents a market snapshot.

---

### Attributes

```text id="8pjlwm"
bid
ask
last
volume
timestamp
```

---

### Lifetime

```text id="gjlwm9"
milliseconds
```

---

## OrderBook

Represents market depth.

---

### Structure

```text id="rjlwm8"
Bids

Asks

Levels
```

---

Example:

```text id="5jlwm7"
100.10  2000
100.09  5000
100.08  1000

-------

100.11  3000
100.12  2000
100.13  7000
```

---

## MarketEvent

Represents exchange activity.

---

### Examples

```text id="vjlwm6"
PriceUpdated
TradePrinted
AuctionOpened
MarketClosed
```

---

# Domain: Trading

---

## Order

Represents a trading instruction.

---

### Attributes

```text id="xjlwm5"
order_id
portfolio_id
instrument_id
side
quantity
price
status
type
created_at
```

---

### Order Types

```text id="yjlwm4"
Market
Limit
Stop
StopLimit
Iceberg
```

---

### States

```text id="7jlwm3"
Created
Submitted
Accepted
Rejected
PartiallyFilled
Filled
Cancelled
Expired
```

---

### State Machine

```text id="vjlwm2"
Created

   |

Submitted

   |

Accepted

   |

PartiallyFilled

   |

Filled
```

---

### Invariants

```text id="3jlwm1"
quantity > 0

price >= 0

immutable order_id
```

---

### Aggregate Root

```text id="0jlwm0"
YES
```

---

## Execution

Represents exchange execution.

---

### Attributes

```text id="fjlwm9"
execution_id
order_id
price
quantity
venue
timestamp
```

---

### Rules

```text id="ljlwm8"
one order

may have

many executions
```

---

## Trade

Represents a completed trade.

---

### Attributes

```text id="xjlwm7"
trade_id
execution_id
portfolio_id
price
quantity
commission
timestamp
```

---

### Aggregate Root

```text id="yjlwm6"
NO
```

---

# Domain: Portfolio

---

## Portfolio

Represents investment holdings.

---

### Attributes

```text id="zjlwm5"
portfolio_id
owner_id
name
base_currency
created_at
```

---

### Relationships

```text id="1klm0a"
Portfolio

    |

    +---- Position

    |

    +---- Cash

    |

    +---- Exposure
```

---

### Aggregate Root

```text id="2klm0b"
YES
```

---

## Position

Represents ownership of an instrument.

---

### Attributes

```text id="3klm0c"
position_id
instrument_id
quantity
average_price
market_price
```

---

### Derived Fields

```text id="4klm0d"
market_value

unrealized_pnl

realized_pnl
```

---

### Invariants

```text id="5klm0e"
market_value >= 0
```

---

## CashBalance

Represents cash holdings.

---

### Attributes

```text id="6klm0f"
currency
balance
available
reserved
```

---

## Exposure

Represents portfolio risk exposure.

---

### Examples

```text id="7klm0g"
Sector

Country

Currency

Factor

Duration
```

---

# Domain: Risk

---

## RiskSnapshot

Represents calculated portfolio risk.

---

### Attributes

```text id="8klm0h"
var
cvar
expected_shortfall
volatility
beta
timestamp
```

---

### Characteristics

```text id="9klm0i"
Immutable
Versioned
Historical
```

---

## Scenario

Represents market stress conditions.

---

### Examples

```text id="aklm0j"
COVID
2008
OilCrash
InterestShock
```

---

## StressResult

Represents scenario output.

---

### Attributes

```text id="bklm0k"
scenario
portfolio
pnl
exposure
risk
```

---

# Domain: Analytics

---

## Metric

Represents calculated analytics.

---

### Examples

```text id="cklm0l"
Sharpe

Sortino

Alpha

Beta

Drawdown
```

---

## Attribution

Represents performance decomposition.

---

### Example

```text id="dklm0m"
Portfolio Return

    |

Sector Contribution

    |

Stock Contribution
```

---

## Report

Represents generated analytics.

---

### Types

```text id="eklm0n"
Daily

Weekly

Monthly

Risk

Performance
```

---

# Domain: Research

---

## News

Represents news articles.

---

### Attributes

```text id="fklm0o"
headline
body
source
published_at
```

---

## ResearchDocument

Represents institutional research.

---

### Examples

```text id="gklm0p"
Equity Report

Macro Report

Sector Report

Strategy Report
```

---

## DocumentChunk

Represents RAG chunks.

---

### Attributes

```text id="hklm0q"
document_id
chunk
embedding
metadata
```

---

# Domain: Alerting

---

## Alert

Represents notification rules.

---

### Examples

```text id="iklm0r"
Price Alert

Volume Alert

Risk Alert

News Alert
```

---

### States

```text id="jklm0s"
Created

Active

Triggered

Expired
```

---

## Notification

Represents alert delivery.

---

### Types

```text id="kklm0t"
Email

SMS

Desktop

Webhook
```

---

# Domain: Workspace

---

## Workspace

Represents a user's desktop layout.

---

### Attributes

```text id="lklm0u"
workspace_id
owner
name
layout
created_at
```

---

### Contains

```text id="mklm0v"
Panels
Charts
Watchlists
Dashboards
Alerts
```

---

## Widget

Represents a visual component.

---

### Types

```text id="nklm0w"
Chart
Grid
Watchlist
News
Portfolio
Analytics
```

---

# Domain: AI

---

## Prompt

Represents user requests.

---

### Attributes

```text id="oklm0x"
prompt_id
user_id
prompt
timestamp
```

---

## Retrieval

Represents RAG retrieval.

---

### Attributes

```text id="pklm0y"
query
documents
confidence
```

---

## Recommendation

Represents AI output.

---

### Attributes

```text id="qklm0z"
recommendation
explanation
confidence
sources
```

---

## Agent

Represents autonomous AI behavior.

---

### Examples

```text id="rklm10"
ResearchAgent

PortfolioAgent

RiskAgent

MarketAgent
```

---

# Aggregate Boundaries

```text id="sklm11"
User

Portfolio

Instrument

Order

Workspace

Alert
```

are aggregate roots.

---

Non-roots:

```text id="tklm12"
Position
Trade
Execution
Cash
Exposure
Quote
Notification
```

---

# Entity Relationships

```text id="uklm13"
User
 |
 +------ Portfolio
 |          |
 |          +---- Position
 |          |
 |          +---- Cash
 |
 +------ Workspace
 |
 +------ Alert
 |
 +------ Session

Instrument
 |
 +------ Quote
 |
 +------ OrderBook
 |
 +------ Trade

Order
 |
 +------ Execution
 |
 +------ Trade

Portfolio
 |
 +------ Risk
 |
 +------ Analytics
```

---

# Ownership Matrix

| Entity         | Owner Domain |
| -------------- | ------------ |
| User           | Identity     |
| Instrument     | Market       |
| Order          | Trading      |
| Trade          | Trading      |
| Portfolio      | Portfolio    |
| Position       | Portfolio    |
| Risk           | Risk         |
| Report         | Analytics    |
| Alert          | Alerting     |
| Workspace      | Workspace    |
| Prompt         | AI           |
| Recommendation | AI           |

---

# Domain Event Producers

| Domain    | Events                  |
| --------- | ----------------------- |
| Market    | PriceUpdated            |
| Trading   | OrderSubmitted          |
| Trading   | TradeExecuted           |
| Portfolio | PositionUpdated         |
| Risk      | RiskCalculated          |
| Alerting  | AlertTriggered          |
| AI        | RecommendationGenerated |

---

# Domain Design Principles

TickerHub follows:

```text id="vklm14"
Rich Domain Models

+

Aggregate Roots

+

Event Sourcing

+

DDD Boundaries

+

Immutable Events

+

CQRS
```

---

# Final Principle

```text id="wklm15"
TickerHub is not organized around:

controllers
services
repositories
utils
```

It is organized around:

```text id="xklm16"
Markets

Trading

Portfolio

Risk

Analytics

Research

AI
```

because in financial systems:

```text id="yklm17"
Business Domains
are the true architecture.
```
