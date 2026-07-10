## Part 8: Security & Validation

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Enforce Zod validation on every API boundary and Server Action input, and harden the app's authorization model.

---

### 1. Concept Explanation

Every part so far has quietly relied on two Zod schemas (`requestProjectSchema` in Part 5, the Inngest event schema in Part 6). This part makes that pattern explicit and complete, and extends it to every remaining boundary: Route Handlers, the Sanity webhook, and Inngest function payloads.

**The core principle:** a Zod schema should be defined *once* per data shape, in `lib/validations/`, and imported everywhere that shape crosses a trust boundary — client → Server Action, external webhook → Route Handler, Server Action → Inngest event. Never re-derive or duplicate the shape; import the same schema and reuse `.infer<>` for the TypeScript type. This guarantees the runtime check and the compile-time type can never drift apart.

**Defense in depth for this app specifically:**
1. **Clerk** — authentication (who) and coarse authorization (role check via `requireRole`).
2. **Zod** — shape and constraint validation of anything that entered from outside our server boundary (form input, webhook payloads, Inngest event data).
3. **Prisma-level checks** — row-level authorization, e.g. confirming a `Project` actually belongs to the requesting `Client` before allowing an update (role check alone isn't enough — a `CLIENT` must only touch *their own* rows).

---

### 2. Implementation

#### 2.1 Centralize all validation schemas

```ts
// src/lib/validations/project.ts
import { z } from "zod";

export const requestProjectSchema = z.object({
  servicePackageSlug: z.string().min(1),
  projectName: z.string().min(3).max(120),
});
export type RequestProjectInput = z.infer<typeof requestProjectSchema>;

export const updateProjectStatusSchema = z.object({
  projectId: z.string().cuid(),
  status: z.enum(["REQUESTED", "ACTIVE", "ON_HOLD", "COMPLETED", "CANCELLED"]),
});
export type UpdateProjectStatusInput = z.infer<typeof updateProjectStatusSchema>;
```

```ts
// src/lib/validations/comment.ts
import { z } from "zod";

export const createCommentSchema = z.object({
  taskId: z.string().cuid(),
  body: z.string().min(1).max(2000),
});
export type CreateCommentInput = z.infer<typeof createCommentSchema>;
```

```ts
// src/lib/validations/webhooks.ts
import { z } from "zod";

export const sanityWebhookPayloadSchema = z.object({
  _type: z.enum(["servicePackage", "article"]),
  _id: z.string(),
  slug: z.object({ current: z.string() }).optional(),
});
export type SanityWebhookPayload = z.infer<typeof sanityWebhookPayloadSchema>;
```

#### 2.2 A reusable Server Action validation wrapper

```ts
// src/lib/validations/validate-action.ts
import { z } from "zod";

export async function validateInput<T extends z.ZodTypeAny>(
  schema: T,
  input: unknown
): Promise<z.infer<T>> {
  const parsed = schema.safeParse(input);
  if (!parsed.success) {
    const message = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Validation failed: ${message}`);
  }
  return parsed.data;
}
```

#### 2.3 A row-level authorization helper for Prisma

```ts
// src/lib/db/authorize.ts
import { db } from "./prisma";

export async function assertProjectOwnership(projectId: string, clerkUserId: string) {
  const project = await db.project.findFirst({
    where: { id: projectId, client: { clerkUserId } },
    select: { id: true },
  });
  if (!project) {
    throw new Error("Not found or not authorized");
  }
  return project;
}
```

#### 2.4 Apply it — the comment Server Action (new, hardened example)

```ts
// src/app/(dashboard)/dashboard/projects/[id]/comment-actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { requireRole } from "@/lib/clerk/roles";
import { db } from "@/lib/db/prisma";
import { validateInput } from "@/lib/validations/validate-action";
import { createCommentSchema, type CreateCommentInput } from "@/lib/validations/comment";
import { revalidatePath } from "next/cache";

export async function createComment(input: CreateCommentInput) {
  await requireRole(["ADMIN", "MEMBER", "CLIENT"]);
  const { userId } = await auth();
  if (!userId) throw new Error("Unauthenticated");

  const { taskId, body } = await validateInput(createCommentSchema, input);

  // Row-level authorization: confirm the task belongs to a project this user can access
  const task = await db.task.findFirst({
    where: {
      id: taskId,
      project: { client: { clerkUserId: userId } },
    },
    select: { id: true, projectId: true },
  });
  if (!task) {
    throw new Error("Not found or not authorized");
  }

  const comment = await db.comment.create({
    data: { body, taskId, authorUserId: userId },
  });

  revalidatePath(`/dashboard/projects/${task.projectId}`);
  return comment;
}
```

Notice this rejects a `CLIENT` from Company A commenting on a task belonging to Company B's project, even though both have the generic `CLIENT` role — the row-level check in the `where` clause is what actually enforces tenant isolation, not the role check alone.

#### 2.5 Hardening the Sanity webhook from Part 7 with the schema

```ts
// src/app/api/sanity/revalidate/route.ts (updated)
import { NextRequest, NextResponse } from "next/server";
import { revalidateTag } from "next/cache";
import { parseBody } from "next-sanity/webhook";
import { sanityWebhookPayloadSchema } from "@/lib/validations/webhooks";

export async function POST(req: NextRequest) {
  const { body, isValidSignature } = await parseBody<unknown>(
    req,
    process.env.SANITY_WEBHOOK_SECRET
  );

  if (!isValidSignature) {
    return NextResponse.json({ message: "Invalid signature" }, { status: 401 });
  }

  const parsed = sanityWebhookPayloadSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ message: "Malformed payload" }, { status: 400 });
  }

  if (parsed.data._type === "servicePackage") revalidateTag("service-packages");
  if (parsed.data._type === "article") revalidateTag("articles");

  return NextResponse.json({ revalidated: true, now: Date.now() });
}
```

Even though a valid signature proves the request came from Sanity, we still validate shape — a misconfigured webhook or a future schema change in Sanity shouldn't be able to crash this route with an unexpected payload shape.

#### 2.6 Validating Inngest event payloads at the boundary

```ts
// src/lib/inngest/functions/handle-project-requested.ts (excerpt, updated)
import { z } from "zod";

const eventDataSchema = z.object({
  projectId: z.string(),
  clerkUserId: z.string(),
  servicePackageName: z.string(),
});

// inside the function, first line of the handler:
const data = eventDataSchema.parse(event.data); // throws -> Inngest marks the run failed & retries per config
```

#### 2.7 Rate-limiting a public-ish Route Handler (defense against abuse)

```ts
// src/lib/security/rate-limit.ts
const hits = new Map<string, number[]>();

export function isRateLimited(key: string, limit = 10, windowMs = 60_000) {
  const now = Date.now();
  const timestamps = (hits.get(key) ?? []).filter((t) => now - t < windowMs);
  timestamps.push(now);
  hits.set(key, timestamps);
  return timestamps.length > limit;
}
```

```ts
// usage inside a Route Handler
import { isRateLimited } from "@/lib/security/rate-limit";
import { auth } from "@clerk/nextjs/server";

export async function POST(req: Request) {
  const { userId } = await auth();
  if (!userId) return new Response("Unauthorized", { status: 401 });
  if (isRateLimited(userId)) return new Response("Too many requests", { status: 429 });
  // ... handle request
}
```

> Note: this in-memory limiter resets per serverless instance and is not durable across Vercel's multiple function instances — it's a stopgap for this PoC, called out explicitly here rather than presented as production-grade.

---

### 3. Checkpoint

- ✅ Every Server Action in the project imports its input schema from `lib/validations/*` rather than inlining `z.object({...})` locally.
- ✅ Submitting malformed input (e.g., empty `projectName`) to `requestProject` throws a clear validation error surfaced in the form's error state.
- ✅ A `CLIENT` user cannot comment on, or otherwise mutate, a project belonging to a different `Client` row — verified by testing with two separate signed-up test accounts.
- ✅ Sending a request to `/api/sanity/revalidate` with an invalid signature returns `401`; with a valid signature but malformed body returns `400`.

---

### 4. Troubleshooting

- **`z.infer` type not updating after schema change** — restart the TypeScript server / editor; this is a known editor-caching quirk, not a code bug.
- **Row-level check always fails even for the correct owner** — confirm the Prisma `where` clause traverses the relation correctly (`project: { client: { clerkUserId } }`) and that the `Client.clerkUserId` was actually populated correctly back in Part 5's `upsert`.
- **Rate limiter never triggers** — remember it's per-instance; in `pnpm dev` there's only one instance so it should work locally, but don't rely on it holding across Vercel's serverless scaling without a shared store.

---

Next: **"Ecosystem Tutorial - Part 9: Performance & Optimization"**

---

Say "next" for Part 9.
