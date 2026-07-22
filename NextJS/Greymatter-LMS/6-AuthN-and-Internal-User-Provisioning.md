# Part 6 — Authentication and Internal User Provisioning

## The goal

By the end of this part, GreyMatter LMS will have real sign-in and sign-up pages powered by Clerk, protected private routes, and — critically — a working webhook pipeline that automatically creates, updates, and deletes rows in our Part 5 `users` table whenever something happens to a user's Clerk account. We'll also build the authorization helper functions (`getCurrentUser`, `requireUser`, `requireRole`) that every remaining part of this series will use to answer "who is making this request, and are they allowed to do this?"

## Why it exists

Part 5 built a `users` table with an `authProviderId` column, but nothing yet populates it from a real identity system. Authentication answers "who are you?" — Clerk handles that entirely, so we never touch passwords, session cookies, or reset-email flows ourselves. But Clerk's own user database and *our* `users` table are two separate systems, exactly the way Sanity and Neon are two separate systems. This part builds the bridge between them: the moment someone signs up through Clerk, we need a corresponding row to appear in Neon — because every other table in Part 5 (`enrollments`, `lesson_progress`, `certificates`) points at *our* internal `users.id`, not Clerk's ID directly.

## The data flow

```text
User submits the sign-up form (rendered by Clerk's components)
        │
        ▼
Clerk creates the account on its own servers
        │
        ▼
Clerk sends a "user.created" webhook to our Next.js app
        │
        ▼
app/api/webhooks/clerk/route.ts verifies the webhook's signature
        │
        ▼
Checks webhook_events table for this event's external ID (idempotency)
        │
        ▼
Creates a row in our users table (authProviderId = Clerk's user ID)
        │
        ▼
From now on, every request from this user is translated:
Clerk session → authProviderId → our internal users.id
```

Terms worth defining before we build this:

- **Webhook**: an HTTP request that an external service (Clerk) sends *to us*, proactively, whenever something happens on their end — the reverse direction of a normal API call, where we'd be the one asking them. Think of it like a delivery notification: instead of you repeatedly calling the shipping company to ask "has my package arrived yet?", they call you the moment it does.
- **Signature verification**: a cryptographic check confirming a webhook request genuinely came from Clerk, and hasn't been tampered with in transit — without it, anyone who discovers our webhook URL could send us a fake "user.created" payload and trick our system into creating fraudulent accounts.
- **Idempotency**: the property that performing the same operation multiple times has the same effect as performing it once. Webhook providers explicitly warn that the same event can occasionally be delivered more than once (due to network retries) — our system must handle a duplicate delivery gracefully, not create two user rows or crash.

---

## Step 1 — Creating a Clerk application

### The Target
A real Clerk application, with publishable and secret keys added to our environment files.

### The Concept
Clerk is a hosted identity provider — it runs the actual sign-up form, password hashing, session cookie management, and account recovery flows on its own infrastructure, so we never have to implement any of that ourselves. Think of it like using a professional locksmith and security company for a building rather than designing your own lock mechanism from scratch — the risk of getting security-critical code subtly wrong is simply too high to reinvent.

### The Implementation

Visit **https://dashboard.clerk.com**, sign up or sign in, and click "Create application." Name it `GreyMatter LMS`. When asked which sign-in methods to enable, choose **Email address** and **Google** (or just Email if you prefer to keep things simple) — either choice works identically with everything we build in this series.

Once created, Clerk's dashboard shows your **Publishable key** and **Secret key** on the initial setup screen (also always available under "API Keys" in the sidebar). Add both to your environment files:

#### `.env.example` (update the Clerk section)

```bash
# ── Clerk (added in Part 6) ───────────────────────────────────────
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
CLERK_WEBHOOK_SIGNING_SECRET=
```

Add your real values to `.env.local` (leave `CLERK_WEBHOOK_SIGNING_SECRET` empty for now — we'll obtain it in Step 5):

```bash
# .env.local
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_real_key_here
CLERK_SECRET_KEY=sk_test_your_real_key_here
```

**Why does the publishable key get a `NEXT_PUBLIC_` prefix and the secret key doesn't?** Recall Part 1's rule: only variables genuinely needed in the browser get that prefix. Clerk's publishable key is *designed* to be public — it's embedded in browser JavaScript to initialize Clerk's client-side components. The secret key, by contrast, can perform privileged server-side operations (like verifying sessions and calling Clerk's backend API) and must never reach the browser.

### The Verification

Confirm both keys are visible in your Clerk dashboard under "API Keys," and confirm `.env.local` contains both without typos. We'll verify they actually work once `ClerkProvider` is wired up in Step 2.

---

## Step 2 — Installing Clerk and adding the provider

### The Target
Installing the Clerk SDK, wrapping our app in `<ClerkProvider>`, and updating `middleware.ts` to make Clerk aware of every incoming request.

### The Concept
`<ClerkProvider>` is a React Context provider (a pattern you may recognize from plain React) that makes the current user's session available to every component in the tree beneath it, without manually passing it down as a prop through every layer. **Middleware** is code that runs *before* a request reaches any page or route handler — think of it as a security checkpoint at a building's front entrance, checking every single person who walks in before they ever reach a specific office.

### The Implementation

```bash
npm install @clerk/nextjs
```

#### `middleware.ts` (project root)

```ts
import { clerkMiddleware } from "@clerk/nextjs/server";

// clerkMiddleware() attaches Clerk's session-detection logic to every
// matching request. It doesn't PROTECT anything by itself yet — it
// simply makes auth() (used throughout this part) work correctly inside
// Server Components and Route Handlers. We add explicit protection logic
// starting in Step 4.
export default clerkMiddleware();

export const config = {
  matcher: [
    // Skip Next.js internals and all static files, unless found in
    // search params. This is Clerk's recommended default matcher —
    // it ensures middleware runs on real pages and API routes, without
    // wasting effort on requests for images, fonts, etc.
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

Now wrap the app root with `<ClerkProvider>`:

#### `app/layout.tsx`

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "GreyMatter LMS",
  description: "A full-stack learning management system.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    // ClerkProvider wraps EVERYTHING, including <html>/<body>, because
    // Clerk needs to inject its own context before any descendant
    // component (including ones using useUser() or auth()) can access it.
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### The Verification

```bash
npm run dev
```

Visit `http://localhost:3000` and confirm the app still loads normally with no errors in the terminal or browser console. This confirms `<ClerkProvider>` initialized successfully with valid keys — an invalid or missing key would throw a visible error immediately at this point.

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 3 — Sign-in and sign-up pages

### The Target
`/sign-in` and `/sign-up` routes rendering Clerk's pre-built authentication UI components.

### The Concept
Clerk ships fully-built, accessible `<SignIn>` and `<SignUp>` components — complete forms handling validation, error states, password strength, and multi-step flows (like email verification codes) — that we drop directly into a page, the same way we'd drop in any other React component. We don't build our own form for this precisely *because* authentication UI is exactly the kind of security-sensitive, easy-to-get-wrong surface best left to a specialist, echoing Part 0's reasoning for choosing Clerk in the first place.

Clerk components need to know their own "base path" so multi-step flows (like "check your email for a code") can navigate correctly — we achieve this using another optional catch-all route, exactly the pattern Part 3 used for embedding Sanity Studio.

### The Implementation

#### `app/sign-in/[[...sign-in]]/page.tsx`

```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-16">
      <SignIn />
    </main>
  );
}
```

#### `app/sign-up/[[...sign-up]]/page.tsx`

```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-16">
      <SignUp />
    </main>
  );
}
```

Now tell Clerk where these routes live, and where to redirect after a successful sign-in/sign-up, using environment variables Clerk's components read automatically:

#### `.env.local` (add these lines)

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
```

And mirror them in `.env.example` (without values, as always):

```bash
# .env.example (append under the Clerk section)
NEXT_PUBLIC_CLERK_SIGN_IN_URL=
NEXT_PUBLIC_CLERK_SIGN_UP_URL=
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=
```

Update the homepage's "Sign In" button (built in Part 2) to actually link somewhere:

#### `app/page.tsx` (update the hero buttons section only)

```tsx
import Link from "next/link";
// ...existing imports remain unchanged

// Inside the hero section, replace the two <Button> elements with:
<div className="flex flex-wrap items-center justify-center gap-3">
  <Link href="/courses">
    <Button variant="primary" size="lg">
      Browse Courses
    </Button>
  </Link>
  <Link href="/sign-in">
    <Button variant="outline" size="lg">
      Sign In
    </Button>
  </Link>
</div>
```

### The Verification

```bash
npm run dev
```

Visit `http://localhost:3000/sign-up` and confirm Clerk's full sign-up form renders (email field, password field, and — if enabled — a "Continue with Google" button). Complete the sign-up flow with a real or disposable email address you control, including any email verification code step Clerk presents.

After completing sign-up, confirm you're redirected to `/dashboard` — this route doesn't exist yet, so you should see Next.js's default 404 page. That's expected and correct for now; we build a real dashboard in Part 7. What matters here is confirming the *redirect itself* happened, proving `NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL` is wired correctly.

Then visit **https://dashboard.clerk.com**, open your application, go to "Users," and confirm your new account appears there with the correct email — this confirms the account was genuinely created on Clerk's side.

---

## Step 4 — Reading server-side sessions and protecting routes

### The Target
A minimal protected page at `/dashboard` (a placeholder we'll properly build out in Part 7), demonstrating how to read the current session server-side and redirect unauthenticated visitors to `/sign-in`.

### The Concept
Clerk's `auth()` function, called from a Server Component, tells us whether the current request has a valid, signed-in session — and if so, Clerk's own user ID for that session. This is the *first half* of the identity bridge described in this part's data-flow diagram; the *second half* (translating that Clerk ID into our internal `users.id`) comes in Step 6, once real user rows actually exist via webhooks.

### The Implementation

#### `app/dashboard/page.tsx`

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function DashboardPlaceholderPage() {
  // auth() reads the incoming request's session cookie (verified by the
  // middleware from Step 2) and returns identity information WITHOUT
  // needing to be manually passed any request object — Next.js's async
  // request context makes this available automatically inside Server
  // Components and Route Handlers.
  const { userId } = await auth();

  if (!userId) {
    // redirect() immediately halts rendering and sends the browser
    // elsewhere — similar in spirit to Part 4's notFound(), but for
    // "you're not allowed here yet" rather than "this doesn't exist."
    redirect("/sign-in");
  }

  return (
    <main className="mx-auto flex max-w-3xl flex-col gap-4 px-6 py-16">
      <h1 className="text-3xl font-bold text-text-primary">Dashboard (placeholder)</h1>
      <p className="text-text-secondary">
        Signed in with Clerk user ID: <code className="rounded bg-surface-inset px-1.5 py-0.5 text-sm">{userId}</code>
      </p>
      <p className="text-sm text-text-muted">
        This page will be replaced with the real student dashboard in Part 7.
      </p>
    </main>
  );
}
```

### The Verification

While signed in (from Step 3), visit `http://localhost:3000/dashboard`. Confirm you now see the placeholder page showing your real Clerk user ID (a string starting with `user_`).

Now sign out — you can do this temporarily by adding Clerk's `<UserButton />` component somewhere visible, or simply by clearing cookies for `localhost:3000` in DevTools → Application → Cookies. Revisit `/dashboard` while signed out and confirm you're redirected to `/sign-in` instead of seeing the placeholder content.

---

## Step 5 — Setting up the Clerk webhook endpoint

### The Target
`app/api/webhooks/clerk/route.ts` — a Route Handler that receives, verifies, and (in Step 6) processes Clerk's `user.created`, `user.updated`, and `user.deleted` webhooks.

### The Concept
This is the "delivery notification" described earlier — Clerk calling *us*, rather than us polling Clerk. Because this endpoint receives requests from the open internet (Clerk's servers, not a logged-in browser), we cannot rely on Clerk's normal session cookie to know "this request is legitimate." Instead, every webhook request is signed with a cryptographic signature, using a secret only we and Clerk know, verified using the `svix` library that Clerk's webhook system is built on.

### The Implementation

First, install the verification library:

```bash
npm install svix
```

Now, before writing the route itself, we need to register the webhook endpoint in Clerk's dashboard so it gives us a **signing secret**. Since Clerk needs to reach a real, publicly-accessible URL (not `localhost`), we use a tunneling tool during local development:

```bash
npx ngrok http 3000
```

This prints a public HTTPS URL like `https://abcd-1234.ngrok-free.app` that forwards to your local dev server. Keep this running in its own terminal window for the rest of this step.

In Clerk's dashboard, go to "Webhooks" → "Add Endpoint." Set the endpoint URL to your ngrok URL plus our route path, e.g. `https://abcd-1234.ngrok-free.app/api/webhooks/clerk`. Under "Subscribe to events," select **user.created**, **user.updated**, and **user.deleted**. Save the endpoint, then copy the **Signing Secret** it generates (starts with `whsec_`).

Add it to your environment:

```bash
# .env.local
CLERK_WEBHOOK_SIGNING_SECRET=whsec_your_real_secret_here
```

Now the route handler itself, in this step verifying the signature only — we'll add the actual database logic in Step 6:

#### `app/api/webhooks/clerk/route.ts`

```ts
import { headers } from "next/headers";
import { Webhook } from "svix";
import { NextResponse } from "next/server";
import type { WebhookEvent } from "@clerk/nextjs/server";

function getWebhookSecret(): string {
  const secret = process.env.CLERK_WEBHOOK_SIGNING_SECRET;
  if (!secret) {
    throw new Error("Missing environment variable: CLERK_WEBHOOK_SIGNING_SECRET");
  }
  return secret;
}

export async function POST(request: Request) {
  const secret = getWebhookSecret();

  // Svix (the webhook delivery system Clerk uses internally) signs every
  // request using three specific headers. We need the RAW, unparsed
  // request body for verification — NOT request.json() — because
  // signature verification is computed over the exact bytes sent, and
  // parsing to JSON first would lose the original byte-for-byte payload.
  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return NextResponse.json(
      { error: "Missing required Svix headers" },
      { status: 400 }
    );
  }

  const rawBody = await request.text();
  const webhook = new Webhook(secret);

  let event: WebhookEvent;
  try {
    // webhook.verify() throws if the signature doesn't match — this is
    // the single line standing between "only Clerk can trigger this
    // code" and "anyone on the internet who finds this URL can."
    event = webhook.verify(rawBody, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    }) as WebhookEvent;
  } catch (error) {
    console.error("Clerk webhook signature verification failed:", error);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  console.log(`Verified Clerk webhook: ${event.type}`);

  // Database processing logic is added in Step 6 — for now, we
  // acknowledge receipt with a 200 so Clerk doesn't treat this as a
  // failed delivery and retry indefinitely.
  return NextResponse.json({ received: true });
}
```

**Code walkthrough:**

- `request.text()` (not `request.json()`) is the critical detail here — signature verification is a cryptographic hash computed over the *exact original bytes* Clerk sent. Parsing to JSON first and later re-serializing it would almost certainly produce slightly different bytes (different key ordering, whitespace, etc.), causing every single verification to fail even for genuinely legitimate requests.
- We return `NextResponse.json({ error: ... }, { status: 400 })` for a bad signature rather than `500` — a `400` communicates "your request was malformed/unauthorized," which is the semantically correct status for a failed signature check, distinct from a `500` which would suggest *our* server is broken.
- Notice we log `event.type` but haven't yet written anything to Neon — we're deliberately verifying the *transport* layer (is this really Clerk, sending real data, unaltered) completely on its own, before adding any database complexity in the next step. Testing one layer at a time like this makes debugging dramatically easier if something goes wrong.

### The Verification

With `npm run dev` and `npx ngrok http 3000` both still running, go to Clerk's dashboard → your webhook endpoint → "Testing" tab, and send a test `user.created` event. Check your `npm run dev` terminal output — you should see:

```text
Verified Clerk webhook: user.created
```

If instead you see `Invalid signature`, double check that `CLERK_WEBHOOK_SIGNING_SECRET` in `.env.local` exactly matches the signing secret shown in Clerk's dashboard for this specific endpoint, and restart the dev server after any `.env.local` change.

---

## Step 6 — Idempotent webhook processing and user provisioning

### The Target
Completing `app/api/webhooks/clerk/route.ts` to actually create, update, and delete rows in our `users` table — using the `webhook_events` table from Part 5 to guarantee each Clerk event is only ever processed once, even if Clerk redelivers it.

### The Concept
This is where Part 5's `webhook_events` table (with its `unique(source, external_id)` constraint) earns its keep. Every Svix-delivered webhook includes a unique `svix-id` header — Clerk's documentation explicitly states the same event may occasionally be delivered more than once due to network conditions on their end. Our defense is straightforward: before doing any real work, we attempt to *record* this event's ID in `webhook_events`. If that insert succeeds, this is genuinely the first time we've seen it, and we proceed. If it fails due to the unique constraint, we've already processed this exact event before — we simply acknowledge and stop, without duplicating any work.

### The Implementation

#### `db/queries/webhook-events.ts` 

```ts
import { and, eq } from "drizzle-orm";
import { db } from "@/db/client";
import { webhookEvents } from "@/db/schema";

export interface RecordWebhookEventInput {
  source: string;
  eventType: string;
  externalId: string;
  payload: unknown;
}

// Returns true if this is a NEW event (first time seen — go ahead and
// process it), or false if it's a DUPLICATE delivery of an event we've
// already recorded (skip processing, just acknowledge receipt).
export async function tryRecordWebhookEvent(
  input: RecordWebhookEventInput
): Promise<boolean> {
  const existing = await db.query.webhookEvents.findFirst({
    where: and(
      eq(webhookEvents.source, input.source),
      eq(webhookEvents.externalId, input.externalId)
    ),
  });

  if (existing) {
    return false; // already processed — this is a redelivery
  }

  // We insert BEFORE doing any real work, not after. This ordering
  // matters: if we processed the user first and inserted this record
  // last, a crash between those two steps could cause the SAME event to
  // be processed twice on a retry, exactly the bug this table exists to
  // prevent. Recording first, then processing, closes that gap.
  await db.insert(webhookEvents).values({
    source: input.source,
    eventType: input.eventType,
    externalId: input.externalId,
    payload: input.payload,
  });

  return true;
}

export async function markWebhookEventProcessed(
  source: string,
  externalId: string
) {
  await db
    .update(webhookEvents)
    .set({ processedAt: new Date() })
    .where(and(eq(webhookEvents.source, source), eq(webhookEvents.externalId, externalId)));
}
```

Now extend our user query helpers from Part 5 with update/delete operations:

#### `db/queries/users.ts` (add these functions)

```ts
// (append to the existing file from Part 5, Step 9)
import { eq } from "drizzle-orm";
import { db } from "@/db/client";
import { users } from "@/db/schema";

export interface UpdateUserInput {
  email?: string;
}

export async function updateUserByAuthProviderId(
  authProviderId: string,
  input: UpdateUserInput
) {
  const [updated] = await db
    .update(users)
    .set({ ...input, updatedAt: new Date() })
    .where(eq(users.authProviderId, authProviderId))
    .returning();
  return updated;
}

export async function deleteUserByAuthProviderId(authProviderId: string) {
  // Thanks to Part 5's onDelete: "cascade" foreign keys, deleting this
  // row automatically deletes every enrollment, lesson_progress,
  // course_progress, module_attempt, and certificate row that pointed
  // at this user — we don't need to manually clean up five other tables
  // here ourselves.
  const [deleted] = await db
    .delete(users)
    .where(eq(users.authProviderId, authProviderId))
    .returning();
  return deleted;
}
```

Now the complete webhook route:

#### `app/api/webhooks/clerk/route.ts` (final version)

```ts
import { headers } from "next/headers";
import { Webhook } from "svix";
import { NextResponse } from "next/server";
import type { WebhookEvent } from "@clerk/nextjs/server";
import { tryRecordWebhookEvent, markWebhookEventProcessed } from "@/db/queries/webhook-events";
import {
  createUser,
  deleteUserByAuthProviderId,
  findUserByAuthProviderId,
  updateUserByAuthProviderId,
} from "@/db/queries/users";

function getWebhookSecret(): string {
  const secret = process.env.CLERK_WEBHOOK_SIGNING_SECRET;
  if (!secret) {
    throw new Error("Missing environment variable: CLERK_WEBHOOK_SIGNING_SECRET");
  }
  return secret;
}

export async function POST(request: Request) {
  const secret = getWebhookSecret();

  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return NextResponse.json({ error: "Missing required Svix headers" }, { status: 400 });
  }

  const rawBody = await request.text();
  const webhook = new Webhook(secret);

  let event: WebhookEvent;
  try {
    event = webhook.verify(rawBody, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    }) as WebhookEvent;
  } catch (error) {
    console.error("Clerk webhook signature verification failed:", error);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  // svixId (the "svix-id" header) is a stable, unique identifier for
  // THIS delivery attempt of THIS event — exactly the externalId our
  // webhook_events table's unique constraint is designed around.
  const isNewEvent = await tryRecordWebhookEvent({
    source: "clerk",
    eventType: event.type,
    externalId: svixId,
    payload: event.data,
  });

  if (!isNewEvent) {
    console.log(`Skipping duplicate Clerk webhook delivery: ${svixId}`);
    return NextResponse.json({ received: true, duplicate: true });
  }

  try {
    switch (event.type) {
      case "user.created": {
        const clerkUser = event.data;
        const primaryEmail = clerkUser.email_addresses.find(
          (e) => e.id === clerkUser.primary_email_address_id
        )?.email_address;

        if (!primaryEmail) {
          throw new Error("Clerk user has no primary email address");
        }

        // Defensive check: if a user with this authProviderId somehow
        // already exists (e.g. from a manual seed, or an earlier partial
        // failure), we don't want to crash with a unique-constraint
        // error — we simply treat this as already-provisioned.
        const existing = await findUserByAuthProviderId(clerkUser.id);
        if (!existing) {
          await createUser({
            authProviderId: clerkUser.id,
            email: primaryEmail,
            role: "STUDENT", // every new sign-up starts as a Student; Part 15/16 cover promoting users to Instructor/Admin
          });
          console.log(`Provisioned internal user for Clerk ID: ${clerkUser.id}`);
        }
        break;
      }

      case "user.updated": {
        const clerkUser = event.data;
        const primaryEmail = clerkUser.email_addresses.find(
          (e) => e.id === clerkUser.primary_email_address_id
        )?.email_address;

        if (primaryEmail) {
          await updateUserByAuthProviderId(clerkUser.id, { email: primaryEmail });
          console.log(`Updated internal user for Clerk ID: ${clerkUser.id}`);
        }
        break;
      }

      case "user.deleted": {
        // Clerk's user.deleted payload only guarantees an "id" field —
        // the user object itself is being removed, so other fields may
        // be absent.
        const clerkUserId = event.data.id;
        if (clerkUserId) {
          await deleteUserByAuthProviderId(clerkUserId);
          console.log(`Deleted internal user for Clerk ID: ${clerkUserId}`);
        }
        break;
      }

      default:
        console.log(`Unhandled Clerk webhook event type: ${event.type}`);
    }

    await markWebhookEventProcessed("clerk", svixId);
  } catch (error) {
    // We deliberately do NOT re-throw here in a way that would cause
    // Clerk to retry indefinitely on a permanent, non-transient error
    // (like a malformed payload) — we log it for our own investigation
    // and still return a 200, since retrying would just fail the same
    // way again. A production system might route this to a dead-letter
    // queue instead; Part 16 discusses this tradeoff further.
    console.error(`Error processing Clerk webhook ${event.type}:`, error);
  }

  return NextResponse.json({ received: true });
}
```

**Code walkthrough:**

- The `isNewEvent` check happens **before** the `switch` statement's real work, and `markWebhookEventProcessed` is called only **after** it succeeds — this brackets the actual provisioning logic between "claim this event" and "confirm it's done," which is the concrete implementation of the idempotency principle explained above.
- Inside `user.created`, we *also* defensively check `findUserByAuthProviderId` before inserting — this is a second, independent layer of duplicate protection beyond the webhook-event check, since `users.authProviderId` itself has its own `unique()` constraint from Part 5. Belt-and-suspenders defensive coding like this is a deliberate habit, not redundancy for its own sake: it protects against a scenario where the webhook-event record succeeded but a previous attempt still managed to create the user row before crashing.
- The `catch` block around the `switch` statement logs the error but still returns `NextResponse.json({ received: true })` with an implicit `200` status — this is a considered decision, not an oversight: returning a `500` here would cause Clerk to retry, and if the failure is due to a genuine bug (not a transient network issue), retrying will just fail identically forever. We accept this tradeoff for the scope of this tutorial series and note the more robust alternative (a dead-letter queue) as a Part 16 topic.

### The Verification

With `ngrok` still forwarding to your running dev server, go to Clerk's dashboard → "Users" → find an existing test account (or create a brand new one via `/sign-up` to generate a fresh `user.created` event naturally) — the cleanest test is simply signing up a **new** account through `/sign-up` now that the full pipeline is wired up.

Watch your `npm run dev` terminal output. You should see:

```text
Provisioned internal user for Clerk ID: user_xxxxxxxxxxxx
```

Open Drizzle Studio to confirm directly:

```bash
npm run db:studio
```

Confirm a new row now exists in the `users` table, with `auth_provider_id` matching the Clerk user ID from the log line, the correct email, and `role = STUDENT`.

Now test the **idempotency** guarantee directly: in Clerk's dashboard, go to your webhook endpoint's "Message Attempts" (or "Testing") tab, find the `user.created` delivery you just triggered, and click "Resend." Watch the terminal again — this time you should see:

```text
Skipping duplicate Clerk webhook delivery: msg_xxxxxxxxxxxx
```

Confirm in Drizzle Studio that the `users` table still has exactly **one** row for this user, not two — proof the idempotency check genuinely works.

Finally, test `user.deleted`: in Clerk's dashboard, delete this test user account entirely. Confirm the terminal logs `Deleted internal user for Clerk ID: ...`, and confirm in Drizzle Studio that the corresponding row is gone from `users` (and, if you'd created any enrollments for this test user, that those cascaded away too).

---

## Step 7 — Building the authorization helper functions

### The Target
`lib/auth/get-current-user.ts`, `lib/auth/require-user.ts`, and `lib/auth/require-role.ts` — the small set of functions every future Server Component, Server Action, and Route Handler in this series will call to answer "who is this, and are they allowed to do this?"

### The Concept
Recall Part 0's driving-test analogy and Part 6's opening thesis: authentication (Clerk) answers "who are you?"; **authorization** answers "are you allowed to do *this specific thing*?" These are genuinely different questions, and conflating them is a common source of security bugs — a logged-in student is authenticated, but is not authorized to view the instructor analytics dashboard. We're building three helpers of increasing strictness, each layering on top of the one before it:

- `getCurrentUser()` — "who is this, if anyone?" Returns `null` gracefully if nobody's signed in. Safe to call from anywhere, including public pages that behave slightly differently for signed-in visitors.
- `requireUser()` — "this operation requires *someone* to be signed in." Throws/redirects if not. Used by anything behind the student dashboard.
- `requireRole()` — "this operation requires someone signed in *with a specific role*." Used by instructor- and admin-only pages and actions.

This is also our first genuine bridge between Clerk's identity (Step 4) and our internal `users` table (Part 5) — every one of these functions performs the exact translation described in this part's opening data-flow diagram.

### The Implementation

#### `lib/auth/get-current-user.ts`

```ts
import { auth } from "@clerk/nextjs/server";
import { findUserByAuthProviderId } from "@/db/queries/users";
import type { UserRole } from "@/db/queries/users";

export interface CurrentUser {
  id: string; // our INTERNAL users.id — this is what every other table's foreign keys expect
  authProviderId: string; // Clerk's ID — useful for logging/debugging, rarely used for queries directly
  email: string;
  role: UserRole;
}

// Returns null if nobody is signed in, OR if a Clerk session exists but
// no matching internal user row has been provisioned yet (a brief race
// window right after sign-up, before the webhook from Step 6 finishes —
// see the "Common mistakes" section for how we handle this).
export async function getCurrentUser(): Promise<CurrentUser | null> {
  const { userId } = await auth();

  if (!userId) {
    return null;
  }

  const user = await findUserByAuthProviderId(userId);

  if (!user) {
    return null;
  }

  return {
    id: user.id,
    authProviderId: user.authProviderId,
    email: user.email,
    role: user.role,
  };
}
```

#### `lib/auth/require-user.ts`

```ts
import { redirect } from "next/navigation";
import { getCurrentUser, type CurrentUser } from "./get-current-user";

// requireUser() is the function every authenticated page/action calls
// FIRST. It guarantees callers always receive a real, fully-provisioned
// CurrentUser — never null — because it redirects away before ever
// returning otherwise. This means every line of code AFTER calling
// requireUser() can safely assume a valid, non-null user exists, with no
// repeated null-checking scattered through every feature.
export async function requireUser(): Promise<CurrentUser> {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  return user;
}
```

#### `lib/auth/require-role.ts`

```ts
import { redirect } from "next/navigation";
import { requireUser } from "./require-user";
import type { CurrentUser } from "./get-current-user";
import type { UserRole } from "@/db/queries/users";

// requireRole() builds directly on requireUser() — it first guarantees
// someone is signed in, THEN checks their role. Notice the deliberate
// choice below: an authenticated-but-wrong-role user is redirected to
// "/dashboard" (a place they DO have access to), not back to "/sign-in"
// (which would be misleading — they ARE signed in, they're just not
// authorized for this specific page).
export async function requireRole(
  allowedRoles: UserRole | UserRole[]
): Promise<CurrentUser> {
  const user = await requireUser();
  const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

  if (!roles.includes(user.role)) {
    redirect("/dashboard");
  }

  return user;
}
```

**Code walkthrough:**

- `requireUser()`'s return type is `Promise<CurrentUser>` — **not** `Promise<CurrentUser | null>` — even though internally it calls `getCurrentUser()`, which *can* return `null`. This is intentional and meaningful: because `redirect()` throws internally (recall Part 4's `notFound()`), execution never actually reaches the `return user;` line unless `user` is guaranteed non-null. TypeScript's control-flow narrowing understands this pattern, letting us give callers a stronger, more convenient guarantee than the underlying primitive provides.
- Distinguishing where each helper redirects to (`/sign-in` for "not authenticated at all" vs. `/dashboard` for "authenticated but wrong role") is a small detail with real user-experience value — it avoids the confusing experience of being sent back to a sign-in page while already signed in.
- We deliberately keep these as three separate, composable functions rather than one function with a `{ role?: UserRole }` options object — this mirrors Part 2's "composition over configuration" principle: `requireUser()` alone is exactly what most authenticated pages need, and `requireRole()` is only reached for once you actually need role restriction, keeping the common case simple.

### The Verification

We don't have a role-restricted page to test against yet (that arrives properly in Part 15's instructor dashboard) — but we can verify `requireUser()` right now by upgrading our Step 4 placeholder dashboard to use it:

#### `app/dashboard/page.tsx` (updated)

```tsx
import { requireUser } from "@/lib/auth/require-user";

export default async function DashboardPlaceholderPage() {
  // requireUser() replaces the manual auth() + redirect() logic from
  // Step 4 entirely — and additionally now gives us our INTERNAL user
  // record (id, email, role), not just Clerk's bare userId string.
  const user = await requireUser();

  return (
    <main className="mx-auto flex max-w-3xl flex-col gap-4 px-6 py-16">
      <h1 className="text-3xl font-bold text-text-primary">Dashboard (placeholder)</h1>
      <dl className="flex flex-col gap-2 text-sm">
        <div className="flex gap-2">
          <dt className="font-medium text-text-secondary">Internal ID:</dt>
          <dd className="text-text-primary">{user.id}</dd>
        </div>
        <div className="flex gap-2">
          <dt className="font-medium text-text-secondary">Email:</dt>
          <dd className="text-text-primary">{user.email}</dd>
        </div>
        <div className="flex gap-2">
          <dt className="font-medium text-text-secondary">Role:</dt>
          <dd className="text-text-primary">{user.role}</dd>
        </div>
      </dl>
      <p className="text-sm text-text-muted">
        This page will be replaced with the real student dashboard in Part 7.
      </p>
    </main>
  );
}
```

Visit `http://localhost:3000/dashboard` while signed in with the account you provisioned in Step 6. Confirm it now shows your **internal** database `id` (a UUID from our `users` table), your email, and `STUDENT` as the role — this proves the full identity bridge works end-to-end: Clerk session → `auth()` → `authProviderId` → Neon lookup → internal `CurrentUser` object.

Sign out and revisit `/dashboard` — confirm the redirect to `/sign-in` still works exactly as before.

```bash
npx tsc --noEmit
npm run build
```

Both should complete without errors.

---

## Step 8 — Handling the provisioning race condition

### The Target
A small but important defensive addition to `getCurrentUser()`, handling the brief window where a user has a valid Clerk session but the `user.created` webhook hasn't finished processing yet.

### The Concept
Webhooks are asynchronous by nature — Clerk creates the account, redirects the browser to `/dashboard` almost instantly, but the `user.created` webhook might arrive at our server a few hundred milliseconds *later*. In that narrow window, a genuinely legitimate, freshly-signed-up user could hit `/dashboard`, call `requireUser()`, find no matching row in Neon yet, and get incorrectly redirected back to `/sign-in` — a confusing, broken-feeling experience for a real user who did everything right. We handle this with a direct, synchronous fallback: if no internal user is found, attempt to fetch the user's details **directly from Clerk's API** (not wait for the webhook) and provision them immediately, right there in the request.

### The Implementation

#### `lib/auth/ensure-internal-user.ts`

```ts
import { clerkClient } from "@clerk/nextjs/server";
import { createUser, findUserByAuthProviderId } from "@/db/queries/users";

// This function is our safety net for the webhook race condition. It is
// NOT a replacement for the webhook (Step 6) — the webhook remains the
// PRIMARY provisioning path, since it also correctly handles user.updated
// and user.deleted, which this function does not. This function only
// handles the narrow "webhook hasn't arrived YET" case for user.created.
export async function ensureInternalUser(clerkUserId: string) {
  const existing = await findUserByAuthProviderId(clerkUserId);
  if (existing) {
    return existing;
  }

  // Fetch directly from Clerk's backend API — this is a synchronous,
  // on-demand alternative to waiting for the asynchronous webhook.
  const client = await clerkClient();
  const clerkUser = await client.users.getUser(clerkUserId);

  const primaryEmail = clerkUser.emailAddresses.find(
    (e) => e.id === clerkUser.primaryEmailAddressId
  )?.emailAddress;

  if (!primaryEmail) {
    throw new Error(`Clerk user ${clerkUserId} has no primary email address`);
  }

  // It's possible (though rare) that the webhook actually completes
  // between our findUserByAuthProviderId check above and this insert —
  // Part 5's unique(auth_provider_id) constraint protects us from ever
  // ending up with two rows in that case. We handle that specific
  // failure gracefully rather than letting it surface as a crash.
  try {
    return await createUser({
      authProviderId: clerkUserId,
      email: primaryEmail,
      role: "STUDENT",
    });
  } catch {
    // The webhook won the race — fetch the row IT created instead.
    const user = await findUserByAuthProviderId(clerkUserId);
    if (!user) {
      throw new Error(`Failed to provision or find user for Clerk ID ${clerkUserId}`);
    }
    return user;
  }
}
```

Now update `getCurrentUser()` to use this fallback:

#### `lib/auth/get-current-user.ts` (updated)

```ts
import { auth } from "@clerk/nextjs/server";
import { ensureInternalUser } from "./ensure-internal-user";
import type { UserRole } from "@/db/queries/users";

export interface CurrentUser {
  id: string;
  authProviderId: string;
  email: string;
  role: UserRole;
}

export async function getCurrentUser(): Promise<CurrentUser | null> {
  const { userId } = await auth();

  if (!userId) {
    return null;
  }

  try {
    // ensureInternalUser() replaces a bare findUserByAuthProviderId()
    // lookup — it transparently handles the "webhook hasn't arrived yet"
    // race condition described above, provisioning the user on-demand
    // if necessary, while still preferring the webhook-created row
    // whenever one already exists.
    const user = await ensureInternalUser(userId);
    return {
      id: user.id,
      authProviderId: user.authProviderId,
      email: user.email,
      role: user.role,
    };
  } catch (error) {
    // If Clerk's API is unreachable, or the user genuinely has no email
    // on file, we fail closed (treat as signed out) rather than throwing
    // an unhandled error up through every page that calls requireUser().
    console.error("Failed to resolve current user:", error);
    return null;
  }
}
```

**Code walkthrough:**

- Notice the layered defense here mirrors Step 6's belt-and-suspenders approach exactly: the webhook is the primary path, `ensureInternalUser` is the on-demand fallback, and Part 5's `unique(auth_provider_id)` database constraint is the final safety net if both somehow race each other. Three independent layers protecting the same invariant ("exactly one internal user row per Clerk identity") is a deliberate, defense-in-depth pattern worth recognizing — we'll see it again in Part 8's enrollment logic and Part 11's assessment grading.
- `getCurrentUser()` catching and swallowing the error (returning `null` instead of re-throwing) means a transient Clerk API outage degrades gracefully to "treated as signed out" rather than crashing every single authenticated page in the app — a deliberate choice to fail safe rather than fail loud, appropriate specifically for this identity-resolution boundary.

### The Verification

This race condition is difficult to trigger reliably on purpose in local development (webhooks usually arrive quickly), so we verify it more directly: temporarily comment out the entire `case "user.created":` block's body inside `app/api/webhooks/clerk/route.ts` (leaving the `break;` in place), effectively simulating "the webhook never arrives." Sign up with a brand new test account and immediately visit `/dashboard`.

Confirm the placeholder dashboard **still loads correctly**, showing your new internal user's ID, email, and `STUDENT` role — proving `ensureInternalUser()`'s on-demand fallback provisioned the user itself, entirely independent of the (deliberately disabled) webhook.

Check Drizzle Studio and confirm exactly one row exists for this user (not zero, not two).

**Revert your temporary edit** to `app/api/webhooks/clerk/route.ts`, restoring the real `user.created` handling, and re-run the full verification suite:

```bash
npx tsc --noEmit
npm run build
```

---

## Common mistakes

- **`ClerkProvider` throws "Missing publishableKey"** — Confirm `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` is present in `.env.local` and the dev server was restarted after adding it.
- **Sign-in/sign-up pages render blank or throw a routing error** — Confirm the catch-all folder names exactly match Clerk's expected convention: `app/sign-in/[[...sign-in]]/page.tsx` and `app/sign-up/[[...sign-up]]/page.tsx` — a mismatched folder name (e.g., missing the double brackets) breaks Clerk's internal multi-step navigation.
- **Webhook verification always fails, even with a correct-looking secret** — Almost always caused by accidentally calling `request.json()` before `request.text()` somewhere, or a proxy/middleware layer that has already consumed the request body. Confirm `rawBody = await request.text()` is the *first* thing read from the request.
- **ngrok URL changes and webhook stops working** — Free ngrok URLs change every time you restart it. If webhooks suddenly stop arriving, check whether your ngrok tunnel restarted and update the endpoint URL in Clerk's dashboard to match the new one.
- **`user.created` webhook fires but no row appears, with no error logged either** — Check that `event.data.email_addresses` actually contains an entry matching `primary_email_address_id` — this can occasionally be empty for certain Clerk-side test/dummy accounts; use a real email during testing.
- **Duplicate key error despite the idempotency check** — If you see a genuine unique-constraint crash on `users.authProviderId` (not `webhook_events`), it usually means the defensive `findUserByAuthProviderId` check inside the `user.created` case and the actual `createUser` call raced against a concurrent request; this is precisely why we wrapped equivalent logic in `ensureInternalUser()` with a try/catch fallback — consider applying the same pattern inside the webhook handler if you see this in practice.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `middleware.ts`, `app/layout.tsx` (modified), `app/sign-in/[[...sign-in]]/page.tsx`, `app/sign-up/[[...sign-up]]/page.tsx`, `app/dashboard/page.tsx` (modified twice this part), `app/api/webhooks/clerk/route.ts`, `db/queries/webhook-events.ts`, `db/queries/users.ts` (modified), `lib/auth/get-current-user.ts`, `lib/auth/require-user.ts`, `lib/auth/require-role.ts`, `lib/auth/ensure-internal-user.ts`, and updated `.env.example`.

```bash
git commit -m "Part 6: Clerk authentication — sign-in/sign-up, webhook-based user provisioning, idempotent processing, auth helper functions, race-condition fallback"
```

---

## Reference: the identity bridge, end to end

| Layer | Lives in | Identifies a user by |
|---|---|---|
| Session cookie | Browser | Clerk session token |
| `auth()` | Clerk SDK, server-side | Clerk's `userId` (e.g. `user_2abc...`) |
| `users.authProviderId` | Neon (our database) | Same Clerk `userId`, stored as a plain string |
| `users.id` | Neon (our database) | Our own internal UUID — **this** is what every other table's foreign keys use |
| `CurrentUser` | Returned by `getCurrentUser()`/`requireUser()` | Both IDs, plus email and role, ready for application code to use |

## Reference: authorization helper cheat sheet

| Function | Use when | Behavior if unauthenticated/unauthorized |
|---|---|---|
| `getCurrentUser()` | A page behaves differently for signed-in vs. anonymous visitors, but doesn't require sign-in | Returns `null` — never redirects |
| `requireUser()` | The entire page/action requires *any* signed-in user | Redirects to `/sign-in` |
| `requireRole(role)` | The entire page/action requires a *specific* role (Instructor/Admin) | Redirects to `/sign-in` if unauthenticated, or `/dashboard` if authenticated but wrong role |

## Reference: webhook idempotency pattern (reusable beyond Clerk)

```text
1. Verify the request's signature.
2. Extract the provider's own unique event/delivery ID.
3. Attempt to INSERT that ID into a tracking table with a unique constraint.
     ├── Insert succeeds → this is new; proceed with real work → mark processed.
     └── Insert fails (constraint violation) → already handled; acknowledge and stop.
```

This exact four-step pattern will reappear in Part 12 when we build Inngest's own idempotency handling — recognizing it here first makes that part feel familiar rather than novel.

---

## What's next

Part 7 builds the real, permanent student dashboard shell that Step 4 and Step 7's placeholder page has been standing in for — a responsive layout with a sidebar showing only the courses a student is actually enrolled in, chapter/lesson navigation, a mobile-friendly navigation drawer, and the Context provider boundaries that will carry progress data down to every lesson page starting in Part 9.
