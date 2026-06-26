# APPENDIX F — INFRASTRUCTURE & DEPLOYMENT REFERENCE

# TickerHub Infrastructure Architecture

> *"Modern software architecture is largely the art of placing failures in different machines."*

---

# Purpose

This appendix defines the complete infrastructure architecture for TickerHub.

The goals are to:

* document deployment topology
* define infrastructure ownership
* establish network boundaries
* document cloud resources
* define scaling strategies
* define disaster recovery
* define production deployment

---

# Infrastructure Evolution

TickerHub evolves through four stages.

```text id="inf001"
Stage 1
Developer Laptop

        ↓

Stage 2
Hybrid Cloud

        ↓

Stage 3
Containerized

        ↓

Stage 4
Distributed Production
```

---

# Stage 1 — Developer Laptop

---

## Goal

Build business logic quickly.

---

## Architecture

```text id="inf002"
Developer Laptop

        |
        +---- Python
        |
        +---- Panel
        |
        +---- FastAPI
        |
        +---- VSCode
```

---

## Characteristics

```text id="inf003"
Fast
Simple
Cheap
Non-scalable
```

---

# Stage 2 — Hybrid Cloud Development

---

## Goal

Offload infrastructure while retaining local development speed.

---

## Architecture

```text id="inf004"
             Developer Laptop

                    |

    ------------------------------------

    |             |                |

    V             V                V

Supabase      Upstash        Upstash Kafka

Postgres       Redis            Kafka
```

---

## Services

| Service        | Provider          |
| -------------- | ----------------- |
| PostgreSQL     | Supabase          |
| Redis          | Upstash           |
| Kafka          | Upstash/CloudAMQP |
| Object Storage | Cloudflare R2     |
| Auth           | Supabase          |

---

## Advantages

```text id="inf005"
Low memory

Low cost

Production parity

Fast laptop
```

---

## Disadvantages

```text id="inf006"
Network latency

Internet dependency
```

---

# Stage 3 — Docker Environment

---

## Goal

Standardize execution.

---

## Architecture

```text id="inf007"
docker-compose

       |

----------------------------

Panel

FastAPI

Redis

Kafka

Postgres

Workers
```

---

## Container Layout

```text id="inf008"
tickerhub/

    panel

    api

    market

    portfolio

    risk

    analytics

    alerts

    ai
```

---

## Docker Network

```text id="inf009"
tickerhub-network
```

---

## Volumes

```text id="inf010"
postgres-data

kafka-data

grafana-data

prometheus-data
```

---

# Stage 4 — Production Architecture

---

# Global Topology

```text id="inf011"
                         INTERNET
                              |
                        Cloudflare
                              |
                       Load Balancer
                              |
                         API Gateway
                              |
             --------------------------------
             |              |               |
             V              V               V

        Panel Pods     FastAPI Pods    WebSocket

             |
             |
             V

           Kafka
             |
             |
             V

     ---------------------
     |         |         |
     V         V         V

 Portfolio   Risk   Analytics

 Workers    Workers   Workers

     |
     |
     V

 PostgreSQL
     |
     |
     V

 Redis
```

---

# Frontend Layer

---

## Components

```text id="inf012"
Cloudflare

NGINX

Panel Cluster
```

---

## Responsibilities

```text id="inf013"
TLS

CDN

Load balancing

Compression

Caching
```

---

# API Layer

---

## Components

```text id="inf014"
FastAPI

OAuth2

JWT

Rate Limiter
```

---

## Responsibilities

```text id="inf015"
Authentication

Authorization

API aggregation

Validation
```

---

# Event Backbone

---

## Kafka Cluster

```text id="inf016"
Broker 1

Broker 2

Broker 3
```

---

## Topics

```text id="inf017"
market-events

trading-events

portfolio-events

risk-events

analytics-events

alerts-events

research-events

ai-events
```

---

## Partitioning Strategy

```text id="inf018"
partition_key

=

aggregate_id
```

---

## Replication Factor

```text id="inf019"
3
```

---

# PostgreSQL Cluster

---

## Architecture

```text id="inf020"
Primary

   |

Read Replica

   |

Read Replica
```

---

## Responsibilities

```text id="inf021"
Transactions

OLTP

Audit

Snapshots
```

---

## Backup Strategy

```text id="inf022"
Continuous WAL

+

Daily Snapshot
```

---

# Redis Cluster

---

## Responsibilities

```text id="inf023"
Cache

Session

Pub/Sub

Rate limit
```

---

## Topology

```text id="inf024"
Redis Cluster

    |

Shard 1

Shard 2

Shard 3
```

---

# Search Infrastructure

---

## Elasticsearch

### Responsibilities

```text id="inf025"
News search

Research search

Trade search

Audit search
```

---

## Cluster

```text id="inf026"
Master

Data Node

Data Node
```

---

# Vector Database

---

## Qdrant

### Responsibilities

```text id="inf027"
Embeddings

RAG

Semantic search
```

---

# Knowledge Graph

---

## Neo4j

### Responsibilities

```text id="inf028"
Relationships

Research

Discovery

AI context
```

---

# Object Storage

---

## Cloudflare R2

Stores:

```text id="inf029"
Reports

Research

Exports

Snapshots

Backups
```

---

# Worker Architecture

---

## Risk Workers

```text id="inf030"
Risk Queue

      |

Risk Worker Pool

      |

Result Queue
```

---

## Analytics Workers

```text id="inf031"
Analytics Queue

       |

Worker Pool
```

---

## AI Workers

```text id="inf032"
Prompt Queue

      |

GPU Workers
```

---

# Observability Stack

---

## Metrics

```text id="inf033"
Prometheus
```

---

## Dashboards

```text id="inf034"
Grafana
```

---

## Logging

```text id="inf035"
Loki
```

---

## Tracing

```text id="inf036"
Tempo
```

---

## Instrumentation

```text id="inf037"
OpenTelemetry
```

---

# Monitoring Architecture

```text id="inf038"
Services

    |

OpenTelemetry

    |

-------------------

|       |         |

V       V         V

Metrics Logs   Traces

 |       |        |

 V       V        V

Prom    Loki    Tempo

      |
      V

   Grafana
```

---

# Security Architecture

---

## Edge

```text id="inf039"
Cloudflare WAF

DDoS

TLS
```

---

## Application

```text id="inf040"
OAuth2

JWT

RBAC

ABAC
```

---

## Service Mesh

```text id="inf041"
mTLS
```

---

## Secrets

```text id="inf042"
Vault

Kubernetes Secrets
```

---

# Kubernetes Architecture

---

## Namespaces

```text id="inf043"
frontend

backend

data

monitoring

security
```

---

## Deployments

```text id="inf044"
panel-deployment

market-deployment

portfolio-deployment

risk-deployment

analytics-deployment

alert-deployment

ai-deployment
```

---

## Services

```text id="inf045"
ClusterIP

LoadBalancer

Ingress
```

---

## Ingress

```text id="inf046"
NGINX Ingress

Traefik
```

---

# Horizontal Scaling

---

## Panel

```text id="inf047"
Users

↓

More Pods
```

---

## Kafka

```text id="inf048"
Events

↓

More Partitions
```

---

## Workers

```text id="inf049"
Jobs

↓

More Workers
```

---

## PostgreSQL

```text id="inf050"
Reads

↓

More Replicas
```

---

# Disaster Recovery

---

## Recovery Objectives

| Metric | Target       |
| ------ | ------------ |
| RPO    | < 1 minute   |
| RTO    | < 15 minutes |

---

## Backup Strategy

```text id="inf051"
Postgres

    |

Continuous WAL

    |

Daily Backup

    |

Object Storage
```

---

## Kafka Recovery

```text id="inf052"
Replication

+

Event Replay
```

---

## Redis Recovery

```text id="inf053"
Snapshot

+

AOF
```

---

# Deployment Pipeline

---

```text id="inf054"
Developer

    |

Git Push

    |

GitHub Actions

    |

Tests

    |

Docker Build

    |

Security Scan

    |

Push Registry

    |

Deploy Kubernetes
```

---

# Environments

| Environment | Purpose     |
| ----------- | ----------- |
| Local       | Development |
| Dev         | Integration |
| Staging     | UAT         |
| Production  | Live        |

---

# Resource Estimates

| Component | CPU | RAM  |
| --------- | --- | ---- |
| Panel     | 2   | 4GB  |
| API       | 2   | 2GB  |
| Market    | 4   | 8GB  |
| Portfolio | 2   | 4GB  |
| Risk      | 16  | 32GB |
| Analytics | 8   | 16GB |
| AI        | GPU | 32GB |

---

# Hugging Face Deployment

---

## Frontend

```text id="inf055"
HuggingFace Space

      |

Panel App
```

---

## External Services

```text id="inf056"
Supabase

Upstash Redis

Upstash Kafka

Cloudflare R2
```

---

## Secrets

```text id="inf057"
HF Secrets

↓

Environment Variables
```

---

# Infrastructure Evolution Roadmap

```text id="inf058"
Laptop

    ↓

Hybrid Cloud

    ↓

Docker

    ↓

Single Cluster

    ↓

Multi Cluster

    ↓

Multi Region

    ↓

Global Platform
```

---

# Infrastructure Principles

TickerHub infrastructure follows:

```text id="inf059"
Cloud Native

+

Event Driven

+

Immutable

+

Observable

+

Secure

+

Scalable

+

Resilient
```

---

# Final Principle

```text id="inf060"
Infrastructure is not where software runs.

Infrastructure is where software fails.

Architecture is the art of surviving those failures.
```
