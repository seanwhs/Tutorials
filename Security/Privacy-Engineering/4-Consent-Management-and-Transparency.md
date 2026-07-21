# Part 4: Consent Management & Transparency

## 4.0 Where we are on the map

Part 2 gave us a `consent_preferences` table representing the *current* state of a user's consent choices, constrained by the `ConsentCategory` enum [4]. But "current state only" has a critical gap: if a user disputes what they agreed to, or a regulator asks "prove this user consented to X on this date," a table that only holds the latest value has already destroyed the evidence of every prior state. Part 4 fixes this by introducing a dedicated, **append-only consent ledger** — a table where rows are only ever added, never edited or deleted — sitting alongside the mutable preferences table, feeding the downstream side effects (email/notification stub, research opt-in sync, audit log entries) shown in the target architecture [2].

By the end of Part 4 you will have:
1. An append-only `ConsentLedgerEntry` table recording every consent change ever made, immutably.
2. Server Actions that write to the ledger first, then update the current-state cache — never the other way around.
3. A consent-management UI deliberately designed against "dark patterns" (manipulative UI tricks that nudge users toward less privacy-protective choices).
4. An Inngest consumer — our first use of Inngest in this series — that reacts to consent-change events and drives the downstream side effects named in the architecture diagram [2].

---

## Step 4.1 — The append-only consent ledger

### The Target
A new `ConsentLedgerEntry` Prisma model, structurally prevented from ever being updated or deleted by application code.

### The Concept
Think of a bank statement versus a whiteboard. A whiteboard shows only the current balance — erase it, write a new number, and the old value is gone forever. A bank statement, by contrast, lists every transaction in sequence; even if your balance today is wrong, you can reconstruct exactly how you got there. Our `consent_preferences` table (Part 2) is the whiteboard — fast to read, but destructive on every update. The ledger we're building now is the bank statement: we never `UPDATE` or `DELETE` a row in it, only ever `INSERT`.

### The Implementation

**File: `prisma/schema.prisma`** (append)

```prisma
// Append-only. No code path in this application is permitted to UPDATE
// or DELETE a row here — enforced by convention in our Server Actions
// (Step 4.2) and, in a production system, by a database-level REVOKE of
// UPDATE/DELETE privileges on this table for the application's DB role.
model ConsentLedgerEntry {
  id         String          @id @default(cuid())
  userId     String
  user       User            @relation(fields: [userId], references: [id], onDelete: Cascade)
  category   ConsentCategory
  status     ConsentStatus
  // Captured verbatim at the moment of consent — NOT looked up later —
  // because the legal text a user agreed to may itself change over time.
  policyVersion String
  recordedAt DateTime        @default(now())

  @@map("consent_ledger_entries")
}
```

```bash
npm run db:migrate -- --name add_consent_ledger
```

### The Verification

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "\d consent_ledger_entries"
```

Confirm the table exists with all five data columns. Commit:

```bash
git add -A
git commit -m "feat: add append-only consent ledger table"
```

---

## Step 4.2 — Server Action: recording consent (ledger-first)

### The Target
A single Server Action, `updateConsent`, that writes to the ledger *before* touching the current-state cache — so the two can never drift out of sync with the ledger missing an entry.

### The Implementation

**File: `src/lib/consent.ts`**

```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { ConsentCategory, ConsentStatus } from "@prisma/client";
import { revalidatePath } from "next/cache";

const CURRENT_POLICY_VERSION = "2026-07-21-v1";

export async function updateConsent(
  category: ConsentCategory,
  status: ConsentStatus,
): Promise<void> {
  const { userId: clerkId } = await auth();
  if (!clerkId) throw new Error("Not authenticated.");

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) throw new Error("User record not found.");

  // Ledger write happens FIRST, inside the same transaction as the
  // current-state upsert, so it is impossible for one to succeed
  // without the other — the ledger can never silently miss an entry
  // that the current-state table actually reflects.
  await db.$transaction([
    db.consentLedgerEntry.create({
      data: { userId: user.id, category, status, policyVersion: CURRENT_POLICY_VERSION },
    }),
    db.consentPreference.upsert({
      where: { userId_category: { userId: user.id, category } },
      update: { status },
      create: { userId: user.id, category, status },
    }),
  ]);

  revalidatePath("/dashboard/consent");
}
```

### The Verification

Call `updateConsent("JOURNALING", "GRANTED")` then revoke it, and confirm both rows accumulate correctly:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "SELECT category, status, \"recordedAt\" FROM consent_ledger_entries ORDER BY \"recordedAt\";"
```

You should see **two** ledger rows (grant, then revoke) but only **one** current `consent_preferences` row reflecting the latest state — proving the ledger preserves history the cache discards.

```bash
git add -A
git commit -m "feat: add ledger-first consent update Server Action"
```

---

## Step 4.3 — An anti-dark-pattern consent UI

### The Target
A consent screen where every category defaults to **unchecked**, toggles are visually equal in weight (no "Accept All" button styled larger than "Reject"), and each category is explained in plain language before the user decides.

### The Implementation

**File: `src/app/dashboard/consent/page.tsx`**

```tsx
"use client";

import { useState } from "react";
import { updateConsent } from "@/lib/consent";
import { ConsentCategory, ConsentStatus } from "@prisma/client";

const CATEGORIES: { key: ConsentCategory; label: string; description: string }[] = [
  { key: "MOOD_TRACKING", label: "Mood Tracking", description: "Store your daily mood scores and notes." },
  { key: "JOURNALING", label: "Journaling", description: "Store your free-text journal entries." },
  { key: "MEDICATION_REMINDERS", label: "Medication Reminders", description: "Store medication names and schedules." },
  { key: "ANONYMIZED_RESEARCH", label: "Anonymized Research", description: "Use anonymized, aggregated data for research. Fully optional." },
  { key: "EMAIL_REMINDERS", label: "Email Reminders", description: "Send reminder emails. Fully optional." },
];

export default function ConsentPage() {
  // Every category starts FALSE — opt-in only, never pre-checked.
  const [state, setState] = useState<Record<string, boolean>>({});

  async function handleToggle(category: ConsentCategory, next: boolean) {
    setState((s) => ({ ...s, [category]: next }));
    await updateConsent(category, next ? ConsentStatus.GRANTED : ConsentStatus.REVOKED);
  }

  return (
    <main className="min-h-screen bg-slate-950 px-6 py-10 text-slate-100">
      <div className="mx-auto max-w-xl space-y-6">
        <h1 className="text-2xl font-semibold">Your Consent Preferences</h1>
        <p className="text-slate-400">
          Each choice below is independent. Nothing is pre-selected. You can change your mind at any time.
        </p>
        {CATEGORIES.map((c) => (
          <div key={c.key} className="flex items-center justify-between rounded-lg border border-slate-800 bg-slate-900 p-4">
            <div>
              <p className="font-medium">{c.label}</p>
              <p className="text-sm text-slate-400">{c.description}</p>
            </div>
            {/* Both options rendered with EQUAL visual weight — no color
                or size bias toward "grant" over "revoke". */}
            <button
              onClick={() => handleToggle(c.key, !state[c.key])}
              className={`rounded-md border px-4 py-2 text-sm font-medium ${
                state[c.key] ? "border-slate-500 bg-slate-700" : "border-slate-700 bg-slate-800"
              }`}
            >
              {state[c.key] ? "Granted" : "Not granted"}
            </button>
          </div>
        ))}
      </div>
    </main>
  );
}
```

### The Verification

Load `/dashboard/consent`, confirm every toggle reads "Not granted" on first load (no pre-checked boxes), toggle one on and off, and confirm the ledger accumulates a row per click via the query from Step 4.2.

---

## Step 4.4 — Inngest: reacting to consent changes

### The Target
Our first Inngest function, triggered whenever a consent change is recorded, driving the downstream side effects shown in the architecture diagram: audit log entries and research opt-in sync [2].

### The Implementation

```bash
npm install inngest
```

**File: `src/lib/inngest/client.ts`**

```typescript
import { Inngest } from "inngest";
export const inngest = new Inngest({ id: "greymatter-mindfulness-log" });
```

**File: `src/lib/inngest/functions/consent-changed.ts`** 

```typescript
import { inngest } from "@/lib/inngest/client";

// Fired every time updateConsent() runs. Kept separate from the
// synchronous Server Action so slow/unreliable downstream work (e.g.,
// syncing a research opt-in flag to an external system) never blocks
// the user's own UI, and automatically retries if it fails — matching
// the "consent-change reaction jobs" box in the target architecture [2].
export const consentChanged = inngest.createFunction(
  { id: "consent-changed" },
  { event: "consent/changed" },
  async ({ event, step }) => {
    // Step 1: audit log entry. This satisfies the DPIA's requirement
    // that any consent-related event be recorded and traceable [1][5].
    await step.run("write-audit-log", async () => {
      console.log(
        `[AUDIT] consent ${event.data.category} -> ${event.data.status} ` +
          `for user ${event.data.userId} at ${new Date().toISOString()}`,
      );
    });

    // Step 2: category-specific downstream effect. Only the
    // ANONYMIZED_RESEARCH category needs to propagate to a hypothetical
    // external research pipeline — every other category simply gets the
    // audit log entry above and stops there. This keeps the function
    // honest about what actually needs to happen, rather than firing
    // unnecessary side effects for categories that don't need them.
    if (event.data.category === "ANONYMIZED_RESEARCH") {
      await step.run("sync-research-opt-in", async () => {
        // In a real system this would call an external API or update a
        // separate research-data pipeline's opt-in flag. We stub it
        // here with a log statement — the important architectural
        // point is WHERE this side effect lives (an independently
        // retryable Inngest step), not the stub implementation itself.
        console.log(
          `[RESEARCH_SYNC] user ${event.data.userId} research opt-in status=${event.data.status}`,
        );
      });
    }

    // Step 3: email/notification stub, matching the "email/notification
    // stub" box in the downstream side effects list [2]. Only fires for
    // the EMAIL_REMINDERS category, and only on GRANTED — we don't want
    // to send a "you'll now get emails" email when someone just revoked
    // that very permission.
    if (event.data.category === "EMAIL_REMINDERS" && event.data.status === "GRANTED") {
      await step.run("send-confirmation-email-stub", async () => {
        console.log(
          `[EMAIL_STUB] would send reminder-opt-in confirmation to user ${event.data.userId}`,
        );
      });
    }
  },
);
```

Now we need to actually **fire** the `consent/changed` event from our `updateConsent` Server Action — an Inngest function does nothing until something sends the event it's listening for. We also need to register the function with an API route so Inngest's infrastructure can discover and invoke it.

**File: `src/lib/consent.ts`** (update — add the Inngest send call)

```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { ConsentCategory, ConsentStatus } from "@prisma/client";
import { revalidatePath } from "next/cache";
import { inngest } from "@/lib/inngest/client";

const CURRENT_POLICY_VERSION = "2026-07-21-v1";

export async function updateConsent(
  category: ConsentCategory,
  status: ConsentStatus,
): Promise<void> {
  const { userId: clerkId } = await auth();
  if (!clerkId) throw new Error("Not authenticated.");

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) throw new Error("User record not found.");

  // Ledger write happens FIRST, inside the same transaction as the
  // current-state upsert, so the ledger can never miss an entry that
  // the current-state table reflects [2].
  await db.$transaction([
    db.consentLedgerEntry.create({
      data: { userId: user.id, category, status, policyVersion: CURRENT_POLICY_VERSION },
    }),
    db.consentPreference.upsert({
      where: { userId_category: { userId: user.id, category } },
      update: { status },
      create: { userId: user.id, category, status },
    }),
  ]);

  // Fire the event AFTER the database transaction commits successfully.
  // This ordering matters: we never want Inngest reacting to a consent
  // change that the database ultimately failed to persist.
  await inngest.send({
    event: "consent/changed",
    data: { userId: user.id, category, status },
  });

  revalidatePath("/dashboard/consent");
}
```

**File: `src/app/api/inngest/route.ts`**

```typescript
// src/app/api/inngest/route.ts
//
// This route is how Inngest's infrastructure discovers and invokes our
// functions. Every Inngest function in the project must be listed in
// the `functions` array here, or it will never actually run.

import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest/client";
import { consentChanged } from "@/lib/inngest/functions/consent-changed";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [consentChanged],
});
```

### The Verification

Install and run the Inngest Dev Server, which provides a local dashboard for watching functions execute in real time:

```bash
npx inngest-cli@latest dev
```

With `npm run dev` also running, open the Inngest Dev Server UI (typically `http://localhost:8288`). Trigger a consent change through your `/dashboard/consent` page (built in Step 4.3) by toggling any category, then check the Dev Server dashboard — you should see a new `consent/changed` event listed, with the `consent-changed` function run underneath it showing each step (`write-audit-log`, and conditionally `sync-research-opt-in` or `send-confirmation-email-stub`) completing successfully.

Toggle `ANONYMIZED_RESEARCH` on specifically, and confirm the `sync-research-opt-in` step appears in the run — proving the category-specific branching logic works. Then check your terminal running `npm run dev` for the corresponding `[AUDIT]` and `[RESEARCH_SYNC]` log lines.

Commit:

```bash
git add -A
git commit -m "feat: add Inngest consumer reacting to consent changes with audit logging and research sync stub"
```

---

## Part 4 Reference Section: Why Ledger-Writes-Then-Event, Not Event-Then-Ledger-Write

A subtle but important ordering decision was made in `updateConsent`: the database transaction commits *before* the Inngest event is sent, never the reverse. It's worth spelling out why, since it's a pattern that generalizes far beyond this one function.

If we sent the event first and the database write failed afterward, Inngest's downstream consumer would react to a consent change that never actually happened — writing an audit log entry, or worse, syncing a "research opt-in granted" flag to an external system, for a change that doesn't exist in our own source of truth. That's a direct violation of exactly the risk the DPIA is trying to prevent: "a user's consent choice is silently ignored or not honored" [1][5] — except inverted, where a *non-existent* choice gets honored instead. Committing the database transaction first guarantees the ledger (our legal source of truth) and the event stream can never diverge in that direction. The small remaining risk — the database commits successfully but the `inngest.send()` call itself fails due to a network blip — is a "fire-and-forget" gap acceptable at this stage of the build; production systems typically close it with a transactional outbox pattern, which is a natural extension exercise once you're comfortable with the pattern shown here.
