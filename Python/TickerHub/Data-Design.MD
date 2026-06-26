# TickerHub Data Design & Data Model

## Enterprise Financial Intelligence Platform

> *"Data is the only permanent asset in a financial system. Everything else—services, APIs, user interfaces, and AI models—is merely a projection of the data."*

---

# Table of Contents

```text
1. Data Philosophy
2. Data Architecture Overview
3. Data Classification
4. Canonical Domain Model
5. Transactional Data Model
6. Event Data Model
7. Market Data Model
8. Portfolio Data Model
9. Trading Data Model
10. Risk Data Model
11. User & Security Data Model
12. Analytics Data Model
13. AI Data Model
14. Knowledge Graph Model
15. Vector Database Model
16. Event Store Model
17. Cache Model
18. Data Lake Model
19. CQRS Read Models
20. Data Governance
21. Data Retention
22. Data Lineage
23. Physical Storage Strategy
```

---

# 1. Data Philosophy

TickerHub adopts several fundamental principles:

## Principle 1

```text
Everything Important
Must Be Persisted
```

---

## Principle 2

```text
Events Are Truth
```

---

## Principle 3

```text
State Is Projection
```

---

## Principle 4

```text
Historical Data
Cannot Be Lost
```

---

## Principle 5

```text
Multiple Storage Engines
Exist For Different Purposes
```

---

# 2. Data Architecture Overview

```text
                        MARKET FEEDS
                               |
                               V

                         EVENT STREAMS
                               |
                               V

                           KAFKA
                               |
       ------------------------------------------------
       |              |              |                |
       V              V              V                V

   EVENT STORE    POSTGRESQL      REDIS         DATA LAKE
       |              |              |                |
       ------------------------------------------------
                               |
                               V

                       VECTOR DATABASE
                               |
                               V

                      KNOWLEDGE GRAPH
                               |
                               V

                           AI SYSTEM
```

---

# 3. Data Classification

TickerHub data is divided into seven categories.

| Category      | Storage          |
| ------------- | ---------------- |
| Transactional | PostgreSQL       |
| Event         | Kafka/EventStore |
| Cache         | Redis            |
| Historical    | Data Lake        |
| Analytical    | Data Warehouse   |
| Knowledge     | Graph DB         |
| Semantic      | Vector DB        |

---

# 4. Canonical Domain Model

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
   |
Execution
```

---

Additional domains:

```text
Market
   |
Instrument
   |
Quote
   |
OrderBook
   |
MarketEvent
```

---

```text
Portfolio
   |
Exposure
   |
Risk
   |
Scenario
```

---

```text
Research
   |
Document
   |
Embedding
   |
KnowledgeNode
```

---

# 5. Transactional Data Model

## USERS

```sql
users
(
    user_id UUID PK,
    username VARCHAR,
    email VARCHAR,
    password_hash TEXT,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    active BOOLEAN
)
```

---

## ROLES

```sql
roles
(
    role_id UUID PK,
    role_name VARCHAR
)
```

---

## USER_ROLES

```sql
user_roles
(
    user_id UUID FK,
    role_id UUID FK
)
```

---

# 6. Event Data Model

All business activity is persisted as immutable events.

## EVENTS

```sql
events
(
    event_id UUID PK,
    aggregate_id UUID,
    aggregate_type VARCHAR,
    event_type VARCHAR,
    event_version INTEGER,
    payload JSONB,
    metadata JSONB,
    timestamp TIMESTAMP
)
```

---

## EVENT STREAMS

```sql
event_streams
(
    stream_id UUID,
    aggregate_id UUID,
    sequence INTEGER,
    event_id UUID
)
```

---

## EVENT SNAPSHOTS

```sql
snapshots
(
    aggregate_id UUID,
    version INTEGER,
    snapshot JSONB,
    created_at TIMESTAMP
)
```

---

# 7. Market Data Model

## EXCHANGES

```sql
exchanges
(
    exchange_id UUID,
    code VARCHAR,
    name VARCHAR,
    timezone VARCHAR
)
```

---

## INSTRUMENTS

```sql
instruments
(
    instrument_id UUID,
    symbol VARCHAR,
    exchange_id UUID,
    instrument_type VARCHAR,
    currency VARCHAR,
    sector VARCHAR,
    industry VARCHAR
)
```

---

## QUOTES

```sql
quotes
(
    quote_id UUID,
    instrument_id UUID,
    bid NUMERIC,
    ask NUMERIC,
    last NUMERIC,
    volume BIGINT,
    timestamp TIMESTAMP
)
```

---

## TRADES

```sql
market_trades
(
    trade_id UUID,
    instrument_id UUID,
    price NUMERIC,
    quantity BIGINT,
    timestamp TIMESTAMP
)
```

---

## ORDER BOOKS

```sql
orderbooks
(
    orderbook_id UUID,
    instrument_id UUID,
    side VARCHAR,
    price NUMERIC,
    quantity BIGINT,
    level INTEGER,
    timestamp TIMESTAMP
)
```

---

# 8. Portfolio Data Model

## PORTFOLIOS

```sql
portfolios
(
    portfolio_id UUID,
    owner_id UUID,
    name VARCHAR,
    base_currency VARCHAR,
    created_at TIMESTAMP
)
```

---

## POSITIONS

```sql
positions
(
    position_id UUID,
    portfolio_id UUID,
    instrument_id UUID,
    quantity NUMERIC,
    average_price NUMERIC,
    market_price NUMERIC,
    market_value NUMERIC,
    unrealized_pnl NUMERIC,
    realized_pnl NUMERIC
)
```

---

## CASH BALANCES

```sql
cash_balances
(
    balance_id UUID,
    portfolio_id UUID,
    currency VARCHAR,
    amount NUMERIC
)
```

---

# 9. Trading Data Model

## ORDERS

```sql
orders
(
    order_id UUID,
    portfolio_id UUID,
    instrument_id UUID,
    side VARCHAR,
    quantity NUMERIC,
    price NUMERIC,
    order_type VARCHAR,
    status VARCHAR,
    created_at TIMESTAMP
)
```

---

## EXECUTIONS

```sql
executions
(
    execution_id UUID,
    order_id UUID,
    quantity NUMERIC,
    price NUMERIC,
    venue VARCHAR,
    timestamp TIMESTAMP
)
```

---

## TRADES

```sql
trades
(
    trade_id UUID,
    execution_id UUID,
    portfolio_id UUID,
    quantity NUMERIC,
    price NUMERIC,
    commission NUMERIC
)
```

---

# 10. Risk Data Model

## RISK SNAPSHOTS

```sql
risk_snapshots
(
    snapshot_id UUID,
    portfolio_id UUID,
    var NUMERIC,
    cvar NUMERIC,
    expected_shortfall NUMERIC,
    timestamp TIMESTAMP
)
```

---

## EXPOSURES

```sql
exposures
(
    exposure_id UUID,
    portfolio_id UUID,
    factor VARCHAR,
    exposure NUMERIC
)
```

---

## STRESS TESTS

```sql
stress_tests
(
    stress_id UUID,
    portfolio_id UUID,
    scenario_name VARCHAR,
    pnl NUMERIC,
    timestamp TIMESTAMP
)
```

---

# 11. User & Security Model

## SESSIONS

```sql
sessions
(
    session_id UUID,
    user_id UUID,
    jwt_id UUID,
    login_at TIMESTAMP,
    expires_at TIMESTAMP
)
```

---

## AUDIT LOGS

```sql
audit_logs
(
    audit_id UUID,
    user_id UUID,
    action VARCHAR,
    object_type VARCHAR,
    object_id UUID,
    metadata JSONB,
    timestamp TIMESTAMP
)
```

---

## PERMISSIONS

```sql
permissions
(
    permission_id UUID,
    permission_name VARCHAR
)
```

---

# 12. Analytics Data Model

## PNL SNAPSHOTS

```sql
pnl_snapshots
(
    snapshot_id UUID,
    portfolio_id UUID,
    daily_pnl NUMERIC,
    monthly_pnl NUMERIC,
    yearly_pnl NUMERIC,
    timestamp TIMESTAMP
)
```

---

## FACTORS

```sql
factor_exposures
(
    factor_id UUID,
    portfolio_id UUID,
    factor_name VARCHAR,
    beta NUMERIC
)
```

---

## ATTRIBUTION

```sql
performance_attribution
(
    attribution_id UUID,
    portfolio_id UUID,
    contribution NUMERIC,
    category VARCHAR
)
```

---

# 13. AI Data Model

## PROMPTS

```sql
prompts
(
    prompt_id UUID,
    user_id UUID,
    prompt TEXT,
    timestamp TIMESTAMP
)
```

---

## RESPONSES

```sql
responses
(
    response_id UUID,
    prompt_id UUID,
    response TEXT,
    confidence NUMERIC
)
```

---

## RECOMMENDATIONS

```sql
recommendations
(
    recommendation_id UUID,
    user_id UUID,
    recommendation TEXT,
    explanation TEXT,
    confidence NUMERIC
)
```

---

# 14. Knowledge Graph Model

Entities:

```text
Company
Person
Exchange
Country
Sector
Industry
Currency
Commodity
Event
Document
```

---

Relationships:

```text
OWNS

TRADES

BELONGS_TO

INFLUENCES

REPORTS

AFFECTS

COMPETES_WITH

SUPPLIES
```

---

Example:

```text
DBS
   |
BELONGS_TO
   |
Banking

DBS
   |
OPERATES_IN
   |
Singapore

MAS
   |
INFLUENCES
   |
DBS
```

---

# 15. Vector Database Model

## DOCUMENT EMBEDDINGS

```text
document_id
document_type
embedding
metadata
created_at
```

---

## MARKET EMBEDDINGS

```text
symbol
embedding
market_context
```

---

## RESEARCH EMBEDDINGS

```text
research_id
embedding
author
publication_date
```

---

# 16. Event Store Model

```text
Stream
     |
     +----- Event
     |
     +----- Event
     |
     +----- Event
```

---

Example:

```text
PortfolioStream
        |
        +--- PortfolioCreated
        +--- PositionAdded
        +--- PositionUpdated
        +--- PositionClosed
```

---

# 17. Cache Model

Redis stores ephemeral data.

## Market Cache

```text
market:D05
market:U11
market:O39
```

---

## Order Book Cache

```text
orderbook:D05
orderbook:U11
```

---

## Session Cache

```text
session:user123
```

---

## Portfolio Cache

```text
portfolio:user123
```

---

# 18. Data Lake Model

Store:

```text
market/

    year/

        month/

            day/
```

---

Store:

```text
orders/

trades/

portfolios/

risk/

analytics/

research/
```

---

Format:

```text
Parquet
Delta Lake
Iceberg
```

---

# 19. CQRS Read Models

## Portfolio View

```sql
portfolio_view
(
    portfolio_id,
    value,
    pnl,
    exposure
)
```

---

## Trading View

```sql
trading_view
(
    order_id,
    status,
    execution_status
)
```

---

## Risk View

```sql
risk_view
(
    portfolio_id,
    var,
    cvar
)
```

---

## Dashboard View

```sql
dashboard_view
(
    market_summary,
    portfolio_summary,
    alerts
)
```

---

# 20. Data Governance

Every data asset shall include:

```text
Owner
Steward
Classification
Retention
Lineage
Sensitivity
```

---

Classification:

| Level        | Description        |
| ------------ | ------------------ |
| Public       | Public market data |
| Internal     | Internal analytics |
| Confidential | Portfolio data     |
| Restricted   | Authentication     |
| Regulated    | Compliance data    |

---

# 21. Data Retention

| Data         | Retention |
| ------------ | --------- |
| Market ticks | Forever   |
| Orders       | Forever   |
| Trades       | Forever   |
| Events       | Forever   |
| Risk         | 10 years  |
| Logs         | 1 year    |
| Sessions     | 90 days   |
| AI prompts   | 2 years   |

---

# 22. Data Lineage

```text
Market Feed
      |
      V
Kafka
      |
      V
Market Service
      |
      V
PostgreSQL
      |
      V
Analytics
      |
      V
AI
```

---

# 23. Physical Storage Strategy

| Data Type      | Storage         |
| -------------- | --------------- |
| OLTP           | PostgreSQL      |
| Cache          | Redis           |
| Streaming      | Kafka           |
| Event Sourcing | EventStore      |
| Historical     | Data Lake       |
| Search         | Elasticsearch   |
| Knowledge      | Neo4j           |
| Embeddings     | pgvector/Qdrant |
| Metrics        | Prometheus      |
| Logs           | Loki            |
| Traces         | Tempo           |

---

# Final Data Principle

TickerHub treats data as:

```text
The Permanent System Of Record
```

while:

```text
Services
Applications
Dashboards
AI Models
Workers
APIs
```

are merely:

```text
Temporary Interpretations
of the underlying data.
```
