# Part II — Structural Foundations

## 1. Hexagonal Architecture (Ports & Adapters)

The goal of Hexagonal Architecture is to isolate the **Core Business Logic** from external concerns like databases, APIs, or third-party integrations.

### Why it Matters

* **Testability:** You can test business rules without spinning up a database.
* **Flexibility:** You can swap a SQL database for a NoSQL one (or a Vector DB for AI) by simply changing an **Adapter**, leaving the **Core** untouched.
* **Decoupling:** Protects the domain model from "leaking" technology-specific details (like ORM annotations or HTTP status codes).

---

## 2. Modular Monoliths

Before jumping to Microservices (Part III), we use the **Modular Monolith** pattern. This keeps the codebase in a single deployment unit while enforcing strict boundaries between modules.

### Key Characteristics

* **Logical Isolation:** Each module (e.g., `Orders`, `Inventory`, `Billing`) has its own internal structure.
* **No Circular Dependencies:** Module A can call Module B, but Module B cannot call Module A directly.
* **In-Memory Communication:** High performance with zero network latency, but designed so that modules *could* be extracted into microservices later.

---

## 🛠 Directory Structure

* `/hexagonal-sample`: A Go/TypeScript implementation showing `domain`, `ports` (interfaces), and `adapters`.
* `/modular-monolith-java`: A Spring Boot example using **ArchUnit** to enforce package boundaries.

---

## 🔄 The Progression

1. **Start with Hexagonal**: Keep the business logic clean.
2. **Organize as Modular Monolith**: Group related hexagonal services.
3. **Scale to Microservices**: Only when team size or scaling requirements demand independent deployment.

