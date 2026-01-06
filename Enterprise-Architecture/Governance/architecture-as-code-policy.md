# Architecture as Code policy

# Policy: Architecture as Code (AaC)

To prevent "Standard Drift," we treat our architectural requirements exactly like our application code.

### 1. The Living Registry (Service Catalog)

Every application must maintain an `architecture.yaml` file in its root directory. This file is ingested by our EA Dashboard to provide a real-time map of the ecosystem.

**Example `architecture.yaml`:**

```yaml
asset_id: "APP-042"
name: "Payments-Gateway"
archetype: "Critical-Scaler"
scenario: "Proactive"
owner_team: "fintech-core"
dependencies: 
  - "APP-012 (Identity)"
  - "APP-088 (Ledger)"
slo_targets:
  availability: 99.99
  latency_p99: "150ms"

```

### 2. Automated Dependency Mapping

We use the **Service Mesh** (Istio/Linkerd) to generate a "Live Map." If a **Utility** app suddenly starts calling an **Aggressive** experiment, the EA team receives an automated alert to review the "Blast Radius."

---

### `Blueprints/the-exit-strategy.md`

# Blueprint: The Cloud-Exit & Portability Strategy

A key responsibility of EA is ensuring the business is never "locked in" to a single provider. For our 50+ apps, we enforce **Provider Abstraction**.

* **Database:** Use managed services (RDS/Cloud SQL) but avoid provider-specific extensions (e.g., DynamoDB-only triggers) unless approved via an **ADR**.
* **Compute:** All assets must be containerized (OCI compliant). No "bare metal" installs that cannot be moved to a different cloud region within the **RTO**.
* **Storage:** Use S3-compatible APIs.

---

### The Final "Big Picture" Dashboard

As the Lead Architect, your daily view changes from a code editor to a **Fleet Health Radar**.

| Quadrant | Metric | Action |
| --- | --- | --- |
| **Drift** | Apps deviating from Blueprints. | Schedule a Mini-QAR. |
| **Debt** | Legacy apps nearing "End of Life." | Accelerate the Strangler Fig. |
| **Efficiency** | Underutilized "Utility" resources. | Rightsizing / Harvesting. |
| **Innovation** | New "Pioneers" entering the fold. | Assign an Enabling Team. |

---

### Final Wrap-Up

You have moved through the entire **EA Maturity Journey**:

1. **Phase 1:** Strategy & Categorization.
2. **Phase 2:** Design Patterns & Blueprints.
3. **Phase 3:** Governance, Security, & SLOs.
4. **Phase 4:** Automation, Roadmaps, & Leadership.

