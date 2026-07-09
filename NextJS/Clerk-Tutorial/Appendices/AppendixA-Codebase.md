Here is the complete **Appendix A: Full Codebase Reference**, all four notes, from the beginning.

---

# Appendix A: Full Codebase Reference (1 of 4) - Next.js 16 Baseline

This appendix collects every file built across the series in one place, for easy copy-paste reference or troubleshooting comparison. This entire reference targets **Next.js 16** (Node 20.9+/22 LTS, Turbopack default, async dynamic APIs, Tailwind CSS v4). Split across four notes:
- **This note (1 of 4):** project config, environment variables, middleware, root layout, homepage
- **Note 2 of 4:** all `/dashboard` files (layout, overview, settings, organization, actions)
- **Note 3 of 4:** Clerk appearance config, prebuilt + custom sign-up auth pages
- **Note 4 of 4:** custom sign-in page, webhook route, package.json reference

## Project structure (final)

```
acme-boards/
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   ├── globals.css
│   │   ├── sign-in/[[...sign-in]]/page.tsx
│   │   ├── sign-up/[[...sign-up]]/page.tsx
│   │   ├── custom-sign-in/page.tsx
│   │   ├── custom-sign-up/page.tsx
│   │   ├── dashboard/
│   │   │   ├── layout.tsx
│   │   │   ├── page.tsx
│   │   │   ├── settings/page.tsx
│   │   │   └── organization/
│   │   │       ├── page.tsx
│   │   │       └── actions.ts
│   │   └── api/
│   │       └── webhooks/
│   │           └── clerk/route.ts
│   ├── lib/
│   │   └── clerkAppearance.ts
│   └── middleware.ts
├── .env.local          (not committed)
├── package.json
├── tsconfig.json
└── next.config.ts
```

## `.env.local` (never commit this file)

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_your_key_here
CLERK_SECRET_KEY=sk_test_your_key_here
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
CLERK_WEBHOOK_SECRET=whsec_your_signing_secret_here
```

See Appendix B for a full explanation of every variable.

## `src/middleware.ts`

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

## `src/app/layout.tsx`

```tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import { clerkAppearance } from "@/lib/clerkAppearance";
import "./globals.css";

export const metadata: Metadata = {
  title: "Acme Boards",
  description: "A Next.js + Clerk + Tailwind demo app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <ClerkProvider appearance={clerkAppearance}>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

## `src/app/page.tsx`

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

## `src/app/globals.css`

```css
@import "tailwindcss";
```

This is the full Tailwind CSS v4 configuration needed - no `tailwind.config.ts` file required for this project's needs.

## Next.js 16 conventions reflected throughout this codebase

- Node.js 20.9+ or 22 LTS required to run any of this.
- Turbopack is the default bundler for `next dev`/`next build` - no extra flags needed.
- Every function reading dynamic data (`headers()`, Clerk's `auth()`/`currentUser()`) is `async` and properly `await`s those calls - see Note 2 of 4 and Note 4 of 4 for the clearest examples.

---

# Appendix A: Full Codebase Reference (2 of 4 - Dashboard) - Next.js 16

Continued from Note 1 of 4. This note covers everything under `src/app/dashboard/`. All Server Components/Actions below correctly use `async`/`await` for Clerk's `auth()`/`currentUser()` calls, per Next.js 16's dynamic API conventions. Continue to Note 3 of 4 for auth pages part 1.

## `src/app/dashboard/layout.tsx`

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
            <Link href="/dashboard/organization" className="text-sm text-gray-600 hover:text-gray-900">
              Organization
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

## `src/app/dashboard/page.tsx`

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

## `src/app/dashboard/settings/page.tsx`

```tsx
"use client";

import { useUser } from "@clerk/nextjs";

export default function SettingsPage() {
  const { isLoaded, isSignedIn, user } = useUser();

  if (!isLoaded) {
    return <p className="text-gray-500">Loading...</p>;
  }

  if (!isSignedIn) {
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

## `src/app/dashboard/organization/actions.ts`

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

  console.log(`Admin action performed on org ${orgId}: set label to "${newLabel}"`);

  return { success: true, label: newLabel };
}
```

## `src/app/dashboard/organization/page.tsx`

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
# Appendix A: Full Codebase Reference (3 of 4 - Auth Pages Part 1) - Next.js 16

Continued from Note 2 of 4. This note covers the Clerk appearance config and the prebuilt + custom sign-up auth pages. Note 4 of 4 covers the custom sign-in page and the webhook route.

## `src/lib/clerkAppearance.ts`

```ts
import type { Appearance } from "@clerk/types";

export const clerkAppearance: Appearance = {
  variables: {
    colorPrimary: "#2563eb",
    colorText: "#111827",
    colorTextSecondary: "#4b5563",
    colorBackground: "#ffffff",
    colorInputBackground: "#ffffff",
    colorInputText: "#111827",
    borderRadius: "0.375rem",
    fontFamily: "inherit",
  },
  elements: {
    card: "shadow-md border border-gray-200",
    formButtonPrimary:
      "bg-blue-600 hover:bg-blue-700 text-sm normal-case font-medium",
    footerActionLink: "text-blue-600 hover:text-blue-700",
    formFieldInput:
      "border-gray-300 focus:border-blue-500 focus:ring-blue-500",
  },
};
```

## `src/app/sign-in/[[...sign-in]]/page.tsx`

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

## `src/app/sign-up/[[...sign-up]]/page.tsx`

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

## `src/app/custom-sign-up/page.tsx`

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
# Appendix A: Full Codebase Reference (4 of 4 - Custom Sign-In & Webhook Route) - Next.js 16

Continued from Note 3 of 4 (auth pages part 1). This final note covers the custom sign-in page and the webhook route handler.

## `src/app/custom-sign-in/page.tsx`

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

## `src/app/api/webhooks/clerk/route.ts`

```ts
import { Webhook } from "svix";
import { headers } from "next/headers";
import type { WebhookEvent } from "@clerk/nextjs/server";

export async function POST(req: Request) {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;

  if (!WEBHOOK_SECRET) {
    throw new Error("Missing CLERK_WEBHOOK_SECRET in environment variables.");
  }

  // Next.js 16: headers() is async and must be awaited
  const headerPayload = await headers();
  const svix_id = headerPayload.get("svix-id");
  const svix_timestamp = headerPayload.get("svix-timestamp");
  const svix_signature = headerPayload.get("svix-signature");

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return new Response("Missing svix headers", { status: 400 });
  }

  const payload = await req.text();

  const wh = new Webhook(WEBHOOK_SECRET);
  let evt: WebhookEvent;

  try {
    evt = wh.verify(payload, {
      "svix-id": svix_id,
      "svix-timestamp": svix_timestamp,
      "svix-signature": svix_signature,
    }) as WebhookEvent;
  } catch (err) {
    console.error("Webhook verification failed:", err);
    return new Response("Invalid signature", { status: 400 });
  }

  const eventType = evt.type;

  if (eventType === "user.created") {
    const { id, email_addresses, first_name, last_name } = evt.data;
    const primaryEmail = email_addresses?.[0]?.email_address ?? null;

    console.log("Syncing new user to our database:", {
      clerkId: id,
      email: primaryEmail,
      firstName: first_name,
      lastName: last_name,
    });

    // await db.insert(usersTable).values({ clerkId: id, email: primaryEmail, firstName: first_name, lastName: last_name });
  }

  if (eventType === "user.updated") {
    const { id, first_name, last_name } = evt.data;
    console.log("Updating user in our database:", { clerkId: id, first_name, last_name });
    // await db.update(usersTable).set({ ... }).where(eq(usersTable.clerkId, id));
  }

  if (eventType === "user.deleted") {
    const { id } = evt.data;
    console.log("Removing user from our database:", { clerkId: id });
    // await db.delete(usersTable).where(eq(usersTable.clerkId, id));
  }

  return new Response("OK", { status: 200 });
}
```

## `package.json` dependencies (key packages only)

```json
{
  "dependencies": {
    "@clerk/nextjs": "latest",
    "next": "^16.0.0",
    "react": "latest",
    "react-dom": "latest",
    "svix": "latest"
  }
}
```

(Exact pinned versions will vary based on when you ran `npm install` — that's expected and fine, as long as `next` resolves to a 16.x release and your local Node version is 20.9+ or 22 LTS as covered in Part 1.)

## Next.js 16 checklist for this codebase

- [ ] Node.js 20.9+ / 22 LTS installed (Part 1)
- [ ] Turbopack used by default for dev/build - no manual flags needed
- [ ] `globals.css` uses Tailwind v4's `@import "tailwindcss";` (no `tailwind.config.ts` required)
- [ ] Every server-side read of dynamic data (`headers()`, `auth()`, `currentUser()`) is inside an `async` function and properly `await`ed - see the webhook route above and Parts 7, 11, 12, 13

This completes the full codebase reference. See Appendix B for environment variable explanations, Appendix C for troubleshooting across the whole series, and Appendix D for a hooks/components cheat sheet and further docs links.

---

That wraps up **Appendix A** in full (all 4 notes). 
