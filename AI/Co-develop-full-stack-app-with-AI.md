# Co-Developing a Full-Stack Blog Platform: The AI-Native Engineering Workflow

> Building software with AI is no longer a coding problem.
>
> It is a systems engineering problem.

This guide demonstrates how to build a production-grade blog platform using:

* Continue.dev
* Gemini CLI
* React
* Next.js
* shadcn/ui
* Clerk
* Sanity CMS
* Appwrite
* PostgreSQL

But the objective is not simply to build a blog.

The objective is to learn a repeatable engineering workflow for building real systems in the AI era.

---

# The AI Engineering Shift

Traditional software development assumed that writing code was expensive.

Modern AI systems have changed that assumption.

Today:

* generating code is cheap
* generating components is cheap
* generating APIs is cheap
* generating boilerplate is nearly free

The bottleneck has moved.

The new bottlenecks are:

* requirements clarity
* architecture quality
* system correctness
* integration complexity
* validation
* operational reliability

The challenge is no longer:

> "Can AI write this code?"

The challenge is:

> "Can we guide AI to build the correct system?"

---

# The Strategic Split

This workflow deliberately separates responsibilities between two AI systems.

| Tool         | Role                | Responsibility                                    |
| ------------ | ------------------- | ------------------------------------------------- |
| Continue.dev | Codebase Expert     | Local implementation and contextual editing       |
| Gemini CLI   | Engineering Copilot | Planning, architecture, reasoning, and validation |

Many developers use both tools incorrectly.

They ask both tools to generate code.

That wastes their strengths.

Instead:

## Continue.dev

Continue operates inside the repository.

It understands:

* project structure
* existing files
* component hierarchy
* local conventions
* implementation details

Use Continue when asking:

```text
How should this feature fit into the existing codebase?
```

Examples:

* implementing components
* refactoring services
* updating routes
* wiring Server Actions
* migrating code
* fixing local bugs

Think of Continue as:

```text
Codebase Memory
```

---

## Gemini CLI

Gemini operates outside the repository.

It is better suited for:

* architectural reasoning
* system design
* requirements engineering
* implementation planning
* debugging workflows
* design reviews
* operational analysis

Use Gemini when asking:

```text
What should we build?
```

or

```text
Why is this system failing?
```

Think of Gemini as:

```text
Engineering Judgment
```

---

# The Most Important Rule

Do not ask AI to generate code first.

Ask AI to think first.

Bad workflow:

```text
Feature Idea
 ↓
Generate Code
 ↓
Debug Forever
```

AI-native workflow:

```text
Problem
 ↓
Requirements
 ↓
Architecture
 ↓
Implementation Plan
 ↓
Code
 ↓
Validation
 ↓
Refinement
```

The difference seems small.

The results are enormous.

---

# The Source of Truth Principle

AI performs dramatically better when given stable reference documents.

Before implementation begins, create:

```text
docs/
├── requirements.md
├── architecture.md
├── implementation-plan.md
├── adr/
├── risks.md
└── roadmap.md
```

These files become the project's memory.

Instead of prompting:

```text
Build a blog platform.
```

you can prompt:

```text
Review docs/requirements.md
Review docs/architecture.md

Implement Phase 4 according to the implementation plan.
```

This reduces:

* hallucinations
* inconsistency
* architectural drift
* duplicate solutions

---

# Context Engineering

Prompt engineering focuses on prompts.

AI-native engineering focuses on context.

A weak prompt:

```text
Create a blog editor.
```

A strong prompt:

```text
Review:

- docs/requirements.md
- docs/architecture.md
- docs/adr/content-strategy.md

Implement the blog editor according to the approved architecture.

Follow all rules in PROMPTS.md.
```

The second prompt provides:

* requirements
* constraints
* architecture
* decisions
* standards

The AI now has context.

Context is more important than prompting.

---

# Planning Before Prompting

Before every major feature:

Use Gemini CLI.

Example:

```bash
gemini
```

Prompt:

```text
Design a publishing workflow.

Include:

- requirements
- user stories
- state transitions
- database changes
- UI requirements
- security concerns
- implementation phases
```

Do not write code yet.

Create the plan first.

Review the plan.

Challenge the assumptions.

Only then implement.

---

# Architecture of the Blog Platform

This project intentionally separates concerns.

## Frontend Layer

Technology:

* React
* Next.js
* Tailwind CSS
* shadcn/ui

Responsibilities:

* rendering
* user interactions
* routing
* accessibility
* UI composition

---

## Identity Layer

Technology:

* Clerk

Responsibilities:

* authentication
* session management
* user identity
* role management

The application should never manage passwords directly.

Identity is delegated.

---

## Content Layer

Technology:

* Sanity CMS

Responsibilities:

* blog content
* author profiles
* categories
* tags
* editorial workflows
* content previews

Sanity acts as the publishing system.

---

## Transaction Layer

Technology:

* Appwrite
* PostgreSQL

Responsibilities:

* user activity
* analytics
* bookmarks
* comments
* likes
* application state

This distinction is critical.

Content systems and transactional systems evolve differently.

Treat them separately.

---

# Architectural Decision Records (ADRs)

Every significant decision should be documented.

Example:

```text
docs/adr/
├── 001-use-clerk.md
├── 002-use-sanity.md
├── 003-use-app-router.md
├── 004-use-server-actions.md
└── 005-content-vs-transaction-boundaries.md
```

When future changes occur:

The team can understand:

* why decisions were made
* what alternatives were considered
* what tradeoffs were accepted

This dramatically improves AI collaboration.

---

# The Implementation Loop

Every feature follows the same process.

## Step 1

Define the problem.

Example:

```text
Users need draft publishing.
```

---

## Step 2

Use Gemini CLI.

Generate:

* requirements
* risks
* architecture updates
* implementation phases

---

## Step 3

Review the proposal.

Challenge assumptions.

Document decisions.

---

## Step 4

Use Continue.dev.

Implement according to the approved plan.

Example:

```text
@codebase

Review docs/architecture.md.

Implement Phase 6:

Draft Publishing Workflow.
```

---

## Step 5

Validate.

Run:

```bash
npm run dev
npm run build
npm run lint
```

Never trust generated code.

Verify it.

---

## Step 6

Review.

Use both tools.

Continue:

```text
@codebase

Review for maintainability.
```

Gemini:

```bash
git diff | gemini -p "
Perform a senior architecture review.
"
```

---

# The Validation Loop

AI accelerates creation.

Validation preserves correctness.

Always validate:

* architecture
* security
* performance
* accessibility
* maintainability
* deployment readiness

A useful rule:

```text
Generation creates value.

Validation protects value.
```

---

# The 60/40 Rule

Most developers spend:

```text
10% Planning
90% Coding
```

AI-native engineers reverse it.

```text
60% Planning & Validation
40% Implementation
```

Because AI can generate implementation rapidly.

Human judgment is still required for:

* tradeoffs
* priorities
* architecture
* correctness

---

# When To Use Which Tool

Use Gemini CLI when asking:

```text
What should we build?
```

Examples:

* requirements
* architecture
* roadmaps
* design reviews
* debugging
* deployment planning

Use Continue.dev when asking:

```text
How should we implement it?
```

Examples:

* components
* routes
* APIs
* forms
* hooks
* refactors

---

# The Real Goal

The purpose of AI-assisted development is not to generate more code.

The purpose is to improve engineering judgment.

The strongest AI-assisted engineers are not the fastest coders.

They are the engineers who build the best systems.

Use Gemini CLI to think.

Use Continue.dev to implement.

Use documentation to align both.

And treat architecture, planning, and validation as first-class engineering activities rather than optional steps.
