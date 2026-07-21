# Part 3: Architecture & Storage — Encrypting Sensitive Data and Controlling Who Sees What

## 3.0 Where we are on the map

Recall the target architecture: Route Handlers and Server Actions sit in front of a Data Access Layer, which itself sits in front of Postgres [2]. So far we've built the Clerk Middleware layer (Part 1) [1] and the raw database tables (Part 2). This Part builds everything in between:

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Clerk Middleware (done, Part 1)  →  Route Handlers / Server Actions     │
│                                       - create mood entry                 │
│                                       - create journal entry              │
│                                       - update consent                    │
│                                       >>> we build these routes here <<< │
│                                              │                            │
│                              ┌────────────────▼───────────────────┐        │
│                              │   Access Control Layer (RBAC/ABAC)  │        │
│                              │        >>> built in this Part <<<   │        │
│                              └────────────────┬───────────────────┘        │
│                              ┌────────────────▼───────────────────┐        │
│                              │   Data Access Layer                 │        │
│                              │  - encrypts sensitive fields         │        │
│                              │  >>> built in this Part <<<          │        │
│                              └────────────────┬───────────────────┘        │
└──────────────────────────────────────────────┼────────────────────────-─┘
                                                ▼
                             ┌─────────────────────────┐
                             │   POSTGRES DATABASE      │
                             │  - journal_entries        │
                             │  - medication_reminders   │
                             │    (ciphertext columns)   │
                             └─────────────────────────┘
```

By the end of Part 3 you will have:
1. `journal_entries` and `medication_reminders` tables completing the schema promised in Part 1's DPIA.
2. A **field-level encryption** module so sensitive columns are stored as ciphertext, not plaintext.
3. A working **RBAC/ABAC** access control layer that routes every non-owner read through our Part 2 masking utilities automatically.
4. Server Actions wiring it all together into real, working features.

---

## Step 3.1 — Completing the schema: journal entries and medication reminders

### The Target
Two new tables — `journal_entries` and `medication_reminders` — completing the data inventory named in Part 1's DPIA.

### The Concept
Both of these tables store data our DPIA already classified as "special category" — directly revealing health information [1]. Unlike `mood_entries` (Part 2), where we stored the note as plain `String?`, here we introduce a **dedicated encrypted type at the schema level**. Think of it like labeling a physical filing cabinet drawer "controlled substances" — anyone glancing at the drawer's label instantly knows different handling rules apply, before they've even opened it. We want the same instant visual signal in our schema file itself.

### The Implementation

**File: `prisma/schema.prisma`** (append)

```prisma
// Journal entries are long-form, free-text reflections. The `bodyCiphertext`
// column name deliberately does NOT say "body" — the name itself signals
// to any future developer reading the schema that this column holds
// encrypted bytes, not readable text, and must be decrypted through our
// dedicated encryption module (Step 3.2), never read directly.
model JournalEntry {
  id              String   @id @default(cuid())
  userId          String
  user            User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // Ciphertext, stored as Base64-encoded text. Never queried with SQL
  // WHERE clauses (you cannot search encrypted text meaningfully) —
  // any search/filter feature would need a separate design (out of
  // scope for this series, flagged honestly rather than faked).
  bodyCiphertext  String

  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  @@map("journal_entries")
}

// Medication reminders directly reveal a health condition being treated,
// per our DPIA risk table — so both the medication name and dosage notes
// are stored as ciphertext.
model MedicationReminder {
  id                  String   @id @default(cuid())
  userId              String
  user                User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  medicationNameCiphertext String
  dosageNoteCiphertext     String?

  // Reminder TIME OF DAY is not itself sensitive in isolation (it reveals
  // nothing about WHAT is being taken), so it stays as a plain column —
  // consistent with our Part 2 data-minimization habit of only protecting
  // what genuinely needs it.
  reminderHour        Int      // 0–23, enforced via CHECK constraint below
  reminderMinute      Int      // 0–59, enforced via CHECK constraint below

  createdAt           DateTime @default(now())

  @@map("medication_reminders")
}
```

Generate the migration with `--create-only` so we can hand-add the `CHECK` constraints, following the same pattern established in Part 2:

```bash
npm run db:migrate -- --name add_journal_and_medication --create-only
```

Edit the generated SQL file to append the time-range constraints:

**File: `prisma/migrations/<timestamp>_add_journal_and_medication/migration.sql`** (append to the generated content)

```sql
-- Manually added: enforce valid 24-hour clock values, same philosophy
-- as the mood_entries score constraint in Part 2 — don't just hope the
-- frontend sends valid values, make the database refuse bad ones.
ALTER TABLE "medication_reminders" ADD CONSTRAINT "medication_reminders_hour_range"
    CHECK ("reminderHour" >= 0 AND "reminderHour" <= 23);

ALTER TABLE "medication_reminders" ADD CONSTRAINT "medication_reminders_minute_range"
    CHECK ("reminderMinute" >= 0 AND "reminderMinute" <= 59);
```

Apply it:

```bash
npm run db:migrate
```

### The Verification

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "\d medication_reminders"
```

Confirm both `CHECK` constraints appear in the output. Then commit:

```bash
git add -A
git commit -m "feat: add journal_entries and medication_reminders tables with ciphertext columns"
```

---

## Step 3.2 — Field-level encryption

### The Target
A `src/lib/encryption.ts` module providing `encryptField()` and `decryptField()` functions, using AES-256-GCM.

### The Concept
"Encryption at rest" often just means the whole disk is encrypted — which protects against someone stealing a physical hard drive, but does nothing if an attacker compromises the *running database* itself (e.g., via a SQL injection bug or a leaked database credential), since the database happily decrypts everything for anyone with valid access. **Field-level encryption** is different: individual sensitive columns are encrypted by *our application*, before the data ever reaches Postgres. Postgres itself never holds the key and never sees plaintext — it only ever stores and returns scrambled bytes.

Think of it like a bank safe deposit box system: the bank (Postgres) securely stores your box, but doesn't hold a copy of your key. Even if someone bribes a bank employee, they get a locked box, not your documents.

We use **AES-256-GCM**, a symmetric encryption algorithm (the same key encrypts and decrypts) that also provides **authentication** — meaning if ciphertext is tampered with even slightly, decryption fails loudly instead of silently returning corrupted data. This matters enormously for journal entries: we'd rather an entry fail to decrypt with a clear error than silently show a user garbled, altered content without any warning.

### The Implementation

Generate a 256-bit encryption key:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

**File: `.env.local`** (append — use YOUR generated key, never this placeholder)

```bash
# .env.local — append this line
# 32-byte (256-bit) key, Base64-encoded. Generated once, must NEVER change
# after real data has been encrypted with it (changing it makes existing
# ciphertext permanently undecryptable). Key rotation strategy is a
# production concern flagged in our DPIA's Section 8 open questions.
FIELD_ENCRYPTION_KEY=paste_your_generated_key_here
```

**File: `src/lib/encryption.ts`**

```typescript
// src/lib/encryption.ts
//
// Field-level encryption for sensitive database columns. Sensitive text
// is encrypted here, in application code, BEFORE it is ever sent to
// Postgres — meaning the database itself never holds a readable copy.

import crypto from "crypto";

const ALGORITHM = "aes-256-gcm";
const IV_LENGTH_BYTES = 12; // recommended IV length for GCM mode
const AUTH_TAG_LENGTH_BYTES = 16;

function getEncryptionKey(): Buffer {
  const base64Key = process.env.FIELD_ENCRYPTION_KEY;
  if (!base64Key) {
    // Fail loudly and immediately — there is no safe fallback behavior
    // for a missing encryption key. We would rather crash on startup
    // than silently write plaintext.
    throw new Error(
      "FIELD_ENCRYPTION_KEY is not set. Refusing to process sensitive data without it.",
    );
  }
  const key = Buffer.from(base64Key, "base64");
  if (key.length !== 32) {
    throw new Error(
      `FIELD_ENCRYPTION_KEY must decode to exactly 32 bytes, got ${key.length}.`,
    );
  }
  return key;
}

/**
 * Encrypts a plaintext string, returning a single Base64 string safe to
 * store directly in a TEXT column. The output packs together the IV
 * (initialization vector — a random value ensuring the same plaintext
 * never produces the same ciphertext twice), the auth tag (proves the
 * ciphertext hasn't been tampered with), and the ciphertext itself.
 */
export function encryptField(plaintext: string): string {
  const key = getEncryptionKey();

  // A fresh, random IV for every single encryption operation is
  // critical: reusing an IV with the same key catastrophically weakens
  // GCM mode's security guarantees. crypto.randomBytes gives us a
  // cryptographically secure random value, not a predictable one.
  const iv = crypto.randomBytes(IV_LENGTH_BYTES);

  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  const ciphertext = Buffer.concat([
    cipher.update(plaintext, "utf8"),
    cipher.final(),
  ]);

  // GCM mode produces an authentication tag alongside the ciphertext —
  // this is what lets decryptField() detect tampering. We must capture
  // it AFTER calling cipher.final(), not before.
  const authTag = cipher.getAuthTag();

  // Pack [IV][authTag][ciphertext] into one buffer, then Base64-encode
  // the whole thing so it fits cleanly into a TEXT column. We store all
  // three pieces together so decryption never depends on a separate,
  // easy-to-lose side table mapping ciphertext to its IV.
  const packed = Buffer.concat([iv, authTag, ciphertext]);
  return packed.toString("base64");
}

/**
 * Reverses encryptField(). Throws if the key is wrong OR if the
 * ciphertext has been tampered with in any way — GCM's authentication
 * tag check fails loudly rather than returning corrupted plaintext
 * silently, which is exactly the behavior we want for sensitive data.
 */
export function decryptField(packedBase64: string): string {
  const key = getEncryptionKey();
  const packed = Buffer.from(packedBase64, "base64");

  const iv = packed.subarray(0, IV_LENGTH_BYTES);
  const authTag = packed.subarray(
    IV_LENGTH_BYTES,
    IV_LENGTH_BYTES + AUTH_TAG_LENGTH_BYTES,
  );
  const ciphertext = packed.subarray(IV_LENGTH_BYTES + AUTH_TAG_LENGTH_BYTES);

  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);

  const plaintext = Buffer.concat([
    decipher.update(ciphertext),
    decipher.final(), // throws here if authTag verification fails
  ]);

  return plaintext.toString("utf8");
}
```

### The Verification

Write a quick regression test proving round-trip correctness and tamper detection — mirroring the same "prove the guarantee, don't just hope it holds" habit established with the masking utilities in Part 2.

**File: `src/lib/encryption.test.ts`**

```typescript
import { describe, it, expect, beforeAll } from "vitest";
import { encryptField, decryptField } from "./encryption";

beforeAll(() => {
  // A fixed test key so this test suite doesn't depend on your real
  // .env.local secret being present in CI environments.
  process.env.FIELD_ENCRYPTION_KEY = Buffer.alloc(32, 7).toString("base64");
});

describe("encryptField / decryptField", () => {
  it("round-trips plaintext correctly", () => {
    const original = "Today I felt anxious about my appointment.";
    const ciphertext = encryptField(original);
    expect(ciphertext).not.toContain("anxious");
    expect(decryptField(ciphertext)).toBe(original);
  });

  it("produces different ciphertext for the same plaintext each time", () => {
    const a = encryptField("same text");
    const b = encryptField("same text");
    expect(a).not.toBe(b); // proves the IV is genuinely random per call
  });

  it("throws if ciphertext is tampered with", () => {
    const ciphertext = encryptField("sensitive note");
    const tampered = ciphertext.slice(0, -4) + "abcd";
    expect(() => decryptField(tampered)).toThrow();
  });
});
```

Run it:

```bash
npm test
```

Confirm all three tests pass. Then commit:

```bash
git add -A
git commit -m "feat: add AES-256-GCM field-level encryption module with round-trip and tamper tests"
```

## Step 3.3 — Server Actions: creating journal entries and medication reminders

### The Target
Two Server Actions — `createJournalEntry` and `createMedicationReminder` — that encrypt sensitive fields before they ever reach Postgres, plus the paired read-side functions that decrypt them back for their rightful owner.

### The Concept
A **Server Action** is a function marked `"use server"` that a React component can call directly, as if it were a local function, but which actually executes securely on the server — no manually wiring up a separate API route and `fetch` call for every form submission. Think of it as a pneumatic tube at a bank: you drop your form in a slot on the client, and it's whisked away to a secure back room where the real work happens, out of the browser's reach entirely.

The critical architectural rule we're establishing here: **encryption happens at the boundary, in exactly one place** — inside the Server Action, immediately before the database write. No component, no route handler, no future feature is ever allowed to construct a raw Prisma `create` call for these tables directly. This mirrors the target architecture's Data Access Layer, which sits between application logic and Postgres specifically to encrypt on write and decrypt only on authorized read [2].

### The Implementation

**File: `src/lib/journal.ts`**

```typescript
// src/lib/journal.ts
//
// The ONLY sanctioned way to create or read journal entries. Encryption
// and decryption are centralized here so no other code path can
// accidentally write plaintext or forget to decrypt correctly.

"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { encryptField, decryptField } from "@/lib/encryption";
import { revalidatePath } from "next/cache";

export async function createJournalEntry(rawBody: string): Promise<void> {
  const { userId: clerkId } = await auth();
  if (!clerkId) {
    // Defense-in-depth: middleware already blocks unauthenticated
    // requests from reaching this far, but we never trust that a
    // Server Action is only ever called from a protected route.
    throw new Error("Not authenticated.");
  }

  const trimmed = rawBody.trim();
  if (trimmed.length === 0) {
    throw new Error("Journal entry cannot be empty.");
  }

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) {
    throw new Error("User record not found. Please try signing in again.");
  }

  // Encrypt BEFORE the database call — Postgres never receives the
  // plaintext body under any circumstance.
  const bodyCiphertext = encryptField(trimmed);

  await db.journalEntry.create({
    data: { userId: user.id, bodyCiphertext },
  });

  revalidatePath("/dashboard/journal");
}

export type DecryptedJournalEntry = {
  id: string;
  body: string;
  createdAt: Date;
};

export async function getOwnJournalEntries(): Promise<DecryptedJournalEntry[]> {
  const { userId: clerkId } = await auth();
  if (!clerkId) {
    throw new Error("Not authenticated.");
  }

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) {
    return [];
  }

  const entries = await db.journalEntry.findMany({
    where: { userId: user.id },
    orderBy: { createdAt: "desc" },
  });

  // Decryption happens here, ONLY because we've just confirmed the
  // requester IS the owner of this data (userId match via Clerk auth).
  // Part 3.4's RBAC/ABAC layer generalizes this "who's allowed to see
  // plaintext" decision for every other role.
  return entries.map((entry) => ({
    id: entry.id,
    body: decryptField(entry.bodyCiphertext),
    createdAt: entry.createdAt,
  }));
}
```

**File: `src/lib/medication.ts`**

```typescript
// src/lib/medication.ts

"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { encryptField, decryptField } from "@/lib/encryption";
import { revalidatePath } from "next/cache";

export async function createMedicationReminder(input: {
  medicationName: string;
  dosageNote?: string;
  reminderHour: number;
  reminderMinute: number;
}): Promise<void> {
  const { userId: clerkId } = await auth();
  if (!clerkId) {
    throw new Error("Not authenticated.");
  }

  // Application-layer validation for fast, friendly errors — the
  // database-level CHECK constraints from Step 3.1 remain our
  // non-negotiable backstop regardless of what happens here.
  if (input.reminderHour < 0 || input.reminderHour > 23) {
    throw new Error("Reminder hour must be between 0 and 23.");
  }
  if (input.reminderMinute < 0 || input.reminderMinute > 59) {
    throw new Error("Reminder minute must be between 0 and 59.");
  }
  if (input.medicationName.trim().length === 0) {
    throw new Error("Medication name is required.");
  }

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) {
    throw new Error("User record not found. Please try signing in again.");
  }

  await db.medicationReminder.create({
    data: {
      userId: user.id,
      medicationNameCiphertext: encryptField(input.medicationName.trim()),
      dosageNoteCiphertext: input.dosageNote?.trim()
        ? encryptField(input.dosageNote.trim())
        : null,
      reminderHour: input.reminderHour,
      reminderMinute: input.reminderMinute,
    },
  });

  revalidatePath("/dashboard/medications");
}

export type DecryptedMedicationReminder = {
  id: string;
  medicationName: string;
  dosageNote: string | null;
  reminderHour: number;
  reminderMinute: number;
};

export async function getOwnMedicationReminders(): Promise<
  DecryptedMedicationReminder[]
> {
  const { userId: clerkId } = await auth();
  if (!clerkId) {
    throw new Error("Not authenticated.");
  }

  const user = await db.user.findUnique({ where: { clerkId } });
  if (!user) {
    return [];
  }

  const reminders = await db.medicationReminder.findMany({
    where: { userId: user.id },
    orderBy: { reminderHour: "asc" },
  });

  return reminders.map((r) => ({
    id: r.id,
    medicationName: decryptField(r.medicationNameCiphertext),
    dosageNote: r.dosageNoteCiphertext ? decryptField(r.dosageNoteCiphertext) : null,
    reminderHour: r.reminderHour,
    reminderMinute: r.reminderMinute,
  }));
}
```

### The Verification

Since these are server-only functions without UI yet, verify them directly with a small temporary test script:

```bash
cat <<'EOF' > /tmp/test-journal.mjs
// Run via: node --loader ts-node/esm /tmp/test-journal.mjs (or call from a Server Component temporarily)
EOF
```

The more practical verification at this stage: temporarily call `createJournalEntry("Testing encryption end to end")` from inside your `dashboard/page.tsx` Server Component during render (just for this test, then remove it), then inspect the raw database row directly:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "SELECT \"bodyCiphertext\" FROM journal_entries;"
```

Confirm the output is unreadable Base64 gibberish — not "Testing encryption end to end." Then confirm `getOwnJournalEntries()` correctly returns the original plaintext when called from your own authenticated session.

Commit:

```bash
git add -A
git commit -m "feat: add Server Actions for journal entries and medication reminders with field-level encryption"
```

## Step 3.4 — The RBAC/ABAC access control layer

### The Target
A centralized authorization module — `src/lib/access-control.ts` — that every read of sensitive data must pass through, deciding what a given viewer is allowed to see based on their role and their relationship to the data.

### The Concept
As Part 0 warned, it would be easy to sprinkle `if (user.role === 'admin')` checks throughout individual route handlers — but that's precisely how access-control bugs are born: one forgotten check in one forgotten file, and a support agent can suddenly read someone's private journal entry [2]. The fix, as laid out from the very beginning of this series, is to centralize the rule "who can see what" into one layer everything must pass through — like a single reception desk in a building, instead of every floor having its own unlocked door [2].

This layer combines two related ideas:
- **RBAC (Role-Based Access Control):** access decisions based on a fixed role, like "owner," "support_agent," or "admin" — analogous to a badge color that grants access to certain floors.
- **ABAC (Attribute-Based Access Control):** access decisions based on *attributes of the specific request*, not just the role alone — e.g., "a support agent may view masked mood entries, but only for a user who has an open support ticket," or "only the owner of *this specific* journal entry may ever see it unmasked, regardless of their role." RBAC alone can't express "same role, different outcome depending on context" — ABAC can.

Our implementation combines both: a role check first, then an attribute check (ownership) layered on top, with every non-owner read automatically routed through the Part 2 masking utilities rather than trusting each caller to remember to mask manually.

### The Implementation

**File: `src/lib/access-control.ts`**

```typescript
// src/lib/access-control.ts
//
// The single, centralized authorization layer. ALL reads of sensitive
// content (journal entries, mood notes, medication data) must be
// requested through this module — never by calling db.journalEntry
// .findMany() directly from a route or component. Centralizing this
// decision in one file is what prevents the "one forgotten check in one
// forgotten file" failure mode described in Part 0.

import { getDisplayText } from "@/lib/masking";

// RBAC: the fixed set of roles that exist in this system. Kept small
// and explicit, mirroring the same "closed list" philosophy as our
// Part 2 ConsentCategory enum — roles are a reviewed, deliberate list,
// not an open string.
export type Role = "owner" | "support_agent" | "admin";

// ABAC: the contextual attributes of a specific access request. Two
// requests from the SAME role can yield different outcomes depending
// on these attributes — this is what distinguishes ABAC from plain RBAC.
export type AccessContext = {
  viewerRole: Role;
  viewerUserId: string;   // the ID of whoever is asking
  resourceOwnerId: string; // the ID of whoever the data actually belongs to
};

/**
 * The core ABAC rule: a viewer is always the "owner" for masking
 * purposes if the resource actually belongs to them, REGARDLESS of
 * their assigned role. A support_agent viewing their OWN journal
 * entries (as a user of the product themselves) sees full plaintext of
 * their own data — the role only matters when viewing someone ELSE's data.
 */
function resolveEffectiveRole(context: AccessContext): Role {
  if (context.viewerUserId === context.resourceOwnerId) {
    return "owner";
  }
  return context.viewerRole;
}

/**
 * The single function every internal tool must call before displaying
 * sensitive free-text. Returns either the raw plaintext (owner access)
 * or an appropriately masked version (any other role), and — critically
 * — logs every non-owner access, satisfying the DPIA's requirement that
 * "all such access logged" for any role permitted to request decryption.
 */
export function getAuthorizedText(
  plaintext: string,
  context: AccessContext,
  maskingStrategy: "preview" | "lengthOnly" | "full" = "preview",
): string {
  const effectiveRole = resolveEffectiveRole(context);

  if (effectiveRole !== "owner") {
    // Audit logging happens HERE, at the single chokepoint, rather than
    // trusting every call site to remember to log — the same philosophy
    // as centralizing masking itself.
    console.log(
      `[ACCESS_LOG] role=${effectiveRole} viewer=${context.viewerUserId} ` +
        `accessed resource owned by=${context.resourceOwnerId} at ${new Date().toISOString()}`,
    );
  }

  return getDisplayText(plaintext, effectiveRole, maskingStrategy);
}

/**
 * A stricter guard for actions more sensitive than viewing masked text —
 * e.g., permanently deleting another user's data, or exporting it. Only
 * "owner" and "admin" pass; a support_agent role is deliberately
 * excluded even from masked-level destructive actions.
 */
export function assertCanModify(context: AccessContext): void {
  const effectiveRole = resolveEffectiveRole(context);
  if (effectiveRole !== "owner" && effectiveRole !== "admin") {
    throw new Error(
      `Access denied: role '${effectiveRole}' cannot modify a resource it does not own.`,
    );
  }
}
```

### The Verification

Add a regression test proving the ABAC ownership override and the audit log firing correctly, following the same "prove the guarantee" discipline used for the masking and encryption modules:

**File: `src/lib/access-control.test.ts`**

```typescript
import { describe, it, expect, vi } from "vitest";
import { getAuthorizedText, assertCanModify } from "./access-control";

describe("getAuthorizedText", () => {
  const secret = "I have been skipping therapy sessions";

  it("returns raw plaintext when viewer owns the resource, regardless of role", () => {
    const result = getAuthorizedText(secret, {
      viewerRole: "support_agent",
      viewerUserId: "user-1",
      resourceOwnerId: "user-1",
    });
    expect(result).toBe(secret);
  });

  it("masks text when a non-owner role views someone else's data", () => {
    const result = getAuthorizedText(secret, {
      viewerRole: "support_agent",
      viewerUserId: "agent-9",
      resourceOwnerId: "user-1",
    });
    expect(result).not.toBe(secret);
    expect(result).not.toContain("therapy");
  });

  it("logs an audit entry when a non-owner accesses the data", () => {
    const logSpy = vi.spyOn(console, "log").mockImplementation(() => {});
    getAuthorizedText(secret, {
      viewerRole: "admin",
      viewerUserId: "admin-1",
      resourceOwnerId: "user-1",
    });
    expect(logSpy).toHaveBeenCalledWith(expect.stringContaining("ACCESS_LOG"));
    logSpy.mockRestore();
  });
});

describe("assertCanModify", () => {
  it("allows the owner to modify their own resource", () => {
    expect(() =>
      assertCanModify({
        viewerRole: "support_agent",
        viewerUserId: "user-1",
        resourceOwnerId: "user-1",
      }),
    ).not.toThrow();
  });

  it("denies a support_agent modifying someone else's resource", () => {
    expect(() =>
      assertCanModify({
        viewerRole: "support_agent",
        viewerUserId: "agent-9",
        resourceOwnerId: "user-1",
      }),
    ).toThrow(/Access denied/);
  });
});
```

Run:

```bash
npm test
```

Confirm all tests pass, then commit:

```bash
git add -A
git commit -m "feat: add centralized RBAC/ABAC access-control layer with audit logging and tests"
```
