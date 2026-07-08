# Part 7: Proposals

Previous: Part 6 (Invoices). UI half is in "Part 7 (continued)".

## 1. Concept

A Proposal belongs to a Project. Admin drafts one (title, content, amount), sends it, and the client Approves or Requests Changes (with a comment logged as a Message, reusing the Part 9 model).

Status flow: DRAFT → SENT → APPROVED or CHANGES_REQUESTED. If changes requested, admin edits and re-sends (back to SENT).

## 2. Proposal router

```ts
// src/server/api/routers/proposal.ts
import { z } from "zod";
import { TRPCError } from "@trpc/server";
import { createTRPCRouter, adminProcedure, protectedProcedure } from "@/server/api/trpc";

export const proposalRouter = createTRPCRouter({
  listByProject: adminProcedure
    .input(z.object({ projectId: z.string() }))
    .query(({ ctx, input }) => {
      return ctx.db.proposal.findMany({
        where: { projectId: input.projectId },
        orderBy: { createdAt: "desc" },
      });
    }),

  listMine: protectedProcedure.query(({ ctx }) => {
    return ctx.db.proposal.findMany({
      where: { project: { client: { userId: ctx.user.id } } },
      orderBy: { createdAt: "desc" },
      include: { project: true },
    });
  }),

  byId: protectedProcedure
    .input(z.object({ id: z.string() }))
    .query(async ({ ctx, input }) => {
      const proposal = await ctx.db.proposal.findUniqueOrThrow({
        where: { id: input.id },
        include: { project: { include: { client: true } } },
      });

      if (ctx.user.role !== "ADMIN" && proposal.project.client.userId !== ctx.user.id) {
        throw new TRPCError({ code: "FORBIDDEN" });
      }

      return proposal;
    }),

  create: adminProcedure
    .input(
      z.object({
        projectId: z.string(),
        title: z.string().min(1),
        content: z.string().min(1),
        amount: z.number().nonnegative(),
      })
    )
    .mutation(({ ctx, input }) => {
      return ctx.db.proposal.create({ data: input });
    }),

  send: adminProcedure
    .input(z.object({ id: z.string() }))
    .mutation(({ ctx, input }) => {
      return ctx.db.proposal.update({
        where: { id: input.id },
        data: { status: "SENT", sentAt: new Date() },
      });
    }),

  approve: protectedProcedure
    .input(z.object({ id: z.string() }))
    .mutation(async ({ ctx, input }) => {
      const proposal = await ctx.db.proposal.findUniqueOrThrow({
        where: { id: input.id },
        include: { project: { include: { client: true } } },
      });

      if (ctx.user.role !== "ADMIN" && proposal.project.client.userId !== ctx.user.id) {
        throw new TRPCError({ code: "FORBIDDEN" });
      }

      return ctx.db.proposal.update({
        where: { id: input.id },
        data: { status: "APPROVED", respondedAt: new Date() },
      });
    }),

  requestChanges: protectedProcedure
    .input(z.object({ id: z.string(), comment: z.string().min(1) }))
    .mutation(async ({ ctx, input }) => {
      const proposal = await ctx.db.proposal.findUniqueOrThrow({
        where: { id: input.id },
        include: { project: { include: { client: true } } },
      });

      if (ctx.user.role !== "ADMIN" && proposal.project.client.userId !== ctx.user.id) {
        throw new TRPCError({ code: "FORBIDDEN" });
      }

      const [updated] = await ctx.db.$transaction([
        ctx.db.proposal.update({
          where: { id: input.id },
          data: { status: "CHANGES_REQUESTED", respondedAt: new Date() },
        }),
        ctx.db.message.create({
          data: {
            projectId: proposal.projectId,
            senderId: ctx.user.id,
            body: `Requested changes on proposal "${proposal.title}": ${input.comment}`,
          },
        }),
      ]);

      return updated;
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
import { proposalRouter } from "@/server/api/routers/proposal";

export const appRouter = createTRPCRouter({
  health: healthRouter,
  client: clientRouter,
  project: projectRouter,
  invoice: invoiceRouter,
  proposal: proposalRouter,
});

export type AppRouter = typeof appRouter;
```

`ctx.db.$transaction` in `requestChanges` ensures the status update and message log both succeed or both fail together.

---

# Part 7 (continued): Proposal UI (Admin and Client)

Continues from Part 7. Build after the proposal router is registered.

## 3. Admin: new proposal dialog (add to project detail page)

```tsx
// src/app/admin/projects/[id]/new-proposal-dialog.tsx
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

export function NewProposalDialog({ projectId }: { projectId: string }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [amount, setAmount] = useState(0);

  const createProposal = api.proposal.create.useMutation({
    onSuccess: () => {
      toast.success("Proposal created as draft");
      setOpen(false);
      setTitle("");
      setContent("");
      setAmount(0);
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button size="sm">New Proposal</Button>
      </DialogTrigger>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>New Proposal</DialogTitle>
        </DialogHeader>
        <div className="space-y-3">
          <div>
            <Label htmlFor="title">Title</Label>
            <Input id="title" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div>
            <Label htmlFor="content">Details</Label>
            <Textarea
              id="content"
              rows={6}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Scope of work, deliverables, timeline..."
            />
          </div>
          <div>
            <Label htmlFor="amount">Amount ($)</Label>
            <Input
              id="amount"
              type="number"
              min={0}
              step="0.01"
              value={amount}
              onChange={(e) => setAmount(Number(e.target.value))}
            />
          </div>
        </div>
        <DialogFooter>
          <Button
            disabled={createProposal.isPending}
            onClick={() => createProposal.mutate({ projectId, title, content, amount })}
          >
            {createProposal.isPending ? "Creating..." : "Save as Draft"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
```

## 4. Admin: proposal detail with Send action

```tsx
// src/app/admin/proposals/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";
import { SendProposalButton } from "./send-proposal-button";

export default async function AdminProposalDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const proposal = await api.proposal.byId({ id });

  return (
    <div className="max-w-2xl space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{proposal.title}</h1>
        <Badge variant="outline">{proposal.status}</Badge>
      </div>
      <p className="whitespace-pre-wrap">{proposal.content}</p>
      <p className="text-lg font-semibold">Amount: ${Number(proposal.amount).toFixed(2)}</p>
      {proposal.status === "DRAFT" && <SendProposalButton proposalId={proposal.id} />}
    </div>
  );
}
```

```tsx
// src/app/admin/proposals/[id]/send-proposal-button.tsx
"use client";

import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";

export function SendProposalButton({ proposalId }: { proposalId: string }) {
  const router = useRouter();
  const send = api.proposal.send.useMutation({
    onSuccess: () => {
      toast.success("Proposal sent to client");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  return (
    <Button onClick={() => send.mutate({ id: proposalId })} disabled={send.isPending}>
      {send.isPending ? "Sending..." : "Send to client"}
    </Button>
  );
}
```

## 5. Client portal: my proposals list

```tsx
// src/app/portal/proposals/page.tsx
import Link from "next/link";
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";

export default async function MyProposalsPage() {
  const api = await getServerApi();
  const proposals = await api.proposal.listMine();

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Proposals</h1>
      <ul className="space-y-2">
        {proposals.map((p) => (
          <li key={p.id} className="flex items-center justify-between rounded border p-3">
            <div>
              <Link href={`/portal/proposals/${p.id}`} className="font-medium underline">
                {p.title}
              </Link>
              <p className="text-sm text-muted-foreground">{p.project.name}</p>
            </div>
            <Badge variant="outline">{p.status}</Badge>
          </li>
        ))}
        {proposals.length === 0 && (
          <p className="text-sm text-muted-foreground">No proposals yet.</p>
        )}
      </ul>
    </div>
  );
}
```

## 6. Client portal: proposal detail with Approve / Request Changes

```tsx
// src/app/portal/proposals/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { Badge } from "@/components/ui/badge";
import { ProposalResponseActions } from "./proposal-response-actions";

export default async function MyProposalDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const proposal = await api.proposal.byId({ id });

  return (
    <div className="max-w-2xl space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">{proposal.title}</h1>
        <Badge variant="outline">{proposal.status}</Badge>
      </div>
      <p className="whitespace-pre-wrap">{proposal.content}</p>
      <p className="text-lg font-semibold">Amount: ${Number(proposal.amount).toFixed(2)}</p>

      {proposal.status === "SENT" && <ProposalResponseActions proposalId={proposal.id} />}
      {proposal.status === "APPROVED" && (
        <p className="font-medium text-green-600">You approved this proposal. Thank you!</p>
      )}
      {proposal.status === "CHANGES_REQUESTED" && (
        <p className="font-medium text-amber-600">
          You requested changes. The freelancer will follow up.
        </p>
      )}
    </div>
  );
}
```

```tsx
// src/app/portal/proposals/[id]/proposal-response-actions.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog";

export function ProposalResponseActions({ proposalId }: { proposalId: string }) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [comment, setComment] = useState("");

  const approve = api.proposal.approve.useMutation({
    onSuccess: () => {
      toast.success("Proposal approved");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  const requestChanges = api.proposal.requestChanges.useMutation({
    onSuccess: () => {
      toast.success("Changes requested");
      setOpen(false);
      setComment("");
      router.refresh();
    },
    onError: (err) => toast.error(err.message),
  });

  return (
    <div className="flex gap-2">
      <Button onClick={() => approve.mutate({ id: proposalId })} disabled={approve.isPending}>
        {approve.isPending ? "Approving..." : "Approve"}
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogTrigger asChild>
          <Button variant="outline">Request Changes</Button>
        </DialogTrigger>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>What would you like changed?</DialogTitle>
          </DialogHeader>
          <Textarea
            rows={4}
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Describe the changes you'd like..."
          />
          <DialogFooter>
            <Button
              disabled={requestChanges.isPending || !comment.trim()}
              onClick={() => requestChanges.mutate({ id: proposalId, comment })}
            >
              {requestChanges.isPending ? "Sending..." : "Submit"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
```

## Checkpoint

- [ ] Admin creates a draft proposal from a project page, sends it
- [ ] Client sees SENT proposals at `/portal/proposals`, can Approve or Request Changes
- [ ] Requesting changes creates a Message row and flips status to CHANGES_REQUESTED

## Next

Continue to **Part 8: File Uploads with UploadThing**.
