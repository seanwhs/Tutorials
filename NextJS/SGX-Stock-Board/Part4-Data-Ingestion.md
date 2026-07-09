# Part 4: Data Ingestion Foundations (yahoo-finance2, .SI tickers)

## Concept

`yahoo-finance2` is an unofficial but well-maintained npm wrapper around Yahoo Finance's public endpoints. It requires no API key, has generous rate limits for personal/prototype use, and — crucially for us — supports `.SI` suffixed SGX tickers out of the box. We'll build a thin wrapper module around it so the rest of our app never talks to `yahoo-finance2` directly (this makes swapping/adding providers in Part 5 painless).

## Step 1: A central ticker list

Create `src/lib/tickers.ts` — a small curated list of SGX tickers we support, used for search/autocomplete and validation:

```typescript
// src/lib/tickers.ts
export interface TickerInfo {
  ticker: string; // e.g. "D05.SI"
  name: string;
  sector: string;
  isReit?: boolean;
}

export const SGX_TICKERS: TickerInfo[] = [
  { ticker: "D05.SI", name: "DBS Group Holdings", sector: "BANKS" },
  { ticker: "O39.SI", name: "Oversea-Chinese Banking Corp", sector: "BANKS" },
  { ticker: "U11.SI", name: "United Overseas Bank", sector: "BANKS" },
  { ticker: "Z74.SI", name: "Singapore Telecommunications", sector: "TELCO" },
  { ticker: "C38U.SI", name: "CapitaLand Integrated Commercial Trust", sector: "REITS", isReit: true },
  { ticker: "A17U.SI", name: "CapitaLand Ascendas REIT", sector: "REITS", isReit: true },
  { ticker: "ES3.SI", name: "SPDR Straits Times Index ETF", sector: "ETF" },
  { ticker: "Y92.SI", name: "Thai Beverage", sector: "CONSUMER" },
  { ticker: "S68.SI", name: "Singapore Exchange (SGX)", sector: "OTHER" },
  { ticker: "9CI.SI", name: "CapitaLand Investment", sector: "OTHER" },
];

export function isKnownTicker(ticker: string): boolean {
  return SGX_TICKERS.some((t) => t.ticker.toUpperCase() === ticker.toUpperCase());
}

export function normalizeTicker(input: string): string {
  const trimmed = decodeURIComponent(input).trim().toUpperCase();
  return trimmed.endsWith(".SI") ? trimmed : `${trimmed}.SI`;
}
```

We keep this list small and curated for the tutorial, but in Step 5 below we show how to accept *any* `.SI` ticker, not just the seeded ones.

## Step 2: Define our normalized data types

Create `src/types/stock.ts`:

```typescript
// src/types/stock.ts
export interface Quote {
  ticker: string;
  price: number;
  change: number;
  changePercent: number;
  open: number;
  high: number;
  low: number;
  previousClose: number;
  volume: number;
  marketCap?: number;
  peRatio?: number;
  dividendYield?: number;
  week52High?: number;
  week52Low?: number;
  currency: string;
  asOf: string; // ISO timestamp
}

export interface OhlcvBar {
  date: string; // ISO date (yyyy-MM-dd)
  open: number;
  high: number;
  low: number;
  close: number;
  volume: number;
}

export type Range = "1D" | "5D" | "1M" | "6M" | "1Y" | "5Y";
```

## Step 3: The yahoo-finance2 wrapper

Create `src/lib/data-sources/yahoo.ts`:

```typescript
// src/lib/data-sources/yahoo.ts
import yahooFinance from "yahoo-finance2";
import type { Quote, OhlcvBar, Range } from "@/types/stock";

// yahoo-finance2 logs some noisy validation warnings by default; keep it quiet.
yahooFinance.suppressNotices(["ripHistorical", "yahooSurvey"]);

export async function fetchYahooQuote(ticker: string): Promise<Quote> {
  const q = await yahooFinance.quote(ticker);

  if (!q || q.regularMarketPrice == null) {
    throw new Error(`No quote data returned for ${ticker}`);
  }

  return {
    ticker,
    price: q.regularMarketPrice,
    change: q.regularMarketChange ?? 0,
    changePercent: q.regularMarketChangePercent ?? 0,
    open: q.regularMarketOpen ?? q.regularMarketPrice,
    high: q.regularMarketDayHigh ?? q.regularMarketPrice,
    low: q.regularMarketDayLow ?? q.regularMarketPrice,
    previousClose: q.regularMarketPreviousClose ?? q.regularMarketPrice,
    volume: q.regularMarketVolume ?? 0,
    marketCap: q.marketCap ?? undefined,
    peRatio: q.trailingPE ?? undefined,
    dividendYield: q.trailingAnnualDividendYield
      ? q.trailingAnnualDividendYield * 100
      : undefined,
    week52High: q.fiftyTwoWeekHigh ?? undefined,
    week52Low: q.fiftyTwoWeekLow ?? undefined,
    currency: q.currency ?? "SGD",
    asOf: new Date().toISOString(),
  };
}

function rangeToDates(range: Range): { period1: Date; interval: "1d" | "1wk" } {
  const now = new Date();
  const period1 = new Date(now);

  switch (range) {
    case "1D":
      period1.setDate(now.getDate() - 5); // pad so we always get at least 1 trading day
      return { period1, interval: "1d" };
    case "5D":
      period1.setDate(now.getDate() - 10);
      return { period1, interval: "1d" };
    case "1M":
      period1.setMonth(now.getMonth() - 1);
      return { period1, interval: "1d" };
    case "6M":
      period1.setMonth(now.getMonth() - 6);
      return { period1, interval: "1d" };
    case "1Y":
      period1.setFullYear(now.getFullYear() - 1);
      return { period1, interval: "1d" };
    case "5Y":
      period1.setFullYear(now.getFullYear() - 5);
      return { period1, interval: "1wk" };
  }
}

export async function fetchYahooHistory(
  ticker: string,
  range: Range
): Promise<OhlcvBar[]> {
  const { period1, interval } = rangeToDates(range);

  const result = await yahooFinance.chart(ticker, {
    period1,
    period2: new Date(),
    interval,
  });

  return result.quotes
    .filter((q) => q.close != null)
    .map((q) => ({
      date: new Date(q.date).toISOString().slice(0, 10),
      open: q.open ?? q.close!,
      high: q.high ?? q.close!,
      low: q.low ?? q.close!,
      close: q.close!,
      volume: q.volume ?? 0,
    }));
}

export async function searchYahooTicker(query: string) {
  const result = await yahooFinance.search(query, { quotesCount: 10 });
  return result.quotes
    .filter((q: any) => q.symbol?.endsWith(".SI"))
    .map((q: any) => ({
      ticker: q.symbol,
      name: q.shortname || q.longname || q.symbol,
    }));
}
```

Why we wrap it this way:
- Every function returns **our own types** (`Quote`, `OhlcvBar`), never Yahoo's raw shape. This is the key decoupling move — Part 5 adds a Finnhub equivalent that returns the exact same shapes, so the rest of the app doesn't care which provider answered.
- `rangeToDates` centralizes the "1D to 5Y" range logic in one place, used later by both Yahoo and Finnhub wrappers.

## Step 4: A quick manual test script

Create a scratch file `scripts/test-yahoo.ts` (not part of the app, just for learning/debugging):

```typescript
// scripts/test-yahoo.ts
import { fetchYahooQuote, fetchYahooHistory } from "../src/lib/data-sources/yahoo";

async function main() {
  const quote = await fetchYahooQuote("D05.SI");
  console.log("Quote:", quote);

  const history = await fetchYahooHistory("D05.SI", "1M");
  console.log(`History (1M): ${history.length} bars`);
  console.log(history.slice(0, 3));
}

main().catch(console.error);
```

Run it:

```bash
npx tsx scripts/test-yahoo.ts
```

You should see a live DBS quote and a handful of recent daily bars printed to your console. If you get an error like "No quote data returned", double check your internet connection and that you typed `D05.SI` correctly (SGX tickers are case-sensitive on the letters but Yahoo is generally forgiving).

## Step 5: Supporting arbitrary `.SI` tickers (not just the seed list)

Our seed list is for search/autocomplete convenience, but a user should be able to type any valid SGX ticker (e.g. `V03.SI` for Venture Corp) and get real data, since `yahoo-finance2` doesn't restrict us. We'll enforce this rule in our API layer (Part 7): if a ticker isn't in our `Stock` table yet, we do a live Yahoo lookup, and if valid, we `upsert` a new `Stock` row on the fly. This keeps our local database self-populating rather than requiring us to hardcode every SGX counter (there are 600+).

We'll implement that upsert-on-demand logic in Part 7 once we have the API routes and Prisma wired together.

## Checkpoint

- [ ] `src/lib/tickers.ts` and `src/types/stock.ts` created
- [ ] `src/lib/data-sources/yahoo.ts` created
- [ ] `npx tsx scripts/test-yahoo.ts` prints a live DBS (D05.SI) quote and historical bars
- [ ] You understand why we normalize provider responses into our own `Quote`/`OhlcvBar` types

Next: **Part 5 — Free Market Data APIs**, where we add Finnhub as a fallback provider and build a resilient "try primary, fall back to secondary" data-fetching strategy.
