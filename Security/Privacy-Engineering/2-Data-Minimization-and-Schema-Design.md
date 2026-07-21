# Part 2: Data Minimization & Schema Design

### Why Data Minimization First?
Data minimization is the privacy equivalent of “declutter your house.” The less data you store, the less can be stolen, leaked, or misused. We design the schema **after** the threat model so every column has a documented justification.

---

#### Step 2.1: The Target — Create Minimized PostgreSQL Schema

**The Concept**:  
Every column must be justifiable. We use `BYTEA` (binary) for sensitive fields so the database literally cannot store plaintext health data. Pseudonymous IDs keep internal references clean.

**Implementation**:

Create `lib/schema.sql`:

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Core user privacy anchor (never expose Clerk ID directly)
CREATE TABLE IF NOT EXISTS users_privacy (
  user_id TEXT PRIMARY KEY,                    -- Clerk user ID
  internal_pseudonym UUID DEFAULT uuid_generate_v4() UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL                  -- Soft delete marker
);

-- Mood logs - highly sensitive
CREATE TABLE IF NOT EXISTS mood_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users_privacy(user_id) ON DELETE CASCADE,
  mood_score INTEGER NOT NULL CHECK (mood_score BETWEEN 1 AND 10),
  notes_encrypted BYTEA,                       -- MUST be encrypted
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NULL                  -- For optional TTL
);

-- Journal entries
CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users_privacy(user_id) ON DELETE CASCADE,
  title TEXT,
  content_encrypted BYTEA NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Append-only consent ledger (never UPDATE)
CREATE TABLE IF NOT EXISTS consent_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL,
  purpose TEXT NOT NULL,                       -- e.g., 'analytics', 'marketing'
  granted BOOLEAN NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  ip_hmac TEXT                                 -- Salted HMAC for fraud detection
);

-- Medication reminders (minimal)
CREATE TABLE IF NOT EXISTS reminders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users_privacy(user_id) ON DELETE CASCADE,
  medication_name TEXT NOT NULL,
  time_of_day TIME NOT NULL,
  active BOOLEAN DEFAULT true
);

-- Create indexes for performance + privacy (no sensitive data in indexes)
CREATE INDEX idx_mood_user ON mood_logs(user_id);
CREATE INDEX idx_consent_user ON consent_records(user_id, purpose);
```

**Run the schema**:

```bash
# In terminal or Neon SQL editor
psql $DATABASE_URL -f lib/schema.sql
```

**Verification**:
```sql
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
ORDER BY table_name, ordinal_position;
```

You should see `notes_encrypted` and `content_encrypted` as `bytea`.

---

#### Step 2.2: The Target — Data Masking & HMAC Utilities

**The Concept**:  
Support staff should only see masked data unless explicitly authorized. HMAC turns identifiable info (IP) into a one-way fingerprint.

**Implementation**:

**lib/privacy-utils.ts**:
```ts
import crypto from 'crypto';

const HMAC_SALT = process.env.HMAC_SALT!;

if (!HMAC_SALT) throw new Error("HMAC_SALT environment variable is required");

/**
 * Returns masked version for support views (e.g., "jo***@example.com")
 */
export function maskEmail(email: string): string {
  const [local, domain] = email.split('@');
  return `${local.slice(0, 2)}***@${domain}`;
}

/**
 * One-way HMAC for IP addresses used in rate limiting / fraud detection
 */
export function hmacValue(value: string): string {
  return crypto
    .createHmac('sha256', HMAC_SALT)
    .update(value)
    .digest('hex');
}

/**
 * Generate internal pseudonym (never expose raw Clerk ID in logs)
 */
export function generateInternalId(externalId: string): string {
  return crypto.createHash('sha256').update(externalId + HMAC_SALT).digest('hex').slice(0, 16);
}
```

Add to `.env.local`:
```env
HMAC_SALT=your-super-secret-random-string-here-min-32-chars
```

**Verification**:
```bash
node -e '
  import("./lib/privacy-utils.js").then(({ maskEmail, hmacValue }) => {
    console.log(maskEmail("user@example.com"));
    console.log(hmacValue("192.168.1.1"));
  });
'
```

---

#### Step 2.3: The Target — TTL (Time-To-Live) Enforcement Setup

**The Concept**:  
Some data should auto-expire (e.g., old security events). Inngest will handle scheduled cleanups.

**Implementation**:

**inngest/functions/cleanup.ts** (we'll expand Inngest setup in later parts):
```ts
// Placeholder for now - full Inngest wiring in Part 4/5
export const cleanupOldData = {
  id: "cleanup-old-data",
  // Will be fully implemented with cron schedule
};
```

**Verification**: Schema has `expires_at` column ready for future queries like:
```sql
DELETE FROM mood_logs WHERE expires_at < NOW();
```

---

#### Step 2.4: The Target — Update DPIA with New Schema

**Implementation** (append to `docs/DPIA.md`):

```markdown
## Schema Update - Part 2
- Added `notes_encrypted BYTEA` → justified for journaling, mitigated by envelope encryption (Part 3)
- Consent table is append-only → preserves audit trail even after deletion
- All foreign keys use `ON DELETE CASCADE` with careful orchestrator in deletion flow
```

The foundation is solid — we’re now ready to make plaintext impossible.
