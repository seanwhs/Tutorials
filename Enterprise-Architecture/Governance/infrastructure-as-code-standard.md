# IaC Standard

In an environment of **50+ applications**, manual infrastructure provisioning is an architectural risk. To ensure the **Initiative Delivery** phase is repeatable and the **Asset Management** phase is stable, we treat our infrastructure exactly like our application code.

---

## 1. The "Module-First" Principle

Teams do not write raw cloud provider resources (e.g., AWS, Azure, GCP). Instead, they consume **Architectural Archetype Modules** curated by the EA and Platform teams.

* **Utility Module:** Pre-configured for cost-efficiency, single-region, and standard monitoring.
* **Scaler Module:** Pre-configured with Auto-scaling Groups, Multi-AZ databases, and CDN integration.
* **Pioneer Module:** Fast-provisioning, ephemeral resources with aggressive "Auto-Delete" tags for cost control.

---

## 2. Mandatory Resource Tagging

To manage the lifecycle effectively, every resource must be tagged. This metadata is the bridge between the cloud console and the **EA Lifecycle**.

| Tag Key | Value Example | Purpose |
| --- | --- | --- |
| `ea-scenario` | `Defensive` / `Proactive` / `Aggressive` | Cost attribution and risk profile. |
| `ea-archetype` | `Scaler` / `Utility` / `Pioneer` | Determines maintenance priority. |
| `asset-id` | `APP-402` | Links resource to the Service Catalog. |
| `owner-team` | `Payments-Core` | Identifies who to contact during an incident. |
| `harvest-date` | `2027-01-01` | Sets a review date for decommissioning. |

---

## 3. Environment Parity & Promotion

Infrastructure must be promoted through environments just like code.

1. **Sandbox:** Created by **Pioneer** initiatives. No persistence guaranteed.
2. **Staging:** An exact replica of Production (using the same modules). Used for Load Testing **Scaler** archetypes.
3. **Production:** Locked down. Changes are only possible via CI/CD service accounts (No manual "Click-Ops").

---

## 4. State Management & Locking

* **Remote State:** Infrastructure state must be stored in a centralized, encrypted backend (e.g., S3 with DynamoDB locking).
* **Drift Detection:** Automated "drift" checks must run daily to ensure no one has manually altered the **Asset** configuration in the cloud console.

---

## 5. EA Lifecycle Alignment

| Phase | IaC Responsibility |
| --- | --- |
| **Strategic Planning** | Estimate cloud spend based on the chosen **Scenario**. |
| **Initiative Delivery** | Compose the solution using approved Modules; submit a "Plan" for review. |
| **Asset Management** | Use IaC to scale resources and rotate secrets without downtime. |
| **Asset Harvesting** | Run `terraform destroy` to ensure no "Ghost Resources" remain. |

---

### Recommended Tools

* **Terraform:** For cross-cloud resource provisioning.
* **Checkov / TFLint:** For automated security scanning of IaC code.
* **Crossplane:** For managing infrastructure directly via Kubernetes APIs.

---

**Next high-value step:** Since we now have the IaC standards, would you like me to draft an **"Enterprise Data Strategy"**? This would define how we handle **Global vs. Local Data**, the use of **Data Lakes** for the 50+ apps, and our "Source of Truth" philosophy.
