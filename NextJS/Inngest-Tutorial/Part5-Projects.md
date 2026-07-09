# Part 5: Projects and Tasks CRUD UI

This part builds plain Next.js 16 CRUD functionality using Server Actions — no Inngest yet. We need real projects, members, and tasks in the database before the fan-out and scheduling patterns in Parts 6-9 have something meaningful to act on.

## 1. A helper to get the current DB user from Clerk session

Create `src/lib/current-user.ts`:

```ts
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

export async function getCurrentDbUser() {
  const { userId } = await auth();
  if (!userId) return null;

  return prisma.user.findUnique({ where: { clerkId: userId } });
}
```

Note the `await auth()` — in Next.js 16, Clerk's `auth()` is async and must be awaited, as are all dynamic APIs.

## 2. Create Project (Server Action)

Create `src/app/projects/actions.ts`:

```ts
"use server";

import { prisma } from "@/lib/prisma";
import { getCurrentDbUser } from "@/lib/current-user";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function createProject(formData: FormData) {
  const user = await getCurrentDbUser();
  if (!user) throw new Error("Not authenticated");

  const name = String(formData.get("name") ?? "").trim();
  if (!name) throw new Error("Project name is required");

  const project = await prisma.project.create({
    data: {
      name,
      members: { create: { userId: user.id } },
    },
  });

  revalidatePath("/projects");
  redirect(`/projects/${project.id}`);
}
```

## 3. Projects list page

Create `src/app/projects/page.tsx`:

```tsx
import { prisma } from "@/lib/prisma";
import { getCurrentDbUser } from "@/lib/current-user";
import { createProject } from "./actions";
import Link from "next/link";

export default async function ProjectsPage() {
  const user = await getCurrentDbUser();
  if (!user) return <p>Please sign in.</p>;

  const projects = await prisma.project.findMany({
    where: { members: { some: { userId: user.id } } },
    orderBy: { createdAt: "desc" },
  });

  return (
    <main className="mx-auto max-w-2xl p-8">
      <h1 className="text-2xl font-bold mb-6">Your Projects</h1>

      <form action={createProject} className="flex gap-2 mb-8">
        <input
          name="name"
          placeholder="New project name"
          className="border rounded px-3 py-2 flex-1"
          required
        />
        <button type="submit" className="bg-black text-white px-4 py-2 rounded">
          Create
        </button>
      </form>

      <ul className="space-y-2">
        {projects.map((p) => (
          <li key={p.id}>
            <Link href={`/projects/${p.id}`} className="text-blue-600 underline">
              {p.name}
            </Link>
          </li>
        ))}
      </ul>
    </main>
  );
}
```

## 4. Project detail page with async params (Next.js 16 pattern)

Create `src/app/projects/[projectId]/page.tsx`:

```tsx
import { prisma } from "@/lib/prisma";
import { createTask } from "./actions";

export default async function ProjectDetailPage({
  params,
}: {
  params: Promise<{ projectId: string }>;
}) {
  const { projectId } = await params;

  const project = await prisma.project.findUnique({
    where: { id: projectId },
    include: {
      tasks: { orderBy: { createdAt: "desc" } },
      members: { include: { user: true } },
    },
  });

  if (!project) return <p>Project not found.</p>;

  return (
    <main className="mx-auto max-w-2xl p-8">
      <h1 className="text-2xl font-bold mb-2">{project.name}</h1>
      <p className="text-sm text-gray-500 mb-6">
        {project.members.length} member(s)
      </p>

      <form action={createTask.bind(null, projectId)} className="flex gap-2 mb-8">
        <input name="title" placeholder="New task title" className="border rounded px-3 py-2 flex-1" required />
        <select name="assigneeId" className="border rounded px-3 py-2">
          <option value="">Unassigned</option>
          {project.members.map((m) => (
            <option key={m.user.id} value={m.user.id}>
              {m.user.email}
            </option>
          ))}
        </select>
        <button type="submit" className="bg-black text-white px-4 py-2 rounded">
          Add Task
        </button>
      </form>

      <ul className="space-y-2">
        {project.tasks.map((t) => (
          <li key={t.id} className="border rounded p-3">
            <p className="font-medium">{t.title}</p>
            <p className="text-sm text-gray-500">Status: {t.status}</p>
          </li>
        ))}
      </ul>
    </main>
  );
}
```

Remember the Next.js 16 async-params rule: `params` is always a `Promise` now — `{ params }: { params: Promise<{ projectId: string }> }` then `const { projectId } = await params;`. This applies to every dynamic route page in the app.

## 5. Create Task action — this is where Inngest comes back in

Create `src/app/projects/[projectId]/actions.ts`:

```ts
"use server";

import { prisma } from "@/lib/prisma";
import { getCurrentDbUser } from "@/lib/current-user";
import { inngest } from "@/inngest/client";
import { revalidatePath } from "next/cache";

export async function createTask(projectId: string, formData: FormData) {
  const user = await getCurrentDbUser();
  if (!user) throw new Error("Not authenticated");

  const title = String(formData.get("title") ?? "").trim();
  const assigneeId = String(formData.get("assigneeId") ?? "") || null;
  if (!title) throw new Error("Task title is required");

  const task = await prisma.task.create({
    data: {
      title,
      projectId,
      createdById: user.id,
      assigneeId,
    },
  });

  await inngest.send({
    name: "task/task.created",
    data: {
      taskId: task.id,
      projectId,
      createdByUserId: user.id,
    },
  });

  if (assigneeId) {
    await inngest.send({
      name: "task/task.assigned",
      data: {
        taskId: task.id,
        assigneeUserId: assigneeId,
      },
    });
  }

  revalidatePath(`/projects/${projectId}`);
}
```

Notice the pattern: the Server Action does the synchronous DB write (creating the task — the user needs to see it immediately), then fires Inngest events for everything that can happen asynchronously (notifications, activity logs). This keeps the user-facing request fast while all the "extra" work happens durably in the background, which we'll build out in Part 6.

## Checkpoint

- [ ] `/projects` lists and creates projects
- [ ] `/projects/[projectId]` shows tasks and a task-creation form, using async `params`
- [ ] Creating a task sends `task/task.created` (and `task/task.assigned` if applicable) via `inngest.send()`
- [ ] You can see these events appear in the Inngest Dev Server's Runs/Stream tab even though no function reacts to them meaningfully yet (we'll add that next)

## Troubleshooting

**"Not authenticated" errors even when signed in.** Ensure the Clerk webhook from Part 3 actually ran and created a matching `User` row — `getCurrentDbUser` looks up by `clerkId`, so if the webhook never fired for your test account, no DB user exists yet. Check Prisma Studio.

**`params` type errors.** Confirm you typed it as `Promise<{ projectId: string }>` and awaited it — this is required for every dynamic segment in Next.js 16, unlike Next.js 14 where params were a plain object.

Next: **Part 6** builds real fan-out notification functions reacting to `task/task.created` and `task/task.assigned` — want me to bring that up next?
