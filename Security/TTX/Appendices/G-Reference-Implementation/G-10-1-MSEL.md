---

title: Appendix G
section: G.10.1
subtitle: Master Scenario Events List (MSEL) – Introduction and Operating Guide
description: How to use the Master Scenario Events List during Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0
---


# G.10.1 Master Scenario Events List (MSEL)

> *"The scenario provides the story. The MSEL controls how the story unfolds."*

---

# Purpose

The Master Scenario Events List (MSEL) is the operational script used by the White Cell to conduct Operation Red Horizon.

Unlike the Scenario Narrative, which describes the overall incident, the MSEL specifies **when**, **how**, and **to whom** information is released during the exercise.

It serves as the authoritative orchestration document for the exercise management team and ensures that all facilitators deliver a consistent experience while retaining the flexibility to adapt to participant decisions.

---

# What Is an MSEL?

An MSEL is a structured timeline of planned exercise events (known as **injects**) that drive discussion and decision-making.

Each inject introduces new information through a realistic communication channel, prompting participants to assess the situation, collaborate, and decide on appropriate actions.

The MSEL is not intended to force a single "correct" path. Instead, it creates opportunities for participants to demonstrate how they apply existing plans, procedures, and governance under evolving conditions.

---

# Relationship to Other Exercise Documents

The MSEL works alongside several other documents in the exercise package.

| Document            | Purpose                                                                     |
| ------------------- | --------------------------------------------------------------------------- |
| Exercise Charter    | Defines why the exercise exists.                                            |
| Rules of Engagement | Establishes governance, safety, and boundaries.                             |
| Participant Guide   | Prepares attendees without revealing the scenario.                          |
| Facilitator Guide   | Explains how the exercise is managed.                                       |
| Scenario Narrative  | Describes the canonical story.                                              |
| **MSEL**            | Controls the live execution of that story.                                  |
| Artifact Library    | Provides emails, alerts, transcripts, screenshots, and supporting evidence. |
| Observer Logs       | Capture participant behaviour and decisions.                                |
| After Action Review | Documents findings and improvement actions.                                 |

Together, these documents form a complete and repeatable exercise package.

---

# Anatomy of an Inject

Every inject within the MSEL follows a consistent structure.

| Field               | Description                                                                            |
| ------------------- | -------------------------------------------------------------------------------------- |
| Time                | Relative exercise time (for example, T+15).                                            |
| Inject ID           | Unique identifier (for example, RH-INJ-001).                                           |
| Phase               | Scenario phase in which the inject occurs.                                             |
| Delivery Method     | How participants receive the information (chat, email, phone, briefing, ticket, etc.). |
| Audience            | Individual, team, or all participants.                                                 |
| Inject Content      | The information presented to participants.                                             |
| Supporting Artifact | Reference to a document in the Artifact Library, if applicable.                        |
| Expected Discussion | Topics participants are likely to explore.                                             |
| Expected Actions    | Actions that demonstrate effective response.                                           |
| Facilitator Notes   | Guidance for the White Cell.                                                           |
| Observer Focus      | Behaviours or decisions observers should monitor.                                      |
| Branches            | Optional variations based on participant actions.                                      |

This standardized format makes the MSEL easier to follow during live facilitation.

---

# Inject Delivery Principles

The White Cell should observe the following principles when delivering injects:

### Realism

Injects should resemble communications that participants would encounter during an actual incident.

Examples include:

* SIEM alerts
* Help desk tickets
* Executive emails
* Vendor phone calls
* News reports
* Customer complaints
* Collaboration platform messages

---

### Progressive Disclosure

Information should be released gradually.

Participants should not receive complete visibility at the beginning of the exercise.

Instead, evidence accumulates over time, allowing participants to form—and revise—working hypotheses as new information becomes available.

---

### Decision-Driven Pacing

Injects should support discussion rather than dictate it.

The White Cell may delay or accelerate injects to allow meaningful conversation to develop before introducing new information.

---

### Controlled Ambiguity

Not every inject should provide definitive answers.

Real-world incidents often involve incomplete, conflicting, or delayed information.

Some injects are intentionally ambiguous to encourage critical thinking and information validation.

---

# Timing Strategy

Although each inject has a planned delivery time, timing should remain flexible.

The White Cell should consider:

* Participant engagement.
* Discussion quality.
* Progress toward learning objectives.
* Time remaining.
* Emerging participant decisions.

The objective is to create a realistic pace—not to adhere rigidly to the clock.

---

# Artifact References

Many injects reference supporting artifacts from the Exercise Artifact Library.

Examples include:

| Artifact ID | Description                          |
| ----------- | ------------------------------------ |
| ART-001     | SIEM Alert – Suspicious Vendor Login |
| ART-002     | Help Desk Verification Call          |
| ART-003     | Executive Situation Update           |
| ART-004     | Vendor Security Notification         |
| ART-005     | Journalist Inquiry                   |
| ART-006     | Backup Integrity Alert               |
| ART-007     | Internal Network Scan Report         |
| ART-008     | Ransom Note                          |

Using referenced artifacts avoids duplicating content and allows individual artifacts to be revised without modifying the MSEL.

---

# Branching and Flexibility

A professional MSEL supports multiple exercise paths.

For example:

* If participants immediately disable the compromised vendor account, later injects may focus on business disruption caused by containment.
* If participants delay containment, injects may escalate toward lateral movement and broader operational impact.
* If participants activate executive leadership early, governance discussions may begin sooner.
* If communication breaks down, media pressure may intensify.

The White Cell should adapt inject sequencing while preserving the overall learning objectives.

---

# Observer Integration

Observers should not simply record what participants say.

Instead, they should monitor:

* How decisions are made.
* Whether assumptions are challenged.
* Escalation timing.
* Leadership effectiveness.
* Cross-functional collaboration.
* Communication quality.
* Risk management.
* Use of existing procedures.

Each inject identifies specific observation opportunities to support a structured After Action Review.

---

# Naming Convention

Injects within Operation Red Horizon use the following format:

```text
RH-INJ-001
RH-INJ-002
RH-INJ-003
...
RH-INJ-065
```

Supporting artifacts use:

```text
ART-001
ART-002
ART-003
...
```

This naming convention simplifies cross-referencing between the MSEL, Artifact Library, Observer Logs, and After Action Review.

---

# Structure of the MSEL

The complete Master Scenario Events List is organized according to the six phases of the scenario.

| Phase   | Focus             |
| ------- | ----------------- |
| Phase 1 | Weak Signals      |
| Phase 2 | Investigation     |
| Phase 3 | Escalation        |
| Phase 4 | Business Impact   |
| Phase 5 | Crisis Management |
| Phase 6 | Recovery          |

Each phase introduces new information, new stakeholders, and increasingly complex decision points.

Together, they guide participants through the lifecycle of a realistic enterprise cybersecurity incident.

---

# Transition to Phase 1

The following section begins the operational execution of Operation Red Horizon.

Phase 1 introduces the first weak signals of compromise through routine operational alerts and seemingly unrelated events.

Individually, these injects appear minor.

Collectively, they establish the pattern that participants must recognize if they are to respond effectively as the exercise unfolds.

The White Cell should resist confirming participant suspicions too early, allowing discussion, uncertainty, and evidence correlation to develop naturally.
