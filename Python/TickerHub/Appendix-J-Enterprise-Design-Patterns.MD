# APPENDIX J — ENTERPRISE DESIGN PATTERNS & ARCHITECTURAL DECISION RECORDS

# TickerHub Engineering Patterns Handbook

> *"Architecture is the accumulation of decisions that were expensive to reverse."*

---

# Purpose

This appendix documents:

* architectural patterns used by TickerHub
* enterprise design patterns
* distributed systems patterns
* event-driven patterns
* UI architecture patterns
* reliability patterns
* Architectural Decision Records (ADRs)

This document answers:

> **Why was TickerHub designed this way?**

---

# Architecture Philosophy

TickerHub follows:

```text id="pat001"
DDD

+

Event Sourcing

+

CQRS

+

Hexagonal Architecture

+

Reactive UI

+

Cloud Native
```

---

# Pattern Taxonomy

```text id="pat002"
Strategic Patterns

Tactical Patterns

Distributed Patterns

UI Patterns

Reliability Patterns

Operational Patterns
```

---

# Strategic Patterns

---

# Domain Driven Design (DDD)

---

## Problem

Large systems become tightly coupled.

---

## Solution

Split system into bounded contexts.

```text id="pat003"
Market

Trading

Portfolio

Risk

Research

Analytics

AI
```

---

## Benefits

```text id="pat004"
Isolation

Ownership

Scalability

Autonomy
```

---

# Bounded Context Pattern

---

```text id="pat005"
Trading

    |

Trade

Order

Execution
```

---

```text id="pat006"
Portfolio

    |

Position

Exposure

PnL
```

---

## Rule

```text id="pat007"
No shared business models.
```

---

# Tactical Patterns

---

# Repository Pattern

---

## Purpose

Hide persistence details.

---

```python
class PositionRepository:

    async def load(self):
        ...

    async def save(self):
        ...
```

---

## Benefits

```text id="pat008"
Testing

Abstraction

Portability
```

---

# Unit Of Work Pattern

---

## Problem

Multiple writes must succeed together.

---

```python
async with UnitOfWork():

    order_repo.save()

    trade_repo.save()

    portfolio_repo.save()
```

---

## Benefit

```text id="pat009"
Atomicity
```

---

# Specification Pattern

---

## Example

```python
spec = (
    PriceGreaterThan(100)
    &
    VolumeGreaterThan(100000)
)
```

---

## Benefit

```text id="pat010"
Composable business rules
```

---

# Factory Pattern

---

## Example

```python
service = ServiceFactory.create(
    "risk"
)
```

---

# Strategy Pattern

---

## Example

```python
calculator = MonteCarloVaR()
```

or

```python
calculator = HistoricalVaR()
```

---

# Builder Pattern

---

## Example

```python
report = (
    ReportBuilder()
      .title()
      .summary()
      .charts()
      .build()
)
```

---

# Event Patterns

---

# Event Sourcing

---

## Problem

Database snapshots lose history.

---

## Solution

```text id="pat011"
OrderCreated

OrderAccepted

TradeExecuted

PositionUpdated
```

---

## Benefits

```text id="pat012"
Audit

Replay

Debugging
```

---

# CQRS

---

## Write Side

```text id="pat013"
Commands

↓

Events
```

---

## Read Side

```text id="pat014"
Read Models

↓

Queries
```

---

## Benefits

```text id="pat015"
Performance

Scalability
```

---

# Event Bus Pattern

---

```text id="pat016"
Producer

↓

Kafka

↓

Consumers
```

---

# Event Choreography

---

Example:

```text id="pat017"
TradeExecuted

↓

PortfolioUpdated

↓

RiskCalculated

↓

PnLCalculated

↓

AlertTriggered
```

---

## Benefits

```text id="pat018"
Loose coupling
```

---

# Saga Pattern

---

## Problem

Distributed transactions fail.

---

## Example

```text id="pat019"
Create Order

↓

Reserve Capital

↓

Execute Trade

↓

Update Position

↓

Calculate Risk
```

---

## Compensation

```text id="pat020"
Undo Reservation
```

---

# Outbox Pattern

---

## Problem

Database and Kafka disagree.

---

## Solution

```text id="pat021"
Database Transaction

        |

Outbox Table

        |

Publisher
```

---

# Inbox Pattern

---

## Problem

Duplicate events.

---

## Solution

```text id="pat022"
Processed Events Table
```

---

# Distributed System Patterns

---

# Circuit Breaker

---

```text id="pat023"
Closed

↓

Open

↓

Half Open
```

---

## Example

```python
if failures > 5:
    circuit.open()
```

---

# Retry Pattern

---

```text id="pat024"
1 sec

2 sec

4 sec

8 sec
```

---

# Bulkhead Pattern

---

## Problem

One service kills all services.

---

## Solution

```text id="pat025"
Market Pool

Risk Pool

Analytics Pool
```

---

# Backpressure

---

## Example

```text id="pat026"
Producer

↓

Queue Full

↓

Slow Down
```

---

# Idempotency Pattern

---

## Example

```text id="pat027"
TradeExecuted

already processed

↓

Ignore
```

---

# UI Patterns

---

# MVVM

---

```text id="pat028"
Model

↓

ViewModel

↓

View
```

---

# Component Pattern

---

```text id="pat029"
Watchlist

Chart

Portfolio

News
```

---

# Reactive State Pattern

---

```text id="pat030"
MarketState

↓

param

↓

Panel
```

---

# Observer Pattern

---

```text id="pat031"
PriceUpdated

↓

Subscribers
```

---

# Publish Subscribe

---

```text id="pat032"
Publisher

↓

EventBus

↓

Subscriber
```

---

# Infrastructure Patterns

---

# Sidecar Pattern

---

```text id="pat033"
Application

+

Telemetry
```

---

# Ambassador Pattern

---

```text id="pat034"
Service

↓

Proxy
```

---

# Adapter Pattern

---

```python
class RedisAdapter:
    ...
```

---

# Anti-Corruption Layer

---

## Problem

External systems are ugly.

---

## Solution

```text id="pat035"
Bloomberg API

↓

Translator

↓

TickerHub
```

---

# Reliability Patterns

---

## Health Check

```text id="pat036"
Liveness

Readiness
```

---

## Graceful Shutdown

```text id="pat037"
SIGTERM

↓

Drain

↓

Stop
```

---

## Leader Election

```text id="pat038"
Worker

↓

Leader
```

---

## Failover

```text id="pat039"
Primary

↓

Replica
```

---

# Security Patterns

---

## Zero Trust

```text id="pat040"
Verify everything
```

---

## Defense In Depth

```text id="pat041"
WAF

↓

API

↓

Service

↓

Database
```

---

## Principle Of Least Privilege

```text id="pat042"
Minimum permissions
```

---

# AI Patterns

---

## RAG Pattern

```text id="pat043"
Question

↓

Search

↓

Context

↓

LLM
```

---

## Agent Pattern

```text id="pat044"
Goal

↓

Planner

↓

Tools

↓

Execution
```

---

## Human-In-The-Loop

```text id="pat045"
AI

↓

Approval

↓

Execution
```

---

# Architectural Decision Records

---

# ADR-001

## Why Kafka?

---

### Decision

```text id="pat046"
Kafka
```

---

### Reason

```text id="pat047"
Ordering

Durability

Replay

Scalability
```

---

# ADR-002

## Why Event Sourcing?

---

### Decision

```text id="pat048"
Store events forever
```

---

### Reason

```text id="pat049"
Audit

Replay

History
```

---

# ADR-003

## Why CQRS?

---

### Decision

```text id="pat050"
Separate reads and writes
```

---

### Reason

```text id="pat051"
Performance

Scalability
```

---

# ADR-004

## Why Panel?

---

### Decision

```text id="pat052"
Panel
```

---

### Reason

```text id="pat053"
Python-native

Reactive

Enterprise UI
```

---

# ADR-005

## Why Param?

---

### Decision

```text id="pat054"
param
```

---

### Reason

```text id="pat055"
Observable state
```

---

# ADR-006

## Why Hybrid Cloud?

---

### Decision

```text id="pat056"
Remote infrastructure
```

---

### Reason

```text id="pat057"
Cheap

Portable

Professional
```

---

# ADR-007

## Why Polyglot Persistence?

---

### Decision

```text id="pat058"
Many databases
```

---

### Reason

```text id="pat059"
Different problems require
different storage engines
```

---

# ADR-008

## Why Event-Driven Architecture?

---

### Decision

```text id="pat060"
Async communication
```

---

### Reason

```text id="pat061"
Loose coupling

Resilience

Scalability
```

---

# Architecture Principles

TickerHub follows:

```text id="pat062"
DDD

+

SOLID

+

CQRS

+

Event Sourcing

+

Cloud Native

+

Reactive Systems

+

Zero Trust
```

---

# Final Principle

```text id="pat063"
Design patterns are not
solutions.

They are names for
tradeoffs that engineers
have agreed to accept.
```

And therefore:

```text id="pat064"
Architecture is not about
choosing the best pattern.

Architecture is about
choosing which problems
you are willing to have.
```
