# Part 2: Prisma Setup & Schema

## 1. Install Prisma

```bash
pnpm add -D prisma
pnpm add @prisma/client

# Also install the Neon serverless driver adapter — required for
# reliable connections from serverless/edge environments in Next.js 16
pnpm add @prisma/adapter-neon @neondatabase/serverless ws
pnpm add -D @types/ws
```

## 2. Initialize Prisma

```bash
pnpm dlx prisma init --datasource-provider postgresql
```

This creates:
```
prisma/
  schema.prisma
.env          # adds DATABASE_URL placeholder (merge with your existing .env)
```

## 3. Define the Schema

```prisma
// prisma/schema.prisma

generator client {
  provider        = "prisma-client-js"
  // Custom output avoids relying on node_modules internals — recommended
  // for Next.js 16 projects using Turbopack + serverless deploy targets.
  output          = "../src/generated/prisma"
  previewFeatures = ["driverAdapters"] // required to use @prisma/adapter-neon
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")   // pooled connection, used at runtime
  directUrl = env("DIRECT_URL")     // direct connection, used for migrations
}

model Author {
  id    String @id @default(uuid())
  name  String
  email String @unique
  posts Post[] // reverse relation, no DB column — just for Prisma's type graph

  @@map("authors") // explicit table name (snake_case in DB, PascalCase in code)
}

model Post {
  id        String   @id @default(uuid())
  title     String
  content   String
  published Boolean  @default(false)
  createdAt DateTime @default(now()) @map("created_at")

  authorId String @map("author_id")
  author   Author @relation(fields: [authorId], references: [id], onDelete: Cascade)

  @@map("posts")
  @@index([authorId]) // speeds up "posts by author" queries
}
```

> **Why `@@map` / `@map`?** Prisma models are conventionally PascalCase/camelCase, but many teams prefer snake_case in actual SQL. Mapping keeps both worlds happy without fighting either convention.

## 4. Run Your First Migration

```bash
pnpm dlx prisma migrate dev --name init
```

What this does:
1. Reads `schema.prisma`.
2. Generates SQL migration files under `prisma/migrations/`.
3. Applies them to `DIRECT_URL` (the non-pooled connection).
4. Runs `prisma generate` automatically afterward.

```bash
# You can re-run generate manually any time the schema changes
pnpm dlx prisma generate
```

## 5. The Singleton Client (with Neon Adapter for Next.js 16)

Next.js 16's dev server (Turbopack, Fast Refresh) can re-instantiate modules on every request in dev mode — a naive `new PrismaClient()` per import will exhaust your DB connection limit. Use the global-singleton pattern.

```ts
// src/lib/db.ts
import { PrismaClient } from "@/generated/prisma";
import { PrismaNeon } from "@prisma/adapter-neon";

// The adapter speaks HTTP/WebSocket to Neon instead of raw TCP,
// which is what makes Prisma work reliably on serverless/edge runtimes.
const adapter = new PrismaNeon({ connectionString: process.env.DATABASE_URL! });

// Reuse the client across hot-reloads in dev; create fresh in prod.
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const db =
  globalForPrisma.prisma ??
  new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

## 6. Sanity-Check Query (Server Component)

```tsx
// src/app/posts/page.tsx
import { db } from "@/lib/db";

export default async function PostsPage() {
  // Server Components can call the DB directly — no API route needed.
  const posts = await db.post.findMany({
    include: { author: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <ul>
      {posts.map((post) => (
        <li key={post.id}>
          <strong>{post.title}</strong> by {post.author.name}
        </li>
      ))}
    </ul>
  );
}
```

## 7. Seed Script (Optional but Recommended)

```ts
// prisma/seed.ts
import { PrismaClient } from "../src/generated/prisma";

const db = new PrismaClient();

async function main() {
  const author = await db.author.upsert({
    where: { email: "jane@example.com" },
    update: {},
    create: { name: "Jane Doe", email: "jane@example.com" },
  });

  await db.post.createMany({
    data: [
      { title: "Hello World", content: "First post!", authorId: author.id, published: true },
      { title: "Draft Post", content: "WIP", authorId: author.id, published: false },
    ],
  });
}

main()
  .then(() => db.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await db.$disconnect();
    process.exit(1);
  });
```

```json
// package.json — wire up "prisma db seed"
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

Continue to **Part 3: Prisma CRUD with Server Actions**.
