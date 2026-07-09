# Part 6: Caching Layer (Upstash Redis)

## Concept

Free-tier APIs (Yahoo unofficially, Finnhub officially at 60 req/min) can rate-limit us if every page view triggers a fresh network call. We add a **15-minute cache** using Upstash Redis — a serverless-friendly, REST-based Redis that works perfectly in Vercel's serverless/edge functions (no persistent TCP connections needed, unlike traditional Redis clients).

Caching strategy:
- Cache key pattern: `quote:{ticker}`, `history:{ticker}:{range}`
- TTL: 15 minutes for quotes and short ranges, longer for 5Y history (which barely changes intraday)
- Cache-aside pattern: check cache → if miss, fetch from `data-sources` → write to cache → return

## Step 1: Create a free Upstash Redis database

1. Go to upstash.com, sign up free.
2. Create a new Redis database (choose a region close to your Vercel deployment region, e.g. Singapore or a nearby AWS region).
3. Copy the **REST URL** and **REST Token** from the database details page.
4. Add to `.env.local`:

```bash
UPSTASH_REDIS_REST_URL="https://xxxx.upstash.io"
UPSTASH_REDIS_REST_TOKEN="xxxx"
```

## Step 2: The Redis client

Create `src/lib/redis.ts`:

```typescript
// src/lib/redis.ts
import { Redis } from "@upstash/redis";

export const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

export const CACHE_TTL = {
  QUOTE: 60 * 15,          // 15 minutes
  HISTORY_SHORT: 60 * 15,  // 1D/5D/1M
  HISTORY_LONG: 60 * 60 * 4, // 6M/1Y/5Y — refresh every 4 hours is plenty
  NEWS: 60 * 30,           // 30 minutes (Part 17)
  AI_SUMMARY: 60 * 30,     // 30 minutes (Part 14)
  DIVIDENDS: 60 * 60 * 24, // 24 hours (Part 11)
} as const;

/**
 * Generic cache-aside helper: try Redis first, otherwise call `fetcher`,
 * store the result, and return it.
 */
export async function cached<T>(
  key: string,
  ttlSeconds: number,
  fetcher: () => Promise<T>
): Promise<{ data: T; cacheHit: boolean }> {
  const cachedValue = await redis.get<T>(key);
  if (cachedValue !== null && cachedValue !== undefined) {
    return { data: cachedValue, cacheHit: true };
  }

  const fresh = await fetcher();
  await redis.set(key, fresh, { ex: ttlSeconds });
  return { data: fresh, cacheHit: false };
}
```

## Step 3: Wrap our data-sources layer with caching

Update `src/lib/data-sources/index.ts` to add cached versions (keep the raw versions too, useful for Part 19's alert-checking cron which wants to bypass cache):

```typescript
// src/lib/data-sources/index.ts (additions)
import { cached, CACHE_TTL } from "@/lib/redis";
import type { Range } from "@/types/stock";

// ...(keep getQuote / getHistory from Part 5 above)...

export async function getCachedQuote(ticker: string) {
  return cached(`quote:${ticker}`, CACHE_TTL.QUOTE, async () => {
    const { data } = await getQuote(ticker);
    return data;
  });
}

export async function getCachedHistory(ticker: string, range: Range) {
  const isLongRange = range === "6M" || range === "1Y" || range === "5Y";
  const ttl = isLongRange ? CACHE_TTL.HISTORY_LONG : CACHE_TTL.HISTORY_SHORT;

  return cached(`history:${ticker}:${range}`, ttl, async () => {
    const { data } = await getHistory(ticker, range);
    return data;
  });
}
```

From here on, our API routes (Part 7) will call `getCachedQuote` / `getCachedHistory`, not the raw versions — except for the alert-checking cron job in Part 19, which intentionally needs the freshest possible price and will call `getQuote` directly.

## Step 4: The stock resolution service

Create `src/lib/stock-service.ts` now, since every route from Part 7 onward depends on it:

```typescript
// src/lib/stock-service.ts
import { prisma } from "@/lib/prisma";
import { getCachedQuote } from "@/lib/data-sources";
import { normalizeTicker } from "@/lib/tickers";
import { Sector } from "@prisma/client";

export async function resolveStock(rawTicker: string) {
  const ticker = normalizeTicker(rawTicker);

  let stock = await prisma.stock.findUnique({ where: { ticker } });
  if (stock) return stock;

  // Unknown ticker — validate it's real by fetching a live quote, then create it.
  const { data: quote } = await getCachedQuote(ticker);

  stock = await prisma.stock.upsert({
    where: { ticker },
    update: {
      peRatio: quote.peRatio,
      marketCap: quote.marketCap,
      dividendYield: quote.dividendYield,
      week52High: quote.week52High,
      week52Low: quote.week52Low,
    },
    create: {
      ticker,
      name: ticker, // we don't know the full name yet; refined later via search results
      sector: Sector.OTHER,
      currency: quote.currency,
      peRatio: quote.peRatio,
      marketCap: quote.marketCap,
      dividendYield: quote.dividendYield,
      week52High: quote.week52High,
      week52Low: quote.week52Low,
    },
  });

  return stock;
}
```

This is the "upsert unknown ticker on first lookup" logic promised in Part 4 — it keeps our `Stock` table self-populating.

## Step 5: Test the cache

Create `scripts/test-cache.ts`:

```typescript
// scripts/test-cache.ts
import { getCachedQuote } from "../src/lib/data-sources";

async function main() {
  console.time("first call");
  const first = await getCachedQuote("D05.SI");
  console.timeEnd("first call");
  console.log("Cache hit?", first.cacheHit); // expect false

  console.time("second call");
  const second = await getCachedQuote("D05.SI");
  console.timeEnd("second call");
  console.log("Cache hit?", second.cacheHit); // expect true, and much faster
}

main().catch(console.error);
```

```bash
npx tsx scripts/test-cache.ts
```

You should see the first call take several hundred milliseconds (real network round-trip to Yahoo) and the second call resolve almost instantly with `cacheHit: true`.

## Step 6: A note on cache invalidation

We deliberately keep this simple with TTL-based expiry only (no manual invalidation) because:
- Stock prices are naturally time-sensitive — a 15-minute-old quote being served for up to 15 more minutes is an acceptable trade-off for a retail-investor dashboard (this isn't a high-frequency trading tool).
- It avoids the complexity of cache invalidation logic, which is famously one of the two hard problems in computer science.

If you want fresher data for a "Refresh" button in the UI later, the simplest approach is to accept a `?force=true` query param on the API route and call the raw (uncached) `getQuote`/`getHistory` directly, then overwrite the Redis key — we'll wire this in Part 7.

## Checkpoint

- [ ] Upstash Redis database created, REST URL/token in `.env.local`
- [ ] `src/lib/redis.ts` created with `cached()` helper
- [ ] `getCachedQuote` / `getCachedHistory` added to the data-sources layer
- [ ] `src/lib/stock-service.ts` created with `resolveStock`
- [ ] Test script confirms first call is a cache miss, second call is a cache hit and near-instant

Next: **Part 7 — Core API Routes**, where we finally build the actual Next.js route handlers (`/api/stocks/[ticker]/quote`, `/history`) that the frontend will call.
