---

title: Appendix B – Part 3.1
subtitle: Scenario Template – Design Principles and Architecture
description: How to design realistic, business-focused cybersecurity tabletop exercise scenarios.
type: appendix
category: templates
version: 1.0
tags:
- ttx
- scenario
- facilitation
- threat-modeling

---

# Appendix B — Templates Library

# Part 3.1 — Scenario Template: Design Principles and Architecture

> *A tabletop exercise is remembered not because of its malware or exploit, but because of the decisions participants were forced to make.*

The scenario is the narrative foundation of every tabletop exercise. It provides the context within which participants interpret information, assess risk, communicate with stakeholders, and make decisions. A well-designed scenario does not attempt to simulate every technical detail of an attack. Instead, it creates a credible environment that challenges participants to apply their organization's processes, governance, and judgment under conditions of uncertainty.

The goal is not to tell participants **what happened**. The goal is to place them in a situation where they must determine **what they believe is happening**, decide **what to do next**, and explain **why**.

---

# The Purpose of a Scenario

The scenario exists to support the objectives established in the Rules of Engagement.

It should:

* Provide a realistic business context.
* Present a believable cybersecurity incident.
* Encourage discussion and collaboration.
* Reveal strengths and weaknesses in existing processes.
* Generate observations that can be converted into measurable improvements.

A scenario is successful when participants spend their time discussing decisions rather than debating whether the story is believable.

---

# Scenario vs. Story

Although a scenario contains a narrative, it is not a work of fiction.

A story entertains.

A tabletop scenario educates.

The difference lies in the intended outcome.

| Storytelling                            | Scenario Design                                                 |
| --------------------------------------- | --------------------------------------------------------------- |
| Drives suspense                         | Drives decision-making                                          |
| Focuses on characters                   | Focuses on organizational roles                                 |
| Reveals information for dramatic effect | Reveals information to create realistic operational uncertainty |
| Seeks emotional engagement              | Seeks organizational learning                                   |
| Ends with a resolution                  | Ends with actionable findings                                   |

Good scenarios create enough realism to encourage immersion without overwhelming participants with unnecessary detail.

---

# Characteristics of an Effective Scenario

Professional tabletop scenarios share several common characteristics.

## Relevant

The scenario should reflect risks that are meaningful to the organization.

Examples include:

* Third-party compromise
* Cloud credential theft
* Business email compromise
* Insider misuse
* Ransomware
* Data exfiltration
* Identity provider compromise
* Operational technology disruption

Participants should immediately recognize why the scenario matters.

---

## Plausible

A scenario does not need to reproduce an actual attack.

It does need to be believable.

Use:

* Current threat intelligence.
* Industry reporting.
* Historical incidents.
* MITRE ATT&CK techniques.
* Organizational architecture.

Avoid scenarios that require unrealistic attacker capabilities or implausible organizational failures unless the exercise specifically explores those edge cases.

---

## Business-Centric

Technology is only one aspect of a cyber incident.

Every scenario should connect technical activity to business impact.

For example:

Technical event:

> An attacker gains privileged access to a cloud identity platform.

Business consequence:

> Payroll processing, customer authentication, and remote workforce access are disrupted.

Participants should be encouraged to think beyond systems and consider customers, employees, regulators, suppliers, and executives.

---

## Decision-Focused

Every significant event in the scenario should lead to at least one meaningful decision.

Examples include:

* Do we isolate the affected environment?
* Should we notify executive leadership?
* Do we activate the crisis management team?
* When do we engage legal counsel?
* Should we involve law enforcement?
* Are customers likely to be affected?
* Is regulatory notification required?

If a scenario contains many events but few decisions, it is unlikely to produce valuable discussion.

---

# The Anatomy of a Scenario

A mature tabletop scenario typically contains the following components.

1. Scenario metadata
2. Executive summary
3. Business context
4. Threat context
5. Initial conditions
6. Narrative timeline
7. Decision points
8. Assumptions
9. Constraints
10. Expected participant actions
11. Success criteria
12. Threat mapping
13. References

Each component serves a distinct purpose and contributes to a coherent exercise experience.

---

# Start with the Business, Not the Attack

A common mistake is to begin by selecting malware or attacker techniques.

Instead, begin with questions such as:

* Which business capability are we trying to exercise?
* Which teams should participate?
* Which executive decisions should be tested?
* Which organizational processes require validation?

Only after answering these questions should the technical attack narrative be developed.

This approach keeps the exercise aligned with organizational objectives rather than technical curiosity.

---

# Define the Business Context

Participants need to understand the environment before the incident begins.

Business context might include:

* Organizational mission.
* Current business priorities.
* Critical services.
* Key suppliers.
* Regulatory obligations.
* Seasonal business pressures.
* Planned maintenance windows.
* Ongoing organizational initiatives.

These contextual elements help participants make realistic decisions during the exercise.

---

# Introduce the Threat Context

Explain why the organization has become a target.

Examples include:

* Increased geopolitical tensions.
* Recent disclosure of a critical vulnerability.
* Expansion into a new market.
* Dependence on a strategic supplier.
* Public announcement of a merger.
* Adoption of new cloud services.

Threat context provides motivation for the simulated adversary without revealing the scenario outcome.

---

# Establish Initial Conditions

Describe what participants know when the exercise begins.

Examples include:

* The Security Operations Center reports unusual authentication activity.
* A help desk analyst receives a suspicious vendor call.
* Network monitoring identifies unexpected scanning.
* An executive receives a media inquiry.
* A cloud administrator notices abnormal API activity.

Starting with observable events encourages participants to investigate rather than react to conclusions.

---

# Build Progressive Complexity

Avoid revealing the entire incident immediately.

Instead, allow complexity to increase over time.

Example progression:

1. Suspicious login.
2. Privileged account activity.
3. Internal reconnaissance.
4. Lateral movement.
5. Data access.
6. Business disruption.
7. Executive escalation.
8. Media attention.
9. Recovery planning.

Each stage introduces new information while preserving uncertainty.

---

# Create Meaningful Decision Points

Every major inject should force participants to choose between realistic alternatives.

Examples include:

### Speed vs. Confidence

Should containment begin immediately, or should investigators gather additional evidence first?

### Security vs. Availability

Should critical systems be isolated even if doing so disrupts business operations?

### Transparency vs. Reputation

Should leadership proactively inform customers, or wait until the investigation confirms impact?

### Local vs. Enterprise Response

Should the issue remain within IT, or should the enterprise crisis management process be activated?

These tensions often generate the most valuable discussions during an exercise.

---

# Use Assumptions Carefully

Every scenario simplifies reality.

Document assumptions explicitly to avoid repeated clarification.

Examples:

* Authentication infrastructure remains available.
* Legal counsel is reachable.
* Cloud providers are operating normally.
* Backups exist unless otherwise stated.
* Vendor contacts respond within agreed service levels.

Assumptions should reduce ambiguity without removing meaningful decision-making.

---

# Define Success Criteria

A tabletop exercise is not judged by whether participants "win."

Instead, success is measured by whether the exercise achieves its objectives.

Possible success criteria include:

* Appropriate escalation decisions.
* Effective communication.
* Timely executive engagement.
* Accurate documentation.
* Clear role definition.
* Identification of process improvements.
* Meaningful After Action Review findings.

Well-defined success criteria help facilitators evaluate outcomes consistently.

---

# Map to Threat Frameworks

Where appropriate, align the scenario with recognized threat frameworks.

For cybersecurity exercises, common references include:

* MITRE ATT&CK
* NIST Cybersecurity Framework (CSF)
* NIST SP 800-61 Incident Response
* CIS Controls
* Organizational incident response playbooks

Framework mapping strengthens realism and enables comparison across multiple exercises.

---

# Common Scenario Design Mistakes

Avoid these frequent pitfalls.

### Too Technical

Participants become overwhelmed by malware details rather than discussing organizational response.

### Unrealistic Escalation

The scenario jumps from a single alert directly to enterprise-wide failure without intermediate evidence.

### Missing Business Context

Technical events occur without explaining why they matter to the organization.

### No Decision Points

Participants simply observe events rather than making meaningful choices.

### Excessive Detail

Large volumes of logs, screenshots, or technical data distract from the exercise objectives.

### Predictable Narrative

Participants immediately recognize the attack path, eliminating uncertainty and reducing discussion.

---

# Design for Discussion

Remember that the objective of a tabletop exercise is not to recreate every packet, process, or exploit.

It is to create an environment in which experienced professionals can discuss uncertainty, evaluate options, challenge assumptions, and improve organizational preparedness.

A successful scenario does not provide all the answers. It asks the right questions at the right time.

The following chapter transforms these principles into a production-ready Markdown Scenario Template that can be adapted to virtually any cybersecurity tabletop exercise, from ransomware and insider threats to cloud compromise and supply chain attacks.
