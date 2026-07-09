# Part 3: Database Design (Prisma + Neon Postgres)

## Concept

Our source of truth for historical data, dividends, watchlists, and alerts is Postgres, accessed through Prisma. We use Neon, a serverless Postgres provider, because it is free, reliable, scales to zero when idle, and gives us both a pooled connection (for serverless functions) and a direct connection (for migrations) out of the box.

Design principles:
- Stock is the master record (ticker, name, sector, and REIT-specific fields)
- Price stores daily OHLCV bars (our own historical cache, refreshed from external APIs)
- Dividend stores historical and upcoming dividend and distribution events
- Watchlist and Alert are user-scoped (tied to a Clerk userId)
- NewsItem stores fetched news headlines plus AI sentiment

## Step 1: Create a free Neon project

1. Go to neon.tech, sign up free, create a new project. Pick a region close to you or close to where you will deploy on Vercel.
2. In the Neon console, open your project's Connection Details panel.
3. Neon gives you a single connection string by default, but for Prisma we want two variants:
   - The pooled connection string (uses PgBouncer, has `-pooler` in the hostname) becomes DATABASE_URL, used at runtime by the app.
   - The direct (unpooled) connection string becomes DIRECT_URL, used only for running migrations.
4. Paste both into .env.local:

```bash
DATABASE_URL="postgresql://neondb_owner:PASSWORD@ep-example-12345-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
DIRECT_URL="postgresql://neondb_owner:PASSWORD@ep-example-12345.ap-southeast-1.aws.neon.tech/neondb?sslmode=require"
```

Notice the only difference between the two hostnames is the `-pooler` segment — Neon's dashboard usually shows you both variants directly, so you can copy them without editing anything by hand. `sslmode=require` is mandatory for Neon.

## Step 2: Initialize Prisma

```bash
npx prisma init
```

This creates prisma/schema.prisma. Replace its contents with:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

enum Sector {
  BANKS
  REITS
  TECH
  TELCO
  INDUSTRIALS
  CONSUMER
  HEALTHCARE
  ENERGY
  ETF
  OTHER
}

model Stock {
  ticker      String   @id
  name        String
  sector      Sector   @default(OTHER)
  isReit      Boolean  @default(false)
  currency    String   @default("SGD")
  exchange    String   @default("SGX")

  peRatio       Float?
  marketCap     Float?
  dividendYield Float?
  week52High    Float?
  week52Low     Float?

  dpu             Float?
  nav             Float?
  gearingRatio    Float?
  occupancyRate   Float?

  updatedAt DateTime @updatedAt
  createdAt DateTime @default(now())

  prices    Price[]
  dividends Dividend[]
  news      NewsItem[]
  watchlist WatchlistItem[]
  alerts    Alert[]

  @@index([sector])
}

model Price {
  id       Int      @id @default(autoincrement())
  ticker   String
  stock    Stock    @relation(fields: [ticker], references: [ticker], onDelete: Cascade)
  date     DateTime
  open     Float
  high     Float
  low      Float
  close    Float
  volume   BigInt

  @@unique([ticker, date])
  @@index([ticker, date])
}

model Dividend {
  id           Int      @id @default(autoincrement())
  ticker       String
  stock        Stock    @relation(fields: [ticker], references: [ticker], onDelete: Cascade)
  exDate       DateTime
  payDate      DateTime?
  amount       Float
  isForecast   Boolean  @default(false)

  @@unique([ticker, exDate])
  @@index([ticker, exDate])
}

model NewsItem {
  id          Int      @id @default(autoincrement())
  ticker      String?
  stock       Stock?   @relation(fields: [ticker], references: [ticker], onDelete: SetNull)
  title       String
  url         String   @unique
  source      String
  publishedAt DateTime
  sentiment   String?
  sentimentReason String?

  @@index([ticker, publishedAt])
}

model WatchlistItem {
  id         Int      @id @default(autoincrement())
  userId     String
  ticker     String
  stock      Stock    @relation(fields: [ticker], references: [ticker], onDelete: Cascade)
  alertPrice Float?
  createdAt  DateTime @default(now())

  @@unique([userId, ticker])
  @@index([userId])
}

model Alert {
  id          Int      @id @default(autoincrement())
  userId      String
  ticker      String
  stock       Stock    @relation(fields: [ticker], references: [ticker], onDelete: Cascade)
  targetPrice Float
  direction   String   @default("above")
  triggered   Boolean  @default(false)
  triggeredAt DateTime?
  createdAt   DateTime @default(now())

  @@index([userId])
  @@index([ticker, triggered])
}
```

This schema is fully identical regardless of which Postgres host you use — Neon or otherwise — because Prisma abstracts the provider away almost entirely once the connection strings are set. The only Neon-specific detail is the pooled-versus-direct URL split in Step 1.

Notes on design decisions:
- Price.volume is BigInt because SGX daily volumes can exceed the safe integer range for some heavily traded counters over long periods when summed; Prisma maps this to a JS bigint.
- Stock.sector is an enum for fast filtering in the sector heatmap (Part 12).
- Dividend.isForecast lets us show projected upcoming distributions (common for REITs, which pay quarterly or semi-annually) separately from confirmed historical ones.
- WatchlistItem and Alert are separate models: a watchlist item is "stocks I'm tracking", an alert is "notify me when price crosses X" — a user can watch a stock without setting an alert, or set multiple alerts.

## Step 3: Push the schema and generate the client

Since we're prototyping (no production data yet), use db push for now (we'll switch to a proper migrate workflow once deployed in Part 21):

```bash
npx prisma db push
npx prisma generate
```

You should see confirmation that your database schema is in sync with Neon.

## Step 4: Create the Prisma client singleton

Create src/lib/prisma.ts:

```typescript
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

This singleton pattern prevents Next.js hot-reload from creating dozens of Prisma Client instances in development, which is a very common beginner bug and also the source of most "too many connections" errors people hit against Neon's pooled connection limit.

A note on Neon plus serverless: Neon's pooled connection string already routes through PgBouncer, so this standard Prisma setup works correctly in Vercel's serverless functions without any extra driver adapter. If you later want edge-runtime compatibility (Prisma running inside an Edge Function rather than a Node serverless function), Neon also offers an HTTP-based driver via the `@neondatabase/serverless` package installed in Part 2, paired with Prisma's `@prisma/adapter-neon` — this is an optional upgrade path, not required for anything in this tutorial, since none of our routes run on the Edge runtime.

## Step 5: Seed a handful of SGX stocks

Create prisma/seed.ts:

```typescript
import { PrismaClient, Sector } from "@prisma/client";

const prisma = new PrismaClient();

const seedStocks = [
  { ticker: "D05.SI", name: "DBS Group Holdings", sector: Sector.BANKS },
  { ticker: "O39.SI", name: "Oversea-Chinese Banking Corp", sector: Sector.BANKS },
  { ticker: "U11.SI", name: "United Overseas Bank", sector: Sector.BANKS },
  { ticker: "Z74.SI", name: "Singapore Telecommunications", sector: Sector.TELCO },
  { ticker: "C38U.SI", name: "CapitaLand Integrated Commercial Trust", sector: Sector.REITS, isReit: true },
  { ticker: "A17U.SI", name: "CapitaLand Ascendas REIT", sector: Sector.REITS, isReit: true },
  { ticker: "ES3.SI", name: "SPDR Straits Times Index ETF", sector: Sector.ETF },
  { ticker: "Y92.SI", name: "Thai Beverage", sector: Sector.CONSUMER },
  { ticker: "S68.SI", name: "Singapore Exchange (SGX)", sector: Sector.OTHER },
  { ticker: "9CI.SI", name: "CapitaLand Investment", sector: Sector.OTHER },
];

async function main() {
  for (const s of seedStocks) {
    await prisma.stock.upsert({
      where: { ticker: s.ticker },
      update: s,
      create: s,
    });
  }
  console.log(`Seeded ${seedStocks.length} stocks`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Add a script to package.json:

```json
{
  "scripts": {
    "seed": "tsx prisma/seed.ts"
  },
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

tsx was already installed in Part 2.

Run the seed:

```bash
npx prisma db seed
```

## Step 6: Inspect your data with Prisma Studio

```bash
npx prisma studio
```

This opens a GUI at http://localhost:5555 where you can browse and edit rows. Confirm your 10 seed stocks appear in the Stock table. Prisma Studio works identically against Neon as it would against any other Postgres host.

## Checkpoint

- [ ] Neon project created, pooled connection string saved as DATABASE_URL and direct connection string saved as DIRECT_URL in .env.local
- [ ] `npx prisma db push` runs successfully against Neon
- [ ] src/lib/prisma.ts singleton created
- [ ] Seed script runs and inserts 10 SGX stocks
- [ ] `npx prisma studio` shows the seeded data

Next: Part 4, Data Ingestion Foundations, where we write our first real data-fetching code using yahoo-finance2 to pull live quotes and historical OHLCV bars for .SI tickers.
