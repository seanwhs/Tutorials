# Part 1: Project Setup and Your First Function

## 1. Prerequisites

Install/verify:

```bash
node -v   # must be 20.9+ or 22 LTS (Next.js 16 requirement)
```

We'll use `pnpm` throughout (swap for `npm`/`yarn` if you prefer).

## 2. Create the Next.js 16 project

```bash
pnpm create next-app@latest taskflow
```

When prompted:

```
Would you like to use TypeScript?  Yes
Would you like to use ESLint?  Yes
Would you like to use Tailwind CSS?  Yes
Would you like your code inside a `src/` directory?  Yes
Would you like to use App Router?  Yes
Would you like to use Turbopack for `next dev`?  Yes
Would you like to customize the default import alias (@/*)?  No
```

```bash
cd taskflow
```

This scaffolds Next.js 16 with Tailwind CSS v4 already wired up via the CSS-first config (check `src/app/globals.css` — you'll see `@import "tailwindcss";` at the top, no `tailwind.config.ts` file). Turbopack is the default bundler for both `next dev` and `next build` in Next.js 16.

## 3. Install Inngest

```bash
pnpm add inngest
```

That's the entire SDK — no extra infrastructure, no Redis, no queue service to stand up.

## 4. Create the Inngest client

Create `src/inngest/client.ts`:

```ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "taskflow" });
```

The `id` is a unique slug for your app inside Inngest's system. Every event and function you create will be associated with this app ID. Keep this client as a singleton — you'll import it anywhere you need to define a function or send an event.

## 5. Write your first Inngest function

Create `src/inngest/functions.ts`:

```ts
import { inngest } from "./client";

export const helloWorld = inngest.createFunction(
  { id: "hello-world" },
  { event: "test/hello.world" },
  async ({ event, step }) => {
    await step.run("say-hello", async () => {
      console.log("Hello, world! Payload was:", event.data);
      return { message: `Hello, ${event.data.name ?? "stranger"}!` };
    });

    return { done: true };
  }
);
```

Let's unpack this line by line:

- `inngest.createFunction(config, trigger, handler)` registers a durable function.
- `{ id: "hello-world" }` — a unique, stable ID for this function within your app. Never reuse IDs for different functions.
- `{ event: "test/hello.world" }` — the **trigger**. This function runs whenever an event named `test/hello.world` is sent.
- The handler receives `{ event, step }`. `event` is the payload that triggered the run. `step` is your toolbox for durable operations — we'll use `step.run` constantly from here on.
- `step.run("say-hello", async () => { ... })` wraps a unit of work with a name. Inngest checkpoints the **return value** of every `step.run` call. If your function crashes or a later step fails and retries, this step will NOT re-run — Inngest replays its already-known result. This is the core idea of "durable execution."

## 6. Expose your functions via the `serve` API route

Inngest needs one HTTP endpoint in your app that it can call to invoke your functions. Create `src/app/api/inngest/route.ts`:

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { helloWorld } from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [helloWorld],
});
```

This one route file is the **only** place Inngest talks to your app over HTTP. Every function you write must be added to the `functions` array here or Inngest won't know it exists. We'll be coming back to this file in every future part to register new functions.

- `GET` lets the Inngest dashboard/CLI introspect what functions exist (used for local dev sync).
- `POST` is how Inngest actually invokes a function run, step by step.
- `PUT` is used to register/sync your app with Inngest Cloud in production (Part 12).

## 7. Run the Inngest Dev Server

The Inngest Dev Server is a local, zero-config UI + event/queue simulator you run alongside `next dev`. It gives you a dashboard to send test events, watch function runs live, inspect step-by-step output, and replay failed runs.

Open **two terminals**.

Terminal 1 — your Next.js app:

```bash
pnpm dev
```

Terminal 2 — the Inngest Dev Server, pointed at your app's `serve` route:

```bash
npx inngest-cli@latest dev
```

You'll see output like:

```
Inngest dev server online, discovering apps at http://127.0.0.1:8288
Connected to app "taskflow" at http://localhost:3000/api/inngest
```

Open **http://localhost:8288** in your browser. This is the Inngest Dev Server dashboard. Click the **Functions** tab — you should see `hello-world` listed. If you don't see it, check the Troubleshooting section below.

## 8. Trigger your function

The Dev Server dashboard has a **Send Event** button (top right, or under the "Events" tab). Click it and send:

```json
{
  "name": "test/hello.world",
  "data": {
    "name": "Ada"
  }
}
```

Click **Send**. Now click the **Runs** tab — you should see a new run for `hello-world`, status **Completed**, almost instantly. Click into it to see:

- The event payload that triggered it
- The `say-hello` step, its duration, and its return value (`{ message: "Hello, Ada!" }`)
- The final function output (`{ done: true }`)

Check your Terminal 1 (Next.js dev server) logs too — you should see `Hello, world! Payload was: { name: 'Ada' }` printed there, since `step.run`'s callback executed inside your Next.js process.

## 9. Trigger events from your own code

You don't have to use the dashboard forever — in real usage, your app code sends events. Let's prove it by adding a tiny test API route. Create `src/app/api/test-hello/route.ts`:

```ts
import { inngest } from "@/inngest/client";
import { NextResponse } from "next/server";

export async function GET() {
  await inngest.send({
    name: "test/hello.world",
    data: { name: "Grace" },
  });

  return NextResponse.json({ sent: true });
}
```

Visit `http://localhost:3000/api/test-hello` in your browser. Then check the Inngest Dev Server's **Runs** tab again — a new `hello-world` run should appear, triggered by your own app code via `inngest.send()`. This `inngest.send()` call is the exact pattern you'll use everywhere: your Server Actions and API routes will call `inngest.send()` to kick off background work instead of doing it inline.

Delete `src/app/api/test-hello/route.ts` once you've confirmed this works — it was just a smoke test.

## Checkpoint

By now you should have:

- [ ] A Next.js 16 project running with `pnpm dev` on port 3000
- [ ] `inngest` installed as a dependency
- [ ] `src/inngest/client.ts` with your Inngest client
- [ ] `src/inngest/functions.ts` with the `helloWorld` function
- [ ] `src/app/api/inngest/route.ts` wired up with `serve()`
- [ ] The Inngest Dev Server running via `npx inngest-cli@latest dev`, showing your app connected at `http://localhost:8288`
- [ ] Successfully sent a test event from the dashboard AND from your own app code, and watched the run complete

## Troubleshooting

**"Discovering apps..." never finds your app.** Make sure `pnpm dev` is running first, on port 3000, before starting `inngest-cli dev`. If you use a different port, run `npx inngest-cli@latest dev -u http://localhost:<port>/api/inngest`.

**Function doesn't show up in the dashboard.** Double check it's included in the `functions: [...]` array in `src/app/api/inngest/route.ts`, and that you haven't got a typo in the import path.

**Nothing happens when I click Send Event.** Make sure the `"name"` field in the JSON you send exactly matches the trigger event name (`test/hello.world`), including case.

Next up, Part 2 goes deeper into events and functions — multiple triggers, sending multiple events, and how the `serve` route really works under the hood.
