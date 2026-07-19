# Part 11: Background & Scheduled Jobs

Every feature so far has run synchronously — a user clicks a button, and they wait until the database work finishes before seeing a result. That's fine for saving an invoice, which takes milliseconds. But some tasks either take too long to make a user wait for (sending an email), or don't have a user sitting there waiting at all (a reminder that should fire automatically every night at 2 AM). This part introduces Inngest to handle both.

## Step 11.1 — Creating an Inngest Account and Understanding Events vs. Functions

### The Target
Sign up for Inngest and understand its two core concepts before writing any code.

### The Concept
Recall the restaurant-buzzer analogy from Part 1: instead of making a customer wait at the counter, the host hands them a buzzer and lets the kitchen work in the background. Inngest formalizes this pattern around two ideas:

- An **event** is a simple announcement that "something happened" — like a kitchen order slip being placed on a spike. It doesn't do any work itself; it just describes a fact, e.g., `"invoice/created"` with some data attached (which invoice, which organization).
- A **function** is a worker that *listens* for a specific event and does something in response, e.g., "whenever an `invoice/created` event appears, send a confirmation email." A function can also be triggered on a **schedule** (a cron job) instead of an event — "run this every day at 2 AM," with no event needed at all.

The critical benefit: your main application code just announces "this event happened" and immediately moves on — it never waits for the email to actually send, and if the email service is temporarily down, Inngest automatically retries the function later without you writing any retry logic yourself.

### The Implementation

1. Go to **[inngest.com](https://inngest.com)** and sign up.
2. Create a new app (Inngest calls this simply your project's connection point) — name it `greymatter-ledger`.
3. In the dashboard, find your **Event Key** and **Signing Key** under the app's settings — we'll need both shortly.

### The Verification

Confirm you can see an empty Inngest dashboard for `greymatter-ledger`, with no events or functions yet — that's expected; we haven't sent anything yet.

---

## Step 11.2 — Installing Inngest and Wiring the Route Handler

### The Target
Install the Inngest SDK and create the one special API route that lets Inngest's cloud service communicate with our app.

### The Concept
Inngest's cloud service needs a way to actually *reach* our functions — since our functions live inside our own Next.js app, not inside Inngest itself. We expose a single API route (`/api/inngest`) that Inngest calls to discover what functions exist and to trigger them when their event fires or their schedule comes due. Think of this route like a dedicated back door installed specifically for the buzzer-and-kitchen delivery service to drop off and pick up orders, separate from the main "front door" your actual users interact with.

### The Implementation

```bash
npm install inngest
```

Add the Inngest keys to `.env.local`:

**`.env.local`** (add to the existing file)
```bash
# ...existing Clerk and Neon variables remain above this line...

INNGEST_EVENT_KEY=your_event_key_here
INNGEST_SIGNING_KEY=your_signing_key_here
```

Create the shared Inngest client, which every event and function will import:

**`src/lib/inngest/client.ts`**
```typescript
import { Inngest } from "inngest";

// The client is the single shared object our app uses both to SEND
// events (from server actions, like "an invoice was just created") and
// to DEFINE functions that respond to those events. The id must be
// unique and stable — it's how Inngest's dashboard identifies this app.
export const inngest = new Inngest({ id: "greymatter-ledger" });
```

Now the route handler that connects our functions to Inngest's cloud service:

**`src/app/api/inngest/route.ts`**
```typescript
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest/client";
import { sendInvoiceConfirmationEmail } from "@/lib/inngest/functions/send-invoice-email";
import { sendOverdueInvoiceReminders } from "@/lib/inngest/functions/overdue-reminders";
import { generateRecurringInvoices } from "@/lib/inngest/functions/recurring-invoices";

// serve() wires our function definitions up to Next.js's route handler
// conventions, automatically exposing GET (Inngest uses this to fetch
// the list of available functions), POST (Inngest uses this to actually
// invoke a function), and PUT (used during initial registration).
export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    sendInvoiceConfirmationEmail,
    sendOverdueInvoiceReminders,
    generateRecurringInvoices,
  ],
});
```

We're importing three function files that don't exist yet — we'll create each one in the next three steps. For now, this file simply describes the *shape* our functions folder will take.

### The Verification

We can't fully verify this route until at least one real function exists — let's build the first one now, then come back and confirm the whole pipeline together.

---

## Step 11.3 — First Job: Invoice Confirmation Email

### The Target
Send a (simulated) confirmation email in the background whenever an invoice is created, without making the user wait for it.

### The Concept
Right now, `createInvoice` (Part 7) does its database work and immediately redirects the user — there's no email at all. We're going to add exactly two things: (1) inside `createInvoice`, *announce* an event (`"invoice/created"`) the moment the invoice is saved, and (2) write a separate Inngest function that *listens* for that event and sends the email. Critically, `createInvoice` does not wait for the email to send — it fires the event and moves on immediately, exactly like the restaurant host handing over a buzzer and turning to help the next customer.

For this course, we'll simulate "sending an email" with a console log and a short artificial delay, clearly commented on exactly where a real email provider (like Resend or Postmark) would be plugged in — since setting up a real transactional email account is outside this course's scope, but the Inngest wiring is identical either way.

### The Implementation

**`src/lib/inngest/functions/send-invoice-email.ts`**
```typescript
import { inngest } from "@/lib/inngest/client";
import { db } from "@/db";

export const sendInvoiceConfirmationEmail = inngest.createFunction(
  { id: "send-invoice-confirmation-email" },
  // This function runs whenever an event named "invoice/created" appears —
  // it doesn't run on any schedule, only in reaction to that specific event.
  { event: "invoice/created" },
  async ({ event, step }) => {
    const { invoiceId } = event.data;

    // step.run() wraps a unit of work so Inngest can track it individually,
    // retry just this step if it fails (without re-running earlier steps
    // that already succeeded), and show it as a distinct entry in the
    // dashboard's execution log — valuable for debugging background jobs,
    // which you can't just watch happen live in a browser the way you can
    // with a normal page request.
    const invoice = await step.run("fetch-invoice-details", async () => {
      return db.query.invoices.findFirst({
        where: (invoices, { eq }) => eq(invoices.id, invoiceId),
        with: { customer: true },
      });
    });

    if (!invoice) {
      throw new Error(`Invoice ${invoiceId} not found — cannot send confirmation email.`);
    }

    await step.run("send-email", async () => {
      // ---- REAL EMAIL PROVIDER GOES HERE ----
      // In a production app, this is where you'd call a transactional
      // email service, e.g.:
      //   await resend.emails.send({
      //     to: invoice.customer.email,
      //     subject: `Invoice ${invoice.invoiceNumber} from Greymatter Ledger`,
      //     html: `<p>Your invoice for $${invoice.total} is ready.</p>`,
      //   });
      // For this course, we simulate the send with a delay and a log
      // line, so the background-job MECHANICS are fully real and
      // testable, without requiring you to sign up for an email provider.
      await new Promise((resolve) => setTimeout(resolve, 500));
      console.log(
        `[SIMULATED EMAIL] To: ${invoice.customer.email ?? "(no email on file)"} — Invoice ${invoice.invoiceNumber} for $${invoice.total} confirmed.`
      );
    });

    return { sent: true, invoiceId };
  }
);
```

Now, wire the event announcement into `createInvoice`:

**`src/lib/actions/invoices.ts`** (updated — add the Inngest import and the event send call)
```typescript
"use server";

import { dbTransactional } from "@/db";
import { db } from "@/db";
import { invoices, invoiceLines, accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { postJournalEntry } from "@/lib/journal";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { inngest } from "@/lib/inngest/client";

export type InvoiceLineInput = {
  description: string;
  quantity: number;
  unitPrice: number;
  gstRate: number;
};

export type CreateInvoiceInput = {
  customerId: string;
  issueDate: string;
  dueDate: string;
  lines: InvoiceLineInput[];
};

export async function createInvoice(input: CreateInvoiceInput) {
  const organizationId = await getOrCreateOrganization();

  if (input.lines.length === 0) {
    throw new Error("An invoice must have at least one line item.");
  }

  const orgAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const arAccount = orgAccounts.find((a) => a.code === "1100");
  const revenueAccount = orgAccounts.find((a) => a.code === "4000");
  const gstOutputAccount = orgAccounts.find((a) => a.code === "2100");

  if (!arAccount || !revenueAccount || !gstOutputAccount) {
    throw new Error(
      "Required accounts (1100 Accounts Receivable, 4000 Sales Revenue, 2100 GST Output Tax Payable) are missing from this organization's Chart of Accounts."
    );
  }

  let subtotalCents = 0;
  let gstTotalCents = 0;

  const computedLines = input.lines.map((line) => {
    const lineTotalCents = Math.round(line.quantity * line.unitPrice * 100);
    const lineGstCents = Math.round(lineTotalCents * (line.gstRate / 100));

    subtotalCents += lineTotalCents;
    gstTotalCents += lineGstCents;

    return {
      description: line.description,
      quantity: line.quantity.toFixed(2),
      unitPrice: line.unitPrice.toFixed(2),
      gstRate: line.gstRate.toFixed(2),
      lineTotal: (lineTotalCents / 100).toFixed(2),
    };
  });

  const totalCents = subtotalCents + gstTotalCents;
  const invoiceNumber = `INV-${Date.now()}`;

  const result = await dbTransactional.transaction(async (tx) => {
    const [invoice] = await tx
      .insert(invoices)
      .values({
        organizationId,
        customerId: input.customerId,
        invoiceNumber,
        issueDate: input.issueDate,
        dueDate: input.dueDate,
        status: "sent",
        subtotal: (subtotalCents / 100).toFixed(2),
        gstTotal: (gstTotalCents / 100).toFixed(2),
        total: (totalCents / 100).toFixed(2),
      })
      .returning();

    await tx.insert(invoiceLines).values(
      computedLines.map((line) => ({
        invoiceId: invoice.id,
        description: line.description,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        gstRate: line.gstRate,
        lineTotal: line.lineTotal,
      }))
    );

    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: input.issueDate,
        description: `Invoice ${invoiceNumber}`,
        sourceType: "invoice",
        sourceId: invoice.id,
        lines: [
          { accountId: arAccount.id, debit: totalCents / 100 },
          { accountId: revenueAccount.id, credit: subtotalCents / 100 },
          ...(gstTotalCents > 0
            ? [{ accountId: gstOutputAccount.id, credit: gstTotalCents / 100 }]
            : []),
        ],
      },
      tx
    );

    await tx
      .update(invoices)
      .set({ journalEntryId: journalResult.entry.id })
      .where(eq(invoices.id, invoice.id));

    return invoice;
  });

  // Announce the event AFTER the transaction has fully committed — never
  // inside the transaction itself. If we sent the event before the
  // transaction was guaranteed to succeed, and the transaction later
  // rolled back due to some failure, we'd have already told Inngest
  // "this invoice exists," which could trigger an email for an invoice
  // that was never actually saved. Firing the event only after `result`
  // is successfully returned guarantees the event and the data always
  // agree with each other.
  await inngest.send({
    name: "invoice/created",
    data: { invoiceId: result.id, organizationId },
  });

  revalidatePath("/invoices");
  redirect(`/invoices/${result.id}`);
}

export async function getInvoices() {
  const organizationId = await getOrCreateOrganization();

  return db.query.invoices.findMany({
    where: (invoices, { eq }) => eq(invoices.organizationId, organizationId),
    with: { customer: true },
    orderBy: (invoices, { desc }) => desc(invoices.issueDate),
  });
}

export async function getInvoiceById(invoiceId: string) {
  const organizationId = await getOrCreateOrganization();

  const invoice = await db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, invoiceId), eq(invoices.organizationId, organizationId)),
    with: { customer: true, lines: true },
  });

  return invoice;
}
```

Since `send-invoice-email.ts` still references two files that don't exist yet (`overdue-reminders.ts`, `recurring-invoices.ts`, imported back in `route.ts`), let's stub those out with placeholder-free, genuinely minimal but real implementations right now, so the app compiles — we'll flesh out their real logic in the next two steps.

**`src/lib/inngest/functions/overdue-reminders.ts`** *(temporary minimal version — replaced fully in Step 11.4)*
```typescript
import { inngest } from "@/lib/inngest/client";

export const sendOverdueInvoiceReminders = inngest.createFunction(
  { id: "send-overdue-invoice-reminders" },
  { cron: "0 8 * * *" }, // 8 AM daily — placeholder, refined in Step 11.4
  async () => {
    return { placeholder: true };
  }
);
```

**`src/lib/inngest/functions/recurring-invoices.ts`** *(temporary minimal version — replaced fully in Step 11.5)*
```typescript
import { inngest } from "@/lib/inngest/client";

export const generateRecurringInvoices = inngest.createFunction(
  { id: "generate-recurring-invoices" },
  { cron: "0 6 * * *" }, // 6 AM daily — placeholder, refined in Step 11.5
  async () => {
    return { placeholder: true };
  }
);
```

### The Verification

**Run the Inngest local dev server**, a small tool that lets you test Inngest functions locally without waiting on real cloud infrastructure. In a **third terminal tab** (leave `npm run dev` running in the first, keep it separate):

```bash
npx inngest-cli@latest dev
```

Expected output: a message that it's running, along with a URL like `http://localhost:8288` — open this in your browser. This is Inngest's local dashboard, showing your app's registered functions once it detects them.

With your Next.js dev server (`npm run dev`) also running, visit `http://localhost:3000/api/inngest` directly in your browser — you should see a JSON response confirming Inngest can see your three registered functions (`send-invoice-confirmation-email`, `send-overdue-invoice-reminders`, `generate-recurring-invoices`).

Now create a real test invoice via `/invoices/new`, exactly as in Part 7. After it saves and redirects, switch to the terminal running `npm run dev` and look for a log line:

```
[SIMULATED EMAIL] To: ... — Invoice INV-... for $... confirmed.
```

Also check the Inngest local dashboard (`http://localhost:8288`) — you should see a new event named `invoice/created` listed, and a corresponding successful run of `send-invoice-confirmation-email`, with a green "Completed" status and both steps (`fetch-invoice-details`, `send-email`) shown individually in its execution timeline.

---

## Step 11.4 — Scheduled Job: Daily Overdue Invoice Reminders

### The Target
Replace the placeholder `overdue-reminders.ts` with a real daily scheduled job that finds overdue invoices and logs a reminder for each one.

### The Concept
Recall Part 9's AR Aging report — we already built the exact logic needed to answer "which invoices are overdue?" (`getArAging`). This job reuses that function directly rather than reinventing overdue-detection logic, which is exactly the blueprint's stated intent: *"a daily overdue-invoice reminder reusing the Part 9 aging logic directly."* A **cron schedule** (instead of an event trigger) means this function runs automatically, every day, with no user action required at all — the defining trait of a truly "background" job, as opposed to the invoice email job, which still originates from a user's action.

Because this job needs to check *every* organization (not just one specific one, the way a user-triggered action naturally scopes to whichever organization is currently active), we need to loop over all organizations in our local `organizations` table.

### The Implementation

**`src/lib/inngest/functions/overdue-reminders.ts`** (full replacement)
```typescript
import { inngest } from "@/lib/inngest/client";
import { db } from "@/db";
import { organizations } from "@/db/schema";
import { getArAging } from "@/lib/aging";

export const sendOverdueInvoiceReminders = inngest.createFunction(
  { id: "send-overdue-invoice-reminders" },
  // Cron syntax: minute hour day month weekday. "0 8 * * *" means
  // "at minute 0 of hour 8, every day, every month, every weekday" —
  // i.e., 8:00 AM daily, in the timezone Inngest is configured for
  // (UTC by default, adjustable in Inngest's dashboard settings).
  { cron: "0 8 * * *" },
  async ({ step }) => {
    // Fetch every organization we know about — this job runs once for
    // the entire platform, not scoped to a single company, unlike almost
    // every other function we've written so far in this course.
    const allOrgs = await step.run("fetch-all-organizations", async () => {
      return db.select().from(organizations);
    });

    const results: { organizationId: string; remindersSent: number }[] = [];

    for (const org of allOrgs) {
      // Each organization's overdue check is wrapped in its own step, so
      // if one organization's check somehow fails, Inngest can retry just
      // that one step without re-running the (potentially expensive)
      // checks already completed successfully for other organizations.
      const remindersSent = await step.run(
        `check-overdue-invoices-${org.id}`,
        async () => {
          const arRows = await getArAging(org.id);
          const overdueRows = arRows.filter((row) => row.daysOverdue > 0);

          for (const row of overdueRows) {
            // ---- REAL EMAIL PROVIDER GOES HERE ----
            // In production, this is where you'd email the actual
            // customer a reminder. We simulate it with a log line,
            // exactly as in Step 11.3.
            console.log(
              `[SIMULATED REMINDER] Org ${org.name}: Invoice ${row.number} to ${row.partyName} is ${row.daysOverdue} days overdue ($${row.balanceDue.toFixed(2)} due).`
            );
          }

          return overdueRows.length;
        }
      );

      results.push({ organizationId: org.id, remindersSent });
    }

    return { organizationsChecked: allOrgs.length, results };
  }
);
```

### The Verification

Scheduled/cron functions can't easily be "waited for" naturally (they only fire at their scheduled time), so Inngest's local dev server provides a manual trigger for testing. In the Inngest local dashboard (`http://localhost:8288`), find `send-overdue-invoice-reminders` in the **Functions** tab, and use its **"Invoke"** or **"Trigger"** button (exact label may vary slightly by Inngest CLI version) to run it immediately, on demand, without waiting for 8 AM.

After triggering it, check the run's execution log in the dashboard — confirm it shows one `fetch-all-organizations` step, followed by one `check-overdue-invoices-{orgId}` step per organization in your database. Check your `npm run dev` terminal for `[SIMULATED REMINDER]` log lines — you should see one per overdue invoice across all your test organizations (recall from Part 9's testing, we manually created one invoice with a due date roughly 45 days in the past — that invoice should trigger a reminder here).

If you have no currently-overdue invoices in any test organization, temporarily create one (following Part 9's aging test instructions) before re-triggering this function, to confirm the reminder logic genuinely fires for at least one real case.

---

## Step 11.5 — Scheduled Job: Recurring Invoice Generator

### The Target
Replace the placeholder `recurring-invoices.ts` with a real system for marking certain invoices as "recurring" and having a scheduled job automatically generate the next occurrence.

### The Concept
Some businesses bill the same customer

$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$

the exact same amount every month — a subscription, a retainer, rent. Rather than manually recreating that invoice every single month, we let a user flag an invoice as recurring (with a defined interval, like "monthly"), and a scheduled job checks daily whether it's time to generate the next occurrence, reusing the exact same `createInvoice` logic from Part 7 so every generated invoice gets the identical journal-posting guarantees as a manually created one.

### The Implementation

First, we need a small schema addition to support this — a `recurring_invoice_templates` table that stores the "recipe" for generating future invoices, plus a `nextRunDate` to track when the next one is due.

**`src/db/schema.ts`** (new addition)
```typescript
export const recurringIntervalEnum = pgEnum("recurring_interval", [
  "weekly",
  "monthly",
  "quarterly",
  "yearly",
]);

// A "recipe" for generating future invoices automatically. We store the
// line items as JSON here rather than a separate relational table,
// since this data is never queried individually the way real
// invoice_lines are — it's only ever read as a whole "recipe" and copied
// wholesale into a brand-new invoice each time it fires.
export const recurringInvoiceTemplates = pgTable("recurring_invoice_templates", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  customerId: uuid("customer_id")
    .notNull()
    .references(() => customers.id, { onDelete: "restrict" }),

  interval: recurringIntervalEnum("interval").notNull(),

  // JSON blob shaped exactly like InvoiceLineInput[] from Part 7's
  // createInvoice — description, quantity, unitPrice, gstRate per line.
  lineItemsJson: text("line_items_json").notNull(),

  nextRunDate: date("next_run_date").notNull(),

  isActive: boolean("is_active").notNull().default(true),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Migrate:

```bash
npm run db:generate
npm run db:migrate
```

Now, a small helper to advance a date by the correct interval:

**`src/lib/recurring-dates.ts`**
```typescript
export function advanceDateByInterval(
  dateStr: string,
  interval: "weekly" | "monthly" | "quarterly" | "yearly"
): string {
  const date = new Date(dateStr);

  switch (interval) {
    case "weekly":
      date.setDate(date.getDate() + 7);
      break;
    case "monthly":
      date.setMonth(date.getMonth() + 1);
      break;
    case "quarterly":
      date.setMonth(date.getMonth() + 3);
      break;
    case "yearly":
      date.setFullYear(date.getFullYear() + 1);
      break;
  }

  return date.toISOString().split("T")[0];
}
```

A server action to create a new recurring template (a minimal form to trigger this is left as a straightforward extension of Part 7's invoice form pattern — we focus here on the scheduled job itself, which is this part's real teaching point):

**`src/lib/actions/recurring-invoices.ts`**
```typescript
"use server";

import { db } from "@/db";
import { recurringInvoiceTemplates } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import type { InvoiceLineInput } from "@/lib/actions/invoices";

export type CreateRecurringTemplateInput = {
  customerId: string;
  interval: "weekly" | "monthly" | "quarterly" | "yearly";
  lines: InvoiceLineInput[];
  startDate: string;
};

export async function createRecurringTemplate(
  input: CreateRecurringTemplateInput
) {
  const organizationId = await getOrCreateOrganization();

  await db.insert(recurringInvoiceTemplates).values({
    organizationId,
    customerId: input.customerId,
    interval: input.interval,
    lineItemsJson: JSON.stringify(input.lines),
    nextRunDate: input.startDate,
  });
}
```

Now, the real scheduled job:

**`src/lib/inngest/functions/recurring-invoices.ts`** (full replacement)
```typescript
import { inngest } from "@/lib/inngest/client";
import { db } from "@/db";
import { recurringInvoiceTemplates } from "@/db/schema";
import { eq, and, lte } from "drizzle-orm";
import { createInvoice, type InvoiceLineInput } from "@/lib/actions/invoices";
import { advanceDateByInterval } from "@/lib/recurring-dates";

export const generateRecurringInvoices = inngest.createFunction(
  { id: "generate-recurring-invoices" },
  { cron: "0 6 * * *" }, // 6 AM daily
  async ({ step }) => {
    // Find every active template whose nextRunDate has arrived (today or
    // earlier — "earlier" covers the edge case where this job somehow
    // didn't run on its exact scheduled day, so nothing silently gets
    // skipped forever).
    const today = new Date().toISOString().split("T")[0];

    const dueTemplates = await step.run("fetch-due-templates", async () => {
      return db
        .select()
        .from(recurringInvoiceTemplates)
        .where(
          and(
            eq(recurringInvoiceTemplates.isActive, true),
            lte(recurringInvoiceTemplates.nextRunDate, today)
          )
        );
    });

    const generatedInvoiceIds: string[] = [];

    for (const template of dueTemplates) {
      // Each template's generation is its own step — if one template's
      // invoice creation fails (e.g. a deleted customer), Inngest can
      // retry just that step without regenerating invoices that already
      // succeeded for other templates in this same run.
      const invoiceId = await step.run(
        `generate-invoice-${template.id}`,
        async () => {
          const lines: InvoiceLineInput[] = JSON.parse(template.lineItemsJson);

          // createInvoice ends with a Next.js redirect() call, which is
          // meant for interactive user requests — it throws a special
          // internal signal that has no meaning in this background job
          // context. Since we're calling it from a non-request context
          // here, we deliberately catch and ignore ONLY that specific
          // signal, treating it as expected successful completion rather
          // than a real error, exactly the same defensive pattern used
          // in the invoice form's submit handler back in Part 7.
          try {
            await createInvoice({
              customerId: template.customerId,
              issueDate: today,
              dueDate: advanceDateByInterval(today, "monthly"), // 30-day payment terms
              lines,
            });
          } catch (err) {
            const message = (err as Error)?.message ?? "";
            if (!message.includes("NEXT_REDIRECT")) {
              throw err; // a genuine failure — let Inngest retry this step
            }
          }

          // Advance this template's nextRunDate so it doesn't fire again
          // until its next real interval has elapsed.
          const newNextRunDate = advanceDateByInterval(
            template.nextRunDate,
            template.interval
          );

          await db
            .update(recurringInvoiceTemplates)
            .set({ nextRunDate: newNextRunDate })
            .where(eq(recurringInvoiceTemplates.id, template.id));

          return template.id;
        }
      );

      generatedInvoiceIds.push(invoiceId);
    }

    return { templatesProcessed: dueTemplates.length, generatedInvoiceIds };
  }
);
```

### The Verification

First, create a test recurring template. Since we didn't build a dedicated form page for this (noted above as a straightforward extension), test it directly by temporarily calling the server action from a throwaway page:

**`src/app/recurring-test/page.tsx`** *(temporary — delete after use)*
```tsx
import { createRecurringTemplate } from "@/lib/actions/recurring-invoices";
import { getCustomers } from "@/lib/actions/customers";

export default async function RecurringTestPage() {
  const customers = await getCustomers();
  const customer = customers[0];

  if (!customer) {
    return <p className="p-8">Create a customer first.</p>;
  }

  await createRecurringTemplate({
    customerId: customer.id,
    interval: "monthly",
    startDate: new Date().toISOString().split("T")[0], // due today, on purpose
    lines: [
      { description: "Monthly retainer", quantity: 1, unitPrice: 800, gstRate: 9 },
    ],
  });

  return <p className="p-8">Recurring template created for {customer.name}, due today.</p>;
}
```

Visit `http://localhost:3000/recurring-test` once, confirm the success message, then delete the file:

```bash
rm -rf src/app/recurring-test
```

Now, in the Inngest local dashboard (`http://localhost:8288`), find `generate-recurring-invoices` and manually trigger it (same "Invoke" mechanism as Step 11.4). Confirm the run completes successfully, showing one `fetch-due-templates` step and one `generate-invoice-{templateId}` step.

Verify in Drizzle Studio:
- `invoices` — confirm a brand-new invoice now exists for "Monthly retainer," $800.00 + 9% GST = $872.00 total, dated today.
- `recurring_invoice_templates` — confirm the template's `next_run_date` has advanced to one month from today (not still today), proving it won't fire again until its real next cycle.

Trigger the job a second time immediately. Confirm **no new invoice** is generated this time — the template's `nextRunDate` has already moved past today, so `lte(nextRunDate, today)` correctly excludes it now.

---

## Step 11.6 — Tenth Git Commit

### The Target
Save the completed background/scheduled job system as a new checkpoint.

### The Implementation

```bash
git add .
git commit -m "Add Inngest background invoice emails, daily overdue reminders, and recurring invoice generation"
```

### The Verification

```bash
git log --oneline
```

Expected output, ten lines, newest first.

---

## ✅ Checkpoint — Part 11

At this point, you should have:

- [x] An Inngest account, local dev server, and the `/api/inngest` route serving three registered functions
- [x] `createInvoice` announcing an `invoice/created` event only *after* its transaction commits, never before
- [x] A working background email confirmation job, verified via console logs and the Inngest local dashboard
- [x] A working daily-scheduled overdue reminder job, reusing Part 9's `getArAging` directly, manually triggerable and verified
- [x] A `recurring_invoice_templates` table and a working scheduled job that generates real invoices (via the same `createInvoice` used everywhere else) and correctly advances its own next-run date
- [x] Confirmed the recurring job is idempotent per cycle — triggering it twice in a row doesn't double-generate an invoice
- [x] A tenth Git commit checkpoint

---

## 📚 Reference Section: Events, Idempotency, and Why Order Matters

*(A standalone reference — read now or return later.)*

**Why fire the `invoice/created` event *after* the transaction commits, rather than from inside it?**
This is one of the most important lessons in this part. A database transaction can still fail or roll back at any point up until it fully commits — but once `inngest.send()` is called, that announcement is immediately, irreversibly out in the world, and Inngest may act on it before you'd have any chance to "unsend" it. If we called `inngest.send()` from inside the `dbTransactional.transaction(...)` callback, and the transaction later rolled back for any reason (a bug, a constraint violation, a network blip), we'd have already told Inngest "this invoice exists" — which could trigger a confirmation email for an invoice that was never actually saved to the database. By waiting until `result` is successfully returned from the transaction (proof it committed), we guarantee the event and the underlying data can never disagree with each other. This is the exact same "don't create inconsistent state" discipline from Part 6's atomicity guarantee, just applied one layer further out, to an external system.

**Why does `step.run()` matter so much — couldn't we just write plain `await` code inside the function body?**
Technically, yes, plain `await` calls would run — but you'd lose Inngest's most valuable guarantee: granular, automatic retries. If a function has three sequential `step.run()` calls and the third one throws an error (say, an email provider's API is briefly down), Inngest retries *only* that third step — the first two, which already succeeded, are never re-executed. Without `step.run()` wrapping, a retry would re-run the *entire function from the top*, including any side effects (like inserting a database row) that already happened successfully the first time — potentially creating duplicates. Wrapping meaningful units of work in `step.run()` is what makes retries safe rather than dangerous.

**What does "idempotent" mean, and why did we specifically test for it in Step 11.5?**
An idempotent operation produces the same end result no matter how many times it's triggered, given the same starting conditions — running it twice shouldn't cause double the effect. Our recurring invoice job achieves this specifically because it advances `nextRunDate` *before* the job could possibly run again, and its "is this due?" check (`lte(nextRunDate, today)`) is re-evaluated fresh every single time the job runs. This matters enormously for scheduled jobs specifically, because cron-based systems occasionally fire more than once around the same trigger time (network retries, infrastructure quirks) — a job that isn't idempotent could silently double-bill a real customer, which would be a serious, embarrassing bug in a real accounting product.

**Why store `lineItemsJson` as a JSON-in-text column instead of a proper relational table, when we specifically avoided that shortcut for `invoice_lines` back in Part 7?**
This is a deliberate, context-dependent tradeoff, not an inconsistency. `invoice_lines` represents *historical, immutable financial fact* — once an invoice is created, its lines are permanent records that reports (Parts 9–10) query, filter, and aggregate individually, in combination with other tables (joining against `invoices`, filtering by `gstRate`). A recurring template's stored lines, by contrast, are never queried individually or reported on — they exist purely as a "recipe" that gets read as one atomic blob and copied wholesale into a brand-new, *real* `invoice_lines` row-set every time the job fires. When data is only ever read-as-a-whole and never filtered/joined/aggregated at the field level, a JSON blob is a perfectly reasonable, simpler choice than a full relational table — but this judgment call would flip immediately if we ever needed to, say, report on "total value of all recurring templates by line item category," which would demand real relational columns.

**What happens if Inngest's cloud service is briefly unreachable when `inngest.send()` is called inside `createInvoice`?**
The Inngest SDK has its own internal retry behavior for delivering the event itself. In the rare case that event delivery genuinely fails after those retries are exhausted, the invoice itself is still safely saved (since, per the ordering explained above, the event is only sent *after* the transaction already committed) — the only consequence is a missed confirmation email, not a corrupted or lost invoice. This is a reasonable, appropriately-scoped failure mode: the core accounting data (the invoice, its journal entry) is never at risk, only a secondary, non-critical notification.

---

## 🔧 Troubleshooting — Part 11

**"Visiting `/api/inngest` shows an error instead of a JSON list of functions."**
Check the terminal running `npm run dev` for a stack trace — the most common cause at this stage is one of the three function files (`send-invoice-email.ts`, `overdue-reminders.ts`, `recurring-invoices.ts`) having a typo in its import path or a missing `export`. Confirm all three files exist at the exact paths referenced in `src/app/api/inngest/route.ts`.

**"The Inngest local dashboard at `localhost:8288` shows no functions at all."**
Confirm both `npm run dev` (your Next.js app) and `npx inngest-cli@latest dev` are running simultaneously in separate terminal tabs — the local Inngest dev server needs to reach your running Next.js app's `/api/inngest` route to discover functions, so if the Next.js server isn't running, there's nothing for it to find.

**"Creating an invoice doesn't trigger the simulated email log line."**
Check the Inngest local dashboard's **Events** tab first — if the `invoice/created` event never appears there at all, the problem is in `createInvoice` (confirm `await inngest.send(...)` is actually being reached, i.e., placed after the transaction, not accidentally inside a code path that throws first). If the event *does* appear but the function run shows a red "Failed" status, click into it to see the actual error — a common cause is the invoice ID not being found because of a typo in `event.data.invoiceId` versus what was actually sent.

**"Manually triggering the overdue reminders job in the dashboard shows zero results even though I have overdue test invoices."**
Confirm you're checking the correct organization — remember this job loops over `db.select().from(organizations)` (every organization in your entire local database), and `getArAging` is scoped per organization internally; if your overdue test invoice exists in an organization not currently reflected in your local `organizations` table (e.g., you created it in Drizzle Studio directly rather than through the app), it may not surface correctly here.

**"The recurring invoice job's second trigger STILL generates a duplicate invoice."**
This means the `nextRunDate` update didn't actually persist. Double check the `db.update(recurringInvoiceTemplates).set({ nextRunDate: newNextRunDate })` call is inside the same `step.run(...)` callback as the invoice creation itself, and that its `.where(eq(recurringInvoiceTemplates.id, template.id))` clause correctly targets the specific template's ID, not accidentally omitted (which would silently update zero rows, since Drizzle requires an explicit `.where()` to avoid accidentally updating every row in a table).

**"TypeScript complains that `createInvoice`'s redirect-related catch logic conflicts with its return type when called from `recurring-invoices.ts`."**
Since `createInvoice` in Part 7's design always ends in either a thrown error or a `redirect()` call (which itself throws internally), it never actually returns a normal value — calling it from a background job and expecting a return value isn't meaningful. Confirm the recurring invoice job only relies on `createInvoice`'s *side effects* (the invoice existing in the database afterward), never on a return value from the call itself, exactly as written in Step 11.5.

