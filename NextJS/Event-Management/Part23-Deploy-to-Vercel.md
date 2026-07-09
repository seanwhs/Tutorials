# **Part 23: Deploying to Vercel for Free**:

---

# Part 23: Deploying to Vercel for Free

Deploy live for $0/month on Vercel's Hobby tier — full support for Next.js 16 + Turbopack production builds, zero special config.

## 1. Push to GitHub
```bash
git add .
git commit -m "EventHub feature-complete, ready to deploy"
git remote add origin https://github.com/YOUR_USERNAME/eventhub.git
git branch -M main
git push -u origin main
```

## 2. Import into Vercel
1. https://vercel.com/new → sign in with GitHub → select `eventhub` repo → **Import**
2. Vercel auto-detects Next.js 16. Its build image already satisfies Node 20.9+/22 LTS — only override under **Project Settings → General → Node.js Version** if needed.
3. **Before deploying**, add all env vars from `.env.local`:
```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY
NEXT_PUBLIC_CLERK_SIGN_IN_URL
NEXT_PUBLIC_CLERK_SIGN_UP_URL
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL
DATABASE_URL
CLERK_WEBHOOK_SECRET
RESEND_API_KEY
```
`DATABASE_URL`: same Neon pooled string works for prod (optionally use a separate Neon branch). `CLERK_WEBHOOK_SECRET`: placeholder for now — updated in step 4.

4. Click **Deploy** → builds with Turbopack → live at `https://eventhub-yourname.vercel.app`.

## 3. Migrations
Already applied if using the same Neon database. If using a separate branch:
```bash
DATABASE_URL="your-production-connection-string" pnpm db:migrate
```

## 4. Update Clerk for production
Clerk dashboard → **Webhooks** → Add second endpoint → `https://eventhub-yourname.vercel.app/api/webhooks/clerk` → subscribe to same events → copy new Signing Secret → update `CLERK_WEBHOOK_SECRET` in Vercel (Production env) → check Clerk's **Domains** settings → redeploy.

## 5. Configure Inngest for production
Inngest dashboard → add production URL `https://eventhub-yourname.vercel.app/api/inngest` → copy Signing/Event keys → add as Vercel env vars:
```
INNGEST_SIGNING_KEY
INNGEST_EVENT_KEY
```
Redeploy → check **Apps** shows synced, all 3 functions listed, cron shows next run time.

## 6. Resend in production
No changes needed — same API key works.

## 7. End-to-end smoke test
Sign up → create event → RSVP → check email (QR code) → check-in as organizer → confirm live attendee list updates → verify Inngest production **Runs** → click through dynamic routes (`/events/[id]`, `/dashboard/[id]`, `/my-rsvps/[id]`) to confirm async `params` works correctly on Vercel's Turbopack production build.

## 8. Custom domain (optional, free)
Vercel **Settings → Domains** → add domain → follow DNS instructions (CNAME/A record).

## Checkpoint
- [ ] Live at a public URL, built with Next.js 16 + Turbopack
- [ ] Full flow works end-to-end in production
- [ ] Clerk webhook shows successful deliveries
- [ ] Inngest shows production app synced, 3 functions, successful runs
- [ ] Total cost: $0/month

**Next: Part 24 — Roadmap and Phase 2 Ideas**
