# Part 23: Conclusion & Roadmap (Phase 2/3 Ideas)

## Conclusion

You've now built, end to end, a real SGX Stock Analytics Dashboard on Next.js 16: live and historical price data for SGX-listed counters, candlestick/line/volume charts across six timeframes, a key metrics panel, RSI/MACD indicators computed from scratch, a dividend tracker with a DCA calculator, a sector heatmap, a pattern backtesting engine, AI-generated plain-English summaries powered entirely by free-tier models with automatic fallback, a REIT-specific analytics tab, a CPF/SRS DCA simulator, news with AI sentiment classification, authenticated watchlists, and automated price-alert emails — all deployed for free on Vercel, Neon, Upstash, Clerk, and Resend's free tiers.

More importantly, along the way you practiced the skills that actually matter in real engineering work: designing a normalized database schema before writing code, building a provider-agnostic data layer with graceful fallback, caching to respect rate limits, writing pure/testable business logic separate from API plumbing, being upfront with disclaimers wherever a feature could be mistaken for financial advice, and — throughout this series — correctly handling Next.js 16's async `params` requirement on every dynamic route.

This project, as built, is a strong portfolio piece specifically for the Singapore market: it demonstrates full-stack ability (frontend, backend, database, third-party integrations) *and* domain understanding (REITs, CPF, SRS, SGX-specific tickers) that a generic "stock tracker" clone never shows.

## What to do with this project now

- Deploy it, put the live link and GitHub repo on your resume/LinkedIn
- Write a short case-study style README (or blog post) explaining the architecture decisions from Part 1 — interviewers love seeing *why*, not just *what* (e.g. why Neon over a bundled backend-as-a-service platform, given this project only ever needed Postgres)
- Record a 2-3 minute demo video walking through the REIT tab and CPF/SRS simulator specifically, since these are the features that differentiate you

## Phase 2 Roadmap

These are natural next features, roughly in order of value-to-effort ratio:

1. **Broader ticker coverage**: seed all ~600+ SGX-listed counters (scriptable via a one-time bulk import from a public SGX securities list) instead of our curated 10, so the search/heatmap genuinely covers the whole market.
2. **Portfolio tracking (not just watchlist)**: let users log actual buy/sell transactions (ticker, quantity, price, date) and compute real unrealized/realized P&L, not just a DCA hypothetical — this is the single biggest "real product" upgrade.
3. **Multi-currency support**: some SGX-listed counters trade in USD; extend the `Stock.currency` field (already in our Part 3 schema) throughout formatting and calculations.
4. **Streaming AI summaries**: upgrade Part 14's `generateText` to `streamText` with a token-by-token UI, as noted as an optional upgrade at the time.
5. **Historical DPU/NAV/gearing time series for REITs**: Part 15 only tracks the latest trailing figures; storing a proper quarterly time series unlocks real trend charts instead of single snapshots.
6. **Mobile app or PWA**: wrap the existing Next.js app as an installable PWA (manifest + service worker) so users can "install" it on their phone home screen without building a separate native app.
7. **More backtest strategies and proper statistical rigor**: add confidence intervals, out-of-sample testing (train pattern on one period, test on another), and more strategies (e.g., moving average crossovers).
8. **SMS/push alerts in addition to email**: Part 19 only emails; a free-tier push notification service (e.g., web push via a service worker) could complement this.
9. **Community/social layer**: shared, anonymized watchlists or "most-watched SGX stocks this week" — careful here to keep scope disciplined; this is a "Phase 3, if ever" idea, not core to the value proposition.
10. **Per-environment Neon branches**: use Neon's database branching feature (mentioned in Parts 1, 3, and 21) to give each Vercel preview deployment its own isolated database branch — a natural next step once you're collaborating with others or want safer testing of schema changes.
11. **Paid data upgrade path**: if you ever outgrow free tiers (e.g., real-time intraday ticks, deeper historical fundamentals), the provider-agnostic data layer built in Part 5 makes swapping in a paid provider (e.g., Polygon.io's paid SGX coverage) a contained change, not a rewrite — this was a deliberate architectural decision from Part 1.

## A closing note on the free-tier constraint

Every single feature in this series was built using only free tiers and free/open-source tooling — no paid API keys, no paid AI models. This was a deliberate constraint, not a limitation: it forces good architecture (caching, fallback, rate-limit awareness) that scales the same way whether you're on a free tier or a paid one. If you take nothing else from this series, take this: build for resilience and graceful degradation from day one, regardless of budget.

## A closing note on validation

Every code sample in this series was written and statically reviewed against the Next.js 16 API surface (async `params`, Node 20.9+, Tailwind v4, lightweight-charts v5, current Clerk/AI SDK APIs, Neon's connection model) — but none of it has been executed in the environment that generated it. Treat Part 2's `npm run dev` checkpoint as your real first test, and work through each part's checkpoint as you go; that's the only way to catch anything version-specific that shifts between when this was written and when you build it.

Good luck, and happy building.
