---

title: Appendix D – Part 1
subtitle: Sample Artifact Library – Detection & Initial Response
description: A reusable library of realistic, synthetic cybersecurity exercise artifacts for use as tabletop exercise injects. This section focuses on detection, monitoring, and initial response artifacts.
type: appendix
category: sample-artifacts
version: 1.0
tags:
- ttx
- artifacts
- injects
- soc
- siem

---

# Appendix D — Sample Artifact Library

# Part 1 — Detection & Initial Response

> *Artifacts are the fuel that drives a tabletop exercise. Well-crafted artifacts create realism, encourage discussion, and force participants to make decisions based on incomplete information—the same conditions they face during a real incident.*

---

# About This Library

This appendix provides a collection of **synthetic, reusable artifacts** that can be adapted for almost any cybersecurity tabletop exercise.

Every artifact is intentionally fictional. They are designed to:

* simulate realistic operational evidence,
* encourage discussion,
* support facilitator injects,
* remain safe for publication,
* avoid using sensitive or proprietary information.

Each artifact includes:

* Exercise objective
* Recommended timing
* Delivery method
* Facilitator notes
* Sample content

Artifacts may be delivered through:

* Chat
* Email
* Help desk ticket
* Printed handout
* Slide
* Voice inject
* Screenshot
* Incident management system
* Collaboration platform

---

# Artifact 1 — SIEM Alert: Impossible Travel Login

## Exercise Objective

Validate identity verification, incident triage, and escalation.

---

## Recommended Timing

T+05

---

## Delivery Method

SOC chat

Incident ticket

Screenshot

---

## Facilitator Notes

Participants should determine:

* Is this a false positive?
* Has the account been compromised?
* Should access be disabled?
* Should the vendor be contacted?

---

### Sample Artifact

```text
[TTX-EXERCISE]

SIEM ALERT

Alert ID:
SIEM-2026-041

Severity:
High

Detection Time:
09:05

Rule:
Impossible Travel Authentication

User:
vendor.support@example.com

Previous Login:
Singapore

Current Login:
Frankfurt

Elapsed Time:
18 minutes

Risk Indicators

• New device fingerprint
• First login from country
• Privileged account
• VPN authentication successful

Recommended Action

Review authentication history.

Validate user identity.

Correlate with recent activity.
```

---

# Artifact 2 — Identity Provider Alert

## Objective

Test identity governance procedures.

---

### Sample

```text
Identity Protection Alert

Risk Level:
High

User:
administrator@company.com

Risk Detection

• New location
• Anonymous IP
• Password reset completed
• MFA challenge accepted

Confidence:
High

Recommended Investigation

Review account activity.

Verify recent administrative actions.

Determine whether credentials remain trustworthy.
```

---

# Artifact 3 — Endpoint Detection Alert

## Objective

Encourage endpoint investigation.

---

```text
EDR Detection

Host:
ENG-LAPTOP-204

Severity:
High

Detection

Suspicious PowerShell execution

Observed Activity

Encoded command

Credential access attempt

Process chain anomaly

MITRE ATT&CK

T1059

Confidence

Medium

Action

Investigate immediately.
```

---

# Artifact 4 — Network Detection Alert

## Objective

Identify lateral movement.

---

```text
Network Detection Alert

Alert ID:
NDR-117

Source Host

10.24.18.44

Activity

Internal network scanning detected.

Services Enumerated

3389

445

5985

22

Recommended Response

Determine asset ownership.

Correlate with authentication events.

Assess lateral movement risk.
```

---

# Artifact 5 — Firewall Alert

## Objective

Validate perimeter monitoring.

---

```text
Firewall Event

Severity

Medium

Source

185.xxx.xxx.xxx

Destination

VPN Gateway

Activity

Repeated authentication failures.

Blocked Connections

327

Time Window

15 Minutes

Suggested Action

Review authentication attempts.

Determine whether activity aligns with current threat intelligence.
```

---

# Artifact 6 — Cloud Security Alert

## Objective

Exercise cloud governance.

---

```text
Cloud Security Alert

Service

Object Storage

Finding

Public read permission enabled.

Bucket

project-finance

Risk

Sensitive documents may be exposed.

Action

Review access policy.

Determine ownership.

Validate recent configuration changes.
```

---

# Artifact 7 — Privileged Account Change

## Objective

Validate change management.

---

```text
Identity Management Event

Administrator Group Modified

User Added

svc-support-admin

Requested By

Unknown

Approval Record

Not Found

Recommended Action

Verify authorization.

Review change history.

Determine business justification.
```

---

# Artifact 8 — Backup Monitoring Alert

## Objective

Exercise recovery planning.

---

```text
Backup Monitoring

Status

Warning

Latest Backup

Successful

Immutable Snapshot

Verification Pending

Recovery Confidence

Unknown

Action

Perform verification.

Confirm restore readiness.
```

---

# Artifact 9 — Threat Intelligence Notification

## Objective

Determine whether external intelligence changes incident priority.

---

```text
Threat Intelligence Bulletin

Campaign

VendorTrust-2026

Summary

Multiple organizations report compromise through trusted vendor remote access accounts.

Observed Techniques

Credential Theft

Remote Access Abuse

Privilege Escalation

Recommendation

Review all vendor access activity over the previous seven days.
```

---

# Artifact 10 — SOC Analyst Escalation Note

## Objective

Prompt formal incident declaration.

---

```text
SOC Internal Note

Current Assessment

Confidence has increased following correlation between authentication alerts, endpoint activity, and internal network scanning.

Recommendation

Escalate to Incident Response.

Notify Incident Commander.

Preserve forensic evidence.
```

---

# Facilitator Guidance

These artifacts intentionally increase uncertainty rather than provide complete answers.

Participants should:

* correlate multiple sources,
* identify missing information,
* request additional evidence,
* discuss escalation thresholds,
* explain decision rationale.

Avoid confirming whether an alert represents malicious activity unless the scenario requires it.

---

# Suggested Inject Progression

| Time | Artifact                  | Purpose               |
| ---- | ------------------------- | --------------------- |
| T+05 | Impossible Travel Login   | Initial detection     |
| T+10 | Identity Protection Alert | Identity verification |
| T+15 | Endpoint Detection        | Endpoint compromise   |
| T+20 | Network Detection         | Lateral movement      |
| T+25 | Firewall Alert            | External activity     |
| T+35 | Threat Intelligence       | External context      |
| T+45 | Backup Warning            | Recovery planning     |

This progression gradually expands the participants' understanding of the incident while creating realistic decision pressure.

---

# Design Principles

Effective artifacts should:

* Look authentic without copying real production data.
* Contain enough information to prompt analysis, but not enough to eliminate uncertainty.
* Reinforce the exercise objectives rather than distract participants.
* Be internally consistent with the scenario and timeline.
* Encourage collaboration across technical and business roles.

Remember that the purpose of an artifact is not to reveal the "correct answer." Its purpose is to stimulate discussion, expose assumptions, and provide credible evidence upon which participants can base decisions.

This concludes **Part 1 – Detection & Initial Response** of the Sample Artifact Library. Later parts will build on these initial indicators by introducing operational pressure, executive decision-making, external communications, business disruption, and recovery challenges, allowing facilitators to scale exercises from simple investigations to full organizational crisis management.
