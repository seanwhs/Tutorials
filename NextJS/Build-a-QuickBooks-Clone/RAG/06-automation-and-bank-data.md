# QB Clone: Automation and Bank Data - Inngest Jobs, Cron, CSV Import, Plaid Overview

File 7 of 8. Covers Inngest background jobs, scheduled/cron jobs, CSV bank import, and an optional Plaid overview. See file "00 Master Overview and Architecture" for the big picture.

---

## PART A: Your First Background Job

### Two core Inngest concepts

**An event** is data describing "something happened" (e.g. `{ name: "invoice/created", data: {...} }`) - your app SENDS events. **A function** RUNS in response to event(s) - registered ahead of time, called reliably with automatic retries, and (Part B below) can run on a schedule instead.

### Sign up and install

1. https://www.inngest.com, sign up free (no credit card)
2. Install:
```
npm install inngest
```

### Create the Inngest client

Create src/lib/inngest/client.ts:
```ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "qb-clone" });
```

### Create the Inngest API route

Create src/app/api/inngest/route.ts:
```ts
import { serve } from "inngest/next";
import { inngest } from "@/lib/inngest/client";
import { sendInvoiceEmail } from "@/lib/inngest/functions/send-invoice-email";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [sendInvoiceEmail],
});
```

### Write the first Inngest function

Create src/lib/inngest/functions/send-invoice-email.ts:
```ts
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { invoices, customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

export const sendInvoiceEmail = inngest.createFunction(
  { id: "send-invoice-email" },
  { event: "invoice/created" },
  async ({ event, step }) => {
    const { invoiceId } = event.data;

    const invoice = await step.run("fetch-invoice", async () => {
      const [inv] = await db
        .select({
          id: invoices.id,
          invoiceNumber: invoices.invoiceNumber,
          totalCents: invoices.totalCents,
          customerName: customers.name,
          customerEmail: customers.email,
        })
        .from(invoices)
        .innerJoin(customers, eq(customers.id, invoices.customerId))
        .where(eq(invoices.id, invoiceId))
        .limit(1);
      return inv;
    });

    if (!invoice || !invoice.customerEmail) {
      return { skipped: true, reason: "No invoice or customer email found" };
    }

    await step.run("send-email", async () => {
      // Logging instead of sending a real email keeps this focused on the Inngest pattern.
      console.log(
        `[EMAIL] To: ${invoice.customerEmail} - Invoice ${invoice.invoiceNumber} for $${(
          invoice.totalCents / 100
        ).toFixed(2)}`
      );
    });

    return { sent: true, invoiceId };
  }
);
```

Each `step.run("name", async () => {...})` is checkpointed: if the function fails partway and Inngest retries it, already-succeeded steps are NOT re-run - only the failed step (and anything after) runs again. This prevents e.g. double-sending an email on retry.

### Send the event when an invoice is created

Open src/app/dashboard/invoices/actions.ts (from file 04, PART C). After the db.transaction block completes successfully, add:
```ts
import { inngest } from "@/lib/inngest/client";

// ...inside createInvoice, after the db.transaction(...) call completes:

await inngest.send({
  name: "invoice/created",
  data: { invoiceId: /* the invoice id from inside the transaction */, orgId },
});
```
Capture the created invoice's id from inside the transaction so it's available here. CRITICAL: send the event AFTER the transaction commits, never before/inside - if you sent it inside and the transaction later rolled back (e.g. unbalanced entry), you'd fire an email event for an invoice that doesn't actually exist.

### Run Inngest's local dev server

```
npx inngest-cli@latest dev
```
Dashboard at http://localhost:8288 - shows every function it's discovered and every event sent, entirely locally.

### Test it

With both npm run dev and the Inngest dev server running, create an invoice. Check: (1) your Next.js terminal for the `[EMAIL]` log line appearing asynchronously; (2) the Inngest dashboard for the invoice/created event and the function run with both steps visible.

### Commit

```
git add .
git commit -m "Add Inngest, send invoice/created event, background email function with steps"
```

### Checkpoint A
- [ ] inngest installed, client created, API route registered
- [ ] sendInvoiceEmail uses step.run for its two stages
- [ ] createInvoice sends the event only after its transaction commits
- [ ] Inngest dev server shows the function and lets you watch it execute
- [ ] Creating an invoice triggers the background log, visible in both terminal and dashboard
- [ ] Understand why step.run matters for retry-safety, and why the event is sent after the transaction

### Troubleshooting A

**Nothing appears in the Inngest dashboard** - Confirm both `npx inngest-cli@latest dev` and `npm run dev` are still running in their own terminals.

**Function stays "Queued" forever** - The event was likely never sent - confirm `await inngest.send({...})` is present in createInvoice, after the transaction.

**"sendInvoiceEmail is not defined" in route.ts** - Confirm the import path matches exactly where the function file lives.

**Email log appears twice** - Check the Inngest dashboard's run details for a retry due to an earlier failure, or confirm you don't have two dev servers running at once.

**TypeScript error on event.data.invoiceId** - Add an explicit assertion: `const { invoiceId } = event.data as { invoiceId: string };` as a pragmatic fix.

**"Cannot find module 'inngest/next'"** - Confirm `npm install inngest` completed; check package.json.

**Invoice creation feels slower** - It shouldn't - inngest.send() is fire-and-forget. If genuinely slow, confirm nothing is accidentally awaited that blocks the request.

**localhost:8288 won't load** - Confirm the CLI command is still running without errors; check its terminal output for the actual port if 8288 was already in use.

---
```

Now PART B — Scheduled Jobs / Cron (overdue reminders and recurring invoice generation).
```markdown
## PART B: Scheduled Jobs / Cron

Event-triggered functions (Part A) run because something happened. Scheduled functions run automatically at defined times with nobody present. Cron syntax: 5 parts (minute, hour, day-of-month, month, day-of-week). Examples: `0 9 * * *` = every day 9am; `0 0 1 * *` = first of every month at midnight; `*/15 * * * *` = every 15 minutes.

### Build the overdue invoice reminder function

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
This reuses getArAging (file 05) directly - the same aging calculation now powers both a human-facing report and an automated job. Each organization's check is wrapped in its own named step.run so one org's failure doesn't force the whole loop to restart on retry.

### Register the new function

Update src/app/api/inngest/route.ts:
```ts
import { sendOverdueReminders } from "@/lib/inngest/functions/send-overdue-reminders";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [sendInvoiceEmail, sendOverdueReminders],
});
```

### Test without waiting a full day

In the Inngest dev dashboard (localhost:8288), Functions tab, find send-overdue-reminders, click "Invoke"/"Trigger" to run it immediately regardless of schedule. Check your terminal for [REMINDER] lines (create a test invoice with a past due date if needed).

### Build a simple recurring invoice generator

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
      if (template.lastGeneratedDate === todayStr) continue;

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
This reuses postJournalEntry and findAccountBySubtype exactly as createInvoice does - "createInvoice, called by a robot instead of a human clicking a button." The lastGeneratedDate check prevents duplicate generation if triggered twice on the same day.

Register it in route.ts alongside the other two functions.

### Test the recurring invoice generator

Insert a test row into recurring_invoice_templates with dayOfMonth set to today's actual date via Neon's SQL Editor, then manually trigger the function from the Inngest dashboard. Confirm a new invoice + correct journal entry appear.

### Commit

```
git add .
git commit -m "Add scheduled Inngest functions: overdue reminders and recurring invoice generation"
```

### Checkpoint B
- [ ] sendOverdueReminders registered with a cron trigger, reuses getArAging
- [ ] Manually triggered it and saw correct reminder logs
- [ ] recurring_invoice_templates table exists; generateRecurringInvoices creates a real invoice + journal entry from a due template
- [ ] lastGeneratedDate guard prevents double-generation on the same day
- [ ] Understand event-triggered vs cron-triggered functions
- [ ] Understand why reusing postJournalEntry/findAccountBySubtype here matters

### Troubleshooting B

**Scheduled function doesn't appear in the dashboard** - Confirm it's registered in route.ts's functions array.

**"Invoke" does nothing or errors** - Check the run's error detail; confirm getArAging handles zero invoices/customers gracefully (it should, per file 05).

**generateRecurringInvoices runs but creates zero invoices** - Confirm your test template's dayOfMonth equals TODAY'S actual date exactly.

**Running it twice creates two invoices instead of skipping** - Confirm the `if (template.lastGeneratedDate === todayStr) continue;` line is present, and the update happens inside the same transaction.

**"No account found with subtype accounts_receivable"** - The template's orgId doesn't have seeded default accounts.

**Cron schedule "not mattering" locally** - Expected - manual triggering during development bypasses the schedule; the cron only matters once deployed (file 07).

---
```

**PART B is now complete** — append this to `06-automation-and-bank-data.md`, right after PART A.

Now PART C — Importing Bank Transactions from CSV.
```markdown
## PART C: Importing Bank Transactions from CSV

CSV import is the universal fallback nearly every accounting product supports - works today, for any bank, with no external API dependency (unlike Plaid, Part D below, which is Phase 2/optional).

### Workflow

1. User exports a CSV from their bank (external to this app)
2. Upload it into the app
3. Parse and store each row as uncategorized in bank_transactions
4. User reviews and assigns each to a Chart of Accounts category
5. Categorizing posts a journal entry, same as invoices/bills

### Add the schema

Add to src/lib/db/schema.ts:
```ts
export const bankTransactions = pgTable("bank_transactions", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  bankAccountId: uuid("bank_account_id")
    .notNull()
    .references(() => accounts.id),
  transactionDate: date("transaction_date").notNull(),
  description: text("description").notNull(),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(), // positive = money in, negative = money out
  status: text("status").notNull().default("uncategorized"),
  categorizedAccountId: uuid("categorized_account_id").references(() => accounts.id),
  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```
(For simplicity, bankAccountId references the org's Checking account directly rather than a separate bank_accounts table - one bank account is enough to learn the pattern.)

Run:
```
npm run db:generate
npm run db:migrate
```

### Install a CSV parser

```
npm install papaparse
npm install -D @types/papaparse
```

### Build the CSV upload and parsing action

Assumes a simple CSV shape: Date, Description, Amount. Create src/app/dashboard/bank-import/actions.ts:

```ts
"use server";

import { db } from "@/lib/db";
import { bankTransactions, accounts } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import Papa from "papaparse";
import { findAccountBySubtype } from "@/lib/accounting/find-account";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { eq } from "drizzle-orm";

export async function importCsv(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const file = formData.get("csvFile") as File;
  if (!file || file.size === 0) throw new Error("Please choose a CSV file");

  const text = await file.text();
  const parsed = Papa.parse<{ Date: string; Description: string; Amount: string }>(text, {
    header: true,
    skipEmptyLines: true,
  });

  const bankAccount = await findAccountBySubtype(orgId, "bank");

  const rows = parsed.data
    .filter((r) => r.Date && r.Description && r.Amount)
    .map((r) => ({
      orgId,
      bankAccountId: bankAccount.id,
      transactionDate: r.Date,
      description: r.Description,
      amountCents: Math.round(Number(r.Amount) * 100),
      status: "uncategorized" as const,
    }));

  if (rows.length === 0) {
    throw new Error("No valid rows found in that CSV file");
  }

  await db.insert(bankTransactions).values(rows);

  revalidatePath("/dashboard/bank-import");
  redirect("/dashboard/bank-import");
}

export async function categorizeBankTransaction(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const transactionId = formData.get("transactionId") as string;
  const accountId = formData.get("accountId") as string;

  const [txn] = await db.select().from(bankTransactions).where(eq(bankTransactions.id, transactionId)).limit(1);
  if (!txn || txn.orgId !== orgId) throw new Error("Invalid transaction");

  const [chosenAccount] = await db.select().from(accounts).where(eq(accounts.id, accountId)).limit(1);
  if (!chosenAccount || chosenAccount.orgId !== orgId) throw new Error("Invalid account");

  const amountCents = Math.abs(txn.amountCents);
  const isMoneyIn = txn.amountCents > 0;

  await db.transaction(async (tx) => {
    const lines = isMoneyIn
      ? [
          { accountId: txn.bankAccountId, debitCents: amountCents },
          { accountId: chosenAccount.id, creditCents: amountCents },
        ]
      : [
          { accountId: chosenAccount.id, debitCents: amountCents },
          { accountId: txn.bankAccountId, creditCents: amountCents },
        ];

    const entry = await postJournalEntry(
      {
        orgId,
        date: new Date(txn.transactionDate),
        memo: `Bank: ${txn.description}`,
        sourceType: "bank_transaction",
        sourceId: txn.id,
        lines,
      },
      tx
    );

    await tx
      .update(bankTransactions)
      .set({ status: "categorized", categorizedAccountId: chosenAccount.id, journalEntryId: entry.id })
      .where(eq(bankTransactions.id, txn.id));
  });

  revalidatePath("/dashboard/bank-import");
}
```

Notice `formData.get("csvFile") as File` gives native file upload support in Server Actions (encType handled automatically). Notice the isMoneyIn branch: money IN debits the bank account and credits the chosen category (e.g. Income); money OUT debits the category (e.g. Expense) and credits the bank account - the direction is decided dynamically by the sign of the amount, unlike invoices/bills which always post the same fixed direction.

### Build the upload form and review list page

Create src/app/dashboard/bank-import/page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { bankTransactions, accounts } from "@/lib/db/schema";
import { eq, and } from "drizzle-orm";
import { importCsv, categorizeBankTransaction } from "./actions";

export default async function BankImportPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const uncategorized = await db
    .select()
    .from(bankTransactions)
    .where(and(eq(bankTransactions.orgId, orgId), eq(bankTransactions.status, "uncategorized")));

  const allAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.orgId, orgId))
    .orderBy(accounts.code);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Bank Import</h1>

      <form action={importCsv} style={{ marginBottom: "2rem" }}>
        <input type="file" name="csvFile" accept=".csv" required />
        <button type="submit">Upload CSV</button>
      </form>

      <h2>Uncategorized Transactions</h2>
      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Date</th>
            <th>Description</th>
            <th>Amount</th>
            <th>Categorize</th>
          </tr>
        </thead>
        <tbody>
          {uncategorized.map((t) => (
            <tr key={t.id}>
              <td>{t.transactionDate}</td>
              <td>{t.description}</td>
              <td>{(t.amountCents / 100).toFixed(2)}</td>
              <td>
                <form action={categorizeBankTransaction} style={{ display: "flex", gap: "0.5rem" }}>
                  <input type="hidden" name="transactionId" value={t.id} />
                  <select name="accountId" required>
                    <option value="">Choose account</option>
                    {allAccounts.map((a) => (
                      <option key={a.id} value={a.id}>{a.name}</option>
                    ))}
                  </select>
                  <button type="submit">Categorize</button>
                </form>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

### Test the whole flow

Create a test CSV (test-transactions.csv):
```
Date,Description,Amount
2025-01-05,OFFICE DEPOT,-45.99
2025-01-06,CLIENT PAYMENT,500.00
2025-01-07,ELECTRIC COMPANY,-120.00
```
Upload it, confirm three uncategorized rows appear, categorize each one, and confirm each produces a correct journal entry (check Neon for source_type = 'bank_transaction').

Add a "Bank Import" nav link.

### Commit

```
git add .
git commit -m "Add CSV bank transaction import and categorization posting journal entries"
```

### Checkpoint C
- [ ] bank_transactions table exists
- [ ] Uploading a CSV correctly parses rows and stores them as uncategorized
- [ ] Categorizing a transaction posts a correct journal entry, direction depending on money in vs out
- [ ] Understand why the debit/credit direction flips here, unlike invoices/bills
- [ ] Can describe how a more robust version would support flexible CSV column mapping

### Troubleshooting C

**"Please choose a CSV file" despite selecting one** - Confirm the file input is named exactly csvFile.

**Zero rows appear after upload** - Confirm the CSV header row is spelled EXACTLY Date,Description,Amount (case-sensitive).

**Amounts 100x too large/small** - Confirm Math.round(Number(r.Amount) * 100) is present exactly as shown.

**"Invalid account selected"** - Confirm the chosen account belongs to the currently active organization.

**Debit/credit direction looks backwards** - Re-check the sign convention of your CSV (negative = money out, positive = money in, per this course's assumption) - some banks use the opposite convention.

**"Module not found: papaparse"** - Confirm both npm install papaparse and npm install -D @types/papaparse ran successfully.

**Categorized transactions still show as uncategorized** - Confirm the status update is inside the same transaction as postJournalEntry, and the list query filters status = 'uncategorized'.

---
```

**PART C is now complete** — append this to `06-automation-and-bank-data.md`, right after PART B.

Now PART D — the optional Plaid overview, completing `06-automation-and-bank-data.md`.
```markdown
## PART D (Optional/Phase 2 Preview): Connecting Real Banks with Plaid

This part is intentionally lighter on exact code - Plaid requires a developer account, has real security/compliance considerations, and is Phase 2, not required for a working demoable app. The app is already fully functional without it (Part C's CSV import solves the same underlying problem today, for any bank).

### What Plaid is

A service sitting between your app and thousands of banks, letting users securely connect their real bank account without ever giving your app their actual bank username/password. Your app receives a token representing that connection and can fetch transactions on an ongoing basis. This is meaningfully different from everything else in the stack: Plaid involves a THIRD PARTY holding a live, ongoing connection to a user's real financial institution - a bigger trust/security responsibility than anything else here, which is why production use requires Plaid's approval process.

### The Plaid Link flow, conceptually

1. App asks Plaid for a "link token"
2. App shows Plaid's own prebuilt "Plaid Link" UI popup - user logs into their real bank directly with Plaid, never your servers
3. On success, Plaid gives the app a "public token"
4. Server exchanges the public token for a permanent "access token" - stored, used going forward
5. App calls Plaid's transactions API periodically (an Inngest cron job, exactly like Part B's pattern)
6. Each fetched transaction inserts into the SAME bank_transactions table and categorization flow from Part C - zero changes needed

This last point matters: designing the data model around the underlying concept ("a bank transaction needing categorization") rather than a specific data source means Plaid becomes just a second, automated way of populating the same table CSV upload already populates.

### Setting up a Plaid developer account (optional)

1. https://plaid.com, sign up free
2. Use the "Sandbox" environment - fake banks, fake credentials, no real data or compliance concerns
3. Get a client_id and secret (sandbox-specific) - same .env.local discipline as every other secret

### A minimal sandbox-only sketch (optional to build)

```
npm install plaid react-plaid-link
```

src/lib/plaid/client.ts:
```ts
import { Configuration, PlaidApi, PlaidEnvironments } from "plaid";

const configuration = new Configuration({
  basePath: PlaidEnvironments.sandbox,
  baseOptions: {
    headers: {
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID!,
      "PLAID-SECRET": process.env.PLAID_SECRET!,
    },
  },
});

export const plaidClient = new PlaidApi(configuration);
```

A route src/app/api/plaid/create-link-token/route.ts would call `plaidClient.linkTokenCreate({...})` and return it to the browser. The frontend uses react-plaid-link's usePlaidLink hook to open the Plaid Link popup. On success, send the public_token to another route calling `plaidClient.itemPublicTokenExchange({...})` for the permanent access_token, stored (ideally encrypted) per organization.

This is intentionally not built out fully line-by-line - use Plaid's own quickstart docs alongside this conceptual map for the deeper implementation.

### Fetching transactions on a schedule

Once you have a stored access_token, an Inngest cron function (Part B's pattern) would run nightly, call `plaidClient.transactionsSync({ access_token })`, and insert new transactions into bank_transactions with status "uncategorized" - reusing 100% of Part C's review/categorization UI.

### Troubleshooting D

**Plaid signup asks for business info you don't have** - Sandbox-only experimentation is still free and typically only needs basic developer details, no real registered business required.

**"Cannot find module 'plaid'"** - Confirm npm install plaid react-plaid-link ran, if you chose to experiment.

**PLAID_CLIENT_ID/PLAID_SECRET undefined** - Add to .env.local, never commit, restart dev server.

**Plaid Link popup never opens** - Check browser console for errors from the link-token route; confirm PlaidEnvironments.sandbox specifically.

**Unsure whether to build this out** - Skip it unless specifically motivated to explore bank feeds - the core app (files 1-6 plus 7's deployment) is fully complete and demoable without any Plaid code.

---

This completes file 7 of 8 (Automation and Bank Data). Proceed to file "07 Deployment and Roadmap - Free Vercel Hosting, Phase 2/3 Plan" next.
```

**`06-automation-and-bank-data.md` is now complete** — Parts A, B, C, and D all appended in sequence.

