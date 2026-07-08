# Part 12: Deploying to Vercel and Conclusion

Goal: deploy the app to Vercel and wrap up the course.

---

## 1. Commit your code

```bash
git add .
git commit -m "Build HDB resale price API and dashboard on Next.js 16"
```

If you haven't created a GitHub repo yet:

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/hdb-resale-api.git
git push -u origin main
```

---

## 2. Create a Vercel project

1. Go to https://vercel.com and sign in.
2. Import your GitHub repository.
3. Keep the detected framework as Next.js — no build settings need to change.
4. Add environment variables (next step) before deploying, or add them and redeploy afterward.

---

## 3. Set environment variables in Vercel

Add these under Project Settings → Environment Variables:

```env
UPSTASH_REDIS_REST_URL="your_upstash_url"
UPSTASH_REDIS_REST_TOKEN="your_upstash_token"
AUTH_COOKIE_SECRET="your_long_random_secret"
NEXT_PUBLIC_APP_URL="https://your-project.vercel.app"
```

Use your real, final deployed URL for `NEXT_PUBLIC_APP_URL` (you may need to redeploy once you know the exact URL Vercel assigns).

---

## 4. Deploy and verify

Click **Deploy**. Once it finishes, check:

```txt
https://your-project.vercel.app/api/health
```

Expected:

```json
{ "ok": true, "redis": true, "value": "...", "latencyMs": 123 }
```

---

## 5. Production walkthrough

1. Visit your deployed home page.
2. Log in with your email.
3. Create a production API key.
4. Call the live API:

```bash
curl -i "https://your-project.vercel.app/api/v1/resale-prices?limit=2" \
  -H "x-api-key: paste_production_key_here"
```

5. Check `/dashboard/usage` to confirm the call was recorded.
6. Check `/docs` renders correctly in production.

---

## 6. What you built

A complete, working, deployed developer product:

- Next.js 16 App Router application with Route Handlers
- signed-cookie login and protected dashboard
- API key generation, hashing, listing, and revocation
- a public, versioned API endpoint (`/api/v1/resale-prices`)
- Upstash Redis for storage, caching, and counters
- Upstash rate limiting per API key
- live HDB resale price data from data.gov.sg, cached in Redis
- a usage dashboard with per-key daily charts
- Fumadocs-powered API documentation
- a full Vercel deployment

---

## 7. Conclusion

This project teaches the same core architecture behind Stripe, Resend, OpenAI, and most developer-facing SaaS platforms:

```txt
account -> API key -> authenticated request -> rate limit -> service logic -> usage tracking -> docs
```

Here, that architecture happens to serve Singapore HDB resale transaction data — but the same pattern works equally well for weather data, transit data, finance data, or any internal company API you want to expose cleanly and safely.

From here, the highest-value next steps (fully detailed in Appendix C) are:

- swap the tutorial auth for Clerk, Auth.js, or Supabase Auth,
- move durable business data into Postgres,
- publish an OpenAPI spec,
- add paid tiers and billing,
- add monitoring/observability and abuse detection,
- add Terms of Service and a Privacy Policy.

Congratulations — you built and shipped a real public API product from scratch.

---

## Checkpoint

- [ ] App is live on Vercel.
- [ ] `/api/health` returns `ok: true` in production.
- [ ] Login, key creation, and the public API all work against the production URL.
- [ ] `/docs` works in production.

---

## Troubleshooting

**Production login redirects back to `/login` in a loop**
Confirm `AUTH_COOKIE_SECRET` is set in Vercel's environment variables and redeploy after adding it.

**Redis works locally but not in production**
Double-check both `UPSTASH_REDIS_REST_URL` and `UPSTASH_REDIS_REST_TOKEN` are set in Vercel (not just `.env.local`), and that they point to the same Upstash database you intend to use.

**A key created locally doesn't work in production**
Local and production only share data if both point at the exact same Upstash Redis database. If they're different databases, create a fresh key in production.

**Fumadocs build fails on Vercel**
Run the Fumadocs generation step locally first and confirm the app builds locally with `npm run build` before pushing; commit any generated source files your Fumadocs version requires.

---

🎉 That's the complete core tutorial (Parts 0–12)! You've built and deployed the whole HDB Resale API + dashboard.

Three appendices are also available whenever useful:
- **Appendix A** — Full Codebase Reference
- **Appendix B** — API Reference and Example Queries
- **Appendix C** — Production Hardening Roadmap (real auth, Postgres, OpenAPI, billing, observability, legal pages)
