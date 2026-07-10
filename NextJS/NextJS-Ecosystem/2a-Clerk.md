## Part 2a: Identity & Content

**Series:** Building Enterprise-Grade Full-Stack Applications: The Next.js 16 Ecosystem
**Goal:** Wire up Clerk for auth and Sanity for CMS, connect both to the Next.js 16 frontend.

> This note covers the **Clerk (Identity)** half. The **Sanity (Content)** half continues in the companion note **"Ecosystem Tutorial - Part 2b: Content (Sanity Setup)"**.

---

### 1. Concept Explanation

Clerk owns identity: who is signed in, and what role do they have. Sanity owns editorial content: service packages the agency offers, and knowledge-base articles it publishes. Neither service knows about the other, and neither knows about Prisma/Neon yet — that bridge is Part 5's job.

**Role model:** three roles — `ADMIN`, `MEMBER`, `CLIENT` — stored in Clerk `publicMetadata.role`. Read from the session claim directly, never a separate DB round trip, so route protection in `proxy.ts` stays fast.

**Sanity content model for this part:** `servicePackage` (name, description, price, features) and `article` (title, slug, body, publishedAt) — built in Part 2b.

---

### 2. Implementation — Clerk

#### 2.1 Install

```bash
pnpm add @clerk/nextjs
```

#### 2.2 Env vars

Create a Clerk application named "Orbit" in the dashboard, then fill in:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
```

#### 2.3 Root layout

```tsx
// src/app/layout.tsx
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "Orbit",
  description: "Client engagement & knowledge portal",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

#### 2.4 Sign-in / sign-up pages

```tsx
// src/app/(auth)/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from "@clerk/nextjs";

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
```

```tsx
// src/app/(auth)/sign-up/[[...sign-up]]/page.tsx
import { SignUp } from "@clerk/nextjs";

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
```

#### 2.5 Route protection — src/proxy.ts

```ts
// src/proxy.ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher([
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
  "/articles(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (!isPublicRoute(req)) {
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

#### 2.6 Role helper — lib/clerk/roles.ts

```ts
// src/lib/clerk/roles.ts
import { auth } from "@clerk/nextjs/server";

export type OrbitRole = "ADMIN" | "MEMBER" | "CLIENT";

export async function getUserRole(): Promise<OrbitRole> {
  const { sessionClaims } = await auth();
  const role = sessionClaims?.publicMetadata as { role?: OrbitRole } | undefined;
  return role?.role ?? "CLIENT";
}

export async function requireRole(allowed: OrbitRole[]) {
  const role = await getUserRole();
  if (!allowed.includes(role)) {
    throw new Error(`Forbidden: requires one of [${allowed.join(", ")}], got ${role}`);
  }
  return role;
}
```

#### 2.7 Setting a user's role (admin-only Route Handler)

```ts
// src/app/api/admin/set-role/route.ts
import { NextRequest, NextResponse } from "next/server";
import { clerkClient } from "@clerk/nextjs/server";
import { requireRole } from "@/lib/clerk/roles";

export async function POST(req: NextRequest) {
  await requireRole(["ADMIN"]);

  const { userId, role } = await req.json();
  const client = await clerkClient();

  await client.users.updateUserMetadata(userId, {
    publicMetadata: { role },
  });

  return NextResponse.json({ ok: true });
}
```

> For the very first user, promote yourself to `ADMIN` manually in the Clerk dashboard (User → Metadata tab → public metadata `{ "role": "ADMIN" }`), since no admin exists yet to call this route.

---

### 3. Checkpoint (Clerk half)

- `pnpm dev`, visit `/sign-up`, create an account, get redirected in.
- Visiting any non-public route while signed out redirects to `/sign-in`.
- Promoting yourself to `ADMIN` via the dashboard and calling `requireRole(["ADMIN"])` in a test page succeeds.

### 4. Troubleshooting (Clerk half)

- `sessionClaims.publicMetadata.role` undefined after setting it → sign out/in; the JWT only refreshes on new session issuance.
- Both `src/middleware.ts` and `src/proxy.ts` present → Next.js 16 build error; delete the old `middleware.ts` if it exists.

---

**Continue to:** **"Ecosystem Tutorial - Part 2b: Content (Sanity Setup)"** for the Sanity CMS half of this part, then **"Ecosystem Tutorial - Part 3: The Persistence Layer"**.

---

Want **Part 2b (Sanity Setup)** next, or straight to **Part 3**?
