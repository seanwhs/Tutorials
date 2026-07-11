# Appendix D

# Domain Model and Business Architecture

> *"Software architecture should reflect the business it serves. Before writing a single line of code, we must first understand the language, rules, and relationships of the problem domain."*

---

# Purpose

The attendance platform is not a CRUD application.

It is an event-driven system responsible for coordinating people, events, workflows, and operational processes under real-world conditions.

This appendix defines the domain model that underpins the entire application.

Rather than focusing on implementation details, it identifies the business concepts, responsibilities, relationships, invariants, and lifecycle of each domain object.

Every repository, service, workflow, and user interface presented later in this book is built upon this model.

---

# Ubiquitous Language

One of the core principles of Domain-Driven Design (DDD) is the use of a **ubiquitous language**—a shared vocabulary understood by developers, product owners, event organizers, and operations teams.

The following terms are used consistently throughout the application.

| Term              | Definition                                                                    |
| ----------------- | ----------------------------------------------------------------------------- |
| Organization      | Entity responsible for hosting one or more events.                            |
| Venue             | Physical location where an event takes place.                                 |
| Event             | A scheduled gathering that attendees can register for and check into.         |
| Session           | A subdivision of an event, such as a workshop or keynote.                     |
| Attendee          | An authenticated user participating in an event.                              |
| Attendance Record | Immutable evidence that an attendee successfully checked in.                  |
| Check-In          | The business process that validates and records attendance.                   |
| QR Code           | Encoded identifier that directs an attendee to the event check-in experience. |
| Workflow          | A durable background process that performs asynchronous tasks.                |

Maintaining consistent terminology reduces ambiguity across both code and documentation.

---

# Domain Overview

The system revolves around a single business capability:

> **Safely and reliably recording attendance for an event while coordinating downstream business processes.**

The core domain is intentionally small.

```text
Organization
      │
      ▼
   Venue
      │
      ▼
    Event
      │
 ┌────┴────┐
 ▼         ▼
Session   Attendance Record
              │
              ▼
          User Profile
```

Each entity has a clearly defined responsibility and lifecycle.

---

# Bounded Contexts

Although implemented as a single application, the platform is organised into distinct bounded contexts.

```text
+-----------------------------------------------------------+
|                  Attendance Platform                      |
+-----------------------------------------------------------+

   Identity Context
        │
        ▼
Authentication
Authorization
Profiles

────────────────────────────────────────

   Event Context

Organizations
Venues
Events
Sessions

────────────────────────────────────────

Attendance Context

Check-In
Attendance Records
Capacity
Policies

────────────────────────────────────────

Workflow Context

Notifications
Analytics
Audit
Email
Realtime Updates
```

Separating business capabilities in this way reduces coupling and clarifies ownership.

---

# Aggregate Roots

Not every document should be modified directly.

Instead, aggregate roots control consistency boundaries.

The application defines the following aggregate roots.

## Organization

Owns:

* Venues
* Events

Responsible for:

* Governance
* Branding
* Multi-event management

---

## Event

Owns:

* Sessions
* Attendance Policies

Coordinates:

* Capacity
* Schedule
* Check-in Window
* Event Status

The Event aggregate is the centre of the application.

---

# Entities

Entities possess identity throughout their lifecycle.

## Venue

Represents a physical location.

Attributes include:

* Name
* Address
* Capacity
* Time Zone
* Geographic Coordinates

---

## Session

Represents a scheduled activity within an event.

Examples:

* Opening keynote
* Workshop
* Breakout session
* Closing remarks

Sessions inherit governance from the parent event while maintaining their own schedule.

---

## Attendance Record

The most important entity in the system.

Represents immutable proof that an attendee checked in.

Attributes include:

* Event
* User
* Timestamp
* Check-in Method
* Device Metadata
* Workflow Correlation ID
* Audit Information

Attendance records are append-only and are never updated to represent a second check-in.

---

## User Profile

Extends identity information provided by Clerk.

Stores application-specific metadata such as:

* Preferred display name
* Avatar
* Notification preferences
* Attendance history

Authentication remains delegated to Clerk.

---

# Value Objects

Some concepts are defined entirely by their values rather than identity.

Examples include:

## QR Code

Contains:

* Event Identifier
* Signed Payload
* Expiration Timestamp
* Version

QR codes are generated rather than persisted.

---

## Attendance Policy

Defines:

* Check-in window
* Capacity rules
* Duplicate behaviour
* Authentication requirements
* Geofencing requirements

Policies can evolve independently of attendance records.

---

## Coordinates

Represents:

* Latitude
* Longitude
* Accuracy

Used when optional geofencing is enabled.

---

# Business Invariants

The platform enforces several invariants.

## Attendance

An attendee may have at most one active attendance record for an event unless explicitly permitted by policy.

---

## Capacity

Attendance cannot exceed event capacity unless overbooking is enabled.

---

## Authentication

Anonymous users cannot create attendance records.

---

## Time Window

Check-ins are accepted only within the configured attendance window.

---

## Consistency

Attendance records are immutable once created.

Corrections require administrative workflows rather than direct modification.

---

# Domain Events

The application communicates internally through domain events.

Examples include:

```text
AttendanceRequested

AttendanceValidated

AttendanceRecorded

AttendanceRejected

EmailRequested

NotificationRequested

DashboardUpdated

AuditRecorded
```

These events become the triggers for Inngest workflows.

---

# Entity Lifecycle

The lifecycle of an attendance record illustrates how business processes unfold.

```text
QR Scan
    │
    ▼
Authenticate User
    │
    ▼
Validate Event
    │
    ▼
Validate Policy
    │
    ▼
Check Duplicate
    │
    ▼
Create Attendance Record
    │
    ▼
Publish Domain Event
    │
    ▼
Execute Background Workflows
```

Each transition represents a business decision rather than a technical operation.

---

# Responsibility Matrix

| Entity            | Creates       | Reads | Updates | Deletes |
| ----------------- | ------------- | ----- | ------- | ------- |
| Organization      | Administrator | Yes   | Yes     | Rare    |
| Venue             | Administrator | Yes   | Yes     | Rare    |
| Event             | Organizer     | Yes   | Yes     | Rare    |
| Session           | Organizer     | Yes   | Yes     | Rare    |
| Attendance Record | Workflow      | Yes   | No      | No      |
| User Profile      | User          | Yes   | Yes     | Rare    |

Immutable entities simplify auditing and reduce concurrency concerns.

---

# Domain Boundaries

Business rules belong in the domain layer.

Examples include:

* Is check-in currently open?
* Has the attendee already checked in?
* Is capacity exceeded?
* Does the attendee satisfy the attendance policy?

Infrastructure concerns such as email delivery, persistence, and analytics remain outside the domain model.

---

# Why This Matters

The remainder of the reference implementation follows this domain model closely.

Repositories persist entities.

Services implement business rules.

Server Actions initiate business processes.

Workflows react to domain events.

Because responsibilities are clearly defined here, later implementation chapters can focus on execution rather than continually redefining business concepts.

---

# Looking Ahead

The next appendix transitions from conceptual architecture to implementation.

Each domain entity introduced here will be implemented as a strongly typed Sanity schema, forming the foundation of the application's persistence model and enabling the repository layer, workflows, and user interface described throughout the rest of the book.
