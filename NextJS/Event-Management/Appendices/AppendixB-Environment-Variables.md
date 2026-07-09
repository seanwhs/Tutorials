# Appendix B: Environment Variables Reference

| Variable | Where to get it | Introduced in | Notes |
|---|---|---|---|
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | Clerk dashboard → API Keys | Part 4 | Public, safe for browser |
| `CLERK_SECRET_KEY` | Clerk dashboard → API Keys | Part 4 | Secret, server-only |
| `NEXT_PUBLIC_CLERK_SIGN_IN_URL` | You choose (`/sign-in`) | Part 4 | Sign-in page location |
| `NEXT_PUBLIC_CLERK_SIGN_UP_URL` | You choose (`/sign-up`) | Part 4 | Sign-up page location |
| `NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL` | You choose (`/dashboard`) | Part 4 | Post sign-in redirect |
| `NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL` | You choose (`/dashboard`) | Part 4 | Post sign-up redirect |
| `CLERK_WEBHOOK_SECRET` | Clerk → Webhooks → endpoint → Signing Secret | Part 7 | Different for dev (ngrok) vs production (Part 23); starts `whsec_` |
| `DATABASE_URL` | Neon dashboard → pooled connection string | Part 5 | Must include `?sslmode=require` |
| `RESEND_API_KEY` | Resend dashboard → API Keys | Part 16 | Starts `re_`; free: 100/day, 3,000/month |
| `INNGEST_SIGNING_KEY` | Inngest → Manage → Keys | Part 15/23 | Production only |
| `INNGEST_EVENT_KEY` | Inngest → Manage → Keys | Part 15/23 | Production only |

## Where these live
- **Local:** `.env.local` (gitignored by default)
- **Production:** Vercel project settings → Environment Variables (per-environment: Production/Preview/Development)

## NEXT_PUBLIC_ prefix note
Anything prefixed `NEXT_PUBLIC_` gets bundled into client JS — visible in browser dev tools. Only Clerk's publishable key should have this prefix; every other secret must stay server-only.

## Runtime prerequisite
Next.js 16 requires **Node.js 20.9+ or 22 LTS**. If `pnpm dev` fails oddly, check `node -v` before troubleshooting env vars (Part 2, Appendix E).

## Quick copy-paste template
```bash
# --- Clerk ---
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
CLERK_WEBHOOK_SECRET=

# --- Neon / Database ---
DATABASE_URL=

# --- Resend ---
RESEND_API_KEY=

# --- Inngest (production only) ---
INNGEST_SIGNING_KEY=
INNGEST_EVENT_KEY=
```

**Next: Appendix C — Database Schema Reference.**
