## Part 10: Production Deployment

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Link GitHub to Vercel, manage environment variables across environments, set up automated preview deployments, and wire the production webhooks/keys for all four services.

---

### 1. Concept Explanation

Deploying a four-service app is mostly about **environment parity and secret management**, not code changes — nothing built in Parts 1–9 needs to change for production, because every service client was built once (Part 1's `lib/` principle) and every config value was read from `process.env`. Production deployment is where that discipline pays off.

**Two deployment concerns are distinct and both matter:**
1. **Build-time vs runtime envs on Vercel** — `NEXT_PUBLIC_*` vars are inlined at build time; everything else is read at runtime inside serverless functions. Vercel lets you scope every variable to Production / Preview / Development independently — we use this to point Preview deployments at a separate Neon branch/Sanity dataset where useful, while keeping Production stable.
2. **Webhook re-registration** — the Sanity webhook (Part 7) and the Inngest app registration (Part 6) both reference URLs. Once deployed, these must point at the real production domain, not `localhost`.

---

### 2. Implementation

#### 2.1 Push to GitHub

```bash
git init
git add .
git commit -m "Orbit: initial commit through Part 9"
git branch -M main
git remote add origin https://github.com/your-username/orbit.git
git push -u origin main
```

Confirm `.gitignore` excludes `.env.local`, `node_modules`, `.next`, and `sanity/dist` (or Sanity's build output dir, if generated).

#### 2.2 Import into Vercel

1. In the Vercel dashboard: **Add New → Project → Import Git Repository**, select `orbit`.
2. Framework preset should auto-detect **Next.js**. Leave build command (`next build`) and output settings as default.
3. Do **not** click Deploy yet — first configure environment variables (2.3).

#### 2.3 Environment variables in Vercel

Under **Project Settings → Environment Variables**, add every key from Appendix A's `.env` template, scoped appropriately:

| Variable | Production | Preview | Development |
|---|---|---|---|
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` | prod key | prod or test key | test key |
| `CLERK_SECRET_KEY` | prod secret | prod or test secret | test secret |
| `NEXT_PUBLIC_CLERK_SIGN_IN_URL` | `/sign-in` | same | same |
| `NEXT_PUBLIC_CLERK_SIGN_UP_URL` | `/sign-up` | same | same |
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | same across all | same | same |
| `NEXT_PUBLIC_SANITY_DATASET` | `production` | `production` (or a `staging` dataset) | `production` |
| `SANITY_API_TOKEN` | prod token | prod token | prod token |
| `SANITY_WEBHOOK_SECRET` | prod secret | prod secret | prod secret |
| `DATABASE_URL` | Neon prod branch (pooled) | Neon **preview branch** (pooled) | local dev connection |
| `DIRECT_URL` | Neon prod branch (direct) | Neon preview branch (direct) | local dev connection |
| `INNGEST_EVENT_KEY` | prod key | prod key | (unused locally) |
| `INNGEST_SIGNING_KEY` | prod key | prod key | (unused locally) |

> **Neon branching tip:** Neon supports instant database branching on the free tier. Create a `preview` branch off `main` and point Vercel's *Preview* environment variables at its connection strings — every PR then gets an isolated database copy, with zero risk of a preview deployment corrupting production data. This is one of Neon's best free-tier features and worth calling out explicitly.

#### 2.4 First deploy

Click **Deploy**. Vercel builds with Turbopack (per Part 9) and assigns a `*.vercel.app` domain.

#### 2.5 Re-register the Inngest app for production

In the Inngest dashboard, add a new "app" pointing at:

```
https://your-domain.vercel.app/api/inngest
```

Inngest auto-detects the registered functions (Part 6's `handleProjectRequested` and `weeklyDigest`) via the `serve()` handler. Confirm both appear in the dashboard's Functions list after the first deploy.

#### 2.6 Re-register the Sanity webhook for production

In the Sanity dashboard → API → Webhooks, update (or add a new) webhook URL to:

```
https://your-domain.vercel.app/api/sanity/revalidate
```

Keep the same `SANITY_WEBHOOK_SECRET` used in Vercel's env vars, filtered on `servicePackage` and `article` document types, on Create/Update/Delete.

#### 2.7 Update Clerk's allowed origins

In the Clerk dashboard → Domains, add your production Vercel domain (and any custom domain) to the allowed list, otherwise `ClerkProvider` will reject requests from an unrecognized origin.

#### 2.8 Run production migrations

```json
{
  "scripts": {
    "build": "prisma migrate deploy && next build"
  }
}
```

`prisma migrate deploy` (not `migrate dev`) is the production-safe command — it applies pending migrations without generating new ones or prompting interactively.

#### 2.9 Preview deployments

Every PR against `main` now automatically gets its own preview deployment with its own URL and (if configured per 2.3) its own Neon branch.

```bash
git checkout -b test-preview-deploy
echo "<!-- test -->" >> README.md
git add README.md
git commit -m "test preview deployment"
git push -u origin test-preview-deploy
```

Open a PR on GitHub; watch the Vercel bot comment appear with the preview link within roughly a minute.

#### 2.10 Post-deploy smoke test

Walk through the full cross-service flow against the live production URL:

1. Sign up as a new user.
2. Promote to `ADMIN` via Clerk dashboard.
3. Open `/studio`, confirm it loads (and only it loads the Studio bundle, per Part 9).
4. Create/verify a `servicePackage` document.
5. Sign in as a second (or the same, demoted-to-CLIENT) test user, request a project.
6. Confirm in the Inngest dashboard that `project/requested` fired and the function ran successfully in production.
7. Confirm in Neon (via `prisma studio` pointed at the prod `DATABASE_URL`, or the Neon SQL editor) that the `Project` and `Task` rows exist.
8. Edit the `servicePackage` in the Studio, publish, and confirm the Sanity webhook fires (check Sanity's webhook "Attempts" log) and the marketing page updates without a redeploy.

---

### 3. Checkpoint

- ✅ Production deployment live at a `*.vercel.app` URL (or custom domain).
- ✅ All environment variables correctly scoped per Production/Preview/Development.
- ✅ Inngest dashboard shows the production app registered with both functions.
- ✅ Sanity webhook attempts log shows successful `200` responses hitting the production URL.
- ✅ A test PR triggers an automatic, isolated preview deployment.
- ✅ Full smoke test (2.10) passes end-to-end against production.

---

### 4. Troubleshooting

- **Build fails with "Environment variable not found: DATABASE_URL"** — the variable exists in Vercel but wasn't scoped to the environment being built (Production vs Preview); re-check the scoping checkboxes when adding each var.
- **Clerk works in dev but throws a CORS-like origin error in production** — the production domain wasn't added under Clerk's allowed Domains list (2.7).
- **Inngest functions show as registered but never actually run in production** — confirm `INNGEST_SIGNING_KEY` is set in Vercel; without it, Inngest can't authenticate its calls into your deployed `/api/inngest` endpoint and requests are silently rejected.
- **Prisma migrations "already applied" errors on redeploy** — this is expected/safe; `migrate deploy` is idempotent and skips already-applied migrations. If you see genuine drift errors, check nobody ran `migrate dev` directly against the production database out of band.
- **Preview deployments corrupt shared production data** — you forgot the Neon preview-branch env var scoping in 2.3; go back and set `DATABASE_URL`/`DIRECT_URL` for the *Preview* environment specifically to the Neon preview branch, not production.

---

**Series complete.** See the companion note **"Ecosystem Tutorial - Appendices"** for the full project file tree, `.env` template, the Free & Open-Source Service Matrix, and the condensed Deployment Checklist.

---

That's all 10 parts! Want to wrap up with the **Appendices** (file tree, `.env` template, service matrix, deployment checklist) next?
