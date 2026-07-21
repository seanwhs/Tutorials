# Part 5: Automating DSAR & The "Right to be Forgotten"

---

## 5.1 The Two Halves of Subject Rights: Access and Erasure

**Analogy:** Think of a hotel guest checking out. **Access** is the guest asking the front desk for an itemized copy of everything on their bill and everything in their guest file — every night stayed, every room-service order, every note staff left about their preferences. **Erasure** is the guest asking the hotel to permanently shred that entire file once they've left — not just cross out their name, but ensure no trace remains in the filing cabinet, the accounting ledger, or the housekeeping notes.

This Part builds both halves as real, working, automated systems — not manual processes a support team runs by hand in a spreadsheet:

1. **DSAR (Data Subject Access Request) Export Engine** — GDPR Article 15 & 20: a user can request a complete, portable copy of their personal data.
2. **Right to be Forgotten Deletion Orchestrator** — GDPR Article 17: a user can request permanent erasure, and it must actually cascade correctly across every system that holds their data — including third parties.

Both are built using the exact same architectural pattern established in Part 4: an Inngest event triggers a durable, multi-step function, because both operations (assembling a full export, tearing down data across multiple systems) are too slow and too failure-prone to run synchronously inside a single HTTP request.

---

## 5.2 The Target: The DSAR Export Engine

**The Concept:** A user clicks "Download My Data." Behind the scenes, we must gather every piece of personal data across every table — decrypting the encrypted fields back to readable plaintext, since an export in ciphertext would be useless to the person receiving it — bundle it into a portable format (JSON), zip it, and make it available for download. This cannot happen synchronously in the request/response cycle: decrypting dozens of journal entries via KMS calls, querying multiple tables, and building a ZIP file can take longer than a browser's patience for an open HTTP connection.

### The Implementation

**Step 1 — Install a zipping library**

```bash
npm install archiver
npm install -D @types/archiver
```

**Step 2 — Define the DSAR request/status table**

We need somewhere to track "a DSAR export was requested, here's its status, here's where the finished file lives" — a request doesn't complete instantly, so the user needs to come back and check on it.

**File: `src/db/schema.ts`** (add this new table — remember, per our Part 1 binding rule, this requires a DPIA update first; see Section 5.6 below)
```typescript
export const dsarStatusEnum = pgEnum("dsar_status", [
  "pending",
  "processing",
  "completed",
  "failed",
]);

/**
 * dsar_requests
 * -------------
 * Tracks the lifecycle of a single export request. `resultStorageKey` is
 * nullable because it's only populated once the export actually finishes —
 * before that, a user checking their request's status should see
 * "processing," not a broken link. We deliberately do NOT store the
 * exported data itself in this table (it could be many megabytes of
 * decrypted personal data) — instead we store a reference to where it
 * lives in a short-lived, access-controlled object store (Section 5.3).
 */
export const dsarRequests = pgTable("dsar_requests", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  status: dsarStatusEnum("status").notNull().default("pending"),
  resultStorageKey: varchar("result_storage_key", { length: 512 }),
  requestedAt: timestamp("requested_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  completedAt: timestamp("completed_at", { withTimezone: true }),

  // Exports themselves must not live forever — a forgotten download link
  // sitting around for years is itself a privacy liability. Enforced by
  // the same generic TTL-sweep pattern established in Part 2.
  expiresAt: timestamp("expires_at", { withTimezone: true }),
});

export const dsarRequestsRelations = relations(dsarRequests, ({ one }) => ({
  user: one(users, { fields: [dsarRequests.userId], references: [users.id] }),
}));
```

```bash
npx drizzle-kit generate
npx drizzle-kit push
```

**Step 3 — The Server Action that kicks off a request**

**File: `src/app/actions/dsar.ts`**
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/db";
import { dsarRequests, users } from "@/db/schema";
import { eq, desc } from "drizzle-orm";
import { inngest } from "@/inngest/client";

async function getInternalUserId(): Promise<string> {
  const { userId: clerkUserId } = await auth();
  if (!clerkUserId) throw new Error("Not authenticated.");

  const existing = await db.query.users.findFirst({
    where: eq(users.clerkUserId, clerkUserId),
  });
  if (existing) return existing.id;

  const [created] = await db
    .insert(users)
    .values({ clerkUserId })
    .returning({ id: users.id });
  return created.id;
}

/**
 * Kicks off a DSAR export. Notice this function does almost nothing itself
 * — it creates a tracking row and fires an event. All the actual, slow
 * work (querying, decrypting, zipping) happens in the Inngest function in
 * Section 5.3, entirely OUTSIDE this request/response cycle. This keeps
 * the user-facing action instant, even though fulfillment might take
 * seconds to minutes depending on how much data exists.
 */
export async function requestDsarExport(): Promise<{ requestId: string }> {
  const userId = await getInternalUserId();

  const [request] = await db
    .insert(dsarRequests)
    .values({ userId, status: "pending" })
    .returning({ id: dsarRequests.id });

  await inngest.send({
    name: "dsar/export.requested",
    data: { userId, requestId: request.id },
  });

  return { requestId: request.id };
}

/**
 * Lets the UI poll for status. We deliberately return only a status enum
 * and a boolean "ready" flag here — never the resultStorageKey directly —
 * the actual download is handled through a separate, authenticated route
 * (Section 5.4) that re-validates ownership before streaming any bytes.
 */
export async function getDsarRequestStatus(requestId: string): Promise<{
  status: string;
  ready: boolean;
}> {
  const userId = await getInternalUserId();

  const request = await db.query.dsarRequests.findFirst({
    where: eq(dsarRequests.id, requestId),
  });

  if (!request || request.userId !== userId) {
    // Same fail-closed philosophy as Part 3's policy engine: a mismatched
    // owner is treated identically to "not found," leaking no information
    // about whether the ID exists but belongs to someone else.
    throw new Error("Request not found.");
  }

  return { status: request.status, ready: request.status === "completed" };
}

export async function getMostRecentDsarRequest(): Promise<
  { id: string; status: string; requestedAt: Date } | null
> {
  const userId = await getInternalUserId();

  const request = await db.query.dsarRequests.findFirst({
    where: eq(dsarRequests.userId, userId),
    orderBy: desc(dsarRequests.requestedAt),
  });

  return request
    ? { id: request.id, status: request.status, requestedAt: request.requestedAt }
    : null;
}
```

### The Verification (Intermediate Checkpoint)

```bash
npm run dev
```
From a Server Action test button (or the browser console via a temporary debug page), call `requestDsarExport()`. Confirm in Neon:
```sql
SELECT id, status, requested_at FROM dsar_requests ORDER BY requested_at DESC LIMIT 1;
```
You should see one new row with `status = 'pending'`. We'll build the actual fulfillment logic next — this checkpoint just confirms the request-tracking half works before we add the heavy Inngest processing.

---

## 5.3 The Target: The Export Fulfillment Function (Gather, Decrypt, Zip)

**The Concept:** This is the "back-office clerk" from Part 0's analogy in full action: a durable, multi-step Inngest function that gathers data from every table, decrypts what needs decrypting, assembles a human-readable JSON export, zips it, and uploads it somewhere the user can retrieve it — each step checkpointed so a crash midway doesn't mean starting over from scratch.

### The Implementation

**Step 1 — A minimal local "object store" abstraction**

For this series we implement a simple filesystem-backed store standing in for a real cloud object store (S3, GCS). The interface is intentionally small so swapping in a real provider later touches only this one file.

**File: `src/lib/storage/object-store.ts`**
```typescript
import { writeFile, readFile, mkdir, unlink } from "node:fs/promises";
import path from "node:path";

// In production this directory would be a cloud bucket; for local
// development we use a gitignored folder. The KEY LESSON here is the
// INTERFACE (put/get/delete by key), not the implementation — a real
// deployment swaps this file for an S3/GCS-backed version without
// touching any of the calling code in Section 5.3 or 5.4.
const STORAGE_ROOT = path.join(process.cwd(), ".local-object-store");

export async function putObject(key: string, data: Buffer): Promise<void> {
  await mkdir(STORAGE_ROOT, { recursive: true });
  await writeFile(path.join(STORAGE_ROOT, key), data);
}

export async function getObject(key: string): Promise<Buffer> {
  return readFile(path.join(STORAGE_ROOT, key));
}

export async function deleteObject(key: string): Promise<void> {
  await unlink(path.join(STORAGE_ROOT, key)).catch(() => {
    // Deleting an already-deleted/nonexistent object is not an error in
    // this context — idempotent deletes are safer than throwing.
  });
}
```

```bash
echo ".local-object-store/" >> .gitignore
```

**Step 2 — The fulfillment function itself**

**File: `src/inngest/functions/fulfill-dsar-export.ts`**
```typescript
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import {
  users,
  moodEntries,
  journalEntries,
  medicationReminders,
  dsarRequests,
} from "@/db/schema";
import { decryptField } from "@/lib/crypto/envelope";
import { getFullConsentLedger } from "@/app/actions/consent";
import { putObject } from "@/lib/storage/object-store";
import { eq } from "drizzle-orm";
import archiver from "archiver";
import { PassThrough } from "node:stream";

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * The full DSAR fulfillment pipeline. Each `step.run` call is an
 * independently-retried checkpoint: if, say, the KMS has a transient
 * outage while decrypting journal entries, ONLY that step retries —
 * Inngest does not re-fetch mood entries or rebuild the ZIP from scratch
 * once earlier steps have already succeeded and been checkpointed.
 */
export const fulfillDsarExport = inngest.createFunction(
  { id: "fulfill-dsar-export" },
  { event: "dsar/export.requested" },
  async ({ event, step }) => {
    const { userId, requestId } = event.data;

    await step.run("mark-processing", async () => {
      await db
        .update(dsarRequests)
        .set({ status: "processing" })
        .where(eq(dsarRequests.id, requestId));
    });

    // --- Gather account metadata ---
    const accountData = await step.run("gather-account-metadata", async () => {
      const user = await db.query.users.findFirst({ where: eq(users.id, userId) });
      if (!user) throw new Error("User not found during DSAR fulfillment.");
      return {
        internalUserId: user.id,
        accountCreatedAt: user.createdAt.toISOString(),
      };
    });

    // --- Gather and decrypt mood entries ---
    const moodData = await step.run("gather-mood-entries", async () => {
      const rows = await db.query.moodEntries.findMany({
        where: eq(moodEntries.userId, userId),
      });

      const results = [];
      for (const row of rows) {
        results.push({
          score: row.score,
          note: row.noteCiphertext
            ? await decryptField(row.noteCiphertext)
            : null,
          createdAt: row.createdAt.toISOString(),
        });
      }
      return results;
    });

    // --- Gather and decrypt journal entries ---
    const journalData = await step.run("gather-journal-entries", async () => {
      const rows = await db.query.journalEntries.findMany({
        where: eq(journalEntries.userId, userId),
      });

      const results = [];
      for (const row of rows) {
        results.push({
          body: await decryptField(row.bodyCiphertext),
          createdAt: row.createdAt.toISOString(),
        });
      }
      return results;
    });

    // --- Gather and decrypt medication reminders ---
    const medicationData = await step.run("gather-medication-reminders", async () => {
      const rows = await db.query.medicationReminders.findMany({
        where: eq(medicationReminders.userId, userId),
      });

      const results = [];
      for (const row of rows) {
        results.push({
          label: await decryptField(row.labelCiphertext),
          remindAt: row.remindAt.toISOString(),
          createdAt: row.createdAt.toISOString(),
        });
      }
      return results;
    });

    // --- Gather the FULL consent ledger (Part 4) ---
    // This satisfies GDPR's requirement that a user can see proof of
    // exactly what they consented to and when — reusing, unmodified, the
    // exact function built in Part 4 for the settings history page.
    const consentData = await step.run("gather-consent-ledger", async () => {
      return getFullConsentLedger();
    });

    // --- Assemble and zip everything ---
    const storageKey = await step.run("build-and-store-zip", async () => {
      const exportPayload = {
        exportGeneratedAt: new Date().toISOString(),
        account: accountData,
        moodEntries: moodData,
        journalEntries: journalData,
        medicationReminders: medicationData,
        consentHistory: consentData,
      };

      const zipBuffer = await new Promise<Buffer>((resolve, reject) => {
        const archive = archiver("zip", { zlib: { level: 9 } });
        const passthrough = new PassThrough();
        const chunks: Buffer[] = [];

        passthrough.on("data", (chunk) => chunks.push(chunk));
        passthrough.on("end", () => resolve(Buffer.concat(chunks)));
        passthrough.on("error", reject);
        archive.on("error", reject);

        archive.pipe(passthrough);
        // A single, clearly-named JSON file inside the zip — human-
        // readable, portable, and directly satisfies GDPR Article 20's
        // "structured, commonly used, machine-readable format" requirement.
        archive.append(JSON.stringify(exportPayload, null, 2), {
          name: "mindfullog-data-export.json",
        });
        archive.finalize();
      });

      const key = `dsar-exports/${requestId}.zip`;
      await putObject(key, zipBuffer);
      return key;
    });

    // --- Finalize: mark completed, set an expiry on the export file ---
    await step.run("mark-completed", async () => {
      await db
        .update(dsarRequests)
        .set({
          status: "completed",
          resultStorageKey: storageKey,
          completedAt: new Date(),
          expiresAt: new Date(Date.now() + SEVEN_DAYS_MS),
        })
        .where(eq(dsarRequests.id, requestId));
    });

    return { requestId, storageKey };
  }
);
```

**Step 3 — Register the function**

**File: `src/app/api/inngest/route.ts`** (update)
```typescript
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { securityEventTtlSweep } from "@/inngest/functions/security-event-ttl-sweep";
import { syncMarketingConsent } from "@/inngest/functions/sync-marketing-consent";
import { fulfillDsarExport } from "@/inngest/functions/fulfill-dsar-export";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    securityEventTtlSweep,
    syncMarketingConsent,
    fulfillDsarExport, // Part 5: DSAR export fulfillment pipeline
  ],
});
```

### The Verification

**Step 1 — Seed some real data, then request an export**

Create 2-3 mood entries, 1-2 journal entries, and 1 medication reminder through the app UI (or Server Actions directly), toggle at least one consent purpose, then call `requestDsarExport()`.

**Step 2 — Watch it run in the Inngest Dev Server**

Visit `http://localhost:8288`, find the `fulfill-dsar-export` run, and confirm every step (`gather-account-metadata` through `mark-completed`) shows a green checkmark with a non-empty output.

**Step 3 — Inspect the actual ZIP file**

```bash
ls .local-object-store/dsar-exports/
unzip -p .local-object-store/dsar-exports/YOUR_REQUEST_ID.zip mindfullog-data-export.json | jq .
```
Confirm the JSON contains:
- Your account's `internalUserId` and `accountCreatedAt`.
- Every mood entry with its **plaintext** note (not ciphertext) and correct score.
- Every journal entry with its **plaintext** body.
- Every medication reminder with its **plaintext** label.
- The complete consent history, matching what you saw on the `/dashboard/settings/privacy/history` page in Part 4.

**Step 4 — Confirm the database status transitioned correctly**
```sql
SELECT status, result_storage_key, completed_at, expires_at FROM dsar_requests ORDER BY requested_at DESC LIMIT 1;
```
`status` should read `completed`, `result_storage_key` should be non-null, and `expires_at` should be roughly 7 days out — confirming the export itself won't live forever unattended.

---

## 5.4 The Target: Secure Download Delivery

**The Concept:** We never expose the raw `resultStorageKey` or a direct file path to the client. Every download must re-verify, at request time, that the requester actually owns this specific export — otherwise a leaked or guessed request ID could let anyone download someone else's complete personal data archive.

### The Implementation

**File: `src/app/api/dsar/[requestId]/download/route.ts`**
```typescript
import { auth } from "@clerk/nextjs/server";
import { db } from "@/db";
import { dsarRequests, users } from "@/db/schema";
import { eq } from "drizzle-orm";
import { getObject } from "@/lib/storage/object-store";
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ requestId: string }> }
) {
  const { userId: clerkUserId } = await auth();
  if (!clerkUserId) {
    return NextResponse.json({ error: "Not authenticated." }, { status: 401 });
  }

  const { requestId } = await params;

  const user = await db.query.users.findFirst({
    where: eq(users.clerkUserId, clerkUserId),
  });
  if (!user) {
    return NextResponse.json({ error: "Not found." }, { status: 404 });
  }

  const dsarRequest = await db.query.dsarRequests.findFirst({
    where: eq(dsarRequests.id, requestId),
  });

  // Ownership check happens HERE, at download time — never trust that a
  // request ID reaching this route implies the requester is entitled to
  // it, even if it came from a link we generated ourselves earlier.
  if (
    !dsarRequest ||
    dsarRequest.userId !== user.id ||
    dsarRequest.status !== "completed" ||
    !dsarRequest.resultStorageKey
  ) {
    return NextResponse.json({ error: "Not found." }, { status: 404 });
  }

  // Respect the export's own expiry — an old, technically-still-present
  // file should not be servable past its stated retention window.
  if (dsarRequest.expiresAt && dsarRequest.expiresAt < new Date()) {
    return NextResponse.json({ error: "This export has expired." }, { status: 410 });
  }

  const fileBuffer = await getObject(dsarRequest.resultStorageKey);

  return new NextResponse(fileBuffer, {
    headers: {
      "Content-Type": "application/zip",
      "Content-Disposition": `attachment; filename="mindfullog-export-${requestId}.zip"`,
    },
  });
}
```

**File: `src/app/dashboard/settings/export/page.tsx`**
```typescript
import {
  requestDsarExport,
  getMostRecentDsarRequest,
} from "@/app/actions/dsar";

export default async function ExportPage() {
  const mostRecent = await getMostRecentDsarRequest();

  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="mb-4 text-2xl font-bold text-slate-800">Export Your Data</h1>
      <p className="mb-6 text-sm text-slate-500">
        Request a complete copy of everything MindfulLog knows about you,
        including your journal entries, mood history, and consent decisions.
      </p>

      <form
        action={async () => {
          "use server";
          await requestDsarExport();
        }}
      >
        <button
          type="submit"
          className="rounded-lg bg-slate-800 px-4 py-2 font-semibold text-white hover:bg-slate-700"
        >
          Request Export
        </button>
      </form>

      {mostRecent && (
        <div className="mt-6 rounded-lg border border-slate-200 p-4 text-sm">
          <p>
            Most recent request: <strong>{mostRecent.status}</strong>{" "}
            ({mostRecent.requestedAt.toLocaleString()})
          </p>

          {mostRecent.status === "completed" && (
            <a
              href={`/api/dsar/${mostRecent.id}/download`}
              className="mt-3 inline-block rounded-lg bg-emerald-700 px-4 py-2 font-semibold text-white hover:bg-emerald-600"
            >
              Download ZIP
            </a>
          )}

          {mostRecent.status !== "completed" && (
            <p className="mt-2 text-slate-500">
              Your export is still being prepared. Refresh this page in a
              moment.
            </p>
          )}
        </div>
      )}
    </main>
  );
}
```

### The Verification

**Step 1 — End-to-end happy path in the browser**

Visit `/dashboard/settings/export`, click **Request Export**, wait a few seconds (watching the Inngest dev server confirm the run completes), then refresh the page. A green **Download ZIP** button should appear. Click it — your browser should download a real `.zip` file, which unzips to reveal `mindfullog-data-export.json` containing all your plaintext data.

**Step 2 — Confirm cross-user protection at the download route**

Sign in as **User B** in an incognito window. Manually navigate to `/api/dsar/USER_A_REQUEST_ID/download` (copy User A's request ID from the database). Confirm the response is `404 Not Found` — **not** User A's ZIP file, and not a revealing error message like "this belongs to someone else."

**Step 3 — Confirm expiry enforcement**

```sql
-- Manually force an export to look expired
UPDATE dsar_requests SET expires_at = now() - interval '1 day' WHERE id = 'YOUR_REQUEST_ID';
```
Reload the download link. Confirm the response is `410 Gone` with the message `"This export has expired."` — proving the retention window is enforced at read-time, not just documented as a policy.

---

## 5.5 The Target: The Right to be Forgotten — A Multi-System Deletion Orchestrator

**The Concept:** This is the single most architecturally important feature in the entire series. Recall from Part 0: erasure is **never** a single `DELETE FROM users` statement — it's a cascade across every system that ever touched the user's data, including a third-party vendor (Clerk) we don't control. We need to handle three distinct categories of data differently:

| Data Category | Strategy | Why |
|---|---|---|
| Our own encrypted content (journal, mood, medication) | **Hard delete** via `ON DELETE CASCADE` | No legal reason to retain special-category health data past a valid erasure request |
| Consent ledger | **Retain, but anonymize the link** | GDPR requires *proving* consent was properly obtained and honored — deleting the audit trail could itself violate accountability obligations; instead we sever its connection to identity |
| Third-party identity (Clerk) | **Explicit API call to delete** | This data was never in our database at all — our own deletion is incomplete without it |

**Analogy:** This is the hotel-checkout shredding example from 5.1, but now precisely specified: the room-service orders and guest notes (journal/mood data) get shredded outright. The accounting ledger entry proving "this guest signed the terms on this date" is kept for financial audit purposes, but with the guest's name blacked out — a **tombstone**, not a full erasure, because destroying proof-of-consent could itself create a compliance gap. And the hotel chain's separate central reservation system (Clerk) needs its own, separate phone call to also delete the guest's profile — the local hotel shredding its own copy doesn't touch the central system at all.

### The Implementation

**Step 1 — Add a `deletion_requests` tracking table**

**File: `src/db/schema.ts`** (add)
```typescript
export const deletionStatusEnum = pgEnum("deletion_status", [
  "pending",
  "processing",
  "completed",
  "failed",
]);

/**
 * deletion_requests
 * ------------------
 * Tracks the lifecycle of an erasure request. Unlike dsar_requests, this
 * table's rows are themselves NEVER deleted, even after the user's data
 * is gone — this row IS the tombstone proving a deletion occurred, when,
 * and that it completed successfully. Note there is deliberately NO
 * foreign key with onDelete: "cascade" to users here — if it cascaded,
 * the very act of deleting the user would delete the proof that deletion
 * happened, defeating the purpose of an audit trail.
 */
export const deletionRequests = pgTable("deletion_requests", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id").notNull(), // intentionally NOT a live FK — see comment above
  status: deletionStatusEnum("status").notNull().default("pending"),
  requestedAt: timestamp("requested_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
  completedAt: timestamp("completed_at", { withTimezone: true }),
});
```

```bash
npx drizzle-kit generate
npx drizzle-kit push
```

**Step 2 — The Server Action to initiate deletion**

**File: `src/app/actions/deletion.ts`**
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/db";
import { users, deletionRequests } from "@/db/schema";
import { eq } from "drizzle-orm";
import { inngest } from "@/inngest/client";

async function getInternalUserId(): Promise<string> {
  const { userId: clerkUserId } = await auth();
  if (!clerkUserId) throw new Error("Not authenticated.");

  const existing = await db.query.users.findFirst({
    where: eq(users.clerkUserId, clerkUserId),
  });
  if (existing) return existing.id;

  throw new Error("User record not found.");
}

/**
 * Initiates account deletion. This function deliberately does almost
 * nothing itself — real deletion work happens entirely in the Inngest
 * orchestrator (Section 5.5, Step 3), because a multi-system cascade
 * (Postgres tables + Clerk's API) is exactly the kind of slow,
 * failure-prone, must-not-silently-drop operation Inngest exists for.
 */
export async function requestAccountDeletion(): Promise<{ requestId: string }> {
  const userId = await getInternalUserId();

  const [request] = await db
    .insert(deletionRequests)
    .values({ userId, status: "pending" })
    .returning({ id: deletionRequests.id });

  await inngest.send({
    name: "user.deletion.requested",
    data: { userId, requestId: request.id },
  });

  return { requestId: request.id };
}
```

**Step 3 — Clerk's Backend API client for identity deletion**

```bash
npm install @clerk/backend
```

**File: `src/lib/auth/clerk-admin.ts`**
```typescript
import { createClerkClient } from "@clerk/backend";

// A SEPARATE client from the request-scoped `auth()` helper used
// elsewhere — this one uses our secret key directly to make privileged,
// server-to-server Backend API calls, entirely outside any user's
// session context. It should NEVER be imported into any client-facing
// code path — only into the deletion orchestrator below.
export const clerkAdminClient = createClerkClient({
  secretKey: process.env.CLERK_SECRET_KEY!,
});

/**
 * Permanently deletes a user's identity record from Clerk. This is the
 * step that makes our "Right to be Forgotten" implementation actually
 * complete — without this call, a user's email, login history, and
 * session records would persist indefinitely in Clerk's systems even
 * after every trace of them is gone from our own database.
 */
export async function deleteClerkUser(clerkUserId: string): Promise<void> {
  await clerkAdminClient.users.deleteUser(clerkUserId);
}
```

**Step 4 — The full deletion orchestrator**

**File: `src/inngest/functions/fulfill-account-deletion.ts`**
```typescript
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import { users, deletionRequests } from "@/db/schema";
import { deleteClerkUser } from "@/lib/auth/clerk-admin";
import { eq, sql } from "drizzle-orm";

/**
 * The complete Right to be Forgotten cascade. Steps run in a specific,
 * deliberate order: we delete OUR OWN encrypted data FIRST (irreversible,
 * lowest-risk-to-delay), THEN sever/anonymize the consent ledger's link to
 * identity (preserving the audit trail itself), and ONLY THEN call out to
 * Clerk — because if the Clerk call fails and needs a retry, we want it
 * retried in isolation without re-running destructive SQL that already
 * succeeded. Each step is idempotent: safe to re-run if Inngest retries it.
 */
export const fulfillAccountDeletion = inngest.createFunction(
  { id: "fulfill-account-deletion" },
  { event: "user.deletion.requested" },
  async ({ event, step }) => {
    const { userId, requestId } = event.data;

    await step.run("mark-processing", async () => {
      await db
        .update(deletionRequests)
        .set({ status: "processing" })
        .where(eq(deletionRequests.id, requestId));
    });

    // Fetch the Clerk ID BEFORE we sever it — we need it later to call
    // Clerk's API, and once the users row is anonymized/deleted, this
    // information is gone from our side forever (by design).
    const clerkUserId = await step.run("fetch-clerk-user-id", async () => {
      const user = await db.query.users.findFirst({ where: eq(users.id, userId) });
      if (!user) throw new Error("User not found — cannot proceed with deletion.");
      return user.clerkUserId;
    });

    // Hard-delete all of our own special-category data. The `ON DELETE
    // CASCADE` foreign keys defined in schema.ts (Part 2) on
    // mood_entries, journal_entries, and medication_reminders mean a
    // SINGLE delete against the users row cascades automatically — we
    // don't need five separate DELETE statements. This step is naturally
    // idempotent: if Inngest retries it after a crash, the second
    // DELETE simply matches zero rows and succeeds silently.
    await step.run("hard-delete-user-and-cascaded-data", async () => {
      await db.delete(users).where(eq(users.id, userId));
    });

    // Anonymize (NOT delete) the consent ledger's link to this user.
    // We overwrite userId with a fixed, non-reversible sentinel value
    // rather than deleting these rows outright — preserving the AUDIT
    // TRAIL that consent decisions were properly recorded and honored,
    // while removing any way to tie those decisions back to a specific
    // identity. This directly implements the "tombstone, not full
    // erasure" strategy described in Section 5.5's introduction.
    //
    // NOTE: consent_records has `onDelete: "cascade"` on its userId FK
    // (Part 2), which means the hard-delete above would ALREADY have
    // cascaded these rows away before we get here. To actually preserve
    // them as anonymized tombstones instead, this requires an updated
    // schema decision — see Reference 5.B for the full explanation of
    // why we deliberately change consent_records' foreign key behavior
    // and how, before this step can work as described.
    await step.run("anonymize-consent-ledger-tombstones", async () => {
      const ANONYMIZED_SENTINEL = "00000000-0000-0000-0000-000000000000";
      await db.execute(sql`
        UPDATE consent_records
        SET user_id = ${ANONYMIZED_SENTINEL}
        WHERE user_id = ${userId}
      `);
    });

    // Finally, call out to Clerk to delete the identity record itself.
    // This runs LAST and in its own isolated step so that if it fails
    // (e.g., Clerk API transient outage), Inngest retries ONLY this
    // step — our own database-side deletion has already durably
    // succeeded and will not be redone or double-processed.
    await step.run("delete-clerk-identity", async () => {
      await deleteClerkUser(clerkUserId);
    });

    await step.run("mark-completed", async () => {
      await db
        .update(deletionRequests)
        .set({ status: "completed", completedAt: new Date() })
        .where(eq(deletionRequests.id, requestId));
    });

    return { requestId, userId, status: "completed" };
  }
);
```

> **Important correction flagged inline above, and expanded in Reference 5.B:** as written, Part 2's schema has `consent_records.userId` configured with `onDelete: "cascade"`, meaning the `hard-delete-user-and-cascaded-data` step would delete consent rows *before* the anonymization step ever runs — silently destroying the very audit trail we intend to preserve. This is a deliberate teaching moment, not an oversight: real deletion cascades are easy to get subtly wrong precisely because cascade behavior is configured once, far away (in `schema.ts`), from where deletion actually executes. We fix this properly in Section 5.5, Step 5 below, by changing the foreign key.

**Step 5 — Fixing the foreign key to make the tombstone strategy actually work**

**File: `src/db/schema.ts`** (modify the existing `consentRecords` table definition)
```typescript
export const consentRecords = pgTable("consent_records", {
  id: uuid("id").defaultRandom().primaryKey(),

  // CHANGED from `{ onDelete: "cascade" }` to `{ onDelete: "set null" }`...
  // but wait: userId is `.notNull()`, which is incompatible with
  // "set null". The correct fix is to REMOVE the foreign key constraint
  // entirely for this table, since we now manage the anonymization
  // relationship manually and intentionally at the application layer
  // (Step 4 above) rather than relying on Postgres's cascade behavior.
  userId: uuid("user_id").notNull(), // no .references() — see explanation below

  purpose: consentPurposeEnum("purpose").notNull(),
  granted: boolean("granted").notNull(),
  recordedAt: timestamp("recorded_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});
```

This is a meaningful, deliberate architectural decision: `consent_records` no longer has a live foreign-key relationship to `users` at all. It is treated as an independent, append-only audit log whose rows must outlive the user row they originally referenced. We accept the tradeoff of losing referential-integrity enforcement at the database level in exchange for guaranteed audit-trail survivability — a tradeoff regulators explicitly expect controllers to make correctly.

```bash
npx drizzle-kit generate
# Review the generated migration carefully — it should DROP the existing
# foreign key constraint on consent_records.user_id, and nothing else.
npx drizzle-kit push
```

**Step 6 — Register the function**

**File: `src/app/api/inngest/route.ts`** (final update for this Part)
```typescript
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { securityEventTtlSweep } from "@/inngest/functions/security-event-ttl-sweep";
import { syncMarketingConsent } from "@/inngest/functions/sync-marketing-consent";
import { fulfillDsarExport } from "@/inngest/functions/fulfill-dsar-export";
import { fulfillAccountDeletion } from "@/inngest/functions/fulfill-account-deletion";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    securityEventTtlSweep,
    syncMarketingConsent,
    fulfillDsarExport,
    fulfillAccountDeletion, // Part 5: the full Right to be Forgotten cascade
  ],
});
```

**Step 7 — A confirmation-gated UI (never a single accidental click)**

**File: `src/app/dashboard/settings/delete-account/page.tsx`**
```typescript
"use client";

import { useState } from "react";
import { requestAccountDeletion } from "@/app/actions/deletion";

export default function DeleteAccountPage() {
  const [confirmText, setConfirmText] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const isConfirmed = confirmText === "DELETE MY ACCOUNT";

  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="mb-4 text-2xl font-bold text-red-700">Delete Account</h1>
      <p className="mb-4 text-sm text-slate-600">
        This permanently deletes your journal entries, mood history, and
        medication reminders, and removes your identity from our
        authentication provider. This cannot be undone.
      </p>
      <p className="mb-4 text-sm text-slate-500">
        Type <strong>DELETE MY ACCOUNT</strong> below to confirm.
      </p>

      <input
        type="text"
        value={confirmText}
        onChange={(e) => setConfirmText(e.target.value)}
        className="mb-4 w-full rounded-lg border border-slate-300 p-2"
        placeholder="DELETE MY ACCOUNT"
      />

      <button
        disabled={!isConfirmed || submitted}
        onClick={async () => {
          await requestAccountDeletion();
          setSubmitted(true);
        }}
        className="rounded-lg bg-red-700 px-4 py-2 font-semibold text-white disabled:cursor-not-allowed disabled:bg-red-300"
      >
        {submitted ? "Deletion in progress..." : "Permanently Delete My Account"}
      </button>
    </main>
  );
}
```

### The Verification

**Step 1 — Full end-to-end deletion test on a disposable Neon branch**

This is exactly the "Neon database branching" workflow flagged as a key stack advantage back in Part 0 — we never rehearse a destructive cascade against real-looking data without a disposable copy:
```bash
neonctl branches create --name deletion-test-branch --parent main
neonctl connection-string deletion-test-branch
# Copy this connection string into a TEMPORARY .env.local override for this test only
```

**Step 2 — Seed a full test account, then delete it**

Using the temporary branch, sign up a test user, create journal entries, mood entries, medication reminders, and at least one consent decision. Note the user's `id`, `clerkUserId`, and the consent record count. Then trigger deletion via the UI.

**Step 3 — Watch the cascade in the Inngest dashboard**

Confirm all six steps (`mark-processing` through `mark-completed`) succeed in order.

**Step 4 — Verify each category was handled correctly, per the strategy table in 5.5**

```sql
-- 1. Confirm the user row itself is gone
SELECT * FROM users WHERE id = 'YOUR_TEST_USER_ID'; -- expect 0 rows

-- 2. Confirm cascaded content tables are empty for this user
SELECT count(*) FROM journal_entries WHERE user_id = 'YOUR_TEST_USER_ID'; -- expect 0
SELECT count(*) FROM mood_entries WHERE user_id = 'YOUR_TEST_USER_ID'; -- expect 0
SELECT count(*) FROM medication_reminders WHERE user_id = 'YOUR_TEST_USER_ID'; -- expect 0

-- 3. Confirm consent records were ANONYMIZED, not deleted — same row
--    COUNT as before deletion, but now under the sentinel ID
SELECT count(*) FROM consent_records WHERE user_id = '00000000-0000-0000-0000-000000000000';
-- expect this to match the exact number of consent decisions the test
-- user made — proving the audit trail survived deletion intact

-- 4. Confirm the deletion_requests tombstone row itself persists
SELECT status, completed_at FROM deletion_requests WHERE id = 'YOUR_REQUEST_ID';
-- expect status = 'completed', with a real completed_at timestamp
```

**Step 5 — Verify the Clerk side**

In the Clerk dashboard, search for the deleted test user's email. Confirm **no matching user exists** — proving the third-party identity deletion actually happened, not just our local database cleanup.

**Step 6 — Clean up the disposable branch**
```bash
neonctl branches delete deletion-test-branch
```
Restore your real `.env.local` `DATABASE_URL` before continuing any further development.

---

## Part 5 — Reference Section: Deep Dives

### Reference 5.A — Why Deletion Order Matters (Fetch-Before-Sever)

Notice `fetch-clerk-user-id` runs and captures `clerkUserId` into a local variable *before* the hard-delete step. This ordering is not arbitrary: once `users` row is deleted, there is no longer any stored link between our internal `userId` and Clerk's `clerkUserId` anywhere in our system — by design, since Section 2.2 established this as the *only* place that link lives. If we deleted the user row first and only afterward tried to look up their Clerk ID to call the deletion API, we would have already destroyed our only reference to it. Any multi-system deletion cascade must therefore be sequenced with this rule in mind: **capture every cross-system reference you'll need *before* deleting the row that holds it, never after.** This is a subtle but extremely common real-world bug — teams build a deletion flow that works perfectly in testing (because they test deletion order loosely), then discover in production that a retry after partial failure has permanently orphaned a third-party account with no way to look up which one it was.

### Reference 5.B — Why We Removed the Foreign Key on `consent_records` Entirely

Earlier in this Part, we deliberately walked through a broken first attempt (cascading delete silently destroying the audit trail) before fixing it — because this exact mistake is the single most common bug in real "Right to be Forgotten" implementations. It's worth stating the general principle explicitly:

**Any table your organization needs to survive a user's deletion for accountability/audit purposes must never have a cascading foreign key to that user's row.** This includes: consent records (to prove lawful basis was honored), billing/invoice records (often required by tax law to retain for years, in tension with — but generally lawfully overriding — an erasure request under GDPR Article 17(3)(b)'s "compliance with a legal obligation" exception), and security incident logs tied to abuse investigations already in progress.

The general pattern is: **before deletion, walk every table with a foreign key to `users` and classify each one as either "must hard-delete" or "must survive as an anonymized tombstone."** Get this classification wrong in either direction, and you either destroy legally-required records or fail to actually honor an erasure request.

### Reference 5.C — The Sentinel UUID Pattern, and Its Limits

We used a fixed, obviously-fake UUID (`00000000-0000-0000-0000-000000000000`) as the "anonymized" value for `consent_records.user_id`. This is a simple, readable choice for a tutorial, but it has one real limitation worth naming: every deleted user's consent records collapse into the *same* sentinel value, meaning you can prove "consent was granted/withdrawn by *some now-deleted user*, at this exact timestamp, for this exact purpose" — but you can no longer distinguish *which* deleted user, even internally. For MindfulLog's purposes (proving the *system as a whole* honored consent decisions correctly) this is sufficient. A more sophisticated production system might instead generate a unique, unlinkable random UUID per deletion (rather than one shared sentinel), preserving the ability to distinguish "these five consent records belonged to the same now-deleted person" without being able to determine who that person was — a technique called **pseudonymization** rather than full anonymization, and worth escalating to if your specific audit requirements need per-user distinction post-deletion.

### Reference 5.D — What About Backups and Event Streams?

Our deletion orchestrator correctly handles our live Postgres database and Clerk's live identity store — but Part 0's architecture diagram and Part 1's DPIA both flagged event streams (Inngest's own event log) and, in a real production system, database backups/snapshots as additional places data can persist. This series does not build a backup-purging pipeline (most managed database providers, including Neon, apply a rolling retention window to backups — e.g., 7 or 30 days — after which old backups are automatically discarded, which typically satisfies GDPR's "without undue delay" standard for erasure as long as this window is documented in your DPIA and privacy policy). What you **must** do in a real system: confirm and document your specific provider's backup retention window in the DPIA's Risk Assessment table (Part 1, Section 4), and ensure your event bus (Inngest, Kafka, EventBridge) payloads never carry more than the pseudonymous ID needed for processing — exactly the discipline we established back in Part 1's data-flow map, and reused unchanged in every event payload this Part fired (`dsar/export.requested`, `user.deletion.requested`). Because we never put raw PII into event payloads, an event stream retaining old events for a period after deletion is a much smaller residual risk than it would be if we had been careless from the start.

---

## Part 5 — Summary & What Carries Forward

By completing Part 5, your repository now contains:

- ✅ `src/db/schema.ts` extended with `dsarRequests` and `deletionRequests` tracking tables, and a corrected (no-cascade) foreign key on `consentRecords`
- ✅ A complete, tested DSAR export pipeline: request → durable multi-step gather/decrypt/zip → secure, ownership-verified, expiry-respecting download
- ✅ `src/lib/auth/clerk-admin.ts` — the Backend API bridge completing our third-party deletion obligation
- ✅ A fully sequenced, idempotent, multi-system deletion orchestrator distinguishing hard-delete vs. tombstone-anonymize vs. third-party-API-delete
- ✅ A confirmation-gated deletion UI preventing accidental single-click destruction
- ✅ A verified, branch-tested (via Neon branching) end-to-end proof that deletion actually cascades correctly across Postgres and Clerk

**What Part 6 inherits from here:** every pattern built in this Part — decrypting fields for export, anonymizing rather than deleting audit records, calling third-party APIs during teardown — becomes something a CI/CD pipeline must actively protect against regressions. Part 6 builds automated checks that would have caught our own deliberately-inserted Reference 5.B bug (a cascading FK on an audit table) *before* it ever reached production, plus PII-leak scanning across logs and error trackers, and a full privacy posture audit process.

**Quick self-check before moving on:**
1. Can I explain why `fetch-clerk-user-id` must run before `hard-delete-user-and-cascaded-data`, not after?
2. Do I understand why `consent_records` no longer has a foreign key to `users` at all?
3. Did my Neon branch test confirm the exact same consent-record count survived deletion, just under the sentinel ID?
4. Can I name one category of data (per Reference 5.D) that this Part's orchestrator does NOT directly purge, and why that's an acceptable, documented residual risk rather than a bug?
