# Part 9: Human-in-the-Loop with step.waitForEvent

## 1. The scenario

Let's add a lightweight "task review" flow: when a task is marked `DONE` by its assignee, the project creator should get 24 hours to approve or reject it before it's auto-approved. This requires a function to **pause and wait for a human action** (clicking Approve/Reject in the UI), with a timeout that fires if nobody responds in time. This is exactly what `step.waitForEvent` is for.

## 2. Add a status and event types

We already have `TaskStatus` with `TODO | IN_PROGRESS | DONE`. Let's add `IN_REVIEW` and `APPROVED`:

```prisma
enum TaskStatus {
  TODO
  IN_PROGRESS
  IN_REVIEW
  APPROVED
  DONE
}
```

```bash
npx prisma db push && npx prisma generate
```

Add event types to `src/inngest/client.ts`:

```ts
"task/task.submitted-for-review": {
  data: { taskId: string; projectId: string };
};
"task/task.reviewed": {
  data: { taskId: string; approved: boolean; reviewerUserId: string };
};
```

## 3. Server Action to submit for review

Add to `src/app/projects/[projectId]/actions.ts`:

```ts
export async function submitTaskForReview(taskId: string, projectId: string) {
  await prisma.task.update({ where: { id: taskId }, data: { status: "IN_REVIEW" } });

  await inngest.send({
    name: "task/task.submitted-for-review",
    data: { taskId, projectId },
  });

  revalidatePath(`/projects/${projectId}`);
}

export async function reviewTask(taskId: string, approved: boolean, reviewerUserId: string) {
  await inngest.send({
    name: "task/task.reviewed",
    data: { taskId, approved, reviewerUserId },
  });
}
```

Note `reviewTask` itself doesn't update the database — it just announces "a review decision happened" as an event. The waiting function (below) is what actually reacts and updates state. This keeps the "did a human approve or reject" signal in one place.

## 4. The waiting function

Add to `src/inngest/functions/tasks.ts`:

```ts
export const taskReviewWorkflow = inngest.createFunction(
  { id: "task-review-workflow" },
  { event: "task/task.submitted-for-review" },
  async ({ event, step }) => {
    const reviewEvent = await step.waitForEvent("wait-for-review-decision", {
      event: "task/task.reviewed",
      timeout: "24h",
      match: "data.taskId",
    });

    if (reviewEvent === null) {
      // Timed out - nobody reviewed within 24 hours. Auto-approve.
      await step.run("auto-approve", async () => {
        await prisma.task.update({ where: { id: event.data.taskId }, data: { status: "APPROVED" } });
      });
      return { outcome: "auto-approved" };
    }

    await step.run("apply-review-decision", async () => {
      await prisma.task.update({
        where: { id: event.data.taskId },
        data: { status: reviewEvent.data.approved ? "APPROVED" : "IN_PROGRESS" },
      });
    });

    return { outcome: reviewEvent.data.approved ? "approved" : "rejected" };
  }
);
```

Key details on `step.waitForEvent`:

- `event: "task/task.reviewed"` — the event name this step is listening for.
- `timeout: "24h"` — how long to wait before giving up. If no matching event arrives in this window, the step resolves to `null` rather than throwing.
- `match: "data.taskId"` — this is crucial. Without `match`, the *first* `task/task.reviewed` event for *any* task would satisfy *every* waiting function, which is wrong. `match: "data.taskId"` tells Inngest: only resolve this wait if the incoming event's `data.taskId` equals this run's original `event.data.taskId`. Under the hood this compares the field on both the triggering event and the incoming event.

This is functionally similar to `step.sleep`, but instead of waking up after a fixed duration, it wakes up early the moment a matching event arrives (or at the timeout, whichever comes first) — and just like sleep, your serverless function isn't running (or costing anything) while it waits.

## 5. Add Approve/Reject buttons to the UI

Update the project detail page to show review actions for tasks `IN_REVIEW`:

```tsx
{project.tasks.filter((t) => t.status === "IN_REVIEW").map((t) => (
  <li key={t.id} className="border rounded p-3 flex justify-between items-center">
    <span>{t.title} — awaiting review</span>
    <div className="flex gap-2">
      <form action={async () => { "use server"; await reviewTask(t.id, true, user.id); }}>
        <button className="bg-green-600 text-white px-3 py-1 rounded text-sm">Approve</button>
      </form>
      <form action={async () => { "use server"; await reviewTask(t.id, false, user.id); }}>
        <button className="bg-red-600 text-white px-3 py-1 rounded text-sm">Reject</button>
      </form>
    </div>
  </li>
))}
```

(You'll need `user` — the current DB user — available in this server component; pull it in alongside `project`.)

## 6. Register and test

Add `taskReviewWorkflow` to the `functions` array in the serve route. To test the timeout path quickly, temporarily change `timeout: "24h"` to `timeout: "30 seconds"`, submit a task for review, and **don't** click Approve/Reject — watch the Dev Server Runs tab show the function "Waiting" and then automatically resolve to `auto-approved` after 30 seconds. Then test the happy path: submit another task, click Approve within the timeout window, and confirm the run resolves immediately with `outcome: "approved"` rather than waiting the full duration. Revert the timeout to `"24h"` afterward.

## Checkpoint

- [ ] `taskReviewWorkflow` uses `step.waitForEvent` with `timeout` and `match`
- [ ] Confirmed the auto-approve timeout path works
- [ ] Confirmed a real Approve/Reject click resolves the wait immediately instead of waiting for the timeout
- [ ] Understand why `match` is necessary to avoid cross-task interference

## Troubleshooting

**Wrong task gets approved/rejected.** Almost always a missing or incorrect `match` expression — double check it references the correct field path (`data.taskId`) on both sides.

**Function never resolves even after clicking Approve.** Confirm `reviewTask`'s `inngest.send()` call actually includes `taskId` in `data` with the exact same value the waiting function is matching against — a mismatched ID (e.g. sending the wrong task's ID) will never satisfy the match.

Next: **Part 10** covers reliability controls in depth — retries and error handling, idempotency keys, concurrency limits, rate limiting, and throttling — so your functions behave well under real-world load and failure conditions. Want me to bring that up next?
