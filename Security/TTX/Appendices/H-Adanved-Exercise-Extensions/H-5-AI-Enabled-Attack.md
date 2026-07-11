---

title: Appendix H
section: H.5
subtitle: AI-Enabled Attack Advanced MSEL Package
description: Complete tabletop exercise package for AI-assisted cyber attack and executive impersonation scenario.
classification: "TLP:GREEN"
version: 1.0
---

# H.5 AI-Enabled Attack Advanced MSEL Package

## Scenario Name

# Operation Synthetic Trust

> *A cyber resilience exercise testing organizational response to AI-enhanced social engineering, deepfake impersonation, and automated attack campaigns.*

---

# 1. Exercise Overview

## Exercise Type

Advanced Cyber Crisis Tabletop Exercise

---

## Scenario Category

Artificial Intelligence Enabled Cyber Attack

---

## Primary Threat Theme

A threat actor uses AI capabilities to conduct a coordinated attack combining:

* Automated reconnaissance.
* Highly personalized phishing.
* Synthetic voice impersonation.
* Identity manipulation.
* Fraud attempts.

---

## Target Environment

Example environment:

* Corporate email.
* Collaboration platforms.
* Executive communications.
* Finance systems.
* Identity platforms.
* Customer communication channels.

---

# 2. Scenario Background

The organization has adopted AI technologies across multiple departments.

Employees use:

* AI productivity assistants.
* Automated workflows.
* Cloud collaboration tools.

Security controls include:

* Email protection.
* MFA.
* Security awareness training.

However:

* Human trust remains a major attack surface.
* Verification processes vary between departments.
* Executive impersonation procedures are informal.

---

# 3. Initial Scenario Narrative

A senior finance employee receives an urgent request appearing to come from the Chief Executive Officer.

The request includes:

* A realistic writing style.
* Familiar business context.
* A voice message that appears authentic.

The request asks for:

* Confidential financial documents.
* Urgent payment preparation.
* Immediate action outside normal workflow.

---

# 4. Exercise Objectives

The exercise evaluates the organization's ability to:

---

# Objective 1 — Detect AI-Assisted Social Engineering

Evaluate:

* Email analysis.
* User reporting.
* Security investigation.

---

# Objective 2 — Validate Identity

Evaluate:

* Verification procedures.
* Executive communication controls.
* Trust boundaries.

---

# Objective 3 — Manage AI-Driven Incident Response

Evaluate:

* Investigation.
* Containment.
* Communication.

---

# Objective 4 — Protect Business Processes

Evaluate:

* Financial controls.
* Approval workflows.
* Separation of duties.

---

# Objective 5 — Adapt Security Culture

Evaluate:

* Employee awareness.
* New verification practices.

---

# 5. Rules of Engagement

## Exercise Boundaries

This is a simulated AI-enabled attack.

No real employees or executives are impersonated.

---

## Participants Should

* Evaluate decisions.
* Challenge assumptions.
* Consider new attack methods.

---

## Participants Should Not

* Assume AI-generated content is always detectable.
* Depend only on technical controls.
* Skip human verification.

---

# 6. Participant Roles

## Security Operations

Responsibilities:

* Analyze suspicious activity.
* Investigate indicators.

---

## Identity Team

Responsibilities:

* Validate authentication.
* Assess account compromise.

---

## Executive Leadership

Responsibilities:

* Provide decision authority.
* Participate in verification processes.

---

## Finance Team

Responsibilities:

* Protect payment processes.
* Validate requests.

---

## Communications Team

Responsibilities:

* Manage misinformation risks.
* Coordinate messaging.

---

## Legal / Compliance

Responsibilities:

* Assess regulatory obligations.

---

## Business Users

Responsibilities:

* Report suspicious interactions.
* Follow verification procedures.

---

# 7. Threat Narrative

Simulated attacker progression:

```text id="q4p9kc"
Public Information Collection

        ↓

AI-Assisted Profile Creation

        ↓

Personalized Phishing

        ↓

Executive Impersonation

        ↓

Credential Theft / Fraud Attempt

        ↓

Data Disclosure
```

---

# 8. Master Scenario Events List (MSEL)

---

# Phase 1 — Suspicious Executive Email

## Time

T+00

---

## Inject H5-001

### Urgent Executive Request

```markdown id="1xv6kp"
[TTX-EXERCISE]

Email Received

From:

Executive Leadership

Message:

"Please prepare the requested financial documents immediately.
This is confidential and time-sensitive."

Indicators:

- Unusual urgency.
- Request bypasses normal process.
- Context appears realistic.

Question:

Should this request be trusted?
```

---

## Expected Discussion

Participants should consider:

* Verification.
* Approval process.
* Security reporting.

---

## Observer Focus

Record:

* Whether urgency overrides controls.
* Whether verification occurs.

---

# Phase 2 — Synthetic Voice Message

## Time

T+45

---

## Inject H5-002

### Voice Verification Challenge

```markdown id="n8x2qm"
[TTX-EXERCISE]

Finance employee receives a voice message.

The speaker appears to be:

Senior Executive

Message:

"I approved this request. Please proceed quickly."

Question:

How should identity be verified?
```

---

## Expected Discussion

Topics:

* Secondary verification.
* Trusted communication channels.
* Approval controls.

---

# Phase 3 — Credential Compromise

## Time

T+90

---

## Inject H5-003

### Identity Alert

```markdown id="b4s7mz"
[TTX-EXERCISE]

Security Alert

A user account involved in the communication:

- Logged in from unusual location.
- Accessed confidential files.
- Created new forwarding rules.

Question:

Is this a fraud incident or cyber incident?
```

---

# Decision Point

Participants must decide:

* Disable account?
* Investigate?
* Notify leadership?
* Preserve evidence?

---

# Phase 4 — Automated Reconnaissance Discovery

## Time

T+150

---

## Inject H5-004

### Threat Intelligence Update

```markdown id="c9v3ha"
[TTX-EXERCISE]

Threat intelligence reveals:

The attacker used:

- Public executive information.
- Company announcements.
- Employee social media content.

Question:

How should the organization reduce future risk?
```

---

# Phase 5 — Customer Impact

## Time

T+210

---

## Inject H5-005

### External Communication Challenge

```markdown id="m2k8px"
[TTX-EXERCISE]

Customers report receiving suspicious messages.

The messages appear to originate from company representatives.

Question:

Who manages the response?
```

---

# Phase 6 — Executive Crisis Decision

## Time

T+270

---

## Inject H5-006

### Leadership Question

```markdown id="s5d1qn"
[TTX-EXERCISE]

Executive Team asks:

"How do we know future communications are genuine?"

Required decisions:

- Verification processes.
- Employee guidance.
- Customer messaging.
```

---

# 9. Critical Decision Areas

---

# Decision Area 1 — Trust Verification

Questions:

* How is identity proven?
* What channels are trusted?

---

# Decision Area 2 — Business Process Protection

Questions:

* Can urgent requests bypass controls?
* Are approvals resilient?

---

# Decision Area 3 — Security Awareness

Questions:

* Are employees prepared for AI deception?

---

# Decision Area 4 — Reputation Protection

Questions:

* How does the company respond to impersonation?

---

# 10. Observer Evaluation Framework

Observers should assess:

---

## Human Verification

Questions:

* Were verification steps followed?
* Did urgency override controls?

---

## Identity Security

Questions:

* Were suspicious activities detected?
* Were accounts protected?

---

## Business Controls

Questions:

* Were financial workflows resilient?

---

## Communication

Questions:

* Was misinformation managed?

---

# 11. Expected AAR Findings

Potential findings:

| Finding                                        | Category   |
| ---------------------------------------------- | ---------- |
| Executive verification process immature        | Governance |
| Business workflows vulnerable to impersonation | Process    |
| AI threat awareness insufficient               | Training   |
| Identity monitoring requires improvement       | Detection  |
| External communication controls unclear        | Reputation |

---

# 12. Exercise Success Criteria

The exercise succeeds when participants demonstrate:

✓ Identity verification under pressure.

✓ Resistance to social engineering.

✓ Strong business process controls.

✓ Cross-functional coordination.

✓ Understanding of AI-enabled threats.

---

# End of Appendix H.5

## Next Section

# Appendix H.6 — OT / ICS Cyber-Physical Advanced MSEL Package

The next module will address the highest-consequence scenario class:

* Industrial control compromise.
* Production disruption.
* Safety implications.
* IT/OT coordination.
* Operational shutdown decisions.
* Cyber-physical risk management.
