# Primer 10 — Production Operations

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, technical founders, DevOps engineers, maintainers, product owners  
**Goal:** Explain how to think about operating GreyMatter Ledger in production  

---

# 1. Why Production Operations Matter

Building an app locally is not the same as operating it in production.

A local app can be restarted casually.

A production accounting app must be treated carefully.

Why?

Because it may contain:

```txt
Customer invoices
Vendor bills
Payment records
Journal entries
GST reports
Bank transactions
Audit logs
Company financial data
```

Production operations must protect:

```txt
Confidentiality
Integrity
Availability
Auditability
Recoverability
```

In simple terms:

```txt
Keep data private.
Keep data correct.
Keep the app available.
Keep a record of important actions.
Be able to recover from mistakes.
```

---

# 2. Production Architecture

GreyMatter Ledger production architecture:

```txt
Browser
  |
  v
Vercel-hosted Next.js app
  |
  |-- Clerk authentication
  |-- Neon Postgres database
  |-- Inngest background jobs
```

Services:

```txt
Vercel  -> web hosting
Clerk   -> authentication and organizations
Neon    -> Postgres database
Inngest -> background jobs and scheduled workflows
GitHub  -> source control
```

---

# 3. Production Readiness Mindset

Before production use, ask:

```txt
Can users sign in?
Can organizations be created?
Is data isolated by organization?
Are database migrations applied?
Can users create invoices and bills?
Do journal entries balance?
Are reports correct?
Are audit logs available?
Are backups understood?
Can background jobs run?
Can we recover from a bad deployment?
```

If the answer to any of these is no, the system is not fully production-ready.

---

# 4. Environments

A serious app should separate environments.

Recommended:

```txt
Development
Preview/Staging
Production
```

---

## Development

Used for:

```txt
Local coding
Experiments
Debugging
```

Can use test data.

---

## Preview / Staging

Used for:

```txt
Testing deployment
Reviewing pull requests
Testing migrations
Manual QA
```

Should not use production data unless properly controlled.

---

## Production

Used for:

```txt
Real users
Real company data
Real financial records
```

Must be protected.

---

# 5. Environment Variables

Production requires environment variables.

Key variables:

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

Secrets must never be committed to Git.

Secret examples:

```txt
DATABASE_URL
CLERK_SECRET_KEY
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

---

# 6. Deployment Flow

A typical deployment flow:

```txt
1. Run pnpm check locally.
2. Commit changes.
3. Push to GitHub.
4. Vercel builds deployment.
5. Apply database migrations if needed.
6. Smoke test deployment.
7. Monitor logs.
```

Command before deployment:

```bash
pnpm check
```

This runs:

```txt
lint
tests
build
```

---

# 7. Database Migrations in Production

Database migrations must be handled carefully.

Migration commands:

```bash
pnpm db:generate
pnpm db:migrate
```

Production migration example:

```bash
DATABASE_URL="production-url" pnpm db:migrate
```

Before production migration:

```txt
Review generated SQL.
Back up or branch database.
Apply during low-risk period.
Smoke test after migration.
```

---

# 8. Why Migrations Are Risky

Migrations change the system of record.

They can:

```txt
Create tables
Add columns
Add constraints
Drop columns
Change data types
Modify indexes
```

A bad migration can break production or damage data.

Be extra careful with tables like:

```txt
journal_entries
journal_lines
invoices
bills
payments
audit_logs
```

---

# 9. Backup Strategy

Accounting data must be recoverable.

A backup strategy should answer:

```txt
How often are backups taken?
Where are they stored?
Who can access them?
How do we restore?
Has restore been tested?
```

For Neon, review:

```txt
Backups
Point-in-time recovery
Branching
Restore options
```

A backup that has never been restored is not proven.

---

# 10. Recovery Strategy

If something goes wrong, you need a recovery plan.

Possible incidents:

```txt
Bad deployment
Bad migration
Accidental data deletion
Secret leak
Authentication misconfiguration
Background job failure
Database outage
```

Recovery plan should include:

```txt
Rollback app deployment
Restore database backup or branch
Rotate secrets
Disable affected feature
Review audit logs
Communicate with users if needed
```

---

# 11. Vercel Operations

Vercel is responsible for hosting the Next.js app.

Important areas:

```txt
Deployments
Environment variables
Build logs
Runtime logs
Domains
Preview deployments
```

Before production use:

```txt
Production env vars configured
Custom domain configured if needed
Build passes
Deployment logs clean
```

If a deployment fails:

```txt
Check build logs.
Run pnpm check locally.
Verify env vars.
```

---

# 12. Neon Operations

Neon hosts Postgres.

Important areas:

```txt
Connection string
Database branches
Backups
Query editor
Usage metrics
Access control
```

Operational tasks:

```txt
Review database health.
Apply migrations.
Monitor connection errors.
Use branches before risky changes.
Restrict dashboard access.
```

---

# 13. Clerk Operations

Clerk handles authentication and organizations.

Important areas:

```txt
Allowed origins
Redirect URLs
Production keys
Organizations
Roles
User management
Session settings
```

Production checklist:

```txt
Production domain configured.
Sign-in/sign-up URLs configured.
Organizations enabled.
Admin roles verified.
Test users removed or isolated.
```

---

# 14. Inngest Operations

Inngest handles background jobs.

Important areas:

```txt
Function list
Event history
Failures
Retries
Schedules
Endpoint configuration
Signing keys
```

Production endpoint:

```txt
https://your-domain.com/api/inngest
```

Operational tasks:

```txt
Monitor failed jobs.
Verify scheduled jobs run.
Check retry behavior.
Avoid sensitive event payloads.
```

---

# 15. Smoke Testing

A smoke test is a quick check of critical workflows.

After deployment, test:

```txt
Landing page loads.
Sign-in works.
Organization creation works.
Database status works.
Chart of accounts seeds.
Customer creation works.
Invoice creation works.
Journal diagnostics show balanced entries.
Reports load.
Inngest health check works.
```

For accounting app smoke testing, also check:

```txt
Journal balance SQL returns zero rows.
```

---

# 16. Journal Balance Production Check

Run:

```sql
select
  je.id,
  je.memo,
  sum(jl.debit_cents) as debits,
  sum(jl.credit_cents) as credits,
  sum(jl.debit_cents) - sum(jl.credit_cents) as difference
from journal_entries je
join journal_lines jl
  on jl.journal_entry_id = je.id
group by je.id, je.memo
having sum(jl.debit_cents) <> sum(jl.credit_cents);
```

Expected:

```txt
0 rows
```

If this returns rows, investigate immediately.

---

# 17. Monitoring

Minimum monitoring sources:

```txt
Vercel logs
Neon dashboard
Clerk dashboard
Inngest dashboard
Application audit logs
```

Future recommended tools:

```txt
Sentry
Axiom
Datadog
Logtail
OpenTelemetry
Vercel Analytics
```

Monitor:

```txt
Runtime errors
Failed builds
Database connection errors
Failed background jobs
Authentication issues
Unexpected journal validation failures
```

---

# 18. Audit Logs in Operations

Audit logs help answer:

```txt
Who created this invoice?
Who recorded this payment?
Who reversed this journal entry?
When did it happen?
```

Audit logs should be reviewed during:

```txt
Financial investigation
Support requests
Security incidents
Accounting corrections
```

Access to audit logs should be restricted.

---

# 19. Incident Response

If there is an incident:

```txt
1. Stay calm.
2. Preserve evidence.
3. Identify affected systems.
4. Stop ongoing damage.
5. Rotate secrets if needed.
6. Review audit logs.
7. Review deployment logs.
8. Review database changes.
9. Communicate if required.
10. Document root cause.
11. Add prevention measures.
```

For accounting incidents:

```txt
Do not delete records casually.
Use reversals or corrective entries.
Preserve history.
```

---

# 20. Secret Leak Response

If a secret leaks:

```txt
DATABASE_URL
CLERK_SECRET_KEY
INNGEST_SIGNING_KEY
INNGEST_EVENT_KEY
```

Do:

```txt
1. Rotate the secret in provider dashboard.
2. Update Vercel environment variable.
3. Update local .env.local.
4. Redeploy.
5. Revoke old secret.
6. Review logs for suspicious activity.
```

---

# 21. Access Control Operations

Review regularly:

```txt
Who has Vercel access?
Who has Neon access?
Who has Clerk dashboard access?
Who has Inngest access?
Who is an organization admin?
```

Remove access for people who no longer need it.

Use least privilege.

---

# 22. Data Retention

Accounting data usually needs long retention periods.

Production policy should define:

```txt
How long invoices are retained
How long journal entries are retained
How long audit logs are retained
How backups are retained
How deleted organizations are handled
```

Consult legal and accounting requirements.

---

# 23. Accounting Period Operations

The tutorial does not implement accounting period close.

Future production operations should include:

```txt
Monthly close
Year-end close
Locked periods
Retained earnings closing
GST filing period lock
```

Without period locks, users may change historical data too easily.

---

# 24. Background Job Operations

For each background job, document:

```txt
Purpose
Schedule
Inputs
Outputs
Failure behavior
Retry behavior
Idempotency strategy
Owner
```

Example:

```txt
Daily overdue invoice reminders
Schedule: daily
Input: unpaid overdue invoices
Output: reminder payloads
Future: send email
```

---

# 25. Idempotency in Production

Background jobs may retry.

Services may be called twice.

Users may double-click buttons.

Production systems should protect against duplicates.

Examples:

```txt
Unique invoice numbers
Unique account codes
One payment per full-paid invoice in tutorial
Posted bank transactions locked
Reconciled bank transactions locked
```

Future improvements:

```txt
Idempotency keys
Generation logs
Unique recurring invoice run constraints
```

---

# 26. Performance Operations

As data grows, watch:

```txt
Report query speed
Journal line count
Bank transaction count
Audit log size
Database indexes
Vercel response times
```

Potential optimizations:

```txt
Pagination
Date filters
Materialized report summaries
Background report generation
Indexes
Archiving
```

---

# 27. Logging Guidelines

Good logs:

```txt
Operation name
Organization ID
Entity ID
Error message
Timestamp
```

Avoid logging:

```txt
Secrets
Passwords
Full tokens
Sensitive bank details
Unnecessary personal data
```

---

# 28. Production Readiness Checklist

Before real use:

```txt
pnpm check passes
Production env vars configured
Database migrations applied
Clerk production setup complete
Inngest production endpoint configured
Tenant isolation manually tested
Journal balance SQL returns zero rows
Backups understood
Audit log tested
Admin permissions tested
Smoke test passed
Disclaimers reviewed
Professional accounting/tax review completed
```

---

# 29. Common Production Problems

## Problem: App Builds Locally but Fails on Vercel

Check:

```txt
Missing env vars
Different Node version
Build-time database access
Lint/test failure
```

Run locally:

```bash
pnpm check
```

---

## Problem: App Loads but Database Pages Fail

Check:

```txt
DATABASE_URL in Vercel
Neon database active
Migrations applied
SSL mode
```

---

## Problem: Auth Redirect Fails

Check Clerk:

```txt
Allowed origins
Redirect URLs
Production keys
```

---

## Problem: Background Jobs Do Not Run

Check:

```txt
/api/inngest endpoint
Inngest dashboard endpoint
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
Vercel deployment logs
```

---

# 30. Final Operations Mental Model

Operating GreyMatter Ledger means protecting:

```txt
Accounting truth
Tenant privacy
System availability
Audit history
Recovery capability
```

The most important production rule:

```txt
Do not treat production as a playground.
```

The second rule:

```txt
Back up before risky changes.
```

The third rule:

```txt
If financial history is wrong, correct it visibly and audibly.
```
