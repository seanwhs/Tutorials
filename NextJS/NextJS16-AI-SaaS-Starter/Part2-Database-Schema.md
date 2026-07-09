## AI SaaS Tutorial - Part 2: Database Schema (Prisma + Postgres + pgvector)

*Note: this part has no Next.js-version-specific code (it's pure Prisma/SQL) — confirmed compatible with Next.js 16 as-is. Prisma 6+ is recommended (installed in Part 1).*

### Goal
Set up a free Postgres database (Neon), enable pgvector, and define our multi-tenant Prisma schema: Users, Workspaces, Memberships, Documents, Chunks (with embeddings), Messages, and Subscriptions.

### 1. Create a free Neon Postgres database
1. Go to neon.tech and sign up (free tier).
2. Create a new project, e.g. `acme-docs-ai`.
3. Copy the connection string shown (starts with `postgresql://...`).

### 2. Enable pgvector and pgcrypto
In the Neon SQL editor, run:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```
(`pgcrypto` is needed later in Part 7 for `gen_random_uuid()`.)

### 3. Configure environment variables
Create `.env.local` in your project root:
```bash
DATABASE_URL="postgresql://<user>:<password>@<host>/<db>?sslmode=require"
```
(Full env var reference lives in Appendix B.)

### 4. Initialize Prisma
```bash
npx prisma init
```
This creates `prisma/schema.prisma` and a `.env` — delete the generated `.env` and keep using `.env.local` (Next.js reads `.env.local` automatically; point Prisma at it via dotenv or just copy `DATABASE_URL` into both for now).

### 5. Define the schema
Replace `prisma/schema.prisma` with:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id          String       @id @default(cuid())
  clerkId     String       @unique
  email       String       @unique
  name        String?
  createdAt   DateTime     @default(now())
  memberships Membership[]
  messages    Message[]
}

model Workspace {
  id            String         @id @default(cuid())
  clerkOrgId    String         @unique
  name          String
  createdAt     DateTime       @default(now())
  memberships   Membership[]
  documents     Document[]
  messages      Message[]
  subscription  Subscription?
}

model Membership {
  id          String    @id @default(cuid())
  role        Role      @default(MEMBER)
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId      String
  workspace   Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId String
  createdAt   DateTime  @default(now())

  @@unique([userId, workspaceId])
}

enum Role {
  OWNER
  ADMIN
  MEMBER
}

model Document {
  id          String     @id @default(cuid())
  workspace   Workspace  @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId String
  name        String
  fileUrl     String
  status      DocStatus  @default(PROCESSING)
  createdAt   DateTime   @default(now())
  chunks      Chunk[]
}

enum DocStatus {
  PROCESSING
  READY
  FAILED
}

model Chunk {
  id         String                     @id @default(cuid())
  document   Document                   @relation(fields: [documentId], references: [id], onDelete: Cascade)
  documentId String
  content    String
  embedding  Unsupported("vector(768)")?
  createdAt  DateTime                   @default(now())

  @@index([documentId])
}

model Message {
  id          String    @id @default(cuid())
  workspace   Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId String
  user        User?     @relation(fields: [userId], references: [id], onDelete: SetNull)
  userId      String?
  role        MsgRole
  content     String
  createdAt   DateTime  @default(now())

  @@index([workspaceId])
}

enum MsgRole {
  USER
  ASSISTANT
}

model Subscription {
  id                   String    @id @default(cuid())
  workspace            Workspace @relation(fields: [workspaceId], references: [id], onDelete: Cascade)
  workspaceId          String    @unique
  stripeCustomerId     String?   @unique
  stripeSubscriptionId String?   @unique
  plan                 Plan      @default(FREE)
  status               String    @default("active")
  currentPeriodEnd     DateTime?
}

enum Plan {
  FREE
  PRO
}
```

**Why `Unsupported("vector(768)")`?** Prisma doesn't have a native vector type, but lets us declare raw column types via `Unsupported(...)`. We'll write raw SQL for the actual similarity search queries in Part 8. 768 matches the dimension of the open-source embedding model we'll use in Part 7 (adjust if you pick a different model).

### 6. Run the migration
```bash
npx prisma migrate dev --name init --create-only
```
Open the generated `prisma/migrations/<timestamp>_init/migration.sql` and confirm the `Chunk` table includes:
```sql
"embedding" vector(768)
```
If Prisma comments it out or errors, add it manually right after the `CREATE TABLE "Chunk"` block:
```sql
ALTER TABLE "Chunk" ADD COLUMN "embedding" vector(768);
```
Then apply it:
```bash
npx prisma migrate dev
```

### 7. Add an index for fast similarity search
```bash
npx prisma migrate dev --name add_vector_index --create-only
```
Edit the generated SQL file to add:
```sql
CREATE INDEX IF NOT EXISTS chunk_embedding_idx
ON "Chunk"
USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```
Apply it:
```bash
npx prisma migrate dev
```

### 8. Generate the Prisma client
```bash
npx prisma generate
```

### 9. Create a Prisma client singleton
`src/lib/db.ts`:
```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

**Checkpoint:** Run `npx prisma studio` — you should see empty tables: User, Workspace, Membership, Document, Chunk, Message, Subscription.

**Next:** Part 3 — Auth & Multi-Tenancy (Clerk Organizations).
