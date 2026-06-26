# APPENDIX R — THE TickerHub CAPSTONE

# Building the Minimum Viable Bloomberg Terminal

> *"The difference between learning and mastery is synthesis."*

---

# Purpose

Throughout TickerHub, each module focused on a single aspect of engineering:

* UI
* State
* Events
* Services
* Data
* Infrastructure
* Security
* Reliability
* AI
* Operations

The purpose of the Capstone is to answer the question:

> **Can you combine everything into a single coherent system?**

This appendix defines the **final engineering challenge**.

---

# Capstone Goal

Build a:

```text id="cap001"
Bloomberg-style

multi-user

real-time

AI-enabled

financial workstation
```

using:

```text id="cap002"
Panel

Param

FastAPI

Kafka

Redis

PostgreSQL

Docker

Kubernetes

RAG

Agents
```

---

# Target System

The final system should resemble:

```text id="cap003"
Bloomberg Terminal

+

Trading System

+

Research System

+

AI Assistant

+

Distributed Platform
```

---

# Architecture

```text id="cap004"
                     Internet
                         |
                  Authentication
                         |
                    API Gateway
                         |
        ---------------------------------
        |               |              |
        V               V              V

      Panel         REST API      WebSocket

        |               |              |

        --------------------------------

                         |

                    Event Bus
                         |

      -----------------------------------------
      |            |            |             |
      V            V            V             V

   Market       Portfolio     Risk       Research

      |            |            |             |

      -----------------------------------------
                         |
                  Infrastructure
                         |
       ---------------------------------------
       |               |                    |
       V               V                    V

     Redis          Kafka            PostgreSQL
```

---

# Minimum Features

---

# Feature 1

## Live Market Terminal

Must support:

```text id="cap005"
Live prices

Streaming quotes

Market depth

Trades

Watchlists
```

---

Example:

```text id="cap006"
DBS

SIA

UOB

OCBC
```

---

# Feature 2

## Portfolio Workstation

Must support:

```text id="cap007"
Positions

PnL

Exposure

Returns

Performance
```

---

Example:

```text id="cap008"
Portfolio Value

Daily PnL

Total Return

Sector Allocation
```

---

# Feature 3

## Risk Terminal

Must support:

```text id="cap009"
VaR

CVaR

Stress tests

Scenario analysis
```

---

Example:

```text id="cap010"
2008 crisis

COVID crash

Interest hike
```

---

# Feature 4

## Order Management

Must support:

```text id="cap011"
Create

Cancel

Modify

Execute
```

---

Order lifecycle:

```text id="cap012"
Created

↓

Accepted

↓

Executed

↓

Settled
```

---

# Feature 5

## Event Backbone

Must support:

```text id="cap013"
Kafka topics

Replay

Ordering

Partitioning
```

---

Required topics:

```text id="cap014"
prices

orders

trades

risk

portfolio

alerts

ai
```

---

# Feature 6

## AI Research Assistant

Example:

```text id="cap015"
Explain DBS earnings.
```

---

Pipeline:

```text id="cap016"
Question

↓

RAG

↓

Retrieval

↓

LLM

↓

Answer
```

---

Must support:

```text id="cap017"
Sources

Confidence

Citations
```

---

# Feature 7

## AI Operations Assistant

Example:

```text id="cap018"
Why is Kafka lagging?
```

---

Pipeline:

```text id="cap019"
Metrics

↓

Logs

↓

Analysis

↓

Explanation
```

---

# Feature 8

## Alert Engine

Examples:

```text id="cap020"
Price > threshold

Volume spike

Risk breach

News event
```

---

Architecture:

```text id="cap021"
Events

↓

Rules

↓

Actions
```

---

# Feature 9

## Observability

Must include:

```text id="cap022"
Metrics

Logs

Tracing

Dashboards
```

---

Metrics:

```text id="cap023"
Latency

Throughput

Errors

Users

Sessions
```

---

# Feature 10

## Authentication

Must support:

```text id="cap024"
OAuth2

JWT

RBAC
```

---

Roles:

```text id="cap025"
Trader

Risk

Research

Admin
```

---

# Feature 11

## Multi-User Sessions

Must support:

```text id="cap026"
Concurrent users

Shared state

User isolation
```

---

# Feature 12

## Persistence

Must support:

```text id="cap027"
Recovery

Replay

Audit
```

---

Example:

```text id="cap028"
Crash

↓

Replay

↓

Restore
```

---

# Required Infrastructure

---

## PostgreSQL

Stores:

```text id="cap029"
Users

Trades

Portfolios

Orders

Audit
```

---

## Redis

Stores:

```text id="cap030"
Sessions

Cache

Realtime state
```

---

## Kafka

Stores:

```text id="cap031"
Events
```

---

# Required UI Components

---

## Watchlist

```text id="cap032"
Live prices
```

---

## Chart

```text id="cap033"
Time series
```

---

## Order Book

```text id="cap034"
Depth
```

---

## Portfolio

```text id="cap035"
Positions
```

---

## Risk Dashboard

```text id="cap036"
Risk analytics
```

---

## News Panel

```text id="cap037"
Research
```

---

## AI Chat

```text id="cap038"
Assistant
```

---

# Required Background Workers

---

## Feed Worker

```text id="cap039"
Market ingestion
```

---

## Risk Worker

```text id="cap040"
Analytics
```

---

## Alert Worker

```text id="cap041"
Rules
```

---

## AI Worker

```text id="cap042"
Inference
```

---

# Required Reliability Features

Must support:

```text id="cap043"
Retries

Timeouts

Circuit breakers

Replay

Backpressure
```

---

# Required Security Features

Must support:

```text id="cap044"
Authentication

Authorization

Encryption

Secrets

Audit
```

---

# Required AI Features

Must support:

```text id="cap045"
RAG

Embeddings

Tools

Guardrails

Human approval
```

---

# Required Deployment

Deploy:

```text id="cap046"
Docker
```

Then:

```text id="cap047"
Kubernetes
```

Then:

```text id="cap048"
Cloud
```

---

# Required Documentation

Produce:

```text id="cap049"
README

SRD

Architecture

Threat Model

ADR

Data Model

Runbooks
```

---

# Required Testing

Implement:

```text id="cap050"
Unit tests

Integration tests

Load tests

Chaos tests
```

---

# Stretch Goals

---

## Level 1

Build:

```text id="cap051"
Exchange simulator
```

---

## Level 2

Build:

```text id="cap052"
Smart order router
```

---

## Level 3

Build:

```text id="cap053"
Portfolio optimizer
```

---

## Level 4

Build:

```text id="cap054"
Multi-agent AI
```

---

## Level 5

Build:

```text id="cap055"
Enterprise knowledge graph
```

---

# Grading Rubric

| Area          | Weight |
| ------------- | ------ |
| Architecture  | 25%    |
| Reliability   | 20%    |
| Security      | 15%    |
| Performance   | 15%    |
| AI            | 10%    |
| UI            | 10%    |
| Documentation | 5%     |

---

# Failure Conditions

Automatic failure if:

```text id="cap056"
No authentication

No audit

No recovery

No observability

No testing
```

Because:

```text id="cap057"
A demo is not a system.
```

---

# Success Criteria

Success means:

```text id="cap058"
The system survives:

Failures

Users

Latency

Bad data

Bad networks

Bad AI

Bad humans
```

---

# The Real Capstone

The visible capstone is:

```text id="cap059"
TickerHub
```

The invisible capstone is:

```text id="cap060"
Learning how to reason
about complex systems.
```

---

# Final Principle

If you complete this capstone, you will discover:

```text id="cap061"
Building software
is not difficult.
```

What is difficult is:

```text id="cap062"
Building systems
that continue working
after everything
starts going wrong.
```

And that is what professional engineering has always been.
