# Legacy Modernization

# Blueprint: Legacy Modernization (Strangler Fig)

When a legacy **Asset** becomes a bottleneck (high cost, low reliability, or "Defensive" risk), we do not replace it all at once. We "strangle" it by migrating functionality piece-by-piece to a new **Scaler** or **Utility** service.

---

## 1. The Migration Phases

1. **Transform:** Build a new version of a specific feature (e.g., "User Profile") in a modern service.
2. **Co-exist:** Use a **Proxy** or **API Gateway** to route traffic. New features go to the new service; old features stay with the Monolith.
3. **Eliminate:** Once all features are moved and the Monolith is empty, decommission it (the **Asset Harvesting** phase).

---

## 2. The Interception Layer

To the outside world (the other 49 apps), nothing should change. We use an **Anti-Corruption Layer (ACL)**.

* **The Proxy:** An Edge Gateway or Service Mesh that intercepts calls.
* **The Translation:** The ACL ensures that the new service's modern data format is translated back to the legacy format if downstream systems still expect it.

---

## 3. Data Synchronicity

The hardest part is the database. We use **CDC (Change Data Capture)** to keep the legacy and modern databases in sync during the "Co-exist" phase.

* **Pattern:** Write to the new database, then asynchronously update the legacy database so old reporting tools still work.

---

## 4. EA Lifecycle Alignment

| Phase | Modernization Responsibility |
| --- | --- |
| **Strategic Planning** | Identify the "Laggard" assets and approve a **Proactive** modernization budget. |
| **Initiative Delivery** | Deploy the Proxy and the first "Strangled" microservice. |
| **Asset Management** | Monitor the Proxy logs to ensure traffic is successfully shifting away from the legacy core. |
| **Asset Harvesting** | The final "Unplugging" of the legacy hardware/license. |

---

## 5. Decision Matrix: When to Strangle?

| Metric | Trigger for Modernization |
| --- | --- |
| **Release Velocity** | Deployment takes > 1 week. |
| **Cost** | License/Infrastructure costs > Value delivered. |
| **Skill Gap** | Only 1-2 people know how to maintain the legacy code. |
| **Failure Rate** | The asset is responsible for > 30% of enterprise-wide SEVs. |

---

### Summary of the Journey

We have built a system that handles:

* **Vision:** Strategic Scenarios.
* **Structure:** Archetypes and Team Topologies.
* **Execution:** Blueprints, IaC, and Eventual Consistency.
* **Safety:** Zero Trust, DR, and Observability.
* **Continuity:** Onboarding, ADRs, and Modernization.

