# Appendix E

# Domain Implementation Reference

> *"The domain model describes the business. The implementation gives that model executable form."*

---

# Purpose

Appendix D introduced the conceptual model of the attendance platform.

This appendix bridges the gap between architecture and implementation by defining how each domain concept is represented within the application.

Rather than presenting isolated source files, this appendix serves as the **Domain Reference Manual** for the entire codebase.

Every repository, service, workflow, and user interface presented later in the book depends upon the structures defined here.

---

# Why Start Here?

A common mistake in software tutorials is to begin with frameworks or databases.

This reference implementation begins with the domain.

The technology stack may evolve over time—from Next.js to another framework, or from Sanity to another persistence solution—but the business concepts remain stable.

The implementation therefore starts with the domain model rather than the infrastructure.

---

# Domain Package Structure

The application groups domain objects according to business capability.

```text
src/
│
├── domain/
│
│   ├── organization/
│   ├── venue/
│   ├── event/
│   ├── attendance/
│   ├── session/
│   ├── user/
│   ├── policies/
│   ├── value-objects/
│   └── shared/
```

This organization intentionally separates business concepts from infrastructure concerns.

Infrastructure-specific files such as Sanity schemas, repositories, or API clients reference these domain definitions rather than embedding business logic directly.

---

# Domain Objects

The platform is composed of six primary entities.

```text
Organization
      │
      ▼
Venue
      │
      ▼
Event
 ┌────┴────┐
 ▼         ▼
Session  AttendanceRecord
              │
              ▼
          UserProfile
```

Supporting these entities are several value objects and policies.

---

# Aggregate Roots

The following objects define aggregate boundaries.

| Aggregate         | Responsibility                      |
| ----------------- | ----------------------------------- |
| Organization      | Owns venues and events              |
| Event             | Coordinates sessions and attendance |
| Attendance Record | Immutable record of participation   |

Aggregate roots enforce consistency and prevent invalid modifications from bypassing business rules.

---

# Entity Reference

## Organization

Represents the owner of one or more events.

Typical responsibilities include:

* Branding
* Administrative ownership
* Event governance
* Configuration defaults

---

## Venue

Represents a physical or virtual location.

Stores information including:

* Name
* Address
* Capacity
* Time zone
* Geographic coordinates

A venue may host multiple events.

---

## Event

Represents a scheduled occurrence.

Contains:

* Metadata
* Schedule
* Capacity
* Attendance policy
* Session references

The Event aggregate coordinates all attendance activity.

---

## Session

Represents a scheduled activity within an event.

Examples include:

* Workshops
* Keynotes
* Panels
* Breakout sessions

Sessions inherit governance from their parent event while maintaining independent scheduling.

---

## Attendance Record

Represents immutable evidence that an attendee successfully checked in.

Stores:

* User reference
* Event reference
* Session reference (optional)
* Timestamp
* Check-in method
* Device metadata
* Correlation identifiers

Attendance records are append-only.

---

## User Profile

Represents application-specific information associated with a Clerk identity.

Stores:

* Display name
* Avatar
* Notification preferences
* Attendance history

Authentication credentials remain outside the domain.

---

# Value Objects

Several concepts are represented as immutable value objects.

Examples include:

* QRCode
* AttendancePolicy
* GeoLocation
* DateRange
* EventCapacity
* DeviceInformation

These objects have no identity and exist solely through their values.

---

# Enumerations

The application defines several common enumerations.

Examples include:

* EventStatus
* AttendanceStatus
* SessionType
* CheckInMethod
* NotificationChannel

Using shared enumerations improves consistency across the application.

---

# Shared Interfaces

Common interfaces reduce duplication.

Examples include:

* BaseEntity
* AuditableEntity
* TimestampedEntity
* SoftDeletableEntity

These interfaces establish consistent behaviour across entities.

---

# Validation Strategy

Validation occurs at multiple layers.

```text
User Input
      │
      ▼
Zod Validation
      │
      ▼
Domain Validation
      │
      ▼
Repository Validation
      │
      ▼
Persistence
```

Each layer validates only the concerns it owns.

---

# Domain Events

Business events emitted by the domain include:

* AttendanceRequested
* AttendanceValidated
* AttendanceRecorded
* AttendanceRejected
* SessionStarted
* SessionCompleted
* NotificationRequested

These events become triggers for durable workflows.

---

# Directory Layout

The domain package is organised as follows.

```text
src/domain/

organization/
    Organization.ts
    OrganizationPolicy.ts
    OrganizationTypes.ts

venue/
    Venue.ts
    VenuePolicy.ts

event/
    Event.ts
    EventPolicy.ts
    EventStatus.ts

attendance/
    AttendanceRecord.ts
    AttendancePolicy.ts
    AttendanceStatus.ts

session/
    Session.ts
    SessionType.ts

user/
    UserProfile.ts

shared/
    BaseEntity.ts
    AuditableEntity.ts
    DateRange.ts
    Coordinates.ts
```

This layout intentionally mirrors the conceptual model introduced in Appendix D.

---

# Relationship to Sanity

Although Sanity provides document persistence, the domain model remains independent of any particular storage technology.

The mapping between domain objects and Sanity documents is handled within the repository layer.

This separation enables future migration to another persistence mechanism without rewriting business rules.

---

# Reference Implementation Sequence

The remainder of the implementation appendices build upon these definitions.

```text
Domain
      │
      ▼
Infrastructure
      │
      ▼
Repositories
      │
      ▼
Services
      │
      ▼
Server Actions
      │
      ▼
Workflows
      │
      ▼
User Interface
```

Each layer adds behaviour while preserving the integrity of the domain.

---

# Looking Ahead

The next appendix introduces the infrastructure that supports the domain implementation.

Rather than immediately connecting to external services, it establishes the application's foundational capabilities, including configuration, logging, identifiers, caching, and other cross-cutting concerns that every subsequent layer depends upon.
