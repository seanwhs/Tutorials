# Part 8: Stripe Webhooks — Verifying Signatures & Handling checkout.session.completed

Previous: Part 7 (Database Setup with Prisma + SQLite). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Webhooks are how Stripe reliably tells your server "this payment succeeded" — independent of whether the customer's browser ever makes it back to your success page. This is the **only trustworthy source of truth** for "was this order actually paid."

Two critical rules:
1. **Always verify the webhook signature** using your webhook signing secret, so you know the request genuinely came from Stripe and wasn't forged.
2. **Always make webhook handling idempotent** — Stripe may deliver the same event more than once (network retries), so your handler must not create duplicate orders if it receives the same event twice.

## 2. Why Route Handlers need the raw request body

Verifying a Stripe signature requires the **exact raw bytes** of the request body — not a re-serialized JSON object, since even whitespace differences would break the signature check. Next.js Route Handlers give us this via `req.text()`.

## 3. The webhook route

File: src/app/api/webhooks/stripe/route.ts

```ts
import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = req.headers.get("stripe-signature");

  if (!signature) {
    return NextResponse.json({ error: "Missing stripe-signature header" }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      await handleCheckoutCompleted(session);
      break;
    }
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  return NextResponse.json({ received: true });
}

async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  // Idempotency check: have we already recorded this Checkout Session?
  const existing = await db.order.findUnique({
    where: { stripeCheckoutId: session.id },
  });
  if (existing) {
    console.log(`Order for session ${session.id} already recorded, skipping.`);
    return;
  }

  // Fetch full line item details (not included on the event payload by default)
  const lineItems = await stripe.checkout.sessions.listLineItems(session.id, {
    limit: 100,
  });

  await db.order.create({
    data: {
      stripeCheckoutId: session.id,
      stripeCustomerId:
        typeof session.customer === "string" ? session.customer : session.customer?.id ?? null,
      stripePaymentIntentId:
        typeof session.payment_intent === "string" ? session.payment_intent : null,
      customerEmail: session.customer_details?.email ?? null,
      amountTotal: session.amount_total ?? 0,
      currency: session.currency ?? "usd",
      status: "paid",
      items: {
        create: lineItems.data.map((item) => ({
          productName: item.description ?? "Unknown product",
          quantity: item.quantity ?? 1,
          amountTotal: item.amount_total ?? 0,
        })),
      },
    },
  });

  console.log(`Recorded order for session ${session.id}`);
}
```

## 4. Route configuration note

Next.js App Router Route Handlers already receive the raw, unparsed request by default when you call `req.text()` — there's no special config needed (unlike older Pages Router API routes, which needed `bodyParser: false`). Just make sure you never call `req.json()` before `req.text()` in this handler, since the body stream can only be read once.

## 5. What about STRIPE_WEBHOOK_SECRET?

We referenced `process.env.STRIPE_WEBHOOK_SECRET` above but haven't set it yet — that requires either the Stripe CLI (for local dev) or a Dashboard-configured webhook endpoint (for production). We set this up in the very next part, Part 9, because you need a running webhook forwarder to get this secret in the first place.

## Checkpoint

- [ ] `src/app/api/webhooks/stripe/route.ts` created and compiles with no TypeScript errors.
- [ ] You understand why we use `req.text()` instead of `req.json()` here.
- [ ] You understand why the idempotency check (`findUnique` by `stripeCheckoutId`) matters.
- [ ] Do not test this route yet by hand — it needs a real signed request. That's Part 9.

## Next

Continue to Part 9: Local Webhook Testing with the Stripe CLI.
