# Sanity Mastery - Part 12: Deployment

## Approach A (Recommended): Embedded Studio Deploys with Your Next.js App

Since Part 1 embedded Studio at `/studio` inside the Next.js app itself, **deploying the app deploys the Studio** — no separate step.

### Step 1: Push to GitHub, import into Vercel

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourname/my-sanity-app.git
git push -u origin main
```

Vercel → **Add New Project** → import the repo → framework auto-detected as Next.js.

### Step 2: Environment variables in Vercel

**Project Settings → Environment Variables** — add every var from `.env.local`, split correctly:

| Variable | Environments |
|---|---|
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_DATASET` | Production, Preview, Development |
| `NEXT_PUBLIC_SANITY_API_VERSION` | Production, Preview, Development |
| `NEXT_PUBLIC_SITE_URL` | Set per-environment to the real deployed URL (Part 7's preview button depends on this being correct) |
| `SANITY_API_READ_TOKEN` | Production, Preview (never Development if the token is shared with teammates) |
| `SANITY_PREVIEW_SECRET` | Production, Preview |
| `SANITY_REVALIDATE_SECRET` | Production, Preview |
| `SANITY_WRITE_TOKEN` | Production only, if used (Part 9) |

### Step 3: Update CORS origins (Part 9) for the real domain

sanity.io/manage → API → CORS Origins → add:

```text
https://my-sanity-app.vercel.app
https://my-sanity-app-*.vercel.app   (wildcard for preview deployments, if supported on your plan)
```

### Step 4: Update the Sanity webhook (Part 8) to point at production

```text
https://my-sanity-app.vercel.app/api/revalidate
```

### Step 5: Deploy

```bash
git push origin main
```

Vercel builds and deploys automatically. Visit `https://my-sanity-app.vercel.app/studio` to confirm Studio loads in production, and log in with your Sanity account.

## Approach B (Alternative): Separately-Hosted Studio via `sanity deploy`

Some teams prefer a fully decoupled Studio (e.g. at `my-project.sanity.studio`) instead of embedding it — useful if multiple frontends (web + mobile admin tooling) share one Studio, or if you want Studio's lifecycle independent from app deploys.

```bash
npx sanity deploy
```

```text
? You're about to deploy "My Sanity App" to Sanity's hosting.
? Studio hostname: my-sanity-app   (becomes my-sanity-app.sanity.studio)
```

If choosing this path:
- **Remove** the `src/app/studio/[[...tool]]/page.tsx` route from the Next.js app (or keep it as a redirect to the hosted Studio URL)
- Editors log in at `https://my-sanity-app.sanity.studio` instead of `/studio`
- CORS origins still need the Next.js app's domain (for API reads), but no longer need the Studio's own origin added manually — Sanity's hosting handles that

| Consideration | Embedded (`/studio`, Approach A) | Hosted (`sanity deploy`, Approach B) |
|---|---|---|
| Extra hosting step | None | One extra `sanity deploy` command, separate from app CI |
| Studio URL | `yourapp.com/studio` | `yourproject.sanity.studio` |
| Studio version tied to app deploys | Yes (redeploy app to update Studio) | No (independent release cadence) |
| Best for | Single-frontend apps (this series' assumption) | Multi-frontend orgs, agencies managing many client sites from shared Studios |

## Post-Deployment Smoke Test Checklist

```text
[ ] / and /blog render published posts correctly
[ ] /blog/[slug] renders individual posts with images and Portable Text
[ ] /studio loads and logs in successfully
[ ] Editing + publishing a post in production Studio triggers the webhook
    and the live page updates within seconds (Part 8)
[ ] Clicking "Preview" on an unpublished draft shows draft content + yellow
    banner, and "Exit preview" works (Part 7)
[ ] Images load from cdn.sanity.io with no next/image console warnings (Part 6)
[ ] No SANITY_WRITE_TOKEN or SANITY_API_READ_TOKEN visible in browser
    devtools → Network → any request payload or response (Part 9)
```

## Checkpoint ✅
- [ ] App deployed to Vercel with all env vars split correctly across environments
- [ ] CORS origins updated for the real production (and preview) domain(s)
- [ ] Webhook URL updated to production
- [ ] Full smoke test checklist passed

**Series complete.** See Appendices A–E for consolidated reference material.

This wraps up the **main 13-part series** (Parts 0–12)! 🎉

Next up are the **Appendices** — reference material rather than sequential tutorial parts:

- **Appendix A** (5 notes) — full copy-pasteable codebase
- **Appendix B** — schema files summary reference
- **Appendix C** — env vars & config reference
- **Appendix D** — troubleshooting guide
- **Appendix E** — GROQ cheat sheet

Want me to continue with **Appendix A (1 of 5)**, or is there a specific appendix or part you'd like to revisit?
