# Appendix B — Templates Library

# Part 2.2 — Rules of Engagement (RoE): Section-by-Section Design Guide

> *A good Rules of Engagement document answers questions before participants need to ask them.*

In the previous chapter, we explored the purpose and guiding principles of the Rules of Engagement (RoE). This chapter focuses on implementation by examining every major section of a professional RoE document, explaining not only **what** belongs in each section, but **why** it matters.

Although organizations may adapt the structure to suit their own governance processes, maintaining a consistent format across all exercises improves readability, simplifies approval, and supports long-term reuse.

---

# Recommended Document Structure

A production-quality Rules of Engagement document typically contains the following sections:

1. Document Metadata
2. Executive Summary
3. Exercise Purpose
4. Exercise Objectives
5. Scope
6. Out of Scope
7. Assumptions
8. Constraints
9. Roles and Responsibilities
10. Communications Plan
11. Exercise Safety
12. No-Blame Statement
13. Pause and Stop Authority
14. White Cell Governance
15. Artifact Handling
16. Evaluation Criteria
17. Deliverables
18. Approval and Distribution
19. Version History

Each section contributes to the overall governance of the exercise.

---

# 1. Document Metadata

Metadata identifies the document and establishes accountability.

Typical metadata includes:

* Exercise name
* Version
* Document owner
* Sponsor
* Classification
* Approval status
* Creation date
* Review date

Example:

| Field          | Example                   |
| -------------- | ------------------------- |
| Exercise       | Operation Red Horizon     |
| Version        | 1.2                       |
| Owner          | Incident Response Manager |
| Status         | Approved                  |
| Classification | Internal Use              |
| Review Date    | 11 July 2026              |

Keeping metadata consistent across all templates enables automation through tools such as Obsidian Dataview and simplifies document management.

---

# 2. Executive Summary

Busy executives may only read the first page of the RoE.

The Executive Summary should briefly explain:

* the purpose of the exercise,
* participating teams,
* expected duration,
* major objectives,
* intended outcomes.

Limit this section to one page.

Avoid operational detail.

Its purpose is orientation rather than instruction.

---

# 3. Exercise Purpose

This section answers a simple question:

**Why are we conducting this exercise?**

Examples include:

* Validate the Incident Response Plan.
* Assess executive decision-making.
* Improve communications with third-party vendors.
* Evaluate ransomware response procedures.
* Practice regulatory notification workflows.

Purpose describes intent.

It does not describe the scenario.

---

# 4. Exercise Objectives

Objectives translate the broad purpose into measurable outcomes.

Good objectives begin with action verbs.

Examples:

* Validate incident escalation procedures.
* Assess executive communications.
* Practice containment decision-making.
* Evaluate coordination between Security Operations and Infrastructure teams.
* Confirm understanding of backup recovery priorities.

Objectives should be realistic, observable, and achievable within the exercise timeframe.

---

# SMART Objectives

Where practical, objectives should follow the SMART model.

They should be:

* **Specific**
* **Measurable**
* **Achievable**
* **Relevant**
* **Time-bound**

Example:

> Assess whether participants can identify executive escalation criteria within fifteen minutes of receiving confirmation of ransomware activity.

This is significantly more useful than:

> Improve ransomware response.

---

# 5. Scope

Scope defines the boundaries of discussion.

Examples of in-scope topics include:

* Incident Response Team
* Security Operations Center
* Executive Leadership
* Communications Team
* Vendor Management
* Identity Platform
* Corporate Network
* Cloud Infrastructure

Scope should be explicit.

Participants should never need to guess whether something belongs in the exercise.

---

# 6. Out of Scope

This section is equally important.

Typical exclusions include:

* Production system modifications
* Penetration testing
* Procurement discussions
* Budget approval
* Disaster recovery testing
* Personnel performance evaluation

Documenting exclusions prevents unnecessary debate during facilitation.

---

# 7. Assumptions

Exercises necessarily simplify reality.

Assumptions make those simplifications explicit.

Examples include:

* Identity services remain available.
* Backups exist unless stated otherwise.
* Vendor contacts are reachable.
* Legal counsel is available.
* Communications systems remain operational.

Assumptions prevent repeated clarification questions during the exercise.

---

# 8. Constraints

Constraints identify limitations imposed on the exercise.

Examples:

* No production system access.
* No real credential resets.
* No live firewall changes.
* No customer communications.
* Time-compressed scenario.
* Simulated forensic evidence only.

Constraints protect operational stability while maintaining realism.

---

# 9. Roles and Responsibilities

Clearly define every participant role.

Typical roles include:

| Role             | Primary Responsibility |
| ---------------- | ---------------------- |
| Sponsor          | Approves exercise      |
| Lead Facilitator | Conducts session       |
| White Cell       | Controls scenario      |
| Scribe           | Records decisions      |
| Observer         | Documents observations |
| Participant      | Responds to scenario   |

Each role should have clearly documented authority and responsibilities.

---

# Responsibility Matrix

A RACI matrix can improve clarity.

| Activity         | Sponsor | Facilitator | White Cell | Participant |
| ---------------- | ------- | ----------- | ---------- | ----------- |
| Approve Exercise | A       | C           | I          | I           |
| Deliver Injects  | I       | A           | R          | I           |
| Pause Exercise   | C       | A           | R          | I           |
| Capture Notes    | I       | C           | C          | I           |
| Produce AAR      | I       | A           | C          | I           |

Legend:

* **R** – Responsible
* **A** – Accountable
* **C** – Consulted
* **I** – Informed

---

# 10. Communications Plan

Exercises frequently involve multiple communication channels.

Document:

* chat platform,
* email simulation,
* voice conference,
* executive briefing method,
* White Cell coordination,
* observer communications.

Example:

| Communication     | Channel         |
| ----------------- | --------------- |
| Exercise Traffic  | Teams Channel   |
| Executive Updates | Email Inject    |
| White Cell        | Private Chat    |
| Observer Notes    | Shared Document |

Participants should know where official exercise communications originate.

---

# 11. Exercise Safety

Safety extends beyond physical wellbeing.

A professional RoE considers:

* emotional safety,
* psychological safety,
* operational safety,
* information security,
* business continuity.

Examples include:

* participants may request clarification,
* breaks are permitted,
* facilitators may pause discussions,
* no production systems will be affected.

Safety enables honest participation.

---

# 12. No-Blame Statement

Every exercise should include an explicit no-blame declaration.

Recommended principles include:

* focus on processes,
* avoid individual criticism,
* encourage experimentation,
* recognize uncertainty,
* support learning.

This statement should be reinforced verbally during the opening briefing.

---

# 13. Pause and Stop Authority

Unexpected situations occasionally arise.

Examples include:

* real cybersecurity incident,
* participant distress,
* significant technical failure,
* executive emergency,
* accidental production impact.

The RoE should clearly identify:

* who may pause,
* who may stop,
* who may resume,
* how decisions are communicated.

Ambiguity during a live exercise can quickly undermine confidence.

---

# Example Pause Criteria

Typical pause triggers include:

* Active production incident
* Medical emergency
* Safety concern
* Significant exercise confusion
* Technology failure
* Sponsor request

Every participant should know how to request a pause.

---

# 14. White Cell Governance

The White Cell maintains scenario integrity.

Its responsibilities should include:

* inject timing,
* scenario truth,
* clarification requests,
* pacing adjustments,
* contingency planning,
* exercise continuity.

Participants should understand that only the White Cell may introduce new scenario facts.

---

# 15. Artifact Handling

Exercises often include realistic documentation.

Specify:

* storage location,
* naming convention,
* classification,
* retention,
* sanitization requirements.

Example:

```
[TTX-EXERCISE]
artifact-email-vendor-alert.md
```

Never use real confidential information in training artifacts.

---

# 16. Evaluation Criteria

Participants should understand how the exercise will be evaluated.

Examples:

* communication effectiveness,
* decision quality,
* collaboration,
* governance,
* documentation,
* adherence to process.

Avoid scoring individual participants unless this has been explicitly agreed beforehand.

---

# 17. Deliverables

State the expected outputs.

Typical deliverables include:

* completed observer logs,
* incident timeline,
* hot-wash notes,
* After Action Review,
* improvement roadmap,
* updated procedures.

Defining deliverables early improves accountability.

---

# 18. Approval and Distribution

Document:

* approving authority,
* document owner,
* review cycle,
* distribution list.

Not every participant requires every document.

For example:

| Document     | Audience         |
| ------------ | ---------------- |
| RoE          | All Participants |
| MSEL         | White Cell Only  |
| Observer Log | Observers        |
| AAR          | Leadership       |

Controlled distribution protects scenario integrity.

---

# 19. Version History

Every revision should be documented.

Example:

| Version | Date        | Author     | Summary        |
| ------- | ----------- | ---------- | -------------- |
| 0.1     | 01 Jul 2026 | J. Smith   | Initial Draft  |
| 0.9     | 07 Jul 2026 | White Cell | Review Updates |
| 1.0     | 10 Jul 2026 | Sponsor    | Approved       |

Version history provides traceability and supports continuous improvement.

---

# Final Review Checklist

Before approving the RoE, confirm that it:

* Clearly states the exercise purpose.
* Defines measurable objectives.
* Documents scope and exclusions.
* Identifies assumptions and constraints.
* Defines participant roles.
* Specifies communication channels.
* Includes safety and no-blame statements.
* Identifies pause and stop authority.
* Explains evaluation criteria.
* Lists expected deliverables.
* Includes approvals and version history.

If every item on this checklist can be answered confidently, the Rules of Engagement is ready to support a successful tabletop exercise.

The next chapter transforms these design principles into a complete, production-ready Markdown template that can be copied directly into an Obsidian vault and customized for any cybersecurity tabletop exercise.
