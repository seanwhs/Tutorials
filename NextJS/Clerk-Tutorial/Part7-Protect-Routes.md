# Part 7: Protecting Routes & Reading the Current User

Right now, `clerkMiddleware()` runs on every request but doesn't block anything. Let's actually protect `/dashboard` (and any future routes under it) so only signed-in users can see them.

## A quick but important note on Next.js 16 async APIs

Since Next.js 15, "dynamic" data-reading functions/values — `headers()`, `cookies()`, route `params`, `searchParams` — became **asynchronous** and must be `await`ed. Next.js 16 continues this fully. Clerk's own server functions, `auth()` and `currentUser()`, are also async and must be awaited, as you'll see below. Forgetting `await` is the single most common mistake in this part, so pay close attention to it.

## 1. Update the middleware to protect routes

Replace `src/middleware.ts` with:

```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

What's happening:
- `createRouteMatcher([...])` builds a matcher function from an array of path patterns. `(.*)` means "this segment and anything after it," so `/dashboard(.*)` matches `/dashboard`, `/dashboard/settings`, `/dashboard/anything`.
- Inside the middleware callback, `auth.protect()` checks if the request is signed in. If not, it automatically redirects to your sign-in page (using the `NEXT_PUBLIC_CLERK_SIGN_IN_URL` env var). If signed in, the request proceeds normally.
- Note the callback itself is `async` and `auth.protect()` is `await`ed — this matches Next.js 16's async-first conventions.

## 2. Create a placeholder dashboard page

Create `src/app/dashboard/page.tsx`:

```tsx
import { currentUser } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const user = await currentUser();

  return (
    <main className="min-h-screen bg-gray-50 px-4 py-12">
      <div className="mx-auto max-w-2xl rounded-lg bg-white p-8 shadow-md">
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-2 text-gray-600">
          Welcome, {user?.firstName ?? "friend"}! Your email is{" "}
          {user?.emailAddresses[0]?.emailAddress}.
        </p>
      </div>
    </main>
  );
}
```

`currentUser()` is a server-side function from `@clerk/nextjs/server` that fetches the full user object for the currently authenticated request — only usable in Server Components, Route Handlers, or Server Actions (never in client components). Notice `DashboardPage` itself is declared `async` and `currentUser()` is awaited — required both by Clerk's API design and by Next.js 16's async conventions for Server Components that read dynamic data.

## 3. Test protection is working

1. **Sign out** if you're currently signed in (we'll add a proper sign-out button in Part 8 — for now, go to the Clerk Dashboard → Users, or simply clear cookies for localhost, or use an incognito window).
2. Visit http://localhost:3000/dashboard directly while signed out. You should be redirected to `/sign-in`.
3. Sign in with your test account. You should land on `/dashboard` and see your welcome message with your first name and email.
4. Visit `/dashboard/anything` (a route that doesn't even exist) while signed out — you should still be redirected to sign-in, because the middleware runs before Next.js even tries to resolve the route. (It'll 404 after sign-in since the page doesn't exist, but the protection itself is confirmed.)

## 4. Understanding `auth()` vs `currentUser()`

You'll see both used in Clerk code:

- **`auth()`** (from `@clerk/nextjs/server`) — fast, lightweight, reads the session JWT already verified by middleware. Gives you `userId`, `orgId`, `sessionId`, etc. Use this when you just need IDs/booleans (e.g. "is someone logged in? what's their user ID?"). It's async — always `await auth()`.
- **`currentUser()`** — makes an API call to fetch the *full* user object (name, email, image, metadata). Slightly slower since it's a network call. Use this when you need actual profile data to display. Also async — always `await currentUser()`.

Example using `auth()` instead, if you only needed the ID:

```tsx
import { auth } from "@clerk/nextjs/server";

export default async function SomePage() {
  const { userId } = await auth();
  if (!userId) {
    // this shouldn't happen here since middleware already protects this route,
    // but it's good practice in shared/reusable code
    return <p>Not signed in.</p>;
  }
  return <p>Your user ID is {userId}</p>;
}
```

## 5. Commit

```bash
git add .
git commit -m "Protect /dashboard route and read current user"
```

## Checkpoint

- [ ] `/dashboard` redirects unauthenticated visitors to `/sign-in`
- [ ] `/dashboard` shows the signed-in user's first name and email when logged in
- [ ] You understand the difference between `auth()` and `currentUser()`
- [ ] You understand that both are async and must always be awaited, consistent with Next.js 16's dynamic API conventions

## Troubleshooting

**Visiting `/dashboard` while signed in shows a blank page or error about `user` being null.**
Double-check `currentUser()` is `await`ed and that `DashboardPage` is declared `async function`. Forgetting `async`/`await` is the single most common mistake here, and Next.js 16 is strict about this for any function reading dynamic/auth data.

**TypeScript or a runtime error mentions a Promise where a value was expected (e.g. trying to read `.firstName` directly off the result of `currentUser()` without awaiting).**
This is exactly the async-API mistake described above — add the missing `await`.

**I'm redirected to sign-in even though I just signed in.**
Session cookies can occasionally lag by a second right after sign-up in local dev. Refresh the page. If it persists, check that `ClerkProvider` wraps your whole app (Part 5) — without it, the client-side session can get out of sync with the server.

**`auth.protect()` doesn't seem to do anything / route isn't protected.**
Confirm `isProtectedRoute` matches your actual path. `/dashboard(.*)` matches `/dashboard` and everything under it, but if you protect e.g. `/app(.*)` instead by mistake, `/dashboard` won't be covered. Also confirm the `config.matcher` at the bottom still includes your route (it should, via the broad default pattern) — middleware never runs at all on paths excluded by `matcher`.

**TypeScript complains `user` is possibly `null`.**
`currentUser()` returns `null` if nobody is signed in, which is correct behavior for a general-purpose function — TypeScript is right to flag it. In routes protected by middleware, it will never actually be null in practice, but you can safely use optional chaining (`user?.firstName`) as shown above, or add an explicit early-return check if you prefer stricter code.

Next up: Part 8, where we build out a fully Tailwind-styled dashboard with a real navigation shell and the `UserButton` component.
