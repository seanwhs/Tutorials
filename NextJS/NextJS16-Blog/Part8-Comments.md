## Blog Tutorial - Part 8: Comments System (Clerk-gated, stored in Sanity)

## What we're doing
We'll let signed-in users leave comments on posts. Comments will be stored as Sanity documents (referencing the post and the Clerk user), submitted via a Next.js Server Action, and displayed on the post page. Comment creation requires the Sanity write token we skipped in Part 2.

## ⚠️ Next.js 16 reminder: auth() and currentUser() are async

This is the first Part where we actually call Clerk's `auth()` and `currentUser()` helpers ourselves (inside a Server Action). Both must be `await`-ed.

## Step 1: Create a Sanity API token with write access
1. Go to https://www.sanity.io/manage, select your project
2. Go to API tab, then Tokens
3. Click "Add API token"
4. Name it "blog-write-token", permissions: Editor
5. Copy the token (shown once)

Add it to .env.local:

```bash
SANITY_API_WRITE_TOKEN=your_token_here
```

Never expose this token to the browser. It must only be used in server-side code (Server Actions, Route Handlers).

## Step 2: Create a server-only Sanity write client

Create src/sanity/lib/writeClient.ts:

```ts
import { createClient } from "next-sanity";

export const writeClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2024-01-01",
  useCdn: false,
  token: process.env.SANITY_API_WRITE_TOKEN,
});
```

## Step 3: Add a comment schema

Create src/sanity/schemaTypes/comment.ts:

```ts
import { defineField, defineType } from "sanity";
import { CommentIcon } from "@sanity/icons";

export const comment = defineType({
  name: "comment",
  title: "Comment",
  type: "document",
  icon: CommentIcon,
  fields: [
    defineField({ name: "post", title: "Post", type: "reference", to: [{ type: "post" }], validation: (Rule) => Rule.required() }),
    defineField({ name: "userId", title: "Clerk User ID", type: "string", validation: (Rule) => Rule.required() }),
    defineField({ name: "userName", title: "User Name", type: "string" }),
    defineField({ name: "userImageUrl", title: "User Image URL", type: "url" }),
    defineField({ name: "text", title: "Comment Text", type: "text", rows: 3, validation: (Rule) => Rule.required().max(1000) }),
    defineField({ name: "approved", title: "Approved", type: "boolean", initialValue: true, description: "Uncheck to hide a comment without deleting it." }),
    defineField({ name: "createdAt", title: "Created At", type: "datetime", initialValue: () => new Date().toISOString() }),
  ],
  preview: {
    select: { title: "userName", subtitle: "text" },
  },
});
```

Register it in src/sanity/schemaTypes/index.ts (add comment to the imports and to the types array alongside post, author, category, blockContent).

## Step 4: Add a comments query

Add to src/sanity/lib/queries.ts:

```ts
export const COMMENTS_BY_POST_QUERY = groq`
  *[_type == "comment" && post._ref == $postId && approved == true] | order(createdAt asc) {
    _id, userId, userName, userImageUrl, text, createdAt
  }
`;
```

## Step 5: Create a Server Action to submit a comment (Next.js 16: await auth())

Create src/app/actions/comments.ts:

```ts
"use server";

import { auth, currentUser } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { writeClient } from "@/sanity/lib/writeClient";

export async function submitComment(formData: FormData) {
  const { userId } = await auth();
  if (!userId) {
    throw new Error("You must be signed in to comment.");
  }

  const postId = formData.get("postId") as string;
  const postSlug = formData.get("postSlug") as string;
  const text = (formData.get("text") as string)?.trim();

  if (!text || text.length === 0) {
    throw new Error("Comment cannot be empty.");
  }
  if (text.length > 1000) {
    throw new Error("Comment is too long.");
  }

  const user = await currentUser();

  await writeClient.create({
    _type: "comment",
    post: { _type: "reference", _ref: postId },
    userId,
    userName: user?.fullName || user?.username || "Anonymous",
    userImageUrl: user?.imageUrl || "",
    text,
    approved: true,
    createdAt: new Date().toISOString(),
  });

  revalidatePath(`/posts/${postSlug}`);
}
```

Notice both `auth()` and `currentUser()` are called with `await` — this is required in Next.js 16 with current Clerk versions. Forgetting the `await` on `auth()` will give you a Promise object instead of `{ userId }`, causing `userId` to always be `undefined` and every comment submission to incorrectly throw "You must be signed in."

`revalidatePath` immediately busts the ISR cache for that specific post page so the new comment shows up right away, without waiting for the 60-second window.

## Step 6: Build the Comments UI (list + form)

Create src/components/Comments.tsx:

```tsx
import Image from "next/image";
import { SignedIn, SignedOut, SignInButton } from "@clerk/nextjs";
import { client } from "@/sanity/lib/client";
import { COMMENTS_BY_POST_QUERY } from "@/sanity/lib/queries";
import { submitComment } from "@/app/actions/comments";

interface CommentDoc {
  _id: string;
  userId: string;
  userName: string;
  userImageUrl?: string;
  text: string;
  createdAt: string;
}

export default async function Comments({
  postId,
  postSlug,
}: {
  postId: string;
  postSlug: string;
}) {
  const comments = await client.fetch<CommentDoc[]>(COMMENTS_BY_POST_QUERY, {
    postId,
  });

  return (
    <section className="mt-16 border-t border-gray-200 pt-8 dark:border-gray-800">
      <h2 className="text-2xl font-semibold">
        Comments ({comments.length})
      </h2>

      <SignedIn>
        <form action={submitComment} className="mt-6 space-y-3">
          <input type="hidden" name="postId" value={postId} />
          <input type="hidden" name="postSlug" value={postSlug} />
          <textarea
            name="text"
            required
            maxLength={1000}
            rows={3}
            placeholder="Share your thoughts..."
            className="w-full rounded-lg border border-gray-300 p-3 focus:outline-none focus:ring-2 focus:ring-blue-500 dark:border-gray-700 dark:bg-gray-900"
          />
          <button
            type="submit"
            className="rounded-full bg-black px-5 py-2 text-sm font-medium text-white dark:bg-white dark:text-black"
          >
            Post Comment
          </button>
        </form>
      </SignedIn>

      <SignedOut>
        <div className="mt-6 rounded-lg bg-gray-50 p-4 text-sm text-gray-600 dark:bg-gray-900 dark:text-gray-300">
          <SignInButton mode="modal">
            <button className="font-medium underline">Sign in</button>
          </SignInButton>{" "}
          to leave a comment.
        </div>
      </SignedOut>

      <ul className="mt-8 space-y-6">
        {comments.map((c) => (
          <li key={c._id} className="flex gap-3">
            {c.userImageUrl ? (
              <Image
                src={c.userImageUrl}
                alt={c.userName}
                width={40}
                height={40}
                className="h-10 w-10 rounded-full object-cover"
              />
            ) : (
              <div className="h-10 w-10 rounded-full bg-gray-300" />
            )}
            <div>
              <div className="flex items-center gap-2">
                <span className="font-medium">{c.userName}</span>
                <span className="text-xs text-gray-500">
                  {new Date(c.createdAt).toLocaleDateString()}
                </span>
              </div>
              <p className="mt-1 text-gray-700 dark:text-gray-300">
                {c.text}
              </p>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
```

Because c.userImageUrl comes from Clerk (a different domain than Sanity's CDN), add Clerk's image domain to next.config so next/image accepts it. Update next.config.ts remotePatterns array to also include hostname "img.clerk.com".

## Step 7: Add Comments to the post page

In src/app/posts/[slug]/page.tsx, import Comments and render it at the bottom of the article, after the closing article tag:

```tsx
import Comments from "@/components/Comments";
```

And in the JSX, right after the closing `</article>` tag:

```tsx
<Comments postId={post._id} postSlug={post.slug.current} />
```

(Recall `post` here already comes from an `await`-ed `params`-derived `slug`, per Part 5.)

## Step 8: Test it

Run the dev server. Sign in, open a post, submit a comment, confirm it appears immediately below the post without a full page reload delay. Sign out and confirm the comment box is replaced by a sign-in prompt, but existing comments are still visible to everyone.

## Checkpoint ✅
- [ ] Comment schema appears in Studio under "Comment"
- [ ] Signed-in users can submit a comment
- [ ] Comments display immediately after submission
- [ ] Signed-out visitors see existing comments plus a sign-in prompt instead of a form
- [ ] Studio lets you uncheck "Approved" on a comment to hide it (moderation)
- [ ] `submitComment` uses `await auth()` and `await currentUser()` — check your terminal for "userId is undefined"-type bugs if you forgot an `await`

Next: **Part 9 — Members-Only Premium Posts**
