# Blueprint: Saga Orchestration Pattern

In a distributed environment of 50+ applications, traditional distributed transactions (2PC) do not scale and create synchronous blocking. To maintain eventual consistency across service boundaries, we utilize the **Saga Orchestration Pattern**.

## 1. The Problem
A single business process (e.g., "Order Fulfillment") requires successful actions from the Inventory, Payment, and Shipping services. If the Payment service fails after Inventory is reserved, the system remains in an inconsistent state unless a rollback occurs.

## 2. The Solution: Centralized Orchestration
An **Orchestrator** (State Machine) manages the workflow logic. It tells each participant what to do and—crucially—manages **Compensating Transactions** if a failure occurs.

### Successful Path
1. **Orchestrator** sends `ReserveInventory` command.
2. **Inventory** replies `Success`.
3. **Orchestrator** sends `ProcessPayment` command.
4. **Payment** replies `Success`.
5. **Orchestrator** sends `ShipOrder` command.

### Failure Path (Compensation)
1. **Orchestrator** sends `ProcessPayment` command.
2. **Payment** replies `Declined`.
3. **Orchestrator** identifies the failure and sends `ReleaseInventory` (the **Compensating Transaction**) to restore the system state.



## 3. Implementation Standards

### Technology Options
* **Workflow Engines:** Temporal.io (Recommended), AWS Step Functions, or Camunda.
* **State Management:** The Orchestrator must persist the state of the Saga in a database to survive service restarts.

### Key Requirements
* **Idempotent Participants:** Every participant (Inventory, Payment, etc.) must be able to process the same command multiple times without side effects (handling retries).
* **Compensating Logic:** For every "Do" action, there must be a corresponding "Undo" action defined in the Blueprint.
* **Observability:** Orchestrators must emit events for every state transition to allow centralized tracking of long-running workflows.

## 4. Comparison: Orchestration vs. Choreography

| Feature | Orchestration (This Blueprint) | Choreography (Event-Driven) |
| :--- | :--- | :--- |
| **Visibility** | High (State is in one place) | Low (Distributed across logs) |
| **Coupling** | Orchestrator knows all services | Services only know events |
| **Complexity** | Centralized logic | Emerging "Spaghetti" at scale |
| **Best Use** | Complex, multi-step business flows | Simple 2-3 step notifications |



## 5. Error Handling
* **Transient Failures:** Use the Service Mesh (Istio) or Orchestrator retries.
* **Business Failures:** (e.g., Insufficient funds) Trigger the compensation path.
* **System Failures:** If the Orchestrator itself fails, it must resume from its last persisted state upon restart.
