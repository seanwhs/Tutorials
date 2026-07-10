# Appendix A

# TTX Toolkit

> *The effectiveness of a tabletop exercise is determined less by the software you use than by how consistently you use it.*

This appendix presents a practical toolkit for planning, facilitating, documenting, and continuously improving cybersecurity tabletop exercises (TTXs). Rather than prescribing a single technology stack, it recommends a collection of lightweight, interoperable tools that emphasize portability, transparency, and long-term maintainability.

The toolkit follows four guiding principles:

* **Markdown-first** documentation
* **Open standards** wherever practical
* **Vendor-neutral workflows**
* **Minimal operational overhead**

The objective is to ensure that every artifact created during an exercise—from Rules of Engagement (RoE) documents to After Action Reviews (AARs)—remains accessible, version-controlled, and reusable regardless of future technology changes.

---

# 1. The TTX Technology Stack

A successful tabletop exercise relies on several categories of tools rather than a single platform.

| Category             | Purpose                                  | Recommended Tools                               |
| -------------------- | ---------------------------------------- | ----------------------------------------------- |
| Knowledge Management | Store all documentation                  | Obsidian                                        |
| Diagramming          | Visualize attack paths and architectures | Excalidraw, diagrams.net                        |
| Video Collaboration  | Facilitate remote sessions               | Jitsi, BigBlueButton, Microsoft Teams, Zoom     |
| Chat & Messaging     | Exercise communications                  | Mattermost, Slack, Microsoft Teams              |
| Project Tracking     | Improvement roadmap                      | GitHub Projects, GitLab Issues, Jira, Trello    |
| Version Control      | Preserve history                         | Git                                             |
| Documentation        | Markdown editing                         | Obsidian, VS Code                               |
| Artifact Creation    | Produce injects                          | Markdown, Image Editors, AI-assisted generation |
| Threat Intelligence  | Threat research                          | MITRE ATT&CK, CISA, Vendor Advisories           |
| Ticket Simulation    | Mock incident tracking                   | Markdown tables, Jira Sandbox                   |

These tools work together to support the complete exercise lifecycle.

---

# 2. Knowledge Management

## Why Knowledge Management Matters

Every exercise generates valuable organizational knowledge.

Unfortunately, many organizations lose this information because it is scattered across emails, slide decks, chat messages, and personal notebooks.

Instead, maintain a **single source of truth**.

The recommended approach is to use an Obsidian vault containing:

```
Exercises/
Scenarios/
Templates/
Artifacts/
AARs/
Roadmaps/
Case Studies/
Appendices/
```

Every document should remain in Markdown, making it searchable, portable, and easy to version-control.

---

# Why Obsidian?

Obsidian provides several advantages for TTX programs:

* Plain Markdown storage
* Internal linking
* Graph visualization
* Fast full-text search
* Local-first architecture
* Git compatibility
* Community plugin ecosystem
* Cross-platform support

Because everything is stored as ordinary files, the knowledge base remains usable even if Obsidian is replaced in the future.

---

# Recommended Plugins

Although optional, the following plugins significantly improve productivity.

| Plugin     | Purpose                     |
| ---------- | --------------------------- |
| Templates  | Insert reusable documents   |
| Templater  | Dynamic template generation |
| Dataview   | Query exercise metadata     |
| Excalidraw | Interactive diagrams        |
| Git        | Version history             |
| Kanban     | Improvement tracking        |

---

# 3. Diagramming

Visual communication often accelerates understanding more effectively than lengthy descriptions.

Diagrams should be used to illustrate:

* Attack paths
* Network topology
* Trust relationships
* Identity flows
* Decision trees
* Escalation paths
* Incident timelines

---

## Excalidraw

Recommended for:

* Whiteboard sessions
* Collaborative planning
* ATT&CK mapping
* MSEL walkthroughs

Strengths:

* Lightweight
* Hand-drawn appearance
* Excellent Obsidian integration
* SVG export

---

## diagrams.net

Recommended for:

* Executive documentation
* Architecture diagrams
* Infrastructure illustrations
* Formal reports

Strengths:

* Professional output
* UML support
* AWS/Azure/GCP icon libraries

---

# 4. Live Collaboration Platforms

Modern tabletop exercises frequently involve distributed participants.

A collaboration platform should support:

* Audio
* Video
* Screen sharing
* Breakout rooms
* Chat
* Recording (optional)

---

## Jitsi

Ideal when:

* Open-source solutions are preferred.
* Privacy is important.
* Small-to-medium exercises are conducted.

Advantages:

* Free
* Browser-based
* No client installation
* Self-hostable

---

## BigBlueButton

Designed specifically for structured learning environments.

Particularly useful for:

* Government training
* Universities
* Large workshops
* Facilitated discussions

---

## Microsoft Teams

Many enterprises already standardize on Teams.

Benefits include:

* Existing authentication
* Calendar integration
* Persistent chat
* File sharing
* Meeting recording

---

## Zoom

Still one of the simplest platforms for external participants.

Recommended when:

* Multiple organizations participate.
* External consultants are involved.

---

# 5. Exercise Communications

Exercise traffic should never be confused with real operational communications.

Every message should clearly indicate that it belongs to the exercise.

Recommended prefixes include:

```
[TTX-EXERCISE]

[SIMULATION]

[TRAINING]
```

Example:

```
[TTX-EXERCISE]

SOC Alert

Suspicious authentication activity detected...
```

---

## Dedicated Channels

Create separate communication spaces such as:

```
#ttx-red-horizon

#white-cell

#observer-room

#executive-room
```

Avoid mixing operational discussions with exercise discussions.

---

# 6. Artifact Creation

Realistic artifacts make exercises significantly more engaging.

Artifacts may include:

* SIEM alerts
* Firewall logs
* EDR notifications
* Email messages
* Ticket updates
* Chat transcripts
* News reports
* Vendor communications
* Executive briefings

Each artifact should feel authentic while remaining entirely synthetic.

---

## Sanitization Principles

Never include:

* Production IP addresses
* Employee names
* Customer information
* API keys
* Credentials
* Internal emails
* Confidential diagrams

Instead, create fictional equivalents.

---

## Multiple Difficulty Levels

Prepare at least two versions of important artifacts.

### Clean Version

Contains only relevant information.

Suitable for:

* Beginner exercises
* L1
* L2

---

### Noisy Version

Includes:

* False positives
* Unrelated alerts
* Duplicate events
* Background activity

Suitable for:

* L3
* L4
* Experienced responders

---

# 7. Version Control

Every exercise package should be tracked using Git.

Benefits include:

* Change history
* Peer review
* Recovery
* Branching
* Audit trail

Recommended repository structure:

```
ttx-library/

Exercises/

Templates/

Appendices/

Case-Studies/

Images/

Roadmaps/
```

Each exercise becomes a permanent organizational asset.

---

# 8. AI-Assisted Preparation

Generative AI can significantly reduce preparation time when used responsibly.

Suitable uses include:

* Drafting scenarios
* Writing injects
* Generating synthetic emails
* Producing mock news articles
* Creating executive updates
* Brainstorming attack paths
* Improving facilitator guides

AI should assist preparation—not replace facilitator judgment.

Always review AI-generated content for:

* Accuracy
* Consistency
* Organizational relevance
* Security implications

---

# 9. Threat Intelligence Resources

Ground scenarios in realistic threat behavior.

Recommended references include:

* MITRE ATT&CK
* CISA Known Exploited Vulnerabilities (KEV)
* Vendor security advisories
* National CERT publications
* Industry ISAC reports
* Public ransomware reports

Real threat intelligence increases credibility and educational value.

---

# 10. Documentation Standards

Every artifact should follow consistent conventions.

Recommended naming:

```
scenario-vendor-compromise.md

msel-vendor-compromise.md

aar-vendor-compromise.md

roe-vendor-compromise.md
```

Recommended metadata:

```yaml
type: scenario
owner: SOC
version: 1.1
status: Approved
```

Consistency enables automation and simplifies maintenance.

---

# 11. Operational Best Practices

Experienced facilitators consistently follow several practices.

### Keep Everything Modular

Each document should have a single responsibility.

Avoid creating monolithic documents that are difficult to update.

---

### Prefer Markdown

Markdown files are:

* Portable
* Searchable
* Human-readable
* Git-friendly
* Vendor-independent

---

### Automate Repetitive Tasks

Use templates for:

* Rules of Engagement
* MSELs
* Observer Logs
* AARs

Automation reduces administrative effort and improves consistency.

---

### Build a Knowledge Repository

Each completed exercise contributes to institutional knowledge.

Rather than archiving reports, continuously enrich your library with:

* New injects
* Lessons learned
* Updated templates
* Improved scenarios
* Additional case studies

Over time, the toolkit evolves from a collection of documents into an operational knowledge base that captures the organization's experience and continuously improves future exercises.

---

# Toolkit Summary

The tools described in this appendix are intentionally simple, widely available, and interoperable. They support the complete lifecycle of a tabletop exercise—from initial planning and scenario development to live facilitation, after-action review, and long-term program improvement.

Technology alone does not produce effective exercises. Success comes from disciplined preparation, consistent documentation, realistic facilitation, and a commitment to continuous improvement. A well-maintained toolkit provides the foundation for that discipline, enabling facilitators to focus on meaningful learning rather than administrative overhead.
