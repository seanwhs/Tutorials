# Appendix B — Templates Library

# Part 2.3 — Production Rules of Engagement (RoE) Template

> **Instructions:** Replace all placeholder values enclosed in square brackets (`[ ]`) with exercise-specific information before distributing this document. Remove any instructional notes that are not required for participants.

---

```yaml
---
title: Rules of Engagement
exercise: "[Exercise Name]"
scenario: "[Scenario Name]"
exercise_id: "[TTX-2026-001]"
type: roe
version: 1.0
status: Draft
classification: Internal Use
owner: "[Exercise Owner]"
sponsor: "[Executive Sponsor]"
lead_facilitator: "[Lead Facilitator]"
white_cell_lead: "[White Cell Lead]"
created: "[YYYY-MM-DD]"
last_updated: "[YYYY-MM-DD]"
exercise_date: "[YYYY-MM-DD]"
duration: "[4 Hours]"
maturity_level: "[L1|L2|L3|L4]"
tags:
  - ttx
  - cybersecurity
  - tabletop
---
```

---

# Rules of Engagement

## Document Control

| Field             | Value            |
| ----------------- | ---------------- |
| Exercise          | [Exercise Name]  |
| Scenario          | [Scenario Name]  |
| Exercise ID       | [TTX-2026-001]   |
| Version           | 1.0              |
| Classification    | Internal Use     |
| Owner             | [Exercise Owner] |
| Executive Sponsor | [Sponsor]        |
| Lead Facilitator  | [Facilitator]    |
| White Cell Lead   | [Name]           |

---

# Executive Summary

This document establishes the Rules of Engagement governing the execution of the **[Exercise Name]** cybersecurity tabletop exercise.

The Rules of Engagement define the objectives, governance, communication procedures, participant responsibilities, exercise boundaries, safety controls, and evaluation approach that will be followed throughout the exercise.

All participants are expected to review this document before the exercise begins.

---

# 1. Exercise Purpose

The purpose of this exercise is to:

* Validate the organization's Incident Response capability.
* Assess cross-functional coordination.
* Evaluate executive decision-making.
* Improve communication procedures.
* Identify opportunities for continuous improvement.

---

# 2. Exercise Objectives

The exercise objectives are:

* Validate incident detection procedures.
* Assess escalation workflows.
* Evaluate communication effectiveness.
* Confirm decision-making under uncertainty.
* Exercise executive coordination.
* Evaluate business continuity processes.
* Practice stakeholder communications.
* Produce actionable improvement recommendations.

Success will be measured against these objectives rather than by individual performance.

---

# 3. Scope

The following functions are included in this exercise.

## Business Functions

* Executive Leadership
* Security Operations
* Incident Response
* Infrastructure
* Cloud Operations
* Identity and Access Management
* Service Desk
* Corporate Communications
* Legal
* Risk Management
* Vendor Management

## Technology

* Corporate network
* Cloud workloads
* Identity platform
* Endpoint environment
* SIEM
* EDR
* Backup platform
* VPN services

---

# 4. Out of Scope

The following activities are explicitly excluded.

* Production changes
* Live malware execution
* Penetration testing
* Vulnerability scanning
* Customer notification
* Regulatory notification
* Procurement discussions
* Budget approvals
* Personnel evaluation

---

# 5. Assumptions

Unless otherwise stated:

* Identity services remain operational.
* Backup infrastructure is available.
* Internal communications remain functional.
* Key personnel are available.
* Third-party contacts respond when requested.
* Required forensic data exists.

---

# 6. Constraints

The following constraints apply throughout the exercise.

* No production systems will be modified.
* No live accounts will be disabled.
* No firewall changes will be performed.
* No passwords will be reset.
* No customer-facing services will be interrupted.
* All artifacts are simulated.

---

# 7. Exercise Principles

Participants are expected to operate according to the following principles.

* Collaboration over competition.
* Learning over testing.
* Discussion over perfection.
* Process improvement over fault finding.
* Respect for all participants.
* Decisions based on available information.

---

# 8. No-Blame Statement

This exercise is conducted solely to improve organizational preparedness.

Observations, findings, and recommendations relate to:

* processes,
* governance,
* communication,
* technology,
* documentation.

The exercise is **not** an employee performance evaluation.

Mistakes, uncertainty, and differing opinions are expected and encouraged as part of the learning process.

---

# 9. Participant Expectations

Participants are expected to:

* Engage actively.
* Explain assumptions.
* Ask clarifying questions.
* Remain within exercise scope.
* Respect differing opinions.
* Avoid real operational changes.
* Participate in the hot-wash.

---

# 10. Roles and Responsibilities

## Executive Sponsor

Responsible for:

* approving the exercise,
* providing organizational support,
* reviewing outcomes.

---

## Lead Facilitator

Responsible for:

* conducting the exercise,
* maintaining pacing,
* guiding discussion,
* enforcing the Rules of Engagement.

---

## White Cell

Responsible for:

* scenario truth,
* inject delivery,
* clarification,
* timing adjustments,
* contingency management.

---

## Scribe

Responsible for:

* recording decisions,
* capturing timestamps,
* documenting actions.

---

## Observers

Responsible for:

* recording observations,
* documenting assumptions,
* remaining silent unless requested.

---

## Participants

Responsible for:

* responding realistically,
* collaborating,
* documenting decisions,
* contributing to discussion.

---

# 11. Communications Plan

| Purpose                  | Channel            |
| ------------------------ | ------------------ |
| Exercise Discussion      | Teams / Zoom       |
| White Cell               | Private Chat       |
| Executive Updates        | Email Inject       |
| Observer Notes           | Shared Document    |
| Facilitator Coordination | White Cell Channel |

All exercise communications should use the prefix:

```text
[TTX-EXERCISE]
```

---

# 12. Exercise Timeline

| Phase                 | Duration  |
| --------------------- | --------- |
| Welcome               | 15 min    |
| Rules of Engagement   | 15 min    |
| Scenario Introduction | 15 min    |
| Exercise              | 2–3 hours |
| Hot-Wash              | 30 min    |
| Closing               | 15 min    |

---

# 13. Pause Authority

The exercise may be paused if:

* a real security incident occurs,
* participant safety is affected,
* significant technical issues arise,
* facilitator judgment requires it,
* executive leadership requests it.

Any participant may request a pause.

Only the Lead Facilitator may resume the exercise after consultation with the White Cell.

---

# 14. Stop Authority

The exercise may be terminated if:

* a real operational emergency occurs,
* business continuity is affected,
* participant wellbeing is at risk,
* executive leadership directs termination.

---

# 15. White Cell Governance

The White Cell is responsible for maintaining scenario consistency.

Only the White Cell may:

* introduce new scenario facts,
* modify inject timing,
* answer authoritative scenario questions,
* change exercise pacing,
* introduce contingency injects.

---

# 16. Artifact Handling

Exercise artifacts must:

* be clearly marked as simulated,
* contain no confidential information,
* remain within approved collaboration platforms,
* be retained according to organizational policy.

Example naming convention:

```text
artifact-siem-alert-001.md
artifact-executive-email-002.md
```

---

# 17. Evaluation

The exercise evaluates organizational capability in the following areas:

* Detection
* Analysis
* Decision-making
* Communication
* Coordination
* Governance
* Documentation
* Recovery planning

Individual employees are **not** scored unless explicitly stated in the exercise charter.

---

# 18. Deliverables

The following outputs will be produced.

* Observer Logs
* Incident Timeline
* Hot-Wash Notes
* After Action Review
* Improvement Roadmap
* Updated Procedures (where applicable)

---

# 19. Approval

| Role             | Name | Signature | Date |
| ---------------- | ---- | --------- | ---- |
| Sponsor          |      |           |      |
| Exercise Owner   |      |           |      |
| Lead Facilitator |      |           |      |
| White Cell Lead  |      |           |      |

---

# 20. Distribution

| Audience      | Document            |
| ------------- | ------------------- |
| Participants  | Rules of Engagement |
| White Cell    | MSEL                |
| Observers     | Observer Guide      |
| Leadership    | Executive Brief     |
| Exercise Team | Complete Package    |

---

# 21. References

Reference documents may include:

* Incident Response Plan
* Business Continuity Plan
* Crisis Communications Plan
* Cybersecurity Policies
* Relevant Playbooks
* Applicable Regulatory Guidance

---

# 22. Version History

| Version | Date | Author | Description     |
| ------- | ---- | ------ | --------------- |
| 0.1     |      |        | Initial Draft   |
| 0.9     |      |        | Internal Review |
| 1.0     |      |        | Approved        |

---

# Appendix A — Acronyms

| Acronym | Meaning                     |
| ------- | --------------------------- |
| AAR     | After Action Review         |
| IR      | Incident Response           |
| MSEL    | Master Scenario Events List |
| RoE     | Rules of Engagement         |
| SOC     | Security Operations Center  |
| TTX     | Tabletop Exercise           |

---

# Appendix B — Document Checklist

Before issuing this document, verify that:

* Exercise purpose is clearly stated.
* Objectives are measurable.
* Scope and exclusions are complete.
* Roles are assigned.
* Communication channels are confirmed.
* Pause and stop authorities are documented.
* No-blame statement is included.
* Deliverables are defined.
* Sponsor approval has been obtained.
* Version history has been updated.

Once approved, this Rules of Engagement document becomes the governing authority for the exercise and should be distributed to all participants before the exercise briefing.
