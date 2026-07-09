# Part 7: Core API Routes (search, quote, history, dividends)

> **Next.js 16 note:** Route Handler `params` are asynchronous (`Promise`-based) in current Next.js. Every dynamic route below types `params` as `Promise<{ ticker: string }>` and `await`s it before use — this is the correct, required pattern for the version of Next.js this series targets.

## Concept

Now we wire everything together into actual Next.js Route Handlers that the frontend calls. Each route:
1. Validates input with `zod`
2. Resolves/creates the `Stock` row in Postgres if it doesn't exist yet (self-populating database, via `resolveStock` from Part 6)
3. Fetches cached quote/history data
4. Returns clean JSON

## Step 1: Quote route

Create `src/app/api/stocks/[ticker]/quote/route.ts`:

```typescript
// src/app/api/stocks/[ticker]/quote/route.ts
import { NextRequest, NextResponse } from "next/server";
import { getCachedQuote, getQuote } from "@/lib/data-sources";
import { resolveStock } from "@/lib/stock-service";
import { normalizeTicker } from "@/lib/tickers";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  try {
    const { ticker: rawTicker } = await params;
    const ticker = normalizeTicker(rawTicker);
    const forceRefresh = req.nextUrl.searchParams.get("force") === "true";

    // Ensure the stock exists in our DB (creates it on first lookup if needed).
    await resolveStock(ticker);

    if (forceRefresh) {
      const { data, source } = await getQuote(ticker);
      return NextResponse.json({ ...data, source, cached: false });
    }

    const { data, cacheHit } = await getCachedQuote(ticker);
    return NextResponse.json({ ...data, cached: cacheHit });
  } catch (err) {
    console.error("[api/quote] error:", err);
    return NextResponse.json(
      { error: (err as Error).message || "Failed to fetch quote" },
      { status: 502 }
    );
  }
}
```

Note the signature: `{ params }: { params: Promise<{ ticker: string }> }` followed by `const { ticker: rawTicker } = await params;` inside the function body. This `Promise`-based params pattern applies to **every** dynamic route handler in this series.

## Step 2: History route

Create `src/app/api/stocks/[ticker]/history/route.ts`:

```typescript
// src/app/api/stocks/[ticker]/history/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getCachedHistory } from "@/lib/data-sources";
import { resolveStock } from "@/lib/stock-service";
import { normalizeTicker } from "@/lib/tickers";
import { prisma } from "@/lib/prisma";

const RangeSchema = z.enum(["1D", "5D", "1M", "6M", "1Y", "5Y"]);

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  try {
    const { ticker: rawTicker } = await params;
    const ticker = normalizeTicker(rawTicker);
    const rangeParam = req.nextUrl.searchParams.get("range") ?? "6M";
    const range = RangeSchema.parse(rangeParam);

    await resolveStock(ticker);

    const { data: bars, cacheHit } = await getCachedHistory(ticker, range);

    // Fire-and-forget: persist bars to Postgres for our own historical archive.
    // We don't await this on the response path so the API stays fast.
    void persistBars(ticker, bars).catch((e) =>
      console.error("[api/history] persist error:", e)
    );

    return NextResponse.json({ ticker, range, bars, cached: cacheHit });
  } catch (err) {
    console.error("[api/history] error:", err);
    return NextResponse.json(
      { error: (err as Error).message || "Failed to fetch history" },
      { status: 502 }
    );
  }
}

async function persistBars(ticker: string, bars: { date: string; open: number; high: number; low: number; close: number; volume: number }[]) {
  await prisma.$transaction(
    bars.map((bar) =>
      prisma.price.upsert({
        where: { ticker_date: { ticker, date: new Date(bar.date) } },
        update: {
          open: bar.open,
          high: bar.high,
          low: bar.low,
          close: bar.close,
          volume: BigInt(Math.round(bar.volume)),
        },
        create: {
          ticker,
          date: new Date(bar.date),
          open: bar.open,
          high: bar.high,
          low: bar.low,
          close: bar.close,
          volume: BigInt(Math.round(bar.volume)),
        },
      })
    )
  );
}
```

Note the `ticker_date` compound key name — Prisma auto-generates this name from the `@@unique([ticker, date])` constraint we defined in Part 3 (field names joined with underscore).

## Step 3: Search route (for the ticker search box)

Create `src/app/api/stocks/search/route.ts`. This route has no dynamic segment (no `[ticker]` in its path), so it takes no `params` at all — no async params handling needed here:

```typescript
// src/app/api/stocks/search/route.ts
import { NextRequest, NextResponse } from "next/server";
import { SGX_TICKERS } from "@/lib/tickers";
import { searchYahooTicker } from "@/lib/data-sources/yahoo";

export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q")?.trim() ?? "";
  if (q.length < 1) return NextResponse.json({ results: [] });

  // 1. Search our curated local list first (instant, no network call)
  const localMatches = SGX_TICKERS.filter(
    (t) =>
      t.ticker.toLowerCase().includes(q.toLowerCase()) ||
      t.name.toLowerCase().includes(q.toLowerCase())
  );

  if (localMatches.length > 0) {
    return NextResponse.json({ results: localMatches, source: "local" });
  }

  // 2. Fall back to a live Yahoo search for tickers we don't have curated
  try {
    const remoteMatches = await searchYahooTicker(q);
    return NextResponse.json({ results: remoteMatches, source: "yahoo" });
  } catch (err) {
    console.error("[api/stocks/search] error:", err);
    return NextResponse.json({ results: [], error: "search failed" });
  }
}
```

## Step 4: Dividends route (stub for now, full logic in Part 11)

Create `src/app/api/stocks/[ticker]/dividends/route.ts`:

```typescript
// src/app/api/stocks/[ticker]/dividends/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);
  await resolveStock(ticker);

  const dividends = await prisma.dividend.findMany({
    where: { ticker },
    orderBy: { exDate: "desc" },
  });

  return NextResponse.json({ ticker, dividends });
}
```

This will return an empty array until Part 11, where we build the actual dividend-fetching logic (Yahoo Finance provides historical dividend data too, via its `historical`/`chart` events).

## Step 5: Test the routes

```bash
npm run dev
```

In another terminal, or via your browser:

```bash
curl "http://localhost:3000/api/stocks/D05.SI/quote"
curl "http://localhost:3000/api/stocks/D05.SI/history?range=1M"
curl "http://localhost:3000/api/stocks/search?q=DBS"
curl "http://localhost:3000/api/stocks/D05.SI/dividends"
```

You should get real JSON quote data, an array of OHLCV bars, a search match for DBS, and an empty dividends array respectively.

Also check Prisma Studio (`npx prisma studio`) — the `Price` table should now be populating with real historical bars, and if you queried a brand-new ticker not in your seed list (e.g. `curl .../V03.SI/quote`), the `Stock` table should have gained a new row automatically.

## Checkpoint

- [ ] Quote, history, search, and dividends (stub) routes created, all using the `Promise<{ ticker: string }>` params pattern for dynamic routes
- [ ] All four `curl` tests return sensible JSON
- [ ] Querying an unseeded ticker auto-creates a `Stock` row
- [ ] `Price` rows are being persisted to Postgres after a history call

Next: **Part 8 — Price & Volume Charts**, where we finally build the frontend: a real candlestick chart with TradingView Lightweight Charts v5, a line-chart mode, volume bars, and range selector buttons (1D to 5Y).
