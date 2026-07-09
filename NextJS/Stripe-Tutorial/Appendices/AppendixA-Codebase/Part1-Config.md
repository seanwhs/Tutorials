# Appendix A (1 of 5): Full Codebase Reference — Config, Lib & Schema

Index: "Stripe Tutorial - INDEX (Start Here)". Covers project config, `src/lib/*`, and the Prisma schema. See parts 2-5 of 5 for components, pages, and API routes.

## package.json (key dependencies)

```json
{
  "dependencies": {
    "next": "16.x.x",
    "react": "latest",
    "react-dom": "latest",
    "stripe": "latest",
    "@prisma/client": "latest"
  },
  "devDependencies": {
    "prisma": "latest",
    "tailwindcss": "latest",
    "typescript": "latest",
    "tsx": "latest"
  }
}
```

## .env.local (template — fill in your own values, never commit real values)

```bash
STRIPE_SECRET_KEY=sk_test_...
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
NEXT_PUBLIC_APP_URL=http://localhost:3000
DATABASE_URL="file:./dev.db"
```

## src/app/globals.css

```css
@import "tailwindcss";
```

## prisma/schema.prisma

```prisma
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

## src/lib/env.ts

```ts
function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  STRIPE_SECRET_KEY: requireEnv("STRIPE_SECRET_KEY"),
  STRIPE_WEBHOOK_SECRET: requireEnv("STRIPE_WEBHOOK_SECRET"),
  NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY: requireEnv("NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY"),
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000",
};
```

## src/lib/stripe.ts

```ts
import Stripe from "stripe";
import { env } from "@/lib/env";

export const stripe = new Stripe(env.STRIPE_SECRET_KEY, {
  apiVersion: "2025-08-27.basil",
  typescript: true,
});
```

## src/lib/db.ts

```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const db = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = db;
}
```

## src/lib/products.ts

```ts
export type Product = {
  id: string;
  name: string;
  description: string;
  priceId: string;
  priceLabel: string;
  image: string;
};

export const products: Product[] = [
  {
    id: "mug",
    name: "Acme Mug",
    description: "A sturdy 11oz ceramic mug with the Acme logo.",
    priceId: "price_REPLACE_WITH_MUG_PRICE_ID",
    priceLabel: "$12.00",
    image: "https://placehold.co/400x400?text=Acme+Mug",
  },
  {
    id: "tshirt",
    name: "Acme T-Shirt",
    description: "100% cotton tee, unisex fit, in classic black.",
    priceId: "price_REPLACE_WITH_TSHIRT_PRICE_ID",
    priceLabel: "$25.00",
    image: "https://placehold.co/400x400?text=Acme+T-Shirt",
  },
  {
    id: "stickers",
    name: "Acme Sticker Pack",
    description: "A pack of 5 vinyl stickers, weatherproof.",
    priceId: "price_REPLACE_WITH_STICKERS_PRICE_ID",
    priceLabel: "$6.00",
    image: "https://placehold.co/400x400?text=Acme+Stickers",
  },
];

export function getProductById(id: string): Product | undefined {
  return products.find((p) => p.id === id);
}
```

## src/lib/plans.ts

```ts
export type Plan = {
  id: string;
  name: string;
  description: string;
  priceId: string;
  priceLabel: string;
};

export const plans: Plan[] = [
  {
    id: "pro-monthly",
    name: "Acme Pro Plan",
    description: "Unlock pro features, billed monthly. Cancel anytime.",
    priceId: "price_REPLACE_WITH_PRO_MONTHLY_PRICE_ID",
    priceLabel: "$9.00 / month",
  },
];

export function getPlanById(id: string): Plan | undefined {
  return plans.find((p) => p.id === id);
}
```

## Next

Continue to **Appendix A (2 of 5): Layout, Nav & Cart Components**.
