---

title: Appendix G
section: G.9
subtitle: Scenario Narrative & Exercise Timeline
description: Canonical scenario narrative for Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
---

# G.9 Scenario Narrative & Exercise Timeline

> *"A good scenario tells a believable story. A great scenario creates believable decisions."*

---

# Purpose of the Scenario

Operation Red Horizon is designed to simulate a realistic enterprise cyber incident that evolves gradually over time.

Rather than beginning with an obvious ransomware outbreak, the scenario starts with weak signals—isolated events that appear individually explainable but collectively reveal a coordinated attack.

Participants are expected to:

* Detect emerging patterns.
* Validate assumptions.
* Escalate appropriately.
* Balance operational continuity with cybersecurity risk.
* Coordinate across business functions.
* Manage increasing executive pressure.
* Prepare for business recovery.

The scenario intentionally mirrors the uncertainty and ambiguity experienced during real-world incidents.

---

# Background

Several days before the exercise begins, a trusted third-party maintenance provider unknowingly suffers a credential compromise.

The attacker acquires legitimate VPN credentials used to support remote maintenance activities for ACME Manufacturing Group.

Because the authentication appears valid and originates from an approved vendor account, the initial intrusion bypasses many traditional perimeter defenses.

Over the following days, the attacker quietly explores the environment, identifies privileged systems, and establishes a broader understanding of the organization's technology landscape.

No disruptive activity has yet occurred.

At the official start of the exercise, participants are unaware that the compromise has already progressed beyond the initial access phase.

---

# Scenario Objectives

The scenario has been deliberately constructed to exercise organizational—not merely technical—capabilities.

Primary objectives include:

* Detecting subtle indicators of compromise.
* Managing uncertainty.
* Coordinating cross-functional response.
* Protecting critical manufacturing operations.
* Managing third-party cyber risk.
* Communicating effectively with executives.
* Balancing containment against business continuity.
* Planning recovery under incomplete information.

---

# Narrative Structure

The scenario unfolds through six progressive phases.

```text id="g9phase"
Phase 1 → Weak Signals
        │
        ▼
Phase 2 → Investigation
        │
        ▼
Phase 3 → Escalation
        │
        ▼
Phase 4 → Business Impact
        │
        ▼
Phase 5 → Crisis Management
        │
        ▼
Phase 6 → Recovery
```

Each phase introduces new information, additional stakeholders, and increasingly complex decisions.

---

# Phase 1 — Weak Signals

The exercise begins during a routine business morning.

Security monitoring systems generate several alerts.

Individually, none appear particularly alarming.

Examples include:

* An unusual vendor login.
* A small number of failed authentication attempts.
* Administrative activity outside normal maintenance windows.
* Limited internal network scanning.
* Endpoint detection alerts classified as low confidence.

Operational systems remain healthy.

Manufacturing continues normally.

At this stage, participants face their first challenge:

**Are these isolated anomalies or early indicators of a coordinated attack?**

---

## Expected Discussion

Participants typically explore:

* Alert validation.
* User verification.
* Vendor confirmation.
* Initial triage.
* Logging and evidence collection.
* Escalation thresholds.

The emphasis is on disciplined investigation rather than immediate containment.

---

# Phase 2 — Investigation

As additional information becomes available, isolated alerts begin forming a recognizable pattern.

New findings include:

* Authentication from an unfamiliar device.
* Access to systems outside the vendor's normal responsibilities.
* Internal reconnaissance activity.
* Unusual PowerShell execution.
* Requests for privileged resources.

Confidence that malicious activity may be occurring increases.

However, significant uncertainty remains.

Participants must now decide whether available evidence justifies activating formal incident response procedures.

---

## Business Questions

Discussion shifts from technical investigation toward organizational implications.

Questions include:

* Who needs to know?
* What business services could be affected?
* Should executive leadership be informed?
* Should vendor access be suspended?
* What evidence is still missing?

---

# Phase 3 — Escalation

The investigation now confirms unauthorized activity.

The Incident Response Team is formally activated.

Additional indicators emerge.

Examples include:

* Privilege escalation.
* Lateral movement.
* Access to engineering documentation.
* Suspicious administrative sessions.
* Potential data staging.

Although business operations continue, organizational concern increases significantly.

Executive leadership requests frequent situation updates.

Legal counsel begins evaluating notification obligations.

Corporate Communications prepares holding statements.

The exercise broadens from cybersecurity to enterprise crisis management.

---

## Decision Points

Participants should evaluate:

* Containment options.
* Operational consequences.
* Customer impact.
* Third-party coordination.
* Executive reporting cadence.
* Crisis governance activation.

---

# Phase 4 — Business Impact

The attacker begins taking actions that affect business operations.

Possible developments include:

* Manufacturing slowdown.
* File server disruption.
* Backup integrity concerns.
* Customer portal degradation.
* Increased media speculation.

Although ransomware has not yet been deployed, business disruption becomes increasingly visible.

Executives face difficult choices.

Isolating systems may reduce cyber risk but interrupt manufacturing.

Maintaining operations may preserve production but increase attacker freedom.

The scenario intentionally creates tension between security and business continuity.

---

# Phase 5 — Crisis Management

Operational disruption now becomes organization-wide.

Executive leadership activates enterprise crisis management.

New pressures emerge simultaneously.

Examples include:

* Journalist inquiries.
* Customer questions.
* Vendor communications.
* Board updates.
* Legal advice.
* Regulatory considerations.

Technical response is no longer the primary challenge.

Leadership, governance, communication, and prioritization become the dominant themes.

Participants must continuously balance:

* Speed.
* Accuracy.
* Transparency.
* Business continuity.
* Long-term organizational trust.

---

# Phase 6 — Recovery

The attacker has been contained.

Attention shifts toward recovery.

Key activities include:

* System restoration.
* Identity assurance.
* Backup validation.
* Business prioritization.
* Customer communication.
* Executive reporting.
* Lessons learned.

Recovery is intentionally presented as a business process rather than a technical event.

Participants discuss:

* Recovery sequencing.
* Risk acceptance.
* Return-to-service criteria.
* Monitoring requirements.
* Long-term improvements.

---

# Escalation Timeline

The exercise follows an approximate progression.

| Exercise Time | Scenario Event                     |
| ------------- | ---------------------------------- |
| T+00          | Initial alerts                     |
| T+20          | Vendor anomaly confirmed           |
| T+45          | Internal reconnaissance identified |
| T+75          | Incident Response Team activated   |
| T+110         | Executive notification             |
| T+145         | Manufacturing impact emerges       |
| T+170         | Crisis Management Team activated   |
| T+210         | Recovery planning begins           |

Actual pacing may be adjusted by the White Cell to support participant discussion.

---

# Information Flow

Participants do not receive complete visibility.

Information reaches them through multiple channels.

Examples include:

* SIEM alerts.
* EDR findings.
* Help desk tickets.
* Vendor communications.
* Executive requests.
* Media inquiries.
* Customer reports.
* Internal status updates.

The White Cell controls the timing and completeness of information released through each channel.

---

# Hidden Scenario Truth

The following facts remain hidden unless specifically revealed through injects.

* Vendor credentials were stolen several days earlier.
* Initial reconnaissance has already succeeded.
* Sensitive engineering documentation has been staged.
* The attacker is prepared to deploy ransomware if uninterrupted.
* Several early alerts were dismissed as benign.
* No insider is involved.

These hidden facts provide consistency for adjudicating participant decisions.

---

# Learning Themes

Operation Red Horizon is built around several recurring themes.

* Trust can be exploited.
* Weak signals become strong evidence through correlation.
* Technical certainty is rarely available.
* Business decisions often precede technical certainty.
* Communication is a security control.
* Recovery begins long before eradication.

Facilitators should reinforce these themes during the Hot Wash and After Action Review.

---

# End State

The exercise concludes after participants have:

* Managed executive decision-making.
* Addressed operational disruption.
* Planned recovery.
* Identified immediate improvement opportunities.

The objective is not to "win" the scenario.

The objective is to strengthen organizational resilience through informed discussion and collaborative decision-making.

---

# Transition to the Next Section

The scenario narrative establishes **what happens** during Operation Red Horizon.

The next section transforms this narrative into an operational delivery tool: the **Master Scenario Events List (MSEL)**.

The MSEL provides the minute-by-minute execution plan used by the White Cell, including inject sequencing, delivery methods, expected participant actions, decision points, contingency branches, and facilitator notes.

Unlike the narrative, the MSEL is designed to be used live during the exercise and serves as the primary orchestration document for the exercise management team.
