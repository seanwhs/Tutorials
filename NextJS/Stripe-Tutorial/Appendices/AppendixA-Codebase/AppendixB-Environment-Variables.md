# Appendix B: Environment Variables Reference

Index: "Stripe Tutorial - INDEX (Start Here)".

Full list of every environment variable used across this series, where it's introduced, and what it's for.

| Variable | Introduced | Server or client? | Purpose |
|---|---|---|---|
| `STRIPE_SECRET_KEY` | Part 2 | Server only | Authenticates all server-side Stripe API calls (creating Checkout Sessions, retrieving sessions, listing line items, billing portal sessions). Starts with `sk_test_` in this tutorial. Never expose to the browser. |
| `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` | Part 2 | Client-safe | Stripe's publishable key. Not actually used by any code in this tutorial (since we use hosted Checkout, not Stripe.js/Elements), but included as standard practice and needed if you extend to embedded Elements (Appendix E). Starts with `pk_test_`. |
| `STRIPE_WEBHOOK_SECRET` | Part 9 (local), Part 14 (production) | Server only | Used to verify that incoming webhook requests genuinely came from Stripe (`stripe.webhooks.constructEvent`). Starts with `whsec_`. Differs between your local Stripe CLI session and your production Dashboard-registered endpoint — never reuse one for the other. |
| `NEXT_PUBLIC_APP_URL` | Part 1 | Client-safe | Base URL used to build `success_url`, `cancel_url`, and the Customer Portal `return_url`. `http://localhost:3000` locally, your real Vercel URL in production. |
| `DATABASE_URL` | Part 7 | Server only | Prisma's connection string. `file:./dev.db` for local SQLite in this tutorial. If you upgrade to Postgres (see Appendix E), this becomes a real `postgresql://...` connection string. |

## Where each variable lives

- **Local development:** `.env.local` in the project root (git-ignored). Prisma CLI commands (like `migrate dev`) read from `.env` specifically — for this tutorial we keep `DATABASE_URL` consistent in both files, or you can consolidate into a single `.env` file if you prefer (Next.js reads `.env`, `.env.local`, `.env.development`, etc. — see Next.js docs on env var loading order if customizing this).
- **Production (Vercel):** Project Settings → Environment Variables. Set for the "Production" environment (and "Preview"/"Development" too if you want preview deployments to work identically).

## Security reminders

- Anything prefixed `NEXT_PUBLIC_` is bundled into client-side JavaScript and visible to anyone — only ever put genuinely public values there.
- Anything without that prefix stays server-only, but only if you never import the file that reads it from a `"use client"` component.
- Rotate any key immediately if you ever suspect it was exposed (Stripe Dashboard → Developers → API keys → roll key).

## Next

Continue to **Appendix C: Stripe Test Card & Test Data Reference**.
