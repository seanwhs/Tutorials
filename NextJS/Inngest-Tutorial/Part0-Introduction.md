# Part 0: Introduction and What Is Inngest

## Welcome

This is a complete, beginner-friendly, code-heavy tutorial series that teaches you **Inngest** — a platform for running reliable background jobs, scheduled tasks, and event-driven workflows — by building a real application with **Next.js 16**.

By the end of this series you will have built and deployed **TaskFlow**, a small team task-management app with:

- Sign-up/sign-in via Clerk
- Projects and tasks stored in Postgres (Neon) via Prisma
- Instant "welcome" and "task assigned" emails sent via a background job (not blocking the request)
- A durable, multi-step onboarding workflow (with sleeps/delays) that nurtures new users over several days
- Scheduled/cron jobs (daily digest emails, overdue-task sweeps)
- Fan-out jobs (notify every project member when a task changes)
- Automatic retries and idempotency so jobs never double-send or silently fail
- Rate limiting, concurrency control, and throttling on expensive jobs
- Human-in-the-loop workflows that wait for an event (approve/reject a task) with a timeout
- Full local dev workflow using the Inngest Dev Server, then production deployment on Vercel with Inngest Cloud

You do **not** need any prior background-jobs experience. You do need basic familiarity with JavaScript/TypeScript and React. Next.js experience helps but isn't required — Part 1 gets you from zero to a running project.

## Why Inngest?

Most web apps eventually need to do something *outside* the request/response cycle: send an email, generate a report, call a slow third-party API, run something on a schedule, or coordinate multi-step processes with retries. The naive approach — doing this work inline in an API route — is fragile:

- If the server crashes mid-way, the work is lost.
- Slow work makes users wait, or times out entirely on serverless platforms.
- There's no way to schedule things ("run this in 3 days") without extra infrastructure.
- Retrying failures usually means writing your own retry/backoff logic.
- Fan-out (do this for every user in a list) means writing your own queue.

Inngest solves all of this **without you running a queue, a worker process, or a scheduler**. You write plain TypeScript functions. Inngest handles invoking them reliably — retrying failed steps, remembering progress across restarts, sleeping for days without holding a server open, and scaling fan-out automatically. It works great with serverless platforms like Vercel because your functions are just HTTP endpoints Inngest calls; there's no long-running worker to manage.

## Core concepts you'll learn (don't worry, each is explained hands-on later)

- **Events** — JSON payloads that describe "something happened" (e.g. `app/user.created`). Functions subscribe to events.
- **Functions** — durable TypeScript functions triggered by an event or a schedule (cron).
- **Steps** (`step.run`, `step.sleep`, `step.sleepUntil`, `step.waitForEvent`, `step.sendEvent`) — the building blocks inside a function. Each step's result is checkpointed, so retries only re-run failed steps, not the whole function.
- **Retries** — automatic, configurable retry attempts with backoff for failed steps.
- **Concurrency, rate limiting, throttling, and idempotency keys** — controls to keep jobs well-behaved.
- **The Inngest Dev Server** — a local UI (like a mini queue + dashboard) you run on your machine to see and debug every event and function run in real time.
- **The `serve` handler** — the one API route (`/api/inngest`) that exposes all your functions to Inngest.

## Tech stack (all free tiers)

- **Next.js 16** (App Router, Turbopack default, Node.js 20.9+ or 22 LTS)
- **Inngest** (free tier: generous monthly step/run allowance, no credit card required for dev)
- **Clerk** (auth, free tier up to 10k MAU)
- **Neon** (serverless Postgres, free tier) + **Prisma** (ORM)
- **Resend** (email sending, free tier: 100 emails/day / 3,000/month)
- **Tailwind CSS v4** (CSS-first config)
- **Vercel** (free Hobby tier deployment)

## Series structure

**Part 1** — Project setup: Next.js 16 + Tailwind v4 scaffold, installing Inngest, running your first "Hello World" function against the local Inngest Dev Server.

**Part 2** — Understanding events, functions, and the `serve` API route in depth. Multiple functions, multiple triggers.

**Part 3** — Building the real app's foundation: Clerk auth, Neon + Prisma schema (Users, Projects, Tasks), Clerk webhook syncing users into your database (your first real event-driven Inngest function).

**Part 4** — Steps deep dive: `step.run` for checkpointing, sending a real "welcome email" via Resend triggered from the Clerk webhook function.

**Part 5** — Building Projects and Tasks CRUD UI (Server Actions) — the app surface that will trigger our background jobs.

**Part 6** — Fan-out: notify every project member when a task is created/assigned, using `step.sendEvent` and multiple functions subscribed to the same event.

**Part 7** — Durable multi-step workflows with delays: a multi-day onboarding email drip using `step.sleep` / `step.sleepUntil`.

**Part 8** — Scheduled functions (cron): a daily digest email and an overdue-task sweep.

**Part 9** — Human-in-the-loop workflows: `step.waitForEvent` for a task-approval flow with a timeout fallback.

**Part 10** — Reliability controls: retries and error handling, idempotency keys, concurrency limits, rate limiting, and throttling.

**Part 11** — Observability and testing: reading the Inngest Dev Server / Cloud dashboard, structured logging, and writing tests for Inngest functions.

**Part 12** — Deploying to Vercel and connecting production Inngest Cloud (signing keys, event keys, syncing your app).

**Conclusion** — Recap and where to go next.

## Appendices

- **Appendix A** — Full codebase reference (every final file, in one place)
- **Appendix B** — Environment variables reference
- **Appendix C** — Inngest functions reference (every function: trigger, steps, purpose)
- **Appendix D** — Inngest concepts cheat sheet (events vs. functions vs. steps, all step types, config options)
- **Appendix E** — Troubleshooting guide

## How to use this series

Follow the parts in order — each builds on the previous part's code. Every part ends with a "Checkpoint" so you know you're on track before moving on.

Let's get started in Part 1.
