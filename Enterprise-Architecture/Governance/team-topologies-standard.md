# Team Topologies Standard

# Governance: Team Topologies & Interaction

To manage 50+ applications, we must align our team structures with our software boundaries (Conway’s Law). We categorize teams into four specific types to reduce friction.

* **Stream-aligned Teams:** Own a specific business domain (e.g., "Checkout" or "Inventory"). They are responsible for the full **EA Lifecycle** of their assigned assets.
* **Platform Teams:** Build the **Golden Path**. They own the IaC modules, the Service Mesh, and the Observability stack that the other teams consume.
* **Enabling Teams:** Specialists (like the EA Team) who consult with Stream-aligned teams to bridge knowledge gaps (e.g., helping a team adopt the **Saga Pattern**).
* **Complicated Subsystem Teams:** Highly specialized teams (e.g., "Math/Algorithmic Engine") that provide a service too complex for a generalist stream-aligned team to maintain.

---

### `Templates/architecture-decision-record-adr.md`

# Template: Architecture Decision Record (ADR)

Code tells you *what* was built; the **ADR** tells you *why*. For every major deviation or new standard in the 50+ app fleet, an ADR must be created. This prevents "Chesterton’s Fence"—where a new architect deletes a critical configuration because they don't understand why it was put there.

**Structure:**

1. **Title:** ADR-00X: [Short Title]
2. **Context:** What was the problem? What were the constraints?
3. **Decision:** What did we choose to do? (e.g., "We will use Kafka over RabbitMQ for this domain.")
4. **Status:** Proposed / Accepted / Superseded.
5. **Consequences:** What is the trade-off? (e.g., "Increased operational complexity but higher throughput.")

---

### `Governance/architectural-principles.md`

# Governance: Core Architectural Principles

These are the "Ten Commandments" that guide every **Options Assessment**.

1. **Decouple by Default:** No shared databases between services. Communication must be via API or Events.
2. **Smart Endpoints, Dumb Pipes:** Avoid complex logic in the network layer (like ESBs); keep the logic in the services.
3. **Automate Everything:** If a process (deployment, scaling, testing) happens twice, it must be scripted.
4. **Design for Failure:** Assume the network will fail and the database will lag. Use Circuit Breakers and Retries.
5. **Data Sovereignty is Non-Negotiable:** PII stays in its region. No exceptions.

---ery & Business Continuity" blueprint?** This would define how the 50+ apps behave during a total regional cloud outage.
