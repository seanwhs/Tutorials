---

title: Appendix F – Part 6
subtitle: Facilitator's Inject Cookbook – Recovery, Curveballs & Advanced Facilitation
description: Advanced guidance for tabletop exercise facilitators covering recovery, adaptive scenario management, White Cell operations, dynamic inject design, and continuous improvement.
type: appendix
category: facilitator
version: 1.0
tags:
- ttx
- facilitation
- recovery
- white-cell
- lessons-learned

---

# Appendix F — Facilitator's Inject Cookbook

# Part 6 — Recovery, Curveballs & Advanced Facilitation

> *A tabletop exercise is not a script to be performed. It is a guided learning experience that evolves through participant decisions. The facilitator's role is to shape that experience—not to control its outcome.*

The best facilitators understand that every exercise is unique. Even when the same scenario is reused, different participants, organizational cultures, and operational contexts produce different discussions and different lessons.

This section concludes the Inject Cookbook by focusing on recovery, adaptive facilitation, and techniques that help facilitators deliver realistic, engaging, and educational exercises.

---

# Learning Objectives

This section helps facilitators:

* Guide recovery discussions.
* Adapt scenarios without losing realism.
* Introduce "curveballs" appropriately.
* Manage White Cell operations.
* Maintain exercise pacing.
* Encourage meaningful discussion.
* Capture actionable observations.
* Translate exercises into organizational improvement.

---

# Category 29 — Recovery & Restoration

Recovery begins only after participants have confidence that containment has been achieved.

---

## Inject RC-01 — Recovery Approval Request

### Objective

Evaluate executive governance.

### Scenario

Technical teams recommend beginning restoration.

Executives request confirmation that sufficient evidence exists to proceed.

### Discussion

* Has the threat been eradicated?
* What residual risks remain?
* Who authorizes restoration?

---

## Inject RC-02 — Backup Integrity Failure

### Objective

Exercise recovery planning.

### Scenario

Initial restoration testing discovers that the most recent backup is corrupted.

An earlier backup remains available.

### Discussion

* Accept additional data loss?
* Delay recovery?
* Restore partial services?

---

## Inject RC-03 — Unexpected Reinfection

### Objective

Evaluate monitoring during recovery.

### Scenario

Shortly after restored systems return online, monitoring identifies suspicious activity resembling the original compromise.

### Facilitator Notes

Participants should determine whether this represents:

* incomplete eradication,
* unrelated activity,
* false positive,
* secondary attack.

---

## Inject RC-04 — Business Priority Conflict

### Objective

Balance operational urgency with technical assurance.

### Scenario

Business leadership requests accelerated restoration of customer-facing systems despite incomplete forensic analysis.

---

# Category 30 — Organizational Learning

---

## Inject OL-01 — Observation Review

### Objective

Transition participants into evaluation.

### Scenario

Observers present a timeline of notable decisions made during the exercise.

### Discussion

* Which decisions worked well?
* Which assumptions proved incorrect?
* What evidence supported key actions?

---

## Inject OL-02 — Improvement Planning

### Objective

Create measurable follow-up actions.

### Scenario

Participants identify three improvement initiatives that should be completed before the next exercise.

### Facilitator Notes

Recommendations should include:

* owner,
* priority,
* target completion date,
* validation method.

---

# Category 31 — Curveball Injects

Curveballs should increase realism—not create confusion.

A useful curveball forces participants to reassess assumptions while remaining consistent with the scenario.

---

## Inject CB-01 — Real Operational Outage

### Objective

Separate unrelated events from the incident.

### Scenario

A network outage occurs in an unrelated office because of scheduled maintenance.

### Discussion

Should this be treated as part of the incident?

---

## Inject CB-02 — False Positive

### Objective

Evaluate disciplined investigation.

### Scenario

A critical alert initially appears connected to the attack.

Further analysis suggests it is unrelated.

### Facilitator Notes

Reward participants who validate evidence before escalating.

---

## Inject CB-03 — Subject Matter Expert Unavailable

### Objective

Assess organizational resilience.

### Scenario

The primary database administrator is unavailable throughout the exercise.

### Discussion

* Are alternate contacts documented?
* Can responsibilities be delegated?

---

## Inject CB-04 — Executive Changes Direction

### Objective

Evaluate adaptability.

### Scenario

Senior leadership unexpectedly changes recovery priorities after receiving new business information.

### Discussion

How should technical teams adapt?

---

## Inject CB-05 — New Threat Intelligence

### Objective

Exercise reassessment.

### Scenario

Threat intelligence suggests another organization recently experienced an almost identical attack using different techniques.

### Discussion

Should current assumptions change?

---

# White Cell Best Practices

The White Cell is responsible for maintaining realism, consistency, and learning value.

Its responsibilities include:

* controlling inject timing,
* answering participant questions,
* adapting pacing,
* recording deviations,
* maintaining scenario integrity,
* protecting exercise objectives.

The White Cell should never become the center of attention.

Participants—not facilitators—should remain the primary actors.

---

# Dynamic Inject Design

Experienced facilitators rarely rely exclusively on pre-written injects.

Instead, they adapt based on participant behaviour.

A useful decision framework is:

```text
Participant Decision
        │
        ▼
Expected?
        │
   ┌────┴────┐
   │         │
 Yes        No
   │         │
Continue   Introduce
Scenario   New Inject
```

When participants make unexpected but reasonable decisions, adapt the scenario to explore the consequences rather than forcing them back onto the original script.

---

# Pacing Guidelines

Exercises should feel realistic without becoming exhausting.

A practical rhythm is:

| Phase             |                                                 Typical Pace |
| ----------------- | -----------------------------------------------------------: |
| Initial Detection |                               New inject every 10–15 minutes |
| Investigation     |                                           Every 8–12 minutes |
| Active Incident   |                                           Every 5–10 minutes |
| Crisis Management | Based on participant discussion rather than a fixed schedule |
| Recovery          |       Slower, reflective pacing with longer decision windows |

Silence is acceptable when participants are productively discussing complex decisions.

---

# When to Pause

A facilitator should consider pausing the exercise if:

* participants become confused about objectives,
* discussions become dominated by one individual,
* safety or psychological comfort is affected,
* a real operational incident occurs,
* scenario assumptions are no longer understood.

A pause is a facilitation tool—not a failure.

---

# Common Facilitation Mistakes

Avoid these common pitfalls:

## Over-Facilitating

Allow participants to solve problems without excessive prompting.

---

## Leading the Discussion

Avoid suggesting preferred answers.

Instead ask:

* "What evidence supports that conclusion?"
* "What alternatives should be considered?"

---

## Punishing Creativity

If participants develop a reasonable response not anticipated during planning, explore it.

Exercises should reward thoughtful adaptation.

---

## Overloading Participants

Too many simultaneous injects reduce discussion quality.

Quality is more valuable than quantity.

---

## Ignoring Learning Objectives

Every inject should support at least one documented exercise objective.

If an inject does not advance learning, consider removing it.

---

# Capturing Observations

Observers should document:

* significant decisions,
* communication patterns,
* assumptions,
* coordination challenges,
* notable quotations,
* timing,
* process deviations.

Observations should describe behaviour—not judge performance.

---

# From Observation to Improvement

A mature exercise program follows a repeatable improvement cycle:

```text
Exercise
     │
     ▼
Observation
     │
     ▼
Analysis
     │
     ▼
Finding
     │
     ▼
Recommendation
     │
     ▼
Action Plan
     │
     ▼
Validation
     │
     ▼
Future Exercise
```

Each exercise should strengthen organizational capability.

The goal is continuous improvement, not a perfect score.

---

# Measuring Exercise Success

Success should not be measured by whether participants "won."

Instead, evaluate whether the exercise:

* revealed meaningful observations,
* stimulated productive discussion,
* validated existing capabilities,
* identified improvement opportunities,
* strengthened collaboration,
* increased organizational confidence.

A challenging exercise that exposes weaknesses often delivers greater value than an easy exercise that confirms existing assumptions.

---

# Facilitator's Final Checklist

Before concluding the exercise, confirm that:

* All planned objectives were addressed.
* Critical decisions were documented.
* Observers submitted their notes.
* Participants completed the hot wash.
* Improvement actions have identified owners.
* A timeline exists for the After Action Review.
* Lessons learned are captured before memories fade.

---

# Final Design Principles

Exceptional tabletop exercises are built on realism, preparation, disciplined facilitation, and a commitment to organizational learning.

Facilitators should strive to:

* create psychological safety,
* encourage evidence-based reasoning,
* maintain scenario credibility,
* adapt thoughtfully,
* avoid unnecessary complexity,
* focus on decisions rather than technical trivia,
* convert every observation into measurable improvement.

Technology, processes, and threats will continue to evolve.

The principles of effective facilitation—clarity, curiosity, collaboration, and continuous improvement—remain constant.

---

# Conclusion

This completes **Appendix F – Facilitator's Inject Cookbook**.

Across its six parts, the cookbook provides a structured library of reusable injects spanning the full lifecycle of a cybersecurity incident:

* Initial detection and triage.
* Identity compromise and lateral movement.
* Cloud, SaaS, and supply chain incidents.
* Ransomware and operational disruption.
* Executive leadership, communications, and regulatory engagement.
* Recovery, organizational learning, and advanced facilitation.

Together with the preceding appendices—templates, sample artifacts, checklists, and glossary—this handbook equips facilitators with a comprehensive toolkit for designing, delivering, and continuously improving cybersecurity tabletop exercises of varying scope, maturity, and complexity.

Every exercise should leave the organization better prepared than it was before. That—not flawless execution—is the true measure of success.
