# Part 6: Sign-In and Sign-Up Pages with Clerk's Prebuilt Components

Clerk ships prebuilt, fully-functional `<SignIn />` and `<SignUp />` components that handle the entire auth flow (including email verification, password reset, social login buttons) with almost no code. Let's add them.

## 1. Create the sign-in page

Create `src/app/sign-in/[[...sign-in]]/page.tsx`:

```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <SignIn />
    </main>
  );
}
```

The odd folder name `[[...sign-in]]` is a Next.js **optional catch-all route**. Clerk's component internally navigates between sub-steps (e.g. "enter email" → "enter code" → "forgot password"), and it needs a catch-all route so those internal navigations don't 404. This routing convention is unchanged in Next.js 16.

## 2. Create the sign-up page

Create `src/app/sign-up/[[...sign-up]]/page.tsx`:

```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <SignUp />
    </main>
  );
}
```

## 3. Confirm your env vars point to these routes

From Part 5, you should already have in `.env.local`:

```bash
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
```

These tell Clerk's components: "when a user clicks 'Sign in' anywhere, send them to `/sign-in`" and "once they successfully authenticate, send them to `/dashboard`." We haven't built `/dashboard` yet — that's Part 8. For now it will 404 after signing in, which is expected.

Restart your dev server after any `.env.local` change:
```bash
npm run dev
```

## 4. Add navigation links from the homepage

Update `src/app/page.tsx`:

```tsx
import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-gray-50 px-4">
      <h1 className="text-4xl font-bold text-blue-600">Acme Boards</h1>
      <p className="mt-2 text-gray-600">A demo app built with Next.js, Clerk, and Tailwind.</p>
      <div className="mt-6 flex gap-4">
        <Link
          href="/sign-in"
          className="rounded-md border border-gray-300 bg-white px-4 py-2 text-gray-700 hover:bg-gray-100"
        >
          Sign In
        </Link>
        <Link
          href="/sign-up"
          className="rounded-md bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
        >
          Sign Up
        </Link>
      </div>
    </main>
  );
}
```

## 5. Test it

1. Visit http://localhost:3000 — you should see your homepage with Sign In / Sign Up buttons.
2. Click **Sign Up**. You should see Clerk's full sign-up form (styled with a default theme).
3. Create a test account with your real email (you'll need to verify it) or a throwaway one.
4. Complete the verification code step if prompted.
5. After signing up, you'll be redirected to `/dashboard` — which 404s right now. That's expected; we build it in Part 8.
6. Go back to http://localhost:3000/sign-in and confirm you can sign in with the account you just created.

## 6. Commit

```bash
git add .
git commit -m "Add sign-in and sign-up pages"
```

## Checkpoint

- [ ] `/sign-in` shows Clerk's sign-in form
- [ ] `/sign-up` shows Clerk's sign-up form
- [ ] You successfully created a test account and can sign in/out
- [ ] Homepage links to both pages

## Troubleshooting

**404 on `/sign-in` or `/sign-up` itself (not just after signing in).**
Check the exact folder name: `[[...sign-in]]` — double square brackets, three dots, then the name, no typos. This is Next.js's optional catch-all segment syntax, unchanged in Next.js 16. A single bracket `[...sign-in]` (non-optional catch-all) will break the base route.

**The form loads but looks broken/unstyled.**
Clerk injects its own default CSS for its components; this doesn't depend on Tailwind. If it looks totally broken (raw HTML, no styling at all), check the browser console for a blocked network request — an ad blocker or strict corporate network occasionally blocks Clerk's CDN assets in older SDK versions. Try an incognito window or disabling extensions temporarily.

**After sign-up, verification email never arrives.**
Check spam. In development, Clerk sometimes has a short delay. You can also switch to email-code-only in the Clerk Dashboard for faster testing, or use the Clerk Dashboard's **Users** section to manually verify a test user.

**Redirect after sign-in goes to `/dashboard` and 404s — is that a bug?**
No — expected at this stage since we build `/dashboard` in Part 8. If you want to avoid seeing the 404 for now, temporarily remove the `FORCE_REDIRECT_URL` env vars and restart the dev server; Clerk will fall back to redirecting to the homepage instead.

**I want the sign-in/up forms centered better or full-page styled.**
That's coming in Part 10 (theming) — for now the default Clerk card floating in a centered Tailwind container is expected and fine.

Next up: Part 7, where we protect routes and learn to read the currently signed-in user on the server using Next.js 16's async APIs.
