# Part 5: Clients and Projects (Clerk Webhook and Admin CRUD)


## 1. Concept

Two things happen here:

1. A Clerk webhook fires on `user.created`/`user.updated`, creating/updating a matching row in our `User` table (default role `CLIENT`). This is what makes `protectedProcedure` actually work.
2. First real CRUD vertical slice: Clients and Projects, admin-only for now.

## 2. Install the webhook verification library

```bash
pnpm add svix
```

## 3. Configure the Clerk webhook

1. Clerk dashboard → Webhooks → Add Endpoint.
2. URL: `https://yourdomain.com/api/webhooks/clerk` (use ngrok for local testing).
3. Subscribe to: `user.created`, `user.updated`.
4. Copy Signing Secret into `.env.local`:

```bash
CLERK_WEBHOOK_SECRET=whsec_xxxxxxxx
```

## 4. Webhook route handler

Uses Next.js 16's async `headers()`:

```ts
// src/app/api/webhooks/clerk/route.ts
import { headers } from "next/headers";
import { Webhook } from "svix";
import { db } from "@/server/db";

type ClerkUserEvent = {
  type: "user.created" | "user.updated";
  data: {
    id: string;
    email_addresses: { id: string; email_address: string }[];
    primary_email_address_id: string;
    first_name: string | null;
    last_name: string | null;
    public_metadata: { role?: "ADMIN" | "CLIENT" };
  };
};

export async function POST(req: Request) {
  const webhookSecret = process.env.CLERK_WEBHOOK_SECRET;
  if (!webhookSecret) {
    return new Response("Missing CLERK_WEBHOOK_SECRET", { status: 500 });
  }

  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return new Response("Missing svix headers", { status: 400 });
  }

  const body = await req.text();
  const wh = new Webhook(webhookSecret);

  let event: ClerkUserEvent;
  try {
    event = wh.verify(body, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    }) as ClerkUserEvent;
  } catch (err) {
    console.error("Clerk webhook verification failed", err);
    return new Response("Invalid signature", { status: 400 });
  }

  if (event.type === "user.created" || event.type === "user.updated") {
    const { id, email_addresses, primary_email_address_id, first_name, last_name, public_metadata } =
      event.data;

    const primaryEmail =
      email_addresses.find((e) => e.id === primary_email_address_id)?.email_address ??
      email_addresses[0]?.email_address;

    if (!primaryEmail) {
      return new Response("No email on user", { status: 400 });
    }

    const name = [first_name, last_name].filter(Boolean).join(" ") || null;
    const role = public_metadata.role === "ADMIN" ? "ADMIN" : "CLIENT";

    await db.user.upsert({
      where: { clerkId: id },
      update: { email: primaryEmail, name, role },
      create: { clerkId: id, email: primaryEmail, name, role },
    });
  }

  return new Response("ok", { status: 200 });
}
```

`/api/webhooks(.*)` must stay in `isPublicRoute` in `src/middleware.ts` (already is).

## 5. Test the webhook locally

Use Clerk dashboard's Testing tab, or sign up a fresh test user and check Prisma Studio.

## Checkpoint A

- Signing up creates a User row with role CLIENT.
- Your admin account has a User row with role ADMIN.

## 6. Client router (admin-only CRUD)

```ts
// src/server/api/routers/client.ts
import { z } from "zod";
import { createTRPCRouter, adminProcedure } from "@/server/api/trpc";

export const clientRouter = createTRPCRouter({
  list: adminProcedure.query(({ ctx }) => {
    return ctx.db.client.findMany({
      orderBy: { createdAt: "desc" },
      include: { projects: true },
    });
  }),

  byId: adminProcedure
    .input(z.object({ id: z.string() }))
    .query(({ ctx, input }) => {
      return ctx.db.client.findUniqueOrThrow({
        where: { id: input.id },
        include: { projects: true },
      });
    }),

  create: adminProcedure
    .input(
      z.object({
        name: z.string().min(1),
        company: z.string().optional(),
        email: z.string().email(),
      })
    )
    .mutation(({ ctx, input }) => {
      return ctx.db.client.create({ data: input });
    }),

  update: adminProcedure
    .input(
      z.object({
        id: z.string(),
        name: z.string().min(1),
        company: z.string().optional(),
        email: z.string().email(),
      })
    )
    .mutation(({ ctx, input }) => {
      const { id, ...data } = input;
      return ctx.db.client.update({ where: { id }, data });
    }),

  delete: adminProcedure
    .input(z.object({ id: z.string() }))
    .mutation(({ ctx, input }) => {
      return ctx.db.client.delete({ where: { id: input.id } });
    }),
});
```

## 7. Project router

```ts
// src/server/api/routers/project.ts
import { z } from "zod";
import { createTRPCRouter, adminProcedure } from "@/server/api/trpc";

export const projectRouter = createTRPCRouter({
  list: adminProcedure.query(({ ctx }) => {
    return ctx.db.project.findMany({
      orderBy: { createdAt: "desc" },
      include: { client: true },
    });
  }),

  byId: adminProcedure
    .input(z.object({ id: z.string() }))
    .query(({ ctx, input }) => {
      return ctx.db.project.findUniqueOrThrow({
        where: { id: input.id },
        include: { client: true, proposals: true, invoices: true },
      });
    }),

  create: adminProcedure
    .input(
      z.object({
        clientId: z.string(),
        name: z.string().min(1),
        description: z.string().optional(),
      })
    )
    .mutation(({ ctx, input }) => {
      return ctx.db.project.create({ data: input });
    }),

  updateStatus: adminProcedure
    .input(
      z.object({
        id: z.string(),
        status: z.enum(["ACTIVE", "ON_HOLD", "COMPLETED"]),
      })
    )
    .mutation(({ ctx, input }) => {
      return ctx.db.project.update({
        where: { id: input.id },
        data: { status: input.status },
      });
    }),
});
```

Note: `project.byId` is upgraded to `protectedProcedure` + ownership check in Part 9. Keep as `adminProcedure` for now.

## 8. Register routers

```ts
// src/server/api/root.ts
import { createTRPCRouter } from "@/server/api/trpc";
import { healthRouter } from "@/server/api/routers/health";
import { clientRouter } from "@/server/api/routers/client";
import { projectRouter } from "@/server/api/routers/project";

export const appRouter = createTRPCRouter({
  health: healthRouter,
  client: clientRouter,
  project: projectRouter,
});

export type AppRouter = typeof appRouter;
```

## Checkpoint

- [ ] Webhook creates User rows on sign up
- [ ] `client` and `project` routers registered, no type errors

# Part 5 (continued): Admin UI for Clients and Projects

Continues directly from Part 5. Build after the routers are in place.

## 9. Admin layout with navigation

```tsx
// src/app/admin/layout.tsx
import Link from "next/link";
import { UserButton } from "@clerk/nextjs";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <aside className="w-56 border-r p-4">
        <nav className="flex flex-col gap-2 text-sm">
          <Link href="/admin" className="font-semibold">Dashboard</Link>
          <Link href="/admin/clients">Clients</Link>
          <Link href="/admin/projects">Projects</Link>
        </nav>
      </aside>
      <div className="flex-1">
        <header className="flex items-center justify-between border-b p-4">
          <span className="font-semibold">Admin</span>
          <UserButton />
        </header>
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
```

## 10. Clients list page

```tsx
// src/app/admin/clients/page.tsx
import Link from "next/link";
import { getServerApi } from "@/trpc/server";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { NewClientDialog } from "./new-client-dialog";

export default async function ClientsPage() {
  const api = await getServerApi();
  const clients = await api.client.list();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Clients</h1>
        <NewClientDialog />
      </div>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Company</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Projects</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {clients.map((c) => (
            <TableRow key={c.id}>
              <TableCell>
                <Link href={`/admin/clients/${c.id}`} className="underline">{c.name}</Link>
              </TableCell>
              <TableCell>{c.company ?? "-"}</TableCell>
              <TableCell>{c.email}</TableCell>
              <TableCell>{c.projects.length}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
```

## 11. New client dialog

```tsx
// src/app/admin/clients/new-client-dialog.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";

export function NewClientDialog() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [company, setCompany] = useState("");
  const [email, setEmail] = useState("");

  const createClient = api.client.create.useMutation({
    onSuccess: () => {
      toast.success("Client created");
      setOpen(false);
      setName("");
      setCompany("");
      setEmail("");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>New Client</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New Client</DialogTitle>
        </DialogHeader>
        <div className="space-y-3">
          <div>
            <Label htmlFor="name">Name</Label>
            <Input id="name" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div>
            <Label htmlFor="company">Company (optional)</Label>
            <Input id="company" value={company} onChange={(e) => setCompany(e.target.value)} />
          </div>
          <div>
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
        </div>
        <DialogFooter>
          <Button
            disabled={createClient.isPending}
            onClick={() =>
              createClient.mutate({ name, company: company || undefined, email })
            }
          >
            {createClient.isPending ? "Creating..." : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

## 12. Client detail page (async params)

```tsx
// src/app/admin/clients/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";
import { NewProjectDialog } from "./new-project-dialog";

export default async function ClientDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const client = await api.client.byId({ id });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">{client.name}</h1>
        <p className="text-muted-foreground">{client.company} - {client.email}</p>
      </div>

      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold">Projects</h2>
        <NewProjectDialog clientId={client.id} />
      </div>

      <ul className="space-y-2">
        {client.projects.map((p) => (
          <li key={p.id} className="flex items-center justify-between rounded border p-3">
            <span>{p.name}</span>
            <Badge variant="outline">{p.status}</Badge>
          </li>
        ))}
        {client.projects.length === 0 && (
          <p className="text-sm text-muted-foreground">No projects yet.</p>
        )}
      </ul>
    </div>
  );
}
```

## 13. New project dialog

```tsx
// src/app/admin/clients/[id]/new-project-dialog.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";

export function NewProjectDialog({ clientId }: { clientId: string }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");

  const createProject = api.project.create.useMutation({
    onSuccess: () => {
      toast.success("Project created");
      setOpen(false);
      setName("");
      setDescription("");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm">New Project</Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>New Project</DialogTitle>
        </DialogHeader>
        <div className="space-y-3">
          <div>
            <Label htmlFor="pname">Name</Label>
            <Input id="pname" value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div>
            <Label htmlFor="pdesc">Description (optional)</Label>
            <Textarea id="pdesc" value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
        </div>
        <DialogFooter>
          <Button
            disabled={createProject.isPending}
            onClick={() =>
              createProject.mutate({ clientId, name, description: description || undefined })
            }
          >
            {createProject.isPending ? "Creating..." : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

## 14. Projects list page (all projects across clients)

```tsx
// src/app/admin/projects/page.tsx
import Link from "next/link";
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";

export default async function ProjectsPage() {
  const api = await getServerApi();
  const projects = await api.project.list();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Projects</h1>
      <ul className="space-y-2">
        {projects.map((p) => (
          <li key={p.id} className="flex items-center justify-between rounded border p-3">
            <div>
              <Link href={`/admin/projects/${p.id}`} className="font-medium underline">
                {p.name}
              </Link>
              <p className="text-sm text-muted-foreground">{p.client.name}</p>
            </div>
            <Badge variant="outline">{p.status}</Badge>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

## Checkpoint

- [ ] `/admin/clients` shows table + "New Client" button; creating adds a row
- [ ] `/admin/clients/[id]` shows details, lets you add a project
- [ ] `/admin/projects` lists all projects with status badges

## Next

Continue to **Part 6: Invoices**.
