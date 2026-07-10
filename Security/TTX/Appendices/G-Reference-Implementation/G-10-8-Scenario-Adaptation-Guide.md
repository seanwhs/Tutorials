---

title: Appendix G
section: G.10.8
subtitle: Facilitator Branches, Decision Paths, and Scenario Adaptation Guide
description: White Cell guidance for adapting Operation Red Horizon during live execution.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0
---

# G.10.8 Facilitator Branches, Decision Paths, and Scenario Adaptation Guide

> *"A good tabletop exercise is not a performance of a script. It is a structured conversation designed to reveal capability gaps."*

---

# Purpose

The purpose of this section is to help facilitators manage unexpected participant decisions while maintaining the intended learning outcomes of Operation Red Horizon.

Participants may:

* Identify the compromise earlier than expected.
* Miss important indicators.
* Take aggressive containment actions.
* Delay escalation.
* Request information that was not planned.
* Introduce solutions outside the original scenario design.

The White Cell should not attempt to "correct" participants.

Instead, facilitators should:

1. Allow realistic consequences.
2. Preserve exercise objectives.
3. Introduce appropriate scenario adjustments.
4. Capture decision-making quality.

---

# Core Facilitation Principle

## Preserve Objectives, Not the Script

The MSEL provides structure, but the learning objectives are the true destination.

Example:

The planned storyline expects participants to discover unauthorized vendor access at T+60.

However:

* If participants identify it at T+20, accelerate later investigation injects.
* If participants ignore it until T+90, introduce additional evidence.
* If participants take immediate containment action, explore business consequences.

The exercise succeeds when participants demonstrate effective decision-making—not when injects occur exactly on schedule.

---

# White Cell Decision Model

When participants take an unexpected action, the White Cell should evaluate four questions:

| Question                                   | Purpose                                   |
| ------------------------------------------ | ----------------------------------------- |
| Does this change the scenario outcome?     | Determine whether adaptation is required. |
| Does it affect the learning objective?     | Preserve exercise value.                  |
| What realistic consequence would occur?    | Maintain realism.                         |
| What new information should be introduced? | Guide the next decision point.            |

---

# Branch Category 1 — Early Detection

## Situation

Participants rapidly correlate indicators and identify the compromise during Phase 1.

Example:

The SOC states:

> "The vendor account compromise is highly likely. We recommend immediate suspension and incident activation."

---

## Facilitator Response

Do not penalize effective response.

Instead, accelerate the scenario.

Introduce:

* Confirmation from the vendor.
* Evidence of previous access.
* Business impact questions.
* Executive decision requirements.

---

## Possible Inject Adjustment

Replace later investigation injects with:

**Accelerated Threat Discovery**

```
The forensic review confirms that unauthorized access occurred before the account was disabled.

The organization must now determine:

- What systems were accessed?
- What data may have been exposed?
- What communications are required?
```

---

## Learning Objective Preserved

The exercise moves from:

"Can we detect the incident?"

to:

"Can we manage the consequences effectively?"

---

# Branch Category 2 — Delayed Escalation

## Situation

Participants continue treating alerts independently and delay formal incident response.

Example:

"The SOC needs more evidence before involving leadership."

---

## Facilitator Response

Allow the delay.

Real organizations often struggle with escalation thresholds.

Introduce increasing evidence.

---

## Possible Inject Adjustment

Add:

**Additional Authentication Evidence**

```
A review identifies that the vendor account accessed administrative systems outside its approved scope.

The activity occurred over several hours.
```

---

## Learning Objective Preserved

The exercise tests:

* Escalation judgement.
* Risk tolerance.
* Governance maturity.

---

# Branch Category 3 — Immediate Shutdown Decision

## Situation

Participants immediately isolate systems or stop production.

Example:

"The safest option is to disconnect the network immediately."

---

## Facilitator Response

Do not discourage the decision.

Introduce realistic operational consequences.

---

## Possible Inject Adjustment

Add:

**Manufacturing Impact**

```
Production scheduling systems are unavailable.

Several production lines require manual coordination.

Operations leadership requests an estimated recovery timeline.
```

---

## Learning Objective Preserved

The exercise explores:

* Cyber risk versus business continuity.
* Executive decision-making.
* Operational resilience.

---

# Branch Category 4 — Refusal to Declare Incident

## Situation

Leadership avoids formal declaration due to uncertainty.

---

## Facilitator Response

Introduce governance pressure.

Possible sources:

* Board inquiry.
* Customer concern.
* Vendor confirmation.
* Regulatory advice.

---

## Possible Inject Adjustment

Add:

**Executive Challenge**

```
The CEO asks:

"If this is not an incident, what evidence would convince us that it is?"
```

---

## Learning Objective Preserved

The exercise examines:

* Decision accountability.
* Risk acceptance.
* Leadership confidence.

---

# Branch Category 5 — Overconfidence in Security Controls

## Situation

Participants assume existing controls eliminate risk.

Examples:

* "MFA was successful, so credentials cannot be compromised."
* "The antivirus did not detect malware."
* "The firewall blocked suspicious traffic."

---

## Facilitator Response

Introduce evidence showing control limitations.

---

## Possible Inject Adjustment

Add:

**Control Effectiveness Review**

```
Security architecture review confirms that the control operated correctly.

However, the attacker used legitimate access methods that bypassed those assumptions.
```

---

## Learning Objective Preserved

Participants learn:

* Controls reduce risk.
* Controls do not eliminate risk.

---

# Branch Category 6 — Lack of Executive Engagement

## Situation

Technical teams continue operating without involving leadership.

---

## Facilitator Response

Introduce business impact.

Examples:

* Customer escalation.
* Production delay.
* Media inquiry.
* Financial concern.

---

## Learning Objective Preserved

The exercise reinforces:

* Cyber incidents are business events.
* Executive decisions require timely information.

---

# Branch Category 7 — Participants Request Missing Information

## Situation

Participants ask questions that were not anticipated.

Examples:

* "Can we see firewall logs?"
* "What data was accessed?"
* "What contracts exist with the vendor?"

---

## Facilitator Guidance

Use three responses:

### If information exists

Provide it.

### If information would realistically require time

Delay the response.

Example:

> "The forensic team is reviewing those logs and expects an update within one hour."

### If information does not exist

State the limitation.

Example:

> "That information was not available during the initial response period."

---

# Branch Category 8 — Exercise Finishes Early

## Situation

Participants resolve the scenario faster than planned.

---

## Facilitator Options

Introduce additional complexity:

### Option 1 — Executive Pressure

Add:

* Board questions.
* Customer concerns.
* Media attention.

### Option 2 — Recovery Challenge

Add:

* Backup validation issue.
* Restoration failure.
* Remaining attacker access.

### Option 3 — Governance Challenge

Ask:

"What improvements would you fund after this incident?"

---

# Branch Category 9 — Exercise Runs Behind Schedule

## Situation

Discussion takes longer than expected.

---

## Facilitator Actions

Prioritize learning objectives.

Recommended compression:

Reduce:

* Technical investigation detail.
* Repeated discussions.

Preserve:

* Major decisions.
* Executive engagement.
* Communication challenges.
* Recovery planning.

---

# Facilitator Escalation Matrix

| Participant Behaviour     | Facilitator Response             |
| ------------------------- | -------------------------------- |
| Good detection            | Accelerate impact.               |
| Slow investigation        | Increase evidence.               |
| Poor communication        | Introduce stakeholder pressure.  |
| Weak governance           | Introduce executive decisions.   |
| Excessive technical focus | Introduce business consequences. |
| Premature closure         | Introduce recovery challenges.   |

---

# Maintaining Scenario Integrity

Facilitators should avoid:

* Punishing good decisions.
* Forcing failure outcomes.
* Revealing the "correct answer."
* Turning the exercise into a technical test.
* Allowing unrealistic assumptions.

The goal is not to demonstrate that participants failed.

The goal is to reveal where the organization can improve.

---

# White Cell Closing Questions

At the conclusion of the exercise, the White Cell should capture:

## Decision Quality

* Were decisions timely?
* Were risks understood?
* Were owners clear?

## Communication

* Did information flow effectively?
* Were stakeholders engaged appropriately?

## Process

* Were procedures followed?
* Were escalation paths understood?

## Capability

* What worked?
* What failed?
* What requires improvement?

---

# Transition to After Action Review

Operation Red Horizon is now complete.

The exercise has produced:

* Participant decisions.
* Observer observations.
* Facilitator notes.
* Identified capability gaps.
* Improvement opportunities.

The next step is converting these observations into an actionable:

**After Action Review (AAR)**

The AAR transforms exercise experience into organizational improvement.

---

# End of Appendix G MSEL Package

The complete Operation Red Horizon exercise package now contains:

| Component           | Purpose                              |
| ------------------- | ------------------------------------ |
| Exercise Charter    | Defines objectives and governance.   |
| Rules of Engagement | Establishes boundaries.              |
| Scenario            | Provides the incident narrative.     |
| Artifact Library    | Provides realistic evidence.         |
| MSEL                | Controls exercise execution.         |
| Observer Logs       | Capture behaviours and decisions.    |
| Hot Wash            | Captures immediate feedback.         |
| AAR                 | Converts observations into findings. |
| Roadmap             | Drives improvement actions.          |

Operation Red Horizon is now ready to be facilitated as a repeatable enterprise cybersecurity tabletop exercise.
