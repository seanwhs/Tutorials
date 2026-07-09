# Appendix E: Further Resources & Next Steps

Index: "Stripe Tutorial - INDEX (Start Here)".

## Official documentation

- Stripe Checkout overview: https://docs.stripe.com/payments/checkout
- Stripe Checkout Sessions API reference: https://docs.stripe.com/api/checkout/sessions
- Stripe webhooks guide: https://docs.stripe.com/webhooks
- Stripe testing reference (cards, etc.): https://docs.stripe.com/testing
- Stripe CLI docs: https://docs.stripe.com/stripe-cli
- Stripe Billing / Subscriptions: https://docs.stripe.com/billing/subscriptions/overview
- Stripe Customer Portal: https://docs.stripe.com/customer-management
- Stripe Node.js SDK reference: https://github.com/stripe/stripe-node
- Next.js 16 docs: https://nextjs.org/docs
- Next.js Route Handlers: https://nextjs.org/docs/app/building-your-application/routing/route-handlers
- Tailwind CSS v4 docs: https://tailwindcss.com/docs
- Prisma docs: https://www.prisma.io/docs
- Vercel deployment docs: https://vercel.com/docs

## Expanding this project — suggested next steps, roughly in order of effort

### Small additions
1. **Promotion codes** — add `allow_promotion_codes: true` to any `stripe.checkout.sessions.create()` call; create codes under Dashboard → Product catalog → Coupons.
2. **Shipping address collection** — add `shipping_address_collection: { allowed_countries: ["US", "CA"] }` to a Checkout Session for physical products.
3. **Automatic tax** — enable Stripe Tax in the Dashboard and add `automatic_tax: { enabled: true }` to Checkout Session creation (has its own pricing beyond a certain volume — check current Stripe Tax pricing before enabling in a real project).

### Medium additions
4. **Real authentication** — add a free-tier auth solution so `/orders` and `/account` are scoped per logged-in user, and store `stripeCustomerId` directly on the user's own record (removing the "last order" workaround from Part 12).
5. **Hosted Postgres** — swap SQLite for a free-tier Postgres provider (Neon or Supabase) for durable production data; change `provider = "sqlite"` to `provider = "postgresql"` in `prisma/schema.prisma`, update `DATABASE_URL`, re-run migrations.
6. **Handle more webhook events** — `invoice.paid`, `invoice.payment_failed`, `customer.subscription.trial_will_end` for a more complete subscription lifecycle (dunning emails, trial reminders).
7. **Email receipts** — trigger a transactional email from inside the webhook handler once an order is recorded.

### Larger additions
8. **Embedded Stripe Elements** instead of hosted Checkout — for a fully custom on-page payment form. Requires `@stripe/stripe-js` + `@stripe/react-stripe-js`, and switching from Checkout Sessions to a Payment Intents-based flow (`stripe.paymentIntents.create` + `<PaymentElement>`). Useful if you want zero redirect away from your own domain, at the cost of more integration work and slightly more PCI-compliance surface area (still minimal, since Stripe Elements still handles raw card data in an iframe).
9. **Multiple pricing tiers / metered billing** — for a SaaS-style product, add several recurring Prices per plan (monthly/yearly) and/or usage-based billing via Stripe's metered billing APIs.
10. **Connect / marketplace payments** — if you ever need to split payments between multiple sellers, look into Stripe Connect, a materially different (and more complex) integration than everything covered in this series.

## Recap: what NOT to change without care

- Never accept a raw price/amount from client-side input — always resolve it server-side from your own catalog by internal ID (Parts 3, 6, 11).
- Never mark something "paid" from the success page redirect alone — only from a verified webhook event (Part 8).
- Always keep webhook handling idempotent (Part 8's `stripeCheckoutId` uniqueness check) since Stripe can and will redeliver events.
- Always keep `STRIPE_SECRET_KEY` out of any `"use client"` file and out of git.

---

🎉 **This concludes the entire Acme Shop / Stripe + Next.js 16 + Tailwind CSS tutorial series** — all 16 main notes (Parts 0–15) plus 9 appendix notes (Appendix A across 5 notes, plus B, C, D, and this one, E) have now been reviewed in full, start to finish.

You've walked through: project setup → Stripe SDK → one-time checkout → success/cancel handling → a cart → multi-item checkout → a database → verified/idempotent webhooks → local webhook testing → order history → subscriptions → the Customer Portal → production polish → free deployment → conclusion → the full codebase reference → env vars → test cards → troubleshooting → further resources.

