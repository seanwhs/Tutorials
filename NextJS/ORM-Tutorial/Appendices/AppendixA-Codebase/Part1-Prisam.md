# Appendix A1: Full Codebase Reference — Prisma Variant

Complete, copy-pasteable file tree for the Prisma track (Parts 1–4). Use this as the canonical reference if any snippet in the main parts seems out of context.

## File Tree

```
orm-nextjs-demo/
├── .env
├── .gitignore
├── package.json
├── next.config.ts
├── prisma/
│   ├── schema.prisma
│   ├── seed.ts
│   └── migrations/
│       ├── 20240101000000_init/
│       │   └── migration.sql
│       └── 20240102000000_add_tags/
│           └── migration.sql
└── src/
    ├── generated/
    │   └── prisma/            # output of `prisma generate`, do not edit
    ├── lib/
    │   └── db.ts
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

## `prisma/schema.prisma`

```prisma
generator client {
  provider        = "prisma-client-js"
  output          = "../src/generated/prisma"
  previewFeatures = ["driverAdapters"]
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

model Author {
  id    String @id @default(uuid())
  name  String
  email String @unique
  posts Post[]

  @@map("authors")
}

model Post {
  id        String    @id @default(uuid())
  title     String
  content   String
  published Boolean   @default(false)
  createdAt DateTime  @default(now()) @map("created_at")
  authorId  String    @map("author_id")
  author    Author    @relation(fields: [authorId], references: [id], onDelete: Cascade)
  tags      PostTag[]

  @@map("posts")
  @@index([authorId])
}

model Tag {
  id    String    @id @default(uuid())
  name  String    @unique
  posts PostTag[]

  @@map("tags")
}

model PostTag {
  postId  String   @map("post_id")
  tagId   String   @map("tag_id")
  post    Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  tag     Tag      @relation(fields: [tagId], references: [id], onDelete: Cascade)
  addedAt DateTime @default(now()) @map("added_at")

  @@id([postId, tagId])
  @@map("post_tags")
}
```

## `src/lib/db.ts`

```ts
import { PrismaClient } from "@/generated/prisma";
import { PrismaNeon } from "@prisma/adapter-neon";

const adapter = new PrismaNeon({ connectionString: process.env.DATABASE_URL! });

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

## `src/app/posts/actions.ts`

```ts
"use server";

import { db } from "@/lib/db";
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

  await db.post.create({ data: parsed.data });
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

  await db.post.update({ where: { id }, data: parsed.data });
  revalidatePath("/posts");
  revalidatePath(`/posts/${id}`);
  redirect(`/posts/${id}`);
}

export async function deletePost(id: string) {
  await db.post.delete({ where: { id } });
  revalidatePath("/posts");
}

export async function togglePublished(id: string, current: boolean) {
  await db.post.update({ where: { id }, data: { published: !current } });
  revalidatePath("/posts");
}

export async function createPostWithTagsInteractive(
  data: { title: string; content: string; authorId: string },
  tagNames: string[]
) {
  return db.$transaction(async (tx) => {
    const post = await tx.post.create({ data });
    for (const name of tagNames) {
      const tag = await tx.tag.upsert({ where: { name }, update: {}, create: { name } });
      await tx.postTag.create({ data: { postId: post.id, tagId: tag.id } });
    }
    return post;
  });
}
```

## `src/app/posts/page.tsx`

```tsx
import Link from "next/link";
import { db } from "@/lib/db";
import { deletePost, togglePublished } from "./actions";

export default async function PostsPage() {
  const posts = await db.post.findMany({
    include: { author: true },
    orderBy: { createdAt: "desc" },
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
        {posts.map((post) => (
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
import { db } from "@/lib/db";
import { notFound } from "next/navigation";

type PageProps = { params: Promise<{ id: string }> };

export default async function PostDetailPage({ params }: PageProps) {
  const { id } = await params;
  const post = await db.post.findUnique({ where: { id }, include: { author: true } });
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

See Part 2/3/4 for the remaining form components (`new-post-form.tsx`, `edit-post-form.tsx`) — they are reproduced verbatim in this codebase without changes.

Continue to **Appendix A2 (Drizzle Variant)** for the equivalent full file tree.
