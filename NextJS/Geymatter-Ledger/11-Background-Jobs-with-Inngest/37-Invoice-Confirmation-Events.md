# Part 37 — Invoice Confirmation Events

In Part 36, we installed and configured Inngest.

Now we will send a background event whenever an invoice is created.

By the end of this part, you will have:

- Invoice created event type
- Inngest function that handles invoice creation
- Event sent after invoice creation
- Background job diagnostics in Inngest
- Clear foundation for email reminders later

We will not send real emails yet.

For now, the background function logs/returns structured confirmation data.

---

# 1. Understand Invoice Events

## The Target

We are sending an event after invoice creation.

---

## The Concept

When an invoice is created, multiple things might need to happen later:

```txt
Send confirmation email
Notify accountant
Schedule overdue reminder
Update analytics
```

We should not put all of that directly inside the invoice creation request.

Instead, invoice creation sends an event:

```txt
invoice.created
```

Background functions can listen for that event.

This keeps invoice creation fast and modular.

---

# 2. Define Invoice Event Names

## The Target

We are creating:

```txt
inngest/events.ts
```

---

## The Implementation

Create:

```txt
inngest/events.ts
```

Add:

```ts
// inngest/events.ts

export const inngestEvents = {
  invoiceCreated: "invoice.created",
} as const;

export type InvoiceCreatedEventData = {
  invoiceId: string;
  invoiceNumber: string;
  organizationId: string;
  customerId: string;
  totalCents: number;
};
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 3. Add Invoice Created Function

## The Target

We are updating:

```txt
inngest/functions.ts
```

---

## The Concept

The function listens for:

```txt
invoice.created
```

and returns confirmation data.

Later we can add email sending.

---

## The Implementation

Open:

```txt
inngest/functions.ts
```

Replace it with:

```ts
// inngest/functions.ts

import { inngest } from "@/inngest/client";
import {
  inngestEvents,
  type InvoiceCreatedEventData,
} from "@/inngest/events";

export const backgroundHealthCheck = inngest.createFunction(
  {
    id: "background-health-check",
    name: "Background Health Check",
  },
  {
    event: "app/health.check",
  },
  async ({ event, step }) => {
    const message = await step.run("create-health-message", async () => {
      return {
        receivedAt: new Date().toISOString(),
        payload: event.data,
      };
    });

    return message;
  },
);

export const invoiceCreatedConfirmation = inngest.createFunction(
  {
    id: "invoice-created-confirmation",
    name: "Invoice Created Confirmation",
  },
  {
    event: inngestEvents.invoiceCreated,
  },
  async ({ event, step }) => {
    const data = event.data as InvoiceCreatedEventData;

    const confirmation = await step.run(
      "prepare-invoice-confirmation",
      async () => {
        return {
          message: `Invoice ${data.invoiceNumber} was created.`,
          invoiceId: data.invoiceId,
          organizationId: data.organizationId,
          customerId: data.customerId,
          totalCents: data.totalCents,
          processedAt: new Date().toISOString(),
        };
      },
    );

    return confirmation;
  },
);

export const inngestFunctions = [
  backgroundHealthCheck,
  invoiceCreatedConfirmation,
];
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Send Event After Invoice Creation

## The Target

We are updating:

```txt
services/invoices/invoice-services.ts
```

---

## The Concept

After the invoice is created and posted successfully, we send:

```txt
invoice.created
```

The event should only be sent after the database transaction succeeds.

---

## The Implementation

Open:

```txt
services/invoices/invoice-services.ts
```

Add imports:

```ts
import { inngest } from "@/inngest/client";
import { inngestEvents } from "@/inngest/events";
```

Find the successful result block:

```ts
return {
  ok: true,
  invoice: result,
};
```

Before it, add:

```ts
await inngest.send({
  name: inngestEvents.invoiceCreated,
  data: {
    invoiceId: result.id,
    invoiceNumber: result.invoiceNumber,
    organizationId: result.organizationId,
    customerId: result.customerId,
    totalCents: result.totalCents,
  },
});
```

The success end should look like:

```ts
await writeAuditLog({
  action: "invoice.created",
  entityType: "invoice",
  entityId: result.id,
  message: `Invoice created and posted: ${result.invoiceNumber}`,
  metadata: {
    invoiceNumber: result.invoiceNumber,
    totalCents: result.totalCents,
    journalEntryId: result.journalEntryId,
  },
});

await inngest.send({
  name: inngestEvents.invoiceCreated,
  data: {
    invoiceId: result.id,
    invoiceNumber: result.invoiceNumber,
    organizationId: result.organizationId,
    customerId: result.customerId,
    totalCents: result.totalCents,
  },
});

return {
  ok: true,
  invoice: result,
};
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 5. Test with Inngest Dev Server

## The Target

We are verifying the invoice-created event fires.

---

## The Implementation

Terminal 1:

```bash
pnpm dev
```

Terminal 2:

```bash
npx inngest-cli@latest dev -u http://localhost:3000/api/inngest
```

Open:

```txt
/invoices
```

Create a new invoice.

---

## The Verification

In the Inngest dev UI, you should see:

```txt
invoice.created
invoice-created-confirmation
```

The function output should include:

```txt
Invoice INV-... was created.
```

---

# 6. Add Background Job Notes to Invoice Success

## The Target

We are updating:

```txt
components/invoice-status-banner.tsx
```

---

## The Implementation

Open:

```txt
components/invoice-status-banner.tsx
```

In the created success branch, update the second paragraph to:

```tsx
<p className="mt-2 text-sm leading-6">
  The invoice was saved, GST was calculated, a balanced journal entry was
  posted, and an invoice.created background event was sent.
</p>
```

---

## The Verification

Create another invoice.

You should see the updated success message.

---

# 7. Run Full Project Check

## The Target

We are verifying everything still passes.

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should pass.

---

# 8. Commit Invoice Events

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Add invoice created background event"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: Event does not appear in Inngest

Check:

```txt
inngest/functions.ts
```

includes:

```ts
invoiceCreatedConfirmation
```

inside:

```ts
inngestFunctions
```

Also make sure the Inngest dev server is running.

---

## Error: Invoice creates but event fails

Check terminal output.

In production, consider making event sending retry-safe and observable.

For this tutorial, event sending happens after successful database work.

---

# Phase 11 Reference — Invoice Events

## Event

```txt
invoice.created
```

---

## Producer

The invoice creation service sends the event.

---

## Consumer

The Inngest function handles the event.

---

# Part 37 Completion Checklist

You are ready for Part 38 if:

- [ ] `inngest/events.ts` exists
- [ ] `invoice.created` event is defined
- [ ] Inngest invoice-created function exists
- [ ] Invoice creation sends event after DB success
- [ ] Inngest dev server receives invoice event
- [ ] Invoice success banner mentions background event
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
