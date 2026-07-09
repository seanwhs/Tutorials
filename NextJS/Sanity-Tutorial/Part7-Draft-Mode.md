# Sanity Mastery - Part 7: Draft Mode & Live Preview

Goal: let an editor click "Preview" inside Sanity Studio and see their **unpublished draft** rendered on the live Next.js site, without exposing drafts to normal visitors.

## Step 1: Get a read token with draft access

1. https://www.sanity.io/manage → your project → **API** → **Tokens** → **Add API token**
2. Name: `Next.js Preview Token`, Permissions: **Viewer** (read-only is enough — we only need to *read* drafts, not write)
3. Copy the token — it's shown once.

```bash
# .env.local
SANITY_API_READ_TOKEN=sk_your_token_here
SANITY_PREVIEW_SECRET=generate_a_long_random_string_here
```

> Generate the secret with `openssl rand -hex 32` or any password generator — it's used to prevent randoms from toggling draft mode on your live site.

## Step 2: A perspective-aware client for previews

```ts
// src/sanity/client.ts (extended from Part 4)
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  useCdn: true,
});

// Separate client for draft/preview reads: bypasses CDN (always fresh),
// authenticated with a token, and set to see draft documents.
export const previewClient = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2025-01-01",
  useCdn: false,
  token: process.env.SANITY_API_READ_TOKEN,
  perspective: "previewDrafts", // see the draft version of a doc if one exists
});
```

## Step 3: Update `sanityFetch` to switch clients based on Next.js 16's async `draftMode()`

```ts
// src/sanity/fetch.ts
import { draftMode } from "next/headers";
import { client, previewClient } from "./client";
import type { QueryParams } from "next-sanity";

export async function sanityFetch<T>({
  query,
  params = {},
  tags = [],
}: {
  query: string;
  params?: QueryParams;
  tags?: string[];
}): Promise<T> {
  // CRITICAL Next.js 16 pattern: draftMode() returns a Promise now, must be awaited.
  const { isEnabled } = await draftMode();

  if (isEnabled) {
    // Bypass Data Cache entirely while in draft mode — editors must always see
    // the latest edit, even edits made seconds ago.
    return previewClient.fetch<T>(query, params, { cache: "no-store" });
  }

  return client.fetch<T>(query, params, { next: { tags } });
}
```

> Because every page already calls `sanityFetch`, **this one change makes every page in the app preview-aware for free** — no per-page conditional logic needed.

## Step 4: The enable-draft-mode Route Handler

```ts
// src/app/api/draft/route.ts
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";
import { client } from "@/sanity/client";
import { postBySlugQuery } from "@/sanity/queries";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const secret = searchParams.get("secret");
  const slug = searchParams.get("slug");
  const type = searchParams.get("type") ?? "post";

  if (secret !== process.env.SANITY_PREVIEW_SECRET) {
    return new Response("Invalid preview secret", { status: 401 });
  }

  if (!slug) {
    return new Response("Missing slug", { status: 400 });
  }

  // Sanity-check the target document actually exists (prevents open redirect abuse)
  const exists = await client.fetch(
    `*[_type == $type && slug.current == $slug][0]._id`,
    { type, slug }
  );
  if (!exists) {
    return new Response("Post not found", { status: 404 });
  }

  // CRITICAL Next.js 16 pattern: draftMode() is async here too.
  const draft = await draftMode();
  draft.enable(); // sets an httpOnly cookie that flips isEnabled -> true on future requests

  redirect(`/blog/${slug}`);
}
```

```ts
// src/app/api/draft/disable/route.ts — lets editors exit preview mode
import { draftMode } from "next/headers";
import { redirect } from "next/navigation";

export async function GET() {
  const draft = await draftMode();
  draft.disable();
  redirect("/blog");
}
```

## Step 5: Configure the Studio's "Open Preview" action

```ts
// sanity.config.ts (extended)
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schema } from "./src/sanity/schemaTypes";

export default defineConfig({
  name: "default",
  title: "My Sanity App",
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  plugins: [structureTool(), visionTool()],
  schema,
  basePath: "/studio",

  document: {
    // Adds a "Preview" button in the Studio document toolbar for `post` docs,
    // opening our draft-mode route with the correct slug pre-filled.
    productionUrl: async (prev, { document }) => {
      if (document._type !== "post") return prev;
      const slug = (document.slug as { current?: string } | undefined)?.current;
      if (!slug) return prev;

      const params = new URLSearchParams({
        secret: process.env.SANITY_PREVIEW_SECRET!,
        slug,
        type: "post",
      });
      return `${process.env.NEXT_PUBLIC_SITE_URL}/api/draft?${params.toString()}`;
    },
  },
});
```

```bash
# .env.local — add the site URL used above
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

## Step 6: Show a visible "Preview Mode" banner

```tsx
// src/components/PreviewBanner.tsx
import { draftMode } from "next/headers";
import Link from "next/link";

export async function PreviewBanner() {
  const { isEnabled } = await draftMode(); // async in Next.js 16

  if (!isEnabled) return null;

  return (
    <div className="bg-yellow-400 text-black text-sm px-4 py-2 flex items-center justify-between">
      <span>👁️ Preview Mode — viewing draft content</span>
      <Link href="/api/draft/disable" className="underline font-medium">
        Exit preview
      </Link>
    </div>
  );
}
```

```tsx
// src/app/layout.tsx (relevant excerpt)
import { PreviewBanner } from "@/components/PreviewBanner";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <PreviewBanner />
        {children}
      </body>
    </html>
  );
}
```

## How It All Connects

```text
Editor clicks "Preview" in Studio
   → GET /api/draft?secret=...&slug=hello-world
       → validates secret + doc exists
       → draftMode().enable()  (sets cookie)
       → redirects to /blog/hello-world
           → PostPage renders
               → sanityFetch() sees isEnabled=true
                   → uses previewClient (token, no CDN, sees drafts)
           → PreviewBanner renders, shows "Exit preview" link
```

## Checkpoint ✅
- [ ] Viewer-role token created and stored server-side only (`SANITY_API_READ_TOKEN`)
- [ ] `previewClient` added and `sanityFetch` branches on awaited `draftMode()`
- [ ] `/api/draft` and `/api/draft/disable` route handlers created
- [ ] Studio's "Preview" button opens the live app showing unpublished edits
- [ ] Yellow preview banner appears/disappears correctly

**Next: Part 8 — On-Demand Revalidation via Webhooks**
