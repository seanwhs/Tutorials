# Part 2: Database Schema (Relational + Vector, on Neon)

## 1. Create the free Neon Postgres database
1. Go to neon.tech -> sign up free -> "Create a project" -> name it `cortex-kg-manager`.
2. Once created, open the project dashboard -> "Connection Details" -> copy the **pooled** connection string (starts `postgresql://...` and ends `?sslmode=require`).
3. Paste it into `.env.local` as `DATABASE_URL`.
4. Neon also gives you a **direct** (non-pooled) connection string — copy that too, we need it for Prisma migrations, which don't play well with connection pooling in some drivers:
```bash
DATABASE_URL="postgresql://user:pass@ep-xxxx-pooler.region.aws.neon.tech/dbname?sslmode=require"
DIRECT_URL="postgresql://user:pass@ep-xxxx.region.aws.neon.tech/dbname?sslmode=require"
```

## 2. Enable the pgvector extension
Neon supports `pgvector` out of the box. Open the Neon SQL Editor (in the dashboard) and run:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```
Verify:
```sql
SELECT extname FROM pg_extension WHERE extname = 'vector';
```
You should see one row back: `vector`.

## 3. Why one database for both relational rows and vectors
A common beginner mistake is reaching for a dedicated vector DB (Pinecone, Weaviate) the moment embeddings are involved. For this project's scale, that adds an entire second network hop and a second free-tier account to manage, for no real benefit. `pgvector` lets us:
- Join a chunk's embedding similarity score directly against its parent `Document`, or against the `Node`s extracted from it, **in a single SQL query**.
- Keep one connection string, one migration history, one free-tier limit to track.
- Upgrade later (swap to a dedicated vector DB) only if we ever actually hit pgvector's scaling ceiling — which for a learning project, or even a small real app, we won't.

## 4. Initialize Prisma
```bash
npx prisma init
```
This creates `prisma/schema.prisma` and adds `DATABASE_URL` to `.env` (delete that duplicate line it adds — we already have it in `.env.local`, which Next.js and Prisma both read; keep them in sync).

## 5. The schema
`prisma/schema.prisma`:
```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

model Document {
  id          String   @id @default(cuid())
  fileName    String
  mimeType    String
  status      DocumentStatus @default(PENDING)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  chunks      Chunk[]

  @@map("documents")
}

enum DocumentStatus {
  PENDING
  CHUNKING
  EXTRACTING
  DONE
  FAILED
}

model Chunk {
  id          String   @id @default(cuid())
  content     String
  chunkIndex  Int
  documentId  String
  document    Document @relation(fields: [documentId], references: [id], onDelete: Cascade)

  // pgvector column - Prisma has no native vector type, so we declare it
  // "Unsupported" and manage it with raw SQL (see lib/vector.ts in Part 3/6).
  embedding   Unsupported("vector(768)")?

  nodeLinks   NodeSourceChunk[]
  edgeLinks   EdgeSourceChunk[]

  createdAt   DateTime @default(now())

  @@index([documentId])
  @@map("chunks")
}

model Node {
  id          String   @id @default(cuid())
  name        String
  type        String   // e.g. "PERSON", "ORGANIZATION", "CONCEPT", "LOCATION"
  description String?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  outgoingEdges Edge[] @relation("SourceNode")
  incomingEdges Edge[] @relation("TargetNode")
  sourceChunks  NodeSourceChunk[]

  // De-duplication key: same name+type = same real-world entity.
  @@unique([name, type])
  @@map("nodes")
}

model Edge {
  id          String   @id @default(cuid())
  label       String   // e.g. "WORKS_AT", "LOCATED_IN", "RELATED_TO"
  sourceId    String
  targetId    String
  source      Node     @relation("SourceNode", fields: [sourceId], references: [id], onDelete: Cascade)
  target      Node     @relation("TargetNode", fields: [targetId], references: [id], onDelete: Cascade)
  createdAt   DateTime @default(now())

  sourceChunks EdgeSourceChunk[]

  @@unique([sourceId, targetId, label])
  @@map("edges")
}

// Provenance join tables: which chunk(s) justify a given node/edge existing.
// This is what makes the graph "context-aware" - every fact is traceable
// back to the exact text it came from.
model NodeSourceChunk {
  nodeId  String
  chunkId String
  node    Node  @relation(fields: [nodeId], references: [id], onDelete: Cascade)
  chunk   Chunk @relation(fields: [chunkId], references: [id], onDelete: Cascade)

  @@id([nodeId, chunkId])
  @@map("node_source_chunks")
}

model EdgeSourceChunk {
  edgeId  String
  chunkId String
  edge    Edge  @relation(fields: [edgeId], references: [id], onDelete: Cascade)
  chunk   Chunk @relation(fields: [chunkId], references: [id], onDelete: Cascade)

  @@id([edgeId, chunkId])
  @@map("edge_source_chunks")
}
```

### Why 768 dimensions
768 matches `nomic-embed-text`, a fully open-source embedding model we run for free via Ollama (same choice used in similar tutorials in this series' family). If you swap embedding models later, update the `vector(768)` dimension to match — dimension mismatches are the #1 pgvector runtime error beginners hit.

### Why `Unsupported("vector(768)")` instead of a normal Prisma type
Prisma's schema language has no first-class vector type. Marking it `Unsupported(...)` tells Prisma "generate the column in migrations, but don't generate a typed client field for it." We read/write this column exclusively through raw SQL (`$queryRaw`/`$executeRaw`), which we'll build in `lib/vector.ts` (Part 3 for inserts, Part 6 for similarity search).

### Why separate join tables (`NodeSourceChunk`/`EdgeSourceChunk`) instead of a single `chunkId` column on `Node`/`Edge`
A single entity or relationship is often mentioned across *multiple* chunks/documents (e.g., "Alice" appears in five different uploaded files). A many-to-many join table lets one `Node` accumulate provenance from every chunk that mentions it, which is exactly the "context" a user wants when they click a node in the graph.

## 6. Run the migration
Since the schema uses a raw `vector(768)` type Prisma doesn't natively understand, generate the migration but apply the vector-specific part manually the first time:
```bash
npx prisma migrate dev --name init
```
If Prisma complains about the `Unsupported` type when generating, that's expected — it still creates the column correctly in the generated SQL migration file. Open the generated file at `prisma/migrations/<timestamp>_init/migration.sql` and confirm it contains:
```sql
"embedding" vector(768)
```
If it's missing (rare, depends on Prisma version), add that line manually to the `chunks` table's `CREATE TABLE` statement before running:
```bash
npx prisma migrate dev
```

## 7. Generate the Prisma client
```bash
npx prisma generate
```

## 8. Prisma client singleton
`src/lib/db.ts`:
```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const db =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```
This avoids exhausting Neon's free-tier connection limit from Next.js's hot-reload creating a new `PrismaClient` on every file save in dev.

## 9. Verification checkpoint
```bash
npx prisma studio
```
This opens a local GUI at `http://localhost:5555`. Confirm you can see empty `documents`, `chunks`, `nodes`, `edges`, `node_source_chunks`, and `edge_source_chunks` tables. Then, back in the Neon SQL editor, sanity-check the vector column type directly:
```sql
SELECT column_name, data_type, udt_name
FROM information_schema.columns
WHERE table_name = 'chunks' AND column_name = 'embedding';
```
Expect `udt_name = vector`.

Next: Part 3 - File Ingestion Pipeline.
