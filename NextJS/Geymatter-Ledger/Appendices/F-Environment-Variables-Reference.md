# Appendix F — Environment Variables Reference

This appendix documents the environment variables used by **GreyMatter Ledger**.

Environment variables are configuration values that live outside your source code.

They are used for:

```txt
Database credentials
Authentication keys
Background job secrets
Redirect URLs
Deployment-specific settings
```

A key rule:

```txt
Secrets must never be committed to Git.
```

---

# 1. Files Used for Environment Variables

In local development, use:

```txt
.env.local
```

This file contains real local secrets.

It should be ignored by Git.

For documentation, use:

```txt
.env.example
```

This file contains placeholder values.

It is safe to commit.

---

## `.env.local`

Example:

```bash
DATABASE_URL="postgresql://real_user:real_password@real_host/real_database?sslmode=require"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_real_value"
CLERK_SECRET_KEY="sk_test_real_value"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"

INNGEST_EVENT_KEY="real_inngest_event_key"
INNGEST_SIGNING_KEY="real_inngest_signing_key"
```

Do not commit this.

---

## `.env.example`

Example:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_replace_with_your_clerk_publishable_key"
CLERK_SECRET_KEY="sk_test_replace_with_your_clerk_secret_key"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"

INNGEST_EVENT_KEY="replace_with_inngest_event_key"
INNGEST_SIGNING_KEY="replace_with_inngest_signing_key"
```

This file is safe to commit because it contains placeholders.

---

# 2. Git Ignore Checklist

Make sure `.gitignore` includes:

```gitignore
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
```

Also make sure Git has not already staged `.env.local`.

Check:

```bash
git status --short
```

If `.env.local` appears, unstage it:

```bash
git restore --staged .env.local
```

If `.env.local` was ever committed, rotate the secrets immediately.

---

# 3. Public vs Secret Variables

Next.js exposes variables beginning with:

```txt
NEXT_PUBLIC_
```

to browser code.

That means they are not secrets.

Variables without `NEXT_PUBLIC_` are server-side only.

---

## Public Variables

These may be visible in browser bundles:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
NEXT_PUBLIC_CLERK_SIGN_IN_URL
NEXT_PUBLIC_CLERK_SIGN_UP_URL
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL
NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL
```

Public does **not** mean unimportant.

It means safe to expose.

---

## Secret Variables

These must stay private:

```bash
DATABASE_URL
CLERK_SECRET_KEY
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

Do not expose these to the browser.

Do not prefix them with:

```txt
NEXT_PUBLIC_
```

---

# 4. Database Variables

## `DATABASE_URL`

Required:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"
```

Used by:

```txt
Drizzle ORM
Drizzle Kit migrations
Application database client
Server-rendered database pages
```

Example shape:

```txt
postgresql://neondb_owner:password@ep-example.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
```

---

## Important Notes

The URL includes sensitive information:

```txt
username
password
host
database name
```

Treat it as a secret.

---

## SSL

For Neon, the URL should usually include:

```txt
sslmode=require
```

If missing, you may see connection or SSL errors.

---

## Special Characters in Passwords

If your password contains characters like:

```txt
@
:
/
?
#
&
```

they may need URL encoding.

Examples:

```txt
@ = %40
# = %23
& = %26
```

The safest option is to copy the full connection string from Neon.

---

# 5. Clerk Variables

Clerk handles:

```txt
Authentication
User sessions
Organizations
Organization roles
```

---

## `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`

Required.

Example:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
```

This is public and used by Clerk client-side components.

---

## `CLERK_SECRET_KEY`

Required.

Example:

```bash
CLERK_SECRET_KEY="sk_test_..."
```

This is secret.

It is used by server-side Clerk helpers.

Never expose this to the browser.

---

## Clerk URL Variables

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"
```

Purpose:

```txt
Tell Clerk where sign-in and sign-up pages live.
Tell Clerk where users should go after auth.
```

---

## Clerk Organization Variables

```bash
NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Purpose:

```txt
Redirect users after creating/selecting organizations.
```

---

# 6. Inngest Variables

Inngest handles background jobs.

Used for:

```txt
Invoice created events
Overdue invoice reminder schedules
Recurring invoice scheduler stub
Background health checks
```

---

## `INNGEST_EVENT_KEY`

Secret.

Used for sending events securely in production.

Example:

```bash
INNGEST_EVENT_KEY="..."
```

---

## `INNGEST_SIGNING_KEY`

Secret.

Used to verify requests from Inngest.

Example:

```bash
INNGEST_SIGNING_KEY="..."
```

---

## Local Development

For local development, you can use the Inngest dev server:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

The endpoint is:

```txt
/api/inngest
```

---

# 7. Where Variables Are Used

## `DATABASE_URL`

Used in:

```txt
db/index.ts
drizzle.config.ts
database-backed Server Components
database-backed services
```

---

## Clerk Variables

Used in:

```txt
app/layout.tsx
app/sign-in/[[...sign-in]]/page.tsx
app/sign-up/[[...sign-up]]/page.tsx
proxy.ts
lib/auth.ts
lib/authorization.ts
```

---

## Inngest Variables

Used in:

```txt
inngest/client.ts
app/api/inngest/route.ts
server actions that send events
Inngest production runtime
```

---

# 8. Local Development Setup

A typical local setup requires:

```bash
DATABASE_URL="postgresql://..."

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"
```

Inngest variables can be added when testing production-like background jobs.

---

# 9. Vercel Production Setup

In Vercel:

```txt
Project Settings
  -> Environment Variables
```

Add all required variables.

Recommended environments:

```txt
Production
Preview
Development
```

At minimum, add required variables to Production.

---

## Production Variables Checklist

```txt
DATABASE_URL
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
CLERK_SECRET_KEY
NEXT_PUBLIC_CLERK_SIGN_IN_URL
NEXT_PUBLIC_CLERK_SIGN_UP_URL
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL
NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

After changing Vercel env vars, redeploy.

---

# 10. Drizzle CLI Environment Loading

Next.js automatically loads `.env.local`.

Drizzle Kit does not automatically do that unless configured.

GreyMatter Ledger loads `.env.local` in:

```txt
drizzle.config.ts
```

Using:

```ts
config({ path: ".env.local" });
```

That lets commands work locally:

```bash
pnpm db:generate
pnpm db:migrate
pnpm db:studio
```

---

# 11. Environment Variable Troubleshooting

## Error: `DATABASE_URL is missing`

Fix:

1. Add `DATABASE_URL` to `.env.local`.
2. Restart the dev server.
3. Re-run the command.

```bash
pnpm dev
```

or:

```bash
pnpm db:migrate
```

---

## Error: Clerk publishable key missing

Fix:

Check `.env.local`:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
```

Restart dev server.

---

## Error: Clerk secret key missing

Fix:

Check `.env.local`:

```bash
CLERK_SECRET_KEY="sk_test_..."
```

Do not use `NEXT_PUBLIC_` for this value.

---

## Error: Vercel build fails

Common cause:

```txt
Vercel environment variables are missing.
```

Fix:

Add required variables in Vercel Project Settings.

Redeploy.

---

## Error: Drizzle migration cannot connect

Check:

```txt
DATABASE_URL
```

Make sure it points to the intended Neon database.

Make sure it includes:

```txt
sslmode=require
```

---

## Error: Inngest event does not appear

Check:

```txt
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
/api/inngest endpoint
```

For local testing, run:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

# 12. Secret Rotation Checklist

Rotate secrets if:

```txt
.env.local was committed
a screenshot exposed secrets
a terminal recording exposed secrets
a teammate leaves and had access
a production incident occurs
```

Rotate:

```txt
DATABASE_URL password
CLERK_SECRET_KEY
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

After rotation:

1. Update local `.env.local`.
2. Update Vercel environment variables.
3. Redeploy.
4. Confirm production works.

---

# 13. Recommended `.env.example`

A complete example:

```bash
DATABASE_URL="postgresql://user:password@host/database?sslmode=require"

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_replace_with_your_clerk_publishable_key"
CLERK_SECRET_KEY="sk_test_replace_with_your_clerk_secret_key"

NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"
NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL="/dashboard"
NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL="/dashboard"

NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL="/dashboard"
NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL="/dashboard"

INNGEST_EVENT_KEY="replace_with_inngest_event_key"
INNGEST_SIGNING_KEY="replace_with_inngest_signing_key"
```

---

# 14. Final Environment Checklist

Before running locally:

```txt
.env.local exists
DATABASE_URL is present
Clerk publishable key is present
Clerk secret key is present
Clerk URLs are present
DATABASE_URL points to a migrated Neon database
```

Before deploying:

```txt
Vercel env vars configured
Clerk production URLs configured
Neon production database migrated
Inngest production endpoint configured
Secrets not committed
```

The most important security rule:

```txt
Never commit real secrets.
```
