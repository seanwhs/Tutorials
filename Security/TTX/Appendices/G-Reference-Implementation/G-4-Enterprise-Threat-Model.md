---

title: Appendix G
section: G.4
subtitle: Enterprise Threat Model
description: Business-driven threat model supporting Operation Red Horizon.
classification: TLP:CLEAR (Exercise Use Only)
---

# G.4 Enterprise Threat Model

> *"A tabletop exercise should never begin with an attack. It should begin with a risk."*

---

# Purpose of this Section

The previous chapters established three essential foundations:

* The organization and its strategic priorities.
* The enterprise architecture supporting critical business services.
* The current cyber threat landscape.

This section connects those foundations through structured threat modeling.

Rather than asking, *"How could an attacker compromise our network?"*, the exercise asks a more useful business question:

> **"Which risks could materially disrupt our ability to achieve our business objectives, and how might those risks realistically unfold?"**

The resulting threat model provides the analytical basis for Operation Red Horizon.

It identifies the business assets worth protecting, the trust relationships most likely to be exploited, the attack paths available to a capable adversary, and the defensive assumptions that participants will examine during the exercise.

---

# Threat Modeling Objectives

The threat model has five objectives:

* Identify the organization's most valuable business assets.
* Understand the trust relationships that enable normal operations.
* Determine realistic attack paths.
* Evaluate potential business consequences.
* Select a scenario that exercises meaningful organizational decisions.

The emphasis is not on exhaustive technical analysis but on supporting effective exercise design.

---

# Business Assets

The first step is to identify what the organization cannot afford to lose.

| Asset                             | Business Value           | Primary Security Concern |
| --------------------------------- | ------------------------ | ------------------------ |
| Manufacturing Operations          | Revenue generation       | Availability             |
| Engineering Intellectual Property | Competitive advantage    | Confidentiality          |
| Enterprise Identity Services      | Organization-wide trust  | Integrity & Availability |
| ERP Platform                      | Business operations      | Availability             |
| Customer Information              | Commercial relationships | Confidentiality          |
| Supply Chain Platform             | Manufacturing continuity | Availability             |
| Executive Communications          | Crisis leadership        | Integrity                |

Each asset represents a potential objective for an attacker and a potential decision point for exercise participants.

---

# Business Dependencies

Critical services rarely operate independently.

The following simplified dependency model illustrates the relationships most relevant to the exercise.

```text
Identity Services
        │
        ▼
Enterprise Applications
        │
        ▼
Manufacturing Operations
        │
        ▼
Supply Chain
        │
        ▼
Customer Commitments
```

A disruption affecting identity services, for example, has consequences far beyond user authentication. It influences access to enterprise applications, manufacturing systems, vendor connectivity, and executive communications.

Understanding these dependencies helps participants evaluate containment decisions throughout the exercise.

---

# Trust Relationships

Modern enterprises depend on trust.

The following relationships are essential to normal operations:

* Employees trust corporate identity services.
* Manufacturing systems trust enterprise authentication.
* Cloud services trust federated identities.
* Vendors trust remote access gateways.
* Business applications trust shared identity providers.
* Executives trust operational reporting.
* Customers trust digital services.

Every trusted relationship creates potential opportunities for abuse.

Operation Red Horizon focuses on the compromise of one such relationship: trusted vendor access.

---

# Threat Actors

Several categories of adversaries could reasonably target ACME Manufacturing Group.

| Threat Actor                         | Motivation                 | Likelihood | Exercise Focus |
| ------------------------------------ | -------------------------- | ---------- | -------------- |
| Financially motivated cybercriminals | Extortion                  | High       | ✔              |
| Nation-state espionage               | Intelligence collection    | Medium     |                |
| Insider threat                       | Personal gain or grievance | Medium     |                |
| Opportunistic attackers              | Financial gain             | Medium     |                |
| Hacktivists                          | Publicity                  | Low        |                |

Although multiple threats exist, the exercise concentrates on financially motivated attackers because they create the greatest combination of operational disruption, executive pressure, and cross-functional decision-making.

---

# Threat Scenarios Considered

During exercise planning, several scenarios were evaluated.

### Business Email Compromise

Rejected because it primarily exercises finance and executive communications rather than enterprise-wide incident response.

---

### Insider Threat

Rejected because it introduces complex human resource and legal considerations that distract from the intended learning objectives.

---

### Cloud Misconfiguration

Rejected because it focuses heavily on cloud engineering rather than organizational crisis management.

---

### Operational Technology Attack

Deferred for a future exercise focused specifically on industrial control systems.

---

### Supply Chain Compromise

Selected.

This scenario exercises:

* Third-party risk management.
* Identity security.
* Enterprise incident response.
* Executive decision-making.
* Manufacturing continuity.
* Crisis communications.
* Regulatory considerations.
* Business recovery.

It provides the broadest organizational learning opportunity.

---

# Initial Attack Path

The exercise models a realistic progression from compromise to impact.

```text
Trusted Vendor Account
        │
        ▼
Remote Access Authentication
        │
        ▼
Internal Discovery
        │
        ▼
Privilege Escalation
        │
        ▼
Lateral Movement
        │
        ▼
Sensitive Data Access
        │
        ▼
Ransomware Deployment
```

This progression reflects commonly observed intrusion patterns while remaining understandable for participants from both technical and business backgrounds.

---

# Trust Boundary Analysis

Several trust boundaries become focal points during the exercise.

| Boundary                                    | Risk                      |
| ------------------------------------------- | ------------------------- |
| Vendor → Enterprise                         | Compromised credentials   |
| Enterprise → Cloud                          | Identity federation abuse |
| Enterprise → OT                             | Operational disruption    |
| Administrator → Critical Systems            | Privilege misuse          |
| Executive Decision-Making → Crisis Response | Delayed containment       |
| Business Operations → Recovery              | Conflicting priorities    |

Participants must continually assess whether these trust boundaries remain reliable as new information emerges.

---

# Assumptions

The threat model is built on several planning assumptions.

* The attacker possesses valid credentials.
* Initial compromise has already occurred before detection.
* Existing security controls continue operating normally.
* Not every alert indicates malicious activity.
* Business leaders initially possess limited situational awareness.
* Production continues unless containment decisions change operational conditions.

These assumptions maintain realism while avoiding unnecessary technical complexity.

---

# Key Decision Points

Rather than prescribing technical actions, the threat model identifies the organizational decisions the exercise intends to explore.

Examples include:

* When should the Incident Response Team be formally activated?
* When should executive leadership be informed?
* Should vendor access be immediately disabled?
* When does suspicious activity justify business disruption?
* How should evidence uncertainty influence containment?
* When should legal counsel become involved?
* At what point should customers or regulators be notified?
* When should business continuity plans be activated?

These decision points become the backbone of the Master Scenario Events List (MSEL).

---

# Threat Model Summary

The analysis identifies one dominant organizational risk:

> **A trusted third-party relationship provides the attacker with an opportunity to gain legitimate access to enterprise systems, creating uncertainty that delays detection while increasing the likelihood of significant operational and business impact.**

This statement summarizes the central challenge that Operation Red Horizon is designed to explore.

It is not the ransomware itself that creates the learning opportunity.

It is the series of decisions made **before** the ransomware appears.

---

# From Threat Model to Scenario

At this stage, the planning team has completed the analytical work.

The organization is understood.

The technology landscape is documented.

The threat intelligence has been assessed.

The attack paths have been evaluated.

The critical business risks have been identified.

The next step is no longer analysis.

It is storytelling.

The scenario translates the threat model into a realistic sequence of events that participants will experience during the tabletop exercise. Every inject, artifact, and decision point that follows is rooted in the analysis presented here, ensuring that the exercise remains credible, internally consistent, and aligned with the organization's business objectives.

The next section presents the Exercise Charter, where those objectives are formalized and the planning assumptions are converted into an executable exercise.
