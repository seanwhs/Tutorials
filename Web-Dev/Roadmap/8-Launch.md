# Part 8: Launch & Iterate

## 8.1 Concept: From Fake Data to a Real Database

Every prior Part used an in-memory array (`let cards = [...]`) as a stand-in database — deliberately, to keep focus on the concept at hand. That array resets on every server restart and doesn't scale past one server process. This Part replaces it with a real, persistent Postgres database, using tools that stay entirely on free tiers.

## 8.2 Setting Up Neon (Free Postgres)

1. Go to neon.tech, sign up free, create a new project named `devboard`.
2. Copy the connection string shown (starts with `postgresql://...`).
3. This string is a secret — it goes in an environment variable, never in committed code (Part 2.8's `.gitignore` is exactly why).

```bash
# .env.local — NEVER committed (already covered by .gitignore from Part 2.8)
DATABASE_URL="postgresql://user:password@ep-example.neon.tech/devboard?sslmode=require"
```

## 8.3 Installing and Configuring Prisma

```bash
npm install prisma --save-dev
npm install @prisma/client
npx prisma init
```

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Board {
  id      String   @id @default(cuid())
  name    String
  columns Column[]
}

model Column {
  id      String @id @default(cuid())
  name    String
  boardId String
  board   Board  @relation(fields: [boardId], references: [id])
  cards   Card[]
}

model Card {
  id       String @id @default(cuid())
  title    String
  columnId String
  column   Column @relation(fields: [columnId], references: [id])
  createdAt DateTime @default(now())
}
```

```bash
npx prisma migrate dev --name init
npx prisma generate
```

`prisma migrate dev` reads your schema, diffs it against the database's actual current structure, and generates + runs a SQL migration file — this is version-controlled, reviewable schema evolution, the database equivalent of Part 2's Git commits.

## 8.4 A Shared Prisma Client (Singleton Pattern)

```typescript
// lib/db.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

This prevents Next.js's development hot-reloading from creating a new database connection pool on every file save — a common, easy-to-miss production bug if skipped.

## 8.5 Replacing the Fake Store: Server Actions on Real Data

```typescript
// app/actions/cards.ts
"use server";

import { db } from "@/lib/db";
import { revalidatePath } from "next/cache";

export async function createCard(formData: FormData) {
  const title = formData.get("title");
  const columnId = formData.get("columnId");

  if (typeof title !== "string" || title.trim().length === 0) {
    return { error: "Title is required" };
  }
  if (typeof columnId !== "string") {
    return { error: "Invalid column" };
  }

  await db.card.create({
    data: { title: title.trim(), columnId },
  });

  revalidatePath("/board");
}

export async function deleteCard(cardId: string) {
  await db.card.delete({ where: { id: cardId } });
  revalidatePath("/board");
}
```

```typescript
// app/board/page.tsx
import { db } from "@/lib/db";

async function getBoard() {
  return db.board.findFirst({
    include: { columns: { include: { cards: true } } },
  });
}

export default async function BoardPage() {
  const board = await getBoard();
  if (!board) return <p>No board found. Seed the database first.</p>;
  // ...render as in Part 7, now backed by real, persistent data
}
```

Notice: the Server Action's *signature and calling convention from Part 6 didn't change at all* — only the implementation inside swapped from an in-memory array mutation to `db.card.create(...)`. This is the payoff of the layered approach: the UI/data-flow architecture built across Parts 5–7 was already correct; only the persistence layer was a placeholder.

## 8.6 Seeding Initial Data

```typescript
// prisma/seed.ts
import { PrismaClient } from "@prisma/client";
const db = new PrismaClient();

async function main() {
  const board = await db.board.create({
    data: {
      name: "DevBoard",
      columns: {
        create: [
          { name: "Todo", cards: { create: [{ title: "Fix login bug" }] } },
          { name: "In Progress", cards: { create: [] } },
          { name: "Done", cards: { create: [{ title: "Set up Next.js project" }] } },
        ],
      },
    },
  });
  console.log("Seeded board:", board.id);
}

main().finally(() => db.$disconnect());
```

```json
// package.json — add under "prisma" key
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

```bash
npx prisma db seed
```

## 8.7 Environment Variables: Local vs. Production

| File | Committed to Git? | Used when |
|---|---|---|
| `.env.local` | No (gitignored) | Local development only |
| `.env.example` | **Yes** | Documents *which* variables are needed, with placeholder values |
| Vercel Project Settings -> Environment Variables | N/A (stored by Vercel, not in repo) | Production/Preview deployments |

```bash
# .env.example — commit this one, so teammates know what to set
DATABASE_URL="postgresql://user:password@host/dbname?sslmode=require"
```

## 8.8 Deploying to Vercel

```bash
npm install -g vercel   # optional: CLI-based deploy
vercel login
vercel                  # follow prompts to link the project
```

Or, the more common professional path — connect via the Vercel dashboard:

1. Push the current state of `devboard` to GitHub (`git push`, per Part 2).
2. Go to vercel.com -> **Add New Project** -> Import the `devboard` GitHub repo.
3. Vercel auto-detects Next.js and sets the build command (`next build`) and output automatically — no config needed for a standard App Router project.
4. Before the first deploy, add the environment variable: **Settings -> Environment Variables** -> add `DATABASE_URL` with your Neon connection string, scoped to Production (and Preview, if you want preview deploys to hit the same database).
5. Click **Deploy**.

Every subsequent `git push` to `main` triggers a new production deployment automatically; every push to any other branch gets its own preview URL — this is the payoff of Part 2.5's branching workflow.

## 8.9 Under the Hood: What Happens on Every Vercel Deploy

1. Vercel clones your GitHub repo at the pushed commit.
2. Runs `npm install`, then `next build` — this is where Server Components are compiled, Route Handlers bundled, and static assets optimized.
3. Next.js's build output is deployed as a combination of static assets (CDN-served) and serverless functions (for dynamic Server Components, Server Actions, Route Handlers) — Vercel maps this automatically from the build manifest.
4. A new immutable deployment URL is created; if this was a push to `main`, the production domain is pointed at it.

This closes the loop back to Part 1: your `git push` ultimately results in a server, somewhere, ready to receive the exact HTTP request-response cycle that opened this entire series.

## Exercise Challenge

1. Add a `Prisma` unique constraint so a Board can't have two Columns with the same `name`, then handle the resulting error gracefully in `createCard`'s sibling action, `createColumn`.
2. Deploy DevBoard to Vercel, then intentionally omit the `DATABASE_URL` environment variable on a preview branch and observe what error surfaces — explain why.

## Solution & Explanation

```prisma
model Column {
  id      String @id @default(cuid())
  name    String
  boardId String
  board   Board  @relation(fields: [boardId], references: [id])
  cards   Card[]

  @@unique([boardId, name])
}
```

```typescript
export async function createColumn(formData: FormData) {
  try {
    await db.column.create({
      data: { name: formData.get("name") as string, boardId: formData.get("boardId") as string },
    });
  } catch (err: any) {
    if (err.code === "P2002") {
      return { error: "A column with that name already exists on this board" };
    }
    throw err;
  }
  revalidatePath("/board");
}
```

Without `DATABASE_URL` set, `PrismaClient` throws at the first query attempt — typically surfacing as a `500 Internal Server Error` (Part 1.8's 5xx category) in the deployed app, because the *server* failed to fulfill an otherwise valid request. Checking Vercel's **Deployment -> Functions -> Logs** tab shows the actual Prisma connection error, which is the professional first move any time a deployed app 500s but works locally: the local `.env.local` and the production environment variables are two entirely separate configurations, and this is the single most common "works on my machine" production bug.

---
*This completes the 8-part series. See Appendix A for the full codebase reference, Appendix B for the glossary, and Appendix C for the deployment checklist.*

*Previous: `Roadmap Tutorial - Part 7: Styling & Polish`*

