## Part 7: Advanced Data Fetching

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Master Next.js 16's caching model — `use cache`, `revalidateTag`, `revalidatePath` — to keep Sanity content and Prisma data fresh across the app without sacrificing performance.

---

### 1. Concept Explanation

Next.js 16 continues the shift (started in 15) toward **explicit, opt-in caching** rather than implicit fetch caching. The directive `"use cache"` marks a function or component's output as cacheable; you then control invalidation precisely with **cache tags**. This is a deliberate design: nothing is cached by accident, and every cached thing has a named tag you can invalidate on demand.

Two invalidation primitives, used for two different situations:

- **`revalidateTag(tag)`** — invalidate every cache entry tagged with `tag`, regardless of which URL/path produced it. Use this when the *same underlying data* might be rendered on multiple pages (e.g., a `servicePackage` shown on the marketing page AND inside the dashboard's "request project" form — one Sanity mutation should bust both).
- **`revalidatePath(path)`** — invalidate the cache for one specific route. Use this when a mutation is scoped to exactly one page's data (e.g., a Server Action that only affects `/dashboard/projects`).

**Where each service fits in this model:**
- **Sanity reads** are the best candidate for `"use cache"` + tags, since content changes infrequently (editorial cadence, not per-request) and the same content often appears on multiple routes.
- **Prisma reads** for a signed-in user's own data are usually *not* cached at all by default (each user's dashboard is inherently dynamic/personalized) — but list views that are the same for all viewers with a given role (e.g., an admin's "all active projects" view) are good `"use cache"` candidates too.
- **Clerk session data** is never cached — it's always read fresh per-request via `auth()`.

---

### 2. Implementation

#### 2.1 Enable the cache directive

```ts
// next.config.ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  cacheComponents: true,
};

export default nextConfig;
```

#### 2.2 Tag Sanity fetches at the source

```ts
// src/lib/sanity/queries.ts (updated from Part 2)
import { sanityClient } from "./client";
import { cacheTag } from "next/cache";

export interface ServicePackage {
  _id: string;
  name: string;
  slug: { current: string };
  description: string;
  priceUsd: number;
  features: string[];
}

const SERVICE_PACKAGES_QUERY = `*[_type == "servicePackage"] | order(priceUsd asc)`;

export async function getServicePackages(): Promise<ServicePackage[]> {
  "use cache";
  cacheTag("service-packages");

  return sanityClient.fetch(SERVICE_PACKAGES_QUERY);
}
```

Every consumer of `getServicePackages()` — the marketing home page from Part 2 *and* the "Request Project" form from Part 5 — now shares one cache entry tagged `"service-packages"`.

#### 2.3 Invalidate on Sanity content changes

```ts
// src/app/api/sanity/revalidate/route.ts
import { NextRequest, NextResponse } from "next/server";
import { revalidateTag } from "next/cache";
import { parseBody } from "next-sanity/webhook";

export async function POST(req: NextRequest) {
  const { body, isValidSignature } = await parseBody<{ _type: string }>(
    req,
    process.env.SANITY_WEBHOOK_SECRET
  );

  if (!isValidSignature) {
    return NextResponse.json({ message: "Invalid signature" }, { status: 401 });
  }

  if (body?._type === "servicePackage") {
    revalidateTag("service-packages");
  }
  if (body?._type === "article") {
    revalidateTag("articles");
  }

  return NextResponse.json({ revalidated: true, now: Date.now() });
}
```

Register this URL (`https://your-domain.vercel.app/api/sanity/revalidate`) under **Settings → API → Webhooks** in the Sanity dashboard, filtered to fire on create/update/delete for both document types, and add a matching secret:

```bash
SANITY_WEBHOOK_SECRET=your_webhook_secret
```

#### 2.4 Tag Prisma reads for shared (non-personalized) views

```ts
// src/lib/db/queries.ts
import { db } from "./prisma";
import { cacheTag } from "next/cache";

export async function getAllActiveProjectsForAdmin() {
  "use cache";
  cacheTag("admin-active-projects");

  return db.project.findMany({
    where: { status: "ACTIVE" },
    include: { client: true, tasks: true },
    orderBy: { updatedAt: "desc" },
  });
}
```

#### 2.5 Invalidate Prisma tags from the Inngest function

Recall Part 6's `handle-project-requested` function flips a project's status to `ACTIVE`. Now that admin views are cached, that function must also bust the tag:

```ts
// src/lib/inngest/functions/handle-project-requested.ts (updated)
import { inngest } from "../client";
import { db } from "@/lib/db/prisma";
import { clerkClient } from "@clerk/nextjs/server";
import { revalidateTag } from "next/cache";

export const handleProjectRequested = inngest.createFunction(
  { id: "handle-project-requested", retries: 3 },
  { event: "project/requested" },
  async ({ event, step }) => {
    const { projectId, clerkUserId, servicePackageName } = event.data;

    await step.run("create-onboarding-tasks", async () => {
      await db.task.createMany({
        data: [
          { title: "Kickoff call scheduled", projectId },
          { title: "Gather brand assets", projectId },
          { title: `Review ${servicePackageName} scope`, projectId },
        ],
      });
    });

    await step.run("activate-project", async () => {
      await db.project.update({ where: { id: projectId }, data: { status: "ACTIVE" } });
    });

    await step.run("bust-admin-cache", async () => {
      revalidateTag("admin-active-projects");
    });

    await step.run("notify-admins", async () => {
      const client = await clerkClient();
      const { data: users } = await client.users.getUserList({ limit: 100 });
      const admins = users.filter((u) => (u.publicMetadata as { role?: string })?.role === "ADMIN");
      for (const admin of admins) {
        console.log(`[notify] Admin ${admin.id}: new project request from ${clerkUserId}`);
      }
    });

    return { projectId, status: "ACTIVE" };
  }
);
```

This is the payoff of the architecture: a background job triggered by a Server Action reaches back into Next.js's cache layer to keep a completely different page (the admin dashboard) fresh — the three services and the framework's cache are all cooperating through named tags.

#### 2.6 `revalidatePath` for single-route personalized mutations

Contrast with Part 5's `requestProject` action, which only needs to refresh the current user's own `/dashboard/projects` list — no shared tag needed:

```ts
// excerpt from src/app/(dashboard)/dashboard/projects/actions.ts (Part 5, unchanged)
revalidatePath("/dashboard/projects");
```

This remains correct as-is: it's scoped, personalized data, so path-based invalidation is the right tool, not a tag.

#### 2.7 Streaming with Suspense for slow reads

```tsx
// src/app/(dashboard)/dashboard/admin/active-projects/page.tsx
import { Suspense } from "react";
import { getAllActiveProjectsForAdmin } from "@/lib/db/queries";
import { ProjectCardSkeleton } from "@/components/dashboard/project-card-skeleton";
import { ProjectCard } from "@/components/dashboard/project-card";

async function ActiveProjectsList() {
  const projects = await getAllActiveProjectsForAdmin();
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {projects.map((p) => (
        <ProjectCard key={p.id} name={p.name} status={p.status} taskCount={p.tasks.length} />
      ))}
    </div>
  );
}

export default function AdminActiveProjectsPage() {
  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">All Active Projects</h1>
      <Suspense
        fallback={
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <ProjectCardSkeleton />
            <ProjectCardSkeleton />
            <ProjectCardSkeleton />
          </div>
        }
      >
        <ActiveProjectsList />
      </Suspense>
    </div>
  );
}
```

---

### 3. Checkpoint

- ✅ Editing a `servicePackage` in the Sanity Studio and publishing triggers the webhook (check the Vercel/local logs, or use the Sanity dashboard's webhook "Attempts" log) and the home page reflects the change without a manual redeploy.
- ✅ Requesting a project (Part 5 flow) updates the admin's `/dashboard/admin/active-projects` view within the same session, without a full page reload, because the Inngest function busts `admin-active-projects`.
- ✅ The admin active-projects page shows skeleton cards briefly on a cold cache, then streams in real data.

---

### 4. Troubleshooting

- **Webhook fires but content doesn't change** — confirm the tag string used in `revalidateTag` inside the webhook route exactly matches the tag used in `cacheTag(...)` at the fetch site; these are plain string keys.
- **`isValidSignature` always false** — the `SANITY_WEBHOOK_SECRET` in `.env.local` must match exactly what's configured in the Sanity dashboard's webhook settings; regenerate and re-paste if unsure.
- **`"use cache"` function still re-runs every request in dev** — this is expected; Next.js disables persistent caching in `next dev` by default for correctness during development. Verify caching behavior with `pnpm build && pnpm start` instead.

---

Next: **"Ecosystem Tutorial - Part 8: Security & Validation"**

---

Say "next" for Part 8.
