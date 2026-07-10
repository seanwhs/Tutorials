# Phase 6: Deploy 

<Step number="6.1" title="Understanding Vercel Hobby Tier Constraints">
<Explanation>
Before deploying, it's important to understand exactly which free-tier limits apply to InsightAgent's architecture, since a multi-step agentic loop with external API calls (Tavily, Firecrawl, and a free-tier LLM provider) is more latency-sensitive than a typical CRUD app. Vercel Hobby (free) plan constraints relevant here: Serverless Functions on the Node.js runtime have a **default max duration of 10 seconds**, but this is configurable up to **60 seconds on Hobby** via `maxDuration` (which is exactly why Step 2.6 already set `export const maxDuration = 60`) — beyond 60s requires a paid plan. Edge Functions have no such duration cap but a much stricter execution model (no arbitrary `fetch` timeout control, restricted Node APIs), which is why Step 2.6 deliberately chose `runtime = "nodejs"` rather than Edge for `/api/chat`. Hobby also caps total function invocations and bandwidth per month at generous but finite free-tier quotas, and restricts you to non-commercial personal use per Vercel's terms — appropriate for this tutorial's zero-cost learning goal.

The practical implication: our `MAX_AGENT_STEPS = 8` cap (Step 2.5) isn't just a cost/safety guard against a runaway model — it's also what keeps a full agent run (up to 8 rounds of LLM call + tool call) comfortably inside the 60-second ceiling. A single Groq call is typically sub-second; Tavily search and Firecrawl scrape calls are each usually 1-3 seconds; even a full 8-step run should complete in well under a minute in the common case. If you observe timeouts in production, the fix is lowering `MAX_AGENT_STEPS`, not raising `maxDuration` past what Hobby allows.
</Explanation>

<Code language="text" title="Hobby tier limits summary (as of this series)">
| Constraint                          | Hobby (Free) Limit         | InsightAgent's usage                  |
|--------------------------------------|-----------------------------|----------------------------------------|
| Serverless Function max duration     | 60s (configurable)          | maxDuration = 60 on /api/chat          |
| Serverless Function runtime          | Node.js or Edge              | Node.js (chosen for fetch flexibility) |
| Function invocations / month         | Generous free quota          | Well within range for personal/demo use|
| Concurrent builds                    | 1 at a time                  | Fine for a solo tutorial project       |
| Custom domains                       | Supported (with subdomain)   | Optional — *.vercel.app works free     |
| Environment variables                | Unlimited, per-environment   | All Phase 1 .env.example keys          |
</Code>

<Explanation>
Keep in mind free-tier limits and exact numbers are controlled by Vercel and can change — always check Vercel's current pricing page before a real deployment. The architectural decisions in this series (Node runtime, bounded step count, generous-but-bounded `maxDuration`) were made specifically to stay comfortably within Hobby's constraints as of this writing, not to just barely fit them.
</Explanation>
</Step>

---

**Step 6.2: Deploying to Vercel & Configuring Environment Variables**.

---

<Step number="6.2" title="Deploying to Vercel & Configuring Environment Variables">
<Explanation>
Deployment itself is simple — Vercel auto-detects Next.js and handles the Turbopack production build — but getting every environment variable correctly set is where most first deployments break. Every single key from the consolidated `.env.example` (Step 1.2) must be added to the Vercel Project's Environment Variables settings before the first deploy, because `resolveModel` (Step 2.1) and `db/index.ts` (Step 1.5) both throw hard errors at request time if their required env vars are missing — better a clear local error than a silent misconfiguration in prod, but that means production truly will not function without them. We push the repo to GitHub (or GitLab/Bitbucket) first, since Vercel's standard flow deploys from a connected Git repository and gives you automatic preview deployments on every pull request for free.
</Explanation>

<Code language="bash" title="terminal: push to GitHub">
git init
git add .
git commit -m "Initial InsightAgent commit"
git branch -M main
git remote add origin https://github.com/<your-username>/insight-agent.git
git push -u origin main
</Code>

<Code language="text" title="Vercel setup steps">
1. Go to vercel.com -> Add New Project -> Import your insight-agent GitHub repo.
2. Framework Preset: Next.js (auto-detected). Build Command / Output: leave defaults.
3. Before the first deploy, open "Environment Variables" and add every key below,
   applied to Production, Preview, and Development environments:

   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
   CLERK_SECRET_KEY
   NEXT_PUBLIC_CLERK_SIGN_IN_URL
   NEXT_PUBLIC_CLERK_SIGN_UP_URL
   NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL
   NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL
   DATABASE_URL
   GROQ_API_KEY
   TOGETHER_API_KEY
   HUGGINGFACE_API_KEY
   DEFAULT_MODEL_ID
   TAVILY_API_KEY
   FIRECRAWL_API_KEY
   NEXT_PUBLIC_APP_URL          (set to your production URL, e.g. https://insight-agent.vercel.app)

4. Click Deploy. Vercel runs `npm install` then `next build` (Turbopack) automatically.
5. Once deployed, go to your Clerk dashboard -> configure allowed redirect URLs /
   your production domain so sign-in/sign-up work outside localhost.
</Code>

<Explanation>
A subtlety worth flagging: `NEXT_PUBLIC_APP_URL` must be updated to your real Vercel URL (or custom domain) post-deploy — it's not auto-detected, and while it's not directly consumed by any code in this series yet, it's reserved specifically for constructing absolute URLs in future extensions (e.g. email links, OG image generation) and should be kept accurate from day one to avoid a forgotten stale-localhost bug later. Also double check Clerk's dashboard: by default Clerk restricts sign-in to explicitly allowed origins, so a fresh production domain must be added there or every auth flow will fail immediately after deploy despite the app itself working.
</Explanation>
</Step>

---
**Step 6.3: Running the Production Database Migration**.

---

<Step number="6.3" title="Running the Production Database Migration">
<Explanation>
Deploying the app code does not automatically apply Drizzle migrations to your Neon database — that's a deliberate separation of concerns (you don't want a bad migration silently running on every deploy) and must be done explicitly. Because Neon is a separate managed service from Vercel, the same `DATABASE_URL` you configured as a Vercel environment variable (Step 6.2) is also what you use locally to run `drizzle-kit migrate` against production. The cleanest approach for a solo/tutorial project is to keep one Neon database for local dev and reuse it in production by pointing both `.env.local` and Vercel's env vars at the same `DATABASE_URL` — acceptable here since this is a personal project, but worth flagging that a real multi-developer team would provision separate dev/staging/production Neon branches (Neon's free tier supports database branching) rather than sharing one.
</Explanation>

<Code language="bash" title="terminal: apply migrations to production Neon DB">
# Ensure .env.local points at the SAME DATABASE_URL configured in Vercel,
# or temporarily export it inline if using separate databases:
# export DATABASE_URL="postgresql://...same-url-as-vercel..."

npm run db:generate   # only if schema.ts changed since the last migration
npm run db:migrate    # applies pending migrations to whichever DATABASE_URL is active
</Code>

<Explanation>
If you forget this step, the app will deploy successfully and even load, but the very first chat message will fail with a Postgres "relation does not exist" error inside the `/api/chat` route's `db.insert(conversations, ...)` call — a common first-deploy gotcha. A good verification habit: run `npm run db:studio` pointed at the production `DATABASE_URL` right after migrating, and confirm the `conversations`, `messages`, and `tool_events` tables exist and are empty, before testing the live app end-to-end.
</Explanation>
</Step>

---

**Step 6.4: Production Readiness Checklist & Phase 6 Wrap-up**. 

---

<Step number="6.4" title="Production Readiness Checklist & Phase 6 Wrap-up">
<Explanation>
Before considering the deployment "done," walk through this checklist — it consolidates decisions made across all six phases into a single pre-launch verification pass, catching the most common first-deploy failure modes for exactly this kind of agentic app.
</Explanation>

<Code language="text" title="Pre-launch checklist">
[ ] All 13 env vars from .env.example are set in Vercel (Production + Preview envs)
[ ] DEFAULT_MODEL_ID matches an actual `value` in MODEL_REGISTRY (src/lib/agent/models.ts)
[ ] Neon DATABASE_URL migrated: conversations / messages / tool_events tables exist
[ ] Clerk dashboard: production domain added to allowed origins / redirect URLs
[ ] Clerk dashboard: sign-in/sign-up URLs match NEXT_PUBLIC_CLERK_SIGN_IN_URL / SIGN_UP_URL
[ ] Tavily account: confirm free-tier quota (1,000 searches/mo) is active, not exhausted
[ ] Firecrawl account: confirm free-tier quota (500 credits/mo) is active, not exhausted
[ ] Groq / Together / HF: confirm each API key is valid and its free tier is active
[ ] /api/chat route: confirm `runtime = "nodejs"` and `maxDuration = 60` are present
[ ] Manually test: sign up, ask a question, confirm ThoughtDashboard + ReportView render
[ ] Manually test: refresh the page mid-conversation, confirm sidebar + resume works
[ ] Manually test: switch models mid-conversation, confirm next message uses new model
[ ] Run `npm run test` locally one final time before/after deploy — full suite should pass
</Code>

<Explanation>
Two items deserve special attention because they fail silently rather than loudly: free-tier quota exhaustion (Tavily/Firecrawl/model providers) surfaces as a generic tool-call error inside `ThoughtDashboard` rather than an obvious "quota exceeded" banner anywhere in the UI, so if research runs start failing with no code changes, check provider dashboards for quota usage first; and Clerk's allowed-origins misconfiguration, which typically manifests as sign-in silently redirecting back to the sign-in page in a loop rather than showing a clear error.
</Explanation>

<Explanation>
**Phase 6 — and the core InsightAgent build — is now complete.** Recapping the full journey: Phase 1 established a zero-cost-tier stack (Next.js 16, Tailwind v4, Clerk, Neon+Drizzle) with a consolidated environment configuration. Phase 2 built the agentic core: a provider-agnostic model registry spanning three free LLM providers, two research tools (Tavily search, Firecrawl scrape), a citation-disciplined system prompt, and a step-capped `streamText` agent loop. Phase 3 built a fully streaming UI with live tool-call visualization and a structured report renderer. Phase 4 made every research session durable and resumable via Postgres. Phase 5 covered the entire agentic core with deterministic, zero-cost automated tests using `MockLanguageModelV2`. Phase 6 deployed the whole system to Vercel's free Hobby tier with a concrete understanding of its constraints.

The Conclusion and Appendices (full codebase reference, package.json, config files, and additional resources/FAQ) remain to consolidate this series into a single reference — available next.
</Explanation>
</Step>
