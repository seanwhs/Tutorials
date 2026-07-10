---

title: Appendix F – Part 2
subtitle: Facilitator's Inject Cookbook – Credential Compromise, Insider Threat & Lateral Movement
description: A reusable library of tabletop exercise injects focused on identity compromise, insider risk, privilege escalation, persistence, and lateral movement.
type: appendix
category: facilitator
version: 1.0
tags:
- ttx
- injects
- identity
- insider-threat
- lateral-movement
- privilege-escalation

---

# Appendix F — Facilitator's Inject Cookbook

# Part 2 — Credential Compromise, Insider Threat & Lateral Movement

> *Most modern cyberattacks succeed not because malware is sophisticated, but because identities are compromised, trust relationships are abused, and attackers move through environments without being challenged.*

Once participants have identified an initial security concern, the exercise should evolve naturally toward questions of identity, privilege, persistence, and internal movement.

The purpose of these injects is not to "prove" that an attacker exists. Instead, they encourage participants to evaluate evidence, challenge assumptions, and make coordinated decisions while the picture is still incomplete.

---

# Learning Objectives

These injects help evaluate an organization's ability to:

* Validate suspicious authentication activity.
* Detect privileged account misuse.
* Coordinate with Human Resources and business owners.
* Investigate insider threat indicators.
* Respond to unauthorized administrative activity.
* Identify lateral movement.
* Balance operational continuity with containment.

---

# Category 4 — Credential Compromise

---

# Inject CC-01 — Password Spraying Detected

## Objective

Evaluate identity monitoring and authentication controls.

### Difficulty

L2

### Timing

T+20

### Delivery

SIEM Alert

### Scenario

Authentication monitoring identifies hundreds of failed login attempts against multiple employee accounts from a single external IP address.

A small number of accounts later authenticate successfully.

### Expected Discussion

* Is this credential stuffing or password spraying?
* Which accounts should be investigated first?
* Should password resets be initiated?
* Is executive notification required?

### Facilitator Notes

Encourage participants to discuss containment options before assuming account compromise.

---

# Inject CC-02 — Service Account Authentication

## Objective

Assess service account governance.

### Scenario

A legacy service account authenticates interactively for the first time in several years.

### Discussion

* Is interactive login expected?
* Who owns the account?
* Should the account be disabled immediately?

---

# Inject CC-03 — MFA Enrollment Changed

## Objective

Test identity recovery procedures.

### Scenario

A privileged administrator account registers a new MFA device during non-business hours.

### Facilitator Questions

* Was this change authorized?
* How should identity be verified?
* Should emergency access procedures be invoked?

---

# Inject CC-04 — Privileged Session Detected

## Objective

Exercise privileged access management.

### Scenario

A privileged administrative session remains active for several hours while simultaneously accessing multiple systems.

### Discussion

* Is this expected administrative behavior?
* How should privileged sessions be monitored?
* What additional telemetry is required?

---

# Category 5 — Insider Threat

Insider-related injects are intentionally ambiguous.

Participants should avoid assuming malicious intent without evidence.

---

# Inject IT-01 — Large USB Data Copy

## Objective

Evaluate insider investigation procedures.

### Scenario

Endpoint monitoring reports a large file transfer to removable media.

### Additional Context

The employee is scheduled to leave the organization next week.

### Discussion

* Legitimate business activity?
* Intellectual property concern?
* Human Resources involvement?

---

# Inject IT-02 — Suspicious Printing Activity

## Objective

Introduce physical data handling concerns.

### Scenario

An employee prints several hundred pages of engineering documentation shortly before leaving the office.

### Facilitator Notes

Participants should discuss proportional investigation rather than immediate disciplinary action.

---

# Inject IT-03 — Cloud File Sharing

## Objective

Exercise data governance.

### Scenario

Large volumes of internal documents appear to have been shared with a newly created external collaboration account.

### Discussion

* Was the sharing intentional?
* Are approval processes documented?
* Should sharing be suspended?

---

# Inject IT-04 — Executive Assistant Request

## Objective

Test verification procedures.

### Scenario

An executive assistant requests immediate access to confidential financial records on behalf of a senior executive.

### Facilitator Twist

The executive is currently travelling and cannot immediately confirm the request.

---

# Category 6 — Privilege Escalation

---

# Inject PE-01 — New Domain Administrator

## Objective

Assess change validation.

### Scenario

Monitoring identifies a newly created Domain Administrator account.

No approved change record exists.

### Discussion

* Who owns the investigation?
* Is this an emergency?
* Should access be revoked immediately?

---

# Inject PE-02 — Disabled Logging

## Objective

Exercise detection engineering.

### Scenario

Audit logging has been disabled on several production servers.

### Facilitator Questions

* Coincidence?
* Maintenance?
* Evidence tampering?

---

# Inject PE-03 — Security Tool Uninstalled

## Objective

Validate endpoint protection monitoring.

### Scenario

Endpoint protection software is removed from multiple systems within a short period.

### Discussion

* Authorized maintenance?
* Administrative misuse?
* Active attacker?

---

# Category 7 — Lateral Movement

These injects gradually increase operational complexity.

---

# Inject LM-01 — Internal Port Scanning

## Objective

Assess internal network visibility.

### Scenario

Network monitoring detects repeated service discovery across multiple internal subnets.

### Discussion

* Who owns the host?
* Is vulnerability scanning scheduled?
* Should network segmentation be adjusted?

---

# Inject LM-02 — Remote Administration Activity

## Objective

Validate remote administration governance.

### Scenario

Administrative tools are used to connect to systems that have never previously communicated.

### Facilitator Notes

Encourage participants to distinguish between legitimate administration and attacker behavior.

---

# Inject LM-03 — Remote PowerShell Execution

## Objective

Evaluate endpoint detection.

### Scenario

Security monitoring identifies remote PowerShell execution against multiple servers.

### Expected Discussion

* Change activity?
* Administrative automation?
* Malicious lateral movement?

---

# Inject LM-04 — Authentication Across Business Units

## Objective

Test enterprise coordination.

### Scenario

A single privileged account authenticates across geographically separated business units within a short period.

### Discussion

Participants should consider:

* Federation
* Identity compromise
* Administrative maintenance
* Logging accuracy

---

# Category 8 — Persistence

---

# Inject PS-01 — Scheduled Task Created

## Objective

Evaluate persistence detection.

### Scenario

Endpoint monitoring detects a newly created scheduled task executing every hour.

---

# Inject PS-02 — Startup Service Added

## Objective

Assess endpoint investigation.

### Scenario

A new Windows service appears across several production systems.

Ownership cannot immediately be determined.

---

# Facilitator Guidance

As the exercise progresses, participants should begin recognizing relationships between previously isolated events.

For example:

```text id="attack-progression"
Password Spraying
        │
        ▼
Compromised Account
        │
        ▼
Privilege Escalation
        │
        ▼
Remote Administration
        │
        ▼
Internal Scanning
        │
        ▼
Persistence
```

Participants should explain **why** they believe events are connected rather than simply assuming an attack chain.

---

# Facilitator Escalation Techniques

Increase complexity by introducing:

* conflicting evidence,
* delayed notifications,
* incomplete logs,
* unavailable subject matter experts,
* simultaneous business priorities,
* uncertain ownership.

Avoid escalating complexity merely by adding more alerts.

Each new inject should require participants to make a new decision.

---

# Difficulty Variations

| Level  | Example Adaptation                                                                                             |
| ------ | -------------------------------------------------------------------------------------------------------------- |
| **L1** | Single compromised account with complete logging.                                                              |
| **L2** | Multiple suspicious authentications requiring coordination.                                                    |
| **L3** | Privileged misuse combined with business pressure and incomplete evidence.                                     |
| **L4** | Simultaneous identity compromise across multiple regions with conflicting telemetry and executive involvement. |

---

# Discussion Prompts

Consider asking participants:

* What evidence supports your current assessment?
* What assumptions are you making?
* What additional telemetry would increase confidence?
* Who should own this decision?
* What are the risks of acting too quickly?
* What are the risks of waiting?

These questions encourage structured reasoning rather than intuitive guesswork.

---

# Design Principles

Identity compromise rarely presents itself as a single, obvious event. Instead, organizations observe a sequence of individually explainable activities that only become significant when correlated over time.

Effective injects mirror this reality. They encourage participants to synthesize information from identity systems, endpoint monitoring, network telemetry, business context, and human observations before deciding whether to escalate, contain, or continue investigating.

This concludes **Part 2 – Credential Compromise, Insider Threat & Lateral Movement** of the Facilitator's Inject Cookbook.

The next part expands beyond the enterprise perimeter into cloud environments, SaaS platforms, third-party suppliers, managed service providers, and software supply chain incidents, reflecting the increasingly interconnected nature of modern organizations.
