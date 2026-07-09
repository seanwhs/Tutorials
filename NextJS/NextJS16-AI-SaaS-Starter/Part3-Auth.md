## AI SaaS Tutorial - Part 3: Auth & Multi-Tenancy with Clerk Organizations

*Next.js 16 note: this part uses Clerk's current async `auth()` API and the async `headers()` API — both required patterns under Next.js 16's fully-async dynamic APIs. Confirmed correct below.*

### Goal
Add Clerk authentication and use Clerk Organizations as our "Workspaces," then sync Clerk users/orgs into our own Postgres database via webhooks.

### 1. Create a free Clerk application
1. Go to clerk.com and sign up (free tier).
2. Create an application named `acme-docs-ai`.
3. Under Organizations, toggle **Enable Organizations** (this is Clerk's multi-tenancy primitive — one Organization = one Workspace in our app).
4. Copy your API keys from the Clerk dashboard.

### 2. Environment variables
Add to `.env.local`:
```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxx
CLERK_SECRET_KEY=sk_test_xxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/workspaces
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/workspaces
CLERK_WEBHOOK_SIGNING_SECRET=whsec_xxx
```

### 3. Wrap the app in ClerkProvider
`src/app/layout.tsx`:
```tsx
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

### 4. Add middleware to protect routes
`src/middleware.ts`:
```ts
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isPublicRoute = createRouteMatcher([
  "/",
  "/sign-in(.*)",
  "/sign-up(.*)",
  "/api/webhooks(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (!isPublicRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: ["/((?!_next|.*\\..*).*)", "/(api|trpc)(.*)"],
};
```

### 5. Sign-in / sign-up pages
`src/app/sign-in/[[...sign-in]]/page.tsx`:
```tsx
import { SignIn } from "@clerk/nextjs";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  );
}
```
`src/app/sign-up/[[...sign-up]]/page.tsx`:
```tsx
import { SignUp } from "@clerk/nextjs";

export default function SignUpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  );
}
```

### 6. Sync Clerk to our DB via webhooks
We need our own User/Workspace/Membership rows to exist so we can join against Documents, Messages, and Subscriptions. `svix` was installed in Part 1.

`src/app/api/webhooks/clerk/route.ts`:
```ts
import { headers } from "next/headers";
import { Webhook } from "svix";
import { db } from "@/lib/db";

export async function POST(req: Request) {
  const secret = process.env.CLERK_WEBHOOK_SIGNING_SECRET!;
  // headers() is async in Next.js 16 - must be awaited
  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return new Response("Missing svix headers", { status: 400 });
  }

  const body = await req.text();
  const wh = new Webhook(secret);
  let evt: any;
  try {
    evt = wh.verify(body, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    });
  } catch {
    return new Response("Invalid signature", { status: 400 });
  }

  const { type, data } = evt;

  if (type === "user.created" || type === "user.updated") {
    await db.user.upsert({
      where: { clerkId: data.id },
      update: {
        email: data.email_addresses?.[0]?.email_address ?? "",
        name: `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim(),
      },
      create: {
        clerkId: data.id,
        email: data.email_addresses?.[0]?.email_address ?? "",
        name: `${data.first_name ?? ""} ${data.last_name ?? ""}`.trim(),
      },
    });
  }

  if (type === "organization.created" || type === "organization.updated") {
    await db.workspace.upsert({
      where: { clerkOrgId: data.id },
      update: { name: data.name },
      create: { clerkOrgId: data.id, name: data.name },
    });
  }

  if (type === "organizationMembership.created" || type === "organizationMembership.updated") {
    const user = await db.user.findUnique({ where: { clerkId: data.public_user_data.user_id } });
    const workspace = await db.workspace.findUnique({ where: { clerkOrgId: data.organization.id } });
    if (user && workspace) {
      const role = data.role === "org:admin" ? "OWNER" : "MEMBER";
      await db.membership.upsert({
        where: { userId_workspaceId: { userId: user.id, workspaceId: workspace.id } },
        update: { role },
        create: { userId: user.id, workspaceId: workspace.id, role },
      });
    }
  }

  return new Response("ok", { status: 200 });
}
```

### 7. Register the webhook in Clerk
1. In the Clerk dashboard, go to **Webhooks → Add Endpoint**.
2. For local dev, use `ngrok http 3000` and set the endpoint to `https://<your-ngrok-id>.ngrok-free.app/api/webhooks/clerk`.
3. Subscribe to events: `user.created`, `user.updated`, `organization.created`, `organization.updated`, `organizationMembership.created`, `organizationMembership.updated`.
4. Copy the Signing Secret into `CLERK_WEBHOOK_SIGNING_SECRET`.

**Checkpoint:** Sign up a test user, create an Organization from Clerk's UI (or via `<OrganizationSwitcher />`, added next part), and confirm rows appear in User, Workspace, and Membership via `npx prisma studio`.

**Next:** Part 4 — Workspace CRUD, Roles & Access Control.
