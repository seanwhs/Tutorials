---

title: Appendix H
section: H.1
subtitle: Advanced Exercise Extensions Overview
description: Scenario expansion library for enterprise cyber resilience tabletop exercises.
classification: TLP:GREEN
version: 1.0
---

# Appendix H — Advanced Exercise Extensions

## Enterprise Cyber Resilience Scenario Library

> *"Mature organizations do not practice one incident. They practice resilience against many possible futures."*

---

# H.1 Purpose

Appendix H provides advanced tabletop exercise scenarios that extend the Operation Red Horizon framework.

These scenarios are designed for organizations that already have:

* Established tabletop processes.
* Basic incident response capability.
* Defined exercise governance.
* Previous exercise experience.

The scenarios introduce additional complexity through:

* New technologies.
* New threat actors.
* New business pressures.
* New decision challenges.

---

# H.2 How to Use This Appendix

Each scenario extension can be used in three ways:

---

## Option 1 — Standalone Exercise

Run the scenario as a complete tabletop.

Example:

> Cloud Compromise Exercise

Duration:

2–4 hours

Participants:

Cloud, Security, IAM, Leadership

---

## Option 2 — Add-On Module

Insert the scenario into an existing exercise.

Example:

Operation Red Horizon:

Phase 4:

Add cloud workload compromise.

---

## Option 3 — Maturity Progression

Increase exercise difficulty over time.

Example:

Year 1:

Vendor compromise

↓

Year 2:

Cloud breach

↓

Year 3:

AI-enabled attack

↓

Year 4:

Cyber-physical crisis

---

# H.3 Scenario Library

The Advanced Exercise Extension Library includes:

---

# H.3.1 Cloud Breach Scenario

## Theme

Compromise of cloud infrastructure resulting in unauthorized access and data exposure.

---

## Threat Context

Modern enterprises increasingly depend on:

* Public cloud platforms.
* SaaS applications.
* Cloud-native workloads.
* Identity-based access.

Attackers increasingly target:

* Cloud identities.
* Misconfigured resources.
* CI/CD pipelines.
* API access.

---

## Scenario Summary

A compromised developer credential is used to access cloud resources.

The attacker:

1. Authenticates using a legitimate identity.
2. Enumerates cloud resources.
3. Creates persistence mechanisms.
4. Accesses sensitive data.
5. Attempts privilege escalation.

---

# Exercise Objectives

Evaluate:

## Identity Response

Can the organization:

* Detect abnormal cloud access?
* Disable compromised identities?
* Validate privilege scope?

---

## Cloud Visibility

Can teams answer:

* What resources are affected?
* What data was accessed?
* Who owns impacted systems?

---

## Business Decision-Making

Can leadership decide:

* Whether to shut down workloads?
* Whether to notify customers?
* Whether to involve regulators?

---

# Key Decision Points

| Decision           | Tension                     |
| ------------------ | --------------------------- |
| Disable account    | Security vs availability    |
| Isolate workload   | Containment vs disruption   |
| Rotate credentials | Speed vs completeness       |
| Notify customers   | Transparency vs uncertainty |

---

# Example Injects

## Inject 1 — Suspicious Cloud Login

```markdown
[TTX-EXERCISE]

Cloud Security Alert

Multiple authentication attempts detected from a developer account.

Indicators:

- Unusual geographic location.
- Access outside normal working hours.
- New API activity detected.

Question:

What actions should be taken?
```

---

## Inject 2 — Privilege Escalation

```markdown
[TTX-EXERCISE]

Cloud Audit Log Review

A developer identity created a new administrative role.

The activity was technically successful.

No approved change request exists.

Question:

Is this an incident?
Who owns the decision?
```

---

## Inject 3 — Data Exposure

```markdown
[TTX-EXERCISE]

Investigation Update

Security teams confirm unauthorized access to a storage bucket containing customer-related information.

Scope is unknown.

Question:

What actions are required?
```

---

# Expected Learning Outcomes

Participants should identify:

✓ Identity is the new security perimeter.

✓ Cloud incidents require different investigation skills.

✓ Asset ownership is critical.

✓ Business impact assessment must happen quickly.

---

# H.3.2 Ransomware Crisis Scenario

## Theme

Enterprise-wide ransomware affecting critical business operations.

---

## Scenario Summary

A malicious attachment results in:

* Endpoint compromise.
* Lateral movement.
* Privilege escalation.
* Encryption of critical systems.

---

# Exercise Objectives

Evaluate:

* Incident command.
* Business continuity.
* Recovery confidence.
* Executive decision-making.

---

# Scenario Progression

## Phase 1 — Initial Detection

Inject:

Multiple endpoints show unusual encryption activity.

---

## Phase 2 — Containment

Decision:

Should the organization:

* Disconnect network segments?
* Shut down systems?
* Continue operations?

---

## Phase 3 — Business Impact

Inject:

Manufacturing operations experience disruption.

---

## Phase 4 — Recovery

Inject:

Backup restoration confidence is uncertain.

---

# Key Decision Tensions

| Decision             | Conflict                   |
| -------------------- | -------------------------- |
| Shutdown systems     | Safety vs availability     |
| Restore quickly      | Speed vs security          |
| Pay ransom           | Recovery vs policy         |
| Communicate publicly | Transparency vs reputation |

---

# Expected Learning Outcomes

Participants understand:

* Recovery is a business decision.
* Backups require testing.
* Communication matters.
* Leadership must make risk decisions.

---

# H.3.3 Insider Threat Scenario

## Theme

Malicious or compromised employee activity.

---

## Scenario Summary

An employee account begins:

* Accessing unusual systems.
* Downloading sensitive files.
* Sharing information externally.

---

# Exercise Objectives

Evaluate:

* Detection capability.
* HR/security coordination.
* Investigation boundaries.
* Privacy considerations.

---

# Key Decision Points

| Decision         | Tension                               |
| ---------------- | ------------------------------------- |
| Disable account  | Security vs employee impact           |
| Monitor activity | Investigation vs privacy              |
| Notify employee  | Transparency vs evidence preservation |

---

# Expected Learning Outcomes

Participants identify:

* Insider threats require multiple functions.
* Security alone cannot manage the response.
* Legal and HR involvement is essential.

---

# H.3.4 AI-Enabled Attack Scenario

## Theme

Use of artificial intelligence by threat actors.

---

## Scenario Summary

Attackers use AI-assisted techniques to:

* Generate convincing phishing messages.
* Create synthetic voice communications.
* Automate reconnaissance.
* Adapt attack methods.

---

# Exercise Objectives

Evaluate:

* Human verification processes.
* Identity assurance.
* Security awareness.
* Executive decision-making.

---

# Example Inject

```markdown
[TTX-EXERCISE]

Executive Communication Alert

A senior executive receives a voice message requesting an urgent financial transfer.

Voice appears authentic.

No normal approval process was followed.

Question:

How should the request be validated?
```

---

# Expected Learning Outcomes

Participants understand:

✓ Trust assumptions must change.

✓ Verification processes become critical.

✓ AI increases attack speed and realism.

---

# H.3.5 OT / ICS Cyber-Physical Scenario

## Theme

Cyber attack affecting operational technology.

---

## Scenario Summary

Attackers compromise systems connected to industrial operations.

Potential impacts:

* Production disruption.
* Safety concerns.
* Equipment damage.
* Supply chain interruption.

---

# Exercise Objectives

Evaluate:

* IT/OT coordination.
* Safety prioritization.
* Operational decision-making.

---

# Key Decision Points

| Decision            | Conflict                  |
| ------------------- | ------------------------- |
| Shutdown production | Safety vs business impact |
| Isolate network     | Security vs operations    |
| Continue operation  | Revenue vs risk           |

---

# Expected Learning Outcomes

Participants understand:

* Cyber incidents can become physical events.
* Safety overrides availability.
* OT requires specialized response.

---

# H.4 Scenario Selection Guidance

Choose scenarios based on:

| Organizational Context   | Recommended Scenario |
| ------------------------ | -------------------- |
| Cloud-first company      | Cloud Breach         |
| Manufacturing            | OT/ICS               |
| Financial services       | Identity / Insider   |
| Global enterprise        | Ransomware           |
| Executive maturity focus | AI-enabled attack    |

---

# H.5 Scenario Difficulty Scaling

## Level 1 — Awareness

Focus:

* Discussion.
* Roles.
* Responsibilities.

---

## Level 2 — Coordination

Focus:

* Cross-team decisions.
* Escalation.

---

## Level 3 — Crisis Management

Focus:

* Leadership pressure.
* Business disruption.

---

## Level 4 — Enterprise Simulation

Focus:

* Multiple simultaneous failures.
* External stakeholders.
* Real-time decision pressure.

---

# End of Appendix H.1

## Next Section

# Appendix H.2 — Cloud Breach Advanced MSEL Package

The next section will expand the Cloud Breach scenario into a complete exercise package:

* Scenario narrative.
* Rules of engagement.
* Full inject timeline.
* Participant roles.
* Observer focus areas.
* Expected decision paths.
* AAR findings examples.
