# Part 36 — Install and Configure Inngest

So far, almost everything in GreyMatter Ledger happens during a user request.

Examples:

```txt
User creates invoice
User records payment
User uploads bank CSV
User reverses journal entry
```

Now we add background jobs.

Background jobs let the app do work outside normal page requests.

Examples we will build soon:

```txt
Invoice confirmation events
Daily overdue invoice reminders
Recurring invoices
```

In this part, we will install and configure Inngest.

By the end of this part, you will have:

- Inngest installed
- Inngest client configured
- Inngest route handler
- A test background function
- Environment variables documented
- A local Inngest dev workflow
- A settings diagnostic page for background jobs

---

# 1. Understand Background Jobs

## The Target

We are adding a background job system.

---

## The Concept

A normal request is like ordering coffee at a counter.

You ask for something and wait.

A background job is like placing a bakery order for tomorrow morning.

You ask the system to do something later or separately.

Useful background jobs:

```txt
Send overdue invoice reminders every morning
Generate recurring invoices
Process uploaded bank files
Send confirmation emails
Run scheduled report snapshots
```

We will use **Inngest** because it works well with Next.js and event-driven workflows.

---

# 2. Install Inngest

## The Target

We are installing the Inngest package.

---

## The Implementation

Run:

```bash
pnpm add inngest
```

---

## The Verification

Run:

```bash
pnpm build
```

The build should still pass after we add configuration in the next steps.

---

# 3. Add Inngest Environment Variables

## The Target

We are updating:

```txt
.env.example
```

---

## The Concept

Inngest uses environment variables in production.

For local development, Inngest can run with a dev server.

---

## The Implementation

Open:

```txt
.env.example
```

Add:

```bash
INNGEST_EVENT_KEY="replace_with_inngest_event_key"
INNGEST_SIGNING_KEY="replace_with_inngest_signing_key"
```

Also add those values to your production environment later.

For local development, you may leave them unset until using the Inngest cloud dashboard.

---

## The Verification

Run:

```bash
git status --short
```

You should see `.env.example` changed, not `.env.local` unless you edited it.

---

# 4. Create Inngest Client

## The Target

We are creating:

```txt
inngest/client.ts
```

---

## The Concept

The Inngest client identifies your app and sends/receives events.

---

## The Implementation

Create:

```bash
mkdir -p inngest
```

Create:

```txt
inngest/client.ts
```

Add:

```ts
// inngest/client.ts

import { Inngest } from "inngest";

export const inngest = new Inngest({
  id: "greymatter-ledger",
  name: "GreyMatter Ledger",
});
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create a Test Inngest Function

## The Target

We are creating:

```txt
inngest/functions.ts
```

---

## The Concept

An Inngest function listens for an event.

Example:

```txt
Event: app/health.check
Function: records that the background worker received it
```

For now, we create a simple test function.

---

## The Implementation

Create:

```txt
inngest/functions.ts
```

Add:

```ts
// inngest/functions.ts

import { inngest } from "@/inngest/client";

export const backgroundHealthCheck = inngest.createFunction(
  {
    id: "background-health-check",
    name: "Background Health Check",
  },
  {
    event: "app/health.check",
  },
  async ({ event, step }) => {
    const message = await step.run("create-health-message", async () => {
      return {
        receivedAt: new Date().toISOString(),
        payload: event.data,
      };
    });

    return message;
  },
);

export const inngestFunctions = [backgroundHealthCheck];
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 6. Create Inngest Route Handler

## The Target

We are creating:

```txt
app/api/inngest/route.ts
```

---

## The Concept

Inngest needs an API endpoint to discover and run functions.

In Next.js App Router, route handlers live under:

```txt
app/api
```

---

## The Implementation

Create:

```bash
mkdir -p app/api/inngest
```

Create:

```txt
app/api/inngest/route.ts
```

Add:

```ts
// app/api/inngest/route.ts

import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { inngestFunctions } from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: inngestFunctions,
});
```

---

## The Verification

Run:

```bash
pnpm build
```

Then run:

```bash
pnpm dev
```

Open:

```txt
http://localhost:3000/api/inngest
```

You should see an Inngest endpoint response.

---

# 7. Add an Inngest Test Server Action

## The Target

We are creating:

```txt
app/settings/background-jobs/actions.ts
```

---

## The Concept

We want a button in the app that sends a test event.

The event will be:

```txt
app/health.check
```

The Inngest dev server will receive it.

---

## The Implementation

Create:

```bash
mkdir -p app/settings/background-jobs
```

Create:

```txt
app/settings/background-jobs/actions.ts
```

Add:

```ts
// app/settings/background-jobs/actions.ts

"use server";

import { redirect } from "next/navigation";
import { inngest } from "@/inngest/client";

export async function sendBackgroundHealthCheckAction() {
  await inngest.send({
    name: "app/health.check",
    data: {
      source: "settings/background-jobs",
      sentAt: new Date().toISOString(),
    },
  });

  redirect("/settings/background-jobs?status=sent");
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 8. Create Background Jobs Settings Page

## The Target

We are creating:

```txt
app/settings/background-jobs/page.tsx
```

---

## The Implementation

Create:

```txt
app/settings/background-jobs/page.tsx
```

Add:

```tsx
// app/settings/background-jobs/page.tsx

import { AppLayout } from "@/components/app-layout";
import { sendBackgroundHealthCheckAction } from "@/app/settings/background-jobs/actions";

export const dynamic = "force-dynamic";

type BackgroundJobsPageProps = {
  searchParams?: Promise<{
    status?: string;
  }>;
};

export default async function BackgroundJobsPage({
  searchParams,
}: BackgroundJobsPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};

  return (
    <AppLayout
      title="Background Jobs"
      description="Configure and test Inngest background workflows."
    >
      <div className="space-y-6">
        {resolvedSearchParams.status === "sent" ? (
          <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
            <p className="text-sm font-semibold">
              Background health check event sent.
            </p>

            <p className="mt-2 text-sm leading-6">
              Check your Inngest dev server or dashboard for the event.
            </p>
          </section>
        ) : null}

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Inngest diagnostic
          </p>

          <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
            Send background health check
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
            This sends an <code>app/health.check</code> event to Inngest. In
            local development, run the Inngest dev server to see the function
            execute.
          </p>

          <form action={sendBackgroundHealthCheckAction} className="mt-5">
            <button
              type="submit"
              className="rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
            >
              Send test event
            </button>
          </form>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-950">
            Local development
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-500">
            Run your Next.js app and Inngest dev server at the same time.
          </p>

          <pre className="mt-4 overflow-x-auto rounded-xl bg-slate-950 p-4 text-sm text-slate-100">
{`pnpm dev

# In another terminal:
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest`}
          </pre>
        </section>
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
/settings/background-jobs
```

You should see the test event button.

---

# 9. Link Background Jobs from Settings

## The Target

We are updating:

```txt
app/settings/page.tsx
```

---

## The Implementation

Add this card to `settingsCards`:

```ts
{
  eyebrow: "Automation",
  title: "Background jobs",
  description:
    "Configure and test Inngest background workflows.",
  href: "/settings/background-jobs",
},
```

---

## The Verification

Open:

```txt
/settings
```

Click:

```txt
Background jobs
```

---

# 10. Run Inngest Locally

## The Target

We are testing the local Inngest workflow.

---

## The Implementation

Terminal 1:

```bash
pnpm dev
```

Terminal 2:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

Open:

```txt
/settings/background-jobs
```

Click:

```txt
Send test event
```

---

## The Verification

In the Inngest dev server UI or terminal, you should see:

```txt
app/health.check
background-health-check
```

---

# 11. Run Full Project Check

## The Target

We are verifying everything still passes.

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should pass.

---

# 12. Commit Inngest Setup

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Install and configure Inngest"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: `/api/inngest` not found

Make sure this file exists:

```txt
app/api/inngest/route.ts
```

---

## Error: Inngest dev server cannot connect

Make sure Next.js is running:

```bash
pnpm dev
```

Then run:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

## Error: Event sent but function does not run

Check that:

```txt
inngest/functions.ts
```

exports the function in:

```ts
inngestFunctions
```

And route handler imports that array.

---

# Phase 11 Reference — Inngest

## Event

A message that something happened.

Example:

```txt
invoice.created
```

---

## Function

A background workflow that responds to an event.

---

## Step

A durable unit of work inside an Inngest function.

---

# Part 36 Completion Checklist

You are ready for Part 37 if:

- [ ] `inngest` package installed
- [ ] Inngest env vars documented
- [ ] `inngest/client.ts` exists
- [ ] `inngest/functions.ts` exists
- [ ] `/api/inngest` route exists
- [ ] Background health check function exists
- [ ] `/settings/background-jobs` exists
- [ ] Test event can be sent
- [ ] Local Inngest dev server sees event
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
