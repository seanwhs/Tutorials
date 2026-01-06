# Part II — Structural Foundations: Drawing the Right Boundaries

Architecture is fundamentally the discipline of **boundary design**.
If you don’t define where one domain ends and another begins, your system risks becoming a **Big Ball of Mud**.

In 2026, the industry is moving away from “Microservices by default” toward:

* **Modular Monoliths** — simple, strongly modular single deployments
* **Hexagonal (Clean) Architecture** — isolating core business logic from technical details

The goal: **build boundaries that are easy to draw but hard to cross**, so you can stay monolithic early on but trivially “snap off” modules into microservices later.

---

## 1. Hexagonal Architecture (Ports & Adapters)

**Definition:** Business logic lives at the core and interacts with the outside world via **ports** (interfaces) and **adapters** (implementations).

```
        [ UI / Agent ]
              |
        +-----v-----+
        |    Port   |
+-------+-----------+-------+
|     Business Logic       |
+-------+-----------+-------+
        |    Port   |
        +-----^-----+
              |
       [ DB / API / Vector ]
```

### Components

* **Core:** Contains only pure business logic and domain entities.
* **Ports:** Define *what* the core requires (e.g., `UserRepository`).
* **Adapters:** Implement ports for specific technologies (e.g., `PostgresUserRepository`, `AIAdapter`).

### 2026 Use Case

As AI evolves, you may replace a traditional REST API with an **AI Agent Adapter**. In a hexagonal system, your business logic remains untouched; you simply plug in a new adapter.

**Benefits:**

* Supports rapid substitution of technology layers
* Prevents business logic from being tightly coupled to infrastructure

---

## 2. Modular Monolith

A **Modular Monolith** is a single deployment unit (one process) partitioned into independent modules.

```
+----------------------------------+
|        Modular Monolith           |
|----------------------------------|
|  Billing | Orders | Inventory    |
|  (Clear Domain Boundaries)       |
+----------------------------------+
```

**Rules:**

* Modules communicate only via explicit public APIs.
* Modules **never** share database tables directly.

**Benefits:**

* Simplicity of a single codebase
* Safety of service-like boundaries
* Faster iteration and debugging
* Easier to evolve into microservices later

---

## 💻 Implementation Example: Defining a Port (TypeScript)

This example shows how to isolate business logic from a database using a **Port**.

```typescript
// --- THE PORT (In the Core) ---
export interface OrderRepository {
  save(order: Order): Promise<void>;
  getById(id: string): Promise<Order | null>;
}

// --- THE BUSINESS LOGIC (In the Core) ---
export class OrderService {
  constructor(private orderRepo: OrderRepository) {}

  async placeOrder(order: Order) {
    if (order.total > 1000) {
      order.applyDiscount(0.1);
    }
    await this.orderRepo.save(order);
  }
}

// --- THE ADAPTER (On the Outside) ---
export class PostgresOrderRepository implements OrderRepository {
  async save(order: Order): Promise<void> {
    console.log('Saved to Postgres');
  }
  
  async getById(id: string): Promise<Order | null> {
    return null; // Implementation details here
  }
}
```

---

## 🛠 Decision Framework: When to Move Beyond the Monolith

| Signal                                                                 | Action                        |
| ---------------------------------------------------------------------- | ----------------------------- |
| **Team Size:** > 3 independent teams working on the same repo          | Consider Microservices        |
| **Deployment:** One slow module delays the entire build by 20+ minutes | Extract the slow module       |
| **Tech Stack:** One module requires Python (AI) while the rest is Go   | Use a Sidecar or Microservice |

---

## 📖 Recommended Research

* [Domain-Driven Design (Eric Evans)](https://www.domainlanguage.com/ddd/)
* [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
* [Modular Monolith: A Guide (Simon Brown)](https://structurizr.com/help/modularity-maturity-model)

---

