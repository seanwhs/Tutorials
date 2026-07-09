# Appendix C: Environment Variables & Troubleshooting Guide

## Full Environment Variable Reference

| Variable | Introduced | Where to get it | Required? |
|---|---|---|---|
| DATABASE_URL | Part 3 | Neon dashboard, Connection Details panel, pooled connection string (hostname includes -pooler) | Yes |
| DIRECT_URL | Part 3 | Neon dashboard, Connection Details panel, direct connection string (no -pooler in hostname) | Yes |
| UPSTASH_REDIS_REST_URL | Part 6 | Upstash, your database, REST API section | Yes |
| UPSTASH_REDIS_REST_TOKEN | Part 6 | Upstash, your database, REST API section | Yes |
| FINNHUB_API_KEY | Part 5 | finnhub.io dashboard | Recommended, fallback provider |
| NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY | Part 18 | Clerk dashboard, API Keys | Yes, once auth is added |
| CLERK_SECRET_KEY | Part 18 | Clerk dashboard, API Keys | Yes, once auth is added |
| GOOGLE_GENERATIVE_AI_API_KEY | Part 14 | Google AI Studio, aistudio.google.com | Yes, for AI summary and sentiment |
| GROQ_API_KEY | Part 14 | console.groq.com | Yes, default AI provider |
| OPENROUTER_API_KEY | Part 14 | openrouter.ai | Optional, tertiary AI fallback |
| RESEND_API_KEY | Part 19 | resend.com dashboard | Yes, once alerts are added |
| CRON_SECRET | Part 19 | Generate your own random string | Yes, once alerts/cron are added |
| NEXT_PUBLIC_APP_URL | Part 2 placeholder, Part 21 production value | Your deployed Vercel URL | Recommended for production |

## Common Errors and Fixes

### Node.js version too old, Next.js 16 will not start
Next.js 16 requires Node.js 20.9 or newer, with Node 22 LTS recommended. Run node -v. If it is below v20.9, install a current LTS via nodejs.org or nvm install --lts before running anything in Part 2. On Vercel, confirm Settings, General, Node.js Version is set to 20.x or newer, as described in Part 21.

### params should be awaited, or a TypeScript error on params.ticker
This is the most common issue when adapting older Next.js tutorial content. On Next.js 16, params, and page-level searchParams, in both Page components and Route Handlers are Promise-based and must be awaited. Every dynamic route and page in this series already uses the correct pattern:

```typescript
export async function GET(req: NextRequest, { params }: { params: Promise<{ ticker: string }> }) {
  const { ticker } = await params;
}
```

```tsx
export default async function StockPage({ params }: { params: Promise<{ ticker: string }> }) {
  const { ticker } = await params;
}
```

If you copy a snippet from an older blog post or AI-generated response using the synchronous shape, with no await, update it to the Promise-based pattern above.

### Tailwind classes or utilities not applying as expected
This series scaffolds with Tailwind CSS v4, CSS-first config. There is no tailwind.config.js by default, and custom utilities are declared with the @utility directive in globals.css, from Part 2, not the old @layer utilities plus @apply combo. If you are following an older Tailwind v3 guide alongside this series, do not mix the two config styles in the same project.

### Neon connection errors, or "too many connections"
Make sure DATABASE_URL is the pooled connection string, the one with -pooler in the hostname, and DIRECT_URL is the direct, unpooled one. Using the direct connection string for DATABASE_URL in a serverless environment is the most common cause of connection exhaustion, since every invocation opens a fresh connection rather than going through Neon's pooler. Also confirm you are using the Prisma client singleton from src/lib/prisma.ts (Part 3) rather than creating a new PrismaClient per request, since that alone can exhaust connections quickly in development due to Next.js hot reload.

### First request after idle time is slow
Neon's free tier scales compute to zero when your database has been idle for a while. The next query automatically wakes it back up, but that first request can take a couple of seconds longer than usual. This is expected behavior, not a bug, and only affects the first request after a period of inactivity.

### "No quote data returned for [ticker]"
Confirm the ticker has the .SI suffix, normalizeTicker from Part 4 should handle this automatically, check you are calling it. Try the ticker directly on finance.yahoo.com to confirm it is a real, currently listed symbol. If it is a genuinely valid but obscure ticker, Yahoo's coverage might be thin, this is exactly what Part 5's Finnhub fallback exists for, check your console logs to see if the fallback was attempted and what error it hit.

### "All data sources failed for quote(...)"
Both Yahoo and Finnhub failed. Check your internet connection, check Finnhub's status page, and check you have not exceeded Finnhub's 60 requests per minute free tier limit, this is more likely during local development if you are re-running test scripts rapidly.

### Prisma: "Unique constraint failed on the fields: (ticker,date)"
This should never surface if you are using upsert correctly, Part 7's persistBars. If you see this, check you are using prisma.price.upsert with the correct compound where clause, where ticker_date matches ticker and date together, rather than create.

### Prisma Client out of sync after schema changes
Any time you edit prisma/schema.prisma, run npx prisma generate to regenerate the TypeScript client, and either npx prisma db push, for prototyping in Parts 1 through 20, or npx prisma migrate dev with a name, after Part 21's migration switch, to apply the change to your actual Neon database.

### Upstash Redis: cached() always returns cacheHit false
Double check UPSTASH_REDIS_REST_URL and TOKEN are correct, and that you are not accidentally creating a new Redis client instance per request instead of reusing the singleton from src/lib/redis.ts. Confirm your TTL constants have not been set to zero or a negative number by mistake.

### lightweight-charts: "chart.addCandlestickSeries is not a function"
This series uses lightweight-charts v5, which changed the API to chart.addSeries(CandlestickSeries, options), as shown in Part 8. Update your imports and calls to match the v5 pattern, or pin to a v4 version if you specifically want the older API, not recommended, since v5 is the actively maintained version.

### Cannot find module '@ai-sdk/openai'
Part 14's OpenRouter option requires @ai-sdk/openai, an OpenAI-compatible client, since OpenRouter speaks that API shape. Part 2's full dependency install already includes it, if you skipped ahead, run npm install @ai-sdk/openai, or remove the openrouter-free entry from FREE_MODELS if you do not want the third fallback.

### AI model not found error from generateText
Free-tier model IDs rotate. Check the provider's current model list, Groq, Google AI Studio, or OpenRouter's free filter, and update the corresponding string in src/lib/ai/models.ts, see Appendix B's Keeping model IDs current section.

### Clerk: auth() returns null unexpectedly in an API route
Confirm the route is actually covered by your middleware.ts matcher config, Part 18, routes outside the matcher will not have Clerk's auth context attached. Confirm you are using await auth(), the async server-side helper from @clerk/nextjs/server, not a client-side hook, inside a Route Handler.

### AI summary route always falls back to the second or third model
Check your primary provider's API key is valid and has remaining free-tier quota for the day or minute. Log the actual error inside generateWithFallback, Part 14, rather than swallowing it silently, most always-falls-back issues are simple auth or malformed-request errors from the primary provider that are easy to spot once logged.

### Vercel Cron shows 401 in the execution log
Your CRON_SECRET environment variable in the Vercel dashboard does not match the value your route handler expects, Part 19. Re-check both values match exactly, redeploy after fixing, since env var changes require a redeploy to take effect for already-built serverless functions.

### Vercel build fails on prisma migrate deploy
This usually means your migration history in prisma/migrations is out of sync with your production Neon database's actual current state. If you are still early in development, it is often simplest to reset: drop and recreate your Neon database's tables (or create a fresh Neon branch for a clean slate, using Neon's branching feature), delete the prisma/migrations folder, and re-run npx prisma migrate dev with a name locally to regenerate a clean migration history, then redeploy. Be careful doing this on a database with real user data, this reset approach is only appropriate before you have real users.

### SGX StockFacts scraper, Part 15, returns empty results
This is expected and handled gracefully by design, the page structure may have changed. Check the manual fallback seed data is still populated for your seeded REITs, and consider updating the scraper's CSS selectors if you want to keep the live-scrape path working.

### RSS news fetcher, Part 17, returns no items for a ticker
Confirm the configured RSS feed URL is still valid, feeds occasionally get moved or renamed. Confirm your ticker or company-name substring matching is not too strict, try loosening the match or logging the raw feed items to see what is actually being returned before filtering.

### notFound() does not work as expected
notFound(), from next/navigation, used in Part 20, must be called inside a Server Component's render path, and after any await params step, not before, see Part 20 Step 5 for the exact pattern used in StockPage. Calling it from a Client Component, or from inside a try/catch without re-throwing or returning immediately afterward, can cause it to be silently ignored.

## General debugging tips used throughout this series

Every data-source function is wrapped in try/catch and logs a clear module-prefixed error message, always check your terminal or Vercel function logs first before assuming a UI bug. Prefer testing new data-fetching logic via a standalone scripts/test file, the pattern established in Parts 4 through 6, before wiring it into a UI component, it is much faster to iterate against. When in doubt about what is actually stored, npx prisma studio, Part 3, is your fastest way to inspect real data without writing a query, this works identically against Neon as it would against any other Postgres host. If you ever see a params-related type or runtime error anywhere in this project that is not covered above, it is almost certainly the sync-versus-async params issue described near the top of this list, every dynamic route or page in this series has already been written using the correct Promise-based pattern, so the fix is usually just matching that same shape in whatever new file you are adding.

## Validation honesty note

This entire guide reflects a static, line-by-line code review against the known Next.js 16 API surface and Neon's connection model, no code in this series has been executed in the environment that generated it. The definitive test of everything in this appendix is running npm run dev, Part 2 checkpoint, and later npm run build or a live Vercel deploy, Part 21, yourself.
