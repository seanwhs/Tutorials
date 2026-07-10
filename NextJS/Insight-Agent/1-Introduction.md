# Phase 1: Setup & Infrastructure 

## Introduction

**InsightAgent** is a personalized, agentic research dashboard. A signed-in user types a research question; an AI agent (built on the Vercel AI SDK's tool-calling loop) autonomously decides to search the web (Tavily), scrape pages for full content (Firecrawl), reason over the results, and stream back a structured report — all visible in real time via a "Thought Dashboard" that shows each tool call as it happens.

### Tech Stack

| Layer | Choice | Free Tier? |
|---|---|---|
| Framework | Next.js 16 (App Router, Turbopack, async APIs) | Open source |
| Styling | Tailwind CSS v4 (CSS-first config) | Open source |
| Auth | Clerk | Yes — generous free tier |
| Database | Neon Postgres (serverless) | Yes — free tier |
| ORM | Drizzle ORM | Open source |
| AI Orchestration | Vercel AI SDK (`streamText`, tool loop) | Open source |
| AI Model Providers | Groq, Together AI, Hugging Face Inference (OpenAI-compatible) | Yes — all free tiers |
| Search Tool | Tavily API | Yes — free tier (1,000 credits/mo) |
| Scrape Tool | Firecrawl API | Yes — free tier (500 credits/mo) |
| Testing | Vitest + `ai/test` (`MockLanguageModelV2`) | Open source |
| Hosting | Vercel Hobby | Yes — free tier |

### Learning Outcomes

1. Build a Next.js 16 app that's fully async-first (params, searchParams, Clerk `auth()` all awaited).
2. Implement a **provider-agnostic AI model layer** for free-tier model switching in the UI with zero code changes to add a new provider.
3. Build a real **agentic tool loop** using the Vercel AI SDK with web search + scrape tools.
4. Stream both final answers and intermediate "thoughts" (tool calls/results) to the client.
5. Persist chat/agent-run history per user in Postgres via Drizzle.
6. Write deterministic, offline agent tests with `MockLanguageModelV2` — zero API cost in CI.
7. Deploy to Vercel Hobby, respecting free-tier function limits.

## Series Map

| Phase | Title | Scope |
|---|---|---|
| 1 | Setup & Infrastructure | Scaffold, Tailwind v4, Clerk, Neon+Drizzle, `.env.example`, folder structure |
| 2 | The Agentic Core | Model-provider abstraction, Tavily + Firecrawl tools, system prompt, agent loop, API route |
| 3 | UI & Streaming | Chat UI, model selector, ThoughtDashboard, ReportView |
| 4 | Persistent Chat History | Drizzle schema, save-on-finish, history sidebar |
| 5 | Testing the Agent | Vitest + `ai/test`, tool tests, agent-loop integration test |
| 6 | Deploy | Vercel Hobby deployment, env vars, function limits |
| — | Conclusion | Recap, extensions |
| — | Appendix A | Full codebase reference |
| — | Additional Resources | Links, FAQ |

<Step number="1.1" title="Repo Scaffold & package.json">
<Explanation>
Clean Next.js 16 App Router project, Turbopack default. We depend on `@ai-sdk/openai-compatible` instead of `openai` — Groq, Together AI, and Hugging Face's Inference API all expose OpenAI-compatible chat completion endpoints, which is the foundation of the model-agility pillar: one provider package, many free backends, chosen at runtime by base URL + API key + model id.
</Explanation>

<Code language="bash" title="terminal: scaffold">
npx create-next-app@latest insight-agent --typescript --tailwind --eslint --app --src-dir --turbopack --import-alias "@/*"
cd insight-agent
</Code>

<Code language="json" title="package.json">
{
  "name": "insight-agent",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "test": "vitest run",
    "test:watch": "vitest",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:studio": "drizzle-kit studio"
  },
  "dependencies": {
    "next": "16.0.0",
    "react": "19.1.0",
    "react-dom": "19.1.0",
    "@clerk/nextjs": "^6.14.0",
    "ai": "^5.0.0",
    "@ai-sdk/openai-compatible": "^0.2.0",
    "@ai-sdk/react": "^2.0.0",
    "drizzle-orm": "^0.36.4",
    "@neondatabase/serverless": "^0.10.4",
    "zod": "^3.24.1",
    "clsx": "^2.1.1",
    "lucide-react": "^0.469.0",
    "nanoid": "^5.0.9"
  },
  "devDependencies": {
    "typescript": "^5.7.2",
    "@types/node": "^22.10.2",
    "@types/react": "^19.0.2",
    "@types/react-dom": "^19.0.2",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "drizzle-kit": "^0.28.1",
    "vitest": "^2.1.8",
    "@vitejs/plugin-react": "^4.3.4",
    "dotenv": "^16.4.7",
    "eslint": "^9.17.0",
    "eslint-config-next": "16.0.0"
  }
}
</Code>
</Step>

---

Step 1.2: Consolidated Environment Variables.

---

<Step number="1.2" title="Consolidated Environment Variables">
<Explanation>
This is the single source of truth for every environment variable used across the entire series — defined once here, only consumed later. Rather than one `OPENAI_API_KEY`, we define one key per free provider plus a `DEFAULT_MODEL_ID` used server-side as a fallback when a client request doesn't specify a model. The actual provider/model registry (mapping UI-selectable options to base URLs + env keys) is built in Phase 2.
</Explanation>

<Code language="bash" title=".env.example">
# ── Clerk (Auth) ──────────────────────────────────────────────
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard

# ── Database (Neon Postgres, free tier) ──────────────────────
DATABASE_URL=postgresql://user:password@ep-xxxx.neon.tech/insightagent?sslmode=require

# ── AI Model Providers (all free-tier, OpenAI-compatible) ───
# Groq: https://console.groq.com/keys (free tier, very fast inference)
GROQ_API_KEY=gsk_xxxxxxxxxxxx
# Together AI: https://api.together.xyz/settings/api-keys (free tier credits)
TOGETHER_API_KEY=tgp_v1_xxxxxxxxxxxx
# Hugging Face Inference API: https://huggingface.co/settings/tokens (free tier)
HUGGINGFACE_API_KEY=hf_xxxxxxxxxxxx

# Server-side fallback model id if the client sends no selection.
# Must match a `value` in the MODEL_REGISTRY (see Phase 2).
DEFAULT_MODEL_ID=groq:llama-3.3-70b-versatile

# ── Research Tools ────────────────────────────────────────────
# Tavily: https://app.tavily.com (free tier: 1,000 searches/mo)
TAVILY_API_KEY=tvly-xxxxxxxxxxxx
# Firecrawl: https://www.firecrawl.dev (free tier: 500 credits/mo)
FIRECRAWL_API_KEY=fc-xxxxxxxxxxxx

# ── App ────────────────────────────────────────────────────────
NEXT_PUBLIC_APP_URL=http://localhost:3000
</Code>

<Explanation>
Copy `.env.example` to `.env.local` for local dev. Every key here must also be added to the Vercel project's Environment Variables settings before deployment (covered in Phase 6). None of these services require a credit card for the free tier used in this tutorial.
</Explanation>
</Step>

---
Step 1.3: Tailwind CSS v4 config, and Step 1.4: Clerk Authentication Setup.

---

<Step number="1.3" title="Tailwind CSS v4 (CSS-first Configuration)">
<Explanation>
Tailwind v4 drops the JS-based `tailwind.config.ts` in favor of a CSS-first approach. All theme customization lives directly in `globals.css` using the `@theme` directive. The PostCSS plugin is `@tailwindcss/postcss`, already added to `package.json` in Step 1.1. This file also defines InsightAgent's design tokens — a brand/surface palette used consistently across the ThoughtDashboard and chat UI in later phases.
</Explanation>

<Code language="css" title="src/app/globals.css">
@import "tailwindcss";

@theme {
  --color-brand-50: oklch(0.97 0.01 264);
  --color-brand-100: oklch(0.93 0.03 264);
  --color-brand-500: oklch(0.55 0.18 264);
  --color-brand-600: oklch(0.48 0.19 264);
  --color-brand-700: oklch(0.4 0.18 264);

  --color-surface-0: oklch(1 0 0);
  --color-surface-50: oklch(0.98 0 0);
  --color-surface-100: oklch(0.96 0 0);
  --color-surface-900: oklch(0.16 0.01 264);

  --font-sans: "Inter", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, monospace;

  --animate-pulse-slow: pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@layer base {
  html,
  body {
    height: 100%;
  }
  body {
    background-color: var(--color-surface-50);
    color: var(--color-surface-900);
    font-family: var(--font-sans);
  }
}

@layer utilities {
  .scrollbar-thin {
    scrollbar-width: thin;
  }
}
</Code>

<Code language="typescript" title="postcss.config.mjs">
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
  },
};

export default config;
</Code>

<Explanation>
No `tailwind.config.ts` file exists anywhere in this project — intentional, matching Tailwind v4's CSS-first model. Any future design token is added directly to the `@theme` block above; every phase references only these tokens (`bg-brand-600`, `text-surface-900`, etc.) for consistency.
</Explanation>
</Step>

<Step number="1.4" title="Clerk Authentication Setup">
<Explanation>
Clerk protects every route under `/dashboard` and `/api/chat`. Next.js 16 requires `clerkMiddleware` from the current Clerk SDK, and all server-side reads of the current user use the async `auth()` function — always awaited, never called synchronously (a common migration mistake from older Next.js/Clerk versions). We wrap the root layout in `<ClerkProvider>` and add prebuilt sign-in/sign-up pages using Clerk's catch-all routing convention.
</Explanation>

<Code language="typescript" title="middleware.ts">
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/api/chat(.*)",
  "/api/conversations(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
</Code>

<Code language="typescript" title="src/app/layout.tsx">
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "InsightAgent — Personalized Agentic Research Dashboard",
  description: "Ask a research question. Watch an AI agent search, scrape, and synthesize an answer in real time.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
</Code>

<Code language="typescript" title="src/app/sign-in/[[...sign-in]]/page.tsx">
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-surface-50">
      <SignIn />
    </div>
  );
}
</Code>

<Code language="typescript" title="src/app/sign-up/[[...sign-up]]/page.tsx">
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-surface-50">
      <SignUp />
    </div>
  );
}
</Code>

<Code language="typescript" title="src/app/page.tsx">
import Link from "next/link";
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function HomePage() {
  const { userId } = await auth();

  if (userId) {
    redirect("/dashboard");
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 bg-surface-50 px-6 text-center">
      <h1 className="text-4xl font-bold text-surface-900">InsightAgent</h1>
      <p className="max-w-md text-surface-900/70">
        A personalized agentic research dashboard. Ask a question, pick a free
        AI model, and watch the agent search and scrape the web in real time.
      </p>
      <div className="flex gap-3">
        <Link
          href="/sign-in"
          className="rounded-lg bg-brand-600 px-5 py-2.5 font-medium text-white hover:bg-brand-700"
        >
          Sign In
        </Link>
        <Link
          href="/sign-up"
          className="rounded-lg border border-brand-600 px-5 py-2.5 font-medium text-brand-600 hover:bg-brand-50"
        >
          Sign Up
        </Link>
      </div>
    </main>
  );
}
</Code>

<Explanation>
Key Next.js 16 detail: `auth()` from `@clerk/nextjs/server` returns a Promise and must be awaited — applies everywhere in this series, including inside Server Actions and Route Handlers in later phases. The middleware matcher excludes static assets and Next internals but still runs on all app/API routes, letting `createRouteMatcher` decide per-request which paths need `auth.protect()`.
</Explanation>
</Step>

---

Step 1.5: Neon + Drizzle ORM Client, and Step 1.6: Canonical Folder Structure. This completes Phase 1.

---

<Step number="1.5" title="Neon Postgres + Drizzle ORM Client">
<Explanation>
We use Neon's serverless HTTP driver (`@neondatabase/serverless`) rather than a traditional `pg` connection pool, because it works over HTTP/WebSockets and is compatible with Vercel's serverless/Edge functions — no persistent TCP connections, which matters on Vercel Hobby's function model. Drizzle ORM sits on top as a fully-typed query builder. The full schema (conversations, messages, tool events) is introduced in Phase 4 — here we only set up the base client, config, and a placeholder schema file so `drizzle-kit` has something to point at from day one.
</Explanation>

<Code language="typescript" title="src/db/schema.ts">
import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

// Placeholder table so drizzle-kit can generate an initial migration.
// Full schema (conversations, messages, toolEvents) is added in Phase 4.
export const healthCheck = pgTable("health_check", {
  id: uuid("id").primaryKey().defaultRandom(),
  note: text("note").notNull().default("insight-agent-db-ok"),
  createdAt: timestamp("created_at", { withTimezone: true })
    .notNull()
    .defaultNow(),
});
</Code>

<Code language="typescript" title="src/db/index.ts">
import { neon } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-http";
import * as schema from "./schema";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set. Copy .env.example to .env.local and fill it in.");
}

const sql = neon(process.env.DATABASE_URL);

export const db = drizzle(sql, { schema });
</Code>

<Code language="typescript" title="drizzle.config.ts">
import { defineConfig } from "drizzle-kit";
import "dotenv/config";

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set. Copy .env.example to .env.local and fill it in.");
}

export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
  strict: true,
  verbose: true,
});
</Code>

<Explanation>
Run `npm run db:generate` to produce a SQL migration from `schema.ts`, then `npm run db:migrate` to apply it to your Neon database. `npm run db:studio` opens Drizzle Studio, a free local GUI for browsing your Neon data. Because `db/index.ts` throws immediately if `DATABASE_URL` is missing, misconfiguration fails fast and loudly during local dev rather than producing confusing downstream errors.
</Explanation>
</Step>

<Step number="1.6" title="Canonical Folder Structure">
<Explanation>
This is the definitive folder layout for the entire project, referenced identically in every subsequent phase. Nothing here is renamed or moved later — files are only added inside these directories.
</Explanation>

<Code language="text" title="folder structure">
insight-agent/
├── .env.example
├── .env.local                      (gitignored, created by you)
├── drizzle.config.ts
├── vitest.config.ts                (Phase 5)
├── middleware.ts
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── tsconfig.json
├── drizzle/                        (generated SQL migrations)
└── src/
    ├── app/
    │   ├── globals.css
    │   ├── layout.tsx
    │   ├── page.tsx
    │   ├── sign-in/[[...sign-in]]/page.tsx
    │   ├── sign-up/[[...sign-up]]/page.tsx
    │   ├── dashboard/
    │   │   └── page.tsx            (Phase 3)
    │   └── api/
    │       ├── chat/route.ts       (Phase 2)
    │       └── conversations/      (Phase 4)
    ├── components/
    │   ├── ThoughtDashboard.tsx    (Phase 3)
    │   ├── ReportView.tsx          (Phase 3)
    │   ├── ModelSelector.tsx       (Phase 3)
    │   └── ChatInput.tsx           (Phase 3)
    ├── db/
    │   ├── index.ts
    │   └── schema.ts
    └── lib/
        └── agent/
            ├── models.ts           (Phase 2 — model registry)
            ├── system-prompt.ts    (Phase 2)
            ├── agent-loop.ts       (Phase 2)
            ├── agent-loop.test.ts  (Phase 5)
            └── tools/
                ├── tavily-search.ts        (Phase 2)
                ├── tavily-search.test.ts   (Phase 5)
                ├── firecrawl-scrape.ts     (Phase 2)
                └── firecrawl-scrape.test.ts (Phase 5)
</Code>

<Code language="typescript" title="next.config.ts">
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  typedRoutes: true,
  experimental: {
    turbopackPersistentCaching: true,
  },
};

export default nextConfig;
</Code>

<Code language="json" title="tsconfig.json">
{
  "compilerOptions": {
    "target": "ES2022",
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
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
</Code>
</Step>

<Explanation>
This completes Phase 1. At this point you have: a running Next.js 16 + Tailwind v4 app, working Clerk auth (sign-in/sign-up gating `/dashboard`), a Neon Postgres database wired through Drizzle with a placeholder table you can migrate right now to confirm connectivity end-to-end, and the full folder skeleton that every later phase will fill in — never restructure.
</Explanation>

---

**Phase 1 complete.** Ready to move to Phase 2: The Agentic Core (model registry, Tavily/Firecrawl tools, agent loop, API route) — also delivered in digestible parts. Let me know when you'd like to start.
