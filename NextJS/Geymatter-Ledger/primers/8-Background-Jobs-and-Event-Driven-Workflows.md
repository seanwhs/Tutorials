# Primer 8 — Background Jobs and Event-Driven Workflows

**Product:** GreyMatter Ledger  
**Document type:** Primer  
**Audience:** Developers, technical founders, product engineers, maintainers  
**Goal:** Explain background jobs, scheduled workflows, and event-driven architecture as used in GreyMatter Ledger  

---

# 1. Why Background Jobs Matter

Not every task should happen during a user’s page request.

Some tasks are:

```txt
Slow
Scheduled
Retryable
Triggered by events
Not necessary for immediate page response
```

Examples:

```txt
Send invoice confirmation
Send overdue invoice reminders
Generate recurring invoices
Process large imports
Sync external systems
```

If the user clicks “Create invoice,” the app should save the invoice and return quickly.

Extra work can happen in the background.

GreyMatter Ledger uses:

```txt
Inngest
```

for background jobs and event-driven workflows.

---

# 2. Request-Time Work vs Background Work

## Request-Time Work

Happens while the user waits.

Examples:

```txt
Create invoice row
Post journal entry
Return success message
```

Request-time work should be:

```txt
Fast
Required immediately
User-facing
Transactional where needed
```

---

## Background Work

Happens separately.

Examples:

```txt
Send confirmation email
Send overdue reminder
Generate monthly invoice
Run scheduled checks
```

Background work can be:

```txt
Delayed
Retried
Scheduled
Observed in job dashboard
```

---

# 3. Coffee Shop Analogy

Request-time work:

```txt
You order coffee and wait at the counter.
```

Background work:

```txt
You place a catering order for tomorrow.
The shop prepares it later.
```

Both are important, but they happen on different timelines.

---

# 4. What Is an Event?

An event is a message saying something happened.

Examples:

```txt
invoice.created
app/health.check
```

An event usually has:

```txt
name
data
timestamp
```

Example:

```ts
await inngest.send({
  name: "invoice.created",
  data: {
    invoiceId: "invoice-id",
    invoiceNumber: "INV-2026-0001",
    organizationId: "org-db-id",
    customerId: "customer-id",
    totalCents: 10900,
  },
});
```

---

# 5. What Is an Event Producer?

An event producer is the code that sends an event.

In GreyMatter Ledger, invoice creation produces:

```txt
invoice.created
```

The producer is in:

```txt
services/invoices/invoice-services.ts
```

After the invoice and journal entry are successfully created, the service sends the event.

---

# 6. What Is an Event Consumer?

An event consumer is a function that listens for an event.

In GreyMatter Ledger:

```txt
invoiceCreatedConfirmation
```

listens for:

```txt
invoice.created
```

Location:

```txt
inngest/functions.ts
```

---

# 7. What Is a Scheduled Job?

A scheduled job runs on a timetable.

Example:

```txt
Every day at midnight
```

In cron syntax:

```txt
0 0 * * *
```

GreyMatter Ledger includes scheduled jobs for:

```txt
Daily overdue invoice reminders
Recurring invoice scheduler stub
```

---

# 8. Why Use Inngest?

Inngest provides:

```txt
Event handling
Scheduled functions
Retries
Step-based workflows
Local dev server
Dashboard visibility
Next.js integration
```

It works well for event-driven app workflows.

---

# 9. Inngest Files in GreyMatter Ledger

Important files:

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
app/api/inngest/route.ts
```

---

## `inngest/client.ts`

Creates the Inngest client:

```ts
export const inngest = new Inngest({
  id: "greymatter-ledger",
  name: "GreyMatter Ledger",
});
```

---

## `inngest/events.ts`

Defines event names and event payload types.

Example:

```ts
export const inngestEvents = {
  invoiceCreated: "invoice.created",
} as const;
```

---

## `inngest/functions.ts`

Defines background functions.

Examples:

```txt
backgroundHealthCheck
invoiceCreatedConfirmation
dailyOverdueInvoiceReminders
dailyRecurringInvoiceScheduler
```

---

## `app/api/inngest/route.ts`

Exposes the Inngest endpoint:

```txt
/api/inngest
```

This lets Inngest discover and invoke functions.

---

# 10. Inngest Route Handler

The route handler looks like:

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { inngestFunctions } from "@/inngest/functions";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: inngestFunctions,
});
```

Endpoint:

```txt
/api/inngest
```

Local:

```txt
http://localhost:3000/api/inngest
```

Production:

```txt
https://your-domain.com/api/inngest
```

---

# 11. Background Health Check

GreyMatter Ledger includes a simple test event:

```txt
app/health.check
```

Triggered from:

```txt
/settings/background-jobs
```

Purpose:

```txt
Verify Inngest is connected.
```

---

# 12. Invoice Created Event

When an invoice is created successfully, GreyMatter Ledger sends:

```txt
invoice.created
```

Payload:

```ts
{
  invoiceId: string;
  invoiceNumber: string;
  organizationId: string;
  customerId: string;
  totalCents: number;
}
```

The listener:

```txt
invoiceCreatedConfirmation
```

prepares a confirmation payload.

Future enhancement:

```txt
Send actual customer email.
```

---

# 13. Daily Overdue Invoice Reminder Job

Function:

```txt
dailyOverdueInvoiceReminders
```

Schedule:

```txt
0 0 * * *
```

It finds invoices where:

```txt
due_date < today
status not in paid, void
```

Current tutorial behavior:

```txt
Prepare reminder payloads.
```

Future production behavior:

```txt
Send reminder emails.
Log reminder history.
Avoid duplicate reminders.
```

---

# 14. Recurring Invoice Scheduler

Function:

```txt
dailyRecurringInvoiceScheduler
```

Schedule:

```txt
15 0 * * *
```

In the tutorial, this is a stub.

Why?

Because scheduled jobs do not naturally have an active signed-in user or active organization context.

A production recurring invoice generator should use:

```txt
System actor context
Explicit organization iteration
Tenant-scoped generation
Audit logs
Idempotency controls
```

---

# 15. Background Jobs and Tenant Context

This is very important.

Normal user request:

```txt
User is signed in.
Active organization is selected.
```

Scheduled background job:

```txt
No active user.
No active organization.
```

Therefore, background jobs should not casually call:

```ts
requireCurrentDatabaseOrganization()
```

unless they are triggered by a user action.

For scheduled jobs, use explicit organization scope.

Example future pattern:

```ts
const organizations = await db.select().from(organizations);

for (const organization of organizations) {
  await processOrganization(organization.id);
}
```

---

# 16. System Actor Pattern

A production background job should often act as:

```txt
system
```

not a normal user.

Audit logs might store:

```txt
actor_user_id = null
actor = system
```

or use a dedicated system actor field.

This makes it clear that the action was automated.

---

# 17. Idempotency

Background jobs may retry.

A retry means the same job may run more than once.

So background workflows should be idempotent where possible.

Idempotent means:

```txt
Running the same operation multiple times does not create duplicate bad results.
```

Example:

```txt
Do not generate the same recurring invoice twice for the same profile and date.
```

Future recurring invoice production design should include:

```txt
profile_id
run_date
unique constraint
generation log
```

---

# 18. Retries

Background systems may retry failed jobs.

This is useful, but it means workflows must be designed carefully.

Example risk:

```txt
Email sent twice.
Invoice generated twice.
Payment posted twice.
```

Mitigation:

```txt
Use idempotency keys.
Use unique constraints.
Check existing records before creating new ones.
```

---

# 19. What Should Stay in the Request?

Some things should happen immediately before returning success.

Examples:

```txt
Create invoice row
Create invoice line
Post journal entry
Link invoice to journal entry
```

Why?

Because the user expects invoice creation to be complete.

The accounting state must be correct immediately.

Do not delay core ledger posting to a background job unless you design for pending states.

---

# 20. What Can Move to Background?

Good background candidates:

```txt
Send emails
Send notifications
Generate reminders
Schedule recurring tasks
Update analytics
Create exports
Process large files
```

Less suitable for background unless carefully designed:

```txt
Core journal posting
Payment recording
Invoice status updates
```

Those affect immediate financial state.

---

# 21. Event Timing

For invoice creation, send the event after:

```txt
Database transaction succeeds.
```

Not before.

Bad:

```txt
Send invoice.created event.
Then database insert fails.
```

Now background systems think an invoice exists when it does not.

Good:

```txt
Create invoice.
Post journal.
Commit transaction.
Send invoice.created event.
```

---

# 22. Observability

Background jobs need observability.

You should be able to answer:

```txt
Did the job run?
Did it fail?
What event triggered it?
What data did it process?
Will it retry?
```

Inngest provides a dashboard for this.

---

# 23. Local Development Workflow

Terminal 1:

```bash
pnpm dev
```

Terminal 2:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

Then open:

```txt
/settings/background-jobs
```

Click:

```txt
Send test event
```

Expected:

```txt
Inngest dev server shows app/health.check.
```

---

# 24. Production Workflow

Production endpoint:

```txt
https://your-domain.com/api/inngest
```

Required environment variables:

```txt
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
```

Configure endpoint in Inngest dashboard.

Verify functions appear.

---

# 25. Common Background Job Mistakes

## Mistake 1 — Relying on Active User in Scheduled Job

Bad:

```ts
await requireCurrentDatabaseOrganization();
```

inside a cron function.

Better:

```txt
Process organizations explicitly.
```

---

## Mistake 2 — Sending Events Before DB Commit

Bad:

```txt
Send event first.
Write database later.
```

Better:

```txt
Write database.
Then send event.
```

---

## Mistake 3 — Non-Idempotent Job

Bad:

```txt
Retry creates duplicate invoice.
```

Better:

```txt
Use unique generation key.
Check before creating.
```

---

## Mistake 4 — Sending Sensitive Data in Events

Avoid sending:

```txt
Secrets
Full bank details
Unnecessary personal data
```

Send IDs and minimal payloads.

---

# 26. Good Event Payload Design

Prefer:

```ts
{
  invoiceId: string;
  organizationId: string;
}
```

Instead of sending the entire invoice object.

Why?

Because:

```txt
Smaller payloads
Less sensitive data
Fresh data can be loaded when needed
Less risk of stale data
```

---

# 27. Background Job Testing Checklist

Test:

```txt
/api/inngest endpoint loads
Inngest dev server detects functions
Health check event runs
Invoice created event runs
Scheduled overdue reminder can be triggered
Failures appear in dashboard
```

---

# 28. Future Background Workflows

Possible future workflows:

```txt
Send invoice emails
Send overdue reminders
Generate recurring invoices with system context
Export reports monthly
Detect unreconciled bank transactions
Notify admins about failed jobs
Send GST filing reminders
Send payment receipt emails
```

---

# 29. Architecture Rule

Use background jobs for:

```txt
Side effects
Delayed work
Scheduled work
Retryable workflows
```

Do not use background jobs to hide core accounting uncertainty.

If the user creates an invoice, the accounting posting should be complete or clearly marked pending.

---

# 30. Final Mental Model

Background jobs in GreyMatter Ledger follow this idea:

```txt
The request creates reliable accounting state.
Events trigger helpful follow-up work.
Scheduled jobs automate routine checks.
Inngest makes that work observable and retryable.
```

The key rules:

```txt
Send events after successful database writes.
Design scheduled jobs without assuming a user session.
Make retryable jobs idempotent.
Keep sensitive data out of event payloads.
```
