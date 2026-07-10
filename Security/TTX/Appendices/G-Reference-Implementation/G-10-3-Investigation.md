---
title: Appendix G
section: G.10.3
subtitle: "Master Scenario Events List (MSEL) – Phase 2: Investigation"
description: Operational MSEL for the investigation phase of Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0
---

# G.10.3 Master Scenario Events List (MSEL)

## Phase 2 – Investigation

> *"Investigation is the bridge between suspicion and action. The quality of the response depends on the quality of the investigation."*

---

# Phase Overview

Phase 2 builds upon the weak signals established during the opening of the exercise. By this stage, participants have identified several related anomalies but have not yet confirmed the full scope or intent of the activity.

The purpose of this phase is to encourage participants to:

* Correlate evidence from multiple sources.
* Establish an initial incident hypothesis.
* Validate assumptions.
* Determine whether formal incident response should be activated.
* Expand collaboration beyond technical teams.
* Consider the business implications of emerging technical findings.

The White Cell should continue to introduce information gradually. Participants should feel increasing confidence that an incident is unfolding while still facing uncertainty about its scale and impact.

---

# Phase Objectives

By the conclusion of Phase 2, participants should have:

* Confirmed that the observed activity is unlikely to be routine.
* Identified multiple indicators consistent with an active compromise.
* Considered formal activation of the Incident Response Team (IRT).
* Begun notifying business stakeholders.
* Discussed initial containment options.
* Recognized the importance of preserving evidence while maintaining business operations.

---

# Phase Timeline

| Exercise Time | Inject Range             | Focus                                                                                              |
| ------------- | ------------------------ | -------------------------------------------------------------------------------------------------- |
| T+45 to T+85  | RH-INJ-011 to RH-INJ-020 | Evidence correlation, hypothesis development, incident declaration, and preparation for escalation |

---

# RH-INJ-011 — Privileged Access Review

| Field    | Details                             |
| -------- | ----------------------------------- |
| Time     | T+45                                |
| Delivery | Identity & Access Management Report |
| Audience | SOC, IAM, Incident Response         |
| Artifact | ART-009 – Privileged Access Summary |

### Inject Content

IAM reports that the compromised vendor account accessed administrative resources outside its normal support responsibilities. While access was technically permitted, the activity deviates from historical patterns.

### Expected Discussion

* Is the activity authorized?
* Has the principle of least privilege been violated?
* Should privileged sessions be terminated?

### Expected Actions

* Review privileged access logs.
* Identify affected systems.
* Assess whether emergency access controls should be implemented.

### Facilitator Notes

Participants may focus on technical controls. Encourage discussion about governance and privileged access management.

### Observer Focus

* Risk-based decision-making.
* Collaboration between Security and IAM.

### Branching

If vendor access was already disabled in Phase 1, present this inject as a retrospective review of recent activity.

---

# RH-INJ-012 — Endpoint Triage Results

| Field    | Details                                  |
| -------- | ---------------------------------------- |
| Time     | T+50                                     |
| Delivery | EDR Investigation Report                 |
| Audience | SOC and Incident Response                |
| Artifact | ART-010 – Endpoint Investigation Summary |

### Inject Content

Endpoint analysis reveals evidence of credential harvesting tools executed shortly after the vendor session began. No malware signatures are detected, but several suspicious administrative utilities were launched.

### Expected Discussion

* Does this confirm malicious activity?
* What additional evidence is required?
* Which endpoints should now be examined?

### Expected Actions

* Expand endpoint review.
* Preserve forensic evidence.
* Increase monitoring of privileged accounts.

### Facilitator Notes

Avoid allowing participants to assume that absence of malware means absence of compromise.

### Observer Focus

* Analytical reasoning.
* Evidence preservation.

---

# RH-INJ-013 — Network Traffic Anomaly

| Field    | Details                            |
| -------- | ---------------------------------- |
| Time     | T+55                               |
| Delivery | Network Monitoring Alert           |
| Audience | Network Operations, SOC            |
| Artifact | ART-011 – East-West Traffic Report |

### Inject Content

Network monitoring identifies sustained communication between systems that do not normally exchange data. Traffic volumes remain low but persistent.

### Expected Discussion

* Is lateral movement occurring?
* Which systems require closer inspection?
* Should network segmentation be considered?

### Expected Actions

* Map communication paths.
* Identify affected business systems.
* Evaluate network containment options.

### Facilitator Notes

The anomaly is intentionally subtle. Encourage participants to correlate it with previous findings rather than treating it as an isolated event.

### Observer Focus

* Correlation of technical evidence.
* Cross-functional analysis.

---

# RH-INJ-014 — Data Access Alert

| Field    | Details                             |
| -------- | ----------------------------------- |
| Time     | T+60                                |
| Delivery | File Access Monitoring Report       |
| Audience | Security, Data Governance           |
| Artifact | ART-012 – Sensitive File Access Log |

### Inject Content

Monitoring indicates that engineering documentation repositories were accessed outside standard maintenance windows. The volume of accessed files exceeds typical vendor activity.

### Expected Discussion

* Has sensitive information been exposed?
* What is the potential business impact?
* Should executive leadership be informed?

### Expected Actions

* Identify accessed repositories.
* Assess data sensitivity.
* Coordinate with Data Governance and Legal.

### Facilitator Notes

Participants may immediately assume data exfiltration. Remind them that access does not necessarily confirm theft.

### Observer Focus

* Business impact assessment.
* Engagement with non-technical stakeholders.

---

# RH-INJ-015 — Incident Declaration Decision

| Field    | Details                    |
| -------- | -------------------------- |
| Time     | T+65                       |
| Delivery | Facilitator Decision Point |
| Audience | All Participants           |

### Inject Content

The facilitator asks participants whether the available evidence justifies formally declaring a cybersecurity incident and activating the Incident Response Team.

### Facilitator Questions

* What criteria have been met?
* What risks exist if activation is delayed?
* What are the consequences of activating too early?

### Observer Focus

* Governance.
* Decision quality.
* Escalation timing.

---

# RH-INJ-016 — Vendor Security Update

| Field    | Details                               |
| -------- | ------------------------------------- |
| Time     | T+70                                  |
| Delivery | Vendor Security Advisory              |
| Audience | Vendor Management, Incident Response  |
| Artifact | ART-013 – Vendor Investigation Update |

### Inject Content

The vendor confirms that multiple customer environments may have been exposed through compromised support credentials. They recommend immediate review of all shared access.

### Expected Discussion

* Should all vendor access be suspended?
* What contractual obligations apply?
* How will operations be affected?

### Expected Actions

* Assess third-party risk.
* Coordinate with Procurement and Legal.
* Review emergency access procedures.

### Facilitator Notes

This inject significantly increases confidence that the compromise extends beyond ACME.

### Observer Focus

* Third-party governance.
* Business continuity considerations.

---

# RH-INJ-017 — Executive Briefing Request

| Field    | Details                   |
| -------- | ------------------------- |
| Time     | T+75                      |
| Delivery | Executive Meeting Request |
| Audience | Incident Response Lead    |

### Inject Content

The Chief Information Security Officer requests a five-minute briefing summarizing:

* Current facts.
* Key uncertainties.
* Recommended next steps.
* Immediate business risks.

### Expected Discussion

* What should be communicated?
* What should be deferred until confirmed?
* How should confidence levels be expressed?

### Expected Actions

* Prepare an executive summary.
* Separate confirmed facts from assumptions.
* Recommend a clear course of action.

### Facilitator Notes

Observe whether participants communicate in business language rather than technical jargon.

### Observer Focus

* Executive communication.
* Clarity.
* Confidence calibration.

---

# RH-INJ-018 — Legal Consultation

| Field    | Details                     |
| -------- | --------------------------- |
| Time     | T+80                        |
| Delivery | Legal Advisory              |
| Audience | Legal, Executive Leadership |

### Inject Content

Legal counsel advises that if customer information is confirmed to have been compromised, notification obligations may apply under contractual and regulatory requirements.

### Expected Discussion

* Is there sufficient evidence to begin notification planning?
* Who should be informed?
* What records should be preserved?

### Expected Actions

* Document legal considerations.
* Preserve evidence.
* Coordinate with Privacy and Communications.

### Facilitator Notes

The objective is to introduce governance considerations without requiring participants to perform legal analysis.

### Observer Focus

* Legal engagement.
* Cross-functional collaboration.

---

# RH-INJ-019 — Situation Assessment

| Field    | Details                |
| -------- | ---------------------- |
| Time     | T+83                   |
| Delivery | Facilitated Discussion |
| Audience | All Participants       |

### Inject Content

The facilitator pauses inject delivery and asks participants to summarize:

* What is now known?
* What remains uncertain?
* What decisions have been made?
* What decisions remain outstanding?

### Observer Focus

* Shared situational awareness.
* Information synthesis.
* Decision rationale.

---

# RH-INJ-020 — Transition to Escalation

| Field    | Details             |
| -------- | ------------------- |
| Time     | T+85                |
| Delivery | White Cell Briefing |
| Audience | All Participants    |

### Inject Content

The White Cell advises that new intelligence has been received indicating broader organizational implications. The exercise now transitions into **Phase 3 – Escalation**, where executive governance, coordinated containment, and enterprise decision-making become the primary focus.

No additional technical details are provided until the opening inject of Phase 3.

---

# Phase 2 Facilitator Review

Before progressing to Phase 3, confirm that participants have:

* Correlated technical evidence across multiple sources.
* Discussed whether formal incident response should be activated.
* Considered business implications of the compromise.
* Engaged executive leadership appropriately.
* Involved Legal, Procurement, and other relevant stakeholders.
* Documented assumptions, decisions, and unresolved questions.

If significant gaps remain, use clarifying questions or additional discussion before advancing the scenario.

---

# Transition to Phase 3

Phase 3 marks the transition from investigation to coordinated organizational response.

The compromise is no longer viewed as a collection of suspicious events. It is now treated as an active cybersecurity incident requiring enterprise governance, executive oversight, containment planning, and coordinated communication across the organization.

Participants shift from asking **"Is something happening?"** to **"How do we manage this incident while protecting the business?"**
