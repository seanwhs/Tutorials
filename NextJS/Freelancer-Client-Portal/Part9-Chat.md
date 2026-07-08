# Part 9: Chat Between Admin and Client

Previous: Part 8 (File Uploads).

## 1. Concept

One flat message thread per Project, shared by admin and client — no separate "conversations", no group chat. Uses the Message model from Part 3.

No WebSockets/Pusher in the MVP (Phase 2 idea, Part 14). Instead: tRPC `useQuery` with `refetchInterval` (polling) — reasonable, low-complexity, no added infrastructure.

## 2. Message router

```ts
// src/server/api/routers/message.ts
import { z } from "zod";
import { TRPCError } from "@trpc/server";
import { createTRPCRouter, protectedProcedure } from "@/server/api/trpc";

async function assertCanAccessProject(
  db: typeof import("@/server/db").db,
  userId: string,
  role: string,
  projectId: string
) {
  const project = await db.project.findUniqueOrThrow({
    where: { id: projectId },
    include: { client: true },
  });

  if (role !== "ADMIN" && project.client.userId !== userId) {
    throw new TRPCError({ code: "FORBIDDEN" });
  }

  return project;
}

export const messageRouter = createTRPCRouter({
  listByProject: protectedProcedure
    .input(z.object({ projectId: z.string() }))
    .query(async ({ ctx, input }) => {
      await assertCanAccessProject(ctx.db, ctx.user.id, ctx.user.role, input.projectId);

      return ctx.db.message.findMany({
        where: { projectId: input.projectId },
        orderBy: { createdAt: "asc" },
        include: { sender: true },
      });
    }),

  send: protectedProcedure
    .input(z.object({ projectId: z.string(), body: z.string().min(1).max(4000) }))
    .mutation(async ({ ctx, input }) => {
      await assertCanAccessProject(ctx.db, ctx.user.id, ctx.user.role, input.projectId);

      return ctx.db.message.create({
        data: {
          projectId: input.projectId,
          senderId: ctx.user.id,
          body: input.body,
        },
        include: { sender: true },
      });
    }),
});
```

Register it in `root.ts`.

## 3. Chat component (shared, client component)

```tsx
// src/components/project-chat.tsx
"use client";

import { useEffect, useRef, useState } from "react";
import { api } from "@/trpc/client";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";

export function ProjectChat({ projectId, currentUserId }: { projectId: string; currentUserId: string }) {
  const [body, setBody] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);
  const utils = api.useUtils();

  const { data: messages } = api.message.listByProject.useQuery(
    { projectId },
    { refetchInterval: 4000 }
  );

  const send = api.message.send.useMutation({
    onSuccess: () => {
      setBody("");
      utils.message.listByProject.invalidate({ projectId });
    },
  });

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  return (
    <div className="flex h-[500px] flex-col rounded border">
      <div className="flex-1 space-y-3 overflow-y-auto p-4">
        {messages?.map((m) => {
          const isMe = m.senderId === currentUserId;
          return (
            <div key={m.id} className={`flex items-start gap-2 ${isMe ? "flex-row-reverse" : ""}`}>
              <Avatar className="h-8 w-8">
                <AvatarFallback>{m.sender.name?.[0] ?? m.sender.email[0]}</AvatarFallback>
              </Avatar>
              <div
                className={`max-w-[70%] rounded-lg px-3 py-2 text-sm ${
                  isMe ? "bg-primary text-primary-foreground" : "bg-muted"
                }`}
              >
                <p>{m.body}</p>
                <p className="mt-1 text-[10px] opacity-70">
                  {new Date(m.createdAt).toLocaleTimeString()}
                </p>
              </div>
            </div>
          );
        })}
        <div ref={bottomRef} />
      </div>

      <div className="flex items-end gap-2 border-t p-3">
        <Textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          placeholder="Type a message..."
          rows={2}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey) {
              e.preventDefault();
              if (body.trim()) send.mutate({ projectId, body });
            }
          }}
        />
        <Button
          onClick={() => body.trim() && send.mutate({ projectId, body })}
          disabled={send.isPending || !body.trim()}
        >
          Send
        </Button>
      </div>
    </div>
  );
}
```

## 4. Wire it into the admin project detail page

```tsx
// src/app/admin/projects/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { auth } from "@clerk/nextjs/server";
import { Badge } from "@/components/ui/badge";
import { NewProposalDialog } from "./new-proposal-dialog";
import { NewInvoiceDialog } from "./new-invoice-dialog";
import { ProjectAttachments } from "@/components/project-attachments";
import { ProjectChat } from "@/components/project-chat";
import { db } from "@/server/db";

export default async function AdminProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const project = await api.project.byId({ id });

  const { userId: clerkUserId } = await auth();
  const me = await db.user.findUniqueOrThrow({ where: { clerkId: clerkUserId! } });

  return (
    <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold">{project.name}</h1>
          <Badge variant="outline">{project.status}</Badge>
        </div>
        <p className="text-muted-foreground">{project.description}</p>

        <div className="flex gap-2">
          <NewProposalDialog projectId={project.id} />
          <NewInvoiceDialog projectId={project.id} />
        </div>

        <ProjectAttachments projectId={project.id} attachments={[]} />
      </div>

      <ProjectChat projectId={project.id} currentUserId={me.id} />
    </div>
  );
}
```

## 5. Wire it into the client portal project detail page

```tsx
// src/app/portal/projects/[id]/page.tsx
import { getServerApi } from "@/trpc/server";
import { auth } from "@clerk/nextjs/server";
import { Badge } from "@/components/ui/badge";
import { ProjectChat } from "@/components/project-chat";
import { db } from "@/server/db";

export default async function ClientProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const api = await getServerApi();
  const project = await api.project.byId({ id });

  const { userId: clerkUserId } = await auth();
  const me = await db.user.findUniqueOrThrow({ where: { clerkId: clerkUserId! } });

  return (
    <div className="grid grid-cols-1 gap-8 lg:grid-cols-2">
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold">{project.name}</h1>
          <Badge variant="outline">{project.status}</Badge>
        </div>
        <p className="text-muted-foreground">{project.description}</p>
      </div>

      <ProjectChat projectId={project.id} currentUserId={me.id} />
    </div>
  );
}
```

**Important**: `project.byId` needs upgrading from `adminProcedure` to `protectedProcedure` + ownership check:

```ts
// src/server/api/routers/project.ts (update byId)
byId: protectedProcedure
  .input(z.object({ id: z.string() }))
  .query(async ({ ctx, input }) => {
    const project = await ctx.db.project.findUniqueOrThrow({
      where: { id: input.id },
      include: { client: true, proposals: true, invoices: true },
    });

    if (ctx.user.role !== "ADMIN" && project.client.userId !== ctx.user.id) {
      throw new TRPCError({ code: "FORBIDDEN" });
    }

    return project;
  }),
```

## Checkpoint

- [ ] Admin and linked client see the same chat thread
- [ ] Messages appear for the other party within ~4s via polling
- [ ] Client can't view/message a project that isn't theirs (FORBIDDEN)

## Next

Continue to **Part 10: Payments with Stripe**.
