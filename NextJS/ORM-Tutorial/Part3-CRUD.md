# Part 3: Prisma CRUD with Server Actions

This part builds a full Create/Read/Update/Delete UI for the `Post` model using Next.js 16 **Server Actions** — no separate API routes needed.

## 1. Server Actions File

```ts
// src/app/posts/actions.ts
"use server";

import { db } from "@/lib/db";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

// Zod schema validates untrusted form data before it ever touches Prisma.
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
    // useActionState (Part-of React 19) reads this shape to show field errors
    return { errors: parsed.error.flatten().fieldErrors };
  }

  await db.post.create({ data: parsed.data });

  // Re-render the posts list Server Component with fresh data
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

  await db.post.update({
    where: { id },
    data: parsed.data,
  });

  revalidatePath("/posts");
  revalidatePath(`/posts/${id}`);
  redirect(`/posts/${id}`);
}

export async function deletePost(id: string) {
  // onDelete: Cascade in schema means we don't need to manually clean up
  // related rows — Postgres handles it at the DB level.
  await db.post.delete({ where: { id } });
  revalidatePath("/posts");
}

export async function togglePublished(id: string, current: boolean) {
  await db.post.update({
    where: { id },
    data: { published: !current },
  });
  revalidatePath("/posts");
}
```

## 2. List Page (Server Component)

```tsx
// src/app/posts/page.tsx
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
              {/* Inline forms calling Server Actions directly - no client JS required */}
              <form
                action={togglePublished.bind(null, post.id, post.published)}
              >
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

> `.bind(null, arg)` on a Server Action lets you pass extra arguments while keeping the function signature compatible with the `action` prop, which only supplies `FormData` automatically.

## 3. New Post Form (Client Component using `useActionState`)

```tsx
// src/app/posts/new/page.tsx
import { db } from "@/lib/db";
import { NewPostForm } from "./new-post-form";

export default async function NewPostPage() {
  // Fetch authors server-side to populate a <select>
  const authors = await db.author.findMany({ orderBy: { name: "asc" } });
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
  // React 19's useActionState wires the form action to pending/error state
  // without any manual useState + onSubmit + fetch boilerplate.
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
import { db } from "@/lib/db";
import { notFound } from "next/navigation";

type PageProps = {
  params: Promise<{ id: string }>; // params is a Promise in Next.js 16
};

export default async function PostDetailPage({ params }: PageProps) {
  const { id } = await params; // must await before using

  const post = await db.post.findUnique({
    where: { id },
    include: { author: true },
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

## 5. Full-Text-ish Search Example (Bonus)

```ts
// src/app/posts/actions.ts (add-on)
export async function searchPosts(query: string) {
  return db.post.findMany({
    where: {
      OR: [
        { title: { contains: query, mode: "insensitive" } },
        { content: { contains: query, mode: "insensitive" } },
      ],
    },
    take: 20,
  });
}
```

Continue to **Part 4: Prisma Relations, Transactions & Connection Pooling**.
