# Appendix C: Troubleshooting & Common Errors

## 1. Errors Common to Both ORMs

### `Error: connect ETIMEDOUT` / `Error: too many connections`

**Cause:** Runtime traffic is hitting the direct (non-pooled) connection string, exhausting Postgres's max connections under serverless concurrency.

```bash
# ❌ Wrong — runtime queries pointed at direct URL
DATABASE_URL="postgresql://user:pass@ep-xxxx.neon.tech/db"

# ✅ Correct — runtime queries use the pooled endpoint
DATABASE_URL="postgresql://user:pass@ep-xxxx-pooler.neon.tech/db"
```

### `params.id` is undefined / `Cannot read properties of undefined`

**Cause:** Next.js 16 made route params a `Promise`. Forgetting to `await` them is the #1 upgrade bug from Next.js 14/15 code.

```tsx
// ❌ Old Next.js 14/15 pattern — breaks silently in 16
export default async function Page({ params }: { params: { id: string } }) {
  const post = await db.post.findUnique({ where: { id: params.id } }); // params.id is a Promise object, not a string!
}

// ✅ Next.js 16 pattern
export default async function Page({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const post = await db.post.findUnique({ where: { id } });
}
```

### `Module not found` for `@/lib/db` or `@/db` inside a Client Component

**Cause:** A database client was imported into a file with `"use client"` at the top. DB clients (both Prisma and Drizzle) must stay server-only.

```tsx
// ❌ Wrong
"use client";
import { db } from "@/lib/db"; // will fail to bundle or leak secrets to the browser

// ✅ Correct — fetch data in a Server Component/Server Action, pass as props
```

### Stale data after a mutation (list doesn't update)

**Cause:** Missing or mismatched `revalidatePath` call after a Server Action mutation.

```ts
// Make sure every mutating action revalidates every path that displays the data
await db.post.delete({ where: { id } }); // or db.delete(posts).where(...)
revalidatePath("/posts");        // list page
revalidatePath(`/posts/${id}`);  // detail page, if it still exists in cache
```

## 2. Prisma-Specific Errors

### `PrismaClientInitializationError: Can't reach database server`

| Check | Fix |
|---|---|
| Is `DATABASE_URL` set in the running environment? | Confirm `.env` is loaded (Next.js auto-loads `.env`/`.env.local`; scripts run via `tsx` need `dotenv` or `--env-file`) |
| Is `sslmode=require` present? | Neon rejects plain connections |
| Did you forget `prisma generate` after pulling new schema changes? | Run `pnpm dlx prisma generate` |

### `Error: P1001: Can't reach database server` during `migrate dev`

**Cause:** `migrate dev` uses `directUrl`, not `url`. If `DIRECT_URL` is missing/wrong, migrations fail even though runtime queries work fine.

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL") // this is what migrate dev actually uses
}
```

### `Type error: Property 'post' does not exist on type 'PrismaClient'`

**Cause:** Client wasn't regenerated after a schema change, or you're importing from the wrong path (custom `output` in `generator client`).

```bash
pnpm dlx prisma generate
# then restart the Next.js dev server — Turbopack can cache stale type info
```

### `EPERM: operation not permitted` regenerating client on Windows

**Cause:** A running dev server process is holding a lock on the generated client files.

```bash
# Stop the dev server first, then:
pnpm dlx prisma generate
pnpm dev
```

### Multiple `PrismaClient` instances warning in dev

**Cause:** Singleton pattern from Part 2 wasn't used — every hot-reload creates a new client and a new connection pool.

```ts
// Always use the globalThis-cached singleton shown in Part 2 / Appendix A1,
// never `export const db = new PrismaClient()` directly in a module.
```

## 3. Drizzle-Specific Errors

### `Error: No transactions support in neon-http driver`

**Cause:** Calling `db.transaction()` on a client created via `drizzle-orm/neon-http`.

```ts
// ❌ Wrong — neon-http is stateless HTTP, no transaction support
import { db } from "@/db"; // neon-http instance
await db.transaction(async (tx) => { ... });

// ✅ Correct — use the WebSocket pool client for any transaction
import { txDb } from "@/db"; // neon-serverless instance
await txDb.transaction(async (tx) => { ... });
```

### `relation "posts" does not exist`

**Cause:** Ran `drizzle-kit generate` but forgot to actually apply the migration.

```bash
pnpm dlx drizzle-kit generate
pnpm dlx drizzle-kit migrate   # this step is easy to forget
```

### `db.query.posts is undefined`

**Cause:** The `schema` object wasn't passed into `drizzle()`, so the relational query API (`db.query.*`) isn't available — only the core builder (`db.select()...`) works.

```ts
// ❌ Missing schema — db.query.* will be undefined
export const db = drizzle(sql);

// ✅ Pass schema to enable db.query.posts.findMany, etc.
import * as schema from "./schema";
export const db = drizzle(sql, { schema });
```

### `drizzle-kit push` overwrote data unexpectedly

**Cause:** `push` directly syncs schema to DB without a migration history — including potentially destructive changes (dropping/renaming columns) without confirmation prompts in non-interactive environments.

```bash
# Only use `push` for local prototyping.
# For anything with real data, always use generate + migrate:
pnpm dlx drizzle-kit generate --name my_change
pnpm dlx drizzle-kit migrate
```

### Type errors after editing `schema.ts` don't show up until restart

**Cause:** Next.js/Turbopack module graph caching. Unlike Prisma, there's no separate `generate` step, but your editor's TS server may still need a restart to pick up new inferred types.

```bash
# In VS Code: Cmd/Ctrl+Shift+P -> "TypeScript: Restart TS Server"
```

## 4. Quick Diagnostic Checklist

| Symptom | First thing to check |
|---|---|
| App can't connect to DB at all | `DATABASE_URL` uses the **pooled** host |
| Migrations fail but app runs fine | `DIRECT_URL` is set and uses the **non-pooled** host |
| Route param is `[object Promise]` or crashes | Did you `await params`? |
| Data doesn't refresh after mutation | Missing `revalidatePath` |
| "too many connections" under load | Not using pooled URL, or not using the singleton client pattern |
| Drizzle transaction throws immediately | Using `neon-http` instead of `neon-serverless` client |

Continue to **Appendix D: Testing Strategy for Both ORMs**.
