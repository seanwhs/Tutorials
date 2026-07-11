# Production Patterns with Next.js 16

## Reference Architecture #1 — Part 4

# Building the Secure Check-In Experience

### Implementing the Application Layer with Server Components, Clerk, and Server Actions

> **The browser should express intent. The server should make decisions.**

---

# Executive Summary

By this point we've established:

* the architecture
* the project structure
* the domain model

Now we're finally building the application.

Notice that I didn't say we're building the attendance system.

We're building **the application layer**.

This distinction matters.

The application layer does **not** record attendance.

It authenticates users.

It validates requests.

It gathers context.

It publishes an event.

Everything after that belongs elsewhere.

Keeping these responsibilities separate dramatically improves reliability and maintainability.

---

# The Request Journey

When an attendee scans a QR code, this is what really happens.

```text
          Scan QR

             │

             ▼

 Next.js App Router

             │

             ▼

 Server Component

             │

             ▼

 Load Event

             │

             ▼

 Authenticate User

             │

             ▼

 Validate Request

             │

             ▼

 Render UI

             │

             ▼

 Click Check-In

             │

             ▼

 Server Action

             │

             ▼

 Publish Workflow Event
```

Notice what is missing.

There is **no database write.**

That is intentional.

---

# Why Server Components?

Server Components allow the application to make decisions before rendering the page.

That means we can safely perform:

* authentication
* event lookup
* permission checks
* feature flags
* maintenance windows
* check-in window validation

before sending HTML to the browser.

The browser never needs to know how these decisions were made.

It simply receives the appropriate interface.

---

# QR Codes Are Not Security

A common mistake is assuming the QR code itself provides security.

It does not.

The QR code is merely a transport mechanism.

A typical QR payload might simply be:

```text
/events/devfest-2026/checkin
```

Everything else happens on the server.

When the page loads we validate:

✓ Event exists

✓ Event published

✓ Check-in window open

✓ User authenticated

✓ User authorized

Only then do we display the Check In button.

---

# Route Design

Our routes remain intentionally simple.

```text
/events/[slug]/checkin
```

The slug is human-readable.

The database identifier never leaves the server.

URLs remain stable while internal implementation can evolve independently.

---

# Separating Presentation from Behaviour

The page itself should remain almost entirely declarative.

```tsx
export default async function Page() {

    const event = ...

    return (
        <EventDetails />

        <CheckInButton />
    )

}
```

The page should describe **what** is shown.

It should not contain business logic.

---

# Engineering Decision Record

## Why Thin Pages?

**Problem**

As applications grow, page components become difficult to maintain.

**Decision**

Move business logic into dedicated services.

**Benefits**

* reusable logic

* simpler testing

* clearer responsibilities

* easier maintenance

---

# Authentication

Identity comes entirely from Clerk.

The browser never sends:

```text
userId
```

Instead, identity is derived from the authenticated session.

This eliminates an entire class of security problems.

The application only needs to answer one question:

> Is this authenticated user allowed to check into this event?

---

# Authorization

Authentication answers:

> Who are you?

Authorization answers:

> Can you do this?

These are different concerns.

Every Server Action performs authorization even if the route is already protected.

Never trust the browser.

---

# Server Actions as Commands

Server Actions represent **commands** rather than CRUD operations.

Instead of thinking:

```
POST Attendance
```

think:

```
Request Attendance Check-In
```

That subtle difference completely changes the design.

Commands express intent.

The system decides what happens next.

---

# What Happens Inside the Server Action?

Only four things.

```
Authenticate

↓

Authorize

↓

Validate

↓

Publish Workflow
```

Nothing else.

No database.

No email.

No analytics.

No dashboards.

No side effects.

The Server Action finishes in milliseconds.

---

# Why Keep Server Actions Thin?

Imagine this implementation.

```
Authenticate

↓

Save Database

↓

Send Email

↓

Update Dashboard

↓

Slack

↓

Analytics

↓

Badge Printing

↓

Return Response
```

Now imagine email takes five seconds.

Should the attendee wait?

What if Slack is down?

Should attendance fail?

Of course not.

Long-running work belongs in the workflow engine.

---

# Optimistic User Experience

The user interface should reflect intent immediately.

Traditional UX:

```
Click

↓

Loading...

↓

Loading...

↓

Loading...

↓

Success
```

Production UX:

```
Click

↓

Processing...

↓

Attendance Submitted

↓

Workflow Continues
```

Notice the wording.

We don't say:

> Attendance Completed

We say:

> Attendance Submitted

That wording accurately reflects an asynchronous system.

---

# Validation Rules

Before publishing the workflow event we validate:

* authenticated user

* valid event

* published event

* check-in window

* event capacity (optional)

* duplicate submission

The workflow should never receive invalid requests.

---

# Engineering Decision Record

## Validate Early

**Problem**

Invalid requests consume workflow resources.

**Decision**

Reject them immediately.

**Benefits**

* fewer retries

* lower infrastructure cost

* cleaner workflow

* simpler monitoring

---

# Failure Scenarios

Even the application layer must assume failure.

| Scenario        | Result             |
| --------------- | ------------------ |
| Browser refresh | Safe               |
| Double click    | Safe               |
| Lost connection | Retry              |
| Expired session | Redirect to login  |
| Event closed    | Reject immediately |
| Invalid QR      | Reject immediately |

Every one of these outcomes is deterministic.

---

# Logging

Every request should generate structured logs.

Useful fields include:

* correlation ID

* user ID

* event ID

* route

* execution time

* validation result

* workflow ID

These logs become invaluable during live events.

---

# The Real Responsibility of the Application Layer

Notice what this article never discussed.

Database writes.

That's because recording attendance is **not** the responsibility of the application layer.

The application's only responsibility is to transform user intent into a trusted workflow request.

That request is then handed to the orchestration layer.

---

# Looking Ahead

Everything we've built so far leads to a single event:

```
attendance/checkin.requested
```

In the next article we'll follow that event through the system.

We'll build the durable orchestration pipeline using Inngest.

We'll learn how to:

* validate attendance

* implement retries

* enforce idempotency

* write to Sanity

* send confirmation emails

* update analytics

* power live dashboards

* recover automatically from failure

For the first time, we'll see why the architecture introduced in Part 1 was designed the way it was.

The application layer simply starts the journey.

The workflow engine ensures the journey reaches its destination.
