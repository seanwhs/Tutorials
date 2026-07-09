# Part 15: Conclusion & Next Steps

Previous: Part 14 (Deploying to Vercel for Free). Index: "Stripe Tutorial - INDEX (Start Here)".

## What you built

Starting from an empty folder, you built **Acme Shop** — a real, deployed storefront with working payments:

- **Next.js 16 App Router** foundation with **Tailwind CSS v4**, using Turbopack and async dynamic APIs throughout.
- A **product catalog** with one-time purchases via **Stripe Checkout**.
- A **multi-item cart** (client-side state + localStorage) that checks out multiple line items in a single Checkout Session.
- Styled **success** and **cancel** pages that read real Checkout Session data server-side.
- A **Prisma + SQLite** database recording orders.
- A **verified, idempotent Stripe webhook** — the single source of truth for "was this actually paid," tested locally with the **Stripe CLI**.
- An **Order History** page reading from the database.
- **Subscriptions** via Checkout in subscription mode, plus a **Stripe Customer Portal** integration so customers can self-manage or cancel — with zero custom billing UI built by you.
- Production-hardening: centralized env validation, typed Stripe error handling, and a security checklist.
- A **free deployment to Vercel**, with a real production Stripe webhook endpoint.

## Key lessons to carry forward

1. **Checkout Sessions, not raw card handling.** Stripe Checkout keeps you out of PCI-compliance scope entirely — you never touch a card number.
2. **Webhooks are the source of truth.** The success page redirect is for UX only; only a verified webhook event should ever mark something "paid" in your own database.
3. **Idempotency matters.** Webhook deliveries can repeat — always guard against creating duplicate records.
4. **Never trust client-submitted prices.** Always resolve Price IDs from your own server-side catalog, keyed by an internal product/plan ID the client sends — never accept an amount or Price ID directly from the browser.
5. **Test mode is a complete, free sandbox.** You can build and fully verify an entire payments flow — one-time and recurring — without ever touching real money or a live key.

## Suggested next steps (Phase 2 ideas)

- **Add real authentication** (e.g. a free-tier auth provider) so `/orders` and `/account` are scoped to the signed-in user instead of showing all orders — and store `stripeCustomerId` directly on the user record rather than inferring it from the last order.
- **Move to hosted Postgres** (Neon or Supabase free tier) for durable production data instead of SQLite.
- **Handle `invoice.paid` / `invoice.payment_failed` webhook events** to track ongoing subscription renewals and dunning (failed-payment retries), not just the initial signup.
- **Add embedded Stripe Elements** as an alternative to hosted Checkout if you want a fully custom on-page payment form (requires `@stripe/stripe-js` + `@stripe/react-stripe-js` and a Payment Intents-based flow instead of/alongside Checkout Sessions).
- **Add email receipts** with a free-tier transactional email provider, triggered from the webhook handler.
- **Add coupons/promotion codes** via Stripe Checkout's built-in `allow_promotion_codes: true` option — a one-line addition to any `checkout.sessions.create` call.
- **Add usage-based/metered billing** for a SaaS-style product instead of flat subscription pricing.

## Reference appendices

- **Appendix A** — Full codebase reference
- **Appendix B** — Environment variables reference
- **Appendix C** — Stripe test card & test data reference
- **Appendix D** — Troubleshooting guide
- **Appendix E** — Further resources & next steps (expanded)

Thanks for building along with this series — you now have a solid, reusable mental model for integrating Stripe into any Next.js app.

---

That's the end of the main series (Parts 0–15)! Want to continue on to the appendices — starting with **Appendix A (1 of 5): Full Codebase Reference**?
