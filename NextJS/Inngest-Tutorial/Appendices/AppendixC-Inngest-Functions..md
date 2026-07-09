# Appendix C: Inngest Functions Reference

Quick reference for every Inngest function built in TaskFlow — its trigger, purpose, steps, and reliability config. All are registered in `src/app/api/inngest/route.ts`.

## helloWorld
- **File**: `src/inngest/functions.ts`
- **Trigger**: event `test/hello.world`
- **Purpose**: introductory smoke-test function from Part 1
- **Steps**: `say-hello`

## syncUserOnCreate
- **File**: `src/inngest/functions/users.ts`
- **Trigger**: event `app/user.created`
- **Purpose**: upserts a `User` row in Postgres and sends a welcome email, in response to the Clerk `user.created` webhook
- **Steps**: `upsert-user-in-db`, `send-welcome-email`
- **Introduced**: Part 3 (upsert step), Part 4 (email step)

## onboardingEmailDrip
- **File**: `src/inngest/functions/users.ts`
- **Trigger**: event `app/user.created` (separate function from `syncUserOnCreate`, same trigger)
- **Purpose**: multi-day onboarding email sequence — a tip after 10 minutes, then a conditional nudge after 3 days if the user still has no projects
- **Steps**: `wait-before-first-tip` (sleep), `send-tip-1-email`, `wait-until-day-3` (sleep), `check-if-user-has-projects`, `send-nudge-email` (conditional)
- **Introduced**: Part 7

## fanOutTaskCreatedNotifications
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: event `task/task.created`
- **Purpose**: looks up all project members and fans out one `notification/member.notify` event per member
- **Steps**: `get-project-members`, `get-task`, `notify-all-members` (step.sendEvent, batched)
- **Introduced**: Part 6

## createNotificationRow
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: event `notification/member.notify`
- **Purpose**: writes one `Notification` row per invocation
- **Steps**: `insert-notification`
- **Reliability config**: `concurrency: { limit: 10 }` (Part 10)
- **Introduced**: Part 6

## sendTaskAssignedEmail
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: event `task/task.assigned`
- **Purpose**: emails the assignee when a task is assigned to them
- **Steps**: `get-assignee`, `get-task`, `send-email`
- **Reliability config**: `throttle: { limit: 10, period: "1m" }` (Part 10)
- **Introduced**: Part 6

## dailyDigest
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: cron `0 8 * * *` (daily, 08:00 UTC)
- **Purpose**: finds users with open (non-DONE) assigned tasks and fans out one digest email request per user
- **Steps**: `get-active-users`, `send-digest-per-user` (step.sendEvent, batched)
- **Introduced**: Part 8

## sendDigestEmail
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: event `email/digest.requested`
- **Purpose**: sends one digest email to one user
- **Steps**: `get-user`, `send-email`
- **Reliability config**: `rateLimit: { limit: 1, period: "1h", key: "event.data.userId" }` (Part 10)
- **Introduced**: Part 8

## overdueTaskSweep
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: cron `0 * * * *` (hourly)
- **Purpose**: finds overdue, non-DONE tasks with an assignee and fans out `notification/member.notify` events (reuses `createNotificationRow`)
- **Steps**: `find-overdue-tasks`, `notify-overdue` (step.sendEvent, batched)
- **Introduced**: Part 8

## taskReviewWorkflow
- **File**: `src/inngest/functions/tasks.ts`
- **Trigger**: event `task/task.submitted-for-review`
- **Purpose**: waits up to 24 hours for a `task/task.reviewed` event matching the same `taskId`; auto-approves on timeout, otherwise applies the human decision
- **Steps**: `wait-for-review-decision` (step.waitForEvent, 24h timeout, matched on `data.taskId`), `auto-approve` or `apply-review-decision`
- **Introduced**: Part 9

## Events index (every event used, and who sends/receives it)

| Event name | Sent by | Received by |
|---|---|---|
| `test/hello.world` | Dashboard / test route (Part 1) | `helloWorld` |
| `app/user.created` | Clerk webhook route | `syncUserOnCreate`, `onboardingEmailDrip` |
| `task/task.created` | `createTask` Server Action | `fanOutTaskCreatedNotifications` |
| `task/task.assigned` | `createTask` Server Action | `sendTaskAssignedEmail` |
| `notification/member.notify` | `fanOutTaskCreatedNotifications`, `overdueTaskSweep` | `createNotificationRow` |
| `email/digest.requested` | `dailyDigest` | `sendDigestEmail` |
| `task/task.submitted-for-review` | `submitTaskForReview` Server Action | `taskReviewWorkflow` |
| `task/task.reviewed` | `reviewTask` Server Action | `taskReviewWorkflow` (via `step.waitForEvent`) |

---

Next up is **Appendix D: Inngest Concepts Cheat Sheet** — want me to bring that up?
