# Part 11: End-to-End Testing

Goal: walk through the entire product once, end to end, confirming every piece from Parts 1-10 works together.

---

## 1. Start fresh

```bash
npm run dev
```

Visit `http://localhost:3000`.

---

## 2. Full browser walkthrough

1. Click **Get an API key** on the home page.
2. Enter your email on `/login` and submit.
3. Confirm you land on `/dashboard`, signed in with your email shown.
4. Go to `/dashboard/keys`.
5. Create a key named `Local test key`.
6. Copy the raw key immediately — it's shown only once.
7. Visit `/docs` and confirm the documentation page renders correctly.

---

## 3. Test a successful API call

```bash
curl -i "http://localhost:3000/api/v1/resale-prices?town=ANG%20MO%20KIO&limit=2" \
  -H "x-api-key: paste_your_key_here"
```

Expect: HTTP 200, `X-RateLimit-*` headers, and a JSON body with `data`/`meta`.

---

## 4. Test failure cases

```bash
# missing key -> 401
curl -i "http://localhost:3000/api/v1/resale-prices?limit=1"

# invalid key -> 401
curl -i "http://localhost:3000/api/v1/resale-prices?limit=1" -H "x-api-key: fake"

# invalid query -> 400 (limit above 100)
curl -i "http://localhost:3000/api/v1/resale-prices?limit=999" -H "x-api-key: paste_your_key_here"
```

---

## 5. Test usage tracking

After a few successful calls, visit `/dashboard/usage`. Today's bar for your key should reflect the number of successful calls made.

---

## 6. Test revocation

1. Go to `/dashboard/keys`.
2. Revoke your test key.
3. Repeat the successful curl call from step 3 with the same (now revoked) key.

Expected: HTTP 401 this time.

---

## 7. Optional: scripted smoke test

Create `scripts/smoke-test.mjs`:

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

Run it:

```bash
API_KEY="paste_your_key_here" node scripts/smoke-test.mjs
```

---

## Checkpoint

- [ ] Login → dashboard → key creation flow works end to end.
- [ ] Public API returns 200 for valid requests, 401 for missing/invalid keys, 400 for bad params.
- [ ] Rate-limit headers appear on every response from the public endpoint.
- [ ] Usage dashboard reflects successful calls only.
- [ ] Revoking a key immediately breaks future calls with that key.
- [ ] `/docs` loads correctly.

---

## Troubleshooting

**`fetch is not defined` when running the smoke test script**
Use Node.js 18+ (this course recommends Node 22 LTS) — native `fetch` requires it.

**401 even though you copied a key**
Confirm you copied the entire raw key string (starting with `hdb_live_`), not just the short prefix shown in the keys table afterward.

**Usage dashboard shows 0 despite calls succeeding**
Only successful (HTTP 200) calls increment usage — 401/400/429 responses are intentionally excluded.

---

Ready for **Part 12 — Deploying to Vercel + Conclusion**, the final part of the core tutorial?
