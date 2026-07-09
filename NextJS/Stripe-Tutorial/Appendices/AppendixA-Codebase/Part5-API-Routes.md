# Appendix A (5 of 5): Full Codebase Reference — API Routes

Index: "Stripe Tutorial - INDEX (Start Here)". This is the final part of Appendix A. See part 4 of 5 for orders/pricing/account pages.

## src/app/api/checkout/route.ts
```ts
import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { stripe } from "@/lib/stripe";
import { getProductById } from "@/lib/products";
import { env } from "@/lib/env";

export async function POST(req: NextRequest) {
  const { productId } = await req.json();

  const product = getProductById(productId);
  if (!product) {
    return NextResponse.json({ error: "Unknown product" }, { status: 400 });
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [{ price: product.priceId, quantity: 1 }],
      success_url: `${env.NEXT_PUBLIC_APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${env.NEXT_PUBLIC_APP_URL}/cancel`,
      metadata: { productId: product.id },
    });

    if (!session.url) {
      return NextResponse.json({ error: "Could not create checkout session" }, { status: 500 });
    }
    return NextResponse.json({ url: session.url });
  } catch (err) {
    if (err instanceof Stripe.errors.StripeRateLimitError) {
      return NextResponse.json({ error: "Too many requests, please try again shortly." }, { status: 429 });
    }
    if (err instanceof Stripe.errors.StripeInvalidRequestError) {
      console.error("Stripe invalid request:", err.message);
      return NextResponse.json({ error: "Invalid checkout request." }, { status: 400 });
    }
    console.error("Unexpected Stripe error:", err);
    return NextResponse.json({ error: "Something went wrong." }, { status: 500 });
  }
}
```

## src/app/api/checkout-cart/route.ts
```ts
import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { stripe } from "@/lib/stripe";
import { getProductById } from "@/lib/products";
import { env } from "@/lib/env";

type CartLine = { productId: string; quantity: number };

export async function POST(req: NextRequest) {
  const { lines }: { lines: CartLine[] } = await req.json();

  if (!Array.isArray(lines) || lines.length === 0) {
    return NextResponse.json({ error: "Cart is empty" }, { status: 400 });
  }

  const lineItems = [];
  for (const line of lines) {
    const product = getProductById(line.productId);
    if (!product) {
      return NextResponse.json({ error: `Unknown product: ${line.productId}` }, { status: 400 });
    }
    if (!Number.isInteger(line.quantity) || line.quantity < 1) {
      return NextResponse.json({ error: `Invalid quantity for ${line.productId}` }, { status: 400 });
    }
    lineItems.push({ price: product.priceId, quantity: line.quantity });
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: lineItems,
      success_url: `${env.NEXT_PUBLIC_APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${env.NEXT_PUBLIC_APP_URL}/cart`,
    });

    if (!session.url) {
      return NextResponse.json({ error: "Could not create checkout session" }, { status: 500 });
    }
    return NextResponse.json({ url: session.url });
  } catch (err) {
    if (err instanceof Stripe.errors.StripeRateLimitError) {
      return NextResponse.json({ error: "Too many requests, please try again shortly." }, { status: 429 });
    }
    if (err instanceof Stripe.errors.StripeInvalidRequestError) {
      console.error("Stripe invalid request:", err.message);
      return NextResponse.json({ error: "Invalid checkout request." }, { status: 400 });
    }
    console.error("Unexpected Stripe error:", err);
    return NextResponse.json({ error: "Something went wrong." }, { status: 500 });
  }
}
```

## src/app/api/checkout-subscription/route.ts
```ts
import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { stripe } from "@/lib/stripe";
import { getPlanById } from "@/lib/plans";
import { env } from "@/lib/env";

export async function POST(req: NextRequest) {
  const { planId } = await req.json();

  const plan = getPlanById(planId);
  if (!plan) {
    return NextResponse.json({ error: "Unknown plan" }, { status: 400 });
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: plan.priceId, quantity: 1 }],
      success_url: `${env.NEXT_PUBLIC_APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${env.NEXT_PUBLIC_APP_URL}/cancel`,
    });

    if (!session.url) {
      return NextResponse.json({ error: "Could not create checkout session" }, { status: 500 });
    }
    return NextResponse.json({ url: session.url });
  } catch (err) {
    if (err instanceof Stripe.errors.StripeRateLimitError) {
      return NextResponse.json({ error: "Too many requests, please try again shortly." }, { status: 429 });
    }
    if (err instanceof Stripe.errors.StripeInvalidRequestError) {
      console.error("Stripe invalid request:", err.message);
      return NextResponse.json({ error: "Invalid checkout request." }, { status: 400 });
    }
    console.error("Unexpected Stripe error:", err);
    return NextResponse.json({ error: "Something went wrong." }, { status: 500 });
  }
}
```

## src/app/api/portal/route.ts
```ts
import { NextResponse } from "next/server";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";
import { env } from "@/lib/env";

export async function POST() {
  const lastOrderWithCustomer = await db.order.findFirst({
    where: { stripeCustomerId: { not: null } },
    orderBy: { createdAt: "desc" },
  });

  if (!lastOrderWithCustomer?.stripeCustomerId) {
    return NextResponse.json(
      { error: "No Stripe customer found. Subscribe first from /pricing." },
      { status: 400 }
    );
  }

  const portalSession = await stripe.billingPortal.sessions.create({
    customer: lastOrderWithCustomer.stripeCustomerId,
    return_url: `${env.NEXT_PUBLIC_APP_URL}/account`,
  });

  return NextResponse.json({ url: portalSession.url });
}
```

## src/app/api/webhooks/stripe/route.ts
```ts
import { NextRequest, NextResponse } from "next/server";
import Stripe from "stripe";
import { stripe } from "@/lib/stripe";
import { db } from "@/lib/db";
import { env } from "@/lib/env";

export async function POST(req: NextRequest) {
  const body = await req.text();
  const signature = req.headers.get("stripe-signature");

  if (!signature) {
    return NextResponse.json({ error: "Missing stripe-signature header" }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, env.STRIPE_WEBHOOK_SECRET);
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
    case "customer.subscription.created":
    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const subscription = event.data.object as Stripe.Subscription;
      console.log(`Subscription ${subscription.id} is now status: ${subscription.status}`);
      break;
    }
    default:
      console.log(`Unhandled event type: ${event.type}`);
  }

  return NextResponse.json({ received: true });
}

async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const existing = await db.order.findUnique({
    where: { stripeCheckoutId: session.id },
  });
  if (existing) {
    console.log(`Order for session ${session.id} already recorded, skipping.`);
    return;
  }

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

