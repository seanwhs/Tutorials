# Production Patterns with Next.js

# Reference Architecture #1

# Designing a Production-Ready QR Attendance System

### Building a resilient attendance platform with Next.js 16, Clerk, Sanity, Inngest, and modern serverless architecture

> **Handling ten QR check-ins is an application problem. Handling five thousand concurrent check-ins without losing a single attendance record is a distributed systems problem.**

---

## Executive Summary

Generating a QR code is easy.

Recording attendance is easy.

Building an attendance platform that continues to work under production conditions is not.

Consider what actually happens when the doors open at a large conference.

Within the first few minutes:

* thousands of attendees scan the same QR code
* users accidentally tap **Check In** multiple times
* mobile networks become congested
* serverless functions cold start simultaneously
* database writes begin competing with one another
* email providers experience intermittent latency
* organizers expect live attendance dashboards to update in real time
* support teams expect complete audit trails

None of these scenarios are unusual.

They are the normal operating conditions of modern distributed systems.

Most tutorials focus on implementing the **happy path**:

```
Scan QR
    ↓
POST /checkin
    ↓
Save to Database
```

That architecture works well in development.

It begins to fail in production.

The problem isn't the QR code.

The problem is coupling user interaction, validation, persistence, notifications, analytics, and reporting into a single synchronous request.

This article presents a **reference architecture** that separates these concerns into independent, resilient components capable of scaling from a classroom workshop to a conference with tens of thousands of attendees.

Rather than teaching a single implementation, this article explains the engineering decisions behind the architecture and the trade-offs involved in building reliable systems.

---

# The Engineering Problem

Let's reframe the question.

Instead of asking:

> **How do we build a QR attendance application?**

Ask:

> **How do we guarantee that every attendee is recorded exactly once, even when users retry requests, networks fail, APIs become unavailable, and thousands of requests arrive simultaneously?**

That single question changes everything.

Attendance is no longer a CRUD operation.

Attendance becomes a workflow.

And workflows require orchestration.

---

# Engineering Principles

Before discussing frameworks or writing code, define the principles that drive every architectural decision.

These principles remain valid regardless of the technologies you choose.

## Principle 1 — Identity Must Come From the Server

The browser should never tell the backend who the user is.

Identity is established through an authenticated session and verified by the server.

Every subsequent decision depends on trusted identity.

---

## Principle 2 — Every Operation Must Be Idempotent

Distributed systems retry requests.

Browsers retry requests.

Users retry requests.

Your application must behave correctly regardless.

The desired outcome is simple:

One attendee.

One event.

One attendance record.

No matter how many identical requests arrive.

---

## Principle 3 — Separate Critical Work From Side Effects

The primary responsibility of the system is recording attendance.

Everything else is secondary.

Examples include:

* confirmation emails
* analytics
* dashboard updates
* Slack notifications
* CRM integrations

These should never delay or jeopardize the primary operation.

---

## Principle 4 — Assume Failure Is Normal

Production systems don't ask:

> "What happens if something fails?"

They ask:

> "Which component will fail next?"

Design every layer assuming temporary failure.

Retries should be expected.

Timeouts should be expected.

Duplicate requests should be expected.

---

## Principle 5 — Every Component Should Have One Responsibility

Authentication authenticates.

Validation validates.

Persistence persists.

Workflows orchestrate.

Notifications notify.

Keeping responsibilities isolated reduces complexity and allows each service to scale independently.

---

## Principle 6 — Optimize for Operations, Not Demos

Most tutorials optimize for simplicity.

Production systems optimize for observability.

Can operators answer questions like:

* Why did this attendance fail?
* Was it eventually recorded?
* Which retry succeeded?
* How many attendees checked in during the last minute?

If not, the architecture is incomplete.

---

# The Reference Architecture

The system can be viewed as a pipeline rather than a request.

```
                 QR Code
                    │
                    ▼
         Next.js Server Component
                    │
                    ▼
         Clerk Authentication
                    │
                    ▼
            Server Action
                    │
                    ▼
         Attendance Event Published
                    │
                    ▼
         Inngest Durable Workflow
                    │
      ┌─────────────┼──────────────┐
      ▼             ▼              ▼
 Validate      Persist Data    Side Effects
                    │
                    ▼
               Sanity CMS
      ┌─────────────┼──────────────┐
      ▼             ▼              ▼
   Resend      Analytics      Live Dashboard
```

Notice what **doesn't** happen.

The browser never communicates directly with the database.

Instead, it communicates intent.

The backend decides how that intent becomes state.

That distinction dramatically improves resilience.

---

# Technology Choices

Every technology in the stack exists for a specific architectural reason.

| Layer           | Technology    | Why It Was Chosen                                                                     |
| --------------- | ------------- | ------------------------------------------------------------------------------------- |
| UI              | Next.js 16    | Server Components and Server Actions simplify secure application architecture.        |
| Authentication  | Clerk         | Removes the complexity of authentication while integrating naturally with App Router. |
| Content & Data  | Sanity        | Flexible document storage for events, attendance records, and evolving metadata.      |
| Workflow Engine | Inngest       | Durable execution with retries, observability, and step-level recovery.               |
| Email           | Resend        | Reliable transactional messaging after successful attendance.                         |
| Rate Limiting   | Upstash Redis | Protects the platform during traffic spikes and abusive clients.                      |
| Deployment      | Vercel        | Serverless deployment with Edge support and excellent developer experience.           |

Notice something important.

None of these technologies were selected because they are fashionable.

Each solves a specific architectural problem.

That is the mindset of production engineering.

---

# End-to-End Request Lifecycle

When an attendee scans the QR code, far more happens than most users realize.

```
Attendee

    │

Scan QR

    │

    ▼

Load Event Page

    │

Authenticate

    │

Render Check-In Screen

    │

User Clicks Button

    │

Server Action

    │

Publish Workflow

    │

Workflow Validation

    │

Persist Attendance

    │

Execute Side Effects

    │

Complete
```

From the attendee's perspective, the experience feels instantaneous.

Behind the scenes, multiple independent systems collaborate to make that experience reliable.

---

# Engineering Decision Record #001

## Why Server Actions Instead of REST APIs?

### Problem

Attendance requires access to authenticated user identity.

### Decision

Use Next.js Server Actions.

### Why?

Server Actions execute on the server, integrate naturally with Clerk authentication, reduce unnecessary API surface area, and simplify authorization.

### Trade-offs

Server Actions are tightly coupled to Next.js.

Teams requiring public APIs for external clients may still expose REST or GraphQL endpoints where appropriate.

### Alternatives Considered

* REST API
* GraphQL Mutation
* tRPC

Each remains valid, but none integrate as naturally with authenticated App Router workflows.

---

# Engineering Decision Record #002

## Why Inngest Instead of Writing Directly to Sanity?

### Problem

Database writes may fail.

Emails may fail.

Analytics providers may fail.

Users should never experience those failures.

### Decision

Publish a workflow event.

### Why?

Durable workflows separate user interaction from backend processing.

Individual steps retry automatically.

Failures remain isolated.

Observability becomes significantly easier.

### Trade-offs

The system becomes eventually consistent for non-critical operations.

Additional infrastructure is introduced.

### Alternatives Considered

* Direct database writes
* BullMQ
* RabbitMQ
* AWS SQS
* Temporal

Each solves part of the problem.

Inngest provides durable execution with significantly less operational overhead for serverless applications.

---

# Failure Is the Default State

One of the defining characteristics of production systems is that they are designed around failure rather than success.

| Failure Scenario           | Expected Outcome                    | Architectural Response                       |
| -------------------------- | ----------------------------------- | -------------------------------------------- |
| User taps twice            | One attendance record               | Idempotency key (`eventId + userId`)         |
| Mobile network disconnects | Attendance eventually succeeds      | Offline queue and background synchronization |
| Sanity rate limits writes  | Attendance delayed but preserved    | Automatic retries in Inngest                 |
| Email provider unavailable | Attendance recorded immediately     | Email retried independently                  |
| Dashboard unavailable      | Organizers temporarily lose metrics | Workflow isolates non-critical side effects  |
| Function timeout           | Processing resumes automatically    | Durable workflow execution                   |
| Browser refresh            | No duplicate attendance             | Idempotent persistence                       |

These are not edge cases.

They are expected behavior.

---

# Production Tips

> **Production Tip — Design Every Workflow to Be Re-runnable**
>
> Assume every request will execute more than once. If rerunning the workflow changes the final state, the workflow is not yet production ready.

---

> **Production Tip — Separate User Latency from System Latency**
>
> Users care about seeing "Check-In Successful." They do not care whether analytics completed 200 milliseconds later. Optimize the critical path and defer everything else.

---

> **Production Tip — Logs Tell You What Happened. Workflows Tell You Why.**
>
> A durable workflow gives operations teams visibility into every step, retry, and failure. This is invaluable during large events where diagnosing issues quickly matters.

---

# Looking Ahead

This article intentionally focuses on **architecture rather than implementation**.

Understanding *why* the system is structured this way makes the code that follows much easier to reason about.

In the next articles, we'll implement the entire platform step by step:

* **Part 2 — Modeling Events and Attendance with Sanity**
* **Part 3 — Building the Clerk-Protected Check-In Experience with Next.js**
* **Part 4 — Implementing Durable Workflows with Inngest**
* **Part 5 — Real-Time Dashboards, Notifications, and Offline Support**
* **Part 6 — Production Hardening: Observability, Rate Limiting, and Scaling to Tens of Thousands of Check-Ins**

---

# Closing Thoughts

The most important lesson is not about QR codes.

Nor is it about Next.js, Clerk, Sanity, or Inngest.

It is about how we think about systems.

A tutorial asks:

> *"How do I write this feature?"*

An architect asks:

> *"How does this feature behave when everything around it starts failing?"*

That shift in perspective changes not only how we build attendance systems, but how we design every production application.

When user actions are modeled as **durable workflows** instead of **database writes**, applications become easier to scale, easier to operate, easier to extend, and far more resilient.

And that, ultimately, is the difference between software that works in a demo and software that succeeds in production.
