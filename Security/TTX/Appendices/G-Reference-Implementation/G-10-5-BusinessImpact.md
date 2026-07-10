---

title: Appendix G
section: G.10.5
subtitle: "Master Scenario Events List (MSEL) – Phase 4: Business Impact"
description: Operational MSEL for the business impact phase of Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0
---

# G.10.5 Master Scenario Events List (MSEL)

## Phase 4 – Business Impact

> *"A cyber incident becomes an enterprise crisis when technical decisions begin to affect business operations."*

---

# Phase Overview

Containment efforts are underway, but the incident is now affecting normal business operations. While the technical investigation continues, operational leaders are increasingly concerned about manufacturing continuity, customer commitments, supplier relationships, and financial performance.

The objective of this phase is to assess how well participants balance cybersecurity, safety, operational resilience, regulatory obligations, and commercial priorities.

The White Cell should increase the pace of injects slightly while ensuring that participants have sufficient time to discuss major decisions.

---

# Phase Objectives

By the conclusion of Phase 4, participants should have:

* Evaluated the impact on critical business processes.
* Prioritized business services for protection and recovery.
* Balanced containment actions against operational continuity.
* Coordinated across IT, OT, Manufacturing, Finance, Supply Chain, Customer Service, and Executive Leadership.
* Established clear priorities for the next operational period.

---

# Phase Timeline

| Exercise Time  | Inject Range             | Focus                                                                                                          |
| -------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------- |
| T+135 to T+175 | RH-INJ-031 to RH-INJ-040 | Manufacturing disruption, supply chain, customer commitments, business continuity, operational decision-making |

---

# RH-INJ-031 — Manufacturing Performance Degradation

| Field    | Details                                      |
| -------- | -------------------------------------------- |
| Time     | T+135                                        |
| Delivery | Operations Dashboard Alert                   |
| Audience | Manufacturing Operations, Incident Commander |
| Artifact | ART-018 – Production Performance Dashboard   |

### Inject Content

Plant managers report intermittent delays in receiving production schedules from the Manufacturing Execution System (MES). Production has not stopped, but several work orders are arriving later than expected.

### Expected Discussion

* Is the issue operational, technical, or cyber-related?
* Can production continue safely?
* What additional information is required?

### Expected Actions

* Confirm whether OT systems are directly affected.
* Engage Manufacturing and OT engineering.
* Assess production risk.

### Facilitator Notes

Avoid confirming a compromise of OT systems. Participants should distinguish between degraded business processes and confirmed operational technology compromise.

### Observer Focus

* Cross-functional collaboration.
* Risk assessment under uncertainty.

---

# RH-INJ-032 — Customer Order Delays

| Field    | Details                                              |
| -------- | ---------------------------------------------------- |
| Time     | T+140                                                |
| Delivery | Customer Service Escalation                          |
| Audience | Customer Service, Supply Chain, Executive Leadership |
| Artifact | ART-019 – Customer Escalation Report                 |

### Inject Content

Customer Service reports that several strategic customers are requesting confirmation that planned deliveries will not be affected.

### Expected Discussion

* What commitments can be made?
* Should customers be informed of the incident?
* How should expectations be managed?

### Expected Actions

* Coordinate with Sales and Communications.
* Review customer notification criteria.
* Develop a holding response.

### Observer Focus

* Customer communication.
* Commercial risk management.

---

# RH-INJ-033 — ERP Transaction Failures

| Field    | Details                      |
| -------- | ---------------------------- |
| Time     | T+145                        |
| Delivery | ERP Operations Alert         |
| Audience | Finance, IT Operations       |
| Artifact | ART-020 – ERP Service Status |

### Inject Content

Users report intermittent failures when processing purchase orders and inventory updates. No data corruption has been confirmed, but transaction latency is increasing.

### Expected Discussion

* Can financial operations continue?
* Should ERP services be restricted?
* How does this affect procurement and inventory?

### Expected Actions

* Prioritize ERP stability.
* Identify manual workarounds.
* Assess downstream business impacts.

### Facilitator Notes

This inject highlights the dependency between cybersecurity response and enterprise resource planning.

### Observer Focus

* Business continuity planning.
* Operational prioritization.

---

# RH-INJ-034 — OT Isolation Proposal

| Field    | Details                                           |
| -------- | ------------------------------------------------- |
| Time     | T+150                                             |
| Delivery | Technical Advisory                                |
| Audience | OT Engineering, Manufacturing, Incident Commander |
| Artifact | ART-021 – Network Segmentation Recommendation     |

### Inject Content

The security architecture team recommends temporarily isolating the OT network from corporate IT until the extent of the compromise is understood.

Manufacturing advises that isolation may interrupt production scheduling and quality reporting.

### Expected Discussion

* Does the benefit outweigh the operational cost?
* Are there alternative containment measures?
* Who has authority to approve isolation?

### Expected Actions

* Evaluate operational risk.
* Consider phased isolation.
* Document executive approval.

### Facilitator Notes

There is no single correct answer. The discussion is more important than the decision itself.

### Observer Focus

* Executive governance.
* Balancing cyber risk and operational continuity.

---

# RH-INJ-035 — Supplier Escalation

| Field    | Details                                |
| -------- | -------------------------------------- |
| Time     | T+155                                  |
| Delivery | Supplier Relationship Manager Briefing |
| Audience | Procurement, Supply Chain              |

### Inject Content

A major supplier requests confirmation that electronic purchase orders remain trustworthy before dispatching high-value materials.

### Expected Discussion

* Can procurement systems be trusted?
* Should manual verification be introduced?
* What financial risks exist?

### Expected Actions

* Validate procurement processes.
* Coordinate with Finance.
* Implement compensating controls if necessary.

### Observer Focus

* Supply chain resilience.
* Vendor coordination.

---

# RH-INJ-036 — Finance Concern

| Field    | Details              |
| -------- | -------------------- |
| Time     | T+160                |
| Delivery | CFO Briefing Request |
| Audience | Executive Leadership |

### Inject Content

The Chief Financial Officer requests an estimate of:

* Financial exposure.
* Potential production losses.
* Customer penalties.
* Recovery costs.

### Expected Discussion

* What information is available?
* What assumptions underpin the estimate?
* How should uncertainty be communicated?

### Expected Actions

* Develop preliminary impact estimates.
* Clearly state confidence levels.
* Identify information gaps.

### Observer Focus

* Executive reporting.
* Financial risk communication.

---

# RH-INJ-037 — Human Resources Inquiry

| Field    | Details            |
| -------- | ------------------ |
| Time     | T+165              |
| Delivery | HR Notification    |
| Audience | HR, Communications |

### Inject Content

Employees have begun discussing the incident internally. HR asks whether an employee communication should be distributed to reduce speculation and misinformation.

### Expected Discussion

* What should employees know?
* How should rumours be addressed?
* Should managers receive additional guidance?

### Expected Actions

* Draft an internal communication.
* Coordinate with Communications.
* Reinforce reporting procedures.

### Observer Focus

* Internal communication strategy.
* Organizational trust.

---

# RH-INJ-038 — Business Continuity Review

| Field    | Details                                        |
| -------- | ---------------------------------------------- |
| Time     | T+170                                          |
| Delivery | Facilitated Business Continuity Meeting        |
| Audience | Executive Leadership, Business Continuity Team |

### Inject Content

The Incident Commander requests confirmation of business priorities for the next operational period.

Participants are asked to rank:

* Safety.
* Manufacturing.
* Customer commitments.
* Financial operations.
* IT restoration.
* Forensic preservation.

### Observer Focus

* Prioritization.
* Leadership alignment.
* Decision rationale.

---

# RH-INJ-039 — Executive Situation Assessment

| Field    | Details                |
| -------- | ---------------------- |
| Time     | T+173                  |
| Delivery | Facilitated Discussion |
| Audience | Executive Leadership   |

### Facilitator Questions

* What is the greatest current business risk?
* Which decisions cannot be delayed?
* Which stakeholders require immediate updates?
* What assumptions remain unverified?

### Observer Focus

* Executive decision-making.
* Shared situational awareness.
* Strategic thinking.

---

# RH-INJ-040 — Transition to Crisis Management

| Field    | Details             |
| -------- | ------------------- |
| Time     | T+175               |
| Delivery | White Cell Briefing |
| Audience | All Participants    |

### Inject Content

The White Cell informs participants that news of the incident has begun to spread beyond the organization. Media enquiries are expected, industry partners are requesting updates, and senior leadership anticipates external scrutiny.

The exercise now transitions into **Phase 5 – Crisis Management**.

---

# Phase 4 Facilitator Review

Before advancing, confirm that participants have:

* Assessed impacts on manufacturing and operations.
* Considered customer and supplier implications.
* Discussed business continuity strategies.
* Balanced operational resilience with cybersecurity objectives.
* Engaged Finance, HR, Procurement, Manufacturing, and Communications.
* Prioritized business services for ongoing protection and recovery.

If operational priorities remain unclear, use additional discussion to establish a common understanding before introducing external pressures.

---

# Key Learning Outcomes

Phase 4 demonstrates that cyber incidents quickly evolve into enterprise resilience challenges.

Participants should recognize that:

* Cybersecurity decisions have operational consequences.
* Manufacturing and OT environments require coordinated IT and business decision-making.
* Customer confidence depends on timely, accurate communication.
* Supply chain resilience extends beyond technology.
* Business continuity planning must be integrated with incident response.
* Executive leadership must continuously balance competing priorities under uncertainty.

---

# Transition to Phase 5

The organization is now managing both the technical aspects of the incident and its operational consequences.

In Phase 5, the focus expands beyond internal stakeholders. Media outlets, customers, regulators, industry partners, and the Board begin demanding answers.

Participants must demonstrate disciplined crisis leadership, coordinated communications, and strategic decision-making while the technical response continues in the background.

The central question becomes:

**"How do we preserve trust while managing an evolving cyber crisis?"**
