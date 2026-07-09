# Neon Tutorial - Appendix A (1 of 3): Config, Env & Lib Files

Full final-state contents of every config and `src/lib` file built across Parts 1-8. Appendix A (2 of 3) covers `src/actions`, and Appendix A (3 of 3) covers `src/app` pages and Prisma/Drizzle schema files.

## Folder Tree

```
neon-nextjs16-tutorial/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── notes/
│   │   │   ├── page.tsx
│   │   │   ├── new/page.tsx
│   │   │   └── [id]/page.tsx
│   │   ├── notes-prisma/
│   │   │   ├── page.tsx
│   │   │   └── [id]/page.tsx
│   │   ├── notes-drizzle/
│   │   │   ├── page.tsx
│   │   │   └── [id]/page.tsx
│   │   └── api/notes/route.ts
│   ├── lib/
│   │   ├── env.ts
│   │   ├── db-raw.ts
│   │   ├── db-prisma.ts
│   │   ├── db-drizzle.ts
│   │   ├── db-pool.ts
│   │   └── db-drizzle-pool.ts
│   └── actions/
│       ├── notes-raw.ts
│       ├── notes-prisma.ts
│       └── notes-drizzle.ts
├── prisma/
│   └── schema.prisma
├── drizzle/
│   ├── schema.ts
│   └── migrations/
├── scripts/
│   ├── migrate.ts
│   ├── seed.ts
│   └── audit-branches.ts
├── drizzle.config.ts
├── .env.local
└── package.json
```

## `package.json`

```json
{
  "name": "neon-nextjs16-tutorial",
  "version": "0.1.0",
  "private": true,
  "engines": {
    "node": ">=20.9.0"
  },
  "scripts": {
    "dev": "next dev",
    "build": "prisma generate && prisma migrate deploy && next build",
    "start": "next start",
    "lint": "next lint",
    "seed": "tsx scripts/seed.ts",
    "audit-branches": "tsx scripts/audit-branches.ts"
  },
  "dependencies": {
    "next": "16.0.0",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "zod": "^3.23.0",
    "@neondatabase/serverless": "^0.10.0",
    "@prisma/client": "^6.0.0",
    "@prisma/adapter-neon": "^6.0.0",
    "drizzle-orm": "^0.36.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "prisma": "^6.0.0",
    "drizzle-kit": "^0.28.0",
    "tsx": "^4.19.0",
    "tailwindcss": "^4.0.0"
  }
}
```

## `src/lib/env.ts` (Part 3)

```ts
import { z } from "zod";

const envSchema = z.object({
  DATABASE_URL: z.string().url().startsWith("postgresql://"),
  DIRECT_URL: z.string().url().startsWith("postgresql://"),
});

export const env = envSchema.parse({
  DATABASE_URL: process.env.DATABASE_URL,
  DIRECT_URL: process.env.DIRECT_URL,
});
```

## `src/lib/db-raw.ts` (Part 4)

```ts
import { neon } from "@neondatabase/serverless";
import { env } from "@/lib/env";

export const sql = neon(env.DATABASE_URL);
```

## `src/lib/db-prisma.ts` (Part 5)

```ts
import { PrismaClient } from "@/generated/prisma";
import { PrismaNeon } from "@prisma/adapter-neon";
import { env } from "@/lib/env";

const adapter = new PrismaNeon({ connectionString: env.DATABASE_URL });

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient({ adapter });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
```

## `src/lib/db-drizzle.ts` (Part 6)

```ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import { env } from "@/lib/env";
import * as schema from "../../drizzle/schema";

const sql = neon(env.DATABASE_URL);

export const db = drizzle(sql, { schema });
```

## `src/lib/db-pool.ts` (Part 8)

```ts
import { Pool } from "@neondatabase/serverless";
import { env } from "@/lib/env";

export const pool = new Pool({ connectionString: env.DATABASE_URL });
```

## `src/lib/db-drizzle-pool.ts` (Part 8)

```ts
import { drizzle } from "drizzle-orm/neon-serverless";
import { Pool } from "@neondatabase/serverless";
import { env } from "@/lib/env";
import * as schema from "../../drizzle/schema";

const pool = new Pool({ connectionString: env.DATABASE_URL });
export const dbPool = drizzle(pool, { schema });
```

## `drizzle.config.ts` (Part 6)

```ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./drizzle/schema.ts",
  out: "./drizzle/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DIRECT_URL!,
  },
});
```

## `scripts/migrate.ts` (Part 7)

```ts
import { drizzle } from "drizzle-orm/neon-http";
import { migrate } from "drizzle-orm/neon-http/migrator";
import { neon } from "@neondatabase/serverless";

async function main() {
  const sql = neon(process.env.DATABASE_URL!);
  const db = drizzle(sql);
  await migrate(db, { migrationsFolder: "./drizzle/migrations" });
  console.log("Migrations applied.");
}

main();
```

## `scripts/seed.ts` (Part 7)

```ts
import { db } from "@/lib/db-drizzle";
import { notesDrizzle } from "../drizzle/schema";

async function seed() {
  await db.insert(notesDrizzle).values([
    { title: "Welcome", content: "This is a seeded note." },
    { title: "Second note", content: "Another seeded example." },
  ]);
  console.log("Seed complete.");
}

seed();
```

## `scripts/audit-branches.ts` (Part 10)

```ts
const NEON_API_KEY = process.env.NEON_API_KEY!;
const NEON_PROJECT_ID = process.env.NEON_PROJECT_ID!;

async function main() {
  const res = await fetch(
    `https://console.neon.tech/api/v2/projects/${NEON_PROJECT_ID}/branches`,
    { headers: { Authorization: `Bearer ${NEON_API_KEY}` } }
  );
  const data = await res.json();

  console.log(`Total branches: ${data.branches.length} / 10`);
  for (const branch of data.branches) {
    console.log(`- ${branch.name} (created ${branch.created_at})`);
  }
}

main();
```

## Next

See **Appendix A (2 of 3)** for all `src/actions` Server Action files.
