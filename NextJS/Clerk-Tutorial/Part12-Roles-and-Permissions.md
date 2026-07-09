# Part 12: Roles & Permissions

Clerk Organizations come with two built-in roles out of the box: **admin** and **member**. In this part, we'll use a member's role to show/hide UI and to protect a server action so only admins can perform a sensitive operation.

## 1. Understand the default roles

- The user who creates an organization automatically becomes its **admin**.
- Anyone invited afterward defaults to **member**, unless the inviting admin picks a different role during invitation.
- Admins can: invite/remove members, change roles, rename/delete the organization, manage domains.
- Members can: view the organization, leave it, and do whatever your own app's custom logic allows.

You can also define **custom roles** (e.g. "billing_manager") in the Clerk Dashboard under Organizations → Roles, but the built-in admin/member pair is enough for this tutorial.

## 2. Show role-gated UI on the client

Update `src/app/dashboard/page.tsx` to add an admin-only section, reading `orgRole` server-side (simplest approach, avoids extra client-side loading states):

```tsx
import { currentUser, auth } from "@clerk/nextjs/server";
import Link from "next/link";

export default async function DashboardPage() {
  const user = await currentUser();
  const { orgId, orgSlug, orgRole } = await auth();
  const isAdmin = orgRole === "org:admin";

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Welcome back, {user?.firstName ?? "friend"} 👋
        </h1>
        <p className="mt-1 text-gray-600">
          {orgId
            ? `You're working in "${orgSlug}" as ${isAdmin ? "an admin" : "a member"}.`
            : "You're in your personal workspace."}
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-gray-500">Email</p>
          <p className="mt-1 font-medium text-gray-900">
            {user?.emailAddresses[0]?.emailAddress}
          </p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-gray-500">User ID</p>
          <p className="mt-1 truncate font-mono text-xs text-gray-900">{user?.id}</p>
        </div>
        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-gray-500">Active Organization</p>
          <p className="mt-1 font-medium text-gray-900">{orgSlug ?? "None (personal)"}</p>
        </div>
      </div>

      {isAdmin && orgId && (
        <div className="rounded-lg border border-yellow-200 bg-yellow-50 p-6">
          <h2 className="font-semibold text-yellow-900">Admin Tools</h2>
          <p className="mt-1 text-sm text-yellow-800">
            Only admins can see this section.
          </p>
          <Link
            href="/dashboard/organization"
            className="mt-3 inline-block rounded-md bg-yellow-600 px-4 py-2 text-sm font-medium text-white hover:bg-yellow-700"
          >
            Manage Organization
          </Link>
        </div>
      )}
    </div>
  );
}
```

Clerk's role strings are namespaced like `org:admin` and `org:member` (the `org:` prefix distinguishes organization-level roles from any application-level roles you might add elsewhere) — always compare against the exact string, e.g. `orgRole === "org:admin"`.

## 3. Test the role gate visually

1. As the admin (the account that created the organization), visit `/dashboard` — confirm you see the yellow "Admin Tools" box.
2. Sign in as the member account you invited in Part 11 (or invite a fresh second test account now if you skipped that step), switch to the same organization, and visit `/dashboard` — confirm the admin box does **not** appear.

## 4. Protect a Server Action by role (the important part)

Client-side hiding is just UX — it is **not** security, since anyone can inspect network requests or call your server actions directly. The real protection must happen server-side. Let's build a simple example: an admin-only server action that "renames" the organization's internal display label (a placeholder for any sensitive action in your real app, e.g. deleting data, changing billing).

Create `src/app/dashboard/organization/actions.ts`:

```ts
"use server";

import { auth } from "@clerk/nextjs/server";

export async function adminOnlyAction(newLabel: string) {
  const { orgId, orgRole } = await auth();

  if (!orgId) {
    throw new Error("No active organization.");
  }

  if (orgRole !== "org:admin") {
    throw new Error("Only admins can perform this action.");
  }

  // In a real app, you'd write to your database here, scoped by orgId.
  console.log(`Admin action performed on org ${orgId}: set label to "${newLabel}"`);

  return { success: true, label: newLabel };
}
```

`auth()` is awaited here just like everywhere else in this series — this is a Server Action (marked with `"use server"`), and Next.js 16 requires the same async handling of dynamic/auth data in Server Actions as it does in Server Components. This is the pattern to remember: **every** sensitive Server Action or Route Handler must re-check `auth()` itself. Never trust that a button was hidden client-side as your only line of defense.

## 5. Wire it up with a small form

Update `src/app/dashboard/organization/page.tsx`:

```tsx
import { OrganizationProfile } from "@clerk/nextjs";
import { auth } from "@clerk/nextjs/server";
import { adminOnlyAction } from "./actions";

export default async function OrganizationPage() {
  const { orgRole } = await auth();
  const isAdmin = orgRole === "org:admin";

  async function handleSubmit(formData: FormData) {
    "use server";
    const label = formData.get("label") as string;
    await adminOnlyAction(label);
  }

  return (
    <div className="space-y-6">
      {isAdmin && (
        <form action={handleSubmit} className="flex gap-2 rounded-lg border border-gray-200 bg-white p-4">
          <input
            type="text"
            name="label"
            placeholder="New internal label"
            className="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm"
          />
          <button
            type="submit"
            className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Save (admin only)
          </button>
        </form>
      )}
      <div className="flex justify-center">
        <OrganizationProfile routing="hash" />
      </div>
    </div>
  );
}
```

## 6. Test the server-side protection

1. As admin, submit the form — check your terminal (where `npm run dev` is running) for the `console.log` output confirming success.
2. As a member (non-admin), the form won't even render — but to prove the *server* check works (not just the UI hiding), you could temporarily comment out the `{isAdmin && (...)}` wrapper, submit as a member, and confirm you get a thrown error instead of it succeeding. Remember to restore the wrapper afterward.

## 7. Commit

```bash
git add .
git commit -m "Add role-gated UI and server-side admin-only action"
```

## Checkpoint

- [ ] Admin sees an "Admin Tools" box on the dashboard; members don't
- [ ] `adminOnlyAction` Server Action re-checks `orgRole` itself, independent of the UI
- [ ] You verified (by temporarily bypassing the UI check) that the server rejects non-admins
- [ ] You understand: client-side role checks are UX only; server-side checks are the real security boundary, and both rely on properly awaited async Clerk calls

## Troubleshooting

**`orgRole` is `undefined` even though I'm the admin.**
Confirm you actually have an *active* organization selected via the switcher — `orgRole` is only populated in the context of an active org, not for personal workspace.

**Both admin and member see the Admin Tools box.**
Double check the exact string comparison `orgRole === "org:admin"` — a common typo is comparing against `"admin"` without the `org:` prefix, which will always be false.

**The Server Action throws but I don't see the error anywhere in the UI.**
Server Actions called from a plain `<form action={...}>` that throw will surface as an unhandled error boundary in Next.js (you may see a generic error overlay in development). For production-quality error handling, wrap the action call in a try/catch and return a structured `{ error: string }` result instead of throwing, then render that in the UI — a good exercise once you're comfortable with the basics shown here.

**I want custom roles beyond admin/member (e.g. "billing_manager").**
Define them in Clerk Dashboard → Organizations → Roles, assign granular Permissions to each custom role, and check `has({ permission: "org:billing:manage" })` (available from `auth()`) instead of comparing raw role strings — this is Clerk's more scalable permissions system for larger apps, mentioned here for awareness; see Appendix D for docs links.

Next up: Part 13, where we sync every new Clerk user into our own database using webhooks.
