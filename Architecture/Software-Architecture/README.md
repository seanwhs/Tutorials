# Modern Software Architecture (2026+)

### A Research-Led Field Guide to Resilient, Scalable, and AI-Native Systems

This repository serves as a live curriculum for architects and senior engineers. It synthesizes the foundational work of **Martin Fowler**, **Zhamak Dehghani**, and the **CNCF** into a practical implementation guide.

---

## 📂 Repository Structure

### [01_Discipline](https://www.google.com/search?q=./01_discipline)

**Focus:** Operational Excellence & 12-Factor App

* **Concepts:** Statelessness, explicit dependencies, config-as-data.
* **Updated for 2026:** How to treat LLM endpoints and Vector DBs as "attached resources."

### [02_Structure](https://www.google.com/search?q=./02_structure)

**Focus:** Clean Architecture & Modular Monoliths

* **Concepts:** Hexagonal Architecture (Ports & Adapters), Domain-Driven Design (DDD).
* **Goal:** Building boundaries that allow you to swap frameworks without rewriting logic.

### [03_Distribution](https://www.google.com/search?q=./03_distribution)

**Focus:** Microservices & Distributed Patterns

* **Concepts:** Service Discovery, API Gateways, and Fowler's "Microservice Premium."
* **Patterns:** CQRS, Saga (Orchestration vs. Choreography), and Circuit Breakers.

### [04_Cloud_Native](https://www.google.com/search?q=./04_cloud_native)

**Focus:** Execution Models

* **Concepts:** Kubernetes, Serverless (FaaS), and Service Mesh (Istio/Linkerd).
* **Implementation:** Moving networking (mTLS, retries) out of the application code.

### [05_Data](https://www.google.com/search?q=./05_data)

**Focus:** Event-Driven Systems & Data Mesh

* **Concepts:** Event Sourcing, Kinesis/Kafka integration, and Dehghani's Data Mesh pillars.
* **Goal:** Moving from centralized "Data Lakes" to decentralized "Data Products."

### [06_Intelligence](https://www.google.com/search?q=./06_intelligence)

**Focus:** AI-Native & Edge Architectures

* **Concepts:** RAG (Retrieval-Augmented Generation), Agentic Orchestration, and Zero-Trust Edge.
* **2026 Shift:** Architecting systems where the LLM is the router, not just a feature.

---

## 🛠 Architectural Selection Matrix

| If your goal is... | Use this Pattern | The Trade-off is... |
| --- | --- | --- |
| **Rapid MVP** | Modular Monolith | Eventual scaling bottlenecks |
| **Team Autonomy** | Microservices | High operational "tax" |
| **Auditability** | Event Sourcing | High complexity in state retrieval |
| **AI Personalization** | RAG / Agentic | Token costs and latency |
| **Ultra-Low Latency** | Edge Computing | Decentralized management |

---

## 🚀 How to use this guide

1. **Follow the Sequence:** Start at `01_discipline`. You cannot build a stable AI-Agentic system on a foundation that violates 12-Factor principles.
2. **Run the Samples:** Each directory contains a `docker-compose.yml` to spin up a local environment demonstrating the pattern (e.g., a Saga flow with RabbitMQ).
3. **Read the Research:** Every module includes a `RESEARCH.md` with links to original papers and articles.

---

## 📜 The Architect’s Credo

> **Discipline before Distribution. Structure before Scale. Data before Intelligence.**

---

