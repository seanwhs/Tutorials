## AI SaaS Tutorial - Part 13: Enforcing Plan Limits per Workspace

*Next.js 16 note: no dynamic route params in the new lib files here; the workspace home page snippet reuses the same Promise-based params pattern already established in Part 4.*

### Goal
Give Free workspaces real limits (e.g. 3 documents, 20 messages/month) and Pro workspaces higher/unlimited limits, enforced server-side at the exact mutation points (upload, send message).

### 1. Define plan limits in one place
`src/lib/billing/limits.ts`:
```ts
export const PLAN_LIMITS = {
  FREE: {
    maxDocuments: 3,
    maxMessagesPerMonth: 20,
  },
  PRO: {
    maxDocuments: 100,
    maxMessagesPerMonth: 2000,
  },
} as const;

export type PlanName = keyof typeof PLAN_LIMITS;
```

### 2. Helper to get a workspace's current plan + usage
`src/lib/billing/usage.ts`:
```ts
import { db } from "@/lib/db";
import { PLAN_LIMITS, type PlanName } from "./limits";

export async function getWorkspacePlan(workspaceId: string): Promise<PlanName> {
  const subscription = await db.subscription.findUnique({ where: { workspaceId } });
  return (subscription?.plan as PlanName) ?? "FREE";
}

export async function getDocumentCount(workspaceId: string) {
  return db.document.count({ where: { workspaceId } });
}

export async function getMessageCountThisMonth(workspaceId: string) {
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  return db.message.count({
    where: {
      workspaceId,
      role: "USER",
      createdAt: { gte: startOfMonth },
    },
  });
}

export async function checkCanUploadDocument(workspaceId: string) {
  const plan = await getWorkspacePlan(workspaceId);
  const count = await getDocumentCount(workspaceId);
  const limit = PLAN_LIMITS[plan].maxDocuments;
  return { allowed: count < limit, count, limit, plan };
}

export async function checkCanSendMessage(workspaceId: string) {
  const plan = await getWorkspacePlan(workspaceId);
  const count = await getMessageCountThisMonth(workspaceId);
  const limit = PLAN_LIMITS[plan].maxMessagesPerMonth;
  return { allowed: count < limit, count, limit, plan };
}
```

### 3. Enforce at document upload (UploadThing middleware from Part 5)
Update `src/app/api/uploadthing/core.ts`:
```ts
import { checkCanUploadDocument } from "@/lib/billing/usage";

.middleware(async () => {
  const ctx = await getCurrentWorkspaceAndRole();
  if (!ctx) throw new Error("Unauthorized");

  const { allowed, count, limit } = await checkCanUploadDocument(ctx.workspace.id);
  if (!allowed) {
    throw new Error(
      `Document limit reached (${count}/${limit}) for your plan. Upgrade to Pro for more.`
    );
  }

  return { workspaceId: ctx.workspace.id };
})
```
UploadThing surfaces thrown errors from `.middleware()` to the client's `onUploadError` callback, so the existing `alert(...)` in `uploader.tsx` (Part 5) will show this message automatically.

### 4. Enforce at chat message send (chat route from Part 10/11)
Update `src/app/api/chat/route.ts`:
```ts
import { checkCanSendMessage } from "@/lib/billing/usage";

const usage = await checkCanSendMessage(workspaceId);
if (!usage.allowed) {
  return new Response(
    JSON.stringify({
      error: `Message limit reached (${usage.count}/${usage.limit}) for your plan this month. Upgrade to Pro for more.`,
    }),
    { status: 403, headers: { "Content-Type": "application/json" } }
  );
}
```

### 5. Surface limit errors nicely in the chat UI
```tsx
const { messages, sendMessage, status, error } = useChat();

{error && (
  <p className="border-t bg-red-50 p-3 text-sm text-red-700">{error.message}</p>
)}
```

### 6. Show usage on the dashboard (workspace home page, Promise-based params from Part 4)
```tsx
import { getWorkspacePlan, getDocumentCount, getMessageCountThisMonth } from "@/lib/billing/usage";
import { PLAN_LIMITS } from "@/lib/billing/limits";

const plan = await getWorkspacePlan(workspaceId);
const docCount = await getDocumentCount(workspaceId);
const msgCount = await getMessageCountThisMonth(workspaceId);
const limits = PLAN_LIMITS[plan];

<div className="mt-6 rounded-lg border bg-white p-4 text-sm text-gray-600">
  <p>Plan: <strong>{plan}</strong></p>
  <p>Documents: {docCount} / {limits.maxDocuments}</p>
  <p>Messages this month: {msgCount} / {limits.maxMessagesPerMonth}</p>
</div>
```

**Checkpoint:** On a FREE-plan workspace, upload 3 documents, then try a 4th — you should see the limit error. Send 20 messages in a month (or temporarily lower `maxMessagesPerMonth` to 2 to test faster), then confirm the 3rd is blocked with a clear upgrade message. Upgrade to Pro (Part 12) and confirm the same actions succeed with higher limits.

**Next:** Part 14 — Polish (loading/error/empty states).
