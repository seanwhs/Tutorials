# Part 14: Deploying to Vercel for Free

Previous: Part 13 (Polish). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

We deploy to **Vercel's free Hobby tier**, which is zero-config for Next.js. The main extra steps versus local dev: (a) switching our SQLite database to something that works in a serverless/production environment, and (b) creating a **production webhook endpoint** in the Stripe Dashboard (the Stripe CLI was only for local dev).

## 2. Database note: SQLite in production

SQLite as a single local file works great for this tutorial, but most serverless hosts (including Vercel) don't provide persistent writable disk across deployments/instances — a file-based `dev.db` will not reliably persist in that environment. For this tutorial, pick one:

- **Simplest (recommended for following along):** deploy anyway with SQLite for demo purposes, understanding that order history may not persist reliably across deployments/cold starts on Vercel. This is fine for demonstrating Checkout + webhooks working live, which is this series' main goal.
- **Production-grade option:** swap the Prisma datasource to a free hosted Postgres provider (e.g. Neon or Supabase free tier) before deploying. This only requires changing `provider = "sqlite"` to `provider = "postgresql"` in `prisma/schema.prisma`, updating `DATABASE_URL`, and re-running `npx prisma migrate dev`. This is noted as a recommended upgrade in Appendix E, but kept optional here to avoid adding a new account requirement mid-series.

The rest of this part assumes you're deploying as-is (SQLite) for simplicity, per the first option.

## 3. Push your code to GitHub

If you haven't already:

```bash
git add .
git commit -m "feat: complete Acme Shop Stripe tutorial app"
git remote add origin <your-repo-url>
git push -u origin main
```

## 4. Import the project into Vercel

1. Go to https://vercel.com and sign up/log in (free, no credit card required for Hobby tier).
2. Click **Add New → Project**, then import your GitHub repository.
3. Vercel auto-detects Next.js — leave build settings as default (`next build`, `.next` output).
4. Before clicking Deploy, add Environment Variables (see next step).

## 5. Set production environment variables

In the Vercel project's **Settings → Environment Variables**, add:

```
STRIPE_SECRET_KEY=sk_test_...              (same test key, or your own if you made a separate one)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=                      (leave blank for now — filled in step 7)
NEXT_PUBLIC_APP_URL=https://your-project-name.vercel.app
DATABASE_URL=file:./dev.db
```

We're staying in Stripe **test mode** even in production for this tutorial, so nothing ever charges a real card — appropriate for a learning project. Click **Deploy**.

## 6. Confirm the deployment

Once deployed, visit your Vercel URL. You should see the same Acme Shop homepage. Try a test purchase — Checkout should work immediately (it doesn't depend on the webhook to redirect you to `/success`).

## 7. Create a production webhook endpoint in the Stripe Dashboard

The Stripe CLI was only for local forwarding — production needs a real registered endpoint:

1. Go to https://dashboard.stripe.com/test/webhooks (still test mode).
2. Click **+ Add endpoint**.
3. Endpoint URL: `https://your-project-name.vercel.app/api/webhooks/stripe`.
4. Select events to listen for: `checkout.session.completed`, `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`.
5. Click **Add endpoint**. Stripe shows a **Signing secret** (starts with `whsec_...`) — copy it.
6. Back in Vercel, edit `STRIPE_WEBHOOK_SECRET` to this new value (it will differ from your local CLI's secret — that's expected; each endpoint has its own signing secret).
7. Redeploy (Vercel → Deployments → ⋯ → Redeploy) so the new env var takes effect.

## 8. End-to-end production test

1. Visit your live Vercel URL, buy a product with test card `4242 4242 4242 4242`.
2. In the Stripe Dashboard, go to **Developers → Webhooks → [your endpoint] → recent events** — you should see `checkout.session.completed` delivered with a `200` response.
3. Visit `/orders` on your live site — the order should appear (subject to the SQLite persistence caveat in step 2; if it doesn't persist, this confirms you should migrate to Postgres per Appendix E).

## Checkpoint

- [ ] Code pushed to GitHub.
- [ ] Project deployed on Vercel with all env vars set.
- [ ] Production Stripe webhook endpoint created, pointing at your live `/api/webhooks/stripe` URL.
- [ ] `STRIPE_WEBHOOK_SECRET` updated to the production endpoint's signing secret, project redeployed.
- [ ] A live test purchase shows a `200` delivered event in the Stripe Dashboard's webhook logs.

## Next

Continue to Part 15: Conclusion & Next Steps.
