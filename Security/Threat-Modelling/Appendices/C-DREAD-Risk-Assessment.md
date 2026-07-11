# Appendix C – DREAD Risk Assessment Guide

## Professional Handout Material

> **Course:** Threat Modeling Masterclass
> **Appendix C**
> **Purpose:** This appendix provides a comprehensive reference for the **DREAD Risk Assessment Model**, including scoring methodology, practical examples, scoring worksheets, strengths and limitations, integration with STRIDE, and guidance on adapting DREAD for modern enterprise environments.

> **Note:** While DREAD remains valuable as a teaching and structured thinking tool, many organizations today prefer customized enterprise risk matrices or standards such as **CVSS** for vulnerability scoring. Understanding DREAD remains useful because it introduces disciplined, repeatable risk evaluation.

---

# Table of Contents

1. Introduction to DREAD
2. History and Evolution
3. Why Risk Scoring Matters
4. DREAD Methodology
5. The Five DREAD Categories
6. Scoring Method
7. Risk Rating Matrix
8. Worked Examples
9. DREAD Worksheets
10. Integrating STRIDE with DREAD
11. Enterprise Adaptations
12. DREAD vs CVSS
13. DREAD vs Business Risk Matrix
14. Common Mistakes
15. Best Practices
16. Risk Acceptance
17. Executive Reporting
18. Quick Reference

---

# 1. Introduction to DREAD

Threat identification alone is not enough.

After identifying threats, organizations must determine:

* Which threats are most dangerous?
* Which threats require immediate attention?
* Which threats can be accepted?
* Which threats should be monitored?

DREAD provides a structured way to answer these questions.

---

## What is DREAD?

DREAD is a qualitative risk assessment methodology used to estimate the severity of identified threats.

It evaluates five characteristics of a threat.

```
D
Damage

R
Reproducibility

E
Exploitability

A
Affected Users

D
Discoverability
```

---

## Goal

Instead of saying

> "SQL Injection is dangerous"

DREAD allows us to say

> "SQL Injection scores 9.4/10 and is therefore Critical."

---

# 2. History and Evolution

DREAD originated at Microsoft as part of the Secure Development Lifecycle (SDL).

Originally used alongside STRIDE:

```
STRIDE

↓

Threat Identification

↓

DREAD

↓

Risk Prioritization
```

Microsoft later moved away from DREAD because organizations often scored threats inconsistently.

However, DREAD remains valuable for:

* Teaching
* Architecture workshops
* Threat modeling exercises
* Small and medium projects
* Structured brainstorming

---

# 3. Why Risk Scoring Matters

Suppose a system has identified:

* 200 threats

Should every threat be fixed immediately?

Obviously not.

Resources are limited.

Risk scoring helps answer:

* Which threats matter most?
* Which threats can wait?
* Which threats should be accepted?

---

## Benefits

* Prioritization
* Resource allocation
* Budget justification
* Management reporting
* Consistent decision making
* Better remediation planning

---

# 4. DREAD Methodology

Each threat receives a score from **0 to 10** in five categories.

```
Damage
+
Reproducibility
+
Exploitability
+
Affected Users
+
Discoverability

÷ 5
```

Result:

```
Overall Risk Score
```

---

# 5. The Five DREAD Categories

---

## Damage Potential

Question:

> **If the attack succeeds, how much damage occurs?**

Consider:

* Financial loss
* Regulatory penalties
* Reputation damage
* Customer impact
* Service outage

---

### Damage Scoring

| Score | Description  |
| ----- | ------------ |
| 0     | No impact    |
| 2     | Negligible   |
| 4     | Minor        |
| 6     | Moderate     |
| 8     | Major        |
| 10    | Catastrophic |

---

## Examples

Damage = 2

* Minor UI bug

Damage = 10

* Customer banking database stolen

---

## Reproducibility

Question:

> **Can the attack be repeated easily?**

---

High reproducibility means:

* Automated attacks
* Scripts
* Bots

Low reproducibility means:

* Rare conditions
* Physical access
* Specialized equipment

---

### Example

Password spraying

Score

```
10
```

Because it is easy to automate.

---

Hardware side-channel attack

Score

```
2
```

Because it requires specialized equipment.

---

## Exploitability

Question

> **How difficult is the attack?**

Factors:

* Technical skill
* Required tools
* Authentication needed
* Insider knowledge
* Time

---

### Example

Public SQL Injection

Score

```
10
```

Requires:

* Browser
* URL

---

Kernel privilege escalation

Score

```
3
```

Requires:

* Deep technical knowledge
* Local access

---

## Affected Users

Question

> **How many users could be impacted?**

---

Score Guide

| Score | Users Impacted |
| ----- | -------------- |
| 0     | None           |
| 2     | Single user    |
| 4     | Small group    |
| 6     | Department     |
| 8     | Organization   |
| 10    | All customers  |

---

Example

Online banking outage

Score

```
10
```

---

Internal HR application

Maybe

```
4
```

---

## Discoverability

Question

> **How easy is it to discover the vulnerability?**

---

Examples

Open S3 bucket

```
10
```

Visible to everyone.

---

Hidden API endpoint requiring insider knowledge

```
3
```

---

Hardcoded API key in GitHub

```
10
```

---

# 6. DREAD Formula

```
Risk Score

=

Damage
+
Reproducibility
+
Exploitability
+
Affected Users
+
Discoverability

÷5
```

Example

```
9
+
8
+
10
+
10
+
8

=

45

÷5

=

9.0
```

---

# 7. Risk Rating Matrix

| Score | Rating        | Recommended Action            |
| ----- | ------------- | ----------------------------- |
| 9–10  | Critical      | Immediate remediation         |
| 7–8.9 | High          | Prioritize in current release |
| 4–6.9 | Medium        | Planned remediation           |
| 1–3.9 | Low           | Accept or monitor             |
| 0     | Informational | No action                     |

---

# 8. Worked Example 1

## SQL Injection

| Factor          | Score |
| --------------- | ----: |
| Damage          |    10 |
| Reproducibility |    10 |
| Exploitability  |     9 |
| Affected Users  |    10 |
| Discoverability |     8 |

Average

```
47

÷5

=

9.4
```

Critical

---

# Worked Example 2

## Cross-Site Scripting (Stored XSS)

| Factor          | Score |
| --------------- | ----: |
| Damage          |     6 |
| Reproducibility |     8 |
| Exploitability  |     7 |
| Affected Users  |     6 |
| Discoverability |     8 |

Average

```
35

÷5

=

7.0
```

High

---

# Worked Example 3

## Public Cloud Storage Bucket

| Factor          | Score |
| --------------- | ----: |
| Damage          |     9 |
| Reproducibility |    10 |
| Exploitability  |    10 |
| Affected Users  |     9 |
| Discoverability |    10 |

Average

```
48

÷5

=

9.6
```

Critical

---

# Worked Example 4

## Missing Security Headers

| Factor          | Score |
| --------------- | ----: |
| Damage          |     3 |
| Reproducibility |    10 |
| Exploitability  |     5 |
| Affected Users  |     3 |
| Discoverability |    10 |

Average

```
31

÷5

=

6.2
```

Medium

---

# 9. DREAD Assessment Worksheet

Threat ID

```
T-001
```

Threat

```
SQL Injection
```

Component

```
Customer API
```

---

| Category        | Score | Notes |
| --------------- | ----: | ----- |
| Damage          |       |       |
| Reproducibility |       |       |
| Exploitability  |       |       |
| Affected Users  |       |       |
| Discoverability |       |       |

Overall Score

---

Risk Rating

---

Owner

---

---

# 10. Combining STRIDE and DREAD

Example

Threat identified:

```
Spoofing
```

Attack

```
JWT Forgery
```

Now score it.

| Category        | Score |
| --------------- | ----: |
| Damage          |     8 |
| Reproducibility |     7 |
| Exploitability  |     8 |
| Users           |     9 |
| Discoverability |     6 |

Average

```
7.6
```

High

---

Workflow

```
DFD

↓

STRIDE

↓

Threat List

↓

DREAD

↓

Prioritized Risks

↓

Controls
```

---

# 11. Enterprise Adaptations

Many organizations modify DREAD.

Example

Instead of

Affected Users

They use

```
Business Impact
```

Instead of

Discoverability

They use

```
Detection Capability
```

Customized model

| Category          |
| ----------------- |
| Business Impact   |
| Exploitability    |
| Likelihood        |
| Detectability     |
| Regulatory Impact |

This often aligns better with enterprise risk management.

---

# 12. DREAD vs CVSS

| Feature               | DREAD                  | CVSS                      |
| --------------------- | ---------------------- | ------------------------- |
| Purpose               | Threat prioritization  | Vulnerability scoring     |
| Scope                 | Architecture & design  | Technical vulnerabilities |
| Ease of Use           | Simple                 | More detailed             |
| Standardized          | No                     | Yes                       |
| Widely Used           | Educational / internal | Industry standard         |
| Regulatory Acceptance | Limited                | High                      |

---

# 13. DREAD vs Business Risk Matrix

| DREAD                | Business Matrix     |
| -------------------- | ------------------- |
| Technical focus      | Business focus      |
| Numeric              | Often qualitative   |
| Threat-centric       | Enterprise-centric  |
| Architecture reviews | Governance meetings |

Many organizations use:

```
STRIDE

↓

DREAD

↓

Business Risk Matrix

↓

Executive Decision
```

---

# 14. Common Mistakes

### Inconsistent Scoring

Different reviewers assign different scores without agreed criteria.

**Mitigation:** Define scoring guidance before the workshop.

---

### Ignoring Business Context

A technically severe issue may have low business impact—or vice versa.

**Mitigation:** Include business stakeholders.

---

### Treating Scores as Exact Science

DREAD provides structured judgment, not mathematical certainty.

**Mitigation:** Use scores to guide discussion, not replace it.

---

### Scoring Without Evidence

Assigning values based on assumptions can distort priorities.

**Mitigation:** Record assumptions and supporting evidence.

---

# 15. Best Practices

* Agree on scoring criteria before the assessment.
* Involve cross-functional participants.
* Document assumptions.
* Revisit scores when architecture changes.
* Combine DREAD with business impact analysis.
* Use DREAD to prioritize—not to justify ignoring lower-risk issues indefinitely.

---

# 16. Risk Acceptance

Not every risk should be mitigated.

Possible treatment options:

| Option   | Description                                         |
| -------- | --------------------------------------------------- |
| Mitigate | Reduce the likelihood or impact                     |
| Transfer | Shift responsibility (e.g., insurance, outsourcing) |
| Avoid    | Eliminate the risky activity                        |
| Accept   | Acknowledge and monitor the residual risk           |

Risk acceptance should:

* Be formally documented.
* Identify the risk owner.
* Include review dates.
* Specify monitoring requirements.

---

# 17. Executive Reporting

Executives generally do not need detailed DREAD calculations.

Instead, summarize:

| Threat                   | Rating   | Business Impact                  | Recommendation                          |
| ------------------------ | -------- | -------------------------------- | --------------------------------------- |
| SQL Injection            | Critical | Customer data compromise         | Immediate remediation                   |
| DDoS                     | High     | Service outage                   | Implement rate limiting and autoscaling |
| Missing Security Headers | Medium   | Increased browser attack surface | Address in next release                 |

Focus discussions on:

* Business impact
* Regulatory implications
* Cost of remediation
* Residual risk

---

# 18. DREAD Quick Reference

### DREAD Questions

| Category        | Key Question                            |
| --------------- | --------------------------------------- |
| Damage          | If exploited, how severe is the impact? |
| Reproducibility | Can the attack be repeated easily?      |
| Exploitability  | How difficult is the attack?            |
| Affected Users  | How many users or systems are impacted? |
| Discoverability | How easy is it to find the weakness?    |

---

### Risk Thresholds

| Score | Priority |
| ----- | -------- |
| 9–10  | Critical |
| 7–8.9 | High     |
| 4–6.9 | Medium   |
| 1–3.9 | Low      |

---

### DREAD Assessment Checklist

* Threat clearly described.
* Supporting evidence available.
* Scores justified.
* Business impact considered.
* Risk owner assigned.
* Treatment option selected.
* Review date established.

---

# Key Takeaways

* DREAD provides a structured approach for prioritizing threats identified through frameworks such as STRIDE.
* The model encourages consistent discussion about damage, exploitability, and business impact, but it relies on agreed scoring criteria.
* Modern organizations often adapt DREAD or supplement it with enterprise risk matrices and standards like CVSS to better align technical findings with governance and business decision-making.
* Risk scoring should inform decisions—not replace expert judgment. The most effective assessments combine technical evidence, architectural understanding, and business context.
