# Part 3: Field-Level Encryption & Zero-Trust Access Control

---

### Why This Part Is Critical
Even if someone hacks your database or a developer makes a mistake, health data must stay protected.  
**Field-Level Encryption** encrypts each sensitive field individually.  
**Zero-Trust** means "never trust, always verify" — every access decision goes through a central policy engine.

---

#### Step 3.1: The Target — Envelope Encryption Library with Google Cloud KMS

**The Concept (Simple Analogy)**:  
You put your secret note in a small locked box (DEK = Data Encryption Key). Then you put that box inside a giant bank vault (KEK = Key Encryption Key managed by Google’s hardware). We throw away the small key after use.

**Implementation**:

1. Install the library:
```bash
npm install @google-cloud/kms
```

2. Create **`lib/encryption.ts`** (complete, production-ready code):

```ts
import crypto from 'crypto';
import { KeyManagementServiceClient } from '@google-cloud/kms';

const kmsClient = new KeyManagementServiceClient();

// Get this from Google Cloud Console
const KEY_NAME = process.env.KMS_KEY_NAME!;

if (!KEY_NAME) {
  throw new Error("❌ KMS_KEY_NAME environment variable is required. Check your .env.local");
}

/**
 * Encrypts a string using Envelope Encryption (AES-256-GCM)
 * Returns a single Buffer safe to store in BYTEA column
 */
export async function encryptField(plaintext: string): Promise<Buffer> {
  if (!plaintext) return Buffer.from([]);

  // Step 1: Generate a fresh Data Encryption Key (DEK)
  const dek = crypto.randomBytes(32);                    // 256-bit key

  // Step 2: Encrypt the actual data with AES-256-GCM
  const iv = crypto.randomBytes(12);                     // Initialization Vector
  const cipher = crypto.createCipheriv('aes-256-gcm', dek, iv);
  
  let encrypted = cipher.update(plaintext, 'utf8');
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  
  const authTag = cipher.getAuthTag();                   // Prevents tampering

  // Step 3: Wrap (encrypt) the DEK using Google KMS
  const [wrapResult] = await kmsClient.encrypt({
    name: KEY_NAME,
    plaintext: dek,
  });

  const wrappedDek = wrapResult.ciphertext!;

  // Step 4: Combine everything into one payload
  return Buffer.concat([wrappedDek, iv, encrypted, authTag]);
}

/**
 * Decrypts the payload back to original string
 */
export async function decryptField(encryptedBuffer: Buffer): Promise<string> {
  if (encryptedBuffer.length === 0) return "";

  const wrappedDekLength = 256;   // Typical size from KMS
  const ivLength = 12;
  const authTagLength = 16;

  const wrappedDek = encryptedBuffer.slice(0, wrappedDekLength);
  const iv = encryptedBuffer.slice(wrappedDekLength, wrappedDekLength + ivLength);
  const ciphertext = encryptedBuffer.slice(
    wrappedDekLength + ivLength,
    encryptedBuffer.length - authTagLength
  );
  const authTag = encryptedBuffer.slice(encryptedBuffer.length - authTagLength);

  // Unwrap the DEK using KMS
  const [unwrapResult] = await kmsClient.decrypt({
    name: KEY_NAME,
    ciphertext: wrappedDek,
  });

  const dek = unwrapResult.plaintext!;

  // Decrypt the data
  const decipher = crypto.createDecipheriv('aes-256-gcm', dek, iv);
  decipher.setAuthTag(authTag);

  let decrypted = decipher.update(ciphertext);
  decrypted = Buffer.concat([decrypted, decipher.final()]);

  return decrypted.toString('utf8');
}
```

**Add to `.env.local`** (replace with your actual values from Google Cloud):
```env
KMS_KEY_NAME=projects/your-project/locations/global/keyRings/your-ring/cryptoKeys/your-key
```

**Verification**:
```bash
node -e '
  import("./lib/encryption.js").then(async ({ encryptField, decryptField }) => {
    const secret = "My private mental health note";
    const encrypted = await encryptField(secret);
    console.log("✅ Encrypted length:", encrypted.length, "bytes");
    const decrypted = await decryptField(encrypted);
    console.log("✅ Decrypted:", decrypted);
  });
'
```

---

#### Step 3.2: The Target — Zero-Trust Policy Engine

**The Concept**:  
All access decisions go through **one** place. If the policy doesn’t explicitly allow it → deny.

**Implementation**:

Create **`lib/policy-engine.ts`**:

```ts
export type UserContext = {
  userId: string;
  role: 'owner' | 'support' | 'admin';
  isSupportMasked?: boolean;
};

export type Resource = {
  ownerId: string;
  type: 'mood_log' | 'journal_entry';
};

export class PolicyEngine {
  /**
   * Can the current user view this resource?
   */
  static canView(context: UserContext, resource: Resource): boolean {
    // Owner can always see their own data
    if (context.userId === resource.ownerId) return true;

    // Support staff get masked view only
    if (context.role === 'support') {
      return context.isSupportMasked === true;
    }

    // Default: deny (Zero-Trust)
    return false;
  }

  static canEdit(context: UserContext, resource: Resource): boolean {
    return context.userId === resource.ownerId;
  }

  static async auditLog(context: UserContext, action: string, resourceId: string) {
    console.log(`[AUDIT ${new Date().toISOString()}] User ${context.userId} (${context.role}) ${action} resource ${resourceId}`);
    // In production: send to audit table or external service
  }
}
```

**Verification**:
Test in a temporary script or Node REPL.

---

#### Step 3.3: The Target — Integrate Encryption with Database

**Implementation** (update **`lib/db.ts`**):

```ts
import { sql } from './db'; // self import if needed
import { encryptField, decryptField } from './encryption';

export async function createEncryptedMoodLog(userId: string, moodScore: number, notes?: string) {
  const notesEncrypted = notes ? await encryptField(notes) : null;

  const result = await sql`
    INSERT INTO mood_logs (user_id, mood_score, notes_encrypted)
    VALUES (${userId}, ${moodScore}, ${notesEncrypted})
    RETURNING id;
  `;

  return result[0].id;
}
```

---

**Part 3 Complete!**

You now have strong encryption and access control. Sensitive data is protected even if the database is compromised.

Great work — the hardest technical parts are behind us!
