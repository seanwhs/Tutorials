# Part 11: Organizations (Multi-Tenancy) with Clerk

Many real apps aren't single-user — they're team-based ("workspaces," "companies," "projects"). Clerk calls these **Organizations**, and they come with built-in invitations, membership management, and roles. Let's add them.

## 1. Enable Organizations in the Clerk Dashboard

1. Go to your Clerk Dashboard → **Organizations** (left sidebar).
2. Toggle **Enable organizations**.
3. Leave the default settings (any user can create an organization) for now — we'll touch roles in Part 12.

## 2. Add an Organization Switcher to the dashboard nav

Update `src/app/dashboard/layout.tsx`:

```tsx
import Link from "next/link";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="border-b border-gray-200 bg-white px-6 py-4">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <Link href="/dashboard" className="text-lg font-bold text-blue-600">
            Acme Boards
          </Link>
          <div className="flex items-center gap-4">
            <Link href="/dashboard" className="text-sm text-gray-600 hover:text-gray-900">
              Overview
            </Link>
            <Link href="/dashboard/settings" className="text-sm text-gray-600 hover:text-gray-900">
              Settings
            </Link>
            <OrganizationSwitcher
              afterCreateOrganizationUrl="/dashboard"
              afterSelectOrganizationUrl="/dashboard"
              afterLeaveOrganizationUrl="/dashboard"
              hidePersonal={false}
            />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>
      </nav>
      <main className="mx-auto max-w-5xl px-6 py-8">{children}</main>
    </div>
  );
}
```

`<OrganizationSwitcher />` is a fully prebuilt dropdown that lets users: switch between organizations they belong to, create a new organization, and (from within it) manage members/invitations. `hidePersonal={false}` keeps the option to work in a "Personal account" context alongside organizations — set it to `true` if your app should always require an organization context.

## 3. Test creating an organization

1. Visit `/dashboard` while signed in.
2. Click the `OrganizationSwitcher` — choose **Create organization**.
3. Give it a name, e.g. "Acme Inc." Confirm it's created and now shown as the active context.
4. Click the switcher again — you should see options to view organization members, invite people, and switch back to "Personal account."

## 4. Read the active organization on the server

Update `src/app/dashboard/page.tsx` to show which organization (if any) is active:

```tsx
import { currentUser } from "@clerk/nextjs/server";
import { auth } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const user = await currentUser();
  const { orgId, orgSlug, orgRole } = await auth();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Welcome back, {user?.firstName ?? "friend"} 👋
        </h1>
        <p className="mt-1 text-gray-600">
          {orgId
            ? `You're currently working in organization "${orgSlug}" as ${orgRole}.`
            : "You're currently in your personal workspace."}
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
    </div>
  );
}
```

Both `currentUser()` and `auth()` are awaited here, consistent with Next.js 16's async dynamic API conventions covered in Part 7. `auth()` (from `@clerk/nextjs/server`) returns `orgId`, `orgSlug`, and `orgRole` in addition to `userId` when an organization is the active context — this is exactly what you'd use to scope database queries per-tenant (e.g. `WHERE organization_id = orgId`) in a real multi-tenant app.

## 5. Add an Organization Profile page

Create `src/app/dashboard/organization/page.tsx` so members can manage their org (invite people, see the member list, rename it):

```tsx
import { OrganizationProfile } from "@clerk/nextjs";

export default function OrganizationPage() {
  return (
    <div className="flex justify-center">
      <OrganizationProfile routing="hash" />
    </div>
  );
}
```

Add a link to it in the nav (`src/app/dashboard/layout.tsx`), alongside "Overview" and "Settings":

```tsx
<Link href="/dashboard/organization" className="text-sm text-gray-600 hover:text-gray-900">
  Organization
</Link>
```

`<OrganizationProfile />` is the organization-equivalent of the account management modal `UserButton` opens — full UI for renaming the org, uploading a logo, managing members and their roles, and handling pending invitations, all built in.

## 6. Test inviting a member (optional but recommended)

1. Visit `/dashboard/organization`.
2. Go to the "Members" tab, then "Invite."
3. Enter a second email address you control (e.g. a personal Gmail alias, or a `+test` alias like `you+test@gmail.com` if your provider supports it).
4. Send the invite, then check that inbox and accept it (you may need to sign up as a "new" user first, since it's a different email).
5. Confirm the second account shows up in the organization's member list.

## 7. Commit

```bash
git add .
git commit -m "Add Organizations: switcher, profile, and org-aware dashboard"
```

## Checkpoint

- [ ] Organizations enabled in Clerk Dashboard
- [ ] `OrganizationSwitcher` visible and functional in the dashboard nav
- [ ] Created a test organization and can switch between it and personal workspace
- [ ] `/dashboard/organization` shows the full `OrganizationProfile` UI
- [ ] Dashboard overview page shows the active org's slug and your role in it
- [ ] (Optional) successfully invited and accepted a second member

## Troubleshooting

**`OrganizationSwitcher` doesn't appear or errors out.**
Confirm Organizations is actually enabled in the Clerk Dashboard (step 1) — the component silently renders nothing useful if the feature is off for your application instance.

**`orgId` is always `null` even after creating an org.**
Make sure you've actually selected/activated the organization via the switcher (creating one usually auto-activates it, but switching back to "Personal account" sets `orgId` back to null — that's correct behavior, not a bug).

**Invitation email never arrives.**
Check spam as usual. Also confirm the invited email isn't already tied to an existing account in a way that conflicts — for clean testing, use a genuinely fresh email address.

**I want every page under `/dashboard` to require an active organization (no personal workspace allowed).**
Set `hidePersonal={true}` on `OrganizationSwitcher`, and additionally check `orgId` in your middleware or page-level logic, redirecting to an "select or create an organization" page if it's null. This is a common real-world SaaS pattern — feel free to extend the tutorial's middleware from Part 7 to add this check as a stretch exercise.

**Can non-admin members remove other members or delete the organization?**
No — Clerk's organization roles restrict destructive actions to admins by default, and `OrganizationProfile` respects this automatically. Part 12 goes deeper into roles and how to enforce your own custom permission checks beyond Clerk's defaults.

Next up: Part 12, where we use organization roles to control what admins vs. members can see and do.
