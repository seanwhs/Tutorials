## Blog Tutorial — Part 9: Members-Only Premium Posts

We are now enforcing the `isMembersOnly` flag. By performing the check on the server, we ensure that premium content is never sent to the client unless the user has an active session.

### Step 1: Secure Server-Side Gating

Update your `src/app/posts/[slug]/page.tsx` file to handle authentication. Note that in Next.js 16, `auth()` must be awaited.

```tsx
import { notFound } from "next/navigation";
import Image from "next/image";
import { PortableText } from "@portabletext/react";
import { auth } from "@clerk/nextjs/server";
import { client } from "@/sanity/lib/client";
import { urlForImage } from "@/sanity/lib/image";
import { POST_QUERY, POST_SLUGS_QUERY } from "@/sanity/lib/queries";
import type { Post } from "@/sanity/lib/types";
import { portableTextComponents } from "@/components/PortableTextComponents";
import Comments from "@/components/Comments";
import MembersOnlyPaywall from "@/components/MembersOnlyPaywall";

export const revalidate = 60;

type PageProps = { params: Promise<{ slug: string }> };

export async function generateStaticParams() {
  const slugs = await client.fetch<string[]>(POST_SLUGS_QUERY);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });
  if (!post) return {};
  return { title: post.title, description: post.excerpt };
}

export default async function PostPage({ params }: PageProps) {
  const { slug } = await params;
  const post = await client.fetch<Post>(POST_QUERY, { slug });

  if (!post) notFound();

  // Await the auth promise to retrieve the current user state
  const { userId } = await auth();
  const canViewFullContent = !post.isMembersOnly || Boolean(userId);

  return (
    <main className="mx-auto max-w-3xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight">{post.title}</h1>

      {post.mainImage && (
        <div className="relative mt-8 h-96 w-full overflow-hidden rounded-xl">
          <Image
            src={urlForImage(post.mainImage).width(1200).height(675).url()}
            alt={post.mainImage.alt || post.title}
            fill
            className="object-cover"
            priority
          />
        </div>
      )}

      <article className="prose prose-lg mt-10 max-w-none dark:prose-invert">
        {canViewFullContent ? (
          post.body && (
            <PortableText
              value={post.body}
              components={portableTextComponents}
            />
          )
        ) : (
          <MembersOnlyPaywall />
        )}
      </article>

      {/* Gate comments as well to protect community discussions */}
      {canViewFullContent && (
        <Comments postId={post._id} postSlug={post.slug.current} />
      )}
    </main>
  );
}

```

### Step 2: Paywall Component

Create `src/components/MembersOnlyPaywall.tsx`. The `not-prose` class is critical here—it prevents the Tailwind Typography plugin from applying unwanted article styling to your CTA card.

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

### Verification: What to Expect at `localhost:3000`

1. **True Security:** In an Incognito window, "View Page Source." The post body will be entirely absent from the HTML, proving it is protected server-side.
2. **Auth Integration:** Ensure your `POST_QUERY` in Sanity fetches the `isMembersOnly` boolean.
3. **UI/UX:** The `not-prose` class ensures the Paywall card renders with clean, consistent spacing regardless of the `prose` typography settings applied to the article.
4. **Instant Feedback:** Signing in via the modal should trigger a re-render that displays the full content and comments without a full page refresh.

### Checkpoint ✅

* [ ] **True Security:** `post.body` is completely excluded from the server-rendered HTML for non-members.
* [ ] **Auth Pattern:** `await auth()` is correctly implemented, ensuring accurate session state handling.
* [ ] **UI:** Gated content and comments are hidden, with clear conversion paths (Sign In/Up) provided for visitors.

---

### The "Freemium" Architectural Milestone

Congratulations—you have officially moved beyond a simple content-display site and into the realm of **authenticated, gated application architecture.**

By implementing this "freemium" model, you haven't just added a "gate"; you have architected a **data-permissive flow** that balances audience growth with content monetization.

1. **Server-Side Enforcement (The "Hard Gate"):** By awaiting `auth()` inside the React Server Component, you have ensured that the sensitive `post.body` **never reaches the client's device** unless they are authenticated.
2. **Frictionless Conversion:** Leveraging `mode="modal"` for Clerk buttons keeps the user in the "flow state" of your application, significantly increasing conversion.
3. **Content as an Asset:** By decoupling the `isMembersOnly` status from the content itself (managed via Sanity CMS), you can change your business model on the fly without touching a single line of code.
4. **Foundation for Growth:** This is the bedrock for future analytics, personalization, and advanced subscription logic (like Stripe integration).

You have moved from "displaying text" to "managing access." This is the core skill that separates a frontend hobbyist from a **full-stack software engineer.**
