# Part 6: Drizzle CRUD with Server Actions

Same Posts app as Part 3, rebuilt with Drizzle, so you can diff the two side by side.

## 1. Server Actions File

```ts
// src/app/posts/actions.ts
"use server";

import { db } from "@/db";
import { posts } from "@/db/schema";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

const PostSchema = z.object({
  title: z.string().min(3, "Title must be at least 3 characters"),
  content: z.string().min(10, "Content must be at least 10 characters"),
  authorId: z.string().uuid("Invalid author"),
});

export type ActionState = {
  errors?: Record<string, string[]>;
  message?: string;
};

export async function createPost(
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const parsed = PostSchema.safeParse({
    title: formData.get("title"),
    content: formData.get("content"),
    authorId: formData.get("authorId"),
  });

  if (!parsed.success) {
    return { errors: parsed.error.flatten().fieldErrors };
  }

  // .insert().values() is the Drizzle equivalent of prisma.post.create()
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

  if (!parsed.success) {
    return { errors: parsed.error.flatten().fieldErrors };
  }

  await db.update(posts).set(parsed.data).where(eq(posts.id, id));

  revalidatePath("/posts");
  revalidatePath(`/posts/${id}`);
  redirect(`/posts/${id}`);
}

export async function deletePost(id: string) {
  // Cascade delete is defined at the schema/DB level (onDelete: "cascade"),
  // so related post_tags rows are cleaned up automatically by Postgres.
  await db.delete(posts).where(eq(posts.id, id));
  revalidatePath("/posts");
}

export async function togglePublished(id: string, current: boolean) {
  await db.update(posts).set({ published: !current }).where(eq(posts.id, id));
  revalidatePath("/posts");
}
```

## 2. List Page (Server Component)

```tsx
// src/app/posts/page.tsx
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

## 3. New Post Form (Client Component using `useActionState`)

```tsx
// src/app/posts/new/page.tsx
import { db } from "@/db";
import { NewPostForm } from "./new-post-form";

export default async function NewPostPage() {
  const authors = await db.query.authors.findMany({
    orderBy: (authors, { asc }) => [asc(authors.name)],
  });
  return <NewPostForm authors={authors} />;
}
```

```tsx
// src/app/posts/new/new-post-form.tsx
"use client";

import { useActionState } from "react";
import { createPost, type ActionState } from "../actions";

type Author = { id: string; name: string };

export function NewPostForm({ authors }: { authors: Author[] }) {
  const initialState: ActionState = {};
  const [state, formAction, isPending] = useActionState(createPost, initialState);

  return (
    <form action={formAction} className="mx-auto max-w-md space-y-4 p-6">
      <h1 className="text-xl font-bold">New Post</h1>

      <div>
        <label className="block text-sm font-medium">Title</label>
        <input name="title" className="w-full rounded border p-2" />
        {state.errors?.title && (
          <p className="text-sm text-red-600">{state.errors.title[0]}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium">Content</label>
        <textarea name="content" className="w-full rounded border p-2" rows={4} />
        {state.errors?.content && (
          <p className="text-sm text-red-600">{state.errors.content[0]}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-medium">Author</label>
        <select name="authorId" className="w-full rounded border p-2">
          {authors.map((a) => (
            <option key={a.id} value={a.id}>
              {a.name}
            </option>
          ))}
        </select>
      </div>

      <button
        type="submit"
        disabled={isPending}
        className="rounded bg-black px-4 py-2 text-white disabled:opacity-50"
      >
        {isPending ? "Creating..." : "Create Post"}
      </button>
    </form>
  );
}
```

## 4. Detail Page (Next.js 16 Promise-based Params)

```tsx
// src/app/posts/[id]/page.tsx
import { db } from "@/db";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>; // params is a Promise in Next.js 16
};

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

## 5. Search Example (Bonus)

```ts
// src/app/posts/actions.ts (add-on)
import { or, ilike } from "drizzle-orm";

export async function searchPosts(query: string) {
  return db
    .select()
    .from(posts)
    .where(or(ilike(posts.title, `%${query}%`), ilike(posts.content, `%${query}%`)))
    .limit(20);
}
```

## 6. Quick API Comparison Recap

| Operation | Prisma | Drizzle |
|---|---|---|
| Find many + relation | `db.post.findMany({ include: { author: true } })` | `db.query.posts.findMany({ with: { author: true } })` |
| Find one | `db.post.findUnique({ where: { id } })` | `db.query.posts.findFirst({ where: (p, { eq }) => eq(p.id, id) })` |
| Insert | `db.post.create({ data })` | `db.insert(posts).values(data)` |
| Update | `db.post.update({ where, data })` | `db.update(posts).set(data).where(eq(posts.id, id))` |
| Delete | `db.post.delete({ where: { id } })` | `db.delete(posts).where(eq(posts.id, id))` |
| Raw SQL | ``db.$queryRaw`...` `` | ``db.execute(sql`...`)`` |

Continue to **Part 7: Drizzle Relations, Transactions & Migrations**.
