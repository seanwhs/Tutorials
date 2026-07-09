# Part 3: Clerk Auth, Prisma Schema, and Your First Real Event

## 1. Install and configure Clerk

```bash
pnpm add @clerk/nextjs
```

Sign up at clerk.com, create an application, and copy your keys into `.env.local`:

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx
```

Create `src/proxy.ts` (Next.js 16's replacement for the old `middleware.ts` convention; same clerkMiddleware API):

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/((?!_next|.*\\..*).*)", "/", "/(api|trpc)(.*)"],
};
```

Wrap your root layout with ClerkProvider in `src/app/layout.tsx`. Add sign-in/sign-up pages under `src/app/sign-in/[[...sign-in]]/page.tsx` and `src/app/sign-up/[[...sign-up]]/page.tsx` using Clerk's `SignIn` / `SignUp` components.

## Checkpoint A

- [ ] Clerk keys in `.env.local`
- [ ] `src/proxy.ts` created
- [ ] Sign in / sign up pages work at /sign-in and /sign-up

---
# Part 3b: Prisma Schema and the Clerk Webhook Function

## 1. Set up Neon Postgres

Create a free project at neon.tech, copy the pooled connection string into `.env.local`:

```
DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require
```

## 2. Install Prisma

```bash
pnpm add -D prisma
pnpm add @prisma/client
npx prisma init
```

## 3. Define the schema

Replace `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        String   @id @default(cuid())
  clerkId   String   @unique
  email     String   @unique
  firstName String?
  lastName  String?
  createdAt DateTime @default(now())

  projects     ProjectMember[]
  tasksCreated Task[]          @relation("TaskCreatedBy")
  tasksAssigned Task[]         @relation("TaskAssignedTo")
}

model Project {
  id        String   @id @default(cuid())
  name      String
  createdAt DateTime @default(now())

  members ProjectMember[]
  tasks   Task[]
}

model ProjectMember {
  id        String  @id @default(cuid())
  project   Project @relation(fields: [projectId], references: [id])
  projectId String
  user      User    @relation(fields: [userId], references: [id])
  userId    String

  @@unique([projectId, userId])
}

enum TaskStatus {
  TODO
  IN_PROGRESS
  DONE
}

model Task {
  id          String     @id @default(cuid())
  title       String
  description String?
  status      TaskStatus @default(TODO)
  priority    String     @default("normal")
  dueDate     DateTime?
  createdAt   DateTime   @default(now())

  project   Project @relation(fields: [projectId], references: [id])
  projectId String

  createdBy   User   @relation("TaskCreatedBy", fields: [createdById], references: [id])
  createdById String

  assignee   User?   @relation("TaskAssignedTo", fields: [assigneeId], references: [id])
  assigneeId String?
}
```

Push it and generate the client:

```bash
npx prisma db push
npx prisma generate
```

Create `src/lib/prisma.ts` (singleton pattern to avoid exhausting connections in dev):

```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

## 4. Set up the Clerk webhook

In your Clerk dashboard, go to Webhooks, create an endpoint pointing at `https://<your-ngrok-or-deployed-url>/api/webhooks/clerk`, subscribe to `user.created`. Copy the signing secret into `.env.local`:

```
CLERK_WEBHOOK_SECRET=whsec_xxx
```

For local testing, install the Clerk-recommended `svix` package to verify signatures:

```bash
pnpm add svix
```

## 5. The webhook route: verify, then send an Inngest event

This is the key idea for this part: **the webhook route itself does almost nothing except verify the signature and send an Inngest event.** All the actual work (creating the DB user, sending a welcome email) happens inside a durable Inngest function, not inline in the webhook handler. This matters because webhook handlers must respond fast (Clerk retries if you're slow/timeout), and because Inngest gives you automatic retries if something downstream fails.

Create `src/app/api/webhooks/clerk/route.ts`:

```ts
import { Webhook } from "svix";
import { headers } from "next/headers";
import { inngest } from "@/inngest/client";

export async function POST(req: Request) {
  const payload = await req.text();
  const headerPayload = await headers();

  const svixHeaders = {
    "svix-id": headerPayload.get("svix-id") ?? "",
    "svix-timestamp": headerPayload.get("svix-timestamp") ?? "",
    "svix-signature": headerPayload.get("svix-signature") ?? "",
  };

  const wh = new Webhook(process.env.CLERK_WEBHOOK_SECRET!);

  let event: { type: string; data: Record<string, unknown> };
  try {
    event = wh.verify(payload, svixHeaders) as typeof event;
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  if (event.type === "user.created") {
    const data = event.data as {
      id: string;
      email_addresses: { email_address: string }[];
      first_name: string | null;
      last_name: string | null;
    };

    await inngest.send({
      name: "app/user.created",
      data: {
        clerkId: data.id,
        email: data.email_addresses[0]?.email_address ?? "",
        firstName: data.first_name,
        lastName: data.last_name,
      },
    });
  }

  return new Response("OK", { status: 200 });
}
```

Notice the webhook route never touches Prisma directly. It verifies the signature (fast, synchronous) and sends one event (fast, fire-and-forget). All the actual database work happens in the Inngest function below, where it's safe to retry.

## 6. Add the event type

Update the `Events` type in `src/inngest/client.ts`:

```ts
"app/user.created": {
  data: {
    clerkId: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
  };
};
```

## 7. Write the sync function

Create `src/inngest/functions/users.ts`:

```ts
import { inngest } from "../client";
import { prisma } from "@/lib/prisma";

export const syncUserOnCreate = inngest.createFunction(
  { id: "sync-user-on-create" },
  { event: "app/user.created" },
  async ({ event, step }) => {
    const user = await step.run("upsert-user-in-db", async () => {
      return prisma.user.upsert({
        where: { clerkId: event.data.clerkId },
        update: {
          email: event.data.email,
          firstName: event.data.firstName,
          lastName: event.data.lastName,
        },
        create: {
          clerkId: event.data.clerkId,
          email: event.data.email,
          firstName: event.data.firstName,
          lastName: event.data.lastName,
        },
      });
    });

    return { userId: user.id };
  }
);
```

Using `upsert` instead of `create` here is deliberate: if Clerk retries the webhook (which it does on any non-2xx or timeout), we'd send the event again, and the function could run twice. `upsert` makes re-running this step harmless — a core idea called **idempotency**, which we'll cover formally in Part 10.

Wire it into the route: update `src/app/api/inngest/route.ts`:

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { helloWorld } from "@/inngest/functions";
import { syncUserOnCreate } from "@/inngest/functions/users";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [helloWorld, syncUserOnCreate],
});
```

## 8. Test locally with ngrok

Clerk needs a public URL to send webhooks to during local dev:

```bash
npx ngrok http 3000
```

Copy the `https://xxxx.ngrok-free.app` URL into your Clerk webhook endpoint config (append `/api/webhooks/clerk`). Sign up a brand-new test user through your app's `/sign-up` page, then check:

1. Clerk dashboard → Webhooks → your endpoint → recent deliveries (should show 200 OK)
2. Inngest Dev Server dashboard → Runs → a `sync-user-on-create` run should appear, completed
3. Run `npx prisma studio` and confirm a new `User` row exists with the right `clerkId` and `email`

## Checkpoint

- [ ] Neon database connected, schema pushed, Prisma Client generated
- [ ] Clerk webhook endpoint configured and verified (svix signature check passes)
- [ ] Signing up a new user results in an `app/user.created` event
- [ ] The `sync-user-on-create` Inngest function runs and creates a `User` row in Postgres
- [ ] You understand why the webhook route only sends an event instead of touching Prisma directly

## Troubleshooting

**Webhook shows "Invalid signature."** Confirm `CLERK_WEBHOOK_SECRET` matches the *signing secret* shown for that specific endpoint in the Clerk dashboard (it's per-endpoint, not per-account).

**No Inngest run appears after sign-up.** Check the ngrok terminal for incoming requests — if nothing shows, the webhook URL in Clerk's dashboard is likely wrong or ngrok restarted with a new URL (ngrok free tier URLs change every restart; update Clerk's config each time).

**Prisma Client import errors.** Re-run `npx prisma generate` after any schema change, and restart your dev server (`pnpm dev`) — the generated client is cached at module load.

Next: **Part 4** goes deeper on `step.run`, and adds a real welcome email via Resend triggered from this same webhook function — want me to bring that up next?
