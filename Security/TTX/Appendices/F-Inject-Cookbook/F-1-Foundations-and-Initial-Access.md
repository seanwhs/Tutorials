---

title: Appendix F – Part 1
subtitle: Facilitator's Inject Cookbook – Foundations & Initial Access
description: A reusable library of tabletop exercise injects organized by attack lifecycle, beginning with initial access, identity, authentication, and early-stage compromise.
type: appendix
category: facilitator
version: 1.0
tags:
- ttx
- injects
- facilitator
- scenarios

---

# Appendix F — Facilitator's Inject Cookbook

# Part 1 — Foundations & Initial Access

> *Injects are the engine of a tabletop exercise. A good inject introduces uncertainty. A great inject forces meaningful decisions.*

Unlike technical indicators, injects are **facilitation tools**. Their purpose is to stimulate discussion, test assumptions, reveal process gaps, and encourage collaboration across technical and business teams.

A mature facilitator does not ask, "What should happen next?" Instead, they ask, "What information would naturally emerge next if this incident were real?"

---

# What Is an Inject?

An **inject** is any planned event introduced into an exercise that prompts participants to take action, make decisions, request information, or reassess their understanding of the scenario.

Injects can be delivered through many channels:

* Email
* Chat message
* Phone call
* Help desk ticket
* SIEM alert
* News article
* Executive briefing
* Physical observation
* Social media post
* Vendor notification
* Mock screenshot
* Voice role-play

The most effective injects are believable, relevant, and timed to support the exercise objectives.

---

# Anatomy of an Inject

Each inject in this cookbook includes:

* **Objective** – The capability being tested.
* **Difficulty** – L1 (Introductory) to L4 (Advanced).
* **Recommended Timing** – Typical point in the exercise.
* **Delivery Method** – How the inject is presented.
* **Expected Discussion** – Topics participants should explore.
* **Facilitator Notes** – Guidance for steering the conversation.
* **Variations** – Ways to scale the inject for different maturity levels.

---

# Category 1 — Initial Access

These injects introduce the first indications that something may be wrong.

Participants should focus on verification, triage, and early incident assessment.

---

# Inject IA-01 — Impossible Travel Login

## Objective

Assess identity validation and authentication monitoring.

### Difficulty

L1–L4

### Timing

T+05

### Delivery

SIEM alert

### Expected Discussion

* Is this malicious?
* Could there be a legitimate explanation?
* What evidence should be gathered?
* Who owns the investigation?

### Facilitator Notes

Do not confirm whether the alert represents a compromise. Encourage participants to identify what additional information they need.

### Variations

**L1:** Single suspicious login.

**L2:** Multiple impossible travel events.

**L3:** Login followed by privileged activity.

**L4:** Multiple compromised identities across business units.

---

# Inject IA-02 — Vendor MFA Fatigue

## Objective

Evaluate identity protection procedures.

### Difficulty

L2

### Delivery

Help desk ticket

### Scenario

A vendor reports repeated MFA approval requests they did not initiate.

### Discussion

* Is this credential theft?
* Should access be disabled immediately?
* How should the vendor be contacted?

---

# Inject IA-03 — Phishing Email Report

## Objective

Evaluate security awareness.

### Delivery

Email

### Scenario

A Finance employee reports a suspicious invoice attachment.

### Facilitator Questions

* Has anyone else received it?
* Should additional mailboxes be searched?
* How should users be informed?

---

# Inject IA-04 — Password Reset Request

## Objective

Validate executive identity verification.

### Delivery

Help desk call

### Scenario

An executive requests an urgent password reset while travelling internationally.

### Discussion

Participants should balance customer service with identity assurance.

---

# Inject IA-05 — Anonymous Security Tip

## Objective

Assess evidence validation.

### Delivery

Anonymous reporting portal

### Scenario

An employee claims administrators are hiding an earlier security incident.

### Discussion

* Should anonymous reports change incident priority?
* How should claims be verified?

---

# Category 2 — Identity & Authentication

Compromised identities remain one of the most common attack vectors.

These injects test governance rather than technical implementation.

---

# Inject ID-01 — Privileged Group Change

## Objective

Validate change management.

### Scenario

An administrator account appears in a privileged security group without an approved change request.

### Expected Discussion

* Authorized or unauthorized?
* How is ownership determined?
* Should access be removed immediately?

---

# Inject ID-02 — Dormant Account Login

## Objective

Evaluate identity lifecycle management.

### Scenario

A user account that has not authenticated for eight months suddenly becomes active.

### Facilitator Notes

This inject often reveals weaknesses in account review processes.

---

# Inject ID-03 — Former Employee VPN Access

## Objective

Test deprovisioning procedures.

### Scenario

HR confirms an employee departed yesterday.

Security identifies a successful VPN login today.

### Discussion

* Was the account disabled?
* Are additional accounts affected?
* Does this indicate a process failure?

---

# Inject ID-04 — Shared Administrator Credentials

## Objective

Challenge governance practices.

### Scenario

Investigation reveals several administrators share the same privileged account.

### Expected Discussion

* Accountability
* Auditability
* Risk
* Immediate mitigation

---

# Category 3 — User Reports

Not every incident begins with a SIEM alert.

Sometimes users notice the first warning signs.

---

# Inject UR-01 — Slow Computer Complaint

### Objective

Differentiate operational issues from security concerns.

Scenario

Several users report unusually slow computers.

Facilitator Twist

Initially, there is no obvious evidence linking the reports.

---

# Inject UR-02 — Unexpected File Names

Employees report unfamiliar file extensions appearing in shared folders.

Should participants immediately suspect ransomware?

---

# Inject UR-03 — Printer Produces Random Pages

Several network printers begin printing unreadable documents.

Discussion

* Operational fault?
* Malware?
* Insider prank?

---

# Inject UR-04 — Customer Reports Strange Emails

Customers begin reporting emails appearing to originate from the organization.

Questions

* Has the email platform been compromised?
* Is this simple spoofing?
* Who investigates?

---

# Facilitator Tips

Avoid presenting every user report as genuine.

Some reports may represent:

* coincidence,
* misunderstanding,
* unrelated outages,
* operational issues,
* genuine indicators of compromise.

The team's ability to investigate objectively is more important than whether they correctly guess the scenario.

---

# Scaling Difficulty

Every inject can be adapted.

| Level  | Characteristics                                                                |
| ------ | ------------------------------------------------------------------------------ |
| **L1** | Single event, clear evidence, guided discussion                                |
| **L2** | Multiple related events requiring collaboration                                |
| **L3** | Ambiguous evidence, conflicting priorities, executive involvement              |
| **L4** | Simultaneous incidents, incomplete information, sustained operational pressure |

Changing the difficulty often requires only minor adjustments to timing, supporting evidence, or stakeholder involvement.

---

# Inject Sequencing

Good injects build naturally upon one another.

For example:

```text
Suspicious Login
        │
        ▼
Help Desk Call
        │
        ▼
EDR Alert
        │
        ▼
Vendor Notification
        │
        ▼
Executive Briefing
```

Each inject should increase understanding or introduce a new decision—not merely add noise.

---

# Common Facilitator Mistakes

Avoid these common pitfalls:

* Revealing the answer too early.
* Introducing unrelated injects.
* Overloading participants with simultaneous events.
* Rewarding guesswork instead of structured analysis.
* Ignoring participant requests for additional information.
* Using injects that do not support the exercise objectives.

Remember that injects exist to guide learning, not to confuse participants.

---

# Design Principles

An effective opening phase should establish curiosity rather than certainty.

Participants should gradually build a shared understanding of the situation by gathering evidence, validating assumptions, and coordinating across teams.

Early injects should emphasize disciplined investigation and communication rather than rapid technical action.

This concludes **Part 1 – Foundations & Initial Access** of the Facilitator's Inject Cookbook.

Subsequent parts expand into credential compromise, insider threats, cloud attacks, ransomware, executive pressure, business continuity, recovery, and advanced facilitation techniques, providing a comprehensive library of reusable injects for exercises ranging from introductory workshops to enterprise-scale crisis simulations.
