# Part 1: The Data Layer — The Repository Pattern

Goal: eliminate client-side data fetching (`useEffect` + `useState` + loading flags) entirely for initial page data. Fetch on the server, cache deliberately, revalidate deliberately.

---

## 1. The Anti-Pattern (Next.js 13/14-style client fetching)

```tsx
// app/dashboard/page.tsx  (BAD — client-fetched, waterfall, no caching control)
"use client";

import { useEffect, useState } from "react";

interface Project {
  id: string;
  name: string;
  status: string;
}

export default function DashboardPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/projects")
      .then((res) => res.json())
      .then((data) => {
        setProjects(data);
        setLoading(false);
      });
  }, []);

  if (loading) return <p>Loading...</p>;

  return (
    <ul>
      {projects.map((p) => (
        <li key={p.id}>{p.name} — {p.status}</li>
      ))}
    </ul>
  );
}
```

**Why this is bad:**
- Ships an entire data-fetching + state machine to the client bundle.
- Creates a client-server waterfall: HTML loads → JS hydrates → `fetch` fires → spinner → content. Users see a loading state that server rendering could have eliminated.
- No caching semantics — every mount refetches, no `revalidate`/`tags` control, and you're stuck reinventing loading/error state per component.
- Bypasses the framework's built-in Data Cache entirely.

---

## 2. The Next.js 16 Pattern: Repository Pattern + Server Components

The Repository Pattern isolates **data access** behind a typed interface. Components never call `fetch` or hit a DB directly — they call a repository function. This gives you one place to change caching strategy, swap data sources (REST → GraphQL → DB), and mock for tests.

### Directory structure

```
lib/
  repositories/
    project-repository.ts   # data access + caching strategy
    types.ts                 # shared domain types
  db.ts                       # fake in-memory / real DB client
app/
  dashboard/
    page.tsx                 # Server Component, calls repository
    loading.tsx
```

### Step 1 — Define domain types

```ts
// lib/repositories/types.ts
export interface Project {
  id: string;
  name: string;
  status: "active" | "archived" | "draft";
  updatedAt: string;
}

export interface ProjectRepository {
  getAll(): Promise<Project[]>;
  getById(id: string): Promise<Project | null>;
}
```

### Step 2 — Implement the repository with explicit caching

```ts
// lib/repositories/project-repository.ts
import "server-only";
import type { Project, ProjectRepository } from "./types";

const API_BASE = process.env.API_BASE_URL!;

class HttpProjectRepository implements ProjectRepository {
  async getAll(): Promise<Project[]> {
    const res = await fetch(`${API_BASE}/projects`, {
      // Time-based revalidation: re-fetch in background every 60s (ISR-style)
      next: { revalidate: 60, tags: ["projects"] },
    });

    if (!res.ok) throw new Error(`Failed to load projects: ${res.status}`);
    return res.json();
  }

  async getById(id: string): Promise<Project | null> {
    const res = await fetch(`${API_BASE}/projects/${id}`, {
      // Tag-based revalidation: only invalidated by an explicit revalidateTag call
      next: { tags: ["projects", `project:${id}`] },
    });

    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`Failed to load project ${id}: ${res.status}`);
    return res.json();
  }
}

export const projectRepository: ProjectRepository = new HttpProjectRepository();
```

Key details:
- `import "server-only"` guarantees this module throws a build error if accidentally imported into a Client Component — a compile-time boundary, not just a convention.
- The `next: { revalidate, tags }` options are the actual caching contract. `revalidate: 60` = stale-while-revalidate every 60 seconds. `tags` lets you invalidate on-demand from a Server Action (Part 2) without waiting for the timer.

### Step 3 — Consume it in a Server Component (zero client JS for data)

```tsx
// app/dashboard/page.tsx
import { projectRepository } from "@/lib/repositories/project-repository";
import type { Project } from "@/lib/repositories/types";

export default async function DashboardPage() {
  const projects: Project[] = await projectRepository.getAll();

  return (
    <ul className="divide-y divide-gray-200">
      {projects.map((p) => (
        <li key={p.id} className="py-2 flex justify-between">
          <span>{p.name}</span>
          <span className="text-sm text-gray-500">{p.status}</span>
        </li>
      ))}
    </ul>
  );
}
```

```tsx
// app/dashboard/loading.tsx
export default function Loading() {
  return <p className="animate-pulse text-gray-400">Loading projects…</p>;
}
```

No `useState`, no `useEffect`, no client bundle cost. `loading.tsx` gives you the Suspense boundary automatically — Next.js streams the shell immediately and swaps in `page.tsx`'s output when the `await` resolves.

### Step 4 — Database-backed repository variant

If you're hitting a database instead of an HTTP API, wrap it with React's `cache()` to dedupe calls within a single request (e.g., when both `layout.tsx` and `page.tsx` need the same project):

```ts
// lib/repositories/project-repository.db.ts
import "server-only";
import { cache } from "react";
import { db } from "@/lib/db";
import type { Project } from "./types";

export const getProjectById = cache(async (id: string): Promise<Project | null> => {
  const row = await db.project.findUnique({ where: { id } });
  return row ?? null;
});
```

`cache()` is request-scoped memoization — it does not persist across requests like `fetch`'s Data Cache does. Use both together: `fetch` caching for cross-request/user caching, `cache()` for de-duplicating repeated calls inside one render pass.

---

## 3. Type-Safe Implementation Checklist

- [ ] Every repository implements an explicit `interface` (`ProjectRepository`) — never return `any`, never inline shapes in components.
- [ ] Domain types live in `lib/repositories/types.ts`, imported by both server code and (if needed) client components that just render props — never re-declared.
- [ ] All repository modules are marked `import "server-only"` unless intentionally isomorphic.
- [ ] `.env` values used in repositories are asserted with `!` or validated with `zod` at module load, not scattered with optional chaining.

```ts
// lib/env.ts
import { z } from "zod";

const envSchema = z.object({
  API_BASE_URL: z.string().url(),
});

export const env = envSchema.parse({
  API_BASE_URL: process.env.API_BASE_URL,
});
```

---

## 4. Architect's Note

**Trade-off — `revalidate: N` vs `tags`:**
Time-based revalidation (`revalidate: 60`) is simple but means data can be up to 60s stale for *every* consumer, with no way to force freshness on demand. Tag-based revalidation (`tags: [...]` + `revalidateTag()` called from a Server Action after a mutation) gives you on-demand precision — the cache stays valid indefinitely until something explicitly invalidates it, which is the correct model for data that changes via user action rather than by clock.

**Trade-off — Repository Pattern overhead:** For a tiny app, an interface + implementation class per resource feels like ceremony. It pays off the moment you need to (a) swap a REST backend for a DB or GraphQL, (b) unit test a page without a live network dependency, or (c) enforce that only server code can reach a secret-bearing API — the `server-only` import makes that a build-time guarantee, not a code-review hope.

**Trade-off — request memoization vs Data Cache:** `cache()` only prevents duplicate work *within one render*; it doesn't reduce load on your backend across users/requests the way `fetch`'s Data Cache does. If you're on a DB (no `fetch`), you lose the Data Cache entirely and must build your own layer (e.g., `unstable_cache` from `next/cache`) if cross-request caching is needed:

```ts
import { unstable_cache } from "next/cache";

export const getAllProjectsCached = unstable_cache(
  async () => db.project.findMany(),
  ["projects-all"],
  { revalidate: 60, tags: ["projects"] }
);
```

Next up: **Part 2 — Orchestration & State**, where these repositories get mutated via Server Actions and `revalidateTag("projects")` closes the loop.
