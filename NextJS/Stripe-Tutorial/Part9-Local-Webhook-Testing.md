# Part 9: Local Webhook Testing with the Stripe CLI

Previous: Part 8 (Stripe Webhooks). Index: "Stripe Tutorial - INDEX (Start Here)".

## 1. Concept

Stripe can't send webhooks to `http://localhost:3000` directly — your local machine isn't reachable from the internet. The free, official solution is the **Stripe CLI**, which opens an authenticated tunnel from your Stripe account to your local dev server and forwards real test-mode events to it.

## 2. Install the Stripe CLI

Pick the method for your OS (all free, open-source):

**macOS (Homebrew):**
```bash
brew install stripe/stripe-cli/stripe
```

**Windows (Scoop):**
```bash
scoop bucket add stripe https://github.com/stripe/scoop-bucket.git
scoop install stripe
```

**Linux:** download the latest `.tar.gz` from https://github.com/stripe/stripe-cli/releases/latest, extract it, and move the `stripe` binary onto your PATH.

Confirm installation:
```bash
stripe --version
```

## 3. Log in

```bash
stripe login
```

This opens a browser window to authorize the CLI against your Stripe account (test mode). Follow the prompts.

## 4. Forward webhooks to your local app

With `npm run dev` already running in one terminal, open a **second terminal** and run:

```bash
stripe listen --forward-to localhost:3000/api/webhooks/stripe
```

The CLI prints something like:

```
> Ready! Your webhook signing secret is whsec_XXXXXXXXXXXXXXXXXXXXXXXX (^C to quit)
```

Copy that `whsec_...` value into your `.env.local`:

```bash
# .env.local
STRIPE_WEBHOOK_SECRET=whsec_XXXXXXXXXXXXXXXXXXXXXXXX
```

**Restart your `npm run dev` process** after editing `.env.local` — Next.js only reads env files on startup.

Keep the `stripe listen` command running in its own terminal for the rest of local development — it must be running any time you want webhooks to reach your app locally.

## 5. Trigger a real test event end-to-end

With both `npm run dev` and `stripe listen` running:
1. Go to `http://localhost:3000`, buy a product (or check out a cart) using test card `4242 4242 4242 4242`.
2. Watch the `stripe listen` terminal — you should see a line like:
   ```
   2024-XX-XX checkout.session.completed [evt_...] --> localhost:3000/api/webhooks/stripe [200]
   ```
   A `[200]` means your handler accepted it successfully.
3. Watch your `npm run dev` terminal — you should see the `console.log("Recorded order for session ...")` line from Part 8.

## 6. Manually replay events (useful for debugging)

You can also fire a synthetic test event without a real checkout:

```bash
stripe trigger checkout.session.completed
```

Note: this synthetic event won't have real line items tied to your actual products, so `stripe.checkout.sessions.listLineItems` may return empty results — that's expected. Use this mainly to confirm your route responds `200` and doesn't crash; use a real browser checkout (step 5) to test full data correctness.

## 7. Confirm the order landed in the database

Use Prisma Studio, a free built-in GUI for browsing your local database:

```bash
npx prisma studio
```

This opens a browser tab at `http://localhost:5555`. Click into the `Order` and `OrderItem` tables — you should see the order(s) created by your real test checkout(s) from step 5.

## 8. Common pitfalls

- **403/400 signature errors:** almost always means `STRIPE_WEBHOOK_SECRET` in `.env.local` doesn't match the secret currently printed by your running `stripe listen` command. Every time you restart `stripe listen`, double check whether it printed the same secret (it's usually stable per CLI login session, but re-copy if in doubt).
- **No events showing up in `stripe listen` at all:** confirm you're checking out in the **same Stripe account/test mode** the CLI is logged into, and that `npm run dev` is actually running on port 3000.
- **Order created twice:** shouldn't happen thanks to the idempotency check in Part 8, but if you see duplicates, confirm `stripeCheckoutId` is actually unique in your schema and that migration was applied.

## Checkpoint

- [ ] `stripe --version` works.
- [ ] `stripe listen --forward-to localhost:3000/api/webhooks/stripe` is running and printed a `whsec_...` secret.
- [ ] `.env.local` updated with that secret, dev server restarted.
- [ ] A real test purchase shows a `[200]` in the `stripe listen` terminal and a "Recorded order" log in the dev server terminal.
- [ ] Prisma Studio shows the resulting Order + OrderItem rows.

## Next

Continue to Part 10: Order History Page.
