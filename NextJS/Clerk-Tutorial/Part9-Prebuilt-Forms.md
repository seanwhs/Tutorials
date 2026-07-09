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

Continue to "Part 9: Custom Sign-In/Sign-Up UI (continued)" for the sign-in form, testing steps, checkpoint, and troubleshooting.
