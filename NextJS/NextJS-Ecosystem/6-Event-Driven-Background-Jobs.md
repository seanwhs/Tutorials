## Part 6: Event-Driven Background Jobs

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Introduce Inngest. Build durable background functions that process the `project/requested` event from Part 5, plus a scheduled weekly digest cron.

---

### 1. Concept Explanation

Server Actions and Route Handlers run inside a request/response cycle with a timeout (Vercel's free tier caps serverless function duration). Anything slow, multi-step, or that needs guaranteed retries has no business running inline there. Inngest solves this: you `send()` an event from anywhere in your app (it returns immediately), and a separate durable function — running out-of-band, with automatic retries, step-level checkpointing, and observability — picks it up.

**Why "durable" matters:** if your background function has three steps (create onboarding tasks, notify admins, send a welcome email) and step 2 throws, Inngest retries *only* step 2 — step 1's work isn't redone. This is achieved via `step.run()`, which memoizes each step's result. This is meaningfully different from a naive `setTimeout` or fire-and-forget `fetch` — those have no retry semantics and no memory of partial progress.

**Free tier reality check:** Inngest's Hobby plan is generous (a large monthly allotment of function runs/steps, unlimited functions, 7-day log retention) and requires no credit card — more than sufficient for this project and most side projects.

**Two trigger modes we use:**
1. **Event-triggered** — `project/requested` fires from the Server Action in Part 5; the function reacts.
2. **Cron-triggered** — a weekly digest runs on a schedule with no external trigger at all.

---

### 2. Implementation

#### 2.1 Install

```bash
pnpm add inngest
```

#### 2.2 Env vars

Sign up at inngest.com, create an app, and grab keys from the dashboard:

```bash
INNGEST_EVENT_KEY=your_event_key
INNGEST_SIGNING_KEY=your_signing_key
```

(Locally, the Inngest Dev Server auto-discovers your app without needing these keys — they're required once deployed to Vercel in Part 10.)

#### 2.3 The one Inngest client — lib/inngest/client.ts

```ts
// src/lib/inngest/client.ts
import { Inngest, EventSchemas } from "inngest";
import { z } from "zod";

const projectRequestedSchema = z.object({
  projectId: z.string(),
  clerkUserId: z.string(),
  servicePackageName: z.string(),
});

type Events = {
  "project/requested": {
    data: z.infer<typeof projectRequestedSchema>;
  };
};

export const inngest = new Inngest({
  id: "orbit",
  schemas: new EventSchemas().fromRecord<Events>(),
});
```

Every other file imports `inngest` from here — mirroring the `lib/db/prisma.ts` and `lib/sanity/client.ts` singleton pattern from Parts 2–3.

#### 2.4 The background function — onboarding + notification

```ts
// src/lib/inngest/functions/handle-project-requested.ts
import { inngest } from "../client";
import { db } from "@/lib/db/prisma";
import { clerkClient } from "@clerk/nextjs/server";

export const handleProjectRequested = inngest.createFunction(
  { id: "handle-project-requested", retries: 3 },
  { event: "project/requested" },
  async ({ event, step }) => {
    const { projectId, clerkUserId, servicePackageName } = event.data;

    // Step 1: generate standard onboarding tasks for this project
    await step.run("create-onboarding-tasks", async () => {
      await db.task.createMany({
        data: [
          { title: "Kickoff call scheduled", projectId },
          { title: "Gather brand assets", projectId },
          { title: `Review ${servicePackageName} scope`, projectId },
        ],
      });
    });

    // Step 2: flip project status from REQUESTED to ACTIVE once onboarding tasks exist
    await step.run("activate-project", async () => {
      await db.project.update({
        where: { id: projectId },
        data: { status: "ACTIVE" },
      });
    });

    // Step 3: notify admins (in this PoC, "notify" = log; swap in Resend or similar for real email)
    await step.run("notify-admins", async () => {
      const client = await clerkClient();
      const { data: users } = await client.users.getUserList({ limit: 100 });
      const admins = users.filter((u) => (u.publicMetadata as { role?: string })?.role === "ADMIN");

      for (const admin of admins) {
        console.log(
          `[notify] Admin ${admin.id}: new project request from ${clerkUserId} for "${servicePackageName}"`
        );
        // e.g. await resend.emails.send({ to: admin.emailAddresses[0].emailAddress, ... })
      }
    });

    return { projectId, status: "ACTIVE" };
  }
);
```

`step.run` is the unit Inngest checkpoints — if `notify-admins` throws, on retry Inngest skips straight back to it without re-running `create-onboarding-tasks` or `activate-project`.

#### 2.5 The cron function — weekly digest

```ts
// src/lib/inngest/functions/weekly-digest.ts
import { inngest } from "../client";
import { db } from "@/lib/db/prisma";

export const weeklyDigest = inngest.createFunction(
  { id: "weekly-digest" },
  { cron: "0 9 * * MON" }, // every Monday at 9am server time
  async ({ step }) => {
    const staleProjects = await step.run("find-stale-projects", async () => {
      const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      return db.project.findMany({
        where: { status: "ACTIVE", updatedAt: { lt: oneWeekAgo } },
        include: { client: true },
      });
    });

    await step.run("log-digest", async () => {
      console.log(`[weekly-digest] ${staleProjects.length} active projects with no updates in 7+ days`);
      for (const p of staleProjects) {
        console.log(` - ${p.name} (client: ${p.client.companyName})`);
      }
    });

    return { staleCount: staleProjects.length };
  }
);
```

#### 2.6 The Next.js API route Inngest calls into

Inngest functions are served through a single Route Handler using the Next.js serve adapter:

```ts
// src/app/api/inngest/route.ts
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest/client";
import { handleProjectRequested } from "@/lib/inngest/functions/handle-project-requested";
import { weeklyDigest } from "@/lib/inngest/functions/weekly-digest";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [handleProjectRequested, weeklyDigest],
});
```

This one file is the registry — every new background function must be added to this `functions` array or Inngest will never invoke it.

#### 2.7 Run the Inngest Dev Server locally

In a second terminal, alongside `pnpm dev`:

```bash
pnpm dlx inngest-cli@latest dev
```

This starts a local dashboard (typically `http://localhost:8288`) that auto-discovers your `/api/inngest` endpoint, shows every event received and every function run, step-by-step, with full input/output inspection — invaluable for debugging the multi-step function from 2.4.

#### 2.8 Wire the send call in the Server Action (from Part 5)

Confirm `src/app/(dashboard)/dashboard/projects/actions.ts` from Part 5 already imports `inngest` from `@/lib/inngest/client` and calls `inngest.send({ name: "project/requested", data: {...} })` — that code doesn't change; it was written forward-looking to this part.

---

### 3. Checkpoint

- ✅ `pnpm dlx inngest-cli@latest dev` running, dashboard open at `localhost:8288`, shows your app registered.
- ✅ Submitting the "Request Project" form from Part 5 shows a `project/requested` event appear in the Inngest dev dashboard within seconds.
- ✅ The function run view shows all three steps (`create-onboarding-tasks`, `activate-project`, `notify-admins`) completing green.
- ✅ `prisma studio` shows the project's status flipped to `ACTIVE` and three new `Task` rows.
- ✅ Manually triggering `weekly-digest` from the dev dashboard's "Trigger" button runs without errors.

---

### 4. Troubleshooting

- **Dev dashboard shows "no app found"** — confirm `pnpm dev` is running on the expected port and `/api/inngest` responds to a `GET` request (visit it directly in the browser; it should return function metadata, not a 404).
- **Function runs but step results look re-executed on retry** — verify each unit of work is wrapped in its own `step.run("name", fn)` call rather than one giant unstepped async function; without `step.run` boundaries there's nothing to checkpoint.
- **Event never appears in the dashboard** — check `INNGEST_EVENT_KEY` isn't required locally (it isn't, for the dev server) but double check no typo in the event `name` string between `inngest.send` and the function's `{ event: "..." }` trigger — these are plain string matches.
- **Cron never fires locally** — the dev server does support cron simulation, but it's easiest to test crons via the dashboard's manual "Trigger" button rather than waiting for real time to pass.

---

Next: **"Ecosystem Tutorial - Part 7: Advanced Data Fetching"**

---

Say "part 7" whenever you're ready.
