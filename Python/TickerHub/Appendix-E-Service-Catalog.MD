# APPENDIX E — SERVICE CATALOG

# TickerHub Microservices & Service Boundary Reference

> *"A service boundary is a business boundary with a network cable attached."*

---

# Purpose

This appendix defines the canonical service architecture of TickerHub.

The goals are to:

* define service ownership
* establish bounded contexts
* document APIs
* define event producers/consumers
* specify persistence ownership
* prevent distributed monoliths

---

# Service Landscape

TickerHub is organized into domain-oriented services.

```text id="svc001"
                    API GATEWAY
                          |
     ------------------------------------------------
     |          |          |         |             |
     V          V          V         V             V

  Market    Trading   Portfolio   Risk     Research
 Service    Service    Service   Service   Service

     |          |          |         |             |

     ------------------------------------------------
                          |
                          V

                    Analytics
                     Service
                          |
                          V

                    Alert Service
                          |
                          V

                       AI Service
```

---

# Service Classification

| Service     | Type           |
| ----------- | -------------- |
| API Gateway | Edge           |
| Market      | Core           |
| Trading     | Core           |
| Portfolio   | Core           |
| Risk        | Compute        |
| Analytics   | Compute        |
| Alert       | Support        |
| Research    | Knowledge      |
| AI          | Intelligence   |
| Auth        | Infrastructure |

---

# Service Communication Model

TickerHub uses two communication mechanisms.

---

## Synchronous

```text id="svc002"
REST

gRPC
```

Used for:

```text id="svc003"
queries
authentication
administration
```

---

## Asynchronous

```text id="svc004"
Kafka
```

Used for:

```text id="svc005"
events
notifications
streaming
analytics
risk
```

---

# API Gateway

---

## Responsibility

Provides:

```text id="svc006"
Authentication
Authorization
Routing
Rate limiting
Aggregation
API versioning
```

---

## Technology

```text id="svc007"
FastAPI
```

---

## APIs

```text id="svc008"
GET  /market/*
GET  /portfolio/*
GET  /risk/*
POST /orders/*
GET  /analytics/*
POST /ai/*
```

---

## Database Ownership

```text id="svc009"
None
```

---

# Authentication Service

---

## Responsibility

Manages:

```text id="svc010"
OAuth2
JWT
RBAC
Sessions
MFA
```

---

## APIs

```text id="svc011"
POST /login
POST /logout
POST /refresh
POST /mfa
GET  /profile
```

---

## Database

```text id="svc012"
users
roles
sessions
audit
```

---

## Events Produced

```text id="svc013"
LoginSucceeded
LoginFailed
SessionCreated
```

---

# Market Service

---

## Responsibility

Manages:

```text id="svc014"
Market feeds
Order books
Trades
Quotes
Exchanges
```

---

## Architecture

```text id="svc015"
Market Feed

      |

Feed Worker

      |

Market Service

      |

Kafka
```

---

## APIs

```text id="svc016"
GET /quotes/{symbol}

GET /orderbook/{symbol}

GET /trades/{symbol}
```

---

## Events Produced

```text id="svc017"
PriceUpdated

TradePrinted

OrderBookUpdated

MarketOpened

MarketClosed
```

---

## Events Consumed

```text id="svc018"
None
```

---

## Database Ownership

```text id="svc019"
instruments
quotes
orderbooks
exchanges
```

---

## Cache Ownership

```text id="svc020"
Redis Market Cache
```

---

# Trading Service

---

## Responsibility

Manages:

```text id="svc021"
Orders
Executions
Trades
Order routing
Validation
```

---

## APIs

```text id="svc022"
POST /orders

GET /orders

DELETE /orders
```

---

## Events Produced

```text id="svc023"
OrderCreated

OrderSubmitted

OrderAccepted

OrderRejected

TradeExecuted
```

---

## Events Consumed

```text id="svc024"
PriceUpdated
RiskThresholdBreached
```

---

## Database Ownership

```text id="svc025"
orders
executions
trades
```

---

# Portfolio Service

---

## Responsibility

Manages:

```text id="svc026"
Positions
Cash
P&L
Exposure
Valuation
```

---

## APIs

```text id="svc027"
GET /portfolio

GET /positions

GET /cash
```

---

## Events Produced

```text id="svc028"
PositionOpened

PositionClosed

PositionMarkedToMarket

ExposureUpdated
```

---

## Events Consumed

```text id="svc029"
TradeExecuted

PriceUpdated
```

---

## Database Ownership

```text id="svc030"
portfolios

positions

cash_balances

exposures
```

---

# Risk Service

---

## Responsibility

Calculates:

```text id="svc031"
VaR

CVaR

Stress tests

Factor exposures

Expected shortfall
```

---

## Architecture

```text id="svc032"
Kafka

    |

Risk Queue

    |

Risk Workers

    |

Risk Database
```

---

## APIs

```text id="svc033"
GET /risk

GET /var

GET /stress
```

---

## Events Produced

```text id="svc034"
VaRCalculated

CVaRCalculated

StressTestCompleted

RiskThresholdBreached
```

---

## Events Consumed

```text id="svc035"
TradeExecuted

PositionUpdated

PriceUpdated
```

---

## Database Ownership

```text id="svc036"
risk_snapshots

stress_tests

factor_exposures
```

---

# Analytics Service

---

## Responsibility

Calculates:

```text id="svc037"
P&L

Sharpe

Attribution

Returns

Performance
```

---

## APIs

```text id="svc038"
GET /pnl

GET /performance

GET /reports
```

---

## Events Produced

```text id="svc039"
PnLCalculated

SharpeCalculated

ReportGenerated
```

---

## Events Consumed

```text id="svc040"
PriceUpdated

TradeExecuted

PositionUpdated
```

---

## Database Ownership

```text id="svc041"
pnl_snapshots

reports

attribution
```

---

# Alert Service

---

## Responsibility

Monitors:

```text id="svc042"
Prices

Risk

News

Portfolio
```

---

## APIs

```text id="svc043"
POST /alerts

DELETE /alerts

GET /alerts
```

---

## Events Produced

```text id="svc044"
AlertTriggered

NotificationSent
```

---

## Events Consumed

```text id="svc045"
PriceUpdated

RiskThresholdBreached

NewsReceived
```

---

## Database Ownership

```text id="svc046"
alerts

notifications
```

---

# Research Service

---

## Responsibility

Manages:

```text id="svc047"
Research

News

Documents

RAG

Knowledge graph
```

---

## APIs

```text id="svc048"
GET /news

GET /research

GET /search
```

---

## Events Produced

```text id="svc049"
NewsReceived

ResearchIndexed

EmbeddingGenerated
```

---

## Events Consumed

```text id="svc050"
DocumentUploaded
```

---

## Database Ownership

```text id="svc051"
news

research_documents

document_chunks
```

---

## External Systems

```text id="svc052"
Elasticsearch

Neo4j

Qdrant
```

---

# AI Service

---

## Responsibility

Provides:

```text id="svc053"
LLM access

RAG

Agents

Recommendations

Summaries
```

---

## APIs

```text id="svc054"
POST /chat

POST /analyze

POST /research
```

---

## Events Produced

```text id="svc055"
PromptSubmitted

RetrievalCompleted

RecommendationGenerated

AgentCompleted
```

---

## Events Consumed

```text id="svc056"
ResearchIndexed

RiskCalculated

AnalyticsCompleted
```

---

## Database Ownership

```text id="svc057"
prompts

responses

recommendations
```

---

# Workspace Service

---

## Responsibility

Manages:

```text id="svc058"
Layouts

Panels

Widgets

Preferences
```

---

## APIs

```text id="svc059"
GET /workspace

POST /workspace

DELETE /workspace
```

---

## Events Produced

```text id="svc060"
WorkspaceSaved

WidgetAdded

LayoutChanged
```

---

## Database Ownership

```text id="svc061"
workspaces

widgets
```

---

# Notification Service

---

## Responsibility

Handles:

```text id="svc062"
Email

SMS

Desktop

Push
```

---

## Events Consumed

```text id="svc063"
AlertTriggered
```

---

## Events Produced

```text id="svc064"
NotificationSent

NotificationFailed
```

---

# Audit Service

---

## Responsibility

Records:

```text id="svc065"
Everything
```

---

## Events Consumed

```text id="svc066"
ALL EVENTS
```

---

## Database Ownership

```text id="svc067"
audit_logs
```

---

# Observability Service

---

## Responsibility

Collects:

```text id="svc068"
Metrics

Logs

Traces
```

---

## Stack

```text id="svc069"
Prometheus

Grafana

Loki

Tempo

OpenTelemetry
```

---

# Service Dependency Graph

```text id="svc070"
                API Gateway
                      |
      -----------------------------------
      |         |          |            |
      V         V          V            V

   Market   Trading   Portfolio      Research
      |         |          |            |
      |         |          |            |
      -----------------------------------
                      |
                      V

                    Risk
                      |
                      V

                 Analytics
                      |
                      V

                   Alerts
                      |
                      V

                      AI
```

---

# Service Ownership Rules

---

## Rule 1

```text id="svc071"
One Service

Owns

One Database
```

---

## Rule 2

```text id="svc072"
No Shared Tables
```

---

## Rule 3

```text id="svc073"
Communication

Occurs Via Events
```

---

## Rule 4

```text id="svc074"
Queries

May Cross Boundaries

Commands

May Not
```

---

# Service Scaling Characteristics

| Service   | Scaling            |
| --------- | ------------------ |
| Market    | Horizontal         |
| Trading   | Horizontal         |
| Portfolio | Horizontal         |
| Risk      | Massive Horizontal |
| Analytics | Horizontal         |
| Research  | Horizontal         |
| AI        | GPU Horizontal     |
| Alert     | Horizontal         |

---

# Service Failure Tolerance

| Service   | Can Fail? |
| --------- | --------- |
| Market    | No        |
| Trading   | No        |
| Portfolio | No        |
| Risk      | Yes       |
| Analytics | Yes       |
| Research  | Yes       |
| AI        | Yes       |
| Alert     | Yes       |

---

# Service Deployment Units

```text id="svc075"
market-service

trading-service

portfolio-service

risk-worker

analytics-worker

research-service

alert-service

ai-service
```

---

# Conway's Law Mapping

| Team       | Services     |
| ---------- | ------------ |
| Platform   | Gateway/Auth |
| Market     | Market       |
| Trading    | Trading      |
| Portfolio  | Portfolio    |
| Risk       | Risk         |
| Analytics  | Analytics    |
| Research   | Research     |
| AI         | AI           |
| Operations | Monitoring   |

---

# Final Service Principle

```text id="svc076"
Services are not technical layers.

Services are autonomous business capabilities.
```

And therefore:

```text id="svc077"
TickerHub is not:

Frontend
Backend
Database

architecture.

It is:

Markets
Trading
Portfolio
Risk
Research
Analytics
AI

architecture.
```
