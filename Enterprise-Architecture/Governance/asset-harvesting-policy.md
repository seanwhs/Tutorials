# Asset Harvesting Policy

In an ecosystem of **50+ applications**, the "Asset Harvesting" phase is critical to prevent **Architectural Rot**. Without a formal decommissioning strategy, the enterprise accumulates "Zombie Apps"—services that provide little value but continue to consume cloud costs, security patches, and engineering headspace.

---

## 1. The Debt-to-Value Ratio

Every asset in the **Asset Management** phase is evaluated annually. We measure the "health" of an application by comparing its business value against its operational debt.

* **Business Value:** Revenue generated, critical processes supported, or user volume.
* **Operational Debt:** Number of security vulnerabilities, outdated runtimes (e.g., Java 8), and "on-call" incident frequency.

---

## 2. Triggering the Harvesting Phase

An asset enters the **Asset Harvesting** phase when one of the following "Harvest Triggers" occurs:

* **Strategic Shift:** The original **Strategic Scenario** (Aggressive/Proactive) is no longer valid.
* **Functional Overlap:** A new initiative has been "Built" or "Bought" that duplicates the asset's capabilities.
* **Technological Obsolescence:** The cost to upgrade the asset to modern security standards exceeds the cost of a rewrite or migration.
* **Archetype Decay:** A "Scaler" that has dropped to low traffic and high maintenance may be re-classified as a "Utility" and marked for consolidation.

---

## 3. The Harvesting Workflow (The 3 R's)

When an asset is marked for harvesting, the EA team chooses one of three paths:

| Path | Action | Outcome |
| --- | --- | --- |
| **Retire** | Total shutdown of the service. | Data is archived; compute resources are deleted. |
| **Replace** | Migrate users/data to a newer "Golden Path" asset. | The old asset is decommissioned after 100% cutover. |
| **Refactor** | Significant reinvestment to move the asset back to the "Delivery" phase. | Only used if business value is exceptionally high. |

---

## 4. Decommissioning Checklist (The "Graceful Exit")

To ensure a clean harvest without breaking the other 49+ applications:

* [ ] **Dependency Mapping:** Use the **Service Catalog** to identify every upstream consumer.
* [ ] **Contract Deprecation:** Issue a `Sunset` HTTP header and notify all consumer owners 90 days in advance.
* [ ] **Data Preservation:** Ensure all data is moved to a long-term "Cold Storage" archive or migrated to the replacement system.
* [ ] **Resource Reclamation:** Delete DNS entries, Load Balancers, IAM roles, and DB instances.

---

## 5. Capturing Lessons Learned

The final act of the EA Lifecycle is the **Harvest Report**. This document feeds back into the **Strategic Planning** phase for future projects:

* What made this asset reach the end of its life?
* Was the original **Archetype** (e.g., Pioneer) correctly identified?
* How can we make the next "Utility" easier to maintain so it stays in the Asset Management phase longer?

---

### Recommended Learning

**Application Portfolio Management (APM) Strategies**
Learn how to manage the lifecycle of hundreds of enterprise applications:
[https://www.youtube.com/watch?v=0hB1k8wI_M8](https://www.google.com/search?q=https://www.youtube.com/watch%3Fv%3D0hB1k8wI_M8)

---

