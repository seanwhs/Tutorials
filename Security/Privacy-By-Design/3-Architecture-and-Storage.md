# Part 3: Architecture & Storage — Field-Level Encryption & Zero-Trust

---

## 3.1 Field-Level Encryption vs. Transport/Storage Encryption: Why We Need Both

**Analogy:** Think of your data's journey like a valuable letter traveling through the postal system. **Transport encryption** (TLS, which we already have via HTTPS) is the sealed, tamper-evident courier bag the letter travels in — nobody can read it *in transit*. **Storage encryption at rest** (which Neon provides automatically on its disks) is the locked warehouse the courier bag sits in overnight. But once the letter arrives at the warehouse and someone with a valid warehouse key opens the bag, the letter itself is still just... a letter, in plain handwriting, readable by anyone who gets that far.

**Field-Level Encryption (FLE)** is sealing the *letter itself* in its own separate, individually-locked envelope, with its own separate key — so that even someone standing inside the unlocked warehouse, holding an open courier bag, still cannot read the words on the page.

This distinction matters enormously in practice:

| Layer | Protects Against | Does NOT Protect Against |
|---|---|---|
| TLS (transport) | Network eavesdroppers, man-in-the-middle | A compromised database, a rogue DBA, a stolen backup file |
| Disk encryption at rest (Neon-managed) | Someone stealing the physical disk/storage snapshot | A compromised application server, a SQL injection dump, an over-privileged database user querying `SELECT *` |
| **Field-Level Encryption (what we build now)** | **All of the above, for the specific fields encrypted** | Nothing decrypts without the correct key — which we ensure the database itself never possesses |

The core zero-trust principle we're implementing: **the database should be treated as untrusted storage.** If a Neon employee, a misconfigured backup export, or an attacker with full read access to our Postgres instance dumped every row in `journal_entries` right now, they should see nothing but meaningless bytes.

---

## 3.2 Envelope Encryption: The Two-Key Pattern

**The Concept:** Naively, you might think "let's just encrypt every journal entry with one master key stored in an environment variable." This has a fatal flaw: rotating that key means re-encrypting *every single row in the database*, and if that one key ever leaks, *every row ever written* is instantly compromised.

**Envelope encryption** solves this with two tiers of keys, and it's the exact pattern used by AWS KMS, Google Cloud KMS, and HashiCorp Vault:

- **Data Encryption Key (DEK):** A unique, randomly generated key used to encrypt one specific piece of data (e.g., one journal entry). Cheap to generate, cheap to rotate.
- **Key Encryption Key (KEK):** A single master key, held inside a dedicated **Key Management System (KMS)** — a hardened, audited vault service — that is used *only* to encrypt/decrypt DEKs, never application data directly.

**Analogy:** Imagine a hotel with hundreds of rooms. Each room has its own unique physical key (the DEK) — losing one room key only compromises one room. But every one of those room keys is itself stored inside a master safe at the front desk (the KEK/KMS), and opening that safe requires the hotel manager's one master credential. If a housekeeper's room key is stolen, only one room is at risk. If the safe combination somehow needed to change, you re-lock the safe — you don't need to re-cut every room key in the building.

**The flow, concretely:**
1. To encrypt a journal entry: generate a fresh random DEK → encrypt the journal text with the DEK → send the DEK itself to the KMS to be encrypted by the KEK → store *both* the encrypted journal text AND the encrypted DEK in the database row. The plaintext DEK is discarded from memory immediately after use.
2. To decrypt: fetch the encrypted DEK from the row → send it to the KMS, which decrypts it back to the plaintext DEK (this requires KMS-level authorization) → use the plaintext DEK to decrypt the journal text → discard the plaintext DEK from memory again.

The database only ever stores **ciphertext of the data** and **ciphertext of the DEK**. Neither is useful without a live, authorized call to the KMS.

---

## 3.3 The Target: Provisioning a Cloud KMS Key

**The Concept:** Before writing code, we need a real KEK living in a real KMS — not something we invent in our own app. We'll use **Google Cloud KMS** for this series (AWS KMS is functionally near-identical; the concepts transfer directly). This is a deliberate choice to teach you real infrastructure provisioning, not a mocked stand-in.

### The Implementation

**Step 1 — Create a Cloud KMS key ring and key**

```bash
# Install the gcloud CLI first if you haven't: https://cloud.google.com/sdk/docs/install

gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# A "key ring" is a logical folder for related keys — like a labeled keychain.
gcloud kms keyrings create mindfullog-keyring --location=us-central1

# The actual KEK. `purpose=encryption` restricts this key to encrypt/decrypt
# operations only — it cannot be used to sign documents, for example,
# following the security principle of least privilege even at the key level.
gcloud kms keys create mindfullog-kek \
  --location=us-central1 \
  --keyring=mindfullog-keyring \
  --purpose=encryption
```

**Step 2 — Create a dedicated service account with minimal permissions**

```bash
gcloud iam service-accounts create mindfullog-kms-client \
  --display-name="MindfulLog KMS Client (encrypt/decrypt DEKs only)"

# Grant ONLY the encrypt/decrypt role on this specific key — not project-wide
# KMS admin access. This is the Zero-Trust principle applied to our own
# infrastructure's permissions, not just user-facing RBAC.
gcloud kms keys add-iam-policy-binding mindfullog-kek \
  --location=us-central1 \
  --keyring=mindfullog-keyring \
  --member="serviceAccount:mindfullog-kms-client@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# Generate a key file for local/server auth. In real production, prefer
# Workload Identity Federation over long-lived key files — noted in
# Reference 3.C at the end of this Part.
gcloud iam service-accounts keys create ./gcp-kms-credentials.json \
  --iam-account=mindfullog-kms-client@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

**Step 3 — Wire the credentials into our environment**

```bash
# NEVER commit this file. Add it to .gitignore immediately.
echo "gcp-kms-credentials.json" >> .gitignore
```

**File: `.env.local`** (add these new variables)
```bash
# --- existing vars from Parts 1 & 2 remain unchanged above ---

# --- Cloud KMS (Part 3) ---
GOOGLE_APPLICATION_CREDENTIALS=./gcp-kms-credentials.json
GCP_KMS_KEY_NAME=projects/YOUR_PROJECT_ID/locations/us-central1/keyRings/mindfullog-keyring/cryptoKeys/mindfullog-kek
```

### The Verification

```bash
gcloud kms keys list --location=us-central1 --keyring=mindfullog-keyring
```
Expected output should list `mindfullog-kek` with `purpose: ENCRYPT_DECRYPT`. This confirms the key exists and is correctly scoped before we ever write a line of application code against it.

```bash
# Sanity-check the service account can actually encrypt/decrypt (not just exist)
echo "test-payload" | gcloud kms encrypt \
  --location=us-central1 --keyring=mindfullog-keyring --key=mindfullog-kek \
  --plaintext-file=- --ciphertext-file=./test-ciphertext.bin \
  --impersonate-service-account=mindfullog-kms-client@YOUR_PROJECT_ID.iam.gserviceaccount.com

ls -la ./test-ciphertext.bin  # should exist and be non-empty
rm ./test-ciphertext.bin      # clean up the scratch file
```

---

## 3.4 The Target: The Envelope Encryption Library

**The Concept:** Now we write the actual code implementing the two-key dance described in Section 3.2. This library becomes the **only** code path in our entire application permitted to touch plaintext sensitive data before it's written to disk, or after it's read from disk.

### The Implementation

**Step 1 — Install the KMS client**

```bash
npm install @google-cloud/kms
```

**Step 2 — Build the envelope encryption module**

**File: `src/lib/crypto/envelope.ts`**
```typescript
import { KeyManagementServiceClient } from "@google-cloud/kms";
import {
  randomBytes,
  createCipheriv,
  createDecipheriv,
} from "node:crypto";

const kmsClient = new KeyManagementServiceClient();
const KEK_NAME = process.env.GCP_KMS_KEY_NAME;

if (!KEK_NAME) {
  throw new Error("GCP_KMS_KEY_NAME is not set. Refusing to start.");
}

// AES-256-GCM is an "authenticated encryption" cipher: it doesn't just
// hide the plaintext, it also produces a tamper-evident tag. If even one
// bit of the ciphertext is altered before decryption, decryption fails
// loudly rather than silently returning corrupted data — critical for
// data we might later rely on for legal/audit purposes.
const ALGORITHM = "aes-256-gcm";
const DEK_LENGTH_BYTES = 32; // 256 bits
const IV_LENGTH_BYTES = 12;  // standard/recommended IV length for GCM

/**
 * The shape we store in the database for every encrypted field: the
 * encrypted DEK (so we can ask the KMS to unwrap it later), the IV used
 * for this specific encryption operation (must be unique per encryption,
 * never reused with the same key), the GCM auth tag (proves integrity),
 * and the actual ciphertext of the real data.
 */
export interface EnvelopeCiphertext {
  encryptedDek: Buffer;
  iv: Buffer;
  authTag: Buffer;
  ciphertext: Buffer;
}

/**
 * Serializes an EnvelopeCiphertext into a single Buffer for storage in a
 * `bytea` column, using a simple length-prefixed format so we can split
 * it back apart deterministically on read. Format:
 * [4-byte DEK length][encryptedDek][12-byte IV][16-byte authTag][ciphertext]
 */
function serialize(envelope: EnvelopeCiphertext): Buffer {
  const dekLengthPrefix = Buffer.alloc(4);
  dekLengthPrefix.writeUInt32BE(envelope.encryptedDek.length, 0);

  return Buffer.concat([
    dekLengthPrefix,
    envelope.encryptedDek,
    envelope.iv,
    envelope.authTag,
    envelope.ciphertext,
  ]);
}

/**
 * The inverse of serialize(): reads the length-prefixed format back apart
 * into its four constituent pieces. We read the DEK length first because
 * encrypted DEKs from a KMS are NOT a fixed length (unlike the IV and auth
 * tag, which are fixed by the AES-GCM spec at 12 and 16 bytes respectively).
 */
function deserialize(buffer: Buffer): EnvelopeCiphertext {
  const dekLength = buffer.readUInt32BE(0);
  let offset = 4;

  const encryptedDek = buffer.subarray(offset, offset + dekLength);
  offset += dekLength;

  const iv = buffer.subarray(offset, offset + IV_LENGTH_BYTES);
  offset += IV_LENGTH_BYTES;

  const AUTH_TAG_LENGTH_BYTES = 16;
  const authTag = buffer.subarray(offset, offset + AUTH_TAG_LENGTH_BYTES);
  offset += AUTH_TAG_LENGTH_BYTES;

  const ciphertext = buffer.subarray(offset);

  return { encryptedDek, iv, authTag, ciphertext };
}

/**
 * Encrypts a plaintext string using the full envelope pattern:
 *   1. Generate a brand-new random DEK (never reused across fields/rows).
 *   2. Encrypt the plaintext locally with that DEK (fast, no network call).
 *   3. Send ONLY the DEK (not the plaintext!) to Cloud KMS to be wrapped
 *      by the KEK. This is the critical zero-trust property: the KMS
 *      service itself never sees the actual journal entry text — only a
 *      throwaway random key that's meaningless on its own.
 *   4. Discard the plaintext DEK from memory (it goes out of scope here;
 *      we never persist it, log it, or return it to any caller).
 *   5. Serialize everything needed to reverse the process into one Buffer
 *      ready to be written directly into a `bytea` column.
 */
export async function encryptField(plaintext: string): Promise<Buffer> {
  const dek = randomBytes(DEK_LENGTH_BYTES);
  const iv = randomBytes(IV_LENGTH_BYTES);

  const cipher = createCipheriv(ALGORITHM, dek, iv);
  const ciphertext = Buffer.concat([
    cipher.update(plaintext, "utf8"),
    cipher.final(),
  ]);
  const authTag = cipher.getAuthTag();

  // The only network call in this whole function — sending a 32-byte
  // random key (not the sensitive plaintext) to the KMS to be wrapped.
  const [encryptResponse] = await kmsClient.encrypt({
    name: KEK_NAME,
    plaintext: dek,
  });

  if (!encryptResponse.ciphertext) {
    throw new Error("KMS did not return an encrypted DEK.");
  }

  return serialize({
    encryptedDek: Buffer.from(encryptResponse.ciphertext),
    iv,
    authTag,
    ciphertext,
  });
}

/**
 * Reverses encryptField(): unwraps the DEK via the KMS, then uses the
 * plaintext DEK locally to decrypt the actual field data. If the ciphertext
 * or auth tag has been tampered with in any way (e.g., a corrupted row, a
 * malicious edit via direct DB access), `decipher.final()` throws instead
 * of returning corrupted data — a deliberate fail-loud behavior.
 */
export async function decryptField(stored: Buffer): Promise<string> {
  const { encryptedDek, iv, authTag, ciphertext } = deserialize(stored);

  const [decryptResponse] = await kmsClient.decrypt({
    name: KEK_NAME,
    ciphertext: encryptedDek,
  });

  if (!decryptResponse.plaintext) {
    throw new Error("KMS did not return a decrypted DEK.");
  }

  const dek = Buffer.from(decryptResponse.plaintext);

  const decipher = createDecipheriv(ALGORITHM, dek, iv);
  decipher.setAuthTag(authTag);

  const plaintext = Buffer.concat([
    decipher.update(ciphertext),
    decipher.final(), // throws if authTag verification fails (tamper detection)
  ]);

  return plaintext.toString("utf8");
}
```

### The Verification

**Step 1 — Round-trip unit test (encrypt, then decrypt, confirm equality)**

**File: `src/lib/crypto/envelope.test.ts`**
```typescript
import { describe, expect, it } from "vitest";
import { encryptField, decryptField } from "./envelope";

describe("envelope encryption", () => {
  it("round-trips plaintext through encrypt -> decrypt unchanged", async () => {
    const original = "Today I felt anxious about the presentation.";
    const ciphertext = await encryptField(original);
    const recovered = await decryptField(ciphertext);
    expect(recovered).toBe(original);
  });

  it("produces ciphertext that does not contain the plaintext as a substring", async () => {
    const original = "sensitive journal content";
    const ciphertext = await encryptField(original);
    expect(ciphertext.toString("utf8")).not.toContain(original);
  });

  it("produces DIFFERENT ciphertext for the same plaintext on repeated calls", async () => {
    // Because both the DEK and IV are freshly randomized every call, even
    // encrypting the identical string twice must never produce identical
    // ciphertext. This prevents an attacker from spotting patterns (e.g.,
    // "these two rows have the same mood note") just by comparing bytes.
    const a = await encryptField("I feel okay today");
    const b = await encryptField("I feel okay today");
    expect(a.equals(b)).toBe(false);
  });

  it("throws if ciphertext has been tampered with", async () => {
    const ciphertext = await encryptField("original text");
    const tampered = Buffer.from(ciphertext);
    tampered[tampered.length - 1] ^= 0xff; // flip the last byte
    await expect(decryptField(tampered)).rejects.toThrow();
  });
});
```

```bash
npx vitest run src/lib/crypto/envelope.test.ts
```
All four tests must pass. The third test is the one most tutorials skip, and it's the one that actually proves you're using a proper authenticated cipher with random IVs rather than a naive deterministic encryption scheme that would leak equality patterns.

**Step 2 — Confirm real KMS network calls are happening (not a local mock)**

```bash
# In one terminal, tail your app's KMS-related network activity via GCP's audit logs:
gcloud logging read \
  'resource.type="audited_resource" AND protoPayload.methodName="Encrypt"' \
  --limit=5 --format="table(timestamp, protoPayload.methodName)"
```
Run your test suite again, then re-run this query — you should see fresh `Encrypt`/`Decrypt` log entries with timestamps matching your test run, proving the DEK really is being wrapped/unwrapped by the real cloud KMS, not a local stand-in.

---

## 3.5 The Target: Wiring Encryption into the Application Layer (Server Actions)

**The Concept:** The encryption library is useless until it sits *between* our application logic and the database. We now write the Server Actions for creating a journal entry — the first real feature code in this series — using our envelope library so that plaintext text sent from the browser never reaches Postgres unencrypted, and ciphertext read from Postgres never reaches the browser undecrypted.

### The Implementation

**File: `src/app/actions/journal.ts`**
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/db";
import { journalEntries, users } from "@/db/schema";
import { encryptField, decryptField } from "@/lib/crypto/envelope";
import { eq, desc } from "drizzle-orm";
import { revalidatePath } from "next/cache";

/**
 * Resolves the Clerk session's user into OUR internal pseudonymous user ID.
 * Every Server Action that touches user data starts with this lookup —
 * it's the join point between Clerk's identity system and our own schema,
 * and the ONLY place clerkUserId is ever read back out of the database.
 */
async function getInternalUserId(): Promise<string> {
  const { userId: clerkUserId } = await auth();
  if (!clerkUserId) {
    throw new Error("Not authenticated.");
  }

  const existing = await db.query.users.findFirst({
    where: eq(users.clerkUserId, clerkUserId),
  });

  if (existing) return existing.id;

  // First-ever action for this Clerk user: provision our internal row.
  const [created] = await db
    .insert(users)
    .values({ clerkUserId })
    .returning({ id: users.id });

  return created.id;
}

/**
 * Creates a new journal entry. Plaintext arrives from the client as a
 * normal string argument (over an encrypted HTTPS connection — transport
 * security), is immediately encrypted via our envelope library, and ONLY
 * the resulting ciphertext Buffer is ever passed to Drizzle/Postgres.
 * The plaintext variable goes out of scope at the end of this function
 * and is never logged, cached, or persisted anywhere else.
 */
export async function createJournalEntry(plaintextBody: string): Promise<void> {
  if (plaintextBody.trim().length === 0) {
    throw new Error("Journal entry cannot be empty.");
  }

  const userId = await getInternalUserId();
  const bodyCiphertext = await encryptField(plaintextBody);

  await db.insert(journalEntries).values({
    userId,
    bodyCiphertext,
  });

  // Tells Next.js to refresh any cached UI showing the journal list, so
  // the new entry appears immediately without a manual page reload.
  revalidatePath("/dashboard/journal");
}

/**
 * Fetches and decrypts every journal entry belonging to the current user.
 * Decryption happens HERE, server-side, immediately before rendering —
 * plaintext journal text exists in the Node.js process memory only for
 * the duration of the request, and is sent to the browser only over TLS.
 */
export async function listJournalEntries(): Promise<
  Array<{ id: string; body: string; createdAt: Date }>
> {
  const userId = await getInternalUserId();

  const rows = await db.query.journalEntries.findMany({
    where: eq(journalEntries.userId, userId),
    orderBy: desc(journalEntries.createdAt),
  });

  // Decrypt sequentially per row. (For very large lists, Promise.all could
  // parallelize KMS calls — omitted here for clarity; see Reference 3.B
  // for the tradeoff discussion.)
  const decrypted = [];
  for (const row of rows) {
    decrypted.push({
      id: row.id,
      body: await decryptField(row.bodyCiphertext),
      createdAt: row.createdAt,
    });
  }

  return decrypted;
}
```

### The Verification

**Step 1 — Exercise the Server Action from a minimal UI**

**File: `src/app/dashboard/journal/page.tsx`**
```typescript
import { createJournalEntry, listJournalEntries } from "@/app/actions/journal";

export default async function JournalPage() {
  const entries = await listJournalEntries();

  return (
    <main className="mx-auto max-w-xl p-8">
      <h1 className="mb-4 text-2xl font-bold text-slate-800">Journal</h1>

      {/* A Server Action wired directly to a <form>'s `action` prop — no
          client-side fetch/JSON plumbing needed. Next.js handles posting
          this form's data to createJournalEntry() on the server, and
          revalidatePath() inside it refreshes this page's data below. */}
      <form
        action={async (formData) => {
          "use server";
          const body = formData.get("body") as string;
          await createJournalEntry(body);
        }}
        className="mb-8 flex flex-col gap-3"
      >
        <textarea
          name="body"
          required
          rows={4}
          placeholder="Write today's entry..."
          className="rounded-lg border border-slate-300 p-3 focus:border-slate-500 focus:outline-none"
        />
        <button
          type="submit"
          className="self-start rounded-lg bg-slate-800 px-4 py-2 font-semibold text-white hover:bg-slate-700"
        >
          Save Entry
        </button>
      </form>

      <ul className="flex flex-col gap-4">
        {entries.map((entry) => (
          <li key={entry.id} className="rounded-lg border border-slate-200 p-4">
            <p className="text-slate-800">{entry.body}</p>
            <p className="mt-2 text-xs text-slate-400">
              {entry.createdAt.toLocaleString()}
            </p>
          </li>
        ))}
      </ul>
    </main>
  );
}
```

**Step 2 — Run it end-to-end in the browser**

```bash
npm run dev
```
Navigate to `http://localhost:3000/dashboard/journal` (signing in via Clerk if prompted, since this route is protected by our Part 1 middleware). Type "This is a test entry" into the textarea and click **Save Entry**. Confirm it appears immediately in the list below, rendered as readable plaintext.

**Step 3 — The critical proof: inspect the raw database row directly**

```sql
-- Run in Neon's SQL console
SELECT id, body_ciphertext, created_at FROM journal_entries ORDER BY created_at DESC LIMIT 1;
```
Expected output: `body_ciphertext` should render as an unreadable hex/binary blob (e.g., `\x0000012a3f8e...`), **never** the readable text "This is a test entry." This is the single most important verification in this entire Part — it's the literal proof that Field-Level Encryption is functioning: the application can read the data, but the database itself cannot.

**Step 4 — Simulate a "compromised database" scenario**

```bash
# Export the table as an attacker with full DB read access would:
pg_dump "$DATABASE_URL" -t journal_entries --data-only > journal_dump.sql
cat journal_dump.sql | grep -i "test entry"
```
This `grep` should return **zero matches**. If your journal text appears anywhere in this raw dump, your encryption wiring has a bug — stop and re-check Section 3.4 before proceeding. Delete `journal_dump.sql` after this test; don't leave a plaintext-adjacent artifact lying around even as a dump of ciphertext.

---

## 3.6 The Target: RBAC/ABAC — Zero-Trust Access Control for Sensitive Attributes

**The Concept:** Encryption answers "can the *database* read this?" (no). Access control answers a different question: "can *this specific authenticated user/role*, right now, for this specific reason, read this decrypted value?" Even with perfect encryption, if our application code has a bug that lets User A call `listJournalEntries()` and receive User B's decrypted entries, we've failed just as badly as if we'd never encrypted anything.

We use two complementary models:
- **RBAC (Role-Based Access Control):** "What can a *role* do?" — e.g., `admin`, `support`, `member`. Simple, coarse-grained, like a job title determining which doors your badge opens.
- **ABAC (Attribute-Based Access Control):** "What can this *specific* user do, given specific *attributes* of the request?" — e.g., "a `support` role may view a masked preview of a journal entry, but only if the user has an open support ticket, and never the full decrypted text." Finer-grained, contextual, like a badge that only opens a specific door during your assigned shift, for your assigned ticket.

**Why MindfulLog needs both:** RBAC alone can't express "support agents can see *masked* journal previews but never full decrypted text, and only for users who opted into support access via consent" — that requires attributes (consent state, specific record ownership) layered on top of a role check.

### The Implementation

**Step 1 — Define roles and attach them to Clerk's session claims**

We use Clerk's built-in **public metadata** feature to store a role per user, checked via Clerk's session claims (no need for a separate roles table for this simple three-role model).

```bash
# One-time setup: assign the admin role to your own test account via Clerk's
# dashboard (Users -> select user -> Public Metadata), setting:
# { "role": "admin" }
# All other users implicitly default to "member" if unset — Principle 2:
# Default Setting applied to permissions, not just data collection.
```

**File: `src/lib/auth/roles.ts`**
```typescript
import { auth } from "@clerk/nextjs/server";

export type Role = "member" | "support" | "admin";

/**
 * Reads the current user's role from Clerk's session claims. Defaults to
 * the LEAST privileged role ("member") if unset — an unset role must
 * never silently grant elevated access. This is Privacy as the Default
 * Setting (Principle 2) applied directly to authorization.
 */
export async function getCurrentRole(): Promise<Role> {
  const { sessionClaims } = await auth();
  const role = (sessionClaims?.publicMetadata as { role?: Role })?.role;
  return role ?? "member";
}
```

**Step 2 — Build the ABAC policy layer for journal entries**

**File: `src/lib/auth/policies.ts`**
```typescript
import { Role } from "./roles";

export type JournalAccessContext = {
  requestingUserId: string; // internal pseudonymous ID of whoever is asking
  requestingRole: Role;
  entryOwnerId: string; // internal pseudonymous ID of the entry's actual owner
  hasActiveSupportTicket: boolean; // an ABAC "attribute" — contextual, not just role
};

export type JournalAccessDecision =
  | { allowed: true; viewMode: "full" }
  | { allowed: true; viewMode: "masked" }
  | { allowed: false };

/**
 * The single, centralized policy function for journal entry access. Every
 * code path that reads a journal entry MUST pass through this function —
 * there is no other way for an entry to be considered "authorized to view."
 * Centralizing this in one function (rather than scattering `if` checks
 * across every route) means a security review only has ONE place to audit.
 */
export function evaluateJournalAccess(
  ctx: JournalAccessContext
): JournalAccessDecision {
  // Rule 1 (RBAC + ownership, the common case): a member can always fully
  // access their OWN entries. This is the only path 99% of requests take.
  if (ctx.requestingUserId === ctx.entryOwnerId) {
    return { allowed: true, viewMode: "full" };
  }

  // Rule 2 (ABAC): support agents may view a MASKED preview of someone
  // else's entry, but ONLY if there's an active support ticket tying them
  // to this specific user right now — role alone is not sufficient.
  if (ctx.requestingRole === "support" && ctx.hasActiveSupportTicket) {
    return { allowed: true, viewMode: "masked" };
  }

  // Rule 3 (RBAC): admins get full access for legitimate operational needs
  // (e.g., responding to a legal request) — but note this is the ONLY
  // role/path with unrestricted access, and every such access should be
  // logged (see Reference 3.A for audit-logging this decision point).
  if (ctx.requestingRole === "admin") {
    return { allowed: true, viewMode: "full" };
  }

  // Default-deny: anything not explicitly matched above is rejected. This
  // fail-closed design means a bug in policy logic tends to produce "access
  // denied" (safe, if annoying) rather than "access silently granted"
  // (dangerous). Never write an access-control function that defaults to
  // allow.
  return { allowed: false };
}
```

**Step 3 — Enforce the policy inside the Server Action**

**File: `src/app/actions/journal.ts`** (update `listJournalEntries` to support viewing another user's entries under policy control)
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/db";
import { journalEntries, users } from "@/db/schema";
import { encryptField, decryptField } from "@/lib/crypto/envelope";
import { maskFreeText } from "@/lib/security/mask";
import { getCurrentRole } from "@/lib/auth/roles";
import { evaluateJournalAccess } from "@/lib/auth/policies";
import { eq, desc } from "drizzle-orm";
import { revalidatePath } from "next/cache";

async function getInternalUserId(): Promise<string> {
  const { userId: clerkUserId } = await auth();
  if (!clerkUserId) {
    throw new Error("Not authenticated.");
  }

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

export async function createJournalEntry(plaintextBody: string): Promise<void> {
  if (plaintextBody.trim().length === 0) {
    throw new Error("Journal entry cannot be empty.");
  }

  const userId = await getInternalUserId();
  const bodyCiphertext = await encryptField(plaintextBody);

  await db.insert(journalEntries).values({
    userId,
    bodyCiphertext,
  });

  revalidatePath("/dashboard/journal");
}

export async function listJournalEntries(): Promise<
  Array<{ id: string; body: string; createdAt: Date }>
> {
  const userId = await getInternalUserId();

  const rows = await db.query.journalEntries.findMany({
    where: eq(journalEntries.userId, userId),
    orderBy: desc(journalEntries.createdAt),
  });

  const decrypted = [];
  for (const row of rows) {
    decrypted.push({
      id: row.id,
      body: await decryptField(row.bodyCiphertext),
      createdAt: row.createdAt,
    });
  }

  return decrypted;
}

/**
 * Support/admin tooling entry point: view a SPECIFIC user's journal entry
 * by ID, subject to the centralized ABAC policy. This function is the
 * ONLY way any code in this app is allowed to read another user's journal
 * data — it is never bypassed by a direct db.query call anywhere else in
 * the codebase (enforced by code review + the CI scanner in Part 6).
 */
export async function viewJournalEntryAsStaff(
  entryId: string,
  hasActiveSupportTicket: boolean
  hasActiveSupportTicket: boolean
): Promise<{ body: string; viewMode: "full" | "masked" }> {
  const requestingUserId = await getInternalUserId();
  const requestingRole = await getCurrentRole();

  const entry = await db.query.journalEntries.findFirst({
    where: eq(journalEntries.id, entryId),
  });

  if (!entry) {
    throw new Error("Journal entry not found.");
  }

  // The policy function is the ONLY gate. Notice we compute the decision
  // BEFORE doing any decryption — we never decrypt speculatively and then
  // decide whether to show it. Denying access means we never even ask the
  // KMS to unwrap the DEK, minimizing the window where plaintext could
  // exist in memory for an unauthorized read.
  const decision = evaluateJournalAccess({
    requestingUserId,
    requestingRole,
    entryOwnerId: entry.userId,
    hasActiveSupportTicket,
  });

  if (!decision.allowed) {
    // Fail loud and generic — never leak WHY access was denied (e.g.,
    // don't say "this entry belongs to another user"), since that itself
    // is information disclosure about the existence/ownership of a record.
    throw new Error("Access denied.");
  }

  const plaintext = await decryptField(entry.bodyCiphertext);

  if (decision.viewMode === "masked") {
    return { body: maskFreeText(plaintext), viewMode: "masked" };
  }

  return { body: plaintext, viewMode: "full" };
}
```

### The Verification

**Step 1 — Unit-test the policy function in complete isolation**

This is deliberately tested *without* touching the database or Clerk — the whole point of centralizing policy logic in a pure function is that it's trivially, exhaustively testable.

**File: `src/lib/auth/policies.test.ts`**
```typescript
import { describe, expect, it } from "vitest";
import { evaluateJournalAccess } from "./policies";

describe("evaluateJournalAccess", () => {
  it("allows a user full access to their own entry", () => {
    const decision = evaluateJournalAccess({
      requestingUserId: "user-1",
      requestingRole: "member",
      entryOwnerId: "user-1",
      hasActiveSupportTicket: false,
    });
    expect(decision).toEqual({ allowed: true, viewMode: "full" });
  });

  it("denies a member access to someone else's entry", () => {
    const decision = evaluateJournalAccess({
      requestingUserId: "user-1",
      requestingRole: "member",
      entryOwnerId: "user-2",
      hasActiveSupportTicket: false,
    });
    expect(decision).toEqual({ allowed: false });
  });

  it("allows support MASKED access only with an active ticket", () => {
    const withTicket = evaluateJournalAccess({
      requestingUserId: "support-1",
      requestingRole: "support",
      entryOwnerId: "user-2",
      hasActiveSupportTicket: true,
    });
    expect(withTicket).toEqual({ allowed: true, viewMode: "masked" });

    const withoutTicket = evaluateJournalAccess({
      requestingUserId: "support-1",
      requestingRole: "support",
      entryOwnerId: "user-2",
      hasActiveSupportTicket: false,
    });
    expect(withoutTicket).toEqual({ allowed: false });
  });

  it("allows admin full access regardless of ownership", () => {
    const decision = evaluateJournalAccess({
      requestingUserId: "admin-1",
      requestingRole: "admin",
      entryOwnerId: "user-2",
      hasActiveSupportTicket: false,
    });
    expect(decision).toEqual({ allowed: true, viewMode: "full" });
  });

  it("defaults to deny for any unrecognized combination (fail-closed)", () => {
    const decision = evaluateJournalAccess({
      requestingUserId: "random-1",
      // @ts-expect-error — deliberately testing an invalid role value
      requestingRole: "guest",
      entryOwnerId: "user-2",
      hasActiveSupportTicket: false,
    });
    expect(decision).toEqual({ allowed: false });
  });
});
```

```bash
npx vitest run src/lib/auth/policies.test.ts
```
All five tests should pass, most importantly the last one — proving that an unrecognized role/state combination fails closed (denies) rather than accidentally matching an `if` branch and granting access.

**Step 2 — Manual end-to-end check with two real accounts**

1. Sign up as **User A**, create a journal entry ("User A's private thought").
2. Sign up as **User B** in an incognito window.
3. As User B, attempt to call `viewJournalEntryAsStaff(entryIdFromUserA, false)` (e.g., wire this to a temporary debug button). Confirm it throws `"Access denied."`
4. In Clerk's dashboard, set User B's public metadata to `{ "role": "support" }`. Retry with `hasActiveSupportTicket = false` — should still be denied. Retry with `hasActiveSupportTicket = true` — should now succeed, and the returned `body` should be the **masked** string (e.g., `"Use*********** (redacted, 27 chars total)"`), never the full plaintext.
5. Set User B's role to `"admin"`. Retry — should now return the **full**, unmasked plaintext.

If every one of these five checks matches expectations, you've verified real, working zero-trust access control — not just a passing unit test in isolation, but the actual authorization boundary functioning against live Clerk sessions and real database rows.

---

## Part 3 — Reference Section: Deep Dives

*(Read now for depth, or skip ahead to Part 4 and return later.)*

### Reference 3.A — Why Every Cross-User Access Should Be Logged (and How)

Notice that Rule 3 in `evaluateJournalAccess` (admin full access) is the single most dangerous path in our entire policy — it's an intentional "break glass" capability for legitimate operational needs (e.g., fulfilling a legal order, investigating abuse), but it's also the path most valuable to an attacker who compromises an admin account. Real production systems pair this kind of rule with **mandatory audit logging**: every time `viewJournalEntryAsStaff` is invoked for an entry the requester doesn't own, an immutable log entry should record *who* accessed *whose* data, *when*, and *why* (ideally requiring a `reason` string parameter, not just silently allowing it). We build this pattern properly as part of the immutable consent ledger in Part 4, and it directly generalizes: any "break glass" access path deserves the same audit-log treatment we'll give consent decisions.

### Reference 3.B — The Sequential-Await Decryption Tradeoff

In `listJournalEntries`, we decrypt rows one at a time in a `for` loop rather than firing all KMS calls concurrently with `Promise.all`. This is a deliberate simplicity-over-throughput tradeoff for this series: sequential awaits are easier to read and reason about, and for a personal journaling app where a user has dozens (not tens of thousands) of entries, the latency difference is imperceptible. In a system with much higher row counts per request, you would batch KMS calls with `Promise.all` (mind your KMS provider's rate limits) or, more commonly, cache decrypted DEKs briefly in memory per-request when many rows share a small number of distinct data-owners — but that introduces its own plaintext-lifetime tradeoffs worth a dedicated design review before adopting in a real production system.

### Reference 3.C — Key Files vs. Workload Identity Federation

Section 3.3 generated a long-lived JSON service account key file (`gcp-kms-credentials.json`) for simplicity in local development. This is explicitly **not** the recommended pattern for a real production deployment: a leaked key file is a permanent credential until manually revoked. Production deployments on GCP should use **Workload Identity Federation**, which lets your deployed service (e.g., on Cloud Run, GKE, or even a properly configured Vercel integration) obtain short-lived, automatically-rotated credentials tied to its runtime identity, with no static file ever existing on disk. We call this out explicitly here rather than silently shipping an insecure-by-default pattern: treat the key-file approach in this Part as a *local development convenience only*, and revisit this reference before deploying MindfulLog anywhere real.

### Reference 3.D — Key Rotation: What It Actually Rotates

A common misconception is that "rotating the KEK" means re-encrypting every row in the database. It does not, in the envelope pattern. Rotating the KEK in Cloud KMS (via `gcloud kms keys versions create`) generates a *new version* of the same key; the KMS service transparently tracks which version encrypted which DEK and uses the correct version on decrypt, while all *new* encryptions automatically use the newest version. Existing encrypted DEKs remain valid and decryptable indefinitely (unless you explicitly disable/destroy an old key version, which you should only do long after confirming nothing still depends on it). This is precisely why envelope encryption exists: KEK rotation becomes a cheap, low-risk, frequent operation instead of a database-wide re-encryption migration.

---

## Part 3 — Summary & What Carries Forward

By completing Part 3, your repository now contains:

- ✅ A provisioned Cloud KMS key ring and KEK, with a minimally-scoped service account
- ✅ `src/lib/crypto/envelope.ts` — a fully tested envelope encryption library (encrypt/decrypt, tamper detection, unique ciphertext per call)
- ✅ `src/app/actions/journal.ts` — real Server Actions proving encryption is wired end-to-end from browser to database and back
- ✅ A working, verified proof that raw database access (`pg_dump`) yields zero readable plaintext
- ✅ `src/lib/auth/roles.ts` and `src/lib/auth/policies.ts` — a centralized, fail-closed RBAC/ABAC authorization layer with a full unit test suite

**What Part 4 inherits from here:** the `consentRecords` table (built in Part 2, unused until now) becomes central — Part 4 builds the actual consent-collection UI and the audit-logging pattern flagged in Reference 3.A above, extending the same "centralized policy function + immutable log" philosophy we just established for journal access into a full consent management system.

**Quick self-check before moving on:**
1. Can I explain, in one sentence, what a DEK is and why it's discarded after use rather than stored?
2. Did my `pg_dump` test in Section 3.5 Step 4 return zero matches for my test journal text?
3. Can I name the three outcomes `evaluateJournalAccess` can return, and under what exact conditions each occurs?
4. Do I understand why key rotation (Reference 3.D) doesn't require re-encrypting the whole database?
