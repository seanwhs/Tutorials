# Repository Layer Implementation

> *"Repositories protect business logic from persistence technology. They answer the question: 'How do we get the data?' without changing the question: 'What does the data mean?'"*

---

## 6.1 Repository Structure

The layer is split into **Contracts** (Interfaces) and **Implementations** (Concrete logic). The application interacts strictly with the interfaces.

```text
repositories/
├── contracts/        # Abstract interfaces (The "What")
├── implementations/  # Sanity-specific logic (The "How")
└── index.ts          # Composition layer

```

---

## 6.2 The Repository Pattern

The application uses Dependency Inversion. When a service needs to save an `Attendance` entity, it calls a method on an interface. It remains completely unaware that the data is being stored in Sanity.

* **Benefit:** Testing becomes significantly easier. You can inject a `MockAttendanceRepository` during unit testing without requiring a database connection.

---

## 6.3 Defining Contracts

Contracts define the capabilities available to the application. They rely solely on domain entities and basic types.

```typescript
// repositories/contracts/attendance.repository.ts
export interface AttendanceRepository {
  findByUserAndEvent(eventId: string, userId: string): Promise<Attendance | null>;
  create(attendance: Attendance): Promise<Attendance>;
  exists(eventId: string, userId: string): Promise<boolean>;
}

```

---

## 6.4 Implementing Sanity Repositories

The implementation handles the translation between technical database records and domain entities.

* **Data Conversion:** The repository maps raw Sanity document properties to Domain Entity parameters.
* **Leakage Prevention:** It is critical that domain entities never interact with Sanity metadata (like `_rev`, `_type`, or `_createdAt`). The implementation strips these values during the mapping process.

```typescript
// Example: Sanity to Domain Mapping
return Attendance.create(
  result._id,
  {
    eventId: result.eventId,
    userId: result.userId,
    checkedInAt: new Date(result.checkedInAt),
    // ...
  }
);

```

---

## 6.5 Repository Factory (`repositories/index.ts`)

The `repositories` export acts as a central composition point. By instantiating repositories here, we avoid "newing up" dependencies inside business services, keeping the code clean and promoting singleton-like usage.

---

## 6.6 Error Handling & Fault Tolerance

Repositories serve as the "Translator" for technical failures:

1. **Sanity Timeout/Network Error:** Caught by the repository.
2. **Domain Translation:** The exception is re-thrown as an `InfrastructureError`.
3. **Workflow Resilience:** Because the application only understands `InfrastructureError`, the background workflow can catch this specific type and initiate an automated retry, while ignoring logical errors like `ValidationError`.

---

## Summary

The persistence boundary is now fully established:

* ✅ **Clean Separation:** Business logic (Domain) is strictly isolated from data access (Sanity).
* ✅ **Testability:** Interfaces allow for easy mocking of persistence layers.
* ✅ **Maintenance:** If you switch databases (e.g., from Sanity to PostgreSQL), you only need to create a `PostgresAttendanceRepository` that adheres to the existing contract. Your Application and Domain layers will require zero changes.
* ✅ **Resilience:** Errors are normalized before reaching the service layer, preventing technical debt from bleeding into the business logic.

---

## Next: Application Services Layer

The architecture is now ready to orchestrate business flows. We will implement:

* `application/services/`: Managing high-level orchestration.
* `application/commands/`: Executing user-initiated actions.
* `application/policies/`: Enforcing cross-cutting business rules.

This layer will tie everything together, bridging the gap between your Domain/Repository infrastructure and the user-facing Server Actions.
