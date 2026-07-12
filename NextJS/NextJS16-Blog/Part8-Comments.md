## Blog Tutorial - Part 8: Comments System (Clerk-gated, stored in Sanity)

### What we're doing

We'll implement a comment system where signed-in users can post comments. These will be stored as documents in Sanity, linked to both the post and the Clerk user profile. We'll use Server Actions for submission and `revalidatePath` for instant UI updates.

### ⚠️ Important: Clerk v7+ Compatibility

Your project is using `@clerk/nextjs` v7.5.17. The `SignedIn` and `SignedOut` components are deprecated. **You must use the `<Show/>` component** as shown below to avoid build errors.

---

### Step 1: Sanity Write Access

1. Go to [Sanity Manage](https://www.sanity.io/manage), select your project → **API** tab → **Tokens**.
2. Click **Add API token**, name it `blog-write-token`, set role to **Editor**, and save.
3. Add the token to your `.env.local`:

```bash
SANITY_API_WRITE_TOKEN=your_token_here

```

### Step 2: Create a Server-Only Write Client

Create `src/sanity/lib/writeClient.ts`:

```ts
import { createClient } from "next-sanity";

export const writeClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: "2024-01-01",
  useCdn: false, // Must be false for write operations
  token: process.env.SANITY_API_WRITE_TOKEN,
});

```

### Step 3: Schema & Queries

Create `src/sanity/schemaTypes/comment.ts`:

```ts
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
    defineField({ name: "approved", type: "boolean", initialValue: true }),
    defineField({ name: "createdAt", type: "datetime" }),
  ],
});

```

* **Register:** Add `comment` to your `types` array in `src/sanity/schemaTypes/index.ts`.
* **Query:** Add this to `src/sanity/lib/queries.ts`:

```ts
export const COMMENTS_BY_POST_QUERY = groq`
  *[_type == "comment" && post._ref == $postId && approved == true] | order(createdAt asc) {
    _id, userId, userName, userImageUrl, text, createdAt
  }
`;

```

### Step 4: Server Action (`src/app/actions/comments.ts`)

```ts
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
    approved: true,
    createdAt: new Date().toISOString(),
  });

  revalidatePath(`/posts/${postSlug}`);
}

```

### Step 5: Build the Comments UI (`src/components/Comments.tsx`)

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
          <SignInButton mode="modal"><button className="underline">Sign in</button></SignInButton> to leave a comment.
        </div>
      </Show>
    </section>
  );
}

```

### Step 6: Final Configuration

1. **Next Config:** Add Clerk images to `next.config.ts`:

```ts
images: { 
  remotePatterns: [
    { protocol: "https", hostname: "cdn.sanity.io" },
    { protocol: "https", hostname: "img.clerk.com" }
  ] 
},

```

2. **Render:** Add `<Comments postId="{post._id}" postSlug="{post.slug.current}"/>` to your post page template.

---

**Checkpoint ✅**

* [ ] `SANITY_API_WRITE_TOKEN` set and server restarted.
* [ ] `Comment` schema registered and visible.
* [ ] Comments render and `<Show/>` components work.
* [ ] Avatars render successfully.

**Ready to proceed to Part 9: Members-Only Premium Posts?**
