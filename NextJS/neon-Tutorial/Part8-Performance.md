# Neon Tutorial - Part 8: Connection Pooling, Edge Runtime & Performance Best Practices

## 1. Pooled vs Direct — The Full Picture

| | Pooled (`-pooler` hostname) | Direct (no `-pooler`) |
|---|---|---|
| Routed through | Neon's built-in PgBouncer-style pooler | Straight to the compute endpoint |
| Max concurrent connections | Very high (thousands) — pooler multiplexes many client connections onto fewer backend connections | Limited by Postgres `max_connections` on the compute size |
| Session-level features (`SET`, advisory locks, `LISTEN/NOTIFY`, long transactions) | ❌ Not supported (transaction-pooling mode) | ✅ Supported |
| Use for | App runtime queries (Server Components, Server Actions, Route Handlers) | Migrations (`prisma migrate`, `drizzle-kit migrate`), one-off admin scripts |
| Env var convention (this series) | `DATABASE_URL` | `DIRECT_URL` |

```bash
# Pooled — safe for hundreds of serverless function invocations at once
DATABASE_URL="postgresql://user:pass@ep-xxxx-pooler.region.aws.neon.tech/neondb?sslmode=require"

# Direct — one connection, full Postgres session semantics
DIRECT_URL="postgresql://user:pass@ep-xxxx.region.aws.neon.tech/neondb?sslmode=require"
```

## 2. Why Serverless Needs Pooling At All

Each Vercel serverless function invocation can be a fresh process. Without pooling, 100 concurrent requests could try to open 100 raw Postgres connections simultaneously — quickly exhausting `max_connections` on a small compute size.

```
Without pooling:                    With pooling:
100 requests                        100 requests
   │                                    │
   ▼                                    ▼
100 raw Postgres connections   ──►  pooler multiplexes onto
   │                                 e.g. 10-20 backend connections
   ▼                                    │
❌ "too many connections"              ▼
                                    ✅ requests queue briefly, succeed
```

`@neondatabase/serverless`'s HTTP mode sidesteps this differently — each query is a stateless HTTP request, so there's no persistent connection to exhaust in the first place. The pooled Postgres connection string matters most when using a traditional driver (`pg`, or Prisma/Drizzle in non-HTTP modes).

## 3. Edge Runtime Compatibility

```tsx
// src/app/api/notes/route.ts
export const runtime = "edge"; // opt into the Edge Runtime

import { neon } from "@neondatabase/serverless";
import { env } from "@/lib/env";
import { NextResponse } from "next/server";

// The neon() HTTP driver works in Edge Runtime because it uses fetch()
// under the hood, not a raw TCP socket (which Edge Runtime disallows).
const sql = neon(env.DATABASE_URL);

export async function GET() {
  const notes = await sql`SELECT id, title FROM notes ORDER BY created_at DESC LIMIT 10`;
  return NextResponse.json({ notes });
}
```

| Client | Edge Runtime Compatible? |
|---|---|
| `@neondatabase/serverless` `neon()` (HTTP) | ✅ Yes |
| `@neondatabase/serverless` `Pool` (WebSocket) | ✅ Yes (uses WebSocket, also edge-safe) |
| Prisma with `@prisma/adapter-neon` | ✅ Yes (adapter uses the same driver under the hood) |
| Drizzle with `drizzle-orm/neon-http` | ✅ Yes |
| Drizzle/Prisma with a standard `pg`-based driver | ❌ No — raw TCP sockets aren't available in Edge Runtime |

## 4. When to Use `Pool` (WebSocket) Instead of `neon()` (HTTP)

```ts
// src/lib/db-pool.ts
import { Pool } from "@neondatabase/serverless";
import { env } from "@/lib/env";

// Pool gives you a pg-compatible client over WebSocket — needed for
// real multi-statement transactions (BEGIN/COMMIT across several
// dependent queries) and any session-level feature.
export const pool = new Pool({ connectionString: env.DATABASE_URL });
```

```ts
// Example: a real transaction with conditional logic between statements —
// impossible with the stateless HTTP driver.
const client = await pool.connect();
try {
  await client.query("BEGIN");

  const { rows } = await client.query(
    "SELECT balance FROM accounts WHERE id = $1 FOR UPDATE",
    [accountId]
  );

  if (rows[0].balance < amount) {
    throw new Error("Insufficient balance");
  }

  await client.query(
    "UPDATE accounts SET balance = balance - $1 WHERE id = $2",
    [amount, accountId]
  );

  await client.query("COMMIT");
} catch (err) {
  await client.query("ROLLBACK");
  throw err;
} finally {
  client.release(); // always release back to the pool
}
```

Drizzle's equivalent, used when `db.transaction()` is required (this is exactly why Part 6 called out that `neon-http` alone doesn't support it):

```ts
// src/lib/db-drizzle-pool.ts
import { drizzle } from "drizzle-orm/neon-serverless";
import { Pool } from "@neondatabase/serverless";
import { env } from "@/lib/env";
import * as schema from "../../drizzle/schema";

const pool = new Pool({ connectionString: env.DATABASE_URL });
export const dbPool = drizzle(pool, { schema });
```

```ts
await dbPool.transaction(async (tx) => {
  await tx.insert(notesDrizzle).values({ title: "A", content: "..." });
  await tx.insert(notesDrizzle).values({ title: "B", content: "..." });
  // if either insert throws, both are rolled back
});
```

## 5. Cold Starts & Scale-to-Zero Latency

Neon's free-tier compute autosuspends after a period of inactivity (roughly 5 minutes by default). The **first** query after a suspend incurs a "cold start" — typically several hundred milliseconds to ~1-2 seconds while compute resumes.

```ts
// Mitigation pattern: don't let a cold start silently hang forever —
// wrap queries with a timeout so users see a clear error/retry UI
// instead of an indefinite spinner.
async function queryWithTimeout<T>(promise: Promise<T>, ms = 5000): Promise<T> {
  return Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error("Query timed out")), ms)
    ),
  ]);
}

const notes = await queryWithTimeout(sql`SELECT * FROM notes`);
```

For latency-sensitive production apps, Neon's paid tiers offer an "always on" compute option that disables autosuspend — not needed for this free-tier tutorial series, but good to know it exists.

## 6. Query Performance Tips

```sql
-- Add indexes on columns you filter/sort/join by often.
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes (created_at DESC);
```

```ts
// Select only the columns you need — smaller payloads over HTTP
// matter more with Neon's HTTP driver than with a persistent socket.
const titles = await sql`SELECT id, title FROM notes`; // ✅ good
const everything = await sql`SELECT * FROM notes`;      // ❌ wasteful if unused
```

```ts
// Batch independent reads with sql.transaction() (read-only) instead
// of sequential awaits, to cut down round trips.
const [notes, tags] = await sql.transaction([
  sql`SELECT * FROM notes ORDER BY created_at DESC LIMIT 10`,
  sql`SELECT * FROM tags`,
]);
```

## 7. Checkpoint

- [ ] Understand transaction-pooling limitations (no `SET`/advisory locks/long transactions on pooled connections)
- [ ] Know which driver/ORM combos are Edge Runtime compatible
- [ ] Can explain when to reach for `Pool`/`neon-serverless` instead of `neon()`/`neon-http`
- [ ] Understand cold-start latency from scale-to-zero and how to add query timeouts
- [ ] Applied at least one index and column-selection optimization

## Troubleshooting

| Problem | Fix |
|---|---|
| `Error: Cannot use transaction pooling with SET/advisory locks` | Switch that specific operation to the direct connection or a `Pool`-based client |
| First request after idle is very slow | Expected cold-start behavior on free tier — add a timeout/retry and consider a lightweight periodic health-check ping if latency-sensitive |
| Edge Runtime build fails referencing `net`/`tls` modules | You're using a `pg`-based (non-Neon) driver under `runtime = "edge"` — switch to `@neondatabase/serverless` |

## Next

**Part 9: Deploying to Vercel Free Tier with Neon** — take the app to production, run migrations in CI, and verify everything end-to-end.
