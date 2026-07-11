# Appendix I

# Application Entry Points with Next.js 16

> *"Every distributed system has a boundary where user intent becomes business intent. In this reference implementation, that boundary is defined by Next.js 16 Server Actions."*

---

# Purpose

Application Entry Points provide the transition between the presentation layer and the application's business services.

In the reference implementation, this responsibility is fulfilled by **Next.js 16 App Router**, **Server Components**, and **Server Actions**.

Rather than exposing a large collection of REST endpoints, user interactions invoke Server Actions directly. These actions authenticate requests, validate input, authorize operations, invoke the appropriate Application Service, and immediately return control to the user interface.

Long-running work is intentionally delegated to durable workflows.

---

# Why Next.js 16?

Next.js 16 introduces an architecture that naturally aligns with workflow-oriented applications.

Key capabilities include:

* App Router
* React Server Components
* React 19 integration
* Server Actions
* Streaming rendering
* Route-level caching
* Partial Prerendering (where applicable)
* Improved async request handling

Together, these features allow the application to keep business logic on the server while delivering responsive user experiences.

---

# Position Within the Architecture

```text
┌────────────────────────────┐
│        Browser UI          │
└─────────────┬──────────────┘
              │
              ▼
      React Client Components
              │
              ▼
      React Server Components
              │
              ▼
      Next.js Server Action
              │
              ▼
      Application Service
              │
              ▼
 Repository + Workflow Publisher
```

Server Actions are the bridge between user interactions and business behavior.

---

# Responsibilities

Every Server Action has a narrow responsibility:

* Authenticate the user.
* Validate incoming data.
* Authorize the requested operation.
* Invoke the appropriate Application Service.
* Return a lightweight response.

Server Actions intentionally avoid:

* Business decisions.
* Database queries.
* Workflow orchestration.
* Third-party integrations.

Those concerns belong to lower architectural layers.

---

# Command-Oriented Design

Each Server Action represents a user intention.

Examples include:

* Check In
* Register Event
* Cancel Registration
* Close Event
* Generate QR Code

This command-oriented style produces APIs that communicate business intent rather than storage operations.

---

# Authentication

Authentication is provided by Clerk.

Every Server Action executes within an authenticated server context.

Typical flow:

```text
User Clicks Button
        │
        ▼
Server Action
        │
        ▼
Clerk Authentication
        │
        ▼
Authenticated User Context
```

Authentication is performed before any business logic executes.

---

# Authorization

Authentication answers:

> Who is the user?

Authorization answers:

> Can they perform this operation?

Typical authorization decisions include:

* Event organizer
* Administrator
* Speaker
* Attendee

Authorization policies remain separate from authentication.

---

# Validation

Every request undergoes validation before reaching the Application Service.

Typical validation includes:

* Event exists.
* QR payload valid.
* Required fields present.
* Event currently accepting attendance.
* Payload schema valid.

Invalid requests terminate immediately.

---

# Server Action Lifecycle

A complete check-in request follows this sequence:

```text
Button Click
      │
      ▼
Server Action
      │
      ▼
Authenticate
      │
      ▼
Validate Input
      │
      ▼
Authorize
      │
      ▼
AttendanceService
      │
      ▼
Return Success
      │
      ▼
Workflow Executes
```

The user does not wait for background work to complete.

---

# Response Design

Server Actions return concise responses.

Typical responses include:

* Success
* Validation failure
* Authorization failure
* Business rule violation

Heavy business objects are not returned unnecessarily.

This minimizes network overhead and simplifies client state management.

---

# Optimistic User Experience

Because durable workflows execute asynchronously, the user interface adopts an optimistic interaction model.

Typical sequence:

```text
Click Check In
      │
      ▼
Disable Button
      │
      ▼
Show Progress
      │
      ▼
Receive Success
      │
      ▼
Display Confirmation
```

Confirmation emails, dashboard updates, and analytics continue independently.

---

> **Production Tip — Fast Responses Win**
>
> Users judge responsiveness by how quickly the interface acknowledges their action, not by how quickly every background process completes. Persist the essential business state, return immediately, and allow durable workflows to handle notifications, analytics, and other side effects asynchronously.

---

# Error Boundaries

Failures are categorized according to responsibility.

| Layer          | Example                  |
| -------------- | ------------------------ |
| Authentication | No session               |
| Authorization  | Insufficient permissions |
| Validation     | Invalid QR payload       |
| Business       | Already checked in       |
| Infrastructure | Temporary service outage |

Each category produces an appropriate user-facing response while preserving diagnostic information in structured logs.

---

# Rate Limiting

Entry points are responsible for protecting the system against abuse.

Rate limiting may be applied based on:

* User identifier
* IP address
* Event identifier
* Organization
* Device fingerprint

The goal is to smooth traffic spikes without affecting legitimate attendees.

---

# Observability

Every Server Action emits telemetry.

Typical metrics include:

* Request duration
* Success rate
* Failure rate
* Retry count
* Validation failures
* Authentication failures

Correlation identifiers allow requests to be traced through downstream workflows.

---

# Testing

Server Actions are tested independently from user interface components.

Typical test scenarios include:

* Authenticated requests
* Anonymous requests
* Invalid payloads
* Authorization failures
* Successful check-ins
* Duplicate submissions

Business logic remains mocked during these tests, ensuring the focus remains on the entry point itself.

---

# Relationship to Workflows

A Server Action completes once the synchronous business operation finishes.

Subsequent activities—including email delivery, analytics, audit logging, and dashboard updates—are delegated to the workflow engine.

This separation keeps request latency low while improving resilience.

---

# Looking Ahead

With application entry points established, the next appendix introduces the **Durable Workflow Engine**.

There, the focus shifts from handling individual requests to orchestrating long-running, fault-tolerant business processes using Inngest. Topics include retries, idempotency, compensation, fan-out, workflow versioning, and event-driven integration across the platform.
