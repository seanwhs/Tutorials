# Quarterly Architecture Review Template

In an ecosystem of **50+ applications**, the **Asset Management** phase is not "set it and forget it." The **QAR** is a recurring checkpoint to ensure that an asset still aligns with its original **Strategic Scenario** and isn't becoming an unmanaged liability.

---

## 1. Asset Identity

* **Asset Name:** [e.g., Global Payment Gateway]
* **Original Archetype:** [Utility / Scaler / Pioneer]
* **Current Strategic Scenario:** [Defensive / Proactive / Aggressive]
* **Owner:** [Team Name / Slack Channel]

---

## 2. Vital Signs (The Four Golden Signals)

*Reviewing the last 90 days of performance data.*

| Metric | Status (Green/Yellow/Red) | Observations |
| --- | --- | --- |
| **Latency** |  | Any  spikes or steady degradation? |
| **Traffic** |  | Is volume increasing or is the asset losing utility? |
| **Errors** |  | Is the error budget being consistently exhausted? |
| **Saturation** |  | Are we over-provisioned (wasting $) or under-provisioned? |

---

## 3. Technical Debt & Compliance Audit

*Checking against the [Service Readiness Checklist](https://www.google.com/search?q=https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture) standards.*

* [ ] **Security:** Are there any outstanding high-risk CVEs in the asset's dependencies?
* [ ] **Patterns:** Is the asset still following the **Blueprints** (e.g., Outbox, Saga)?
* [ ] **API Health:** Are there legacy versions that should be entering the **Contract** phase?
* [ ] **Documentation:** Is the `RUNBOOK.md` up to date with the latest failure modes?

---

## 4. Strategic Alignment Review

*Does this asset still belong in its current phase?*

* **Stay in Asset Management:** The service is stable and delivering high business value.
* **Return to Initiative Delivery:** Significant refactoring or "Aggressive" new features are required to stay competitive.
* **Move to Asset Harvesting:** The service is redundant, the technology is obsolete, or the business need has vanished.

---

## 5. Cost Analysis

* **Cloud Spend:** Monthly cost trend.
* **Efficiency Opportunity:** Can we downsize instances or move to a more efficient storage tier based on actual usage?

---

## 6. Action Items

1. [Action 1: e.g., Patch Spring Boot to v3.x]
2. [Action 2: e.g., Decommission v1 API by end of next month]
3. [Action 3: e.g., Update HLSO to reflect new Kafka integration]

---

### QAR Outcome

**Decision:** [Proceed / Refactor / Harvest]

**Next Review Date:** [YYYY-MM-DD]

---

