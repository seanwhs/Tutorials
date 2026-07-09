# **Part 15: Setting Up Inngest**:

---

# Part 15: Setting Up Inngest

The event-driven background job engine powering confirmation emails (Part 16) and reminders (Part 17). Just plumbing here — no real logic yet. Inngest's SDK works identically under Next.js 16/Turbopack.

## 1. What Inngest is
Write normal async TypeScript functions that either:
- **React to events** (event-driven functions)
- **Run on a schedule** (cron functions)

No queue/worker/cron server to manage — Inngest's free cloud service handles it, calling your app's single `/api/inngest` endpoint.

## 2. Create the Inngest client
```ts
// src/inngest/client.ts
import { Inngest } from "inngest";
export const inngest = new Inngest({ id: "eventhub" });
```

## 3. "Hello world" function
```ts
// src/inngest/functions/hello-world.ts
import { inngest } from "@/inngest/client";

export const helloWorld = inngest.createFunction(
  { id: "hello-world" },
  { event: "test/hello" },
  async ({ event, step }) => {
    await step.run("log-greeting", async () => {
      console.log(`Hello, ${event.data.name ?? "world"}!`);
    });
    return { message: `Hello, ${event.data.name ?? "world"}!` };
  }
);
```
`step.run(...)` wraps a unit of work — on retry, completed steps aren't re-run (crucial in Part 16 for not resending emails after a partial failure).

## 4. Register with the API route
Route Handler, no dynamic segment — no `params` to await here.
```ts
// src/app/api/inngest/route.ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { helloWorld } from "@/inngest/functions/hello-world";

export const { GET, POST, PUT } = serve({ client: inngest, functions: [helloWorld] });
```

## 5. Run the local Dev Server
```bash
npx inngest-cli@latest dev
```
Dashboard at http://localhost:8288, auto-discovers your app (with `pnpm dev` running on port 3000). Check **Apps** → `eventhub`, **Functions** → `hello-world`.

## 6. Trigger the test event
Dashboard: **Functions** → `hello-world` → **Invoke** with `{ "data": { "name": "EventHub" } }` → check **Runs** tab + your `pnpm dev` terminal for the log.

Or from code:
```ts
await inngest.send({ name: "test/hello", data: { name: "EventHub" } });
```

## 7. Get production keys (for Part 23)
Inngest cloud dashboard → **Manage → Keys** → save **Event Key** and **Signing Key** (not needed locally, only production).

## Checkpoint
- [ ] Dev Server shows `eventhub` app + `hello-world` function
- [ ] Manual invoke succeeds, logs in Next.js terminal
- [ ] Production Event Key + Signing Key located

**Next: Part 16 — Event-Driven Inngest Functions (RSVP Confirmation Emails)**
