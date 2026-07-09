# Part 15: REIT Focus Tab (DPU, NAV, Gearing Ratio, Occupancy)

## Concept

SGX is famously REIT-heavy (S-REITs), and generic stock trackers never build REIT-specific analytics. This part is the single biggest differentiator in the entire project. We add four REIT-specific fundamentals already scaffolded in our schema back in Part 3:
- DPU (Distribution Per Unit) — the REIT equivalent of EPS/dividend
- NAV (Net Asset Value per unit) — used to judge premium/discount to book value
- Gearing Ratio — debt as a percentage of total assets, a key REIT risk metric (MAS caps this regulatory limit for S-REITs)
- Occupancy Rate — percentage of leasable area occupied, a core health signal for property trusts

## Step 1: Where this data comes from

Neither Yahoo Finance nor Finnhub's free tier reliably expose DPU/NAV/Gearing/Occupancy for SGX REITs — these are disclosed in quarterly/semi-annual financial results and summarized on SGX StockFacts. We use a narrowly-scoped, resilient scraping approach:

Create `src/lib/data-sources/sgx-stockfacts.ts`:

```typescript
// src/lib/data-sources/sgx-stockfacts.ts
import * as cheerio from "cheerio";

export interface ReitFundamentals {
  dpu?: number;
  nav?: number;
  gearingRatio?: number;
  occupancyRate?: number;
}

export async function fetchReitFundamentals(ticker: string): Promise<ReitFundamentals> {
  try {
    const symbol = ticker.replace(".SI", "");
    const url = `https://www.sgx.com/securities/equities/${encodeURIComponent(symbol)}`;
    const res = await fetch(url, { next: { revalidate: 86400 } });
    if (!res.ok) return {};

    const html = await res.text();
    const $ = cheerio.load(html);
    const text = $.text();

    const parse = (label: string): number | undefined => {
      const match = text.match(new RegExp(`${label}\\s*[:]?\\s*([0-9.]+)%?`, "i"));
      return match ? Number(match[1]) : undefined;
    };

    return {
      dpu: parse("DPU"),
      nav: parse("NAV"),
      gearingRatio: parse("Gearing"),
      occupancyRate: parse("Occupancy"),
    };
  } catch (e) {
    console.warn(`[sgx-stockfacts] failed for ${ticker}:`, (e as Error).message);
    return {};
  }
}
```

This function parses whichever fields it can find and returns a partial object — it never throws just because one field is missing, and it's wrapped in a top-level try/catch that logs a warning and returns `{}` on any total failure, since page structure changes are expected over time and must never crash the app.

## Step 2: Manual fallback data

Because scraping is inherently fragile and this is a tutorial (not a maintained scraping service), add a manual seed fallback: create `prisma/reit-fundamentals-seed.ts` with hardcoded, periodically-updatable REIT fundamental figures for our seeded REITs (C38U.SI, A17U.SI), sourced manually from each REIT's latest published financial results at the time you run the seed. Document clearly in code comments that this seed data goes stale and should be refreshed manually or via the scraper on a schedule (tie this to Part 19's cron infrastructure as an optional extension).

## Step 3: A REIT refresh job

Create `src/lib/reit-refresh.ts`:

```typescript
// src/lib/reit-refresh.ts
import { prisma } from "@/lib/prisma";
import { fetchReitFundamentals } from "@/lib/data-sources/sgx-stockfacts";

export async function refreshReitFundamentals(ticker: string) {
  const fresh = await fetchReitFundamentals(ticker);
  const data = Object.fromEntries(Object.entries(fresh).filter(([, v]) => v != null));
  if (!Object.keys(data).length) return null;
  return prisma.stock.update({ where: { ticker }, data });
}
```

For any fields it could not retrieve, it leaves existing values untouched rather than overwriting good data with nulls. This function is called both from a manual "Refresh REIT Data" button in the UI and, optionally, from a nightly cron job (Part 19).

## Step 4: REIT-derived metrics

Create `src/lib/reit-metrics.ts`:

```typescript
// src/lib/reit-metrics.ts
export function calculateDistributionYield(dpu: number, price: number): number {
  return (dpu / price) * 100;
}

export function calculatePriceToNav(price: number, nav: number): number {
  return price / nav;
}

export function priceToNavLabel(priceToNav: number): string {
  return priceToNav < 1 ? "Trading at a discount to NAV" : "Trading at a premium to NAV";
}

export function classifyGearingRisk(gearingRatio: number): "Low" | "Moderate" | "Elevated" {
  if (gearingRatio < 35) return "Low";
  if (gearingRatio <= 40) return "Moderate";
  return "Elevated";
}
```

The gearing thresholds roughly reflect MAS's regulatory leverage limit context, presented as an educational heuristic, not formal advice.

## Step 5: The REIT API route

> **Next.js 16 note:** As with every dynamic route in this series (see Part 7), `params` here is `Promise`-based and must be awaited.

Create `src/app/api/stocks/[ticker]/reit/route.ts`:

```typescript
// src/app/api/stocks/[ticker]/reit/route.ts
import { NextRequest, NextResponse } from "next/server";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";
import { getCachedQuote } from "@/lib/data-sources";
import { refreshReitFundamentals } from "@/lib/reit-refresh";
import {
  calculateDistributionYield,
  calculatePriceToNav,
  classifyGearingRisk,
} from "@/lib/reit-metrics";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);

  const stock = await resolveStock(ticker);
  if (!stock.isReit) {
    return NextResponse.json({ error: "Not a REIT" }, { status: 404 });
  }

  const { data: quote } = await getCachedQuote(ticker);

  return NextResponse.json({
    ticker,
    dpu: stock.dpu,
    nav: stock.nav,
    gearingRatio: stock.gearingRatio,
    occupancyRate: stock.occupancyRate,
    price: quote.price,
    distributionYield:
      stock.dpu != null ? calculateDistributionYield(stock.dpu, quote.price) : null,
    priceToNav: stock.nav != null ? calculatePriceToNav(quote.price, stock.nav) : null,
    gearingRisk:
      stock.gearingRatio != null ? classifyGearingRisk(stock.gearingRatio) : null,
  });
}

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);

  await refreshReitFundamentals(ticker);

  return NextResponse.json({ success: true });
}
```

The `GET` handler resolves the stock, verifies `isReit` is true (returning a 404-style "not a REIT" response otherwise), reads the stored DPU/NAV/gearing/occupancy fields plus a live quote for current price, computes the derived metrics from Step 4, and returns everything as one JSON payload. The `POST` handler on the same route triggers `refreshReitFundamentals` on demand (used by the "Refresh REIT Data" button in Step 6).

## Step 6: The REIT Focus Tab UI

Build a `ReitFocusPanel` component (only rendered when `stock.isReit` is true, so regular stocks like DBS never show this tab) with:
- A metrics grid (reusing `MetricCard` from Part 9): DPU (trailing 12m), Distribution Yield, NAV per unit, Price/NAV ratio with its discount/premium label, Gearing Ratio with its risk classification badge (green/amber/red), Occupancy Rate.
- A simple Recharts bar or line chart showing DPU trend over the last several distribution periods, if historical DPU data is available.
- A "Refresh REIT Data" button calling the POST endpoint from Step 5 and showing a toast (via the `sonner` component installed in Part 2) on success or failure.

## Step 7: A dedicated REITs overview page

Create `src/app/(dashboard)/reits/page.tsx` listing all stocks where `isReit` is true, in a table (shadcn `Table` component) with columns: Ticker, Name, Distribution Yield, Gearing Ratio (with risk badge), Occupancy Rate, Price/NAV, sortable by clicking column headers. This page has no dynamic route segment, so it needs no `params` handling at all.

## Step 8: Wire into the stock page

Conditionally add a "REIT Focus" tab to the stock detail page's tab set only when the resolved stock's `isReit` flag is true. Since the stock page (Part 8) is already an `async function StockPage({ params })` that awaits `params` once at the top, this addition doesn't need any further params handling — just pass the already-resolved `ticker` string down as a prop.

## Checkpoint

- [ ] `cheerio` installed, `sgx-stockfacts.ts` created with a defensive try/catch scraper
- [ ] Manual fallback seed data added for at least C38U.SI and A17U.SI
- [ ] REIT API route uses `params: Promise<{ ticker: string }>` on both GET and POST
- [ ] REIT API route returns DPU, NAV, gearing ratio, occupancy, and derived metrics for a seeded REIT
- [ ] `ReitFocusPanel` renders correctly for C38U.SI and does not appear at all for D05.SI
- [ ] "Refresh REIT Data" button triggers a re-scrape attempt and shows a success/failure toast
- [ ] `/reits` overview page lists and lets you sort all tracked REITs

Next: Part 16, the CPF/SRS Portfolio Simulator, a DCA-style planning tool specifically framed around CPF and SRS investing.
