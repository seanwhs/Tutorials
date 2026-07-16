# Part 2 — Repository & Project Foundation: Scaffolding the Greymatter LMS Monorepo 

In Part 1, we mapped out the full system architecture for Greymatter LMS — five layers, one event bus in the middle, and strict boundaries between them [12]. Now we turn that architecture into an actual folder structure, so those boundaries are enforced by the codebase itself, not just good intentions [8].

This revised version of Part 2 changes two things from the original: we scaffold a real, running Next.js app with `create-next-app` **first**, before anything else, and we use **npm** instead of pnpm throughout. The goal — a monorepo with clearly separated packages for the app, shared types, event contracts, worker SDK, and registry client — stays exactly the same [8].

**🎯 Goal of this lesson:** Get a real Next.js 16 app running on `localhost:3000`, then grow a proper monorepo around it with clearly separated packages for shared types, event contracts, the worker SDK, and the registry client.

**🧰 Prereqs:** Node.js 20+ installed. npm ships bundled with Node.js, so there's nothing extra to install. No third-party accounts needed yet — Clerk/Sanity/Neon/Inngest signups happen right before we use each one in later parts [8].

---

## 1. Why we start with a running app, not empty folders

Before touching a terminal, it's worth understanding *why* we're doing things in this order. A monorepo is just a single repository holding multiple related projects — in our case, the Next.js app, several shared packages, and some infrastructure config — that can share code without publishing anything to npm. The temptation is to build the *entire skeleton* first: every folder, every boundary, all before anything actually runs. That's technically valid, but it means your very first hands-on step produces nothing you can look at in a browser.

Instead, we'll scaffold the real, working Next.js application first — the same way virtually any Next.js project begins — get it running, and *then* add the surrounding structure (`packages/*`, `infra/*`) around that already-running app, explaining each folder's job as we add it. By the end of this part you'll have the exact same destination described in the original plan [8], just reached in a friendlier order.

---

## 2. Scaffolding the app with create-next-app

Create the project root and scaffold the Next.js app immediately:

```bash
mkdir greymatter-lms && cd greymatter-lms
npm init -y
npx create-next-app@latest apps/web --typescript --tailwind --app --src-dir --import-alias "@/*"
```

A quick breakdown for anyone newer to this: `npx` downloads and runs a package's CLI without installing it globally first — here, it runs the `create-next-app` generator once, which builds a complete, working Next.js 16 project directly inside `apps/web`. The flags configure it up front: TypeScript, Tailwind CSS, the App Router, a `src/` directory, and the `@/*` import alias — all things we'll rely on starting in Part 3 [7].

**✅ Checkpoint:** Run:

```bash
cd apps/web
npm run dev
```

Visit `localhost:3000` and confirm you see the default Next.js welcome page. This is the first real, running piece of Greymatter LMS — everything else in this part builds *around* it.

---

## 3. Why the rest of the monorepo exists

With a working app in hand, step back to the root of `greymatter-lms/` and recall Part 1's five layers [12]. `apps/web` alone can't enforce those boundaries — it needs siblings that hold the pieces that don't belong inside the frontend: shared types, event contracts, the worker SDK, and a registry client. Building these as separate folders (rather than stuffing everything into `apps/web`) is what makes the architecture's rules real instead of just documented.

From the project root, add the rest of the structure:

```bash
mkdir -p packages/ui packages/types packages/events packages/sdk packages/workers packages/registry
mkdir -p infra/db infra/inngest infra/sanity
mkdir -p docs/architecture docs/tutorials
```

The full layout should now look like this [8]:

```text
greymatter-lms/
  apps/
    web/                      # Next.js 16 LMS application (already running!)
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

*(structure adapted from the original monorepo layout [8], with `apps/web` populated from the start instead of created empty)*

A short explanation of each new folder's single job, tying back to Part 1's layers [12]:

- **`packages/types`** — shared TypeScript interfaces used by more than one layer, so the frontend and a worker never silently disagree about a field's shape.
- **`packages/events`** — the event *contracts* (name + payload shape) for things like `assignment.submitted`. This is the one Part 3 references directly when it says the client's job is "event emission" and nothing more [7].
- **`packages/sdk`** — a small client library `apps/web` imports to call into the orchestration layer, keeping raw Inngest calls out of route/component code.
- **`packages/workers`** — the Worker SDK external AI tools implement against, built out fully in Part 7 [3].
- **`packages/registry`** — the Sanity client used to query "which workers exist," built out in Part 6 [4].
- **`infra/db`**, **`infra/inngest`**, **`infra/sanity`** — infrastructure-layer code (schema, workflow functions, registry schemas) that lives outside `apps/web` on purpose, since none of it is UI.

If any of these folders are missing, re-run the corresponding `mkdir -p` command before continuing — every later part assumes this exact layout exists [8].

---

## 4. Wiring up npm workspaces

Since `apps/web` and every `packages/*` folder need to reference each other without publishing to npm, we use npm's built-in **workspaces** feature. In the root `package.json` (created by `npm init -y` in section 2), add:

```json
{
  "name": "greymatter-lms",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ]
}
```

This tells npm that any folder under `apps/` or `packages/` with its own `package.json` is a workspace member — meaning `apps/web` can `import` from `packages/events` directly, and a single `npm install` at the root resolves dependencies for every workspace at once. This is the same benefit a pnpm-based setup would give you, just using the package manager that already ships with Node.js.

**✅ Checkpoint:** From the project root, run `npm install` and confirm it completes without errors, then run `npm run dev --workspace=apps/web` and confirm `localhost:3000` still loads.

---

## 5. What's next

We now have a monorepo with a real, running Next.js app at its center, proper boundaries between the Application, Data, Orchestration, Registry, and Execution layers surrounding it, and npm workspaces wiring them together. In Part 3, we build out the first real, executable piece of the system beyond the welcome page: the Next.js 16 frontend itself — starting with route groups and Clerk authentication [7].

**🩹 Common confusion at this stage:** "Why do `packages/*` folders matter if `apps/web` doesn't import from them yet?" — Because Part 3 through Part 11 will each add real code to these folders one at a time — event contracts in Part 5 [5], the registry client in Part 6 [4], the worker SDK in Part 7 [3] — and each addition lands in a folder whose purpose you already understand, rather than an ad hoc location invented on the spot [12].

Ready? → **Part 3: Next.js App Router Foundation for Greymatter LMS**
