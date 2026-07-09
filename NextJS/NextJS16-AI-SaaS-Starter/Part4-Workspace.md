## AI SaaS Tutorial - Part 4: Workspace CRUD, Roles & Access Control

*Next.js 16 note: every dynamic `[workspaceId]` page below uses the Promise-based params pattern required in Next.js 16 — `{ params }: { params: Promise<{ workspaceId: string }> }` then `const { workspaceId } = await params;`. This pattern is used for every dynamic page in the rest of the series — watch for it.*

### Goal
Let users create/switch workspaces via Clerk's `<OrganizationSwitcher />`, build a workspace dashboard shell, and enforce role-based access (OWNER/ADMIN can manage; MEMBER can only use).

### 1. Helper: get current workspace + membership
`src/lib/workspace.ts`:
```ts
import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";

export async function getCurrentWorkspaceAndRole() {
  const { userId, orgId } = await auth(); // auth() is async in Next.js 16
  if (!userId || !orgId) return null;

  const user = await db.user.findUnique({ where: { clerkId: userId } });
  const workspace = await db.workspace.findUnique({ where: { clerkOrgId: orgId } });
  if (!user || !workspace) return null;

  const membership = await db.membership.findUnique({
    where: { userId_workspaceId: { userId: user.id, workspaceId: workspace.id } },
  });
  if (!membership) return null;

  return { user, workspace, role: membership.role };
}

export function canManageWorkspace(role: "OWNER" | "ADMIN" | "MEMBER") {
  return role === "OWNER" || role === "ADMIN";
}
```

### 2. Dashboard layout with OrganizationSwitcher
`src/app/(dashboard)/layout.tsx`:
```tsx
import { OrganizationSwitcher, UserButton } from "@clerk/nextjs";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="flex items-center justify-between border-b bg-white px-6 py-3">
        <span className="font-bold">Acme Docs AI</span>
        <div className="flex items-center gap-4">
          <OrganizationSwitcher
            afterCreateOrganizationUrl="/workspaces"
            afterSelectOrganizationUrl="/workspaces"
            hidePersonal
          />
          <UserButton afterSignOutUrl="/" />
        </div>
      </nav>
      <main className="mx-auto max-w-5xl px-6 py-8">{children}</main>
    </div>
  );
}
```
`hidePersonal` forces every user into an Organization (workspace) — no "personal account" context, keeping our data model simple (every Document/Message always belongs to a Workspace).

### 3. Workspaces landing page
`src/app/(dashboard)/workspaces/page.tsx`:
```tsx
import { redirect } from "next/navigation";
import { getCurrentWorkspaceAndRole } from "@/lib/workspace";

export default async function WorkspacesPage() {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx) {
    return (
      <div className="text-center">
        <h1 className="text-2xl font-semibold">Select or create a workspace</h1>
        <p className="mt-2 text-gray-600">Use the switcher in the top right to get started.</p>
      </div>
    );
  }
  redirect(`/workspaces/${ctx.workspace.id}`);
}
```

### 4. Workspace home page (Promise-based params — Next.js 16)
`src/app/(dashboard)/workspaces/[workspaceId]/page.tsx`:
```tsx
import { notFound } from "next/navigation";
import { getCurrentWorkspaceAndRole, canManageWorkspace } from "@/lib/workspace";
import Link from "next/link";

export default async function WorkspaceHome({
  params,
}: {
  params: Promise<{ workspaceId: string }>;
}) {
  const { workspaceId } = await params; // await required in Next.js 16
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) notFound();

  return (
    <div>
      <h1 className="text-2xl font-bold">{ctx.workspace.name}</h1>
      <p className="text-gray-600">Your role: {ctx.role}</p>

      <div className="mt-6 grid grid-cols-2 gap-4">
        <Link
          href={`/workspaces/${workspaceId}/documents`}
          className="rounded-lg border bg-white p-6 shadow-sm hover:shadow-md"
        >
          <h2 className="font-semibold">Documents</h2>
          <p className="text-sm text-gray-500">Upload and manage documents</p>
        </Link>
        <Link
          href={`/workspaces/${workspaceId}/chat`}
          className="rounded-lg border bg-white p-6 shadow-sm hover:shadow-md"
        >
          <h2 className="font-semibold">Chat</h2>
          <p className="text-sm text-gray-500">Ask questions about your docs</p>
        </Link>
      </div>

      {canManageWorkspace(ctx.role) && (
        <p className="mt-6 text-sm text-gray-500">
          As an {ctx.role.toLowerCase()}, you can manage billing and members from the
          Clerk Organization Profile (top-right switcher → Manage).
        </p>
      )}
    </div>
  );
}
```

### 5. Enforcing access in Server Actions (real security, not just UI)
Any mutation (uploading docs, sending messages, changing plan) must check membership/role **server-side**. Example pattern we'll reuse throughout:

```ts
"use server";

import { getCurrentWorkspaceAndRole, canManageWorkspace } from "@/lib/workspace";

export async function someAdminOnlyAction(workspaceId: string) {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx || ctx.workspace.id !== workspaceId) {
    throw new Error("Not authorized for this workspace");
  }
  if (!canManageWorkspace(ctx.role)) {
    throw new Error("Only owners/admins can do this");
  }
  // ... perform the mutation
}
```
We hide buttons in the UI for non-admins (good UX), but the server action is the real gate (good security) — never trust the client alone.

**Checkpoint:** Sign in, create a workspace via the switcher, land on `/workspaces/<id>` showing your role and two cards (Documents, Chat — both 404 for now, built in later parts).

**Next:** Part 5 — Document Upload Pipeline.
