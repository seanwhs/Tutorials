This is the final setup for your comments system, integrating Clerk’s user context with Sanity’s write client to enable authenticated, server-side content submission.

---

## Blog Tutorial — Part 8: Comments System

In this part, we implement a robust comments system where signed-in users can post content. These are stored as documents in Sanity and linked to the Clerk user profile.

### Step 1: Sanity Write Client & Schema

Ensure `SANITY_API_WRITE_TOKEN` (Editor role) is added to your `.env.local`. Create `src/sanity/lib/writeClient.ts`:

```typescript
import { createClient } from "next-sanity";

export const writeClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: false, // Required for write operations
  token: process.env.SANITY_API_WRITE_TOKEN,
});

```

Define your comment schema in `src/sanity/schemaTypes/comment.ts`:

```typescript
import { defineField, defineType } from "sanity";
import { ChatIcon } from "@sanity/icons/Chat";

export const comment = defineType({
  name: "comment",
  title: "Comment",
  type: "document",
  icon: ChatIcon,
  fields: [
    defineField({ name: "post", type: "reference", to: [{ type: "post" }] }),
    defineField({ name: "userId", type: "string" }),
    defineField({ name: "userName", type: "string" }),
    defineField({ name: "userImageUrl", type: "url" }),
    defineField({ name: "text", type: "text" }),
    defineField({ name: "createdAt", type: "datetime" }),
  ],
});

```

### Step 2: Server Action for Submissions

Use a Server Action in `src/app/actions/comments.ts` to process submissions securely:

```typescript
"use server";

import { auth, currentUser } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { writeClient } from "@/sanity/lib/writeClient";

export async function submitComment(formData: FormData) {
  const { userId } = await auth();
  if (!userId) throw new Error("Unauthorized");

  const postId = formData.get("postId") as string;
  const postSlug = formData.get("postSlug") as string;
  const text = (formData.get("text") as string)?.trim();

  if (!text) throw new Error("Comment empty");

  const user = await currentUser();
  await writeClient.create({
    _type: "comment",
    post: { _type: "reference", _ref: postId },
    userId,
    userName: user?.fullName || user?.username || "Anonymous",
    userImageUrl: user?.imageUrl || "",
    text,
    createdAt: new Date().toISOString(),
  });

  revalidatePath(`/posts/${postSlug}`);
}

```

### Step 3: Comments UI

Update `src/components/Comments.tsx` using the Clerk `<Show/>` pattern:

```tsx
import { Show, SignInButton } from "@clerk/nextjs";
import { client } from "@/sanity/lib/client";
import { COMMENTS_BY_POST_QUERY } from "@/sanity/lib/queries";
import { submitComment } from "@/app/actions/comments";

export default async function Comments({ postId, postSlug }: { postId: string, postSlug: string }) {
  const comments = await client.fetch(COMMENTS_BY_POST_QUERY, { postId });

  return (
    <section className="mt-16 border-t pt-8">
      <h2 className="text-2xl font-semibold">Comments ({comments.length})</h2>

      <Show when="signed-in">
        <form action={submitComment} className="mt-6">
          <input type="hidden" name="postId" value={postId} />
          <input type="hidden" name="postSlug" value={postSlug} />
          <textarea name="text" required className="w-full border p-2" />
          <button type="submit" className="bg-black text-white px-4 py-2 mt-2">Post Comment</button>
        </form>
      </Show>

      <Show when="signed-out">
        <div className="mt-6">
          <SignInButton mode="modal"><button className="underline">Sign in</button></SignInButton> to comment.
        </div>
      </Show>
    </section>
  );
}

```

---

### Checkpoint ✅

* [ ] **Write Access:** `SANITY_API_WRITE_TOKEN` configured.
* [ ] **Data Flow:** Server Actions correctly link Clerk identity to Sanity documents.
* [ ] **UX:** `<Show/>` components successfully gate the interaction UI.

Part 8 is complete. Are you ready for **Part 9: Members-Only Premium Posts**?
