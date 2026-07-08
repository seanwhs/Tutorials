# Part 12: Admin Dashboard Polish and Role-Based Views

Previous: Part 11 (Transactional Emails with Resend).

## 1. Concept

Every feature exists but is scattered with no overview, plus a few auth gaps remain. This part: fixes auth gaps, builds real admin dashboard stats, builds a real client portal homepage, adds loading/empty states and portal navigation.

## 2. Fix authorization gaps checklist

Confirm: `client.*` all adminProcedure; `project.list/create/updateStatus` adminProcedure; `project.byId` protectedProcedure+ownership (fixed Part 9); `invoice.*`/`proposal.*`/`message.*` correct as built.

Add a missing procedure — clients listing only their own projects:

```ts
// src/server/api/routers/project.ts (add to projectRouter)
listMine: protectedProcedure.query(({ ctx }) => {
  return ctx.db.project.findMany({
    where: { client: { userId: ctx.user.id } },
    orderBy: { createdAt: "desc" },
  });
}),
```

## 3. Admin dashboard homepage with real stats

```ts
// src/server/api/routers/dashboard.ts
import { createTRPCRouter, adminProcedure } from "@/server/api/trpc";

export const dashboardRouter = createTRPCRouter({
  adminStats: adminProcedure.query(async ({ ctx }) => {
    const [clientCount, activeProjectCount, unpaidInvoices, pendingProposals] = await Promise.all([
      ctx.db.client.count(),
      ctx.db.project.count({ where: { status: "ACTIVE" } }),
      ctx.db.invoice.findMany({
        where: { status: { in: ["SENT", "OVERDUE"] } },
        select: { total: true },
      }),
      ctx.db.proposal.count({ where: { status: "SENT" } }),
    ]);

    const outstandingTotal = unpaidInvoices.reduce((sum, inv) => sum + Number(inv.total), 0);

    return {
      clientCount,
      activeProjectCount,
      outstandingTotal,
      unpaidInvoiceCount: unpaidInvoices.length,
      pendingProposals,
    };
  }),
});
```

Register it, then:

```tsx
// src/app/admin/page.tsx
import { getServerApi } from "@/trpc/server";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function AdminHome() {
  const api = await getServerApi();
  const stats = await api.dashboard.adminStats();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Clients</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">{stats.clientCount}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Active Projects</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">{stats.activeProjectCount}</CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Outstanding</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">
            ${stats.outstandingTotal.toFixed(2)}
            <span className="ml-2 text-sm font-normal text-muted-foreground">
              ({stats.unpaidInvoiceCount} unpaid)
            </span>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm text-muted-foreground">Pending Proposals</CardTitle>
          </CardHeader>
          <CardContent className="text-2xl font-bold">{stats.pendingProposals}</CardContent>
        </Card>
      </div>
    </div>
  );
}
```

## 4. Client portal layout with navigation

```tsx
// src/app/portal/layout.tsx
import Link from "next/link";
import { UserButton } from "@clerk/nextjs";

export default function PortalLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <aside className="w-56 border-r p-4">
        <nav className="flex flex-col gap-2 text-sm">
          <Link href="/portal" className="font-semibold">Overview</Link>
          <Link href="/portal/projects">Projects</Link>
          <Link href="/portal/proposals">Proposals</Link>
          <Link href="/portal/invoices">Invoices</Link>
        </nav>
      </aside>
      <div className="flex-1">
        <header className="flex items-center justify-between border-b p-4">
          <span className="font-semibold">Client Portal</span>
          <UserButton />
        </header>
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
```

## 5. Client portal homepage

```tsx
// src/app/portal/page.tsx
import Link from "next/link";
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";

export default async function PortalHome() {
  const api = await getServerApi();
  const [projects, invoices, proposals] = await Promise.all([
    api.project.listMine(),
    api.invoice.listMine(),
    api.proposal.listMine(),
  ]);

  const unpaidCount = invoices.filter((i) => i.status !== "PAID").length;
  const pendingProposalCount = proposals.filter((p) => p.status === "SENT").length;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Welcome back</h1>

      {pendingProposalCount > 0 && (
        <p className="rounded border border-amber-300 bg-amber-50 p-3 text-sm">
          You have {pendingProposalCount} proposal(s) waiting for your review.{" "}
          <Link href="/portal/proposals" className="underline">Review now</Link>
        </p>
      )}

      {unpaidCount > 0 && (
        <p className="rounded border border-red-300 bg-red-50 p-3 text-sm">
          You have {unpaidCount} unpaid invoice(s).{" "}
          <Link href="/portal/invoices" className="underline">View invoices</Link>
        </p>
      )}

      <div>
        <h2 className="mb-2 text-lg font-semibold">Your Projects</h2>
        <ul className="space-y-2">
          {projects.map((p) => (
            <li key={p.id} className="flex items-center justify-between rounded border p-3">
              <Link href={`/portal/projects/${p.id}`} className="underline">{p.name}</Link>
              <Badge variant="outline">{p.status}</Badge>
            </li>
          ))}
          {projects.length === 0 && (
            <p className="text-sm text-muted-foreground">No projects yet.</p>
          )}
        </ul>
      </div>
    </div>
  );
}
```

## 6. Loading and empty states

```tsx
// src/app/admin/clients/loading.tsx
export default function Loading() {
  return <p className="text-sm text-muted-foreground">Loading clients...</p>;
}
```

Duplicate for other list pages (projects, invoices, portal equivalents).

## Checkpoint

- [ ] `/admin` shows real stats
- [ ] `/portal` shows own projects + contextual banners
- [ ] `project.byId` confirmed protectedProcedure + ownership
- [ ] Loading states appear briefly during navigation

## Next

Continue to **Part 13: Deployment to Vercel**.
