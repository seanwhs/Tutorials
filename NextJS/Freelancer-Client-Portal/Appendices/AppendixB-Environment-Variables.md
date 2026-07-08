# Appendix B: Environment Variables Reference

Targets Next.js 16 (requires Node.js 20.9+, 22 LTS recommended — see Part 1 and Appendix F). Every environment variable used across the series, where it comes from, and which Part introduces it.

## Database

| Variable | Introduced | Source | Notes |
|---|---|---|---|
| DATABASE_URL | Part 3 | Neon dashboard, pooled connection string | Needed in both `.env` (for Prisma CLI) and `.env.local` (for Next.js dev server) locally; a single Vercel env var in production. |

## Clerk (auth)

| Variable | Introduced | Source | Notes |
|---|---|---|---|
| NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY | Part 2 | Clerk dashboard → API Keys | `pk_test_` in dev, `pk_live_` in a Clerk Production instance (Part 13). Public — safe to expose client-side. |
| CLERK_SECRET_KEY | Part 2 | Clerk dashboard → API Keys | `sk_test_`/`sk_live_`. Server-only, never expose to the client. |
| NEXT_PUBLIC_CLERK_SIGN_IN_URL | Part 2 | You choose | Set to `/sign-in`. |
| NEXT_PUBLIC_CLERK_SIGN_UP_URL | Part 2 | You choose | Set to `/sign-up`. |
| NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL | Part 2 | You choose | Set to `/dispatch` (role-based redirect route). |
| NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL | Part 2 | You choose | Set to `/dispatch`. |
| CLERK_WEBHOOK_SECRET | Part 5 | Clerk dashboard → Webhooks → your endpoint | Different value per Clerk instance (Development vs Production) — must be regenerated when you add the production webhook in Part 13. |

## UploadThing (files)

| Variable | Introduced | Source | Notes |
|---|---|---|---|
| UPLOADTHING_TOKEN | Part 8 | UploadThing dashboard | Same token generally works across dev and prod. |

## Resend (email)

| Variable | Introduced | Source | Notes |
|---|---|---|---|
| RESEND_API_KEY | Part 11 | Resend dashboard → API Keys | Server-only. |
| EMAIL_FROM | Part 11 | You choose, must match a verified domain | Format: `"Display Name <address@yourdomain.com>"`. Use `onboarding@resend.dev` for early local testing only (delivers to your own account email only). |
| ADMIN_NOTIFICATION_EMAIL | Part 11 | You choose | Your own inbox — where admin-facing notifications (proposal approved, invoice paid) are sent. |

## Stripe (payments)

| Variable | Introduced | Source | Notes |
|---|---|---|---|
| STRIPE_SECRET_KEY | Part 10 | Stripe dashboard → Developers → API keys | `sk_test_` while testing; swap to `sk_live_` only when ready to accept real payments (Part 13). |
| STRIPE_WEBHOOK_SECRET | Part 10 | `stripe listen` CLI output locally; Stripe dashboard webhook endpoint in production | Distinct values for local vs deployed — do not mix them up (see Part 10 and Part 13 troubleshooting sections). |

## App-wide

| Variable | Introduced | Source | Notes |
|---|---|---|---|
| NEXT_PUBLIC_APP_URL | Part 1 (declared) / Part 10 (first used) | You choose | `http://localhost:3000` locally; your Vercel URL or custom domain in production. Used to build absolute URLs in emails and Stripe success/cancel redirects. |

## Non-secret runtime requirement (not an env var, but adjacent)

| Requirement | Introduced | Notes |
|---|---|---|
| Node.js >= 20.9.0 | Part 1 | Not an environment variable — this is a runtime requirement enforced via the `engines` field in package.json (Appendix A/F). Next.js 16 will not run on Node 18. |

## Full .env.local template (copy-paste starting point)

```bash
# Database
DATABASE_URL=

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dispatch
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dispatch
CLERK_WEBHOOK_SECRET=

# UploadThing
UPLOADTHING_TOKEN=

# Resend
RESEND_API_KEY=
EMAIL_FROM=
ADMIN_NOTIFICATION_EMAIL=

# Stripe
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=

# App
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

## Security notes

- Anything prefixed `NEXT_PUBLIC_` is bundled into client-side JavaScript and is visible to anyone — never put a secret behind that prefix.
- `.env.local` and `.env` should both be in `.gitignore`. Never commit real secrets to git, even in a private repo.
- In Vercel, environment variables can be scoped per-environment (Production / Preview / Development) — use test-mode Stripe/Resend keys for Preview deployments so pull-request builds never touch production data or send real emails/charges.

---

Ready for Appendix C, D, E, or F whenever you'd like to continue.
