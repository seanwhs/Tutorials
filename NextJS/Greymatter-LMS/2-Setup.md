# Part 2 — Repository & Project Foundation: Scaffolding the Greymatter LMS Monorepo 

In Part 1, we mapped out the full system architecture for Greymatter LMS — five layers, one event bus in the middle, and strict boundaries between them [12]. Now we turn that architecture into an actual folder structure, so those boundaries are enforced by the codebase itself, not just good intentions [8].

**🎯 Goal of this lesson:** Set up a working monorepo for Greymatter LMS with clearly separated packages for the app, shared types, event contracts, worker SDK, and registry client.

**🧰 Prereqs:** Node.js 20+, pnpm installed (`npm i -g pnpm`), and a terminal. No accounts needed yet — Clerk/Sanity/Neon/Inngest signups happen right before we use each one in later parts [8].

---

## 1. Why a monorepo, not separate repos

Since Greymatter LMS deliberately separates the Application Layer from the Orchestration, Registry, and Execution layers [12], those boundaries need to be *visible* in the codebase, not just remembered. A monorepo lets us put every layer's code side by side — `apps/web` for the frontend, `packages/*` for shared contracts, `infra/*` for orchestration and registry config — while still keeping each one independently buildable. If the Application Layer ever tries to import something it shouldn't (like worker execution logic), that becomes an obvious, catchable mistake rather than a subtle architectural violation.

---

## 2. Creating the monorepo

Start by initializing the repo and adding Turborepo, which lets us run scripts (`dev`, `build`, `lint`) across every package at once:

```bash
mkdir greymatter-lms && cd greymatter-lms
pnpm init
pnpm add -D turbo
```

Now create the folder structure. This mirrors the original Nexus LMS monorepo layout, with two changes made specifically for Greymatter LMS: `nexus-lms` → `greymatter-lms`, and `infra/supabase` → `infra/db`, since we're using Neon Postgres + Drizzle instead of Supabase [8]:

```bash
mkdir -p apps/web
mkdir -p packages/ui packages/types packages/events packages/sdk packages/workers packages/registry
mkdir -p infra/db infra/inngest infra/sanity
mkdir -p docs/architecture docs/tutorials
```

**✅ Checkpoint:** Run `tree -L 3` (or `ls -R` on systems without `tree`) and confirm you see the following structure:

```text
greymatter-lms/
apps/
  web/                      # Next.js 16 LMS application
packages/
  ui/                       # Shared UI components (Tailwind)
  types/                    # Shared TypeScript types
  events/                   # Event contracts (VERY IMPORTANT)
  sdk/                      # LMS client SDK
  workers/                  # Worker SDK (for external AI tools)
  registry/                 # Sanity registry client
infra/
  db/                       # Neon Postgres schema + Drizzle migrations
  inngest/                  # event functions/workflows
  sanity/                   # worker registry schemas
docs/
  architecture/
  tutorials/
```

*(structure adapted from the original monorepo layout [8])*

If any of these folders are missing, go back and re-run the corresponding `mkdir -p` command before continuing — every later part assumes this exact layout exists.

---

## 3. What each package is for, and which layer it belongs to

Mapping this folder structure back onto Part 1's five layers makes it clear why each package exists [12]:

| Folder | Layer it serves | Why it's separate |
|---|---|---|
| `apps/web` | Client + Application | The only place UI renders and Server Actions run |
| `packages/events` | Orchestration (contract) | Shared event shape — imported by both the frontend and Inngest functions later, so neither one "owns" it |
| `packages/types` | Cross-cutting | Shared TypeScript types used across the app and workers |
| `packages/sdk` | Application | A client SDK for interacting with Greymatter LMS |
| `packages/workers` | Execution (contract) | The `WorkerInput`/`WorkerOutput` shape and signing helpers every worker implements, starting in Part 7 |
| `packages/registry` | Registry | The client used to query the Sanity worker registry, starting in Part 6 |
| `infra/db` | Data | Drizzle schema, shared by both the app and any Inngest functions that persist worker results |
| `infra/inngest` | Orchestration | The actual event functions/workflows, built starting in Part 5 |
| `infra/sanity` | Registry | Worker registry schemas, built starting in Part 6 |

**🩹 Common confusion at this stage:** "Why is `infra/db` separate from `apps/web` if the app is the only thing querying the database right now?" — Because starting in Part 5, Inngest workers will *also* need to read/write to Neon Postgres to persist worker results. Keeping schema definitions in their own package means both the Application Layer and the Orchestration Layer share one source of truth, instead of each maintaining its own copy that can drift out of sync [8].

---

## 4. Wiring up Turborepo

Add a `turbo.json` at the root so scripts can run across every package at once:

```json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": { "dependsOn": ["^build"] },
    "dev": { "cache": false, "persistent": true },
    "lint": {}
  }
}
```

Add matching scripts to the root `package.json`:

```json
{
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build"
  }
}
```

**✅ Checkpoint:** Run `pnpm build` from the repo root. Since every package is currently empty, this should complete instantly with no errors — it's only proving that Turborepo can discover and traverse every package we just created. If it fails, double check that each folder from section 2 contains at least an empty `package.json` (run `pnpm init` inside any folder that's missing one).

---

## 5. What's next

We now have a monorepo skeleton with proper boundaries between the Application, Data, Orchestration, Registry, and Execution layers, and Turborepo wired up to run scripts across all of them at once. In Part 3, we build the first real, executable piece of the system: the Next.js 16 frontend itself — starting with route groups and Clerk authentication [7].

**🩹 Common confusion at this stage:** "This part didn't create any real, running code — was that intentional?" — Yes. Part 2 is entirely structural: it exists so that when Part 3 through Part 11 each add real code to `apps/web`, `packages/*`, or `infra/*`, that code lands in a folder whose purpose and boundary you already understand, rather than an ad hoc location invented on the spot [12].

Ready? → **Part 3: Next.js App Router Foundation for Greymatter LMS**
