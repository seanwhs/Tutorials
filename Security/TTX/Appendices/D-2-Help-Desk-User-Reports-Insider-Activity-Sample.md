---

title: Appendix D – Part 2
subtitle: Sample Artifact Library – Help Desk, User Reports & Insider Activity
description: Reusable synthetic exercise artifacts representing user reports, help desk tickets, insider activity, and human observations that often serve as the first indicators of compromise.
type: appendix
category: sample-artifacts
version: 1.0
tags:
- ttx
- artifacts
- helpdesk
- insider-threat
- user-reports

---

# Appendix D — Sample Artifact Library

# Part 2 — Help Desk, User Reports & Insider Activity

> *Technology rarely tells the whole story. Many cybersecurity incidents are first detected not by security tools, but by observant users, help desk analysts, business staff, or trusted third parties.*

While automated detection platforms provide valuable telemetry, they often require corroboration from human observations before incident responders can establish context and assess business impact.

This section provides reusable artifacts that simulate those human-generated signals.

---

# Artifact 11 — Help Desk Call: Suspicious Vendor Request

## Exercise Objective

Evaluate verification procedures for third-party requests.

---

## Recommended Timing

T+10

---

## Delivery Method

* Voice inject
* Help desk ticket
* Chat transcript

---

## Facilitator Notes

Participants should consider:

* How should the caller's identity be verified?
* Does the request align with existing support procedures?
* Should the vendor account be temporarily restricted?

---

### Sample Artifact

```text id="vd-helpdesk-01"
[TTX-EXERCISE]

Help Desk Call Record

Ticket:
HD-20418

Time:
09:14

Caller Statement

"Hi, someone from your IT department asked us to install a remote support tool this morning. Before we continue, we'd like to confirm that request."

Agent Notes

• Caller appeared uncertain.
• No ticket number provided.
• Callback number differs from vendor contact records.
• Vendor requested confirmation before proceeding.

Recommended Action

Verify through approved vendor contacts.

Escalate if connected to current security activity.
```

---

# Artifact 12 — Employee Phishing Report

## Exercise Objective

Assess phishing reporting and awareness.

---

```text id="user-phish-01"
Security Mailbox Submission

Subject

Suspicious Email

Employee

Finance Department

Message

"I received an invoice from one of our suppliers. The email looked unusual, so I didn't open the attachment."

Attachment Name

Invoice_July_2026.zip

Requested Action

Please verify whether this is legitimate.
```

---

# Artifact 13 — Password Reset Request

## Exercise Objective

Test identity verification.

---

```text id="helpdesk-reset"
Help Desk Ticket

Priority

High

Request

Executive requests immediate password reset.

Reason

Unable to authenticate after travelling.

Observation

Caller requested MFA to be temporarily disabled due to mobile device issues.

Recommended Action

Follow executive identity verification procedures.
```

---

# Artifact 14 — Internal User Complaint

## Exercise Objective

Introduce operational impact.

---

```text id="user-impact"
IT Support Ticket

Department

Engineering

Issue

Shared project files unavailable.

Symptoms

Files appear inaccessible.

Recent Observation

Several folders now display unfamiliar filenames.

Business Impact

Engineering work has stopped pending investigation.
```

---

# Artifact 15 — Department Manager Email

## Exercise Objective

Evaluate escalation thresholds.

---

```text id="manager-email"
Internal Email

Subject

Several Team Members Locked Out

Body

Three members of my department have reported authentication problems this morning.

Could someone confirm whether there is an ongoing issue?

Regards,

Department Manager
```

---

# Artifact 16 — Employee Security Concern

## Exercise Objective

Test reporting culture.

---

```text id="employee-report"
Internal Security Report

Employee Statement

"I'm not sure whether this is important, but I noticed someone using an administrator account during a late-night maintenance window that wasn't on our change calendar."

Time Observed

23:47

Requested Action

Please confirm whether this activity was authorized.
```

---

# Artifact 17 — Physical Security Observation

## Exercise Objective

Introduce physical security considerations.

---

```text id="physical-security"
Security Operations Report

Reception Desk

Visitor entered building using contractor credentials.

Observation

Individual was unable to identify their sponsor immediately.

Badge access logs indicate entry into restricted office areas.

Recommended Action

Verify visitor authorization.
```

---

# Artifact 18 — HR Notification

## Exercise Objective

Introduce insider-risk considerations.

---

```text id="hr-notification"
HR Advisory

Employee Status

Employment ended yesterday.

Observation

Identity account remains active.

VPN authentication recorded this morning.

Recommended Action

Confirm deprovisioning status immediately.
```

---

# Artifact 19 — Vendor Security Notification

## Exercise Objective

Exercise third-party incident coordination.

---

```text id="vendor-notice"
Vendor Security Advisory

Summary

We have identified suspicious authentication activity affecting one of our support environments.

Current Status

Investigation underway.

Potential Impact

Remote support accounts may have been accessed without authorization.

Requested Action

Review recent vendor access sessions.

Coordinate through established incident response contacts.
```

---

# Artifact 20 — Anonymous Internal Report

## Exercise Objective

Challenge participants to evaluate incomplete information.

---

```text id="anonymous-tip"
Anonymous Submission

"I don't know whether this is connected, but someone mentioned that our backups failed sometime last week and management didn't want to tell anyone."

Source

Anonymous reporting portal

Confidence

Unknown

Suggested Action

Validate backup status before drawing conclusions.
```

---

# Facilitator Guidance

These artifacts intentionally vary in credibility.

Some reports:

* are accurate,
* are incomplete,
* contain misunderstandings,
* represent genuine concern,
* require independent verification.

Participants should avoid dismissing reports simply because they originate from non-technical staff.

Likewise, they should avoid treating every report as confirmed evidence.

The exercise should encourage disciplined investigation rather than assumption.

---

# Discussion Prompts

Useful facilitator questions include:

* How do we verify this information?
* Does this align with existing evidence?
* Who owns this investigation?
* Does this change our incident severity?
* Should executive leadership be informed?
* What additional information is required?

---

# Suggested Exercise Flow

| Time | Artifact                  | Purpose                  |
| ---- | ------------------------- | ------------------------ |
| T+10 | Vendor Help Desk Call     | Identity verification    |
| T+15 | Employee Phishing Report  | User awareness           |
| T+20 | Password Reset Request    | Identity validation      |
| T+25 | Department Manager Email  | Business impact          |
| T+30 | Employee Security Concern | Insider observation      |
| T+35 | Physical Security Report  | Physical access          |
| T+40 | HR Advisory               | Insider risk             |
| T+45 | Vendor Security Notice    | Third-party coordination |
| T+50 | Anonymous Report          | Evidence validation      |

This progression gradually shifts the exercise from technical detection toward organizational decision-making by introducing multiple human perspectives.

---

# Design Principles

Human-generated artifacts should reflect the uncertainty, ambiguity, and incomplete information that characterize real-world incidents. They should encourage participants to corroborate reports with technical evidence, validate identities through established processes, and avoid making decisions based solely on anecdotal information.

By combining automated alerts from **Part 1** with the human observations in this section, facilitators can create richer scenarios that test not only technical investigation skills but also communication, judgment, and cross-functional collaboration.

This concludes **Part 2 – Help Desk, User Reports & Insider Activity** of the Sample Artifact Library.
