# APPENDIX D — DATA MODEL REFERENCE

# TickerHub Canonical Data Model & Data Dictionary

> *"A distributed system is ultimately a distributed database with opinions."*

---

# Purpose

This document defines the canonical data model for TickerHub.

Its goals are to:

* establish the system of record
* define ownership of data
* document storage strategies
* define relationships
* define constraints
* define retention policies
* define physical persistence

---

# Data Architecture Overview

TickerHub uses **polyglot persistence**.

```text id="d1x001"
                    DATA SOURCES
                          |
                          V

                      EVENTS
                          |
                          V

                        KAFKA
                          |
      ------------------------------------------------
      |             |            |                  |
      V             V            V                  V

  PostgreSQL      Redis     EventStore        Data Lake
      |             |            |                  |
      ------------------------------------------------
                          |
                          V

                    Search Engine
                          |
                          V

                     Vector DB
                          |
                          V

                    Knowledge Graph
```

---

# Storage Responsibilities

| Storage       | Responsibility  |
| ------------- | --------------- |
| PostgreSQL    | OLTP            |
| Redis         | Cache           |
| Kafka         | Event transport |
| EventStore    | Event sourcing  |
| Elasticsearch | Search          |
| Neo4j         | Knowledge       |
| Qdrant        | Embeddings      |
| Data Lake     | Historical      |

---

# Database Naming Convention

---

## Tables

```text id="d1x002"
snake_case
plural
```

Examples:

```text id="d1x003"
users
orders
positions
trades
```

---

## Columns

```text id="d1x004"
snake_case
```

Examples:

```text id="d1x005"
created_at
portfolio_id
market_value
```

---

## Keys

```text id="d1x006"
entity_id
```

Examples:

```text id="d1x007"
user_id
trade_id
order_id
```

---

# Identity Domain

---

## users

### Purpose

System users.

---

### Schema

```sql id="d1x008"
users
(
    user_id UUID PRIMARY KEY,

    username VARCHAR(100)
        UNIQUE
        NOT NULL,

    email VARCHAR(255)
        UNIQUE
        NOT NULL,

    password_hash TEXT
        NOT NULL,

    status VARCHAR(50)
        NOT NULL,

    created_at TIMESTAMP
        NOT NULL,

    updated_at TIMESTAMP
        NOT NULL,

    last_login TIMESTAMP
)
```

---

### Indexes

```sql id="d1x009"
INDEX(username)
INDEX(email)
INDEX(status)
```

---

### Retention

```text id="d1x010"
Forever
```

---

## roles

```sql id="d1x011"
roles
(
    role_id UUID PRIMARY KEY,

    role_name VARCHAR(100)
)
```

---

## user_roles

```sql id="d1x012"
user_roles
(
    user_id UUID,
    role_id UUID
)
```

---

## sessions

```sql id="d1x013"
sessions
(
    session_id UUID PRIMARY KEY,

    user_id UUID,

    jwt_id UUID,

    created_at TIMESTAMP,

    expires_at TIMESTAMP,

    ip_address VARCHAR(50)
)
```

---

# Market Domain

---

## exchanges

```sql id="d1x014"
exchanges
(
    exchange_id UUID PRIMARY KEY,

    code VARCHAR(20),

    name VARCHAR(100),

    timezone VARCHAR(50),

    country VARCHAR(50)
)
```

---

## instruments

### Purpose

Canonical security master.

---

```sql id="d1x015"
instruments
(
    instrument_id UUID PRIMARY KEY,

    symbol VARCHAR(20),

    name VARCHAR(255),

    exchange_id UUID,

    currency VARCHAR(10),

    instrument_type VARCHAR(50),

    sector VARCHAR(100),

    industry VARCHAR(100),

    active BOOLEAN
)
```

---

### Constraints

```text id="d1x016"
(symbol, exchange_id)
must be unique
```

---

### Indexes

```sql id="d1x017"
INDEX(symbol)
INDEX(exchange_id)
INDEX(sector)
INDEX(industry)
```

---

## quotes

### Purpose

Current market snapshots.

---

```sql id="d1x018"
quotes
(
    quote_id UUID PRIMARY KEY,

    instrument_id UUID,

    bid NUMERIC,

    ask NUMERIC,

    last NUMERIC,

    volume BIGINT,

    timestamp TIMESTAMP
)
```

---

### Retention

```text id="d1x019"
Forever
```

---

## orderbooks

```sql id="d1x020"
orderbooks
(
    orderbook_id UUID,

    instrument_id UUID,

    side VARCHAR,

    level INTEGER,

    price NUMERIC,

    quantity BIGINT,

    timestamp TIMESTAMP
)
```

---

# Trading Domain

---

## orders

### Purpose

Trading instructions.

---

```sql id="d1x021"
orders
(
    order_id UUID PRIMARY KEY,

    portfolio_id UUID,

    instrument_id UUID,

    side VARCHAR,

    quantity NUMERIC,

    price NUMERIC,

    order_type VARCHAR,

    status VARCHAR,

    created_at TIMESTAMP,

    updated_at TIMESTAMP
)
```

---

### Constraints

```text id="d1x022"
quantity > 0

price >= 0
```

---

### Indexes

```sql id="d1x023"
INDEX(portfolio_id)
INDEX(status)
INDEX(created_at)
```

---

## executions

```sql id="d1x024"
executions
(
    execution_id UUID PRIMARY KEY,

    order_id UUID,

    venue VARCHAR,

    quantity NUMERIC,

    price NUMERIC,

    timestamp TIMESTAMP
)
```

---

## trades

```sql id="d1x025"
trades
(
    trade_id UUID PRIMARY KEY,

    execution_id UUID,

    portfolio_id UUID,

    instrument_id UUID,

    quantity NUMERIC,

    price NUMERIC,

    commission NUMERIC,

    timestamp TIMESTAMP
)
```

---

# Portfolio Domain

---

## portfolios

```sql id="d1x026"
portfolios
(
    portfolio_id UUID PRIMARY KEY,

    owner_id UUID,

    name VARCHAR,

    base_currency VARCHAR,

    created_at TIMESTAMP
)
```

---

## positions

### Purpose

Current holdings.

---

```sql id="d1x027"
positions
(
    position_id UUID PRIMARY KEY,

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

### Constraints

```text id="d1x028"
(portfolio_id,
 instrument_id)

must be unique
```

---

## cash_balances

```sql id="d1x029"
cash_balances
(
    balance_id UUID PRIMARY KEY,

    portfolio_id UUID,

    currency VARCHAR,

    amount NUMERIC,

    available NUMERIC,

    reserved NUMERIC
)
```

---

## exposures

```sql id="d1x030"
exposures
(
    exposure_id UUID PRIMARY KEY,

    portfolio_id UUID,

    factor VARCHAR,

    exposure NUMERIC
)
```

---

# Risk Domain

---

## risk_snapshots

```sql id="d1x031"
risk_snapshots
(
    snapshot_id UUID PRIMARY KEY,

    portfolio_id UUID,

    var NUMERIC,

    cvar NUMERIC,

    expected_shortfall NUMERIC,

    volatility NUMERIC,

    beta NUMERIC,

    timestamp TIMESTAMP
)
```

---

## stress_tests

```sql id="d1x032"
stress_tests
(
    stress_id UUID PRIMARY KEY,

    portfolio_id UUID,

    scenario VARCHAR,

    pnl NUMERIC,

    timestamp TIMESTAMP
)
```

---

## factor_exposures

```sql id="d1x033"
factor_exposures
(
    factor_id UUID PRIMARY KEY,

    portfolio_id UUID,

    factor_name VARCHAR,

    beta NUMERIC
)
```

---

# Analytics Domain

---

## pnl_snapshots

```sql id="d1x034"
pnl_snapshots
(
    snapshot_id UUID PRIMARY KEY,

    portfolio_id UUID,

    daily_pnl NUMERIC,

    monthly_pnl NUMERIC,

    yearly_pnl NUMERIC,

    timestamp TIMESTAMP
)
```

---

## performance_attribution

```sql id="d1x035"
performance_attribution
(
    attribution_id UUID PRIMARY KEY,

    portfolio_id UUID,

    category VARCHAR,

    contribution NUMERIC
)
```

---

## reports

```sql id="d1x036"
reports
(
    report_id UUID PRIMARY KEY,

    portfolio_id UUID,

    report_type VARCHAR,

    generated_at TIMESTAMP
)
```

---

# Alert Domain

---

## alerts

```sql id="d1x037"
alerts
(
    alert_id UUID PRIMARY KEY,

    user_id UUID,

    alert_type VARCHAR,

    condition JSONB,

    active BOOLEAN
)
```

---

## notifications

```sql id="d1x038"
notifications
(
    notification_id UUID PRIMARY KEY,

    alert_id UUID,

    channel VARCHAR,

    delivered BOOLEAN,

    delivered_at TIMESTAMP
)
```

---

# Workspace Domain

---

## workspaces

```sql id="d1x039"
workspaces
(
    workspace_id UUID PRIMARY KEY,

    owner_id UUID,

    name VARCHAR,

    layout JSONB,

    created_at TIMESTAMP
)
```

---

## widgets

```sql id="d1x040"
widgets
(
    widget_id UUID PRIMARY KEY,

    workspace_id UUID,

    widget_type VARCHAR,

    configuration JSONB
)
```

---

# Research Domain

---

## news

```sql id="d1x041"
news
(
    news_id UUID PRIMARY KEY,

    source VARCHAR,

    headline TEXT,

    body TEXT,

    published_at TIMESTAMP
)
```

---

## research_documents

```sql id="d1x042"
research_documents
(
    document_id UUID PRIMARY KEY,

    title VARCHAR,

    author VARCHAR,

    category VARCHAR,

    uploaded_at TIMESTAMP
)
```

---

## document_chunks

```sql id="d1x043"
document_chunks
(
    chunk_id UUID PRIMARY KEY,

    document_id UUID,

    chunk TEXT,

    embedding VECTOR
)
```

---

# AI Domain

---

## prompts

```sql id="d1x044"
prompts
(
    prompt_id UUID PRIMARY KEY,

    user_id UUID,

    prompt TEXT,

    created_at TIMESTAMP
)
```

---

## responses

```sql id="d1x045"
responses
(
    response_id UUID PRIMARY KEY,

    prompt_id UUID,

    response TEXT,

    confidence NUMERIC
)
```

---

## recommendations

```sql id="d1x046"
recommendations
(
    recommendation_id UUID PRIMARY KEY,

    user_id UUID,

    recommendation TEXT,

    explanation TEXT,

    confidence NUMERIC
)
```

---

# Event Store

---

## events

```sql id="d1x047"
events
(
    event_id UUID PRIMARY KEY,

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

## snapshots

```sql id="d1x048"
snapshots
(
    aggregate_id UUID,

    version INTEGER,

    snapshot JSONB,

    created_at TIMESTAMP
)
```

---

# Audit Domain

---

## audit_logs

```sql id="d1x049"
audit_logs
(
    audit_id UUID PRIMARY KEY,

    user_id UUID,

    action VARCHAR,

    object_type VARCHAR,

    object_id UUID,

    metadata JSONB,

    timestamp TIMESTAMP
)
```

---

# Knowledge Graph

---

## Nodes

```text id="d1x050"
Company
Person
Sector
Country
Exchange
Commodity
Event
Document
```

---

## Relationships

```text id="d1x051"
OWNS

COMPETES_WITH

INFLUENCES

SUPPLIES

BELONGS_TO

REPORTS
```

---

# Vector Database

---

## Collection: research_embeddings

```text id="d1x052"
embedding_id
document_id
vector
metadata
```

---

## Collection: market_embeddings

```text id="d1x053"
instrument_id
vector
metadata
```

---

## Collection: user_memory

```text id="d1x054"
memory_id
user_id
vector
metadata
```

---

# Redis Cache Model

---

## Market Cache

```text id="d1x055"
market:D05

market:U11

market:O39
```

---

## Portfolio Cache

```text id="d1x056"
portfolio:123
```

---

## Session Cache

```text id="d1x057"
session:abc
```

---

## OrderBook Cache

```text id="d1x058"
orderbook:D05
```

---

# Data Lake Layout

```text id="d1x059"
market/

    year/

        month/

            day/
```

---

```text id="d1x060"
trades/

orders/

risk/

analytics/

research/
```

---

# Data Ownership Matrix

| Data       | Owner     |
| ---------- | --------- |
| User       | Identity  |
| Instrument | Market    |
| Order      | Trading   |
| Trade      | Trading   |
| Portfolio  | Portfolio |
| Risk       | Risk      |
| Analytics  | Analytics |
| Workspace  | Workspace |
| Research   | Research  |
| AI         | AI        |
| Audit      | Security  |

---

# Data Retention Matrix

| Data     | Retention |
| -------- | --------- |
| Market   | Forever   |
| Orders   | Forever   |
| Trades   | Forever   |
| Events   | Forever   |
| Risk     | 10 Years  |
| Audit    | 7 Years   |
| Sessions | 90 Days   |
| Logs     | 1 Year    |
| AI       | 2 Years   |

---

# Data Relationships

```text id="d1x061"
User
 |
 +--- Portfolio
 |       |
 |       +--- Position
 |       |
 |       +--- Cash
 |
 +--- Workspace
 |
 +--- Alert

Order
 |
 +--- Execution
 |
 +--- Trade

Instrument
 |
 +--- Quote
 |
 +--- OrderBook
 |
 +--- Trade

Portfolio
 |
 +--- Risk
 |
 +--- Analytics
```

---

# Data Design Principles

TickerHub data design follows:

```text id="d1x062"
Event Sourcing

+

CQRS

+

DDD

+

Polyglot Persistence

+

Immutable Audit

+

Historical Preservation
```

---

# Final Principle

```text id="d1x063"
Services are temporary.

Databases evolve.

Events persist.

Data is forever.
```
