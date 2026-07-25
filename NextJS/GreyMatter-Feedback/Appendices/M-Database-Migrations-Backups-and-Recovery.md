# Appendix M: Database Migrations, Backups, and Recovery

GreyMatter Feedback stores important operational data:

- Published form versions.
- Participant responses.
- Written comments.
- Analytics source data.
- Report records.
- Administrator-created events and sessions.

That data must be changed carefully and protected against accidental deletion, broken deployments, and infrastructure failures.

This appendix explains how to manage Prisma migrations safely with Neon, use Neon branches for testing, and prepare a practical backup and recovery process.

---

## M.1 What is a database migration?

A database migration is a version-controlled instruction for changing database structure.

Examples:

```text
Add a new table.
Add a column.
Create an index.
Rename a field.
Add a relationship.
Change a constraint.
```

For example, if GreyMatter Feedback adds question helper text, the Prisma schema changes:

```prisma
model Question {
  helperText String? @map("helper_text") @db.Text
}
```

Then Prisma generates a migration containing SQL that updates PostgreSQL.

Think of a migration as a carefully documented renovation plan for a building:

```text
Current building layout
        ↓
Migration plan
        ↓
New building layout
```

The plan should be reviewed before it is applied to production.

---

## M.2 Important Prisma commands

| Command | Purpose | Safe environment |
|---|---|---|
| `npx prisma validate` | Check schema syntax and structure | Local, CI, production checks |
| `npx prisma generate` | Generate Prisma TypeScript client | Local, CI, deployment |
| `npx prisma migrate dev` | Create and apply a development migration | Local development only |
| `npx prisma migrate status` | Show migration status | Any environment |
| `npx prisma migrate deploy` | Apply existing migrations | Staging and production |
| `npx prisma studio` | Open database browser | Local or controlled access |
| `npx prisma db seed` | Insert development seed data | Development only |
| `npx prisma migrate reset` | Delete data and rebuild database | Disposable development database only |

The most important distinction is:

```text
migrate dev     → local development
migrate deploy  → staging and production
```

Never use this against production:

```bash
npx prisma migrate reset
```

It deletes data.

---

## M.3 Standard development migration workflow

When changing the Prisma schema locally, use this workflow.

```text
1. Change prisma/schema.prisma
2. Validate schema
3. Create migration
4. Inspect generated SQL
5. Test application locally
6. Commit migration files
7. Deploy migration through CI or deployment process
```

Example:

```bash
npx prisma validate
```

```bash
npx prisma migrate dev --name add_question_helper_text
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

Prisma creates migration files under:

```text
prisma/migrations/
```

Example:

```text
prisma/
├── migrations/
│   ├── 20260725103000_initial_schema/
│   │   └── migration.sql
│   └── 20260726120000_add_question_helper_text/
│       └── migration.sql
└── schema.prisma
```

Commit those migration files to Git:

```bash
git add prisma/schema.prisma prisma/migrations
git commit -m "Add helper text to feedback questions"
```

---

## M.4 Inspect generated migration SQL

Do not blindly trust generated SQL for important production changes.

Open the generated migration file:

### `prisma/migrations/<timestamp>_add_question_helper_text/migration.sql`

It may contain SQL similar to:

```sql
ALTER TABLE "questions"
ADD COLUMN "helper_text" TEXT;
```

This is low risk because the new field is nullable.

However, some changes are riskier.

Example risky change:

```sql
ALTER TABLE "responses"
DROP COLUMN "metadata";
```

That permanently removes stored metadata.

Before applying a migration, ask:

```text
Does this delete data?
Does this lock a large table?
Does this require data backfill?
Does application code support both old and new schema during deployment?
Can this be rolled back?
```

---

## M.5 Safe schema-change patterns

Some schema changes are safer than others.

## Adding a nullable column

Usually safe:

```prisma
model Question {
  helperText String? @map("helper_text") @db.Text
}
```

Why:

```text
Existing rows can have null.
Old application code keeps working.
New application code can handle absent values.
```

## Adding a required column

Potentially risky:

```prisma
model Question {
  reportingTag String @map("reporting_tag") @db.VarChar(100)
}
```

Existing rows have no value for the new required field.

A safer staged approach:

```text
Step 1:
Add nullable field.

Step 2:
Deploy code that writes the field for new records.

Step 3:
Backfill old records.

Step 4:
Make field required in a later migration.
```

Example first migration:

```prisma
reportingTag String? @map("reporting_tag") @db.VarChar(100)
```

Example backfill:

```ts
await prisma.question.updateMany({
  where: {
    reportingTag: null,
  },
  data: {
    reportingTag: "UNCLASSIFIED",
  },
});
```

Then, after confirming all rows are populated, change the field to required.

---

## M.6 Renaming a column safely

A direct rename may be safe for small applications, but it can break code during deployment if old and new application versions overlap.

For example, changing:

```text
questionText
```

to:

```text
prompt
```

A safer staged strategy is:

```text
1. Add prompt column.
2. Deploy code that writes both questionText and prompt.
3. Backfill prompt from questionText.
4. Deploy code that reads prompt.
5. Remove questionText in a later release.
```

This is called an **expand-and-contract migration**.

```text
Expand schema
        ↓
Run compatible code
        ↓
Move data
        ↓
Switch reads
        ↓
Contract old schema later
```

It reduces deployment risk.

---

## M.7 Use Neon branches for migration testing

Neon supports database branching.

A branch is an isolated copy-on-write database environment created from another branch.

This is useful for testing a migration safely:

```text
Production branch
        ↓
Create staging branch
        ↓
Apply migration to staging
        ↓
Test application
        ↓
Apply approved migration to production
```

Recommended branch setup:

```text
main        → production data
staging     → pre-production testing
development → local developer testing
```

For a more isolated workflow:

```text
feature/add-reporting-tags
```

Each branch receives its own connection strings.

Example local environment:

### `.env`

```dotenv
DATABASE_URL="postgresql://...development-pooler.../greymatter?sslmode=require"
DIRECT_URL="postgresql://...development.../greymatter?sslmode=require"
```

Example staging deployment environment:

```dotenv
DATABASE_URL="postgresql://...staging-pooler.../greymatter?sslmode=require"
DIRECT_URL="postgresql://...staging.../greymatter?sslmode=require"
```

Never point a local experimental migration at production by accident.

---

## M.8 Migration workflow with Neon branches

Use this process for important changes.

### Step 1 — Create a Neon branch

In Neon:

1. Open the GreyMatter Feedback project.
2. Open **Branches**.
3. Create a branch from production or staging.
4. Name it clearly:

   ```text
   staging-add-question-helper-text
   ```

5. Copy the branch’s pooled and direct URLs.

### Step 2 — Point local environment to branch

Temporarily update `.env`:

```dotenv
DATABASE_URL="staging-branch-pooled-url"
DIRECT_URL="staging-branch-direct-url"
```

Restart the development server.

### Step 3 — Run migration

```bash
npx prisma migrate deploy
```

### Step 4 — Test the application

Test:

```text
Admin login
Form authoring
Participant route
Feedback submission
Inngest response persistence
Dashboard analytics
CSV export
PDF report generation
```

### Step 5 — Restore development environment

Restore your normal development branch connection strings after testing.

### Step 6 — Apply to production

When approved, deploy the committed migration using:

```bash
npx prisma migrate deploy
```

against the production Neon branch.

---

## M.9 Production migration deployment

A production deployment should follow this order:

```text
1. Back up or confirm recovery point.
2. Confirm migration status.
3. Apply migrations.
4. Deploy application code.
5. Run smoke tests.
6. Monitor errors and database health.
```

Example:

```bash
npx prisma migrate status
```

```bash
npx prisma migrate deploy
```

```bash
npm run build
```

A deployment platform can run migration deployment as a dedicated release step.

For example:

```text
Build application
        ↓
Run prisma migrate deploy
        ↓
Deploy application
        ↓
Run smoke test
```

For larger teams, migrations may run in a separately controlled release job rather than inside every web deployment.

---

## M.10 Avoid destructive migrations during active events

Do not apply risky schema changes while a large live event is collecting feedback.

Avoid changes such as:

```text
Dropping tables
Dropping columns
Rebuilding indexes on large tables
Changing primary keys
Changing response relationships
Large data backfills
```

Schedule high-risk changes outside event windows.

A practical operational rule:

```text
No schema changes during active conferences,
major workshops, or scheduled feedback collection windows.
```

If an urgent application fix is required, prefer a code-only change that does not alter the database structure.

---

## M.11 Backups and recovery points

A backup is a recoverable copy of data.

Neon provides managed PostgreSQL capabilities, but your organization should still understand:

```text
What recovery options exist?
How long backup history is retained?
Who can restore data?
How long restoration takes?
How will a restore be tested?
```

A complete recovery strategy includes:

```text
Database recovery
Object storage recovery
Migration history
Application source code
Environment configuration recovery
```

The database alone is not enough if reports are stored separately in S3-compatible object storage.

---

## M.12 What should be backed up

| Resource | Why it matters |
|---|---|
| Neon PostgreSQL data | Events, forms, responses, answers, reports |
| Prisma migration files | Schema evolution history |
| Source repository | Application code |
| Object storage reports | Generated PDF archives |
| Environment variable inventory | Required deployment configuration |
| Infrastructure configuration | Domain, Inngest, Upstash, storage setup |
| Operational documentation | Recovery procedures and access ownership |

Do not place live secrets in source control.

Instead, store secrets in a password manager or secure secret-management system with access controls.

---

## M.13 Restore testing

A backup strategy is only trustworthy if restoration is tested.

A recommended quarterly exercise:

```text
1. Create a temporary Neon branch from a recovery point.
2. Connect a local or staging app to the branch.
3. Confirm event, session, response, and answer counts.
4. Confirm reports are available from storage.
5. Run dashboard and CSV export checks.
6. Record recovery duration and issues.
```

Example verification queries:

```sql
SELECT COUNT(*) FROM events;
```

```sql
SELECT COUNT(*) FROM sessions;
```

```sql
SELECT COUNT(*) FROM responses;
```

```sql
SELECT COUNT(*) FROM answers;
```

```sql
SELECT COUNT(*) FROM reports;
```

Record expected values before a drill so you can compare restored data.

---

## M.14 Object storage recovery

Database recovery does not automatically restore PDF files stored in S3-compatible storage.

Use storage provider protections such as:

```text
Versioning
Retention policies
Object lock, where appropriate
Cross-region replication, where needed
Lifecycle rules
Restricted deletion permissions
```

A practical report-storage policy:

```text
Generated PDF reports:
Retain 12 months

Old reports:
Move to lower-cost archival storage after 90 days

Deleted reports:
Keep recoverable object versions for 30 days
```

The exact policy depends on privacy and legal requirements.

---

## M.15 Recovery scenarios

## Scenario 1 — Bad deployment breaks participant page

Symptoms:

```text
Participant route returns errors.
No database data was changed.
```

Response:

```text
1. Roll back application deployment.
2. Confirm participant page loads.
3. Review logs.
4. Fix in staging.
5. Redeploy after testing.
```

No database restore is needed.

---

## Scenario 2 — Bad migration causes application errors

Symptoms:

```text
Application expects a column that does not exist.
Migration partially applied.
```

Response:

```text
1. Stop further deployments.
2. Inspect prisma migrate status.
3. Review migration SQL.
4. Decide whether to apply a corrective migration.
5. Avoid manual production SQL unless the team has PostgreSQL expertise.
6. Restore from recovery point only if data integrity is affected.
```

Prefer corrective forward migrations rather than trying to edit migration history already applied to production.

---

## Scenario 3 — Accidental session deletion

Symptoms:

```text
An administrator deletes an event or session.
Related responses disappear because of cascade deletion.
```

Response:

```text
1. Identify deletion time.
2. Create a Neon branch from a recovery point before deletion.
3. Export or restore required records carefully.
4. Restore related reports from object storage if needed.
5. Add stronger deletion confirmation and audit logging.
```

This scenario is why production deletion controls should be restricted and logged.

---

## Scenario 4 — Report files deleted but database records remain

Symptoms:

```text
Report status is COMPLETE.
Report URL returns 404.
```

Response:

```text
1. Check object storage version history.
2. Restore deleted object version if available.
3. If unavailable, queue report regeneration.
4. Update report record if a new URL is created.
5. Review storage deletion permissions.
```

---

## M.16 Soft deletion recommendation

The tutorial uses cascading deletes for simplicity.

For production systems with important historical feedback, consider **soft deletion**.

Instead of immediately deleting a session:

```text
Session is removed permanently.
```

mark it:

```text
deletedAt = timestamp
```

Example schema addition:

```prisma
model Session {
  id        String    @id @db.VarChar(64)
  deletedAt DateTime? @map("deleted_at")

  // Existing fields remain unchanged.
}
```

Then normal queries exclude deleted sessions:

```ts
const session = await prisma.session.findFirst({
  where: {
    id: sessionId,
    deletedAt: null,
  },
});
```

Benefits:

```text
Accidental deletions are recoverable.
Administrators can restore records.
Audit trails are easier.
Historical reports can remain available.
```

Trade-offs:

```text
Every query must filter deletedAt.
Storage is retained longer.
Permanent deletion process is still needed.
```

A common policy is:

```text
Soft delete immediately
        ↓
Retain for 30 days
        ↓
Permanent deletion through controlled cleanup job
```

---

## M.17 Migration checklist

Before creating a migration:

```text
[ ] Understand why schema change is needed.
[ ] Check whether it affects published form history.
[ ] Check whether it affects existing response data.
[ ] Prefer additive nullable changes first.
[ ] Decide whether backfill is required.
[ ] Create a named migration.
[ ] Inspect migration SQL.
[ ] Test on a Neon branch.
[ ] Run application smoke tests.
[ ] Commit migration files.
```

Before production deployment:

```text
[ ] Confirm production database target.
[ ] Confirm backup or recovery-point availability.
[ ] Confirm no major live event is underway.
[ ] Run prisma migrate status.
[ ] Apply prisma migrate deploy.
[ ] Deploy compatible application code.
[ ] Verify participant and admin routes.
[ ] Monitor errors.
```

After production deployment:

```text
[ ] Confirm migration is recorded.
[ ] Confirm application health checks pass.
[ ] Confirm participant submission works.
[ ] Confirm Inngest processing works.
[ ] Confirm dashboard works.
[ ] Confirm CSV and PDF reporting work.
```

---

## M.18 Final data resilience checklist

```text
[ ] Prisma migrations are committed to Git.
[ ] Development and production use separate Neon branches or projects.
[ ] Production uses prisma migrate deploy.
[ ] Destructive migrations are avoided during live events.
[ ] Recovery options are documented.
[ ] Restore drills occur regularly.
[ ] Object storage has versioning or recovery protections.
[ ] Reports can be regenerated if needed.
[ ] Session deletion is restricted.
[ ] Audit logs exist for high-risk admin actions.
[ ] Soft deletion is considered for production.
[ ] Migration changes are tested before production release.
```

Reliable feedback collection depends on reliable data. Careful migrations, tested recovery procedures, and conservative deletion policies help GreyMatter Feedback preserve the value participants provide.
