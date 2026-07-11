# Production Patterns with Next.js 16

## Reference Architecture #1

# Designing a Production-Ready QR Attendance System

### A Reference Architecture Using Next.js 16, Clerk, Sanity, Inngest, Resend, and Upstash Redis

> **Handling ten QR check-ins is an application problem. Handling five thousand concurrent check-ins without losing a single attendance record is a distributed systems problem.**

---

## Executive Summary

Building a QR code attendance application appears deceptively simple.

Generate a QR code.

Allow attendees to scan it.

Record their attendance.

Display a success message.

That workflow is sufficient for demonstrations, prototypes, and small internal events. Unfortunately, production systems rarely operate under ideal conditions.

Imagine the doors opening at a technology conference.

Within the first few minutes:

* 5,000 attendees scan the same QR code.
* Mobile networks become congested.
* Users accidentally tap **Check In** multiple times.
* Serverless functions scale up simultaneously.
* Database writes begin competing with one another.
* Email providers experience intermittent latency.
* Organizers expect a live attendance dashboard to update instantly.
* Support teams expect a complete audit trail for every attendee.

None of these are unusual.

They are the normal operating conditions of modern distributed systems.

Most tutorials focus on the **happy path**:

```text
Scan QR
    │
    ▼
POST /checkin
    │
    ▼
Write Database
    │
    ▼
Success
```

This architecture works until traffic increases, networks become unreliable, or users retry requests.

The problem isn't generating QR codes.

The problem is coupling authentication, validation, persistence, notifications, analytics, and reporting into a single synchronous request.

This article presents a **production reference architecture** that separates these concerns into independent layers, creating an attendance platform that is secure, resilient, observable, and capable of scaling from a classroom workshop to a conference with tens of thousands of attendees.

Rather than teaching a single implementation, this article explains the engineering principles behind the architecture and the trade-offs that informed each design decision.

---

# Who This Series Is For

This series assumes you're already comfortable with modern web development and have some familiarity with React and the Next.js App Router.

Rather than teaching framework fundamentals, this series focuses on **engineering systems that survive production**.

You'll benefit most if you are:

* Building internal business applications
* Developing event registration platforms
* Designing workflow-oriented applications
* Learning modern server-side architecture with Next.js 16
* Interested in durable execution, idempotency, and event-driven design
* Moving beyond CRUD applications into production-grade systems

The objective isn't simply to build an attendance application.

The objective is to understand **why resilient systems are designed differently from simple applications.**

---

# The Engineering Problem

Most software projects begin with a functional requirement.

> "We need attendees to scan a QR code."

While technically correct, it hides the real engineering challenge.

A better question is:

> **How do we guarantee that every attendee is recorded exactly once, even when users retry requests, networks fail, APIs become unavailable, and thousands of requests arrive simultaneously?**

That subtle change completely transforms the architecture.

Attendance is no longer viewed as a CRUD operation.

It becomes a workflow.

And workflows require orchestration.

---

# Why Traditional QR Attendance Systems Fail

A typical implementation looks something like this:

```text
QR Code
    │
    ▼
Client Application
    │
    ▼
REST API
    │
    ▼
Database
```

This design appears straightforward.

Unfortunately, it couples every responsibility into one request.

The API endpoint is expected to:

* authenticate the attendee
* validate the event
* verify the check-in window
* prevent duplicates
* write the attendance record
* send confirmation emails
* update analytics
* refresh live dashboards

All within a single HTTP request.

This introduces several problems:

### Duplicate Requests

Users double-click buttons.

Browsers retry failed requests.

Mobile networks reconnect.

Without idempotency, duplicate attendance records become inevitable.

---

### Long Request Times

Sending emails, updating dashboards, and writing analytics all increase latency.

Users perceive the application as slow, even though the attendance itself may have succeeded.

---

### Tight Coupling

If the email provider becomes unavailable, should attendance fail?

If the analytics platform experiences an outage, should attendees be denied entry?

In tightly coupled systems, unrelated failures often cascade into user-facing problems.

---

### Limited Observability

When everything happens inside one API request, answering questions becomes difficult.

Why did this attendee fail?

Which retry succeeded?

Which notification wasn't delivered?

Which workflow step timed out?

Without visibility into each stage, diagnosing production issues becomes unnecessarily difficult.

---

# Rethinking Attendance

Instead of treating attendance as a database write, we model it as a workflow.

```text
Scan QR
    │
    ▼
Authenticate
    │
    ▼
Validate Request
    │
    ▼
Publish Attendance Event
    │
    ▼
Workflow Orchestration
    │
    ▼
Persist Attendance
    │
    ├────────────► Email
    │
    ├────────────► Analytics
    │
    ├────────────► Live Dashboard
    │
    └────────────► Audit Log
```

This separation is one of the defining characteristics of production systems.

The user interaction ends quickly.

The system continues processing reliably in the background.

---

# Architectural Principles

Every architectural decision in this series is guided by six principles.

These principles remain valid regardless of framework or cloud provider.

## 1. Identity Comes From the Server

Clients initiate requests.

Servers establish identity.

Authentication should never depend on information supplied by the browser.

Instead, every request derives identity from a trusted authenticated session.

---

## 2. Every Operation Must Be Idempotent

Distributed systems retry.

Browsers retry.

Users retry.

Therefore, every attendance request must be safe to execute multiple times.

The desired outcome is always identical:

One attendee.

One event.

One attendance record.

---

## 3. Separate Critical Work From Side Effects

Recording attendance is the critical operation.

Everything else is secondary.

Examples include:

* confirmation emails
* analytics
* dashboards
* Slack notifications
* CRM integrations
* badge printing

These should never delay or jeopardize attendance itself.

---

## 4. Assume Failure Is Normal

Production software isn't designed around success.

It's designed around recovery.

Network failures.

Temporary outages.

API rate limits.

Cold starts.

Retries.

These are expected.

Resilient systems recover automatically without requiring manual intervention.

---

## 5. Every Layer Should Have One Responsibility

Authentication authenticates.

Validation validates.

Persistence persists.

Workflows orchestrate.

Notifications notify.

Keeping responsibilities isolated reduces complexity while making systems easier to maintain and evolve.

---

## 6. Design for Operations

Software isn't finished when it compiles.

It succeeds when operators can answer questions such as:

* What happened?
* When did it happen?
* Why did it happen?
* Can it be replayed?
* Can it be audited?

Operational visibility is a first-class architectural concern.

---

# The Reference Architecture

The system consists of several independent layers.

```text
                   QR Code
                      │
                      ▼
        Next.js 16 Server Component
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
 Validation      Persistence     Side Effects
                      │
                      ▼
                 Sanity CMS
        ┌─────────────┼──────────────┐
        ▼             ▼              ▼
      Resend      Analytics     Live Dashboard
```

Notice what doesn't happen.

The browser never writes directly to the database.

Instead, it communicates **intent**.

The backend decides how that intent becomes application state.

This distinction dramatically improves reliability.

---

# Why This Technology Stack?

Technology should solve architectural problems—not dictate them.

| Layer                 | Technology    | Responsibility                                    |
| --------------------- | ------------- | ------------------------------------------------- |
| UI                    | Next.js 16    | Server Components, App Router, and Server Actions |
| Authentication        | Clerk         | Identity, sessions, and authorization             |
| Content & Persistence | Sanity        | Event metadata and attendance records             |
| Workflow Engine       | Inngest       | Durable execution and orchestration               |
| Email                 | Resend        | Transactional notifications                       |
| Rate Limiting         | Upstash Redis | Traffic shaping and abuse prevention              |
| Deployment            | Vercel        | Serverless hosting and global delivery            |

Each technology addresses a specific engineering concern.

Replace one component and the overall architecture remains intact.

That is the hallmark of loosely coupled systems.

---

# End-to-End Request Lifecycle

Let's follow one attendee through the system.

```text
Attendee
    │
Scan QR Code
    │
    ▼
Load Check-In Page
    │
Authenticate Session
    │
Validate Event
    │
Render Check-In Button
    │
User Confirms
    │
Server Action
    │
Publish Workflow Event
    │
Workflow Validation
    │
Persist Attendance
    │
Execute Side Effects
    │
Workflow Complete
```

From the attendee's perspective, the process feels almost instantaneous.

Behind the scenes, multiple systems collaborate to ensure reliability.

---

# Failure Is the Default State

One hallmark of mature engineering organizations is designing for expected failures rather than exceptional ones.

| Scenario                         | Desired Outcome                  | Architectural Response   |
| -------------------------------- | -------------------------------- | ------------------------ |
| User taps twice                  | One attendance record            | Idempotency key          |
| Network disconnects              | Attendance eventually succeeds   | Retry workflow           |
| Database temporarily unavailable | Workflow pauses and retries      | Durable execution        |
| Email service outage             | Attendance still succeeds        | Independent retry        |
| Analytics unavailable            | Metrics delayed                  | Isolated side effects    |
| Dashboard offline                | Organizers lose visibility only  | Workflow continues       |
| Server timeout                   | Processing resumes automatically | Persisted workflow state |

Failures become isolated events rather than application-wide outages.

---

# Production Patterns

Throughout this series we'll revisit several recurring production patterns.

## Thin Server Actions

Server Actions should:

* authenticate
* authorize
* validate
* publish workflow events

They should not contain long-running business logic.

---

## Event-Driven Processing

Instead of calling multiple services directly:

```text
User
   │
   ▼
Database
   │
   ├── Email
   ├── Analytics
   ├── Dashboard
   └── Notifications
```

Publish a single event.

Allow independent systems to react.

This reduces coupling while improving resilience.

---

## Eventual Consistency

Users care about one thing:

> "Was my attendance accepted?"

They do not need to wait for:

* email delivery
* analytics
* reporting
* dashboards

Processing these asynchronously dramatically improves responsiveness.

---

## Observability

Every request should be traceable.

Useful metadata includes:

* workflow ID
* correlation ID
* user ID
* event ID
* retry count
* execution duration

These become invaluable during production incidents.

---

# Engineering Decision Records

Good engineering isn't about making decisions.

It's about documenting why they were made.

Throughout this series, we'll use Engineering Decision Records (EDRs) to capture architectural reasoning.

---

## EDR-001 — Why Server Actions?

**Problem**

Attendance requests require authenticated user context.

**Decision**

Use Server Actions as the application's command interface.

**Benefits**

* Business logic remains on the server.
* Authentication integrates naturally.
* Internal API endpoints are reduced.
* Type safety improves.

**Trade-offs**

The implementation becomes more tightly coupled to Next.js.

---

## EDR-002 — Why Durable Workflows?

**Problem**

Database writes, emails, analytics, and dashboards have different reliability requirements.

**Decision**

Move orchestration into a durable workflow engine.

**Benefits**

* Automatic retries
* Step-level recovery
* Better observability
* Decoupled side effects

**Trade-offs**

The system becomes eventually consistent for non-critical operations.

---

# Series Roadmap

This article establishes the architectural blueprint.

The remainder of the series implements it layer by layer.

| Part       | Focus                                                                       |
| ---------- | --------------------------------------------------------------------------- |
| **Part 1** | Reference Architecture and Engineering Principles                           |
| **Part 2** | Modeling Events and Attendance with Sanity                                  |
| **Part 3** | Building the Secure Check-In Experience with Next.js 16 and Clerk           |
| **Part 4** | Durable Workflow Orchestration with Inngest                                 |
| **Part 5** | Real-Time Dashboards, Notifications, and Offline Support                    |
| **Part 6** | Production Hardening: Observability, Rate Limiting, Deployment, and Scaling |

By the end of the series, we'll have built not just an attendance application, but a production-grade platform capable of supporting enterprise-scale events.

---

# Closing Thoughts

The most important lesson isn't about QR codes.

Nor is it about Next.js.

Nor Clerk.

Nor Inngest.

It's about how we think about software.

A tutorial asks:

> *How do I build this feature?*

An architect asks:

> *How does this feature behave when the network fails, users retry requests, third-party services become unavailable, and thousands of requests arrive simultaneously?*

That shift in perspective changes everything.

When user interactions are modeled as **durable workflows** instead of **database writes**, systems become easier to scale, easier to operate, easier to extend, and significantly more resilient.

The QR code is merely the beginning of the journey.

The real engineering happens after the scan.
