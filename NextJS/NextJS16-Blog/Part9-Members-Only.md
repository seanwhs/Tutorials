## Blog Tutorial - Part 9: Members-Only Premium Posts

## What we're doing
Recall in Part 3 we added an isMembersOnly boolean to the post schema. Now we'll enforce it: signed-out visitors see a paywall preview (title, excerpt, image) but not the full body; signed-in users see everything.

## ⚠️ Next.js 16 change: auth() must be awaited here too

Just like the Server Action in Part 8, calling `auth()` directly inside our Server Component post page requires `await` in Next.js 16.

## Step 1: Check auth state on the server in the post page

Update src/app/posts/[slug]/page.tsx. Import auth from Clerk's server helpers:

```tsx
import { auth } from "@clerk/nextjs/server";
```

Inside the PostPage component, after fetching post and before rendering, add:

```tsx
const { userId } = await auth();
const canViewFullContent = !post.isMembersOnly || Boolean(userId);
```

Since this page already does `const { slug } = await params;` from Part 5, you'll now have two awaited calls near the top of the function — that's expected and fine:

```tsx
export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  if (!post) {
    notFound();
  }

  const { userId } = await auth();
  const canViewFullContent = !post.isMembersOnly || Boolean(userId);

  // ...rest of the component
}
```

## Step 2: Conditionally render the body

Replace the article block that renders PortableText with:

```tsx
<article className="prose prose-lg mt-10 max-w-none dark:prose-invert">
  {canViewFullContent ? (
    post.body && (
      <PortableText value={post.body} components={portableTextComponents} />
    )
  ) : (
    <MembersOnlyPaywall />
  )}
</article>
```

## Step 3: Build the paywall component

Create src/components/MembersOnlyPaywall.tsx:

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

Import it at the top of the post page file:

```tsx
import MembersOnlyPaywall from "@/components/MembersOnlyPaywall";
```

`not-prose` tells the Tailwind Typography plugin to skip styling this block like article text, since it's a UI card, not content.

## Step 4: Also hide comments behind the same gate (optional but recommended)

In the post page JSX, wrap the Comments component call:

```tsx
{canViewFullContent && (
  <Comments postId={post._id} postSlug={post.slug.current} />
)}
```

This prevents non-members from reading discussion that might spoil the gated content.

## Step 5: Important security note

Because we check `await auth()` on the **server** inside the Server Component before rendering, the members-only body content (post.body) is **never sent to the browser at all** for signed-out users — this is not just a CSS trick hiding content, it is truly excluded from the HTML/JSON payload. This is one of the biggest advantages of Next.js Server Components for building paywalls, and it's unchanged in Next.js 16 — only the syntax to read `auth()` changed (now async).

## Step 6: Test it

1. In the Studio, edit your post (or create a new one) and check "Members Only", publish.
2. Open the post in an incognito/private browser window (signed out) — you should see the title/image/excerpt-area but a paywall instead of the article body, and no comment box.
3. Sign in — refresh — you should now see the full article and comments.

## Checkpoint ✅
- [ ] Signed-out users see the paywall on members-only posts
- [ ] Signed-in users see full content
- [ ] Regular (non-members-only) posts are unaffected and visible to everyone
- [ ] View source / inspect network response confirms gated body content isn't leaked to signed-out users
- [ ] `await auth()` is used (not the old synchronous `auth()` call). If you forget the `await`, destructuring `userId` off a raw Promise object gives `undefined`, which would incorrectly treat every visitor — even signed-in ones — as logged out, showing the paywall to everyone. If signed-in users unexpectedly see the paywall, this missing `await` is the first thing to check.

Next: **Part 10 — SEO: Metadata, Sitemap, Robots.txt, Open Graph Images**
