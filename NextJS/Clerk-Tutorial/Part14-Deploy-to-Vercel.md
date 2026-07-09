# Part 14: Deploying to Vercel for Free

Time to put your app on the real internet. Vercel (made by the creators of Next.js) has a free "Hobby" tier that's perfect for this, and has first-class support for Next.js 16 (Turbopack builds included) on day one.

## 1. Push your project to GitHub

If you haven't already, create a repository:

1. Go to https://github.com/new
2. Name it `acme-boards` (or whatever you like), keep it public or private (either works fine with Vercel's free tier), don't initialize with a README (you already have a project).
3. Back in your terminal, inside the project folder:

```bash
git remote add origin https://github.com/YOUR_USERNAME/acme-boards.git
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username. If prompted to authenticate, follow GitHub's device login flow or use a personal access token (GitHub no longer accepts plain passwords over the CLI).

## 2. Import the project into Vercel

1. Go to https://vercel.com and sign up/log in (free, you can use your GitHub account to sign up which simplifies the next step).
2. Click **Add New → Project**.
3. Choose **Import Git Repository** and select your `acme-boards` repo (you may need to authorize Vercel to access your GitHub account/repos first).
4. Vercel auto-detects it's a Next.js project — leave the build settings on their defaults. Vercel automatically uses a compatible Node.js runtime (20.x/22.x) and Turbopack for the build, matching Next.js 16's requirements without any extra configuration from you.
5. Before clicking Deploy, expand **Environment Variables** and add:
   - `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
   - `CLERK_SECRET_KEY`
   - `NEXT_PUBLIC_CLERK_SIGN_IN_URL` = `/sign-in`
   - `NEXT_PUBLIC_CLERK_SIGN_UP_URL` = `/sign-up`
   - `NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL` = `/dashboard`
   - `NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL` = `/dashboard`
   - `CLERK_WEBHOOK_SECRET` (we'll actually replace this value in step 5 below with a new production one, but you can paste a placeholder for now)

   Use the same values from your `.env.local` for the Clerk keys, for now — we'll discuss switching to a production Clerk instance next.
6. Click **Deploy**. Vercel builds and deploys your app — this takes a minute or two.

## 3. Understand development vs. production Clerk instances

Recall from Part 4: your Clerk application has a **Development instance** (`pk_test_`/`sk_test_` keys) which is fine for `localhost`. For a real production deployment, Clerk strongly recommends creating a **Production instance**, which:
- Uses `pk_live_`/`sk_live_` keys
- Requires verifying a real domain (Vercel gives you one automatically, like `acme-boards.vercel.app`, or you can attach your own custom domain)
- Has stricter security settings appropriate for real users

**To keep this tutorial simple and free**, you can actually continue using your Development instance keys even on your deployed Vercel app — Clerk allows this, and it's totally fine for a portfolio/demo/learning project. Just be aware that development instances have some restrictions (e.g. limits on daily sign-ups) not meant for real production traffic at scale. If/when you're ready to launch something real, switch to a Production instance from the Clerk Dashboard (Configure → your instance selector) and update Vercel's environment variables with the new `pk_live_`/`sk_live_` keys.

## 4. Visit your live app

Once deployed, Vercel gives you a URL like `https://acme-boards.vercel.app`. Visit it and confirm:
1. The homepage loads and is styled correctly.
2. `/sign-up` and `/sign-in` work.
3. After signing in, you land on `/dashboard` and see your data.
4. The `OrganizationSwitcher` and `UserButton` both work.

## 5. Register the production webhook endpoint

Now that you have a permanent public URL, replace the temporary ngrok-based webhook from Part 13:

1. Go to Clerk Dashboard → **Webhooks**.
2. Either edit your existing endpoint's URL, or (recommended for clarity) delete the ngrok one and **Add Endpoint** fresh:
   - Endpoint URL: `https://acme-boards.vercel.app/api/webhooks/clerk` (use your actual Vercel URL)
   - Subscribe to the same events: `user.created`, `user.updated`, `user.deleted`
3. Copy the new **Signing Secret**.
4. In your Vercel project settings → **Environment Variables**, update `CLERK_WEBHOOK_SECRET` with this new value.
5. Redeploy for the env var change to take effect: in Vercel, go to **Deployments**, click the "..." menu on the latest deployment, and choose **Redeploy** (or simply push a new commit to `main`, which triggers this automatically).

## 6. Test the production webhook

Sign up a new test user directly on your live Vercel URL. Then check Clerk Dashboard → Webhooks → your endpoint → **Message Attempts** to confirm a `200 OK` was recorded for the `user.created` event.

## 7. Continuous deployment going forward

From now on, every time you `git push` to `main`, Vercel automatically rebuilds and redeploys your app using Next.js 16 and Turbopack. This is the same workflow real teams use.

```bash
git add .
git commit -m "Ready for production"
git push
```

## Checkpoint

- [ ] Project pushed to GitHub
- [ ] Imported into Vercel with all required environment variables set
- [ ] Live app reachable at a `*.vercel.app` URL
- [ ] Sign up, sign in, dashboard, organizations all work on the live URL
- [ ] Production webhook endpoint registered against the Vercel URL, with a fresh signing secret
- [ ] Confirmed a live sign-up triggers a verified webhook delivery

## Troubleshooting

**Build fails on Vercel with a TypeScript or ESLint error that didn't show locally.**
Vercel runs a full production build (`next build`, using Turbopack by default in Next.js 16), which is stricter than the dev server about type errors. Run `npm run build` locally first to catch these before pushing — it's good practice to do this before every deploy.

**Build fails on Vercel citing an unsupported Node.js version.**
This shouldn't happen by default since Vercel automatically selects a Node runtime compatible with your Next.js version, but if you've manually pinned an older Node version in your Vercel project settings, update it to 20.x or 22.x to satisfy Next.js 16's requirement.

**App deploys but shows a Clerk-related error in production only.**
Almost always a missing or mistyped environment variable in Vercel's project settings. Double-check every key from step 2 is present, with no extra whitespace, and that you redeployed after adding/editing any of them (env var changes require a new deployment to take effect).

**Webhook Message Attempts show a `500` or `401` error.**
`500` usually means an unhandled error inside your route handler (check Vercel's function logs, under your project → Deployments → the specific deployment → Functions) — a common cause here specifically is forgetting to `await headers()` inside the route, per Part 13's Next.js 16 async-API note. `401`/`400` usually means `CLERK_WEBHOOK_SECRET` in Vercel doesn't match the endpoint you registered — recopy it carefully and redeploy.

**I want a custom domain instead of `*.vercel.app`.**
Vercel's free tier supports custom domains — add one under your project's **Settings → Domains**. If you do this, remember to also update your webhook endpoint URL in Clerk to match your custom domain, and consider setting up a Clerk Production instance tied to that domain for the most robust setup.

**Do I need to keep ngrok running after deployment?**
No — ngrok was only needed for local development in Part 13. Your deployed app has its own permanent public URL that Clerk can reach directly.

Next up: Part 15, our conclusion and where to go from here.
