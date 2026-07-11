# Infrastructure Core

> *"Infrastructure code is where the application meets the outside world. Its job is to make external dependencies predictable, observable, and safe."*

---

## 2.1 Infrastructure Structure

The infrastructure layer acts as a buffer between the core business logic and external services, ensuring consistency across logging, error handling, and utility functions.

```text
infrastructure/
├── config/             # Environment validation and constants
├── errors/             # Standardized application error model
├── logging/            # Structured, machine-readable logging
├── utilities/          # Shared date, ID, and retry primitives
└── index.ts            # Public API surface

```

---

## 2.2 Environment Validation

We enforce configuration strictness using Zod. By validating the environment during startup, we ensure that missing secrets trigger an immediate, clear failure rather than silent runtime errors.

```typescript
// infrastructure/config/env.ts
import { z } from "zod";

const envSchema = z.object({
  NEXT_PUBLIC_APP_URL: z.string().url(),
  CLERK_SECRET_KEY: z.string().min(1),
  // ... other variables
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
});

export const env = envSchema.parse(process.env);

```

---

## 2.3 Application Constants & Error Taxonomy

### Centralized Constants

By centralizing configuration (e.g., `CACHE.eventTTL`), code becomes self-documenting, replacing "magic numbers" with intent-revealing constants.

### Error Taxonomy

We distinguish between user-driven mistakes (non-retriable) and system-driven failures (retriable).

```typescript
export class ApplicationError extends Error {
  constructor(
    public code: ErrorCode, // e.g., UNAUTHORIZED, NOT_FOUND, INFRASTRUCTURE_ERROR
    message: string,
    public metadata?: Record<string, unknown>
  ) {
    super(message);
    this.name = "ApplicationError";
  }
}

```

---

## 2.4 Structured Logging

Logs must be machine-readable to be actionable. The `logger` ensures all events are output as structured JSON objects, capturing context (e.g., `eventId`, `userId`, `duration`) that simplifies debugging in production.

```typescript
// Example usage:
logger.info("Attendance recorded", { eventId: "evt_123", userId: "usr_456" });
// Output: {"level":"info", "message":"Attendance recorded", "metadata":{...}}

```

---

## 2.5 Shared Utilities

* **Dates (`dates.ts`):** Enforces UTC globally. Date conversion to local time is strictly reserved for the presentation layer.
* **Identifiers (`ids.ts`):** Standardizes entity ID generation using `crypto.randomUUID()` with context-aware prefixes (e.g., `attendance_...`).
* **Retry (`retry.ts`):** Provides a controlled primitive for transient failures.
* **Rule:** Only retry transient network or rate-limit issues. Never retry logical failures (e.g., duplicate attendance).



---

## 2.6 Infrastructure Export

The `infrastructure/index.ts` file acts as the single point of entry, allowing the rest of the application to import shared resources cleanly:

```typescript
export * from "./config/env";
export * from "./logging/logger";
export * from "./utilities/dates";
// ... etc

```

---

## Summary

The infrastructure foundation is now complete:

* ✅ **Startup Safety:** Environment validation ensures readiness.
* ✅ **Observability:** Structured logging provides production insights.
* ✅ **Consistency:** Centralized error models and constants prevent architectural drift.
* ✅ **Resilience:** Built-in retry primitives support reliable background processing.

---

## Next: External Service Adapters

The next phase connects the platform to production-grade external systems:

* **Clerk:** Authentication & Session handling.
* **Sanity:** Database interactions and data modeling.
* **Inngest:** Durable, event-driven workflows.
* **Upstash/Resend:** Caching and notification strategies.
