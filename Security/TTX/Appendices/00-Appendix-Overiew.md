# Appendix Overview

> *A well-designed tabletop exercise is only as repeatable as the documentation that supports it.*

The appendices in this handbook form a complete, reusable **Cybersecurity Tabletop Exercise (TTX) Toolkit**. Rather than treating templates, scenarios, and facilitator notes as disposable documents, this library organizes them into a structured knowledge base that can be reused across exercises, business units, and organizations.

Designed for **Obsidian** and standard Markdown, every appendix can function independently or be combined into a comprehensive exercise package. Together they provide a repeatable framework for planning, facilitating, evaluating, and continuously improving cybersecurity tabletop exercises.

The appendices are intentionally modular. You can reference a single template when creating a new scenario, embed content into another note using Obsidian transclusion, or clone an entire case study as the starting point for a future exercise.

---

# Purpose of the Appendix Library

This appendix collection serves four primary objectives:

* **Standardization** — establish a consistent format for all exercises regardless of scenario or maturity level.
* **Reusability** — minimize duplicated effort by maintaining canonical templates and reference material.
* **Auditability** — preserve exercise history, decisions, and lessons learned through version-controlled Markdown artifacts.
* **Scalability** — enable organizations to build a growing exercise knowledge base rather than isolated documents.

Instead of recreating Rules of Engagement, MSELs, or After Action Reviews for every exercise, facilitators can start with proven templates and focus their energy on designing meaningful scenarios.

---

# Recommended Folder Structure

The following structure keeps the appendix library organized, searchable, and easy to maintain.

```text
99-Appendices/
│
├── 00-Appendix-Overview.md
│
├── A-TTX-Toolkit.md
│
├── B-Templates-Library/
│   ├── roe-template.md
│   ├── scenario-template.md
│   ├── msel-template.md
│   ├── observer-log-template.md
│   ├── aar-template.md
│   ├── participant-invite-template.md
│   └── facilitator-checklist.md
│
├── C-Facilitator-Checklist.md
│
├── D-Sample-Artifacts.md
│
├── E-Glossary.md
│
├── F-Inject-Cookbook.md
│
└── G-Case-Studies/
    └── acme-red-horizon/
        ├── roe.md
        ├── scenario.md
        ├── msel.md
        ├── participants.md
        ├── observer-log-example.md
        ├── hot-wash.md
        ├── aar.md
        └── roadmap.md
```

This structure intentionally separates reusable reference material from completed exercise packages, making it easy to maintain a clean library while preserving historical exercises.

---

# Appendix Directory

## [[A-TTX-Toolkit]]

A concise reference describing the recommended tools for planning and facilitating tabletop exercises.

Topics include:

* Diagramming tools
* Knowledge management
* Collaboration platforms
* Artifact creation
* Communications
* Best practices

Use this appendix whenever setting up a new exercise environment.

---

## [[B-Templates-Library]]

A collection of production-ready Markdown templates for every major exercise artifact.

Templates include:

* Rules of Engagement
* Scenario
* MSEL
* Observer Log
* Incident Timeline
* After Action Review
* Participant Brief
* Facilitator Checklist

These templates should become the organization's canonical documents.

---

## [[C-Facilitator-Checklist]]

A detailed timeline covering everything a facilitator should accomplish before, during, and after an exercise.

The checklist spans the entire exercise lifecycle, including:

* Planning
* Preparation
* White Cell rehearsals
* Live facilitation
* Hot-wash sessions
* AAR production
* Improvement tracking

Each activity identifies recommended owners and expected deliverables.

---

## [[D-Sample-Artifacts]]

A library of realistic but completely synthetic exercise artifacts.

Examples include:

* SIEM alerts
* EDR notifications
* Email messages
* Ransom notes
* Executive updates
* Vendor communications
* Journalist inquiries
* Help desk transcripts

These artifacts are intentionally generic so they can be adapted to many scenarios without exposing sensitive information.

---

## [[E-Glossary]]

A common vocabulary for facilitators and participants.

Terms include:

* MSEL
* White Cell
* Hot-wash
* Rules of Engagement
* ATT&CK
* Exercise maturity levels
* Incident Response terminology

Maintaining a shared vocabulary improves communication and reduces ambiguity during exercises.

---

## [[F-Inject-Cookbook]]

A categorized collection of reusable exercise injects.

Rather than writing every inject from scratch, facilitators can select and customize injects covering:

* Initial access
* Identity compromise
* Lateral movement
* Communications
* Executive escalation
* Regulatory pressure
* Media inquiries
* Recovery challenges

Each inject is designed to encourage discussion and decision-making rather than simply reveal information.

---

## [[G-Case Studies]]

A complete, end-to-end example exercise package.

The initial case study, **Operation Red Horizon**, demonstrates how every template in this handbook comes together into a professionally facilitated tabletop exercise.

The package includes:

* Final Rules of Engagement
* Scenario documentation
* Complete MSEL
* Sample artifacts
* Observer logs
* Hot-wash notes
* After Action Review
* Improvement roadmap

Facilitators are encouraged to clone this package as the foundation for future exercises.

---

# Working with Obsidian

Although this appendix library is standard Markdown and can be used in any editor, it has been optimized for Obsidian.

Recommended plugins include:

* **Templates** — insert commonly used documents.
* **Templater** — automate metadata, filenames, and timestamps.
* **Dataview** — query exercises, findings, and action items.
* **Excalidraw** — create attack-flow diagrams and whiteboard illustrations.
* **Git** — maintain version history for all exercise documentation.

Using these plugins transforms the appendix library from a static document repository into a living operational knowledge base.

---

# Metadata Standards

Every appendix, template, and completed exercise should include YAML frontmatter.

Example:

```yaml
---
title: Vendor VPN Compromise
type: scenario
category: tabletop-exercise
version: 1.2
owner: Security Operations
status: Approved
created: 2026-07-11
updated: 2026-07-18
tags:
  - ttx
  - ransomware
  - vendor-risk
---
```

Consistent metadata enables automation, reporting, and advanced search capabilities within Obsidian.

---

# Linking Strategy

Avoid duplicating content whenever possible.

Instead, maintain a single authoritative version of each template and reference it using internal links or transclusion.

Example:

```markdown
![[roe-template]]
```

This ensures that improvements made to the master template automatically propagate wherever it is embedded.

---

# Version Control

Treat your appendix library as source code.

Store the entire vault in a private Git repository to gain:

* Complete change history
* Easy rollback
* Peer review through pull requests
* Branching for new scenarios
* Audit trails for regulated environments

Version control transforms documentation from static files into managed operational assets.

---

# Design Principles

Every appendix in this handbook follows the same guiding principles:

* **Simple enough to use during an exercise**
* **Detailed enough to support repeatability**
* **Vendor-neutral whenever possible**
* **Portable across organizations**
* **Written in plain Markdown**
* **Compatible with NIST and CISA guidance**
* **Optimized for continuous improvement**

The objective is not merely to document an exercise but to establish a repeatable operational capability that becomes more valuable with every iteration.

---

# How to Use This Library

If you are new to tabletop exercises, read the appendices sequentially.

If you are planning an exercise, follow this recommended workflow:

1. Review the **TTX Toolkit**.
2. Copy the required templates.
3. Customize the Rules of Engagement.
4. Develop the scenario.
5. Build the MSEL.
6. Prepare supporting artifacts.
7. Conduct the exercise.
8. Complete the After Action Review.
9. Track improvements.
10. Archive the complete package as a new case study.
