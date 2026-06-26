# APPENDIX H — EVENT CATALOG & EVENT-SOURCING REFERENCE

# TickerHub Canonical Event Model

> *"In distributed systems, the truth is not stored in databases. The truth is stored in the history of events."*

---

# Purpose

This appendix defines the canonical event architecture of TickerHub.

The goals are to:

* define all business events
* establish event ownership
* define event contracts
* define event versioning
* establish event sourcing rules
* define replay strategies
* define CQRS patterns

---

# Event Philosophy

TickerHub follows:

```text id="evt001"
Event Sourcing

+

CQRS

+

Event Streaming
```

This means:

```text id="evt002"
Databases store state.

Events store history.

History is truth.
```

---

# Event Lifecycle

```text id="evt003"
Business Action

       |

Command

       |

Aggregate

       |

Domain Event

       |

Kafka

       |

Consumers

       |

Read Models
```

---

# Event Rules

---

## Rule 1

```text id="evt004"
Events are immutable.
```

---

## Rule 2

```text id="evt005"
Events describe facts,
not intentions.
```

Correct:

```text id="evt006"
TradeExecuted
```

Wrong:

```text id="evt007"
ExecuteTrade
```

---

## Rule 3

```text id="evt008"
Events occur in the past tense.
```

---

## Rule 4

```text id="evt009"
Events are forever.
```

---

# Canonical Event Envelope

Every event uses the same envelope.

```json id="evt010"
{
  "event_id": "uuid",
  "event_type": "TradeExecuted",
  "event_version": 1,
  "aggregate_id": "uuid",
  "aggregate_type": "Trade",
  "correlation_id": "uuid",
  "causation_id": "uuid",
  "producer": "TradingService",
  "timestamp": "2026-01-01T12:00:00Z",
  "payload": {},
  "metadata": {}
}
```

---

# Event Metadata

| Field          | Purpose           |
| -------------- | ----------------- |
| event_id       | Unique event      |
| correlation_id | Trace transaction |
| causation_id   | Parent event      |
| producer       | Service owner     |
| timestamp      | Ordering          |
| version        | Schema evolution  |

---

# Event Taxonomy

```text id="evt011"
Market

Trading

Portfolio

Risk

Analytics

Alert

Research

AI

Infrastructure

Audit
```

---

# Market Events

---

## PriceUpdated

```json id="evt012"
{
  "symbol": "D05",
  "price": 34.56,
  "volume": 120000,
  "exchange": "SGX"
}
```

---

## OrderBookUpdated

```json id="evt013"
{
  "symbol": "D05",
  "bid": [],
  "ask": [],
  "timestamp": "..."
}
```

---

## TradePrinted

```json id="evt014"
{
  "symbol": "D05",
  "price": 34.60,
  "quantity": 5000
}
```

---

## MarketOpened

```json id="evt015"
{
  "exchange": "SGX"
}
```

---

## MarketClosed

```json id="evt016"
{
  "exchange": "SGX"
}
```

---

# Trading Events

---

## OrderCreated

```json id="evt017"
{
  "order_id": "...",
  "symbol": "D05",
  "side": "BUY",
  "quantity": 1000
}
```

---

## OrderSubmitted

```json id="evt018"
{
  "order_id": "..."
}
```

---

## OrderAccepted

```json id="evt019"
{
  "order_id": "...",
  "venue": "SGX"
}
```

---

## OrderRejected

```json id="evt020"
{
  "order_id": "...",
  "reason": "Insufficient funds"
}
```

---

## OrderCancelled

```json id="evt021"
{
  "order_id": "..."
}
```

---

## TradeExecuted

```json id="evt022"
{
  "trade_id": "...",
  "order_id": "...",
  "price": 34.55,
  "quantity": 1000
}
```

---

# Portfolio Events

---

## PositionOpened

```json id="evt023"
{
  "portfolio_id": "...",
  "symbol": "D05",
  "quantity": 1000
}
```

---

## PositionUpdated

```json id="evt024"
{
  "portfolio_id": "...",
  "market_value": 500000
}
```

---

## PositionClosed

```json id="evt025"
{
  "portfolio_id": "...",
  "symbol": "D05"
}
```

---

## ExposureUpdated

```json id="evt026"
{
  "sector": "Financials",
  "exposure": 0.25
}
```

---

# Risk Events

---

## VaRCalculated

```json id="evt027"
{
  "portfolio_id": "...",
  "var": 123456
}
```

---

## CVaRCalculated

```json id="evt028"
{
  "portfolio_id": "...",
  "cvar": 160000
}
```

---

## StressTestCompleted

```json id="evt029"
{
  "scenario": "COVID",
  "loss": -500000
}
```

---

## RiskThresholdBreached

```json id="evt030"
{
  "metric": "VaR",
  "value": 500000
}
```

---

# Analytics Events

---

## PnLCalculated

```json id="evt031"
{
  "portfolio_id": "...",
  "daily_pnl": 45000
}
```

---

## SharpeCalculated

```json id="evt032"
{
  "portfolio_id": "...",
  "sharpe": 1.8
}
```

---

## AttributionCalculated

```json id="evt033"
{
  "sector": "Tech",
  "contribution": 0.15
}
```

---

## ReportGenerated

```json id="evt034"
{
  "report_id": "..."
}
```

---

# Alert Events

---

## AlertCreated

```json id="evt035"
{
  "alert_id": "...",
  "type": "PRICE"
}
```

---

## AlertTriggered

```json id="evt036"
{
  "alert_id": "...",
  "symbol": "D05"
}
```

---

## NotificationSent

```json id="evt037"
{
  "notification_id": "...",
  "channel": "EMAIL"
}
```

---

# Research Events

---

## NewsReceived

```json id="evt038"
{
  "headline": "...",
  "source": "Reuters"
}
```

---

## ResearchIndexed

```json id="evt039"
{
  "document_id": "..."
}
```

---

## EmbeddingGenerated

```json id="evt040"
{
  "document_id": "...",
  "vector_size": 1536
}
```

---

# AI Events

---

## PromptSubmitted

```json id="evt041"
{
  "prompt_id": "...",
  "user_id": "..."
}
```

---

## RetrievalCompleted

```json id="evt042"
{
  "documents": 15
}
```

---

## RecommendationGenerated

```json id="evt043"
{
  "recommendation_id": "...",
  "confidence": 0.87
}
```

---

## AgentCompleted

```json id="evt044"
{
  "agent": "ResearchAgent"
}
```

---

# Infrastructure Events

---

## ServiceStarted

```json id="evt045"
{
  "service": "MarketService"
}
```

---

## ServiceStopped

```json id="evt046"
{
  "service": "MarketService"
}
```

---

## CircuitBreakerOpened

```json id="evt047"
{
  "dependency": "Redis"
}
```

---

## DatabaseFailover

```json id="evt048"
{
  "database": "PostgreSQL"
}
```

---

# Security Events

---

## LoginSucceeded

```json id="evt049"
{
  "user_id": "..."
}
```

---

## LoginFailed

```json id="evt050"
{
  "username": "..."
}
```

---

## PermissionDenied

```json id="evt051"
{
  "user_id": "...",
  "resource": "portfolio"
}
```

---

## SecurityViolation

```json id="evt052"
{
  "type": "RBAC"
}
```

---

# Event Topics

---

## Market

```text id="evt053"
market-events
```

---

## Trading

```text id="evt054"
trading-events
```

---

## Portfolio

```text id="evt055"
portfolio-events
```

---

## Risk

```text id="evt056"
risk-events
```

---

## Analytics

```text id="evt057"
analytics-events
```

---

## Research

```text id="evt058"
research-events
```

---

## AI

```text id="evt059"
ai-events
```

---

# Event Partitioning

Partition key:

```text id="evt060"
aggregate_id
```

Example:

```text id="evt061"
PortfolioID

↓

Same Partition

↓

Ordering Guaranteed
```

---

# Event Versioning

---

## Version 1

```json id="evt062"
{
  "symbol":"D05",
  "price":34
}
```

---

## Version 2

```json id="evt063"
{
  "symbol":"D05",
  "price":34,
  "exchange":"SGX"
}
```

---

## Rule

```text id="evt064"
Never modify old events.

Create new versions.
```

---

# Event Store Schema

```sql id="evt065"
events
(
    event_id UUID,

    aggregate_id UUID,

    aggregate_type VARCHAR,

    event_type VARCHAR,

    version INTEGER,

    payload JSONB,

    metadata JSONB,

    timestamp TIMESTAMP
)
```

---

# Snapshot Strategy

---

## Snapshot Every

```text id="evt066"
100 events
```

---

## Example

```text id="evt067"
Position

↓

1000 events

↓

10 snapshots
```

---

# Replay Architecture

```text id="evt068"
Event Store

     |

Replay

     |

Service

     |

Read Model
```

---

# CQRS Architecture

```text id="evt069"
Commands

     |

Write Model

     |

Events

     |

Read Model

     |

Queries
```

---

# Event Flow Example

```text id="evt070"
Place Order

      |

OrderCreated

      |

OrderAccepted

      |

TradeExecuted

      |

PositionUpdated

      |

VaRCalculated

      |

PnLCalculated

      |

AlertTriggered
```

---

# Event Retention

| Event     | Retention |
| --------- | --------- |
| Trading   | Forever   |
| Portfolio | Forever   |
| Market    | Forever   |
| Risk      | Forever   |
| Analytics | Forever   |
| Security  | Forever   |

---

# Event Design Principles

TickerHub events follow:

```text id="evt071"
Immutable

+

Append-only

+

Versioned

+

Auditable

+

Replayable

+

Traceable
```

---

# Final Principle

```text id="evt072"
Databases tell you
what the system is.

Events tell you
how the system became that way.
```

And therefore:

```text id="evt073"
If you lose the database,

you lose the present.

If you lose the events,

you lose reality.
```
