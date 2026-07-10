---

title: Appendix B – Part 3.2
subtitle: Production Scenario Template
description: Production-ready Markdown template for designing cybersecurity tabletop exercise scenarios.
type: template
category: scenario
version: 1.0
tags:
- ttx
- scenario
- template

---

# Appendix B — Templates Library

# Part 3.2 — Production Scenario Template

> **Instructions:** Replace all placeholder values enclosed in square brackets (`[ ]`) with exercise-specific information. Remove instructional notes before distributing participant-facing documents. This scenario document is intended for facilitators and exercise designers; participant briefings should contain only the information appropriate for the audience.

---

```yaml
---
title: "[Scenario Title]"
exercise: "[Exercise Name]"
scenario_id: "[SCN-2026-001]"
type: scenario
version: 1.0
status: Draft
classification: Internal Use
owner: "[Scenario Owner]"
lead_facilitator: "[Lead Facilitator]"
exercise_date: "[YYYY-MM-DD]"
maturity_level: "[L1|L2|L3|L4]"
estimated_duration: "[4 Hours]"
tags:
  - ttx
  - scenario
  - cybersecurity
---
```

---

# Scenario Overview

## Executive Summary

Provide a concise overview of the scenario.

Describe:

* The fictional incident.
* Why the organization is affected.
* The primary business risks.
* The intended learning outcomes.

Keep this section to one or two paragraphs.

---

# Scenario Purpose

Explain why this scenario was selected.

Examples include:

* Validate ransomware response procedures.
* Exercise third-party incident management.
* Assess executive crisis communications.
* Evaluate cloud incident response.
* Test identity compromise playbooks.

The purpose should align directly with the exercise objectives defined in the Rules of Engagement.

---

# Business Context

Describe the organization immediately before the incident.

Consider including:

* Organizational mission.
* Industry sector.
* Business priorities.
* Critical services.
* Peak operating periods.
* Strategic initiatives.
* Key customers.
* Critical suppliers.
* Regulatory obligations.

Example:

> The organization is entering its busiest sales quarter. Customer-facing digital services account for more than 80% of daily revenue. A recently onboarded managed service provider has been granted privileged VPN access to support infrastructure upgrades.

Business context helps participants understand why decisions matter.

---

# Threat Context

Describe the external environment without revealing the outcome.

Possible elements include:

* Increased ransomware activity.
* Publicly disclosed vulnerability.
* Geopolitical tensions.
* Supply chain attacks affecting the industry.
* Recent mergers or acquisitions.
* Targeted phishing campaigns.

The objective is to establish credibility rather than predict the attack.

---

# Initial Conditions

Document exactly what participants know when the exercise begins.

Examples:

* SOC receives a high-severity authentication alert.
* Help desk receives an unusual vendor call.
* Network monitoring identifies internal reconnaissance.
* Executives receive media inquiries.
* Cloud monitoring detects abnormal administrative activity.

Do not include information participants would not reasonably possess at the start of the exercise.

---

# Exercise Assumptions

List assumptions that simplify the scenario.

Examples:

* Corporate email remains operational.
* Authentication services are available.
* Backups exist.
* Vendor contacts respond when requested.
* Key personnel are available.
* Communications infrastructure remains functional.

Assumptions reduce ambiguity and keep the discussion focused.

---

# Exercise Constraints

Document limitations placed on the exercise.

Examples:

* No production changes.
* No real account modifications.
* No live forensic acquisition.
* No malware execution.
* Simulated artifacts only.

Constraints protect operational systems while maintaining realism.

---

# Scenario Narrative

Describe the incident as a sequence of phases rather than a complete story.

## Phase 1 – Initial Activity

Summarize the first observable indicators.

Examples:

* Suspicious authentication.
* Vendor support anomaly.
* Unusual endpoint behavior.

---

## Phase 2 – Investigation

Describe the information participants are expected to uncover.

Examples:

* Identity misuse.
* Internal scanning.
* Privilege escalation.
* Suspicious administrative activity.

---

## Phase 3 – Escalation

Increase operational complexity.

Examples:

* Business disruption.
* Data access concerns.
* Executive involvement.
* Crisis management activation.

---

## Phase 4 – Recovery

Shift focus toward:

* Containment.
* Restoration.
* Communications.
* Lessons learned.
* Business continuity.

---

# Decision Points

Identify major decisions expected during the exercise.

| Decision                      | Trigger                            | Participants         |
| ----------------------------- | ---------------------------------- | -------------------- |
| Escalate to Incident Response | Confirmed compromise               | SOC, IR              |
| Notify Executives             | Business impact                    | IR Lead              |
| Engage Legal                  | Potential regulatory exposure      | Executive Team       |
| Contact Vendor                | Third-party involvement            | Vendor Manager       |
| Activate Crisis Management    | Significant operational disruption | Executive Leadership |

Decision points should align with organizational processes and governance.

---

# Expected Participant Activities

Participants are expected to:

* Assess available information.
* Validate assumptions.
* Communicate effectively.
* Escalate appropriately.
* Coordinate across teams.
* Document decisions.
* Consider business impact.
* Plan recovery.

These activities support the learning objectives rather than prescribe exact responses.

---

# Expected Deliverables

During the exercise, participants should produce or contribute to:

* Incident timeline.
* Decision log.
* Communication updates.
* Executive briefings.
* Situation reports.
* Recovery planning.
* Hot-wash discussion.

---

# Business Impact Analysis

Describe the potential consequences if the incident continues.

Consider impacts on:

## Operations

* Service disruption.
* Manufacturing.
* Logistics.
* Customer support.

## Financial

* Revenue loss.
* Incident response costs.
* Contract penalties.

## Regulatory

* Reporting obligations.
* Compliance exposure.
* Investigations.

## Reputational

* Media attention.
* Customer confidence.
* Investor relations.

The objective is to encourage participants to think beyond technical containment.

---

# Threat Mapping

Document relevant threat framework references.

| Framework                  | Reference                       |
| -------------------------- | ------------------------------- |
| MITRE ATT&CK               | Relevant tactics and techniques |
| NIST CSF                   | Respond, Recover                |
| Incident Response Plan     | Applicable procedures           |
| Crisis Communications Plan | Executive communications        |

Framework mapping supports repeatability and consistency.

---

# Success Criteria

The scenario is considered successful if it enables participants to:

* Identify the incident.
* Escalate appropriately.
* Coordinate effectively.
* Communicate clearly.
* Make informed decisions.
* Capture observations.
* Produce actionable improvements.

The focus is organizational learning rather than operational perfection.

---

# Facilitator Notes

The facilitator should document:

* Expected participant questions.
* Areas likely to generate discussion.
* Potential misconceptions.
* Optional injects.
* Contingency plans.
* Time management guidance.

These notes remain confidential and are not distributed to participants.

---

# White Cell Guidance

The White Cell should maintain a consistent understanding of:

* Scenario truth.
* Inject timing.
* Approved clarifications.
* Decision dependencies.
* Alternative scenario paths.

Any deviations from the planned scenario should be documented for inclusion in the After Action Review.

---

# References

List supporting materials used during scenario development.

Examples include:

* Incident Response Plan.
* Business Continuity Plan.
* Crisis Communications Plan.
* Relevant threat intelligence reports.
* Applicable regulatory guidance.
* Organizational playbooks.

---

# Version History

| Version | Date | Author | Description     |
| ------- | ---- | ------ | --------------- |
| 0.1     |      |        | Initial Draft   |
| 0.9     |      |        | Internal Review |
| 1.0     |      |        | Approved        |

---

# Appendix A — Scenario Validation Checklist

Before approving the scenario, verify that it:

* Aligns with the exercise objectives.
* Reflects realistic business conditions.
* Includes sufficient business context.
* Introduces credible technical indicators.
* Contains meaningful decision points.
* Balances realism with simplicity.
* Defines assumptions and constraints.
* Identifies expected participant actions.
* Includes measurable success criteria.
* References relevant organizational procedures.
* Supports the planned MSEL.

A scenario that satisfies this checklist provides a strong foundation for the next stage of exercise development: constructing the **Master Scenario Events List (MSEL)**, where the narrative is transformed into a timed sequence of injects, observations, and expected participant actions.
