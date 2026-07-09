# Part 4: Prisma Relations, Transactions & Connection Pooling

## 1. Expanding the Schema: 1:N and N:N

```prisma
// prisma/schema.prisma (additions)

model Tag {
  id    String    @id @default(uuid())
  name  String    @unique
  posts PostTag[] // explicit join model (see below)

  @@map("tags")
}

// Explicit join table gives us room for extra columns (e.g. addedAt)
// and matches how you'd hand-write it in Drizzle for a fair comparison.
model PostTag {
  postId String @map("post_id")
  tagId  String @map("tag_id")
  post   Post   @relation(fields: [postId], references: [id], onDelete: Cascade)
  tag    Tag    @relation(fields: [tagId], references: [id], onDelete: Cascade)

  addedAt DateTime @default(now()) @map("added_at")

  @@id([postId, tagId])
  @@map("post_tags")
}

model Post {
  id        String    @id @default(uuid())
  title     String
  content   String
  published Boolean   @default(false)
  createdAt DateTime  @default(now()) @map("created_at")
  authorId  String    @map("author_id")
  author    Author    @relation(fields: [authorId], references: [id], onDelete: Cascade)
  tags      PostTag[] // 1 Post -> many PostTag rows -> many Tags

  @@map("posts")
  @@index([authorId])
}
```

```bash
pnpm dlx prisma migrate dev --name add_tags
```

## 2. Querying Nested Relations

```ts
// Fetch a post with author + tags in a single round trip
const post = await db.post.findUnique({
  where: { id },
  include: {
    author: true,
    tags: { include: { tag: true } }, // walk through the join table
  },
});

// Flatten tags for easier rendering in the UI
const tagNames = post?.tags.map((pt) => pt.tag.name) ?? [];
```

```ts
// Filter posts that have a specific tag ("nextjs")
const posts = await db.post.findMany({
  where: {
    tags: { some: { tag: { name: "nextjs" } } },
  },
});
```

## 3. Transactions

### 3a. Sequential (array) form — good for simple all-or-nothing batches

```ts
// src/app/posts/actions.ts (add-on)
export async function createPostWithTags(
  data: { title: string; content: string; authorId: string },
  tagNames: string[]
) {
  // $transaction([...]) runs all queries in one DB transaction —
  // if any fails, everything rolls back atomically.
  const [post] = await db.$transaction([
    db.post.create({ data }),
    // upsert each tag so we don't duplicate existing ones
    ...tagNames.map((name) =>
      db.tag.upsert({ where: { name }, update: {}, create: { name } })
    ),
  ]);

  return post;
}
```

### 3b. Interactive transaction — needed when later steps depend on earlier results

```ts
export async function createPostWithTagsInteractive(
  data: { title: string; content: string; authorId: string },
  tagNames: string[]
) {
  return db.$transaction(async (tx) => {
    // tx behaves exactly like db, but every call is scoped to this transaction
    const post = await tx.post.create({ data });

    for (const name of tagNames) {
      const tag = await tx.tag.upsert({
        where: { name },
        update: {},
        create: { name },
      });

      await tx.postTag.create({
        data: { postId: post.id, tagId: tag.id },
      });
    }

    return post;
  });
}
```

> **Why interactive transactions cost more:** they hold a real DB connection open for the whole callback. Prefer the array form when steps are independent; reach for `async (tx) => {}` only when you need each step's result to build the next.

## 4. Connection Pooling for Serverless / Edge

Serverless functions can spin up many concurrent instances, each opening its own DB connection — this can exhaust Postgres's connection limit fast. Two complementary fixes:

```ts
// src/lib/db.ts — reusing the adapter pattern from Part 2
import { PrismaClient } from "@/generated/prisma";
import { PrismaNeon } from "@prisma/adapter-neon";

// The Neon adapter talks over HTTP/WebSocket, which is naturally
// connection-efficient for serverless — no long-lived TCP socket per instance.
const adapter = new PrismaNeon({ connectionString: process.env.DATABASE_URL! });

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const db = globalForPrisma.prisma ?? new PrismaClient({ adapter });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = db;
```

```bash
# .env — always point runtime traffic at Neon's pooled endpoint (contains "-pooler")
DATABASE_URL="postgresql://user:pass@ep-xxxx-pooler.neon.tech/db?sslmode=require"

# Migrations bypass the pooler entirely
DIRECT_URL="postgresql://user:pass@ep-xxxx.neon.tech/db?sslmode=require"
```

## 5. Raw SQL Escape Hatch

```ts
// When Prisma's query builder can't express something (e.g. complex window functions)
const topAuthors = await db.$queryRaw<
  { authorId: string; postCount: bigint }[]
>`
  SELECT "author_id" AS "authorId", COUNT(*) AS "postCount"
  FROM "posts"
  GROUP BY "author_id"
  ORDER BY "postCount" DESC
  LIMIT 5
`;
```

## 6. Cheat Sheet: Common Prisma Commands

| Command | Purpose |
|---|---|
| `prisma migrate dev --name x` | Create + apply a migration in dev, regenerates client |
| `prisma migrate deploy` | Apply pending migrations in production (no prompts) |
| `prisma generate` | Regenerate the client after schema changes without migrating |
| `prisma studio` | Visual DB browser/editor in the browser |
| `prisma db seed` | Run the configured seed script |
| `prisma format` | Auto-format `schema.prisma` |
| `prisma validate` | Check schema for errors without touching the DB |

This completes the Prisma track. Continue to **Part 5: Drizzle Setup & Schema** to build the same app with Drizzle.
