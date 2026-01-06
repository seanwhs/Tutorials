# Developer Onboarding: The Enterprise Architecture Path

Welcome to the team. In an ecosystem of **50+ applications**, we do not build in isolation. Every technical decision must align with our **Enterprise Architecture (EA) Lifecycle**. This guide ensures our growth remains governed as we move from a business "Need" to a long-term "Asset."

---

## Phase 1: Strategic Alignment & Archetypes (Week 1)

Before designing, you must understand the **Strategic Scenario** and the **Archetype** assigned to the initiative. This determines the "License to Operate" and the technical rigor required.

* **Strategic Scenarios:** We evaluate the "Need" against three modes:
* **Defensive:** Focused on risk, compliance, and core stability.
* **Proactive:** Improving efficiency and scaling existing success.
* **Aggressive:** High-speed market disruption and new capability builds.


* **Architectural Archetypes:** These provide the blueprint for the solution's personality:
* **The Utility:** High efficiency, low cost, standard features (e.g., Internal HR tools).
* **The Scaler:** High availability, elastic performance (e.g., Customer-facing APIs).
* **The Pioneer:** Rapid experimentation, high flexibility, often ephemeral.


* **The EA Lifecycle:** Familiarize yourself with our 4-Phase flow:
1. **Strategic Planning:** Aligning the initiative with enterprise goals and archetypes.
2. **Initiative Delivery:** Building the solution following the "Golden Path."
3. **Asset Management:** Operating the service as a governed enterprise asset.
4. **Asset Harvesting:** Strategic decommissioning or reinvestment.



---

## Phase 2: Project Initiation & Decisioning (Week 2)

We follow a disciplined **Initiation Process** to ensure we maximize existing investments.

* **Options Assessment:** We follow a strict hierarchy for every new requirement:
1. **Reuse:** Can an existing application or service fulfill the need? (Check the Service Catalog).
2. **Buy:** Is there a COTS (Commercial Off-The-Shelf) solution or SaaS?
3. **Build:** Custom development is only justified if it provides a unique competitive advantage.


* **High-Level Solution Overview (HLSO):** For all "Build" or "Complex Integrate" projects, you must draft an HLSO. This documents integration points, data flows, and how the new service interacts with the other 50+ apps in the fleet.

---

## Phase 3: Technical Delivery & Patterns (Week 3)

During **Initiative Delivery**, we prioritize patterns that simplify **Asset Management**.

* **Distributed Consistency:** We prioritize **Transactional Outbox** and **Saga Patterns** to replace brittle distributed transactions with event-driven eventual consistency.
* **Zero-Downtime Evolution:** Use the **Expand and Contract** pattern for APIs and Database Schemas to prevent breaking downstream consumers.
* **Observability Standards:** Implementation of **Structured Logging (JSON)** and **Trace ID Propagation** is mandatory to track requests across the enterprise fabric.

---

## Phase 4: Governance & Reliability (Ongoing)

Once a service moves to **Asset Management**, the focus shifts to resilience and the "Golden Signals."

* **Service Mesh & Traffic Policy:** Offload retries, mTLS, and circuit breaking to Sidecars.
* **Reliability Metrics:** You are responsible for the **Latency, Traffic, Errors, and Saturation** of your asset.
* **Blameless Post-Mortems:** When an asset fails, use the **Five Whys** to identify systemic flaws and feed lessons back into the **Strategic Planning** phase.

---

## Your First Task: The Initiation Mock-up

To complete your onboarding, you will be given a sample business "Need." You must:

1. Identify the **Strategic Scenario** and recommend a target **Archetype**.
2. Perform a documented **Options Assessment** (proving why we shouldn't "Reuse" current tools).
3. Draft a **High-Level Solution Overview** (HLSO) mapping the data flow between your service and core enterprise stores.

---

### Reference Links (Internal)

* [Strategic Scenarios & Archetypes](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture#1-strategic-scenarios)
* [EA Lifecycle & Phase Breakdown](https://www.google.com/search?q=https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture%232-enterprise-architecture-lifecycle)
* [The Initiation Process](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture/Project-Initiation)
* [Options Assessment Framework](https://www.google.com/search?q=https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture%234-options-assessment)

