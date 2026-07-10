## Part 3: The Persistence Layer

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Provision Neon Postgres, configure Prisma ORM, and build a single type-safe `db` client for the transactional core of Orbit — `Client`, `Project`, `Task`, `Comment`.

---

### 1. Concept Explanation

#### 1.1 Why Neon + Prisma, and why here specifically

Neon is serverless Postgres: free tier gives you a real, ACID-compliant relational database (0.5 GB storage, autosuspend when idle, generous compute hours) with zero ops. Prisma is the ORM layer that gives us end-to-end type safety from schema to query — the moment you define a model in `schema.prisma`, `prisma generate` produces fully-typed client methods, so a typo in a field name is a compile error, not a runtime surprise.

This is the layer that answers "what is the current state of the business." Everything here is relational and mutation-heavy: clients, the projects they've requested, the tasks that make up a project, and comments on those tasks. This is deliberately *not* where content or identity live — a `Project` references a Clerk `userId` as a plain string column (no foreign key into Clerk, since Clerk isn't our database) and can optionally cache a Sanity `servicePackage` slug, but the row of truth for "does this project exist and what state is it in" is Postgres.

#### 1.2 Serverless connection handling

Neon's free tier has a real limit on concurrent direct connections, and serverless functions (Vercel) can spin up many concurrent instances. Two things prevent connection exhaustion:

1. **Neon's pooled connection string** (via PgBouncer, provided automatically as a separate connection string in the Neon dashboard) — always use this for the app's runtime `DATABASE_URL`.
2. **A single cached PrismaClient instance per process**, using the standard Next.js hot-reload-safe singleton pattern, so `pnpm dev`'s module reloading doesn't spawn a new client (and new connection pool) on every file save.

We'll also use Prisma's driver adapter for Neon (`@prisma/adapter-neon`), which routes queries over Neon's HTTP/WebSocket-based driver instead of raw TCP — this is what makes Prisma work well in edge/serverless runtimes and is considered current best practice for Neon + Prisma as of Prisma 6.

---

### 2. Implementation

#### 2.1 Provision Neon

1. Create a project in the Neon console (free tier, no credit card).
2. In the Neon dashboard, copy **both** connection strings: the **pooled** one (contains `-pooler` in the hostname) for `DATABASE_URL`, and the **direct** one for `DIRECT_URL` (Prisma migrations need a direct, non-pooled connection).

```bash
# .env.local
DATABASE_URL="postgresql://user:password@ep-xxx-pooler.us-east-2.aws.neon.tech/orbit?sslmode=require"
DIRECT_URL="postgresql://user:password@ep-xxx.us-east-2.aws.neon.tech/orbit?sslmode=require"
```

#### 2.2 Install Prisma + Neon adapter

```bash
pnpm add prisma --save-dev
pnpm add @prisma/client @prisma/adapter-neon @neondatabase/serverless ws
pnpm dlx prisma init --datasource-provider postgresql
```

This scaffolds `prisma/schema.prisma` and a base `.env`. Delete the generated `.env` (we keep everything in `.env.local`) or merge the `DATABASE_URL` line into it.

#### 2.3 The schema

```prisma
// prisma/schema.prisma
generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["driverAdapters"]
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

enum ProjectStatus {
  REQUESTED
  ACTIVE
  ON_HOLD
  COMPLETED
  CANCELLED
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  DONE
}

model Client {
  id          String    @id @default(cuid())
  clerkUserId String    @unique
  companyName String
  email       String
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  projects    Project[]

  @@index([clerkUserId])
}

model Project {
  id                 String        @id @default(cuid())
  name               String
  status             ProjectStatus @default(REQUESTED)
  sanityPackageSlug  String?
  client             Client        @relation(fields: [clientId], references: [id], onDelete: Cascade)
  clientId           String
  tasks              Task[]
  createdAt          DateTime      @default(now())
  updatedAt          DateTime      @updatedAt

  @@index([clientId])
  @@index([status])
}

model Task {
  id         String     @id @default(cuid())
  title      String
  status     TaskStatus @default(TODO)
  project    Project    @relation(fields: [projectId], references: [id], onDelete: Cascade)
  projectId  String
  comments   Comment[]
  createdAt  DateTime   @default(now())
  updatedAt  DateTime   @updatedAt

  @@index([projectId])
}

model Comment {
  id            String   @id @default(cuid())
  body          String
  authorUserId  String
  task          Task     @relation(fields: [taskId], references: [id], onDelete: Cascade)
  taskId        String
  createdAt     DateTime @default(now())

  @@index([taskId])
}
```

Note the design boundary again: `clerkUserId` and `authorUserId` are plain `String` columns, not foreign keys — they're references into Clerk's identity system, not our own tables. `sanityPackageSlug` is likewise a plain nullable string cache of which Sanity `servicePackage` a project originated from, not a foreign key, since Sanity documents aren't rows in this database.

#### 2.4 Migrate

```bash
pnpm dlx prisma migrate dev --name init
```

This creates `prisma/migrations/`, applies the schema to Neon via the **direct** URL, and regenerates the Prisma Client.

#### 2.5 The one Prisma client — lib/db/prisma.ts

```ts
// src/lib/db/prisma.ts
import { PrismaClient } from "@prisma/client";
import { PrismaNeon } from "@prisma/adapter-neon";

const connectionString = process.env.DATABASE_URL!;

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

function createPrismaClient() {
  const adapter = new PrismaNeon({ connectionString });
  return new PrismaClient({ adapter });
}

export const db = globalForPrisma.prisma ?? createPrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

Every later part imports `db` from this single file. No other file in the codebase is allowed to call `new PrismaClient()`.

#### 2.6 Seed script (optional, useful for local dev)

```ts
// prisma/seed.ts
import { db } from "../src/lib/db/prisma";

async function main() {
  const client = await db.client.create({
    data: {
      clerkUserId: "user_replace_with_real_clerk_id",
      companyName: "Acme Co",
      email: "acme@example.com",
      projects: {
        create: {
          name: "Website Redesign",
          status: "ACTIVE",
          sanityPackageSlug: "website-redesign",
          tasks: {
            create: [{ title: "Kickoff call" }, { title: "Wireframes" }],
          },
        },
      },
    },
  });
  console.log("Seeded client:", client.id);
}

main().finally(() => db.$disconnect());
```

```json
{
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

```bash
pnpm add -D tsx
pnpm dlx prisma db seed
```

#### 2.7 Prisma Studio (quick data browser)

```bash
pnpm dlx prisma studio
```

Opens a local GUI at `http://localhost:5555` to inspect/edit rows directly — useful throughout the rest of the series for verifying Server Action writes.

---

### 3. Checkpoint

- ✅ `DATABASE_URL` (pooled) and `DIRECT_URL` (direct) both set in `.env.local`.
- ✅ `pnpm dlx prisma migrate dev --name init` runs clean against Neon.
- ✅ `prisma studio` shows the four tables: `Client`, `Project`, `Task`, `Comment`.
- ✅ `import { db } from "@/lib/db/prisma"` resolves and `db.client.findMany()` returns typed results in a scratch script.

---

### 4. Troubleshooting

- **`Error: P1001: Can't reach database server`** — check you copied the *pooled* string correctly and it includes `?sslmode=require`; Neon requires SSL.
- **Migrations fail but pooled queries work** — migrations must use `DIRECT_URL`; confirm `directUrl` is set in the `datasource` block, not just `url`.
- **Too many connections in Neon dashboard during `pnpm dev`** — confirm the singleton pattern in `lib/db/prisma.ts` is being hit (check you're not importing `@prisma/client` and instantiating it anywhere else).
- **Driver adapter type errors** — `previewFeatures = ["driverAdapters"]` must be in `schema.prisma` and you must re-run `pnpm dlx prisma generate` after any schema change.

---

Next: **"Ecosystem Tutorial - Part 4: Styling & UI Components"**

---

Say "next" for Part 4.
