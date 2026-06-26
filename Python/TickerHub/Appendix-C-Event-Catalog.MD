# APPENDIX C — EVENT CATALOG

# TickerHub Enterprise Event Catalog

> *"Events are the memory of the enterprise."*

---

# Purpose

This document defines the canonical event taxonomy for TickerHub.

The event catalog serves as the:

* communication contract
* audit model
* replay mechanism
* integration specification
* observability foundation
* event sourcing schema

---

# Event Design Principles

All events in TickerHub follow the following rules:

---

## Rule 1

```text id="f1u8dr"
Events Describe Facts
```

Good:

```text id="6kib10"
OrderSubmitted
TradeExecuted
PositionClosed
```

Bad:

```text id="cwkg0z"
ExecuteTrade
UpdatePosition
CalculateRisk
```

---

## Rule 2

```text id="y0bqq6"
Events Are Immutable
```

Never:

```text id="qzm4c6"
UPDATE EVENT
```

Always:

```text id="5jx5c7"
Create New Event
```

---

## Rule 3

```text id="thl2jc"
Events Are Versioned
```

Example:

```text id="cxjg8v"
PriceUpdatedV1

PriceUpdatedV2
```

---

## Rule 4

```text id="6l9vjh"
Events Must Be Replayable
```

---

# Canonical Event Envelope

Every event inherits from:

```json
{
    "event_id": "uuid",
    "event_type": "PriceUpdated",
    "event_version": 1,
    "aggregate_id": "uuid",
    "aggregate_type": "Instrument",
    "correlation_id": "uuid",
    "causation_id": "uuid",
    "producer": "MarketService",
    "timestamp": "2026-06-26T10:00:00Z",
    "payload": {}
}
```

---

# Event Categories

```text id="06md5s"
Market Events
Trading Events
Portfolio Events
Risk Events
Analytics Events
Alert Events
Research Events
Workspace Events
AI Events
Infrastructure Events
Security Events
```

---

# Market Events

---

## PriceUpdated

### Producer

```text id="1z8flq"
MarketService
```

### Consumers

```text id="f76o4n"
PortfolioService
RiskService
ChartComponent
AlertService
AnalyticsService
```

### Payload

```json
{
    "symbol": "D05",
    "bid": 43.20,
    "ask": 43.21,
    "last": 43.20,
    "volume": 120000
}
```

---

## TradePrinted

### Producer

```text id="h2aq3r"
FeedWorker
```

### Consumers

```text id="afh7sj"
Analytics
Portfolio
Charts
```

---

## OrderBookUpdated

### Producer

```text id="sq6lbh"
MarketService
```

### Payload

```json
{
    "symbol": "D05",
    "bids": [],
    "asks": []
}
```

---

## MarketOpened

---

## MarketClosed

---

## TradingHalt

---

## AuctionStarted

---

## AuctionCompleted

---

# Trading Events

---

## OrderCreated

### Aggregate

```text id="c2l4wp"
Order
```

### Producer

```text id="0sjikj"
TradingService
```

### Consumers

```text id="68jlwm"
RiskService
AuditService
PortfolioService
```

---

### Payload

```json
{
    "order_id": "uuid",
    "portfolio_id": "uuid",
    "symbol": "D05",
    "side": "BUY",
    "quantity": 100,
    "price": 42.50
}
```

---

## OrderSubmitted

---

## OrderValidated

---

## OrderAccepted

---

## OrderRejected

---

### Rejection Reasons

```text id="j2sdql"
InsufficientFunds
InvalidInstrument
RiskViolation
MarketClosed
PermissionDenied
```

---

## OrderCancelled

---

## OrderExpired

---

## OrderPartiallyFilled

---

## OrderFilled

---

### Payload

```json
{
    "order_id": "uuid",
    "filled_quantity": 100,
    "price": 42.20
}
```

---

## ExecutionReceived

---

## TradeExecuted

### Producer

```text id="vjlwmn"
ExecutionService
```

### Consumers

```text id="kwm92v"
PortfolioService
RiskService
AnalyticsService
```

---

### Payload

```json
{
    "trade_id": "uuid",
    "symbol": "D05",
    "price": 42.50,
    "quantity": 100
}
```

---

# Portfolio Events

---

## PortfolioCreated

---

## PortfolioDeleted

---

## PositionOpened

### Payload

```json
{
    "portfolio_id": "uuid",
    "symbol": "D05",
    "quantity": 100,
    "price": 42.50
}
```

---

## PositionIncreased

---

## PositionReduced

---

## PositionClosed

---

## PositionMarkedToMarket

---

## CashDeposited

---

## CashWithdrawn

---

## CurrencyConverted

---

## ExposureUpdated

---

# Risk Events

---

## RiskCalculationRequested

### Producer

```text id="m0f6lr"
PortfolioService
```

### Consumer

```text id="jlwmps"
RiskWorker
```

---

## VaRCalculated

### Payload

```json
{
    "portfolio_id": "uuid",
    "var": 125000,
    "confidence": 0.95
}
```

---

## CVaRCalculated

---

## StressTestCompleted

---

## ScenarioCompleted

---

## MarginCallTriggered

---

## ExposureLimitExceeded

---

## RiskThresholdBreached

---

# Analytics Events

---

## AnalyticsStarted

---

## AnalyticsCompleted

---

## PnLCalculated

---

### Payload

```json
{
    "portfolio_id": "uuid",
    "daily_pnl": 12000,
    "monthly_pnl": 45000
}
```

---

## AttributionCalculated

---

## SharpeCalculated

---

## FactorExposureCalculated

---

## ReportGenerated

---

# Alert Events

---

## AlertCreated

---

## AlertActivated

---

## AlertTriggered

### Payload

```json
{
    "alert_id": "uuid",
    "symbol": "D05",
    "trigger_price": 45.00
}
```

---

## AlertExpired

---

## NotificationSent

---

## NotificationFailed

---

# Research Events

---

## NewsReceived

---

### Payload

```json
{
    "headline": "Fed raises rates",
    "source": "Reuters"
}
```

---

## ResearchUploaded

---

## ResearchIndexed

---

## EmbeddingGenerated

---

## KnowledgeGraphUpdated

---

## EntityDiscovered

---

# Workspace Events

---

## WorkspaceCreated

---

## WorkspaceLoaded

---

## WorkspaceSaved

---

## WidgetAdded

---

## WidgetRemoved

---

## LayoutChanged

---

# AI Events

---

## PromptSubmitted

### Payload

```json
{
    "user_id": "uuid",
    "prompt": "Analyze DBS."
}
```

---

## RetrievalStarted

---

## RetrievalCompleted

---

## ContextAssembled

---

## LLMRequested

---

## LLMCompleted

---

## RecommendationGenerated

---

### Payload

```json
{
    "recommendation": "Buy DBS",
    "confidence": 0.82
}
```

---

## AgentStarted

---

## AgentCompleted

---

## HallucinationDetected

---

# Security Events

---

## LoginSucceeded

---

## LoginFailed

---

## SessionCreated

---

## SessionExpired

---

## PermissionDenied

---

## SecretRotated

---

## MFAChallengeIssued

---

## MFAChallengeCompleted

---

## AuditLogCreated

---

# Infrastructure Events

---

## ServiceStarted

---

## ServiceStopped

---

## ServiceFailed

---

## DatabaseConnected

---

## DatabaseDisconnected

---

## CacheMiss

---

## CacheHit

---

## KafkaConnected

---

## KafkaDisconnected

---

## CircuitBreakerOpened

---

## CircuitBreakerClosed

---

# Event Ownership Matrix

| Event Category | Owner          |
| -------------- | -------------- |
| Market         | Market Team    |
| Trading        | Trading Team   |
| Portfolio      | Portfolio Team |
| Risk           | Risk Team      |
| Analytics      | Analytics Team |
| Alert          | Alert Team     |
| Research       | Research Team  |
| AI             | AI Team        |
| Security       | Security Team  |
| Infrastructure | Platform Team  |

---

# Event Storage Strategy

| Event Type | Storage           |
| ---------- | ----------------- |
| Market     | Kafka + Data Lake |
| Trading    | EventStore        |
| Portfolio  | EventStore        |
| Risk       | PostgreSQL        |
| Analytics  | PostgreSQL        |
| Alert      | PostgreSQL        |
| AI         | PostgreSQL        |
| Security   | Audit Store       |

---

# Event Retention Policy

| Event          | Retention |
| -------------- | --------- |
| Trades         | Forever   |
| Orders         | Forever   |
| Portfolio      | Forever   |
| Risk           | 10 years  |
| Security       | 7 years   |
| Market         | Forever   |
| AI             | 2 years   |
| Infrastructure | 90 days   |

---

# Event Versioning Strategy

Example:

```text id="bjlwmx"
PriceUpdatedV1

        ↓

PriceUpdatedV2

        ↓

PriceUpdatedV3
```

Rules:

```text id="yjlwmw"
Never break old consumers

Never delete fields

Only add fields

Always preserve replay
```

---

# Event Replay Architecture

```text id="zjlwmv"
Historical Events

        ↓

Kafka Replay

        ↓

Consumer Group

        ↓

Projection

        ↓

Read Model
```

---

# Event Correlation

Example:

```text id="0klmw0"
OrderSubmitted

        ↓

OrderAccepted

        ↓

TradeExecuted

        ↓

PositionUpdated

        ↓

RiskCalculated
```

All linked by:

```text id="1klmw1"
correlation_id
```

---

# Event Causation

Example:

```text id="2klmw2"
PriceUpdated

        ↓

PositionMarked

        ↓

PnLCalculated

        ↓

RiskCalculated
```

All linked by:

```text id="3klmw3"
causation_id
```

---

# Event Flow Example

```text id="4klmw4"
Market Feed

      ↓

PriceUpdated

      ↓

PortfolioService

      ↓

PositionMarkedToMarket

      ↓

AnalyticsService

      ↓

PnLCalculated

      ↓

RiskService

      ↓

VaRCalculated

      ↓

AlertService

      ↓

AlertTriggered
```

---

# Event Design Principles

TickerHub events must be:

```text id="5klmw5"
Immutable

Replayable

Versioned

Observable

Auditable

Traceable

Distributed
```

---

# Final Principle

```text id="6klmw6"
Databases store state.

Events store truth.
```

And in TickerHub:

```text id="7klmw7"
Truth is the architecture.
```
