## Part 4: Adding Login with Clerk

Goal: create a Clerk account, install Clerk into qb-clone, get real sign-up/sign-in working, and protect a page.

Prerequisite: Parts 1-3 completed.

**Next.js 16 note:** older Clerk tutorials tell you to create `middleware.ts`. In Next.js 16, this file has been renamed to **`proxy.ts`** (same job: code that runs before a request reaches your pages; `middleware.ts` still works with a deprecation warning, but this course uses the current name throughout). Since our project uses the `src/` directory, ours lives at `src/proxy.ts`.

---

### 1. Create a Clerk account and application

1. Go to https://clerk.com, sign up (free, no credit card)
2. Click "Create Application", name it `qb-clone`
3. Leave "Email" checked under sign-in options
4. Click Create Application
5. Keep the API Keys page open — you'll need `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY`

### 2. Install Clerk

In your terminal, inside `qb-clone`:
```
npm install @clerk/nextjs
```

Expected output ends with something like `added 12 packages`.

### 3. Add your keys

Create a new file at the project root (same level as `package.json`) named exactly `.env.local`. Type this, replacing the placeholder values with your real keys from the Clerk dashboard:

```
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxx
```

Open `.gitignore` and confirm you see a line containing `.env*.local` in it (it's added automatically by create-next-app).

Stop your dev server (Ctrl+C in its terminal) and restart it:
```
npm run dev
```

### 4. Wrap the app with ClerkProvider

Open `src/app/layout.tsx`. Replace its entire contents with:

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "QB Clone",
  description: "A QuickBooks clone built for learning",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

Save. Check http://localhost:3000 still loads with no errors (nothing visibly different yet).

### 5. Add sign-in / sign-up UI

Open `src/app/page.tsx`, replace its entire contents with:

```tsx
import {
  SignedIn,
  SignedOut,
  SignInButton,
  SignUpButton,
  UserButton,
} from "@clerk/nextjs";

export default function Home() {
  return (
    <main style={{ padding: "2rem" }}>
      <h1>QB Clone</h1>

      <SignedOut>
        <p>You are not signed in.</p>
        <SignInButton />
        <SignUpButton />
      </SignedOut>

      <SignedIn>
        <p>You are signed in!</p>
        <UserButton />
      </SignedIn>
    </main>
  );
}
```

Save, check http://localhost:3000. Click **Sign Up**, use a real email you can check, complete the verification code flow, and finish sign-up. You should land back on the page showing "You are signed in!" and your avatar.

### 6. Protect a page with proxy.ts (Next.js 16's renamed middleware)

Create a new file `src/proxy.ts` (directly inside `src/`, NOT inside `src/app/`). Type exactly:

```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher(["/dashboard(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

Note the file is named `proxy.ts`, but the function you import and call is still named `clerkMiddleware` — Clerk kept its own API name the same even though Next.js renamed the file/concept on their end. Do not also create a `src/middleware.ts` file — having both will cause confusing double-execution or Next.js picking the wrong one.

Create a new folder `src/app/dashboard/`, and inside it a file `page.tsx`:

```tsx
import { currentUser } from "@clerk/nextjs/server";

export default async function DashboardPage() {
  const user = await currentUser();

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Dashboard</h1>
      <p>Welcome, {user?.firstName ?? "friend"}! Only signed-in users can see this page.</p>
    </main>
  );
}
```

Test: while signed in, visit http://localhost:3000/dashboard — you should see your welcome message. Sign out (click your avatar -> Sign out), then try visiting /dashboard again directly — Clerk should redirect you to a sign-in screen automatically.

### 7. Commit

```
git add .
git commit -m "Add Clerk authentication with a protected dashboard page (proxy.ts)"
```

---

### ✅ Checkpoint

- [ ] Clerk account and application created
- [ ] `.env.local` has both keys, and `git status` does NOT list it as a tracked/changed file
- [ ] Homepage shows correct Sign In/Up or avatar UI depending on login state
- [ ] `src/proxy.ts` exists (not `src/middleware.ts`) and `/dashboard` redirects to sign-in when logged out, and shows the welcome message when logged in

---

### Troubleshooting

**Homepage shows a blank white screen or a Clerk-related error after adding ClerkProvider**
Almost always means `.env.local` is missing, misnamed, or the dev server wasn't restarted after creating it. Confirm the file is named exactly `.env.local` (not `.env.local.txt` — some editors add a hidden `.txt` extension; check with `ls -la` on Mac or enable file extensions in Windows Explorer). Then fully stop (Ctrl+C) and restart `npm run dev`.

**Error: "Missing publishableKey" or similar**
Your `.env.local` values weren't picked up. Double-check there are no quotes around the values, no extra spaces around the `=` sign, and that the variable names are spelled exactly as shown (case-sensitive). Restart the dev server after any change to `.env.local`.

**Sign-up verification email never arrives**
Check spam/junk folder first. Confirm you're testing against the correct email inbox. Clerk's development instance does rate-limit slightly — wait a minute and try "resend code" if the option appears.

**`/dashboard` doesn't redirect when logged out — it just shows the page anyway**
Confirm the file is located at exactly `src/proxy.ts`, NOT `src/app/proxy.ts` and NOT `src/middleware.ts` — this is a common misplacement/naming mix-up and Next.js will silently ignore a file in the wrong location or with the old name in some setups (though `middleware.ts` alone still works, mixing both is what causes real problems). Restart the dev server after creating or moving it.

**`currentUser()` returns null even though you're logged in**
Confirm the file is an `async` function (`export default async function DashboardPage()`) and that you used `await currentUser()`, not just `currentUser()`.

**TypeScript error on `user?.firstName`**
Confirm you're using the optional chaining `?.` exactly as shown — `user` can legitimately be null if Clerk hasn't loaded yet server-side in edge cases, and the `?.` protects against that.

**Proxy's "matcher" causes some pages (like images) to stop loading**
The regex above is intentionally broad to skip static files. If you added your own static assets with an unusual file extension, add that extension into the matcher's exclusion list, following the same pattern as the others already listed.

**"clerkMiddleware() was not run" or auth-related errors even though proxy.ts looks correct**
Double-check there isn't also a leftover `src/middleware.ts` file from following an older tutorial or an earlier attempt — having both `proxy.ts` and `middleware.ts` in the same project causes exactly this kind of confusing behavior. Delete `middleware.ts` if it exists and keep only `proxy.ts`.
