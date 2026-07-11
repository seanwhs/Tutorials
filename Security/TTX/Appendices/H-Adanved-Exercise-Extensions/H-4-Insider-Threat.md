---

title: Appendix H
section: H.4
subtitle: Insider Threat Advanced MSEL Package
description: Complete tabletop exercise package for insider threat and data exfiltration scenario.
classification: "TLP:GREEN"
version: 1.0
---
# H.4 Insider Threat Advanced MSEL Package

## Scenario Name

# Operation Silent Current

> *A cyber resilience exercise testing response to suspected insider-driven data theft, unauthorized access, and employee risk.*

---

# 1. Exercise Overview

## Exercise Type

Advanced Cybersecurity Tabletop Exercise

---

## Scenario Category

Insider Threat / Data Protection

---

## Primary Threat Theme

A trusted employee account is used to access and remove sensitive organizational information.

---

## Target Environment

Example environment:

* Corporate identity platform.
* File repositories.
* Source code repositories.
* Customer databases.
* Collaboration platforms.
* Data loss prevention systems.

---

# 2. Scenario Background

The organization employs thousands of employees across multiple regions.

Employees have access to:

* Business documents.
* Customer information.
* Intellectual property.
* Internal systems.

Existing controls include:

* Identity management.
* Data loss prevention.
* Security monitoring.

However:

* User behaviour analytics is limited.
* Data ownership is inconsistent.
* Insider threat procedures are not regularly tested.

---

# 3. Initial Scenario Narrative

A security analyst notices unusual activity from an employee account.

The activity includes:

* Access to files outside normal job responsibilities.
* Large-volume downloads.
* External file transfers.
* Activity occurring shortly before the employee announces resignation.

The employee has:

* Valid credentials.
* No malware detected.
* Normal system access.

---

# 4. Exercise Objectives

The exercise evaluates the organization's ability to:

---

# Objective 1 — Detect Insider Risk

Evaluate:

* Monitoring capability.
* Behaviour analysis.
* Escalation process.

---

# Objective 2 — Balance Security and Employee Rights

Evaluate:

* Investigation boundaries.
* Privacy considerations.
* Legal involvement.

---

# Objective 3 — Coordinate Cross-Functional Response

Evaluate:

* Security.
* HR.
* Legal.
* Management collaboration.

---

# Objective 4 — Protect Sensitive Information

Evaluate:

* Data containment.
* Access control.
* Evidence preservation.

---

# Objective 5 — Manage Organizational Trust

Evaluate:

* Communication.
* Workforce confidence.
* Leadership decisions.

---

# 5. Rules of Engagement

## Exercise Boundaries

This is a simulated employee risk scenario.

No actual employee investigation will occur.

---

## Participants Should

* Discuss response options.
* Consider legal and ethical requirements.
* Identify decision ownership.

---

## Participants Should Not

* Assume employee guilt.
* Skip investigation procedures.
* Ignore privacy obligations.

---

# 6. Participant Roles

## Security Operations

Responsibilities:

* Analyze indicators.
* Preserve evidence.
* Recommend controls.

---

## Identity and Access Management

Responsibilities:

* Review access.
* Prepare containment options.

---

## Human Resources

Responsibilities:

* Employee considerations.
* Workforce impact.
* Employment procedures.

---

## Legal / Compliance

Responsibilities:

* Privacy obligations.
* Investigation boundaries.
* Regulatory considerations.

---

## Business Manager

Responsibilities:

* Understand business context.
* Support operational decisions.

---

## Data Owners

Responsibilities:

* Assess information sensitivity.
* Determine impact.

---

## Executive Leadership

Responsibilities:

* Approve strategic response.
* Accept risk.

---

# 7. Threat Narrative

Simulated insider progression:

```text id="8s9r4u"
Legitimate Employee Access

        ↓

Unusual Data Access

        ↓

Sensitive Data Collection

        ↓

External Transfer Attempt

        ↓

Potential Data Disclosure
```

---

# 8. Master Scenario Events List (MSEL)

---

# Phase 1 — Suspicious Activity Detection

## Time

T+00

---

## Inject H4-001

### User Behaviour Alert

```markdown id="u7z9bm"
[TTX-EXERCISE]

Security Alert

User:

Senior Employee Account

Observed Activity:

- Accessing restricted project folders.
- Download volume significantly above baseline.
- Activity outside normal working pattern.

Question:

Is this a security incident?
```

---

## Expected Discussion

Participants should consider:

* Normal business explanation.
* Investigation requirements.
* Escalation criteria.

---

## Observer Focus

Capture:

* Whether assumptions are challenged.
* Whether evidence is preserved.

---

# Phase 2 — Additional Evidence

## Time

T+45

---

## Inject H4-002

### Employment Update

```markdown id="6n2p0k"
[TTX-EXERCISE]

HR Notification

Employee submitted resignation.

Last working day:

Two weeks from today.

The employee has access to:

- Customer data.
- Strategic documents.
- Source materials.

Question:

Does this change the response?
```

---

## Expected Discussion

Topics:

* Access review.
* Risk assessment.
* HR coordination.

---

# Phase 3 — Data Transfer Detection

## Time

T+90

---

## Inject H4-003

### External Transfer Alert

```markdown id="4d8mqs"
[TTX-EXERCISE]

Data Loss Prevention Alert

Detected:

Large transfer of files to external storage.

Data classification:

Internal Confidential

User:

Same employee account.

Question:

What immediate actions are appropriate?
```

---

## Decision Point

Options:

A. Disable account immediately.

B. Continue monitoring.

C. Contact employee.

D. Escalate for executive decision.

---

# Phase 4 — Investigation Complexity

## Time

T+150

---

## Inject H4-004

### Employee Explanation

```markdown id="6qv0ca"
[TTX-EXERCISE]

Employee Statement

"I was preparing documents for my next role.
I believed these files were part of my normal work."

Question:

How should the organization proceed?
```

---

# Decision Tension

| Concern           | Conflict            |
| ----------------- | ------------------- |
| Protect data      | Employee rights     |
| Preserve evidence | Maintain trust      |
| Investigate       | Privacy obligations |

---

# Phase 5 — Data Impact Discovery

## Time

T+210

---

## Inject H4-005

### Data Review Result

```markdown id="j7s5e2"
[TTX-EXERCISE]

Investigation Update

Confirmed accessed information:

- Customer information.
- Product plans.
- Internal documentation.

Scope:

Still being determined.

Question:

Is external notification required?
```

---

# Phase 6 — Executive Decision

## Time

T+270

---

## Inject H4-006

### Leadership Briefing

```markdown id="v9m3r1"
[TTX-EXERCISE]

Executive Question:

"We need confidence that sensitive information is protected.

What actions are required today?"

Required decisions:

- Access controls.
- Investigation scope.
- Communication approach.
```

---

# 9. Critical Decision Areas

---

# Decision Area 1 — Investigation Approach

Questions:

* Who leads?
* What evidence is required?
* What approvals are needed?

---

# Decision Area 2 — Access Control

Questions:

* When should access be removed?
* What operational impact exists?

---

# Decision Area 3 — Privacy and Legal

Questions:

* What employee rights apply?
* What regulatory obligations exist?

---

# Decision Area 4 — Communication

Questions:

* Should employees be informed?
* How should leadership communicate?

---

# 10. Observer Evaluation Framework

Observers should assess:

---

## Detection

Questions:

* Were warning signs recognized?
* Was behaviour analyzed appropriately?

---

## Cross-Functional Coordination

Questions:

* Were HR and Legal involved early?
* Were responsibilities clear?

---

## Evidence Handling

Questions:

* Was evidence preserved?
* Were investigation procedures followed?

---

## Governance

Questions:

* Were decisions properly authorized?

---

# 11. Expected AAR Findings

Potential findings:

| Finding                                      | Category               |
| -------------------------------------------- | ---------------------- |
| Insider risk process unclear                 | Governance             |
| Data ownership incomplete                    | Information Management |
| HR/security coordination immature            | Process                |
| Excessive access privileges                  | Identity               |
| Employee exit procedures require improvement | Operational            |

---

# 12. Exercise Success Criteria

The exercise succeeds when participants demonstrate:

✓ Evidence-based investigation.

✓ Appropriate legal involvement.

✓ Balanced security and privacy decisions.

✓ Clear ownership.

✓ Protection of sensitive information.

---

# End of Appendix H.4

## Next Section

# Appendix H.5 — AI-Enabled Attack Advanced MSEL Package

The next module will explore emerging threats:

* AI-generated phishing.
* Deepfake voice impersonation.
* Automated reconnaissance.
* Social engineering at scale.
* Executive fraud scenarios.
* Trust verification challenges.
