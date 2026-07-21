# Primer 02 — Cryptography Basics

## For GreyMatter MindfulLog

Welcome to **Primer 02: Cryptography Basics**.

This primer introduces the cryptographic ideas we will rely on throughout **GreyMatter MindfulLog**, a privacy-first mental-health journaling application.

GreyMatter MindfulLog handles highly sensitive user data:

- mood notes,
- private journal entries,
- wellness reminders,
- consent history,
- export files,
- account deletion workflows,
- and operational logs.

Because this application may contain mental-health information, we cannot treat cryptography as an optional security upgrade. It is one of the core privacy controls in the system.

In the main build, sensitive mood notes and journal content are designed to be stored as encrypted binary database fields such as `notes_encrypted BYTEA` and `content_encrypted BYTEA`, rather than ordinary plaintext text columns [6]. Later, the application uses envelope encryption with AES-256-GCM and Google Cloud KMS so that sensitive data remains protected even if the database is exposed [5].

This primer explains the concepts behind that design.

---

# 1. Why Cryptography Matters in GreyMatter MindfulLog

A journaling app is not just another CRUD application.

A user might write:

- “I had a panic attack today.”
- “I changed my medication.”
- “I talked to my therapist.”
- “I’m struggling with depression.”
- “I don’t feel safe.”
- “I relapsed.”
- “I’m afraid someone will find out.”

That kind of data can cause real harm if exposed.

So GreyMatter MindfulLog should be built around this rule:

> Sensitive user content should not be readable from the database as plaintext.

This does not mean cryptography solves every privacy problem.

It does not replace:

- authentication,
- authorization,
- data minimization,
- consent,
- logging controls,
- deletion workflows,
- incident response,
- or vendor review.

But cryptography is a crucial layer.

It helps reduce damage when other layers fail.

For example:

| Failure | Cryptographic Protection |
|---|---|
| Database dump is stolen | Encrypted journal content remains unreadable without keys |
| Developer accidentally queries sensitive columns | Values are encrypted binary data |
| Database admin has broad access | Field-level encryption limits plaintext exposure |
| Backup is exposed | Encrypted fields remain protected |
| Logs accidentally include encrypted field | Ciphertext is less harmful than plaintext |

The goal is defense in depth.

Even if the database is breached or a developer makes a mistake, health data should remain protected through field-level encryption and centralized access control [5].

---

# 2. Cryptography Is Not Magic

Before learning specific tools, we need the right mindset.

Cryptography is powerful, but it is easy to misuse.

Bad cryptography can create a false sense of security.

Examples of dangerous mistakes:

- inventing your own encryption algorithm,
- using encryption without authentication,
- reusing nonces or IVs incorrectly,
- storing encryption keys next to encrypted data,
- logging plaintext before encryption,
- decrypting too broadly,
- sending plaintext sensitive content to background jobs,
- failing to rotate keys,
- confusing hashing with encryption,
- assuming encrypted data never needs access control.

In GreyMatter MindfulLog, cryptography must be paired with architecture.

That means:

- sensitive data is minimized before it is encrypted,
- encryption happens before database storage,
- keys are managed separately from data,
- access still goes through the policy engine,
- logs still redact sensitive fields,
- exports are temporary and auditable,
- deletion workflows understand encrypted records,
- incident response includes key rotation and recovery steps.

The final system combines encrypted schema design, envelope encryption, a centralized policy engine, append-only consent, DSAR/deletion pipelines, privacy CI/CD, and an incident playbook [1].

---

# 3. Core Vocabulary

## 3.1 Plaintext

**Plaintext** is readable data before encryption.

Example:

```txt
I felt anxious after my appointment today.
```

In GreyMatter MindfulLog, private notes and journal entries should exist as plaintext only briefly:

1. when the user submits them,
2. while the server validates them,
3. while the encryption function processes them,
4. when the authorized user later requests to read or export them.

Plaintext should not be stored in the database for sensitive free text.

---

## 3.2 Ciphertext

**Ciphertext** is encrypted data.

Example:

```txt
A7F9B23C9E9910...
```

Ciphertext should be unreadable without the correct key.

In the database, sensitive values should appear as binary encrypted data, not readable text.

That is why the schema uses fields such as:

```sql
notes_encrypted BYTEA
content_encrypted BYTEA
```

The main schema design uses `BYTEA` for encrypted mood notes and encrypted journal content [6].

---

## 3.3 Encryption

**Encryption** transforms plaintext into ciphertext.

Conceptually:

```txt
plaintext + key → ciphertext
```

Example:

```txt
"I feel better today" + secret key → encrypted bytes
```

Encryption is reversible if you have the right key.

That is important.

If you need to show the user their journal entry later, you need encryption, not hashing.

---

## 3.4 Decryption

**Decryption** transforms ciphertext back into plaintext.

Conceptually:

```txt
ciphertext + key → plaintext
```

Example:

```txt
encrypted bytes + secret key → "I feel better today"
```

Only authorized flows should decrypt sensitive content.

For GreyMatter MindfulLog, decryption may happen during:

- the user viewing their own journal entry,
- DSAR export generation,
- account portability,
- carefully controlled recovery workflows.

The DSAR export engine decrypts encrypted mood notes so they can be included in the user’s export [3].

---

## 3.5 Key

A **key** is secret material used by cryptographic algorithms.

If the key is exposed, the encrypted data may be exposed.

This means key management is just as important as encryption itself.

Bad:

```txt
Encrypted data and encryption key stored in the same database row.
```

Better:

```txt
Encrypted data stored in the database.
Key material protected separately through a key management system.
```

GreyMatter MindfulLog uses the concept of a Data Encryption Key, or DEK, for encrypting data, and a Key Encryption Key, or KEK, protected by Google Cloud KMS [5].

---

## 3.6 Algorithm

An **algorithm** is the mathematical procedure used for encryption, hashing, or signing.

Examples:

- AES-GCM,
- SHA-256,
- HMAC-SHA256,
- RSA,
- ECDSA,
- Argon2.

For field-level encryption in GreyMatter MindfulLog, the important algorithm is:

```txt
AES-256-GCM
```

The project’s encryption layer uses AES-256-GCM with envelope encryption and Google Cloud KMS [5].

---

# 4. Encoding Is Not Encryption

One of the most common beginner mistakes is confusing encoding with encryption.

Encoding changes the representation of data.

It does not protect it.

Example:

```txt
hello
```

Base64 encoded:

```txt
aGVsbG8=
```

Anyone can decode that.

Base64 is useful for transporting binary data as text, but it is not security.

Bad assumption:

```txt
We base64 encoded the journal entry, so it is safe.
```

Correct understanding:

```txt
Base64 is reversible without a secret key. It is not encryption.
```

Use encoding for formatting.

Use encryption for confidentiality.

---

# 5. Hashing

## 5.1 What Hashing Does

A **hash function** turns input into a fixed-length output.

Example:

```txt
hello → 2cf24dba5fb0a...
```

A cryptographic hash is designed to be one-way.

That means you should not be able to reverse the hash to recover the original input.

Conceptually:

```txt
input → hash
```

But not:

```txt
hash → input
```

Common hash functions include:

- SHA-256,
- SHA-384,
- SHA-512.

---

## 5.2 Hashing Is Not Encryption

Hashing is not encryption because hashing is not meant to be reversed.

Use hashing when you need to verify or fingerprint something.

Use encryption when you need to recover the original data later.

| Need | Use |
|---|---|
| Store journal content and read it later | Encryption |
| Verify a password | Password hashing |
| Fingerprint an IP address for rate limiting | HMAC |
| Store mood notes and export them later | Encryption |
| Check file integrity | Hashing |

Do not hash journal content if the user needs to read it later.

---

## 5.3 Hashing Example

```ts
import crypto from "crypto";

export function sha256(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}
```

This creates a hash.

But for identifiable data such as IP addresses, a plain hash may not be enough.

Why?

Because attackers can guess common values and hash them too.

For example, there are only so many possible IPv4 addresses.

That is where HMAC becomes useful.

---

# 6. HMAC

## 6.1 What HMAC Does

**HMAC** stands for Hash-based Message Authentication Code.

It is a keyed hash.

Conceptually:

```txt
input + secret key → HMAC value
```

Unlike a normal hash, an attacker cannot reproduce the HMAC without the secret key.

GreyMatter MindfulLog uses HMAC for values such as IP addresses when it needs a one-way fingerprint for rate limiting or abuse prevention without storing the raw IP address [6].

---

## 6.2 Why HMAC Is Useful for Privacy

Suppose we need to rate-limit repeated export requests.

We might want to know that the same IP address is making repeated requests.

But we do not necessarily want to store the raw IP address.

Instead of storing:

```txt
203.0.113.10
```

We can store:

```txt
hmac_sha256(203.0.113.10, secret_salt)
```

This lets us compare repeated requests without keeping the raw IP.

---

## 6.3 HMAC Example

```ts
import crypto from "crypto";

const HMAC_SALT = process.env.HMAC_SALT;

if (!HMAC_SALT) {
  throw new Error("HMAC_SALT is required");
}

export function hmacValue(value: string): string {
  return crypto
    .createHmac("sha256", HMAC_SALT)
    .update(value)
    .digest("hex");
}
```

This mirrors the privacy utility approach used in GreyMatter MindfulLog, where identifiable information can be transformed into a one-way fingerprint [6].

---

## 6.4 HMAC Is Still Personal Data Sometimes

Important:

> Pseudonymized data may still be personal data.

An HMAC of an IP address is safer than storing the raw IP address, but it may still relate to a user or device.

So HMAC values still need:

- retention limits,
- access controls,
- documentation in the DPIA,
- deletion or expiration rules,
- careful purpose limitation.

---

# 7. Symmetric Encryption

## 7.1 What Symmetric Encryption Means

In symmetric encryption, the same key is used to encrypt and decrypt.

Conceptually:

```txt
encrypt: plaintext + key → ciphertext
decrypt: ciphertext + key → plaintext
```

This is the style used for encrypting sensitive journal content.

AES is a symmetric encryption algorithm.

---

## 7.2 AES

**AES** stands for Advanced Encryption Standard.

It is a widely used symmetric encryption algorithm.

Common key sizes:

- AES-128,
- AES-192,
- AES-256.

GreyMatter MindfulLog uses AES-256-GCM for field-level encryption [5].

---

## 7.3 What “256” Means

In AES-256, the key is 256 bits long.

That is 32 bytes.

Example:

```ts
const key = crypto.randomBytes(32);
```

A 256-bit key is extremely strong when generated randomly and protected properly.

But AES-256 does not help if:

- the key is hardcoded,
- the key is logged,
- the key is stored beside the data,
- the key is reused incorrectly,
- the encryption mode is unsafe,
- plaintext is stored elsewhere.

Cryptography must be implemented correctly.

---

# 8. Authenticated Encryption

## 8.1 Confidentiality Is Not Enough

Encryption should protect confidentiality.

But we also need integrity.

Confidentiality answers:

```txt
Can someone read the data?
```

Integrity answers:

```txt
Has someone modified the data?
```

A secure field-level encryption design should protect both.

---

## 8.2 AES-GCM

AES-GCM is an authenticated encryption mode.

It provides:

- confidentiality,
- integrity,
- authenticity of encrypted data.

When using AES-GCM, encryption produces:

- ciphertext,
- authentication tag,
- IV/nonce.

The authentication tag helps detect tampering.

The GreyMatter MindfulLog encryption implementation uses AES-256-GCM and stores encrypted output along with the IV and authentication tag [5].

---

## 8.3 Why Authentication Tags Matter

Imagine an attacker cannot decrypt a journal entry but can modify encrypted bytes in the database.

Without integrity protection, the application might decrypt corrupted or manipulated data.

With AES-GCM, tampering should cause decryption to fail.

That is why AES-GCM is a good fit for sensitive field-level encryption.

---

# 9. IVs and Nonces

## 9.1 What Is an IV?

An IV, or initialization vector, is a value used during encryption to ensure that encrypting the same plaintext twice does not produce the same ciphertext.

In AES-GCM, this is often called a nonce.

For AES-GCM, a common IV size is 12 bytes.

The GreyMatter MindfulLog encryption function generates a random 12-byte IV before encrypting plaintext [5].

---

## 9.2 Why IV Reuse Is Dangerous

With AES-GCM, reusing the same key and IV combination can be catastrophic.

That means every encryption operation needs a unique IV for the key being used.

Bad:

```ts
const iv = Buffer.alloc(12); // all zeroes
```

Better:

```ts
const iv = crypto.randomBytes(12);
```

GreyMatter MindfulLog generates a fresh IV for encryption [5].

---

# 10. Randomness

Cryptography depends on strong randomness.

Randomness is needed for:

- encryption keys,
- IVs,
- tokens,
- reset links,
- export links,
- session secrets,
- salts.

Bad randomness:

```ts
Math.random()
```

Good randomness:

```ts
crypto.randomBytes(32)
```

In Node.js, use the built-in `crypto` module for cryptographic randomness.

Example:

```ts
import crypto from "crypto";

const key = crypto.randomBytes(32);
const iv = crypto.randomBytes(12);
```

The field encryption design generates a fresh 32-byte Data Encryption Key for AES-256 and a 12-byte IV for AES-GCM [5].

---

# 11. Key Management

## 11.1 The Hardest Part of Encryption

Encryption is often easier than key management.

The difficult questions are:

- Where are keys stored?
- Who can access them?
- How are they rotated?
- What happens if a key is compromised?
- Can old data still be decrypted?
- Are keys backed up?
- Are keys separated from encrypted data?
- Are development and production keys separate?
- Are keys visible to application developers?

If keys are mishandled, encryption can fail as a privacy control.

---

## 11.2 Do Not Hardcode Keys

Bad:

```ts
const ENCRYPTION_KEY = "super-secret-key";
```

Worse:

```ts
const ENCRYPTION_KEY = "12345678901234567890123456789012";
```

Better:

- use a key management system,
- keep secrets outside source code,
- restrict access,
- rotate keys,
- audit usage.

GreyMatter MindfulLog uses Google Cloud KMS for the Key Encryption Key, and the KEK never leaves Google’s hardware-backed protection model [5].

---

# 12. DEKs and KEKs

Envelope encryption uses two important kinds of keys.

## 12.1 Data Encryption Key

A **Data Encryption Key**, or **DEK**, encrypts the actual data.

Example:

```txt
DEK encrypts journal content.
```

In GreyMatter MindfulLog, a fresh 32-byte DEK is generated for each encryption operation [5].

---

## 12.2 Key Encryption Key

A **Key Encryption Key**, or **KEK**, encrypts or “wraps” the DEK.

Example:

```txt
KEK encrypts the DEK.
DEK encrypts the journal content.
```

The KEK is stored and managed in Google Cloud KMS.

The KEK should not be stored in the application database.

---

## 12.3 Why Use Two Keys?

You might ask:

> Why not just use one master key to encrypt all journal entries?

Because that creates unnecessary risk.

Envelope encryption allows:

- a fresh DEK per encrypted field,
- centralized KEK management,
- safer key rotation,
- separation between encrypted data and master key material,
- less direct exposure of long-term keys.

---

# 13. Envelope Encryption

## 13.1 The Concept

Envelope encryption works like this:

1. Generate a fresh DEK.
2. Encrypt the plaintext with the DEK.
3. Ask KMS to encrypt, or wrap, the DEK using the KEK.
4. Store the ciphertext and wrapped DEK together.
5. During decryption, unwrap the DEK through KMS.
6. Use the DEK to decrypt the ciphertext.

GreyMatter MindfulLog uses this pattern: data is encrypted with the DEK, then the DEK is wrapped with the KEK in Google Cloud KMS [5].

---

## 13.2 Envelope Encryption Analogy

Think of the user’s journal entry as a letter.

- The DEK is a small lockbox key.
- The journal entry goes into the lockbox.
- The KEK is a vault key managed by KMS.
- The lockbox key is placed into the vault.
- The database stores the locked box and the wrapped lockbox key.

If someone steals the database, they get:

- the locked box,
- the wrapped lockbox key,
- but not the vault key.

---

## 13.3 What Gets Stored

An encrypted field may store a packed binary value containing:

- wrapped DEK,
- IV,
- ciphertext,
- authentication tag.

The source implementation describes returning a single buffer containing these parts for storage [5].

Example conceptual layout:

```txt
[wrapped DEK][IV][ciphertext][auth tag]
```

In a production implementation, you may also include:

- version,
- algorithm identifier,
- KMS key ID,
- wrapped DEK length,
- metadata for future migrations.

A versioned format is better long term.

---

# 14. Example: Field Encryption Flow

Here is a simplified conceptual implementation.

```ts
import crypto from "crypto";

export function encryptWithDek(plaintext: string, dek: Buffer) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv("aes-256-gcm", dek, iv);

  const ciphertext = Buffer.concat([
    cipher.update(plaintext, "utf8"),
    cipher.final(),
  ]);

  const authTag = cipher.getAuthTag();

  return {
    iv,
    ciphertext,
    authTag,
  };
}
```

This only encrypts with a DEK.

The full GreyMatter MindfulLog approach also wraps the DEK using Google Cloud KMS [5].

---

# 15. Example: Conceptual Envelope Encryption

This is a teaching version, not the final production implementation.

```ts
import crypto from "crypto";

type WrappedDek = Buffer;

async function wrapDekWithKms(dek: Buffer): Promise<WrappedDek> {
  // In the real app, call Google Cloud KMS.
  return dek;
}

export async function encryptFieldConceptual(plaintext: string) {
  const dek = crypto.randomBytes(32);
  const iv = crypto.randomBytes(12);

  const cipher = crypto.createCipheriv("aes-256-gcm", dek, iv);

  const ciphertext = Buffer.concat([
    cipher.update(plaintext, "utf8"),
    cipher.final(),
  ]);

  const authTag = cipher.getAuthTag();
  const wrappedDek = await wrapDekWithKms(dek);

  return {
    wrappedDek,
    iv,
    ciphertext,
    authTag,
  };
}
```

The real application should use a real KMS client instead of the placeholder `wrapDekWithKms`.

---

# 16. What Not to Encrypt

Not every field needs encryption.

Encryption has tradeoffs:

- encrypted data is harder to search,
- encrypted data is harder to index,
- encrypted data can complicate analytics,
- encrypted data requires key management,
- encrypted data must be carefully decrypted for export.

So we encrypt based on sensitivity.

Example:

| Field | Encrypt? | Reason |
|---|---:|---|
| mood_score | Usually no | Numeric, minimized, useful for trends |
| mood_notes | Yes | Sensitive free text |
| journal_content | Yes | Highly sensitive free text |
| reminder_label | Prefer yes or minimize | May reveal medication or health behavior |
| consent_purpose | Usually no | Needed for audit and current state |
| consent_decision | Usually no | Needed for audit and current state |
| email | Avoid storing locally | Prefer auth provider |
| IP address | Do not store raw | Use HMAC if needed |

The schema intentionally stores mood score as a plain constrained integer while storing notes and journal content as encrypted binary fields [6].

---

# 17. Search and Encryption

Encryption affects search.

If journal content is encrypted, you cannot easily run:

```sql
SELECT * FROM journal_entries
WHERE content ILIKE '%anxiety%';
```

That is a feature, not just a limitation.

It means the database cannot casually inspect private text.

If search is needed later, you must design it carefully.

Possible approaches:

1. Client-side search after decrypting user-owned records.
2. Search over user-created tags that are less sensitive.
3. Encrypted search techniques.
4. Explicit opt-in indexing with clear consent.
5. Local-only search in the browser.

For GreyMatter MindfulLog, the safer starting position is:

> Do not build plaintext full-text search over private journal content.

---

# 18. Logging and Cryptography

Encryption does not help if plaintext is logged before encryption.

Bad:

```ts
safeLog("info", "creating_entry", {
  content: journalContent,
});
```

Better:

```ts
safeLog("info", "creating_entry", {
  entryId,
  userIdHash,
});
```

The project includes a PII-redacting logger concept that redacts sensitive values such as notes, content, email, phone, and encrypted notes before logging [2].

But redaction should be a backup layer.

The best approach is not to pass sensitive plaintext into logs at all.

---

# 19. DSAR Export and Decryption

DSAR export is one of the few places where bulk decryption is expected.

If the user requests an export, the system needs to collect their data and include readable copies.

For encrypted mood notes, the export process decrypts `notes_encrypted` and includes the plaintext note in the export file [3].

That means DSAR export must be treated as a sensitive workflow.

A good export system should ensure:

- the user is authenticated,
- authorization is checked,
- export generation is logged,
- the export is temporary,
- the export is access-controlled,
- generated files expire,
- plaintext is not written to permanent logs,
- background job payloads do not contain unnecessary plaintext.

The source design describes DSAR export as complete, verifiable, and temporary, using durable background processing [3].

---

# 20. Deletion and Encrypted Data

Encryption is not a replacement for deletion.

If a user deletes their account, encrypted records should still be deleted or anonymized according to the deletion policy.

Do not say:

```txt
We do not need to delete it because it is encrypted.
```

Encryption reduces risk.

Deletion respects user rights.

In GreyMatter MindfulLog, the deletion orchestrator deletes local mood logs, journal entries, and reminders, and anonymizes the consent ledger to preserve audit value without keeping the original user identity [3].

---

# 21. Key Rotation

## 21.1 What Is Key Rotation?

Key rotation means replacing old cryptographic keys with new ones.

Why rotate keys?

- reduce impact of possible compromise,
- meet operational security requirements,
- improve cryptographic hygiene,
- retire old key versions,
- support incident response.

The incident response plan uses Google Cloud KMS versioning for annual KEK rotation and creates new DEKs per encryption operation [1].

---

## 21.2 DEK Rotation vs. KEK Rotation

There are different levels of rotation.

### DEK Rotation

Changing the key that encrypts the actual data.

This may require decrypting and re-encrypting every affected field.

### KEK Rotation

Changing the key that wraps the DEKs.

This can sometimes be easier because you may only need to rewrap DEKs rather than re-encrypt all data.

Envelope encryption makes this easier to manage.

---

## 21.3 Rotation During Incidents

If keys may be compromised, incident response should include:

- disabling compromised key versions,
- rotating KEKs,
- rewrapping DEKs,
- re-encrypting affected data if necessary,
- reviewing logs,
- updating the DPIA,
- notifying users or regulators if required.

The incident response playbook includes containment actions such as revoking sessions and rotating keys [1].

---

# 22. Passwords Are Different

Do not encrypt passwords.

Passwords should be hashed with a password-hashing algorithm designed for that purpose, such as:

- Argon2id,
- bcrypt,
- scrypt,
- PBKDF2.

GreyMatter MindfulLog uses Clerk for authentication, so password handling is delegated to the identity provider rather than implemented directly in the application.

That is a good architectural choice because authentication is complex and high risk.

However, vendor use still needs review in the vendor register.

---

# 23. Transport Encryption

Field-level encryption protects data stored in the database.

But data also needs protection in transit.

Use HTTPS everywhere.

Conceptually:

```txt
Browser → HTTPS → Next.js Server
```

Transport encryption protects data moving between the user’s browser and your server.

But HTTPS does not replace field-level encryption.

| Protection | Protects |
|---|---|
| HTTPS | Data in transit |
| Field-level encryption | Sensitive fields at rest |
| KMS | Key management |
| Policy engine | Access authorization |
| Safe logger | Operational leakage |
| CI scanner | Developer mistakes |

The high-level architecture requires HTTPS between the browser and Next.js server, then uses validation, rate limiting, policy enforcement, logging, encryption, Neon Postgres, Google Cloud KMS, Inngest, and Clerk as part of the privacy-first system [8].

---

# 24. Cryptography and the Database Schema

A privacy-first schema makes unsafe storage harder.

Bad:

```sql
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  content TEXT NOT NULL
);
```

This stores private journal content as readable text.

Better:

```sql
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  content_encrypted BYTEA NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

The source schema uses `content_encrypted BYTEA NOT NULL` for journal entries and `notes_encrypted BYTEA` for mood logs [6].

This makes the schema itself communicate the privacy expectation.

Developers can see:

```txt
This is encrypted content.
Do not treat it as ordinary text.
```

---

# 25. Cryptography and CI/CD

Cryptographic expectations should be enforced automatically.

For example, the privacy scanner can fail the build if a developer adds suspicious plaintext columns such as:

```sql
notes TEXT
content TEXT
health TEXT
password TEXT
email TEXT
```

without encryption or binary storage.

The PII schema scanner checks for sensitive patterns like `email`, `phone`, `ssn`, `notes`, `content`, `health`, and `password`, and fails if they are not encrypted or stored as `bytea` [2].

This is important because privacy rules should not depend only on human memory.

---

# 26. Practical Rules for GreyMatter MindfulLog

## Rule 1: Do Not Store Sensitive Free Text as Plaintext

Bad:

```sql
notes TEXT
journal_content TEXT
```

Good:

```sql
notes_encrypted BYTEA
content_encrypted BYTEA
```

---

## Rule 2: Encrypt Before Insert

Bad:

```ts
await sql`
  INSERT INTO journal_entries (user_id, content_encrypted)
  VALUES (${userId}, ${plaintextContent})
`;
```

Good:

```ts
const encrypted = await encryptField(plaintextContent);

await sql`
  INSERT INTO journal_entries (user_id, content_encrypted)
  VALUES (${userId}, ${encrypted})
`;
```

---

## Rule 3: Decrypt Only When Needed

Bad:

```ts
const entries = await getAllEntries();
const decrypted = await decryptEverything(entries);
```

Good:

```ts
const entry = await getEntryForAuthorizedUser(userId, entryId);
const plaintext = await decryptField(entry.content_encrypted);
```

---

## Rule 4: Never Log Plaintext

Bad:

```ts
console.log("journal content", plaintext);
```

Good:

```ts
safeLog("info", "journal_entry_created", {
  userIdHash,
  entryId,
});
```

---

## Rule 5: Keep Keys Out of Source Code

Bad:

```ts
const key = "abc123";
```

Good:

```ts
const keyName = process.env.KMS_KEY_NAME;
```

The KMS key name is configuration. The actual key material should remain in KMS.

---

## Rule 6: Use KMS for KEKs

The KEK should be managed by a key management system.

GreyMatter MindfulLog uses Google Cloud KMS for the KEK, while fresh DEKs encrypt individual fields [5].

---

## Rule 7: Plan for Rotation

Key rotation should not be an afterthought.

Document:

- how KEKs rotate,
- how DEKs are generated,
- how old data remains decryptable,
- how compromised keys are handled,
- how rotation is tested.

---

# 27. Mini Exercise: Choose the Right Primitive

For each situation, choose encryption, hashing, HMAC, or neither.

| Situation | Best Choice | Why |
|---|---|---|
| Store journal entry so user can read it later | Encryption | Must be reversible |
| Store mood note privately | Encryption | Sensitive free text |
| Verify file was not modified | Hash | Integrity fingerprint |
| Store password | Password hashing | Special slow hash required |
| Rate-limit by IP without storing raw IP | HMAC | One-way keyed fingerprint |
| Store mood score 1–10 | Neither, usually | Minimized numeric value |
| Store consent decision | Neither, usually | Needs audit/queryability |
| Store raw access token | Do not store | Avoid if possible |

---

# 28. Mini Exercise: Find the Problems

Review this code:

```ts
export async function createMoodLog(userId: string, score: number, notes: string) {
  console.log("Creating mood log", { userId, score, notes });

  await sql`
    INSERT INTO mood_logs (user_id, mood_score, notes)
    VALUES (${userId}, ${score}, ${notes})
  `;
}
```

Problems:

1. Logs sensitive notes.
2. Stores notes in plaintext.
3. Uses a plaintext `notes` column instead of `notes_encrypted`.
4. Does not validate score range.
5. Does not show authorization context.
6. Does not use field-level encryption.
7. Does not use safe logging.

A safer version:

```ts
import { encryptField } from "@/lib/encryption";
import { safeLog } from "@/lib/safe-logger";

export async function createMoodLog(userId: string, score: number, notes?: string) {
  if (score < 1 || score > 10) {
    throw new Error("Mood score must be between 1 and 10");
  }

  const encryptedNotes = notes ? await encryptField(notes) : null;

  await sql`
    INSERT INTO mood_logs (user_id, mood_score, notes_encrypted)
    VALUES (${userId}, ${score}, ${encryptedNotes})
  `;

  safeLog("info", "mood_log_created", {
    userId,
    hasNotes: Boolean(notes),
  });
}
```

In a production implementation, you would also avoid logging raw `userId` if it is sensitive in your context and would use a hashed or internal identifier where appropriate.

---

# 29. Cryptography Review Checklist

Use this checklist when adding any feature that stores or processes sensitive data.

## Data Classification

- [ ] Is this data personal?
- [ ] Is this data sensitive?
- [ ] Is this data health-related?
- [ ] Can we avoid collecting it?
- [ ] Can we minimize it?

## Encryption

- [ ] Does the data need to be readable later?
- [ ] If yes, is field-level encryption required?
- [ ] Is AES-GCM or another authenticated encryption mode used?
- [ ] Is a fresh IV/nonce generated?
- [ ] Is key material kept out of source code?
- [ ] Is KMS used for key wrapping?

## Key Management

- [ ] Are DEKs generated securely?
- [ ] Is the KEK managed by KMS?
- [ ] Is key access restricted?
- [ ] Is key rotation documented?
- [ ] Is incident key rotation documented?

## Storage

- [ ] Is sensitive free text stored as encrypted binary?
- [ ] Does the column name make encryption obvious?
- [ ] Does the DPIA document the field?
- [ ] Does the privacy scanner catch unsafe alternatives?

## Access

- [ ] Is decryption limited to authorized flows?
- [ ] Does access go through the policy engine?
- [ ] Are support views masked?
- [ ] Are admin actions auditable?

## Logs

- [ ] Is plaintext excluded from logs?
- [ ] Does the safe logger redact sensitive keys?
- [ ] Are errors sanitized?
- [ ] Are encrypted blobs also treated carefully?

## Export and Deletion

- [ ] Is encrypted data decrypted correctly for user export?
- [ ] Is export temporary and auditable?
- [ ] Is encrypted data deleted during account deletion?
- [ ] Are consent/audit records anonymized when needed?

---

# 30. Key Takeaways

Cryptography in GreyMatter MindfulLog exists to reduce harm.

The most important lessons are:

1. Encoding is not encryption.
2. Hashing is not encryption.
3. Use encryption when data must be recovered later.
4. Use HMAC for keyed one-way fingerprints.
5. Use authenticated encryption for sensitive content.
6. AES-256-GCM provides confidentiality and integrity.
7. Generate fresh random DEKs and IVs.
8. Protect KEKs with a key management system.
9. Store sensitive free text as encrypted binary data.
10. Do not log plaintext before or after encryption.
11. Decrypt only in authorized, necessary flows.
12. Encryption does not replace deletion, consent, access control, or incident response.

For GreyMatter MindfulLog, cryptography is not just a security feature.

It is a privacy architecture requirement.

---

# 31. Completion Criteria

You have completed this primer when you can explain:

- the difference between plaintext and ciphertext,
- why encoding is not encryption,
- the difference between hashing and encryption,
- what HMAC is used for,
- why AES-GCM is useful,
- what IVs/nonces do,
- why key reuse can be dangerous,
- what DEKs and KEKs are,
- how envelope encryption works,
- why KMS is useful,
- why sensitive journal content should be stored as `BYTEA`,
- why encryption does not replace access control,
- why encryption does not replace deletion,
- and why logs must never contain plaintext sensitive content.
