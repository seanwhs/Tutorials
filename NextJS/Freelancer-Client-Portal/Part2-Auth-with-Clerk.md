# Part 2: Auth with Clerk (Admin vs Client Roles)

Previous: Part 1 (Dev Environment & Project Setup).

Targets Next.js 16 + current `@clerk/nextjs`. Clerk's `auth()` helper and `clerkMiddleware()` are already async-first, lining up with Next.js 16's async-APIs convention.

## 1. Concept

Clerk gives us hosted sign-in/sign-up pages, session management, and a `publicMetadata` field to store a `role`: `"ADMIN"` or `"CLIENT"`.

- You (freelancer) are the one ADMIN — set manually after signing up.
- When you add a `Client` (Part 5) and invite them, their Clerk account defaults to `"CLIENT"` and links to a `Client` record.
- Middleware protects `/admin/*` (ADMIN only) and `/portal/*` (signed-in users; further scoped at the tRPC layer).

## 2. Create a Clerk application

1. dashboard.clerk.com → new app "Freelancer Portal".
2. Choose "Email" sign-in (add Google if you like).
3. Copy Publishable key and Secret key.

## 3. Install Clerk

```bash
pnpm add @clerk/nextjs
```

## 4. Environment variables

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dispatch
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dispatch
```

## 5. Wrap the app in ClerkProvider

```tsx
// src/app/layout.tsx
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/sonner";
import { ClerkProvider } from "@clerk/nextjs";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Freelancer Client Portal",
  description: "Manage clients, proposals, invoices, and payments in one place.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className={inter.className}>
          {children}
          <Toaster richColors position="top-right" />
        </body>
      </html>
    </ClerkProvider>
  );
}
```

## 6. Sign-in / sign-up pages

```tsx
// src/app/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
```

```tsx
// src/app/sign-up/[[...sign-up]]/page.tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
```

## 7. Middleware: protect routes and attach role

```ts
// src/middleware.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";

const isAdminRoute = createRouteMatcher(["/admin(.*)"]);
const isPortalRoute = createRouteMatcher(["/portal(.*)"]);
const isPublicRoute = createRouteMatcher([
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
  "/api/webhooks(.*)",
  "/api/uploadthing(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isPublicRoute(req)) return;

  const { userId, sessionClaims, redirectToSignIn } = await auth();

  if (!userId) {
    return redirectToSignIn({ returnBackUrl: req.url });
  }

  const role = (sessionClaims?.metadata as { role?: string } | undefined)?.role;

  if (isAdminRoute(req) && role !== "ADMIN") {
    return NextResponse.redirect(new URL("/portal", req.url));
  }

  if (isPortalRoute(req) && role !== "CLIENT" && role !== "ADMIN") {
    return NextResponse.redirect(new URL("/sign-in", req.url));
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

`src/middleware.ts` at project root (next to `src/app/`) is correct for this `src/` layout — Next.js resolves it automatically.

`sessionClaims.metadata.role` requires: Clerk dashboard → **Sessions → Customize session token** → add:
```json
{ "metadata": "{{user.public_metadata}}" }
```

## 8. Make yourself ADMIN

1. `pnpm dev`, sign up at `/sign-up`.
2. Clerk dashboard → Users → your user → Public metadata → Edit:
   ```json
   { "role": "ADMIN" }
   ```
3. Save, sign out/in.

Every client user defaults to `"CLIENT"` — set automatically via a Clerk webhook in Part 5.

## 9. Dispatch route (role-based redirect after login)

```tsx
// src/app/dispatch/page.tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";

export default async function DispatchPage() {
  const { sessionClaims } = await auth();
  const role = (sessionClaims?.metadata as { role?: string } | undefined)?.role;

  if (role === "ADMIN") redirect("/admin");
  redirect("/portal");
}
```

## 10. Minimal placeholder pages for /admin and /portal

```tsx
// src/app/admin/page.tsx
import { UserButton } from "@clerk/nextjs";

export default function AdminHome() {
  return (
    <main className="p-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Admin Dashboard</h1>
        <UserButton />
      </div>
      <p className="mt-4 text-muted-foreground">Clients, projects, proposals, and invoices will live here.</p>
    </main>
  );
}
```

```tsx
// src/app/portal/page.tsx
import { UserButton } from "@clerk/nextjs";

export default function PortalHome() {
  return (
    <main className="p-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Your Portal</h1>
        <UserButton />
      </div>
      <p className="mt-4 text-muted-foreground">Your projects, proposals, and invoices will appear here.</p>
    </main>
  );
}
```

## 11. Update the homepage with sign-in links

```tsx
// src/app/page.tsx
import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6">
      <h1 className="text-3xl font-bold">Freelancer Client Portal</h1>
      <p className="max-w-md text-center text-muted-foreground">
        Invoices, proposals, and payments — all in one place for you and your clients.
      </p>
      <div className="flex gap-3">
        <Button asChild>
          <Link href="/sign-in">Sign in</Link>
        </Button>
        <Button asChild variant="outline">
          <Link href="/sign-up">Sign up</Link>
        </Button>
      </div>
    </main>
  );
}
```

## Checkpoint

- [ ] `/` shows Sign in / Sign up buttons
- [ ] Signing up creates a Clerk user; role set to ADMIN
- [ ] `/dispatch` as ADMIN redirects to `/admin`
- [ ] `/admin` while NOT ADMIN redirects to `/portal`
- [ ] `/admin` or `/portal` while signed out redirects to `/sign-in`

## Troubleshooting

- **`sessionClaims.metadata` undefined**: missed "Customize session token" step, or stale session.
- **Infinite redirect loop**: check `isPublicRoute` matcher.
- **Middleware not running**: confirm file at `src/middleware.ts`, not `src/app/middleware.ts`.

## Next

Continue to **Part 3: Database — Prisma + Neon Postgres**.
