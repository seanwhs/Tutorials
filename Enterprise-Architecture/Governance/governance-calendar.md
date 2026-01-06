# Governance Calendar

# The EA Governance Calendar

Managing **50+ applications** requires a predictable cadence. This calendar ensures we balance immediate "Needs" with long-term "Asset Health" and "Strategic Evolution."

---

## 1. Monthly: The Intake & Alignment Cycle

**Frequency:** First Monday of every month.

**Attendees:** EA Team, Lead Architects, Product Owners.

* **HLSO Review:** Approve or provide feedback on all High-Level Solution Overviews submitted in the previous month.
* **Archetype Validation:** Ensure new projects are correctly categorized (Utility/Scaler/Pioneer).
* **Policy Updates:** Review and merge any new **ADRs** (Architecture Decision Records) into the repository.

---

## 2. Quarterly: The Asset Health Cycle

**Frequency:** Third Wednesday of the first month of each quarter (Jan, April, July, Oct).

**Attendees:** EA Team, Stream-aligned Team Leads.

* **QAR Batch Review:** Deep-dive into 10–15 applications per quarter using the **QAR Template**.
* **Cost & Cloud Audit:** Review **IaC** resource spend against the **Strategic Scenarios**.
* **Harvesting Proposals:** Identify assets that have reached end-of-life and move them to the "Harvesting" phase.

---

## 3. Semi-Annually: The Resiliency Cycle

**Frequency:** March and September.

**Attendees:** Platform Team, SRE, Security.

* **DR Game Day:** Execute a controlled failover of a Tier 0 or Tier 1 asset to a secondary region.
* **Chaos Engineering:** Inject network latency or service failure to validate **Circuit Breaker** and **Saga** logic.
* **Security Perimeter Audit:** Review **Zero Trust** configurations and mTLS certificate health.

---

## 4. Annually: The Strategic Refresh

**Frequency:** Second week of January.

**Attendees:** C-Suite (CTO/CIO), EA Team, Business Stakeholders.

* **Scenario Realignment:** Do we still need to be **Aggressive** in this market, or should we move to a **Defensive** stance?
* **Capability Gap Analysis:** What capabilities are missing from our 50+ app fleet that require a new "Build" or "Buy" initiative?
* **Repository Cleanup:** Archive old blueprints and update the **Golden Path** standards for the new year.

---

## 5. Continuous: The Developer Feedback Loop

**Frequency:** Ongoing.

**Attendees:** Developers, Platform Team.

* **Golden Path Evolution:** As developers find friction in our **IaC Modules** or **Blueprints**, the standards are updated to reflect better practices.

---

### Summary of the EA Lifecycle Rythm

| Cycle | Goal | Primary Artifact |
| --- | --- | --- |
| **Monthly** | Govern "New Build" | Approved HLSO |
| **Quarterly** | Manage "Current Assets" | QAR Report |
| **Semi-Annual** | Prove Resiliency | Game Day Post-Mortem |
| **Annual** | Set the Vision | Strategic Scenario Update |

---

