# Part II — Structural Foundations: Drawing the Right Boundaries

Architecture is fundamentally the discipline of **boundary design**. In 2026, the "Modular Monolith" has reclaimed its status as the gold standard for most growing systems. It provides the speed of a single codebase with the structural integrity required to transition to microservices if—and only if—it becomes necessary.

## 1. The Modular Monolith

A **Modular Monolith** is a single deployment unit (one process) strictly partitioned into independent modules based on business domains.

### Key Advantages

* **Shared Transactional Boundaries:** You can use standard database transactions (`BEGIN/COMMIT`) across modules, ensuring data integrity without complex distributed patterns like Sagas.
* **Straightforward Debugging:** Stack traces remain local; you don't need distributed tracing to follow a request through the system.
* **Lower Cognitive Overhead:** Developers can understand the entire system flow without navigating network topologies.

> **The Warning:** Without strict enforcement, a monolith becomes a "Big Ball of Mud." Poor modularity is the leading cause of "Distributed Monoliths"—systems that have the complexity of microservices but the tight coupling of a monolith.

---

## 2. Hexagonal Architecture (Ports & Adapters)

To keep a monolith modular, we use **Hexagonal Architecture**. This keeps the "Business Logic" agnostic of the "Technology Stack."

### Structural Components:

* **The Core (Domain):** Pure business logic, entities, and domain events. Zero dependencies on external libraries (no ORMs, no Web Frameworks).
* **Ports (Interfaces):** Contractual definitions of what the core needs (e.g., `interface IOrderRepository`).
* **Adapters (Infrastructure):** Concrete implementations of ports (e.g., `DrizzleOrderRepository` or `StripePaymentAdapter`).

---

## 💻 Code Example: Enforcing Boundaries (TypeScript)

This example demonstrates how a **Billing** module and an **Inventory** module interact *without* direct coupling.

### The Core (Domain Logic)

```typescript
// billing/domain/invoice.ts
export interface BillingService {
  createInvoice(orderId: string, amount: number): Promise<void>;
}

// inventory/domain/stock.ts
export class InventoryModule {
  constructor(private billing: BillingService) {}

  async processOrder(orderId: string, items: any[]) {
    // 1. Business logic for stock deduction...
    console.log(`Processing order ${orderId}`);

    // 2. Cross-module communication via Interface (Port)
    await this.billing.createInvoice(orderId, 100);
  }
}

```

### The Infrastructure (Adapters)

```typescript
// billing/infrastructure/stripe-adapter.ts
import { BillingService } from '../domain/invoice';

export class StripeBillingAdapter implements BillingService {
  async createInvoice(orderId: string, amount: number) {
    // Actual API call to Stripe
    console.log(`Stripe Invoice created for ${orderId}: $${amount}`);
  }
}

```

---

## 📂 Directory Contents

* `/domain-driven-design`: Example folder structure for a modular monolith.
* `/hexagonal-boilerplate`: A starter project showing how to swap a `MockRepo` for a `PostgresRepo`.
* `/dependency-injection`: Demonstrates using Inversify or NestJS to wire ports to adapters.

---

## 🛠 Decision Matrix: Is it time to split?

If your Modular Monolith meets these criteria, consider moving to **Part III: Distribution**:

1. **Deployment Bottlenecks:** One module's tests take 30 minutes, slowing down everyone else.
2. **Resource Conflict:** The "Image Processing" module needs high CPU, while "API" needs high RAM.
3. **Data Sovereignty:** One module requires a NoSQL database while the rest are on Postgres.

