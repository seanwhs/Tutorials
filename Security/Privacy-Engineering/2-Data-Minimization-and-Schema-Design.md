# Part 2: Data Minimization & Schema Design

---

### Why Part 2 Matters
**Data Minimization** means: *Collect and store only what is strictly necessary, and protect what you must keep.* This is one of the most powerful privacy principles. By designing the database schema carefully now, we make it much harder to accidentally leak sensitive information later.

We will create a clean, auditable database structure where health data is **typed** as encrypted from the beginning.

---

#### Step 2.1: The Target — Create the Minimized Database Schema

**The Concept**:  
We use PostgreSQL (via Neon). `BYTEA` is a binary data type — perfect for storing encrypted information because the database cannot "read" it as normal text. We also use UUIDs for strong, unique identifiers.

**Implementation**:

Create the file **`lib/schema.sql`** with this complete content:

```sql
-- Enable useful PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";     -- For generating UUIDs
CREATE EXTENSION IF NOT EXISTS pgcrypto;        -- For encryption helpers (optional)

-- 1. Users Privacy Anchor Table
-- This table links everything to a user without scattering Clerk IDs everywhere
CREATE TABLE IF NOT EXISTS users_privacy (
  user_id TEXT PRIMARY KEY,                    -- Comes from Clerk
  internal_pseudonym UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL                  -- For soft deletion
);

-- 2. Mood Logs (Daily mood tracking)
CREATE TABLE IF NOT EXISTS mood_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users_privacy(user_id) ON DELETE CASCADE,
  
  mood_score INTEGER NOT NULL CHECK (mood_score BETWEEN 1 AND 10),  -- 1-10 scale
  notes_encrypted BYTEA,                                            -- Encrypted health notes
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NULL                                       -- Optional auto-expiry
);

-- 3. Journal Entries
CREATE TABLE IF NOT EXISTS journal_entries (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users_privacy(user_id) ON DELETE CASCADE,
  
  title TEXT,
  content_encrypted BYTEA NOT NULL,                                 -- Must be encrypted
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Append-Only Consent Ledger
CREATE TABLE IF NOT EXISTS consent_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL,
  purpose TEXT NOT NULL,                    -- e.g. 'analytics', 'marketing'
  granted BOOLEAN NOT NULL,
  recorded_at TIMESTAMPTZ DEFAULT NOW(),
  ip_hmac TEXT                              -- One-way hash for fraud detection
);

-- 5. Medication Reminders (Minimal)
CREATE TABLE IF NOT EXISTS reminders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users_privacy(user_id) ON DELETE CASCADE,
  medication_name TEXT NOT NULL,
  time_of_day TIME NOT NULL,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance indexes (no sensitive data in index keys)
CREATE INDEX idx_mood_logs_user ON mood_logs(user_id);
CREATE INDEX idx_consent_user_purpose ON consent_records(user_id, purpose);
```

**How to Apply the Schema**:
1. Go to your Neon dashboard → SQL Editor
2. Copy and paste the entire content above
3. Run the query

**Verification**:
```sql
-- Run this query in Neon SQL Editor
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
ORDER BY table_name, ordinal_position;
```

You should see `notes_encrypted` and `content_encrypted` listed as type **`bytea`**.

---

#### Step 2.2: The Target — Privacy Utility Functions (Masking + HMAC)

**The Concept**:  
- **Masking**: Show partial data to support staff (e.g., `jo***@example.com`).
- **HMAC**: One-way hashing — you cannot reverse it to get the original value.

**Implementation**:

Create file **`lib/privacy-utils.ts`**:

```ts
import crypto from 'crypto';

const HMAC_SALT = process.env.HMAC_SALT;

if (!HMAC_SALT || HMAC_SALT.length < 32) {
  throw new Error("HMAC_SALT must be set in .env.local with at least 32 characters");
}

/**
 * Masks email for support views
 */
export function maskEmail(email: string): string {
  if (!email || !email.includes('@')) return '[REDACTED]';
  const [localPart, domain] = email.split('@');
  return `${localPart.substring(0, 2)}***@${domain}`;
}

/**
 * Creates a one-way HMAC hash (used for IP addresses)
 */
export function hmacValue(value: string): string {
  return crypto
    .createHmac('sha256', HMAC_SALT)
    .update(value)
    .digest('hex');
}

/**
 * Generate short internal ID for logs
 */
export function generateInternalId(externalId: string): string {
  return crypto
    .createHash('sha256')
    .update(externalId + HMAC_SALT)
    .digest('hex')
    .slice(0, 16);
}
```

**Update `.env.local`**:
```env
HMAC_SALT=super-secret-random-string-at-least-32-characters-long-here-2025
```

**Verification**:
```bash
node -e '
  import("./lib/privacy-utils.js").then(m => {
    console.log("Masked:", m.maskEmail("user@example.com"));
    console.log("HMAC:", m.hmacValue("192.168.1.1"));
  });
'
```

---

#### Step 2.3: Update the Living DPIA

**Implementation** — Append to `docs/DPIA.md`:

```markdown
## Part 2 Schema Update (Data Minimization)
- All sensitive fields use BYTEA type → plaintext storage is now a compile-time impossibility.
- Consent table is append-only → full history preserved for audits.
- Foreign keys use ON DELETE CASCADE with careful orchestration in deletion flow (Part 5).
```

---

**Part 2 Complete!**

You now have:
- A minimized, privacy-first database schema.
- Strong utility functions for data masking and hashing.
- Updated documentation.

**Test Everything**:
- Run `npm run dev`
- Confirm your database tables were created in Neon.

You are making excellent progress! The application is starting to take real shape.
