# Appendix P: Production Launch and Go-Live Checklist

This appendix provides a final checklist for launching GreyMatter Feedback in production.

Use it before:

- Launching the platform for the first time.
- Running a major conference.
- Opening a large course evaluation.
- Moving from a staging environment to production.
- Handing the system to event operations staff.

The purpose is simple:

> Confirm that the participant journey, administrator workflow, background jobs, database, reporting, and security controls are all ready before real feedback is collected.

---

## P.1 Production architecture checklist

The recommended production architecture is:

```text
Participants and administrators
        ↓
Next.js deployment platform
        ↓
Neon PostgreSQL
        ↓
Inngest production environment
        ↓
Upstash Redis rate limiting
        ↓
Private S3-compatible report storage
```

Confirm each service is configured.

| Service | Production responsibility | Confirmed |
|---|---|---:|
| Next.js host | Participant and admin application | ☐ |
| Neon | PostgreSQL database | ☐ |
| Prisma | Database migrations and typed access | ☐ |
| Inngest | Submission and report background jobs | ☐ |
| Upstash Redis | Distributed rate limiting | ☐ |
| S3-compatible storage | PDF report files | ☐ |
| Error monitoring | Production error visibility | ☐ |
| Domain and DNS | Public participant URLs | ☐ |

---

## P.2 Production environment variables

Confirm that production environment variables are configured in the deployment platform.

```dotenv
DATABASE_URL="your-neon-pooled-production-url"
DIRECT_URL="your-neon-direct-production-url"

IP_HASH_SECRET="long-random-production-secret"
ADMIN_SESSION_SECRET="different-long-random-production-secret"
ADMIN_PASSWORD="strong-production-password"

NEXT_PUBLIC_APP_URL="https://feedback.your-domain.example"

INNGEST_EVENT_KEY="your-production-event-key"
INNGEST_SIGNING_KEY="your-production-signing-key"
INNGEST_DEV="0"

UPSTASH_REDIS_REST_URL="https://your-upstash-url"
UPSTASH_REDIS_REST_TOKEN="your-upstash-token"

S3_REGION="your-region"
S3_BUCKET="greymatter-feedback-reports"
S3_ACCESS_KEY_ID="your-storage-key"
S3_SECRET_ACCESS_KEY="your-storage-secret"
S3_ENDPOINT="https://your-storage-endpoint"
```

Confirm these rules:

```text
[ ] Production secrets are not stored in Git.
[ ] Production uses different secrets than development.
[ ] NEXT_PUBLIC_APP_URL uses the real HTTPS domain.
[ ] INNGEST_DEV is set to 0.
[ ] Upstash Redis is configured.
[ ] Storage credentials can upload only to the intended report bucket.
[ ] Database URLs use SSL.
```

---

## P.3 Domain and QR-code readiness

Before generating final QR codes, confirm:

```text
[ ] Domain uses HTTPS.
[ ] HTTPS certificate is valid.
[ ] NEXT_PUBLIC_APP_URL matches the final domain.
[ ] The domain has no trailing slash in environment configuration.
[ ] Participant URLs open correctly on mobile data.
[ ] Participant URLs open correctly on venue Wi-Fi.
[ ] QR codes encode the production URL, not localhost.
```

Correct production QR URL:

```text
https://feedback.your-domain.example/e/REACT-2026-Q3?src=qr
```

Incorrect QR URL:

```text
http://localhost:3000/e/REACT-2026-Q3?src=qr
```

Test every printed or displayed QR code with at least two different phone models.

---

## P.4 Database and migration readiness

Before deployment:

```bash
npx prisma validate
```

Check migration status:

```bash
npx prisma migrate status
```

Apply production migrations through the controlled deployment process:

```bash
npx prisma migrate deploy
```

Confirm:

```text
[ ] Migrations are committed to source control.
[ ] Production migration target is correct.
[ ] Neon recovery options are understood.
[ ] Migration was tested on a Neon staging branch.
[ ] No destructive migration runs during a live event.
[ ] Prisma client was generated after schema changes.
```

---

## P.5 Inngest production readiness

Inngest must know how to reach the deployed application.

Configure the production sync URL:

```text
https://feedback.your-domain.example/api/inngest
```

Confirm these functions are visible in the Inngest production dashboard:

```text
process-feedback-submission
generate-pdf-report
```

Test both workflows.

### Submission event test

1. Open a published participant form.
2. Submit a test response.
3. Confirm `POST /api/feedback` returns:

   ```text
   202 Accepted
   ```

4. Confirm an Inngest run appears for:

   ```text
   feedback/submitted
   ```

5. Confirm `process-feedback-submission` succeeds.
6. Confirm a `Response` and `Answer` records appear in Neon.

### Report event test

1. Open the session dashboard.
2. Request a PDF report.
3. Confirm an Inngest run appears for:

   ```text
   report/generate.pdf
   ```

4. Confirm `generate-pdf-report` succeeds.
5. Confirm the report record becomes:

   ```text
   COMPLETE
   ```

6. Confirm the administrator can download the PDF.

---

## P.6 Participant experience smoke test

Use a real phone. Do not test only in a desktop browser.

For each important session:

```text
[ ] Scan QR code.
[ ] Confirm the right event and session title appear.
[ ] Confirm the expected published form version appears.
[ ] Confirm all questions appear in correct order.
[ ] Confirm required questions are marked correctly.
[ ] Confirm rating controls are easy to tap.
[ ] Confirm NPS controls fit on the screen.
[ ] Confirm choice options are easy to select.
[ ] Confirm text fields do not cause browser zoom.
[ ] Confirm form draft survives a browser refresh.
[ ] Confirm required-field errors appear clearly.
[ ] Submit a test response successfully.
[ ] Confirm the success confirmation appears.
```

Also test:

```text
[ ] Session is closed.
[ ] Session does not exist.
[ ] Session has no published form.
[ ] Network temporarily disconnects.
[ ] Draft remains available after failed submission.
```

---

## P.7 Administrator workflow smoke test

Sign in with a non-development production administrator account.

```text
[ ] Administrator login works.
[ ] Sign-out works.
[ ] Protected admin route redirects to login when signed out.
[ ] Event list loads.
[ ] Session list loads.
[ ] Draft form can be created.
[ ] Questions can be added.
[ ] Questions can be moved.
[ ] Choice options save correctly.
[ ] Form publishing works.
[ ] Participant preview works.
[ ] Session can be closed and reopened.
[ ] Analytics dashboard loads.
[ ] QR code downloads.
[ ] CSV exports.
[ ] PDF report generates.
```

---

## P.8 Security launch checklist

Before accepting real participant feedback:

```text
[ ] ADMIN_PASSWORD is strong and unique.
[ ] ADMIN_SESSION_SECRET is random and at least 32 characters.
[ ] IP_HASH_SECRET is random and at least 32 characters.
[ ] Admin cookies use Secure in production.
[ ] HTTPS is enabled.
[ ] Production uses Upstash rate limiting.
[ ] Raw IP addresses are not stored.
[ ] CSV exports require admin authentication.
[ ] Report downloads require admin authentication or signed URLs.
[ ] Participant comments are rendered as escaped text.
[ ] Secrets are unavailable to client-side JavaScript.
[ ] Error logs exclude participant comments and secrets.
[ ] Published forms cannot be edited directly.
[ ] Organization has a retention policy.
```

---

## P.9 Monitoring launch checklist

Confirm that the responsible technical operator can access:

```text
[ ] Deployment platform logs.
[ ] Inngest dashboard.
[ ] Neon dashboard.
[ ] Upstash dashboard.
[ ] Object storage dashboard.
[ ] Error-monitoring platform.
```

Create or confirm alerts for:

```text
[ ] Feedback API 503 errors.
[ ] Inngest submission failures.
[ ] PDF generation failures.
[ ] Neon connectivity failures.
[ ] High rate-limit rejection volume.
[ ] Storage upload failures.
```

Record escalation ownership:

```text
Primary technical contact:
[Name and contact method]

Backup technical contact:
[Name and contact method]

Event operations contact:
[Name and contact method]

Decision maker for closing feedback:
[Name and contact method]
```

---

## P.10 Staging-to-production release sequence

Use this release order.

```text
1. Merge reviewed code.
2. Run CI checks.
3. Test migration on Neon staging branch.
4. Deploy staging application.
5. Run participant and admin smoke tests.
6. Apply production migration.
7. Deploy production application.
8. Verify Inngest function sync.
9. Run one production test submission.
10. Run one production report generation test.
11. Confirm monitoring and alerts.
12. Publish or distribute final QR codes.
```

Do not distribute QR codes before confirming the production participant URL works.

---

## P.11 Event-day emergency fallback plan

Prepare an alternative if the platform has a temporary outage.

Possible fallbacks:

```text
Typed participant URL displayed on slides.
Alternative short URL.
Temporary external form provider.
Paper feedback cards.
Email feedback link after the event.
```

A simple fallback message:

> “The QR feedback form is temporarily unavailable. Please use the typed link on screen or share your feedback through the follow-up email.”

Record who has authority to activate a fallback.

---

## P.12 Go-live sign-off template

Use this simple record before a major event.

```text
GreyMatter Feedback Go-Live Sign-Off

Event:
[Event name]

Session:
[Session title]

Session ID:
[Session ID]

Participant URL:
[Production URL]

Published form version:
[Version number]

QR code tested:
[ ] Yes

Participant submission tested:
[ ] Yes

Inngest processing tested:
[ ] Yes

Dashboard tested:
[ ] Yes

CSV export tested:
[ ] Yes

PDF report tested:
[ ] Yes

Technical operator:
[Name]

Event owner:
[Name]

Approved at:
[UTC timestamp]
```

---

## P.13 Final go-live principle

A production launch is ready when every important path has been tested from the perspective of the people who will use it.

```text
Organizer creates and publishes
        ↓
Participant scans and submits
        ↓
Background worker stores safely
        ↓
Administrator reviews and exports
        ↓
Organization acts on feedback
```

If that full path works reliably in production, GreyMatter Feedback is ready for real events.
