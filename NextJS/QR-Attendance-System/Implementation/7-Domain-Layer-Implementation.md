# Domain Layer Implementation

> *"The domain layer is where the system's knowledge lives. Frameworks change. Business rules survive."*

---

## 5.1 Domain Structure

The domain layer contains the core logic. It has zero dependencies on Next.js, Sanity, or any other external library.

```text
domain/
├── attendance/     # Attendance entity, status, and factory
├── event/          # Event entity and check-in policy
├── organization/   # Organization domain model
└── shared/         # Base Entity, ValueObject, and DomainEvent primitives

```

---

## 5.2 Core Primitives

### Entities vs. Value Objects

* **Entities (`Entity<T>`):** Business objects that possess a unique identity (e.g., an `AttendanceRecord` is unique by ID, regardless of its status changes).
* **Value Objects (`ValueObject<T>`):** Business concepts that are defined by their attributes rather than identity (e.g., an Email Address or a Geo-coordinate). They are immutable.

---

## 5.3 Business Logic (The Domain Entity)

Instead of storing data as plain JSON, we encapsulate state and behavior within classes.

* **Behavioral Integrity:** We avoid `attendance.status = 'revoked'`. Instead, we use `attendance.revoke()`. This ensures that the domain layer controls its own state transitions and invariants.

```typescript
// domain/attendance/attendance.entity.ts
export class Attendance extends Entity<AttendanceProps> {
  // ...
  revoke() {
    this.props.status = AttendanceStatus.REVOKED;
  }
  
  isActive() {
    return this.props.status === AttendanceStatus.PRESENT;
  }
}

```

---

## 5.4 Policy Orchestration

Policies encapsulate rules that don't belong to a single entity. They act as "Guardians" for business operations.

* **Example (`EventPolicy`):** The UI should never decide if an event is open for check-in based on raw timestamps. Instead, it asks the domain policy:
* `EventPolicy.canCheckIn(event, now)`


* **Benefit:** If the "check-in window" rule changes (e.g., allowing check-ins 60 minutes prior instead of 30), you change the code in exactly **one place**—the domain—and it updates globally across the app, API, and background workers.

---

## 5.5 Domain Events

Business operations often trigger side effects (emails, dashboard updates). We define these as `DomainEvent` objects.

* **Decoupling:** When a user checks in, the `Attendance` entity emits an `attendance.checked_in` event.
* **Orchestration:** The infrastructure layer listens for this event and triggers the Inngest workflows. The Domain Layer remains completely unaware that an email system exists; it only knows that an "Attendance Occurred."

---

## 5.6 Factories

We use Factories (`AttendanceFactory`) to protect object creation.

* **Safety:** The constructor is private; entities can only be instantiated through the factory. This prevents the creation of "invalid" entities (e.g., an attendance record without a status) and ensures that all mandatory business invariants are met upon initialization.

---

## Summary

The domain layer now acts as the system's "Source of Truth":

* ✅ **Framework-Agnostic:** Business rules can be tested in isolation (unit tests) without starting a browser or connecting to a database.
* ✅ **Behavior-Driven:** State changes are explicit and controlled.
* ✅ **Self-Documenting:** Concepts like `EventNotActiveError` make the system's requirements readable even to non-technical stakeholders.

---

## Next: Repository Layer Implementation

We now connect the Domain Layer to the Infrastructure Layer. The Repository layer will implement the **Dependency Inversion Principle**:

* The Application Layer will depend on an `AttendanceRepository` interface.
* The Infrastructure Layer will provide the `SanityAttendanceRepository` implementation.

This ensures that the business logic (Domain) remains pure, even when interacting with the persistent storage (Sanity).
