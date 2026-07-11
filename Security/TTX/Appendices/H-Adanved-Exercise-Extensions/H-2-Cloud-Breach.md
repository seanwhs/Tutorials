---

title: Appendix H
section: H.2
subtitle: Cloud Breach Advanced MSEL Package
description: Complete tabletop exercise package for cloud identity compromise scenario.
classification: "TLP:GREEN"
version: 1.0
---
# H.2 Cloud Breach Advanced MSEL Package

## Scenario Name

# Operation Cloud Horizon

> *A cloud identity compromise exercise testing enterprise response to unauthorized access, privilege escalation, and potential data exposure.*

---

# 1. Exercise Overview

## Exercise Type

Advanced Cybersecurity Tabletop Exercise

---

## Scenario Category

Cloud Security Incident

---

## Primary Threat Theme

Identity-based cloud compromise.

---

## Target Environment

Example environment:

* Public cloud workloads.
* SaaS applications.
* CI/CD pipelines.
* Cloud databases.
* Object storage.
* Identity platforms.

---

# 2. Scenario Background

The organization has rapidly expanded its cloud footprint.

Development teams use cloud-native services to accelerate delivery.

The environment includes:

* Multiple cloud accounts.
* Federated identities.
* Developer access.
* Automated deployment pipelines.
* Sensitive business applications.

Security monitoring exists but cloud visibility is still developing.

---

# 3. Initial Scenario Narrative

A software engineer reports unusual activity involving their cloud development account.

The engineer states:

> "I received a notification about a login from a location where I have never worked. I assumed it was a false alert."

The Security Operations Center begins reviewing cloud activity.

Initial evidence shows:

* Successful authentication.
* New device registration.
* API activity outside normal hours.
* Creation of unfamiliar cloud resources.

---

# 4. Exercise Objectives

The exercise evaluates the organization's ability to:

---

## Objective 1 — Detect Cloud Identity Abuse

Determine whether teams can:

* Recognize abnormal cloud activity.
* Correlate identity signals.
* Validate legitimate versus malicious actions.

---

## Objective 2 — Contain Cloud Compromise

Evaluate:

* Identity disabling.
* Credential rotation.
* Session termination.
* Resource isolation.

---

## Objective 3 — Understand Cloud Ownership

Assess whether teams know:

* Who owns cloud assets.
* Who approves access.
* Who makes containment decisions.

---

## Objective 4 — Manage Business Risk

Evaluate decisions involving:

* Application availability.
* Customer impact.
* Data exposure.
* Regulatory obligations.

---

# 5. Rules of Engagement

## Exercise Boundaries

This is a simulated event.

No real cloud changes will occur.

---

## Participants May

* Discuss hypothetical actions.
* Review simulated evidence.
* Make response decisions.

---

## Participants May Not

* Execute production changes.
* Access real environments.
* Contact real vendors or customers.

---

# 6. Participant Roles

## Cloud Security Team

Responsibilities:

* Analyze cloud activity.
* Recommend containment.
* Assess exposure.

---

## Security Operations Center

Responsibilities:

* Review alerts.
* Correlate events.
* Escalate findings.

---

## Cloud Platform Team

Responsibilities:

* Understand infrastructure impact.
* Support containment decisions.

---

## Application Teams

Responsibilities:

* Assess application impact.
* Identify business dependencies.

---

## Identity and Access Management

Responsibilities:

* Investigate credentials.
* Review permissions.
* Execute identity controls.

---

## Legal / Compliance

Responsibilities:

* Assess notification requirements.
* Evaluate regulatory impact.

---

## Executive Leadership

Responsibilities:

* Accept risk.
* Approve major business decisions.

---

# 7. Attack Narrative

The simulated attacker progression:

```text
Compromised Developer Credential

        ↓

Cloud Authentication

        ↓

Resource Discovery

        ↓

Privilege Escalation

        ↓

Data Access Attempt

        ↓

Persistence Creation
```

---

# 8. Master Scenario Events List (MSEL)

---

# Phase 1 — Initial Detection

## Time

T+00

---

## Inject H2-001

### Cloud Login Alert

```markdown
[TTX-EXERCISE]

Cloud Identity Alert

User:
developer.account@example

Detection:

Successful login from unfamiliar geography.

Indicators:

- New device fingerprint.
- Login outside normal working hours.
- Multiple failed authentication attempts before success.

Question:

Is this suspicious activity or normal user behaviour?
```

---

## Expected Discussion

Participants should consider:

* Identity validation.
* User confirmation.
* Additional evidence gathering.
* Escalation criteria.

---

## Observer Focus

Record:

* How quickly suspicious activity is recognized.
* Who owns investigation.
* Whether assumptions are documented.

---

# Phase 2 — Investigation

## Time

T+30

---

## Inject H2-002

### Cloud Audit Log Review

```markdown
[TTX-EXERCISE]

Cloud Audit Findings

The account performed:

- Enumeration of cloud resources.
- Listing of storage services.
- Access attempts against restricted resources.

No approved change request exists.

Question:

Does this represent a security incident?
```

---

## Expected Discussion

Teams should discuss:

* Incident declaration.
* Investigation scope.
* Evidence preservation.

---

## Decision Point

Should the account be:

A. Monitored?

B. Restricted?

C. Disabled?

---

# Phase 3 — Privilege Escalation

## Time

T+60

---

## Inject H2-003

### Administrative Role Created

```markdown
[TTX-EXERCISE]

Cloud Configuration Change

A new administrative role was created.

Created by:

Developer account

Approved change:

None found

Access:

Full cloud management privileges

Question:

What immediate actions are required?
```

---

## Expected Discussion

Possible actions:

* Disable identity.
* Remove unauthorized permissions.
* Review activity history.
* Preserve evidence.

---

## Observer Focus

Assess:

* Decision speed.
* Ownership clarity.
* Risk understanding.

---

# Phase 4 — Data Exposure

## Time

T+90

---

## Inject H2-004

### Storage Access Confirmed

```markdown
[TTX-EXERCISE]

Investigation Update

Security confirms unauthorized access to cloud storage.

Contents include:

- Customer documents.
- Application configuration files.
- Internal reports.

Scope:

Unknown.

Question:

What decisions must leadership make?
```

---

## Expected Discussion

Topics:

* Customer notification.
* Regulatory review.
* Forensic investigation.
* Business impact.

---

# Phase 5 — Business Pressure

## Time

T+150

---

## Inject H2-005

### Application Performance Impact

```markdown
[TTX-EXERCISE]

Business Update

Customers report application delays.

Engineering believes containment actions may affect service availability.

Question:

Should containment continue or be adjusted?
```

---

## Decision Tension

Security:

> Remove attacker access immediately.

Business:

> Maintain customer availability.

---

# Phase 6 — Recovery

## Time

T+210

---

## Inject H2-006

### Recovery Decision

```markdown
[TTX-EXERCISE]

Recovery Assessment

Teams need to decide:

- Restore affected services?
- Rotate all credentials?
- Conduct additional investigation?

Question:

What criteria must be satisfied before recovery?
```

---

# 9. Key Decision Matrix

| Decision         | Security Priority | Business Priority     |
| ---------------- | ----------------- | --------------------- |
| Disable identity | Stop attack       | Maintain productivity |
| Isolate workload | Prevent spread    | Maintain service      |
| Notify customers | Transparency      | Reputation impact     |
| Restore systems  | Recovery          | Risk of reinfection   |

---

# 10. Observer Evaluation Areas

Observers should evaluate:

## Identity Governance

Questions:

* Were privileges understood?
* Were access owners clear?

---

## Cloud Visibility

Questions:

* Could teams identify impacted resources?
* Were logs available?

---

## Incident Command

Questions:

* Was leadership clear?
* Were decisions tracked?

---

## Business Integration

Questions:

* Were business consequences considered?

---

# 11. Expected AAR Findings

Potential findings:

| Finding                            | Category      |
| ---------------------------------- | ------------- |
| Cloud asset ownership unclear      | Governance    |
| Excessive developer privileges     | Identity      |
| Limited cloud monitoring           | Detection     |
| Recovery criteria unclear          | Resilience    |
| Customer impact assessment delayed | Communication |

---

# 12. Exercise Success Criteria

The exercise succeeds when participants demonstrate:

✓ Clear ownership.

✓ Evidence-based decisions.

✓ Effective cloud incident coordination.

✓ Understanding of identity-based threats.

✓ Ability to balance security and business priorities.

---

# End of Appendix H.2

## Next Section

# Appendix H.3 — Ransomware Crisis Advanced MSEL Package

The next module will expand ransomware response into a full enterprise crisis exercise covering:

* Initial malware detection.
* Lateral movement.
* Encryption event.
* Business disruption.
* Executive decisions.
* Recovery versus ransom dilemma.
* Communications pressure.
* Post-incident improvement planning.
