# GreyMatter Feedback Disaster Recovery Plan

**Version:** 1.0  
**Purpose:** Restore GreyMatter Feedback after application, database, background-processing, storage, or configuration failures.

---

## 1. Recovery Objectives

| Service Area | RTO Target | RPO Target |
|---|---:|---:|
| Participant feedback form | 1 hour | 15 minutes |
| Admin portal | 4 hours | 1 hour |
| Feedback responses | 4 hours | 15 minutes |
| Analytics dashboard | 4 hours | 1 hour |
| CSV export | 8 hours | 1 hour |
| PDF reports | 24 hours | 24 hours |
| Historical report files | 24 hours | 24 hours |

**Definitions:**

- **RTO — Recovery Time Objective:** Maximum acceptable time to restore service.
- **RPO — Recovery Point Objective:** Maximum acceptable amount of data loss measured in time.

For live high-attendance events, use a stricter operational target:

```text
Participant form RTO: 15 minutes
Submission processing RTO: 30 minutes
```

---

## 2. Recovery Scope

This plan covers:

```text
Next.js application hosting
Neon PostgreSQL database
Prisma migrations
Inngest background workflows
Upstash Redis rate limiting
S3-compatible PDF report storage
Environment variables and secrets
Custom domain and DNS
Source code repository
```

---

## 3. Critical Dependencies

| Dependency | Purpose | Recovery Owner |
|---|---|---|
| Next.js hosting provider | Public participant and admin application | Platform Owner |
| Neon PostgreSQL | Events, forms, responses, answers, reports | Database Owner |
| Inngest | Submission and PDF background jobs | Technical Operator |
| Upstash Redis | Distributed rate limiting | Platform Owner |
| S3/R2 storage | PDF report files | Storage Owner |
| Git repository | Source code and Prisma migrations | Engineering Owner |
| DNS provider | Custom domain routing | Platform Owner |
| Secret manager / deployment variables | Credentials and signing secrets | Security Owner |

---

## 4. Required Preparedness Controls

Before production launch, verify:

```text
[ ] Source code is stored in a private Git repository.
[ ] Prisma migration files are committed to Git.
[ ] Production uses a dedicated Neon production branch or project.
[ ] Staging uses a separate Neon branch or project.
[ ] Object storage has versioning or equivalent recovery capability.
[ ] Environment variables are documented in a secure password manager or secret manager.
[ ] Production report storage is private.
[ ] Inngest production functions are synced.
[ ] Upstash Redis production credentials are documented securely.
[ ] At least two authorized operators can access production infrastructure.
[ ] A fallback feedback collection method exists.
[ ] Restore drills are scheduled at least quarterly.
```

---

## 5. Backup Strategy

## 5.1 Database

GreyMatter Feedback uses Neon PostgreSQL.

Required operational controls:

```text
Use Neon-managed recovery capabilities.
Understand the configured backup and recovery-point options.
Document Neon project, branch, database, and role names.
Test restoration to a separate recovery branch.
Never test destructive recovery directly on production.
```

### Database records to protect

```text
events
sessions
form_versions
questions
responses
answers
reports
```

---

## 5.2 Source Code and Schema

The Git repository must include:

```text
src/
prisma/schema.prisma
prisma/migrations/
prisma/seed.ts
package.json
next.config.ts
deployment documentation
```

Do not store actual secrets in Git.

Required secure secret inventory:

```text
DATABASE_URL
DIRECT_URL
IP_HASH_SECRET
ADMIN_SESSION_SECRET
ADMIN_PASSWORD
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
UPSTASH_REDIS_REST_URL
UPSTASH_REDIS_REST_TOKEN
S3_REGION
S3_BUCKET
S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY
S3_ENDPOINT
```

---

## 5.3 PDF Reports

Production PDF reports must be stored in private S3-compatible storage.

Recommended controls:

```text
[ ] Enable object versioning where available.
[ ] Restrict deletion permissions.
[ ] Retain deleted object versions for at least 30 days.
[ ] Use a separate production storage bucket.
[ ] Maintain a report regeneration process.
[ ] Store report metadata in Neon.
```

Reports can generally be regenerated from stored responses and answers if the database remains intact.

---

# 6. Incident Severity Levels

| Severity | Description | Example |
|---|---|---|
| SEV-1 | Participant feedback unavailable during active major event | Domain outage, app outage, database outage |
| SEV-2 | Feedback accepted but not persisted | Inngest or Neon processing failure |
| SEV-3 | Admin analytics, CSV, or PDF reports unavailable | Dashboard failure, storage failure |
| SEV-4 | Non-critical feature issue | QR download styling issue, delayed report panel refresh |

---

# 7. Disaster Recovery Scenarios

## 7.1 Scenario: Next.js Application Outage

### Symptoms

```text
Participant URLs return 500 errors.
Admin portal unavailable.
Deployment platform reports application failure.
```

### Immediate Actions

```text
1. Confirm incident using participant URL.
2. Check hosting provider status.
3. Check latest deployment logs.
4. Check whether a recent deployment caused the outage.
5. Roll back to previous known-good deployment if applicable.
6. Confirm /e/[sessionId] participant route works.
7. Confirm POST /api/feedback returns expected response.
```

### Recovery Procedure

```text
1. Identify last known-good deployment.
2. Roll back deployment through hosting platform.
3. Verify home page loads.
4. Verify admin login loads.
5. Verify participant form loads.
6. Submit controlled test feedback.
7. Confirm Inngest processing succeeds.
8. Monitor error logs for 30 minutes.
```

### Fallback

```text
Display an approved alternate feedback URL.
Use a temporary external form.
Use paper feedback cards.
Collect feedback through follow-up email.
```

---

## 7.2 Scenario: Neon PostgreSQL Unavailable

### Symptoms

```text
Participant form cannot load.
Feedback API returns 503.
Admin dashboard fails.
Prisma connection errors appear.
```

### Immediate Actions

```text
1. Check Neon status dashboard.
2. Run npm run db:test from trusted operator environment.
3. Check Neon project and branch status.
4. Confirm DATABASE_URL and DIRECT_URL have not changed unexpectedly.
5. Check deployment logs for Prisma or connection-pool errors.
```

### Recovery Procedure

```text
1. If Neon provider outage exists, monitor provider incident status.
2. Keep participant drafts intact; do not clear browser drafts on failed submission.
3. Use alternative feedback collection method if outage exceeds RTO.
4. When Neon recovers, verify:
   - Participant route loads.
   - API accepts submissions.
   - Inngest jobs process.
   - Dashboard loads.
5. Review Inngest retries and failed runs.
6. Replay failed Inngest jobs where appropriate.
```

### Recovery Validation

```text
[ ] npx prisma validate succeeds.
[ ] npm run db:test succeeds.
[ ] Participant form loads.
[ ] New test response persists.
[ ] Dashboard count updates.
```

---

## 7.3 Scenario: Accidental Database Deletion or Corruption

### Examples

```text
Event deleted accidentally.
Session deleted accidentally.
Published form version altered incorrectly.
Responses deleted through direct database action.
Bad migration damages schema.
```

### Immediate Actions

```text
1. Stop destructive operations.
2. Record exact incident time in UTC.
3. Identify affected event/session/report IDs.
4. Do not run additional migrations.
5. Do not overwrite data with ad hoc fixes.
6. Notify database owner and platform owner.
```

### Recovery Procedure

```text
1. Create a Neon recovery branch from a recovery point before the incident.
2. Connect Prisma Studio or staging application to the recovery branch.
3. Verify affected records exist in recovery branch.
4. Determine restoration scope:
   - Full database restore
   - Event-level restore
   - Session-level restore
   - Response-level restore
5. Export or copy required records carefully.
6. Restore related report files from object storage if required.
7. Apply corrective application changes.
8. Add audit log or deletion safeguards if missing.
```

### Important Rule

Do not restore an entire old database over current production unless the impact assessment justifies it.

A full restore may overwrite valid responses submitted after the recovery point.

Prefer targeted restoration where possible.

---

## 7.4 Scenario: Bad Prisma Migration

### Symptoms

```text
Application errors after deployment.
Missing database column.
Invalid constraint.
Migration fails halfway through.
Slow or locked database tables.
```

### Immediate Actions

```text
1. Stop further deployments.
2. Run npx prisma migrate status.
3. Identify migration name and deployment time.
4. Review generated migration.sql.
5. Determine whether data integrity is affected.
```

### Recovery Procedure

```text
1. Roll back application code if it depends on unavailable schema.
2. Do not edit an already-applied production migration.
3. Create a corrective forward migration.
4. Test corrective migration on a Neon staging or recovery branch.
5. Apply with:
   npx prisma migrate deploy
6. Verify participant and admin workflows.
```

### Prevention

```text
Use expand-and-contract migration strategy.
Test migrations on Neon branches.
Avoid destructive schema changes during live events.
Use prisma migrate deploy in production.
Never use prisma migrate reset in production.
```

---

## 7.5 Scenario: Inngest Submission Processing Failure

### Symptoms

```text
Participant receives 202 Accepted.
No Response record appears in Neon.
Dashboard count does not increase.
Inngest run fails or retries repeatedly.
```

### Immediate Actions

```text
1. Open Inngest dashboard.
2. Locate process-feedback-submission runs.
3. Inspect failed step.
4. Check Neon database availability.
5. Check Inngest signing and event keys.
6. Confirm /api/inngest endpoint is reachable.
```

### Recovery Procedure

```text
1. Resolve root dependency issue.
2. Confirm new test event processes successfully.
3. Replay failed Inngest runs where safe.
4. Confirm idempotency prevents duplicate responses.
5. Compare accepted API submissions with saved Response records.
6. Monitor retries and queue backlog.
```

### Recovery Validation

```text
[ ] Inngest function is visible.
[ ] New feedback/submitted event succeeds.
[ ] Response record exists.
[ ] Answer records exist.
[ ] Replay does not create duplicate response.
```

---

## 7.6 Scenario: Inngest PDF Report Failure

### Symptoms

```text
Report remains QUEUED.
Report remains PROCESSING.
Report becomes FAILED.
PDF URL does not work.
```

### Immediate Actions

```text
1. Locate generate-pdf-report run.
2. Inspect failed step.
3. Check report record in Neon.
4. Check object storage credentials.
5. Check object storage bucket permissions.
6. Check report size and comment volume.
```

### Recovery Procedure

```text
1. Correct storage or rendering configuration.
2. Confirm a new report request succeeds.
3. Retry or replay failed report job if appropriate.
4. If report file is missing but data exists, regenerate report.
5. If reports are unavailable during event, use CSV export as fallback.
```

---

## 7.7 Scenario: S3-Compatible Storage Outage or Accidental Report Deletion

### Symptoms

```text
Report status is COMPLETE but URL returns 404.
Report download fails.
Storage upload fails.
```

### Immediate Actions

```text
1. Check storage provider status.
2. Verify bucket and object key.
3. Verify report record URL.
4. Check object version history.
5. Check storage access logs.
```

### Recovery Procedure

```text
1. Restore deleted object version if available.
2. If file cannot be restored, regenerate report from Neon data.
3. Update Report record with new URL.
4. Confirm private download access.
5. Review storage deletion permissions.
```

### Fallback

```text
Export CSV.
Generate report later.
Provide dashboard screenshot only if authorized.
```

---

## 7.8 Scenario: Upstash Redis Failure

### Symptoms

```text
Feedback API returns 503.
Rate-limit check errors appear.
Submission requests cannot proceed.
```

### Immediate Actions

```text
1. Check Upstash status.
2. Check REST URL and token configuration.
3. Check deployment environment values.
4. Confirm Redis endpoint is reachable.
```

### Recovery Procedure

```text
1. Restore Upstash connectivity or credentials.
2. Verify rate-limit checks succeed.
3. Test controlled participant submission.
4. Monitor API 503 rate.
```

### Emergency Decision

Do not automatically disable all rate limiting in production without an explicit incident decision.

If a temporary fallback is implemented, it must include:

```text
Short duration.
Strict monitoring.
Lower session capacity.
Clear rollback plan.
```

---

## 7.9 Scenario: Admin Secret Exposure

### Examples

```text
ADMIN_PASSWORD exposed.
ADMIN_SESSION_SECRET exposed.
DATABASE_URL exposed.
S3 credentials exposed.
Inngest key exposed.
```

### Immediate Actions

```text
1. Treat exposure as active security incident.
2. Remove secret from public location.
3. Rotate exposed credential immediately.
4. Redeploy application with new values.
5. Review logs for suspicious activity.
6. Document exposure scope.
```

### Specific Recovery Actions

| Exposed Secret | Required Action |
|---|---|
| `ADMIN_PASSWORD` | Change password; notify administrators |
| `ADMIN_SESSION_SECRET` | Rotate secret; all admin sessions become invalid |
| `DATABASE_URL` / `DIRECT_URL` | Rotate Neon role password or connection credentials |
| `IP_HASH_SECRET` | Rotate; daily hash continuity will reset |
| Inngest keys | Rotate in Inngest and deployment platform |
| Upstash token | Rotate token |
| S3 access key | Disable old key and create restricted replacement |

---

## 7.10 Scenario: DNS or Custom Domain Failure

### Symptoms

```text
QR code resolves to error.
HTTPS certificate error.
Participant URL unavailable while hosting platform remains healthy.
```

### Immediate Actions

```text
1. Check DNS provider status.
2. Confirm domain records.
3. Confirm hosting custom domain configuration.
4. Confirm certificate status.
5. Test provider deployment URL if available.
```

### Recovery Procedure

```text
1. Restore correct DNS records.
2. Wait for DNS propagation where required.
3. Use known fallback URL only if approved.
4. Do not print temporary preview URLs unless they are stable.
5. Regenerate QR codes if permanent domain changes.
```

---

# 8. Event-Day Fallback Plan

If GreyMatter Feedback is unavailable during a live event, use one of the following approved fallbacks.

| Priority | Fallback |
|---:|---|
| 1 | Display typed backup feedback URL |
| 2 | Use temporary hosted form provider |
| 3 | Collect feedback by follow-up email |
| 4 | Use paper feedback cards |
| 5 | Use moderated chat or event app poll |

### Minimum Fallback Message

> “The QR feedback form is temporarily unavailable. Please use the alternate link on screen or share your feedback through the follow-up method provided by the facilitator.”

---

# 9. Recovery Communication Plan

## 9.1 Internal Update Template

```text
Incident:
[Short description]

Severity:
[SEV-1 / SEV-2 / SEV-3 / SEV-4]

Start time:
[UTC timestamp]

Affected services:
[Participant form / Admin portal / Inngest / Neon / Reports]

Affected sessions:
[Session IDs]

Participant impact:
[Description]

Current mitigation:
[Description]

Owner:
[Name]

Next update:
[UTC timestamp]
```

---

## 9.2 Resolution Template

```text
Incident resolved:
[UTC timestamp]

Root cause:
[Brief description]

Recovery action:
[What restored service]

Data impact:
[None / estimated scope]

Follow-up actions:
1. [Action]
2. [Action]
3. [Action]

Owner:
[Name]
```

---

# 10. Disaster Recovery Testing Schedule

| Test | Frequency | Owner |
|---|---:|---|
| Application rollback test | Quarterly | Platform Owner |
| Neon recovery branch restore test | Quarterly | Database Owner |
| Inngest failed-job replay test | Monthly | Technical Operator |
| PDF regeneration test | Quarterly | Report Owner |
| Object storage recovery test | Quarterly | Storage Owner |
| Secret rotation drill | Annually or after exposure | Security Owner |
| Event-day fallback exercise | Before major event | Event Owner |
| Full participant-to-report smoke test | Before every major event | Administrator |

---

# 11. Recovery Validation Checklist

After any recovery action, verify:

```text
[ ] Public landing page loads.
[ ] Admin login works.
[ ] Admin event list works.
[ ] Participant session URL loads.
[ ] Correct published form renders.
[ ] Participant submission returns 202.
[ ] Inngest processes feedback/submitted successfully.
[ ] Response appears in Neon.
[ ] Answers appear in Neon.
[ ] Dashboard response count updates.
[ ] CSV export works.
[ ] PDF report can be generated.
[ ] Report download works.
[ ] Rate limiting functions.
[ ] Monitoring shows no sustained errors.
```

---

# 12. Final DR Principle

GreyMatter Feedback recovery should prioritize participant data integrity and active-event availability.

```text
1. Restore ability to collect feedback.
2. Preserve participant drafts and avoid false success states.
3. Restore background processing.
4. Restore analytics and exports.
5. Restore PDF reporting.
6. Validate all layers before declaring incident resolved.
```

The most important rule is:

> Never trade data integrity for speed without an explicit, documented incident decision.
