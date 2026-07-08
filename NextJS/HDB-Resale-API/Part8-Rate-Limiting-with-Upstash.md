# Part 8: Rate Limiting with Upstash

Goal: prevent any single API key from overwhelming the service, using `@upstash/ratelimit`. Default: **60 requests per minute per key**.

---

## 1. Create the rate limiter

Create `src/lib/rate-limit.ts`:

```ts
import { Ratelimit } from "@upstash/ratelimit";
import { redis } from "@/lib/redis";

export const apiRateLimit = new Ratelimit({
  redis,
  limiter: Ratelimit.fixedWindow(60, "60 s"),
  analytics: true,
  prefix: "ratelimit:hdb-api",
});

export function rateLimitHeaders(result: Awaited<ReturnType<typeof apiRateLimit.limit>>) {
  return {
    "X-RateLimit-Limit": String(result.limit),
    "X-RateLimit-Remaining": String(result.remaining),
    "X-RateLimit-Reset": String(result.reset),
  };
}
```

`fixedWindow(60, "60 s")` allows 60 requests inside each rolling 60-second window, keyed per identifier we pass to `.limit(id)`.

---

## 2. Wire it into the public API route

Replace `src/app/api/v1/resale-prices/route.ts` with:

```ts
import { validateApiKey } from "@/lib/api-keys/api-keys";
import { fetchHdbResalePrices } from "@/lib/hdb/data-gov";
import { parseHdbQuery } from "@/lib/hdb/parse-request";
import { apiRateLimit, rateLimitHeaders } from "@/lib/rate-limit";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const rawApiKey = request.headers.get("x-api-key") ?? "";
  if (!rawApiKey) {
    return Response.json({ error: { message: "Missing x-api-key header.", status: 401 } }, { status: 401 });
  }

  const apiKey = await validateApiKey(rawApiKey);
  if (!apiKey) {
    return Response.json({ error: { message: "Invalid or revoked API key.", status: 401 } }, { status: 401 });
  }

  const limitResult = await apiRateLimit.limit(apiKey.id);
  const headers = rateLimitHeaders(limitResult);

  if (!limitResult.success) {
    return Response.json(
      { error: { message: "Rate limit exceeded. Try again later.", status: 429 } },
      { status: 429, headers },
    );
  }

  const parsed = parseHdbQuery(request);
  if (!parsed.success) {
    return Response.json(
      {
        error: {
          message: "Invalid query parameters.",
          status: 400,
          issues: parsed.error.flatten().fieldErrors,
        },
      },
      { status: 400, headers },
    );
  }

  try {
    const result = await fetchHdbResalePrices(parsed.data);

    return Response.json(
      {
        data: result.records,
        meta: {
          count: result.records.length,
          total: result.total,
          limit: parsed.data.limit,
          offset: parsed.data.offset,
          cached: result.cached,
        },
      },
      { headers },
    );
  } catch (error) {
    console.error(error);
    return Response.json(
      { error: { message: "Unable to fetch HDB resale data right now.", status: 502 } },
      { status: 502, headers },
    );
  }
}
```

Note the rate limit check happens **after** key validation but **before** query validation — an invalid key should never consume rate-limit budget tied to a real key ID.

---

## 3. Confirm headers appear

```bash
curl -i "http://localhost:3000/api/v1/resale-prices?limit=1" \
  -H "x-api-key: paste_your_key_here"
```

Look for:

```txt
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 59
X-RateLimit-Reset: 1234567890
```

---

## 4. Force a 429 to verify it actually works

Temporarily lower the limit in `src/lib/rate-limit.ts`:

```ts
limiter: Ratelimit.fixedWindow(3, "60 s"),
```

Call the endpoint 4 times in a row with the same key. The 4th call should return HTTP 429 with the "Rate limit exceeded" message.

Change the limit back to `60` once you've confirmed it works.

---

## Checkpoint

- [ ] Successful responses include `X-RateLimit-*` headers.
- [ ] Exceeding the limit returns HTTP 429 with headers still present.
- [ ] Two different API keys have independent limits (test with a second key).

---

## Troubleshooting

**Headers not visible in a browser tab**
Browsers hide response headers by default — use `curl -i` or your browser's Network devtools panel.

**All keys seem to share one limit**
Confirm you're calling `apiRateLimit.limit(apiKey.id)` with the actual key's `id`, not a hardcoded string.

**Limit doesn't reset when expected**
Fixed windows reset at clean window boundaries, not exactly N seconds after your first call — wait for the next full minute boundary if timing seems off.

---

Ready for **Part 9 — Usage Tracking Dashboard**?
