## Part 2: Designing for Traffic (Load Balancing and Caching)

### 1. Concept and Philosophy

A single server, no matter how large, has a throughput ceiling and is a single point of failure. The two levers that let a system absorb 100x traffic without 100x-ing origin compute are load balancing (spread requests across many servers) and caching (avoid doing the work at all). Staff engineers reach for caching before "add more servers" because caching reduces both latency and cost simultaneously, while horizontal scaling only helps throughput and costs money linearly.

Guiding question: for every request, ask "does this need to hit my origin application server at all, and if it does, does it need to hit my database?" Every layer you can intercept the request at (browser, CDN edge, reverse proxy cache, application cache, database cache) removes load from everything behind it.

### 2. L4 vs L7 Load Balancing

**L4** (transport layer): routes based on IP/port only. Extremely fast, no path/header/cookie-based routing. Free options: HAProxy, Linux IPVS.

**L7** (application layer): understands HTTP — route `/api/*` vs `/static/*`, terminate TLS, inspect headers. Free options: Nginx, HAProxy (HTTP mode), Envoy. Costs more CPU per request, slightly higher latency floor.

Trade-off: L4 for raw throughput with simple routing; L7 for smart routing, TLS termination, content-based decisions.

### 3. Load Balancing Algorithms

- **Round robin**: simplest, best for homogeneous servers/requests.
- **Least connections**: sends to server with fewest active connections; better when processing time varies a lot.
- **IP hash / consistent hashing**: same client always routed to same backend; needed for session affinity/cache-locality.
- **Weighted variants**: useful for canary releases or heterogeneous hardware.

Nginx upstream example, using `least_conn` with health checks and a weighted canary server:

```
upstream app_servers {
    least_conn;
    server 10.0.1.10:3000 weight=5 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:3000 weight=5 max_fails=3 fail_timeout=30s;
    server 10.0.1.12:3000 weight=1 max_fails=3 fail_timeout=30s; # canary
}

server {
    listen 443 ssl;
    server_name quikn.example.com;

    location /api/ {
        proxy_pass http://app_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_next_upstream error timeout http_502 http_503;
    }

    location /static/ {
        proxy_cache static_cache;
        proxy_cache_valid 200 30d;
        proxy_pass http://app_servers;
    }
}
```

Why `least_conn` over round robin: Quikn's redirect endpoint is fast and uniform, but the analytics dashboard endpoint is slow and variable, so connection count is a better proxy for real load.

### 4. CDN Strategy

A CDN caches responses at edge points-of-presence close to users. Free/OSS-friendly options: Cloudflare's free tier, or self-hosted Varnish.

Push to CDN: static assets with long cache lifetimes + content-hash filenames, and cacheable API responses like a public shortcode redirect lookup.

```
# Public, cacheable at CDN edge for 5 minutes, revalidate after
Cache-Control: public, max-age=300, stale-while-revalidate=60

# Private, never cache
Cache-Control: private, no-store
```

`stale-while-revalidate` lets the CDN serve the slightly-stale response immediately while revalidating in the background — trading a small consistency window for a large latency win (Part 1's latency-vs-consistency trade-off).

### 5. Multi-Tier Caching

- **Layer 1, Client cache**: browser HTTP cache/in-memory state. Helps only that one user.
- **Layer 2, Edge/CDN cache**: shared across users at that edge location.
- **Layer 3, Application cache (Redis)**: shared across app instances — sessions, dashboard aggregates, rate-limit counters.
- **Layer 4, Database cache**: Postgres's own buffer pool (`shared_buffers`).

Redis example for Quikn — caching the shortcode-to-destination-URL lookup:

```
// lib/redis.ts
import { Redis } from "ioredis";

export const redis = new Redis(process.env.REDIS_URL!);

export async function getDestinationUrl(shortcode: string): Promise<string | null> {
  const cacheKey = `shortcode:${shortcode}`;
  const cached = await redis.get(cacheKey);
  if (cached) return cached; // cache hit, no DB round trip

  const row = await db.link.findUnique({ where: { shortcode } });
  if (!row) return null;

  // Cache for 1 hour; writes (link creation) will proactively invalidate this key
  await redis.set(cacheKey, row.destinationUrl, "EX", 3600);
  return row.destinationUrl;
}
```

Invalidation strategy: on update, **delete** the Redis key rather than update it in place, so the next read repopulates from source of truth:

```
export async function updateDestinationUrl(shortcode: string, newUrl: string) {
  await db.link.update({ where: { shortcode }, data: { destinationUrl: newUrl } });
  await redis.del(`shortcode:${shortcode}`); // invalidate, do not update-in-place
}
```

### 6. Cache Invalidation Patterns, and Why Each Exists

- **Cache-aside (lazy loading)**: check cache first, on miss read DB and populate. Good default.
- **Write-through**: write cache+DB synchronously. Always fresh, but adds write latency and risks partial-failure divergence.
- **Write-behind**: write cache immediately, flush to DB async. Lowest write latency, but risks data loss (only for tolerant data like view counters).
- **TTL-based expiry**: safety net ensuring no key lives forever even if invalidation is missed.

Quikn combines cache-aside + explicit invalidation-on-write + a TTL safety net (the 3600s `EX` above), in case an invalidation call fails to fire.

### 7. C4 Diagram, Container Level (Level 2)

```
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

Person(user, "End User")
System_Boundary(quikn, "Quikn") {
  Container(cdn, "CDN / Edge Cache", "Cloudflare", "Caches static assets and public redirect lookups")
  Container(lb, "Load Balancer", "Nginx (L7)", "TLS termination, routing, canary weighting")
  Container(app, "App Servers", "Next.js", "Stateless request handlers")
  ContainerDb(cache, "Cache", "Redis", "Shortcode lookups, sessions, rate limit counters")
  ContainerDb(db, "Primary DB", "PostgreSQL (Neon)", "System of record for links and users")
}

Rel(user, cdn, "HTTPS")
Rel(cdn, lb, "Cache miss forwards to origin")
Rel(lb, app, "Distributes requests")
Rel(app, cache, "Read/write, low latency")
Rel(app, db, "Read/write, source of truth")
@enduml
```

### 8. Design Challenge

Quikn's redirect endpoint is doing 200 req/s against Postgres directly and p99 latency has crept to 180ms. A campaign will drive traffic to 8,000 req/s for six hours. Design the caching/LB changes, and specify exactly what you would **NOT** cache and why.

### 9. Solution and Discussion

Add Redis in front of the shortcode lookup — at 8,000 req/s with a high cache hit ratio (Zipfian popularity distribution), most requests never reach Postgres, collapsing p99 latency to roughly Redis's sub-millisecond response.

Put the CDN in front of that for the redirect response itself (safe to cache ~60s), using `stale-while-revalidate` so updates propagate within roughly one revalidation window.

Scale app servers horizontally behind the L7 LB using `least_conn` for the residual traffic (cache misses, click-tracking writes).

**What NOT to cache:** the click-analytics write path — every click is a distinct event to be counted, not a repeatable read; instead write to a queue (Part 4), decoupling the spike from the DB. Also never cache authenticated per-user dashboard data at the CDN layer (data leak risk) — that belongs in Redis, keyed per-user, with private cache-control headers.

---
*Next: "Scalable Systems Design - Part 3: The Data Layer"*
