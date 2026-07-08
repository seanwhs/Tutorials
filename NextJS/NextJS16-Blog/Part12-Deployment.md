## Blog Tutorial - Part 12: Deployment to Vercel

## What we're doing
We'll deploy our blog to Vercel's free "Hobby" tier, configure production environment variables for Sanity and Clerk, set up Clerk's production instance, add our domain to Sanity's CORS allowlist, and confirm everything works end to end in production.

## Step 1: Commit and push all your work

```bash
git add .
git commit -m "Complete blog: Next.js 16 + Sanity + Clerk + Tailwind v4, ready to deploy"
git push
```

(Make sure `.env.local` is in your `.gitignore` — we never commit secrets to git. Check with `cat .gitignore` — Next.js includes `.env*.local` there by default.)

## Step 2: Create a Vercel account and import your project
1. Go to https://vercel.com/signup and sign up with your GitHub account (free, no credit card)
2. Click "Add New..." → "Project"
3. Select your `my-blog` GitHub repository → Import
4. Vercel auto-detects Next.js 16 — leave build settings as default (`next build`, which uses Turbopack by default in Next.js 16)

## Step 3: Confirm Vercel's Node.js version

Next.js 16 requires Node 20.9+. Vercel's default Node version for new projects is already compatible, but double check: in your Vercel project → Settings → General → "Node.js Version", select **20.x** or newer (22.x if available) if it isn't already set. Using an older Node version here will cause your build to fail.

## Step 4: Add environment variables in Vercel

Before clicking Deploy, expand "Environment Variables" and add every variable from your `.env.local`:

```
NEXT_PUBLIC_SANITY_PROJECT_ID
NEXT_PUBLIC_SANITY_DATASET
NEXT_PUBLIC_SANITY_API_VERSION
SANITY_API_WRITE_TOKEN
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY
NEXT_PUBLIC_CLERK_SIGN_IN_URL
NEXT_PUBLIC_CLERK_SIGN_UP_URL
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL
NEXT_PUBLIC_SITE_URL
```

For `NEXT_PUBLIC_SITE_URL`, you won't know your exact Vercel URL until after the first deploy. Two options:
- Simplest: deploy first with a placeholder, then come back and update it to the real URL (e.g. `https://my-blog-yourname.vercel.app`) and redeploy.
- Or: assign a custom domain in Vercel now and use that.

Click **Deploy**.

## Step 5: Wait for the build, then get your live URL

Vercel will run `npm install` and `next build` (using Turbopack, the Next.js 16 default). When it finishes, you'll get a live URL like `https://my-blog-yourname.vercel.app`. Click "Visit".

You'll likely see a **Sanity CORS error** in the console when the homepage tries to fetch posts — that's expected, let's fix it next.

## Step 6: Add your Vercel domain to Sanity's CORS allowlist
1. Go to https://www.sanity.io/manage → your project → API tab → CORS Origins
2. Click "Add CORS origin"
3. Enter your Vercel URL, e.g. `https://my-blog-yourname.vercel.app`
4. Check "Allow credentials" (needed if you use authenticated requests)
5. Save

Also add `http://localhost:3000` here if you haven't already (needed for local dev to fetch data, though the CLI init step in Part 2 sometimes adds this automatically).

## Step 7: Configure Clerk for production
1. In your Clerk dashboard, go to "Domains" (or "Deployment" depending on Clerk's current UI)
2. Add your Vercel production URL as an allowed domain
3. Clerk's free tier gives you both a "development" instance (what you've been using, prefixed `pk_test_`) and lets you set up a "production" instance (`pk_live_`) for real deployments. For following this tutorial, using the development keys in production works fine for personal projects/testing; for a real public launch, create a Production instance in Clerk and swap in `pk_live_` / `sk_live_` keys as new Vercel environment variables. Confirm whichever Clerk package version you're using explicitly lists Next.js 16 support in its release notes.
4. Redeploy after changing environment variables (Vercel → Deployments → ⋯ → Redeploy), since Next.js bakes `NEXT_PUBLIC_*` vars in at build time.

## Step 8: Update NEXT_PUBLIC_SITE_URL and redeploy

Go to Vercel → your project → Settings → Environment Variables → edit `NEXT_PUBLIC_SITE_URL` to your real URL (e.g. `https://my-blog-yourname.vercel.app`). Then Deployments → ⋯ on the latest deployment → Redeploy.

## Step 9: Verify everything in production

Visit your live URL and check:
- [ ] Homepage loads posts from Sanity
- [ ] Post detail pages work, including images and code blocks
- [ ] `/studio` loads and you can log in and edit content
- [ ] Sign in / sign up works
- [ ] Comments can be posted while signed in
- [ ] Members-only posts show the paywall when signed out
- [ ] Dark mode toggle works
- [ ] `/sitemap.xml` and `/robots.txt` return correct content with your real domain
- [ ] Visit `/posts/your-slug/opengraph-image` and confirm the generated image loads
- [ ] No build errors related to `params` being treated as a plain object instead of a Promise (this is the most common Next.js 16 migration mistake — see Appendix C if you hit this)

## Step 10: Continuous deployment going forward

From now on, every `git push` to your `main` branch automatically triggers a new Vercel deployment. This means:
- Code changes: edit locally → commit → push → live in ~1 minute
- Content changes: edit in `/studio` (either locally or on your live `/studio` URL) → shows up within 60 seconds (our `revalidate = 60`) with **no redeploy needed**, since content lives in Sanity, not in your codebase

## Step 11 (optional): Custom domain

If you own a domain, in Vercel go to Settings → Domains → Add, and follow the DNS instructions (usually adding an A record or CNAME at your registrar). Vercel provisions free SSL automatically. Remember to also add the custom domain to Sanity's CORS list and Clerk's allowed domains, and update `NEXT_PUBLIC_SITE_URL` again.

## Checkpoint ✅
- [ ] Site is live on a public Vercel URL
- [ ] Vercel project is configured to use Node.js 20.x+ (22.x recommended)
- [ ] All features (posts, auth, comments, paywall, dark mode, SEO files) work in production
- [ ] Sanity CORS and Clerk domains are configured for the production URL
- [ ] Pushing a git commit triggers automatic redeployment

Next: **Conclusion**
