# Part 13: Syncing Clerk Users to Your Own Database via Webhooks

Clerk stores user data for you, but real apps almost always need their own local record of each user too — for example, to store app-specific data (a subscription plan, a preferences row) linked by a foreign key. Clerk sends **webhooks** for events like `user.created`, `user.updated`, and `user.deleted`, so your app can keep its own database in sync automatically.

This part uses **Svix** (the webhook delivery service Clerk uses under the hood) to verify incoming webhook signatures — this is free and included, no separate account needed.

## 1. Install the Svix verification library

```bash
npm install svix
```

## 2. Create the webhook route handler

Create `src/app/api/webhooks/clerk/route.ts`:

```ts
import { Webhook } from "svix";
import { headers } from "next/headers";
import type { WebhookEvent } from "@clerk/nextjs/server";

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;

  if (!WEBHOOK_SECRET) {
    throw new Error("Missing CLERK_WEBHOOK_SECRET in environment variables.");
  }

  // Get the Svix headers for verification
  const headerPayload = await headers();
  const svix_id = headerPayload.get("svix-id");
  const svix_timestamp = headerPayload.get("svix-timestamp");
  const svix_signature = headerPayload.get("svix-signature");

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return new Response("Missing svix headers", { status: 400 });
  }

  // Get the raw body
  const payload = await req.text();

  const wh = new Webhook(WEBHOOK_SECRET);
  let evt: WebhookEvent;

  try {
    evt = wh.verify(payload, {
      "svix-id": svix_id,
      "svix-timestamp": svix_timestamp,
      "svix-signature": svix_signature,
    }) as WebhookEvent;
  } catch (err) {
    console.error("Webhook verification failed:", err);
    return new Response("Invalid signature", { status: 400 });
  }

  const eventType = evt.type;

  if (eventType === "user.created") {
    const { id, email_addresses, first_name, last_name } = evt.data;
    const primaryEmail = email_addresses?.[0]?.email_address ?? null;

    console.log("Syncing new user to our database:", {
      clerkId: id,
      email: primaryEmail,
      firstName: first_name,
      lastName: last_name,
    });

    // Real usage example (pseudo-code - swap in your actual ORM/DB client):
    // await db.insert(usersTable).values({
    //   clerkId: id,
    //   email: primaryEmail,
    //   firstName: first_name,
    //   lastName: last_name,
    // });
  }

  if (eventType === "user.updated") {
    const { id, email_addresses, first_name, last_name } = evt.data;
    console.log("Updating user in our database:", { clerkId: id, first_name, last_name });

    // await db.update(usersTable).set({ ... }).where(eq(usersTable.clerkId, id));
  }

  if (eventType === "user.deleted") {
    const { id } = evt.data;
    console.log("Removing user from our database:", { clerkId: id });

    // await db.delete(usersTable).where(eq(usersTable.clerkId, id));
  }

  return new Response("OK", { status: 200 });
}
```

**This route is a good showcase of Next.js 16's async dynamic APIs in action:** notice `const headerPayload = await headers();` — `headers()` from `next/headers` must be awaited, exactly like `cookies()`, `params`, and `searchParams` elsewhere in this series (see Part 7). This has been true since Next.js 15 and remains the rule in Next.js 16.

We've left the actual database write as commented pseudo-code, since this tutorial is about Clerk, not a specific ORM/DB — the pattern (verify signature → check `evt.type` → write to your DB) is exactly what you'd wire into Drizzle, Prisma, or any other setup you use in a real project.

**Important:** this route intentionally bypasses our own `clerkMiddleware` auth check — webhook requests come from Clerk's servers, not from a logged-in browser session, so there's no user session to check. Signature verification (via Svix) is what proves the request is genuinely from Clerk instead of requiring a signed-in user.

## 3. Expose this route locally with a tunnel

Clerk's servers need to reach your webhook URL over the public internet — `localhost:3000` isn't reachable from Clerk's servers. For local development/testing, use a free tunnel tool. **ngrok** is a common free choice:

1. Install ngrok: https://ngrok.com/download (free tier requires a free account and one-time auth token setup, no credit card).
2. Run your Next.js dev server as usual: `npm run dev`
3. In a separate terminal, run:
   ```bash
   ngrok http 3000
   ```
4. Copy the `https://xxxx.ngrok-free.app` URL it gives you.

## 4. Register the webhook in the Clerk Dashboard

1. Go to Clerk Dashboard → **Webhooks** → **Add Endpoint**.
2. Endpoint URL: `https://xxxx.ngrok-free.app/api/webhooks/clerk` (your ngrok URL + our route path).
3. Subscribe to events: check `user.created`, `user.updated`, `user.deleted`.
4. Click **Create**.
5. Clerk shows you a **Signing Secret** (starts with `whsec_...`) — copy it.

## 5. Add the signing secret to your env vars

In `.env.local`:

```bash
CLERK_WEBHOOK_SECRET=whsec_your_signing_secret_here
```

Restart your dev server.

## 6. Test it end to end

1. With your dev server and ngrok tunnel both running, go to your Clerk Dashboard's Webhooks page, select your endpoint, and use the **Testing** tab to send a sample `user.created` event — or simply sign up a brand new test user through your app.
2. Check your terminal running `npm run dev` — you should see the `console.log` output confirming the event was received and verified.
3. In the Clerk Dashboard's Webhooks page, click into your endpoint's **Message Attempts** log to confirm a `200 OK` response was recorded.

## 7. Commit

```bash
git add .
git commit -m "Add Clerk webhook endpoint to sync users to our database"
```

(Note: don't commit ngrok itself or your tunnel URL anywhere permanent — it's only for local testing. In Part 14 we'll register a permanent webhook URL pointing at your real deployed domain.)

## Checkpoint

- [ ] `svix` installed
- [ ] `/api/webhooks/clerk` route created, verifying signatures before trusting payloads
- [ ] `headers()` is properly awaited, consistent with Next.js 16's async API rules
- [ ] ngrok tunnel running and webhook endpoint registered in Clerk Dashboard
- [ ] `CLERK_WEBHOOK_SECRET` set in `.env.local`
- [ ] Signing up a test user triggers a verified `user.created` event visible in your terminal logs
- [ ] Clerk Dashboard's Message Attempts log shows successful `200` deliveries

## Troubleshooting

**"Invalid signature" error every time.**
Almost always means `CLERK_WEBHOOK_SECRET` doesn't match the endpoint you're actually receiving events from (e.g. you copied the secret from a different/old endpoint, or didn't restart the dev server after adding it to `.env.local`). Delete and recreate the endpoint if you're unsure, and carefully recopy the fresh secret.

**Webhook never arrives / times out.**
Confirm your ngrok tunnel is still running (free ngrok tunnels expire when you close the terminal, and the URL changes each time you restart it unless you have a paid reserved domain) — if you restarted ngrok, you must update the endpoint URL in the Clerk Dashboard to the new one.

**`req.text()` / body parsing errors.**
Do not use `req.json()` here — signature verification requires the exact raw request body string. Using `req.text()` as shown is required; parse the JSON only after verification succeeds (which `wh.verify()` does for you, returning the typed `evt` object).

**TypeScript or runtime error about `headers()` returning a Promise / forgetting to await it.**
This is the exact Next.js 16 async-API gotcha flagged above. `headers()` must be awaited: `const headerPayload = await headers();` — using it without `await` will not give you a usable header-reading object.

**TypeScript complains about `evt.data` fields on `user.created`.**
`WebhookEvent` from `@clerk/nextjs/server` is a union type across all possible event types; TypeScript narrows `evt.data`'s shape correctly once you check `evt.type === "user.created"` inside an `if` block, as shown — accessing fields outside that narrowing may show type errors, which is expected and helps prevent bugs across event types.

**Do I need ngrok forever, even in production?**
No — ngrok is only a local development workaround for receiving webhooks before you have a real public URL. Once deployed to Vercel (Part 14), you'll register the webhook against your real `https://your-app.vercel.app/api/webhooks/clerk` URL instead, and ngrok is no longer needed.

Next up: Part 14, where we deploy the whole app to Vercel for free, including wiring up the production webhook.
