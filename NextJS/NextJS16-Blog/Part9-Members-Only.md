## Blog Tutorial — Part 9: Members-Only Premium Posts

We are now enforcing the `isMembersOnly` flag. By performing the check on the server, we ensure that premium content is never sent to the client unless the user has an active session.

### Step 1: Secure Server-Side Gating

Update `src/app/posts/[slug]/page.tsx` to handle authentication. Note that `auth()` must be awaited.

```tsx
import { auth } from "@clerk/nextjs/server";
import MembersOnlyPaywall from "@/components/MembersOnlyPaywall";

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });
  
  if (!post) notFound();

  // Await the auth promise to retrieve the current user state
  const { userId } = await auth();
  const canViewFullContent = !post.isMembersOnly || Boolean(userId);

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      {/* ... Hero and Image rendering ... */}

      <article className="prose prose-lg mt-10 max-w-none dark:prose-invert">
        {canViewFullContent ? (
          post.body && (
            <PortableText value={post.body} components={portableTextComponents} />
          )
        ) : (
          <MembersOnlyPaywall />
        )}
      </article>

      {/* Optionally gate comments as well */}
      {canViewFullContent && (
        <Comments postId={post._id} postSlug={post.slug.current} />
      )}
    </main>
  );
}

```

### Step 2: Paywall Component

Create `src/components/MembersOnlyPaywall.tsx`. Using the `not-prose` class ensures Tailwind Typography doesn't apply article styles to your CTA card.

```tsx
import { SignInButton, SignUpButton } from "@clerk/nextjs";

export default function MembersOnlyPaywall() {
  return (
    <div className="not-prose mt-6 rounded-xl border border-dashed border-gray-300 bg-gray-50 p-8 text-center dark:border-gray-700 dark:bg-gray-900">
      <h3 className="text-xl font-semibold">This post is for members only</h3>
      <p className="mt-2 text-gray-600 dark:text-gray-300">
        Sign in or create a free account to keep reading.
      </p>
      <div className="mt-6 flex justify-center gap-3">
        <SignInButton mode="modal">
          <button className="rounded-full bg-black px-5 py-2 text-sm font-medium text-white dark:bg-white dark:text-black">
            Sign In
          </button>
        </SignInButton>
        <SignUpButton mode="modal">
          <button className="rounded-full border border-gray-300 px-5 py-2 text-sm font-medium dark:border-gray-700">
            Create Account
          </button>
        </SignUpButton>
      </div>
    </div>
  );
}

```

---

### Checkpoint ✅

* [ ] **True Security:** `post.body` is excluded from the server-rendered HTML for non-members.
* [ ] **Auth Pattern:** `await auth()` is correctly implemented, preventing the common "always show paywall" bug.
* [ ] **UI:** Gated content and comments are appropriately hidden, with clear conversion paths.
