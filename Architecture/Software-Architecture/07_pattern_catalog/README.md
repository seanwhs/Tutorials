# Integrated Pattern Catalog — 2026 Edition

This catalog serves as a **quick-lookup index** for the architectural building blocks used throughout this field guide. It bridges **infrastructure patterns (Parts II–IV)** with **intelligent orchestration (Part VI)**.

---

## 🔹 Core Patterns

| Pattern | Primary Purpose | Typical Use Case |
| --- | --- | --- |
| **Sidecar** | Offload cross-cutting concerns | Service Mesh (Istio), logging, security, observability. |
| **BFF (Backend for Frontend)** | Client-specific data shaping | Optimizing payloads for Web, Mobile, or Edge-native AI clients. |
| **Strangler Fig** | Legacy modernization | Gradually replacing a monolith with microservices by intercepting calls. |
| **Saga** | Distributed consistency | Multi-service workflows: Order → Payment → Inventory. |
| **Event Sourcing** | High-fidelity audit trail | Banking, healthcare, or training AI on historical user behavior. |
| **CQRS** | Read/write segregation | Systems where read models (search/analytics) differ from write models. |
| **Outbox** | Guaranteed message delivery | Ensure events are published only if DB transactions succeed. |
| **Circuit Breaker** | Fault tolerance | Prevent cascading failures when a downstream service or LLM is unavailable. |
| **Agentic Loop / RAG** | AI-driven orchestration | Dynamically select tools/services with context-grounded reasoning. |

---

## 🛠 Strategic Visualization

### 1️⃣ Connectivity Pattern: Sidecar

* Abstracts away **mTLS**, observability, and telemetry.
* Foundation for **Service Mesh**, **Zero-Trust**, and **AI Sidecars** at the edge.

### 2️⃣ Transactional Pattern: Saga

* Supports **BASE semantics** (Basically Available, Soft state, Eventual consistency).
* Ensures consistency in **long-running, multi-team processes** despite partial failures.

### 3️⃣ Intelligence Pattern: Agentic RAG

* Extends the Sidecar concept to include **local AI inference** and **context retrieval**.
* Enables autonomous services to **act, observe, and iterate** without human intervention.

---

## 📂 Implementation Roadmap

| Part | Patterns Demonstrated | Notes |
| --- | --- | --- |
| **III — Foundations** | Sidecar, Circuit Breaker | Service Mesh, observability, fail-safes |
| **IV — API Design** | BFF, Strangler Fig | Optimized Edge and Mobile APIs |
| **V — Data Systems** | Saga, Event Sourcing, CQRS, Outbox | Immutable history, reliable async workflows |
| **VI — AI-Native** | Agentic Loops, RAG, AI Sidecar | Autonomous orchestration with real-time context |

---

## 🔄 Pattern-to-Code Mapping

| Pattern | Primary Directory / Files |
| --- | --- |
| **Sidecar** | `/part_iii/sidecar/` |
| **BFF** | `/part_iv/bff/` |
| **Strangler Fig** | `/part_iv/strangler/` |
| **Saga** | `/part_v/sagas/` |
| **Event Sourcing** | `/part_v/event_store/` |
| **CQRS** | `/part_v/projections/` |
| **Outbox** | `/part_v/outbox/` |
| **Circuit Breaker** | `/part_iii/circuit_breaker/` |
| **Agentic RAG** | `/part_vi/rag-implementation/` |
| **AI Sidecar** | `/part_vi/wasm-edge-functions/` |

---

## 🏗 Integrated Architecture Overview

```text
                                ┌─────────────────────────┐
                                │       User / Client     │
                                │ Browser / Mobile / IoT │
                                └─────────────┬──────────┘
                                              │ API Request
                                              ▼
            ┌───────────────────────────────────────────────────────┐
            │ Part IV — BFF & Strangler Fig                         │
            │ ┌───────────┐   ┌───────────────────────┐             │
            │ │   BFF     │──▶│ Strangler Proxy /     │             │
            │ │ Service   │   │ Legacy Adapter        │             │
            │ └───────────┘   └───────────────────────┘             │
            └───────────────┬─────────────────────────────────────┘
                            │
                            ▼
            ┌───────────────────────────────────────────────────────┐
            │ Part III — Sidecar & Circuit Breaker                  │
            │ ┌───────────────┐   ┌────────────────────────────┐    │
            │ │ Sidecar /     │──▶│ Circuit Breaker Middleware │    │
            │ │ Envoy/Istio   │   │ (Fault Tolerance)          │    │
            │ └───────────────┘   └────────────────────────────┘    │
            └───────────────┬─────────────────────────────────────┘
                            │ Commands / Events
                            ▼
            ┌───────────────────────────────────────────────────────┐
            │ Part V — Data Mesh & Event Systems                    │
            │ ┌───────────────┐   ┌───────────────┐                 │
            │ │ Saga Orchestrator│ │ Outbox        │                 │
            │ └───────────────┘   └───────────────┘                 │
            │         │                 │                           │
            │         ▼                 ▼                           │
            │ ┌───────────────┐   ┌───────────────┐                 │
            │ │ Event Store   │──▶│ CQRS / Read     │◀─────────────┘
            │ │ (Append-Only) │   │ Models          │
            │ └───────────────┘   └───────────────┘
            └───────────────┬─────────────────────────────────────┘
                            │ Data & Commands                     │
                            ▼
            ┌───────────────────────────────────────────────────────┐
            │ Part VI — AI-Native & Edge                            │
            │ ┌───────────────┐   ┌───────────────┐                 │
            │ │ Edge Node /   │──▶│ AI Agent      │                 │
            │ │ Wasm Worker   │   │ (ReAct Loop) │                 │
            │ └───────────────┘   └───────────────┘                 │
            │         │                 │                           │
            │         ▼                 ▼                           │
            │ ┌───────────────┐   ┌───────────────┐                 │
            │ │ Vector DB /   │◀──│ Microservices │                 │
            │ │ RAG Engine    │   │ (Tools)         │                 │
            │ └───────────────┘   └───────────────┘                 │
            └───────────────────────────────────────────────────────┘

```

---

## 💡 Pattern Selection Guidelines

* **Event Sourcing:** Use when **history matters** as much as current state.
* **Saga:** Use for **long-lived, multi-service business processes**.
* **BFF:** Use to **optimize payloads** for low-bandwidth or specialized clients.
* **Sidecar / Circuit Breaker:** Use to **decouple concerns** and improve reliability.
* **Agentic RAG:** Use to **augment AI-driven decision-making** with context-rich, real-time reasoning.

---

