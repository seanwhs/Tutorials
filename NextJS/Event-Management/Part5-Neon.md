# Part 5: Neon Postgres Setup and Drizzle ORM

Database setup/Drizzle config is unaffected by Next.js 16's async API changes — identical in spirit to earlier Next.js versions.

## 1. Get your Neon connection string
Neon dashboard → your `eventhub` project → **Connection string** (use **Pooled connection**, important for serverless). Looks like:
```
postgresql://neondb_owner:AbCd1234@ep-cool-forest-12345.us-east-2.aws.neon.tech/neondb?sslmode=require
```

## 2. Add to environment variables
```bash
# .env.local (add to existing file)
DATABASE_URL=postgresql://neondb_owner:AbCd1234@ep-cool-forest-12345.us-east-2.aws.neon.tech/neondb?sslmode=require
```

## 3. Create the Drizzle client
```ts
// src/db/index.ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "./schema";

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });
```
Uses the `neon-http` driver — talks to Neon over plain HTTP, ideal for serverless (Vercel functions, Inngest steps) since there's no persistent connection to manage.

## 4. Placeholder schema file
```ts
// src/db/schema.ts
import { pgTable, text } from "drizzle-orm/pg-core";

export const _placeholder = pgTable("_placeholder", {
  id: text("id").primaryKey(),
});
```
(Real tables built in Part 6.)

## 5. Configure Drizzle Kit
```ts
// drizzle.config.ts
import { defineConfig } from "drizzle-kit";
import { config } from "dotenv";

config({ path: ".env.local" });

export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
  verbose: true,
  strict: true,
});
```
```bash
pnpm add -D dotenv
```
(Needed since Drizzle Kit CLI doesn't auto-load `.env.local` like Next.js does at runtime.)

## 6. npm scripts
```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "drizzle-kit migrate",
    "db:push": "drizzle-kit push",
    "db:studio": "drizzle-kit studio"
  }
}
```
- `db:generate` → writes migration SQL files
- `db:migrate` → applies them (tracked history)
- `db:push` → direct sync, no migration files (prototyping only)
- `db:studio` → free local GUI for the DB

(`next dev`/`build` already use Turbopack automatically — no extra script variant needed.)

## 7. Test the connection
```bash
pnpm db:generate
pnpm db:migrate
```
Should create `./drizzle/*.sql` and apply successfully. If it fails: check `?sslmode=require` is present and the password hasn't expired.

```bash
pnpm db:studio
```
Opens a local browser GUI — confirm you see the `_placeholder` table.

## Checkpoint
- [ ] `DATABASE_URL` set in `.env.local`
- [ ] `pnpm db:generate` and `pnpm db:migrate` run cleanly
- [ ] Drizzle Studio shows the placeholder table

**Next: Part 6 — Database Schema Design**
