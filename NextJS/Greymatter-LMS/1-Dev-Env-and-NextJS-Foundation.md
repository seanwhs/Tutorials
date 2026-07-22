[GENERATED: Part 0 — What We Are Building]
[STARTING: Part 1 — Development Environment and Next.js 16 Foundation]

---

# Part 1 — Development Environment and Next.js 16 Foundation

## The goal

By the end of this part, you will have an empty folder transformed into a running Next.js 16 web application — complete with TypeScript, Tailwind CSS, a linter, a health-check API endpoint, a first Server Component and a first Client Component, a clean Git history, and a passing production build. Nothing in this part talks to Sanity, Neon, Clerk, or Inngest yet — we are pouring the foundation slab before any walls go up.

## Why it exists

Every part after this one assumes a working project already exists. If the foundation is shaky — wrong Node version, missing TypeScript config, a `.env` file accidentally committed to Git — every later part becomes harder to debug, because you won't know if a new error is caused by *today's* code or by a foundational crack from Part 1. We're going to be deliberately thorough here so that never happens.

## The data flow

There's no application data flowing yet — but there *is* a request flow worth understanding immediately, because it's the skeleton every future feature hangs on:

```text
Browser requests a URL
        │
        ▼
Next.js routes the request based on the app/ folder structure
        │
        ├── If it matches a page   → a React Server Component renders HTML
        └── If it matches an API   → a Route Handler runs and returns JSON
```

Two ideas above are worth defining immediately, because you'll see them in every part from here on:

- **Route Handler**: a file that responds to raw HTTP requests (like `GET` or `POST`) and returns data — usually JSON — instead of a webpage. Think of it as a hotel's back-office phone line: you don't see a room, you just get an answer to a specific question ("is the pool open?").
- **Server Component**: a React component that runs *on the server* and sends already-rendered HTML to the browser, rather than shipping JavaScript that builds the page inside the browser. Think of it as a chef plating a finished dish in the kitchen (the server) versus handing you raw ingredients and a recipe card to cook yourself at the table (the older "client-rendered" approach).

---

## Step 1 — Installing Node.js and Git

### The Target
Two command-line tools installed and verified on your machine: **Node.js** (the JavaScript runtime that runs our server code outside a browser) and **Git** (the version-control tool that tracks every change we make).

### The Concept
Node.js is like the engine block of a car — Next.js, npm, and every package we install are the car's body, wheels, and dashboard, but none of it moves without the engine underneath. Git is the car's black-box flight recorder: it doesn't make the car go, but it means you can always answer "what changed, and when, and can I go back?"

### The Implementation

Install **Node.js 20 LTS or newer** (Next.js 16 requires a modern Node version) from [nodejs.org](https://nodejs.org), choosing the "LTS" (Long-Term Support) build for your operating system. Install **Git** from [git-scm.com](https://git-scm.com) if it isn't already on your machine (macOS and most Linux distributions usually ship with it).

### The Verification

Open a terminal and run:

```bash
node -v
# expected output: v20.x.x or higher

npm -v
# expected output: 10.x.x or higher

git --version
# expected output: git version 2.x.x or higher
```

If any command says "command not found," the installation didn't complete or your terminal needs to be restarted (close and reopen it — this refreshes the terminal's `PATH`, the list of folders it searches for programs).

---

## Step 2 — Scaffolding the Next.js 16 project

### The Target
A new Next.js 16 project named `greymatter-lms`, with TypeScript, Tailwind CSS, ESLint, and the App Router all pre-configured by the official scaffolding tool.

### The Concept
`create-next-app` is a scaffolding tool — like ordering a pre-poured concrete foundation instead of mixing cement by hand. It asks a series of questions, then generates a working starter project so we don't have to hand-wire build tooling (bundlers, compilers) from scratch.

### The Implementation

Navigate to the folder where you keep your projects, then run:

```bash
npx create-next-app@latest greymatter-lms
```

`create-next-app` will ask several questions. Answer exactly as follows — these answers determine the project structure every future part relies on:

```text
Would you like to use TypeScript?          › Yes
Would you like to use ESLint?              › Yes
Would you like to use Tailwind CSS?        › Yes
Would you like your code inside a `src/` directory? › No
Would you like to use App Router?          › Yes
Would you like to use Turbopack for `next dev`? › Yes
Would you like to customize the import alias (@/* by default)? › No
```

**Why "No" to `src/`?** Our final folder structure (from Part 0) places `app/`, `components/`, `db/`, `inngest/`, `lib/`, and `sanity/` all as *siblings* at the project root. This is a common, flat convention for full-stack Next.js apps that touch many different backend concerns — it keeps every subsystem equally visible instead of nesting everything inside `src/`.

Once scaffolding finishes, move into the project:

```bash
cd greymatter-lms
```

### The Verification

Start the development server:

```bash
npm run dev
```

Open **http://localhost:3000** in your browser. You should see the default Next.js welcome page. Stop the server with `Ctrl+C` once confirmed — we're about to replace this page anyway.

---

## Step 3 — Building the target folder structure

### The Target
The full top-level folder layout from Part 0's architecture diagram, created now so every later part has a home to write files into.

### The Concept
We're building empty rooms before we furnish them. An empty, well-labeled folder (`db/`, `inngest/`, `sanity/`) is a promise to your future self about where things belong, so you're never guessing in Part 8 whether a database helper goes in `lib/` or `db/`.

### The Implementation

From the project root, create the remaining top-level folders. Git doesn't track empty folders, so we drop a placeholder `.gitkeep` file in each one:

```bash
mkdir -p db/schema db/migrations
mkdir -p inngest/functions
mkdir -p lib/auth lib/validation
mkdir -p sanity/schema-types sanity/lib
mkdir -p tests/unit tests/e2e
mkdir -p components/ui

touch db/schema/.gitkeep
touch db/migrations/.gitkeep
touch inngest/functions/.gitkeep
touch lib/auth/.gitkeep
touch lib/validation/.gitkeep
touch sanity/schema-types/.gitkeep
touch sanity/lib/.gitkeep
touch tests/unit/.gitkeep
touch tests/e2e/.gitkeep
touch components/ui/.gitkeep
```

> **Windows Command Prompt users:** `mkdir -p` and `touch` are Unix-style commands. If you're on Windows without WSL (Windows Subsystem for Linux) or Git Bash, use PowerShell instead:
> ```powershell
> New-Item -ItemType Directory -Force -Path db/schema, db/migrations, inngest/functions, lib/auth, lib/validation, sanity/schema-types, sanity/lib, tests/unit, tests/e2e, components/ui
> New-Item -ItemType File -Force -Path db/schema/.gitkeep, db/migrations/.gitkeep, inngest/functions/.gitkeep, lib/auth/.gitkeep, lib/validation/.gitkeep, sanity/schema-types/.gitkeep, sanity/lib/.gitkeep, tests/unit/.gitkeep, tests/e2e/.gitkeep, components/ui/.gitkeep
> ```
> Git Bash on Windows behaves like the Unix commands above and is recommended for the rest of this series, since every terminal command we write will use Unix-style syntax.

### The Verification

Confirm the structure exists:

```bash
find . -maxdepth 2 -type d -not -path "./node_modules*" -not -path "./.git*" -not -path "./.next*"
```

Expected output (order may vary):

```text
.
./app
./components
./components/ui
./db
./db/schema
./db/migrations
./inngest
./inngest/functions
./lib
./lib/auth
./lib/validation
./sanity
./sanity/schema-types
./sanity/lib
./public
./tests
./tests/unit
./tests/e2e
```

This now matches the Part 0 architecture diagram exactly. Every future part will tell you precisely which of these folders a new file belongs in.

---

## Step 4 — Configuring TypeScript path aliases

### The Target
Updating `tsconfig.json` so we can import files using a clean `@/` prefix (e.g., `@/lib/auth/get-current-user`) instead of fragile relative paths like `../../../lib/auth/get-current-user`.

### The Concept
Imagine two apartment buildings on the same street. Without a clear addressing system, giving directions from one to another means counting doors ("go left, then two doors down, then up a floor"). A path alias is like assigning every building a fixed street address instead — no matter which apartment you start in, `@/lib/auth` always means the same place. This especially matters in a project like ours, where a deeply nested file (e.g., `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx`) would otherwise need imports like `../../../../../lib/auth/require-user`.

### The Implementation

`create-next-app` already configured a `@/*` alias for you when you declined to customize it. Open `tsconfig.json` at the project root and confirm it looks like this:

#### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": [
    "next-env.d.ts",
    "**/*.ts",
    "**/*.tsx",
    ".next/types/**/*.ts"
  ],
  "exclude": ["node_modules"]
}
```

**Code walkthrough:**

- `"strict": true` — enables TypeScript's full set of strictness checks (no implicit `any`, strict null checks, etc.). We want this **on** from day one. Turning strict mode on later, once hundreds of files exist, is far more painful than starting with it.
- `"paths": { "@/*": ["./*"] }` — this is the actual alias definition. It tells TypeScript "whenever you see an import starting with `@/`, resolve it starting from the project root." So `@/lib/auth/require-user` resolves to `./lib/auth/require-user.ts`.
- `"moduleResolution": "bundler"` — tells TypeScript to resolve modules the way modern bundlers (like the one inside Next.js) do, which correctly supports the newer `exports` field many packages (including some we'll add later) rely on.

### The Verification

We'll fully verify this once we write our first cross-folder import in Step 7. For now, confirm the file saved without a JSON syntax error by running:

```bash
npx tsc --noEmit
```

Expected output: no errors (an empty, silent success — TypeScript only prints something when there's a problem).

---

## Step 5 — Environment variable management

### The Target
An `.env.example` file documenting every environment variable GreyMatter LMS will ever need, and a git-ignored `.env.local` file holding your actual (currently empty) local values.

### The Concept
Think of environment variables as sticky notes taped *inside* a building, never printed on the blueprint that gets mailed to the public. The blueprint (`.env.example`, committed to Git) lists what notes should exist and roughly what they're for, but never the actual secret values. The real sticky notes (`.env.local`, never committed) live only on your machine, and later, only inside your hosting provider's dashboard. If a real secret ever ends up in Git history, it must be treated as compromised — even deleting the file later doesn't erase it from history.

### The Implementation

We don't have real values yet (Sanity, Neon, Clerk, and Inngest don't exist until later parts), but we establish the *pattern* now, and add one real variable: `NEXT_PUBLIC_APP_URL`, which our health-check route will use.

#### `.env.example`

```bash
# ── App ──────────────────────────────────────────────────────────
# The public base URL of the app. Used for links in emails, metadata, etc.
NEXT_PUBLIC_APP_URL=http://localhost:3000

# ── Sanity (added in Part 3) ─────────────────────────────────────
# NEXT_PUBLIC_SANITY_PROJECT_ID=
# NEXT_PUBLIC_SANITY_DATASET=
# SANITY_API_TOKEN=

# ── Neon / Drizzle (added in Part 5) ──────────────────────────────
# DATABASE_URL=

# ── Clerk (added in Part 6) ───────────────────────────────────────
# NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
# CLERK_SECRET_KEY=
# CLERK_WEBHOOK_SIGNING_SECRET=

# ── Inngest (added in Part 12) ─────────────────────────────────────
# INNGEST_EVENT_KEY=
# INNGEST_SIGNING_KEY=
```

Now create your real local file by copying it:

```bash
cp .env.example .env.local
```

`.env.local` will already contain `NEXT_PUBLIC_APP_URL=http://localhost:3000` — leave it as is for now.

**Why the `NEXT_PUBLIC_` prefix on that one variable?** Next.js only exposes environment variables to browser-side JavaScript if their name starts with `NEXT_PUBLIC_`. Anything without that prefix (like the future `CLERK_SECRET_KEY`) stays server-only and is never sent to the browser. This is a critical security boundary we will rely on constantly — get in the habit now of asking "does the browser actually need this value?" before ever adding the `NEXT_PUBLIC_` prefix to a new variable.

### The Verification

Confirm `create-next-app` already added environment files to `.gitignore` (it does, by default). Open `.gitignore` and confirm these lines exist:

```gitignore
# env files
.env*.local
```

Then confirm Git agrees `.env.local` is ignored:

```bash
git status
```

`.env.local` should **not** appear in the output. If it does, add this line manually to `.gitignore`:

```gitignore
.env.local
```

---

## Step 6 — Installing and configuring path-aware ESLint and formatting

### The Target
A working lint command (`npm run lint`) using the ESLint configuration `create-next-app` already scaffolded, plus a `typecheck` script we add ourselves.

### The Concept
A linter is like a proofreader who checks your writing for grammar mistakes *before* it goes to the editor — catching problems (unused variables, unreachable code) automatically, consistently, and instantly, rather than relying on a human to notice them during code review.

### The Implementation

`create-next-app` already installed ESLint and generated a config. Open `package.json` and add a `typecheck` script alongside the existing ones:

#### `package.json`

```json
{
  "name": "greymatter-lms",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "eslint": "^9",
    "eslint-config-next": "^16.0.0",
    "tailwindcss": "^4",
    "@tailwindcss/postcss": "^4"
  }
}
```

> **Note:** exact version numbers in your generated `package.json` may differ slightly depending on what's current when you scaffold the project — that's expected and fine. The important additions here are the `typecheck` script and confirming `lint` exists.

### The Verification

```bash
npm run lint
```

Expected output: `✔ No ESLint warnings or errors` (or similar).

```bash
npm run typecheck
```

Expected output: silent success, no errors printed.

---

## Step 7 — Building the health-check Route Handler

### The Target
A `GET /api/health` endpoint returning a small JSON payload, confirming our server-side request pipeline works end-to-end — and giving us our first real use of the `@/` path alias.

### The Concept
Before wiring an app to three external services (Sanity, Neon, Clerk), production systems almost always include a "health check" — a tiny endpoint whose entire job is answering "am I alive?" Think of it as a hospital's heartbeat monitor: it doesn't diagnose the patient, it just confirms there's a pulse. Later, our hosting provider and monitoring tools will ping this exact URL to know if the app is up.

### The Implementation

First, a tiny helper module to prove the `@/` alias works across folders:

#### `lib/get-app-info.ts`

```ts
// A tiny, dependency-free helper. Its only job right now is to prove that
// files in lib/ can be imported cleanly via the "@/" path alias from
// anywhere else in the project — including deeply nested route files.
export function getAppInfo() {
  return {
    name: "GreyMatter LMS",
    // process.env is how Node.js reads environment variables at runtime.
    // We fall back to "development" so this never crashes if the variable
    // is missing — a defensive habit worth building early.
    environment: process.env.NODE_ENV ?? "development",
    timestamp: new Date().toISOString(),
  };
}
```

Now the actual Route Handler. In the App Router, a file named `route.ts` inside `app/api/health/` automatically becomes the handler for `GET /api/health` — there's no manual route registration step, the *folder path itself* is the URL.

#### `app/api/health/route.ts`

```ts
import { NextResponse } from "next/server";
import { getAppInfo } from "@/lib/get-app-info";

// Exporting a function named after an HTTP verb (GET, POST, PUT, DELETE...)
// is how the App Router knows which requests this file should handle.
// This file only exports GET, so a POST to this same URL will automatically
// receive a 405 Method Not Allowed — we don't have to write that check ourselves.
export async function GET() {
  const info = getAppInfo();

  // NextResponse.json() is a small convenience wrapper: it serializes our
  // object to a JSON string AND sets the "Content-Type: application/json"
  // response header for us, so clients (browsers, curl, future tests)
  // know how to parse the body correctly.
  return NextResponse.json({
    status: "ok",
    ...info,
  });
}
```

**Code walkthrough:**

- The **file path is the route**. `app/api/health/route.ts` → `GET /api/health`. This is the App Router's core convention: routing is derived from the filesystem, not from a separate router configuration file listing every path by hand.
- `import { getAppInfo } from "@/lib/get-app-info";` — this is our first real test of the path alias from Step 4. Without it, this import would have needed to be `../../../lib/get-app-info` from this nested location.
- We deliberately return a small, safe payload — no secrets, no internal error details. Health-check endpoints are usually public, so we treat them the same way we'd treat a note taped to a building's front door: informative, but not sensitive.

### The Verification

Start the dev server:

```bash
npm run dev
```

In a **second** terminal window, request the endpoint with `curl` (a command-line tool for making HTTP requests):

```bash
curl http://localhost:3000/api/health
```

Expected output (timestamp will differ):

```json
{"status":"ok","name":"GreyMatter LMS","environment":"development","timestamp":"2025-01-15T10:32:00.000Z"}
```

You can also simply visit `http://localhost:3000/api/health` directly in your browser — Route Handlers respond to normal browser navigation for `GET` requests too, since a browser address bar visit *is* a `GET` request.

---

## Step 8 — Understanding and building our first Server and Client Components

### The Target
Replacing the default Next.js landing page with a minimal GreyMatter homepage, composed of one Server Component (the page itself) and one Client Component (an interactive "Ping Health Check" button) — so you can see, concretely, the difference between the two component types before we build anything more complex.

### The Concept
Recall the chef analogy from earlier: a **Server Component** is a dish plated in the kitchen and sent out already finished — the browser just displays it, shipping zero extra JavaScript for that specific piece. A **Client Component** is more like a tableside flambé — something has to happen live, in front of the customer (in the browser), because it reacts to a button click or keystroke *after* the page has already loaded. In Next.js's App Router, **every component is a Server Component by default**. You only get a Client Component when you explicitly opt in by adding the `"use client"` directive at the very top of the file. This default-to-server behavior is a deliberate design decision: it means an app tends to ship less JavaScript to the browser unless a piece of the UI genuinely needs interactivity.

We need a Client Component here because clicking a button and updating on-screen state in response is inherently something that happens live, in the browser, after the initial page load — a Server Component cannot do that, because it has already finished its job (producing HTML) before the browser ever displays the page.

### The Implementation

First, the interactive piece — our Client Component:

#### `components/health-check-button.tsx`

```tsx
"use client"; // This directive is required at the very top of the file, before
// any other code (even comments that aren't directly above it can break this
// in some tooling, so always keep it as line 1). It tells Next.js's bundler:
// "ship this component's JavaScript to the browser, because it needs to run
// there" — as opposed to Server Components, which never ship their own JS.

import { useState } from "react";

export function HealthCheckButton() {
  // useState is a React Hook — Hooks are special functions that only work
  // inside Client Components, which is one more reason this file needs
  // "use client" at the top.
  const [result, setResult] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleClick() {
    setIsLoading(true);
    try {
      const response = await fetch("/api/health");
      const data = await response.json();
      setResult(`✅ ${data.status} — checked at ${new Date(data.timestamp).toLocaleTimeString()}`);
    } catch {
      // We deliberately show a generic, safe message here rather than the
      // raw error object — never surface internal error details straight
      // to end users. We'll formalize this "safe error message" pattern
      // further in Part 16.
      setResult("❌ Could not reach the health check endpoint.");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="flex flex-col items-start gap-3">
      <button
        onClick={handleClick}
        disabled={isLoading}
        className="rounded-lg bg-slate-900 px-4 py-2 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {isLoading ? "Checking..." : "Ping Health Check"}
      </button>
      {result && (
        <p className="text-sm text-slate-600" role="status">
          {result}
        </p>
      )}
    </div>
  );
}
```

Now the homepage itself — a Server Component, since it has no `"use client"` directive:

#### `app/page.tsx`

```tsx
import { HealthCheckButton } from "@/components/health-check-button";
import { getAppInfo } from "@/lib/get-app-info";

// No "use client" here — this component runs on the server, computes its
// output once per request, and sends finished HTML to the browser. It can
// freely import server-only helpers like getAppInfo() without worrying
// about leaking that logic's JavaScript to the client bundle.
export default function HomePage() {
  const info = getAppInfo();

  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center gap-6 px-6">
      <div>
        <p className="text-sm font-medium uppercase tracking-wide text-indigo-600">
          {info.environment} build
        </p>
        <h1 className="mt-2 text-4xl font-bold tracking-tight text-slate-900">
          {info.name}
        </h1>
        <p className="mt-4 text-lg text-slate-600">
          A full-stack learning platform, built from an empty folder to a
          production deployment — one part at a time.
        </p>
      </div>

      {/*
        HealthCheckButton is a Client Component being rendered from inside
        a Server Component. This is a completely normal and common pattern:
        Server Components can render Client Components as children, but
        never the other way around (a Client Component cannot import and
        render a Server Component directly).
      */}
      <HealthCheckButton />
    </main>
  );
}
```

### The Verification

With `npm run dev` running, visit **http://localhost:3000**. You should see:

1. A styled heading reading "GreyMatter LMS" with the environment label above it.
2. A dark "Ping Health Check" button.

Click the button. Within a moment, text should appear below it reading something like:

```text
✅ ok — checked at 10:32:15 AM
```

**To directly observe the Server/Client split:** open your browser's DevTools → Network tab, reload the page, and view the initial HTML document response. You'll find the heading text ("GreyMatter LMS") already present in the raw HTML — proof the Server Component rendered it before the browser even ran JavaScript. The button's live click-handling behavior, by contrast, only exists because of the separate JavaScript bundle Next.js shipped for `HealthCheckButton`.

---

## Step 9 — First production build

### The Target
Confirming the entire app — health check, homepage, Tailwind styles, and TypeScript — compiles cleanly into an optimized production bundle.

### The Concept
`npm run dev` prioritizes fast feedback while you're actively coding, but it is **not** what real users get — it's the equivalent of a rehearsal with the lights half up and prompts visible offstage. `npm run build` is opening night: everything is compiled, minified, and checked as strictly as it will be on a real server. Running this now, before any real complexity exists, means if something's wrong with our foundational config, we find out today — not in Part 14 buried under twelve other changes.

### The Implementation

No new files this step — just running the build against everything we've written so far.

### The Verification

```bash
npm run build
```

Expected output ends with something resembling:

```text
Route (app)                              Size     First Load JS
┌ ○ /                                    ...      ...
├ ○ /api/health                          ...      ...
└ ○ /_not-found                          ...      ...

○  (Static)  prerendered as static content
```

The `○` symbol next to `/` confirms Next.js was able to fully pre-render our homepage as static HTML at build time — expected, since nothing on that page currently depends on a specific incoming request. Then confirm the production server actually starts:

```bash
npm run start
```

Visit `http://localhost:3000` again — the app should look and behave identically to `npm run dev`, just running from the compiled, optimized build. Stop the server with `Ctrl+C` when done.

---

## Common mistakes

- **`Module not found: Can't resolve '@/lib/...'`** — Usually means `tsconfig.json`'s `paths` entry was accidentally removed or edited incorrectly. Re-check Step 4 exactly matches.
- **`.env.local` shows up in `git status`** — Means `.gitignore` doesn't have the right entry, or the file was already committed before `.gitignore` was updated. If it was already committed, remove it from tracking with `git rm --cached .env.local` (this only untracks it, it does not delete your local file).
- **Button click does nothing, no network request appears** — Almost always means the `"use client"` directive is missing, misplaced (not on line 1), or there's a typo in it (`'use client'` with single quotes is fine, but `"use-client"` or `"Use client"` are not recognized).
- **`npm run build` fails with a type error inside `.next/types`** — Delete the `.next` folder (`rm -rf .next`) and rebuild; this folder is a generated cache and is always safe to delete.
- **Port 3000 already in use** — Another process (perhaps a previous `npm run dev` that didn't fully stop) is holding the port. Find and stop it, or run `npm run dev -- -p 3001` to use a different port temporarily.

---

## Git checkpoint

Initialize Git (if `create-next-app` didn't already do it automatically — check by running `git status`; if you see `fatal: not a git repository`, run `git init` first) and make your first commit:

```bash
git add .
git status
```

Before committing, glance over the `git status` output and confirm you **do not** see `.env.local` listed — if you do, stop and fix `.gitignore` per the "Common mistakes" section above before proceeding.

```bash
git commit -m "Part 1: project foundation — Next.js 16, TypeScript, Tailwind, health check, first Server/Client components"
```

This is your first checkpoint. If anything ever breaks badly in a later part, you can always compare your current code against this exact snapshot with:

```bash
git log --oneline
git diff <this-commit-hash>
```

---

## Reference: what you built in Part 1

A quick inventory, matched against the Part 0 deliverables list:

| Deliverable | Status |
|---|---|
| Running Next.js application | ✅ `npm run dev` serves the homepage |
| Tailwind-based landing page | ✅ `app/page.tsx` |
| Environment-variable template | ✅ `.env.example` documenting all future secrets |
| First production build | ✅ `npm run build` / `npm run start` verified |
| Clean Git repository | ✅ first commit made, `.env.local` correctly ignored |

You also now have, ready and waiting for future parts:

- A `@/` path alias proven to work across nested files (`app/api/health/route.ts` → `lib/get-app-info.ts`)
- A working Route Handler pattern (`route.ts` + exported `GET`) you'll reuse for webhooks in Part 6 and the Inngest endpoint in Part 12
- A concrete, hands-on example of the Server/Client Component boundary you'll rely on constantly starting in Part 2
- Every top-level folder (`db/`, `inngest/`, `sanity/`, `lib/`, `components/ui/`, `tests/`) pre-created and empty, waiting for their respective parts

---

## Reference: Server Components vs. Client Components cheat sheet

Since this distinction is foundational to *everything* that follows, here is a standalone reference you can return to at any point in the series.

| | Server Component (default) | Client Component (`"use client"`) |
|---|---|---|
| Where it runs | On the server, once per request | In the browser, after page load |
| Ships JavaScript to browser? | No (for that component itself) | Yes |
| Can use `useState`, `useEffect`, event handlers (`onClick`, etc.)? | No | Yes |
| Can directly `await` a database call or read server-only env vars? | Yes | No (must go through a Server Action or fetch to a Route Handler) |
| Can import and render a Client Component? | Yes | N/A — it already is one |
| Can import and render a Server Component? | Yes | No — a Client Component cannot render a Server Component as a child |
| Best for | Data fetching, layout, static or request-derived content | Interactivity: forms, buttons, animations, local state |
| Analogy | A dish plated in the kitchen, served finished | A tableside flambé — happens live, in front of the customer |

**Rule of thumb we'll apply for the rest of the series:** default every new file to a Server Component. Only add `"use client"` when you hit something a Server Component genuinely cannot do — a click handler, `useState`, a browser-only API (`localStorage`, `window`), or a React Hook. This keeps our eventual JavaScript bundle as small as possible, which matters more and more as GreyMatter grows into a full dashboard application in later parts.

---

## What's next

Part 2 stays entirely inside the frontend: we'll build GreyMatter's reusable design system — buttons, inputs, cards, badges, alerts, skeleton loaders — as a proper `components/ui/` library, styled with Tailwind design tokens, before we ever build a real dashboard or course page on top of it.
