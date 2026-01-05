### Overview

This reference implementation provides a "Local-First" version of the **Golden Path**. It allows developers to spin up a fully compliant enterprise stack—including the **Event Backbone**, **Change Data Capture (CDC)**, and **Relay** patterns—with a single command.

---

## 1. Local Stack Architecture

This environment mirrors our production standards, enabling developers to test **Distributed Consistency** patterns (Saga/Outbox) on their workstations.

* **Database:** PostgreSQL 15+ (Configured with `wal_level=logical` for CDC).
* **Event Backbone:** Kafka + Zookeeper (or KRaft).
* **CDC Relay:** Debezium (Kafka Connect) for the Transactional Outbox pattern.
* **Schema Registry:** For enforcing Avro/Protobuf contracts.
* **Control Plane:** Akhq or Kafdrop for visual debugging of event streams.

---

## 2. The `docker-compose.yml` (Scaffold)

```yaml
version: '3.8'
services:
  # The Source of Truth
  postgres:
    image: debezium/postgres:15
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=enterprise_user
      - POSTGRES_PASSWORD=enterprise_pass
      - POSTGRES_DB=orders_db

  # The Event Backbone
  kafka:
    image: confluentinc/cp-kafka:7.4.0
    depends_on: [zookeeper]
    ports:
      - "9092:9092"
    environment:
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      # ... other config ...

  # The Transactional Outbox Relay (CDC)
  connect:
    image: debezium/connect:2.3
    depends_on: [kafka, postgres]
    ports:
      - "8083:8083"
    environment:
      BOOTSTRAP_SERVERS: kafka:29092
      GROUP_ID: 1
      CONFIG_STORAGE_TOPIC: my_connect_configs
      # ... other config ...

  # The Visibility Layer
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092

```

---

## 3. Developer Guide: Implementing the Outbox

To align with the **Initiative Delivery Guide**, engineers must follow these steps to implement the Outbox pattern in this environment:

### Step 1: Create the Outbox Table

Every service database must include a standard `outbox` table.

```sql
CREATE TABLE outbox (
    id UUID PRIMARY KEY,
    aggregate_type VARCHAR(255),
    aggregate_id VARCHAR(255),
    type VARCHAR(255),
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

```

### Step 2: Register the Debezium Connector

Post a JSON configuration to the Connect API (`localhost:8083`) to start the relay.

### Step 3: Verify the Flow

1. Perform a business action (e.g., `INSERT INTO orders...`).
2. Simultaneously `INSERT` the event into the `outbox` table within the same transaction.
3. Open **Kafka-UI** (`localhost:8080`) to see the event appear in the Kafka topic automatically.

---

## 4. Alignment Checklist

* [ ] **Infrastructure:** Does the local environment use the standard Postgres/Kafka versions?
* [ ] **Observability:** Can you see the message headers and trace IDs in the Kafka UI?
* [ ] **Security:** Are you using the standard `enterprise_user` credentials provided in the scaffold?

---

