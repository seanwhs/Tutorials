# ARCHITECTURE.md

# TickerHub Architecture

## Enterprise Financial Intelligence & Trading Platform

> *"TickerHub is not a dashboard application. It is a distributed financial computing platform built around events, state machines, services, and institutional knowledge."*

---

# Table of Contents

```text
1. Vision
2. Architecture Principles
3. System Overview
4. High-Level Architecture
5. Architectural Layers
6. Domain Architecture
7. Event Architecture
8. Service Architecture
9. Data Architecture
10. UI Architecture
11. AI Architecture
12. Security Architecture
13. Observability Architecture
14. Deployment Architecture
15. Organizational Architecture
16. Repository Structure
17. Architectural Decisions
18. Evolution Strategy
```

---

# 1. Vision

TickerHub is an enterprise-grade financial terminal inspired by:

* Bloomberg Terminal
* Refinitiv Workspace
* FactSet
* CQG
* Interactive Brokers TWS

Unlike traditional dashboards, TickerHub is designed as a:

```text
Distributed Financial Intelligence Platform
```

that combines:

* Real-time market systems
* Trading workflows
* Portfolio analytics
* Risk management
* Event sourcing
* Financial knowledge graphs
* AI copilots
* Enterprise observability
* Platform engineering

---

# 2. Architecture Principles

TickerHub is built around several core architectural principles.

---

## Principle 1

### Everything Is An Event

```text
Market data
Portfolio changes
Trades
Orders
Risk calculations
User actions
AI interactions

are events.
```

---

## Principle 2

### State Is Derived

```text
state
    =
events
    +
projections
```

The system minimizes mutable state.

---

## Principle 3

### Asynchronous First

Because infrastructure is cloud-hosted:

* PostgreSQL
* Redis
* Kafka
* AI services

all interactions are asynchronous.

---

## Principle 4

### Services Own Business Logic

Business rules never live inside:

```text
Panel
FastAPI
Widgets
```

Business rules live inside:

```text
services/
```

---

## Principle 5

### UI Is A Projection Layer

The UI exists only to visualize system state.

```text
Events
    ↓

Services
    ↓

State
    ↓

UI
```

---

## Principle 6

### Platform Over Application

TickerHub is designed as:

```text
a platform
```

rather than:

```text
a monolithic application
```

---

# 3. System Overview

```text
                             USERS
                                |
                                V
                         Panel Terminal
                                |
                                V
                         API Gateway
                                |
                                V
                          Service Mesh
                                |
      --------------------------------------------------------
      |            |            |            |              |
      V            V            V            V              V

   Market      Portfolio      Risk       Trading         AI
   Service      Service      Service     Service      Service

      --------------------------------------------------------
                                |
                                V
                           Event Bus
                                |
      --------------------------------------------------------
      |            |            |            |              |
      V            V            V            V              V

     Kafka      Redis      PostgreSQL    EventStore     DataLake
                                |
                                V
                         Knowledge Graph
                                |
                                V
                            AI Layer
```

---

# 4. High-Level Architecture

TickerHub follows a layered architecture:

```text
Presentation Layer

        ↓

Application Layer

        ↓

Domain Layer

        ↓

Event Layer

        ↓

Infrastructure Layer

        ↓

Platform Layer
```

---

# 5. Architectural Layers

## Layer 1 — Presentation

Responsibilities:

* Dashboard rendering
* User interaction
* Visualization
* Session management

Technology:

* Panel
* Param
* Bokeh
* JavaScript

---

## Layer 2 — Application

Responsibilities:

* Workflow orchestration
* Service coordination
* API exposure

Technology:

* FastAPI
* AsyncIO

---

## Layer 3 — Domain

Responsibilities:

* Business entities
* Business rules
* Domain invariants

Examples:

```text
Portfolio
Position
Trade
Order
Risk
```

---

## Layer 4 — Events

Responsibilities:

* Event publishing
* Event persistence
* Event replay

Technology:

* Kafka
* EventStore

---

## Layer 5 — Infrastructure

Responsibilities:

* Database access
* Messaging
* Caching
* Storage

Technology:

* PostgreSQL
* Redis
* Kafka
* Object Storage

---

## Layer 6 — Platform

Responsibilities:

* Security
* Monitoring
* Deployment
* Operations
* Governance

Technology:

* Kubernetes
* Prometheus
* Grafana
* OpenTelemetry

---

# 6. Domain Architecture

## Core Domain Model

```text
User
   |
Portfolio
   |
Position
   |
Trade
   |
Order
```

---

## Portfolio Domain

```text
Portfolio
    |
    +---- Position
    |
    +---- Cash
    |
    +---- Exposure
    |
    +---- Risk
```

---

## Trading Domain

```text
Order
    |
    V

Execution
    |
    V

Trade
    |
    V

Position
```

---

## Risk Domain

```text
Portfolio
      |
      V

Exposure Engine
      |
      V

Risk Engine
      |
      V

Stress Engine
```

---

# 7. Event Architecture

TickerHub uses Event Driven Architecture (EDA).

---

## Event Flow

```text
Producer
    |
    V

Kafka
    |
    V

Consumers
```

---

## Event Categories

### Market Events

```text
PriceUpdated
OrderBookUpdated
TradePrinted
MarketOpened
MarketClosed
```

---

### Portfolio Events

```text
PortfolioCreated
PositionUpdated
PortfolioValued
```

---

### Trading Events

```text
OrderSubmitted
OrderAccepted
OrderFilled
OrderCancelled
TradeExecuted
```

---

### Risk Events

```text
VaRCalculated
CVaRCalculated
RiskLimitBreached
StressCompleted
```

---

### AI Events

```text
PromptSubmitted
ContextRetrieved
RecommendationGenerated
```

---

# 8. Service Architecture

TickerHub uses microservice-inspired service decomposition.

```text
                 Event Bus
                      |
      -----------------------------------
      |         |         |            |
      V         V         V            V

   Market   Portfolio   Risk      Trading
   Service   Service   Service    Service
```

---

## Market Service

Responsibilities:

* market feeds
* pricing
* order books
* historical data

---

## Portfolio Service

Responsibilities:

* positions
* valuations
* pnl
* exposures

---

## Risk Service

Responsibilities:

* VaR
* CVaR
* stress testing
* Monte Carlo

---

## Trading Service

Responsibilities:

* order lifecycle
* execution
* routing
* fills

---

## AI Service

Responsibilities:

* RAG
* retrieval
* copilots
* reasoning

---

# 9. Data Architecture

TickerHub uses polyglot persistence.

---

## PostgreSQL

Stores:

```text
Users
Portfolios
Trades
Orders
Configurations
```

---

## Redis

Stores:

```text
Sessions
Caches
Market snapshots
Temporary state
```

---

## Kafka

Stores:

```text
Event streams
```

---

## Event Store

Stores:

```text
Historical events
```

---

## Data Lake

Stores:

```text
Historical market data
AI training data
Analytics
```

---

## Vector Database

Stores:

```text
Embeddings
Financial documents
Research
```

---

## Knowledge Graph

Stores:

```text
Entities
Relationships
Market intelligence
```

---

# 10. UI Architecture

TickerHub follows reactive UI architecture.

```text
Services
     |
     V

State Layer
     |
     V

Param
     |
     V

Panel Components
```

---

## Component Model

```text
Watchlist

Chart

OrderBook

Portfolio

News

Analytics

Alerts
```

---

## Shared State

```text
MarketState

PortfolioState

RiskState

SessionState
```

---

## Layout

```text
FastListTemplate

     |
     +----- Sidebar
     |
     +----- Main
     |
     +----- Modal
```

---

# 11. AI Architecture

TickerHub AI uses RAG.

```text
Question
    |
Retriever
    |
Vector DB
    |
Context
    |
LLM
    |
Answer
```

---

## AI Components

```text
Portfolio Copilot
Risk Copilot
Market Copilot
Research Copilot
Compliance Copilot
```

---

## Knowledge Graph

```text
Markets
      |
      V

Companies
      |
      V

Sectors
      |
      V

Economies
```

---

# 12. Security Architecture

TickerHub follows Zero Trust principles.

---

## Authentication

```text
OAuth2
```

↓

```text
JWT
```

↓

```text
Session
```

---

## Authorization

Uses:

```text
RBAC
```

and:

```text
ABAC
```

---

## Encryption

### In Transit

```text
TLS 1.3
```

---

### At Rest

```text
AES256
```

---

## Audit

Every operation is logged.

---

# 13. Observability Architecture

TickerHub follows the three pillars of observability.

---

## Metrics

Technology:

```text
Prometheus
```

---

## Logging

Technology:

```text
Loki
```

---

## Tracing

Technology:

```text
OpenTelemetry
Jaeger
```

---

## Visualization

Technology:

```text
Grafana
```

---

# 14. Deployment Architecture

## Local Development

```text
Developer Laptop
        |
        |
        +----- Panel
        |
        +----- FastAPI
        |
        +----- Local Workers
                |
                |
                +----- Supabase
                |
                +----- Upstash Redis
                |
                +----- Cloud Kafka
```

---

## Production

```text
                          INTERNET
                               |
                          Cloudflare
                               |
                          Load Balancer
                               |
                             NGINX
                               |
                         API Gateway
                               |
                      Kubernetes Cluster
                               |
         ------------------------------------------------
         |              |             |                |
         V              V             V                V

      Panel        Services       Workers         AI Cluster

                               |
                               V

                    Kafka / Redis / PostgreSQL
```

---

# 15. Organizational Architecture

TickerHub follows Conway's Law.

---

## Teams

```text
Market Platform Team

Portfolio Team

Risk Team

AI Team

Data Team

Infrastructure Team

Security Team
```

---

## Platform Team

Provides:

```text
CI/CD

Monitoring

Infrastructure

Security

Deployment
```

---

# 16. Repository Structure

```text
tickerhub/

├── app/
├── api/
├── domain/
├── state/
├── services/
├── repositories/
├── events/
├── workers/
├── components/
│
├── ai/
├── analytics/
├── risk/
├── knowledge/
│
├── infrastructure/
├── deployment/
├── observability/
├── security/
│
├── tests/
├── docs/
├── runbooks/
├── adr/
└── scripts/
```

---

# 17. Architectural Decisions

| ADR     | Decision                  |
| ------- | ------------------------- |
| ADR-001 | Event Driven Architecture |
| ADR-002 | Event Sourcing            |
| ADR-003 | CQRS                      |
| ADR-004 | Polyglot Persistence      |
| ADR-005 | RAG Architecture          |
| ADR-006 | Knowledge Graph           |
| ADR-007 | Zero Trust Security       |
| ADR-008 | Platform Engineering      |
| ADR-009 | Hybrid Cloud Development  |
| ADR-010 | Kubernetes Deployment     |

---

# 18. Evolution Strategy

TickerHub evolves through phases.

---

## Phase 1

```text
Panel Dashboard
```

---

## Phase 2

```text
Distributed Application
```

---

## Phase 3

```text
Trading Platform
```

---

## Phase 4

```text
Financial Intelligence Platform
```

---

## Phase 5

```text
Institutional Platform
```

---

# Final Architecture Diagram

```text
                                USERS
                                   |
                                   V
                            Panel Terminal
                                   |
                                   V
                             API Gateway
                                   |
                                   V
                              Service Mesh
                                   |
      ----------------------------------------------------------------
      |              |              |              |                 |
      V              V              V              V                 V

   Market       Portfolio        Risk         Trading             AI
   Service       Service        Service       Service          Service

      ----------------------------------------------------------------
                                   |
                                   V
                              Event Bus
                                   |
      ----------------------------------------------------------------
      |            |             |             |                    |
      V            V             V             V                    V

     Kafka      Redis      PostgreSQL     EventStore         DataLake
                                   |
                                   V
                            Vector DB
                                   |
                                   V
                          Knowledge Graph
                                   |
                                   V
                             AI Platform
                                   |
                                   V
                            Observability
                                   |
                                   V
                               Security
                                   |
                                   V
                        Platform Engineering
                                   |
                                   V
                             Organization
```

---

# Final Principle

> **TickerHub is not built as a trading application.**
>
> TickerHub is built as:
>
> ```text
> A distributed financial intelligence platform
> that combines:
>
> Markets
> +
> Events
> +
> Trading
> +
> Risk
> +
> AI
> +
> Knowledge
> +
> Security
> +
> Observability
> +
> Platform Engineering
> +
> Organizational Design
>
> into a single
> institutional computing system.
> ```
