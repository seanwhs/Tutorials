# Part 0: Introduction  
## Privacy by Design: Engineering the Default

Welcome to **Privacy by Design: Engineering the Default** — a practical, code-first tutorial series about building applications where privacy is not an afterthought, a legal checkbox, or a marketing slogan. Privacy is the **default behavior** of the system.

In this series, we will build **GreyMatter MindfulLog**, a privacy-first mental-health journaling application designed from the ground up around minimization, encryption, user consent, transparency, access control, export rights, deletion rights, and operational readiness.

By the end, you will not just have an app. You will have a working example of privacy engineering as architecture.

---

## The Application: GreyMatter MindfulLog

**GreyMatter MindfulLog** is a private journaling and mental-health reflection app where users can:

- Record daily mood scores from 1–10.
- Add optional private notes to mood logs.
- Write free-text journal entries.
- Set medication or wellness reminders.
- Manage granular consent preferences.
- Request a complete export of their data through a DSAR flow.
- Permanently delete their account and associated data across the system.

Mental-health data is intentionally chosen because it is among the most sensitive categories of personal data. Under GDPR-style privacy regimes, health data receives heightened protection, so if we can design privacy correctly here, the same patterns can transfer to finance, SaaS, education, e-commerce, and social applications [8].

---

## Why This Series Exists

Most applications treat privacy as something added late:

- A cookie banner.
- A privacy policy.
- A checkbox.
- A compliance review.
- A last-minute encryption task.

That is not Privacy by Design.

In **GreyMatter MindfulLog**, we will instead make privacy a structural property of the system. The application should be designed so that unsafe behavior is difficult, obvious, or impossible.

For example:

- Sensitive journal content should not be stored as readable database text.
- Consent decisions should not be silently overwritten.
- Support staff should not casually access private user data.
- Data exports should be deliberate and auditable.
- Account deletion should remove or anonymize the right records.
- Developers should be blocked from accidentally adding plaintext PII.

This is the core idea of the series: **safe behavior should be the only behavior the code naturally allows** [1].

---

## The 7 Privacy by Design Principles

We will use the seven Privacy by Design principles as engineering requirements, not abstract slogans.

### 1. Proactive, not Reactive

We will threat model and perform privacy impact assessment work before designing sensitive features. The goal is to prevent privacy failures before they happen.

### 2. Privacy as the Default

Users should not need to hunt through settings to become safe. The default storage, access, logging, and consent behavior should already protect them.

### 3. Privacy Embedded into Design

Privacy will be built into the schema, encryption layer, access-control model, background jobs, and CI/CD pipeline.

### 4. Full Functionality

Privacy should improve the product, not make it unusable. Features like data export, account deletion, and consent history are both privacy features and user-trust features.

### 5. End-to-End Security

Data must be protected from the browser to the database to background jobs and operational workflows.

### 6. Visibility and Transparency

Users should be able to understand what data exists, why it exists, what they consented to, and how to exercise their rights.

### 7. Respect for the User

The interface should avoid dark patterns. Consent should be clear, symmetric, and freely given [8].

---

## What We Are Building

The final version of **GreyMatter MindfulLog** will include:

- A living DPIA.
- A STRIDE-style threat model.
- A minimized database schema.
- Field-level encryption for sensitive notes and journal content.
- A centralized zero-trust policy engine.
- An append-only consent system.
- Anti-dark-pattern consent screens.
- DSAR export functionality.
- Right-to-erasure account deletion.
- PII-safe logging.
- CI/CD privacy checks.
- Secret scanning.
- Privacy metrics.
- Incident response and operational playbooks.

The completed system is intended to demonstrate production-grade privacy engineering from the ground up [8].

---

## The Core Product Features

GreyMatter MindfulLog will support six primary user-facing capabilities.

### 1. Mood Tracking

Users can record a mood score from 1 to 10. The score itself is relatively low sensitivity compared with free-text notes, but it is still personal behavioral data.

### 2. Private Mood Notes

Users can optionally add private notes to a mood entry. These notes may contain sensitive mental-health information, so they must be encrypted before storage.

### 3. Journal Entries

Users can write free-form journal entries. These entries are highly sensitive and must be protected with strong field-level encryption.

### 4. Reminders

Users can set reminders, such as medication or wellness prompts. These should be designed carefully because reminder content may reveal health-related behavior.

### 5. Consent Management

Users can manage consent preferences for purposes such as analytics, marketing, research, or support access. Consent should be granular, transparent, and auditable.

### 6. Data Rights

Users can request a complete export of their data and can permanently delete their account and associated records [8].

---

## The Engineering Philosophy

This series follows one rule:

> Privacy is not a promise. Privacy is a system property.

That means we do not rely only on developer discipline or policy documents. We enforce privacy through:

- Database design.
- Type choices.
- Encryption boundaries.
- Access-control checks.
- Append-only audit records.
- CI/CD failures.
- Logging restrictions.
- Operational runbooks.

For example, later in the series, sensitive mood notes and journal content will be stored in encrypted binary fields rather than ordinary plaintext text columns [6]. Access decisions will go through a centralized policy engine that fails closed when access is unknown or unsupported [5].

---

## What Makes GreyMatter MindfulLog Different

A normal journaling app might ask:

> How do we let users write notes?

GreyMatter MindfulLog asks:

> How do we let users write notes in a way that minimizes harm if the database leaks, a developer makes a mistake, a support workflow is abused, or consent changes later?

That shift changes everything.

It affects:

- What we store.
- What we refuse to store.
- How we encrypt.
- How we log.
- How we design admin access.
- How we handle user deletion.
- How we test pull requests.
- How we respond to incidents.

This is why the project begins with foundations such as threat modeling, DPIA work, and privacy engineering conventions before user-facing code [7].

---

## Series Roadmap

### Part 0 — Introduction

We define the application, the privacy philosophy, the seven Privacy by Design principles, and the system we are going to build.

### Part 1 — Foundations

We create the project scaffold, privacy conventions, STRIDE threat model, and living DPIA. The DPIA becomes the map of what data exists, why it exists, how sensitive it is, and how it is protected [7].

### Part 2 — Data Minimization and Schema Design

We design the database after the threat model. Every column must have a reason to exist. Sensitive fields such as private notes and journal content are designed as encrypted binary fields, not casual plaintext [6].

### Part 3 — Encryption and Access Control

We implement field-level encryption and a zero-trust policy engine. The goal is defense in depth: even if one layer fails, sensitive health data remains protected [5].

### Part 4 — Consent and Transparency

We build an anti-dark-pattern consent experience with equal prominence for “Allow” and “Don’t Allow,” no pre-checked boxes, and clear explanations [4].

### Part 5 — DSAR Export and Right to be Forgotten

We implement user data export and account deletion flows. This covers the Right of Access and Right to Erasure [3].

### Part 6 — CI/CD and Privacy Guardrails

We add automated privacy checks, safe logging, build validation, and secret scanning so privacy expectations are enforced during development [2].

### Part 7 — Incident Response and Operations

We prepare the application for real-world operation with incident response, key rotation, backups, retention thinking, and final project verification [1].

---

## What You Will Learn

By completing this series, you will learn how to:

- Translate privacy principles into engineering decisions.
- Build a living DPIA.
- Design minimized schemas for sensitive applications.
- Encrypt sensitive fields before database storage.
- Use policy engines for centralized authorization.
- Build append-only consent records.
- Avoid dark patterns in consent UX.
- Implement DSAR exports.
- Implement account deletion and anonymization.
- Redact sensitive values from logs.
- Add privacy checks to CI/CD.
- Prepare an incident response playbook.

The goal is not just to build one app. The goal is to learn reusable privacy architecture patterns.

---

## Success Criteria

At the end of the series, GreyMatter MindfulLog should satisfy these basic checks:

```bash
npm run build
npm run privacy:scan
node -e 'import("./lib/db.js").then(m => m.testConnection())'
```

Manual verification should confirm that:

1. Journal entries are stored as encrypted binary data.
2. Unauthorized access is denied by the policy engine.
3. Data export produces a valid ZIP file.
4. Account deletion removes or anonymizes the appropriate data [1].

---

## Final Thought

GreyMatter MindfulLog is not just a journaling app.

It is a training ground for privacy engineering.

We are going to build a system where privacy is visible in the schema, enforced in the code, checked in CI, respected in the interface, and prepared for operational failure.

That is what it means to engineer privacy as the default.
