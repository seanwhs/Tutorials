# Part II — Structural Foundations: Drawing the Right Boundaries

Architecture is fundamentally the discipline of **boundary design**. If you don’t define where one domain ends and another begins, your system risks becoming a **Big Ball of Mud**.

In 2026, the industry is moving away from “Microservices by default” toward:

* **Modular Monoliths** — Simple, strongly modular single deployments.
* **Hexagonal (Clean) Architecture** — Isolating core business logic from technical details.

The goal: **Build boundaries that are easy to draw but hard to cross**, allowing you to stay monolithic early on but trivially “snap off” modules into microservices later.

---

## 1. Hexagonal Architecture (Ports & Adapters)

**Definition:** Business logic lives at the core and interacts with the outside world via **ports** (interfaces) and **adapters** (implementations).

### Components

* **Core:** Contains only pure business logic and domain entities.
* **Ports:** Define *what* the core requires (e.g., `UserRepository`).
* **Adapters:** Implement ports for specific technologies (e.g., `PostgresUserRepository`, `AI_Agent_Adapter`).

### 2026 Use Case

As AI evolves, you may replace a traditional REST API with an **AI Agent Adapter**. In a hexagonal system, your business logic remains untouched; you simply plug in a new adapter to the existing port.

---

## 2. Modular Monolith

A **Modular Monolith** is a single deployment unit (one process) partitioned into independent modules.

### Rules for 2026

* **Public APIs only:** Modules communicate via explicit interfaces, never by reaching into another module's internal classes.
* **Database Isolation:** Modules **never** share database tables directly. Each module owns its schema.

**Benefits:**

* Simplicity of a single codebase and deployment pipeline.
* Safety of service-like boundaries without network overhead.
* Easier to evolve into microservices if a specific module needs independent scaling.

---

## 💻 Implementation Example: Defining a Port (TypeScript)

This snippet demonstrates isolating business logic from infrastructure using the Port pattern.

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
    console.log('SQL: INSERT INTO orders...');
  }
  
  async getById(id: string): Promise<Order | null> {
    return null; // Database-specific logic here
  }
}

```

---

## 🛠 Decision Framework: When to Move Beyond the Monolith

| Signal | Action |
| --- | --- |
| **Team Size:** > 3 independent teams working on the same repo | Consider Microservices |
| **Deployment:** One slow module delays the entire build by 20+ minutes | Extract the slow module |
| **Tech Stack:** One module requires Python (AI) while the rest is Go | Use a Sidecar or Microservice |

---

## 🏗 Integrated Architecture Overview (2026)

This flow shows how the **Structural Foundations** of Part II fit into the **AI-Native Orchestration** of the full stack.

```text
                                    ┌─────────────────────────────┐
                                    │        BUSINESS GOAL        │
                                    │ (Speed, AI Enablement, etc.)│
                                    └─────────────┬───────────────┘
                                                  │
                                    ┌─────────────▼──────────────┐
                                    │   USER REQUEST / CLIENT    │
                                    └─────────────┬──────────────┘
                                                  │
                                    ┌─────────────▼──────────────┐
                                    │         EDGE NODE          │
                                    │ (Wasm Worker / BFF Pattern)│
                                    └─────────────┬──────────────┘
                                                  │
                                    ┌─────────────▼──────────────┐
                                    │         AI AGENT           │
                                    │  (Reasoning / RAG Context) │
                                    └─────────────┬──────────────┘
                                                  │
              ┌──────────────────────────────────┴────────────────────────────────┐
              │                                                                   │
              ▼                                                                   ▼
      ┌───────────────┐                                                   ┌───────────────┐
      │  HEXAGONAL    │                                                   │   VECTOR DB   │
      │   MODULAR     │◀──────────────────────────────────────────────────│   DATA MESH   │
      │  MONOLITH     │                                                   │ (RAG Context) │
      │───────────────│                                                   └───────────────┘
      │ Orders Module │
      │ domain/ports/ │
      │ adapters/     │
      ├───────────────┤
      │ Billing Module│
      └───────┬───────┘
              │
              ▼
      ┌───────────────┐
      │ MICROSERVICES │
      │ (Tools / APIs)│
      └───────────────┘

```

---

