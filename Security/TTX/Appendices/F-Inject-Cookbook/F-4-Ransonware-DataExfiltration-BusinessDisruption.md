---

title: Appendix F – Part 4
subtitle: Facilitator's Inject Cookbook – Ransomware, Data Exfiltration & Business Disruption
description: A reusable library of tabletop exercise injects covering ransomware, double extortion, operational disruption, executive decision-making, business continuity, and enterprise crisis management.
type: appendix
category: facilitator
version: 1.0
tags:
- ttx
- ransomware
- business-continuity
- crisis-management
- executive

---

# Appendix F — Facilitator's Inject Cookbook

# Part 4 — Ransomware, Data Exfiltration & Business Disruption

> *The defining challenge of ransomware is rarely the encryption itself. It is the cascade of operational, financial, legal, regulatory, and reputational decisions that follow.*

By this stage of the exercise, participants should have moved beyond technical investigation. The scenario should now test the organization's ability to make coordinated business decisions under sustained pressure, incomplete information, and conflicting priorities.

---

# Learning Objectives

These injects are designed to evaluate the organization's ability to:

* Activate crisis management.
* Coordinate executive decision-making.
* Balance containment with business continuity.
* Manage ransomware events.
* Assess claims of data exfiltration.
* Prioritize service restoration.
* Coordinate communications with customers, regulators, insurers, and partners.

---

# Category 16 — Ransomware Detection

---

# Inject RW-01 — Suspicious File Encryption

## Objective

Evaluate early ransomware detection and escalation.

### Difficulty

L2

### Timing

T+90

### Delivery

SOC Alert

### Scenario

Multiple file servers begin generating unusually high volumes of file modification events. Endpoint monitoring reports processes rapidly renaming and encrypting documents.

### Expected Discussion

* Is encryption confirmed?
* Which systems are affected?
* Should network isolation begin immediately?
* Who authorizes containment actions?

### Facilitator Notes

Participants should resist assuming the entire enterprise is compromised. Encourage structured scoping before broad containment.

---

# Inject RW-02 — Ransom Note Appears

## Objective

Assess executive notification and incident classification.

### Scenario

Several employees report a text file appearing on their desktops stating that files have been encrypted and directing the organization to contact the attackers.

### Discussion

* Should this immediately trigger the Crisis Management Team?
* Is payment even a consideration?
* What evidence should be preserved before restoration begins?

---

# Inject RW-03 — Security Tools Disabled

## Objective

Test response under degraded visibility.

### Scenario

Endpoint protection and centralized logging become unavailable on several critical systems.

### Facilitator Questions

* How does the team continue operating with reduced telemetry?
* What alternate evidence sources remain?

---

# Category 17 — Double Extortion

---

# Inject DE-01 — Data Leak Threat

## Objective

Evaluate decision-making under extortion pressure.

### Scenario

The attacker claims to have copied confidential data and threatens public release within 72 hours unless negotiations begin.

### Discussion

* Can the claim be verified?
* Who evaluates legal implications?
* Should external experts be engaged?

---

# Inject DE-02 — Sample Data Released

## Objective

Assess evidence validation.

### Scenario

A small archive allegedly containing internal documents appears on a public leak site.

### Facilitator Notes

The documents may be authentic, outdated, fabricated, or partially altered. Encourage participants to validate before concluding that a full-scale breach has occurred.

---

# Inject DE-03 — Countdown Timer

## Objective

Introduce decision urgency.

### Scenario

The attackers publish a countdown indicating that additional information will be released unless negotiations begin.

### Discussion

* Does the countdown change response priorities?
* What additional stakeholders should now be involved?

---

# Category 18 — Business Operations

---

# Inject BO-01 — ERP System Offline

## Objective

Exercise business continuity planning.

### Scenario

The Enterprise Resource Planning platform becomes unavailable.

### Expected Discussion

* Which business processes are affected?
* Are manual procedures available?
* What restoration priority should be assigned?

---

# Inject BO-02 — Manufacturing Disruption

## Objective

Evaluate operational resilience.

### Scenario

Production supervisors report that manufacturing scheduling systems cannot communicate with warehouse systems.

### Discussion

* Continue production manually?
* Suspend manufacturing?
* Escalate to executive leadership?

---

# Inject BO-03 — Customer Portal Unavailable

## Objective

Assess customer-facing communications.

### Scenario

Customers begin reporting that online services are unavailable.

### Discussion

* Should a public status page be updated?
* How much information should be shared?
* Who approves messaging?

---

# Inject BO-04 — Payroll Deadline

## Objective

Introduce competing business priorities.

### Scenario

Payroll processing must begin within four hours, but the finance environment remains isolated.

### Facilitator Notes

Participants must balance operational urgency against recovery discipline.

---

# Category 19 — Executive Decision-Making

---

# Inject EX-01 — CEO Requests Immediate Update

## Objective

Evaluate executive communications.

### Scenario

The Chief Executive Officer requests a concise briefing in ten minutes.

### Discussion

Participants should explain:

* What is known.
* What remains unknown.
* Immediate business risks.
* Recommended next steps.

---

# Inject EX-02 — Board Meeting Called

## Objective

Exercise governance.

### Scenario

The Chair of the Board requests an emergency briefing.

### Discussion

* What strategic decisions require board approval?
* How should technical details be translated into business language?

---

# Inject EX-03 — Conflicting Priorities

## Objective

Evaluate leadership alignment.

### Scenario

The Chief Operating Officer wants rapid restoration.

The Chief Information Security Officer recommends delaying restoration pending additional forensic validation.

### Facilitator Notes

This inject intentionally creates tension. There is no universally correct answer; the focus is on structured decision-making.

---

# Category 20 — Business Continuity

---

# Inject BC-01 — Manual Operations Activated

## Objective

Assess business continuity readiness.

### Scenario

Business units transition to manual processes.

Unexpectedly, manual documentation proves incomplete.

### Discussion

* Which critical processes continue?
* Which services stop?
* Who sets priorities?

---

# Inject BC-02 — Recovery Resource Constraints

## Objective

Exercise resource management.

### Scenario

Recovery teams report insufficient staff to restore all systems simultaneously.

### Discussion

Participants should prioritize restoration based on business impact rather than technical convenience.

---

# Inject BC-03 — Backup Integrity Questioned

## Objective

Evaluate recovery confidence.

### Scenario

Backup monitoring indicates successful backups exist, but integrity verification has not yet completed.

### Discussion

* Restore immediately?
* Wait for validation?
* Restore non-critical systems first?

---

# Category 21 — Financial & Insurance

---

# Inject FI-01 — Cyber Insurance Notification

## Objective

Test contractual obligations.

### Scenario

The insurer requests immediate notification and requires approval before engaging certain external service providers.

---

# Inject FI-02 — Estimated Financial Impact

## Objective

Introduce executive planning.

### Scenario

Finance estimates that every additional hour of downtime results in significant operational losses.

### Discussion

How does financial pressure influence recovery decisions?

---

# Facilitator Escalation Techniques

At this stage, avoid simply adding more technical alerts.

Instead, increase pressure through:

* executive expectations,
* customer impact,
* financial consequences,
* regulatory deadlines,
* operational dependencies,
* limited recovery resources,
* conflicting business priorities.

The incident should feel increasingly complex, but still manageable through disciplined coordination.

---

# Sample Crisis Progression

```text
Initial Compromise
        │
        ▼
Encryption Detected
        │
        ▼
Ransom Note
        │
        ▼
Operational Disruption
        │
        ▼
Executive Crisis Team
        │
        ▼
Business Continuity
        │
        ▼
Recovery Planning
```

This sequence reflects how many ransomware incidents evolve from technical events into organization-wide crises.

---

# Discussion Prompts

### Executive Leadership

* What decisions require executive approval?
* Which risks are acceptable?
* How should uncertainty be communicated?

### Operations

* Which services must be restored first?
* Are manual workarounds sustainable?
* What business processes are most critical?

### Legal & Compliance

* Are notification thresholds met?
* What evidence must be preserved?
* Which contractual obligations apply?

### Communications

* What should employees know?
* What should customers know?
* Who approves public messaging?

---

# Difficulty Scaling

| Level  | Example Adaptation                                                                                                                |
| ------ | --------------------------------------------------------------------------------------------------------------------------------- |
| **L1** | Single ransomware event affecting one department.                                                                                 |
| **L2** | Multiple business systems disrupted with moderate operational impact.                                                             |
| **L3** | Confirmed data theft, executive involvement, regulatory pressure, and customer communications.                                    |
| **L4** | Enterprise-wide ransomware, international operations, supply chain disruption, media scrutiny, and board-level crisis management. |

---

# Design Principles

The purpose of ransomware injects is not to simulate panic—it is to evaluate disciplined leadership under pressure.

Strong participants recognize that technical containment, executive governance, legal obligations, communications, business continuity, and recovery planning are inseparable. Success depends not on eliminating uncertainty, but on making informed decisions despite it.

This concludes **Part 4 – Ransomware, Data Exfiltration & Business Disruption** of the Facilitator's Inject Cookbook.

The next section expands beyond operational disruption into executive communications, media scrutiny, regulatory engagement, law enforcement coordination, and reputation management, where every public statement and leadership decision can shape the organization's long-term recovery.
