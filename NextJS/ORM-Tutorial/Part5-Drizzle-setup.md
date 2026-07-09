# Part 5: Drizzle Setup & Schema

## 1. Install Drizzle

```bash
pnpm add drizzle-orm @neondatabase/serverless
pnpm add -D drizzle-kit tsx
```

- `drizzle-orm` — the query builder/runtime.
- `@neondatabase/serverless` — HTTP/WebSocket driver, ideal for Next.js 16's serverless + edge runtimes.
- `drizzle-kit` — CLI for generating/running migrations and Drizzle Studio.

## 2. Config File

```ts
// drizzle.config.ts (project root)
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/db/schema.ts",     // where your table definitions live
  out: "./drizzle/migrations",       // generated SQL migration files land here
  dialect: "postgresql",
  dbCredentials: {
    // drizzle-kit uses the DIRECT (non-pooled) URL for migrations,
    // same reasoning as Prisma in Part 2.
    url: process.env.DIRECT_URL!,
  },
  verbose: true,
  strict: true,
});
```

## 3. Define the Schema in Plain TypeScript

```ts
// src/db/schema.ts
import {
  pgTable,
  text,
  boolean,
  timestamp,
  uuid,
  primaryKey,
  index,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const authors = pgTable("authors", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
});

export const posts = pgTable(
  "posts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    title: text("title").notNull(),
    content: text("content").notNull(),
    published: boolean("published").notNull().default(false),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    authorId: uuid("author_id")
      .notNull()
      .references(() => authors.id, { onDelete: "cascade" }),
  },
  (table) => ({
    // Named index, same intent as Prisma's @@index([authorId])
    authorIdx: index("posts_author_id_idx").on(table.authorId),
  })
);

export const tags = pgTable("tags", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull().unique(),
});

// Explicit join table — Drizzle has no "implicit many-to-many" sugar,
// you always model the join table yourself. This is more verbose than
// Prisma's implicit N:N but keeps you closer to the actual SQL.
export const postTags = pgTable(
  "post_tags",
  {
    postId: uuid("post_id")
      .notNull()
      .references(() => posts.id, { onDelete: "cascade" }),
    tagId: uuid("tag_id")
      .notNull()
      .references(() => tags.id, { onDelete: "cascade" }),
    addedAt: timestamp("added_at").notNull().defaultNow(),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.postId, table.tagId] }),
  })
);

// --- Relations API: used only for the type-safe `.query` builder below ---
// These do NOT create foreign keys themselves (the .references() above does that);
// they just teach Drizzle's relational query API how tables connect.
export const authorsRelations = relations(authors, ({ many }) => ({
  posts: many(posts),
}));

export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(authors, { fields: [posts.authorId], references: [authors.id] }),
  tags: many(postTags),
}));

export const tagsRelations = relations(tags, ({ many }) => ({
  posts: many(postTags),
}));

export const postTagsRelations = relations(postTags, ({ one }) => ({
  post: one(posts, { fields: [postTags.postId], references: [posts.id] }),
  tag: one(tags, { fields: [postTags.tagId], references: [tags.id] }),
}));
```

> **Why plain TS instead of a DSL?** Drizzle's schema *is* your source of truth and *is* imported directly by your app code — there's no separate generation step producing types. What you write is what you get, immediately, with full IDE autocomplete.

## 4. The DB Client (Singleton, Neon HTTP Driver)

```ts
// src/db/index.ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "./schema";

// neon-http is stateless/serverless-friendly (one HTTP request per query) —
// ideal default for Next.js Server Components and Server Actions.
const sql = neon(process.env.DATABASE_URL!);

// Passing `schema` enables the relational query API (db.query.posts.findMany, etc.)
export const db = drizzle(sql, { schema });
```

> For long-lived servers or when you need real transactions with multiple statements over one connection, use `drizzle-orm/neon-serverless` (WebSocket-based) instead — see Part 7.

## 5. Generate & Run Migrations

```bash
# Generates SQL files under drizzle/migrations/ by diffing schema.ts
# against the current migration history — nothing touches the DB yet.
pnpm dlx drizzle-kit generate

# Applies any pending generated migrations to DIRECT_URL
pnpm dlx drizzle-kit migrate
```

```ts
// src/db/migrate.ts — script form, handy for CI/CD deploy steps
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import { migrate } from "drizzle-orm/neon-http/migrator";

const sql = neon(process.env.DIRECT_URL!);
const db = drizzle(sql);

async function main() {
  await migrate(db, { migrationsFolder: "./drizzle/migrations" });
  console.log("Migrations applied");
}

main();
```

```bash
pnpm tsx src/db/migrate.ts
```

## 6. Prototyping Shortcut: `drizzle-kit push`

```bash
# Pushes your schema.ts directly to the DB, no migration files generated.
# Great for local prototyping; NOT recommended for team/production workflows
# because there's no history/audit trail of schema changes.
pnpm dlx drizzle-kit push
```

## 7. Seed Script

```ts
// src/db/seed.ts
import { db } from "./index";
import { authors, posts } from "./schema";

async function main() {
  const [author] = await db
    .insert(authors)
    .values({ name: "Jane Doe", email: "jane@example.com" })
    .onConflictDoNothing({ target: authors.email })
    .returning();

  const janeId = author?.id ?? (await db.query.authors.findFirst({
    where: (a, { eq }) => eq(a.email, "jane@example.com"),
  }))!.id;

  await db.insert(posts).values([
    { title: "Hello World", content: "First post!", authorId: janeId, published: true },
    { title: "Draft Post", content: "WIP", authorId: janeId, published: false },
  ]);
}

main().then(() => console.log("Seeded")).catch(console.error);
```

```bash
pnpm tsx src/db/seed.ts
```

## 8. Sanity-Check Query (Server Component)

```tsx
// src/app/posts/page.tsx
import { db } from "@/db";

export default async function PostsPage() {
  // db.query.<table>.findMany is Drizzle's relational query API —
  // reads like Prisma's `include`, but still compiles to efficient SQL.
  const allPosts = await db.query.posts.findMany({
    with: { author: true },
    orderBy: (posts, { desc }) => [desc(posts.createdAt)],
  });

  return (
    <ul>
      {allPosts.map((post) => (
        <li key={post.id}>
          <strong>{post.title}</strong> by {post.author.name}
        </li>
      ))}
    </ul>
  );
}
```

Continue to **Part 6: Drizzle CRUD with Server Actions**.
