# Inngest Durable Workflow Implementation

> *"In production systems, success is not defined by what happens when everything works. Success is defined by how the system behaves when everything fails."*

---

## 9.1 The Durable Execution Model

By using Inngest, your system gains **durability**. A workflow is no longer a single execution block; it is a series of checkpoints. If a step fails, the workflow does not restart from the beginning—it pauses, waits, and resumes exactly where it left off, automatically handling retries and state recovery.

## 9.2 Event-Driven Architecture

We enforce a strict **Event Contract** (`AttendanceCheckInEvent`). This decoupling is crucial: the `AttendanceService` only knows that it needs to *emit an event*; it is entirely ignorant of *who* consumes that event or *what* they do with it.

* **Benefit:** You can add a new feature (e.g., sending an SMS or posting to Slack) by adding a new workflow function without ever touching the core `AttendanceService` code.

---

## 9.3 Workflow Structure

The `workflows/` directory encapsulates the logic of "what happens next."

```text
workflows/
├── attendance/          # Business workflows
├── events/              # Event definitions (contracts)
└── index.ts             # Registry

```

---

## 9.4 Robustness Strategy

### 1. Failure Isolation

If the email provider goes down, the attendance record remains safe in the database. Because the Email Step is a distinct, durable step, Inngest will automatically retry the email delivery based on your defined backoff strategy, while the user’s check-in status remains marked as `PRESENT`.

### 2. Distributed Validation

Even though the `Server Action` validated the request, we re-validate in the `validation.step.ts`. In distributed systems, this is a best practice: **never assume the state hasn't changed between the initial request and the worker execution.**

### 3. Idempotent Processing

To prevent double-processing in the event of network retries, the system relies on the uniqueness of the `eventId` + `userId` combination enforced at the repository level. This prevents duplicate side effects (like sending two confirmation emails) even if the workflow is accidentally triggered twice.

---

## 9.5 Complete Lifecycle Summary

1. **Request:** User performs a check-in action.
2. **Transaction:** `AttendanceService` validates business logic and persists the record to Sanity.
3. **Publication:** The service publishes an `attendance.checked_in` event.
4. **Orchestration:** Inngest picks up the event and triggers the `attendanceWorkflow`.
5. **Durability:** Steps (Email, Analytics) execute sequentially. Each step is automatically checkpointed.
6. **Self-Healing:** If any step fails due to external provider outages, the workflow retries automatically, preserving the system's overall consistency.

---

## Summary of Architectural Evolution

| Feature | Traditional Approach | Durable Approach |
| --- | --- | --- |
| **Failures** | Request fails, transaction rolls back. | Workflow pauses, retries until successful. |
| **Coupling** | Service calls Email API directly. | Service emits event; Workflow consumes event. |
| **Performance** | User waits for all side effects to finish. | User receives immediate feedback; side effects run in background. |
| **Observability** | Logs are scattered. | Inngest dashboard provides full trace history. |

---

## Next: Security Hardening Layer

The final architecture phase is **Security Hardening**. We will implement the production threat model controls:

* **QR Tampering Prevention:** Verifying payload integrity.
* **Replay Attack Protection:** Implementing one-time-use tokens.
* **Rate Limiting:** Preventing brute-force check-ins.
* **Geofencing:** Validating that the check-in request originated from the physical event location.

This layer ensures that your platform is not just functional, but **enterprise-secure.**
