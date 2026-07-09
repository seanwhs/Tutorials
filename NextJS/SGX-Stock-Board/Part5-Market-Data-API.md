# Part 5: Free Market Data APIs (Finnhub Fallback + Normalization Layer)

## Concept

Relying on a single unofficial data source is risky — `yahoo-finance2` can occasionally break when Yahoo changes internal endpoints. We add **Finnhub's free tier** as a fallback. This also teaches a genuinely useful real-world pattern: a **provider-agnostic data layer with automatic failover**.

Free tier facts for Finnhub (as of writing): 60 API calls/minute, supports global exchanges including SGX (symbols formatted as `D05.SI` too, conveniently matching Yahoo's convention in most cases).

## Step 1: Get a free Finnhub API key

1. Go to finnhub.io, sign up free.
2. Copy your API key from the dashboard.
3. Add it to `.env.local`:

```bash
FINNHUB_API_KEY="your_key_here"
```

## Step 2: The Finnhub wrapper

Create `src/lib/data-sources/finnhub.ts`:

```typescript
// src/lib/data-sources/finnhub.ts
import type { Quote, OhlcvBar, Range } from "@/types/stock";

const FINNHUB_BASE = "https://finnhub.io/api/v1";

function apiKey(): string {
  const key = process.env.FINNHUB_API_KEY;
  if (!key) throw new Error("FINNHUB_API_KEY is not set");
  return key;
}

async function finnhubFetch(path: string, params: Record<string, string>) {
  const url = new URL(`${FINNHUB_BASE}${path}`);
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));
  url.searchParams.set("token", apiKey());

  const res = await fetch(url.toString());
  if (!res.ok) {
    throw new Error(`Finnhub error ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

export async function fetchFinnhubQuote(ticker: string): Promise<Quote> {
  const q = await finnhubFetch("/quote", { symbol: ticker });

  if (!q || q.c == null || q.c === 0) {
    throw new Error(`No Finnhub quote for ${ticker}`);
  }

  return {
    ticker,
    price: q.c,
    change: q.d ?? 0,
    changePercent: q.dp ?? 0,
    open: q.o ?? q.c,
    high: q.h ?? q.c,
    low: q.l ?? q.c,
    previousClose: q.pc ?? q.c,
    volume: 0, // Finnhub /quote doesn't include volume; left to caller to merge if needed
    currency: "SGD",
    asOf: new Date().toISOString(),
  };
}

function rangeToUnixRange(range: Range): { from: number; to: number; resolution: string } {
  const to = Math.floor(Date.now() / 1000);
  const day = 86400;
  switch (range) {
    case "1D":
      return { from: to - 5 * day, to, resolution: "60" };
    case "5D":
      return { from: to - 10 * day, to, resolution: "D" };
    case "1M":
      return { from: to - 31 * day, to, resolution: "D" };
    case "6M":
      return { from: to - 183 * day, to, resolution: "D" };
    case "1Y":
      return { from: to - 365 * day, to, resolution: "D" };
    case "5Y":
      return { from: to - 5 * 365 * day, to, resolution: "W" };
  }
}

export async function fetchFinnhubHistory(ticker: string, range: Range): Promise<OhlcvBar[]> {
  const { from, to, resolution } = rangeToUnixRange(range);
  const data = await finnhubFetch("/stock/candle", {
    symbol: ticker,
    resolution,
    from: String(from),
    to: String(to),
  });

  if (data.s !== "ok" || !Array.isArray(data.t)) {
    throw new Error(`No Finnhub candle data for ${ticker}`);
  }

  return data.t.map((ts: number, i: number) => ({
    date: new Date(ts * 1000).toISOString().slice(0, 10),
    open: data.o[i],
    high: data.h[i],
    low: data.l[i],
    close: data.c[i],
    volume: data.v[i],
  }));
}
```

Note: Finnhub's free tier candle endpoint has historically had limited coverage for some non-US exchanges. This is exactly why it's our **fallback**, not primary — SGX coverage varies, so we lean on Yahoo first and only reach for Finnhub when Yahoo fails.

## Step 3: The unified data-source layer with automatic failover

Create `src/lib/data-sources/index.ts`:

```typescript
// src/lib/data-sources/index.ts
import type { Quote, OhlcvBar, Range } from "@/types/stock";
import { fetchYahooQuote, fetchYahooHistory } from "./yahoo";
import { fetchFinnhubQuote, fetchFinnhubHistory } from "./finnhub";

interface FetchResult<T> {
  data: T;
  source: "yahoo" | "finnhub";
}

async function withFallback<T>(
  primary: () => Promise<T>,
  fallback: () => Promise<T>,
  label: string
): Promise<FetchResult<T>> {
  try {
    const data = await primary();
    return { data, source: "yahoo" };
  } catch (yahooError) {
    console.warn(`[data-sources] Yahoo failed for ${label}:`, (yahooError as Error).message);
    try {
      const data = await fallback();
      return { data, source: "finnhub" };
    } catch (finnhubError) {
      console.error(`[data-sources] Finnhub also failed for ${label}:`, (finnhubError as Error).message);
      throw new Error(`All data sources failed for ${label}`);
    }
  }
}

export async function getQuote(ticker: string): Promise<FetchResult<Quote>> {
  return withFallback(
    () => fetchYahooQuote(ticker),
    () => fetchFinnhubQuote(ticker),
    `quote(${ticker})`
  );
}

export async function getHistory(ticker: string, range: Range): Promise<FetchResult<OhlcvBar[]>> {
  return withFallback(
    () => fetchYahooHistory(ticker, range),
    () => fetchFinnhubHistory(ticker, range),
    `history(${ticker}, ${range})`
  );
}
```

This is the **only** module the rest of our app should import for live market data. It guarantees:
- We try Yahoo first (best SGX coverage, no key needed)
- We automatically fall back to Finnhub if Yahoo throws
- If both fail, we get one clear error instead of a confusing crash
- Callers can inspect `source` for debugging/logging, but don't need to care which provider actually answered

## Step 4: A note on SGX StockFacts scraping (optional, advanced)

The original brief mentions optionally scraping SGX StockFacts for fundamentals (DPU, NAV, gearing ratio for REITs — data that neither Yahoo nor Finnhub's free tier reliably provides). We cover this properly in **Part 15 (REIT Focus Tab)**, where we build a dedicated, narrowly-scoped scraper with caching and clear fallbacks to manual/seeded data if scraping fails. We mention it here so you know it's coming — we don't want to scrape prematurely before we know exactly which fields we need.

A general rule we follow in this series: **never let a scraper be a hard dependency**. If SGX StockFacts changes its HTML structure, our app should degrade gracefully (e.g., show cached data or "data unavailable") rather than crash.

## Step 5: Test the fallback layer

Create `scripts/test-data-sources.ts`:

```typescript
// scripts/test-data-sources.ts
import { getQuote, getHistory } from "../src/lib/data-sources";

async function main() {
  const { data: quote, source } = await getQuote("D05.SI");
  console.log(`Quote from ${source}:`, quote);

  const { data: history, source: histSource } = await getHistory("D05.SI", "1M");
  console.log(`History (1M) from ${histSource}: ${history.length} bars`);
}

main().catch(console.error);
```

```bash
npx tsx scripts/test-data-sources.ts
```

To manually verify the fallback works, temporarily rename a function inside `yahoo.ts` (e.g. typo the ticker being passed, or throw an error at the top of `fetchYahooQuote`) and re-run — you should see the console warning and a successful Finnhub result instead. Remember to revert your temporary change afterward!

## Checkpoint

- [ ] Finnhub API key obtained and added to `.env.local`
- [ ] `src/lib/data-sources/finnhub.ts` created
- [ ] `src/lib/data-sources/index.ts` created with `withFallback` logic
- [ ] Test script confirms Yahoo is used normally, and Finnhub kicks in when Yahoo is forced to fail
- [ ] You understand why scraping SGX StockFacts is deferred to Part 15 and must always be optional/degradable

Next: **Part 6 — Caching Layer (Upstash Redis)**, where we wrap `getQuote`/`getHistory` with a 15-minute cache to avoid hammering these free APIs and to keep our app fast.
