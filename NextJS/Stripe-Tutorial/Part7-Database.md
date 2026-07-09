# Part 7: Database Setup with Prisma + SQLite

Previous: Part 6 (Cart Checkout with Multiple Line Items). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

We need somewhere to durably record orders once Stripe confirms payment (via webhook, next part). We use **SQLite** — a zero-config, file-based database perfect for a tutorial (no external account, no hosting) — accessed through **Prisma**, a type-safe ORM.

## 2. Install Prisma

```bash
npm install prisma --save-dev
npm install @prisma/client
npx prisma init --datasource-provider sqlite
```

This creates a `prisma/schema.prisma` file and adds `DATABASE_URL="file:./dev.db"` to `.env` (we already have this in `.env.local` from Part 1 — make sure it's not duplicated; Prisma reads from `.env` by default, so either keep both files consistent or consolidate to `.env` — for this tutorial, keep `DATABASE_URL` in `.env` since Prisma's CLI specifically reads `.env`, and keep the Stripe keys in `.env.local` for Next.js runtime use).

## 3. Define the schema

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model Order {
  id                    String      @id @default(cuid())
  stripeCheckoutId      String      @unique
  stripeCustomerId      String?
  stripePaymentIntentId String?
  customerEmail         String?
  amountTotal           Int
  currency              String
  status                String      @default("paid")
  createdAt             DateTime    @default(now())
  items                 OrderItem[]
}

model OrderItem {
  id          String @id @default(cuid())
  orderId     String
  order       Order  @relation(fields: [orderId], references: [id], onDelete: Cascade)
  productName String
  quantity    Int
  amountTotal Int
}
```

Notes:
- Amounts are stored in cents (`Int`), matching how Stripe represents money — avoids floating point rounding bugs.
- `stripeCheckoutId` is unique — this is how we make webhook handling **idempotent** (Part 8 explains why that matters).

## 4. Run the first migration

```bash
npx prisma migrate dev --name init
```

This creates `prisma/dev.db` (the actual SQLite file) and generates the Prisma Client based on your schema.

## 5. Create the Prisma client singleton

Next.js hot-reloads server code in development, which can create many Prisma Client instances and exhaust database connections. The standard fix is a cached singleton:

```ts
// src/lib/db.ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

## 6. Add dev.db and generated files to .gitignore

Add these lines to `.gitignore` if not already present:

```
# Prisma
/prisma/dev.db
/prisma/dev.db-journal
```

We keep `schema.prisma` and migration files committed (they define your schema), but not the actual local database file.

## 7. Quick sanity check

Add a temporary script to confirm everything's wired up:

```ts
// scripts/db-check.ts (temporary, can delete after confirming)
import { db } from "../src/lib/db";

async function main() {
  const order = await db.order.create({
    data: {
      stripeCheckoutId: "cs_test_sanitycheck",
      amountTotal: 1200,
      currency: "usd",
      items: {
        create: [{ productName: "Test Product", quantity: 1, amountTotal: 1200 }],
      },
    },
  });
  console.log("Created order:", order);
  await db.order.delete({ where: { id: order.id } });
  console.log("Cleaned up test order.");
}

main().finally(() => process.exit(0));
```

Run it with:

```bash
npx tsx scripts/db-check.ts
```

(If `tsx` isn't installed: `npm install -D tsx`.)

You should see the created order logged, then the cleanup message. Delete `scripts/db-check.ts` afterward — it's not part of the final app.

## Checkpoint

- [ ] `npx prisma migrate dev --name init` ran successfully and created `prisma/dev.db`.
- [ ] `src/lib/db.ts` singleton created.
- [ ] `.gitignore` excludes the local `dev.db` file.
- [ ] The sanity-check script successfully creates and deletes a test order with a related order item.

## Next

Continue to Part 8: Stripe Webhooks — Verifying Signatures and Handling checkout.session.completed.
