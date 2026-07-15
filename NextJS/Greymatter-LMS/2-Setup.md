# Part 2 — Repository & Project Foundation: Scaffolding the Greymatter LMS Monorepo

In Part 1, we mapped out the full system architecture for Greymatter LMS — five layers, one event bus in the middle, and strict boundaries between them. Now we turn that architecture into an actual folder structure, so those boundaries are enforced by the codebase itself, not just good intentions [12].

**🎯 Goal of this lesson:** Set up a working monorepo for Greymatter LMS with clearly separated packages for the app, shared types, event contracts, worker SDK, and registry client.

**🧰 Prereqs:** Node.js 20+, pnpm installed (`npm i -g pnpm`), and a terminal. No accounts needed yet — Clerk/Sanity/Neon/Inngest signups happen right before we use each one in later parts.

---

## 1. Why a monorepo?

The original architecture notes describe the frontend as more than a UI layer — it's an event emitter, a workflow initiator, and a domain gateway, but one that must stay **deliberately thin** [7]. To enforce that "thinness" in practice, we don't just write one Next.js app with everything crammed inside. We split responsibilities into separate packages, each with its own job and its own boundary.

---

## 2. Creating the monorepo

```bash
mkdir greymatter-lms && cd greymatter-lms
pnpm init
pnpm add -D turbo
```

Now create the folder structure. This mirrors the original Nexus LMS monorepo layout [8], with two changes for Greymatter LMS: `nexus-lms` → `greymatter-lms`, and `infra/supabase` → `infra/db` (since we're using Neon Postgres + Drizzle instead of Supabase):

```bash
mkdir -p apps/web
mkdir -p packages/ui packages/types packages/events packages/sdk packages/workers packages/registry
mkdir -p infra/db infra/inngest infra/sanity
mkdir -p docs/architecture docs/tutorials
```

**✅ Checkpoint:** Run `tree -L 3` (or `ls -R` on systems without `tree`) and confirm you see:

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

---

## 3. Wiring up Turborepo

Add a root `package.json` with workspaces:

```json
// package.json
{
  "name": "greymatter-lms",
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "lint": "turbo run lint"
  },
  "devDependencies": {
    "turbo": "^2.0.0"
  }
}
```

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "dev": { "cache": false, "persistent": true },
    "build": { "outputs": ["dist/**", ".next/**"] },
    "lint": {}
  }
}
```

**✅ Checkpoint:** Run `pnpm install` from the root. It should complete with no errors and create a single `node_modules` at the root shared across all packages.

---

## 4. Architectural boundaries — what each package is allowed to do

This is the part that actually enforces the layer separation from Part 1. Just like the original spec defines strict responsibilities for `apps/web` [8], we define the same rule for `apps/web` in Greymatter LMS — with Supabase swapped for Neon:

**`apps/web` (Next.js 16 LMS Core)**

Responsibilities:
* UI rendering
* Server Actions
* Authentication (via Clerk)
* Event emission
* Data fetching from Neon Postgres (via Drizzle)

Does **NOT**:
* run AI logic
* define workflows
* contain worker logic

*(boundary rules adapted from the original spec [8])*

The remaining packages each get one job:

| Package | Job | Must never contain |
|---|---|---|
| `packages/ui` | Shared Tailwind components (buttons, cards, layouts) | Business logic |
| `packages/types` | Shared TypeScript interfaces used across app + workers | Implementation code |
| `packages/events` | Event name + payload contracts (e.g. `assignment.submitted`) | Any execution logic |
| `packages/sdk` | Typed client for calling Server Actions/API from the frontend | Direct DB access |
| `packages/workers` | The Worker SDK — interfaces AI workers must implement | LMS-specific business rules |
| `packages/registry` | Typed client for querying the Sanity worker registry | Hardcoded worker lists |
| `infra/db` | Drizzle schema + Neon migrations | UI or workflow code |
| `infra/inngest` | Event functions & workflows | AI model calls themselves |
| `infra/sanity` | Worker registry schemas (Sanity Studio config) | App UI |

---

## 5. A quick sanity check with a placeholder event contract

Let's prove the boundary system works by creating our very first shared package — the one every other part of the series will depend on.

```bash
cd packages/events
pnpm init
```

```typescript
// packages/events/index.ts
export type AssignmentSubmittedEvent = {
  name: "assignment.submitted";
  data: {
    submissionId: string;
    studentId: string;
    orgId: string;
  };
};

export type GreymatterEvent = AssignmentSubmittedEvent;
```

This tiny file is doing exactly what Part 0's `emit()` demo did informally — except now it's a typed, shared contract that both `apps/web` (which emits the event) and every future worker (which reacts to it) can import, without either one knowing about the other's internals.

**✅ Checkpoint:** From the root, run:

```bash
pnpm --filter events build 2>/dev/null || echo "no build step yet — that's expected, we'll add tsconfig in Part 3"
```

You should just see confirmation the file exists and TypeScript recognizes it — no errors about missing dependencies.

---

## 6. What's next

We now have a monorepo skeleton with proper boundaries, an empty (but real) event contracts package, and Turborepo wired up to run scripts across all packages at once. In Part 3, we move into implementation — starting the first executable system, which is the Next.js App Router frontend itself [7]. We'll set up route groups, Clerk auth middleware, and our first Tailwind-styled page.

**🩹 Common confusion at this stage:** "Why is `infra/db` separate from `apps/web` if the app is the only thing that queries the database?" — Because in later parts, Inngest workers will *also* need to read/write to Neon Postgres (to persist worker results), and they should import the same schema definitions from `infra/db` rather than duplicating them inside `apps/web`. Keeping schema definitions in their own package means both the app and the orchestration layer share one source of truth.

Ready? → **Part 3: Next.js App Router Foundation for Greymatter LMS**
