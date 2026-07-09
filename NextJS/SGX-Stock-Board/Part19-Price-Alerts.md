# Part 19: Price Alerts (Vercel Cron + Email)

## Concept

This closes the loop from Part 18: a user sets a target `alertPrice` on a watchlist item; we periodically check current prices against that target, and email them when triggered ("DBS hit your target price $38"). We use Vercel Cron (free on the Hobby plan, configured via `vercel.json`) to trigger a route handler on a schedule, and Resend's free tier for transactional email.

> **Next.js 16 note:** Both routes in this part (`/api/alerts/check` and `/api/cron/nightly-refresh`) have **no** dynamic segments, so neither needs any `params` handling.

## Step 1: Promote watchlist alerts into the Alert model

Recall from Part 3, `WatchlistItem.alertPrice` is a simple optional field, while `Alert` is a richer model supporting direction (`above`/`below`) and a `triggered` flag. Whenever a user sets a non-null `alertPrice` on a `WatchlistItem` (Part 18's POST route), also upsert a corresponding `Alert` row. Update `src/app/api/watchlist/route.ts`'s POST handler to additionally do:

```typescript
if (body.alertPrice != null) {
  const existing = await prisma.alert.findFirst({
    where: { userId, ticker, triggered: false },
  });

  if (existing) {
    await prisma.alert.update({
      where: { id: existing.id },
      data: { targetPrice: body.alertPrice },
    });
  } else {
    await prisma.alert.create({
      data: { userId, ticker, targetPrice: body.alertPrice, direction: "above" },
    });
  }
}
```

`Alert` isn't uniquely constrained per ticker by design from Part 3, so we handle this "find existing untriggered alert, else create" lookup explicitly in code rather than via a DB-level unique constraint.

## Step 2: Get a free Resend API key

1. Go to resend.com, sign up free (includes a generous free monthly email quota, sufficient for a personal project).
2. Verify a sending domain, or use Resend's shared test domain for development.
3. Add to `.env.local`:

```bash
RESEND_API_KEY="re_xxxx"
```

## Step 3: The email sending helper

Create `src/lib/email.ts`:

```typescript
// src/lib/email.ts
import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendPriceAlertEmail(params: {
  to: string;
  ticker: string;
  companyName: string;
  targetPrice: number;
  currentPrice: number;
}) {
  const { to, ticker, companyName, targetPrice, currentPrice } = params;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000";

  await resend.emails.send({
    from: "SGX Dashboard <alerts@yourdomain.com>",
    to,
    subject: `${ticker} hit your target price of $${targetPrice.toFixed(2)}`,
    html: `
      <h2>${companyName} (${ticker})</h2>
      <p>Your target price of <strong>$${targetPrice.toFixed(2)}</strong> has been reached.</p>
      <p>Current price: <strong>$${currentPrice.toFixed(2)}</strong></p>
      <p><a href="${appUrl}/stock/${ticker}">View on SGX Dashboard</a></p>
    `,
  });
}
```

Note: getting each Clerk user's email address requires calling Clerk's backend API (`clerkClient().users.getUser(userId)`) since we only store `userId` on our `Alert`/`WatchlistItem` rows, not email addresses — this keeps our own database free of PII we don't need to duplicate.

## Step 4: The alert-checking cron route

Create `src/app/api/alerts/check/route.ts`:

```typescript
// src/app/api/alerts/check/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getQuote } from "@/lib/data-sources"; // uncached, freshest price — see Part 6 note
import { sendPriceAlertEmail } from "@/lib/email";
import { clerkClient } from "@clerk/nextjs/server";

export async function GET(req: NextRequest) {
  // Protect this route so only Vercel Cron (or you, manually, with the secret) can trigger it.
  const authHeader = req.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const pendingAlerts = await prisma.alert.findMany({
    where: { triggered: false },
    include: { stock: true },
  });

  let triggeredCount = 0;
  const client = await clerkClient();

  for (const alert of pendingAlerts) {
    try {
      const { data: quote } = await getQuote(alert.ticker);
      const hit =
        alert.direction === "above"
          ? quote.price >= alert.targetPrice
          : quote.price <= alert.targetPrice;

      if (!hit) continue;

      const user = await client.users.getUser(alert.userId);
      const email = user.emailAddresses[0]?.emailAddress;

      if (email) {
        await sendPriceAlertEmail({
          to: email,
          ticker: alert.ticker,
          companyName: alert.stock.name,
          targetPrice: alert.targetPrice,
          currentPrice: quote.price,
        });
      }

      await prisma.alert.update({
        where: { id: alert.id },
        data: { triggered: true, triggeredAt: new Date() },
      });

      triggeredCount++;
    } catch (err) {
      console.error(`[alerts/check] error processing alert ${alert.id}:`, err);
      // Continue processing remaining alerts even if one fails.
    }
  }

  return NextResponse.json({ checked: pendingAlerts.length, triggered: triggeredCount });
}
```

Note we deliberately use the **uncached** `getQuote` here (not `getCachedQuote`), since alert checks specifically want the freshest possible price rather than a potentially 15-minute-stale cached value — this is the exception mentioned back in Part 6.

## Step 5: Configure Vercel Cron

Create `vercel.json` in the project root:

```json
{
  "crons": [
    {
      "path": "/api/alerts/check",
      "schedule": "*/30 1-9 * * 1-5"
    }
  ]
}
```

Vercel Cron runs in UTC by default. This schedule (`*/30 1-9 * * 1-5`, every 30 minutes from 1am-9am UTC, Mon-Fri) covers roughly 9am-5pm SGT (Singapore is UTC+8) during SGX trading days — adjust if your Vercel project's configured timezone differs.

Also generate a random `CRON_SECRET` value and add it to both `.env.local` and your Vercel project's environment variables (Part 21) — this prevents anyone else from triggering your alert-check endpoint and spamming your users with emails or exhausting your Resend quota.

```bash
CRON_SECRET="a-long-random-string-you-generate"
```

## Step 6: Local testing without waiting for Vercel's schedule

Since Vercel Cron only runs on deployed projects, test locally by calling the route directly with the correct header:

```bash
curl -H "Authorization: Bearer your-cron-secret" http://localhost:3000/api/alerts/check
```

To force a realistic test, temporarily set an `Alert.targetPrice` in Prisma Studio to a value you know is below (or above, matching `direction`) the current live price, run the curl command, and confirm you receive a real email via Resend and that the `Alert.triggered` flag flips to `true` in the database.

## Step 7: A nightly data-refresh cron (optional, recommended)

Add a second cron entry to `vercel.json` for a lightweight nightly job that refreshes dividend data (Part 11) and REIT fundamentals (Part 15) for all tracked stocks:

```json
{
  "crons": [
    { "path": "/api/alerts/check", "schedule": "*/30 1-9 * * 1-5" },
    { "path": "/api/cron/nightly-refresh", "schedule": "0 18 * * *" }
  ]
}
```

Implement `src/app/api/cron/nightly-refresh/route.ts` similarly protected by `CRON_SECRET`, looping over all `Stock` rows and calling the dividend-refresh and (for REITs) `refreshReitFundamentals` logic from earlier parts. This route also has no dynamic segment.

## Checkpoint

- [ ] Resend API key obtained, `sendPriceAlertEmail` helper created
- [ ] `Alert` rows are created/updated when a watchlist alert price is set (Part 18 integration)
- [ ] `/api/alerts/check` correctly identifies triggered alerts using **uncached** live quotes
- [ ] `CRON_SECRET` protects the route from unauthorized calls
- [ ] Manual curl test with a forced-triggerable alert successfully sends a real email and flips `triggered` to true
- [ ] `vercel.json` cron schedule configured (verified fully once deployed in Part 21)

Next: **Part 20 — Testing, Error Handling, and Rate-Limit Resilience**, where we harden everything we've built before we deploy.
