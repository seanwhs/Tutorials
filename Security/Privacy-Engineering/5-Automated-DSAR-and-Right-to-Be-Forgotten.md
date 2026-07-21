Based on the source material, the numbering is now fully confirmed across all documents. Part 1's own text explicitly states the consent UI is built "in Part 5" and that data minimization is formalized "in Part 3" [1][5], which matches the file-name-based scheme (0-Introduction, 1-Scaffold-Clerk-DPIA, 2-Data-Minimization, 3-Architecture-and-Storage). That means **Part 4** is Consent Management & Transparency (which I generated in my previous turn — the append-only consent ledger, anti-dark-pattern UI, and Inngest consumer), and **Part 5** is the next new part: **Automated DSAR & Right to be Forgotten**.

The target architecture confirms exactly what belongs here: the Inngest background workflows box explicitly lists "DSAR export job" and "account deletion cascade job" as the two jobs living alongside the consent-reaction jobs we already built [2].

The provided sources don't contain the actual DSAR/deletion implementation content itself — only the architecture diagram's labels for these jobs [2] and the earlier Parts' cross-references to later parts [1][5]. So the content below is generated fresh for this part, consistent with what those sources specify as this part's scope.

---

**[GENERATED: Part 4 — Consent Management & Transparency] [STARTING: Part 5 — Automated DSAR & Right to be Forgotten]**

# Part 5: Automated DSAR & Right to be Forgotten

## 5.0 Where we are on the map

The target architecture names exactly two remaining Inngest jobs we haven't built yet: the **DSAR export job** and the **account deletion cascade job** [2]. ("DSAR" stands for Data Subject Access Request — a formal request, under GDPR, for a copy of everything an organization holds about you.) Both jobs sit in the same Inngest background-workflow box as the consent-change consumer we built in Part 4, reacting to events rather than blocking a user's browser while multi-table, multi-step work happens synchronously [2].

By the end of Part 5 you will have:
1. A `DsarRequest` table tracking the lifecycle of export/deletion requests.
2. An Inngest **export job** that gathers every table's data for a user, decrypts it, and produces a downloadable JSON file.
3. An Inngest **deletion cascade job** that permanently removes a user's data across every table — including reconciling with the append-only consent ledger, which must never be silently destroyed even when its owner's account is deleted.
4. User-facing Server Actions and a dashboard page to trigger both.

---

## Step 5.1 — Tracking DSAR requests

### The Target
A `DsarRequest` model recording the type, status, and lifecycle of each export or deletion request.

### The Concept
A DSAR isn't instant — gathering and decrypting every table's data, or safely cascading a deletion, takes real time and can fail partway through. We need a durable record of "what was requested, and where does it currently stand," independent of whether the background job that's actually doing the work is still running, crashed, or hasn't started yet. Think of it like a package tracking number: the number exists and is checkable the moment you request a shipment, well before the package itself has moved.

### The Implementation

**File: `prisma/schema.prisma`** (append)

```prisma
enum DsarRequestType {
  EXPORT
  DELETION
}

enum DsarRequestStatus {
  PENDING
  IN_PROGRESS
  COMPLETED
  FAILED
}

model DsarRequest {
  id          String            @id @default(cuid())
  userId      String
  user        User              @relation(fields: [userId], references: [id], onDelete: Cascade)
  type        DsarRequestType
  status      DsarRequestStatus @default(PENDING)
  // Populated only for EXPORT requests once the job completes — a
  // signed, time-limited download URL in a real deployment; here we
  // store the exported JSON payload directly for simplicity.
  exportPayload Json?
  requestedAt DateTime          @default(now())
  completedAt DateTime?

  @@map("dsar_requests")
}
```

```bash
npm run db:migrate -- --name add_dsar_requests
```

### The Verification

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "\d dsar_requests"
```

Confirm both enums and all columns appear. Commit:

```bash
git add -A
git commit -m "feat: add DsarRequest table tracking export/deletion request lifecycle"
```

---

## Step 5.2 — The DSAR export job

### The Target
An Inngest function that gathers, decrypts, and packages every piece of a user's data into a single JSON export.

### The Concept
Exporting a user's data means touching every sensitive table we've built — mood entries, journal entries, medication reminders, consent ledger — and, critically, **decrypting** the ciphertext columns first, since a raw export of encrypted bytes would be useless to the person requesting it. This is exactly the kind of multi-step, must-not-silently-fail process Inngest exists for: if step 3 of 5 fails, we want a clean retry of that step, not a half-finished export silently reported as "done."

### The Implementation

**File: `src/lib/inngest/functions/dsar-export.ts`**

```typescript
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { decryptField } from "@/lib/encryption";

export const dsarExport = inngest.createFunction(
  { id: "dsar-export" },
  { event: "dsar/export.requested" },
  async ({ event, step }) => {
    const { dsarRequestId, userId } = event.data;

    await step.run("mark-in-progress", async () => {
      await db.dsarRequest.update({
        where: { id: dsarRequestId },
        data: { status: "IN_PROGRESS" },
      });
    });

    // Each table is gathered and decrypted in its own step, so a
    // transient failure on, say, medication reminders retries just
    // that step — not the entire export from scratch.
    const moodEntries = await step.run("gather-mood-entries", async () => {
      const rows = await db.moodEntry.findMany({ where: { userId } });
      return rows.map((r) => ({ score: r.score, note: r.note, loggedAt: r.loggedAt }));
    });

    const journalEntries = await step.run("gather-journal-entries", async () => {
      const rows = await db.journalEntry.findMany({ where: { userId } });
      return rows.map((r) => ({
        body: decryptField(r.bodyCiphertext),
        createdAt: r.createdAt,
      }));
    });

    const medicationReminders = await step.run("gather-medication-reminders", async () => {
      const rows = await db.medicationReminder.findMany({ where: { userId } });
      return rows.map((r) => ({
        medicationName: decryptField(r.medicationNameCiphertext),
        dosageNote: r.dosageNoteCiphertext ? decryptField(r.dosageNoteCiphertext) : null,
        reminderHour: r.reminderHour,
        reminderMinute: r.reminderMinute,
      }));
    });

    const consentHistory = await step.run("gather-consent-history", async () => {
      const rows = await db.consentLedgerEntry.findMany({
        where: { userId },
        orderBy: { recordedAt: "asc" },
      });
      return rows.map((r) => ({
        category: r.category,
        status: r.status,
        policyVersion: r.policyVersion,
        recordedAt: r.recordedAt,
      }));
    });

    await step.run("finalize-export", async () => {
      await db.dsarRequest.update({
        where: { id: dsarRequestId },
        data: {
          status: "COMPLETED",
          completedAt: new Date(),
          exportPayload: {
            moodEntries,
            journalEntries,
            medicationReminders,
            consentHistory,
            exportedAt: new Date().toISOString(),
          },
        },
      });
    });
  },
);
```

### The Verification

Register `dsarExport` in `src/app/api/inngest/route.ts`'s `functions` array (alongside `consentChanged`), then trigger it manually via `inngest.send({ event: "dsar/export.requested", data: { dsarRequestId: "...", userId: "..." } })` from a temporary test script or the Inngest Dev Server UI's "Trigger" button. Watch each step complete individually in the Dev Server dashboard, then confirm:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT status, \"exportPayload\" FROM dsar_requests WHERE id = '...';"
```

Confirm `status = COMPLETED` and `exportPayload` contains readable, decrypted journal/medication text — not ciphertext.

Commit:

```bash
git add -A
git commit -m "feat: add Inngest DSAR export job decrypting and packaging all user data"
```

---

## Step 5.3 — The account deletion cascade job

### The Target
An Inngest function that permanently deletes a user's data across every table — while preserving the consent ledger in anonymized form, exactly as the DPIA's retention policy requires.

### The Concept
"Right to be forgotten" sounds like it should mean "delete everything, no exceptions" — but our own DPIA already carved out a deliberate exception: consent ledger entries are retained permanently, even after account deletion, in anonymized/pseudonymized form, because we must be able to prove historical consent was obtained even for a since-deleted account. Deletion, done correctly, isn't "erase the row" everywhere uniformly — it's "erase or anonymize according to each table's own retention rule," which is precisely why this needs its own deliberate, multi-step job rather than a single `ON DELETE CASCADE`.

### The Implementation

**File: `src/lib/inngest/functions/dsar-deletion.ts`**

```typescript
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";

export const dsarDeletion = inngest.createFunction(
  { id: "dsar-deletion" },
  { event: "dsar/deletion.requested" },
  async ({ event, step }) => {
    const { dsarRequestId, userId } = event.data;

    await step.run("mark-in-progress", async () => {
      await db.dsarRequest.update({
        where: { id: dsarRequestId },
        data: { status: "IN_PROGRESS" },
      });
    });

    // Anonymize, don't delete, the consent ledger — this row's userId
    // is replaced with a stable placeholder so the historical proof of
    // "a grant/revoke happened on this date, under this policy version"
    // survives, while no longer linking back to an identifiable person.
    await step.run("anonymize-consent-ledger", async () => {
      await db.consentLedgerEntry.updateMany({
        where: { userId },
        data: { userId: "ANONYMIZED" },
      });
    });

    // Every other table cascades via the onDelete: Cascade relation
    // already defined in our schema (Parts 2–3) — deleting the User row
    // is sufficient to remove mood entries, journal entries, medication
    // reminders, and current-state consent preferences in one step.
    await step.run("delete-user-and-cascaded-data", async () => {
      await db.user.delete({ where: { id: userId } });
    });

    await step.run("finalize-deletion", async () => {
      await db.dsarRequest.update({
        where: { id: dsarRequestId },
        data: { status: "COMPLETED", completedAt: new Date() },
      });
    });
  },
);
```

**The Verification** 

Register `dsarDeletion` in `src/app/api/inngest/route.ts`'s `functions` array (alongside `consentChanged` and `dsarExport`), trigger it for a test user via the Inngest Dev Server's "Trigger" button (or `inngest.send({ event: "dsar/deletion.requested", data: { dsarRequestId: "...", userId: "..." } })`), then confirm the cascade actually happened correctly:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT COUNT(*) FROM users WHERE id = 'test-user-1';"
```

Expect `0` — the user row itself is gone.

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT COUNT(*) FROM mood_entries WHERE \"userId\" = 'test-user-1';"

docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT COUNT(*) FROM journal_entries WHERE \"userId\" = 'test-user-1';"

docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT COUNT(*) FROM medication_reminders WHERE \"userId\" = 'test-user-1';"
```

Expect `0` for all three — confirming the `onDelete: Cascade` relations did their job.

Now, critically, confirm the consent ledger was **not** destroyed, only anonymized:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT category, status, \"userId\" FROM consent_ledger_entries WHERE \"userId\" = 'ANONYMIZED';"
```

You should see the deleted user's historical consent rows still present, with `userId` now reading `ANONYMIZED` rather than pointing at a deleted account — proof that the "right to be forgotten" was honored for personal content while the legally-required proof of historical consent survives, exactly as the DPIA's retention policy requires.

Finally, confirm the `DsarRequest` row itself reflects completion:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT status, \"completedAt\" FROM dsar_requests WHERE id = '...';"
```

Expect `status = COMPLETED` with a populated `completedAt` timestamp.

Commit:

```bash
git add -A
git commit -m "feat: add Inngest account deletion cascade job that anonymizes consent ledger and removes all other user data"
```

---

## Step 5.4 — User-facing Server Actions and dashboard trigger

### The Target
Two Server Actions — `requestDataExport` and `requestAccountDeletion` — plus a settings page letting a signed-in user actually trigger the workflows built in Steps 5.2 and 5.3, closing the loop from "backend job exists" to "a real user can invoke it."

### The Concept
Everything built so far in this Part is inert until a real user action can fire it. This step is the bridge: a button click in the browser needs to (1) create a `DsarRequest` row recording what was asked for, and (2) send the corresponding Inngest event — the same two-step "durable record, then fire-and-forget event" pattern established for consent changes in Part 4, applied here to export and deletion requests.

### The Implementation

**File: `src/lib/dsar.ts`**

```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { inngest } from "@/lib/inngest/client";
import { revalidatePath } from "next/cache";

export async function requestDataExport(): Promise<void> {
  const { userId: clerkId } = await auth();
  if (!clerkId) throw new Error("Not authenticated.");

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) throw new Error("User record not found.");

  const dsarRequest = await db.dsarRequest.create({
    data: { userId: user.id, type: "EXPORT" },
  });

  await inngest.send({
    event: "dsar/export.requested",
    data: { dsarRequestId: dsarRequest.id, userId: user.id },
  });

  revalidatePath("/dashboard/settings");
}

export async function requestAccountDeletion(): Promise<void> {
  const { userId: clerkId } = await auth();
  if (!clerkId) throw new Error("Not authenticated.");

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) throw new Error("User record not found.");

  const dsarRequest = await db.dsarRequest.create({
    data: { userId: user.id, type: "DELETION" },
  });

  await inngest.send({
    event: "dsar/deletion.requested",
    data: { dsarRequestId: dsarRequest.id, userId: user.id },
  });

  revalidatePath("/dashboard/settings");
}
```

**File: `src/app/dashboard/settings/page.tsx`**

```tsx
"use client";

import { requestDataExport, requestAccountDeletion } from "@/lib/dsar";
import { useState } from "react";

export default function SettingsPage() {
  const [confirmDelete, setConfirmDelete] = useState(false);

  return (
    <main className="min-h-screen bg-slate-950 px-6 py-10 text-slate-100">
      <div className="mx-auto max-w-xl space-y-8">
        <h1 className="text-2xl font-semibold">Your Data</h1>

        <section className="rounded-lg border border-slate-800 bg-slate-900 p-6">
          <h2 className="font-medium">Export your data</h2>
          <p className="mt-1 text-sm text-slate-400">
            Request a full copy of everything we hold about you — mood
            entries, journal entries, medication reminders, and your
            complete consent history.
          </p>
          <button
            onClick={() => requestDataExport()}
            className="mt-4 rounded-md border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium"
          >
            Request export
          </button>
        </section>

        <section className="rounded-lg border border-red-900/50 bg-slate-900 p-6">
          <h2 className="font-medium text-red-400">Delete your account</h2>
          <p className="mt-1 text-sm text-slate-400">
            This permanently deletes your mood entries, journal entries,
            and medication reminders. This cannot be undone.
          </p>
          {!confirmDelete ? (
            <button
              onClick={() => setConfirmDelete(true)}
              className="mt-4 rounded-md border border-red-800 bg-red-950 px-4 py-2 text-sm font-medium text-red-300"
            >
              Delete my account
            </button>
          ) : (
            <div className="mt-4 flex gap-3">
              <button
                onClick={() => requestAccountDeletion()}
                className="rounded-md border border-red-700 bg-red-900 px-4 py-2 text-sm font-medium text-red-100"
              >
                Yes, permanently delete everything
              </button>
              <button
                onClick={() => setConfirmDelete(false)}
                className="rounded-md border border-slate-700 bg-slate-800 px-4 py-2 text-sm font-medium"
              >
                Cancel
              </button>
            </div>
          )}
        </section>
      </div>
    </main>
  );
}
```

### The Verification

Load `/dashboard/settings`, click "Request export," and confirm in the Inngest Dev Server dashboard that a new `dsar/export.requested` event and function run appear, completing successfully. Then check the database:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT type, status FROM dsar_requests ORDER BY \"requestedAt\" DESC LIMIT 1;"
```

Expect `type = EXPORT`, `status = COMPLETED`. Repeat with the deletion flow on a disposable test account, confirming the same end-to-end path as verified manually in Step 5.3.

Commit:

```bash
git add -A
git commit -m "feat: add user-facing Server Actions and settings page for DSAR export and account deletion"
```
