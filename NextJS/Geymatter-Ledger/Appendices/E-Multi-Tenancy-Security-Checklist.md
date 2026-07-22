# Appendix E — Multi-Tenancy and Security Checklist

This appendix documents the multi-tenancy and security principles used in **GreyMatter Ledger**.

It is one of the most important appendices in the entire project.

Why?

Because GreyMatter Ledger is a SaaS-style accounting application.

That means:

```txt
One application serves many companies.
```

Each company must only see its own data.

A multi-tenant accounting bug can be extremely serious.

For example:

```txt
Company A seeing Company B’s invoices
Company B posting to Company A’s ledger
A user reversing another company’s journal entry
A report mixing multiple organizations
```

Those are not small bugs.

They are data isolation failures.

This appendix gives you a checklist to prevent them.

---

# 1. Core Multi-Tenancy Rule

The most important rule is:

```txt
Every company-scoped query must filter by organization_id.
```

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

The application must never casually query all business data unless it is an intentionally admin-only global diagnostic operation.

---

# 2. Users vs Organizations

GreyMatter Ledger separates users from organizations.

A **user** is a person.

An **organization** is a company workspace.

Example:

```txt
User:
  amanda@example.com

Organizations:
  Amanda Consulting Pte. Ltd.
  Client A Pte. Ltd.
  Client B Pte. Ltd.
```

The user may access multiple organizations.

But each organization’s accounting data must be isolated.

---

# 3. Clerk Organization vs Database Organization

GreyMatter Ledger uses Clerk for identity.

Clerk provides:

```txt
Clerk organization ID
Active organization context
Organization roles
```

The app also stores a local database organization row.

```txt
Clerk organization
  -> identity workspace

Database organization
  -> accounting tenant record
```

The local table is:

```txt
organizations
```

Important columns:

```txt
id
clerk_organization_id
name
slug
```

Most business records reference:

```txt
organizations.id
```

not the Clerk org ID directly.

---

# 4. Organization Sync Pattern

The bridge between Clerk and Postgres is:

```ts
getOrCreateCurrentOrganization()
```

Location:

```txt
services/organizations/get-or-create-organization.ts
```

The function:

1. Reads the active Clerk organization.
2. Looks for a matching local database organization.
3. Creates it if missing.
4. Returns the database organization.

Simplified flow:

```txt
Clerk orgId
  |
  v
organizations.clerk_organization_id
  |
  v
organizations.id
```

Future business records use:

```txt
organization_id = organizations.id
```

---

# 5. Never Trust Organization IDs from the Browser

A browser form can be modified.

A malicious user can change hidden inputs.

So do **not** trust organization IDs submitted from the client.

Bad:

```tsx
<input type="hidden" name="organizationId" value={organization.id} />
```

Then:

```ts
const organizationId = String(formData.get("organizationId"));
```

This is unsafe.

Good:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

The server decides the active organization from authenticated context.

---

# 6. Server-Side Organization Helpers

Important helpers:

```txt
lib/auth.ts
services/organizations/get-or-create-organization.ts
```

Common helpers:

```ts
getCurrentOrganizationContext()
getCurrentWorkspaceContext()
requireActiveOrganization()
getOrCreateCurrentOrganization()
requireCurrentDatabaseOrganization()
```

Use these in services and server actions.

---

# 7. Tenant-Scoped Tables

These tables are tenant-scoped and must include organization filtering:

```txt
accounts
customers
vendors
invoices
invoice_lines
customer_payments
bills
bill_lines
vendor_payments
journal_entries
journal_lines
bank_imports
bank_transactions
audit_logs
recurring_invoices
```

The key column is:

```txt
organization_id
```

---

# 8. Tenant-Safe Query Pattern

The safest query pattern is:

```ts
const organization = await requireCurrentDatabaseOrganization();

const rows = await db
  .select()
  .from(someTable)
  .where(eq(someTable.organizationId, organization.id));
```

For updates:

```ts
await db
  .update(someTable)
  .set({
    // fields
  })
  .where(
    and(
      eq(someTable.id, recordId),
      eq(someTable.organizationId, organization.id),
    ),
  );
```

For deletes, if you ever add them:

```ts
await db
  .delete(someTable)
  .where(
    and(
      eq(someTable.id, recordId),
      eq(someTable.organizationId, organization.id),
    ),
  );
```

Never update by ID alone.

Bad:

```ts
await db
  .update(invoices)
  .set({ status: "paid" })
  .where(eq(invoices.id, invoiceId));
```

Good:

```ts
await db
  .update(invoices)
  .set({ status: "paid" })
  .where(
    and(
      eq(invoices.id, invoiceId),
      eq(invoices.organizationId, organization.id),
    ),
  );
```

---

# 9. Tenant-Safe Detail Page Pattern

For detail pages such as:

```txt
/invoices/[invoiceId]
/bills/[billId]
```

Always query with both:

```txt
record ID
organization ID
```

Example:

```ts
const [invoice] = await db
  .select()
  .from(invoices)
  .where(
    and(
      eq(invoices.id, invoiceId),
      eq(invoices.organizationId, organization.id),
    ),
  )
  .limit(1);
```

If not found:

```ts
return null;
```

Then page should call:

```ts
notFound();
```

This avoids leaking whether another organization’s record exists.

---

# 10. Do Not Leak Cross-Tenant Existence

A subtle security issue:

```txt
User opens /invoices/some-other-company-invoice-id
```

Bad response:

```txt
This invoice belongs to another organization.
```

Better response:

```txt
Invoice not found.
```

Do not reveal that the record exists.

In multi-tenant apps, “not found” is often safer than “forbidden” for cross-tenant records.

---

# 11. Tenant-Safe Join Pattern

When joining tables, ensure the main record is organization-scoped.

Example:

```ts
await db
  .select({
    invoiceNumber: invoices.invoiceNumber,
    customerName: customers.name,
  })
  .from(invoices)
  .innerJoin(customers, eq(invoices.customerId, customers.id))
  .where(eq(invoices.organizationId, organization.id));
```

Even better, when appropriate, also ensure joined records belong to the same organization:

```ts
.where(
  and(
    eq(invoices.organizationId, organization.id),
    eq(customers.organizationId, organization.id),
  ),
);
```

This reduces risk if bad data somehow enters the database.

---

# 12. Tenant-Safe Journal Posting

Journal posting is especially sensitive.

The journal engine must verify:

```txt
All accounts belong to active organization.
All lines use active organization.
The journal entry belongs to active organization.
```

Bad:

```ts
// Trusting arbitrary account IDs without checking ownership
await postJournalEntry({
  lines: [
    {
      accountId: accountIdFromForm,
      debitCents: 10000,
    },
  ],
});
```

Good:

The engine loads accounts using:

```ts
eq(accounts.organizationId, organization.id)
```

Then rejects accounts not found in the active organization.

This prevents:

```txt
Company A posting to Company B’s accounts.
```

---

# 13. Tenant-Safe Reports

Reports must be scoped by organization.

Ledger reports should filter:

```txt
journal_lines.organization_id
```

Example:

```ts
.where(eq(journalLines.organizationId, organization.id))
```

If a report reads source documents, such as aging reports, it should filter:

```txt
invoices.organization_id
bills.organization_id
```

Bad report query:

```ts
await db
  .select()
  .from(journalLines);
```

Good:

```ts
await db
  .select()
  .from(journalLines)
  .where(eq(journalLines.organizationId, organization.id));
```

---

# 14. Tenant-Safe Bank Workflows

Bank imports are sensitive.

A bank transaction row includes:

```txt
organization_id
bank_import_id
category_account_id
journal_entry_id
```

Categorization must verify:

```txt
Bank transaction belongs to active organization.
Category account belongs to active organization.
Category account is active.
```

Posting must verify:

```txt
Bank transaction belongs to active organization.
Bank account belongs to active organization.
Category account belongs to active organization.
```

Reconciliation must verify:

```txt
Bank transaction belongs to active organization.
Transaction is posted.
Transaction is not already reconciled.
```

---

# 15. Tenant-Safe Audit Logs

Audit logs are organization-scoped.

Query:

```ts
await db
  .select()
  .from(auditLogs)
  .where(eq(auditLogs.organizationId, organization.id));
```

Do not show all audit logs to normal users.

Audit logs may reveal sensitive operational information.

---

# 16. Authentication Checklist

Authentication answers:

```txt
Who is signed in?
```

GreyMatter Ledger uses Clerk.

Checklist:

```txt
ClerkProvider wraps the app.
Sign-in page works.
Sign-up page works.
Protected routes require auth.
proxy.ts protects internal routes.
UserButton works.
currentUser() works on server.
```

Important route protection file for Next.js 16:

```txt
proxy.ts
```

Not:

```txt
middleware.ts
```

Protected route examples:

```txt
/dashboard
/accounts
/customers
/vendors
/invoices
/bills
/payments
/reports
/bank
/settings
/onboarding
```

---

# 17. Authorization Checklist

Authorization answers:

```txt
What is the signed-in user allowed to do?
```

GreyMatter Ledger uses Clerk organization roles.

Important helper:

```txt
lib/authorization.ts
```

Key functions:

```ts
getCurrentOrganizationRole()
isCurrentUserOrganizationAdmin()
requireOrganizationAdmin()
```

Admin-only actions include:

```txt
View audit logs
Reverse journal entries
```

Server-side enforcement is required.

Do not rely only on hiding UI buttons.

---

# 18. Server-Side Authorization Pattern

Bad:

```tsx
{isAdmin ? <button>Reverse</button> : null}
```

This only hides the button.

A malicious user could still call the server action.

Good:

```ts
export async function reverseJournalEntryForCurrentOrganization(params) {
  await requireOrganizationAdmin();

  // perform reversal
}
```

The server action or service must enforce permission.

UI hiding is optional convenience.

Server enforcement is mandatory.

---

# 19. Admin Feature Checklist

For every admin-only feature, verify:

```txt
UI indicates admin-only nature.
Server checks admin role.
Non-admin request fails.
Friendly error is shown when practical.
Audit log records the action.
```

Examples:

```txt
Audit log page
Journal reversal action
```

---

# 20. Data Mutation Checklist

Before adding any create/update/delete operation, ask:

```txt
Does this operation require an active organization?
Does it use organization from server context?
Does it verify the target record belongs to active organization?
Does it verify related records belong to active organization?
Does it require admin permission?
Does it write an audit log?
Does it revalidate affected pages?
```

---

# 21. Sensitive Operations

These operations are especially sensitive:

```txt
Posting journal entries
Reversing journal entries
Recording payments
Posting bank transactions
Reconciling bank transactions
Changing account active status
Viewing audit logs
Changing organization settings
```

They should have stronger validation and authorization.

---

# 22. Audit Logging Checklist

Important actions should write audit logs.

Examples:

```txt
account.created
account.status_changed
customer.created
vendor.created
invoice.created
bill.created
customer_payment.recorded
vendor_payment.recorded
journal_entry.reversed
```

Audit logs should include:

```txt
organization_id
actor_user_id
action
entity_type
entity_id
message
metadata_json
created_at
```

Avoid storing secrets or unnecessary sensitive personal data in audit logs.

---

# 23. Environment Variable Security

Never commit:

```txt
.env.local
.env
production database URLs
Clerk secret keys
Inngest signing keys
```

Safe to commit:

```txt
.env.example
```

Public variables may start with:

```txt
NEXT_PUBLIC_
```

Secret variables must not.

Examples of secrets:

```txt
DATABASE_URL
CLERK_SECRET_KEY
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

---

# 24. Database Security Checklist

Production database checklist:

```txt
Use SSL.
Use strong credentials.
Do not share production DATABASE_URL.
Use separate development and production databases.
Restrict Neon dashboard access.
Review migrations before applying.
Back up before risky migrations.
Rotate credentials if leaked.
```

---

# 25. Clerk Security Checklist

Clerk checklist:

```txt
Production instance configured.
Allowed origins include production domain.
Redirect URLs are correct.
Organizations enabled.
Roles reviewed.
Admin users verified.
Unused auth providers disabled.
Session settings reviewed.
```

---

# 26. Inngest Security Checklist

Inngest checklist:

```txt
Production endpoint configured.
Signing key configured.
Event key configured.
Endpoint URL is correct.
Failed jobs are monitored.
Sensitive data is not unnecessarily included in event payloads.
```

Do not send secrets in event data.

---

# 27. File Upload Security Checklist

The bank CSV import feature accepts files.

Checklist:

```txt
Accept only expected file types.
Limit file size in production.
Validate headers.
Validate rows.
Reject invalid dates.
Reject invalid amounts.
Do not trust file names.
Do not execute uploaded content.
```

Current tutorial parser expects:

```txt
date,description,amount
```

---

# 28. Common Multi-Tenancy Bugs

## Bug 1 — Listing All Records

Bad:

```ts
await db.select().from(customers);
```

Fix:

```ts
.where(eq(customers.organizationId, organization.id))
```

---

## Bug 2 — Updating by ID Only

Bad:

```ts
await db
  .update(bills)
  .set({ status: "paid" })
  .where(eq(bills.id, billId));
```

Fix:

```ts
.where(
  and(
    eq(bills.id, billId),
    eq(bills.organizationId, organization.id),
  ),
);
```

---

## Bug 3 — Related Record Belongs to Another Organization

Example:

```txt
Invoice belongs to Company A.
Customer belongs to Company B.
```

Prevent by checking both:

```ts
eq(invoices.organizationId, organization.id)
eq(customers.organizationId, organization.id)
```

---

## Bug 4 — Report Missing Organization Filter

Bad:

```ts
from(journalLines)
```

without:

```ts
where(eq(journalLines.organizationId, organization.id))
```

Reports can accidentally mix companies.

---

## Bug 5 — Trusting Hidden Form Fields

Bad:

```tsx
<input type="hidden" name="organizationId" value={organization.id} />
```

Fix:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

---

# 29. Safe Service Template

Use this structure for sensitive services:

```ts
export async function doSomethingForCurrentOrganization(input: Input) {
  const organization = await requireCurrentDatabaseOrganization();

  // Optional:
  // await requireOrganizationAdmin();

  // Validate input shape.

  // Load target record with organization filter.
  const [record] = await db
    .select()
    .from(someTable)
    .where(
      and(
        eq(someTable.id, input.recordId),
        eq(someTable.organizationId, organization.id),
      ),
    )
    .limit(1);

  if (!record) {
    return {
      ok: false,
      error: "Record not found.",
    };
  }

  // Perform mutation with organization-safe where clause.

  // Write audit log if important.

  return {
    ok: true,
  };
}
```

---

# 30. Safe Page Query Template

For pages:

```ts
export default async function SomePage() {
  const organization = await getOrCreateCurrentOrganization();

  if (!organization) {
    return <NoOrganizationState />;
  }

  const rows = await db
    .select()
    .from(someTable)
    .where(eq(someTable.organizationId, organization.id));

  return <Page rows={rows} />;
}
```

---

# 31. Security Testing Checklist

Manually test:

```txt
Signed-out user cannot access protected routes.
Signed-in user can access own organization data.
Switching organizations changes visible data.
Company A invoice does not show in Company B.
Company A bill does not show in Company B.
Company A report does not include Company B data.
Non-admin cannot view audit log.
Non-admin cannot reverse journal entries.
Posted/reconciled bank transactions cannot be modified casually.
```

---

# 32. SQL Tenant Isolation Checks

## Count Records by Organization

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

---

## Check Orphan Invoice Customers

This should return zero rows:

```sql
select
  i.id as invoice_id,
  i.organization_id as invoice_org,
  c.organization_id as customer_org
from invoices i
join customers c
  on c.id = i.customer_id
where i.organization_id <> c.organization_id;
```

---

## Check Orphan Bill Vendors

This should return zero rows:

```sql
select
  b.id as bill_id,
  b.organization_id as bill_org,
  v.organization_id as vendor_org
from bills b
join vendors v
  on v.id = b.vendor_id
where b.organization_id <> v.organization_id;
```

---

## Check Journal Line Organization Mismatch

This should return zero rows:

```sql
select
  jl.id as journal_line_id,
  jl.organization_id as line_org,
  je.organization_id as entry_org
from journal_lines jl
join journal_entries je
  on je.id = jl.journal_entry_id
where jl.organization_id <> je.organization_id;
```

---

## Check Journal Line Account Organization Mismatch

This should return zero rows:

```sql
select
  jl.id as journal_line_id,
  jl.organization_id as line_org,
  a.organization_id as account_org
from journal_lines jl
join accounts a
  on a.id = jl.account_id
where jl.organization_id <> a.organization_id;
```

---

# 33. Production Launch Security Checklist

Before production launch:

```txt
.env.local not committed
Vercel env vars configured
Production Clerk keys used
Production Neon database separate from dev
Migrations applied
Admin users verified
Non-admin behavior tested
Audit log access tested
Journal reversal permission tested
Cross-tenant data isolation tested
Database backup plan reviewed
Inngest signing keys configured
File upload limits considered
```

---

# 34. Final Multi-Tenancy Rules to Remember

If you remember only five rules, remember these:

```txt
1. Never trust organization IDs from the browser.
2. Always derive organization from server-side auth context.
3. Always filter tenant data by organization_id.
4. Always verify related records belong to the same organization.
5. Always enforce sensitive permissions on the server.
```

These rules protect the core promise of a SaaS accounting system:

```txt
Every company’s data stays private, accurate, and isolated.
```
