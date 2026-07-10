---

title: Appendix G
section: G.10.2
subtitle: "Master Scenario Events List (MSEL) – Phase 1: Weak Signals"
description: Operational MSEL for the opening phase of Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0

---

# G.10.2 Master Scenario Events List (MSEL)

## Phase 1 – Weak Signals

> *"The first indicators of a significant cyber incident rarely appear significant in isolation."*

---

# Phase Overview

The opening phase introduces participants to a series of seemingly unrelated operational events. Each event appears plausible on its own and does not immediately justify a major incident response.

The learning objective is to encourage participants to:

* Gather evidence before drawing conclusions.
* Correlate information from multiple sources.
* Validate assumptions.
* Discuss escalation thresholds.
* Coordinate across technical and business teams.
* Recognize that small anomalies can collectively indicate a larger compromise.

Facilitators should resist the temptation to confirm participant suspicions too early. Productive uncertainty is a key feature of this phase.

---

# Phase Objectives

By the end of Phase 1, participants should have:

* Identified that multiple low-confidence alerts may be related.
* Initiated basic triage activities.
* Considered whether vendor access requires verification.
* Begun discussing escalation criteria.
* Recognized that additional investigation is necessary.

Formal incident declaration is **not** expected during the earliest injects, although some organizations may choose to escalate sooner based on their own procedures.

---

# Phase Timeline

| Exercise Time | Inject Range             | Focus                                                                       |
| ------------- | ------------------------ | --------------------------------------------------------------------------- |
| T+00 to T+40  | RH-INJ-001 to RH-INJ-010 | Weak signals, initial investigation, correlation, and escalation discussion |

---

# RH-INJ-001 — Suspicious Vendor Login

| Field              | Details                                 |
| ------------------ | --------------------------------------- |
| Time               | T+00                                    |
| Delivery           | SIEM Alert                              |
| Audience           | SOC Analysts                            |
| Artifact           | ART-001                                 |
| Learning Objective | Detect unusual authentication activity. |

### Inject Content

The SOC receives an automated alert indicating that a trusted maintenance vendor has successfully authenticated through the corporate VPN after several failed login attempts. The session originates from an unfamiliar geographic location and is associated with a previously unseen device fingerprint.

### Expected Discussion

* Is the alert credible?
* Could this represent legitimate travel?
* Should the vendor be contacted?
* What additional logs should be reviewed?

### Expected Actions

* Validate authentication records.
* Compare against previous vendor activity.
* Review recent maintenance schedules.
* Begin documenting observations.

### Facilitator Notes

Avoid confirming that the account is compromised. Participants should investigate rather than assume malicious intent.

### Observer Focus

* Evidence gathering.
* Avoidance of confirmation bias.
* Initial collaboration between SOC and Identity teams.

### Branching

If participants immediately disable the account, note the decision and prepare to adjust later injects concerning business impact.

---

# RH-INJ-002 — Help Desk Verification Call

| Field    | Details          |
| -------- | ---------------- |
| Time     | T+05             |
| Delivery | Help Desk Ticket |
| Audience | IT Operations    |
| Artifact | ART-002          |

### Inject Content

The help desk receives a call from an individual claiming to represent the maintenance vendor. The caller states that they were instructed to install remote access software but cannot verify who requested it.

### Expected Discussion

* Does the request align with approved maintenance procedures?
* Should the caller's identity be verified?
* Is this connected to the earlier login anomaly?

### Expected Actions

* Verify the caller using approved vendor contact channels.
* Record the interaction.
* Notify the SOC if appropriate.

### Facilitator Notes

If participants attempt to trust the caller without verification, allow the discussion to continue naturally before introducing additional evidence.

### Observer Focus

* Vendor management practices.
* Verification processes.
* Communication between IT Operations and Security.

---

# RH-INJ-003 — Endpoint Detection Alert

| Field    | Details          |
| -------- | ---------------- |
| Time     | T+10             |
| Delivery | EDR Notification |
| Audience | SOC Analysts     |
| Artifact | ART-003          |

### Inject Content

An endpoint associated with the vendor session generates a low-confidence alert indicating unusual PowerShell activity. The activity is not blocked because it resembles legitimate administrative tooling.

### Expected Discussion

* Is this administrative maintenance?
* Should the endpoint be isolated?
* What contextual information is missing?

### Expected Actions

* Review endpoint telemetry.
* Correlate with authentication events.
* Determine asset ownership.

### Facilitator Notes

Do not imply that PowerShell use is inherently malicious. Encourage participants to seek context before acting.

### Observer Focus

* Correlation of independent alerts.
* Evidence-based decision-making.

---

# RH-INJ-004 — Internal Network Scan

| Field    | Details                    |
| -------- | -------------------------- |
| Time     | T+15                       |
| Delivery | Network Detection Alert    |
| Audience | SOC and Network Operations |
| Artifact | ART-007                    |

### Inject Content

Network monitoring identifies service enumeration activity originating from a workstation associated with the vendor session. The activity targets administrative services across several adjacent subnets.

### Expected Discussion

* Is this normal vendor behaviour?
* Does the scan require immediate containment?
* Which systems should be reviewed next?

### Expected Actions

* Identify affected assets.
* Review firewall and authentication logs.
* Inform the Incident Response lead of emerging concerns.

### Facilitator Notes

This is the first inject intended to encourage participants to correlate events rather than investigate them independently.

### Observer Focus

* Pattern recognition.
* Escalation discussions.
* Cross-team coordination.

---

# RH-INJ-005 — Vendor Maintenance Schedule Review

| Field    | Details                   |
| -------- | ------------------------- |
| Time     | T+20                      |
| Delivery | Internal Operations Email |
| Audience | IT Operations             |
| Artifact | Internal Reference        |

### Inject Content

A review of the maintenance calendar indicates that no vendor work was scheduled during the period in question.

### Expected Discussion

* Does this increase confidence that the activity is suspicious?
* Who should be informed?
* Are existing escalation thresholds met?

### Expected Actions

* Update incident notes.
* Contact vendor management.
* Review additional historical activity.

### Facilitator Notes

Allow participants to decide whether the absence of scheduled work is sufficient to trigger formal escalation.

### Observer Focus

* Use of business context.
* Escalation rationale.
* Risk assessment.

---

# RH-INJ-006 — Identity Team Review

| Field    | Details                      |
| -------- | ---------------------------- |
| Time     | T+25                         |
| Delivery | Internal Briefing            |
| Audience | Identity & Access Management |

### Inject Content

The Identity team confirms that multifactor authentication was successfully completed using the vendor account. No policy violations are immediately apparent.

### Expected Discussion

* Does successful MFA eliminate the possibility of compromise?
* Could session theft or MFA fatigue be involved?
* What additional authentication evidence is needed?

### Expected Actions

* Examine MFA logs.
* Review device registration.
* Investigate impossible travel indicators.

### Facilitator Notes

Encourage participants to avoid assuming that MFA guarantees legitimacy.

### Observer Focus

* Understanding of identity-based attacks.
* Analytical reasoning.

---

# RH-INJ-007 — Executive Inquiry

| Field    | Details                |
| -------- | ---------------------- |
| Time     | T+30                   |
| Delivery | Executive Email        |
| Audience | Incident Response Lead |

### Inject Content

A senior executive notices increased security team activity and requests a brief explanation, asking whether there is any operational risk.

### Expected Discussion

* What can be communicated confidently?
* Should leadership be informed at this stage?
* How should uncertainty be expressed?

### Expected Actions

* Prepare a concise status update.
* Clearly distinguish facts from assumptions.
* Recommend next investigative steps.

### Facilitator Notes

This inject tests communication under uncertainty rather than technical analysis.

### Observer Focus

* Executive communication.
* Clarity of messaging.
* Transparency.

---

# RH-INJ-008 — Vendor Response

| Field    | Details           |
| -------- | ----------------- |
| Time     | T+35              |
| Delivery | Email             |
| Audience | Vendor Management |
| Artifact | ART-004           |

### Inject Content

The vendor confirms that one of its support accounts is under internal investigation for suspicious activity but cannot yet determine whether customer environments have been affected.

### Expected Discussion

* Should vendor access be suspended?
* What contractual obligations apply?
* Does this justify formal incident activation?

### Expected Actions

* Coordinate with Legal and Procurement if appropriate.
* Review third-party access.
* Reassess containment options.

### Facilitator Notes

This is the strongest indicator so far but still stops short of confirming enterprise compromise.

### Observer Focus

* Third-party risk management.
* Cross-functional decision-making.

---

# RH-INJ-009 — Correlation Meeting

| Field    | Details                |
| -------- | ---------------------- |
| Time     | T+38                   |
| Delivery | Facilitated Discussion |
| Audience | All Participants       |

### Inject Content

The facilitator pauses inject delivery briefly and asks participants to summarize what they currently know, what remains uncertain, and what actions they recommend.

### Facilitator Questions

* What facts have been confirmed?
* Which assumptions require validation?
* Has the escalation threshold been reached?
* Which business functions should now be engaged?

### Observer Focus

* Shared situational awareness.
* Information synthesis.
* Decision quality.

---

# RH-INJ-010 — Transition to Investigation

| Field    | Details             |
| -------- | ------------------- |
| Time     | T+40                |
| Delivery | White Cell Briefing |
| Audience | All Participants    |

### Inject Content

The White Cell confirms that additional evidence has become available and advises participants that the investigation is entering a new stage. The exercise now transitions into **Phase 2 – Investigation**.

No further details are provided until the first Phase 2 inject.

---

# Phase 1 Facilitator Review

Before progressing to Phase 2, confirm that participants have:

* Correlated multiple indicators.
* Discussed escalation thresholds.
* Considered third-party risk.
* Engaged relevant stakeholders.
* Documented assumptions.
* Identified key information gaps.

If these objectives have not been met, consider extending Phase 1 with additional questioning before introducing more conclusive evidence.

---

# Transition to Phase 2

Phase 2 shifts from isolated anomalies to a structured investigation. Participants begin receiving stronger indicators of compromise, prompting formal incident response considerations, deeper technical analysis, and broader business engagement.

The focus moves from **"Could something be wrong?"** to **"What exactly is happening, and how should we respond?"**
