# Part 16: CPF/SRS Portfolio Simulator

> **Next.js 16 note:** The simulator route (`/api/simulator/cpf-srs`) and the simulator page (`/simulator`) have **no** dynamic segments, so neither needs any `params` handling — the route reads its inputs from the POST body.

## Concept

"If I DCA $500 into the STI ETF every month since 2020, using my CPF-OA or SRS funds, what would I have today?" is one of the most common questions SG retail investors ask. This part builds a dedicated simulator page framed specifically around CPF (Central Provident Fund) and SRS (Supplementary Retirement Scheme) investing, reusing the pure DCA math from Part 11 but adding SG-specific framing and constraints.

## Step 1: Why CPF/SRS needs its own simulator, not just the generic DCA calculator

Key differences that make this SG-specific rather than a copy of Part 11:
- CPF-OA (Ordinary Account) funds used for investing have an opportunity cost: CPF-OA itself earns a guaranteed 2.5% per annum (as of writing) if left untouched, so a meaningful comparison must show "invested in STI ETF" versus "left in CPF-OA earning 2.5%" side by side.
- SRS contributions have annual caps (a fixed cap for Singapore Citizens/PRs, a higher cap for foreigners, subject to change) and tax relief benefits; while we won't build a tax calculator, we surface these caps as informational context so the tool feels authentically "for Singapore."
- Both schemes are typically used for long-horizon, low-cost index investing (STI ETF, ES3.SI, being the most common CPF/SRS-approved instrument), so we default the simulator to ES3.SI rather than a generic "any ticker" picker, while still allowing other CPF/SRS-approved counters to be entered.

## Step 2: Configuration constants

Create `src/lib/cpf-srs-constants.ts`:

```typescript
// src/lib/cpf-srs-constants.ts
// NOTE: these are illustrative figures the user should verify against current
// CPF Board / IRAS publications — they change over time and this tutorial is
// not a source of financial or tax advice.
export const CPF_OA_INTEREST_RATE = 0.025;
export const SRS_ANNUAL_CAP_CITIZEN_PR = 15300;
export const SRS_ANNUAL_CAP_FOREIGNER = 35700;
```

## Step 3: The comparison calculation

Create `src/lib/cpf-srs-simulator.ts`:

```typescript
// src/lib/cpf-srs-simulator.ts
import type { OhlcvBar } from "@/types/stock";
import { simulateDca, type DcaResult } from "./dca-calculator";
import { CPF_OA_INTEREST_RATE } from "./cpf-srs-constants";

export interface CpfSrsResult {
  market: DcaResult;
  cpfBaseline: { points: { date: string; value: number }[]; finalValue: number } | null;
  comparisonSentence: string;
}

export function simulateCpfSrsPortfolio(params: {
  monthlyBars: OhlcvBar[];
  monthlyContribution: number;
  dividends: { exDate: string; amount: number }[];
  accountType: "CPF-OA" | "SRS";
  reinvestDividends: boolean;
}): CpfSrsResult {
  const market = simulateDca({
    monthlyBars: params.monthlyBars,
    monthlyContribution: params.monthlyContribution,
    dividends: params.dividends,
    reinvestDividends: params.reinvestDividends,
  });

  let cpfBaseline: CpfSrsResult["cpfBaseline"] = null;

  if (params.accountType === "CPF-OA") {
    const monthlyRate = CPF_OA_INTEREST_RATE / 12;
    let balance = 0;
    const points = market.points.map((p) => {
      balance = (balance + p.contribution) * (1 + monthlyRate);
      return { date: p.date, value: balance };
    });
    cpfBaseline = { points, finalValue: balance };
  }

  const comparisonSentence = cpfBaseline
    ? `Investing this amount would have grown your $${market.totalContributed.toFixed(0)} in contributions to $${market.finalValue.toFixed(0)}, versus $${cpfBaseline.finalValue.toFixed(0)} if left in CPF-OA at 2.5% p.a.`
    : `Investing this amount would have grown your $${market.totalContributed.toFixed(0)} in contributions to $${market.finalValue.toFixed(0)}.`;

  return { market, cpfBaseline, comparisonSentence };
}
```

This reuses the pure `simulateDca` function from Part 11 rather than duplicating DCA math, and separately computes what the same monthly contributions would have grown to if left in CPF-OA earning a flat 2.5% per annum compounded monthly — this baseline only applies when `accountType` is `"CPF-OA"`, since SRS funds sitting uninvested typically don't earn a comparable guaranteed rate.

## Step 4: The Simulator API route

Create `src/app/api/simulator/cpf-srs/route.ts`:

```typescript
// src/app/api/simulator/cpf-srs/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getCachedHistory } from "@/lib/data-sources";
import { prisma } from "@/lib/prisma";
import { simulateCpfSrsPortfolio } from "@/lib/cpf-srs-simulator";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";

const BodySchema = z.object({
  ticker: z.string().default("ES3.SI"),
  monthlyContribution: z.number().positive(),
  accountType: z.enum(["CPF-OA", "SRS"]),
  reinvestDividends: z.boolean().default(true),
});

export async function POST(req: NextRequest) {
  const body = BodySchema.parse(await req.json());
  const ticker = normalizeTicker(body.ticker);
  await resolveStock(ticker);

  const { data: bars } = await getCachedHistory(ticker, "5Y");
  const dividends = await prisma.dividend.findMany({ where: { ticker } });

  const byMonth = new Map<string, typeof bars[number]>();
  for (const bar of bars) byMonth.set(bar.date.slice(0, 7), bar);
  const monthlyBars = Array.from(byMonth.values());

  const result = simulateCpfSrsPortfolio({
    monthlyBars,
    monthlyContribution: body.monthlyContribution,
    dividends: dividends.map((d) => ({ exDate: d.exDate.toISOString().slice(0, 10), amount: d.amount })),
    accountType: body.accountType,
    reinvestDividends: body.reinvestDividends,
  });

  return NextResponse.json(result);
}
```

No route `params` are involved — the ticker and all simulation inputs come from the validated POST body.

## Step 5: The Simulator page and UI

Create `src/app/(dashboard)/simulator/page.tsx` with a `CpfSrsSimulatorForm` component: ticker selector defaulted to ES3.SI (SPDR STI ETF) but allowing free text entry of other tickers, monthly contribution input, account type toggle (CPF-OA vs SRS), reinvest-dividends checkbox, and a prominent but non-alarming informational note displaying the current SRS annual caps from Step 2 for context.

Render results as: a summary card with total contributed, final market value, (if CPF-OA) the CPF-OA baseline value for comparison, and overall return percentage; a Recharts area chart with two overlaid series (market value vs CPF-OA baseline) when `accountType` is CPF-OA, or a single series when SRS is selected; and the plain-English `comparisonSentence` from Step 3, prominently displayed.

## Step 6: Disclaimers

Add a permanent disclaimer directly below the simulator's results, similar in spirit to Part 13's backtest disclaimer: "This simulator is for illustrative and educational purposes only. CPF and SRS scheme rules, interest rates, and contribution caps are subject to change — always verify current figures with CPF Board and IRAS. This is not financial or tax advice."

## Checkpoint

- [ ] `cpf-srs-constants.ts` created with clearly commented illustrative figures
- [ ] `simulateCpfSrsPortfolio` correctly reuses Part 11's DCA math rather than duplicating it
- [ ] CPF-OA baseline comparison computes a sensible compounded value at 2.5% p.a.
- [ ] Simulator page renders with ES3.SI as a sensible default and lets you switch account type and see the comparison chart update
- [ ] Disclaimer is visible and permanent

Next: Part 17, News + Sentiment Analysis, where we pull SGX-related news via RSS and use our free AI models from Part 14 to label each headline's likely impact on the stock.
