# Appendix A INDEX: Full Codebase Reference

Unlike some other tutorial series where Appendix A duplicates every file in dedicated reference notes, TaskFlow's codebase is small enough that each part already contains the complete, final version of every file it introduces or modifies. Use this index as a map to find any file's authoritative final version quickly, without hunting through all 12 parts.

## Configuration and client setup

- `src/inngest/client.ts` (Inngest client + typed `Events`) — introduced in **Part 1**, extended in **Part 2** (typed schemas), **Part 3b** (`app/user.created`), **Part 6** (`notification/member.notify`, `email/task.assigned`), **Part 8** (`email/digest.requested`), **Part 9** (`task/task.submitted-for-review`, `task/task.reviewed`)
- `src/app/api/inngest/route.ts` (the `serve()` handler) — introduced in **Part 1**, updated in every subsequent part as new functions are added; final full function list shown in **Part 12**
- `src/lib/prisma.ts` (Prisma client singleton) — **Part 3b**
- `src/lib/email.ts` (Resend client) — **Part 4**
- `src/lib/current-user.ts` (Clerk → DB user helper) — **Part 5**
- `src/proxy.ts` (Clerk middleware, Next.js 16 convention) — **Part 3**
- `prisma/schema.prisma` (full data model) — introduced in **Part 3b** (User, Project, ProjectMember, Task), extended in **Part 6** (Notification), extended in **Part 9** (TaskStatus enum additions)

## Inngest functions

- `src/inngest/functions.ts` (`helloWorld`) — **Part 1**
- `src/inngest/functions/users.ts` (`syncUserOnCreate`, `onboardingEmailDrip`) — **Part 3b**, **Part 4**, **Part 7**
- `src/inngest/functions/tasks.ts` (`fanOutTaskCreatedNotifications`, `createNotificationRow`, `sendTaskAssignedEmail`, `dailyDigest`, `sendDigestEmail`, `overdueTaskSweep`, `taskReviewWorkflow`) — **Part 6**, **Part 8**, **Part 9**, reliability config added in **Part 10**

## Webhook and API routes

- `src/app/api/webhooks/clerk/route.ts` (Clerk webhook → `app/user.created` event) — **Part 3b**, idempotency key added in **Part 10**

## Pages and Server Actions

- `src/app/projects/page.tsx`, `src/app/projects/actions.ts` (project list + create) — **Part 5**
- `src/app/projects/[projectId]/page.tsx`, `src/app/projects/[projectId]/actions.ts` (task list, create, review actions) — **Part 5**, review UI added in **Part 9**
- `src/app/notifications/page.tsx` — **Part 6**

## Tests

- `src/inngest/functions/tasks.test.ts` (example `InngestTestEngine` test) — **Part 11**
- `src/lib/digest-rules.ts` + `src/lib/digest-rules.test.ts` (extracted pure logic + unit test) — **Part 11**

## How to reconstruct the full project from scratch

Follow Parts 1 through 12 in order — each part's code samples are complete and final for the files they touch (no partial snippets requiring later "fill in the rest"). By the end of Part 12 you will have every file listed above, wired together and deployed.

---

Next up is **Appendix B: Environment Variables Reference** — want me to bring that up?
