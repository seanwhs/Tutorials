# Part 12 — Capstone: Deploying Greymatter LMS to Production 

In Part 11, we replaced every simulated worker with real AI — grading, quiz generation, tutor intervention, lesson summaries, and knowledge graph extraction — all flowing through the same secured, observable, event-driven pipeline built since Part 1 [10]. Everything so far has run locally: `localhost:3000`, `localhost:8288`, and a handful of worker processes on ports 4000–4003. This final part takes every one of those pieces and puts them on real, live infrastructure.

**🎯 Goal of this lesson:** Deploy every layer of Greymatter LMS to production — frontend, database, auth, orchestration, registry, and the entire worker fleet — mapping each deployed piece directly back onto the five-layer architecture diagram from Part 1 [12], and finish with a single audited checklist proving nothing was left running only on your laptop.

**🧰 Prereqs:** Parts 1–11 completed and working locally. You'll need production-tier accounts (or upgraded free tiers) for Vercel, Neon, Clerk, Inngest Cloud, and Sanity — each one is created just before it's needed below.

---

## 1. Deployment Architecture — mapping five layers to five deployments

The capstone architecture is organized around deployment for each layer of the stack, starting with the frontend [9]. For Greymatter LMS, this maps directly onto our five layers from Part 1 [12]:

```text
2.1 Frontend (Next.js) — Powered by Vercel
2.2 Database — Neon Postgres (replacing the original Supabase hosted components: PostgreSQL, Auth, RLS policies, Realtime subscriptions)
2.3 Auth — Clerk
2.4 Orchestration — Inngest, hosted as managed SaaS
2.5 Registry — Sanity
2.6 Workers — independently deployed services (Vercel/Railway/containers)
```
[9]

Notice this is the exact same diagram from Part 1, just with a real hosting provider written next to each layer instead of a technology name alone [12]. Nothing about the *architecture* changes here — only *where* each piece physically runs.

**✅ Checkpoint:** Before deploying anything, redraw this six-item list yourself and, next to each one, write down which local `localhost` port or process it currently corresponds to (e.g., "2.1 Frontend → currently `localhost:3000`"). This is your deployment to-do list for the rest of this part.

---

## 2. Deploying the Frontend (Next.js)

```bash
cd apps/web
pnpm add -g vercel
vercel
```

Set your environment variables in the Vercel dashboard, matching every `.env.local` value we've accumulated since Part 3 [9]:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxxxxxxx
CLERK_SECRET_KEY=sk_live_xxxxxxxx
DATABASE_URL=postgresql://user:password@your-neon-host/greymatter?sslmode=require
INNGEST_EVENT_KEY=xxxxxxxx
INNGEST_SIGNING_KEY=xxxxxxxx
WORKER_SIGNING_SECRET=xxxxxxxx
```
[9]

Notice this list is a direct audit trail of the series: `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`/`CLERK_SECRET_KEY` from Part 3's Clerk setup, `DATABASE_URL` from Part 4's Neon connection, `INNGEST_EVENT_KEY`/`INNGEST_SIGNING_KEY` from Part 5/9's orchestration and spoofed-event defenses [1], and `WORKER_SIGNING_SECRET` from Part 7's HMAC signing scheme [3]. If any of these feel unfamiliar, that's a sign to revisit the part that introduced them before continuing.

**✅ Checkpoint:** Run `vercel --prod`. Visit your deployed URL, sign in with Clerk, and confirm `/courses` renders real data from Neon Postgres [9].

---

## 3. Deploying the Database — Neon production branch

Neon's branching model lets you promote your local development database into a proper production branch without a separate migration story:

```bash
cd infra/db
# from the Neon dashboard, create a "production" branch off your existing project
npx drizzle-kit push --config drizzle.config.ts
```

Update `DATABASE_URL` in Vercel (section 2) to point at this new production branch's connection string, not your local development branch from Part 4 [6].

**✅ Checkpoint:** Open Neon's dashboard, confirm the production branch shows all six tables from Parts 4 and 10 — `courses`, `lessons`, `enrollments`, `submissions`, `worker_results`, and `workflow_logs` — with zero rows, ready for real traffic [6][11].

---

## 4. Deploying Auth — Clerk production instance

Switch your Clerk application from test/development keys to live/production keys:

* In the Clerk dashboard, create a **Production** instance (separate from the Development instance used since Part 3 [7]).
* Copy the `pk_live_...` and `sk_live_...` keys into Vercel's environment variables (section 2).
* Update your production domain in Clerk's allowed origins list.

**✅ Checkpoint:** Sign up with a brand-new account on your production URL and confirm the redirect-to-`/sign-in`-when-signed-out behavior from Part 3's middleware checkpoint still works correctly against the live Clerk instance [7].

---

## 5. Deploying Orchestration — Inngest Cloud

Since Part 5, we've relied on the local Inngest Dev Server at `localhost:8288` to simulate durable execution [5]. In production, this is replaced by Inngest Cloud, a managed SaaS version of the same engine [9]:

* Create an Inngest Cloud account and app, matching the `id: "greymatter-lms"` client from Part 5 [5].
* Copy the generated `INNGEST_EVENT_KEY` and `INNGEST_SIGNING_KEY` into Vercel's environment variables.
* Confirm your deployed `/api/inngest` route (built in Part 5, extended in Part 8) is reachable — Inngest Cloud will auto-sync your functions the same way the local dev server did [2].

**✅ Checkpoint:** In the Inngest Cloud dashboard, confirm both registered functions — `assignment-submitted` and `student-struggling` [2] — appear as synced, matching what you saw locally at `localhost:8288` throughout Parts 5–10.

---

## 6. Deploying the Registry — Sanity Studio

Sanity Studio, used locally since Part 6 to manage worker documents [4], gets deployed as its own hosted app:

```bash
cd infra/sanity
npx sanity deploy
```

Follow the prompt to choose a studio hostname. Your production Next.js app and Inngest Cloud functions should point at the same Sanity `projectId` and `dataset` (`production`) you've used since Part 6 — no new registry client code is needed, since `packages/registry` already reads from these values via environment configuration [4].

**✅ Checkpoint:** Visit your deployed Studio URL and confirm all worker documents registered since Part 6 — Grading Worker, Quiz Worker, and Summary Worker from Part 11 [10] — are visible and still correctly `enabled`.

---

## 7. Deploying the Worker Fleet

Each worker we built in Parts 7 and 11 (Grading, Quiz, Tutor, Summary) currently runs as a separate local Express process on its own port. In production, deploy each as its own small service [9]:

```bash
cd workers/grading-worker
vercel  # or railway up, or docker build/deploy
```

Repeat for `quiz-worker` and `summary-worker`. Update each worker's `endpoint` field in Sanity Studio to point at its new production URL — exactly the same edit-not-deploy pattern we proved back in Part 6, when toggling `enabled` changed behavior with zero code changes [9][4].

**✅ Checkpoint:** Submit a real assignment on your production URL, and trace the full flow: Server Action → Inngest Cloud → Sanity registry lookup → live worker calls → results written to Neon production branch → rendered back in the UI [9].

---

## 8. The full end-to-end production trace

This is the moment the entire series has been building toward. With every layer deployed, walk through Part 1's original nine-step request lifecycle [12] one final time, but on real infrastructure:

1. A student submits an assignment on your live Vercel URL
2. Clerk (production) confirms their identity and org
3. The Application Layer checks course ownership (Part 9's hardening) [1]
4. The submission is written to the Neon production branch
5. `assignment.submitted` is sent to Inngest Cloud
6. Inngest Cloud queries the deployed Sanity Studio for enabled workers
7. Each deployed worker (Grading, Quiz, Summary) is called over HTTPS, HMAC-signed both ways [3]
8. Results are written back to `worker_results` in Neon
9. The student's dashboard reloads and shows a real score, real feedback, and a real quiz

**✅ Checkpoint:** Confirm this entire chain completes with a real trace ID visible in `workflow_logs`, exactly as it did locally in Part 10 [11] — proving observability survived the move to production, not just functionality.

---

## 9. The full environment variable and account audit

Before calling this done, cross-reference every account and environment variable created since Part 3 against what's actually configured in production:

| Variable / Account | First introduced | Where it lives in production |
|---|---|---|
| Clerk publishable/secret keys | Part 3 | Vercel env vars (production instance) |
| `DATABASE_URL` | Part 4 | Vercel env vars → Neon production branch |
| `INNGEST_EVENT_KEY` / `INNGEST_SIGNING_KEY` | Part 5, hardened Part 9 | Vercel env vars → Inngest Cloud |
| Sanity `projectId` / `dataset` | Part 6 | Deployed Studio + Vercel env vars |
| `WORKER_SIGNING_SECRET` | Part 7 | Vercel + every deployed worker's own env vars |
| `OPENAI_API_KEY` | Part 11 | Each worker's own env vars (never in `apps/web`) |

**✅ Checkpoint:** Go through this table line by line in your actual Vercel, Neon, Inngest Cloud, Sanity, and worker-hosting dashboards. If any value is still only set locally in a `.env.local` file, that's a gap — production won't work correctly until it's added to the corresponding hosted dashboard.

---

## 10. What we've built, honestly assessed

Greymatter LMS is now a fully deployed, event-driven, AI-native LMS — but it's worth being honest about what this capstone is and isn't. As flagged back in Part 9, this is "a complete, correct *foundation*... not a finished enterprise product" [1]. Secret rotation, rate limiting on `/api/inngest`, and replay-attack protection remain open, named limitations [1] — real, valuable next steps for a reader who wants to keep going, but intentionally out of scope for this series.

---

## 11. Series complete

Starting from a 10-line `emit()` simulation in Part 0 [13], we've built, in order: a five-layer architecture [12], a boundary-enforcing monorepo [8], a Clerk-authenticated Next.js frontend [7], a full Neon/Drizzle schema [6], a real Inngest orchestration pipeline [5], a live Sanity worker registry [4], a signed Worker SDK [3], fan-out/fan-in/event chaining [2], a hardened threat model [1], a full observability pipeline [11], real AI-native features [10], and now, a complete production deployment [9]. Every part built on the one before it, every checkpoint was something you could verify yourself, and every AI capability was added without ever touching the LMS core — proving the philosophy this whole series started with: **events, not features** [13].

**🩹 Common confusion at this stage:** "Is this genuinely production-ready, or just production-*shaped*?" — Production-shaped, honestly. It correctly separates every layer, secures worker execution, and gives you real observability — but a genuine production launch would still need the items flagged in Part 9 (secret rotation, rate limiting, replay protection) [1], plus standard operational concerns like uptime monitoring and on-call alerting that fall outside this series' scope.

**🎓 You've completed Greymatter LMS.**
