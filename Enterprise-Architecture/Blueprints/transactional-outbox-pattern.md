# Blueprint: Transactional Outbox Pattern

To ensure **Reliable Messaging** and avoid data drift, services must not perform "Dual Writes" (writing to a database and a message broker separately). Instead, utilize the Transactional Outbox pattern.

## The Problem
If a service updates a database but fails to send the corresponding event to Kafka (or vice versa), the system enters an inconsistent state.

## The Solution
Treat the database as the "Source of Truth" for both the state and the notification.

### Technical Workflow
1.  **Atomic Transaction:** Within a single DB transaction, the service updates the business entity (e.g., `Orders`) and inserts a message into an `outbox` table.
2.  **Relay Process:** An external process (Change Data Capture) monitors the `outbox` table.
3.  **Dispatch:** The relay publishes the message to Kafka.
4.  **Acknowledge:** Once the broker confirms receipt, the relay marks the outbox message as processed or deletes it.

### Recommended Tooling
* **Database:** PostgreSQL
* **Relay:** **Debezium** (running on Kafka Connect)
* **Event Log:** Apache Kafka

### Implementation Diagram
```text
[ Service ] 
     |
     v
( Start Transaction )
     |--> Update "Orders" Table
     |--> Insert into "Outbox" Table
( Commit Transaction )
     |
     v
[ Database WAL / Log ] <--- [ Debezium Connector ]
                                     |
                                     v
                            [ Apache Kafka Topic ]
