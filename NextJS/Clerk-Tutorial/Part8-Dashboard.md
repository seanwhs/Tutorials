# Part 8: Building a Styled Dashboard

Let's turn our placeholder dashboard into a real app shell: a top navigation bar with the `UserButton` (avatar + dropdown with sign-out), and a proper layout.

## 1. Create a dashboard layout

Create `src/app/dashboard/layout.tsx`:

```tsx
import Link from "next/link";
import { UserButton } from "@clerk/nextjs";

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
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>
      </nav>
      <main className="mx-auto max-w-5xl px-6 py-8">{children}</main>
    </div>
  );
}
```

`<UserButton />` is a prebuilt Clerk component: it renders the user's avatar and, when clicked, a dropdown with "Manage account" and "Sign out." The `afterSignOutUrl` prop tells it where to redirect once the user signs out.

## 2. Update the dashboard page itself

Replace `src/app/dashboard/page.tsx` with a version that assumes the layout now provides the nav:

```tsx
import { currentUser } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const user = await currentUser();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">
          Welcome back, {user?.firstName ?? "friend"} 👋
        </h1>
        <p className="mt-1 text-gray-600">Here's what's happening with your account.</p>
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
          <p className="text-sm text-gray-500">Joined</p>
          <p className="mt-1 font-medium text-gray-900">
            {user?.createdAt ? new Date(user.createdAt).toLocaleDateString() : "—"}
          </p>
        </div>
      </div>
    </div>
  );
}
```

Note `DashboardPage` remains `async` with `await currentUser()` — required by Next.js 16's conventions for reading dynamic/auth data server-side.

## 3. Create a settings page using the client-side `useUser()` hook

This demonstrates reading user data from a **Client Component** (as opposed to `currentUser()`, which only works server-side). Client Components and their hooks are unaffected by the server-side async API changes in Next.js 16 — `useUser()` works exactly as before.

Create `src/app/dashboard/settings/page.tsx`:

```tsx
"use client";

import { useUser } from "@clerk/nextjs";

export default function SettingsPage() {
  const { isLoaded, isSignedIn, user } = useUser();

  if (!isLoaded) {
    return <p className="text-gray-500">Loading...</p>;
  }

  if (!isSignedIn) {
    // Shouldn't happen since middleware protects this route, but good practice
    return <p className="text-gray-500">You must be signed in.</p>;
  }

  return (
    <div className="max-w-md space-y-4">
      <h1 className="text-2xl font-bold text-gray-900">Settings</h1>
      <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
        <p className="text-sm text-gray-500">First name</p>
        <p className="font-medium text-gray-900">{user.firstName}</p>
        <p className="mt-4 text-sm text-gray-500">Last name</p>
        <p className="font-medium text-gray-900">{user.lastName}</p>
        <p className="mt-4 text-sm text-gray-500">Primary email</p>
        <p className="font-medium text-gray-900">
          {user.primaryEmailAddress?.emailAddress}
        </p>
      </div>
      <p className="text-sm text-gray-500">
        To change your password or profile picture, click your avatar in the top-right
        corner and choose "Manage account."
      </p>
    </div>
  );
}
```

`useUser()` is the client-side equivalent of `currentUser()`. It returns `{ isLoaded, isSignedIn, user }` — you must check `isLoaded` first (Clerk needs a moment to initialize on the client), then `isSignedIn`, before trusting `user`.

## 4. Test it

1. Make sure you're signed in, then visit `/dashboard`. You should see the nav bar with your avatar, three stat cards, and working "Overview"/"Settings" links.
2. Click "Settings" — confirm your name/email render correctly.
3. Click your avatar (top right) — confirm the dropdown shows "Manage account" and "Sign out," and that sign-out actually works and redirects you to `/`.
4. Click "Manage account" — Clerk opens a full account management modal (change password, add email, upload avatar, etc.) — all built in, zero code from us.

## 5. Commit

```bash
git add .
git commit -m "Build styled dashboard with UserButton and settings page"
```

## Checkpoint

- [ ] Dashboard has a nav bar with logo, links, and `UserButton`
- [ ] Overview page shows user stats in styled cards
- [ ] Settings page reads user data client-side via `useUser()`
- [ ] Sign-out works and redirects to homepage
- [ ] "Manage account" modal opens and functions

## Troubleshooting

**`useUser` is not a function / import error.**
It comes from `@clerk/nextjs` (client-safe exports), not `@clerk/nextjs/server`. Also confirm the file starts with `"use client";` as its very first line — hooks only work in Client Components.

**Settings page flashes "Loading..." forever.**
`isLoaded` never becomes true if `ClerkProvider` isn't wrapping the app (check Part 5's `layout.tsx` change is still in place), or if there's a network issue reaching Clerk's frontend API — check the browser console for failed requests.

**`UserButton` renders as a tiny broken image icon.**
Almost always a transient network hiccup loading the avatar — refresh. If it persists, check you don't have an ad blocker or privacy extension blocking Clerk's image CDN domain.

**I want more control over what's in the `UserButton` dropdown.**
`<UserButton>` accepts a `<UserButton.MenuItems>` child with custom `<UserButton.Link>`/`<UserButton.Action>` items for adding your own links — out of scope for this tutorial, but see Appendix D for docs links.

Next up: Part 9, where we ditch the prebuilt forms and build a fully custom sign-in/sign-up UI using Clerk's headless hooks, styled entirely with our own Tailwind markup.
