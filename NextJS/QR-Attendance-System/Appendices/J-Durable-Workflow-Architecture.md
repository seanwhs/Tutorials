# Appendix J

# Durable Workflow Architecture

> *"A user request lasts milliseconds. A business process may last seconds, minutes, or even hours. Durable workflows bridge that gap by ensuring business operations continue reliably long after the original HTTP request has ended."*

---

# Purpose

Modern web applications rarely complete all work within a single request.

After an attendee checks in, the system may need to:

* Send a confirmation email.
* Update attendance statistics.
* Refresh a live dashboard.
* Record audit information.
* Publish analytics.
* Notify downstream systems.

Attempting to perform these operations synchronously increases latency, reduces reliability, and tightly couples independent concerns.

The reference implementation solves this by delegating long-running operations to **Inngest**, which provides durable execution, retries, scheduling, and event-driven orchestration.

---

# Why Durable Workflows?

Traditional request/response processing assumes success or failure occurs immediately.

Production systems are different.

Networks fail.

Email providers experience outages.

Databases become temporarily unavailable.

External APIs return transient errors.

Rather than treating these conditions as exceptional, durable workflows treat them as expected operating conditions.

---

# Architectural Position

```text
                    User
                      │
                      ▼
             Next.js Server Action
                      │
                      ▼
            Attendance Service
                      │
                      ▼
             Attendance Recorded
                      │
                      ▼
          Publish Domain Event
                      │
                      ▼
              Inngest Workflow
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
   Send Email     Analytics      Dashboard
                                      │
                                      ▼
                              Audit Logging
```

The workflow engine operates independently of the user request while preserving business integrity.

---

# Event-Driven Architecture

The platform is fundamentally event-driven.

Instead of invoking downstream services directly, the application publishes domain events.

Examples include:

* AttendanceRequested
* AttendanceValidated
* AttendanceRecorded
* AttendanceRejected
* SessionStarted
* SessionCompleted
* EventClosed
* NotificationRequested

Each event represents a business fact rather than a technical implementation detail.

---

# Workflow Lifecycle

Every workflow progresses through several phases.

```text
Event Published
        │
        ▼
Workflow Created
        │
        ▼
Execute Step
        │
        ▼
Success?
   ┌────┴────┐
   │         │
 Yes        No
   │         │
   ▼         ▼
Next Step   Retry
   │         │
   └────┬────┘
        ▼
Workflow Complete
```

Individual failures do not invalidate the entire workflow.

---

# Workflow Design Principles

Every workflow in the reference implementation follows the same principles:

* Small, focused steps.
* Explicit retry boundaries.
* Idempotent operations.
* Immutable event payloads.
* Observable execution.
* Deterministic behavior.

These principles improve resilience and simplify troubleshooting.

---

# The Attendance Workflow

The central workflow in the platform coordinates all post-check-in processing.

Typical execution sequence:

```text
AttendanceRecorded
        │
        ▼
Load Event Context
        │
        ▼
Generate Audit Record
        │
        ▼
Send Confirmation Email
        │
        ▼
Publish Analytics
        │
        ▼
Update Live Dashboard
        │
        ▼
Notify Integrations
        │
        ▼
Workflow Complete
```

Each operation is isolated into an independently retryable step.

---

# Retry Strategy

Retries are not failures.

They are an expected feature of distributed systems.

Typical retry candidates include:

* Email delivery
* Network requests
* API rate limits
* Temporary database outages
* Third-party integrations

Business rule violations should **not** be retried.

---

# Idempotency

Every workflow must be safe to execute multiple times.

Typical safeguards include:

* Business keys
* Correlation IDs
* Workflow IDs
* Repository uniqueness checks

If a retry produces duplicate business effects, the workflow is incorrectly designed.

---

> **Production Tip — Design for Duplicate Delivery**
>
> In distributed systems, "exactly once" delivery is rarely achievable. Design workflows assuming events may be delivered more than once. Make each step idempotent so repeated execution produces the same final business state.

---

# Compensation

Some business operations cannot simply be retried.

Consider this sequence:

```text
Attendance Recorded

↓

Seat Reserved

↓

Payment Refunded

↓

Email Failed
```

Retrying the entire workflow may produce unintended consequences.

Instead, workflows define **compensation actions**.

Example:

```text
Reserve Seat

↓

Failure

↓

Release Seat
```

Compensation restores business consistency without requiring manual intervention.

---

# Fan-Out Processing

One business event often produces multiple independent activities.

```text
AttendanceRecorded
        │
 ┌──────┼────────┐
 ▼      ▼        ▼
Email Dashboard Analytics
                 │
                 ▼
             Reporting
```

Each branch executes independently.

Failure in one branch does not block the others.

---

# Scheduling

Durable workflows also support delayed execution.

Examples include:

* Reminder emails.
* Follow-up surveys.
* Attendance certificates.
* Event completion reports.

Scheduling removes the need for separate cron infrastructure.

---

# Workflow Versioning

Business processes evolve.

Rather than modifying active workflows, new versions should be introduced alongside existing definitions.

Benefits include:

* Backward compatibility.
* Safer deployments.
* Easier rollback.
* Predictable execution.

Workflow history remains reproducible.

---

# Failure Classification

Workflow failures fall into three categories.

| Category       | Example              | Retry       |
| -------------- | -------------------- | ----------- |
| Business       | Duplicate attendance | No          |
| Infrastructure | Email timeout        | Yes         |
| Unexpected     | Bug                  | Investigate |

Classification enables targeted recovery strategies.

---

# Observability

Every workflow execution should emit telemetry.

Recommended metrics include:

* Execution duration.
* Retry count.
* Success rate.
* Failure rate.
* Queue latency.
* Step duration.

Each execution is correlated with the originating user request.

---

# Dead Letter Strategy

Persistent failures require special handling.

Rather than retrying indefinitely, failed events should eventually be moved to a dead-letter queue or equivalent review process.

Operational teams can then investigate, repair, and replay affected workflows without impacting new requests.

---

# Scaling Characteristics

Durable workflows scale horizontally.

Benefits include:

* Independent workers.
* Automatic retry.
* Parallel execution.
* Burst absorption.
* Fault isolation.

The workflow engine becomes the application's shock absorber during traffic spikes.

---

# Relationship to Next.js

Next.js Server Actions complete quickly.

Durable workflows continue processing after the HTTP request has finished.

This separation enables:

* Faster perceived performance.
* Improved resilience.
* Better fault isolation.
* Cleaner application code.

Together they form the synchronous and asynchronous halves of the application's execution model.

---

# Reference Implementation

The implementation accompanying this appendix includes:

* Workflow definitions.
* Event publishers.
* Retry policies.
* Fan-out orchestration.
* Compensation handlers.
* Scheduled workflows.
* Observability hooks.
* Integration tests.

These artifacts collectively define the platform's asynchronous execution engine.

---

# Looking Ahead

With synchronous request handling and asynchronous workflow orchestration established, the next appendix focuses on the **Presentation Layer**.

The user interface is more than visual design—it is responsible for translating distributed system behavior into a fast, intuitive, and trustworthy user experience through Server Components, Client Components, optimistic updates, progressive enhancement, and offline support.
