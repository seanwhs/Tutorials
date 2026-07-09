## AI SaaS Tutorial - Part 15: Deployment to Vercel (Free Tier)

*Next.js 16 note: Vercel's build image supports Node 20.9+/22 LTS by default, matching our Part 1 Step 0 requirement — no special Node version override should be needed, but double check Project Settings → General → Node.js Version shows 20.x or 22.x, not 18.x.*

### Goal
Deploy the full app live on Vercel's free Hobby tier, wire up production webhooks for Clerk and Stripe, and swap the embedding/chat providers from local Ollama to hosted free alternatives (since Vercel can't run Ollama for you).

### 1. Push your code to GitHub
```bash
git add -A
git commit -m "Ready for deployment"
git push
```

### 2. Import the project into Vercel
1. Go to vercel.com and sign up free with GitHub.
2. Click **Add New → Project**, select your repo.
3. Framework preset should auto-detect Next.js (16.x, Turbopack build).
4. Don't deploy yet — first add environment variables.

### 3. Add all environment variables in Vercel
Go to **Project Settings → Environment Variables** and add everything from your `.env.local`, with these production-specific changes:

```bash
NEXT_PUBLIC_APP_URL=https://your-app.vercel.app

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxx
CLERK_SECRET_KEY=sk_live_xxx
CLERK_WEBHOOK_SIGNING_SECRET=whsec_xxx

DATABASE_URL=postgresql://...

EMBEDDING_PROVIDER=hosted
EMBEDDING_BASE_URL=<your free hosted embeddings endpoint>
EMBEDDING_API_KEY=<your key>
EMBEDDING_MODEL=nomic-embed-text

GROQ_API_KEY=xxx
OPENROUTER_API_KEY=xxx
DEFAULT_CHAT_MODEL_ID=groq-llama-3.1-8b

STRIPE_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_PRO_PRICE_ID=price_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx

UPLOADTHING_TOKEN=xxx
```

**Important:** Since Vercel serverless functions don't have persistent local processes, `EMBEDDING_PROVIDER=ollama` (Part 7) won't work in production — you must use a hosted OpenAI-compatible embeddings endpoint. Keep Ollama for local development only, and switch this one env var per environment.

### 4. Deploy
Click **Deploy**. Vercel builds (using Turbopack by default under Next.js 16) and gives you a URL like `https://your-app.vercel.app`.

### 5. Register the production Clerk webhook
1. Clerk dashboard → switch to **Production** instance → Webhooks → Add Endpoint.
2. URL: `https://your-app.vercel.app/api/webhooks/clerk`.
3. Subscribe to the same events as Part 3.
4. Copy the new signing secret into Vercel's `CLERK_WEBHOOK_SIGNING_SECRET` and redeploy.

### 6. Register the production Stripe webhook
1. Stripe dashboard → Developers → Webhooks → Add endpoint.
2. URL: `https://your-app.vercel.app/api/webhooks/stripe`.
3. Select events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`.
4. Copy the signing secret into Vercel's `STRIPE_WEBHOOK_SECRET` and redeploy.

### 7. Run production database migrations
```bash
npx prisma migrate deploy
```
Run this from your local machine with `DATABASE_URL` pointed at production, or add it as a Vercel build step:
```json
"scripts": {
  "build": "prisma generate && prisma migrate deploy && next build"
}
```

### 8. Remove/guard debug routes
Delete or protect `src/app/api/debug/retrieve/route.ts` from Part 8 before going live — it currently has no auth check and would leak document content to anyone who knows the URL.

### 9. Final smoke test checklist
- Sign up a fresh user on the production URL
- Create a workspace
- Upload a document → confirm it reaches READY status
- Chat and get a grounded, streamed answer
- Upgrade to Pro via Stripe test card `4242 4242 4242 4242`
- Confirm plan limits reflect the new plan
- Hit a plan limit as a second, non-upgraded test workspace and confirm it's blocked correctly

**Checkpoint:** Your app is live, multi-tenant, billed, and answering questions grounded in real uploaded documents — entirely on free-tier infrastructure, running on Next.js 16.

**Next:** Conclusion.

---

That's all 15 parts! Want me to continue with the **Conclusion**, or jump into the **Appendices** (A: full codebase reference, B: env vars/signup guide, C: troubleshooting, D: roadmap)?
