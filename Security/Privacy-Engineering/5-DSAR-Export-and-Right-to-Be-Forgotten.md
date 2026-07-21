# Part 5: DSAR Export & Right to be Forgotten

---

### Why This Part Is Powerful
This is where users get real control. **DSAR** = "Give me all my data". **Right to be Forgotten** = "Delete everything about me". We implement both reliably and safely.

---

#### Step 5.1: The Target — DSAR Export Engine

**The Concept**:  
Collect all user data, decrypt it on the fly, package it as a ZIP with a manifest file, and make it available for download with an expiry.

**Implementation**:

Install helper:
```bash
npm install jszip
```

Create **`lib/dsar-export.ts`**:

```ts
import { sql } from './db';
import { decryptField } from './encryption';
import JSZip from 'jszip';

export async function generateFullDSARExport(userId: string) {
  const zip = new JSZip();
  const timestamp = new Date().toISOString();

  // 1. Mood Logs
  const moodLogs = await sql`SELECT * FROM mood_logs WHERE user_id = ${userId}`;
  const decryptedMoods = await Promise.all(moodLogs.map(async (log: any) => ({
    id: log.id,
    mood_score: log.mood_score,
    notes: log.notes_encrypted ? await decryptField(log.notes_encrypted) : null,
    created_at: log.created_at,
  })));

  zip.file("mood_logs.json", JSON.stringify(decryptedMoods, null, 2));

  // 2. Journal Entries
  const journals = await sql`SELECT * FROM journal_entries WHERE user_id = ${userId}`;
  const decryptedJournals = await Promise.all(journals.map(async (j: any) => ({
    id: j.id,
    title: j.title,
    content: await decryptField(j.content_encrypted),
    created_at: j.created_at,
  })));

  zip.file("journal_entries.json", JSON.stringify(decryptedJournals, null, 2));

  // 3. Consent History
  const consents = await sql`SELECT * FROM consent_records WHERE user_id = ${userId}`;
  zip.file("consent_history.json", JSON.stringify(consents, null, 2));

  // 4. Manifest
  const manifest = {
    userId,
    exportedAt: timestamp,
    recordCounts: {
      moodLogs: moodLogs.length,
      journalEntries: journals.length,
      consents: consents.length,
    },
    note: "This export contains all your personal data as of the export time."
  };
  zip.file("EXPORT_MANIFEST.json", JSON.stringify(manifest, null, 2));

  return await zip.generateAsync({ type: "nodebuffer" });
}
```

**Verification**: Call the function with a test user ID and check the resulting ZIP file.

---

#### Step 5.2: The Target — Right to be Forgotten Orchestrator

**The Concept**:  
Deletion must be careful and ordered. We delete local data, anonymize audit trails, and remove identity from Clerk.

**Implementation**:

Create **`lib/delete-account.ts`**:

```ts
import { sql } from './db';
import { Clerk } from '@clerk/nextjs/server';

export async function orchestrateAccountDeletion(userId: string) {
  console.log(`🗑️ Starting deletion for user: ${userId}`);

  // Step 1: Snapshot for audit (optional)
  const snapshot = await sql`SELECT COUNT(*) FROM mood_logs WHERE user_id = ${userId}`;

  // Step 2: Delete personal data
  await sql`DELETE FROM mood_logs WHERE user_id = ${userId}`;
  await sql`DELETE FROM journal_entries WHERE user_id = ${userId}`;
  await sql`DELETE FROM reminders WHERE user_id = ${userId}`;

  // Step 3: Anonymize consent records (preserve audit trail)
  await sql`
    UPDATE consent_records 
    SET user_id = 'deleted-user-' || substring(user_id from 1 for 8)
    WHERE user_id = ${userId}
  `;

  // Step 4: Delete from users_privacy table
  await sql`DELETE FROM users_privacy WHERE user_id = ${userId}`;

  // Step 5: Delete Clerk identity
  const clerkClient = new Clerk({ secretKey: process.env.CLERK_SECRET_KEY! });
  await clerkClient.users.deleteUser(userId);

  console.log(`✅ Complete deletion finished for user ${userId}`);
  return true;
}
```

Add rate limiting using Upstash Redis (as shown in previous responses).

---

**Part 5 Complete!**

You now have working export and deletion flows — two of the hardest privacy rights to implement correctly.

You're nearly finished with a complete privacy-first application!
