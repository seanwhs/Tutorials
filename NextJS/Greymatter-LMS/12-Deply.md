# Part 12 — Capstone: Deploying Greymatter LMS to Production

In Part 11, we replaced every simulated worker with real AI calls — a working Quiz Worker, Tutor AI intervention, and lesson summaries, all flowing through the same secured, observable, event-driven pipeline built since Part 1. Now we bring everything together and deploy Greymatter LMS to production.

**🎯 Goal of this lesson:** Deploy the Next.js frontend, the database, the orchestration layer, the registry, and the worker fleet — and map every piece of our architecture diagram from Part 1 onto real, live infrastructure.

**🧰 Prereqs:** Part 11 completed (all workers built and running locally). You'll need a Vercel account for the frontend deploy.

---

## 1. Deployment Architecture

The capstone architecture is organized around deployment for each layer of the stack, starting with the frontend [9]. For Greymatter LMS, we map this directly onto our five layers from Part 1:

```text
2.1 Frontend (Next.js) — Powered by Next.js [9]
2.2 Database — Neon Postgres (replacing the original Supabase hosted components: PostgreSQL, Auth, RLS policies, Realtime subscriptions [9])
2.3 Auth — Clerk
2.4 Orchestration — Inngest, hosted as managed SaaS [9]
2.5 Registry — Sanity
2.6 Workers — independently deployed services (Vercel/Railway/containers)
```

Notice item 2.2 — the original capstone blueprint lists PostgreSQL, Auth, RLS policies, and Realtime subscriptions as hosted components bundled together [9]. Since Greymatter LMS uses Neon instead, we only get the first item for free; Auth is Clerk, RLS is our manual `orgId` checks (Part 4/9), and we never used Realtime subscriptions in this series — Inngest's event bus replaced that need entirely.

---

## 2. Deploying the Frontend (Next.js)

```bash
cd apps/web
pnpm add -g vercel
vercel
```

Set your environment variables in the Vercel dashboard, matching every `.env.local` value we've accumulated since Part 3:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxxxxxxx
CLERK_SECRET_KEY=sk_live_xxxxxxxx
DATABASE_URL=postgresql://user:password@your-neon-host/greymatter?sslmode=require
INNGEST_EVENT_KEY=xxxxxxxx
INNGEST_SIGNING_KEY=xxxxxxxx
WORKER_SIGNING_SECRET=xxxxxxxx
```

**✅ Checkpoint:** Run `vercel --prod`. Visit your deployed URL, sign in with Clerk, and confirm `/courses` renders real data from Neon Postgres.

---

## 3. Deploying the Database (Neon)

Neon projects are already cloud-hosted from Part 4, so "deploying" here means promoting your development branch to production:

```bash
# Neon supports branching — create a production branch separate from dev
neon branches create --name production
```

Update your Vercel `DATABASE_URL` to point at the `production` branch connection string, then run migrations against it:

```bash
DATABASE_URL="<production-connection-string>" npx drizzle-kit push
```

**✅ Checkpoint:** Confirm all five tables from Part 4 (`courses`, `lessons`, `enrollments`, `submissions`, `worker_results`) plus `workflow_logs` from Part 10 exist in the production branch via Drizzle Studio.

---

## 4. Deploying Orchestration (Inngest) and Registry (Sanity)

Inngest is hosted as managed SaaS [9] — connect your production `/api/inngest` route in the Inngest Cloud dashboard, and it will automatically pick up every function we've built since Part 5 (`assignmentSubmitted`, `studentStruggling`, plus any Summary Worker functions from Part 11).

For Sanity, deploy Studio so your registry is editable in production, not just locally:

```bash
cd infra/sanity
pnpm dlx sanity@latest deploy
```

**✅ Checkpoint:** Visit your deployed Sanity Studio URL, confirm all worker documents from Part 6 (Grading Worker, Quiz Worker, Tutor Worker, Summary Worker) are present with production `enabled` flags and live endpoint URLs.

---

## 5. Deploying the Worker Fleet

Each worker we built in Parts 7 and 11 (Grading, Quiz, Tutor, Summary) currently runs as a separate local Express process on its own port. In production, deploy each as its own small service:

```bash
cd workers/grading-worker
vercel  # or railway up, or docker build/deploy
```

Update each worker's `endpoint` field in Sanity Studio to point at its new production URL, exactly the same edit-not-deploy pattern we proved back in Part 6.

**✅ Checkpoint:** Submit a real assignment on your production URL, and trace the full flow: Server Action → Inngest Cloud → Sanity registry lookup → live worker calls → results written to Neon production branch → rendered back in the UI.

---

## 6. The full production picture

Putting every part of this series together, here is Greymatter LMS's complete production architecture:

```text
Users
↓
Next.js 16 (Vercel) — Client + Application Layer, Clerk auth
↓
Neon Postgres (production branch) — Data Layer
↓
Inngest Cloud — Orchestration Layer
↓
Sanity (deployed Studio) — Registry Layer
↓
Worker Fleet (Vercel/Railway) — Execution Layer
↓
Neon Postgres — Results written back
↓
Next.js 16 — Reads results, renders to student
```

Every arrow here is the same contract we designed in Part 1 — no layer reaches past the one directly below it, and every AI capability we shipped in Part 11 required zero changes to the LMS core, confirming the promise made all the way back in Part 5: new AI feature = new worker, no core changes [5].

---

## 7. What we built, end to end

Across this series, Greymatter LMS went from a 10-line `emit()` simulation (Part 0) to a fully deployed, event-driven, AI-native LMS with:

* A monorepo with enforced architectural boundaries (Part 2)
* Clerk-authenticated Next.js 16 frontend that never runs AI logic itself (Part 3)
* Neon Postgres schema with manual tenant isolation replacing Supabase RLS (Part 4)
* A real Inngest orchestration pipeline (Part 5)
* A dynamic Sanity-based worker registry — add a feature by inserting a document, not shipping code (Part 6)
* A standardized, HMAC-secured Worker SDK (Part 7)
* Fan-out/fan-in execution and chained adaptive learning loops (Part 8)
* A hardened orchestrator layer defending against spoofed events and forged responses (Part 9)
* Full observability — trace IDs, execution timelines, persistent logs, cost tracking (Part 10)
* Real AI-native features: grading, quiz generation, tutor intervention, summaries (Part 11)
* A fully deployed production system (Part 12 — this lesson)

**🩹 Common confusion at this stage:** "Is this production-ready as-is?" — Architecturally, yes, but recall the honest limitations we flagged in Part 9: secret rotation, rate limiting, and replay-attack protection are still open items for a real-world launch. Treat this capstone as a complete, correct *foundation* — the kind of system a small team could confidently build on, not a finished enterprise product.

This completes the Greymatter LMS tutorial series. From here, the natural next steps are the extension exercises we flagged along the way — a knowledge graph visualization UI (Part 11), a plagiarism detector worker (Part 7's ecosystem list), or a second grading engine running in parallel for A/B comparison, exactly as the registry pattern was designed to support [4].
