# Appendix C: Local Development, Debugging, and Common Problems

This appendix is a practical troubleshooting guide for GreyMatter Feedback.

It covers the local services that work together:

```text
Next.js application
        ↓
Neon PostgreSQL
        ↓
Inngest Dev Server
        ↓
Optional Upstash Redis
```

Use this appendix when a command fails, a page does not load, a feedback submission remains pending, or a report does not generate.

---

## C.1 Local services checklist

During full local development, these services should be available.

| Service | Purpose | Typical local URL or command |
|---|---|---|
| Next.js | Application pages and API routes | `http://localhost:3000` |
| Inngest Dev Server | Background jobs and event dashboard | `http://localhost:8288` |
| Neon | Hosted PostgreSQL database | Configured through `.env` |
| Prisma Studio | Optional database browser | `http://localhost:5555` |

Start Next.js:

```bash
npm run dev
```

Start Inngest in a second terminal:

```bash
npm run inngest:dev
```

Optionally open Prisma Studio in a third terminal:

```bash
npx prisma studio
```

---

## C.2 Recommended terminal layout

A useful development setup has three terminal windows or tabs.

### Terminal 1 — Next.js

```bash
npm run dev
```

Expected output resembles:

```text
▲ Next.js
- Local: http://localhost:3000
```

### Terminal 2 — Inngest

```bash
npm run inngest:dev
```

Expected output resembles:

```text
Inngest Dev Server running at http://localhost:8288
```

### Terminal 3 — Prisma Studio, when needed

```bash
npx prisma studio
```

Expected output resembles:

```text
Prisma Studio is running on http://localhost:5555
```

Do not leave Prisma Studio running if you no longer need it. It uses an additional database connection.

---

## C.3 Environment variable checklist

GreyMatter Feedback requires a private `.env` file.

A minimum local development configuration looks like this:

### `.env`

```dotenv
DATABASE_URL="postgresql://your-pooled-neon-url?sslmode=require"
DIRECT_URL="postgresql://your-direct-neon-url?sslmode=require"

IP_HASH_SECRET="a-long-random-secret-with-at-least-32-characters"
ADMIN_SESSION_SECRET="a-different-long-random-secret-with-at-least-32-characters"
ADMIN_PASSWORD="a-local-password-with-at-least-12-characters"

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

After changing `.env`, restart:

```bash
npm run dev
```

and:

```bash
npm run inngest:dev
```

Next.js does not reliably apply new server environment values to an already running process.

---

## C.4 Neon connection failures

### Symptom

Commands such as these fail:

```bash
npm run db:test
```

```bash
npx prisma migrate dev
```

```bash
npx prisma studio
```

Possible errors include:

```text
Can't reach database server
```

```text
Authentication failed
```

```text
Error validating datasource
```

### Checks

Confirm both URLs exist in `.env`:

```dotenv
DATABASE_URL="..."
DIRECT_URL="..."
```

Confirm both include:

```text
?sslmode=require
```

Confirm URL responsibilities:

| Variable | Expected Neon URL |
|---|---|
| `DATABASE_URL` | Pooled URL, generally contains `-pooler` |
| `DIRECT_URL` | Direct URL, generally does not contain `-pooler` |

Test the connection:

```bash
npm run db:test
```

Validate the Prisma schema:

```bash
npx prisma validate
```

### Common fix

Open the Neon dashboard, click **Connect**, and copy fresh connection strings.

Passwords may be URL-encoded. Copy the entire URL exactly rather than manually rebuilding it.

---

## C.5 Prisma migration problems

### Symptom

This command fails:

```bash
npx prisma migrate dev --name your_migration_name
```

### Important rule

Use this locally:

```bash
npx prisma migrate dev
```

Use this in production:

```bash
npx prisma migrate deploy
```

Do not use `migrate dev` against production.

### Check migration status

```bash
npx prisma migrate status
```

### Regenerate Prisma client

After schema changes, run:

```bash
npx prisma generate
```

### Reset only a disposable development database

If you are using a dedicated Neon development branch and want to remove all test data:

```bash
npx prisma migrate reset
```

This command deletes data. Never use it against a production branch.

A safer Neon workflow is:

```text
Create Neon development branch
        ↓
Use development branch DATABASE_URL
        ↓
Test migration
        ↓
Apply migration to production through controlled deployment
```

---

## C.6 Inngest does not show functions

### Symptom

You open:

```text
http://localhost:8288
```

but do not see:

```text
process-feedback-submission
generate-pdf-report
```

### Checks

1. Confirm Next.js is running:

   ```bash
   npm run dev
   ```

2. Open the function endpoint directly:

   ```text
   http://localhost:3000/api/inngest
   ```

3. Confirm the endpoint file exists:

   ```text
   src/app/api/inngest/route.ts
   ```

4. Confirm function exports exist:

   ```text
   src/inngest/functions/index.ts
   ```

5. Confirm `INNGEST_DEV` is set:

   ```dotenv
   INNGEST_DEV="1"
   ```

6. Restart Next.js and the Inngest Dev Server.

### Correct local command

```bash
npm run inngest:dev
```

The configured command should use the Next.js endpoint:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

---

## C.7 Participant submission does not reach Neon

### Symptom

The participant sees an error after submission, or sees success but no new records appear in Prisma Studio.

### Debugging sequence

1. Confirm the participant form is using a currently published session:

   ```text
   /e/REACT-2026-Q3
   ```

2. Confirm the session is active in Prisma Studio:

   ```text
   Session.isActive = true
   ```

3. Confirm the active form is published:

   ```text
   FormVersion.status = PUBLISHED
   ```

4. Open browser developer tools.

5. Open the **Network** tab.

6. Submit the form.

7. Find the request:

   ```text
   POST /api/feedback
   ```

8. Check the response status.

| HTTP status | Meaning |
|---:|---|
| `202` | Submission accepted and queued |
| `400` | Request or answers failed validation |
| `404` | Session does not exist |
| `409` | Session closed, form changed, or form unavailable |
| `429` | Rate limit reached |
| `503` | Inngest or rate-limit service could not be reached |

9. Open the Inngest Dev Server:

   ```text
   http://localhost:8288
   ```

10. Check **Runs** for:

   ```text
   process-feedback-submission
   ```

11. Open the run and inspect the failed step, if any.

12. Open Prisma Studio:

   ```bash
   npx prisma studio
   ```

13. Inspect:

   ```text
   Response
   Answer
   ```

---

## C.8 Rate limit blocks local testing

### Symptom

The participant receives:

```text
Too many feedback submissions were received from this device.
```

### Why it happens

Without Upstash configured locally, GreyMatter Feedback uses an in-memory fallback.

Local requests often share this identity:

```text
unknown-client
```

The configured local rule is:

```text
One submission per session per client identity every five minutes
```

### Development reset

Restart the Next.js development server:

```bash
Ctrl+C
npm run dev
```

This resets the local in-memory limiter.

### Better local testing approach

Create multiple sessions:

```text
TEST-SESSION-1
TEST-SESSION-2
TEST-SESSION-3
```

The rate limit is scoped by session, so each session has an independent limit.

### Production recommendation

Use Upstash Redis in production:

```dotenv
UPSTASH_REDIS_REST_URL="https://..."
UPSTASH_REDIS_REST_TOKEN="..."
```

---

## C.9 An administrator cannot sign in

### Symptom

The login page always displays:

```text
The administrator password is incorrect.
```

### Checks

1. Confirm `.env` contains:

   ```dotenv
   ADMIN_PASSWORD="your-password"
   ```

2. Confirm it has at least 12 characters.

3. Restart the Next.js server after changing `.env`.

4. Confirm you are entering the exact value.

5. Use a private browser window to avoid an old session cookie affecting testing.

### Clear an old local cookie

In browser developer tools:

1. Open **Application**.
2. Open **Cookies**.
3. Select:

   ```text
   http://localhost:3000
   ```

4. Delete:

   ```text
   greymatter_admin_session
   ```

---

## C.10 A participant form displays “Feedback is not available”

### Symptom

A valid-looking QR URL displays:

```text
Feedback is not available
```

### Cause

The session may exist but does not have an active published form version.

### Checks in Prisma Studio

Open:

```bash
npx prisma studio
```

Inspect the `Session` record:

```text
activeFormVersionId is set
isActive is true
```

Inspect the linked `FormVersion` record:

```text
status = PUBLISHED
```

### Safe fix

Use the GreyMatter admin portal instead of manually editing database records:

```text
/admin/sessions/YOUR-SESSION-ID/edit
```

Then:

```text
Create draft form
→ Add questions
→ Publish version
```

---

## C.11 PDF report remains queued or processing

### Symptom

The admin dashboard shows:

```text
QUEUED
```

or:

```text
PROCESSING
```

for a long time.

### Checks

1. Confirm Inngest is running:

   ```bash
   npm run inngest:dev
   ```

2. Open:

   ```text
   http://localhost:8288
   ```

3. Open the run for:

   ```text
   generate-pdf-report
   ```

4. Check the failed or pending step.

5. Check the Next.js terminal for server errors.

6. Confirm the local report directory exists:

   ```bash
   mkdir -p public/reports
   ```

7. Confirm the current process can write to the project directory.

### Common local report URL

A completed local report should have a URL similar to:

```text
/reports/REACT-2026-Q3-<report-id>.pdf
```

The physical file should exist at:

```text
public/reports/REACT-2026-Q3-<report-id>.pdf
```

---

## C.12 PDF report generation fails in a serverless deployment

### Possible causes

- The runtime does not support the required PDF rendering environment.
- The function timeout is too short.
- Local filesystem writes are not persistent.
- S3-compatible storage credentials are missing.
- The object storage bucket is private but the application uses a public object URL.

### Production requirements

Use S3-compatible storage in production:

```dotenv
S3_REGION="..."
S3_BUCKET="..."
S3_ACCESS_KEY_ID="..."
S3_SECRET_ACCESS_KEY="..."
S3_ENDPOINT="..."
```

Do not rely on:

```text
public/reports
```

in serverless production. Most serverless filesystem storage is temporary and disappears after the request or deployment changes.

### Recommended production improvement

Use a protected report-download route:

```text
GET /api/admin/reports/[reportId]/download
```

That route should:

1. Confirm administrator authentication.
2. Confirm the report belongs to an existing session.
3. Create a short-lived signed S3 URL.
4. Redirect the administrator to it.

This keeps written participant feedback private.

---

## C.13 QR code does not scan

### Checks

1. Confirm the QR card displays a full public URL:

   ```text
   https://feedback.your-domain.example/e/SESSION-ID?src=qr
   ```

2. Do not use this in printed material:

   ```text
   http://localhost:3000
   ```

3. Confirm `NEXT_PUBLIC_APP_URL` has no trailing slash:

   ```dotenv
   NEXT_PUBLIC_APP_URL="https://feedback.your-domain.example"
   ```

4. Rebuild or redeploy after changing `NEXT_PUBLIC_APP_URL`.

5. Print or display QR codes at sufficient size.

Practical guidance:

| Context | Suggested minimum size |
|---|---:|
| Phone screen sharing | 250 × 250 pixels |
| Presentation slide | 350 × 350 pixels |
| Printed poster | 5 cm × 5 cm |
| Large room display | 8 cm × 8 cm or larger |

6. Use high contrast:

```text
Dark QR pattern
Light background
```

7. Avoid placing logos or complex patterns over the QR code unless you test scanning on several phones.

---

## C.14 Service worker appears to do nothing

### Why

GreyMatter Feedback intentionally does not register the service worker during development:

```ts
process.env.NODE_ENV === "development"
```

This avoids stale caches during active coding.

### Test it correctly

Build and run the production server:

```bash
npm run build
npm run start
```

Then open:

```text
http://localhost:3000
```

In browser developer tools:

```text
Application → Service Workers
```

You should see:

```text
/sw.js
```

### Remove a stale service worker

If testing changes to `public/sw.js`, unregister the old worker:

1. Open browser developer tools.
2. Open **Application**.
3. Open **Service Workers**.
4. Click **Unregister**.
5. Clear storage.
6. Refresh the page.

---

## C.15 TypeScript path alias errors

### Symptom

Imports such as this fail:

```ts
import { prisma } from "@/lib/prisma";
```

### Check `tsconfig.json`

The generated project should contain an alias configuration similar to:

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

After changing `tsconfig.json`, restart:

```bash
npm run dev
```

Also restart your editor’s TypeScript server if needed.

In Visual Studio Code:

```text
Command Palette
→ TypeScript: Restart TS Server
```

---

## C.16 Useful maintenance commands

### Validate Prisma schema

```bash
npx prisma validate
```

### Generate Prisma client

```bash
npx prisma generate
```

### Check migration status

```bash
npx prisma migrate status
```

### Open database browser

```bash
npx prisma studio
```

### Test Neon connectivity

```bash
npm run db:test
```

### Seed development data

```bash
npm run db:seed
```

### Run unit tests

```bash
npm test
```

### Run linting

```bash
npm run lint
```

### Create production build

```bash
npm run build
```

---

## C.17 Full troubleshooting checklist

When something fails, work from the outside inward.

```text
1. Is Next.js running?
2. Is the page route correct?
3. Is the environment configuration valid?
4. Can Prisma connect to Neon?
5. Is the database data correct?
6. Is the session active?
7. Is the active form version published?
8. Is the participant request returning 202?
9. Is Inngest running?
10. Did the Inngest function run successfully?
11. Did Neon receive Response and Answer records?
12. Did the dashboard refresh?
13. Is report storage configured correctly?
```

This order prevents random guessing and usually identifies the failed layer quickly.
