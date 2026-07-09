# Neon Tutorial - Part 3: Next.js 16 Project Setup & Environment Variables

## 1. Prerequisites

| Requirement | Version |
|---|---|
| Node.js | 20.9+ or 22 LTS (Node 18 is EOL — will not work) |
| Package manager | pnpm (recommended); npm/yarn also fine |

```bash
node -v   # confirm 20.9+ or 22.x before continuing
```

## 2. Scaffold the Next.js 16 App

```bash
pnpm create next-app@latest neon-nextjs16-tutorial

# Prompts:
# ✔ TypeScript?                 Yes
# ✔ ESLint?                     Yes
# ✔ Tailwind CSS?               Yes
# ✔ src/ directory?             Yes
# ✔ App Router?                 Yes (required)
# ✔ Turbopack (default)?        Yes
# ✔ Customize import alias?     No (keep @/*)

cd neon-nextjs16-tutorial
```

## 3. Install the Zod Env Validator

We validate environment variables at startup so a missing/malformed `DATABASE_URL` fails loudly and immediately rather than causing a cryptic runtime error deep in a query.

```bash
pnpm add zod
```

## 4. Create `.env.local`

```bash
# .env.local — NEVER commit this file (already in .gitignore by default)

# Pooled connection — used by the app at runtime (Parts 4-6)
DATABASE_URL="postgresql://neondb_owner:<password>@ep-xxxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require"

# Direct connection — used only for migrations (Parts 5-6)
DIRECT_URL="postgresql://neondb_owner:<password>@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require"
```

Paste in the two connection strings you saved from Part 2.

## 5. Typed, Validated Environment Variables

```ts
// src/lib/env.ts
import { z } from "zod";

// Defining a schema means a typo'd or missing env var throws a clear
// error at boot instead of a confusing "fetch failed" deep in a Server
// Action three weeks from now.
const envSchema = z.object({
  DATABASE_URL: z.string().url().startsWith("postgresql://"),
  DIRECT_URL: z.string().url().startsWith("postgresql://"),
});

// parse (not safeParse) so an invalid .env.local crashes the server
// immediately with a readable Zod error instead of failing silently.
export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  DIRECT_URL: process.env.DIRECT_URL,
});
```

Use `env.DATABASE_URL` (not `process.env.DATABASE_URL`) everywhere in later parts — it's typed and guaranteed to exist.

## 6. Project Structure for This Series

```
neon-nextjs16-tutorial/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── notes/                 # demo CRUD feature built across Parts 4-6
│   │       ├── page.tsx
│   │       └── [id]/
│   │           └── page.tsx
│   ├── lib/
│   │   ├── env.ts                 # this part
│   │   ├── db-raw.ts              # Part 4 — raw @neondatabase/serverless client
│   │   ├── db-prisma.ts           # Part 5 — Prisma client w/ Neon adapter
│   │   └── db-drizzle.ts          # Part 6 — Drizzle client
│   └── actions/
│       └── notes.ts               # Server Actions, built incrementally
├── prisma/
│   └── schema.prisma              # Part 5
├── drizzle/
│   └── schema.ts                  # Part 6
├── .env.local
└── package.json
```

## 7. Sanity-Check the Env Setup

```tsx
// src/app/page.tsx
import { env } from "@/lib/env";

export default function Home() {
  // Only reveal that the vars EXIST, never render actual secret values
  // in a page — this is purely a wiring sanity check for this part.
  const dbConfigured = Boolean(env.DATABASE_URL && env.DIRECT_URL);

  return (
    <main className="p-8">
      <h1 className="text-2xl font-bold">Neon + Next.js 16 Tutorial</h1>
      <p className="mt-2">
        Environment variables configured: {dbConfigured ? "✅ Yes" : "❌ No"}
      </p>
    </main>
  );
}
```

```bash
pnpm dev
# Visit http://localhost:3000 — should show "✅ Yes"
# If it crashes with a ZodError instead, re-check .env.local
```

## 8. Critical Next.js 16 Reminder

Every dynamic route added from Part 4 onward (e.g. `notes/[id]`) uses **Promise-based params**:

```tsx
// src/app/notes/[id]/page.tsx (skeleton — filled in Part 4)
type PageProps = {
  params: Promise<{ id: string }>;
};

export default async function NotePage({ params }: PageProps) {
  const { id } = await params; // must await in Next.js 16
  return <div>Note ID: {id}</div>;
}
```

## 9. Checkpoint

- [ ] Node 20.9+/22 LTS confirmed
- [ ] Next.js 16 app scaffolded with App Router + TypeScript + Tailwind
- [ ] `.env.local` created with both `DATABASE_URL` (pooled) and `DIRECT_URL` (direct)
- [ ] `src/lib/env.ts` validates env vars with Zod at startup
- [ ] `pnpm dev` runs and the homepage shows "✅ Yes"

## Troubleshooting

| Problem | Fix |
|---|---|
| `ZodError: Required` on startup | `.env.local` is missing a var or the dev server was started before the file was saved — restart `pnpm dev` |
| `.env.local` not picked up | Next.js only loads `.env.local` automatically for `next dev`/`next build` run from the project root — confirm your terminal's `cwd` |
| Connection string has special characters breaking the URL | Percent-encode special characters in the password (e.g. `@` → `%40`) or re-generate the password from the Neon console |

## Next

**Part 4: Connecting Neon via `@neondatabase/serverless`** — write your first real queries using the official lightweight driver, no ORM required.
