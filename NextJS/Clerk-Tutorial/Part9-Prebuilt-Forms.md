# Part 9: Building a Fully Custom Sign-In/Sign-Up UI

Clerk's prebuilt `<SignIn />`/`<SignUp />` components (Part 6) are great for speed, but sometimes you want pixel-perfect control over your auth forms — matching your own design system exactly. Clerk supports this via **headless hooks**: `useSignIn()` and `useSignUp()`. They give you the raw auth logic (submit email, submit password, handle verification codes) with zero prescribed markup — you build 100% of the UI yourself with Tailwind.

These hooks are client-side and unaffected by Next.js 16's server-side async API changes — they behave exactly as you'd expect from React state/hooks.

This part is code-heavy and split across two notes: this one (sign-up form) and "Part 9: Custom Sign-In/Sign-Up UI (continued)" (sign-in form, testing, checkpoint, troubleshooting). Read both.

We'll build:
1. A custom sign-up form (email + password + verification code step) — below
2. A custom sign-in form (email + password) — in the continued note

## 1. Custom Sign-Up Form

Create `src/app/custom-sign-up/page.tsx`:

```tsx
"use client";

import * as React from "react";
import { useSignUp } from "@clerk/nextjs";
import { useRouter } from "next/navigation";

export default function CustomSignUpPage() {
  const { isLoaded, signUp, setActive } = useSignUp();
  const router = useRouter();

  const [emailAddress, setEmailAddress] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [pendingVerification, setPendingVerification] = React.useState(false);
  const [code, setCode] = React.useState("");
  const [error, setError] = React.useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!isLoaded) return;
    setError("");

    try {
      await signUp.create({ emailAddress, password });
      await signUp.prepareEmailAddressVerification({ strategy: "email_code" });
      setPendingVerification(true);
    } catch (err: any) {
      setError(err.errors?.[0]?.message ?? "Something went wrong.");
    }
  }

  async function handleVerify(e: React.FormEvent) {
    e.preventDefault();
    if (!isLoaded) return;
    setError("");

    try {
      const result = await signUp.attemptEmailAddressVerification({ code });
      if (result.status === "complete") {
        await setActive({ session: result.createdSessionId });
        router.push("/dashboard");
      } else {
        setError("Verification incomplete. Please try again.");
      }
    } catch (err: any) {
      setError(err.errors?.[0]?.message ?? "Invalid code.");
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-sm rounded-lg border border-gray-200 bg-white p-8 shadow-md">
        <h1 className="text-xl font-bold text-gray-900">Create your account</h1>

        {!pendingVerification ? (
          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Email</label>
              <input
                type="email"
                value={emailAddress}
                onChange={(e) => setEmailAddress(e.target.value)}
                required
                className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
            {error && <p className="text-sm text-red-600">{error}</p>}
            <button
              type="submit"
              className="w-full rounded-md bg-blue-600 py-2 text-sm font-medium text-white hover:bg-blue-700"
            >
              Sign Up
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerify} className="mt-6 space-y-4">
            <p className="text-sm text-gray-600">
              We sent a verification code to {emailAddress}. Enter it below.
            </p>
            <div>
              <label className="block text-sm font-medium text-gray-700">Code</label>
              <input
                type="text"
                value={code}
                onChange={(e) => setCode(e.target.value)}
                required
                className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              />
            </div>
            {error && <p className="text-sm text-red-600">{error}</p>}
            <button
              type="submit"
              className="w-full rounded-md bg-blue-600 py-2 text-sm font-medium text-white hover:bg-blue-700"
            >
              Verify Email
            </button>
          </form>
        )}
      </div>
    </main>
  );
}
```

### What's happening here

- `useSignUp()` gives us `signUp` (an object with methods for each step of the sign-up flow) and `setActive` (activates a session once sign-up completes).
- `signUp.create({ emailAddress, password })` starts the sign-up process.
- `signUp.prepareEmailAddressVerification({ strategy: "email_code" })` tells Clerk to send a verification email.
- `signUp.attemptEmailAddressVerification({ code })` submits the code the user received. If `result.status === "complete"`, the account is fully created and verified.
- `setActive({ session: result.createdSessionId })` signs the user in immediately, then we redirect to `/dashboard`.
- `router.push("/dashboard")` uses the standard `next/navigation` client router — unchanged in Next.js 16.

This is real state-machine logic — sign-up isn't a single step when email verification is involved, it's "create pending user" → "verify" → "activate session."

# Part 9 (continued): Custom Sign-In Form, Testing, Checkpoint, Troubleshooting

This continues directly from "Clerk Tutorial - Part 9: Custom Sign-In/Sign-Up UI" — read that note first for the custom sign-up form.

## 2. Custom Sign-In Form

Create `src/app/custom-sign-in/page.tsx`:

```tsx
"use client";

import * as React from "react";
import { useSignIn } from "@clerk/nextjs";
import { useRouter } from "next/navigation";

export default function CustomSignInPage() {
  const { isLoaded, signIn, setActive } = useSignIn();
  const router = useRouter();

  const [emailAddress, setEmailAddress] = React.useState("");
  const [password, setPassword] = React.useState("");
  const [error, setError] = React.useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!isLoaded) return;
    setError("");

    try {
      const result = await signIn.create({
        identifier: emailAddress,
        password,
      });

      if (result.status === "complete") {
        await setActive({ session: result.createdSessionId });
        router.push("/dashboard");
      } else {
        // Handles cases like needing 2FA - out of scope here, but log it for learning
        console.log(result);
        setError("Additional verification required.");
      }
    } catch (err: any) {
      setError(err.errors?.[0]?.message ?? "Invalid email or password.");
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-sm rounded-lg border border-gray-200 bg-white p-8 shadow-md">
        <h1 className="text-xl font-bold text-gray-900">Sign in</h1>
        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              value={emailAddress}
              onChange={(e) => setEmailAddress(e.target.value)}
              required
              className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
            />
          </div>
          {error && <p className="text-sm text-red-600">{error}</p>}
          <button
            type="submit"
            className="w-full rounded-md bg-blue-600 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            Sign In
          </button>
        </form>
        <p className="mt-4 text-center text-sm text-gray-500">
          Don&apos;t have an account?{" "}
          <a href="/custom-sign-up" className="text-blue-600 hover:underline">
            Sign up
          </a>
        </p>
      </div>
    </main>
  );
}
```

### What's happening here

- `useSignIn()` gives us `signIn.create({ identifier, password })` — `identifier` can be an email, username, or phone depending on your Clerk configuration.
- If `result.status === "complete"`, the credentials were correct and we activate the session and redirect.
- Any other status (e.g. `needs_second_factor` if you'd enabled 2FA) would need extra handling — out of scope for this tutorial, but the `console.log(result)` line shows you where to inspect it if you want to extend this later.
- Errors (wrong password, unknown user) are caught and shown inline — Clerk deliberately gives a generic "Invalid email or password" style message for the wrong-password case in many configurations, as a security best practice against user enumeration.

## 3. Test both custom forms

1. Sign out of any existing session.
2. Visit `/custom-sign-up`. Create a brand new test account (use a different email than before, since your first test account already exists).
3. Enter the verification code sent to your email. Confirm it redirects you to `/dashboard` and you're signed in.
4. Sign out via the `UserButton` dropdown (Part 8).
5. Visit `/custom-sign-in`. Sign in with the account you just created. Confirm it redirects to `/dashboard`.
6. Try signing in with a wrong password on purpose — confirm you see a friendly inline error instead of a crash.

## 4. Commit

```bash
git add .
git commit -m "Add fully custom sign-in/sign-up UI using headless Clerk hooks"
```

## Checkpoint

- [ ] `/custom-sign-up` creates an account, sends a verification code, verifies it, and signs the user in
- [ ] `/custom-sign-in` signs an existing user in with email/password
- [ ] Both forms are styled entirely with your own Tailwind markup — no Clerk-provided CSS
- [ ] Wrong-password attempts show a graceful inline error, not a crash

## Troubleshooting

**`signUp.create is not a function` or `signIn` is `undefined`.**
`useSignUp()`/`useSignIn()` return `undefined` values for `signUp`/`signIn` until `isLoaded` is `true`. Always guard with `if (!isLoaded) return;` at the top of your submit handlers, exactly as shown above.

**Verification code email never arrives during custom sign-up testing.**
Same as Part 6 — check spam, or use the Clerk Dashboard's Users section to inspect/verify the pending user manually during development.

**Error: "Sign up unsuccessful due to breached password" or similar.**
Clerk checks new passwords against known breached-password databases by default. Use a more unique test password (not "password123").

**`result.status` is `"missing_requirements"` after `signUp.create`.**
This means Clerk's dashboard settings require additional fields (e.g. it expects a username, or first/last name) that your form isn't collecting. Check **User & Authentication** settings in the Clerk Dashboard and either disable the extra required field for this tutorial, or extend the form to collect it (e.g. add a `signUp.update({ username })` call before verification).

**After wiring up custom forms, do I still need the Part 6 prebuilt `/sign-in` and `/sign-up` pages?**
No, you can pick one approach for your real app. We're keeping both in this tutorial purely so you can compare them side by side and decide which fits your project. In Appendix A's full reference, both sets of pages are included for completeness.

**Can I mix prebuilt components with a custom-styled wrapper instead of going fully headless?**
Yes — that's exactly what Part 10 covers next, using the `appearance` prop to restyle the prebuilt `<SignIn />`/`<SignUp />` components instead of replacing them entirely. Fully headless (this part) gives maximum control; `appearance` theming (next part) gives a faster middle ground.

Next up: Part 10, where we theme Clerk's prebuilt components with Tailwind-matching colors using the `appearance` prop, and add dark mode support.
