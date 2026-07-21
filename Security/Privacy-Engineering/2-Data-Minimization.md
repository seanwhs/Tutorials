# Part 2: Data Minimization — Constraining What We Collect at the Database Level

## 2.0 Where we are on the map

In Part 1, the DPIA told us, on paper, exactly what data categories we're allowed to collect and why [1]. Part 2 is where we start making it **structurally impossible** to violate that plan by accident — enforcing data minimization as a database-level engineering constraint, not just a policy.

By the end of Part 2 you will have:
1. A running Postgres database, provisioned via Docker and connected through Prisma.
2. A `consent_preferences` table where the *category* of consent is restricted to an exact, closed list using a Postgres `ENUM`.
3. A `mood_entries` table with a deliberately narrow schema, enforced with a `CHECK` constraint limiting scores to 1–10.
4. A Prisma singleton and Clerk webhook that keeps our own `users` table in sync with Clerk-managed identities.
5. A masking utility library, with automated regression tests, ensuring internal tools never over-expose raw sensitive text.

---

## Step 2.1 — Provisioning Postgres

**The Target:** A running Postgres instance reachable from our Next.js app.

**The Concept:** Postgres enforces schemas and constraints at write time — like a filing cabinet whose clerks refuse to file a document that doesn't match the drawer's rules. This "refuse bad data outright" property is what lets us enforce minimization mechanically.

**The Implementation:**

`docker-compose.yml`
```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: greymatter-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: greymatter
      POSTGRES_PASSWORD: dev_password_change_in_prod
      POSTGRES_DB: greymatter_dev
    ports:
      - "5432:5432"
    volumes:
      - greymatter_pg_data:/var/lib/postgresql/data

volumes:
  greymatter_pg_data:
```

```bash
docker compose up -d
```

`.env.local` (append):
```bash
DATABASE_URL="postgresql://greymatter:dev_password_change_in_prod@localhost:5432/greymatter_dev?schema=public"
```

**The Verification:**
```bash
docker compose ps
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "SELECT version();"
```

---

## Step 2.2 — Installing Prisma

**The Target:** Prisma installed and initialized as our type-safe schema and query layer.

**The Concept:** Prisma's schema file becomes our single source of truth for the data model — the same file that will later carry annotations marking which columns must be encrypted (Part 3), and which our CI guardrail (Part 6) will statically scan.

**The Implementation:**
```bash
npm install prisma --save-dev
npm install @prisma/client
npx prisma init
npm install --save-dev dotenv-cli
```

`prisma/schema.prisma`:
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

`package.json` scripts (add):
```json
{
  "scripts": {
    "db:generate": "dotenv -e .env.local -- prisma generate",
    "db:migrate": "dotenv -e .env.local -- prisma migrate dev",
    "db:studio": "dotenv -e .env.local -- prisma studio"
  }
}
```

**The Verification:**
```bash
npm run db:generate
```

---

## Step 2.3 — A Postgres `ENUM` for consent categories

**The Target:** A `ConsentCategory` enum and `consent_preferences` table making it structurally impossible to store an unapproved consent category.

**The Concept:** A plain string column accepts anything. An `ENUM` is a closed, named list — like multiple-choice versus free text — rejected at the database level if a value isn't on the list, regardless of which client tries to write it.

**The Implementation:**

`prisma/schema.prisma` (append):
```prisma
enum ConsentCategory {
  MOOD_TRACKING
  JOURNALING
  MEDICATION_REMINDERS
  ANONYMIZED_RESEARCH
  EMAIL_REMINDERS
}

enum ConsentStatus {
  GRANTED
  REVOKED
}

model User {
  id        String   @id @default(cuid())
  clerkId   String   @unique
  createdAt DateTime @default(now())

  consentPreferences ConsentPreference[]

  @@map("users")
}

model ConsentPreference {
  id        String          @id @default(cuid())
  userId    String
  user      User            @relation(fields: [userId], references: [id], onDelete: Cascade)
  category  ConsentCategory
  status    ConsentStatus
  updatedAt DateTime        @updatedAt

  @@unique([userId, category])
  @@map("consent_preferences")
}
```

```bash
npm run db:migrate -- --name add_consent_preferences
```

**The Verification:**
```bash
cat prisma/migrations/*_add_consent_preferences/migration.sql
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c \
  "INSERT INTO consent_preferences (id, \"userId\", category, status, \"updatedAt\") VALUES ('test1', 'fake-user', 'SELL_DATA_TO_ADVERTISERS', 'GRANTED', now());"
```
Expected: `ERROR: invalid input value for enum "ConsentCategory"`.

```bash
git add -A
git commit -m "feat: add ConsentCategory enum and consent_preferences table with DB-level constraints"
```

---

## Step 2.4 — The `mood_entries` table: minimal by design

**The Target:** Our first sensitive-content table, with a `CHECK` constraint enforcing a 1–10 score range.

**The Concept:** Every unnecessary column is weight you must justify, secure, audit, and delete on request — like an overloaded hiking backpack. We also don't just *hope* the frontend validates the score; Postgres refuses out-of-range values itself.

**The Implementation:**

`prisma/schema.prisma` (append):
```prisma
model MoodEntry {
  id        String   @id @default(cuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  score     Int
  note      String?
  loggedAt  DateTime @default(now())

  @@map("mood_entries")
}
```

```bash
npm run db:migrate -- --name add_mood_entries --create-only
```

Hand-edit the generated migration file:
```sql
CREATE TABLE "mood_entries" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "score" INTEGER NOT NULL,
    "note" TEXT,
    "loggedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "mood_entries_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "mood_entries" ADD CONSTRAINT "mood_entries_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "users"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "mood_entries" ADD CONSTRAINT "mood_entries_score_range"
    CHECK ("score" >= 1 AND "score" <= 10);
```

```bash
npm run db:migrate
```

**The Verification:**
```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "\d mood_entries"
```
Then attempt an out-of-range insert (score `99`) — expect a `CHECK` constraint violation error.

```bash
git add -A
git commit -m "feat: add mood_entries table with DB-level 1-10 score constraint"
```

---

## Step 2.5 — Prisma singleton and Clerk user sync

**The Target:** A shared `PrismaClient` instance, and a verified webhook that creates a matching `User` row when someone signs up via Clerk.

**The Concept:** Reusing one Prisma client avoids exhausting Postgres's connection limit during hot-reloading. The webhook is Clerk proactively notifying us of events (like a shipping notification texted to you), and we cryptographically verify it's genuinely from Clerk before trusting it.

**The Implementation:**

`src/lib/db.ts`:
```typescript
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const db =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

```bash
npm install svix
```

`.env.local` (append):
```bash
CLERK_WEBHOOK_SIGNING_SECRET=whsec_your_actual_secret_here
```

`src/app/api/webhooks/clerk/route.ts`:
```typescript
import { Webhook } from "svix";
import { headers } from "next/headers";
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

type ClerkUserCreatedEvent = {
  type: "user.created";
  data: { id: string };
};

export async function POST(request: Request) {
  const signingSecret = process.env.CLERK_WEBHOOK_SIGNING_SECRET;
  if (!signingSecret) {
    console.error("CLERK_WEBHOOK_SIGNING_SECRET is not set");
    return NextResponse.json({ error: "Server misconfigured" }, { status: 500 });
  }

  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return NextResponse.json({ error: "Missing svix headers" }, { status: 400 });
  }

  const body = await request.text();
  const webhook = new Webhook(signingSecret);
  let event: ClerkUserCreatedEvent;

  try {
    event = webhook.verify(body, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    }) as ClerkUserCreatedEvent;
  } catch (err) {
    console.error("Clerk webhook signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
  }

  if (event.type === "user.created") {
    await db.user.upsert({
      where: { clerkId: event.data.id },
      // If, for any reason, we receive this event twice (webhooks are
      // "at least once" delivery, not "exactly once"), upsert makes
      // this handler safely idempotent — running it twice has the same
      // effect as running it once.
      update: {},
      create: { clerkId: event.data.id },
    });
  }

  return NextResponse.json({ received: true }, { status: 200 });
}
```

**The Verification:**

With `ngrok http 3000` running and your webhook endpoint registered in the Clerk Dashboard, use the Dashboard's **"Send test event"** feature to fire a test `user.created` event. Check your `npm run dev` terminal for a clean `200` response with no errors.

Confirm the row landed in your database:

```bash
docker exec -it greymatter-postgres psql -U greymatter -d greymatter_dev -c "SELECT * FROM users;"
```

For full confidence, sign up a brand-new test account through your actual `/sign-up` page and re-run that query — a second row should appear automatically, proving the real sign-up flow (not just the dashboard's synthetic test) triggers the webhook correctly.

```bash
git add -A
git commit -m "feat: add Prisma singleton and Clerk webhook to sync users into our database"
```

---

## Step 2.6 — Masking utilities: protecting sensitive text from over-exposure

**The Target:** A reusable masking library that redacts or truncates sensitive text — the *only* sanctioned way any future internal tool is allowed to display mood notes or journal content.

**The Concept:** Data minimization also means not *displaying* more than a task requires. A support engineer debugging a chart-rendering bug needs to know an entry exists, not read its private contents. We build masking as a utility every caller must pipe data through — like a redaction stamp built into the photocopier itself, rather than trusting every clerk to remember to black out sensitive lines by hand.

**The Implementation:**

**File: `src/lib/masking.ts`**

```typescript
// src/lib/masking.ts
//
// Central utility for redacting sensitive free-text before it is shown
// in any context other than the data's owner viewing their own content.
// We reduce bypass risk further with the RBAC/ABAC layer in Part 3,
// which routes ALL non-owner reads through masking automatically.

export function maskFully(): string {
  return "[redacted]";
}

export function maskToPreview(text: string, wordCount = 3): string {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return "[empty]";
  }
  const words = trimmed.split(/\s+/);
  const preview = words.slice(0, wordCount).join(" ");
  const wasTruncated = words.length > wordCount;
  return wasTruncated ? `${preview}… [redacted]` : preview;
}

export function maskToLengthOnly(text: string): string {
  return `[${text.length} characters]`;
}

export const ROLES_ALLOWED_UNMASKED_ACCESS: readonly string[] = ["owner"];

export function getDisplayText(
  rawText: string,
  viewerRole: string,
  strategy: "preview" | "lengthOnly" | "full" = "preview",
): string {
  if (ROLES_ALLOWED_UNMASKED_ACCESS.includes(viewerRole)) {
    return rawText;
  }
  switch (strategy) {
    case "full":
      return maskFully();
    case "lengthOnly":
      return maskToLengthOnly(rawText);
    case "preview":
    default:
      return maskToPreview(rawText);
  }
}
```

Install a test runner and write regression tests, since a masking utility silently regressing is exactly the kind of bug that leaks private data without anyone noticing:

```bash
npm install --save-dev vitest
```

**File: `src/lib/masking.test.ts`**

```typescript
import { describe, it, expect } from "vitest";
import {
  maskFully,
  maskToPreview,
  maskToLengthOnly,
  getDisplayText,
} from "./masking";

describe("maskFully", () => {
  it("always returns a fixed redaction marker", () => {
    expect(maskFully()).toBe("[redacted]");
  });
});

describe("maskToPreview", () => {
  it("returns full text unchanged if under the word limit", () => {
    expect(maskToPreview("I feel okay today", 4)).toBe("I feel okay today");
  });

  it("truncates and redacts anything beyond the word limit", () => {
    const longEntry =
      "I feel really overwhelmed today because of everything going on at work";
    const result = maskToPreview(longEntry, 3);
    expect(result).toBe("I feel really… [redacted]");
    expect(result).not.toContain("overwhelmed");
    expect(result).not.toContain("work");
  });

  it("returns a distinct marker for empty text", () => {
    expect(maskToPreview("   ")).toBe("[empty]");
  });
});

describe("maskToLengthOnly", () => {
  it("reveals only a character count, never content", () => {
    const result = maskToLengthOnly("This is private");
    expect(result).toBe("[16 characters]");
    expect(result).not.toContain("private");
  });
});

describe("getDisplayText", () => {
  const secret = "I skipped my medication and didn't tell anyone";

  it("returns raw text for an allowed role", () => {
    expect(getDisplayText(secret, "owner")).toBe(secret);
  });

  it("masks text for any non-allowed role by default", () => {
    const result = getDisplayText(secret, "support_agent");
    expect(result).not.toBe(secret);
    expect(result).not.toContain("medication");
  });

  it("respects an explicitly requested stricter strategy", () => {
    expect(getDisplayText(secret, "support_agent", "full")).toBe("[redacted]");
  });
});
```

**The Verification:**

```bash
npm test
```

Expect all 9 tests passing. As a sanity check, temporarily break `maskToPreview` (return `trimmed` unmodified), re-run, and confirm the test **fails**, showing the leaked word in the diff — then revert.

```bash
git add -A
git commit -m "feat: add masking utilities with regression tests to prevent sensitive text over-exposure"
```

---

## Part 2 Reference Section: Why Enums/Checks Beat "Just Validate in the API Layer"

Application-layer validation (e.g., Zod) gives fast, user-friendly errors before a request reaches the database. But your Next.js app is very unlikely to be the *only* thing that ever writes to this database over the product's life — migration scripts, 2 AM incident fixes via `psql`, future admin tools, bulk imports all bypass API-layer validation entirely. Database constraints are provable and inspectable independent of application code, and fail atomically within transactions. The rule of thumb: **application validation is for user experience; database constraints are for the correctness guarantees you're willing to stake compliance claims on.** This same "belt and suspenders" pairing reappears in Part 3 with field-level encryption, enforced both by encrypt-before-write helpers and by the CI schema scan mentioned in the DPIA's risk table [1].
