# Production Patterns with Next.js 16

## Reference Architecture #1 — Part 5

# Building a Durable Attendance Orchestration Engine with Inngest

### From User Intent to Reliable Workflow Execution

> **A successful production system isn't one that never fails. It's one that continues making progress when failures inevitably occur.**

---

# Executive Summary

In the previous article, we built the application layer using Next.js 16 Server Components, Clerk authentication, and Server Actions.

When the attendee clicked **Check In**, we deliberately stopped short of writing to the database.

Instead, we published a single event:

```text
attendance/checkin.requested
```

At first glance, that may seem like an unnecessary layer of complexity.

Why not simply save the attendance record directly?

The answer lies in the nature of distributed systems.

Real-world applications experience:

* network interruptions
* transient database failures
* third-party API outages
* serverless cold starts
* duplicate requests
* retry storms
* rate limits

A synchronous request-response model forces the user to wait while all of these operations complete—or fail.

By contrast, a durable workflow decouples user interaction from background processing. The user receives immediate confirmation that their request has been accepted, while the system continues processing reliably in the background.

This article explores how Inngest enables that architecture.

---

# Why Workflows Instead of CRUD?

A CRUD mindset assumes that one request performs one operation.

Attendance appears to fit that model:

```text
POST /attendance

↓

INSERT attendance
```

But in reality, a production check-in is a business process with multiple dependent steps.

```text
Check In Requested
        │
        ▼
Validate Event
        │
        ▼
Validate User
        │
        ▼
Check Idempotency
        │
        ▼
Persist Attendance
        │
        ├────────► Confirmation Email
        │
        ├────────► Analytics
        │
        ├────────► Live Dashboard
        │
        ├────────► Audit Trail
        │
        └────────► Badge Printing
```

Only one of these steps is critical.

Everything else is a side effect.

That distinction is the foundation of a resilient system.

---

# The Workflow Lifecycle

The entire journey begins with a single event emitted from the Server Action.

```text
Server Action
      │
      ▼
attendance/checkin.requested
      │
      ▼
Inngest Workflow
      │
      ├────────► Validation
      ├────────► Idempotency
      ├────────► Persistence
      ├────────► Notifications
      ├────────► Analytics
      └────────► Live Updates
```

The workflow becomes the system's orchestration engine.

It coordinates work without tightly coupling the participating services.

---

# Step 1 — Receive the Event

The workflow starts when Inngest receives the published event.

Its responsibility is not to trust the incoming payload blindly, but to establish context.

The first step gathers everything required to make an informed decision:

* event metadata
* authenticated user information
* workflow identifiers
* timestamps
* correlation IDs

Every subsequent step depends on this context.

---

# Step 2 — Validate the Event

Before touching persistence, the workflow verifies the event itself.

Typical checks include:

* Event exists.
* Event is published.
* Current time is within the check-in window.
* Capacity constraints (if enforced).
* Event has not been cancelled.

Rejecting invalid requests early conserves resources and keeps downstream systems clean.

---

# Step 3 — Enforce Idempotency

Distributed systems retry.

Browsers retry.

Users retry.

Idempotency is therefore not optional—it is fundamental.

Derive a deterministic key using the event identifier and authenticated user.

```text
SHA256(eventId + ":" + userId)
```

Before creating a new attendance record, search for an existing record with the same key.

If one exists, the workflow simply returns the existing result.

Repeated requests converge on the same outcome instead of creating duplicate attendance records.

> **Production Tip — Idempotency Is Your Safety Net**
>
> Never assume a request will only arrive once. Design every workflow so it can be executed repeatedly without changing the final state.

---

# Step 4 — Persist Attendance

Only after validation and idempotency checks succeed should the workflow persist the attendance record.

The persistence layer should store:

* event reference
* user reference
* server timestamp
* workflow ID
* correlation ID
* attendance method
* processing metadata

Persistence represents the **point of commitment**.

Once this step succeeds, the attendee has officially checked in.

Everything else becomes optional from the user's perspective.

---

# Step 5 — Fan-Out Side Effects

With the attendance safely stored, the workflow can execute independent side effects.

```text
Attendance Stored
       │
 ┌─────┼──────────────┐
 ▼     ▼              ▼
Email Analytics Live Dashboard
```

Examples include:

* Sending a confirmation email.
* Updating attendance analytics.
* Incrementing a live dashboard counter.
* Triggering badge printing.
* Recording audit events.
* Publishing webhooks for partner systems.

Each task operates independently.

A failure in one does not compromise the others.

---

# Step 6 — Retry Intelligently

Transient failures are expected.

Examples include:

* Temporary database unavailability.
* Email provider latency.
* API rate limiting.
* Network interruptions.

A durable workflow retries only the failed step, preserving the successful work already completed.

This targeted retry strategy dramatically reduces duplicate processing and improves recovery times.

---

# Failure Scenarios

Let's examine common production failures.

| Failure               | Workflow Behaviour                  |
| --------------------- | ----------------------------------- |
| User taps twice       | Existing attendance returned        |
| Database timeout      | Persistence retried                 |
| Email outage          | Attendance preserved, email retried |
| Analytics unavailable | Metrics delayed                     |
| Dashboard offline     | Workflow continues                  |
| Workflow restart      | Resumes from last completed step    |

Notice that no single failure prevents attendance from being recorded.

---

# Eventual Consistency

A key concept in distributed systems is eventual consistency.

When the attendee presses **Check In**, they receive confirmation that the request has been accepted.

Background work continues asynchronously.

```text
User
  │
  ▼
Attendance Accepted
  │
  ▼
Workflow
  │
  ├────────► Email
  ├────────► Dashboard
  ├────────► Analytics
  └────────► Audit
```

The user experiences a fast, responsive interface while the system ensures reliable completion.

---

# Observability

Production workflows must be observable.

Every execution should capture:

* workflow execution ID
* correlation ID
* event ID
* user ID
* retry count
* execution duration
* current step
* outcome

These identifiers enable operators to trace a single attendance request across every participating system.

---

# Engineering Decision Record — Durable Execution

**Problem**

Business processes involve multiple dependent operations, each with different reliability characteristics.

**Decision**

Model attendance as a durable workflow rather than a synchronous request.

**Benefits**

* Automatic retries.
* Step-level recovery.
* Independent side effects.
* Better scalability.
* Clear operational visibility.

**Trade-offs**

The architecture becomes eventually consistent for non-critical operations, requiring teams to embrace asynchronous thinking.

---

# Common Workflow Anti-Patterns

Avoid these mistakes:

* Writing to the database before validating the event.
* Sending emails before persistence succeeds.
* Assuming requests are unique.
* Coupling analytics to critical path processing.
* Treating retries as exceptional.
* Ignoring correlation IDs.

These shortcuts often work during development but become liabilities in production.

---

# Putting It All Together

The complete orchestration looks like this:

```text
Scan QR
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
attendance/checkin.requested
   │
   ▼
Inngest Workflow
   │
   ├────────► Validate Event
   ├────────► Check Idempotency
   ├────────► Persist Attendance
   ├────────► Send Email
   ├────────► Update Analytics
   ├────────► Update Dashboard
   └────────► Record Audit
```

Each component performs one responsibility.

Together, they form a resilient, production-grade orchestration engine.

---

# Looking Ahead

The architecture is now functionally complete.

In the final article, we'll focus on the operational concerns that distinguish production software from successful prototypes.

Topics include:

* Rate limiting with Upstash Redis.
* Offline-first check-ins using Service Workers.
* Real-time dashboards.
* Structured logging.
* Distributed tracing.
* Correlation IDs.
* Deployment on Vercel.
* Load testing.
* Capacity planning.
* Chaos engineering.
* Scaling to thousands of concurrent attendees.

Because building the system is only half the challenge.

Operating it reliably is where engineering truly begins.
