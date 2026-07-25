# Primer 8: Deployment Environments, Configuration, and Production Readiness

GreyMatter Feedback runs across several services:

```text
Next.js application
Neon PostgreSQL
Inngest
Upstash Redis
S3-compatible storage
Custom domain
```

During development, many values point to local or test resources. In production, they point to real infrastructure used by participants and administrators.

This primer explains how to think about environments, configuration, and safe deployment.

---

## 1. What Is an Environment?

An environment is a separate version of an application and its supporting services.

Most serious applications use at least three:

```text
Development
Staging
Production
```

### Development

Used by developers while building features.

```text
Application URL:
http://localhost:3000

Database:
Neon development branch

Inngest:
Local Dev Server

Reports:
Local public/reports directory
```

### Staging

Used to test the deployed application before real users access it.

```text
Application URL:
https://staging-feedback.example.com

Database:
Neon staging branch

Inngest:
Staging Inngest environment

Reports:
Staging object storage bucket or prefix
```

### Production

Used by real participants and administrators.

```text
Application URL:
https://feedback.example.com

Database:
Neon production branch

Inngest:
Production Inngest environment

Reports:
Private production object storage
```

The key rule is:

> Development and staging must not accidentally write to production data.

---

## 2. Why Separate Environments Matter

Imagine testing a new form-authoring feature against the production database.

A bug could:

```text
Archive a live form version
Close a real feedback session
Delete responses
Generate reports from incorrect data
Rate-limit participants during a live event
```

Separate environments reduce that risk.

```text
Developer tests locally
        ↓
Feature deploys to staging
        ↓
Staging checks pass
        ↓
Production deployment occurs
```

This process is slower than changing production directly, but much safer.

---

## 3. Environment Variables

Environment variables provide configuration without placing private values in source code.

GreyMatter Feedback uses variables such as:

```dotenv
DATABASE_URL="..."
DIRECT_URL="..."
ADMIN_SESSION_SECRET="..."
INNGEST_EVENT_KEY="..."
UPSTASH_REDIS_REST_TOKEN="..."
```

The same code can run in different environments because each environment supplies different values.

For example:

```text
Development:
NEXT_PUBLIC_APP_URL=http://localhost:3000

Production:
NEXT_PUBLIC_APP_URL=https://feedback.example.com
```

The code stays the same:

```ts
const participantUrl = `${process.env.NEXT_PUBLIC_APP_URL}/e/${sessionId}?src=qr`;
```

Only the configuration changes.

---

## 4. Public vs Private Environment Variables

Variables beginning with:

```text
NEXT_PUBLIC_
```

are available to browser JavaScript.

GreyMatter Feedback uses:

```dotenv
NEXT_PUBLIC_APP_URL="https://feedback.example.com"
```

This is safe because participants already need to know the public application URL.

Private values must not use this prefix.

Unsafe:

```dotenv
NEXT_PUBLIC_DATABASE_URL="postgresql://..."
NEXT_PUBLIC_ADMIN_PASSWORD="..."
NEXT_PUBLIC_S3_SECRET_ACCESS_KEY="..."
```

Safe:

```dotenv
DATABASE_URL="postgresql://..."
ADMIN_PASSWORD="..."
S3_SECRET_ACCESS_KEY="..."
```

A useful rule:

```text
If a participant browser must not see it,
do not prefix it with NEXT_PUBLIC_.
```

---

## 5. Required Production Configuration

A typical production environment needs these variables.

```dotenv
DATABASE_URL="your-neon-pooled-production-url"
DIRECT_URL="your-neon-direct-production-url"

IP_HASH_SECRET="long-random-production-secret"
ADMIN_SESSION_SECRET="different-long-random-production-secret"
ADMIN_PASSWORD="strong-production-password"

NEXT_PUBLIC_APP_URL="https://feedback.your-domain.example"

INNGEST_EVENT_KEY="production-event-key"
INNGEST_SIGNING_KEY="production-signing-key"
INNGEST_DEV="0"

UPSTASH_REDIS_REST_URL="https://..."
UPSTASH_REDIS_REST_TOKEN="..."

S3_REGION="..."
S3_BUCKET="..."
S3_ACCESS_KEY_ID="..."
S3_SECRET_ACCESS_KEY="..."
S3_ENDPOINT="https://..."
```

Each value has a purpose.

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Application connection to Neon through pooler |
| `DIRECT_URL` | Direct database connection for Prisma migrations |
| `IP_HASH_SECRET` | Privacy-aware daily IP hashing |
| `ADMIN_SESSION_SECRET` | Signing admin session tokens |
| `ADMIN_PASSWORD` | Baseline admin sign-in secret |
| `NEXT_PUBLIC_APP_URL` | QR-code base URL |
| `INNGEST_EVENT_KEY` | Sending production events |
| `INNGEST_SIGNING_KEY` | Verifying Inngest requests |
| `UPSTASH_REDIS_REST_URL` | Distributed rate limiting |
| `UPSTASH_REDIS_REST_TOKEN` | Upstash authorization |
| S3 variables | PDF report storage |

---

## 6. The `.env.example` File

The project should commit:

```text
.env.example
```

but never commit:

```text
.env
.env.local
```

The example file documents required variable names without real secrets.

### `.env.example`

```dotenv
DATABASE_URL=""
DIRECT_URL=""

IP_HASH_SECRET=""
ADMIN_SESSION_SECRET=""
ADMIN_PASSWORD=""

NEXT_PUBLIC_APP_URL="http://localhost:3000"

INNGEST_EVENT_KEY=""
INNGEST_SIGNING_KEY=""
INNGEST_DEV="1"

UPSTASH_REDIS_REST_URL=""
UPSTASH_REDIS_REST_TOKEN=""

S3_REGION=""
S3_BUCKET=""
S3_ACCESS_KEY_ID=""
S3_SECRET_ACCESS_KEY=""
S3_ENDPOINT=""
```

A new developer can copy it:

```bash
cp .env.example .env
```

Then add their own safe development values.

---

## 7. Database Deployment Workflow

Database changes and application code should be deployed carefully.

A safe sequence is:

```text
Update Prisma schema
        ↓
Create migration locally
        ↓
Commit migration files
        ↓
Test on Neon staging branch
        ↓
Apply migration to production
        ↓
Deploy compatible application code
        ↓
Run production smoke test
```

Development command:

```bash
npx prisma migrate dev --name add_feature_name
```

Production command:

```bash
npx prisma migrate deploy
```

Do not run:

```bash
npx prisma migrate reset
```

against production. It deletes data.

---

## 8. Why Deployment Order Matters

Imagine application code expects a new database column:

```text
questions.helper_text
```

But the production database has not been migrated yet.

```text
New application code deploys
        ↓
Application queries missing column
        ↓
Runtime error
```

For additive changes, a safer order is:

```text
1. Add nullable database column.
2. Deploy code that can handle null.
3. Backfill values if needed.
4. Later make field required, if appropriate.
```

This is called an **expand-and-contract** deployment strategy.

---

## 9. Deploying Next.js

Next.js works well on platforms such as:

```text
Vercel
Cloudflare Workers or Pages with compatible setup
AWS
Google Cloud
Render
Railway
Fly.io
Self-hosted Node.js infrastructure
```

For the tutorial architecture, Vercel is a straightforward choice because it supports Next.js directly.

Typical Vercel workflow:

```text
Push project to Git repository
        ↓
Import repository into Vercel
        ↓
Configure environment variables
        ↓
Deploy preview
        ↓
Test preview
        ↓
Promote to production
```

---

## 10. Production Build Checks

Before deployment, run:

```bash
npx prisma validate
```

```bash
npx prisma generate
```

```bash
npm test
```

```bash
npm run lint
```

```bash
npm run build
```

A successful production build matters because development mode can hide issues through hot reload and different rendering behavior.

---

## 11. Inngest Environment Configuration

In development, GreyMatter Feedback uses:

```dotenv
INNGEST_DEV="1"
```

and runs:

```bash
npm run inngest:dev
```

In production:

```dotenv
INNGEST_DEV="0"
```

The deployed application exposes:

```text
https://feedback.example.com/api/inngest
```

Inngest uses that endpoint to discover and run functions.

After deployment, confirm that Inngest shows:

```text
process-feedback-submission
generate-pdf-report
```

If a function is missing, verify:

```text
The deployment contains src/app/api/inngest/route.ts
The function is exported from src/inngest/functions/index.ts
The Inngest sync URL is correct
The deployed application is reachable through HTTPS
```

---

## 12. Production Rate Limiting

Development may use an in-memory rate-limit fallback.

Production must use shared storage because multiple application instances can run simultaneously.

```text
Participant request reaches server instance A
Participant retry reaches server instance B
```

Without shared state, each instance may think the request is the first submission.

Upstash Redis provides shared state:

```text
Server instance A
        ↓
Upstash Redis

Server instance B
        ↓
Upstash Redis
```

This lets GreyMatter Feedback enforce one consistent rate limit across the deployed application.

---

## 13. Production PDF Storage

Local filesystem storage is convenient in development:

```text
public/reports
```

In a serverless production environment, local files are often temporary.

A report may appear to work briefly, then disappear after:

```text
Function restart
Deployment
Scaling event
New server instance
```

Production reports should use S3-compatible object storage.

```text
Inngest worker
        ↓
Generate PDF buffer
        ↓
Upload to S3-compatible storage
        ↓
Store report URL or object key in Neon
```

For sensitive reports, use private storage and authenticated downloads.

---

## 14. Custom Domains and QR Codes

QR codes must use the final public domain.

Example production URL:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

Before printing a QR code, test:

```text
[ ] Domain resolves correctly.
[ ] HTTPS certificate is valid.
[ ] Participant form loads from mobile data.
[ ] Participant form loads from venue Wi-Fi.
[ ] Correct session title appears.
[ ] Correct published form appears.
[ ] Submission succeeds.
```

Do not print QR codes that point to preview deployment URLs unless the preview is intentionally permanent.

Preview URLs can change or expire.

---

## 15. Health Checks and Smoke Tests

A **smoke test** is a small practical check after deployment.

For GreyMatter Feedback, a production smoke test should include:

```text
1. Open home page.
2. Sign in as administrator.
3. Open existing event.
4. Open a participant session URL.
5. Submit one test response.
6. Confirm Inngest run succeeds.
7. Confirm dashboard count increases.
8. Export CSV.
9. Request PDF report.
10. Download completed PDF.
```

If any step fails, investigate before sharing QR codes widely.

---

## 16. Deployment Rollback

A rollback restores a previous working application deployment.

Example scenario:

```text
New application version deployed
        ↓
Participant page begins returning errors
        ↓
Rollback to previous deployment
        ↓
Participant page works again
```

A code rollback does not necessarily reverse database migrations.

That is why migrations should be:

```text
Carefully reviewed
Backward compatible where possible
Tested in staging
Applied separately from risky code changes when needed
```

For database issues, prefer a corrective forward migration unless data integrity requires recovery.

---

## 17. Production Release Checklist

Before release:

```text
[ ] Code review complete.
[ ] Unit tests pass.
[ ] Lint passes.
[ ] Production build passes.
[ ] Prisma schema validates.
[ ] Migration tested on Neon staging branch.
[ ] Environment variables configured.
[ ] Inngest production sync URL configured.
[ ] Upstash Redis configured.
[ ] S3-compatible storage configured.
[ ] Custom domain configured.
[ ] Error monitoring configured.
[ ] Rollback owner identified.
```

After release:

```text
[ ] Landing page loads.
[ ] Admin sign-in works.
[ ] Participant form loads.
[ ] Test response is accepted.
[ ] Inngest worker processes response.
[ ] Dashboard updates.
[ ] CSV export works.
[ ] PDF generation works.
[ ] Report download is protected.
[ ] Logs show no unexpected errors.
```

---

## 18. Primer Summary

A safe GreyMatter Feedback deployment follows this model:

```text
Development
        ↓
Staging
        ↓
Production
```

Each environment has its own:

```text
Database connection
Secrets
Inngest configuration
Rate-limit storage
Report storage
Application URL
```

The key production principles are:

```text
Never commit secrets.
Use separate environments.
Use Neon pooled connections at runtime.
Use Prisma migration deployment carefully.
Use Upstash Redis for production rate limits.
Use S3-compatible storage for production reports.
Test the complete participant-to-report workflow after every major deployment.
Print QR codes only after final production URLs are verified.
```

A successful deployment is not just a green build. It is a verified system where participants can scan, submit, and receive confirmation while administrators can reliably author, analyze, export, and report.
