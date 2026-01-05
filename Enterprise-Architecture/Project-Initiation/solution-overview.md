# Template: Solution Overview (Initiation Phase)

**Project Name:** [Name]  
**Lead Architect:** [Name]  
**Strategic Archetype:** (Defensive / Aggressive / Proactive / Futurity)  
**Status:** Draft / Under Review / Approved  

---

## 1. Executive Summary
Provide a high-level summary of the business problem and the proposed technical response. 
*What is the primary driver? (e.g., Cost reduction, new market entry, legacy replacement)*

## 2. Options Assessment
Briefly explain why the "Build" path was chosen over "Reuse" or "Buy."
* **Existing Assets Considered:** (List services from the Catalog that were evaluated)
* **Market Solutions Evaluated:** (SaaS/COTS products considered)
* **Justification for Build:** (Why is this core domain logic?)

## 3. High-Level Conceptual Architecture
Describe the "big picture" placement of this service within the enterprise ecosystem. 



* **Entry Points:** (API Gateway, Event Consumers, Manual UI)
* **Downstream Dependencies:** (Which existing 50+ apps will this call?)
* **Data Ownership:** (What is the primary entity this service owns? e.g., "Customer Profile")

## 4. Architectural Patterns & Compliance
Check all that apply to this solution:
- [ ] **Golden Path:** Standard CI/CD and deployment.
- [ ] **Event-Driven:** Uses the Kafka Backbone for async communication.
- [ ] **Distributed Consistency:** Implements Saga Orchestration for multi-step flows.
- [ ] **Zero Trust:** mTLS and OPA policy enforced.



## 5. Risk & Friction Assessment
* **Known Technical Debt:** (What shortcuts are being taken to meet the strategic timeline?)
* **Friction Points:** (Where does the Golden Path not meet the needs of this project?)
* **Security Concerns:** (PII handling or high-risk data flows)

## 6. Infrastructure & Scalability
* **Estimated Traffic:** (Requests per second / Events per day)
* **Persistence Layer:** (Standard PostgreSQL / Specialized NoSQL / Cache)
* **Availability Target:** (Tier 0, 1, 2, or 3 per SLO Policy)

---

## 7. Review Board Notes
*(To be completed by the Architecture Review Board)*
* **Alignment Score:** [1-5]
* **Approved Deviations:** (List any accepted ADRs)
* **Follow-up Actions:**
