## Part 5: Organizations = Companies

Goal: enable Clerk Organizations, build an org switcher, and require an active organization before using the dashboard.

Prerequisite: Parts 1-4 completed (including Part 4's `src/proxy.ts`, Next.js 16's renamed middleware file).

---

### 1. Turn on Organizations in Clerk

1. Go to https://dashboard.clerk.com, select your `qb-clone` application
2. In the left sidebar find **Organizations** (may be under "Configure")
3. Toggle it **on**
4. Leave default settings (anyone can create an organization)

### 2. Update the homepage with an org switcher

Open `src/app/page.tsx`, replace its entire contents with:

```tsx
import {
  SignedIn,
  SignedOut,
  SignInButton,
  SignUpButton,
  UserButton,
  OrganizationSwitcher,
} from "@clerk/nextjs";
import { auth } from "@clerk/nextjs/server";
import Link from "next/link";

export default async function Home() {
  const { orgId } = await auth();

  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>

      <SignedOut>
        <p>You are not signed in.</p>
        <SignInButton />
        <SignUpButton />
      </SignedOut>

      <SignedIn>
        <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
          <UserButton />
          <OrganizationSwitcher
            afterCreateOrganizationUrl="/dashboard"
            afterSelectOrganizationUrl="/dashboard"
          />
        </div>

        {orgId ? (
          <p style={{ marginTop: "1rem" }}>
            <Link href="/dashboard">Go to your Dashboard -&gt;</Link>
          </p>
        ) : (
          <p style={{ marginTop: "1rem" }}>
            Create or select a company above to get started.
          </p>
        )}
      </SignedIn>
    </main>
  );
}
```

Note: `auth()` returns a Promise in the Clerk SDK versions that support Next.js 16, so this Server Component is `async` and awaits it — the same pattern you'll see throughout the rest of this course any time server code needs to read the current request/session.

Save, refresh http://localhost:3000 while signed in. Click the organization switcher dropdown, choose "Create organization," name it "Joe's Landscaping," and create it. The switcher should now show that name, and a "Go to your Dashboard" link should appear.

### 3. Require an active organization on the dashboard

Open `src/app/dashboard/page.tsx`, replace its entire contents with:

```tsx
import { auth, currentUser } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const { orgId } = await auth();
  const user = await currentUser();

  if (!orgId) {
    redirect("/");
  }

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Dashboard</h1>
      <p>Welcome, {user?.firstName ?? "friend"}!</p>
      <p>You&apos;re currently working in organization: {orgId}</p>
    </main>
  );
}
```

Test: open an incognito/private browser window, sign in with a fresh account (or your existing one before creating an org), and confirm visiting `/dashboard` without an active org redirects you to `/`. Then create/select an org and revisit `/dashboard` — you should see it now, with the raw organization ID printed (starts with `org_`).

### 4. Commit

```
git add .
git commit -m "Add Clerk Organizations: org switcher, require active org for dashboard"
```

---

### ✅ Checkpoint

- [ ] Organizations enabled in Clerk dashboard
- [ ] `<OrganizationSwitcher>` visible and usable on the homepage
- [ ] At least one organization created
- [ ] `/dashboard` shows the org ID when an org is active, and redirects to `/` when it's not

---

### Troubleshooting

**`<OrganizationSwitcher>` doesn't appear at all**
Confirm you actually toggled Organizations ON in the Clerk dashboard (step 1) — if it's off, the component silently renders nothing. Refresh the Clerk dashboard page to confirm the toggle saved, then refresh your app.

**Clicking "Create organization" does nothing / errors out**
Check your browser console (F12 or right-click -> Inspect -> Console tab) for an error message. Usually caused by an outdated `@clerk/nextjs` version — run `npm install @clerk/nextjs@latest` and restart the dev server (Clerk ships frequent updates to track new Next.js versions, including Next.js 16's `proxy.ts` support from Part 4).

**`orgId` is always null even after creating an organization**
Make sure you actually selected the organization as "active" in the switcher after creating it (Clerk sometimes creates it without automatically activating it as the current context) — click the switcher and explicitly select the organization from the list.

**Redirect loop: `/dashboard` keeps bouncing back to `/` and `/` doesn't show the switcher**
This usually means you're not actually signed in — confirm `<SignedIn>` content (the switcher, avatar) is visible on `/` first. If you only see `<SignedOut>` content, sign in again from Part 4's sign-in button. If it still loops, double check Part 4's `src/proxy.ts` file exists (not `src/middleware.ts`) and there isn't a leftover copy of the old file confusing route protection.

**TypeScript complains about `You're` apostrophe in JSX**
This is why the code above uses `You&apos;re` instead of a literal apostrophe — React/JSX treats a raw `'` in text content as a potential syntax issue in strict lint setups. Always use `&apos;` for apostrophes inside JSX text.

**Organization ID shown is different from what you expected, or you seem to be in the wrong company**
Click the `<OrganizationSwitcher>` again and explicitly select the correct organization — it's easy to have multiple test organizations if you clicked "Create" more than once while experimenting.

**TypeScript error saying `orgId`/`userId` don't exist on the awaited result, or `auth()` looks like it returns a non-Promise**
Confirm your installed `@clerk/nextjs` version is current (`npm install @clerk/nextjs@latest`) — the `await auth()` pattern used throughout this course requires a version of the Clerk SDK that supports Next.js 16's async request APIs.
