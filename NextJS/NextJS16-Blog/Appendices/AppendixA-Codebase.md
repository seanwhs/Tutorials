## Blog Tutorial - Appendix A: Full Reference Codebase (Part 1 of 2)

This appendix consolidates every file created throughout the tutorial into one reference, updated for **Next.js 16 / Tailwind CSS v4**. Use it to double check your own code, or as a quick copy-paste source if you fall behind. Part 1 covers configuration and Sanity files. Part 2 (separate note) covers all app/ pages and components.

## Project root files

### package.json (key dependencies only — versions will vary slightly)
Dependencies installed across the tutorial: next (v16), react (v19), react-dom (v19), typescript, tailwindcss (v4), @tailwindcss/typography, @sanity/client, @sanity/image-url, @portabletext/react, next-sanity, sanity, groq, @clerk/nextjs (a version with confirmed Next.js 16 support), react-syntax-highlighter, next-themes.

### Node.js requirement
Next.js 16 requires **Node.js 20.9+** (Node 22 LTS recommended). Verify with `node -v` before running any commands in this project.

### .env.local (fill in your own real values — never commit this file)
```
NEXT_PUBLIC_SANITY_PROJECT_ID=
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-01-01
SANITY_API_WRITE_TOKEN=
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

### Tailwind CSS v4 — no tailwind.config.ts

Unlike Next.js 14 tutorials, there is **no `tailwind.config.ts` file** in this project. All Tailwind configuration lives inside `src/app/globals.css`:

```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";

@custom-variant dark (&:where(.dark, .dark *));

body {
  @apply bg-white text-gray-900 dark:bg-gray-950 dark:text-gray-100;
}
```

### next.config.ts
```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "cdn.sanity.io" },
      { protocol: "https", hostname: "img.clerk.com" },
    ],
  },
};

export default nextConfig;
```

### sanity.config.ts
```ts
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schema } from "./src/sanity/schemaTypes";

export default defineConfig({
  name: "default",
  title: "My Blog",
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  plugins: [structureTool(), visionTool()],
  schema,
  basePath: "/studio",
});
```

### sanity.cli.ts
```ts
import { defineCliConfig } from "sanity/cli";

export default defineCliConfig({
  api: {
    projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
    dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  },
});
```

## src/middleware.ts
```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/((?!_next|studio|.*\\..*).*)", "/(api|trpc)(.*)"],
};
```

## Sanity schema files (src/sanity/schemaTypes/)

These are plain Sanity SDK schema definitions — unaffected by the Next.js 16 upgrade (no async/await concerns here).

### index.ts
```ts
import { type SchemaTypeDefinition } from "sanity";
import { post } from "./post";
import { author } from "./author";
import { category } from "./category";
import { blockContent } from "./blockContent";
import { comment } from "./comment";

export const schema: { types: SchemaTypeDefinition[] } = {
  types: [post, author, category, blockContent, comment],
};
```

### post.ts, author.ts, category.ts, blockContent.ts, comment.ts
See Parts 3 and 8 of the tutorial for the full definitions of each schema file — they are reproduced there in full and are unchanged in the final app.

## Sanity lib files (src/sanity/lib/)

These are also unaffected by the Next.js 16 upgrade — the Sanity client and GROQ queries are plain data-fetching code, not route/page files, so nothing here needs `await params` or `await auth()`.

### client.ts
```ts
import { createClient } from "next-sanity";

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  apiVersion: process.env.NEXT_PUBLIC_SANITY_API_VERSION || "2024-01-01",
  useCdn: process.env.NODE_ENV === "production",
});
```

### writeClient.ts
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

### image.ts
```ts
import createImageUrlBuilder from "@sanity/image-url";
import type { SanityImageSource } from "@sanity/image-url/lib/types/types";
import { client } from "./client";

const builder = createImageUrlBuilder(client);

export function urlForImage(source: SanityImageSource) {
  return builder.image(source);
}
```

### queries.ts and types.ts
See Parts 4 and 6 for the complete, final versions of all GROQ queries (POSTS_QUERY, POST_QUERY, POST_SLUGS_QUERY, POSTS_BY_CATEGORY_QUERY, CATEGORIES_QUERY, AUTHOR_QUERY, AUTHOR_SLUGS_QUERY, POSTS_BY_AUTHOR_QUERY, CATEGORY_QUERY, CATEGORY_SLUGS_QUERY, COMMENTS_BY_POST_QUERY) and TypeScript interfaces (SanityImage, Author, Category, Post) — unchanged in the final app.

## Blog Tutorial - Appendix A: Full Reference Codebase (Part 2 of 2)

This covers the app/ directory routes and all components, updated for **Next.js 16**. All code is reproduced in full in earlier tutorial parts (as noted below); this is a consolidated file map for quick reference.

## File map

```
src/
  middleware.ts
  app/
    layout.tsx                        (Parts 1, 7, 10, 11)
    page.tsx                          (Part 4 — no dynamic params)
    globals.css                       (Part 1, 11 — Tailwind v4 CSS-first config)
    sitemap.ts                        (Part 10 — no dynamic params)
    robots.ts                         (Part 10 — no dynamic params)
    studio/[[...tool]]/page.tsx       (Part 2 — params unused, no await needed)
    sign-in/[[...sign-in]]/page.tsx   (Part 7 — params unused, no await needed)
    sign-up/[[...sign-up]]/page.tsx   (Part 7 — params unused, no await needed)
    posts/[slug]/page.tsx             (Parts 5, 9, 10 — ⚠️ async params + async auth())
    posts/[slug]/opengraph-image.tsx  (Part 10 — ⚠️ async params)
    categories/[slug]/page.tsx        (Part 6 — ⚠️ async params)
    authors/[slug]/page.tsx           (Part 6 — ⚠️ async params)
    actions/comments.ts               (Part 8 — ⚠️ async auth() + currentUser())
  components/
    Header.tsx                        (Parts 6, 7, 11)
    Footer.tsx                        (Part 11)
    PostCard.tsx                      (Part 4)
    PortableTextComponents.tsx        (Part 5)
    CodeBlock.tsx                     (Part 5)
    Comments.tsx                      (Part 8)
    MembersOnlyPaywall.tsx            (Part 9)
    ThemeProvider.tsx                 (Part 11)
    ThemeToggle.tsx                   (Part 11)
  sanity/
    schemaTypes/{index,post,author,category,blockContent,comment}.ts  (Parts 3, 8 — unaffected by Next.js 16)
    lib/{client,writeClient,image,queries,types}.ts                   (Parts 4, 6, 8 — unaffected by Next.js 16)
```

## Next.js 16 checklist — every file marked ⚠️ above must follow this pattern

For any route file with a `[slug]` (or other dynamic segment) in its path:

```tsx
type PageProps = {
  params: Promise<{ slug: string }>;
};

export default async function SomePage({ params }: PageProps) {
  const { slug } = await params;
  // ... use slug
}
```

This applies identically to the default page export, `generateMetadata`, and special files like `opengraph-image.tsx`. `generateStaticParams` itself is unaffected — it still returns a plain array of `{ slug }` objects.

For any Server Component or Server Action that calls Clerk's `auth()` or `currentUser()`:

```tsx
import { auth } from "@clerk/nextjs/server";

const { userId } = await auth();
```

## Final version notes / diffs to be aware of

Some files were created in an early part and then modified in a later part. Make sure your final version matches the **latest** part referencing that file:

- **layout.tsx**: final version wraps children in `ClerkProvider` > `html` (with `suppressHydrationWarning`) > `body` > `ThemeProvider` > `Header` + `{children}` + `Footer`, and exports the expanded `metadata` object with `metadataBase`, title template, and Open Graph/Twitter defaults from Part 10.

- **globals.css**: final version contains `@import "tailwindcss";`, `@plugin "@tailwindcss/typography";`, `@custom-variant dark (&:where(.dark, .dark *));`, and the `body` base style rule — all from Parts 1 and 11. There is no `tailwind.config.ts` anywhere in this project.

- **Header.tsx**: final version is an async Server Component that fetches categories from Sanity, and renders category links, `ThemeToggle`, and Clerk's `SignedIn`/`SignedOut`/`SignInButton`/`UserButton`.

- **posts/[slug]/page.tsx**: final version types `params` as `Promise<{ slug: string }>`, awaits it in both `generateMetadata` and the page component, includes `generateStaticParams`, the Open Graph fields from Part 10, the `await auth()` check and `canViewFullContent` gate from Part 9, conditional rendering of either `PortableText` or `MembersOnlyPaywall`, and a conditionally-rendered `Comments` component at the bottom.

- **posts/[slug]/opengraph-image.tsx**: final version types `params` as `Promise<{ slug: string }>` and awaits it before fetching the post, per Part 10.

- **categories/[slug]/page.tsx** and **authors/[slug]/page.tsx**: both type `params` as `Promise<{ slug: string }>` and await it, per Part 6.

- **actions/comments.ts**: final version awaits both `auth()` and `currentUser()` before using their results, per Part 8.

- **next.config.ts**: final version allows both `cdn.sanity.io` (Part 4) and `img.clerk.com` (Part 8, for comment author avatars) as remote image patterns. Note the `.ts` extension, matching what Next.js 16's create-next-app generates by default.

- **schemaTypes/index.ts**: final version registers all five types: `post`, `author`, `category`, `blockContent`, `comment`.

## Quick-start: cloning this structure from scratch

If you want to type out the whole project quickly using just this appendix as reference (skipping the step-by-step narrative), the build order that avoids missing-dependency errors is:

1. `create-next-app` with TypeScript + Tailwind CSS v4 + App Router + src/ dir + Turbopack (Part 1) — confirm Node 20.9+/22 LTS first
2. Install all npm packages listed in Part 1 and Part 5/8/11 (`react-syntax-highlighter`, `next-themes`)
3. Sanity config files + schema files + register in index.ts (Parts 2–3, 8 for comment.ts)
4. Sanity lib files: client, image, queries, types, writeClient (Parts 4, 6, 8)
5. Studio route page (Part 2)
6. Homepage + PostCard (Part 4)
7. Post detail page (async params) + PortableText components + CodeBlock (Part 5)
8. Category + Author pages (async params) + Header nav (Part 6)
9. Clerk middleware, layout ClerkProvider, sign-in/up pages, Header auth buttons (Part 7)
10. Comments schema, query, server action (async auth/currentUser), Comments component, wire into post page (Part 8)
11. MembersOnlyPaywall + gating logic (async auth) in post page (Part 9)
12. sitemap.ts, robots.ts, opengraph-image.tsx (async params), expanded metadata (Part 10)
13. ThemeProvider, ThemeToggle, Footer, globals.css Tailwind v4 config + dark variant (Part 11)
14. Push to GitHub, deploy to Vercel (confirm Node 20.x+ in project settings), configure env vars + Sanity CORS + Clerk domains (Part 12)

For the full code of any file, refer to the tutorial part noted next to it above — every snippet in this series is complete and copy-paste ready (no "..." omissions), so the tutorial parts themselves ARE your full codebase reference.
