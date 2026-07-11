# Application Services Layer

> *"Application services are the conductors of the system. They do not own business rules; they coordinate business capabilities into executable workflows."*

---

## 7.1 Responsibilities

The Application Layer is the entry point for system actions. Its core responsibilities are:

* **Orchestration:** Sequencing calls to the Domain Layer and Repositories.
* **Command Handling:** Interpreting user intent via DTOs and Commands.
* **Policy Enforcement:** Ensuring security and business rules are verified server-side.
* **Event Publication:** Triggering side effects (Inngest) once a business state transition is successful.

---

## 7.2 The Check-In Workflow

The service layer ensures that even if a user interacts with the UI, the business logic remains protected:

1. **Authentication Context:** Verify the user identity (from the Server Action/Request).
2. **Load Entity:** Fetch the Aggregate Root (e.g., `Event`) via a Repository.
3. **Validate Policy:** Ask `AttendancePolicy` if the action is allowed *right now*.
4. **Enforce Idempotency:** Check if a record already exists for this `userId` + `eventId`.
5. **Perform Transition:** Create the `Attendance` entity via a Factory.
6. **Persist:** Save to the database via a Repository.
7. **Publish:** Emit an `attendance.checked_in` event for background workflows.

---

## 7.3 Key Components

### Commands (`CheckInCommand`)

Instead of passing raw, loosely typed objects into functions, we use **Commands**. This makes your business API explicit and self-documenting.

### Application Services

These services (e.g., `AttendanceService`) are the only place where the different parts of the system "meet."

* **Crucially:** They do not know about Sanity queries, React components, or HTTP status codes. They know about `Domain Entities`, `Repositories`, and `ApplicationErrors`.

### DTOs (Data Transfer Objects)

The system uses DTOs to ensure that sensitive domain state (like internal IDs or raw property objects) is never leaked directly to the client. We transform the rich domain object into a clean, read-only JSON shape.

---

## 7.4 Security via Server-Side Policies

By placing logic like `AttendancePolicy.canCheckIn()` in the application layer, you guarantee security. If a user tries to spoof a "check-in" request *before* the event starts (by manipulating the browser), the server will reject it, as the domain policy acts as a gatekeeper that the client cannot bypass.

---

## 7.5 Orchestrating Side Effects

Once an attendance record is successfully saved, the service publishes a domain event.

```typescript
await inngest.send({
  name: "attendance.checked_in",
  data: { eventId: command.eventId, userId: command.userId }
});

```

This is the "Secret Sauce" for scalability. The `AttendanceService` doesn't need to know how to send an email or update analytics; it just reports that the check-in occurred. This keeps the service fast and robust.

---

## Summary of the Architecture

The flow is now fully hardened and decoupled:

| Layer | Responsibility |
| --- | --- |
| **Next.js UI** | Presentation and user input. |
| **Server Actions** | Extracting user intent from the HTTP request. |
| **Application Service** | **Orchestrating the business workflow.** |
| **Domain Layer** | Enforcing business rules and invariants. |
| **Repositories** | Translating business entities to storage. |
| **Infrastructure** | Concrete implementations (Sanity, Inngest). |

---

## Next: Next.js 16 App Router Implementation

The architecture is complete. We now connect this logic to the **App Router**. We will implement:

* **Server Actions:** The gateway from the UI to the Application Service.
* **Inngest Route:** The API endpoint that listens for Domain Events.
* **Middleware:** Protecting routes based on the domain's state.

This will bring the "Business Rules" to life in a functional, production-ready web application.
