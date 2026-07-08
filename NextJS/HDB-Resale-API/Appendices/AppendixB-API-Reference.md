# Appendix B: API Reference and Example Queries

A compact reference for anyone consuming your HDB Resale API.

---

## Base URL

Local:

```txt
http://localhost:3000
```

Production:

```txt
https://your-project.vercel.app
```

---

## Authentication

Every request to the public API must include:

```txt
x-api-key: hdb_live_...
```

Example:

```bash
curl "https://your-project.vercel.app/api/v1/resale-prices?limit=5" \
  -H "x-api-key: hdb_live_your_key_here"
```

---

## Endpoint

```txt
GET /api/v1/resale-prices
```

Returns Singapore HDB resale flat transaction records, optionally filtered.

---

## Query parameters

| Parameter | Type | Default | Notes |
| --- | --- | --- | --- |
| `town` | string | none | Example: `ANG MO KIO`, `TAMPINES`, `QUEENSTOWN` (uppercase) |
| `flat_type` | string | none | Example: `3 ROOM`, `4 ROOM`, `5 ROOM` (uppercase) |
| `month` | string | none | Format `YYYY-MM`, e.g. `2024-03` |
| `min_price` | number | none | Filters the fetched page by minimum resale price |
| `max_price` | number | none | Filters the fetched page by maximum resale price |
| `limit` | number | `20` | Minimum 1, maximum 100 |
| `offset` | number | `0` | Pagination offset |

---

## Examples

**First 5 records, no filters:**

```bash
curl "http://localhost:3000/api/v1/resale-prices?limit=5" \
  -H "x-api-key: hdb_live_your_key_here"
```

**By town:**

```bash
curl "http://localhost:3000/api/v1/resale-prices?town=ANG%20MO%20KIO&limit=5" \
  -H "x-api-key: hdb_live_your_key_here"
```

**By town and flat type:**

```bash
curl "http://localhost:3000/api/v1/resale-prices?town=TAMPINES&flat_type=4%20ROOM&limit=10" \
  -H "x-api-key: hdb_live_your_key_here"
```

**By month:**

```bash
curl "http://localhost:3000/api/v1/resale-prices?month=2024-01&limit=10" \
  -H "x-api-key: hdb_live_your_key_here"
```

**By price range:**

```bash
curl "http://localhost:3000/api/v1/resale-prices?min_price=400000&max_price=600000&limit=10" \
  -H "x-api-key: hdb_live_your_key_here"
```

**Pagination:**

```bash
curl "http://localhost:3000/api/v1/resale-prices?limit=20&offset=20" \
  -H "x-api-key: hdb_live_your_key_here"
```

---

## Success response shape

```json
{
  "data": [
    {
      "month": "2024-01",
      "town": "ANG MO KIO",
      "flat_type": "4 ROOM",
      "block": "123",
      "street_name": "ANG MO KIO AVE 3",
      "storey_range": "10 TO 12",
      "floor_area_sqm": "92",
      "flat_model": "New Generation",
      "lease_commence_date": "1978",
      "remaining_lease": "53 years",
      "resale_price": "520000"
    }
  ],
  "meta": {
    "count": 1,
    "total": 1000,
    "limit": 5,
    "offset": 0,
    "cached": true
  }
}
```

---

## Error responses

**Missing API key (401):**

```json
{ "error": { "message": "Missing x-api-key header.", "status": 401 } }
```

**Invalid or revoked API key (401):**

```json
{ "error": { "message": "Invalid or revoked API key.", "status": 401 } }
```

**Invalid query (400):**

```json
{
  "error": {
    "message": "Invalid query parameters.",
    "status": 400,
    "issues": { "limit": ["Number must be less than or equal to 100"] }
  }
}
```

**Rate limited (429):**

```json
{ "error": { "message": "Rate limit exceeded. Try again later.", "status": 429 } }
```

**Upstream failure (502):**

```json
{ "error": { "message": "Unable to fetch HDB resale data right now.", "status": 502 } }
```

---

## Rate limit headers

Present on both successful and rate-limited responses:

```txt
X-RateLimit-Limit
X-RateLimit-Remaining
X-RateLimit-Reset
```

Default limit: 60 requests per 60-second fixed window, per API key.

---

## Data source attribution

Data is sourced from Singapore's data.gov.sg — HDB Resale Flat Prices dataset. In any public production product, clearly attribute the data source and review data.gov.sg's terms of use/license before commercial use.

---

Ready for the final piece: **Appendix C — Production Hardening Roadmap**?
