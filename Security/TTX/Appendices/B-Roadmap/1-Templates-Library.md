# Appendix B — Templates Library

## Part 1 — Template Architecture, Standards, and Governance

> *Templates should reduce thinking about formatting—not thinking about the exercise.*

A mature Tabletop Exercise (TTX) program depends on consistency. As the number of exercises grows, maintaining quality becomes increasingly difficult if every facilitator creates documents from scratch. Small differences in structure, terminology, and formatting accumulate over time, making exercises harder to compare, lessons more difficult to aggregate, and institutional knowledge more fragmented.

The purpose of this template library is to establish a **single, authoritative set of reusable artifacts** for every stage of the tabletop exercise lifecycle. Rather than providing static forms to fill in, the library defines a common language, document structure, and governance model that supports repeatability, collaboration, and continuous improvement.

---

# Why Standardized Templates Matter

Templates provide much more than convenience. They create a common operating model for the exercise program.

Well-designed templates help organizations:

* Reduce preparation time.
* Improve documentation quality.
* Promote consistency across facilitators.
* Simplify onboarding of new exercise planners.
* Enable comparisons across multiple exercises.
* Support audits and compliance activities.
* Preserve institutional knowledge.

Without standard templates, every exercise becomes a one-off project. With them, each exercise becomes another contribution to a growing body of organizational experience.

---

# Design Principles

Every template in this library follows the same design philosophy.

## 1. Markdown First

All templates are written in standard Markdown.

Benefits include:

* Platform independence
* Long-term readability
* Git compatibility
* Easy conversion to HTML, PDF, or Word
* Lightweight editing
* Plain-text searchability

Avoid proprietary document formats whenever practical.

---

## 2. Modular by Design

Each template has a single purpose.

For example:

* A Rules of Engagement document defines boundaries.
* A Scenario document tells the story.
* An MSEL drives exercise execution.
* An AAR captures findings.

Avoid combining multiple document types into one large file.

Modularity makes templates easier to maintain and reuse.

---

## 3. Reusable, Not Disposable

Templates are organizational assets.

Every improvement made after an exercise should be incorporated into the master template rather than copied into individual documents. This creates a cycle of continuous refinement where the template library becomes progressively more valuable over time.

---

## 4. Technology Neutral

Templates should not assume the use of a specific vendor, cloud provider, or security product.

For example, use generic terms such as:

* Security Information and Event Management (SIEM)
* Endpoint Detection and Response (EDR)
* Identity Provider (IdP)

rather than product-specific terminology unless the exercise explicitly requires it.

This improves portability and makes the templates applicable across different environments.

---

## 5. Scenario Agnostic

Templates should support any type of cybersecurity scenario, including:

* Ransomware
* Business Email Compromise
* Insider Threat
* Cloud Misconfiguration
* Third-Party Compromise
* Supply Chain Attack
* Data Exfiltration
* Operational Technology (OT) Incidents
* Distributed Denial-of-Service (DDoS)
* Artificial Intelligence (AI) Abuse

The template provides the structure; the scenario provides the content.

---

# Template Lifecycle

Every template progresses through a simple governance lifecycle.

```text
Draft
   │
   ▼
Internal Review
   │
   ▼
Approved
   │
   ▼
Published
   │
   ▼
Used in Exercises
   │
   ▼
Lessons Learned
   │
   ▼
Template Updated
```

This feedback loop ensures that improvements discovered during exercises are incorporated into future versions of the template.

---

# Recommended Folder Structure

Organize templates in a dedicated directory.

```text
99-Appendices/
└── B-Templates-Library/
    ├── README.md
    ├── roe-template.md
    ├── scenario-template.md
    ├── msel-template.md
    ├── incident-log-template.md
    ├── observer-log-template.md
    ├── participant-brief-template.md
    ├── facilitator-guide-template.md
    ├── hot-wash-template.md
    ├── aar-template.md
    └── roadmap-template.md
```

Separating templates into individual files makes them easier to discover, update, and embed in other notes.

---

# Naming Conventions

Use descriptive and consistent filenames.

Recommended format:

```text
roe-template.md
scenario-template.md
msel-template.md
observer-log-template.md
aar-template.md
roadmap-template.md
```

Avoid vague names such as:

```text
template1.md
exercise.docx
notes-final.md
new-version.md
```

Clear naming reduces confusion and supports automation.

---

# YAML Frontmatter Standards

Every template should begin with YAML frontmatter.

Example:

```yaml
---
title: Rules of Engagement Template
type: template
category: tabletop-exercise
status: Approved
version: 1.0
owner: Cybersecurity Team
last_reviewed: 2026-07-11
tags:
  - ttx
  - template
---
```

This metadata enables:

* Dataview queries
* Automated reporting
* Template version tracking
* Ownership assignment
* Lifecycle management

---

# Metadata Guidelines

The following fields are recommended across all templates.

| Field   | Purpose                             |
| ------- | ----------------------------------- |
| title   | Human-readable document name        |
| type    | Template, Scenario, AAR, MSEL, etc. |
| version | Document revision                   |
| owner   | Responsible individual or team      |
| status  | Draft, Approved, Archived           |
| created | Initial creation date               |
| updated | Most recent revision                |
| tags    | Search and categorization           |

Consistent metadata simplifies governance and reporting.

---

# Internal Linking

Use Obsidian's internal linking to connect related documents.

Examples:

```markdown
[[Scenario]]

[[Rules of Engagement]]

[[After Action Review]]
```

For reusable content, use transclusion.

```markdown
![[roe-template]]
```

Maintaining a single source of truth minimizes duplication and keeps documentation synchronized.

---

# Version Control Strategy

Treat templates as source code.

Maintain them in a private Git repository with meaningful commit messages.

Example:

```text
feat: add communication matrix to RoE template

fix: clarify observer responsibilities

docs: update MSEL timing guidance
```

Avoid generic commit messages such as:

```text
updates

changes

fixed stuff
```

A clear version history improves traceability and collaboration.

---

# Writing Style Guidelines

Templates should be written using clear, direct language.

### Prefer

* Short sentences
* Active voice
* Consistent terminology
* Action-oriented instructions

Example:

> Notify the White Cell before introducing unscheduled injects.

Instead of:

> The White Cell should potentially be notified in situations where inject timing may require modification.

Clarity is especially important during live exercises when participants may be under time pressure.

---

# Placeholder Conventions

Use obvious placeholders to indicate information that must be customized.

Recommended formats:

```text
[Exercise Name]

[Date]

[Facilitator Name]

[Organization]

[Scenario Summary]
```

Avoid placeholders that resemble real data.

For example, do not use actual email addresses, phone numbers, or employee names unless they are intentionally fictional.

---

# Reusable Sections

Many templates share common components.

Examples include:

* Document metadata
* Approval information
* Version history
* References
* Distribution list

Rather than rewriting these sections, maintain standard wording across the library to improve consistency.

---

# Template Review Process

Templates should be reviewed periodically rather than only after major exercises.

A recommended annual review includes:

1. Validate alignment with current organizational processes.
2. Remove obsolete references.
3. Update terminology.
4. Incorporate lessons learned from recent exercises.
5. Review formatting and accessibility.
6. Confirm ownership and approval status.

Regular maintenance prevents the library from becoming outdated.

---

# Common Mistakes

Organizations often encounter similar problems when developing template libraries.

Avoid:

* Embedding scenario-specific content in generic templates.
* Mixing facilitator notes with participant documents.
* Copying templates instead of updating the master version.
* Using inconsistent terminology.
* Maintaining duplicate templates with overlapping purposes.
* Allowing templates to remain unowned or unreviewed.

A disciplined governance process is as important as the templates themselves.

---

# Integration with the Exercise Lifecycle

Each template corresponds to a specific phase of the tabletop exercise lifecycle.

| Exercise Phase       | Primary Template    |
| -------------------- | ------------------- |
| Planning             | Rules of Engagement |
| Scenario Design      | Scenario Template   |
| Exercise Development | MSEL                |
| Exercise Delivery    | Facilitator Guide   |
| Observation          | Observer Log        |
| Immediate Debrief    | Hot-Wash Template   |
| Formal Evaluation    | After Action Review |
| Improvement          | Roadmap             |

Together, these templates provide end-to-end coverage of the planning, execution, evaluation, and improvement cycle.

---

# Looking Ahead

The remainder of this appendix expands each template into a production-ready artifact with:

* Purpose and intended audience.
* Design rationale.
* Field-by-field guidance.
* Common implementation pitfalls.
* Best practices.
* A complete Markdown template ready for immediate use.

The objective is not simply to provide forms to complete, but to establish a coherent documentation framework that supports repeatable, high-quality tabletop exercises across the organization.
