# Appendix A2: Full Codebase Reference — Drizzle Variant

Complete, copy-pasteable file tree for the Drizzle track (Parts 5–7).

## File Tree

```
orm-nextjs-demo/
├── .env
├── .gitignore
├── package.json
├── drizzle.config.ts
├── drizzle/
│   └── migrations/
│       ├── 0000_init.sql
│       └── 0001_add_tags.sql
└── src/
    ├── db/
    │   ├── schema.ts
    │   ├── index.ts
    │   ├── migrate.ts
    │   └── seed.ts
    └── app/
        ├── layout.tsx
        ├── globals.css
        └── posts/
            ├── page.tsx
            ├── actions.ts
            ├── new/
            │   ├── page.tsx
            │   └── new-post-form.tsx
            └── [id]/
                ├── page.tsx
                └── edit/
                    ├── page.tsx
                    └── edit-post-form.tsx
```

## `.env`

```bash
DATABASE_URL="postgresql://user:pass@ep-xxxx-pooler.neon.tech/orm_demo?sslmode=require"
DIRECT_URL="postgresql://user:pass@ep-xxxx.neon.tech/orm_demo?sslmode=require"
```

## `drizzle.config.ts`

```ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DIRECT_URL! },
  verbose: true,
  strict: true,
});
```

## `src/db/schema.ts`

```ts
import {
  pgTable, text, boolean, timestamp, uuid, primaryKey, index,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

export const authors = pgTable("authors", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
});

export const posts = pgTable("posts", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: text("title").notNull(),
  content: text("content").notNull(),
  published: boolean("published").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  authorId: uuid("author_id").notNull().references(() => authors.id, { onDelete: "cascade" }),
}, (table) => ({
  authorIdx: index("posts_author_id_idx").on(table.authorId),
}));

export const tags = pgTable("tags", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull().unique(),
});

export const postTags = pgTable("post_tags", {
  postId: uuid("post_id").notNull().references(() => posts.id, { onDelete: "cascade" }),
  tagId: uuid("tag_id").notNull().references(() => tags.id, { onDelete: "cascade" }),
  addedAt: timestamp("added_at").notNull().defaultNow(),
}, (table) => ({
  pk: primaryKey({ columns: [table.postId, table.tagId] }),
}));

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

## `src/db/index.ts`

```ts
import { drizzle as drizzleHttp } from "drizzle-orm/neon-http";
import { drizzle as drizzleServerless } from "drizzle-orm/neon-serverless";
import { neon, Pool } from "@neondatabase/serverless";
import * as schema from "./schema";

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzleHttp(sql, { schema });

const pool = new Pool({ connectionString: process.env.DATABASE_URL! });
export const txDb = drizzleServerless(pool, { schema });
```

## `src/db/migrate.ts`

```ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import { migrate } from "drizzle-orm/neon-http/migrator";

const sql = neon(process.env.DIRECT_URL!);
const migrationDb = drizzle(sql);

async function main() {
  await migrate(migrationDb, { migrationsFolder: "./drizzle/migrations" });
  console.log("Migrations applied");
}

main();
```

## `src/db/seed.ts`

```ts
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

## `src/app/posts/actions.ts`

```ts
"use server";

import { db, txDb } from "@/db";
import { posts, tags, postTags } from "@/db/schema";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

const PostSchema = z.object({
  title: z.string().min(3),
  content: z.string().min(10),
  authorId: z.string().uuid(),
});

export type ActionState = { errors?: Record<string, string[]>; message?: string };

export async function createPost(
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const parsed = PostSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
    authorId: formData.get("authorId"),
  });
  if (!parsed.success) return { errors: parsed.error.flatten().fieldErrors };

  await db.insert(posts).values(parsed.data);
  revalidatePath("/posts");
  redirect("/posts");
}

export async function updatePost(
  id: string,
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const parsed = PostSchema.partial().safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
  });
  if (!parsed.success) return { errors: parsed.error.flatten().fieldErrors };

  await db.update(posts).set(parsed.data).where(eq(posts.id, id));
  revalidatePath("/posts");
  revalidatePath(`/posts/${id}`);
  redirect(`/posts/${id}`);
}

export async function deletePost(id: string) {
  await db.delete(posts).where(eq(posts.id, id));
  revalidatePath("/posts");
}

export async function togglePublished(id: string, current: boolean) {
  await db.update(posts).set({ published: !current }).where(eq(posts.id, id));
  revalidatePath("/posts");
}

export async function createPostWithTags(
  data: { title: string; content: string; authorId: string },
  tagNames: string[]
) {
  return txDb.transaction(async (tx) => {
    const [post] = await tx.insert(posts).values(data).returning();
    for (const name of tagNames) {
      await tx.insert(tags).values({ name }).onConflictDoNothing({ target: tags.name });
      const tag = await tx.query.tags.findFirst({ where: (t, { eq }) => eq(t.name, name) });
      if (tag) await tx.insert(postTags).values({ postId: post.id, tagId: tag.id });
    }
    return post;
  });
}
```

## `src/app/posts/page.tsx`

```tsx
import Link from "next/link";
import { db } from "@/db";
import { deletePost, togglePublished } from "./actions";

export default async function PostsPage() {
  const allPosts = await db.query.posts.findMany({
    with: { author: true },
    orderBy: (posts, { desc }) => [desc(posts.createdAt)],
  });

  return (
    <main className="mx-auto max-w-2xl p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Posts</h1>
        <Link href="/posts/new" className="rounded bg-black px-3 py-2 text-white">
          New Post
        </Link>
      </div>
      <ul className="mt-6 space-y-3">
        {allPosts.map((post) => (
          <li key={post.id} className="rounded border p-4">
            <Link href={`/posts/${post.id}`} className="font-semibold hover:underline">
              {post.title}
            </Link>
            <p className="text-sm text-gray-500">by {post.author.name}</p>
            <div className="mt-2 flex gap-2">
              <form action={togglePublished.bind(null, post.id, post.published)}>
                <button type="submit" className="text-sm underline">
                  {post.published ? "Unpublish" : "Publish"}
                </button>
              </form>
              <form action={deletePost.bind(null, post.id)}>
                <button type="submit" className="text-sm text-red-600 underline">
                  Delete
                </button>
              </form>
            </div>
          </li>
        ))}
      </ul>
    </main>
  );
}
```

## `src/app/posts/[id]/page.tsx`

```tsx
import { db } from "@/db";
import { notFound } from "next/navigation";

type PageProps = { params: Promise<{ id: string }> };

export default async function PostDetailPage({ params }: PageProps) {
  const { id } = await params;
  const post = await db.query.posts.findFirst({
    where: (posts, { eq }) => eq(posts.id, id),
    with: { author: true },
  });
  if (!post) notFound();

  return (
    <main className="mx-auto max-w-2xl p-6">
      <h1 className="text-2xl font-bold">{post.title}</h1>
      <p className="text-sm text-gray-500">by {post.author.name}</p>
      <p className="mt-4 whitespace-pre-wrap">{post.content}</p>
    </main>
  );
}
```

See Part 6 for the remaining form components (`new-post-form.tsx`, `edit-post-form.tsx`) — reproduced verbatim without changes.

Continue to **Appendix B: package.json & Environment Variables Reference**.
