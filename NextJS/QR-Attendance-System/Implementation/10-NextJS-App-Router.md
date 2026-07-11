# Next.js 16 App Router Implementation

> *"Next.js 16 is not just a frontend framework in this architecture. It becomes the edge orchestration layer that connects user interaction with backend workflows."*

---

## 8.1 Modern Architectural Shifts

* **Async Request APIs:** Following the move to Next.js 16, route parameters (like `params` and `searchParams`) are accessed as `Promise` objects. Your architecture now accounts for this natively.
* **Server-Side Security:** The UI is stripped of business logic. If a client-side check (`if(event.isClosed)`) is bypassed, the **Server Action** acts as the final arbiter, re-validating all domain policies before any state is mutated in Sanity.

---

## 8.2 The Server Action Lifecycle

Server Actions replace traditional API routes (`/api/checkin`). This simplifies your stack by removing the need for manual JSON serialization and manual endpoint management.

* **Flow:** `Client Component` → `Server Action` → `Application Service`.
* **Security:** Because the `attendanceService.checkIn()` call happens inside the Server Action, it is implicitly guarded by your `clerkMiddleware`. You cannot trigger a check-in without an authenticated session.

---

## 8.3 Optimistic UX vs. Durable Backend

* **Client Side (`components/checkin-utton.tsx`):** Provides an immediate "Processing..." state. This hides the latency of the round-trip to Sanity and Inngest.
* **Backend Side:** Once the Server Action finishes, the system handles the heavy lifting (database writes, Inngest event publication) without the user needing to wait for downstream effects like email delivery or analytics tallying.

---

## 8.4 Infrastructure Orchestration

The system utilizes a clean boundary for external services:

| Component | Role | Next.js Integration |
| --- | --- | --- |
| **Clerk** | Identity | `middleware.ts` protects the event routes. |
| **Inngest** | Orchestration | `app/api/inngest/route.ts` serves as the event consumer. |
| **Sanity** | Persistence | Accessed via repositories; never via UI components. |

---

## 8.5 Production Hardening

To maintain a professional-grade system, follow these three rules implemented in the App Router:

1. **Do Not Trust the Client:** Even if you hide a "Check In" button in React, the browser remains insecure. Always perform validation inside the `Application Service` logic.
2. **Thin Components:** Your `page.tsx` files should only be responsible for fetching data from an `EventService` and rendering props. They contain zero logic regarding "if" a user can check in.
3. **Graceful Loading:** Using `loading.tsx` and React Suspense ensures that the UI remains interactive while the backend fetches event data, maintaining a high-quality user experience.

---

## Summary

The system is now a complete, event-driven, production-ready machine:

* ✅ **Edge Orchestrated:** User intent is captured at the edge via Next.js.
* ✅ **Domain Protected:** All business rules are enforced server-side.
* ✅ **Resilient:** Background workflows (Inngest) handle the heavy lifting asynchronously.
* ✅ **Extensible:** Adding a new event type or a new integration simply requires adding a new Domain Entity or an Inngest Step.

---

## Next: Inngest Durable Workflow Implementation

With the architecture now fully connected, the final piece is the **Durable Workflow Layer**. We will move beyond simple API requests and implement:

* **Reliability:** Automatic retries for failed emails or analytics calls.
* **Visibility:** Using the Inngest dashboard to trace check-in failures.
* **Durability:** Ensuring that if a third-party service is down, your attendance system records the event and processes the side-effect whenever the service recovers.

This is where your system transitions from "working" to "bulletproof."
