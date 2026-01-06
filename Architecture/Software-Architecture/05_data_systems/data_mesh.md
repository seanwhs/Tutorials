# 05 — Data Systems & Event-Driven Architecture

In a distributed world, data is the "gravity" that makes scaling difficult. This directory explores how to move away from static, centralized databases toward **immutable event streams** and **decentralized data products**.

---

## 1. Event Sourcing + CQRS

Traditional CRUD (Create, Read, Update, Delete) architectures destroy history by overwriting the current state. **Event Sourcing** changes the source of truth to a sequence of immutable events.

* **The Log is the Truth:** Every change is an event (e.g., `FundsDeposited`, `AddressChanged`).
* **Projections (CQRS):** We project these events into specialized "Read Models."
* *Search:* Project events into **Elasticsearch**.
* *Analytics:* Project events into **Snowflake**.
* *AI:* Project events into a **Vector Database**.


* **Deterministic Replay:** You can reconstruct the state of the system at any point in time by replaying the log.

---

## 2. Data Mesh (Zhamak Dehghani)

Data Mesh applies **microservice principles to analytical data systems**. It solves the "Data Bottleneck" by decentralizing ownership.

### The Four Pillars

1. **Domain-Oriented Ownership**: The "Sales Team" owns the sales data; the "Shipping Team" owns shipping data.
2. **Data as a Product**: Data must be discoverable, versioned, and trustworthy—not an accidental byproduct.
3. **Self-Serve Data Platform**: Centralized infrastructure (Kafka, BigQuery) with decentralized content.
4. **Federated Governance**: Global standards for security (PII masking) and interoperability.

---

## 3. Event-Driven Architecture (EDA)

EDA allows for **temporal decoupling**. Services communicate via an asynchronous message broker (Kafka, RabbitMQ, or NATS), allowing the system to scale and handle spikes without cascading failures.

```text
[ Producer Service ] ----> ( Event Published ) ----> [ Message Broker ]
                                                        |
          +-----------------------+---------------------+
          |                       |                     |
          v                       v                     v
[ Consumer Service A ]   [ Consumer Service B ]   [ Archive / AI Store ]

```

---

## 📂 Directory Contents

* `/event-store`: A Python/TypeScript implementation of an append-only event log.
* `/cqrs-projections`: Code demonstrating how to sync a "Write Model" to multiple "Read Models."
* `/data-contract-examples`: YAML definitions for formalizing the interface between data producers and consumers.

---

## 🛠 Strategic Comparison

| Pattern | Best For... | Main Challenge |
| --- | --- | --- |
| **CRUD** | Simple internal tools / MVPs. | No history; hard to scale. |
| **Event Sourcing** | Auditing, complex business logic, AI training. | High learning curve; eventual consistency. |
| **Data Mesh** | Large organizations with many data-producing teams. | Significant cultural and platform overhead. |

---

