## Part 9: Performance & Optimization

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Image optimization, edge-caching strategies, bundle splitting, and a Lighthouse pass over Orbit.

---

### 1. Concept Explanation

Performance work in a multi-service app has service-specific angles:

- **Sanity** serves images through its own CDN with on-the-fly transforms (resize/format) via URL parameters — we should never re-host or manually resize Sanity images; instead use `@sanity/image-url` to build correctly-sized URLs and let `next/image` handle responsive `srcset`/lazy-loading on top.
- **Clerk**'s `UserButton`/`SignIn` components are already optimized (code-split, lazy-loaded internally) — the main lever we have is making sure we don't accidentally import server-only Clerk helpers into client bundles.
- **Prisma** performance is a database-side concern: proper indexes (already added in Part 3's schema via `@@index`), `select`ing only needed fields instead of full rows, and avoiding N+1 query patterns by using `include`/`select` intentionally.
- **Inngest** functions run out-of-band, so they don't affect page load performance directly, but poorly batched `step.run` calls (e.g., one step per row in a loop) waste function-run quota on the free tier — batch database writes (`createMany`) instead of looping `create` calls, as we already did in Part 6.
- **Next.js 16** itself: Turbopack is the default bundler for both dev and (as of 16) build, which meaningfully speeds up build times; combine with route-level code splitting (automatic with the App Router) and `next/dynamic` for genuinely heavy, rarely-used client components (e.g., the Sanity Studio embed from Part 2, which should never be part of the main app bundle).

---

### 2. Implementation

#### 2.1 Sanity image optimization

```ts
// src/lib/sanity/image.ts
import createImageUrlBuilder from "@sanity/image-url";
import { sanityClient } from "./client";

const builder = createImageUrlBuilder(sanityClient);

export function urlForImage(source: { asset: { _ref: string } }) {
  return builder.image(source).auto("format").fit("max");
}
```

```tsx
// usage: rendering a Sanity image field through next/image
import Image from "next/image";
import { urlForImage } from "@/lib/sanity/image";

export function ArticleHeroImage({ image, alt }: { image: { asset: { _ref: string } }; alt: string }) {
  return (
    <Image
      src={urlForImage(image).width(1200).height(630).url()}
      alt={alt}
      width={1200}
      height={630}
      className="rounded-lg"
      priority={false}
    />
  );
}
```

Allow the Sanity CDN domain in Next.js image config:

```ts
// next.config.ts (updated)
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
  images: {
    remotePatterns: [{ protocol: "https", hostname: "cdn.sanity.io" }],
  },
};

export default nextConfig;
```

#### 2.2 Code-split the Sanity Studio out of the main bundle

```tsx
// src/app/studio/[[...tool]]/page.tsx (updated from Part 2)
import dynamic from "next/dynamic";

const NextStudioClient = dynamic(
  () => import("./studio-client").then((mod) => mod.StudioClient),
  { ssr: false }
);

export default function StudioPage() {
  return <NextStudioClient />;
}
```

```tsx
// src/app/studio/[[...tool]]/studio-client.tsx
"use client";

import { NextStudio } from "next-sanity/studio";
import config from "../../../../sanity.config";

export function StudioClient() {
  return <NextStudio config={config} />;
}
```

This ensures the (large) Sanity Studio JS payload only ever loads for the handful of staff visiting `/studio`, never bundled into the client-facing dashboard.

#### 2.3 Select-only Prisma queries (avoid over-fetching)

```ts
// src/lib/db/queries.ts (addition)
import { db } from "./prisma";

export async function getProjectSummariesForClient(clerkUserId: string) {
  return db.project.findMany({
    where: { client: { clerkUserId } },
    select: {
      id: true,
      name: true,
      status: true,
      _count: { select: { tasks: true } },
    },
    orderBy: { createdAt: "desc" },
  });
}
```

Using `_count` instead of `include: { tasks: true }` avoids pulling every task row over the wire just to display a count — a small thing that matters once a project has hundreds of tasks.

#### 2.4 Avoiding N+1s in the admin function from Part 6

Part 6's `notify-admins` step calls `clerkClient().users.getUserList()` once per function run (good — not per admin), but double check any future code doesn't loop a per-user API/DB call. As a rule for this codebase: any `for (const x of list)` loop containing an `await db.*` or `await client.*` call is a smell — batch it (`createMany`, `findMany` with `in`, etc.) or explicitly justify why it can't be batched in a code comment.

#### 2.5 Turbopack build

```bash
pnpm build
```

Next.js 16 defaults to Turbopack for both `next dev` and `next build`. Confirm the build output explicitly states Turbopack was used, and compare cold build times against the legacy Webpack build (`pnpm build --webpack` as a one-off comparison) if curious — Turbopack builds are typically substantially faster on repositories this size.

#### 2.6 Bundle analysis

```bash
pnpm add -D @next/bundle-analyzer
```

```ts
// next.config.ts (final form for this part)
import type { NextConfig } from "next";
import withBundleAnalyzer from "@next/bundle-analyzer";

const nextConfig: NextConfig = {
  cacheComponents: true,
  images: {
    remotePatterns: [{ protocol: "https", hostname: "cdn.sanity.io" }],
  },
};

export default withBundleAnalyzer({ enabled: process.env.ANALYZE === "true" })(nextConfig);
```

```bash
ANALYZE=true pnpm build
```

Opens an interactive treemap; check specifically that `next-sanity/studio` does not appear in the main app's client bundle (it should only show up in the `/studio` route's chunk, confirming 2.2 worked).

#### 2.7 Streaming already covered in Part 7 — extend to the marketing page

```tsx
// src/app/page.tsx (updated with Suspense for cold-cache resilience)
import { Suspense } from "react";
import { getServicePackages } from "@/lib/sanity/queries";

async function PackagesList() {
  const packages = await getServicePackages();
  return (
    <div className="mt-6 grid gap-4 sm:grid-cols-2">
      {packages.map((pkg) => (
        <div key={pkg._id} className="rounded-lg border p-4">
          <h2 className="text-xl font-semibold">{pkg.name}</h2>
          <p className="mt-2 text-sm text-gray-600">{pkg.description}</p>
          <p className="mt-2 font-mono">${pkg.priceUsd}</p>
        </div>
      ))}
    </div>
  );
}

export default function HomePage() {
  return (
    <main className="mx-auto max-w-4xl p-8">
      <h1 className="text-3xl font-bold">Orbit Service Packages</h1>
      <Suspense fallback={<p className="mt-6 text-sm text-muted-foreground">Loading packages…</p>}>
        <PackagesList />
      </Suspense>
    </main>
  );
}
```

#### 2.8 Lighthouse pass

```bash
pnpm build && pnpm start
```

Run Chrome DevTools → Lighthouse against `http://localhost:3000` (Performance + Best Practices + SEO categories) for both the marketing home page and `/dashboard`. Target: 90+ on Performance for the public marketing page (fully static-cacheable content); the authenticated dashboard will score lower on "Best Practices" purely due to Clerk's third-party script, which is expected and acceptable.

---

### 3. Checkpoint

- ✅ `ANALYZE=true pnpm build` confirms `next-sanity/studio` is isolated to the `/studio` chunk.
- ✅ Sanity images render via `next/image` with correctly sized `srcset`s (inspect via DevTools Network tab — should request appropriately scaled Sanity CDN URLs, not full-resolution originals).
- ✅ Lighthouse Performance score on the marketing home page is 90+.
- ✅ `getProjectSummariesForClient` returns in well under 100ms locally against seeded data (check via Prisma's query logging or a simple `console.time`).

---

### 4. Troubleshooting

- **`next/image` throws "invalid src" for Sanity URLs** — confirm `remotePatterns` in `next.config.ts` includes `cdn.sanity.io` exactly; `next/image` refuses unlisted remote hosts by default.
- **Studio still appears in main bundle after dynamic import** — confirm the *page* file doesn't statically import anything from `next-sanity/studio` directly; only the separated `studio-client.tsx` may import it, and it must be dynamically imported with `ssr: false`.
- **Lighthouse dashboard score much lower than expected** — check if Clerk's dev-mode banner/script is inflating it; test against a production Clerk instance/build, not a dev-mode key, for a representative score.

---

Next: **"Ecosystem Tutorial - Part 10: Production Deployment"**

---

Say "next" for the final part, Part 10.
