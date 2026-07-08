# Appendix A: Full Codebase Reference

A complete reference map of the finished Next.js 16 project. Use this to double-check your project structure, or to quickly copy the most critical final files in one place.

---

## Final file tree

```txt
hdb-resale-api/
  .env.local
  next.config.ts
  source.config.ts
  package.json
  content/
    docs/
      index.mdx
  scripts/
    smoke-test.mjs
  src/
    app/
      api/
        auth/
          login/route.ts
          logout/route.ts
        health/route.ts
        keys/route.ts
        keys/revoke/route.ts
        test-hdb/route.ts        (temporary, from Part 6)
        v1/resale-prices/route.ts
      dashboard/
        layout.tsx
        page.tsx
        keys/page.tsx
        usage/page.tsx
      docs/
        layout.tsx
        [[...slug]]/page.tsx
      login/page.tsx
      globals.css
      layout.tsx
      page.tsx
    components/
      dashboard-nav.tsx
      ui/
        button.tsx
        card.tsx
        badge.tsx
    lib/
      api-keys/api-keys.ts
      auth/session.ts
      auth/users.ts
      hdb/cache.ts
      hdb/data-gov.ts
      hdb/parse-request.ts
      hdb/schema.ts
      usage/usage.ts
      cn.ts
      env.ts
      rate-limit.ts
      redis.ts
      source.ts
```

---

## Environment variables

```env
UPSTASH_REDIS_REST_URL="https://your-db.upstash.io"
UPSTASH_REDIS_REST_TOKEN="your-upstash-token"
AUTH_COOKIE_SECRET="a-random-string-at-least-32-characters-long"
NEXT_PUBLIC_APP_URL="http://localhost:3000"
```

---

## Redis key layout (for reference)

```txt
user:{email}                     -> AppUser record
user:{email}:keys                -> SET of API key ids
key:{keyId}                      -> ApiKeyRecord
key_hash:{sha256hash}            -> keyId
usage:{keyId}:{yyyy-mm-dd}       -> integer counter
cache:hdb:{queryHash}            -> { records, total }
ratelimit:hdb-api:*              -> managed internally by @upstash/ratelimit
```

---

## The final public API route

`src/app/api/v1/resale-prices/route.ts` — this is the most important file in the project, combining key validation, rate limiting, HDB data fetching/caching, and usage tracking:

```ts
import { validateApiKey } from "@/lib/api-keys/api-keys";
import { fetchHdbResalePrices } from "@/lib/hdb/data-gov";
import { parseHdbQuery } from "@/lib/hdb/parse-request";
import { apiRateLimit, rateLimitHeaders } from "@/lib/rate-limit";
import { recordUsage } from "@/lib/usage/usage";

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
    await recordUsage(apiKey.id);

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

---

## API key lifecycle

`src/lib/api-keys/api-keys.ts` — full create/list/revoke/validate logic:

```ts
import { createHash, randomBytes } from "node:crypto";
import { nanoid } from "nanoid";
import { redis } from "@/lib/redis";

export type ApiKeyRecord = {
  id: string;
  name: string;
  ownerEmail: string;
  prefix: string;
  hash: string;
  createdAt: string;
  revokedAt: string | null;
};

export function hashApiKey(rawKey: string) {
  return createHash("sha256").update(rawKey).digest("hex");
}

function userKeysSet(email: string) {
  return `user:${email.toLowerCase()}:keys`;
}
function apiKeyRecordKey(id: string) {
  return `key:${id}`;
}
function apiKeyHashKey(hash: string) {
  return `key_hash:${hash}`;
}

export async function createApiKey(ownerEmail: string, name: string) {
  const id = nanoid(12);
  const secret = randomBytes(24).toString("base64url");
  const rawKey = `hdb_live_${id}_${secret}`;
  const hash = hashApiKey(rawKey);
  const prefix = rawKey.slice(0, 18);

  const record: ApiKeyRecord = {
    id,
    name: name || "Default key",
    ownerEmail: ownerEmail.toLowerCase(),
    prefix,
    hash,
    createdAt: new Date().toISOString(),
    revokedAt: null,
  };

  await redis.set(apiKeyRecordKey(id), record);
  await redis.set(apiKeyHashKey(hash), id);
  await redis.sadd(userKeysSet(ownerEmail), id);

  return { rawKey, record };
}

export async function listApiKeys(ownerEmail: string) {
  const ids = await redis.smembers<string[]>(userKeysSet(ownerEmail));
  if (!ids.length) return [];
  const records = await Promise.all(ids.map((id) => redis.get<ApiKeyRecord>(apiKeyRecordKey(id))));
  return records
    .filter((record): record is ApiKeyRecord => Boolean(record))
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function revokeApiKey(ownerEmail: string, id: string) {
  const record = await redis.get<ApiKeyRecord>(apiKeyRecordKey(id));
  if (!record || record.ownerEmail !== ownerEmail.toLowerCase()) return false;
  await redis.set(apiKeyRecordKey(id), { ...record, revokedAt: new Date().toISOString() });
  await redis.del(apiKeyHashKey(record.hash));
  return true;
}

export async function validateApiKey(rawKey: string) {
  const hash = hashApiKey(rawKey);
  const id = await redis.get<string>(apiKeyHashKey(hash));
  if (!id) return null;
  const record = await redis.get<ApiKeyRecord>(apiKeyRecordKey(id));
  if (!record || record.revokedAt) return null;
  return record;
}
```

---

## Smoke test script

`scripts/smoke-test.mjs`:

```js
const baseUrl = process.env.APP_URL ?? "http://localhost:3000";
const apiKey = process.env.API_KEY;

if (!apiKey) {
  console.error("Set API_KEY first");
  process.exit(1);
}

const response = await fetch(`${baseUrl}/api/v1/resale-prices?limit=1`, {
  headers: { "x-api-key": apiKey },
});

console.log("status", response.status);
console.log("rate limit remaining", response.headers.get("x-ratelimit-remaining"));
console.log(await response.json());

if (!response.ok) process.exit(1);
```

Run with:

```bash
API_KEY="hdb_live_..." node scripts/smoke-test.mjs
```

---

## If something is missing

Every file above traces back to a specific tutorial part:

- auth/session files → Part 4
- api-keys files → Part 5
- hdb files → Part 6
- v1/resale-prices/route.ts → Parts 7, 8, 9 (built incrementally)
- usage files → Part 9
- docs files → Part 10

Return to the relevant part if a file's contents don't match what's shown here.

---

Proceed to **Appendix B — API Reference and Example Queries**, or "appendix c" to jump to the Production Hardening Roadmap.
