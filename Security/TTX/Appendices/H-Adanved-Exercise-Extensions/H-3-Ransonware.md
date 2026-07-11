---

title: Appendix H
section: H.3
subtitle: Ransomware Crisis Advanced MSEL Package
description: Complete tabletop exercise package for enterprise ransomware response.
classification: "TLP:GREEN"
version: 1.0
---

# H.3 Ransomware Crisis Advanced MSEL Package

## Scenario Name

# Operation Dark Winter

> *A ransomware crisis exercise testing enterprise response, business continuity, recovery confidence, and executive decision-making.*

---

# 1. Exercise Overview

## Exercise Type

Advanced Cyber Crisis Tabletop Exercise

---

## Scenario Category

Ransomware / Business Disruption

---

## Primary Threat Theme

A coordinated ransomware attack disrupts critical business operations after attackers compromise enterprise systems.

---

## Target Environment

Example environment:

* Corporate network.
* Identity infrastructure.
* File services.
* Business applications.
* Manufacturing systems.
* Backup environment.
* Cloud workloads.

---

# 2. Scenario Background

The organization operates globally with:

* Multiple business units.
* Distributed IT environments.
* Critical operational systems.
* External suppliers.

The organization has:

* Endpoint protection.
* Backup capabilities.
* Incident response procedures.

However:

* Recovery testing has been inconsistent.
* Business dependency mapping is incomplete.
* Decision ownership during major disruption is unclear.

---

# 3. Initial Scenario Narrative

At 04:30 local time, the Security Operations Center receives multiple endpoint alerts.

The alerts indicate:

* Suspicious encryption activity.
* Unusual administrative commands.
* Disabled security controls.

Within one hour:

* Several file servers become unavailable.
* Users report inability to access business systems.
* The incident response team begins investigation.

---

# 4. Exercise Objectives

The exercise evaluates the organization's ability to:

---

# Objective 1 — Detect and Contain Ransomware

Evaluate:

* Alert response.
* Investigation.
* Isolation decisions.
* Evidence preservation.

---

# Objective 2 — Coordinate Enterprise Response

Evaluate:

* Incident command.
* Executive involvement.
* Business alignment.

---

# Objective 3 — Maintain Business Continuity

Evaluate:

* Critical process identification.
* Operational prioritization.
* Alternative procedures.

---

# Objective 4 — Recover Safely

Evaluate:

* Backup confidence.
* Restoration decisions.
* Security validation.

---

# Objective 5 — Manage Crisis Communication

Evaluate:

* Internal messaging.
* Customer communication.
* Media response.

---

# 5. Rules of Engagement

## Exercise Boundaries

This is a simulated ransomware event.

No production systems will be modified.

---

## Participants Should

* Discuss decisions.
* Identify responsibilities.
* Consider real-world constraints.

---

## Participants Should Not

* Assume unlimited resources.
* Skip approval processes.
* Treat recovery as purely technical.

---

# 6. Participant Roles

## Incident Commander

Responsible for:

* Overall coordination.
* Prioritization.
* Escalation.

---

## Security Operations

Responsible for:

* Detection.
* Threat analysis.
* Containment recommendations.

---

## IT Infrastructure

Responsible for:

* System isolation.
* Restoration planning.
* Infrastructure recovery.

---

## Identity Team

Responsible for:

* Account compromise investigation.
* Credential reset strategy.

---

## Business Operations

Responsible for:

* Defining critical services.
* Accepting operational risk.

---

## Manufacturing / OT Leadership

Responsible for:

* Production impact.
* Safety considerations.

---

## Legal / Compliance

Responsible for:

* Regulatory obligations.
* Legal risk.

---

## Communications

Responsible for:

* Messaging strategy.
* Stakeholder communication.

---

## Executive Leadership

Responsible for:

* Strategic decisions.
* Risk acceptance.

---

# 7. Attack Narrative

The simulated attacker progression:

```text id="z9kq2f"
Initial Access

      ↓

Credential Theft

      ↓

Privilege Escalation

      ↓

Lateral Movement

      ↓

Backup Targeting

      ↓

Ransomware Deployment
```

---

# 8. Master Scenario Events List (MSEL)

---

# Phase 1 — Initial Detection

## Time

T+00

---

## Inject H3-001

### Endpoint Security Alert

```markdown id="3l4mnb"
[TTX-EXERCISE]

Endpoint Detection Alert

Multiple systems report:

- Suspicious file modification activity.
- Encryption behaviour detected.
- Security tooling disabled.

Affected systems:

- User laptops.
- Shared file services.

Question:

What is the immediate response?
```

---

## Expected Discussion

Participants should consider:

* Incident declaration.
* Scope assessment.
* Containment.

---

## Observer Focus

Capture:

* Escalation speed.
* Decision ownership.
* Initial assumptions.

---

# Phase 2 — Spread Assessment

## Time

T+30

---

## Inject H3-002

### Lateral Movement Evidence

```markdown id="q6g4ra"
[TTX-EXERCISE]

Investigation Update

Security identifies:

- Compromised administrator account.
- Access to multiple servers.
- Remote execution activity.

Question:

How far has the attacker progressed?
```

---

## Expected Discussion

Topics:

* Identity compromise.
* Privileged access review.
* Network isolation.

---

# Phase 3 — Enterprise Disruption

## Time

T+60

---

## Inject H3-003

### Business Systems Offline

```markdown id="cx9m4w"
[TTX-EXERCISE]

Business Impact Update

The following services are unavailable:

- ERP system.
- Shared documents.
- Internal applications.

Business leaders request:

"How long until normal operations resume?"

Question:

Who owns the response?
```

---

## Decision Point

Should leadership:

A. Focus on technical recovery?

B. Activate crisis management?

C. Wait for more information?

---

# Phase 4 — Backup Compromise

## Time

T+90

---

## Inject H3-004

### Backup Integrity Warning

```markdown id="v6as2k"
[TTX-EXERCISE]

Backup Monitoring Alert

Investigation shows:

- Recent backups exist.
- Some backup systems show unusual access activity.
- Restore confidence is uncertain.

Question:

Can recovery begin?
```

---

## Expected Discussion

Participants should consider:

* Backup validation.
* Recovery priority.
* Security verification.

---

# Phase 5 — Ransom Demand

## Time

T+150

---

## Inject H3-005

### Ransom Communication

```markdown id="2y5wqn"
[TTX-EXERCISE]

Threat Actor Message

Your systems are encrypted.

We have copied selected data.

You have limited time to respond.

Question:

What decisions are required?
```

---

# Decision Tensions

| Decision               | Conflict                        |
| ---------------------- | ------------------------------- |
| Pay ransom             | Recovery speed vs policy        |
| Continue investigation | Evidence vs operational urgency |
| Notify customers       | Transparency vs reputation      |
| Restore systems        | Recovery vs reinfection risk    |

---

# Phase 6 — External Pressure

## Time

T+210

---

## Inject H3-006

### Media Inquiry

```markdown id="9pmw0k"
[TTX-EXERCISE]

Media Request

A journalist asks:

"Has your company experienced a ransomware attack affecting customers?"

Response requested within two hours.

Question:

Who responds?
What can be confirmed?
```

---

# Phase 7 — Recovery Decision

## Time

T+270

---

## Inject H3-007

### Restoration Approval

```markdown id="k1n4xq"
[TTX-EXERCISE]

Recovery Team Report

Initial assessment:

- Clean backups identified.
- Systems require rebuilding.
- Restoration may take several days.

Question:

What systems are restored first?
Who approves priorities?
```

---

# 9. Critical Decision Areas

---

# Decision Area 1 — Containment

Questions:

* How aggressive should isolation be?
* What business impact is acceptable?

---

# Decision Area 2 — Recovery

Questions:

* Are backups trustworthy?
* Has attacker persistence been removed?

---

# Decision Area 3 — Communication

Questions:

* When should stakeholders be notified?
* Who approves messaging?

---

# Decision Area 4 — Executive Risk

Questions:

* Who accepts operational risk?
* What information is needed?

---

# 10. Observer Evaluation Framework

Observers should assess:

---

## Incident Command

Questions:

* Was command established?
* Were responsibilities clear?

---

## Technical Response

Questions:

* Was containment effective?
* Was evidence preserved?

---

## Business Continuity

Questions:

* Were critical services identified?
* Were priorities agreed?

---

## Recovery Readiness

Questions:

* Were backups trusted?
* Was restoration validated?

---

## Communication

Questions:

* Were messages coordinated?
* Were facts separated from assumptions?

---

# 11. Expected AAR Findings

Potential findings:

| Finding                               | Category            |
| ------------------------------------- | ------------------- |
| Recovery priorities unclear           | Business Continuity |
| Backup testing insufficient           | Resilience          |
| Privileged access controls weak       | Identity            |
| Crisis communication approval unclear | Governance          |
| Incident command escalation delayed   | Process             |

---

# 12. Exercise Success Criteria

The exercise succeeds when participants demonstrate:

✓ Rapid recognition of enterprise impact.

✓ Coordinated leadership response.

✓ Evidence-based recovery decisions.

✓ Understanding of business priorities.

✓ Ability to communicate under pressure.

---

# End of Appendix H.3

## Next Section

# Appendix H.4 — Insider Threat Advanced MSEL Package

The next module will cover:

* Malicious insider scenario.
* Compromised employee identity.
* Data exfiltration.
* HR/legal coordination.
* Privacy considerations.
* Investigation versus employee rights.
* Executive decision pressure.
