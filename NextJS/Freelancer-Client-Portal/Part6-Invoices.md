# Part 6: Invoices

## 1. Concept

Invoices belong to a Project: status (DRAFT, SENT, PAID, OVERDUE), due date, line items, computed total. Admin creates/sends; clients view (and, from Part 10, pay) their own.

Key decision: `Invoice.total` is stored, not recomputed, so historical invoices stay accurate even if pricing logic changes later.

## 2. Invoice number generation

```ts
// src/server/invoice-number.ts
import { db } from "@/server/db";

export async function generateInvoiceNumber(): Promise<string> {
  const count = await db.invoice.count();
  const next = count + 1;
  return `INV-${String(next).padStart(4, "0")}`;
}
```

Tiny race-condition risk under concurrent creation — fine for single-admin MVP (Appendix E notes the sequence-based Phase 2 fix).

## 3. Invoice router

```ts
// src/server/api/routers/invoice.ts
import { z } from "zod";
import { TRPCError } from "@trpc/server";
import { createTRPCRouter, adminProcedure, protectedProcedure } from "@/server/api/trpc";
import { generateInvoiceNumber } from "@/server/invoice-number";

const lineItemInput = z.object({
  description: z.string().min(1),
  quantity: z.number().int().positive().default(1),
  unitPrice: z.number().nonnegative(),
});

function computeTotal(items: { quantity: number; unitPrice: number }[]) {
  return items.reduce((sum, i) => sum + i.quantity * i.unitPrice, 0);
}

export const invoiceRouter = createTRPCRouter({
  listAll: adminProcedure.query(({ ctx }) => {
    return ctx.db.invoice.findMany({
      orderBy: { createdAt: "desc" },
      include: { project: { include: { client: true } } },
    });
  }),

  listByProject: adminProcedure
    .input(z.object({ projectId: z.string() }))
    .query(({ ctx, input }) => {
      return ctx.db.invoice.findMany({
        where: { projectId: input.projectId },
        orderBy: { createdAt: "desc" },
        include: { items: true },
      });
    }),

  byId: protectedProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      const invoice = await ctx.db.invoice.findUniqueOrThrow({
        where: { id: input.id },
        include: { items: true, project: { include: { client: true } } },
      });

      if (ctx.user.role !== "ADMIN" && invoice.project.client.userId !== ctx.user.id) {
        throw new TRPCError({ code: "FORBIDDEN" });
      }

      return invoice;
    }),

  listMine: protectedProcedure.query(({ ctx }) => {
    return ctx.db.invoice.findMany({
      where: { project: { client: { userId: ctx.user.id } } },
      orderBy: { createdAt: "desc" },
      include: { items: true, project: true },
    });
  }),

  create: adminProcedure
    .input(
      z.object({
        projectId: z.string(),
        dueDate: z.coerce.date(),
        items: z.array(lineItemInput).min(1),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const number = await generateInvoiceNumber();
      const total = computeTotal(input.items);

      return ctx.db.invoice.create({
        data: {
          projectId: input.projectId,
          number,
          dueDate: input.dueDate,
          total,
          items: {
            create: input.items.map((i) => ({
              description: i.description,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            })),
          },
        },
        include: { items: true },
      });
    }),

  send: adminProcedure
    .input(z.object({ id: z.string() }))
    .mutation(({ ctx, input }) => {
      return ctx.db.invoice.update({
        where: { id: input.id },
        data: { status: "SENT" },
      });
    }),

  markPaidManually: adminProcedure
    .input(z.object({ id: z.string() }))
    .mutation(({ ctx, input }) => {
      return ctx.db.invoice.update({
        where: { id: input.id },
        data: { status: "PAID", paidAt: new Date() },
      });
    }),
});
```

Register it:

```ts
// src/server/api/root.ts
import { createTRPCRouter } from "@/server/api/trpc";
import { healthRouter } from "@/server/api/routers/health";
import { clientRouter } from "@/server/api/routers/client";
import { projectRouter } from "@/server/api/routers/project";
import { invoiceRouter } from "@/server/api/routers/invoice";

export const appRouter = createTRPCRouter({
  health: healthRouter,
  client: clientRouter,
  project: projectRouter,
  invoice: invoiceRouter,
});

export type AppRouter = typeof appRouter;
```

# Part 6 (continued): Invoice UI (Admin and Client)

Continues from Part 6. Build after the invoice router is registered.

## 4. Admin: invoices list (all)

```tsx
// src/app/admin/invoices/page.tsx
import Link from "next/link";
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";

export default async function AdminInvoicesPage() {
  const api = await getServerApi();
  const invoices = await api.invoice.listAll();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Invoices</h1>
      <ul className="space-y-2">
        {invoices.map((inv) => (
          <li key={inv.id} className="flex items-center justify-between rounded border p-3">
            <div>
              <Link href={`/admin/invoices/${inv.id}`} className="font-medium underline">
                {inv.number}
              </Link>
              <p className="text-sm text-muted-foreground">
                {inv.project.client.name} - {inv.project.name}
              </p>
            </div>
            <div className="flex items-center gap-3">
              <span>${Number(inv.total).toFixed(2)}</span>
              <Badge variant="outline">{inv.status}</Badge>
            </div>
          </li>
        ))}
        {invoices.length === 0 && (
          <p className="text-sm text-muted-foreground">No invoices yet.</p>
        )}
      </ul>
    </div>
  );
}
```

## 5. Admin: invoice detail page with Send / Mark Paid actions

```tsx
// src/app/admin/invoices/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";
import { InvoiceActions } from "./invoice-actions";

export default async function AdminInvoiceDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const invoice = await api.invoice.byId({ id });

  return (
    <div className="max-w-xl space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{invoice.number}</h1>
        <Badge variant="outline">{invoice.status}</Badge>
      </div>

      <div className="text-sm text-muted-foreground">
        <p>Client: {invoice.project.client.name}</p>
        <p>Project: {invoice.project.name}</p>
        <p>Due: {new Date(invoice.dueDate).toLocaleDateString()}</p>
      </div>

      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2">Description</th>
            <th className="py-2">Qty</th>
            <th className="py-2">Unit Price</th>
            <th className="py-2 text-right">Line Total</th>
          </tr>
        </thead>
        <tbody>
          {invoice.items.map((item) => (
            <tr key={item.id} className="border-b">
              <td className="py-2">{item.description}</td>
              <td className="py-2">{item.quantity}</td>
              <td className="py-2">{Number(item.unitPrice).toFixed(2)}</td>
              <td className="py-2 text-right">
                {(item.quantity * Number(item.unitPrice)).toFixed(2)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <p className="text-right text-lg font-semibold">
        Total: {Number(invoice.total).toFixed(2)}
      </p>

      <InvoiceActions invoiceId={invoice.id} status={invoice.status} />
    </div>
  );
}
```

## 6. Invoice actions (Send / Mark Paid buttons)

```tsx
// src/app/admin/invoices/[id]/invoice-actions.tsx
"use client";

import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";

export function InvoiceActions({
  invoiceId,
  status,
}: {
  invoiceId: string;
  status: "DRAFT" | "SENT" | "PAID" | "OVERDUE";
}) {
  const router = useRouter();

  const send = api.invoice.send.useMutation({
    onSuccess: () => {
      toast.success("Invoice sent to client");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  const markPaid = api.invoice.markPaidManually.useMutation({
    onSuccess: () => {
      toast.success("Invoice marked as paid");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  return (
    <div className="flex gap-2">
      {status === "DRAFT" && (
        <Button onClick={() => send.mutate({ id: invoiceId })} disabled={send.isPending}>
          {send.isPending ? "Sending..." : "Send to client"}
        </Button>
      )}
      {status !== "PAID" && (
        <Button
          variant="outline"
          onClick={() => markPaid.mutate({ id: invoiceId })}
          disabled={markPaid.isPending}
        >
          {markPaid.isPending ? "Updating..." : "Mark as paid manually"}
        </Button>
      )}
    </div>
  );
}
```

"Mark as paid manually" stays as an offline-payment fallback even after Stripe (Part 10) automates online payments.

## 7. Client portal: my invoices list

```tsx
// src/app/portal/invoices/page.tsx
import Link from "next/link";
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";

export default async function MyInvoicesPage() {
  const api = await getServerApi();
  const invoices = await api.invoice.listMine();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Invoices</h1>
      <ul className="space-y-2">
        {invoices.map((inv) => (
          <li key={inv.id} className="flex items-center justify-between rounded border p-3">
            <div>
              <Link href={`/portal/invoices/${inv.id}`} className="font-medium underline">
                {inv.number}
              </Link>
              <p className="text-sm text-muted-foreground">{inv.project.name}</p>
            </div>
            <div className="flex items-center gap-3">
              <span>{Number(inv.total).toFixed(2)}</span>
              <Badge variant="outline">{inv.status}</Badge>
            </div>
          </li>
        ))}
        {invoices.length === 0 && (
          <p className="text-sm text-muted-foreground">No invoices yet.</p>
        )}
      </ul>
    </div>
  );
}
```

## 8. Client portal: invoice detail (pay button stubbed until Part 10)

```tsx
// src/app/portal/invoices/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

export default async function MyInvoiceDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const invoice = await api.invoice.byId({ id });

  return (
    <div className="max-w-xl space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{invoice.number}</h1>
        <Badge variant="outline">{invoice.status}</Badge>
      </div>

      <table className="w-full text-sm">
        <thead>
          <tr className="border-b text-left">
            <th className="py-2">Description</th>
            <th className="py-2">Qty</th>
            <th className="py-2">Unit Price</th>
            <th className="py-2 text-right">Line Total</th>
          </tr>
        </thead>
        <tbody>
          {invoice.items.map((item) => (
            <tr key={item.id} className="border-b">
              <td className="py-2">{item.description}</td>
              <td className="py-2">{item.quantity}</td>
              <td className="py-2">{Number(item.unitPrice).toFixed(2)}</td>
              <td className="py-2 text-right">
                {(item.quantity * Number(item.unitPrice)).toFixed(2)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <p className="text-right text-lg font-semibold">
        Total: {Number(invoice.total).toFixed(2)}
      </p>

      {invoice.status !== "PAID" ? (
        <Button disabled className="w-full">
          Pay now (coming in Part 10)
        </Button>
      ) : (
        <p className="text-center text-green-600 font-medium">Paid. Thank you!</p>
      )}
    </div>
  );
}
```

## Checkpoint

- [ ] Admin can create an invoice with multiple line items from a project page
- [ ] `/admin/invoices` and `/admin/invoices/[id]` work, send/mark-paid functional
- [ ] Client sees only their own invoices at `/portal/invoices`

## Next

Continue to **Part 7: Proposals**.
