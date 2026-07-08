# Part 6: Fetching HDB Data from data.gov.sg

Goal: build a reusable module that validates query params, fetches HDB resale transaction data from data.gov.sg, and caches results in Redis.

The dataset is Singapore's official **HDB Resale Flat Prices** dataset, available through data.gov.sg's Datastore API.

---

## 1. Query schema

Create `src/lib/hdb/schema.ts`:

```ts
import { z } from "zod";

export const hdbQuerySchema = z.object({
  town: z.string().trim().optional(),
  flat_type: z.string().trim().optional(),
  min_price: z.coerce.number().int().nonnegative().optional(),
  max_price: z.coerce.number().int().nonnegative().optional(),
  month: z.string().regex(/^\d{4}-\d{2}$/).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});

export type HdbQuery = z.infer<typeof hdbQuerySchema>;

export type HdbResaleRecord = {
  month: string;
  town: string;
  flat_type: string;
  block: string;
  street_name: string;
  storey_range: string;
  floor_area_sqm: string;
  flat_model: string;
  lease_commence_date: string;
  remaining_lease: string;
  resale_price: string;
};
```

---

## 2. Cache key helper

Create `src/lib/hdb/cache.ts`:

```ts
import { createHash } from "node:crypto";
import type { HdbQuery } from "@/lib/hdb/schema";

export function hdbCacheKey(query: HdbQuery) {
  const stable = JSON.stringify(query, Object.keys(query).sort());
  const hash = createHash("sha256").update(stable).digest("hex").slice(0, 24);
  return `cache:hdb:${hash}`;
}
```

Sorting keys before hashing means `{town, limit}` and `{limit, town}` produce the same cache key.

---

## 3. data.gov.sg client

Create `src/lib/hdb/data-gov.ts`:

```ts
import { redis } from "@/lib/redis";
import { hdbCacheKey } from "@/lib/hdb/cache";
import type { HdbQuery, HdbResaleRecord } from "@/lib/hdb/schema";

const DATASTORE_URL = "https://data.gov.sg/api/action/datastore_search";
const RESOURCE_ID = "f1765b54-a209-4718-8d38-a39237f502b3";

type DataGovResponse = {
  success: boolean;
  result?: {
    records?: HdbResaleRecord[];
    total?: number;
  };
  error?: unknown;
};

function buildFilters(query: HdbQuery) {
  const filters: Record<string, string> = {};
  if (query.town) filters.town = query.town.toUpperCase();
  if (query.flat_type) filters.flat_type = query.flat_type.toUpperCase();
  if (query.month) filters.month = query.month;
  return filters;
}

function applyPriceFilters(records: HdbResaleRecord[], query: HdbQuery) {
  return records.filter((record) => {
    const price = Number(record.resale_price);
    if (query.min_price !== undefined && price < query.min_price) return false;
    if (query.max_price !== undefined && price > query.max_price) return false;
    return true;
  });
}

export async function fetchHdbResalePrices(query: HdbQuery) {
  const cacheKey = hdbCacheKey(query);
  const cached = await redis.get<{ records: HdbResaleRecord[]; total: number }>(cacheKey);

  if (cached) {
    return { records: cached.records, total: cached.total, cached: true };
  }

  const url = new URL(DATASTORE_URL);
  url.searchParams.set("resource_id", RESOURCE_ID);
  url.searchParams.set("limit", String(query.limit));
  url.searchParams.set("offset", String(query.offset));

  const filters = buildFilters(query);
  if (Object.keys(filters).length > 0) {
    url.searchParams.set("filters", JSON.stringify(filters));
  }

  const response = await fetch(url, {
    headers: { accept: "application/json" },
    next: { revalidate: 60 * 60 },
  });

  if (!response.ok) {
    throw new Error(`data.gov.sg returned HTTP ${response.status}`);
  }

  const json = (await response.json()) as DataGovResponse;
  if (!json.success) {
    throw new Error("data.gov.sg returned an unsuccessful response");
  }

  const rawRecords = json.result?.records ?? [];
  const records = applyPriceFilters(rawRecords, query);
  const total = json.result?.total ?? records.length;

  await redis.set(cacheKey, { records, total }, { ex: 60 * 60 * 6 });

  return { records, total, cached: false };
}
```

---

## 4. Temporary test route

Create `src/app/api/test-hdb/route.ts`:

```ts
import { hdbQuerySchema } from "@/lib/hdb/schema";
import { fetchHdbResalePrices } from "@/lib/hdb/data-gov";

export const runtime = "nodejs";

export async function GET() {
  const query = hdbQuerySchema.parse({ town: "ANG MO KIO", limit: 3, offset: 0 });
  const result = await fetchHdbResalePrices(query);
  return Response.json(result);
}
```

Visit `http://localhost:3000/api/test-hdb`. You should get real HDB rows for Ang Mo Kio. Run it again — `cached` should now be `true`.

You can delete this route after confirming it works, or keep it for local debugging.

---

## Checkpoint

- [ ] `hdbQuerySchema` validates and defaults `limit`/`offset` correctly.
- [ ] `fetchHdbResalePrices` returns real rows from data.gov.sg on first call.
- [ ] A second identical call returns `cached: true` and is noticeably faster.

---

## Troubleshooting

**Empty `records` array**
Town/flat type filters are exact-match and case-sensitive against the dataset — always send uppercase values like `ANG MO KIO`, `TAMPINES`, `4 ROOM`.

**`data.gov.sg returned HTTP 404` or similar**
Government datasets occasionally change resource IDs. Search data.gov.sg for "HDB Resale Flat Prices" and update `RESOURCE_ID` if needed.

**Price filters feel incomplete**
`min_price`/`max_price` filter only the page of rows already fetched from the datastore, not the entire remote dataset — good enough for this tutorial. Appendix C covers ingesting the full dataset into Postgres for real filtering/search at scale.

---

Ready for **Part 7 — The Public API Route Handler**?
