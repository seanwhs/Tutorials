---

title: Appendix G
section: G.10.4
subtitle: "Master Scenario Events List (MSEL) – Phase 3: Escalation"
description: Operational MSEL for the escalation phase of Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0
---

# G.10.4 Master Scenario Events List (MSEL)

## Phase 3 – Escalation

> *"The declaration of an incident is not the end of the investigation—it is the beginning of organizational decision-making."*

---

# Phase Overview

By the start of Phase 3, participants have accumulated sufficient evidence to conclude that the organization is responding to a credible cybersecurity incident.

The technical investigation continues, but it is no longer the dominant activity.

Attention now shifts toward:

* Enterprise governance.
* Executive leadership.
* Incident command.
* Containment strategy.
* Business continuity.
* Cross-functional coordination.
* Communication planning.

The objective is to determine whether participants can transition smoothly from technical analysis to coordinated organizational response.

---

# Phase Objectives

By the end of this phase, participants should have:

* Formally activated the Incident Response Team (IRT).
* Established an incident command structure.
* Briefed executive leadership.
* Identified critical business priorities.
* Evaluated containment options.
* Considered operational impacts.
* Assigned clear ownership for key decisions.

---

# Phase Timeline

| Exercise Time | Inject Range             | Focus                                                                                   |
| ------------- | ------------------------ | --------------------------------------------------------------------------------------- |
| T+90 to T+130 | RH-INJ-021 to RH-INJ-030 | Incident declaration, governance activation, containment planning, executive engagement |

---

# RH-INJ-021 — Incident Declared

| Field    | Details                               |
| -------- | ------------------------------------- |
| Time     | T+90                                  |
| Delivery | Facilitator Announcement              |
| Audience | All Participants                      |
| Artifact | ART-014 – Incident Declaration Notice |

### Inject Content

Following review of the accumulated evidence, the Incident Response Team formally declares a cybersecurity incident. An incident commander is appointed, and the organization's incident management process is activated.

### Expected Discussion

* Who assumes command?
* How will decisions be documented?
* What reporting cadence is required?

### Expected Actions

* Confirm command structure.
* Establish communication channels.
* Begin formal incident documentation.

### Facilitator Notes

If participants have already declared an incident during Phase 2, present this inject as confirmation of executive endorsement.

### Observer Focus

* Governance activation.
* Clarity of roles.
* Incident command effectiveness.

---

# RH-INJ-022 — Manufacturing Leadership Joins

| Field    | Details                                      |
| -------- | -------------------------------------------- |
| Time     | T+95                                         |
| Delivery | Executive Briefing                           |
| Audience | Incident Commander, Manufacturing Operations |
| Artifact | ART-015 – Manufacturing Operations Status    |

### Inject Content

The Head of Manufacturing joins the response meeting and asks whether production should continue. No production impact has yet been observed, but concern is growing regarding potential operational disruption.

### Expected Discussion

* Should manufacturing continue?
* What evidence supports the recommendation?
* What are the risks of acting too early—or too late?

### Expected Actions

* Identify critical manufacturing systems.
* Assess operational dependencies.
* Develop decision criteria for production shutdown.

### Facilitator Notes

Avoid presenting shutdown as the obvious choice. Encourage balanced consideration of cyber risk and operational continuity.

### Observer Focus

* Business continuity planning.
* Risk communication.
* Executive collaboration.

---

# RH-INJ-023 — Potential Lateral Movement Confirmed

| Field    | Details                           |
| -------- | --------------------------------- |
| Time     | T+100                             |
| Delivery | Threat Hunting Report             |
| Audience | SOC, Incident Response            |
| Artifact | ART-016 – Threat Hunting Findings |

### Inject Content

Threat hunters identify evidence that the attacker accessed additional systems beyond the original vendor endpoint. Several administrative credentials appear to have been used across multiple network segments.

### Expected Discussion

* Has containment failed?
* Which systems require immediate attention?
* Is additional monitoring sufficient?

### Expected Actions

* Expand containment planning.
* Prioritize critical assets.
* Consider credential rotation.

### Facilitator Notes

Participants should recognize that the incident is broader than initially believed, but avoid implying complete loss of control.

### Observer Focus

* Adaptability.
* Prioritization.
* Containment strategy.

---

# RH-INJ-024 — Procurement Advisory

| Field    | Details                  |
| -------- | ------------------------ |
| Time     | T+105                    |
| Delivery | Procurement Update       |
| Audience | Vendor Management, Legal |

### Inject Content

Procurement confirms that the compromised vendor supports several production systems and has contractual obligations related to emergency maintenance.

Suspending all access may delay critical maintenance activities.

### Expected Discussion

* How should contractual obligations influence technical decisions?
* Can access be restricted rather than fully revoked?
* Who authorizes changes?

### Expected Actions

* Review contractual requirements.
* Coordinate with Legal.
* Evaluate compensating controls.

### Facilitator Notes

Introduce tension between operational necessity and security.

### Observer Focus

* Cross-functional governance.
* Vendor risk management.

---

# RH-INJ-025 — Executive Decision Point

| Field    | Details                       |
| -------- | ----------------------------- |
| Time     | T+110                         |
| Delivery | Facilitated Executive Meeting |
| Audience | Executive Leadership          |

### Inject Content

The CEO requests a recommendation regarding containment.

Three broad options are presented:

1. Continue monitoring while gathering additional evidence.
2. Restrict vendor access and increase monitoring.
3. Immediately isolate affected systems.

### Facilitator Questions

* Which option best balances operational continuity and cybersecurity risk?
* What assumptions support the recommendation?
* What are the consequences if the assessment is incorrect?

### Observer Focus

* Executive decision-making.
* Risk appetite.
* Decision rationale.

---

# RH-INJ-026 — Corporate Communications Alert

| Field    | Details                              |
| -------- | ------------------------------------ |
| Time     | T+115                                |
| Delivery | Communications Team Update           |
| Audience | Executive Leadership, Communications |
| Artifact | ART-017 – Holding Statement Draft    |

### Inject Content

Corporate Communications requests guidance on whether a draft internal communication should be prepared in anticipation of employee questions.

### Expected Discussion

* Should employees be informed now?
* What information can be shared safely?
* How should uncertainty be communicated?

### Expected Actions

* Develop key messaging.
* Coordinate with HR and Legal.
* Approve communication ownership.

### Facilitator Notes

The goal is to examine communication governance—not public relations expertise.

### Observer Focus

* Internal communications.
* Message consistency.

---

# RH-INJ-027 — Security Operations Update

| Field    | Details                |
| -------- | ---------------------- |
| Time     | T+120                  |
| Delivery | SOC Briefing           |
| Audience | Incident Response Team |

### Inject Content

The SOC reports increased authentication failures involving privileged accounts. No successful compromise has yet been confirmed.

### Expected Discussion

* Is this attacker persistence?
* Should privileged credentials be reset?
* What business disruption could result?

### Expected Actions

* Assess credential protection measures.
* Consider emergency password resets.
* Evaluate operational impact.

### Facilitator Notes

The inject introduces urgency without confirming attacker success.

### Observer Focus

* Prioritization.
* Identity security decisions.

---

# RH-INJ-028 — Board Notification Request

| Field    | Details              |
| -------- | -------------------- |
| Time     | T+125                |
| Delivery | CEO Request          |
| Audience | Executive Leadership |

### Inject Content

The CEO asks whether the Board of Directors should be notified at this stage and requests a recommendation.

### Expected Discussion

* What threshold triggers board notification?
* What information should be provided?
* Who delivers the briefing?

### Expected Actions

* Recommend board engagement.
* Prepare executive summary.
* Identify unresolved questions.

### Facilitator Notes

Encourage governance discussion rather than focusing solely on technical evidence.

### Observer Focus

* Executive governance.
* Strategic communication.

---

# RH-INJ-029 — Situation Review

| Field    | Details                |
| -------- | ---------------------- |
| Time     | T+128                  |
| Delivery | Facilitated Discussion |
| Audience | All Participants       |

### Inject Content

The facilitator pauses new injects and asks participants to review:

* Current incident status.
* Key risks.
* Immediate priorities.
* Pending executive decisions.
* Outstanding technical uncertainties.

### Observer Focus

* Shared situational awareness.
* Decision quality.
* Leadership effectiveness.

---

# RH-INJ-030 — Transition to Business Impact

| Field    | Details             |
| -------- | ------------------- |
| Time     | T+130               |
| Delivery | White Cell Briefing |
| Audience | All Participants    |

### Inject Content

The White Cell advises that conditions have changed.

Although containment activities continue, new reports indicate that operational business services are beginning to experience measurable disruption.

The exercise now transitions into **Phase 4 – Business Impact**, where technical response must be balanced against manufacturing continuity, customer commitments, financial considerations, and organizational resilience.

---

# Phase 3 Facilitator Review

Before progressing, confirm that participants have:

* Established an incident command structure.
* Assigned decision ownership.
* Briefed executive leadership.
* Considered containment strategies.
* Discussed manufacturing implications.
* Coordinated with Legal, Procurement, Communications, and HR.
* Documented strategic decisions and assumptions.

If governance remains unclear, use targeted facilitator questions before advancing.

---

# Key Learning Outcomes

Phase 3 reinforces that successful incident response depends on governance as much as technology.

Participants should recognize that:

* Incident command must be clearly established.
* Executive leaders require concise, actionable information.
* Containment decisions carry business consequences.
* Vendor risk extends beyond technical controls.
* Communication planning begins well before public disclosure.
* Decision-making under uncertainty is an essential leadership capability.

---

# Transition to Phase 4

With governance established and executive leadership engaged, the incident begins to affect day-to-day operations.

Phase 4 introduces tangible business disruption. Manufacturing performance degrades, customer-facing services become unstable, and the pressure to restore normal operations intensifies.

Participants must now balance competing priorities:

* Protect critical assets.
* Maintain production.
* Support customers.
* Preserve organizational trust.
* Prepare for potential regulatory and public scrutiny.

The discussion shifts from **"How do we contain the incident?"** to **"How do we keep the business operating while responding effectively?"**
