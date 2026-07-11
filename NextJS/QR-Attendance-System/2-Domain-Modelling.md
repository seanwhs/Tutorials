# Production Patterns with Next.js

## Reference Architecture #1 — Part 2

# Designing the Data Model for a Production-Ready QR Attendance System

### Modeling Events, Attendees, and Attendance Records with Sanity

---

## Executive Summary

In Part 1, we established that attendance is not a CRUD operation—it is a durable workflow.

Before implementing that workflow, we need a data model capable of supporting:

* high-concurrency check-ins
* auditability
* idempotency
* analytics
* real-time dashboards
* future product evolution

A common mistake is treating attendance as a simple join table between users and events.

That works initially, but quickly becomes limiting.

Questions like these become difficult to answer:

* Who checked in manually?
* Who checked in offline?
* Which device was used?
* How many retry attempts occurred?
* Which attendees arrived after the keynote?
* Which entrances experienced the most traffic?
* Which check-ins were completed automatically after reconnecting?

A richer document model enables these insights without major schema redesigns later.

This article explores how to model the domain using Sanity, balancing flexibility with operational efficiency.

---

## Domain Model Overview

Rather than starting with schemas, begin with the core domain concepts.

```text
                Event
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
 Check-In Window        QR Configuration
      │
      ▼
Attendance Record
      │
      ▼
 Attendee (Clerk User)
      │
      ▼
 Device / Metadata
```

Each entity represents a business concept rather than a database optimization.

---

## Core Design Principles

Our data model is guided by five principles:

1. **Events are immutable once published.**
2. **Attendance is append-only.**
3. **Identity comes from Clerk, not the client.**
4. **Every attendance record is independently auditable.**
5. **Documents should evolve without schema rewrites.**

These principles influence every schema we create.

---

## Event Schema

The `event` document defines everything required for check-in.

Typical fields include:

* Title
* Slug
* Description
* Venue
* Start time
* End time
* Check-in opens
* Check-in closes
* Capacity
* Status (Draft, Published, Closed)
* QR configuration
* Organizer

By separating the check-in window from the event schedule, organizers gain flexibility. For example, check-in might open 30 minutes before the keynote begins.

### Design Decision

**Problem:** How do we prevent early or late check-ins?

**Decision:** Store explicit `checkInOpensAt` and `checkInClosesAt` fields.

**Trade-off:** Slightly more configuration, but significantly more control over event operations.

---

## Attendance Record Schema

This document is the heart of the system.

Unlike a simple join table, it captures the context of every check-in.

Suggested fields:

* Event reference
* Clerk user ID
* Check-in timestamp
* Attendance status
* Check-in method (QR, Manual, Offline Sync)
* Device information
* Browser
* Operating system
* IP address (if required)
* Geolocation (optional)
* Retry count
* Workflow execution ID
* Notes

This richer model enables auditing, troubleshooting, and analytics without introducing additional tables later.

### Engineering Insight

Treat attendance as an event log rather than a boolean flag.

Instead of asking, "Is this user checked in?"

Ask, "What happened during this attendee's journey?"

That mindset enables better reporting and operational visibility.

---

## QR Configuration

Rather than hardcoding QR behavior, encapsulate it in the event configuration.

Possible settings include:

* QR expiration
* Signed token
* Geofencing enabled
* Allowed radius
* One-time use
* Manual override allowed

This approach allows different events to enforce different security policies without changing application code.

---

## Attendance States

Avoid reducing attendance to a single boolean.

Instead, model it as a lifecycle.

```text
Pending
   │
   ▼
Validated
   │
   ▼
Checked In
   │
   ├──────────────►Confirmed
   │
   └──────────────►Cancelled
```

Representing attendance as a state machine makes future enhancements—such as approvals, cancellations, or badge printing—far easier to implement.

---

## Idempotency Strategy

One of the most important design decisions is ensuring duplicate requests do not create duplicate records.

Instead of relying solely on database constraints, derive a deterministic idempotency key:

```
SHA256(eventId + ":" + userId)
```

Every workflow execution checks for an existing attendance record using this key before creating a new document.

This guarantees that repeated scans converge to a single attendance record.

### Design Decision

**Problem:** QR scans are frequently retried.

**Decision:** Use deterministic idempotency keys.

**Trade-off:** Additional lookup before writes, but eliminates duplicate attendance records.

---

## Metadata for Observability

Operational metadata is often overlooked but invaluable.

Consider storing:

* Workflow execution ID
* Retry attempts
* Processing duration
* Origin (Web, Mobile, Offline Sync)
* User agent
* Request correlation ID

These fields dramatically improve troubleshooting during large events.

---

## Query Patterns

Before finalizing the schema, think about the queries you'll need.

Examples include:

* List all attendees for an event.
* Check whether a user has already checked in.
* Count attendees in real time.
* Show arrivals over time.
* Identify offline synchronizations.
* Display manual overrides.
* Audit failed check-in attempts.

Designing for these queries upfront prevents costly schema changes later.

---

## Engineering Decision Record — Attendance as a Document

**Problem:** Should attendance be embedded within the event document?

**Decision:** Store attendance as independent documents.

**Why:** Attendance grows independently of event metadata and benefits from isolated indexing, querying, and lifecycle management.

**Trade-off:** Requires references between documents but scales significantly better.

---

## Common Modeling Mistakes

Avoid these pitfalls:

* Using a boolean `checkedIn` field on the user.
* Storing attendance inside the event document.
* Trusting client-generated timestamps.
* Omitting audit metadata.
* Ignoring idempotency.
* Coupling business logic to the schema.

These shortcuts often lead to painful migrations as the system grows.

---

## Looking Ahead

With the domain model defined, the next step is to build the user-facing experience.

In **Part 3**, we'll implement:

* Clerk authentication
* QR entry flow
* Next.js Server Components
* Secure Server Actions
* Optimistic UI
* Publishing attendance events to Inngest

By the end of Part 3, users will be able to scan a QR code and initiate a secure, authenticated attendance workflow—laying the groundwork for the durable orchestration pipeline introduced in Part 1.

---

This progression keeps the series cohesive:

1. **Part 1 — Reference Architecture:** The "why" behind the system.
2. **Part 2 — Domain Modeling:** Designing the data structures and lifecycle.
3. **Part 3 — Application Layer:** Implementing the user experience and secure entry flow.
4. **Part 4 — Workflow Layer:** Building durable orchestration with Inngest.
5. **Part 5 — Operations:** Notifications, dashboards, analytics, and offline support.
6. **Part 6 — Production Hardening:** Observability, resilience testing, deployment, and scaling.
