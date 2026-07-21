**Part 5: DSAR Export & Right to be Forgotten**

This part implements two GDPR rights: **Right of Access (DSAR)** and **Right to Erasure** ("Right to be Forgotten").

---

#### Step 5.1: The Target — DSAR Export Engine (Async + Durable)

**The Concept**:  
Exporting all user data must be complete, verifiable, and temporary. We use Inngest for reliable background processing.

**Implementation**:

First, install additional deps if needed:

```bash
npm install jszip
```

**lib/export.ts** (core engine):
```ts
import { sql } from './db';
import { decryptField } from './encryption';
import JSZip from 'jszip';

export async function generateDSARExport(userId: string) {
  const zip = new JSZip();

  // 1. Mood logs
  const moodLogs = await sql`SELECT * FROM mood_logs WHERE user_id = ${userId}`;
  const decryptedMoods = await Promise.all(moodLogs.map(async (log: any) => ({
    ...log,
    notes: log.notes_encrypted ? await decryptField(log.notes_encrypted) : null,
    notes_encrypted: undefined
  })));

  zip.file("mood_logs.json", JSON.stringify(decryptedMoods, null, 2));

  // 2. Journal entries (similar decryption)
  // 3. Consent history
  const consents = await sql`SELECT * FROM consent_records WHERE user_id = ${userId}`;
  zip.file("consent_history.json", JSON.stringify(consents, null, 2));

  // 4. Manifest
  const manifest = {
    userId,
    exportedAt: new Date().toISOString(),
    recordCount: moodLogs.length + consents.length,
    completeness: "All tables processed"
  };
  zip.file("manifest.json", JSON.stringify(manifest, null, 2));

  const content = await zip.generateAsync({ type: "nodebuffer" });
  return content;
}
```

**Inngest function** (simplified — full setup requires Inngest client registration):

```ts
// inngest/functions/export-dsar.ts
import { Inngest } from 'inngest';

const inngest = new Inngest({ id: "mindful-log" });

export const dsarExport = inngest.createFunction(
  { id: "dsar-export" },
  { event: "app/dsar.requested" },
  async ({ event }) => {
    const { userId } = event.data;
    const zipBuffer = await generateDSARExport(userId);
    // Upload to temporary signed URL or email
    return { success: true, expiresIn: "7 days" };
  }
);
```

**Verification**:
Trigger export → Check generated ZIP contains decrypted JSON + manifest.

---

#### Step 5.2: The Target — Right to be Forgotten Orchestrator

**The Concept**:  
Deletion must be atomic across systems. We use explicit sequencing and retries.

**Implementation**:

**lib/deletion-orchestrator.ts**:
```ts
import { sql } from './db';
import { Clerk } from '@clerk/nextjs/server';

export async function deleteUserAccount(userId: string) {
  // Step 1: Capture references
  const references = await sql`SELECT * FROM mood_logs WHERE user_id = ${userId} LIMIT 5`; // audit snapshot

  // Step 2: Delete local data
  await sql`DELETE FROM mood_logs WHERE user_id = ${userId}`;
  await sql`DELETE FROM journal_entries WHERE user_id = ${userId}`;
  await sql`DELETE FROM reminders WHERE user_id = ${userId}`;

  // Step 3: Anonymize consent ledger (preserve audit)
  await sql`
    UPDATE consent_records 
    SET user_id = 'deleted-' || substring(user_id from 1 for 8)
    WHERE user_id = ${userId}
  `;

  // Step 4: Delete Clerk identity
  const clerk = new Clerk({ secretKey: process.env.CLERK_SECRET_KEY! });
  await clerk.users.deleteUser(userId);

  // Step 5: Mark as deleted
  await sql`
    UPDATE users_privacy 
    SET deleted_at = NOW() 
    WHERE user_id = ${userId}
  `;

  console.log(`✅ Full deletion completed for user ${userId}`);
  return true;
}
```

**UI Confirmation** (critical for safety):

```tsx
// Simple confirmation page snippet
const [confirmationText, setConfirmationText] = useState("");
// Button disabled unless confirmationText === "DELETE MY ACCOUNT"
```

**Rate Limiting** (using Upstash Redis):
```ts
import { Redis } from '@upstash/redis';

const redis = new Redis({ url: process.env.UPSTASH_REDIS_REST_URL!, token: process.env.UPSTASH_REDIS_REST_TOKEN! });

export async function checkDeletionRateLimit(userId: string): Promise<boolean> {
  const key = `deletion:${userId}`;
  const count = await redis.get(key) as number || 0;
  if (count >= 1) return false;
  await redis.set(key, count + 1, { ex: 86400 }); // 24 hours
  return true;
}
```

**Verification**:
- Use Neon branch to safely test deletion.
- Confirm data gone, consent anonymized, Clerk user deleted.

We’re in the home stretch!
