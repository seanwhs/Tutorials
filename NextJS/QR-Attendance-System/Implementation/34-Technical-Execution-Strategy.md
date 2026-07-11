# Technical Execution Strategy

## 1. Project Scaffold (Modular Monolith)

To maintain the "Locality of Behavior" you favor, we will organize the codebase by **domain module**, not by technical function.

```text
/src
  /app              # Next.js App Router (Entry points)
  /components       # Shared UI (Tailwind + Alpine)
  /modules          # The Modular Monolith core
    /attendance     # Logic, Services, Actions
    /events         # Logic, Services, Actions
    /identity       # Logic, Services, Actions
    /reporting      # Logic, Services, Actions
  /lib              # Shared infra (Clerk, Sanity, Inngest, Redis)
  /types            # Shared domain types

```

---

## 2. Core Service Implementation: The "Attendance" Module

We will start by creating a robust **Server Action** that leverages your defined security and audit patterns.

### Technical Specification

* **Action:** `checkInAttendee`
* **Requirements:** QR signature validation, rate limiting, audit logging, idempotency.

```typescript
// /modules/attendance/actions/check-in.ts
'use server';

import { z } from 'zod';
import { validateQrSignature } from '../lib/qr';
import { db } from '@/lib/db';
import { auditLog } from '@/lib/audit';

const CheckInSchema = z.object({
  eventId: z.string(),
  attendeeId: z.string(),
  signature: z.string(),
});

export async function checkInAttendee(data: z.infer<typeof CheckInSchema>) {
  // 1. Validation
  const validatedData = CheckInSchema.parse(data);

  // 2. Security: Verify QR Payload
  const isValid = await validateQrSignature(validatedData.signature);
  if (!isValid) throw new Error('Invalid QR Signature');

  // 3. Business Logic (Check idempotency, update status)
  const record = await db.attendance.create({ 
     data: { ...validatedData, timestamp: new Date() } 
  });

  // 4. Audit
  await auditLog('attendance.checked_in', { attendeeId: validatedData.attendeeId });

  return { success: true, record };
}

```

---

## 3. Data Integrity & Schema Definition (Zod + TypeScript)

We define the **Canonical Information Model** in code to ensure consistency across the API and the Database.

```typescript
// /modules/events/types.ts
export interface EventAggregate {
  id: string;
  organizationId: string;
  name: string;
  status: 'draft' | 'live' | 'completed';
  capacity: number;
  metadata: Record<string, any>;
}

```

---

## 4. Operational "Safety Net" Integration

We will configure **Inngest** for all side effects (email notifications, reporting updates) to ensure the main attendance loop is never blocked by external service latency.

```typescript
// /lib/inngest/client.ts
// This manages the asynchronous event-driven architecture
export const inngest = new Inngest({ name: "Singapore Field Operations" });

// Example: Triggering a background task after check-in
await inngest.send({
  name: "attendance/checked_in",
  data: { attendeeId: record.id },
});

```

---

## 5. Development Roadmap: The "First Three Sprints"

* **Sprint 1:** Foundation. Set up Next.js 16 + Tailwind + Clerk (Auth) + Sanity (CMS).
* **Sprint 2:** Domain Core. Build the `Identity` and `Event` modules. Implement the RBAC middleware.
* **Sprint 3:** The "Final Boss." Implement the QR scanning flow with Server Actions, rate limiting, and the Audit Log service.
