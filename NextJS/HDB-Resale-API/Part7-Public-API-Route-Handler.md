# Part 7: The Public API Route Handler

Goal: build the first version of the public endpoint, `GET /api/v1/resale-prices`, protected by API key validation.

---

## 1. Query parser

Create `src/lib/hdb/parse-request.ts`:

```ts
import { hdbQuerySchema } from "@/lib/hdb/schema";

export function parseHdbQuery(request: Request) {
  const url = new URL(request.url);
  const raw = Object.fromEntries(url.searchParams.entries());
  return hdbQuerySchema.safeParse(raw);
}
```

---

## 2. The public API route

Create `src/app/api/v1/resale-prices/route.ts`:

```ts
import { validateApiKey } from "@/lib/api-keys/api-keys";
import { fetchHdbResalePrices } from "@/lib/hdb/data-gov";
import { parseHdbQuery } from "@/lib/hdb/parse-request";

export const runtime = "nodejs";

export async function GET(request: Request) {
  const rawApiKey = request.headers.get("x-api-key") ?? "";
  if (!rawApiKey) {
    return Response.json(
      { error: { message: "Missing x-api-key header.", status: 401 } },
      { status: 401 },
    );
  }

  const apiKey = await validateApiKey(rawApiKey);
  if (!apiKey) {
    return Response.json(
      { error: { message: "Invalid or revoked API key.", status: 401 } },
      { status: 401 },
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
      { status: 400 },
    );
  }

  try {
    const result = await fetchHdbResalePrices(parsed.data);

    return Response.json({
      data: result.records,
      meta: {
        count: result.records.length,
        total: result.total,
        limit: parsed.data.limit,
        offset: parsed.data.offset,
        cached: result.cached,
      },
    });
  } catch (error) {
    console.error(error);
    return Response.json(
      { error: { message: "Unable to fetch HDB resale data right now.", status: 502 } },
      { status: 502 },
    );
  }
}
```

We'll add rate limiting and usage tracking to this same file in Parts 8 and 9.

---

## 3. Test with curl

Go to `/dashboard/keys`, create a key, copy the raw value, then:

```bash
curl -i "http://localhost:3000/api/v1/resale-prices?town=ANG%20MO%20KIO&limit=2" \
  -H "x-api-key: paste_your_key_here"
```

Expected: HTTP 200 with a JSON body containing `data` and `meta`.

Test failure cases:

```bash
# missing key
curl -i "http://localhost:3000/api/v1/resale-prices?limit=1"

# invalid key
curl -i "http://localhost:3000/api/v1/resale-prices?limit=1" -H "x-api-key: not-a-real-key"

# invalid query (limit too high)
curl -i "http://localhost:3000/api/v1/resale-prices?limit=999" -H "x-api-key: paste_your_key_here"
```

All three should return non-200 status codes with a structured `error` object.

---

## Checkpoint

- [ ] Valid key + valid params returns 200 with real HDB data.
- [ ] Missing key returns 401.
- [ ] Invalid/revoked key returns 401.
- [ ] Invalid query params (e.g. `limit=999`) returns 400 with field-level `issues`.

---

## Troubleshooting

**Header seems to be ignored**
Header names are case-insensitive in HTTP, but the literal name must be `x-api-key` — check for typos like `x_api_key` or `X-API-Key-` with trailing characters.

**Spaces in `town` break the request**
URL-encode spaces as `%20` (e.g. `ANG%20MO%20KIO`) when testing with curl directly in a shell.

**Route returns 502**
Check your terminal running `npm run dev` for the logged error — usually a data.gov.sg outage or a changed resource ID (see Part 6 troubleshooting).

---

Ready for **Part 8 — Rate Limiting with Upstash**?
