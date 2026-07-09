# Appendix C: Environment Variables Reference

Every environment variable used across this series, what it does, where to get it, and where it's set.

## Complete .env.local

```bash
# File: .env.local

# Sanity — from Part 5 / Part 7
NEXT_PUBLIC_SANITY_PROJECT_ID=your_project_id
NEXT_PUBLIC_SANITY_DATASET=production
NEXT_PUBLIC_SANITY_API_VERSION=2024-06-01

# Web3Forms — from Part 12
NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY=your_web3forms_access_key

# Revalidation webhook — from Part 15
SANITY_REVALIDATE_SECRET=your_generated_secret

# Site URL — from Part 14 (used for absolute URLs in metadata/sitemap)
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

## Variable-by-Variable Reference

### `NEXT_PUBLIC_SANITY_PROJECT_ID`
- **Introduced in**: Part 5
- **Where to find it**: printed after running `npm create sanity@latest` in Part 4, or at https://www.sanity.io/manage under your project name
- **Purpose**: identifies which Sanity project the client connects to
- **Public?** Yes — Sanity project IDs are not secret; they're required client-side to construct the CDN API URL

### `NEXT_PUBLIC_SANITY_DATASET`
- **Introduced in**: Part 5
- **Value used in this series**: `production`
- **Purpose**: which dataset within the project to query
- **Public?** Yes

### `NEXT_PUBLIC_SANITY_API_VERSION`
- **Introduced in**: Part 5
- **Value used in this series**: `2024-06-01` (or later — any valid, dated API version works; using a fixed date avoids unannounced breaking changes)
- **Purpose**: pins which version of Sanity's Content API your queries target
- **Public?** Yes

### `NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY`
- **Introduced in**: Part 12
- **Where to find it**: sign up free at https://web3forms.com, confirm your email, copy the key from the confirmation email/dashboard
- **Purpose**: authorizes form submissions to be emailed to your registered address
- **Public?** Yes — Web3Forms access keys are designed to be used directly in client-side JavaScript

### `SANITY_REVALIDATE_SECRET`
- **Introduced in**: Part 15
- **How to generate**: `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`
- **Purpose**: verifies incoming webhook requests to `/api/revalidate` genuinely came from Sanity (via HMAC signature verification, handled by `next-sanity/webhook`'s `parseBody`)
- **Public?** **No** — do NOT prefix with `NEXT_PUBLIC_`. Must remain server-only. Also entered into Sanity's webhook "Secret" field so both sides can verify the signature.

### `NEXT_PUBLIC_SITE_URL`
- **Introduced in**: Part 14
- **Local value**: `http://localhost:3000`
- **Production value**: your real Vercel URL (or custom domain), set in Part 16 after first deployment
- **Purpose**: used as `metadataBase` for resolving absolute Open Graph/Twitter image URLs, and as the base for `sitemap.xml`/`robots.txt` URLs
- **Public?** Yes

## Where Each Variable Must Be Set

| Environment | File / Location |
|---|---|
| Local development | `.env.local` (gitignored automatically by `create-next-app`) |
| Vercel production | Project → Settings → Environment Variables (set in Part 16, Step 4) |

## Common Mistakes

- **Forgetting to restart `npm run dev`** after editing `.env.local` — Next.js only reads env files at server startup, not on hot reload.
- **Forgetting to redeploy on Vercel** after adding/changing an environment variable — env var changes don't apply to already-built deployments; you must trigger a new deployment (Part 16, Step 6).
- **Prefixing a secret with `NEXT_PUBLIC_`** — this exposes it to the browser bundle. Only `SANITY_REVALIDATE_SECRET` in this series must NOT have that prefix; everything else is intentionally public.
- **Committing `.env.local` to Git** — verify your `.gitignore` includes `.env*.local` (it does by default from `create-next-app`; double check with `git status` before your first commit if unsure).
