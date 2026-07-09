# Part 2 Code Appendix — Full Snippets

Companion code for **EntNext16 - Part 2: Orchestration and State**.

---

## `lib/actions/types.ts`

```ts
export type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: string };
```

## `lib/actions/project-actions.ts`

```ts
"use server";

import { z } from "zod";
import { revalidateTag } from "next/cache";
import { db } from "@/lib/db";
import type { ActionResult } from "./types";
import type { Project } from "@/lib/repositories/types";

const archiveProjectSchema = z.object({
  id: z.string().uuid(),
});

export async function archiveProject(
  id: string
): Promise<ActionResult<Project>> {
  const parsed = archiveProjectSchema.safeParse({ id });
  if (!parsed.success) {
    return { success: false, error: "Invalid project id." };
  }

  try {
    const updated = await db.project.update({
      where: { id: parsed.data.id },
      data: { status: "archived" },
    });

    revalidateTag("projects");
    revalidateTag(`project:${parsed.data.id}`);

    return { success: true, data: updated };
  } catch {
    return { success: false, error: "Failed to archive project." };
  }
}

// Composition: a higher-level action built from lower-level ones.
export async function archiveAndNotify(
  id: string,
  actorEmail: string
): Promise<ActionResult<Project>> {
  const result = await archiveProject(id);
  if (!result.success) return result;

  await notifyProjectArchived(result.data, actorEmail);
  return result;
}

async function notifyProjectArchived(project: Project, actorEmail: string) {
  // Fire-and-forget server-side notification (email, webhook, audit log, etc.)
  await fetch(`${process.env.NOTIFY_WEBHOOK_URL}`, {
    method: "POST",
    body: JSON.stringify({
      event: "project.archived",
      projectId: project.id,
      actor: actorEmail,
    }),
  });
}
```

---

## `app/dashboard/projects/page.tsx` (URL state consumer)

```tsx
import { z } from "zod";
import { projectRepository } from "@/lib/repositories/project-repository";
import { FilterBar } from "./filter-bar";
import { ProjectRow } from "./project-row";

const projectFilterSchema = z.object({
  status: z.enum(["all", "active", "archived", "draft"]).catch("all"),
  sort: z.enum(["updatedAt", "name"]).catch("updatedAt"),
});

interface PageProps {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function ProjectsPage({ searchParams }: PageProps) {
  const rawParams = await searchParams;
  const { status, sort } = projectFilterSchema.parse({
    status: rawParams.status,
    sort: rawParams.sort,
  });

  const projects = await projectRepository.getAll({ status, sort });

  return (
    <div className="space-y-4">
      <FilterBar currentStatus={status} currentSort={sort} />
      <ul className="divide-y divide-gray-200">
        {projects.map((project) => (
          <ProjectRow key={project.id} project={project} />
        ))}
      </ul>
    </div>
  );
}
```

## `app/dashboard/projects/filter-bar.tsx` (client, URL-only state)

```tsx
"use client";

import { useRouter, useSearchParams, usePathname } from "next/navigation";
import { useTransition } from "react";

interface FilterBarProps {
  currentStatus: string;
  currentSort: string;
}

export function FilterBar({ currentStatus, currentSort }: FilterBarProps) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  function updateParam(key: string, value: string) {
    const params = new URLSearchParams(searchParams.toString());
    params.set(key, value);

    startTransition(() => {
      router.push(`${pathname}?${params.toString()}`);
    });
  }

  return (
    <div className={isPending ? "opacity-60" : ""}>
      <select
        value={currentStatus}
        onChange={(e) => updateParam("status", e.target.value)}
      >
        <option value="all">All</option>
        <option value="active">Active</option>
        <option value="archived">Archived</option>
        <option value="draft">Draft</option>
      </select>

      <select
        value={currentSort}
        onChange={(e) => updateParam("sort", e.target.value)}
      >
        <option value="updatedAt">Last updated</option>
        <option value="name">Name</option>
      </select>
    </div>
  );
}
```

## `app/dashboard/projects/project-row.tsx` (`useOptimistic` example)

```tsx
"use client";

import { useOptimistic, useState, useTransition } from "react";
import { archiveProject } from "@/lib/actions/project-actions";
import type { Project } from "@/lib/repositories/types";

interface ProjectRowProps {
  project: Project;
}

export function ProjectRow({ project }: ProjectRowProps) {
  const [optimisticStatus, setOptimisticStatus] = useOptimistic(project.status);
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleArchive() {
    setError(null);
    startTransition(async () => {
      setOptimisticStatus("archived");
      const result = await archiveProject(project.id);
      if (!result.success) {
        setError(result.error);
      }
    });
  }

  return (
    <li className="py-2 flex items-center justify-between">
      <span>{project.name}</span>
      <span className="text-sm text-gray-500">{optimisticStatus}</span>
      {optimisticStatus !== "archived" && (
        <button onClick={handleArchive} disabled={isPending}>
          Archive
        </button>
      )}
      {error && <span className="text-red-500 text-xs">{error}</span>}
    </li>
  );
}
```

---

## Local `useState` example (for contrast — no server round-trip)

```tsx
"use client";

import { useState } from "react";

export function ProjectDescription({ text }: { text: string }) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div>
      <p>{expanded ? text : `${text.slice(0, 80)}...`}</p>
      <button onClick={() => setExpanded((v) => !v)}>
        {expanded ? "Show less" : "Show more"}
      </button>
    </div>
  );
}
```

This has nothing to do with server state, so plain `useState` — no `useOptimistic`, no Server Action — is correct here.
