# Part 20: Testing, Error Handling, and Rate-Limit Resilience

## Concept

Before deploying, we harden the app: consistent error boundaries so one bad API response doesn't crash a whole page, loading states everywhere data is fetched, defensive handling of every external dependency (Yahoo, Finnhub, Upstash, Clerk, Resend, AI providers, RSS feeds), and a lightweight automated test suite covering the pure calculation logic we've built (RSI/MACD, DCA math, backtest engine, CPF/SRS simulator) since these are the parts most sensitive to subtle bugs.

## Step 1: Vitest setup

`vitest` was installed in Part 2. Add a script to `package.json`:

```json
{
  "scripts": {
    "test": "vitest run"
  }
}
```

## Step 2: Unit tests for pure calculation modules

Create `src/lib/indicators/rsi.test.ts`, `src/lib/indicators/macd.test.ts`, `src/lib/dca-calculator.test.ts`, `src/lib/backtest/engine.test.ts`, and `src/lib/cpf-srs-simulator.test.ts`. For each, write tests against small, hand-computable synthetic datasets (e.g., a 20-day array of prices you construct so you can manually verify the expected RSI value), rather than relying on live API data, so tests are fast, deterministic, and don't burn API quota. Cover edge cases explicitly: empty input arrays, input shorter than the required period (should return an empty result rather than throwing), and all-flat price series (RSI should not divide by zero when average loss is zero — verify the guard clause we wrote in Part 10 actually works).

Example:

```typescript
// src/lib/indicators/rsi.test.ts
import { describe, expect, it } from "vitest";
import { calculateRSI } from "./rsi";

const bars = Array.from({ length: 30 }, (_, i) => ({
  date: `2024-01-${String(i + 1).padStart(2, "0")}`,
  open: 100 + i,
  high: 100 + i,
  low: 100 + i,
  close: 100 + i,
  volume: 1000,
}));

describe("calculateRSI", () => {
  it("returns points once enough bars exist", () => {
    expect(calculateRSI(bars).length).toBeGreaterThan(0);
  });

  it("returns an empty array when too few bars exist", () => {
    expect(calculateRSI(bars.slice(0, 5))).toEqual([]);
  });
});
```

Run:

```bash
npm test
```

## Step 3: A shared API error-response helper

Create `src/lib/api-error.ts` to standardize how every route handler reports failures:

```typescript
// src/lib/api-error.ts
import { NextResponse } from "next/server";

export function apiError(message: string, status = 502) {
  console.error(`[api-error] ${status}: ${message}`);
  return NextResponse.json({ error: message }, { status });
}
```

Go back through every route handler built in Parts 7, 11-19 and replace ad-hoc `NextResponse.json({ error: ... })` calls with this shared helper, so error responses are consistently shaped `{ error: string }` and always logged server-side — this makes debugging production issues via Vercel's function logs much easier. This is a pure refactor of response bodies; it doesn't touch how any route reads its (already-awaited, per Part 7) `params`.

## Step 4: A shared client-side error/loading pattern

Most of our hooks (`use-quote`, `use-stock-history`, `use-indicators`) already follow a `{ data, loading, error }` shape. Create a small reusable `<AsyncBoundary>` component in `src/components/async-boundary.tsx` that takes `loading`, `error`, and `children`, rendering a `Skeleton` while loading, a consistent error card (with a "Try again" button wired to a passed-in `onRetry` callback) on error, and `children` otherwise. Retrofit the panels built in Parts 8-17 (chart card, metrics panel, indicators, dividend tracker, heatmap, backtest panel, AI summary, REIT panel, news feed, watchlist table) to use this shared component instead of each hand-rolling its own loading/error markup.

## Step 5: A Next.js error boundary and not-found page

Create `src/app/error.tsx` (a client component implementing Next.js's route-level error boundary) that catches any unhandled render error within a route segment and shows a friendly "Something went wrong" screen with a reset button, rather than a blank white screen or a raw stack trace in production.

Create `src/app/not-found.tsx` for invalid routes, and specifically handle an invalid/nonexistent ticker gracefully. In `src/app/(dashboard)/stock/[ticker]/page.tsx` (the `async function StockPage({ params })` established in Part 8), after `await`-ing `params` and resolving the ticker, wrap the `resolveStock` validation check so that if a ticker fails Yahoo/Finnhub validation entirely (truly not a real symbol), we call Next.js's `notFound()` (imported from `next/navigation`) to render the not-found page instead of a confusing blank chart:

```tsx
// src/app/(dashboard)/stock/[ticker]/page.tsx (excerpt, extending Part 8/9)
import { notFound } from "next/navigation";
import { resolveStock } from "@/lib/stock-service";
// ...other imports from Parts 8-17...

export default async function StockPage({ params }: { params: Promise<{ ticker: string }> }) {
  const { ticker: rawTicker } = await params;
  const ticker = decodeURIComponent(rawTicker).toUpperCase();

  try {
    await resolveStock(ticker);
  } catch {
    notFound();
  }

  // ...render the page using `ticker` as before...
}
```

`notFound()` can only be called from within a Server Component (which `StockPage` already is, per Part 8), and must be called after the `await params` step, not before — calling it before would defeat the purpose since we need the resolved ticker to know whether it's actually invalid.

## Step 6: Rate-limit and timeout resilience

Update `src/lib/data-sources/finnhub.ts` (and any other raw `fetch()` call) to wrap network calls with a timeout using `AbortController`, so a hanging upstream request can't hang our own API route indefinitely and exhaust Vercel's serverless function execution time limit:

```typescript
export async function fetchWithTimeout(url: string, options: RequestInit = {}, timeoutMs = 8000) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { ...options, signal: controller.signal });
    return res;
  } finally {
    clearTimeout(id);
  }
}
```

Apply the same timeout discipline to the RSS fetcher (Part 17) and the SGX StockFacts scraper (Part 15), since these are the two other places we depend on a third-party HTTP endpoint that could hang or behave unexpectedly.

## Step 7: Basic request throttling for expensive routes

The sector heatmap (Part 12) and backtest (Part 13) routes are more expensive than a single quote lookup. Add Upstash-based rate limiting (`@upstash/ratelimit`, installed in Part 2) to these routes, capping requests per IP to a sane number per minute:

```typescript
// src/lib/rate-limit.ts
import { Ratelimit } from "@upstash/ratelimit";
import { redis } from "./redis";

export const expensiveRouteLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, "1 m"),
  analytics: true,
});
```

Wire it into the heatmap and backtest routes:

```typescript
const ip = req.headers.get("x-forwarded-for") ?? "anonymous";
const { success } = await expensiveRouteLimiter.limit(ip);
if (!success) {
  return NextResponse.json({ error: "Too many requests" }, { status: 429 });
}
```

Neither of these two routes has a dynamic `[ticker]`-style segment, so this change is purely additive and doesn't interact with the async `params` pattern used elsewhere.

## Step 8: A manual pre-deployment checklist

Before moving to Part 21, manually click through the entire app once, end to end: home page heatmap, search for a ticker, view its chart/indicators/dividends/DCA/backtest/REIT (if applicable)/news tabs, generate an AI summary with each of your two-plus configured free models, sign in, add/remove watchlist items with an alert price, and manually trigger the alert-check cron route locally. Also specifically test an invalid ticker (e.g. `/stock/ZZZZZ.SI`) to confirm the `notFound()` handling from Step 5 works correctly rather than showing a blank/broken page. Fix anything that breaks before deploying — it's much easier to debug locally than on Vercel.

## Checkpoint

- [ ] `vitest` unit tests written and passing for RSI, MACD, DCA calculator, backtest engine, and CPF/SRS simulator
- [ ] All API routes use the shared `apiError` helper for consistent error responses
- [ ] `AsyncBoundary` component created and retrofitted across major UI panels
- [ ] `error.tsx` and `not-found.tsx` created; an invalid ticker correctly triggers the not-found page (via `notFound()` called after awaiting `params`) instead of crashing
- [ ] Network calls to Finnhub, RSS feeds, and the SGX scraper all have explicit timeouts
- [ ] Rate limiting added to the heatmap and backtest routes
- [ ] Full manual click-through of every feature completed with no console errors

Next: **Part 21 — Deployment to Vercel**, where we finally ship this to a live URL, wire up all our environment variables in production, and confirm cron jobs run on schedule.
