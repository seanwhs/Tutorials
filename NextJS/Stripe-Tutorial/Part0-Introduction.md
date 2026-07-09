# Part 0: Introduction & Architecture

Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. What we're building

**Acme Shop** — a small storefront that teaches you every common Stripe integration pattern using Next.js 16 and Tailwind CSS:

1. A product catalog page with a **Buy Now** button per product → one-time payment via **Stripe Checkout**.
2. A **cart** you can add multiple products to, then check out all at once (multiple line items in one Checkout Session).
3. A **webhook** endpoint that Stripe calls when a payment succeeds, so we can reliably record the order in our own database (never trust the client-side redirect alone!).
4. An **order history** page.
5. A **Subscriptions** flow — recurring billing — plus a **Customer Portal** link so customers can update payment methods or cancel, without you building any UI for that yourself.
6. Free local testing the whole way, using Stripe's **test mode** and the **Stripe CLI**.
7. Free deployment to **Vercel**.

## 2. Why this stack

| Tool | Why |
|---|---|
| **Next.js 16 (App Router)** | Server and client code in one project; Route Handlers give us a simple place to call the Stripe API and receive webhooks. |
| **Tailwind CSS v4** | Fast, utility-first styling with no separate CSS files to maintain. |
| **Stripe** | The industry-standard payments platform. Test mode is 100% free and behaves identically to live mode. Handles PCI compliance for you via Stripe Checkout (hosted payment page) — you never touch raw card numbers. |
| **Stripe CLI** | Forwards Stripe webhook events to your local dev server for free, so you can build and test webhooks without deploying anything. |
| **Prisma + SQLite** | A zero-config, file-based database perfect for a tutorial — no external database account needed. Prisma gives us type-safe queries. |
| **Vercel** | Free ("Hobby") tier deployment, zero-config for Next.js. |

## 3. Two core Stripe concepts you must understand first

### a) Products & Prices
In Stripe, a **Product** (e.g. "Acme Mug") is separate from a **Price** (e.g. "$12.00 USD, one-time" or "$9.00 USD, billed monthly"). One Product can have multiple Prices (e.g. monthly vs yearly). We'll create these either in the Stripe Dashboard or on the fly via the API — we'll do dashboard-first for the catalog, then API-created ad-hoc prices for the cart.

### b) Checkout Sessions
A **Checkout Session** is a short-lived object you create server-side via the Stripe SDK, describing what's being purchased (one or more `line_items`, each referencing a Price and quantity). Stripe returns a `url` — you redirect the customer there. Stripe hosts the entire payment form (card fields, Apple Pay, etc.) on a page you don't have to build or secure yourself. After payment, Stripe redirects the customer back to your `success_url` or `cancel_url`.

```
Your Next.js App                     Stripe
─────────────────                    ──────
1. User clicks "Buy Now"
2. POST /api/checkout  ──────────►   Create Checkout Session
                        ◄──────────  { url: "https://checkout.stripe.com/..." }
3. Redirect browser to that url
                                      User enters card, pays
                                      Stripe redirects browser to
                        ◄──────────  your success_url
4. (separately, async)               Stripe sends webhook event
   POST /api/webhooks/stripe ◄────── "checkout.session.completed"
5. Verify signature, save Order to DB
```

**Critical lesson this tutorial drills in:** never mark an order "paid" just because the browser landed on your success page — that redirect can be faked or interrupted. The **webhook** is the only trustworthy source of truth, because it's a server-to-server call authenticated with a signing secret.

## 4. High-level architecture

```
┌───────────────────────────────────────────────────────────┐
│                     Next.js 16 App                        │
│                                                             │
│  /app/page.tsx                  (product catalog)          │
│  /app/cart/page.tsx              (cart UI, client state)    │
│  /app/success/page.tsx           (post-payment confirmation)│
│  /app/cancel/page.tsx            (payment cancelled)        │
│  /app/orders/page.tsx            (order history, from DB)   │
│  /app/account/page.tsx           (manage subscription)       │
│                                                             │
│  /app/api/checkout/route.ts        → creates Checkout Session (one-time)
│  /app/api/checkout-cart/route.ts   → creates Checkout Session (multi-item)
│  /app/api/checkout-subscription/route.ts → subscription mode
│  /app/api/portal/route.ts          → creates Customer Portal session
│  /app/api/webhooks/stripe/route.ts → receives & verifies Stripe events
│                                                             │
│  /lib/stripe.ts     (Stripe SDK client, server-only)         │
│  /lib/db.ts         (Prisma client)                          │
│  /prisma/schema.prisma (Order, OrderItem models)             │
└───────────────────────────────────────────────────────────┘
                         │              ▲
                         ▼              │ webhook (signed)
                  ┌─────────────┐  ┌────┴─────┐
                  │   Stripe    │  │  Stripe   │
                  │  Checkout   │  │  Webhook  │
                  └─────────────┘  └───────────┘
                         │
                         ▼
                 ┌───────────────┐
                 │ SQLite (local │
                 │  dev.db file) │
                 └───────────────┘
```

## 5. What "done" looks like

By the end of Part 14 you will have a deployed app where a visitor can:
1. Browse a product catalog and buy a single item with a Stripe test card.
2. Add multiple products to a cart and check out in one payment.
3. Land on a success page confirming their order.
4. See that order appear in an Order History page (populated via a verified webhook, not just the redirect).
5. Subscribe to a recurring plan, and later cancel it themselves via the Stripe-hosted Customer Portal.
6. All of this running live on Vercel's free tier, using Stripe test mode (so it costs nothing and no real cards are charged).

## 6. How this tutorial is organized

Each part follows the same shape:
1. **Concept** — what we're adding and why, in plain English.
2. **Code** — file-by-file, with the exact file path shown as the first line of each code block.
3. **Checkpoint** — a manual test to run before moving to the next part.

Copy files exactly as shown unless a step explicitly says to edit an existing file.

## Next

Continue to **Part 1: Dev Environment & Project Setup**.
