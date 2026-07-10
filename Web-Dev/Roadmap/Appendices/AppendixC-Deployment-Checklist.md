# Appendix C: Deployment Checklist

Step-by-step, from a working local project to a live production URL.

## C.1 Pre-Flight (Local)

- [ ] `npm run build` succeeds locally with zero errors — never discover a build error for the first time on Vercel.
- [ ] `npm run lint` passes.
- [ ] `.env.local` exists locally and is listed in `.gitignore` (verify with `git status` — it should **not** appear as untracked/staged).
- [ ] `.env.example` exists and is committed, listing every required variable with placeholder values.
- [ ] All secrets (`DATABASE_URL`, any API keys) are referenced via `process.env.*`, never hardcoded.
- [ ] `git status` shows a clean working tree; latest work is committed.

## C.2 GitHub

- [ ] Repository exists on GitHub (Part 2.6).
- [ ] `git push -u origin main` has been run at least once — confirm by refreshing the GitHub repo page and seeing your latest commit.
- [ ] Repository visibility (public/private) matches your intent — Vercel's free tier works with either.

## C.3 Linking GitHub to Vercel

1. Go to vercel.com, sign in with your GitHub account (this grants Vercel read access to your repos).
2. Click **Add New -> Project**.
3. Select the `devboard` repository from the list. If it's not visible, click "Adjust GitHub App Permissions" and grant access to that repo specifically.
4. Vercel auto-detects the framework as **Next.js** — leave Build Command (`next build`) and Output Directory as the defaults; do not override these unless you have a specific reason.

## C.4 Environment Variables in Production

1. Still on the import screen (or later via **Project -> Settings -> Environment Variables**), add each variable from your `.env.example`:
   - Name: `DATABASE_URL`
   - Value: your **production** Neon connection string (can be the same Neon project, or a separate one — many teams use a separate database branch for Preview deployments)
   - Environment: check **Production**, and separately decide whether to also check **Preview** and **Development**
2. Repeat for every other secret your app needs (API keys, auth secrets, etc.) as your project grows beyond DevBoard's scope.
3. Never paste a secret into a commit, a Slack message, or a public issue — treat the Vercel dashboard as the single source of truth for production secrets.

## C.5 First Deploy

1. Click **Deploy**.
2. Watch the build logs in real time — this is the same `next build` output you validated locally in C.1, just running on Vercel's infrastructure.
3. On success, Vercel gives you a `*.vercel.app` production URL immediately.
4. Visit the URL and manually click through the app's core flows (view board, add a card, refresh — confirm the card persisted, proving the production database connection works).

## C.6 Custom Domain (Optional)

1. **Project -> Settings -> Domains -> Add**.
2. Enter your domain (e.g., `devboard.app`).
3. Vercel shows the DNS records to add (an `A` record or `CNAME`, depending on setup) — add these at your domain registrar.
4. This is Part 1.2's DNS resolution in direct practice: you're now the one configuring the phonebook entry.

## C.7 Ongoing Workflow (Every Future Change)

- [ ] Create a feature branch: `git checkout -b feature/x`.
- [ ] Make changes, commit, `git push -u origin feature/x`.
- [ ] Vercel automatically builds a **Preview Deployment** for that branch/PR with its own unique URL — test there before merging.
- [ ] Open a Pull Request on GitHub, review the diff, merge into `main`.
- [ ] Vercel automatically builds and promotes a new **Production Deployment** from `main`.

## C.8 Troubleshooting Quick Reference

| Symptom | Likely cause | Where to check |
|---|---|---|
| Build fails on Vercel but works locally | Env var missing in Vercel, or Node version mismatch | Vercel build logs; `engines` field in `package.json` |
| App loads but data is empty/broken | `DATABASE_URL` not set for the right environment (Production vs Preview) | Settings -> Environment Variables, check environment scoping |
| `500 Internal Server Error` in production only | Unhandled exception hitting a resource unavailable in prod (e.g., DB unreachable) | Project -> Deployments -> select deployment -> Functions/Logs tab |
| Changes not appearing after push | Pushed to a branch, not `main`; or browser cache | Confirm which deployment URL you're viewing — preview vs. production have different URLs |
| Env var change not taking effect | Environment variables require a **redeploy** to apply — editing them doesn't affect already-built deployments | Settings -> Environment Variables -> then trigger "Redeploy" |
