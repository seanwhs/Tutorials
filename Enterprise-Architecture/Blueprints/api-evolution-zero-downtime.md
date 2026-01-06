# API Evolution - Zero Downtime

# Blueprint: API Evolution & Zero-Downtime

In an interconnected enterprise, "Breaking Changes" are the primary cause of SEV-0 incidents. This blueprint defines how to evolve an **Asset** while maintaining 100% availability for downstream consumers.

---

## 1. The "Expand and Contract" Pattern

This is our mandatory standard for evolving any shared interface (API or Database Schema). It decouples the deployment of the Producer from the migration of the Consumer.

### The Three Stages:

1. **Expand:**
* **Action:** Add the new field or endpoint. Keep the old field/endpoint fully functional.
* **Goal:** The service now supports *both* versions simultaneously.


2. **Migrate:**
* **Action:** Downstream teams (the 50+ other apps) update their code to point to the new field/version at their own pace.
* **Goal:** All traffic eventually moves to the new version.


3. **Contract:**
* **Action:** Once logs confirm zero traffic on the old version, remove the legacy field/endpoint.
* **Goal:** The codebase is cleaned, and technical debt is harvested.



---

## 2. API Versioning Strategy

* **Major Versions (Breaking):** Reflected in the URL (e.g., `/v1/orders` vs `/v2/orders`).
* **Minor/Patch (Non-Breaking):** Handled via backward-compatible code.
* **The Sunset Header:** When an API enters the **Asset Harvesting** phase, it must return an HTTP `Sunset` header. This programmatically alerts consumers of the upcoming retirement date.

---

## 3. Database Schema Evolution

In the **Initiative Delivery** phase, code is often deployed faster than databases can be migrated.

* **Rule:** Code must be "N-1" compatible.
* **Mechanism:** Your application must be able to run against the *previous* version of the database schema. This allows you to roll back the application code immediately if a bug is found, without having to roll back the entire database.

---

## 4. Deployment Archetypes

The method of rollout is determined by the **Architectural Archetype** assigned during Initiation:

| Archetype | Deployment Method | Logic |
| --- | --- | --- |
| **Pioneer** | **Recreate** | Fast and simple; short downtime is acceptable for experiments. |
| **Utility** | **Blue-Green** | Switch 100% traffic to new environment after smoke tests pass. |
| **Scaler** | **Canary Release** | Route 5% of traffic to the new version, monitor **Golden Signals**, then ramp up. |

---

## 5. EA Lifecycle Alignment

* **Strategic Planning:** Determine if the initiative requires high availability (Blue-Green/Canary).
* **Initiative Delivery:** Implement "Expand" changes and monitor consumer migration logs.
* **Asset Management:** Use "Contract" phases to keep the service lean and performant.
* **Asset Harvesting:** Use the `Sunset` header to gracefully offboard legacy consumers.

---

