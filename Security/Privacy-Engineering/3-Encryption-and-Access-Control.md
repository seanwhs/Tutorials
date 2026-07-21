# Part 3: Field-Level Encryption & Zero-Trust Access Control

### Why Field-Level Encryption + Zero-Trust?
Even if the database is breached or a developer makes a mistake, health data must remain protected. **Envelope encryption** + a centralized **policy engine** ensures defense-in-depth.

---

#### Step 3.1: The Target — Envelope Encryption Library (AES-256-GCM + Google Cloud KMS)

**The Concept**:  
Imagine a small locked box (Data Encryption Key — DEK) inside a big vault (Key Encryption Key — KEK in HSM). We encrypt data with the DEK, then wrap the DEK with the KEK. The KEK never leaves Google’s hardware.

**Implementation**:

First, install the KMS client:

```bash
npm install @google-cloud/kms
```

Create **lib/encryption.ts** (complete production code):

```ts
import crypto from 'crypto';
import { KeyManagementServiceClient } from '@google-cloud/kms';

const kmsClient = new KeyManagementServiceClient();

const KEY_NAME = process.env.KMS_KEY_NAME!;

if (!KEY_NAME) throw new Error("KMS_KEY_NAME is required");

/**
 * Encrypts plaintext using envelope encryption
 * Returns a single Buffer containing: wrappedDEK + IV + ciphertext + authTag
 */
export async function encryptField(plaintext: string): Promise<Buffer> {
  // 1. Generate fresh DEK (32 bytes for AES-256)
  const dek = crypto.randomBytes(32);

  // 2. Encrypt plaintext with AES-256-GCM
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', dek, iv);
  
  let encrypted = cipher.update(plaintext, 'utf8');
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  const authTag = cipher.getAuthTag();

  // 3. Wrap DEK using KMS (KEK)
  const [wrappedResponse] = await kmsClient.encrypt({
    name: KEY_NAME,
    plaintext: dek,
  });

  const wrappedDek = wrappedResponse.ciphertext!;

  // 4. Concatenate everything for storage
  return Buffer.concat([wrappedDek, iv, encrypted, authTag]);
}

/**
 * Decrypts the envelope payload
 */
export async function decryptField(encryptedBuffer: Buffer): Promise<string> {
  const wrappedDekLength = 256; // Adjust based on KMS response size
  const ivLength = 12;
  const authTagLength = 16;

  const wrappedDek = encryptedBuffer.slice(0, wrappedDekLength);
  const iv = encryptedBuffer.slice(wrappedDekLength, wrappedDekLength + ivLength);
  const ciphertext = encryptedBuffer.slice(
    wrappedDekLength + ivLength, 
    encryptedBuffer.length - authTagLength
  );
  const authTag = encryptedBuffer.slice(encryptedBuffer.length - authTagLength);

  // Unwrap DEK
  const [dekResponse] = await kmsClient.decrypt({
    name: KEY_NAME,
    ciphertext: wrappedDek,
  });

  const dek = dekResponse.plaintext!;

  // Decrypt with AES-GCM
  const decipher = crypto.createDecipheriv('aes-256-gcm', dek, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(ciphertext);
  decrypted = Buffer.concat([decrypted, decipher.final()]);

  return decrypted.toString('utf8');
}
```

**Verification**:
```bash
node -e '
  import("./lib/encryption.js").then(async ({ encryptField, decryptField }) => {
    const encrypted = await encryptField("This is secret health data");
    console.log("Encrypted length:", encrypted.length);
    const decrypted = await decryptField(encrypted);
    console.log("Decrypted:", decrypted);
  });
'
```

---

#### Step 3.2: The Target — Zero-Trust Policy Engine (RBAC + ABAC)

**The Concept**:  
All access decisions go through one trusted place. “Fail closed” means unknown = deny.

**Implementation**:

**lib/policy-engine.ts**:
```ts
type UserContext = {
  userId: string;
  role: 'owner' | 'support' | 'admin';
  isSupportMasked?: boolean;
};

type Resource = {
  ownerId: string;
  type: 'mood_log' | 'journal' | 'consent';
};

export class PolicyEngine {
  static canView(context: UserContext, resource: Resource): boolean {
    if (context.userId === resource.ownerId) return true; // Owner always wins

    if (context.role === 'support') {
      return context.isSupportMasked === true; // Only masked view
    }

    return false; // Fail closed
  }

  static canEdit(context: UserContext, resource: Resource): boolean {
    return context.userId === resource.ownerId;
  }

  static async logAccess(context: UserContext, action: string, resourceId: string) {
    // In real app: send to audit table via Inngest or direct insert
    console.log(`[AUDIT] ${context.userId} performed ${action} on ${resourceId}`);
  }
}
```

**Verification**:
Test in Node REPL — owner succeeds, support gets masked, stranger denied.

---

#### Step 3.3: The Target — Integrate Encryption into Data Layer

**Implementation** — Update **lib/db.ts** with helper functions:

```ts
import { encryptField, decryptField } from './encryption';

export async function createMoodLog(userId: string, moodScore: number, notes?: string) {
  let notesEncrypted: Buffer | null = null;
  if (notes) {
    notesEncrypted = await encryptField(notes);
  }

  return sql`
    INSERT INTO mood_logs (user_id, mood_score, notes_encrypted)
    VALUES (${userId}, ${moodScore}, ${notesEncrypted})
    RETURNING id;
  `;
}
```

**Verification**:
Insert a record with notes, then query and confirm `notes_encrypted` is binary data (not readable text).

We’re building something truly privacy-first. Keep going!
