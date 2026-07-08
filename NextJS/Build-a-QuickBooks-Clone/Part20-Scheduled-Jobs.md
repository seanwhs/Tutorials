## Part 20: Scheduled Jobs / Cron 

**Goal:** teach Inngest to run functions on a timer rather than in response to an event. We'll build a daily overdue-invoice reminder job (reusing Part 18's AR aging logic) and a simple recurring-invoice generator.

**Prerequisite:** Parts 1-19 completed.

---

### 1. Event-triggered vs schedule-triggered functions

Part 19's function ran because something happened (an invoice was created) — there was always a specific request, a specific user action, that led to it. A scheduled function is different: nothing "happens" to trigger it — it just runs automatically at times you define, with no user present at all. This is exactly the "nightly check" pattern described back in Part 3: nobody is sitting there clicking a button at 2am, but the business still needs the reminder emails to go out.

### 2. Cron syntax, briefly

Inngest schedules functions using "cron syntax" — a compact way of describing recurring times, used by countless scheduling systems for decades. A cron expression has five parts: minute, hour, day-of-month, month, day-of-week. A few examples worth memorizing the shape of:
- `0 9 * * *` — every day at 9:00 AM
- `0 0 1 * *` — the first day of every month at midnight
- `*/15 * * * *` — every 15 minutes

You don't need to become a cron expert — just recognize the pattern and know you can look up "cron expression generator" online anytime you need a specific schedule.

### 3. Build the overdue invoice reminder function

Create src/lib/inngest/functions/send-overdue-reminders.ts:

```ts
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { organizations } from "@/lib/db/schema";
import { getArAging } from "@/lib/reports/ar-aging";

export const sendOverdueReminders = inngest.createFunction(
  { id: "send-overdue-reminders" },
  { cron: "0 9 * * *" }, // every day at 9:00 AM
  async ({ step }) => {
    const allOrgs = await step.run("fetch-organizations", async () => {
      return db.select().from(organizations);
    });

    const today = new Date().toISOString().slice(0, 10);

    for (const org of allOrgs) {
      await step.run(`check-org-${org.id}`, async () => {
        const { rows } = await getArAging(org.id, today);
        const overdue = rows.filter((r) => r.daysPastDue > 0);

        for (const invoice of overdue) {
          console.log(
            `[REMINDER] ${org.name}: Invoice ${invoice.invoiceNumber} for ${invoice.customerName} is ${invoice.daysPastDue} days overdue`
          );
        }

        return { orgId: org.id, overdueCount: overdue.length };
      });
    }

    return { checkedOrgs: allOrgs.length };
  }
);
```

Notice this reuses getArAging from Part 18 directly — a great example of why we built our reporting logic as clean, reusable functions rather than embedding it inline in a page component. The same aging calculation now powers both a report a human looks at, and an automated job that runs with nobody watching.

Also notice the loop wraps each organization's check in its own named step.run — this means if checking org #47 out of 100 throws an error, Inngest's retry will re-run starting from wherever it left off in terms of already-completed steps, not from scratch, and one organization's failure doesn't have to block the loop from being retried correctly for the rest.

### 4. Register the new function

Update src/app/api/inngest/route.ts to include it:

```ts
import { sendOverdueReminders } from "@/lib/inngest/functions/send-overdue-reminders";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [sendInvoiceEmail, sendOverdueReminders],
});
```

### 5. Test a scheduled function without waiting a full day

Waiting until 9am tomorrow to test this would be impractical. Inngest's local dev server (from Part 19, npx inngest-cli@latest dev) lets you manually trigger any registered function on demand for testing, regardless of its schedule. In the dev dashboard at localhost:8288, find the Functions tab, locate send-overdue-reminders, and use its "Invoke" or "Trigger" button to run it immediately.

Check your Next.js terminal — you should see [REMINDER] log lines for any invoices you have that are genuinely overdue (past their due date and still status "sent" or "partially_paid" — go create one with a past due date via /dashboard/invoices/new if you don't have one yet).

---

### 6. Build a simple recurring invoice generator

Many businesses send the same invoice every month (rent, retainer fees, subscriptions). Let's build a simple version: a recurring_invoice_templates table describing what to generate, and a scheduled function that creates real invoices from active templates on their due day.

Add to src/lib/db/schema.ts:

```ts
export const recurringInvoiceTemplates = pgTable("recurring_invoice_templates", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customers.id),
  description: text("description").notNull(),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
  dayOfMonth: integer("day_of_month").notNull(),
  isActive: boolean("is_active").notNull().default(true),
  lastGeneratedDate: date("last_generated_date"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Fields explained: `dayOfMonth` (e.g. 1 for "generate on the 1st of every month"), `lastGeneratedDate` (tracks the last date we generated an invoice from this template, so we don't double-generate if the job runs more than once on the same day).

Run:
```
npm run db:generate
npm run db:migrate
```

Create src/lib/inngest/functions/generate-recurring-invoices.ts:

```ts
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { recurringInvoiceTemplates, invoices, invoiceLines } from "@/lib/db/schema";
import { eq, and } from "drizzle-orm";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { findAccountBySubtype } from "@/lib/accounting/find-account";

export const generateRecurringInvoices = inngest.createFunction(
  { id: "generate-recurring-invoices" },
  { cron: "0 6 * * *" }, // every day at 6:00 AM, before the reminder job
  async ({ step }) => {
    const today = new Date();
    const todayStr = today.toISOString().slice(0, 10);
    const dayOfMonth = today.getDate();

    const dueTemplates = await step.run("find-due-templates", async () => {
      return db
        .select()
        .from(recurringInvoiceTemplates)
        .where(
          and(
            eq(recurringInvoiceTemplates.isActive, true),
            eq(recurringInvoiceTemplates.dayOfMonth, dayOfMonth)
          )
        );
    });

    for (const template of dueTemplates) {
      if (template.lastGeneratedDate === todayStr) continue; // already generated today

      await step.run(`generate-invoice-${template.id}`, async () => {
        const arAccount = await findAccountBySubtype(template.orgId, "accounts_receivable");
        const incomeAccount = await findAccountBySubtype(template.orgId, "income");

        await db.transaction(async (tx) => {
          const [invoice] = await tx
            .insert(invoices)
            .values({
              orgId: template.orgId,
              customerId: template.customerId,
              invoiceNumber: `REC-${template.id.slice(0, 8)}-${todayStr}`,
              issueDate: todayStr,
              dueDate: todayStr,
              totalCents: template.amountCents,
              status: "sent",
            })
            .returning();

          await tx.insert(invoiceLines).values({
            invoiceId: invoice.id,
            description: template.description,
            quantity: 1,
            unitPriceCents: template.amountCents,
            amountCents: template.amountCents,
          });

          await postJournalEntry(
            {
              orgId: template.orgId,
              date: today,
              memo: `Recurring invoice: ${template.description}`,
              sourceType: "invoice",
              sourceId: invoice.id,
              lines: [
                { accountId: arAccount.id, debitCents: template.amountCents },
                { accountId: incomeAccount.id, creditCents: template.amountCents },
              ],
            },
            tx
          );

          await tx
            .update(recurringInvoiceTemplates)
            .set({ lastGeneratedDate: todayStr })
            .where(eq(recurringInvoiceTemplates.id, template.id));
        });
      });
    }

    return { generatedCount: dueTemplates.length };
  }
);
```

Notice this function reuses postJournalEntry and findAccountBySubtype exactly as Part 13's createInvoice does — it's essentially "createInvoice, called by a robot instead of a human clicking a button." This is a good illustration of a bigger idea: once your core business logic (posting a balanced journal entry for an invoice) lives in one well-tested, reusable function, both humans (via forms) and automation (via scheduled jobs) can safely trigger the exact same underlying correctness guarantees.

Also notice the lastGeneratedDate check — a simple but important safeguard against accidentally generating duplicate invoices if this function were ever triggered twice on the same day (e.g., a manual test trigger followed by the real scheduled run).

Register it in src/app/api/inngest/route.ts alongside the other two functions.

### 7. Test the recurring invoice generator

You'd need a row in recurring_invoice_templates with today's day-of-month to see this fire today — insert one manually via Neon's SQL Editor for a quick test, e.g. set dayOfMonth to today's actual date, then manually trigger the function from the Inngest dev dashboard exactly as in step 5. Confirm a new invoice appears in /dashboard/invoices, and a correct journal entry was posted, exactly like a manually created invoice would produce.

### 8. Commit your progress

```
git add .
git commit -m "Add scheduled Inngest functions: overdue reminders and recurring invoice generation"
```

---

### Checkpoint

- [ ] sendOverdueReminders is registered with a cron trigger and reuses getArAging from Part 18
- [ ] You manually triggered it from the Inngest dev dashboard and saw correct reminder logs
- [ ] recurring_invoice_templates table exists, and generateRecurringInvoices correctly creates a real invoice + journal entry from a due template
- [ ] The lastGeneratedDate guard prevents double-generation on the same day
- [ ] You understand the difference between an event-triggered function (Part 19) and a cron-triggered function (this part)
- [ ] You can explain why reusing postJournalEntry/findAccountBySubtype here (rather than duplicating logic) matters

---

### Troubleshooting

**The scheduled function doesn't show up in the Inngest dev dashboard at all**
Confirm you registered it in src/app/api/inngest/route.ts's functions array (alongside sendInvoiceEmail) — a function that exists as a file but isn't added to that array will never be discovered by Inngest.

**Clicking "Invoke" / "Trigger" in the dashboard does nothing, or shows an error immediately**
Check the Inngest dashboard's function run detail view for the actual error message — a common cause for sendOverdueReminders specifically is that getArAging (from Part 18) throws if an organization has zero customers/invoices; confirm that function handles empty results gracefully (it should, since it just returns an empty rows array, but double check you copied it exactly as written in Part 18).

**generateRecurringInvoices runs successfully but creates zero invoices**
Confirm you actually inserted a test row into recurring_invoice_templates with dayOfMonth matching TODAY'S actual date (not next month or a future date) — the function only processes templates whose dayOfMonth equals `today.getDate()`. Query `SELECT * FROM recurring_invoice_templates;` in Neon's SQL Editor to confirm your test row's values.

**Running the recurring invoice generator twice on the same day creates two invoices instead of skipping the second run**
Confirm the `if (template.lastGeneratedDate === todayStr) continue;` line is present and that the update to lastGeneratedDate happens INSIDE the same db.transaction as the invoice creation (so it's guaranteed to be set before any possible second run could check it).

**Error: "No account found with subtype accounts_receivable" when triggering generateRecurringInvoices**
This means the organization referenced by your test template (`template.orgId`) doesn't have seeded default accounts. Confirm the orgId in your test recurring_invoice_templates row matches an organization that went through Part 9's seeding.

**Cron schedule seems to not matter at all during local development — is that expected?**
Yes — Inngest's local dev server lets you manually trigger cron-scheduled functions on demand specifically so you don't have to wait for the real schedule during development and testing. The cron expression only matters once deployed to Inngest Cloud in Part 23, where it truly runs unattended on that schedule.

**TypeScript complains about the loop variable `org` or `template` having an implicit `any` type**
Confirm your Drizzle query's `.select()` (with no explicit column list) returns full typed rows automatically based on your schema.ts definitions — if you see this error, double check you didn't accidentally destructure or reshape the query result in a way that lost its inferred type.

**You want to test with a shorter/different schedule while developing (not wait for 6am/9am equivalents)**
Since you can manually trigger any function from the Inngest dev dashboard regardless of its cron schedule, there's no need to temporarily change the cron string during development — just use the dashboard's manual trigger button as shown in step 5.

---

### What's next

Part 21: Importing Bank Transactions from CSV — we move into the Bank Data section, letting a user upload a CSV export from their bank and turning each row into a reviewable transaction ready to be categorized against the Chart of Accounts.
