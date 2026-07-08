# Appendix C: Production Hardening Roadmap

The course app is intentionally beginner-friendly. This appendix explains what to upgrade before treating it as a serious, public, commercial API product.

---

## 1. Replace tutorial auth

The course uses a signed email cookie. Better production options:

- Clerk
- Auth.js (NextAuth)
- Supabase Auth
- custom passwordless magic links with email verification

Production auth should add:

- email verification,
- session rotation/expiry management,
- account deletion,
- multi-device/session management,
- CSRF protection where relevant.

---

## 2. Use Postgres for durable business data

Redis is great for cache, counters, and rate limits — not ideal as your only source of truth for business-critical data.

Recommended tables:

```txt
users
api_keys
api_key_usage_daily
plans
subscriptions
audit_logs
```

Keep Redis for what it's best at:

```txt
rate limits
short-term cache
hot counters
abuse throttles
```

---

## 3. Improve API key security

The course hashes keys with SHA-256 and shows the raw key once. Further improvements:

- support key rotation without downtime,
- show "last used" timestamps,
- support scoped/limited-permission keys,
- support multiple environments (test vs live keys),
- alert users about unusual usage patterns.

---

## 4. Add OpenAPI + generated clients

Publish a machine-readable spec so developers can generate SDKs.

Useful tools:

- `zod-openapi` or `@asteasolutions/zod-to-openapi`
- Swagger UI
- Scalar API Reference

---

## 5. Improve data querying at scale

The course relies on data.gov.sg's Datastore API plus light app-side price filtering.

For real production use:

- ingest the full dataset into Postgres on a schedule,
- index `town`, `flat_type`, `month`, `resale_price`, `street_name`,
- add full-text search,
- add aggregation endpoints (e.g. median price by town/month),
- add time-series endpoints for trend analysis.

Example indexes:

```sql
create index on hdb_resale_prices (town);
create index on hdb_resale_prices (flat_type);
create index on hdb_resale_prices (month);
create index on hdb_resale_prices (resale_price);
```

---

## 6. Add billing and plans

Example tiers:

```txt
Free: 60 requests/minute, limited monthly quota
Pro: 600 requests/minute, higher quota, priority support
Business: custom limits, SLA
```

Billing providers: Stripe, Lemon Squeezy, Paddle.

---

## 7. Add observability

At minimum, track:

- request count and error rate,
- latency (p50/p95/p99),
- cache hit rate,
- data.gov.sg upstream failures,
- top consumers/endpoints,
- abusive or anomalous keys.

Tools: Vercel Observability, Sentry, Axiom, Better Stack, OpenTelemetry.

---

## 8. Add legal and trust pages

A public API product needs:

- Terms of Service,
- Privacy Policy,
- Acceptable Use Policy,
- clear data attribution/licensing notes,
- a support/contact page,
- a status page for uptime/incidents.

---

## 9. Add background jobs

Use scheduled/background jobs for:

- refreshing cached HDB data proactively,
- precomputing aggregates/analytics,
- emailing users approaching quota limits,
- pruning old logs/usage data,
- detecting and flagging abusive usage patterns.

Options: Vercel Cron, Inngest, Trigger.dev, Upstash QStash.

---

## 10. Frontend and developer-experience polish

- copy-to-clipboard button for new API keys,
- "last used" timestamp per key,
- date-range picker for usage charts,
- richer charts (e.g. Recharts) instead of plain divs,
- an interactive API explorer in the docs,
- an onboarding checklist for new users.

---

## Priority order if commercializing this project

1. Real authentication provider.
2. Postgres-backed data model for users/keys/usage.
3. OpenAPI spec + generated docs/clients.
4. Billing and usage quotas.
5. Observability and abuse detection.
6. Legal pages and data licensing review.
7. Full HDB dataset ingestion for real search/filtering at scale.

---

🎉 **That's the complete series** — Parts 0–12 plus Appendices A, B, and C. You've now walked through the entire "HDB Resale API Tutorial" (Next.js 16 canonical version) from introduction to a deployed, documented, rate-limited public API with a usage dashboard, plus a clear roadmap for taking it to production-grade.

