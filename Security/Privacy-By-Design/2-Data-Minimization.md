# Part 2: Data Minimization & Collection Patterns

---

## 2.1 The Core Principle: "If You Don't Store It, You Can't Leak It"

**Analogy:** A doctor's office that keeps every patient's full medical history, insurance number, and home address in an unlocked filing cabinet in the waiting room is running an enormous, unnecessary risk — even if nobody ever actually opens that cabinet. The **safest filing cabinet is the one that was never created** because the data never needed to be stored in the first place. Every field you *don't* collect is a field that can never be breached, subpoenaed, misused, or forgotten-to-be-deleted.

Data minimization (GDPR Art. 5(1)(c)) is the discipline of collecting the smallest possible set of fields, retaining them for the shortest possible time, and deriving identity in the least identifying possible form. In Part 1, our DPIA already forced us to write a necessity justification for every field. Part 2 turns those justifications into enforced schema and code, and introduces three concrete techniques:

| Technique | What It Does | Where We Use It |
|---|---|---|
| **Schema-level minimization** | Simply never create the column | `schema.ts` design (2.2) |
| **Salt-and-hash pipelines** | Store a one-way derived value instead of the raw identifier | Hashing IP addresses (2.3) |
| **Data masking** | Show only a redacted/partial view of a value, even to authorized viewers, unless full access is explicitly required | Admin/UI previews (2.4) |
| **Ephemerality (TTL)** | Automatically delete data after a defined lifespan — no human has to remember to do it | Security event sweeps (2.5) |

---

## 2.2 The Target: Building the Minimized `schema.ts`

**The Concept:** We now write the real Drizzle schema — but every table decision below is a direct, traceable answer to a row in our Part 1 DPIA Data Inventory (`docs/dpia/dpia-mindfullog-v1.md`, Section 2). Nothing appears here "because we might need it later." Speculative fields are the #1 source of privacy debt.

**Design decisions we're locking in, and why:**

1. **Pseudonymous internal ID, not Clerk ID, as our foreign-key anchor.** We store a locally-generated UUID (`id`) as the primary key across our own tables, rather than scattering Clerk's `user_id` string across a dozen tables. If we ever need to sever the link to Clerk (e.g., during deletion in Part 5), we only need to break *one* link, in one row, not rewrite foreign keys everywhere.
2. **No `full_name` column.** Per the DPIA, display name is optional and not core-function-necessary; where used, it lives in Clerk itself (already collected at signup), not duplicated in our own database. Duplicating identity fields across systems only multiplies the number of places a breach can occur.
3. **Mood notes, journal text, and medication labels stored as `bytea` (ciphertext), never `text`.** We build the actual encryption pipeline in Part 3 — but the schema-level decision to make plaintext storage *impossible* (by typing the column as binary from day one) happens now. This is Principle 3 (Privacy Embedded into Design): a future engineer literally cannot accidentally write plaintext into this column without the type system complaining.
4. **Security-relevant metadata (IP addresses) lives in a dedicated, short-lived table with a hard `expiresAt` column** — never mixed into the permanent `users` table. Per the DPIA risk table, security logs must auto-expire in 30 days.

### The Implementation

**File: `src/db/schema.ts`**
```typescript
import {
  pgTable,
  uuid,
  varchar,
  smallint,
  customType,
  timestamp,
  boolean,
  pgEnum,
  index,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

// Drizzle doesn't ship a native `bytea` helper out of the box, so we define
// a small custom type. This forces every encrypted column to be explicitly
// typed as raw bytes (ciphertext) rather than `text` — making "oops I wrote
// plaintext to this column" a type error, not a runtime mistake.
const bytea = customType<{ data: Buffer }>({
  dataType() {
    return "bytea";
  },
});

/**
 * users
 * -----
 * The anchor table. `id` is OUR pseudonymous identifier — generated locally,
 * never derived from or equal to Clerk's user ID. `clerkUserId` is stored
 * ONLY here, in exactly one place, so a future deletion (Part 5) severs the
 * link to Clerk by clearing a single column in a single row, rather than
 * hunting for Clerk IDs scattered across every table in the database.
 */
export const users = pgTable("users", {
  id: uuid("id").defaultRandom().primaryKey(),

  // Unique, but deliberately NOT the primary key — see design decision #1.
  clerkUserId: varchar("clerk_user_id", { length: 255 }).notNull().unique(),

  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),

  // Soft "tombstone" marker used by the deletion pipeline in Part 5.
  // Defaults to false — nothing is ever considered deleted until an
  // explicit, audited action sets this. (Principle 2: Default Setting.)
  isDeleted: boolean("is_deleted").notNull().default(false),
});

/**
 * mood_entries
 * ------------
 * `score` is a small integer (1-10) — not sensitive on its own, stored in
 * plaintext per the DPIA. `noteCiphertext` is the ONLY place a user's free
 * text about their mood lives, and it is typed as `bytea`, making plaintext
 * storage a compile-time impossibility. Full encryption logic lands in
 * Part 3 — for now this column simply cannot accept a JS string.
 */
export const moodEntries = pgTable("mood_entries", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  score: smallint("score").notNull(),
  noteCiphertext: bytea("note_ciphertext"), // nullable: notes are optional
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

/**
 * journal_entries
 * ---------------
 * Same encryption-by-schema pattern as mood_entries. Notice there is no
 * `title` or `tags` column — the DPIA's Data Inventory only justified the
 * entry body itself. If a future feature genuinely needs tagging, THAT
 * feature's first step is a DPIA update, not a migration.
 */
export const journalEntries = pgTable("journal_entries", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  bodyCiphertext: bytea("body_ciphertext").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

/**
 * medication_reminders
 * --------------------
 * `labelCiphertext` covers things like "Sertraline 50mg" — clearly health
 * data. `remindAt` is a plain timestamp; scheduling metadata alone isn't
 * sensitive without the label, but we still scope access to it strictly via
 * RBAC/ABAC in Part 3.
 */
export const medicationReminders = pgTable("medication_reminders", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  labelCiphertext: bytea("label_ciphertext").notNull(),
  remindAt: timestamp("remind_at", { withTimezone: true }).notNull(),
  createdAt: timestamp("created_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

// A Postgres ENUM constrains consent purposes to a known, reviewable set —
// preventing a typo'd or ad-hoc string like "marketingEmails2" from ever
// silently becoming a new, unreviewed consent category. Every value here
// must correspond to an entry in the DPIA's Legal Basis section (Part 1,
// Section 1.3.6) before it's added. This enum is fully used starting Part 4.
export const consentPurposeEnum = pgEnum("consent_purpose", [
  "product_analytics",
  "therapist_data_sharing",
  "marketing_emails",
]);

/**
 * consent_records
 * ---------------
 * Append-only by convention (enforced in Part 4 at the query layer): we
 * NEVER UPDATE a row here, we only INSERT a new one representing the
 * latest decision. This gives us a full audit trail of every consent
 * decision a user has ever made, satisfying Principle 6 (Visibility and
 * Transparency) and GDPR's burden-of-proof requirement for consent.
 */
export const consentRecords = pgTable("consent_records", {
  id: uuid("id").defaultRandom().primaryKey(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  purpose: consentPurposeEnum("purpose").notNull(),

  // Defaults to false at the APPLICATION layer (enforced in Part 4's insert
  // logic) — Postgres itself has no way to know "false is safer here" for
  // an INSERT statement that always supplies an explicit value, so this is
  // a case where the Section 1.5 rule is enforced in code, not SQL DEFAULT.
  granted: boolean("granted").notNull(),

  recordedAt: timestamp("recorded_at", { withTimezone: true })
    .defaultNow()
    .notNull(),
});

/**
 * security_events
 * ----------------
 * THE key ephemerality table for this Part. Per the DPIA, IP addresses
 * tied to login events are collected for fraud/abuse detection ONLY, under
 * "legitimate interest" — not for any product feature — and MUST be
 * auto-deleted after 30 days. We never store a raw IP; we store a
 * salted HMAC hash of it (Section 2.3), and we give every row an explicit
 * `expiresAt` timestamp that our Inngest sweep job (Section 2.5) uses to
 * find and delete rows whose time is up. The `index` on `expiresAt` makes
 * that sweep query fast even as this table grows to millions of rows.
 */
export const securityEvents = pgTable(
  "security_events",
  {
    id: uuid("id").defaultRandom().primaryKey(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),

    // Never the raw IP — see Section 2.3 for the hashing pipeline.
    ipHash: varchar("ip_hash", { length: 64 }).notNull(),

    eventType: varchar("event_type", { length: 32 }).notNull(), // e.g. "login_success", "login_failed"

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),

    // The entire point of this table: every row knows its own death date
    // at the moment it's born. Nothing here is "permanent by accident."
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  },
  (table) => ({
    expiresAtIdx: index("security_events_expires_at_idx").on(table.expiresAt),
  })
);

/**
 * Relations — these don't create SQL, they just teach Drizzle's query
 * builder how tables connect, so later code can write
 * db.query.users.findFirst({ with: { moodEntries: true } }) with full
 * type safety instead of hand-writing JOINs everywhere.
 */
export const usersRelations = relations(users, ({ many }) => ({
  moodEntries: many(moodEntries),
  journalEntries: many(journalEntries),
  medicationReminders: many(medicationReminders),
  consentRecords: many(consentRecords),
  securityEvents: many(securityEvents),
}));

export const moodEntriesRelations = relations(moodEntries, ({ one }) => ({
  user: one(users, { fields: [moodEntries.userId], references: [users.id] }),
}));

export const journalEntriesRelations = relations(journalEntries, ({ one }) => ({
  user: one(users, { fields: [journalEntries.userId], references: [users.id] }),
}));

export const medicationRemindersRelations = relations(
  medicationReminders,
  ({ one }) => ({
    user: one(users, {
      fields: [medicationReminders.userId],
      references: [users.id],
    }),
  })
);

export const consentRecordsRelations = relations(consentRecords, ({ one }) => ({
  user: one(users, {
    fields: [consentRecords.userId],
    references: [users.id],
  }),
}));

export const securityEventsRelations = relations(securityEvents, ({ one }) => ({
  user: one(users, {
    fields: [securityEvents.userId],
    references: [users.id],
  }),
}));
```

### The Verification

**Step 1 — Generate and run the migration**
```bash
npx drizzle-kit generate
```
This inspects `schema.ts` and produces a SQL migration file under `./drizzle`. Open it and manually confirm:
- `note_ciphertext`, `body_ciphertext`, and `label_ciphertext` are declared as `bytea`, **not** `text` or `varchar`.
- `is_deleted` and any boolean columns default to `false`.
- `security_events` has an index on `expires_at`.

```bash
npx drizzle-kit push
```
This applies the migration to your Neon database.

**Step 2 — Confirm in Neon's SQL console (or `psql`)**
```sql
\d mood_entries
```
Expected output should show `note_ciphertext | bytea |`. If you see `text` instead, stop and fix your schema before continuing — this is the exact bug Part 3's entire encryption layer depends on not existing.

**Step 3 — Attempt to violate the type system on purpose (this is the real test)**
```typescript
// scratch.ts — a throwaway file, do not commit
import { db } from "@/db";
import { moodEntries } from "@/db/schema";

async function tryToBreakIt() {
  await db.insert(moodEntries).values({
    userId: "00000000-0000-0000-0000-000000000000",
    score: 7,
    // @ts-expect-error — this line MUST fail to type-check.
    // If it does NOT produce a TypeScript error, our schema is broken.
    noteCiphertext: "I feel okay today",
  });
}
```
Run `npx tsc --noEmit` — you should see a type error on that line. If you *don't* see an error, the `bytea` custom type isn't wired correctly, and plaintext could silently leak into that column. Delete this scratch file once confirmed.

---

## 2.3 The Target: A Salt-and-Hash Pipeline for the IP Address

**The Concept:** We need IP addresses for one narrow purpose — detecting repeated failed logins from the same source (fraud/abuse detection) — but we must never store them in a reversible form. A **hash** is a one-way meat grinder: you can turn a sausage into ground meat, but you can never turn ground meat back into the original sausage. A **salt** is a secret ingredient mixed in before grinding, so that even if two different users have the exact same IP address, their ground-meat outputs look completely different — preventing an attacker from pre-computing a lookup table of "common IP → hash" pairs (called a rainbow table).

**Why not just encrypt the IP instead of hashing it?** Encryption is reversible (by design — that's the whole point of Part 3's FLE layer for journal text, which authorized code *needs* to read back). But for this specific use case, we never need to recover the original IP — we only ever need to compare "is this the same IP as a previous failed login?" A one-way hash is strictly more secure for this exact requirement, because there is no key anywhere in the system that could ever reverse it, even under a full compromise.

### The Implementation

**File: `src/lib/security/ip-hash.ts`**
```typescript
import { createHmac } from "node:crypto";

// This is a SEPARATE secret from any encryption key we build in Part 3 —
// deliberately scoped to exactly one purpose. Never reuse a cryptographic
// secret across unrelated concerns; if this secret were ever rotated or
// leaked, the blast radius should be limited to "IP hash comparisons stop
// matching historical rows," not "someone can now decrypt journal entries."
const IP_HASH_SECRET = process.env.IP_HASH_SECRET;

if (!IP_HASH_SECRET) {
  // Fail loudly at startup rather than silently hashing with `undefined`,
  // which would produce a predictable, insecure hash for every request.
  throw new Error(
    "IP_HASH_SECRET is not set. Refusing to start — see .env.local.example."
  );
}

/**
 * Produces a salted, one-way HMAC-SHA256 hash of an IP address.
 * - Deterministic: the same IP always hashes to the same value, so we CAN
 *   still detect "5 failed logins from the same source in 10 minutes."
 * - Irreversible: there is no operation that recovers the original IP from
 *   this output, even with full knowledge of the code.
 * - Salted via HMAC's secret key: prevents rainbow-table attacks that a
 *   plain, unsalted SHA-256 hash would be vulnerable to.
 */
export function hashIpAddress(rawIp: string): string {
  return createHmac("sha256", IP_HASH_SECRET!).update(rawIp).digest("hex");
}
# --- existing vars from Part 1 remain unchanged above ---

# --- IP hashing secret (Part 2) ---
# Generate with: openssl rand -hex 32
IP_HASH_SECRET=replace_with_a_64_character_hex_string_from_openssl
```

Generate a real value rather than typing a placeholder:
```bash
openssl rand -hex 32
```
Copy the output into `.env.local` as the value for `IP_HASH_SECRET`.

**File: `src/lib/security/record-login-event.ts`**
```typescript
import { db } from "@/db";
import { securityEvents } from "@/db/schema";
import { hashIpAddress } from "./ip-hash";

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000;

/**
 * Records a login-related security event (success or failure) tied to an
 * internal user ID, storing only a salted hash of the source IP — never
 * the raw address — and stamping an explicit expiry 30 days out, per the
 * DPIA's Risk Assessment (Section 4) and Data Inventory retention column
 * (Section 2) from Part 1.
 */
export async function recordLoginEvent(params: {
  internalUserId: string;
  rawIp: string;
  eventType: "login_success" | "login_failed";
}): Promise<void> {
  const { internalUserId, rawIp, eventType } = params;

  await db.insert(securityEvents).values({
    userId: internalUserId,
    ipHash: hashIpAddress(rawIp), // raw IP is used ONLY in-memory, here, and discarded
    eventType,
    expiresAt: new Date(Date.now() + THIRTY_DAYS_MS),
  });
}
```

Notice the comment on `ipHash`: the raw IP string exists in memory for a single function call and is never assigned to any variable that outlives this function, never logged, and never passed anywhere else. This is a deliberate coding discipline — the raw value's *entire lifetime* in our system is milliseconds.

### The Verification

**Step 1 — Unit-test the hash function's core properties**

**File: `src/lib/security/ip-hash.test.ts`**
```typescript
import { describe, expect, it } from "vitest";
import { hashIpAddress } from "./ip-hash";

describe("hashIpAddress", () => {
  it("produces the same hash for the same IP (deterministic)", () => {
    const a = hashIpAddress("203.0.113.42");
    const b = hashIpAddress("203.0.113.42");
    expect(a).toBe(b);
  });

  it("produces different hashes for different IPs", () => {
    const a = hashIpAddress("203.0.113.42");
    const b = hashIpAddress("203.0.113.43");
    expect(a).not.toBe(b);
  });

  it("never returns the raw IP substring in its output", () => {
    const hash = hashIpAddress("203.0.113.42");
    expect(hash).not.toContain("203.0.113.42");
  });

  it("produces a 64-character hex string (SHA-256 output length)", () => {
    const hash = hashIpAddress("203.0.113.42");
    expect(hash).toMatch(/^[a-f0-9]{64}$/);
  });
});
```
```bash
npm install -D vitest
npx vitest run src/lib/security/ip-hash.test.ts
```
All four assertions should pass. The third test is the one that matters most philosophically: it's a machine-checked guarantee that our "one-way grinder" never accidentally leaks the raw ingredient back out in its output.

**Step 2 — End-to-end check against the real database**
```sql
-- Run in Neon's SQL console after triggering one real login via the app
SELECT ip_hash, event_type, expires_at FROM security_events ORDER BY created_at DESC LIMIT 1;
```
Confirm `ip_hash` is a 64-character hex string, never a dotted-quad IP, and that `expires_at` is roughly 30 days in the future.

---

## 2.4 The Target: Data Masking for Support/Admin Views

**The Concept:** Sometimes an authorized person (e.g., a support engineer helping a user with a bug) genuinely needs to see *that a field has a value*, without needing to see its *full contents*. **Masking** is like a bank statement that shows "····· ····· ····· 4242" for a card number — enough to confirm identity, not enough to commit fraud. This is distinct from encryption (Part 3): masking is a *display-time* transformation applied after data is already decrypted for an authorized viewer, reducing exposure even to people who technically passed the access-control check.

**Why this matters even with FLE already planned for Part 3:** Encryption controls *who can decrypt*. Masking controls *how much of the decrypted value is actually shown*, adding a second, independent layer — because "authorized to view" and "needs to view everything" are not the same thing. A support engineer resolving a login issue needs to know an email is `j***@example.com`, not the fully unmasked address.

### The Implementation

**File: `src/lib/security/mask.ts`**
```typescript
/**
 * Masks an email address for display, preserving enough structure to be
 * recognizable/useful (first character + domain) without exposing the
 * full local part. Used anywhere we render user data to admin/support
 * tooling where full identity confirmation isn't required.
 */
export function maskEmail(email: string): string {
  const [localPart, domain] = email.split("@");
  if (!domain || localPart.length === 0) return "***";

  const visibleChars = localPart.slice(0, 1);
  const maskedRemainder = "*".repeat(Math.max(localPart.length - 1, 3));
  return `${visibleChars}${maskedRemainder}@${domain}`;
}

/**
 * Masks free-text content (e.g., a journal entry snippet) down to a fixed
 * short preview, used ONLY in admin/support contexts that need to confirm
 * "yes, this entry has content" without displaying the sensitive content
 * itself. Note: this function assumes it is receiving ALREADY DECRYPTED
 * plaintext — it is a display-layer control, not a replacement for the
 * encryption boundary built in Part 3.
 */
export function maskFreeText(plaintext: string, visibleChars = 3): string {
  if (plaintext.length <= visibleChars) return "*".repeat(plaintext.length);
  return `${plaintext.slice(0, visibleChars)}${"*".repeat(12)} (redacted, ${plaintext.length} chars total)`;
}
```

### The Verification

```bash
npx tsx -e "
import { maskEmail, maskFreeText } from './src/lib/security/mask';
console.log(maskEmail('jane.doe@example.com'));
console.log(maskFreeText('Today I felt anxious about the presentation but pushed through it.'));
"
```
Expected output:
```
j*******@example.com
Tod************ (redacted, 68 chars total)
```
Confirm neither output contains recognizable sensitive substrings from the input — this is your manual proof that masking is actually reducing information, not just cosmetically truncating it.

---

## 2.5 The Target: Ephemeral Data — A TTL Sweep via Inngest Scheduled Function

**The Concept:** Declaring `expiresAt` on a row (Section 2.2) is a promise, not an enforcement mechanism — Postgres doesn't delete rows just because a timestamp column says it should. We need an active process that periodically asks "who's overdue?" and removes them. Think of this like a library's automated system that doesn't just print a due date on your book — it actively runs a nightly job canceling accounts and sending notices for anything not returned.

**Why Inngest instead of a simple `cron` script?** A bare cron job on a single server is a single point of failure — if that box is down during the scheduled window, the sweep silently never runs, and nobody notices until an audit. Inngest's scheduled functions are managed or self-hosted+retried: if a run fails, Inngest retries it with backoff and surfaces the failure in its dashboard, giving us actual visibility into "did our retention policy actually execute" rather than blind faith in a crontab.

### The Implementation

**File: `src/inngest/functions/security-event-ttl-sweep.ts`**
```typescript
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import { securityEvents } from "@/db/schema";
import { lt } from "drizzle-orm";

/**
 * Runs once daily. Deletes every security_events row whose expiresAt has
 * already passed. This is the ENFORCEMENT half of the promise made by the
 * `expiresAt` column in schema.ts — without this function running reliably,
 * that column is just a suggestion, not a retention guarantee.
 */
export const securityEventTtlSweep = inngest.createFunction(
  { id: "security-event-ttl-sweep" },
  { cron: "0 3 * * *" }, // 03:00 UTC daily — low-traffic window
  async ({ step }) => {
    // Wrapping the deletion in `step.run` gives us a durable checkpoint:
    // if this step succeeds but a LATER step in a more complex function
    // were to fail, Inngest will not re-run this step on retry — it
    // remembers the result. For this simple function it also gives us
    // automatic logging/observability in the Inngest dashboard for free.
    const deletedCount = await step.run("delete-expired-security-events", async () => {
      const result = await db
        .delete(securityEvents)
        .where(lt(securityEvents.expiresAt, new Date()))
        .returning({ id: securityEvents.id });

      return result.length;
    });

    return { deletedCount };
  }
);
```

**File: `src/app/api/inngest/route.ts`** (update — register the new function)
```typescript
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { securityEventTtlSweep } from "@/inngest/functions/security-event-ttl-sweep";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    securityEventTtlSweep, // Part 2: enforces the 30-day IP-hash retention policy
  ],
});
```

### The Verification

**Step 1 — Manually trigger the function in the local Inngest Dev Server**
```bash
npx inngest-cli@latest dev
```
Visit `http://localhost:8288`, find `security-event-ttl-sweep` in the Functions list, and click **"Invoke"** to run it on demand (bypassing the cron schedule for testing).

**Step 2 — Seed an already-expired row to prove the sweep actually deletes something**
```sql
-- Run in Neon's SQL console
INSERT INTO security_events (id, user_id, ip_hash, event_type, created_at, expires_at)
VALUES (
  gen_random_uuid(),
  (SELECT id FROM users LIMIT 1),
  'deadbeef00000000000000000000000000000000000000000000000000000000',
  'login_failed',
  now() - interval '40 days',
  now() - interval '10 days'  -- already expired 10 days ago
);
```

**Step 3 — Re-invoke the function and confirm deletion**

After invoking again from the Inngest dashboard, check the run's output — it should report `{ "deletedCount": 1 }` (or more, if other expired rows exist). Then confirm directly:
```sql
SELECT count(*) FROM security_events WHERE expires_at < now();
-- expected: 0
```

If this returns `0`, your retention policy is not just documented — it is **actively enforced by running code**, verified end-to-end: a row was created with an expired timestamp, a scheduled function found it, deleted it, and a follow-up query confirms it's gone. This is the difference between a DPIA that says "30-day TTL" on paper and a system that actually honors that promise every single night without a human remembering to run anything.

**Step 4 — Confirm the schedule itself is correctly registered (not just manually invokable)**

```bash
# In the Inngest Dev Server UI (localhost:8288), open the function detail
# page for "security-event-ttl-sweep" and check the "Triggers" tab.
```
You should see `Cron: 0 3 * * *` listed as a trigger, alongside the manual "Invoke" option you used for testing. This confirms that in production (once deployed with real Inngest keys), this sweep will run automatically every night at 03:00 UTC without any further action from you.

---

## Part 2 — Reference Section: Deep Dives

*(Read now for depth, or skip ahead to Part 3 and return later.)*

### Reference 2.A — Hashing vs. Encryption vs. Tokenization: Choosing the Right Tool

This is one of the most commonly confused trios in privacy engineering. All three "hide" data, but they have fundamentally different reversibility guarantees, and picking the wrong one for a given field is a real, recurring production mistake.

| Technique | Reversible? | Use When | Example in MindfulLog |
|---|---|---|---|
| **Hashing** (one-way, e.g., HMAC-SHA256) | No — never, by anyone, even with any key | You only ever need to *compare* values for equality, never recover the original | IP addresses in `security_events` (Section 2.3) |
| **Encryption** (symmetric, e.g., AES-GCM) | Yes — with the correct key | You need to *read the original value back* for legitimate authorized use | Journal entries, mood notes (Part 3) |
| **Tokenization** | Yes — but only via a separate lookup service/vault, not mathematically | You need a stable reference to swap in and out of systems (e.g., payment tokens) without those systems ever seeing the real value | Not used in MindfulLog directly, but common for card numbers, SSNs shared across microservices |

**The decision rule to memorize:** Ask *"Will any legitimate part of my system ever need to see the original value again?"* If the answer is **no**, hash it. If the answer is **yes, but only in this one service**, encrypt it. If the answer is **yes, but many independent services need to reference it without each holding the decryption key**, tokenize it via a dedicated vault.

### Reference 2.B — Why `expiresAt` Belongs on the Row, Not in a Config File

A tempting shortcut is to skip the `expiresAt` column entirely and instead write a sweep query like `WHERE created_at < now() - interval '30 days'`, with "30 days" hardcoded in the Inngest function. We deliberately rejected this pattern. Here's why it matters:

1. **Auditability:** With `expiresAt` stored per-row, an auditor (or your future self) can query "when is *this specific row* scheduled to die?" without needing to know which sweep function governs it or what its current configured interval is.
2. **Policy changes don't corrupt history:** If MindfulLog later decides security logs should retain for 14 days instead of 30 (a real, foreseeable policy change), a hardcoded-interval query retroactively reinterprets *every existing row* under the new rule the instant you change one constant. Storing `expiresAt` explicitly at write-time means existing rows keep the retention promise they were created under, while only new rows pick up the new policy — which is usually the legally and ethically correct behavior (you generally cannot silently shorten a promise already made, and shouldn't silently lengthen it either without new justification).
3. **Decoupling policy from enforcement:** The sweep function's *only* job becomes "find and delete anything where `expiresAt < now()`" — an extremely simple, hard-to-get-wrong query that works identically regardless of *why* a given row expires when it does. This single sweep pattern will be reused, unmodified, for other ephemeral tables in later parts (e.g., session-adjacent caches) — we are building a generic "any row with an `expiresAt` gets swept" capability, not a one-off script tied to security logs.

### Reference 2.C — The Cost of "Just in Case" Fields

Every field added to a schema "just in case it's useful later" carries a permanent, compounding cost, even if it's never populated:

- **DPIA burden:** Every field must be justified and re-reviewed (Part 1, Section 1.5's binding rule). An unused field with no justification is a compliance liability sitting in your schema, waiting to be found in an audit.
- **Breach surface:** A field with `NULL` in every row today can be populated by a bug, a well-meaning future engineer, or a scope-creeping feature tomorrow — and now it's live, unencrypted, unreviewed PII in production.
- **DSAR/deletion complexity:** Part 5's export and deletion engines must enumerate *every* column that might contain personal data. Speculative fields silently expand that surface area for a feature that may never ship.

**The rule of thumb this series follows:** if a field doesn't have a corresponding row in the DPIA's Data Inventory table *right now*, it does not get added to `schema.ts` *right now* — no exceptions, no "we'll clean it up later." This is Principle 1 (Proactive not Reactive) enforced at the literal keystroke level.

---

## Part 2 — Summary & What Carries Forward

By completing Part 2, your repository now contains:

- ✅ A fully minimized `src/db/schema.ts` — every column traceable to a DPIA justification, sensitive text columns typed as `bytea` to make plaintext storage a compile error
- ✅ `src/lib/security/ip-hash.ts` — a salted, one-way HMAC pipeline for IP addresses, with a passing unit test suite
- ✅ `src/lib/security/record-login-event.ts` — the only code path allowed to touch a raw IP address, and it does so for milliseconds
- ✅ `src/lib/security/mask.ts` — display-layer masking utilities for admin/support tooling
- ✅ `src/inngest/functions/security-event-ttl-sweep.ts` — a scheduled, durable, retry-safe enforcement of our 30-day retention promise, registered in `src/app/api/inngest/route.ts`

**What Part 3 inherits from here, directly:** the `bytea` columns (`noteCiphertext`, `bodyCiphertext`, `labelCiphertext`) currently sit empty/unused in practice — no code writes to them yet, because we have no encryption layer. Part 3 builds exactly that layer, and its very first verification step will be proving that a value written through it and read back matches the original, while the raw database row shows only unintelligible bytes. The generic "sweep anything with an expired `expiresAt`" pattern built here will also be reused without modification for at least one ephemeral table introduced in Part 4.

**Quick self-check before moving on:**
1. Can I explain, in one sentence, why we hash IPs instead of encrypting them?
2. If I inspect `mood_entries` in Neon's SQL console right now, does `note_ciphertext` show as `bytea`?
3. Do I understand why `expiresAt` is stored on the row itself, rather than computed at sweep-time from a hardcoded interval?
4. Can I locate, in my own repo, the exact single line where a raw IP address exists in memory — and confirm it's never assigned to a variable that outlives one function call?
