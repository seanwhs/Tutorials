# Service Readiness Checklist

This checklist acts as the final "Quality Gate" in your **EA Lifecycle**. It ensures that an **Initiative** has met all architectural standards before it is promoted to a production **Asset**.

---

## 1. Strategic & Design Alignment

*Confirming the foundation laid during the [Initiation Process](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture/Project-Initiation).*

* [ ] **HLSO Approved:** A High-Level Solution Overview has been reviewed and signed off by the EA team.
* [ ] **Archetype Adherence:** The service implementation matches its assigned Archetype (e.g., if it's a **Scaler**, it has been load-tested).
* [ ] **Options Assessment:** Documentation exists proving that **Reuse** and **Buy** were evaluated before the **Build** phase began.

---

## 2. Distributed Architecture (The Blueprints)

*Ensuring the service plays well within the 50+ app ecosystem.*

* [ ] **Consistency Pattern:** The service utilizes the **Transactional Outbox** or **Saga Pattern** for cross-service state changes.
* [ ] **Idempotency:** All event consumers can safely process the same message multiple times.
* [ ] **API Versioning:** The API follows the **Expand and Contract** pattern and includes major versioning in the URL.
* [ ] **N-1 Compatibility:** The application can successfully run and roll back against the previous database schema version.

---

## 3. Observability & Health

*Meeting the [Observability & Health Governance](https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture) requirements.*

* [ ] **Golden Signals:** A dashboard exists tracking **Latency, Traffic, Errors, and Saturation**.
* [ ] **Structured Logs:** Logs are emitted in **JSON** format with a mandatory `service_id`.
* [ ] **Trace Propagation:** The service correctly passes `trace_id` (W3C Traceparent) to all downstream dependencies.
* [ ] **Health Probes:** `/health/live` and `/health/ready` endpoints are correctly configured in the orchestrator.

---

## 4. Operational Resiliency

*Preparing the service for the [Asset Management](https://www.google.com/search?q=https://github.com/seanwhs/Tutorials/tree/main/Enterprise-Architecture%232-enterprise-architecture-lifecycle) phase.*

* [ ] **Service Runbook:** A `RUNBOOK.md` exists in the repo with clear "Panic Button" procedures.
* [ ] **Dependency Fallbacks:** Circuit breakers or retries are configured for all downstream calls.
* [ ] **Autoscaling:** HPA (Horizontal Pod Autoscaler) or equivalent is configured based on **Saturation** metrics.

---

## 5. Security & Compliance

* [ ] **Data Sovereignty:** The service stores PII in the designated regional cell.
* [ ] **Secret Management:** No credentials or API keys are hardcoded; all are fetched from the Enterprise Vault.
* [ ] **Identity:** Inter-service communication is secured via mTLS or the standard JWT/OPA sidecar.

---

## 6. Lifecycle Handover

* [ ] **Asset Owner Assigned:** A specific team and Slack channel are designated as the long-term owners.
* [ ] **Harvesting Plan:** An approximate "End of Life" or review date has been set to prevent future architectural rot.

---

### Certification of Readiness

Upon completion of this checklist, the **Initiative** is officially re-classified as an **Enterprise Asset** and moves into the **Asset Management** phase of the EA Lifecycle.

