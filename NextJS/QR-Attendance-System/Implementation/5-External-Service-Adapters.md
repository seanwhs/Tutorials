# External Service Adapters

> *"A resilient architecture protects its core business logic from external dependency changes."*

---

## 3.1 Infrastructure Structure

The infrastructure layer provides clean interfaces (adapters) to external systems. Application services interact only with these interfaces, never with raw SDKs.

```text
infrastructure/
├── clerk/          # Auth & identity management
├── sanity/         # Database and document storage
├── inngest/        # Durable workflow execution
├── redis/          # Caching and rate limiting
├── email/          # Email communication (Resend)
└── index.ts        # Unified API surface

```

---

## 3.2 Clerk Authentication Adapter

By wrapping Clerk's SDK in `infrastructure/clerk/auth.ts`, we create a single point of entry for identity verification.

* **Benefit:** The application logic doesn't import Clerk directly. If you migrate to a different authentication provider, you only update this adapter.

```typescript
// infrastructure/clerk/auth.ts
export async function requireUser() {
  const { userId } = await auth();
  if (!userId) {
    throw new ApplicationError(ErrorCode.UNAUTHORIZED, "Authentication required");
  }
  return userId;
}

```

---

## 3.3 Sanity Client & Query Management

Sanity is our primary data store. We strictly separate data retrieval (queries) from persistence (mutations).

* **Consistency Rule:** `useCdn` is set to `false` for attendance operations. In a high-concurrency check-in system, we require real-time data consistency, which cached CDN responses cannot guarantee.
* **Query Centralization:** GROQ queries are stored as constants in `queries.ts`. This prevents the "scattered string" anti-pattern where query logic is hidden within UI components.

```typescript
// infrastructure/sanity/queries.ts
export const EVENT_BY_SLUG = `*[ _type == "event" && slug.current == $slug ][0]`;

```

---

## 3.4 Inngest (Workflow Engine)

Inngest provides durability for side effects. Instead of chaining operations directly (e.g., `SaveDB -> SendEmail -> UpdateDashboard`), which risks partial failures, we trigger an Inngest event.

* **Durability:** If the email provider (Resend) is down, the Inngest workflow will automatically retry the notification step without failing the entire attendance record process.

---

## 3.5 Redis & Email Adapters

* **Redis (`infrastructure/redis/client.ts`):** Centralizes caching and rate limiting. This will be used in middleware to enforce check-in frequency (e.g., 5 requests/minute).
* **Email (`infrastructure/email/resend.ts`):** Exposes a simple `sendEmail` interface. The business layer treats email as a "fire-and-forget" side effect, completely unaware of the underlying Resend API.

---

## 3.6 Infrastructure Export

`infrastructure/index.ts` acts as the platform's API surface, hiding the implementation details:

```typescript
export * from "./clerk/auth";
export * from "./sanity/client";
export * from "./inngest/client";
export * from "./redis/client";
export * from "./email/resend";

```

---

## Summary

The system now successfully isolates third-party dependencies:

* ✅ **Decoupling:** Business logic remains agnostic of provider-specific SDKs.
* ✅ **Testability:** Adapters can be mocked easily during testing.
* ✅ **Resilience:** Durable workflows (Inngest) and retry logic ensure data integrity despite external service instability.
* ✅ **Security:** Uniform error handling ensures authentication failures are caught consistently.

---

## Next: Data Modeling & Domain Schemas

The next phase shifts focus to the "Business Language" of the application:

* `schemas/event.ts`
* `schemas/attendance.ts`
* `schemas/session.ts`
* `schemas/organization.ts`

This is where the platform's core business requirements are translated into strictly typed code.
