## AI SaaS Tutorial - Appendix B: Environment Variables and Free-Tier Signup Guide

### Full .env.local reference (development)
```bash
DATABASE_URL=postgresql://user:password@host/db?sslmode=require

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/workspaces
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/workspaces
CLERK_WEBHOOK_SIGNING_SECRET=whsec_xxx

NEXT_PUBLIC_APP_URL=http://localhost:3000

UPLOADTHING_TOKEN=xxx

EMBEDDING_PROVIDER=ollama
EMBEDDING_BASE_URL=http://localhost:11434/v1
EMBEDDING_API_KEY=ollama
EMBEDDING_MODEL=nomic-embed-text

CHAT_BASE_URL=http://localhost:11434/v1
CHAT_API_KEY=ollama
CHAT_MODEL=llama3.1
GROQ_API_KEY=xxx
OPENROUTER_API_KEY=xxx
DEFAULT_CHAT_MODEL_ID=ollama-llama3.1

STRIPE_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_PRO_PRICE_ID=price_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

### Runtime prerequisite (Next.js 16)
Node.js 20.9+ or 22 LTS is required to run this project at all — Next.js 16 will not start on Node 18. Run `node -v` before starting Part 1 and again before deploying (Part 15 checks the Vercel project's configured Node version too).

### Where each variable comes from and free-tier signup steps

**1. Neon (Postgres + pgvector) — `DATABASE_URL`**
- Sign up free at neon.tech
- Create a project, copy the connection string
- Run: `CREATE EXTENSION IF NOT EXISTS vector;` and `CREATE EXTENSION IF NOT EXISTS pgcrypto;` in the Neon SQL editor
- Free tier: generous storage and compute for small projects, serverless (scales to zero when idle)

**2. Clerk (Auth + Organizations) — `CLERK_*` variables**
- Sign up free at clerk.com
- Create an application, enable Organizations under application settings
- Copy publishable/secret keys from the dashboard
- Set up a webhook endpoint (Part 3) and copy its signing secret
- Free tier: generous monthly active user allowance, no credit card required
- Note: Clerk's current SDK version ships async `auth()`/`clerkMiddleware` APIs that this series relies on throughout — make sure you install the latest `@clerk/nextjs`, not an older major version

**3. UploadThing (file storage) — `UPLOADTHING_TOKEN`**
- Sign up free at uploadthing.com
- Create an app, copy your token
- Free tier: several GB of storage/bandwidth per month at time of writing

**4. Ollama (local embeddings + chat, optional but recommended for dev) — `EMBEDDING_*`/`CHAT_*` when using "ollama"**
- Install free from ollama.com
- Run: `ollama pull nomic-embed-text`
- Run: `ollama pull llama3.1`
- No API key or account needed — fully local and free
- Not usable in Vercel's serverless production environment (Part 15) — dev only

**5. Groq (free hosted chat inference) — `GROQ_API_KEY`**
- Sign up free at console.groq.com
- Create an API key under API Keys
- Free tier: generous requests-per-minute allowance at time of writing, no credit card required

**6. OpenRouter (free hosted chat inference, alternate) — `OPENROUTER_API_KEY`**
- Sign up free at openrouter.ai
- Create an API key
- Filter models by `max_price=0` to see current free models; update `src/lib/ai/models.ts` if the exact free model slug has changed since this series was written

**7. Stripe (billing) — `STRIPE_*` variables**
- Sign up free at stripe.com, stay in Test mode
- Create a recurring price for your Pro plan, copy its Price ID
- Copy your test-mode secret/publishable keys from Developers → API keys
- Install the Stripe CLI (free) for local webhook forwarding: `stripe listen --forward-to localhost:3000/api/webhooks/stripe`
- Test card for Checkout: `4242 4242 4242 4242`, any future expiry, any CVC

### Production-only changes (Part 15)
- `NEXT_PUBLIC_APP_URL` becomes your real Vercel URL
- Clerk keys switch to a Production instance (`pk_live_`/`sk_live_`) with a new webhook + signing secret
- `EMBEDDING_PROVIDER` switches from "ollama" to "hosted" with a real hosted embeddings endpoint, since Vercel cannot run Ollama
- `DEFAULT_CHAT_MODEL_ID` switches away from an `ollama-*` id to a `groq-*` or `openrouter-*` id
- Stripe webhook gets a new production endpoint + signing secret (test-mode keys are fine to keep for a demo app)
- Confirm Vercel's Project Settings → Node.js Version is set to 20.x or 22.x, matching the Next.js 16 minimum

