# Part V — Data Systems & Event-Driven Architecture

Data is the "gravity" of software architecture. While compute is easy to scale, stateful data is difficult to move, synchronize, and protect. Modern systems solve this by treating data as an **immutable stream of events** rather than a static snapshot.

---

## 1. Event-Driven Architecture (EDA)

In an EDA, services communicate by emitting and consuming events. This creates **temporal decoupling**: Service A doesn't need Service B to be "up" to send a message; it simply publishes to a broker (Kafka, Pulsar).

* **Pub/Sub Pattern:** Producers remain unaware of who their consumers are.
* **Scalability:** Allows for massive parallel processing of data streams.

---

## 2. Event Sourcing & CQRS

Traditional CRUD deletes history by overwriting rows. **Event Sourcing** persists every change as a unique, immutable event.

* **The Source of Truth:** The Event Store (a sequence of what happened).
* **Projections:** We "project" these events into specialized databases (CQRS Read Models) optimized for specific queries (e.g., an Elasticsearch index for search, a Neo4j graph for relationships).
* **Auditability:** You can "time travel" to any point in the system's history by replaying events up to that timestamp.

---

## 3. Data Mesh

As organizations grow, the "Central Data Team" becomes a bottleneck. **Data Mesh** shifts the responsibility of data quality to the teams who actually generate the data.

* **Data as a Product:** Each domain (e.g., Billing, Inventory) provides a "Clean API" for their analytical data.
* **Federated Governance:** Global standards for security and interoperability, but local execution.

---

## 🔄 Conceptual Data Flow

```text
[ User Action ] 
      |
[ Command Service ] ----> ( Emit Event: "OrderPlaced" )
      |                          |
      |                 [ Persistent Event Store ]
      |                          |
      |          +---------------+---------------+
      |          |                               |
      v          v                               v
[ Write DB ] [ Read Model A (SQL) ]    [ Read Model B (Vector DB) ]
(Consistency)  (Fast UI Queries)        (AI / Semantic Search)

```

---

## 📂 Directory Contents

* `/event-store-demo`: A basic implementation of an append-only log with snapshots.
* `/kafka-projections`: How to build a Read Model from a stream using Kafka Streams or Flink.
* `/data-product-manifest`: An example of a "Data Contract" for a Data Mesh node.

---

