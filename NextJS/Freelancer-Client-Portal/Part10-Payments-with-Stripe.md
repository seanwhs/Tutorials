# Part 10: Payments with Stripe

Previous: Part 9 (Chat).

Targets current `stripe` Node SDK. Webhook route uses Next.js 16's async `headers()`.

## 1. Concept

Stripe Checkout: hosted payment page. Server creates a Checkout Session, redirects client, Stripe redirects back. A webhook (`checkout.session.completed`) is the source of truth for PAID status — never trust the client-side redirect alone.

Flow: client clicks "Pay now" → server creates Checkout Session with invoice line items + `invoice.id` in metadata → client pays with test card on Stripe's page → Stripe calls our webhook → we mark invoice PAID → client redirected back.

## 2. Create a Stripe account and get keys

1. dashboard.stripe.com → sign up, stay in Test mode.
2. Copy Secret key.
3. `.env.local`:

```bash
STRIPE_SECRET_KEY=sk_test_xxxxxxxx
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## 3. Install Stripe SDK

```bash
pnpm add stripe
```

## 4. Stripe client singleton

```ts
// src/server/stripe.ts
import Stripe from "stripe";

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);
```

No `apiVersion` pinned — lets the SDK use its own default, avoiding confusing TypeScript literal-type errors on upgrade.

## 5. Add a tRPC procedure to create a Checkout Session

```ts
// src/server/api/routers/invoice.ts (add to existing invoiceRouter)
import { stripe } from "@/server/stripe";

createCheckoutSession: protectedProcedure
  .input(z.object({ invoiceId: z.string() }))
  .mutation(async ({ ctx, input }) => {
    const invoice = await ctx.db.invoice.findUniqueOrThrow({
      where: { id: input.invoiceId },
      include: { items: true, project: { include: { client: true } } },
    });

    if (ctx.user.role !== "ADMIN" && invoice.project.client.userId !== ctx.user.id) {
      throw new TRPCError({ code: "FORBIDDEN" });
    }

    if (invoice.status === "PAID") {
      throw new TRPCError({ code: "BAD_REQUEST", message: "Invoice already paid" });
    }

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      line_items: invoice.items.map((item) => ({
        price_data: {
          currency: "usd",
          product_data: { name: item.description },
          unit_amount: Math.round(Number(item.unitPrice) * 100),
        },
        quantity: item.quantity,
      })),
      metadata: { invoiceId: invoice.id },
      success_url: `${process.env.NEXT_PUBLIC_APP_URL}/portal/invoices/${invoice.id}?paid=1`,
      cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/portal/invoices/${invoice.id}`,
    });

    await ctx.db.invoice.update({
      where: { id: invoice.id },
      data: { stripeCheckoutId: session.id },
    });

    return { url: session.url };
  }),
```

Add this inside `invoiceRouter`, right after `markPaidManually`.

## 6. Stripe webhook route handler

```ts
// src/app/api/webhooks/stripe/route.ts
import { headers } from "next/headers";
import { stripe } from "@/server/stripe";
import { db } from "@/server/db";
import Stripe from "stripe";

export async function POST(req: Request) {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    return new Response("Missing STRIPE_WEBHOOK_SECRET", { status: 500 });
  }

  const body = await req.text();
  const signature = (await headers()).get("stripe-signature");

  if (!signature) {
    return new Response("Missing stripe-signature header", { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    console.error("Stripe webhook signature verification failed", err);
    return new Response("Invalid signature", { status: 400 });
  }

  if (event.type === "checkout.session.completed") {
    const session = event.data.object as Stripe.Checkout.Session;
    const invoiceId = session.metadata?.invoiceId;

    if (invoiceId) {
      await db.invoice.update({
        where: { id: invoiceId },
        data: {
          status: "PAID",
          paidAt: new Date(),
          stripePaymentIntentId:
            typeof session.payment_intent === "string" ? session.payment_intent : undefined,
        },
      });
    }
  }

  return new Response("ok", { status: 200 });
}
```

## 7. Local webhook testing with the Stripe CLI

```bash
stripe login
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

Prints a `whsec_` secret — add to `.env.local` as `STRIPE_WEBHOOK_SECRET`. Keep `stripe listen` running while testing.

## 8. "Pay now" button on the client invoice page

```tsx
// src/app/portal/invoices/[id]/pay-button.tsx
"use client";

import { useState } from "react";
import { toast } from "sonner";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";

export function PayButton({ invoiceId }: { invoiceId: string }) {
  const [loading, setLoading] = useState(false);

  const createCheckout = api.invoice.createCheckoutSession.useMutation({
    onSuccess: (data) => {
      if (data.url) {
        window.location.href = data.url;
      }
    },
    onError: (err) => {
      toast.error(err.message);
      setLoading(false);
    },
  });

  return (
    <Button
      className="w-full"
      disabled={loading || createCheckout.isPending}
      onClick={() => {
        setLoading(true);
        createCheckout.mutate({ invoiceId });
      }}
    >
      {loading ? "Redirecting to Stripe..." : "Pay now"}
    </Button>
  );
}
```

Replace the disabled placeholder in the Part 6 invoice detail page with `<PayButton invoiceId={invoice.id} />`.

## 9. Test cards

Use `4242 4242 4242 4242`, any future expiry/CVC/ZIP. Stripe's Checkout page keeps you out of PCI-DSS scope.

## Checkpoint

- [ ] "Pay now" redirects to Stripe Checkout with correct line items
- [ ] Test payment redirects back to `?paid=1`
- [ ] Invoice flips to PAID within seconds (verify `stripePaymentIntentId`, `paidAt`)
- [ ] "Mark as paid manually" still works as fallback

## Troubleshooting

- **Webhook never fires locally**: confirm `stripe listen` running, secret matches
- **Signature mismatch**: wrong webhook secret for environment
- **Session created but invoice never updates**: check terminal for webhook handler errors

## Next

Continue to **Part 11: Transactional Emails with Resend**.
