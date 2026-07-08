# Part 13: Deployment to Vercel

Previous: Part 12 (Admin Dashboard Polish).

## 1. Concept

Vercel: zero-config, generous free tier, first-class Next.js 16 support. Real work here is reconfiguring every external service (Clerk, Neon, UploadThing, Resend, Stripe) with production credentials/webhook URLs.

## 2. Push your code to GitHub

```bash
git add .
git commit -m "feat: complete MVP through Part 12"
git branch -M main
git remote add origin https://github.com/yourusername/freelancer-portal.git
git push -u origin main
```

## 3. Create the Vercel project

1. vercel.com → sign in with GitHub → "Add New → Project" → select repo.
2. Framework auto-detects Next.js 16.
3. Vercel's build image satisfies the 20.9+ requirement; your `engines` field acts as an explicit floor.
4. Don't deploy yet — add env vars first.

## 4. Add production environment variables in Vercel

```
DATABASE_URL                          (same Neon URL, or separate prod project)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY     (Production instance, pk_live_...)
CLERK_SECRET_KEY                      (Production instance, sk_live_...)
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dispatch
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dispatch
CLERK_WEBHOOK_SECRET                  (new, prod endpoint)
UPLOADTHING_TOKEN
RESEND_API_KEY
EMAIL_FROM                            (verified domain)
ADMIN_NOTIFICATION_EMAIL
STRIPE_SECRET_KEY                     (sk_test_ or sk_live_)
STRIPE_WEBHOOK_SECRET                 (new, prod endpoint)
NEXT_PUBLIC_APP_URL                   (your Vercel/custom domain)
```

Key notes:
- Clerk Development and Production instances have separate keys and separate user bases — switch to Production before copying keys.
- Same Neon DB works for a personal project; separate project/branch for anything serious.
- Keep Stripe in test mode until ready for real payments.

## 5. First deploy

Watch build logs for Turbopack confirmation. Two common issues:

```json
// package.json
{
  "scripts": {
    "postinstall": "prisma generate",
    "build": "prisma migrate deploy && next build"
  }
}
```

This regenerates the Prisma Client and applies pending migrations on every deploy.

## 6. Update Clerk production settings

1. Switch to Production instance.
2. Confirm Paths match env vars.
3. Redo "Customize session token" (per-instance setting).
4. Add webhook: `https://your-domain.vercel.app/api/webhooks/clerk`, subscribe to `user.created`/`user.updated`, copy secret.
5. Sign up on live URL, set `publicMetadata.role: "ADMIN"` again (separate user base from Development).

## 7. Update Stripe webhook for production

1. Stripe dashboard → Developers → Webhooks → Add endpoint.
2. URL: `https://your-domain.vercel.app/api/webhooks/stripe`.
3. Event: `checkout.session.completed`.
4. Copy secret into Vercel's `STRIPE_WEBHOOK_SECRET` (independent of local CLI secret).

## 8. Update Resend

Just ensure `EMAIL_FROM` uses a verified domain (required to send to arbitrary recipients).

## 9. Custom domain (optional)

Vercel Settings → Domains → add domain, follow DNS instructions. Update `NEXT_PUBLIC_APP_URL` and both webhook URLs, then redeploy.

## 10. Continuous deployment

Every `git push` to main auto-deploys. PRs get preview deployments.

## Checkpoint

- [ ] Vercel URL shows homepage
- [ ] Sign up creates User row in production DB
- [ ] ADMIN role reaches `/admin` on live site
- [ ] Full client/project/proposal/invoice flow works in production
- [ ] Test Stripe payment flips invoice to PAID via prod webhook
- [ ] Invoice-sent email arrives

## Troubleshooting

- **500 right after deploy, Prisma-related**: confirm postinstall script + migrate deploy ran
- **Redirected to /portal despite being admin**: role set in wrong Clerk instance
- **Stripe webhook 400**: secret mismatch (prod vs CLI)
- **Node engine mismatch**: check `engines.node` and Vercel's Node.js Version setting

## Next

Continue to **Part 14: Conclusion and Phase 2 Roadmap** — the final part.
