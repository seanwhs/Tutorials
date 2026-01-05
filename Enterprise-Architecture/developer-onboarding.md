# Developer Onboarding: Master the Enterprise Architecture

Welcome. In an ecosystem of **50+ applications**, your role shifts from building siloed features to managing **Distributed Complexity**. This path leverages our existing [Enterprise Architecture framework](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture) to help you scale systems reliably.

---

## 1. The Strategy & Lifecycle (Week 1)
Start here to understand how we bridge the gap between business intent and technical execution.

* **Strategic Scenarios:** Learn how we categorize initiatives (Defensive, Proactive, Aggressive) to determine technical investment.
    * *Reference:* [Strategic Scenarios & Archetypes](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture#1-strategic-scenarios)
* **The EA Lifecycle:** Master the four phases of delivery—from Strategic Planning to Asset Harvesting.
    * *Reference:* [EA Delivery Lifecycle](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture#2-enterprise-architecture-lifecycle)
* **Initiation Process:** Understand how new projects are assessed before they reach the "Build" phase.
    * *Reference:* [The Initiation Process](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture#3-initiation-process)

---

## 2. Technical Decisions & Options (Week 2)
Learn how we make "Build vs. Buy" decisions and apply consistent technical patterns across the fleet.

* **Options Assessment:** We prioritize **Reuse** and **Buying** before committing to **Building**. 
    * *Reference:* [Build vs Buy Framework](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture#4-options-assessment)
* **Distributed Consistency:** Master the **Saga Pattern** and **Transactional Outbox** for cross-service transactions.
    * *Reference:* [New Guide: Distributed Consistency Blueprints](./blueprints/distributed-consistency.md)
* **API Governance:** Learn how we evolve contracts using the **Expand and Contract** pattern.
    * *Reference:* [New Guide: API Versioning & Deprecation](./governance/api-versioning-policy.md)

---

## 3. Operations & Reliability (Week 3)
"You Build It, You Run It." Master the tools that keep our 50+ apps alive.

* **Observability:** Use `trace_id` correlation to debug requests spanning multiple services.
    * *Reference:* [New Guide: Logging & Observability Standard](./governance/logging-and-observability-standard.md)
* **Resiliency:** Understand how we use the **Service Mesh** for automated retries and circuit breaking.
    * *Reference:* [New Guide: Service Mesh Traffic Policy](./governance/service-mesh-traffic-policy.md)
* **The Runbook:** Familiarize yourself with our mandatory incident response procedures.
    * *Reference:* [Template: Service Runbook](./templates/service-runbook-template.md)

---

## 4. Your First Task: "Golden Path" Implementation
To complete onboarding, you will set up a local environment using our standard scaffold and implement a **Transactional Outbox** flow.

* **Action:** Follow the [Golden Path Local Scaffold](./templates/golden-path-environment/README.md).

---

### Recommended Learning

**Saga Pattern in Microservices** Visual deep-dive into distributed transactions and coordination strategies:  
[https://www.youtube.com/watch?v=7xred44h4s0](https://www.youtube.com/watch?v=7xred44h4s0)
