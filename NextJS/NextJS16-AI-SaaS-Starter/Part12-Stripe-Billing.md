## AI SaaS Tutorial - Part 12: Stripe Billing & Subscription Plans

*Next.js 16 note: the Stripe webhook route uses the async `headers()` API required in Next.js 16. Server Actions use the standard `"use server"` pattern, unaffected by the async dynamic API changes since they don't take params. The billing page uses Promise-based params like every other dynamic page in this series.*

### Goal
Add a Free and Pro plan per workspace using Stripe (test mode — free to use), with Checkout for upgrading and a webhook to keep our Subscription table in sync.

### 1. Create a free Stripe account
1. Go to stripe.com and sign up (stay in **Test mode**).
2. In Product catalog, create a product "Pro Plan" with a recurring monthly price (e.g. $9/mo — test mode never actually charges anyone).
3. Copy the Price ID (`price_xxx`).
4. Copy your Secret key and Publishable key from Developers → API keys (test mode keys).

### 2. Environment variables
```bash
STRIPE_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_PRO_PRICE_ID=price_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

### 3. Stripe client
`src/lib/stripe.ts`:
```ts
import Stripe from "stripe";

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: "2025-01-27.acacia",
});
```
(If a newer API version is shown in your Stripe dashboard/SDK types, use that instead.)

### 4. Checkout Server Action
`src/app/(dashboard)/workspaces/[workspaceId]/billing/actions.ts`:
```ts
"use server";

import { redirect } from "next/navigation";
import { stripe } from "@/lib/stripe";
import { getCurrentWorkspaceAndRole, canManageWorkspace } from "@/lib/workspace";
import { db } from "@/lib/db";

export async function createCheckoutSession(workspaceId: string) {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) throw new Error("Not authorized");
  if (!canManageWorkspace(ctx.role)) throw new Error("Only owners/admins can manage billing");

  let subscription = await db.subscription.findUnique({ where: { workspaceId } });

  let customerId = subscription?.stripeCustomerId;
  if (!customerId) {
    const customer = await stripe.customers.create({
      email: ctx.user.email,
      metadata: { workspaceId },
    });
    customerId = customer.id;
    subscription = await db.subscription.upsert({
      where: { workspaceId },
      update: { stripeCustomerId: customerId },
      create: { workspaceId, stripeCustomerId: customerId, plan: "FREE" },
    });
  }

  const session = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer: customerId,
    line_items: [{ price: process.env.STRIPE_PRO_PRICE_ID!, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/workspaces/${workspaceId}/billing?success=1`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/workspaces/${workspaceId}/billing?canceled=1`,
    metadata: { workspaceId },
  });

  redirect(session.url!);
}

export async function createBillingPortalSession(workspaceId: string) {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) throw new Error("Not authorized");
  if (!canManageWorkspace(ctx.role)) throw new Error("Only owners/admins can manage billing");

  const subscription = await db.subscription.findUnique({ where: { workspaceId } });
  if (!subscription?.stripeCustomerId) throw new Error("No billing account yet");

  const session = await stripe.billingPortal.sessions.create({
    customer: subscription.stripeCustomerId,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/workspaces/${workspaceId}/billing`,
  });

  redirect(session.url);
}
```

### 5. Stripe webhook to sync subscription state (async `headers()` — Next.js 16)
`src/app/api/webhooks/stripe/route.ts`:
```ts
import { headers } from "next/headers";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";

export async function POST(req: Request) {
  const body = await req.text();
  const signature = (await headers()).get("stripe-signature")!; // await required in Next.js 16

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as any;
      const workspaceId = session.metadata.workspaceId;
      const subscription = await stripe.subscriptions.retrieve(session.subscription);
      await db.subscription.update({
        where: { workspaceId },
        data: {
          stripeSubscriptionId: subscription.id,
          plan: "PRO",
          status: subscription.status,
          currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        },
      });
      break;
    }
    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const sub = event.data.object as any;
      const existing = await db.subscription.findUnique({
        where: { stripeSubscriptionId: sub.id },
      });
      if (existing) {
        await db.subscription.update({
          where: { id: existing.id },
          data: {
            plan: sub.status === "active" ? "PRO" : "FREE",
            status: sub.status,
            currentPeriodEnd: new Date(sub.current_period_end * 1000),
          },
        });
      }
      break;
    }
  }

  return new Response("ok", { status: 200 });
}
```

### 6. Register the webhook (local dev via Stripe CLI — free)
```bash
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```
This prints a webhook signing secret — put it in `STRIPE_WEBHOOK_SECRET`.

### 7. Billing page (Promise-based params — Next.js 16)
`src/app/(dashboard)/workspaces/[workspaceId]/billing/page.tsx`:
```tsx
import { notFound } from "next/navigation";
import { getCurrentWorkspaceAndRole, canManageWorkspace } from "@/lib/workspace";
import { db } from "@/lib/db";
import { createCheckoutSession, createBillingPortalSession } from "./actions";

export default async function BillingPage({
  params,
}: {
  params: Promise<{ workspaceId: string }>;
}) {
  const { workspaceId } = await params;
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) notFound();

  const subscription = await db.subscription.findUnique({ where: { workspaceId } });
  const plan = subscription?.plan ?? "FREE";

  return (
    <div>
      <h1 className="text-2xl font-bold">Billing</h1>
      <p className="mt-2">
        Current plan: <span className="font-semibold">{plan}</span>
      </p>

      {canManageWorkspace(ctx.role) ? (
        plan === "FREE" ? (
          <form action={createCheckoutSession.bind(null, workspaceId)}>
            <button className="mt-4 rounded bg-blue-600 px-4 py-2 text-white">
              Upgrade to Pro
            </button>
          </form>
        ) : (
          <form action={createBillingPortalSession.bind(null, workspaceId)}>
            <button className="mt-4 rounded border px-4 py-2">Manage Billing</button>
          </form>
        )
      ) : (
        <p className="mt-4 text-sm text-gray-500">Only owners/admins can manage billing.</p>
      )}
    </div>
  );
}
```

**Checkpoint:** Click "Upgrade to Pro," complete Stripe's test Checkout using card number `4242 4242 4242 4242` (any future expiry/CVC), and confirm the workspace's plan flips to PRO in `npx prisma studio` after the webhook fires.

**Next:** Part 13 — Enforcing Plan Limits per Workspace.
