# Appendix B: Environment Variables Reference

Complete list of every environment variable used across the TaskFlow project, where to get each one, and which part introduces it. Add all of these to `.env.local` for local dev, and to your Vercel project settings for production (Part 12).

| Variable | Where to get it | Introduced | Notes |
|---|---|---|---|
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk dashboard → API Keys | Part 3 | Public, safe to expose client-side |
| `CLERK_SECRET_KEY` | Clerk dashboard → API Keys | Part 3 | Server-only secret |
| `CLERK_WEBHOOK_SECRET` | Clerk dashboard → Webhooks → your endpoint | Part 3 | Per-endpoint secret; local (ngrok) and production endpoints each have their own |
| `DATABASE_URL` | Neon dashboard → Connection Details (use the pooled connection string) | Part 3 | Postgres connection string used by Prisma |
| `RESEND_API_KEY` | Resend dashboard → API Keys | Part 4 | Free tier: 100 emails/day, 3,000/month |
| `INNGEST_EVENT_KEY` | Inngest Cloud dashboard → Manage → Keys | Part 12 | Only required in production; local Dev Server needs no key |
| `INNGEST_SIGNING_KEY` | Inngest Cloud dashboard → Manage → Keys | Part 12 | Only required in production; authenticates Inngest Cloud's calls to your `/api/inngest` route |

## Local dev vs. production

Locally, you do **not** need `INNGEST_EVENT_KEY` or `INNGEST_SIGNING_KEY` at all — the Inngest Dev Server (`npx inngest-cli@latest dev`) talks to your app with no authentication required, which is why Part 1 through Part 11 never mention these two variables. They only become necessary once you connect to Inngest Cloud in Part 12.

## Example `.env.local` (development)

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx
CLERK_WEBHOOK_SECRET=whsec_xxx

DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require

RESEND_API_KEY=re_xxx
```

## Example production environment variables (Vercel project settings)

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxx
CLERK_SECRET_KEY=sk_live_xxx
CLERK_WEBHOOK_SECRET=whsec_yyy   (the production endpoint's own secret, different from local)

DATABASE_URL=postgresql://user:pass@ep-xxx-pooler.region.aws.neon.tech/neondb?sslmode=require

RESEND_API_KEY=re_xxx

INNGEST_EVENT_KEY=xxx
INNGEST_SIGNING_KEY=signkey-xxx
```

---

Next up is **Appendix C: Inngest Functions Reference** — want me to bring that up?
