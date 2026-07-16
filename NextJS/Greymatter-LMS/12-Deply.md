# Part 12 — Capstone: Deploying Greymatter LMS to Production *(Expanded & Enriched)*

In Part 11, we replaced every simulated worker response since Part 5 with real, LLM-powered intelligence — grading, quiz generation, tutor intervention, summaries, and knowledge graph extraction — all flowing through the same secured, observable, event-driven pipeline built since Part 1 [10]. Everything so far has run locally. This final part takes every layer we've built and deploys it to real, live infrastructure — mapping the exact architecture diagram from Part 1 onto production, one layer at a time [9][12].

**🎯 Goal of this lesson:** Deploy the frontend, database, orchestration layer, registry, and entire worker fleet to production, wire every environment variable across every hosted dashboard, and trace one real assignment submission end-to-end on a live URL.

**🧰 Prereqs:** Parts 1–11 completed and working locally. You'll need accounts with a hosting provider for the frontend (Vercel), Neon (already in use since Part 4 [6]), Inngest Cloud, Sanity (already in use since Part 6 [4]), and a worker-hosting provider (Vercel, Railway, or containers) [9].

---

## 1. Deployment architecture — mapping five layers to five deployments

The entire capstone is organized around one idea: deploying each of Part 1's five layers independently, exactly as they were designed [9][12]:

```text
2.1 Frontend (Next.js) — Powered by Vercel
2.2 Database — Neon Postgres (replacing the original Supabase hosted components: PostgreSQL, Auth, RLS policies, Realtime subscriptions)
2.3 Auth — Clerk
2.4 Orchestration — Inngest, hosted as managed SaaS
2.5 Registry — Sanity
2.6 Workers — independently deployed services (Vercel/Railway/containers)
```

It's worth pausing on this directly: this is the **exact same diagram from Part 1** [12] — nothing about the architecture itself changes here, only *where* each piece physically runs [9]. If you find yourself needing to redesign anything to make deployment work, that's a signal a boundary was violated somewhere earlier in the series, not a normal part of deploying.

---

## 2. Deploying the frontend

`apps/web` — the Next.js 16 app scaffolded all the way back in Part 2/3 with `create-next-app` [7] — deploys to Vercel like any standard Next.js project, since none of our architectural discipline required anything nonstandard at the framework level:

```bash
cd apps/web
npx vercel
```

Follow the prompts to link the project and deploy. Vercel auto-detects the Next.js App Router setup, so no custom build configuration should be required.

**✅ Checkpoint:** Visit the deployed URL and confirm the marketing page and sign-in flow render — though don't expect the dashboard to work correctly yet, since no environment variables have been configured on Vercel at this point.

---

## 3. Wiring environment variables across every hosted dashboard

This is the step most likely to silently break a deployment, because unlike local development — where a single `.env.local` file quietly covers everything — production requires every secret to be set **in the specific dashboard of the service that needs it**, not centralized in one place:

| Variable | Introduced in | Belongs in |
|---|---|---|
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY` | Part 3 [7] | Vercel (apps/web) |
| `DATABASE_URL` | Part 4 [6] | Vercel (apps/web) + Inngest Cloud |
| `SANITY_PROJECT_ID`, `SANITY_DATASET` | Part 6 [4] | Vercel (apps/web) + Inngest Cloud |
| `WORKER_SIGNING_SECRET` | Part 7 [3] | Vercel (apps/web), Inngest Cloud, and every individual worker |
| `OPENAI_API_KEY` | Part 11 [10] | Each worker's own env vars (never in `apps/web`) |

That last row deserves emphasis: `OPENAI_API_KEY` deliberately never touches `apps/web`, in either its local `.env.local` or its Vercel dashboard — only workers are allowed to call AI models directly, a rule held consistently since Part 11 [10]. If you find `OPENAI_API_KEY` anywhere inside the frontend's environment variables, that's a boundary violation worth fixing before going further.

**✅ Checkpoint:** Go through this table line by line in your actual Vercel, Neon, Inngest Cloud, Sanity, and worker-hosting dashboards. If any value is still only set locally in a `.env.local` file, that's a gap — production won't work correctly until it's added to the corresponding hosted dashboard [9].

---

## 4. Migrating the database to production

Neon Postgres, already in use since Part 4 [6], typically separates a development branch from a production branch. Point Drizzle Kit at your production `DATABASE_URL` and push the exact same schema that's been running locally since Part 4, extended in Part 10 with `workflow_logs` [11]:

```bash
cd infra/db
DATABASE_URL="your-production-neon-url" npx drizzle-kit push
```

**✅ Checkpoint:** Open Drizzle Studio against the production database and confirm all six tables exist — `courses`, `lessons`, `enrollments`, `submissions`, `worker_results`, and `workflow_logs` — empty, but structurally identical to your local database.

---

## 5. Moving Inngest from local dev server to Inngest Cloud

Since Part 5, we've relied on `npx inngest-cli@latest dev` running locally on `localhost:8288` to simulate the durable execution engine Inngest Cloud runs in production [5]. Deploying means pointing your app at real Inngest Cloud infrastructure instead:

1. Create an Inngest Cloud account and app, matching the `id: "greymatter-lms"` used in the client since Part 5 [5].
2. Add the Inngest signing key Inngest Cloud provides to your Vercel environment variables.
3. Redeploy `apps/web` — the `/api/inngest` route built in Part 5 [5] is what Inngest Cloud calls to discover and invoke your functions, exactly as the local dev server did.

**✅ Checkpoint:** In the Inngest Cloud dashboard, confirm `assignment-submitted` and `student-struggling` — the two functions built across Parts 5 and 8 [5][2] — both appear as registered, synced functions, the same way they appeared under the "Functions" tab of the local dev server [5].

---

## 6. Redeploying the registry — Sanity

Sanity, unlike Inngest, doesn't require a "local vs. cloud" migration — it's been a real, hosted service since Part 6 [4]. The only production step here is confirming your production `SANITY_PROJECT_ID` and `SANITY_DATASET` are set in both Vercel and Inngest Cloud's environment variables, and that every worker document registered since Part 6 — Grading Worker [4], Quiz Worker [2], and the workers added in Part 11 [10] — is published, not left as a draft.

**✅ Checkpoint:** From your production deployment, trigger a call to `findWorkers("assignment.submitted")` and confirm it returns real, published worker documents — proving the registry client built in Part 6 [4] works identically against production as it did locally.

---

## 7. Deploying the worker fleet

Each worker built in Parts 7 and 11 — Grading, Quiz, Tutor, Summary — currently runs as a separate local Express process on its own port [10]. In production, deploy each as its own independent service:

```bash
cd workers/grading-worker
npx vercel  # or railway up, or docker build/deploy
```

Repeat this for `quiz-worker` and `summary-worker`. Then update each worker's `endpoint` field in Sanity Studio to point at its new production URL — the exact same edit-not-deploy pattern proven back in Part 6, when toggling `enabled` changed runtime behavior with zero code changes [4][9].

**✅ Checkpoint:** Submit a real assignment on your production URL, and trace the full flow end-to-end: Server Action → Inngest Cloud → Sanity registry lookup → live worker calls → results written to the Neon production branch → rendered back in the UI [9].

---

## 8. Confirming the whole system in production

With every layer deployed, this is the moment to prove the entire architecture — not just each piece individually. Submit an assignment on the live URL and confirm, using the `workflow_logs` table and trace IDs built in Part 10 [11]:

- The submission triggers `assignment.submitted` on Inngest Cloud, not the local dev server.
- `discover-workers` returns real, production Sanity documents.
- `execute-workers` calls real, deployed worker URLs, verified via HMAC signatures using the production `WORKER_SIGNING_SECRET`.
- A genuinely low score still triggers `student.struggling` and a real, LLM-written tutor intervention, exactly as designed in Parts 8 and 11 [2][10].
- Every step of this run appears in `workflow_logs`, queryable by trace ID, exactly as it did locally in Part 10 [11].

**✅ Checkpoint:** Query production `workflow_logs` by the trace ID of this one submission and confirm the entire chain — across Inngest Cloud, Sanity, and multiple independently deployed workers — is visible in a single, ordered query result.

---

## 9. What we've built — the full picture

Looking back across all twelve parts: we started with a 10-line `emit()` simulation demonstrating "one event, many workers" [13], designed a five-layer architecture with strict boundaries [12], scaffolded a real Next.js app and grew a monorepo around it [8][7], built a real database with manual tenant isolation standing in for Supabase's RLS [6], stood up a durable event bus [5], replaced a hardcoded worker list with a live, queryable registry [4], secured every worker call with HMAC signing [3], composed fan-out/fan-in workflows into adaptive learning loops [2], hardened the entire threat surface [1], built full tracing and observability [11], replaced every placeholder with real AI [10], and now deployed every layer to real, live infrastructure [9].

Every step along the way was something *you* built, in order, with a working checkpoint before moving to the next [13]. Greymatter LMS is now a fully deployed, secure, observable, AI-native LMS — and, crucially, adding a *thirteenth* AI capability tomorrow still requires nothing more than the six-step registration flow from Part 7 [3]: no core file touched, no redeploy of the orchestrator, no change to the architecture diagram this entire series has been building toward since Part 1 [12].

**🩹 Common confusion at this stage:** "Now that everything's deployed, do I still need the local Inngest dev server or local worker processes?" — Not for production traffic, but they remain genuinely useful for development: adding a fourteenth worker or debugging a workflow change is still faster and safer to do against `localhost:8288` first, exactly as every part since Part 5 has [5], before deploying that change to Inngest Cloud and your production worker fleet.

Congratulations — you've built Greymatter LMS end-to-end
