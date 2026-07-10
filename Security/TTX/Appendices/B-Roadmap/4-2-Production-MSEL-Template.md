# Appendix B — Templates Library

# Part 4.2 — Production Master Scenario Events List (MSEL) Template

> **Instructions:** This document is intended exclusively for the **White Cell** and facilitation team. It contains privileged scenario information and must **not** be distributed to exercise participants.

---

```yaml
---
title: "[Exercise Name] - Master Scenario Events List"
exercise: "[Exercise Name]"
scenario: "[Scenario Name]"
exercise_id: "[TTX-2026-001]"
type: msel
version: 1.0
status: Draft
classification: White Cell Only
owner: "[Exercise Director]"
lead_facilitator: "[Lead Facilitator]"
white_cell_lead: "[White Cell Lead]"
exercise_date: "[YYYY-MM-DD]"
estimated_duration: "[4 Hours]"
maturity_level: "[L1|L2|L3|L4]"
---
```

---

# Document Purpose

This Master Scenario Events List (MSEL) provides the operational script for conducting the tabletop exercise.

It defines:

* exercise pacing,
* inject sequencing,
* facilitator guidance,
* expected participant actions,
* contingency planning,
* evaluation opportunities.

The MSEL should always be used together with:

* Rules of Engagement
* Scenario Document
* Facilitator Guide
* Observer Guide
* Exercise Artifacts

---

# Exercise Summary

| Field            | Value           |
| ---------------- | --------------- |
| Exercise         | [Exercise Name] |
| Scenario         | [Scenario Name] |
| Duration         | 4 Hours         |
| Exercise Level   | L2              |
| White Cell Lead  | [Name]          |
| Lead Facilitator | [Name]          |

---

# Exercise Objectives

List the objectives supported by this MSEL.

Example:

1. Validate incident detection.
2. Assess escalation.
3. Evaluate executive communications.
4. Exercise cross-functional coordination.
5. Identify process improvements.

Every inject should support one or more of these objectives.

---

# Exercise Timeline

| Phase                 | Planned Duration |
| --------------------- | ---------------- |
| Opening Brief         | 15 min           |
| Scenario Introduction | 15 min           |
| Phase 1               | 30 min           |
| Phase 2               | 45 min           |
| Phase 3               | 45 min           |
| Break                 | 15 min           |
| Phase 4               | 45 min           |
| Phase 5               | 30 min           |
| Hot Wash              | 30 min           |
| Closing               | 15 min           |

Timing should remain flexible. Productive discussion takes precedence over rigid adherence to the schedule.

---

# Inject Register

Each inject should be uniquely identified.

Recommended format:

```text
INJ-001
INJ-002
INJ-003
```

Avoid renumbering injects after review. If necessary, retire obsolete injects rather than changing identifiers.

---

# Master Inject Table

| Time | Inject ID | Phase     | Delivery Method | Inject Summary          | Recipient | Expected Decisions                 | Exercise Objectives | White Cell Notes                                             | Status  |
| ---- | --------- | --------- | --------------- | ----------------------- | --------- | ---------------------------------- | ------------------- | ------------------------------------------------------------ | ------- |
| T+05 | INJ-001   | Detection | SIEM Alert      | Suspicious vendor login | SOC       | Investigate authentication anomaly | Obj 1               | Do not confirm compromise unless asked appropriate questions | Pending |

---

# Detailed Inject Record

Each inject should have its own detailed section.

---

## Inject INJ-001

### Title

Suspicious Vendor Authentication

---

### Planned Delivery

T+05 minutes

---

### Delivery Method

* SIEM alert
* Email
* Screenshot
* Chat message

---

### Recipient

Security Operations Center

---

### Inject Content

Provide the exact text, screenshot, email, or artifact that participants receive.

Avoid including facilitator commentary in this section.

---

### Background (White Cell Only)

Explain:

* what actually occurred,
* what participants do not yet know,
* hidden attacker activity,
* assumptions.

Participants never see this section.

---

### Learning Objectives

Supports:

* Objective 1
* Objective 2

---

### Expected Participant Actions

Examples:

* Review authentication logs.
* Verify vendor identity.
* Correlate SIEM alerts.
* Escalate if appropriate.
* Notify Incident Response.

These are guidance only.

Participants may legitimately choose alternative approaches.

---

### Decision Gate

The exercise should not progress until participants have addressed:

* Whether an incident exists.
* Whether escalation is required.

---

### White Cell Guidance

If participants:

**Escalate quickly**

→ Proceed to INJ-002.

**Request additional evidence**

→ Provide authentication logs.

**Ignore the alert**

→ Introduce a follow-up endpoint alert after ten minutes.

---

### Observer Focus

Observers should pay attention to:

* assumptions,
* communication,
* escalation timing,
* collaboration,
* leadership.

---

### Success Indicators

Evidence of successful discussion might include:

* structured investigation,
* clear ownership,
* documented decisions,
* executive awareness.

---

### Facilitator Notes

Record:

* discussion highlights,
* unexpected questions,
* deviations,
* timing adjustments.

---

# Decision Gates

Critical decisions should be identified separately.

| Decision          | Trigger                          | Responsible Participants | Required Before Next Inject |
| ----------------- | -------------------------------- | ------------------------ | --------------------------- |
| Activate IR       | Confirmed suspicious activity    | SOC Lead                 | Yes                         |
| Notify Executives | Business impact identified       | IR Lead                  | Yes                         |
| Engage Vendor     | Third-party compromise suspected | Vendor Manager           | Optional                    |

Decision gates encourage deliberate discussion and prevent important topics from being skipped.

---

# Contingency Injects

Some injects are delivered only if required.

Examples:

| Inject               | Trigger                                         |
| -------------------- | ----------------------------------------------- |
| Media inquiry        | Participants contain incident unusually quickly |
| Executive phone call | Discussion stalls                               |
| Customer complaint   | Business impact not recognized                  |
| Backup verification  | Recovery discussion begins early                |

These injects help facilitators maintain pacing without forcing the narrative.

---

# White Cell Tracking

Maintain a live record during the exercise.

| Inject  | Delivered | Time  | Completed | Notes                       |
| ------- | --------- | ----- | --------- | --------------------------- |
| INJ-001 | ✓         | 09:05 | ✓         | Strong discussion           |
| INJ-002 | ✓         | 09:30 |           | Awaiting executive decision |

This log supports the After Action Review.

---

# Facilitator Observation Log

Throughout the exercise record:

* notable decisions,
* participant assumptions,
* recurring misunderstandings,
* communication breakdowns,
* excellent practices,
* opportunities for improvement.

These notes often become the foundation of the AAR.

---

# Exercise Branches

Document possible alternative paths.

## Path A

Participants identify the compromise early.

Expected outcome:

* faster escalation,
* earlier executive involvement,
* shorter investigation.

---

## Path B

Participants delay escalation.

Expected outcome:

* additional injects,
* increased business impact,
* stronger executive pressure.

---

## Path C

Participants misclassify the incident.

Expected outcome:

* delayed containment,
* customer complaints,
* media attention.

Branch planning allows facilitators to adapt naturally to participant decisions.

---

# Recovery Transition

Before entering the recovery phase verify that participants have discussed:

* containment,
* evidence preservation,
* executive communications,
* stakeholder management.

Only then introduce recovery-related injects.

---

# Exercise Completion Checklist

Before concluding the exercise confirm that:

* All primary objectives were exercised.
* Major decision points were discussed.
* Critical injects were delivered.
* Observer notes were collected.
* Hot-wash has been scheduled.
* White Cell notes have been consolidated.

---

# White Cell Debrief

Immediately after the exercise capture:

## What worked well?

---

## What surprised the facilitation team?

---

## Which injects generated the strongest discussion?

---

## Which injects should be improved?

---

## Timing adjustments for future exercises

---

## Recommended scenario improvements

---

## New inject ideas

---

# Version History

| Version | Date | Author | Description     |
| ------- | ---- | ------ | --------------- |
| 0.1     |      |        | Initial Draft   |
| 0.9     |      |        | Internal Review |
| 1.0     |      |        | Approved        |

---

# Appendix A — MSEL Quality Checklist

Before approving the MSEL, verify that:

* Every inject supports one or more exercise objectives.
* Inject timing follows a logical progression.
* Decision points are clearly identified.
* White Cell guidance exists for every inject.
* Contingency branches have been considered.
* Recovery activities are included.
* Observer focus areas are documented.
* Expected participant actions are realistic.
* The exercise concludes with sufficient material for an After Action Review.
* All supporting artifacts have been prepared and validated.

A well-designed MSEL does more than schedule events—it orchestrates learning. By carefully sequencing information, guiding facilitators, and creating meaningful decision opportunities, the MSEL becomes the operational backbone of a successful tabletop exercise. When combined with a realistic scenario and clear Rules of Engagement, it enables consistent delivery, rich observations, and actionable improvement outcomes.
