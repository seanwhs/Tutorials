# Phase 9 — Auditability and Permissions

# Part 31 — Role-Based Access Control: Admin Features

In Part 30, we added audit logs.

Now we add role-based access control, commonly called **RBAC**.

RBAC answers:

```txt
Is this user allowed to perform this action?
```

By the end of this part, you will have:

- Clerk organization role helpers
- Server-side admin enforcement
- Admin-only settings page
- Admin-only audit log access
- Admin-only reversal enforcement
- Beginner-friendly authorization patterns
- Verification flows for admin/member behavior

---

# 1. Understand Authentication vs Authorization

## The Target

We are adding authorization checks.

---

## The Concept

Authentication asks:

```txt
Who are you?
```

Authorization asks:

```txt
What are you allowed to do?
```

Example:

```txt
Authentication:
Amanda is signed in.

Authorization:
Amanda is an org admin, so she can reverse journal entries.
```

A helpful analogy:

```txt
Authentication = ID card
Authorization  = room permissions on the ID card
```

---

# 2. Create Authorization Helpers

## The Target

We are creating:

```txt
lib/authorization.ts
```

---

## The Concept

We do not want role checks scattered everywhere.

Instead, we centralize:

```ts
requireOrganizationAdmin()
```

This helper will check Clerk organization role.

Clerk role examples commonly look like:

```txt
org:admin
org:member
```

---

## The Implementation

Create:

```txt
lib/authorization.ts
```

Add:

```ts
// lib/authorization.ts

import { auth } from "@clerk/nextjs/server";

export class AuthorizationError extends Error {
  constructor(message = "You do not have permission to perform this action.") {
    super(message);
    this.name = "AuthorizationError";
  }
}

export function isAuthorizationError(
  error: unknown,
): error is AuthorizationError {
  return error instanceof AuthorizationError;
}

export async function getCurrentOrganizationRole(): Promise<string | null> {
  const { orgRole } = await auth();

  return orgRole ?? null;
}

export async function isCurrentUserOrganizationAdmin(): Promise<boolean> {
  const role = await getCurrentOrganizationRole();

  return role === "org:admin" || role === "admin";
}

export async function requireOrganizationAdmin(): Promise<void> {
  const isAdmin = await isCurrentUserOrganizationAdmin();

  if (!isAdmin) {
    throw new AuthorizationError(
      "Only organization admins can perform this action.",
    );
  }
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 3. Protect Journal Reversals with Admin Check

## The Target

We are updating:

```txt
services/journal/reverse-journal-entry.ts
```

---

## The Concept

Reversing a journal entry is powerful.

It affects reports and accounting history.

So only organization admins should be allowed to reverse entries.

---

## The Implementation

Open:

```txt
services/journal/reverse-journal-entry.ts
```

Import:

```ts
import { requireOrganizationAdmin } from "@/lib/authorization";
```

At the start of `reverseJournalEntryForCurrentOrganization()`, before requiring organization, add:

```ts
await requireOrganizationAdmin();
```

The top of the function should look like:

```ts
export async function reverseJournalEntryForCurrentOrganization(params: {
  journalEntryId: string;
  reason: string;
}): Promise<ReverseJournalEntryResult> {
  await requireOrganizationAdmin();

  const organization = await requireCurrentDatabaseOrganization();
  const { userId } = await auth();

  // existing code...
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Protect Audit Log Page with Admin Check

## The Target

We are updating:

```txt
app/settings/audit-log/page.tsx
```

---

## The Concept

Audit logs can reveal sensitive operational activity.

Only organization admins should view them.

---

## The Implementation

Open:

```txt
app/settings/audit-log/page.tsx
```

Import:

```ts
import { requireOrganizationAdmin } from "@/lib/authorization";
```

At the top of the page function, add:

```ts
await requireOrganizationAdmin();
```

So the function begins:

```tsx
export default async function AuditLogPage() {
  await requireOrganizationAdmin();

  const { organizationId, logs } = await listCurrentOrganizationAuditLogs();

  // existing code...
}
```

If a non-admin opens the page, this will throw an authorization error.

In a later refinement, we could create a polished forbidden page. For now, server enforcement is the priority.

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Create Admin Settings Page

## The Target

We are creating:

```txt
app/settings/admin/page.tsx
```

---

## The Concept

Admin pages should be separated from normal settings.

This page will confirm whether the current user has admin access.

---

## The Implementation

Create:

```bash
mkdir -p app/settings/admin
```

Create:

```txt
app/settings/admin/page.tsx
```

Add:

```tsx
// app/settings/admin/page.tsx

import Link from "next/link";
import { AppLayout } from "@/components/app-layout";
import {
  getCurrentOrganizationRole,
  isCurrentUserOrganizationAdmin,
} from "@/lib/authorization";

export const dynamic = "force-dynamic";

export default async function AdminSettingsPage() {
  const role = await getCurrentOrganizationRole();
  const isAdmin = await isCurrentUserOrganizationAdmin();

  return (
    <AppLayout
      title="Admin Settings"
      description="Review organization role and admin-only capabilities."
    >
      <div className="space-y-6">
        <section
          className={`rounded-2xl border p-6 shadow-sm ${
            isAdmin
              ? "border-emerald-200 bg-emerald-50"
              : "border-amber-200 bg-amber-50"
          }`}
        >
          <p
            className={`text-sm font-semibold uppercase tracking-[0.2em] ${
              isAdmin ? "text-emerald-700" : "text-amber-700"
            }`}
          >
            Role check
          </p>

          <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
            {isAdmin ? "You are an organization admin." : "You are not an admin."}
          </h2>

          <p className="mt-2 text-sm leading-6 text-slate-700">
            Current Clerk organization role:{" "}
            <span className="font-mono font-semibold">
              {role ?? "No organization role found"}
            </span>
          </p>
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          <Link
            href="/settings/audit-log"
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
              Admin feature
            </p>

            <h2 className="mt-3 text-lg font-semibold text-slate-950">
              Audit log
            </h2>

            <p className="mt-2 text-sm leading-6 text-slate-500">
              View operational activity for the active organization. Admin-only.
            </p>
          </Link>

          <Link
            href="/settings/database/journal"
            className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
          >
            <p className="text-sm font-semibold uppercase tracking-[0.2em] text-slate-500">
              Admin action
            </p>

            <h2 className="mt-3 text-lg font-semibold text-slate-950">
              Journal reversals
            </h2>

            <p className="mt-2 text-sm leading-6 text-slate-500">
              Reverse posted journal entries. Admin-only.
            </p>
          </Link>
        </section>
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
/settings/admin
```

You should see your current organization role.

---

# 6. Link Admin Settings

## The Target

We are updating:

```txt
app/settings/page.tsx
```

---

## The Implementation

Add this card to `settingsCards`:

```ts
{
  eyebrow: "Admin",
  title: "Admin settings",
  description:
    "Review organization role and access admin-only controls.",
  href: "/settings/admin",
},
```

---

## The Verification

Open:

```txt
/settings
```

You should see:

```txt
Admin settings
```

---

# 7. Create a Friendly Authorization Error Boundary

## The Target

We are creating:

```txt
app/settings/audit-log/error.tsx
```

---

## The Concept

If a non-admin tries to view audit logs, we should show a friendly message.

Error boundaries in Next.js catch errors thrown by pages in that route segment.

Because this is a Client Component, it starts with:

```tsx
"use client";
```

---

## The Implementation

Create:

```txt
app/settings/audit-log/error.tsx
```

Add:

```tsx
// app/settings/audit-log/error.tsx

"use client";

import Link from "next/link";

export default function AuditLogErrorPage({
  error,
}: {
  error: Error & { digest?: string };
}) {
  const isAuthorizationError =
    error.name === "AuthorizationError" ||
    error.message.toLowerCase().includes("permission") ||
    error.message.toLowerCase().includes("admin");

  return (
    <main className="min-h-screen bg-slate-50 px-6 py-16 text-slate-950">
      <section className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-600">
          {isAuthorizationError ? "Access restricted" : "Something went wrong"}
        </p>

        <h1 className="mt-3 text-2xl font-bold tracking-tight">
          {isAuthorizationError
            ? "Only organization admins can view the audit log."
            : "The audit log could not be loaded."}
        </h1>

        <p className="mt-3 text-sm leading-6 text-slate-500">
          {isAuthorizationError
            ? "Ask an organization admin to update your role if you need access."
            : error.message}
        </p>

        <Link
          href="/settings"
          className="mt-6 inline-flex rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
        >
          Back to settings
        </Link>
      </section>
    </main>
  );
}
```

---

## The Verification

If you can test with a non-admin organization member, open:

```txt
/settings/audit-log
```

They should see a friendly restricted message.

---

# 8. Update Reversal Action Error Handling

## The Target

We are updating:

```txt
app/settings/database/journal/actions.ts
```

---

## The Concept

If a non-admin tries reversal, the action should redirect with a friendly error.

It already catches result errors from the service.

But if `requireOrganizationAdmin()` throws before the service returns a result, we need to catch that inside the action.

---

## The Implementation

Open:

```txt
app/settings/database/journal/actions.ts
```

Replace the file with:

```ts
// app/settings/database/journal/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import {
  isAuthorizationError,
} from "@/lib/authorization";
import { reverseJournalEntryForCurrentOrganization } from "@/services/journal/reverse-journal-entry";

function getErrorMessage(error: unknown): string {
  if (isAuthorizationError(error)) {
    return error.message;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return "Unexpected error while reversing journal entry.";
}

export async function reverseJournalEntryAction(formData: FormData) {
  const journalEntryId = String(formData.get("journalEntryId") ?? "");
  const reason = String(formData.get("reason") ?? "");

  try {
    const result = await reverseJournalEntryForCurrentOrganization({
      journalEntryId,
      reason,
    });

    revalidatePath("/settings/database/journal");
    revalidatePath("/reports/ledger-overview");
    revalidatePath("/reports/profit-and-loss");
    revalidatePath("/reports/balance-sheet");
    revalidatePath("/reports/gst-f5");

    if (!result.ok) {
      redirect(
        `/settings/database/journal?reversalStatus=error&reversalMessage=${encodeURIComponent(
          result.error,
        )}`,
      );
    }

    redirect("/settings/database/journal?reversalStatus=reversed");
  } catch (error) {
    redirect(
      `/settings/database/journal?reversalStatus=error&reversalMessage=${encodeURIComponent(
        getErrorMessage(error),
      )}`,
    );
  }
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 9. Test Admin Behavior

## The Target

We are verifying admin-only features.

---

## The Implementation

As an organization admin:

1. Open:

```txt
/settings/admin
```

2. Confirm you see:

```txt
You are an organization admin.
```

3. Open:

```txt
/settings/audit-log
```

4. Confirm it loads.

5. Open:

```txt
/settings/database/journal
```

6. Try reversing an eligible journal entry.

---

## The Verification

Admin users should be able to:

```txt
View audit logs
Reverse journal entries
```

---

# 10. Optional Non-Admin Test

## The Target

We are testing non-admin behavior.

---

## The Implementation

In Clerk, invite or switch to a user with member role:

```txt
org:member
```

As that user:

1. Open:

```txt
/settings/admin
```

2. Confirm the page says:

```txt
You are not an admin.
```

3. Open:

```txt
/settings/audit-log
```

4. Try reversing an entry.

---

## The Verification

Non-admin users should not be able to:

```txt
View audit logs
Reverse journal entries
```

---

# 11. Run Full Project Check

## The Target

We are verifying everything still passes.

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should pass.

---

# 12. Commit RBAC

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add role based access control"
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

## Error: Admin check fails even though you own the organization

Check Clerk organization role.

Open:

```txt
/settings/admin
```

Look at:

```txt
Current Clerk organization role
```

If Clerk returns something different from `org:admin`, update `isCurrentUserOrganizationAdmin()` to include your role string.

---

## Error: Audit log page crashes without friendly UI

Make sure this file exists:

```txt
app/settings/audit-log/error.tsx
```

And starts with:

```tsx
"use client";
```

---

## Error: Reversal action throws instead of redirecting

Make sure `app/settings/database/journal/actions.ts` wraps the service call in `try/catch`.

---

# Phase 9 Reference — RBAC

## Authentication

Who is signed in?

---

## Authorization

What are they allowed to do?

---

## RBAC

Role-based access control.

Common roles:

```txt
Admin
Member
Viewer
```

---

## Server-Side Enforcement

Never rely only on hiding buttons.

Always check permissions on the server before performing sensitive actions.

---

# Part 31 Completion Checklist

You are ready for Part 32 if:

- [ ] `lib/authorization.ts` exists
- [ ] Admin role helper works
- [ ] Journal reversals require admin
- [ ] Audit log page requires admin
- [ ] `/settings/admin` exists
- [ ] `/settings` links to admin settings
- [ ] Friendly audit log authorization error page exists
- [ ] Reversal action handles authorization errors
- [ ] Admin users can access admin features
- [ ] Non-admin users are blocked from admin features
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
