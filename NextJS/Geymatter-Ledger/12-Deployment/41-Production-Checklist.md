# Part 41 — Production Checklist and Best Practices

In Part 40, we deployed GreyMatter Ledger to Vercel.

Now we will document a serious production readiness checklist.

This part is less about adding features and more about engineering discipline.

By the end of this part, you will have:

- A production checklist document
- A security checklist
- A database operations checklist
- A financial data integrity checklist
- A monitoring and logging checklist
- A backup and recovery checklist
- A responsible launch guidance document

This is important because accounting software handles sensitive business data.

A demo can be casual.

A production accounting system cannot.

---

# 1. Understand Production Readiness

## The Target

We are documenting what must be true before using the app seriously.

---

## The Concept

Production readiness means:

```txt
The app works.
The app is secure.
The app is observable.
The app can recover from failure.
The app protects financial data.
The team knows operational responsibilities.
```

For accounting software, the bar is higher than a simple todo app.

Why?

Because mistakes can affect:

```txt
Financial statements
Tax reports
Customer invoices
Vendor payments
Business decisions
```

---

# 2. Create Production Checklist Document

## The Target

We are creating:

```txt
docs/production-checklist.md
```

---

## The Implementation

Create:

```txt
docs/production-checklist.md
```

Add:

```md
# GreyMatter Ledger Production Checklist

GreyMatter Ledger is an educational accounting application. Before using any accounting system for real business operations, review technical, accounting, legal, and tax requirements with qualified professionals.

## 1. Environment Variables

Confirm production has:

- `DATABASE_URL`
- `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`
- `CLERK_SECRET_KEY`
- `NEXT_PUBLIC_CLERK_SIGN_IN_URL`
- `NEXT_PUBLIC_CLERK_SIGN_UP_URL`
- `NEXT_PUBLIC_CLERK_SIGN_IN_FALLBACK_REDIRECT_URL`
- `NEXT_PUBLIC_CLERK_SIGN_UP_FALLBACK_REDIRECT_URL`
- `NEXT_PUBLIC_CLERK_AFTER_CREATE_ORGANIZATION_URL`
- `NEXT_PUBLIC_CLERK_AFTER_SELECT_ORGANIZATION_URL`
- `INNGEST_EVENT_KEY`
- `INNGEST_SIGNING_KEY`

Never commit real secrets to Git.

## 2. Authentication and Authorization

- Clerk production instance configured.
- Clerk allowed origins include production domain.
- Clerk organizations enabled.
- Admin/member roles reviewed.
- Admin-only actions protected on the server.
- Audit log access restricted to admins.
- Journal reversals restricted to admins.

## 3. Database

- Production Neon database exists.
- Migrations applied.
- Connection uses SSL.
- Production and development databases are separate.
- Database dashboard access is restricted.
- Database credentials are rotated if exposed.
- Schema migrations are reviewed before deployment.

## 4. Financial Integrity

- Journal entries must balance.
- Money stored as integer cents.
- Posted entries are not deleted casually.
- Corrections use reversals.
- Reports are based on journal lines.
- Tenant-scoped queries are enforced.
- Account codes are unique per organization.
- Reconciled bank transactions are locked from casual editing.

## 5. Multi-Tenancy

- Every business table includes `organization_id`.
- Queries filter by active organization.
- Cross-tenant access is manually tested.
- Organization switcher works correctly.
- Database diagnostics do not expose cross-tenant data to normal users.

## 6. Auditability

- Audit logs exist for important actions.
- Reversals include a reason.
- Payment recording is auditable.
- Invoice and bill posting is traceable to journal entries.
- Bank transaction posting links to journal entries.

## 7. Backups and Recovery

- Neon backup/branching strategy reviewed.
- Recovery process tested.
- Accidental deletion response plan documented.
- Database export process documented.
- Critical production migrations are backed up beforehand.

## 8. Monitoring

- Vercel deployment logs reviewed.
- Runtime errors monitored.
- Inngest function failures monitored.
- Database connection errors monitored.
- Authentication errors monitored.

## 9. Background Jobs

- Inngest production app configured.
- `/api/inngest` endpoint reachable.
- Event keys configured.
- Scheduled jobs verified.
- Failed jobs reviewed and retry behavior understood.

## 10. Compliance and Professional Review

Before real use, consult qualified professionals about:

- GST reporting
- IRAS filing requirements
- ACRA recordkeeping
- CPF obligations
- Corporate tax
- Data protection obligations
- Accounting policy choices

## 11. Launch Smoke Test

Before launch:

1. Sign up.
2. Create organization.
3. Seed chart of accounts.
4. Create customer.
5. Create invoice.
6. Record customer payment.
7. Create vendor.
8. Create bill.
9. Record vendor payment.
10. Import bank CSV.
11. Post bank transaction.
12. Reconcile bank transaction.
13. Review Profit & Loss.
14. Review Balance Sheet.
15. Review GST report.
16. Review audit log.
17. Trigger Inngest health check.

## 12. Known Educational Limitations

This tutorial app intentionally simplifies some production concerns:

- No partial invoice payments yet.
- No partial bill payments yet.
- No real email delivery yet.
- No file storage for invoice PDFs yet.
- No formal GST F5 submission workflow.
- No advanced approval workflows.
- No full general ledger export.
- No external bank feed integration.
- No accounting period close.
- No immutable database-level append-only enforcement yet.

Treat this as a strong learning foundation, not a certified accounting product.
```

---

## The Verification

Run:

```bash
cat docs/production-checklist.md
```

---

# 3. Create Security Notes Document

## The Target

We are creating:

```txt
docs/security.md
```

---

## The Implementation

Create:

```txt
docs/security.md
```

Add:

```md
# Security Notes

## Secrets

Never commit:

- `.env.local`
- production database URLs
- Clerk secret keys
- Inngest signing keys

If a secret leaks, rotate it immediately.

## Authentication

Authentication is handled by Clerk.

Use production Clerk keys for production deployments.

## Authorization

Sensitive actions must be checked on the server.

Do not rely only on hiding buttons.

Current admin-only actions include:

- Viewing audit logs
- Reversing journal entries

## Multi-Tenant Data Protection

Every organization-scoped query must filter by organization ID.

Bad:

```ts
await db.select().from(invoices);
```

Good:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organization.id));
```

## Financial Data

Financial records require extra care.

Do not delete posted journal entries casually.

Use reversals.

## Audit Logs

Audit logs should not contain sensitive secrets.

Avoid storing:

- passwords
- API keys
- full bank account numbers
- unnecessary personal data

## Dependencies

Run dependency updates carefully.

Review security advisories.

## Production Headers

Consider adding security headers for:

- Content Security Policy
- X-Frame-Options
- Referrer-Policy
- Permissions-Policy

## Incident Response

If a security incident occurs:

1. Disable affected credentials.
2. Rotate secrets.
3. Review audit logs.
4. Review deployment logs.
5. Notify affected parties if required.
6. Document timeline and remediation.
```

---

## The Verification

Run:

```bash
cat docs/security.md
```

---

# 4. Create Database Operations Document

## The Target

We are creating:

```txt
docs/database-operations.md
```

---

## The Implementation

Create:

```txt
docs/database-operations.md
```

Add:

```md
# Database Operations

## Database Provider

GreyMatter Ledger uses Neon Postgres.

## Migrations

Generate migrations:

```bash
pnpm db:generate
```

Apply migrations:

```bash
pnpm db:migrate
```

Open Drizzle Studio:

```bash
pnpm db:studio
```

## Production Migration Safety

Before production migrations:

1. Review generated SQL.
2. Confirm migration is additive when possible.
3. Back up or branch the database.
4. Apply during low-traffic periods.
5. Verify application health after migration.

## Common Verification Queries

List tables:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

Check journal balance:

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

This query should return zero rows.

## Tenant Data Checks

Check invoice counts by organization:

```sql
select
  o.name,
  count(i.id) as invoice_count
from organizations o
left join invoices i
  on i.organization_id = o.id
group by o.name
order by o.name;
```

## Backup and Recovery

Use Neon branching/backups.

Before risky migrations, create a branch or backup.

Test recovery process before relying on it.
```

---

## The Verification

Run:

```bash
cat docs/database-operations.md
```

---

# 5. Update README with Production Docs

## The Target

We are updating:

```txt
README.md
```

---

## The Implementation

Open:

```txt
README.md
```

Add this section near the bottom:

```md
## Production Documentation

See:

- [`docs/deployment.md`](docs/deployment.md)
- [`docs/production-checklist.md`](docs/production-checklist.md)
- [`docs/security.md`](docs/security.md)
- [`docs/database-operations.md`](docs/database-operations.md)
```

---

## The Verification

Run:

```bash
pnpm check
```

---

# 6. Commit Production Readiness Docs

## The Target

We are saving this documentation milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add production readiness documentation"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: Docs folder missing

Create it:

```bash
mkdir -p docs
```

---

## Error: README links broken

Check file names:

```txt
deployment.md
production-checklist.md
security.md
database-operations.md
```

---

# Phase 12 Reference — Production Mindset

## Production Readiness

A combination of reliability, security, observability, recovery, and operational discipline.

---

## Smoke Test

A quick end-to-end check that critical workflows still work.

---

## Backup Strategy

A documented way to restore data after failure or mistake.

---

# Part 41 Completion Checklist

You are ready for Part 42 if:

- [ ] `docs/production-checklist.md` exists
- [ ] `docs/security.md` exists
- [ ] `docs/database-operations.md` exists
- [ ] README links to production docs
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
