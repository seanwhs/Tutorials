## Blog Tutorial - Appendix B: Environment Variables & Free-Tier Setup Checklist

## Runtime requirement

**Node.js 20.9+ required (Node 22 LTS recommended)** for Next.js 16. Node 18 is end-of-life and unsupported. Check with `node -v` before starting, and again before deploying (Vercel project settings → Node.js Version).

## Complete .env.local reference

```
# Sanity
NEXT_PUBLIC_SANITY_PROJECT_ID=          # from sanity.io/manage
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-01-01
SANITY_API_WRITE_TOKEN=                 # Editor-permission token, server-only, never expose to client

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=      # pk_test_... (or pk_live_... in production)
CLERK_SECRET_KEY=                       # sk_test_... (or sk_live_... in production)
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/

# Site
NEXT_PUBLIC_SITE_URL=                   # http://localhost:3000 locally, your Vercel URL in production
```

Variables prefixed `NEXT_PUBLIC_` are exposed to the browser — never put secrets there. `CLERK_SECRET_KEY` and `SANITY_API_WRITE_TOKEN` must remain server-only.

## Free-tier limits reference (as designed for in this tutorial)

These are the free tiers referenced throughout the series. Limits can change over time — always check each provider's current pricing page — but at time of writing they comfortably support this tutorial and small real-world blogs:

- **Sanity** (Free/"Growth" plan): 3 users, generous free API request allowance, unlimited document types, 5GB assets — no credit card required to start.
- **Clerk** (Free plan): up to 10,000 monthly active users, unlimited sign-ins, social login providers, prebuilt UI components — no credit card required. Use a package version with confirmed Next.js 16 support.
- **Vercel** (Hobby plan): unlimited personal projects, generous bandwidth/build minutes for hobby use, automatic HTTPS, free custom domain support, edge network — no credit card required. Supports Next.js 16 out of the box, including Turbopack builds.
- **GitHub** (Free plan): unlimited public/private repos — no credit card required.

## Account setup checklist (do these once, in order)

- [ ] Node.js 20.9+ installed locally (22 LTS recommended)
- [ ] GitHub account created, SSH or HTTPS git auth configured
- [ ] Sanity account created at sanity.io — project created, Project ID noted
- [ ] Clerk account created at clerk.com — application created, Publishable/Secret keys noted
- [ ] Vercel account created at vercel.com (sign in with GitHub for easiest repo import)

## Per-environment checklist

### Local development (.env.local)
- [ ] `node -v` confirms 20.9+ before running `npm install` or `npm run dev`
- [ ] All Sanity vars set (Project ID, dataset, API version)
- [ ] Sanity write token generated and set (needed once you reach Part 8, Comments)
- [ ] All Clerk vars set with **test/development** keys (`pk_test_`/`sk_test_`)
- [ ] `NEXT_PUBLIC_SITE_URL=http://localhost:3000`
- [ ] `.env.local` present in `.gitignore` (verify: `git check-ignore -v .env.local` should print something)
- [ ] `localhost:3000` added to Sanity CORS origins (Part 2/12)
- [ ] No `tailwind.config.ts` file present — confirm Tailwind config lives entirely in `globals.css` (Tailwind v4 CSS-first config)

### Production (Vercel dashboard → Settings → Environment Variables)
- [ ] All the same variable **names** as local, with production values
- [ ] `NEXT_PUBLIC_SITE_URL` set to your real Vercel (or custom) domain
- [ ] Your Vercel domain added to Sanity CORS origins, with "Allow credentials" checked
- [ ] Your Vercel domain added to Clerk's allowed domains
- [ ] Vercel project's Node.js Version setting is 20.x or newer (22.x if available)
- [ ] Redeployed after any environment variable change (Next.js inlines `NEXT_PUBLIC_*` vars at build time, so a redeploy — not just a save — is required)

## Costs you should never see in this tutorial
If you're ever asked for a credit card by Sanity, Clerk, Vercel, or GitHub while following this exact tutorial, you've likely clicked into a paid upgrade path by mistake — everything required here is available on each provider's free tier. Double check you're on the free/hobby plan before entering any payment details.
