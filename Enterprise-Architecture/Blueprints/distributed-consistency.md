# Distributed Consistency

# Blueprint: Distributed Consistency

In an ecosystem of **50+ applications**, we move away from "All-or-Nothing" ACID transactions. Instead, we embrace **Eventual Consistency** to ensure that services remain decoupled and highly available.

---

## 1. The Transactional Outbox Pattern

**Problem:** When a service updates its database and sends a message to Kafka, one might succeed while the other fails, leading to data inconsistency.
**Solution:** Every "Build" project must use an **Outbox** to ensure atomicity between the database and the message broker.

### How it Works:

1. **Local Transaction:** The application updates its business tables (e.g., `Orders`) and inserts a message into an `Outbox` table within the **same local transaction**.
2. **Relay Service:** A separate process (or Change Data Capture tool like Debezium) reads the `Outbox` table and publishes the message to the Enterprise Event Backbone.
3. **Guarantee:** This ensures "At-Least-Once" delivery without needing complex distributed locking.

---

## 2. The Saga Pattern

**Problem:** How do we manage a business process that spans multiple services (e.g., *Order -> Payment -> Inventory*) without a distributed transaction?
**Solution:** Use a **Saga**, which is a sequence of local transactions.

### Choreography (Event-Driven)

* **Mechanism:** Each service performs its transaction and publishes an event that triggers the next service.
* **Best For:** Simple workflows with few participants.
* **Strategic Scenario:** Usually fits the **Proactive** or **Aggressive** scenarios due to high decoupling.

### Orchestration (Command-Driven)

* **Mechanism:** A central "Saga Manager" tells participants when to execute their local transactions.
* **Best For:** Complex workflows where the business logic needs to be centralized.
* **Archetype:** Often required for **Scaler** archetypes where visibility into long-running processes is critical.

---

## 3. Compensating Transactions (The "Undo" Logic)

Because we cannot "rollback" a transaction that has already been committed in another service, every action must have a corresponding **Compensating Transaction**.

* **Action:** `Reserve Inventory` -> **Compensating Action:** `Release Inventory`.
* **Rule:** If a step in the Saga fails, the system must execute the compensating actions for all previously completed steps in reverse order to return the enterprise to a consistent state.

---

## 4. Idempotency Requirement

In a distributed system, messages may be delivered more than once.

* **Standard:** Every consumer in the 50+ app fleet **must** be idempotent.
* **Mechanism:** Use a `Unique Transaction ID` to check if a message has already been processed before executing business logic.

---

## 5. EA Lifecycle Alignment

* **Strategic Planning:** Identify if the initiative requires high consistency (Orchestration) or high availability (Choreography).
* **Initiative Delivery:** Implement the Outbox and Saga logic as defined in the HLSO.
* **Asset Management:** Monitor "Saga Health" and DLQs (Dead Letter Queues) to identify stalled business processes.

---

**Next high-value step:** Would you like me to draft the **"API Evolution & Zero-Downtime Blueprint"**? This would define exactly how to handle the **Expand and Contract** pattern to ensure deployments never break dependencies.
