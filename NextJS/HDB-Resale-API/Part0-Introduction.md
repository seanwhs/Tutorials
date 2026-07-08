# Part 0: Introduction

Welcome. In this course you will build, from scratch, a real developer-facing product: a **Singapore HDB Resale Price API** complete with API keys, rate limiting, caching, usage tracking, a dashboard, and generated documentation — all on **Next.js 16**.

This is a full regeneration of the course. Every part uses current Next.js 16 conventions (async `params`/`searchParams`/`cookies`, Turbopack by default, Tailwind v4).

---

## 1. What you are building

A visitor can:

1. Sign in with an email (lightweight signed-cookie session — no password, no third-party auth provider).
2. Create one or more API keys from a dashboard.
3. Call `GET /api/v1/resale-prices` with their key in an `x-api-key` header.
4. Get back real Singapore HDB resale flat transaction data, cached in Redis, filtered by town/flat type/month/price.
5. Be rate limited automatically (60 requests/minute per key by default).
6. See their own usage on a dashboard chart, broken down per key, per day.
7. Read documentation for the API at `/docs`, built with Fumadocs.

Example call:

```bash
curl "https://your-app.vercel.app/api/v1/resale-prices?town=BEDOK&flat_type=4%20ROOM&limit=5" \
  -H "x-api-key: hdb_live_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Example response:

```json
{
  "data": [
    {
      "month": "2024-03",
      "town": "BEDOK",
      "flat_type": "4 ROOM",
      "block": "512",
      "street_name": "BEDOK NORTH AVE 2",
      "storey_range": "07 TO 09",
      "floor_area_sqm": "93",
      "flat_model": "Model A",
      "lease_commence_date": "1985",
      "remaining_lease": "60 years 04 months",
      "resale_price": "545000"
    }
  ],
  "meta": {
    "count": 1,
    "total": 812,
    "limit": 5,
    "offset": 0,
    "cached": true
  }
}
```

---

## 2. The stack, and why each piece

- **Next.js 16** — one project serves the marketing page, the dashboard, the public API, and the docs.
- **Route Handlers** — the modern App Router way to build API endpoints (`route.ts` files with exported `GET`/`POST`).
- **Upstash Redis** — a serverless, HTTP-based Redis. Perfect for Vercel because it needs no persistent TCP connection. Stores users, API keys, cache entries, and usage counters.
- **@upstash/ratelimit** — a small library built on Upstash Redis specifically for rate limiting serverless functions.
- **Tailwind CSS v4** — utility-first styling for the dashboard and landing page.
- **Fumadocs** — turns Markdown/MDX files into a real documentation site with navigation and search-ready structure.
- **data.gov.sg** — Singapore's open data portal; we use its HDB Resale Flat Prices dataset via its Datastore API.

---

## 3. Architecture

**Public API request:**

```txt
client
  -> GET /api/v1/resale-prices?town=...
  -> Route Handler reads x-api-key header
  -> look up key hash in Redis -> reject if missing/revoked
  -> check Upstash rate limit for that key id
  -> build cache key from query params
  -> Redis cache hit? return cached rows
  -> Redis cache miss? fetch data.gov.sg, filter, cache, return
  -> increment today's usage counter for that key
  -> respond with JSON + rate-limit headers
```

**Dashboard / auth:**

```txt
browser
  -> POST /api/auth/login (email only)
  -> server creates a signed session token, sets it as an httpOnly cookie
  -> Server Components read the cookie via cookies() and verify the signature
  -> dashboard pages read/write Redis: users, keys, usage
```

---

## 4. Redis key layout

We use Redis as our only datastore, to keep the course focused. Key naming:

```txt
user:{email}                     -> user profile record
user:{email}:keys                -> Redis SET of API key ids owned by that user
key:{keyId}                      -> API key record (name, prefix, hash, timestamps)
key_hash:{sha256hash}            -> keyId (reverse lookup for fast validation)
usage:{keyId}:{yyyy-mm-dd}       -> integer counter, incremented per successful call
cache:hdb:{queryHash}            -> cached HDB rows for a specific query
ratelimit:hdb-api:{keyId}        -> internal keys managed by @upstash/ratelimit
```

---

## 5. Scope and honest limitations

This course intentionally keeps two things simple so it stays beginner-friendly and finishable in one sitting:

- **Auth** is a signed cookie, not a full identity provider. Good for learning, not for a real company handling many users' data.
- **Data storage** is Redis only, no relational database. Great for keys/cache/counters, but not ideal for complex querying/reporting at scale.

Appendix C is a complete roadmap for upgrading both of these when you're ready to take this further.

---

## Checkpoint

Before moving on, you should be able to explain in your own words:

- [ ] What an API key is for, and why we only ever store its hash.
- [ ] Why we rate limit per API key rather than per IP.
- [ ] Why Redis works well for this project's cache/usage/rate-limit needs.
- [ ] The overall request flow from `curl` to JSON response.

Next: **Part 1 — Project Setup**.
