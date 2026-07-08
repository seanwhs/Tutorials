## Appendix A Part 2: DB Client, Accounting, Reports (first section)

### src/lib/db/index.ts

```ts
import { Pool, neonConfig } from "@neondatabase/serverless";
import { drizzle } from "drizzle-orm/neon-serverless";
import ws from "ws";
import * as schema from "./schema";

neonConfig.webSocketConstructor = ws;

const pool = new Pool({ connectionString: process.env.DATABASE_URL! });

export const db = drizzle(pool, { schema });
```

### src/lib/db/seed-default-accounts.ts

```ts
import { db } from "./index";
import { accounts } from "./schema";

export async function seedDefaultAccounts(orgId: string) {
  await db.insert(accounts).values([
    { orgId, code: "1000", name: "Checking Account", type: "asset", subtype: "bank", normalBalance: "debit" },
    { orgId, code: "1100", name: "Accounts Receivable", type: "asset", subtype: "accounts_receivable", normalBalance: "debit" },
    { orgId, code: "1200", name: "Undeposited Funds", type: "asset", subtype: "other_current_asset", normalBalance: "debit" },
    { orgId, code: "1500", name: "Fixed Assets", type: "asset", subtype: "fixed_asset", normalBalance: "debit" },
    { orgId, code: "2000", name: "Accounts Payable", type: "liability", subtype: "accounts_payable", normalBalance: "credit" },
    { orgId, code: "2100", name: "Credit Card", type: "liability", subtype: "credit_card", normalBalance: "credit" },
    { orgId, code: "3000", name: "Owner's Equity", type: "equity", subtype: "equity", normalBalance: "credit" },
    { orgId, code: "3100", name: "Retained Earnings", type: "equity", subtype: "equity", normalBalance: "credit" },
    { orgId, code: "4000", name: "Sales Income", type: "income", subtype: "income", normalBalance: "credit" },
    { orgId, code: "4100", name: "Service Income", type: "income", subtype: "income", normalBalance: "credit" },
    { orgId, code: "5000", name: "Cost of Goods Sold", type: "expense", subtype: "cogs", normalBalance: "debit" },
    { orgId, code: "5100", name: "Advertising Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5200", name: "Office Supplies Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5300", name: "Rent Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5400", name: "Utilities Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
    { orgId, code: "5500", name: "Payroll Expense", type: "expense", subtype: "expense", normalBalance: "debit" },
  ]);
}
```

### src/lib/accounting/post-journal-entry.ts (the core engine)

```ts
import { db } from "@/lib/db";
import { journalEntries, journalLines } from "@/lib/db/schema";

type JournalLineInput = {
  accountId: string;
  debitCents?: number;
  creditCents?: number;
};

type PostJournalEntryParams = {
  orgId: string;
  date: Date;
  memo?: string;
  sourceType:
    | "manual"
    | "invoice"
    | "bill"
    | "payment_received"
    | "payment_made"
    | "opening_balance"
    | "bank_transaction"
    | "reversal";
  sourceId?: string;
  lines: JournalLineInput[];
};

export async function postJournalEntry(
  params: PostJournalEntryParams,
  tx?: typeof db
) {
  const { orgId, date, memo, sourceType, sourceId, lines } = params;

  if (lines.length < 2) {
    throw new Error("A journal entry needs at least two lines");
  }

  const totalDebits = lines.reduce((sum, l) => sum + (l.debitCents ?? 0), 0);
  const totalCredits = lines.reduce((sum, l) => sum + (l.creditCents ?? 0), 0);

  if (totalDebits !== totalCredits) {
    throw new Error(
      `Journal entry is unbalanced: debits ${totalDebits} !== credits ${totalCredits}`
    );
  }

  async function runPosting(activeTx: typeof db) {
    const [entry] = await activeTx
      .insert(journalEntries)
      .values({
        orgId,
        date: date.toISOString().slice(0, 10),
        memo,
        sourceType,
        sourceId,
      })
      .returning();

    await activeTx.insert(journalLines).values(
      lines.map((l) => ({
        entryId: entry.id,
        accountId: l.accountId,
        debitCents: l.debitCents ?? 0,
        creditCents: l.creditCents ?? 0,
      }))
    );

    return entry;
  }

  if (tx) {
    return runPosting(tx);
  }
  return db.transaction(async (innerTx) => runPosting(innerTx));
}
```

### src/lib/accounting/find-account.ts

```ts
import { db } from "@/lib/db";
import { accounts } from "@/lib/db/schema";
import { and, eq } from "drizzle-orm";

export async function findAccountBySubtype(orgId: string, subtype: string) {
  const [account] = await db
    .select()
    .from(accounts)
    .where(and(eq(accounts.orgId, orgId), eq(accounts.subtype, subtype)))
    .limit(1);

  if (!account) {
    throw new Error(`No account found with subtype "${subtype}" for this organization`);
  }

  return account;
}
```

### src/lib/reports/profit-and-loss.ts

```ts
import { db } from "@/lib/db";
import { accounts, journalEntries, journalLines } from "@/lib/db/schema";
import { and, eq, gte, lte, inArray } from "drizzle-orm";
import { sql } from "drizzle-orm";

export async function getProfitAndLoss(orgId: string, startDate: string, endDate: string) {
  const rows = await db
    .select({
      accountId: accounts.id,
      accountName: accounts.name,
      accountType: accounts.type,
      totalDebitCents: sql<number>`COALESCE(SUM(${journalLines.debitCents}), 0)`,
      totalCreditCents: sql<number>`COALESCE(SUM(${journalLines.creditCents}), 0)`,
    })
    .from(accounts)
    .leftJoin(journalLines, eq(journalLines.accountId, accounts.id))
    .leftJoin(
      journalEntries,
      and(
        eq(journalEntries.id, journalLines.entryId),
        gte(journalEntries.date, startDate),
        lte(journalEntries.date, endDate)
      )
    )
    .where(
      and(
        eq(accounts.orgId, orgId),
        inArray(accounts.type, ["income", "expense"])
      )
    )
    .groupBy(accounts.id, accounts.name, accounts.type);

  const income = rows
    .filter((r) => r.accountType === "income")
    .map((r) => ({
      ...r,
      balanceCents: Number(r.totalCreditCents) - Number(r.totalDebitCents),
    }));

  const expense = rows
    .filter((r) => r.accountType === "expense")
    .map((r) => ({
      ...r,
      balanceCents: Number(r.totalDebitCents) - Number(r.totalCreditCents),
    }));

  const totalIncomeCents = income.reduce((sum, r) => sum + r.balanceCents, 0);
  const totalExpenseCents = expense.reduce((sum, r) => sum + r.balanceCents, 0);
  const netProfitCents = totalIncomeCents - totalExpenseCents;

  return { income, expense, totalIncomeCents, totalExpenseCents, netProfitCents };
}
```

---

## Appendix A Part 2b: Balance Sheet, Aging Reports, Inngest

### src/lib/reports/balance-sheet.ts

```ts
import { db } from "@/lib/db";
import { accounts, journalEntries, journalLines } from "@/lib/db/schema";
import { eq, lte, and, inArray, sql } from "drizzle-orm";

export async function getBalanceSheet(orgId: string, asOfDate: string) {
  const rows = await db
    .select({
      accountId: accounts.id,
      accountName: accounts.name,
      accountType: accounts.type,
      totalDebitCents: sql<number>`COALESCE(SUM(${journalLines.debitCents}), 0)`,
      totalCreditCents: sql<number>`COALESCE(SUM(${journalLines.creditCents}), 0)`,
    })
    .from(accounts)
    .leftJoin(journalLines, eq(journalLines.accountId, accounts.id))
    .leftJoin(
      journalEntries,
      and(eq(journalEntries.id, journalLines.entryId), lte(journalEntries.date, asOfDate))
    )
    .where(and(eq(accounts.orgId, orgId), inArray(accounts.type, ["asset", "liability", "equity", "income", "expense"])))
    .groupBy(accounts.id, accounts.name, accounts.type);

  const withBalance = rows.map((r) => {
    const debits = Number(r.totalDebitCents);
    const credits = Number(r.totalCreditCents);
    let balanceCents: number;
    if (r.accountType === "asset" || r.accountType === "expense") {
      balanceCents = debits - credits;
    } else {
      balanceCents = credits - debits;
    }
    return { ...r, balanceCents };
  });

  const assets = withBalance.filter((r) => r.accountType === "asset");
  const liabilities = withBalance.filter((r) => r.accountType === "liability");
  const equity = withBalance.filter((r) => r.accountType === "equity");
  const income = withBalance.filter((r) => r.accountType === "income");
  const expense = withBalance.filter((r) => r.accountType === "expense");

  const totalAssetsCents = assets.reduce((s, r) => s + r.balanceCents, 0);
  const totalLiabilitiesCents = liabilities.reduce((s, r) => s + r.balanceCents, 0);
  const totalEquityCents = equity.reduce((s, r) => s + r.balanceCents, 0);

  const netIncomeCents =
    income.reduce((s, r) => s + r.balanceCents, 0) - expense.reduce((s, r) => s + r.balanceCents, 0);

  const totalEquityWithNetIncomeCents = totalEquityCents + netIncomeCents;

  return {
    assets,
    liabilities,
    equity,
    netIncomeCents,
    totalAssetsCents,
    totalLiabilitiesCents,
    totalEquityWithNetIncomeCents,
    isBalanced:
      totalAssetsCents === totalLiabilitiesCents + totalEquityWithNetIncomeCents,
  };
}
```

### src/lib/reports/ar-aging.ts

```ts
import { db } from "@/lib/db";
import { invoices, customers } from "@/lib/db/schema";
import { and, eq, inArray } from "drizzle-orm";

function daysOverdue(dueDate: string, asOfDate: string) {
  const due = new Date(dueDate);
  const asOf = new Date(asOfDate);
  const msPerDay = 1000 * 60 * 60 * 24;
  return Math.floor((asOf.getTime() - due.getTime()) / msPerDay);
}

function bucketFor(daysPastDue: number) {
  if (daysPastDue <= 0) return "current";
  if (daysPastDue <= 30) return "days1to30";
  if (daysPastDue <= 60) return "days31to60";
  return "days61plus";
}

export async function getArAging(orgId: string, asOfDate: string) {
  const openInvoices = await db
    .select({
      id: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      dueDate: invoices.dueDate,
      totalCents: invoices.totalCents,
      customerName: customers.name,
    })
    .from(invoices)
    .innerJoin(customers, eq(customers.id, invoices.customerId))
    .where(
      and(
        eq(invoices.orgId, orgId),
        inArray(invoices.status, ["sent", "partially_paid"])
      )
    );

  const rows = openInvoices.map((inv) => {
    const daysPastDue = daysOverdue(inv.dueDate, asOfDate);
    return { ...inv, daysPastDue, bucket: bucketFor(daysPastDue) };
  });

  const totals = {
    current: 0,
    days1to30: 0,
    days31to60: 0,
    days61plus: 0,
  };
  for (const r of rows) {
    totals[r.bucket as keyof typeof totals] += r.totalCents;
  }

  return { rows, totals };
}
```

### src/lib/reports/ap-aging.ts

```ts
import { db } from "@/lib/db";
import { bills, vendors } from "@/lib/db/schema";
import { and, eq, inArray } from "drizzle-orm";

function daysOverdue(dueDate: string, asOfDate: string) {
  const due = new Date(dueDate);
  const asOf = new Date(asOfDate);
  const msPerDay = 1000 * 60 * 60 * 24;
  return Math.floor((asOf.getTime() - due.getTime()) / msPerDay);
}

function bucketFor(daysPastDue: number) {
  if (daysPastDue <= 0) return "current";
  if (daysPastDue <= 30) return "days1to30";
  if (daysPastDue <= 60) return "days31to60";
  return "days61plus";
}

export async function getApAging(orgId: string, asOfDate: string) {
  const openBills = await db
    .select({
      id: bills.id,
      billNumber: bills.billNumber,
      dueDate: bills.dueDate,
      totalCents: bills.totalCents,
      vendorName: vendors.name,
    })
    .from(bills)
    .innerJoin(vendors, eq(vendors.id, bills.vendorId))
    .where(
      and(
        eq(bills.orgId, orgId),
        inArray(bills.status, ["open", "partially_paid"])
      )
    );

  const rows = openBills.map((b) => {
    const daysPastDue = daysOverdue(b.dueDate, asOfDate);
    return { ...b, daysPastDue, bucket: bucketFor(daysPastDue) };
  });

  const totals = {
    current: 0,
    days1to30: 0,
    days31to60: 0,
    days61plus: 0,
  };
  for (const r of rows) {
    totals[r.bucket as keyof typeof totals] += r.totalCents;
  }

  return { rows, totals };
}
```

### src/lib/inngest/client.ts

```ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "qb-clone" });
```

### src/lib/inngest/functions/send-invoice-email.ts

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

---

## Appendix A Part 2c: Remaining Inngest Functions

### src/lib/inngest/functions/send-overdue-reminders.ts

```ts
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { organizations } from "@/lib/db/schema";
import { getArAging } from "@/lib/reports/ar-aging";

export const sendOverdueReminders = inngest.createFunction(
  { id: "send-overdue-reminders" },
  { cron: "0 9 * * *" },
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

### src/lib/inngest/functions/generate-recurring-invoices.ts

```ts
import { inngest } from "@/lib/inngest/client";
import { db } from "@/lib/db";
import { recurringInvoiceTemplates, invoices, invoiceLines } from "@/lib/db/schema";
import { eq, and } from "drizzle-orm";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { findAccountBySubtype } from "@/lib/accounting/find-account";

export const generateRecurringInvoices = inngest.createFunction(
  { id: "generate-recurring-invoices" },
  { cron: "0 6 * * *" },
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

This is the end of the `src/lib/` business logic layer. All files in `src/lib/db/`, `src/lib/accounting/`, `src/lib/reports/`, and `src/lib/inngest/` have now been shown in full across Appendix A Parts 1b, 1c, 2, 2b, and 2c.

---

Next up is **Appendix A Part 3 (Root Pages, Middleware, Dashboard Core)** — `layout.tsx`, `middleware.ts`, the homepage, and the dashboard's core pages (accounts, customers, vendors). 
