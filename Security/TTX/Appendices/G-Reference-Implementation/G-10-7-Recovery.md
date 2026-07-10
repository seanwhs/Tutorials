---

title: Appendix G
section: G.10.7
subtitle: "Master Scenario Events List (MSEL) – Phase 6: Recovery"
description: Operational MSEL for the recovery phase of Operation Red Horizon.
classification: TLP:RESTRICTED (Exercise Staff Only)
version: 1.0
---

# G.10.7 Master Scenario Events List (MSEL)

## Phase 6 – Recovery

> *"Recovery is not returning to where we were. Recovery is building the capability to operate better than before."*

---

# Phase Overview

The immediate crisis has stabilized.

The organization has:

* Identified the initial compromise path.
* Contained affected access.
* Stabilized critical business operations.
* Engaged leadership and stakeholders.
* Established confidence that the immediate threat has been reduced.

The focus now moves toward restoration and long-term resilience.

Recovery is deliberately treated as a separate discipline from incident response.

The organization must now answer:

* Which systems can safely return to operation?
* How do we validate trust?
* What evidence is required before restoration?
* Which temporary measures become permanent improvements?
* How do we prevent recurrence?

---

# Phase Objectives

By the conclusion of Phase 6, participants should have:

* Established recovery priorities.
* Defined criteria for system restoration.
* Validated security controls before reconnecting systems.
* Considered business continuity trade-offs.
* Planned post-incident improvement activities.
* Transitioned ownership from crisis response to normal operations.

---

# Phase Timeline

| Exercise Time  | Inject Range             | Focus                                                                 |
| -------------- | ------------------------ | --------------------------------------------------------------------- |
| T+225 to T+270 | RH-INJ-051 to RH-INJ-060 | Recovery planning, restoration decisions, validation, lessons learned |

---

# RH-INJ-051 — Recovery Planning Session

| Field    | Details                                           |
| -------- | ------------------------------------------------- |
| Time     | T+225                                             |
| Delivery | Recovery Planning Meeting                         |
| Audience | Incident Response, IT Operations, Business Owners |
| Artifact | ART-029 – Recovery Prioritization Matrix          |

### Inject Content

The Incident Commander requests each business function identify:

* Critical services.
* Recovery dependencies.
* Acceptable downtime.
* Required validation before restoration.

### Expected Discussion

* Which systems should return first?
* What business priorities influence sequencing?
* Who approves restoration decisions?

### Expected Actions

* Create recovery priority list.
* Assign system owners.
* Define restoration criteria.

### Facilitator Notes

Observe whether participants restore based on business priority or technical convenience.

### Observer Focus

* Recovery governance.
* Business alignment.
* Prioritization discipline.

---

# RH-INJ-052 — Backup Validation Results

| Field    | Details                              |
| -------- | ------------------------------------ |
| Time     | T+230                                |
| Delivery | Backup Operations Report             |
| Audience | IT Operations, Incident Response     |
| Artifact | ART-030 – Backup Verification Report |

### Inject Content

Backup teams confirm that recovery copies exist, but integrity validation is incomplete for several critical systems.

### Expected Discussion

* Can restoration begin?
* What additional validation is required?
* Should business operations wait?

### Expected Actions

* Perform restore validation.
* Confirm backup integrity.
* Document recovery confidence.

### Facilitator Notes

This tests whether participants understand that "having backups" does not equal "having recovery capability."

### Observer Focus

* Recovery confidence.
* Technical discipline.

---

# RH-INJ-053 — System Restoration Proposal

| Field    | Details                             |
| -------- | ----------------------------------- |
| Time     | T+235                               |
| Delivery | IT Recovery Recommendation          |
| Audience | Incident Commander, Business Owners |

### Inject Content

IT proposes restoring several business systems.

However, forensic teams have not yet completed analysis of all affected infrastructure.

### Expected Discussion

* Should restoration proceed?
* What safeguards should be applied?
* Can systems be restored in isolated environments first?

### Expected Actions

* Define restoration approval process.
* Balance business urgency with security assurance.
* Document residual risks.

### Observer Focus

* Risk acceptance.
* Governance.
* Decision ownership.

---

# RH-INJ-054 — Business Pressure Escalation

| Field    | Details              |
| -------- | -------------------- |
| Time     | T+240                |
| Delivery | Executive Escalation |
| Audience | Executive Leadership |

### Inject Content

Manufacturing leadership reports that continued reduced capability is affecting customer delivery commitments.

They request accelerated restoration.

### Expected Discussion

* Who owns the final decision?
* What risks are acceptable?
* What alternatives exist?

### Expected Actions

* Review recovery options.
* Communicate trade-offs.
* Make documented risk decisions.

### Facilitator Notes

There is no perfect answer. The objective is quality decision-making.

### Observer Focus

* Executive leadership.
* Risk balancing.

---

# RH-INJ-055 — Threat Intelligence Update

| Field    | Details                               |
| -------- | ------------------------------------- |
| Time     | T+245                                 |
| Delivery | Threat Intelligence Briefing          |
| Audience | Security Leadership                   |
| Artifact | ART-031 – Threat Intelligence Summary |

### Inject Content

Threat intelligence indicates the attacker group associated with similar campaigns typically attempts follow-up access after initial containment.

### Expected Discussion

* Is additional monitoring required?
* Are current containment measures sufficient?
* Should access controls remain restricted?

### Expected Actions

* Maintain enhanced monitoring.
* Review identity controls.
* Continue threat hunting.

### Observer Focus

* Long-term security posture.
* Avoiding premature closure.

---

# RH-INJ-056 — Lessons Learned Request

| Field    | Details           |
| -------- | ----------------- |
| Time     | T+250             |
| Delivery | Executive Request |
| Audience | All Participants  |

### Inject Content

The CEO requests a preliminary summary:

* What happened?
* What worked?
* What failed?
* What investments are required?

### Expected Discussion

* How early should lessons learned begin?
* Who owns improvement actions?
* How should findings be prioritized?

### Expected Actions

* Capture observations.
* Identify improvement themes.
* Assign ownership.

### Observer Focus

* Organizational learning.
* Accountability.

---

# RH-INJ-057 — Control Improvement Discussion

| Field    | Details                               |
| -------- | ------------------------------------- |
| Time     | T+255                                 |
| Delivery | Security Architecture Review          |
| Audience | Security, IT, Enterprise Architecture |

### Inject Content

The investigation identifies several improvement opportunities:

* Stronger third-party access controls.
* Improved identity monitoring.
* Better segmentation.
* More frequent recovery testing.

### Expected Discussion

* Which improvements provide highest risk reduction?
* What requires immediate investment?
* What belongs in the longer-term roadmap?

### Expected Actions

* Prioritize improvements.
* Identify owners.
* Establish target timelines.

### Observer Focus

* Strategic thinking.
* Security maturity improvement.

---

# RH-INJ-058 — Return to Normal Operations Decision

| Field    | Details                    |
| -------- | -------------------------- |
| Time     | T+260                      |
| Delivery | Executive Decision Meeting |
| Audience | Executive Leadership       |

### Inject Content

The Incident Commander recommends transitioning from emergency response into normal operational governance.

### Expected Discussion

* Are all risks sufficiently understood?
* Which controls remain temporarily elevated?
* Who owns ongoing monitoring?

### Expected Actions

* Approve transition criteria.
* Define post-incident monitoring.
* Transfer ownership.

### Observer Focus

* Closure discipline.
* Governance transition.

---

# RH-INJ-059 — Final Situation Report

| Field    | Details                     |
| -------- | --------------------------- |
| Time     | T+265                       |
| Delivery | Incident Commander Briefing |
| Audience | All Participants            |

### Inject Content

The Incident Commander presents a final exercise status:

* Incident contained.
* Critical systems restored.
* Monitoring increased.
* Improvement initiatives identified.

Participants are asked:

"What would we do differently if this happened tomorrow?"

### Observer Focus

* Reflection.
* Continuous improvement mindset.

---

# RH-INJ-060 — Exercise Closure

| Field    | Details                  |
| -------- | ------------------------ |
| Time     | T+270                    |
| Delivery | Facilitator Announcement |
| Audience | All Participants         |

### Inject Content

The White Cell officially concludes Operation Red Horizon.

Participants are informed that the exercise will move into:

* Hot-wash discussion.
* Observer review.
* After Action Review.
* Improvement roadmap development.

---

# Phase 6 Facilitator Review

Before closing the operational scenario, confirm that participants have:

* Defined recovery priorities.
* Considered restoration risks.
* Validated backups and system integrity.
* Balanced operational urgency with security assurance.
* Identified improvement opportunities.
* Assigned ownership for future actions.

---

# Key Learning Outcomes

Phase 6 reinforces that recovery is a strategic capability.

Participants should recognize that:

* Restoration requires validation, not urgency alone.
* Business pressure must be balanced against residual risk.
* Recovery plans require regular testing.
* Incident response maturity depends on learning after failure.
* Security improvements should become measurable organizational commitments.

---

# Transition to Post-Exercise Activities

The live scenario is complete.

However, the exercise itself is not finished.

The next stage converts observations into organizational improvement.

The White Cell now begins:

1. Hot-wash discussion.
2. Observer consolidation.
3. After Action Review.
4. Improvement roadmap creation.
5. Future exercise planning.

The final measure of success is not whether participants "solved" the scenario.

The measure of success is whether the organization becomes more prepared for the next real incident.

---
