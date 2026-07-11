---

title: Appendix H
section: H.6
subtitle: OT / ICS Cyber-Physical Advanced MSEL Package
description: Complete tabletop exercise package for industrial control system cyber incident.
classification: "TLP:GREEN"
version: 1.0
---

# H.6 OT / ICS Cyber-Physical Advanced MSEL Package

## Scenario Name

# Operation Iron Shield

> *A cyber-physical resilience exercise testing response to industrial control system compromise, operational disruption, and safety-driven decision-making.*

---

# 1. Exercise Overview

## Exercise Type

Advanced Cyber-Physical Crisis Tabletop Exercise

---

## Scenario Category

Operational Technology (OT) / Industrial Control System (ICS)

---

## Primary Threat Theme

A cyber attack affects industrial environments, creating potential consequences across:

* Production.
* Safety.
* Supply chain.
* Physical operations.

---

## Target Environment

Example environment:

* Manufacturing plant.
* Industrial control systems.
* Supervisory Control and Data Acquisition (SCADA).
* Programmable Logic Controllers (PLC).
* Engineering workstations.
* Industrial networks.
* Safety systems.

---

# 2. Scenario Background

The organization operates multiple industrial facilities.

The environment consists of:

* Corporate IT networks.
* Industrial OT networks.
* Remote maintenance access.
* Third-party engineering support.

Operational priorities include:

* Production availability.
* Worker safety.
* Product quality.
* Regulatory compliance.

Existing controls include:

* Network segmentation.
* Endpoint protection.
* Access controls.

However:

* IT and OT teams operate separately.
* Asset visibility is incomplete.
* Incident response procedures are primarily IT-focused.

---

# 3. Initial Scenario Narrative

A manufacturing facility reports unusual behaviour.

Operators observe:

* Unexpected equipment alarms.
* Intermittent process interruptions.
* Engineering workstation alerts.

The production team initially suspects:

* Equipment failure.
* Configuration issue.
* Network instability.

Security investigation later identifies:

* Unauthorized access to an engineering workstation.
* Suspicious commands sent to industrial systems.

---

# 4. Exercise Objectives

The exercise evaluates the organization's ability to:

---

# Objective 1 — Protect Human Safety

Evaluate:

* Safety escalation.
* Operational shutdown decisions.
* Risk acceptance.

---

# Objective 2 — Coordinate IT and OT Response

Evaluate:

* Joint incident management.
* Communication.
* Ownership.

---

# Objective 3 — Detect Cyber-Physical Threats

Evaluate:

* Visibility.
* Investigation capability.
* Threat understanding.

---

# Objective 4 — Maintain Business Continuity

Evaluate:

* Production priorities.
* Alternative operating procedures.
* Recovery planning.

---

# Objective 5 — Manage External Stakeholders

Evaluate:

* Regulators.
* Customers.
* Suppliers.
* Public communication.

---

# 5. Rules of Engagement

## Exercise Boundaries

This is a simulated industrial cyber incident.

No operational systems will be changed.

---

## Participants Should

* Discuss safety implications.
* Evaluate operational choices.
* Identify responsibilities.

---

## Participants Should Not

* Assume IT controls are sufficient.
* Prioritize production over safety.
* Treat OT as identical to IT.

---

# 6. Participant Roles

## OT Operations Team

Responsibilities:

* Monitor industrial processes.
* Assess operational impact.

---

## Control Engineers

Responsibilities:

* Understand equipment behaviour.
* Recommend technical actions.

---

## Security Operations

Responsibilities:

* Investigate cyber indicators.
* Coordinate threat response.

---

## IT Infrastructure

Responsibilities:

* Support containment.
* Manage enterprise systems.

---

## Plant Management

Responsibilities:

* Balance safety and production.

---

## Safety Officer

Responsibilities:

* Protect personnel.
* Evaluate physical risks.

---

## Supply Chain Team

Responsibilities:

* Assess downstream impact.

---

## Executive Leadership

Responsibilities:

* Accept operational risk.
* Approve major decisions.

---

# 7. Threat Narrative

Simulated attacker progression:

```text id="f8k1qp"
Initial Access

       ↓

IT Network Compromise

       ↓

OT Network Access

       ↓

Engineering Workstation Compromise

       ↓

Control System Manipulation

       ↓

Operational Impact
```

---

# 8. Master Scenario Events List (MSEL)

---

# Phase 1 — Operational Anomaly

## Time

T+00

---

## Inject H6-001

### Production Alert

```markdown id="r3w7nx"
[TTX-EXERCISE]

Plant Operations Alert

Operators report:

- Unexpected equipment behaviour.
- Multiple system alarms.
- Intermittent production interruption.

Initial assumption:

Possible equipment malfunction.

Question:

Who should be notified?
```

---

## Expected Discussion

Participants should consider:

* Operations escalation.
* Security involvement.
* Safety assessment.

---

## Observer Focus

Capture:

* Whether cyber is considered early.
* IT/OT communication.

---

# Phase 2 — Cyber Evidence Appears

## Time

T+45

---

## Inject H6-002

### Security Investigation

```markdown id="v8q2kd"
[TTX-EXERCISE]

Security Findings

Evidence indicates:

- Unauthorized remote access.
- Compromised engineering workstation.
- Suspicious configuration changes.

Question:

Is this now a cyber incident?
```

---

# Expected Discussion

Topics:

* Incident declaration.
* OT containment.
* Evidence preservation.

---

# Phase 3 — Safety Decision

## Time

T+90

---

## Inject H6-003

### Safety Risk Emerges

```markdown id="m4c9zs"
[TTX-EXERCISE]

Engineering Assessment

Certain process parameters are changing unexpectedly.

Potential outcomes:

- Equipment damage.
- Product quality issues.
- Personnel safety concerns.

Question:

Should production continue?
```

---

# Decision Tension

| Choice             | Risk                  |
| ------------------ | --------------------- |
| Continue operation | Safety impact         |
| Shutdown systems   | Production loss       |
| Partial isolation  | Uncertain containment |

---

# Phase 4 — IT/OT Containment Challenge

## Time

T+150

---

## Inject H6-004

### Network Isolation Proposal

```markdown id="w7n5qa"
[TTX-EXERCISE]

Security Recommendation

Disconnect affected OT segment from enterprise network.

Operations Response:

"This may stop production."

Question:

Who makes the decision?
```

---

# Expected Discussion

Participants should identify:

* Decision authority.
* Safety priority.
* Risk acceptance.

---

# Phase 5 — Supply Chain Impact

## Time

T+210

---

## Inject H6-005

### Customer Impact

```markdown id="p5x8lm"
[TTX-EXERCISE]

Business Update

Production delays may affect:

- Customer deliveries.
- Supplier commitments.
- Contract obligations.

Question:

How should business priorities be managed?
```

---

# Phase 6 — Recovery Decision

## Time

T+270

---

## Inject H6-006

### Restoration Planning

```markdown id="z2r6cf"
[TTX-EXERCISE]

Recovery Team Report

Before restarting operations:

Required validation:

- System integrity.
- Safety checks.
- Configuration review.

Question:

Who approves restart?
```

---

# 9. Critical Decision Areas

---

# Decision Area 1 — Safety vs Availability

Primary principle:

> Safety takes priority over production.

Questions:

* What conditions require shutdown?
* Who has authority?

---

# Decision Area 2 — IT/OT Coordination

Questions:

* Who leads?
* Are responsibilities clear?

---

# Decision Area 3 — Operational Recovery

Questions:

* How is safe restoration validated?
* Who approves restart?

---

# Decision Area 4 — External Communication

Questions:

* Are regulators notified?
* Are customers informed?

---

# 10. Observer Evaluation Framework

Observers should assess:

---

## Safety Management

Questions:

* Was safety prioritized?
* Were risks understood?

---

## IT/OT Collaboration

Questions:

* Did teams coordinate?
* Was technical language understood?

---

## Incident Command

Questions:

* Was authority clear?

---

## Recovery Governance

Questions:

* Were restart criteria defined?

---

# 11. Expected AAR Findings

Potential findings:

| Finding                                          | Category          |
| ------------------------------------------------ | ----------------- |
| IT/OT incident ownership unclear                 | Governance        |
| Industrial asset inventory incomplete            | Visibility        |
| Cyber response procedures lack OT considerations | Process           |
| Recovery restart authority unclear               | Operations        |
| Third-party maintenance access requires review   | Access Management |

---

# 12. Exercise Success Criteria

The exercise succeeds when participants demonstrate:

✓ Safety-first decision-making.

✓ Effective IT/OT collaboration.

✓ Clear operational ownership.

✓ Controlled recovery.

✓ Understanding of cyber-physical consequences.

---

# End of Appendix H.6

## Next Section

# Appendix H.7 — Multi-Scenario Enterprise Cyber Crisis Simulation

The next module will combine multiple threat types into a higher-maturity exercise:

* Initial cloud compromise.
* Ransomware escalation.
* Third-party involvement.
* AI-enabled deception.
* Executive crisis management.
* Supply chain impact.

This represents a **Level 4 enterprise resilience simulation**.
