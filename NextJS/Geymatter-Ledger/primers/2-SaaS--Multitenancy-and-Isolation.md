# Primer 2 — SaaS Multi-Tenancy and Organization Isolation

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, technical founders, product managers, QA engineers  
**Goal:** Explain how multi-tenancy works in GreyMatter Ledger and why organization isolation is critical  

---

# 1. Why This Primer Matters

GreyMatter Ledger is not a single-company desktop accounting tool.

It is designed like a SaaS application.

That means one deployed app can serve many companies.

Example:

```txt
GreyMatter Ledger App
  |
  |-- Merlion Creative Pte. Ltd.
  |-- Orchard Studio Pte. Ltd.
  |-- CloudStack Consulting Pte. Ltd.
  |-- Client A Pte. Ltd.
```

Each company’s data must stay isolated.

If Merlion Creative can see Orchard Studio’s invoices, that is a serious security failure.

If one company’s reports include another company’s data, the accounting is unusable.

The core rule is:

```txt
Every organization-scoped record must be filtered by organization_id.
```

---

# 2. What Is Multi-Tenancy?

Multi-tenancy means:

```txt
One application serves multiple customers or organizations.
```

Each customer or organization is called a tenant.

In GreyMatter Ledger:

```txt
Tenant = Organization = Company workspace
```

A useful analogy:

```txt
The app is an office building.
Each organization is a locked office.
Users are people with access cards.
Data is paperwork inside each office.
```

People may access more than one office.

But paperwork from one office must not appear in another.

---

# 3. User vs Organization

A user is a person.

An organization is a company workspace.

Example:

```txt
User:
  amanda@example.com

Organizations:
  Merlion Creative Pte. Ltd.
  Orchard Studio Pte. Ltd.
  Client A Pte. Ltd.
```

Amanda can switch between organizations.

When Amanda is working in Merlion Creative, she should only see Merlion Creative’s data.

When she switches to Orchard Studio, she should only see Orchard Studio’s data.

---

# 4. Why User ID Alone Is Not Enough

A beginner mistake is attaching all records to the user.

Example:

```txt
invoices.user_id = amanda
```

This fails when one user works with multiple companies.

Amanda may create invoices for:

```txt
Merlion Creative
Orchard Studio
Client A
```

If all invoices belong only to Amanda, the app cannot separate company records properly.

Correct approach:

```txt
invoices.organization_id = active company
```

Optionally, records may also track who created them, but ownership belongs to the organization.

---

# 5. Clerk Organizations

GreyMatter Ledger uses Clerk for authentication and organization management.

Clerk provides:

```txt
Users
Sessions
Organizations
Organization membership
Organization roles
```

When a user selects a company workspace, Clerk gives the app an active organization context.

Important Clerk values:

```txt
orgId
orgSlug
orgRole
```

Example:

```txt
orgId: org_abc123
orgSlug: merlion-creative
orgRole: org:admin
```

---

# 6. Local Database Organizations

GreyMatter Ledger also stores organizations in its own database.

Table:

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

Why store a local organization row?

Because accounting records need database foreign keys.

Example:

```txt
accounts.organization_id -> organizations.id
invoices.organization_id -> organizations.id
journal_entries.organization_id -> organizations.id
```

This creates a clean relational model.

---

# 7. Clerk Organization vs Database Organization

There are two related but different IDs:

```txt
Clerk organization ID
Database organization ID
```

Example:

```txt
Clerk organization ID:
org_abc123

Database organization ID:
6f4a9b4e-4fd9-42fd-a147-d4a4e7e90111
```

The database table maps them:

```txt
organizations.clerk_organization_id = org_abc123
organizations.id = 6f4a9...
```

Most business records use:

```txt
organizations.id
```

as:

```txt
organization_id
```

---

# 8. Organization Sync Flow

When a user selects an organization:

```txt
User selects Clerk organization
  |
  v
App reads Clerk orgId
  |
  v
App checks local organizations table
  |
  |-- found      -> use existing database organization
  |
  |-- not found  -> create local organization row
```

The key function is:

```ts
getOrCreateCurrentOrganization()
```

Location:

```txt
services/organizations/get-or-create-organization.ts
```

This function bridges identity and accounting data.

---

# 9. The Tenant Boundary

The tenant boundary is:

```txt
organization_id
```

Every company-scoped table must include it.

Examples:

```txt
accounts.organization_id
customers.organization_id
vendors.organization_id
invoices.organization_id
bills.organization_id
journal_entries.organization_id
journal_lines.organization_id
bank_transactions.organization_id
audit_logs.organization_id
```

This is how the database knows which company owns each record.

---

# 10. The Most Important Query Rule

Always filter by active organization.

Bad:

```ts
await db.select().from(invoices);
```

This may return invoices from all companies.

Good:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organization.id));
```

This returns only invoices for the active company.

---

# 11. Loading a Single Record Safely

A common mistake is loading a record by ID only.

Bad:

```ts
const [invoice] = await db
  .select()
  .from(invoices)
  .where(eq(invoices.id, invoiceId));
```

Why is this dangerous?

Because if a user somehow gets another company’s invoice ID, the query may return it.

Good:

```ts
const [invoice] = await db
  .select()
  .from(invoices)
  .where(
    and(
      eq(invoices.id, invoiceId),
      eq(invoices.organizationId, organization.id),
    ),
  );
```

This checks both:

```txt
Record ID
Organization ID
```

---

# 12. Updating a Record Safely

Bad:

```ts
await db
  .update(bills)
  .set({ status: "paid" })
  .where(eq(bills.id, billId));
```

Good:

```ts
await db
  .update(bills)
  .set({ status: "paid" })
  .where(
    and(
      eq(bills.id, billId),
      eq(bills.organizationId, organization.id),
    ),
  );
```

Never update tenant data by ID alone.

---

# 13. Deleting a Record Safely

GreyMatter Ledger avoids casual deletion of accounting records.

But if a future feature deletes tenant data, it must include organization scope.

Bad:

```ts
await db.delete(customers).where(eq(customers.id, customerId));
```

Good:

```ts
await db
  .delete(customers)
  .where(
    and(
      eq(customers.id, customerId),
      eq(customers.organizationId, organization.id),
    ),
  );
```

---

# 14. Never Trust Organization IDs from Forms

The browser is not trusted.

Bad:

```tsx
<input type="hidden" name="organizationId" value={organization.id} />
```

Then:

```ts
const organizationId = String(formData.get("organizationId"));
```

A malicious user can change the hidden field.

Good:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

The server determines the active organization.

---

# 15. Server-Side Organization Helpers

Important helpers:

```txt
lib/auth.ts
services/organizations/get-or-create-organization.ts
```

Common functions:

```ts
getCurrentOrganizationContext()
getCurrentWorkspaceContext()
getOrCreateCurrentOrganization()
requireCurrentDatabaseOrganization()
```

Use:

```ts
requireCurrentDatabaseOrganization()
```

inside services that create or update tenant data.

---

# 16. Safe Service Pattern

A safe organization-scoped service looks like this:

```ts
export async function createCustomerForCurrentOrganization(input: ContactInput) {
  const organization = await requireCurrentDatabaseOrganization();

  // validate input

  const [created] = await db
    .insert(customers)
    .values({
      organizationId: organization.id,
      name: input.name,
    })
    .returning();

  return created;
}
```

Notice:

```txt
organizationId comes from server context
```

not from the form.

---

# 17. Related Record Ownership

When creating records that reference other records, verify ownership.

Example:

```txt
Invoice references customer.
```

Before creating invoice, check:

```ts
const [customer] = await db
  .select()
  .from(customers)
  .where(
    and(
      eq(customers.id, input.customerId),
      eq(customers.organizationId, organization.id),
    ),
  )
  .limit(1);

if (!customer) {
  throw new Error("Customer does not exist for active organization.");
}
```

Without this, a user might create an invoice in Company A using a customer from Company B.

---

# 18. Journal Account Ownership

Journal entries are especially sensitive.

Every journal line references an account.

The journal engine must verify:

```txt
The account exists.
The account belongs to active organization.
The account is active.
```

This prevents cross-company ledger contamination.

---

# 19. Reports Must Be Tenant-Scoped

Reports are dangerous if they forget tenant filters.

Bad:

```ts
await db
  .select()
  .from(journalLines);
```

This can mix all companies.

Good:

```ts
await db
  .select()
  .from(journalLines)
  .where(eq(journalLines.organizationId, organization.id));
```

Financial reports must never mix organizations.

---

# 20. Detail Pages Should Return Not Found

If a user opens another organization’s record, prefer:

```txt
Not found
```

instead of:

```txt
This belongs to another organization
```

Why?

Because the second message leaks that the record exists.

Good behavior:

```txt
/invoices/other-company-invoice-id -> Not found
```

---

# 21. Authentication Is Not Authorization

Authentication means:

```txt
The user is signed in.
```

Authorization means:

```txt
The user is allowed to do this action.
```

A signed-in user may not be allowed to:

```txt
View audit logs
Reverse journal entries
Manage admin settings
```

---

# 22. Roles

Clerk organization roles may include:

```txt
org:admin
org:member
```

GreyMatter Ledger uses role helpers in:

```txt
lib/authorization.ts
```

Important function:

```ts
requireOrganizationAdmin()
```

---

# 23. Server-Side Authorization

Do not rely only on hiding buttons.

Bad:

```tsx
{isAdmin ? <button>Reverse</button> : null}
```

This hides the button but does not secure the server action.

Good:

```ts
await requireOrganizationAdmin();
```

inside the server-side service.

---

# 24. Admin-Only Examples

In GreyMatter Ledger, admin-only actions include:

```txt
Viewing audit logs
Reversing journal entries
```

These actions should enforce admin permissions on the server.

---

# 25. Background Jobs and Tenancy

Background jobs are tricky.

A normal page request has:

```txt
current user
current organization
```

A scheduled background job may not.

Example:

```txt
Daily overdue invoice reminders
```

A scheduled job should not rely on:

```ts
requireCurrentDatabaseOrganization()
```

because there may be no active user session.

Better production pattern:

```txt
Load organizations explicitly.
For each organization, query data by organization.id.
Use system actor.
Write audit logs as system.
```

---

# 26. Diagnostic Pages

GreyMatter Ledger includes diagnostic pages such as:

```txt
/settings/database
/settings/database/journal
/settings/auth-status
/settings/audit-log
```

These are useful for development and administration.

In production, consider restricting diagnostics to admins.

---

# 27. Cross-Tenant Testing

Manual test:

1. Create Organization A.
2. Create invoice in Organization A.
3. Copy invoice URL.
4. Switch to Organization B.
5. Open copied URL.

Expected:

```txt
Invoice not found.
```

Repeat for:

```txt
Bills
Customers
Vendors
Reports
Bank transactions
Audit logs
```

---

# 28. SQL Checks for Tenant Integrity

## Invoice Customer Mismatch

Should return zero rows:

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

## Bill Vendor Mismatch

Should return zero rows:

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

## Journal Line Account Mismatch

Should return zero rows:

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

# 29. Common Multi-Tenancy Bugs

## Bug 1 — Query Without Organization Filter

```ts
await db.select().from(invoices);
```

Fix:

```ts
.where(eq(invoices.organizationId, organization.id))
```

---

## Bug 2 — Update by ID Only

```ts
await db
  .update(invoices)
  .set({ status: "paid" })
  .where(eq(invoices.id, invoiceId));
```

Fix:

```ts
.where(
  and(
    eq(invoices.id, invoiceId),
    eq(invoices.organizationId, organization.id),
  ),
);
```

---

## Bug 3 — Trusting Client Organization ID

```ts
const organizationId = formData.get("organizationId");
```

Fix:

```ts
const organization = await requireCurrentDatabaseOrganization();
```

---

## Bug 4 — Background Job Without Tenant Scope

```ts
await db.select().from(invoices);
```

Fix:

```ts
for (const organization of organizations) {
  await db
    .select()
    .from(invoices)
    .where(eq(invoices.organizationId, organization.id));
}
```

---

# 30. Security Checklist for New Features

When adding a feature, ask:

```txt
Does this data belong to an organization?
Does the table include organization_id?
Do reads filter by organization_id?
Do updates filter by organization_id?
Do related records belong to the same organization?
Does the action require admin permission?
Does the action need an audit log?
Does the action post to the journal?
Does the action affect reports?
```

If yes, enforce it in the service layer.

---

# 31. Recommended Architecture Rule

Use this naming convention for tenant-scoped services:

```txt
createInvoiceForCurrentOrganization
recordCustomerPaymentForCurrentOrganization
postBankTransactionForCurrentOrganization
```

This makes intent clear.

The service should not accept arbitrary organization IDs from the browser.

---

# 32. Final Mental Model

For GreyMatter Ledger:

```txt
Clerk authenticates the user.
Clerk identifies the active organization.
The app syncs the organization to the database.
Business records belong to the database organization.
Every query is scoped by organization_id.
Sensitive permissions are checked on the server.
```

The three most important boundaries are:

```txt
Authentication boundary:
  Who is signed in?

Authorization boundary:
  What can they do?

Tenant boundary:
  Which organization data can they access?
```

A secure SaaS accounting system must protect all three.

---

# 33. Final Rule

If you remember only one thing:

```txt
Never query organization-owned data without organization_id.
```

If you remember two things:

```txt
Never trust organization_id from the browser.
```

If you remember three things:

```txt
Enforce permissions on the server.
```

These rules keep GreyMatter Ledger safe.
