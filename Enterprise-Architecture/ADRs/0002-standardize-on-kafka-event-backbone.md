# ADR 0002: Standardize on Apache Kafka as the Enterprise Event Backbone

## Status
Accepted

## Context
As we scale beyond 50 applications, point-to-point synchronous communication (REST/gRPC) is creating tight coupling and cascading failures. We require a persistent, distributed event streaming platform to enable:
* **Temporal Decoupling:** Services should function regardless of downstream availability.
* **Data Consistency:** Supporting patterns like the Transactional Outbox and Sagas.
* **Streaming Analytics:** Real-time processing of business events.

We evaluated RabbitMQ (Traditional Pub/Sub), AWS SNS/SQS (Cloud Native), and Apache Kafka (Distributed Log).

## Decision
We will standardize on **Apache Kafka** as the primary event backbone for the enterprise.

### Rationale
* **Replayability:** Unlike traditional message brokers, Kafka's distributed log allows services to "rewind" and replay events, critical for disaster recovery and new service synchronization.
* **Throughput:** Kafka handles high-volume telemetry and transactional data more efficiently than SQS or RabbitMQ at our projected scale.
* **Ecosystem:** Strong support for Kafka Connect (for CDC/Debezium) and Schema Registry (for contract enforcement).

## Consequences
### Positive
* Standardized client libraries and observability across all teams.
* Ability to use Change Data Capture (CDC) to eliminate dual-write problems.
* Simplified integration for data engineering and warehouse teams.

### Negative
* **Operational Complexity:** Requires dedicated expertise (or managed services like Confluent/AWS MSK).
* **Higher Latency:** Slightly higher overhead than pure in-memory brokers for simple messaging.
* **Learning Curve:** Engineering teams must be trained on partition keys, consumer groups, and offset management.

## Compliance Requirement
All Kafka topics must utilize the **Confluent Schema Registry** to ensure Avro/Protobuf contract compatibility.
