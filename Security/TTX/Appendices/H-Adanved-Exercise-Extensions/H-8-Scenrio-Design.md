---

title: Appendix H
section: H.8
subtitle: Exercise Design Guide and Scenario Builder
description: Framework for designing future cybersecurity tabletop exercises.
classification: "TLP:GREEN"
version: 1.0
---

# H.8 Exercise Design Guide and Scenario Builder

## Enterprise Cyber Resilience Exercise Development Framework

> *"A mature exercise program does not repeat yesterday's incident. It prepares for tomorrow's uncertainty."*

---

# 1. Purpose

This guide provides a repeatable method for creating new cybersecurity tabletop exercises.

It enables organizations to design scenarios that:

* Reflect current risks.
* Challenge decision-making.
* Test organizational readiness.
* Produce measurable improvements.

---

# 2. Exercise Design Lifecycle

The recommended design lifecycle:

```text id="f7x2km"
Identify Risk

      ↓

Define Objectives

      ↓

Build Scenario

      ↓

Create Injects

      ↓

Map Decisions

      ↓

Prepare Participants

      ↓

Execute Exercise

      ↓

Capture Lessons

      ↓

Improve Capability
```

---

# 3. Step 1 — Identify Exercise Theme

Start with a strategic question.

Examples:

## Technology Change

Question:

> "What happens if our new cloud platform is compromised?"

Scenario:

Cloud identity attack.

---

## Business Dependency

Question:

> "What happens if our critical supplier fails?"

Scenario:

Third-party cyber crisis.

---

## Emerging Threat

Question:

> "What happens if attackers use AI deception against executives?"

Scenario:

AI-enabled fraud.

---

## Operational Risk

Question:

> "What happens if cyber affects physical operations?"

Scenario:

OT/ICS compromise.

---

# 4. Step 2 — Define Exercise Objectives

Every exercise should have clear objectives.

Avoid:

> "Test cybersecurity readiness."

Too broad.

---

Better:

> "Evaluate whether the organization can identify, contain, and communicate during a cloud identity compromise."

---

# Objective Categories

## Detection

Can we identify the problem?

---

## Response

Can we contain the threat?

---

## Coordination

Can teams work together?

---

## Decision-Making

Can leaders make informed choices?

---

## Recovery

Can operations resume safely?

---

# 5. Step 3 — Select Scenario Type

Use the scenario selection matrix.

| Scenario       | Best For               |
| -------------- | ---------------------- |
| Cloud Breach   | Cloud maturity         |
| Ransomware     | Crisis response        |
| Insider Threat | Governance             |
| AI Attack      | Emerging risks         |
| OT/ICS         | Operational resilience |
| Supply Chain   | Third-party risk       |
| Data Breach    | Privacy response       |

---

# 6. Step 4 — Build the Threat Narrative

A good scenario requires:

## Threat Actor

Who is attacking?

Examples:

* Cybercriminal group.
* Nation-state actor.
* Insider.
* Hacktivist.

---

## Motivation

Why attack?

Examples:

* Financial gain.
* Espionage.
* Disruption.
* Reputation damage.

---

## Attack Path

How does compromise occur?

Example:

```text id="d2m8vz"
Phishing

 ↓

Credential Theft

 ↓

Privilege Escalation

 ↓

Data Access

 ↓

Business Impact
```

---

## Impact

What changes for the organization?

Examples:

* Systems unavailable.
* Data exposed.
* Operations disrupted.
* Customer impact.

---

# 7. Step 5 — Design Injects

Injects drive the exercise.

A good inject should create:

* New information.
* New pressure.
* New decisions.

---

# Inject Formula

```text id="z5v1nx"
Situation

+

Evidence

+

Uncertainty

+

Decision Required
```

---

## Example

Weak inject:

> "A ransomware attack occurs."

---

Strong inject:

```markdown id="r8q4mf"
Systems are unavailable.

Investigation confirms ransomware activity.

Backup availability is uncertain.

Leadership asks:

Should critical systems be restored immediately?
```

---

# 8. Step 6 — Design Decision Points

Exercises should not only create discussion.

They should create choices.

---

# Decision Types

## Operational Decision

Example:

Should systems be isolated?

---

## Risk Decision

Example:

Should business operations continue?

---

## Communication Decision

Example:

Should customers be notified?

---

## Governance Decision

Example:

Who approves recovery?

---

# 9. Step 7 — Map Expected Outcomes

For each decision, define:

## Desired Behaviour

What should participants demonstrate?

---

## Common Failure Modes

What problems should the exercise reveal?

---

## Improvement Opportunities

What actions may result?

---

# Decision Mapping Template

```markdown id="m5q9wd"
# Decision Point

Scenario:

Decision Required:

Options:

1.
2.
3.

Expected Considerations:

Risks:

Owner:

Observer Focus:

Potential Findings:
```

---

# 10. Step 8 — Build Observer Guidance

Observers need:

* What to watch.
* What evidence to collect.
* What questions to ask.

---

# Observer Focus Areas

## Governance

* Is ownership clear?

---

## Process

* Are procedures followed?

---

## Technology

* Are capabilities sufficient?

---

## People

* Are teams coordinated?

---

# 11. Step 9 — Align With AAR

Every exercise should produce actionable improvement.

Map:

```text id="w8m2cq"
Exercise Observation

        ↓

Finding

        ↓

Risk

        ↓

Recommendation

        ↓

Owner

        ↓

Validation
```

---

# 12. Scenario Complexity Model

Organizations should gradually increase difficulty.

---

# Level 1 — Awareness Exercise

Focus:

* Roles.
* Responsibilities.
* Basic response.

Participants:

Small teams.

---

# Level 2 — Coordination Exercise

Focus:

* Cross-functional communication.
* Escalation.

Participants:

Multiple departments.

---

# Level 3 — Crisis Exercise

Focus:

* Executive decisions.
* Business disruption.

Participants:

Leadership.

---

# Level 4 — Enterprise Simulation

Focus:

* Multiple failures.
* External pressure.
* Real-time decisions.

Participants:

Entire organization.

---

# 13. Exercise Quality Checklist

Before execution:

☐ Objectives are clear.
☐ Scenario is realistic.
☐ Participants understand roles.
☐ Injects create decisions.
☐ Observers understand evaluation criteria.
☐ AAR process is prepared.

---

# 14. Common Scenario Design Mistakes

---

# Mistake 1 — Testing Technology Only

Weak:

> "Can the firewall block the attack?"

Better:

> "Can the organization make the right business decisions during the attack?"

---

# Mistake 2 — Making the Scenario Too Perfect

Real incidents include:

* Missing information.
* Conflicting priorities.
* Human uncertainty.

---

# Mistake 3 — No Business Impact

Cyber exercises must connect to:

* Customers.
* Revenue.
* Operations.
* Reputation.

---

# Mistake 4 — No Follow-Up

A scenario without improvement tracking creates little value.

---

# 15. Scenario Builder Template

```markdown id="a9k4tp"
# Exercise Scenario Builder

## Exercise Name

## Business Context

## Threat Actor

## Attack Narrative

## Exercise Objectives

1.
2.
3.

## Participants

## Scenario Timeline

## Injects

## Decision Points

## Observer Focus

## Expected Findings

## Improvement Actions

## Validation Method
```

---

# 16. Future Scenario Ideas

Organizations may create additional modules:

---

## Cloud Supply Chain Attack

Theme:

Compromise of software provider.

---

## Quantum-Resistant Migration Failure

Theme:

Cryptographic transition risk.

---

## AI Model Security Incident

Theme:

Compromised AI system affecting business decisions.

---

## Data Poisoning Scenario

Theme:

Manipulated analytics and decision systems.

---

## Regulatory Crisis

Theme:

Cyber incident requiring executive and regulator coordination.

---

# 17. Final Appendix H Assessment

Appendix H transforms the tabletop exercise framework into a reusable enterprise capability.

The organization now has:

✓ Baseline exercise framework.

✓ Advanced scenario library.

✓ Multi-domain crisis simulation.

✓ Scenario creation methodology.

✓ Continuous improvement model.

---

# Final Message

The strongest cybersecurity programs do not ask:

> "Can we prevent every attack?"

They ask:

> "When prevention fails, can we detect quickly, decide wisely, recover safely, and improve continuously?"

A mature tabletop exercise program builds exactly that capability.

---

# End of Appendix H

## Enterprise Cyber Resilience Exercise Library Complete

**Operation Red Horizon → Advanced Scenario Library → Continuous Improvement Capability**
