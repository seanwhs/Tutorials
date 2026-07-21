**Part 0: Introduction**

Welcome to **Privacy by Design: Engineering the Default** — the most practical, code-first guide to building applications where privacy isn’t an afterthought, a legal checkbox, or a marketing slogan. It is the **default behavior** of the system. By the end of this series, you will have built **GreyMatter MindfulLog**, a fully functional mental-health journaling application that demonstrates production-grade privacy engineering from the ground up.

### Why This Series Exists
Most “privacy” tutorials stop at “add a consent banner and a terms-of-service link.” That approach fails users and engineers alike. Real privacy engineering asks a harder question:

> **What is the system architecture that makes violating user privacy structurally difficult or impossible, rather than merely contractually forbidden?**

This series answers that question by building a real application with real code. No hand-wavy theory. No “in a real app you would…” placeholders. Every concept is implemented, tested, and verified before you move on.

### Who This Is For
- Engineers who know **TypeScript**, **React**, and basic **SQL**.
- Developers who have shipped apps but feel uneasy about how they handle user data.
- No prior experience required in cryptography, compliance, security engineering, or privacy law. Every term is explained with concrete analogies the first time it appears.

If you can follow `npm install` and copy-paste code into the right files, you can complete this series.

### The Project: MindfulLog
**MindfulLog** is a private journaling app where users:
- Record daily mood scores (1–10) with optional private notes.
- Write free-text journal entries.
- Set medication reminders.
- Manage granular consent preferences for every purpose.
- Request a complete export of their data (DSAR — Data Subject Access Request).
- Permanently delete their account and all associated data across every system.

**Why mental health data?**  
Under regulations like GDPR, health data is classified as “special category” data. It receives the highest level of protection. If you learn to engineer privacy correctly for health data, every other domain (finance, social media, e-commerce, SaaS) becomes a simpler variation. The patterns you learn here transfer directly.

### Core Philosophy
We refuse to treat “just add a checkbox” as an acceptable solution. Instead, we ask at every decision point:
- Can this data be minimized or removed entirely?
- Is encryption enforced by the type system?
- Does the code make the safe behavior the *only* possible behavior?
- Is the user in control, with transparency and easy rights exercise?

### The Complete Stack
We use modern, production-ready tools chosen specifically for privacy and developer experience:

| Technology              | Role                                                                 | Privacy Benefit |
|-------------------------|----------------------------------------------------------------------|-----------------|
| **Next.js 16 (App Router)** | Full-stack framework (UI + API routes + Server Actions)             | Server Components keep sensitive logic off the client |
| **Clerk**               | Authentication, user management, deletion webhooks                  | Secure sessions + easy account deletion |
| **Neon Serverless Postgres** | Database with branching for safe testing                            | Easy to test destructive operations |
| **Inngest**             | Durable background jobs with retries and state                      | Reliable consent propagation & export jobs |
| **Google Cloud KMS**    | Hardware Security Module (HSM) backed key management                | Strong envelope encryption |
| **Tailwind CSS**        | Styling                                                              | Clean, accessible UI |
| **Zod**                 | Runtime validation & type inference                                 | Prevents bad data at boundaries |
| **Upstash Redis**       | Rate limiting                                                        | Prevents abuse of export/deletion endpoints |

### High-Level Architecture
```
Browser (React Server Components + Tailwind)
    ↓ HTTPS (always)
Next.js Server
    ├── Clerk Middleware (auth)
    ├── Zod Validation
    ├── Rate Limiting (Redis)
    ├── RBAC/ABAC Policy Engine (centralized, testable)
    ├── PII-Redacting Logger
    ├── Field-Level Encryption Service
    │
    ├──→ Neon Postgres (encrypted columns only, minimized schema)
    ├──→ Google Cloud KMS (KEK never leaves HSM)
    ├──→ Inngest (durable jobs for export, deletion, consent sync)
    └──→ Clerk (identity lifecycle)
```

**Key Design Decisions**:
- Plaintext health data **never** touches disk or logs.
- Every access decision goes through a centralized policy engine.
- Consent is append-only (immutable history).
- Deletion cascades safely across systems with retries.
- CI/CD enforces privacy rules on every pull request.

### The 7 Privacy by Design Principles (Engineering Lens)
1. **Proactive not Reactive** — Threat modeling and DPIA *before* writing schema.
2. **Privacy as the Default** — Encryption and minimization enforced by types and compiler.
3. **Privacy Embedded into Design** — Policy engine at the heart of the app.
4. **Full Functionality** — Privacy features (export, deletion) improve the product.
5. **End-to-End Security** — Protection from browser to database to background jobs.
6. **Visibility & Transparency** — Users can see their full consent history and data.
7. **Respect for the User** — Anti-dark-pattern interfaces and easy rights exercise.

### What You Will Have Built by the End
- A living **DPIA** (Data Protection Impact Assessment) document.
- Minimized, type-safe encrypted database schema.
- Production-grade envelope encryption library.
- Centralized RBAC/ABAC policy engine with audit logging.
- Append-only consent ledger with event-driven propagation.
- Anti-dark-pattern consent UI.
- Full DSAR export pipeline (ZIP with manifest).
- Safe multi-system deletion orchestrator.
- PII-redacting logger and privacy CI/CD pipeline.
- Incident response playbook.

### Prerequisites & Account Setup
**Technical**:
- Node.js 20+ and npm
- Git

**Accounts (create these now)**:
1. **Clerk** — Sign up, create an application (Email + Password enabled).
2. **Neon** — Create a Postgres project and copy the connection string.
3. **Google Cloud** — Create a project, enable Cloud KMS, create a key ring and symmetric key.
4. **Upstash** — Create a Redis instance.
5. GitHub account (for CI later).

We will configure environment variables step-by-step in Part 1.

### How to Use This Series
- Follow every step in order.
- Type (don’t just copy-paste) the code when possible — it helps learning.
- Run every verification command before moving forward.
- At the end of each major part, you will have a working, testable milestone.

This is not a passive reading experience. This is an **engineering apprenticeship**.

---

**You are now ready to begin building.**
