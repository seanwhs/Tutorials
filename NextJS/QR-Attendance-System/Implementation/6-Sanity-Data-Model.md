# Sanity Data Model & Domain Schemas

> *"Good systems begin with good models. The database should represent business concepts, not merely store application data."*

---

## 4.1 Schema Structure

The model is designed to support scalable relationships between entities, separating identity management (Clerk) from business content (Sanity).

```text
schemas/
├── organization.ts  # Event owners
├── event.ts         # Central aggregate
├── session.ts       # Track-specific segments
├── attendance.ts    # Business transactions
├── venue.ts         # Location-based data
└── index.ts         # Schema registration

```

---

## 4.2 Core Entities

### Organization & Venue

* **Organization:** Links to `clerkOrganizationId` to create a bridge between the identity layer and the business data layer.
* **Venue:** Stores latitude and longitude coordinates. This is a deliberate architectural choice to enable future **geofencing** features, allowing the system to validate check-ins based on physical proximity.

### Event & Session

* **Event:** The primary aggregate. It tracks temporal boundaries (`startTime`/`endTime`) and configuration for the check-in window.
* **Session:** Allows the system to support complex conference structures (e.g., Opening Keynote vs. Security Track).

---

## 4.3 Attendance Record (The Business Transaction)

The attendance document captures the outcome of a business event: *"User X attended Event Y at time Z."*

* **Idempotency Constraint:** The most critical business rule is enforced: **One User + One Event = One Attendance Record.**
* **Implementation Strategy:** Even though the database stores the records, the **Application Layer** must treat the unique combination of `eventId` and `userId` as a strictly enforced constraint to handle network-level retries and accidental double-submissions.

---

## 4.4 Schema Design Principles

### Separating Identity from Business Data

By storing the `clerkOrganizationId` or `userId` as strings rather than embedding them, we keep the two systems decoupled. Clerk remains the "Source of Truth" for identities, while Sanity acts as the "Source of Truth" for business state.

### State Lifecycle

The schemas support a transition-based lifecycle for events:
`Draft → Published → Open → Running → Completed → Archived`

This ensures that UI logic (e.g., hiding the check-in button) can be derived directly from the event’s state.

---

## 4.5 Performance Strategy

Efficient querying is built into the model through indexing:

* **Query Pattern:** The application frequently performs lookups on `WHERE eventId == X AND userId == Y`.
* **Implementation:** All schemas define fields that facilitate these lookups, ensuring that as the `attendance` collection grows, query performance remains stable.

---

## 4.6 Schema Registration (`schemas/index.ts`)

Registration is centralized, providing a clean array of types that Next.js and the Sanity client can ingest to generate the CMS configuration.

```typescript
export const schemaTypes = [
  event, 
  attendance, 
  session, 
  organization, 
  venue
];

```

---

## Summary

The system’s data foundation is now complete:

* ✅ **Domain-Driven:** The database model now mirrors actual business processes.
* ✅ **Extensible:** Architecture supports multi-tenant organizations and complex multi-session events.
* ✅ **Validation-Ready:** Latitude/Longitude fields and unique constraint strategies prepare the system for geofencing and duplicate prevention.
* ✅ **Decoupled:** Identity and Business Logic remain cleanly separated.

---

## Next: Domain Layer Implementation

We transition from **data storage** to **business objects**. The next phase defines the `domain/` folder, where business rules move out of the database/infrastructure and into pure, framework-agnostic TypeScript entities.

This is where your business language truly becomes code.
