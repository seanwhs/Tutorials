# Permissions Matrix

**Product:** GreyMatter Ledger  
**Document type:** Permissions Matrix  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Product owners, developers, QA engineers, security reviewers, administrators  
**Scope:** Role-based access control for organization-scoped application features  

---

# 1. Purpose

This document defines recommended permissions for GreyMatter Ledger roles.

It answers:

```txt
Who can view what?
Who can create records?
Who can post accounting entries?
Who can reverse entries?
Who can view audit logs?
Who can manage organization settings?
```

GreyMatter Ledger currently uses Clerk organization roles.

The tutorial implementation includes admin checks for:

```txt
Audit log access
Journal entry reversal
```

This document expands the intended permission model for future production hardening.

---

# 2. Current Role Model

Current implemented roles are based on Clerk organization roles.

Common Clerk roles:

```txt
org:admin
org:member
```

The current helper treats the following as admin:

```txt
org:admin
admin
```

Implemented helper:

```txt
lib/authorization.ts
```

Important functions:

```ts
getCurrentOrganizationRole()
isCurrentUserOrganizationAdmin()
requireOrganizationAdmin()
```

---

# 3. Recommended Future Role Model

For a production accounting system, consider these roles:

```txt
Owner
Admin
Accountant
Bookkeeper
Member
Viewer
```

---

## 3.1 Owner

Highest organization-level authority.

Can:

```txt
Manage billing
Manage organization settings
Manage users and roles
Perform all accounting actions
Access audit logs
```

---

## 3.2 Admin

Operational administrator.

Can:

```txt
Manage accounting setup
Reverse journal entries
View audit logs
Manage accounts
Perform accounting workflows
```

---

## 3.3 Accountant

Accounting professional.

Can:

```txt
Review and post accounting records
Run reports
Reverse entries with permission
Review audit logs if granted
```

---

## 3.4 Bookkeeper

Operational finance user.

Can:

```txt
Create invoices
Create bills
Record payments
Import bank CSV
Categorize bank transactions
Run standard reports
```

Should not necessarily:

```txt
Reverse journal entries
View all audit logs
Manage roles
```

---

## 3.5 Member

General business user.

Can:

```txt
View dashboard
Create limited business records
View basic reports
```

Permissions may vary by organization policy.

---

## 3.6 Viewer

Read-only user.

Can:

```txt
View reports
View records
```

Cannot:

```txt
Create or modify financial records
Post to ledger
Reverse entries
View sensitive admin pages unless granted
```

---

# 4. Current Implemented Permissions

In the current tutorial implementation:

| Feature | `org:admin` | `org:member` |
|---|---:|---:|
| Sign in | Yes | Yes |
| View dashboard | Yes | Yes |
| Switch organizations | Yes | Yes |
| View accounts | Yes | Yes |
| Seed accounts | Yes | Yes |
| Create custom account | Yes | Yes |
| Create customer | Yes | Yes |
| Create vendor | Yes | Yes |
| Create invoice | Yes | Yes |
| Create bill | Yes | Yes |
| Record customer payment | Yes | Yes |
| Record vendor payment | Yes | Yes |
| Import bank CSV | Yes | Yes |
| Categorize bank transactions | Yes | Yes |
| Post bank transactions | Yes | Yes |
| Reconcile bank transactions | Yes | Yes |
| View reports | Yes | Yes |
| View audit log | Yes | No |
| Reverse journal entry | Yes | No |
| View admin settings | Yes | Yes, but shows not admin |

---

# 5. Recommended Production Permissions Matrix

The following table is a recommended future model.

Legend:

```txt
Y = Allowed
N = Not allowed
R = Restricted / configurable
```

---

## 5.1 Navigation and Read Access

| Feature | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| View dashboard | Y | Y | Y | Y | Y | Y |
| View accounts | Y | Y | Y | Y | R | Y |
| View customers | Y | Y | Y | Y | Y | Y |
| View vendors | Y | Y | Y | Y | Y | Y |
| View invoices | Y | Y | Y | Y | Y | Y |
| View bills | Y | Y | Y | Y | R | Y |
| View payments | Y | Y | Y | Y | R | Y |
| View reports | Y | Y | Y | Y | R | Y |
| View bank transactions | Y | Y | Y | Y | R | R |
| View audit logs | Y | Y | R | N | N | N |
| View organization settings | Y | Y | R | N | N | N |

---

## 5.2 Master Data Permissions

| Action | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| Seed chart of accounts | Y | Y | Y | R | N | N |
| Create account | Y | Y | Y | R | N | N |
| Deactivate account | Y | Y | Y | N | N | N |
| Reactivate account | Y | Y | Y | N | N | N |
| Create customer | Y | Y | Y | Y | R | N |
| Edit customer | Y | Y | Y | Y | R | N |
| Create vendor | Y | Y | Y | Y | R | N |
| Edit vendor | Y | Y | Y | Y | R | N |

---

## 5.3 Sales Workflow Permissions

| Action | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| Create invoice | Y | Y | Y | Y | R | N |
| View invoice detail | Y | Y | Y | Y | Y | Y |
| Void invoice | Y | Y | Y | R | N | N |
| Record customer payment | Y | Y | Y | Y | R | N |
| View AR Aging | Y | Y | Y | Y | R | Y |
| Manage recurring invoices | Y | Y | Y | R | N | N |

---

## 5.4 Purchase Workflow Permissions

| Action | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| Create bill | Y | Y | Y | Y | R | N |
| View bill detail | Y | Y | Y | Y | R | Y |
| Void bill | Y | Y | Y | R | N | N |
| Record vendor payment | Y | Y | Y | Y | R | N |
| View AP Aging | Y | Y | Y | Y | R | Y |

---

## 5.5 Ledger Permissions

| Action | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| View journal diagnostics | Y | Y | Y | R | N | R |
| Post manual journal entry | Y | Y | Y | N | N | N |
| Reverse journal entry | Y | Y | R | N | N | N |
| View ledger overview | Y | Y | Y | Y | R | Y |

---

## 5.6 Bank Workflow Permissions

| Action | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| Upload bank CSV | Y | Y | Y | Y | N | N |
| Categorize bank transaction | Y | Y | Y | Y | N | N |
| Post bank transaction | Y | Y | Y | R | N | N |
| Reconcile bank transaction | Y | Y | Y | R | N | N |
| View reconciliation | Y | Y | Y | Y | R | Y |

---

## 5.7 Report Permissions

| Report | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| Profit & Loss | Y | Y | Y | Y | R | Y |
| Balance Sheet | Y | Y | Y | Y | R | Y |
| GST F5-style | Y | Y | Y | R | N | R |
| AR Aging | Y | Y | Y | Y | R | Y |
| AP Aging | Y | Y | Y | Y | R | Y |
| CPF Estimate | Y | Y | Y | R | N | R |
| Corporate Tax Estimate | Y | Y | Y | R | N | R |
| Multi-Currency Reference | Y | Y | Y | Y | Y | Y |

---

## 5.8 Admin and Security Permissions

| Action | Owner | Admin | Accountant | Bookkeeper | Member | Viewer |
|---|---:|---:|---:|---:|---:|---:|
| Manage users | Y | Y | N | N | N | N |
| Manage roles | Y | Y | N | N | N | N |
| View audit logs | Y | Y | R | N | N | N |
| Manage organization settings | Y | Y | R | N | N | N |
| Configure background jobs | Y | Y | N | N | N | N |
| View database diagnostics | Y | Y | R | N | N | N |

---

# 6. Current Authorization Implementation

Current file:

```txt
lib/authorization.ts
```

Key helper:

```ts
export async function requireOrganizationAdmin(): Promise<void> {
  const isAdmin = await isCurrentUserOrganizationAdmin();

  if (!isAdmin) {
    throw new AuthorizationError(
      "Only organization admins can perform this action.",
    );
  }
}
```

Current admin check recognizes:

```txt
org:admin
admin
```

---

# 7. Recommended Permission Helper Design

For production, consider a more granular permission system.

Example permission names:

```txt
accounts:create
accounts:update
customers:create
vendors:create
invoices:create
invoices:void
bills:create
bills:void
payments:create
journal:reverse
journal:manual_post
reports:view
audit:view
bank:import
bank:post
bank:reconcile
settings:manage
users:manage
```

Then define role mappings:

```ts
const permissionsByRole = {
  owner: ["*"],
  admin: [
    "accounts:create",
    "accounts:update",
    "journal:reverse",
    "audit:view",
  ],
  bookkeeper: [
    "customers:create",
    "vendors:create",
    "invoices:create",
    "bills:create",
    "payments:create",
  ],
  viewer: ["reports:view"],
};
```

---

# 8. Suggested Future Authorization API

Example:

```ts
await requirePermission("journal:reverse");
```

Instead of:

```ts
await requireOrganizationAdmin();
```

This allows more flexible access.

Potential file:

```txt
lib/permissions.ts
```

Possible functions:

```ts
getCurrentUserPermissions()
hasPermission(permission)
requirePermission(permission)
```

---

# 9. Server-Side Enforcement Rule

All sensitive actions must be enforced on the server.

Bad:

```tsx
{isAdmin ? <ReverseButton /> : null}
```

This only hides the UI.

Good:

```ts
export async function reverseJournalEntryForCurrentOrganization(params) {
  await requireOrganizationAdmin();

  // continue reversal
}
```

UI permissions improve experience.

Server permissions provide security.

---

# 10. Route-Level vs Action-Level Permissions

## Route-Level Permissions

Useful for pages like:

```txt
/settings/audit-log
/settings/admin
```

Example:

```ts
await requireOrganizationAdmin();
```

inside the page.

---

## Action-Level Permissions

Required for mutations.

Examples:

```txt
Reverse journal entry
Void invoice
Post manual journal entry
Manage users
```

Even if route is hidden, the action must enforce permission.

---

# 11. Permission Testing

## Admin User

Admin should be able to:

```txt
View audit log
Reverse journal entry
Access admin settings
```

---

## Member User

Member should not be able to:

```txt
View audit log
Reverse journal entry
```

---

## Viewer User

Viewer should not be able to:

```txt
Create invoices
Create bills
Record payments
Post bank transactions
```

Future role.

---

# 12. Manual Test Cases

## RBAC-001 — Admin Can View Audit Log

Steps:

1. Sign in as organization admin.
2. Open:

```txt
/settings/audit-log
```

Expected:

```txt
Audit log loads.
```

---

## RBAC-002 — Member Cannot View Audit Log

Steps:

1. Sign in as organization member.
2. Open:

```txt
/settings/audit-log
```

Expected:

```txt
Access restricted.
```

---

## RBAC-003 — Admin Can Reverse Journal Entry

Steps:

1. Sign in as organization admin.
2. Open:

```txt
/settings/database/journal
```

3. Reverse eligible entry.

Expected:

```txt
Reversal succeeds.
Audit log written.
```

---

## RBAC-004 — Member Cannot Reverse Journal Entry

Steps:

1. Sign in as organization member.
2. Attempt reversal.

Expected:

```txt
Reversal fails.
No reversal entry created.
```

---

# 13. Audit Expectations by Permission

Sensitive permission actions should write audit logs.

Examples:

| Action | Audit Required |
|---|---:|
| Reverse journal entry | Yes |
| Void invoice | Yes |
| Void bill | Yes |
| Change account status | Yes |
| Record payment | Yes |
| Post bank transaction | Recommended |
| Reconcile bank transaction | Recommended |
| Manage roles | Yes |
| Change organization settings | Yes |

---

# 14. Permission-Related Risks

## Risk 1 — Overly Broad Member Access

If all members can post financial records, mistakes may increase.

Mitigation:

```txt
Introduce Bookkeeper and Viewer roles.
```

---

## Risk 2 — Admin-Only Action Missing Server Check

Mitigation:

```txt
Code review checklist.
Authorization tests.
```

---

## Risk 3 — Audit Logs Exposed to Members

Mitigation:

```txt
Admin-only audit route.
Server-side requireOrganizationAdmin().
```

---

## Risk 4 — Role String Mismatch

Clerk role strings may differ.

Mitigation:

```txt
Display current role in /settings/admin.
Adjust role helper as needed.
```

---

# 15. Future Permission Enhancements

Recommended:

```txt
Granular permissions
Viewer role
Bookkeeper role
Accountant role
Owner role
Approval workflows
Role management UI
Permission audit logs
Per-feature access controls
Read-only report access
Journal entry approval
Payment approval
Bank reconciliation approval
```

---

# 16. Final Permission Principles

The permission model should follow these rules:

```txt
1. Authenticate every internal user.
2. Scope every record by organization.
3. Enforce sensitive permissions on the server.
4. Prefer least privilege.
5. Audit important actions.
6. Do not rely only on UI hiding.
```

The minimum production rule:

```txt
Admin-only actions must call server-side authorization helpers.
```
