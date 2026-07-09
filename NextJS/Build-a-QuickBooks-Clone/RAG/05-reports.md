# QB Clone: Reports - Profit and Loss, Balance Sheet, AR/AP Aging

File 6 of 8. Covers the Profit and Loss report, the Balance Sheet, and the AR/AP Aging reports. See file "00 Master Overview and Architecture" for the big picture.

---

## PART A: Building the Profit and Loss Report

A P&L answers: "over this period of time, did the business make or lose money, and on what?" Always a date RANGE (unlike the Balance Sheet, which is a snapshot at one instant). Income accounts are credit-normal, Expense accounts are debit-normal:
- Income balance for a period = SUM(credits) - SUM(debits)
- Expense balance for a period = SUM(debits) - SUM(credits)

### Write the report query

Create folder src/lib/reports/, inside it profit-and-loss.ts:

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

CRITICAL DETAIL: the date range filter (gte/lte on journalEntries.date) is inside the leftJoin's ON clause (the `and(...)` in the second leftJoin's second argument), NOT in a separate WHERE clause. If you filtered by date in WHERE instead, accounts with zero matching journal lines in that range would be silently excluded entirely, when the correct behavior is to show them with a $0 balance (thanks to COALESCE). This is a genuinely common source of report bugs in any system, not just accounting ones.

### Build the report page

Create src/app/dashboard/reports/profit-and-loss/page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { getProfitAndLoss } from "@/lib/reports/profit-and-loss";

function formatCents(cents: number) {
  return (cents / 100).toLocaleString("en-US", { style: "currency", currency: "USD" });
}

export default async function ProfitAndLossPage({
  searchParams,
}: {
  searchParams: Promise<{ start?: string; end?: string }>;
}) {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const { start, end } = await searchParams;
  const now = new Date();
  const defaultStart = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().slice(0, 10);
  const defaultEnd = now.toISOString().slice(0, 10);

  const startDate = start ?? defaultStart;
  const endDate = end ?? defaultEnd;

  const report = await getProfitAndLoss(orgId, startDate, endDate);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Profit & Loss</h1>
      <form style={{ marginBottom: "1rem", display: "flex", gap: "0.5rem" }}>
        <input type="date" name="start" defaultValue={startDate} />
        <input type="date" name="end" defaultValue={endDate} />
        <button type="submit">Update</button>
      </form>

      <h2>Income</h2>
      <table border={1} cellPadding={8}>
        <tbody>
          {report.income.map((r) => (
            <tr key={r.accountId}>
              <td>{r.accountName}</td>
              <td>{formatCents(r.balanceCents)}</td>
            </tr>
          ))}
          <tr>
            <td><strong>Total Income</strong></td>
            <td><strong>{formatCents(report.totalIncomeCents)}</strong></td>
          </tr>
        </tbody>
      </table>

      <h2>Expenses</h2>
      <table border={1} cellPadding={8}>
        <tbody>
          {report.expense.map((r) => (
            <tr key={r.accountId}>
              <td>{r.accountName}</td>
              <td>{formatCents(r.balanceCents)}</td>
            </tr>
          ))}
          <tr>
            <td><strong>Total Expenses</strong></td>
            <td><strong>{formatCents(report.totalExpenseCents)}</strong></td>
          </tr>
        </tbody>
      </table>

      <h2>Net {report.netProfitCents >= 0 ? "Profit" : "Loss"}: {formatCents(Math.abs(report.netProfitCents))}</h2>
    </main>
  );
}
```

Notice searchParams is how a Server Component reads the URL's query string. A plain HTML form with default GET behavior naturally produces URLs like `?start=2025-01-01&end=2025-01-31` with no JavaScript needed.

### Test it

Visit /dashboard/reports/profit-and-loss. Should show Income/Expense accounts with correct totals and a net profit/loss figure. Try a date range before any transactions - all accounts should show $0 (confirming the ON-clause fix), not an empty report. Cross-check one account's total by hand against real invoices/bills.

Add a report link to the dashboard nav.

### Commit

```
git add .
git commit -m "Add Profit and Loss report computed from journal_lines with date range filtering"
```

### Checkpoint A
- [ ] getProfitAndLoss correctly sums income (credits - debits) and expenses (debits - credits)
- [ ] Date range filter is in the JOIN's ON clause, not WHERE, so zero-activity accounts still show $0
- [ ] Report page reads start/end from URL search params, defaults to current month
- [ ] Manually cross-checked at least one account's total
- [ ] Understand why a P&L is for a date range, unlike the Balance Sheet

### Troubleshooting A

**Blank Income/Expenses even with invoices/bills** - Confirm the date filter is in the leftJoin's ON clause, not a separate WHERE.

**"Cannot read properties of undefined (reading 'totalDebitCents')"** - Confirm the `sql` import from drizzle-orm is present.

**Numbers off by a factor of 100** - Confirm formatCents divides by 100 before display, and you're not double-converting elsewhere.

**Date picker reloads but numbers never change** - Confirm the form has no action/onSubmit - it should rely on default GET behavior.

**"Property 'start' does not exist on type..."** - Confirm the signature is `searchParams: Promise<{ start?: string; end?: string }>` and you `await searchParams`.

**Net Profit/Loss sign looks wrong** - netProfitCents = totalIncomeCents - totalExpenseCents; use Math.abs() only when displaying.

---
```

Now PART B — Building the Balance Sheet.
```markdown
## PART B: Building the Balance Sheet

A snapshot AS OF a single date (not a range like the P&L), showing Assets, Liabilities, Equity. P&L = a movie (a period of activity); Balance Sheet = a photograph (a single instant).

Asset balance = SUM(debits) - SUM(credits), all-time up to the as-of date. Liability/Equity balance = SUM(credits) - SUM(debits). Current-period net income (income minus expenses, not yet formally "closed") is folded into Equity as a computed line. The equation being proved: Total Assets = Total Liabilities + Total Equity (including folded-in net income) - if this doesn't hold, something posted an unbalanced entry, which postJournalEntry (file 03) should make impossible. This report is a live integrity check on the whole ledger.

### Write the report query

Create src/lib/reports/balance-sheet.ts:

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

Notice the same ON-clause date filtering fix from the P&L report is reused here (lte(journalEntries.date, asOfDate) inside the join condition), so ALL accounts appear even with zero activity. Notice `isBalanced` - a genuinely useful integrity-check field.

### Build the report page

Create src/app/dashboard/reports/balance-sheet/page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { getBalanceSheet } from "@/lib/reports/balance-sheet";

function formatCents(cents: number) {
  return (cents / 100).toLocaleString("en-US", { style: "currency", currency: "USD" });
}

export default async function BalanceSheetPage({
  searchParams,
}: {
  searchParams: Promise<{ asOf?: string }>;
}) {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const { asOf } = await searchParams;
  const asOfDate = asOf ?? new Date().toISOString().slice(0, 10);

  const report = await getBalanceSheet(orgId, asOfDate);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Balance Sheet</h1>
      <form style={{ marginBottom: "1rem" }}>
        <label>As of: <input type="date" name="asOf" defaultValue={asOfDate} /></label>
        <button type="submit">Update</button>
      </form>

      <h2>Assets</h2>
      <table border={1} cellPadding={8}>
        <tbody>
          {report.assets.map((r) => (
            <tr key={r.accountId}><td>{r.accountName}</td><td>{formatCents(r.balanceCents)}</td></tr>
          ))}
          <tr><td><strong>Total Assets</strong></td><td><strong>{formatCents(report.totalAssetsCents)}</strong></td></tr>
        </tbody>
      </table>

      <h2>Liabilities</h2>
      <table border={1} cellPadding={8}>
        <tbody>
          {report.liabilities.map((r) => (
            <tr key={r.accountId}><td>{r.accountName}</td><td>{formatCents(r.balanceCents)}</td></tr>
          ))}
          <tr><td><strong>Total Liabilities</strong></td><td><strong>{formatCents(report.totalLiabilitiesCents)}</strong></td></tr>
        </tbody>
      </table>

      <h2>Equity</h2>
      <table border={1} cellPadding={8}>
        <tbody>
          {report.equity.map((r) => (
            <tr key={r.accountId}><td>{r.accountName}</td><td>{formatCents(r.balanceCents)}</td></tr>
          ))}
          <tr><td>Net Income (current period, unclosed)</td><td>{formatCents(report.netIncomeCents)}</td></tr>
          <tr><td><strong>Total Equity</strong></td><td><strong>{formatCents(report.totalEquityWithNetIncomeCents)}</strong></td></tr>
        </tbody>
      </table>

      <h2 style={{ color: report.isBalanced ? "green" : "red" }}>
        {report.isBalanced
          ? `Balanced: Assets (${formatCents(report.totalAssetsCents)}) = Liabilities + Equity (${formatCents(report.totalLiabilitiesCents + report.totalEquityWithNetIncomeCents)})`
          : `WARNING: Balance sheet does NOT balance - check your ledger for an unbalanced entry`}
      </h2>
    </main>
  );
}
```

### Test it, and really absorb what you're seeing

Visit /dashboard/reports/balance-sheet. Should show Checking and AR under Assets, AP under Liabilities, Owner's Equity plus Net Income under Equity, and critically the green "Balanced" message. Every invoice, bill, and payment entered across many separate features all independently posted through the one shared postJournalEntry function - and the fundamental equation of accounting holds perfectly, automatically, with zero manual reconciliation. Try an asOf date before any transactions - should show mostly zeros but still say "Balanced" (0 = 0 + 0).

Add a "Balance Sheet" nav link alongside Profit & Loss.

### Commit

```
git add .
git commit -m "Add Balance Sheet report with as-of-date snapshot and live balance verification"
```

### Checkpoint B
- [ ] getBalanceSheet correctly computes all-time (up to asOfDate) balances for Asset/Liability/Equity
- [ ] Current-period Net Income is folded into Equity, and you understand why
- [ ] isBalanced reads true against your real data
- [ ] Understand why Balance Sheet uses a single "as of" date while P&L uses a range
- [ ] Understand why isBalanced=true is a meaningful integrity check on the whole system

### Troubleshooting B

**isBalanced shows false** - Should be mathematically impossible if every entry went through postJournalEntry. Likely cause: an entry was inserted directly (bypassing postJournalEntry) and was unbalanced. Find it: `SELECT entry_id, SUM(debit_cents), SUM(credit_cents) FROM journal_lines GROUP BY entry_id HAVING SUM(debit_cents) != SUM(credit_cents);`

**Net Income here doesn't match the P&L for "the same period"** - The Balance Sheet's Net Income is unbounded-start-to-asOfDate; the P&L uses whatever range you set. They only match if the date ranges truly align (e.g., both starting Jan 1).

**"Cannot read properties of undefined (reading 'totalDebitCents')"** - Confirm the sql import is present.

**All accounts show $0 unexpectedly** - Confirm asOfDate isn't earlier than your transactions, and the lte condition is inside the leftJoin's second argument.

**TypeScript complains about balanceCents' type** - Confirm `let balanceCents: number;` (not const) is declared before the if/else.

---
```

**PART B is now complete** — append this to `05-reports.md`, right after PART A.

Now PART C — AR/AP Aging Reports, the final piece of `05-reports.md`.
```markdown
## PART C: AR/AP Aging Reports

Shows which specific invoices/bills are still unpaid, grouped by how overdue they are. Unlike the P&L and Balance Sheet (pure journal_lines rollups), this reads directly from invoices/bills tables, because it needs document-level detail (due dates, specific document identities) that the ledger alone doesn't carry. Standard buckets: Current, 1-30 days, 31-60 days, 61+ days.

### Write the AR aging query

Create src/lib/reports/ar-aging.ts:

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

CAVEAT: this treats totalCents as fully outstanding for any "sent"/"partially_paid" invoice - it does NOT net out partial payments already applied via payment_applications. A real system should compute remaining balance as totalCents minus SUM(payment_applications.amountCents). This is a good stretch exercise now that you understand both tables.

### Write the AP aging query (the mirror)

Create src/lib/reports/ap-aging.ts, mirroring the function above: query bills joined with vendors, where status is in ["open", "partially_paid"], compute days past due against dueDate, bucket the same way:

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

### Build the AR aging report page

Create src/app/dashboard/reports/ar-aging/page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { getArAging } from "@/lib/reports/ar-aging";

function formatCents(cents: number) {
  return (cents / 100).toLocaleString("en-US", { style: "currency", currency: "USD" });
}

export default async function ArAgingPage({
  searchParams,
}: {
  searchParams: Promise<{ asOf?: string }>;
}) {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const { asOf } = await searchParams;
  const asOfDate = asOf ?? new Date().toISOString().slice(0, 10);

  const { rows, totals } = await getArAging(orgId, asOfDate);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Accounts Receivable Aging</h1>
      <form style={{ marginBottom: "1rem" }}>
        <label>As of: <input type="date" name="asOf" defaultValue={asOfDate} /></label>
        <button type="submit">Update</button>
      </form>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Customer</th>
            <th>Invoice #</th>
            <th>Due Date</th>
            <th>Days Overdue</th>
            <th>Bucket</th>
            <th>Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.id}>
              <td>{r.customerName}</td>
              <td>{r.invoiceNumber}</td>
              <td>{r.dueDate}</td>
              <td>{r.daysPastDue > 0 ? r.daysPastDue : 0}</td>
              <td>{r.bucket}</td>
              <td>{formatCents(r.totalCents)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h2>Totals by Bucket</h2>
      <ul>
        <li>Current: {formatCents(totals.current)}</li>
        <li>1-30 days: {formatCents(totals.days1to30)}</li>
        <li>31-60 days: {formatCents(totals.days31to60)}</li>
        <li>61+ days: {formatCents(totals.days61plus)}</li>
      </ul>
    </main>
  );
}
```

### Build the AP aging report page

Create src/app/dashboard/reports/ap-aging/page.tsx, mirroring the AR page above using getApAging, showing vendorName instead of customerName, and billNumber instead of invoiceNumber (same structure, just swap the field names and import).

### Test both reports

Create a few test invoices/bills with due dates spread across the past and future (e.g. 45 days ago, 10 days ago, 15 days from now) to populate all four buckets. Cross-check: the AR aging total should roughly match the Balance Sheet's Accounts Receivable balance ("roughly" due to the partial-payment caveat above).

Add "AR Aging" and "AP Aging" nav links.

### Commit

```
git add .
git commit -m "Add AR and AP aging reports with due-date bucketing"
```

### Checkpoint C
- [ ] getArAging and getApAging correctly bucket open invoices/bills by days overdue
- [ ] Both report pages display with an as-of date control
- [ ] Understand why this report reads from invoices/bills directly, unlike the P&L/Balance Sheet
- [ ] Understand the partial-payment caveat and could describe the fix
- [ ] Cross-checked the AR aging total loosely against the Balance Sheet's AR balance

### Troubleshooting C

**Every invoice shows in "Current" even ones expected overdue** - Check the asOfDate; if it defaults to today and test invoices have future due dates, that's correct. Create a test invoice with a past due date.

**daysOverdue seems off** - Confirm both dueDate and asOfDate are in the same YYYY-MM-DD format, no mixed timestamp formats.

**getApAging undefined/not a function** - Confirm you actually created ap-aging.ts with the code above, not just referenced it.

**Totals don't add up as expected** - Confirm totalCents (already cents) is used consistently; only convert to dollars via formatCents at final display.

**Large mismatch vs Balance Sheet AR** - Expected if you have several partially-paid invoices - re-read the partial-payment caveat; this is a known limitation, not a bug.

**Column errors like invoices.dueDate not existing** - Use Drizzle's camelCase property names (dueDate) not snake_case database columns (due_date) in your TypeScript code.

---

This completes file 6 of 8 (Reports). Proceed to file "06 Automation and Bank Data - Inngest Jobs, Cron, CSV Import, Plaid Overview" next.
```

**`05-reports.md` is now complete** — Parts A, B, and C all appended in sequence.

