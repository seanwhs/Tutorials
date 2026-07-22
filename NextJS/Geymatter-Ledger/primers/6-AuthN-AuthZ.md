# Primer 6 — Authentication vs Authorization

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, product managers, QA engineers, security reviewers  
**Goal:** Explain the difference between authentication and authorization, and how GreyMatter Ledger uses both  

---

# 1. Why This Primer Matters

Authentication and authorization are often confused.

They sound similar, but they answer different questions.

Authentication asks:

```txt
Who are you?
```

Authorization asks:

```txt
What are you allowed to do?
```

In GreyMatter Ledger, both are essential.

Why?

Because accounting software contains sensitive business data.

A user should not be able to:

```txt
View another company’s invoices
Reverse journal entries without permission
View audit logs without admin role
Post to another organization’s accounts
```

Authentication proves identity.

Authorization enforces permissions.

---

# 2. Simple Analogy

Imagine an office building.

Authentication:

```txt
You show your ID at the front desk.
The security guard confirms you are Amanda.
```

Authorization:

```txt
Your access card only opens certain doors.
You can enter your company’s office.
You cannot enter another company’s office.
Only admins can enter the records room.
```

In software:

```txt
Authentication = sign in
Authorization = permission checks
```

---

# 3. Authentication in GreyMatter Ledger

GreyMatter Ledger uses Clerk for authentication.

Clerk handles:

```txt
Sign up
Sign in
Sign out
Sessions
User profile
User identity
```

Important files:

```txt
app/layout.tsx
app/sign-in/[[...sign-in]]/page.tsx
app/sign-up/[[...sign-up]]/page.tsx
components/auth-controls.tsx
lib/auth.ts
proxy.ts
```

---

# 4. Authentication Flow

A typical authentication flow:

```txt
User opens protected route
  |
  v
proxy.ts checks Clerk session
  |
  |-- no session
  |     redirect to sign-in
  |
  |-- valid session
        allow route
```

Example protected route:

```txt
/dashboard
```

If signed out:

```txt
/dashboard -> /sign-in
```

If signed in:

```txt
/dashboard loads
```

---

# 5. Public Routes

Public routes can be visited without signing in.

Examples:

```txt
/
 /sign-in
 /sign-up
 /design
```

The landing page is public.

Sign-in and sign-up pages are public.

---

# 6. Protected Routes

Most app routes are protected.

Examples:

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

These require a signed-in user.

---

# 7. Next.js 16 Route Protection

GreyMatter Ledger targets Next.js 16.

Route protection uses:

```txt
proxy.ts
```

Not:

```txt
middleware.ts
```

The proxy uses Clerk helpers to protect internal app routes.

Conceptually:

```ts
if (isProtectedRoute(request)) {
  await auth.protect();
}
```

---

# 8. Server-Side User Context

The app can read the signed-in user on the server.

Helper:

```ts
getCurrentUserProfile()
```

Location:

```txt
lib/auth.ts
```

Returns:

```ts
{
  id: string;
  displayName: string;
  primaryEmail: string | null;
  imageUrl: string;
}
```

This is useful for:

```txt
Dashboard greeting
Audit logs
Posted by user ID
Admin diagnostics
```

---

# 9. Organizations and Authentication

A user can belong to multiple organizations.

Clerk manages organization membership.

Example:

```txt
User: amanda@example.com

Organizations:
  Merlion Creative Pte. Ltd.
  Orchard Studio Pte. Ltd.
```

Authentication tells us:

```txt
Amanda is signed in.
```

Organization context tells us:

```txt
Amanda is currently working in Merlion Creative.
```

---

# 10. Authorization in GreyMatter Ledger

Authorization determines what a signed-in user may do.

Examples:

```txt
Can this user view the audit log?
Can this user reverse a journal entry?
Can this user access this organization’s invoice?
Can this user post to this account?
```

Authorization is enforced through:

```txt
Organization-scoped database queries
Role checks
Server-side service validation
```

---

# 11. Organization-Based Authorization

Most authorization in GreyMatter Ledger starts with organization isolation.

A user can only access data for the active organization.

Example:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organization.id));
```

This ensures:

```txt
Only invoices for the active company are returned.
```

---

# 12. Role-Based Authorization

Some actions require specific roles.

GreyMatter Ledger uses admin checks for sensitive operations.

Admin-only examples:

```txt
View audit logs
Reverse journal entries
```

Role helper file:

```txt
lib/authorization.ts
```

Important helpers:

```ts
getCurrentOrganizationRole()
isCurrentUserOrganizationAdmin()
requireOrganizationAdmin()
```

---

# 13. Clerk Organization Roles

Clerk organization roles may look like:

```txt
org:admin
org:member
```

An admin can perform sensitive organization-level actions.

A member may perform normal workflows but should not access admin-only controls.

---

# 14. `requireOrganizationAdmin()`

The key admin enforcement helper is:

```ts
await requireOrganizationAdmin();
```

If the user is not an admin, it throws:

```ts
AuthorizationError
```

Use it inside server-side services or actions.

Example:

```ts
export async function reverseJournalEntryForCurrentOrganization(params) {
  await requireOrganizationAdmin();

  // perform reversal
}
```

---

# 15. UI Hiding Is Not Security

A common mistake is hiding a button and thinking the action is secure.

Bad:

```tsx
{isAdmin ? <button>Reverse</button> : null}
```

This only hides the button.

A malicious user might still call the server action.

Good:

```ts
await requireOrganizationAdmin();
```

inside the server-side function.

The UI can hide buttons for convenience, but the server must enforce security.

---

# 16. Tenant Authorization vs Role Authorization

GreyMatter Ledger uses two major authorization patterns.

---

## Tenant Authorization

Checks whether the record belongs to the active organization.

Example:

```ts
and(
  eq(invoices.id, invoiceId),
  eq(invoices.organizationId, organization.id),
)
```

Question answered:

```txt
Does this record belong to the selected company?
```

---

## Role Authorization

Checks whether the user has permission to perform an action.

Example:

```ts
await requireOrganizationAdmin();
```

Question answered:

```txt
Is this user allowed to perform this sensitive action?
```

Both are necessary.

---

# 17. Example: Viewing an Invoice

To view an invoice, the user must:

```txt
Be signed in.
Have an active organization.
Request an invoice belonging to that organization.
```

Query pattern:

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

If no invoice is found:

```txt
Show not found.
```

Do not reveal whether the invoice exists in another organization.

---

# 18. Example: Reversing a Journal Entry

To reverse a journal entry, the user must:

```txt
Be signed in.
Have an active organization.
Be organization admin.
Reverse an entry belonging to the active organization.
Entry must not already be reversed.
```

Checks:

```ts
await requireOrganizationAdmin();

const [entry] = await db
  .select()
  .from(journalEntries)
  .where(
    and(
      eq(journalEntries.id, journalEntryId),
      eq(journalEntries.organizationId, organization.id),
    ),
  );
```

This combines role authorization and tenant authorization.

---

# 19. Example: Viewing Audit Logs

Audit logs are sensitive.

A user must:

```txt
Be signed in.
Have an active organization.
Be organization admin.
```

The page calls:

```ts
await requireOrganizationAdmin();
```

Then lists logs scoped by:

```txt
organization_id
```

---

# 20. Authentication Errors

Authentication errors usually mean:

```txt
User is not signed in.
Session missing.
Clerk keys missing.
Route not protected correctly.
```

Examples:

```txt
Redirect to /sign-in
Clerk publishable key missing
Clerk secret key missing
```

---

# 21. Authorization Errors

Authorization errors usually mean:

```txt
User is signed in but lacks permission.
Record belongs to another organization.
No active organization selected.
```

Examples:

```txt
Only organization admins can perform this action.
Invoice not found.
No active organization selected.
```

---

# 22. Safe Error Messages

For cross-tenant records, prefer:

```txt
Not found.
```

Instead of:

```txt
This invoice belongs to another organization.
```

Why?

Because the second message leaks that the record exists.

---

# 23. Authentication Checklist

For authentication, verify:

```txt
ClerkProvider wraps app
Sign-in page works
Sign-up page works
UserButton works
proxy.ts protects app routes
Signed-out users cannot access protected pages
currentUser() works server-side
```

---

# 24. Authorization Checklist

For authorization, verify:

```txt
Organization context is required for tenant data
Queries filter by organization_id
Detail pages check record ID and organization ID
Admin-only actions call requireOrganizationAdmin()
Non-admin users are blocked from admin features
Audit logs are admin-only
Journal reversals are admin-only
```

---

# 25. Common Mistakes

## Mistake 1 — Thinking Sign-In Is Enough

Bad assumption:

```txt
User is signed in, so they can access any invoice ID.
```

Correct:

```txt
User must access only invoices in active organization.
```

---

## Mistake 2 — Hiding Buttons Without Server Checks

Bad:

```tsx
{isAdmin && <ReverseButton />}
```

without server enforcement.

Correct:

```ts
await requireOrganizationAdmin();
```

inside the service.

---

## Mistake 3 — Loading Records by ID Only

Bad:

```ts
where(eq(invoices.id, invoiceId))
```

Correct:

```ts
where(
  and(
    eq(invoices.id, invoiceId),
    eq(invoices.organizationId, organization.id),
  )
)
```

---

## Mistake 4 — Trusting Form Fields for Permission

Bad:

```ts
const role = formData.get("role");
```

Correct:

```ts
const { orgRole } = await auth();
```

---

# 26. Manual Test Scenarios

## Scenario 1 — Signed-Out Access

Steps:

1. Sign out.
2. Open `/dashboard`.

Expected:

```txt
Redirect to sign-in.
```

---

## Scenario 2 — Cross-Organization Invoice

Steps:

1. Create invoice in Organization A.
2. Copy invoice URL.
3. Switch to Organization B.
4. Open copied URL.

Expected:

```txt
Invoice not found.
```

---

## Scenario 3 — Non-Admin Audit Log

Steps:

1. Sign in as org member.
2. Open `/settings/audit-log`.

Expected:

```txt
Access restricted.
```

---

## Scenario 4 — Non-Admin Reversal

Steps:

1. Sign in as org member.
2. Try reversing a journal entry.

Expected:

```txt
Authorization error.
Entry not reversed.
```

---

# 27. Production Recommendations

For production, consider adding:

```txt
Viewer role
Accountant role
Approver role
Granular permissions
Admin audit event alerts
Access logs
Security headers
Rate limiting
Session policy review
```

Also consider a permission matrix.

Example:

| Feature | Admin | Member | Viewer |
|---|---:|---:|---:|
| View reports | Yes | Yes | Yes |
| Create invoice | Yes | Yes | No |
| Record payment | Yes | Yes | No |
| Reverse journal entry | Yes | No | No |
| View audit log | Yes | No | No |
| Manage organization | Yes | No | No |

---

# 28. Final Mental Model

Authentication:

```txt
Who is the user?
```

Authorization:

```txt
What can the user do?
```

Tenant isolation:

```txt
Which organization’s data can the user access?
```

In GreyMatter Ledger, safe access requires all three:

```txt
Signed in
Correct organization
Correct permission
```

The most important rule:

```txt
Never treat authentication alone as permission.
```
