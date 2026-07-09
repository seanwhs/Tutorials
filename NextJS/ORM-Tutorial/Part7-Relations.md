# Part 7: Drizzle Relations, Transactions & Migrations

## 1. Querying the Tags Many-to-Many (from Part 5's schema)

```ts
// Fetch a post with author + tags — nested `with` walks the join table
const post = await db.query.posts.findFirst({
  where: (posts, { eq }) => eq(posts.id, id),
  with: {
    author: true,
    tags: { with: { tag: true } }, // posts -> postTags -> tags
  },
});

// Flatten for the UI, same shape as the Prisma version in Part 4
const tagNames = post?.tags.map((pt) => pt.tag.name) ?? [];
```

```ts
// Filter posts that have a tag named "nextjs" using the query builder
// (relational `with` doesn't support filtering by nested field directly,
// so drop down to the core query builder with joins for this case)
import { eq } from "drizzle-orm";
import { posts, postTags, tags } from "@/db/schema";

const filteredPosts = await db
  .selectDistinct({ id: posts.id, title: posts.title })
  .from(posts)
  .innerJoin(postTags, eq(postTags.postId, posts.id))
  .innerJoin(tags, eq(postTags.tagId, tags.id))
  .where(eq(tags.name, "nextjs"));
```

## 2. Transactions

Drizzle transactions require a driver that supports a persistent connection for the transaction's lifetime. The stateless `neon-http` driver from Part 5 does **not** support `db.transaction()` — switch to `neon-serverless` (WebSocket-based) for any code path needing real transactions.

```ts
// src/db/index.ts — dual client setup
import { drizzle as drizzleHttp } from "drizzle-orm/neon-http";
import { drizzle as drizzleServerless } from "drizzle-orm/neon-serverless";
import { neon } from "@neondatabase/serverless";
import { Pool } from "@neondatabase/serverless";
import * as schema from "./schema";

// Fast, stateless — use for simple reads/writes in Server Components
const sql = neon(process.env.DATABASE_URL!);
export const db = drizzleHttp(sql, { schema });

// WebSocket pool — use whenever you need db.transaction()
const pool = new Pool({ connectionString: process.env.DATABASE_URL! });
export const txDb = drizzleServerless(pool, { schema });
```

```ts
// src/app/posts/actions.ts (add-on)
"use server";

import { txDb } from "@/db";
import { posts, tags, postTags } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function createPostWithTags(
  data: { title: string; content: string; authorId: string },
  tagNames: string[]
) {
  // db.transaction gives you an all-or-nothing block, same guarantee
  // as Prisma's interactive $transaction(async (tx) => {...})
  return txDb.transaction(async (tx) => {
    const [post] = await tx.insert(posts).values(data).returning();

    for (const name of tagNames) {
      // Upsert-by-name pattern using onConflictDoNothing + a follow-up read
      await tx.insert(tags).values({ name }).onConflictDoNothing({ target: tags.name });

      const tag = await tx.query.tags.findFirst({
        where: (t, { eq }) => eq(t.name, name),
      });

      if (tag) {
        await tx.insert(postTags).values({ postId: post.id, tagId: tag.id });
      }
    }

    return post;
  });
}
```

> **Rule of thumb:** use `neon-http` (`db`) for everyday Server Component reads and single-statement Server Action writes — it's cheaper and simpler. Reach for the WebSocket pool (`txDb`) only when a request needs multiple statements to succeed or fail together.

## 3. Migration Workflow Deep Dive

| Command | What it does | When to use |
|---|---|---|
| `drizzle-kit generate` | Diffs `schema.ts` against migration history, writes new SQL file(s) to `drizzle/migrations/` | Every time you change `schema.ts` in a real project |
| `drizzle-kit migrate` | Applies any un-applied SQL files from `drizzle/migrations/` to the DB | Local apply, or as a CI/CD deploy step |
| `drizzle-kit push` | Directly syncs `schema.ts` -> DB schema, no SQL files, no history | Quick local prototyping only — skip in team projects |
| `drizzle-kit studio` | Opens a web GUI to browse/edit data | Visual inspection, Prisma Studio equivalent |
| `drizzle-kit check` | Detects migration file conflicts (e.g. from merged branches) | Before deploying, especially after rebasing |
| `drizzle-kit drop` | Removes the last generated migration file | Undo a `generate` you haven't applied yet |

```bash
pnpm dlx drizzle-kit generate --name add_tags
pnpm dlx drizzle-kit migrate
```

Example generated file:

```sql
-- drizzle/migrations/0001_add_tags.sql
CREATE TABLE IF NOT EXISTS "tags" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" text NOT NULL,
	CONSTRAINT "tags_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "post_tags" (
	"post_id" uuid NOT NULL,
	"tag_id" uuid NOT NULL,
	"added_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "post_tags_post_id_tag_id_pk" PRIMARY KEY("post_id","tag_id")
);
--> statement-breakpoint
ALTER TABLE "post_tags" ADD CONSTRAINT "post_tags_post_id_posts_id_fk"
  FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE cascade;
--> statement-breakpoint
ALTER TABLE "post_tags" ADD CONSTRAINT "post_tags_tag_id_tags_id_fk"
  FOREIGN KEY ("tag_id") REFERENCES "tags"("id") ON DELETE cascade;
```

> Reading raw generated SQL is a big Drizzle differentiator — you always know exactly what will run against your database, with no black-box migration engine.

## 4. Raw SQL Escape Hatch

```ts
import { sql } from "drizzle-orm";

const topAuthors = await db.execute(sql`
  SELECT author_id AS "authorId", COUNT(*) AS "postCount"
  FROM posts
  GROUP BY author_id
  ORDER BY "postCount" DESC
  LIMIT 5
`);
```

## 5. Cheat Sheet: Common Drizzle Commands

| Command | Purpose |
|---|---|
| `drizzle-kit generate` | Create SQL migration files from schema diff |
| `drizzle-kit migrate` | Apply pending migration files |
| `drizzle-kit push` | Sync schema straight to DB (prototyping only) |
| `drizzle-kit studio` | Visual DB browser/editor |
| `drizzle-kit check` | Validate migration history integrity |
| `drizzle-kit drop` | Remove an unapplied migration file |

This completes the Drizzle track. Continue to **Part 8: Prisma vs Drizzle — Decision Guide** for a final side-by-side wrap-up.
