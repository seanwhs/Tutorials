## Part 5: Server-Side Orchestration

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Write Server Actions that bridge Clerk identity, Sanity content, and Prisma writes — the architectural core of the whole series.

---

### 1. Concept Explanation

Every other part has kept the three data sources cleanly separate. This part is where they *meet*, deliberately, in exactly one place: a Server Action. The pattern we teach here is the single most important lesson in the series:

> A Server Action that orchestrates multiple services should (1) authenticate/authorize first via Clerk, (2) read whatever content it needs from Sanity, (3) perform the actual state mutation in Prisma inside a single transaction, and (4) hand off anything slow or non-critical to Inngest (Part 6) rather than doing it inline.

We build the flagship example: **"Client requests a service package."** A signed-in `CLIENT` browses `servicePackage` documents (Sanity) on `/dashboard/projects/new`, picks one, and submits a form. The Server Action:

1. Confirms the caller is authenticated and has role `CLIENT` (or `ADMIN` acting on their behalf) — Clerk.
2. Fetches the chosen `servicePackage` from Sanity to get its canonical name/slug (never trust the client-submitted name — always re-fetch source-of-truth content server-side).
3. Looks up (or creates) the corresponding `Client` row in Prisma keyed by `clerkUserId`, then creates the `Project` row referencing it, in one `db.$transaction`.
4. Fires an Inngest event (`project/requested`) so background work — onboarding task generation, notifying the agency's admins — happens asynchronously (built fully in Part 6; this part just fires the event).

This is "Locality of Behavior" applied at the service-integration level: one function, one file, and you can read top-to-bottom exactly what happens across all three systems, without needing to trace an API call through six other files.

---

### 2. Implementation

#### 2.1 The Zod schema (shared input contract)

```ts
// src/lib/validations/project.ts
import { z } from "zod";

export const requestProjectSchema = z.object({
  servicePackageSlug: z.string().min(1),
  projectName: z.string().min(3).max(120),
});

export type RequestProjectInput = z.infer<typeof requestProjectSchema>;
```

```bash
pnpm add zod
```

#### 2.2 The Server Action

```ts
// src/app/(dashboard)/dashboard/projects/actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { requireRole } from "@/lib/clerk/roles";
import { sanityClient } from "@/lib/sanity/client";
import { db } from "@/lib/db/prisma";
import { inngest } from "@/lib/inngest/client";
import { requestProjectSchema, type RequestProjectInput } from "@/lib/validations/project";
import { revalidatePath } from "next/cache";

export async function requestProject(input: RequestProjectInput) {
  // 1. Auth — Clerk
  await requireRole(["CLIENT", "ADMIN"]);
  const { userId } = await auth();
  if (!userId) throw new Error("Unauthenticated");

  // Validate input against the shared Zod contract
  const parsed = requestProjectSchema.safeParse(input);
  if (!parsed.success) {
    throw new Error(`Invalid input: ${parsed.error.message}`);
  }
  const { servicePackageSlug, projectName } = parsed.data;

  // 2. Content — Sanity (re-fetch source of truth, never trust client-submitted content)
  const servicePackage = await sanityClient.fetch(
    `*[_type == "servicePackage" && slug.current == $slug][0]{ name, slug }`,
    { slug: servicePackageSlug }
  );
  if (!servicePackage) {
    throw new Error("Unknown service package");
  }

  // 3. Persistence — Prisma, single transaction
  const project = await db.$transaction(async (tx) => {
    const client = await tx.client.upsert({
      where: { clerkUserId: userId },
      update: {},
      create: {
        clerkUserId: userId,
        companyName: "Pending — update in Settings",
        email: "pending@orbit.local",
      },
    });

    return tx.project.create({
      data: {
        name: projectName,
        status: "REQUESTED",
        sanityPackageSlug: servicePackage.slug.current,
        clientId: client.id,
      },
    });
  });

  // 4. Orchestration — Inngest (fire-and-forget event, fully built in Part 6)
  await inngest.send({
    name: "project/requested",
    data: {
      projectId: project.id,
      clerkUserId: userId,
      servicePackageName: servicePackage.name,
    },
  });

  revalidatePath("/dashboard/projects");

  return { ok: true, projectId: project.id };
}
```

> Note: `inngest` here is imported from `lib/inngest/client.ts`, built in Part 6. If you're following the series in strict order, stub this import with a no-op client for now — Part 6 fills in the real implementation, and this Server Action doesn't change at all.

#### 2.3 The form (Client Component calling the Server Action)

```tsx
// src/app/(dashboard)/dashboard/projects/new/request-project-form.tsx
"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { requestProject } from "../actions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export function RequestProjectForm({
  servicePackages,
}: {
  servicePackages: { name: string; slug: { current: string } }[];
}) {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  return (
    <form
      className="space-y-4 max-w-md"
      action={(formData: FormData) => {
        setError(null);
        startTransition(async () => {
          try {
            await requestProject({
              servicePackageSlug: String(formData.get("servicePackageSlug")),
              projectName: String(formData.get("projectName")),
            });
            router.push("/dashboard/projects");
          } catch (e) {
            setError(e instanceof Error ? e.message : "Something went wrong");
          }
        });
      }}
    >
      <div>
        <Label htmlFor="projectName">Project name</Label>
        <Input id="projectName" name="projectName" required minLength={3} />
      </div>

      <div>
        <Label htmlFor="servicePackageSlug">Service package</Label>
        <select
          id="servicePackageSlug"
          name="servicePackageSlug"
          required
          className="w-full rounded-md border px-3 py-2 text-sm"
        >
          {servicePackages.map((pkg) => (
            <option key={pkg.slug.current} value={pkg.slug.current}>
              {pkg.name}
            </option>
          ))}
        </select>
      </div>

      {error && <p className="text-sm text-destructive">{error}</p>}

      <Button type="submit" disabled={isPending}>
        {isPending ? "Submitting..." : "Request Project"}
      </Button>
    </form>
  );
}
```

#### 2.4 The page (Server Component fetching Sanity content for the form)

```tsx
// src/app/(dashboard)/dashboard/projects/new/page.tsx
import { getServicePackages } from "@/lib/sanity/queries";
import { RequestProjectForm } from "./request-project-form";

export default async function NewProjectPage() {
  const servicePackages = await getServicePackages();

  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">Request a New Project</h1>
      <RequestProjectForm servicePackages={servicePackages} />
    </div>
  );
}
```

#### 2.5 Reading Prisma data back into a Server Component

```tsx
// src/app/(dashboard)/dashboard/projects/page.tsx
import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db/prisma";
import { ProjectCard } from "@/components/dashboard/project-card";

export default async function ProjectsPage() {
  const { userId } = await auth();
  if (!userId) return null;

  const projects = await db.project.findMany({
    where: { client: { clerkUserId: userId } },
    include: { tasks: true },
    orderBy: { createdAt: "desc" },
  });

  return (
    <div>
      <h1 className="mb-4 text-2xl font-bold">Your Projects</h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {projects.map((p) => (
          <ProjectCard key={p.id} name={p.name} status={p.status} taskCount={p.tasks.length} />
        ))}
      </div>
    </div>
  );
}
```

---

### 3. Checkpoint

- ✅ Signed in as `CLIENT`, visiting `/dashboard/projects/new` shows a form populated with live Sanity `servicePackage` options.
- ✅ Submitting the form creates a `Client` row (if none existed) and a `Project` row in Neon, visible via `prisma studio`.
- ✅ `revalidatePath` causes `/dashboard/projects` to immediately reflect the new project without a hard refresh.
- ✅ The Server Action rejects the request if called by a user without `CLIENT`/`ADMIN` role (test by temporarily setting a test user's role to something else).

---

### 4. Troubleshooting

- **"Unknown service package" thrown even though the slug looks right** — GROQ slug matching is case-sensitive; confirm the `<select>` option value exactly matches the Sanity document's `slug.current`.
- **Transaction rolls back silently** — wrap the whole Server Action body in a try/catch during development and `console.error` the caught error; Prisma transaction errors are otherwise swallowed by Next.js's generic Server Action error boundary in production.
- **`inngest.send` throws because `lib/inngest/client.ts` doesn't exist yet** — expected if you're strictly reading in order; either skip ahead to Part 6 first, or temporarily comment out step 4.

---

Next: **"Ecosystem Tutorial - Part 6: Event-Driven Background Jobs"**

---

Say "next" for Part 6 (Inngest).
