# Part 9: Core Reports

This is the payoff part. Part 4 promised that once every transaction is disciplined into balanced journal entries, every report becomes "almost boringly simple — just correct aggregation." Today we prove that promise with real code: the Profit & Loss statement, the Balance Sheet, and AR/AP Aging — three reports, built almost entirely from `SUM()` and `GROUP BY`, with no special-case logic anywhere.

## Step 9.1 — A Shared Account Balance Helper

### The Target
Write one reusable function, `getAccountBalancesAsOf`, that every report in this part will build on top of.

### The Concept
Recall Part 4, Section 4.7: every report is just aggregation over the ledger. Concretely, that means: for any account, at any point in time, its balance is simply *"total debits posted to it, minus total credits posted to it (or the reverse, depending on its normal balance), considering only journal lines dated on or before the date we care about."* Think of this like asking a librarian "as of today, how many books are on this specific shelf?" — you don't recount the whole library, you just look at everything that was ever placed on or removed from that one shelf, up to today.

We write this exactly once, as a shared building block, so the Profit & Loss, Balance Sheet, and Trial Balance-style logic all reuse identical, trusted arithmetic — rather than three slightly-different, independently-bug-prone calculations.

### The Implementation

**`src/lib/reports.ts`**
```typescript
import { db } from "@/db";
import { accounts, journalLines, journalEntries } from "@/db/schema";
import { eq, and, sql, lte, gte } from "drizzle-orm";

export type AccountBalance = {
  accountId: string;
  code: string;
  name: string;
  accountType: "asset" | "liability" | "equity" | "revenue" | "expense";
  normalBalance: "debit" | "credit";
  subtype: string;
  totalDebit: number;
  totalCredit: number;
  // The account's true balance, already flipped to the correct sign
  // based on its normal balance — e.g. for a debit-normal Asset account,
  // balance = totalDebit - totalCredit; for a credit-normal Liability,
  // balance = totalCredit - totalDebit. Every report below just reads
  // this one field and never has to think about debit/credit direction
  // again — that discipline is fully centralized here, exactly once.
  balance: number;
};

/**
 * Returns every account belonging to an organization, along with its
 * running balance as of a specific date (inclusive) — considering ONLY
 * journal lines whose parent journal entry's entryDate falls on or
 * before asOfDate. Accounts with zero activity are still included, with
 * a balance of 0, so reports can show a complete Chart of Accounts.
 */
export async function getAccountBalancesAsOf(
  organizationId: string,
  asOfDate: string
): Promise<AccountBalance[]> {
  const rows = await db
    .select({
      accountId: accounts.id,
      code: accounts.code,
      name: accounts.name,
      accountType: accounts.accountType,
      normalBalance: accounts.normalBalance,
      subtype: accounts.subtype,
      // sql<string> + coalesce(...,0): a LEFT JOIN means accounts with
      // zero journal lines would otherwise produce NULL sums, which
      // coalesce() converts to a clean "0" instead.
      totalDebit: sql<string>`coalesce(sum(case when ${journalEntries.entryDate} <= ${asOfDate} then ${journalLines.debitAmount} else 0 end), 0)`,
      totalCredit: sql<string>`coalesce(sum(case when ${journalEntries.entryDate} <= ${asOfDate} then ${journalLines.creditAmount} else 0 end), 0)`,
    })
    .from(accounts)
    .leftJoin(journalLines, eq(journalLines.accountId, accounts.id))
    .leftJoin(journalEntries, eq(journalLines.journalEntryId, journalEntries.id))
    .where(eq(accounts.organizationId, organizationId))
    .groupBy(
      accounts.id,
      accounts.code,
      accounts.name,
      accounts.accountType,
      accounts.normalBalance,
      accounts.subtype
    );

  return rows.map((row) => {
    const totalDebit = parseFloat(row.totalDebit);
    const totalCredit = parseFloat(row.totalCredit);
    const balance =
      row.normalBalance === "debit"
        ? totalDebit - totalCredit
        : totalCredit - totalDebit;

    return {
      accountId: row.accountId, code: row.code,
      name: row.name,
      accountType: row.accountType,
      normalBalance: row.normalBalance,
      subtype: row.subtype,
      totalDebit,
      totalCredit,
      balance,
    };
  });
}

/**
 * Same idea as getAccountBalancesAsOf, but scoped to a date RANGE rather
 * than "everything up to a single date." This is what the Profit & Loss
 * statement needs (Part 4, Section 4.7: P&L covers a period, not a
 * single point in time), whereas the Balance Sheet needs a single
 * as-of date. We keep these as two separate functions rather than
 * awkwardly overloading one, since "as of a date" and "during a range"
 * are genuinely different questions with different natural SQL shapes.
 */
export async function getAccountBalancesForRange(
  organizationId: string,
  startDate: string,
  endDate: string
): Promise<AccountBalance[]> {
  const rows = await db
    .select({
      accountId: accounts.id,
      code: accounts.code,
      name: accounts.name,
      accountType: accounts.accountType,
      normalBalance: accounts.normalBalance,
      subtype: accounts.subtype,
      totalDebit: sql<string>`coalesce(sum(case when ${journalEntries.entryDate} between ${startDate} and ${endDate} then ${journalLines.debitAmount} else 0 end), 0)`,
      totalCredit: sql<string>`coalesce(sum(case when ${journalEntries.entryDate} between ${startDate} and ${endDate} then ${journalLines.creditAmount} else 0 end), 0)`,
    })
    .from(accounts)
    .leftJoin(journalLines, eq(journalLines.accountId, accounts.id))
    .leftJoin(journalEntries, eq(journalLines.journalEntryId, journalEntries.id))
    .where(eq(accounts.organizationId, organizationId))
    .groupBy(
      accounts.id,
      accounts.code,
      accounts.name,
      accounts.accountType,
      accounts.normalBalance,
      accounts.subtype
    );

  return rows.map((row) => {
    const totalDebit = parseFloat(row.totalDebit);
    const totalCredit = parseFloat(row.totalCredit);
    const balance =
      row.normalBalance === "debit"
        ? totalDebit - totalCredit
        : totalCredit - totalDebit;

    return {
      accountId: row.accountId,
      code: row.code,
      name: row.name,
      accountType: row.accountType,
      normalBalance: row.normalBalance,
      subtype: row.subtype,
      totalDebit,
      totalCredit,
      balance,
    };
  });
}
```

### The Verification

Save the file. Confirm no TypeScript errors — pay close attention to the `sql<string>` template literals; a missing backtick or unmatched `${...}` interpolation is the most common typo here. We'll verify this function's actual output once the Profit & Loss report calls it in the next step, since raw numbers alone aren't very meaningful without a report to display them.

---

## Step 9.2 — Building the Profit & Loss Statement

### The Target
Create `/reports/profit-and-loss`, showing total Revenue minus total Expenses over a chosen date range.

### The Concept
Recall Part 4, Section 4.7: *"The Profit & Loss statement is nothing more than: add up every Revenue account balance, subtract every Expense account balance, over a specific date range."* We already built the exact function that computes this — `getAccountBalancesForRange` — so this report is now almost entirely presentation: filter the results down to just Revenue and Expense accounts, and lay them out.

### The Implementation

**`src/app/reports/profit-and-loss/page.tsx`**
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import { getAccountBalancesForRange } from "@/lib/reports";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

function firstDayOfCurrentMonth() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1)
    .toISOString()
    .split("T")[0];
}

function today() {
  return new Date().toISOString().split("T")[0];
}

export default async function ProfitAndLossPage({
  searchParams,
}: {
  searchParams: Promise<{ start?: string; end?: string }>;
}) {
  const { start, end } = await searchParams;
  const startDate = start ?? firstDayOfCurrentMonth();
  const endDate = end ?? today();

  const organizationId = await getOrCreateOrganization();
  const balances = await getAccountBalancesForRange(organizationId, startDate, endDate);

  const revenueAccounts = balances.filter((b) => b.accountType === "revenue");
  const expenseAccounts = balances.filter((b) => b.accountType === "expense");

  // Every core report principle from Part 4 in action: this is pure
  // addition over already-computed balances. No special cases, no
  // account-specific logic — just sum one category, sum the other,
  // subtract.
  const totalRevenue = revenueAccounts.reduce((sum, a) => sum + a.balance, 0);
  const totalExpenses = expenseAccounts.reduce((sum, a) => sum + a.balance, 0);
  const netIncome = totalRevenue - totalExpenses;

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Profit &amp; Loss</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <form className="mt-4 flex items-end gap-3 rounded-lg border border-gray-200 bg-white p-4">
          <div>
            <label className="block text-xs font-medium text-gray-600">From</label>
            <input
              type="date"
              name="start"
              defaultValue={startDate}
              className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600">To</label>
            <input
              type="date"
              name="end"
              defaultValue={endDate}
              className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm"
            />
          </div>
          <button className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white">
            Update
          </button>
        </form>

        <div className="mt-6 rounded-lg border border-gray-200 bg-white p-6">
          <p className="text-sm text-gray-500">
            For the period {startDate} to {endDate}
          </p>

          <h2 className="mt-4 font-semibold text-gray-800">Revenue</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              {revenueAccounts.map((a) => (
                <tr key={a.accountId} className="border-t border-gray-100">
                  <td className="py-1.5 text-gray-700">
                    {a.code} {a.name}
                  </td>
                  <td className="py-1.5 text-right text-gray-900">
                    ${a.balance.toFixed(2)}
                  </td>
                </tr>
              ))}
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">Total Revenue</td>
                <td className="py-1.5 text-right">${totalRevenue.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <h2 className="mt-6 font-semibold text-gray-800">Expenses</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              {expenseAccounts.map((a) => (
                <tr key={a.accountId} className="border-t border-gray-100">
                  <td className="py-1.5 text-gray-700">
                    {a.code} {a.name}
                  </td>
                  <td className="py-1.5 text-right text-gray-900">
                    ${a.balance.toFixed(2)}
                  </td>
                </tr>
              ))}
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">Total Expenses</td>
                <td className="py-1.5 text-right">${totalExpenses.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <div className="mt-6 flex justify-between border-t-2 border-gray-800 pt-3 text-lg font-bold">
            <span>Net Income</span>
            <span className={netIncome >= 0 ? "text-green-700" : "text-red-700"}>
              ${netIncome.toFixed(2)}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
```

### The Verification

Visit `http://localhost:3000/reports/profit-and-loss` while signed in with your test organization from Parts 7–8 active. The date range should default to "first day of this month" through "today," which should comfortably cover your test invoice and bill from earlier parts (assuming you created them recently — if not, adjust the "From" date back further using the form and click Update).

Expected results, based on the running example data from Parts 7–8:
- **Revenue:** `4000 Sales Revenue` — $1,200.00 (from the first invoice's subtotal) + $500.00 (second invoice's subtotal) = **$1,700.00 Total Revenue**
- **Expenses:** `5100 Rent Expense` — $2,000.00, `5300 Software & Subscriptions Expense` — $100.00 = **$2,100.00 Total Expenses**
- **Net Income:** $1,700.00 − $2,100.00 = **−$400.00**, shown in red (a net loss, which makes sense — we've barely started operating and one large rent bill dwarfs revenue so far)

Confirm the GST accounts (`1200`, `2100`) do **not** appear anywhere on this report — they're a Liability and an Asset respectively, not Revenue or Expense, so they should be correctly excluded. This is a good manual check that our `accountType` filtering is working precisely as designed.

---

## Step 9.3 — Building the Balance Sheet

### The Target
Create `/reports/balance-sheet`, showing Assets, Liabilities, and Equity as of a single date — and, critically, *proving on screen* that Assets equals Liabilities plus Equity.

### The Concept
Recall Section 4.3: the Balance Sheet equation, `Assets = Liabilities + Equity`, must *always* hold, for any business, at any moment — and per Section 4.7, this report is just a printout proving that equation using real numbers. There's one subtlety worth understanding before writing the code: **Equity, on a Balance Sheet, isn't just the raw `equity`-type accounts** — it must also include the *cumulative* Net Income earned to date (all Revenue minus all Expenses, since the beginning of time, not just this period), because Revenue and Expense accounts *feed into* Equity conceptually (Section 4.3), even though they're stored as their own separate account types.

This is why real accounting systems have a "Retained Earnings" concept — cumulative historical profit that becomes part of Equity. We handle this by computing all-time Revenue/Expense balances (using a very early "beginning of time" start date) and folding that net figure into our displayed Equity total, alongside the actual `equity`-type accounts (like "Owner's Equity," seeded in Part 5).

### The Implementation

**`src/app/reports/balance-sheet/page.tsx`**
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import {
  getAccountBalancesAsOf,
  getAccountBalancesForRange,
} from "@/lib/reports";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

function today() {
  return new Date().toISOString().split("T")[0];
}

// A date far enough in the past that no real business could have
// transactions before it — used to compute "all-time" Revenue/Expense
// totals for folding into Equity, per the concept explained above.
const BEGINNING_OF_TIME = "1970-01-01";

export default async function BalanceSheetPage({
  searchParams,
}: {
  searchParams: Promise<{ asOf?: string }>;
}) {
  const { asOf } = await searchParams;
  const asOfDate = asOf ?? today();

  const organizationId = await getOrCreateOrganization();

  const balances = await getAccountBalancesAsOf(organizationId, asOfDate);

  // All-time Revenue/Expense, used to compute cumulative Net Income —
  // this becomes part of Equity, per the concept explained in Step 9.3.
  const allTimeBalances = await getAccountBalancesForRange(
    organizationId,
    BEGINNING_OF_TIME,
    asOfDate
  );
  const allTimeRevenue = allTimeBalances
    .filter((b) => b.accountType === "revenue")
    .reduce((sum, a) => sum + a.balance, 0);
  const allTimeExpenses = allTimeBalances
    .filter((b) => b.accountType === "expense")
    .reduce((sum, a) => sum + a.balance, 0);
  const cumulativeNetIncome = allTimeRevenue - allTimeExpenses;

  const assetAccounts = balances.filter((b) => b.accountType === "asset");
  const liabilityAccounts = balances.filter((b) => b.accountType === "liability");
  const equityAccounts = balances.filter((b) => b.accountType === "equity");

  const totalAssets = assetAccounts.reduce((sum, a) => sum + a.balance, 0);
  const totalLiabilities = liabilityAccounts.reduce((sum, a) => sum + a.balance, 0);
  const rawEquity = equityAccounts.reduce((sum, a) => sum + a.balance, 0);

  // The figure actually shown as "Total Equity" — the raw equity accounts
  // PLUS cumulative net income, per the concept explained above. This is
  // the number that makes the Balance Sheet equation actually balance.
  const totalEquity = rawEquity + cumulativeNetIncome;

  const totalLiabilitiesAndEquity = totalLiabilities + totalEquity;
  const isBalanced = Math.abs(totalAssets - totalLiabilitiesAndEquity) < 0.01;

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Balance Sheet</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <form className="mt-4 flex items-end gap-3 rounded-lg border border-gray-200 bg-white p-4">
          <div>
            <label className="block text-xs font-medium text-gray-600">As of</label>
            <input
              type="date"
              name="asOf"
              defaultValue={asOfDate}
              className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm"
            />
          </div>
          <button className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white">
            Update
          </button>
        </form>

        <div className="mt-6 rounded-lg border border-gray-200 bg-white p-6">
          <p className="text-sm text-gray-500">As of {asOfDate}</p>

          <h2 className="mt-4 font-semibold text-gray-800">Assets</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              {assetAccounts.map((a) => (
                <tr key={a.accountId} className="border-t border-gray-100">
                  <td className="py-1.5 text-gray-700">{a.code} {a.name}</td>
                  <td className="py-1.5 text-right text-gray-900">
                    ${a.balance.toFixed(2)}
                  </td>
                </tr>
              ))}
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">Total Assets</td>
                <td className="py-1.5 text-right">${totalAssets.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <h2 className="mt-6 font-semibold text-gray-800">Liabilities</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              {liabilityAccounts.map((a) => (
                <tr key={a.accountId} className="border-t border-gray-100">
                  <td className="py-1.5 text-gray-700">{a.code} {a.name}</td>
                  <td className="py-1.5 text-right text-gray-900">
                    ${a.balance.toFixed(2)}
                  </td>
                </tr>
              ))}
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">Total Liabilities</td>
                <td className="py-1.5 text-right">${totalLiabilities.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <h2 className="mt-6 font-semibold text-gray-800">Equity</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              {equityAccounts.map((a) => (
                <tr key={a.accountId} className="border-t border-gray-100">
                  <td className="py-1.5 text-gray-700">{a.code} {a.name}</td>
                  <td className="py-1.5 text-right text-gray-900">
                    ${a.balance.toFixed(2)}
                  </td>
                </tr>
              ))}
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">
                  Retained Earnings (cumulative Net Income)
                </td>
                <td className="py-1.5 text-right text-gray-900">
                  ${cumulativeNetIncome.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">Total Equity</td>
                <td className="py-1.5 text-right">${totalEquity.toFixed(2)}</td>
              </tr>
            </tbody>
          </table>

          <div className="mt-6 flex justify-between border-t-2 border-gray-800 pt-3 font-bold">
            <span>Total Liabilities + Equity</span>
            <span>${totalLiabilitiesAndEquity.toFixed(2)}</span>
          </div>

          <div
            className={`mt-4 rounded p-3 text-center text-sm font-semibold ${
              isBalanced
                ? "bg-green-100 text-green-800"
                : "bg-red-100 text-red-800"
            }`}
          >
            {isBalanced
              ? "✅ Balance Sheet is balanced: Assets = Liabilities + Equity"
              : "❌ Balance Sheet is OUT OF BALANCE — this should never happen if every entry was posted through postJournalEntry"}
          </div>
        </div>
      </div>
    </div>
  );
}
```

### The Verification

Visit `http://localhost:3000/reports/balance-sheet`. Confirm the green banner reads **"✅ Balance Sheet is balanced: Assets = Liabilities + Equity."** This is the single most important visual confirmation in the entire course — it's live, real proof that every discipline enforced back in Part 6's `postJournalEntry` has paid off exactly as promised in Part 4.

Cross-check the actual numbers using your running example data:
- **Assets:** Cash (net of all invoice/bill payments so far), Accounts Receivable (remaining unpaid invoice balances), GST Input Tax Receivable ($189.00 from the bill).
- **Liabilities:** Accounts Payable (remaining unpaid bill balances, likely $0 if you fully paid your test bill), GST Output Tax Payable ($90.00 + $45.00 = $135.00 from your two invoices).
- **Equity:** Owner's Equity ($0.00, since we never recorded an owner contribution in this run-through — unlike Part 4's lemonade example, which was purely conceptual), plus Retained Earnings equal to the same Net Income figure computed on the P&L report (−$400.00, if using the same example data).

If you want an extra, satisfying test: temporarily change the "As of" date to a date *before* any of your test invoices/bills were created (e.g., a month ago). Confirm every single figure on the report drops to `$0.00`, and the banner still reads "✅ balanced" — because zero equals zero plus zero, which is itself a small but pleasing confirmation the date filtering logic works correctly at the boundary.

---

## Step 9.4 — Building AR/AP Aging

### The Target
Create `/reports/aging`, answering "who owes me money, and how overdue are they?" (Accounts Receivable Aging) and "who am I overdue in paying?" (Accounts Payable Aging).

### The Concept
Recall Section 4.7: *"AR/AP Aging is nothing more than: look at unpaid customer invoices or unpaid vendor bills, group them by how many days overdue they are, and total each group."* Unlike the P&L and Balance Sheet, this report doesn't read from `journal_lines` at all — it reads directly from `invoices`/`bills`, since what we care about here is each individual outstanding invoice/bill's *own* due date, not an aggregated account balance. This is a good moment to notice: not every report needs the exact same underlying query shape — the right tool depends on the question being asked.

We'll bucket each unpaid invoice/bill into one of: **Current** (not yet due), **1–30 days overdue**, **31–60 days overdue**, **61–90 days overdue**, or **90+ days overdue** — the standard aging buckets used in real accounting software.

### The Implementation

**`src/lib/aging.ts`**
```typescript
import { db } from "@/db";

export type AgingBucket = "current" | "1-30" | "31-60" | "61-90" | "90+";

export type AgingRow = {
  id: string;
  number: string;
  partyName: string;
  dueDate: string;
  balanceDue: number;
  daysOverdue: number;
  bucket: AgingBucket;
};

function bucketFor(daysOverdue: number): AgingBucket {
  if (daysOverdue <= 0) return "current";
  if (daysOverdue <= 30) return "1-30";
  if (daysOverdue <= 60) return "31-60";
  if (daysOverdue <= 90) return "61-90";
  return "90+";
}

function daysBetween(from: string, to: Date): number {
  const fromDate = new Date(from);
  const diffMs = to.getTime() - fromDate.getTime();
  return Math.floor(diffMs / (1000 * 60 * 60 * 24));
}

export async function getArAging(
  organizationId: string,
  asOf: Date = new Date()
): Promise<AgingRow[]> {
  const unpaidInvoices = await db.query.invoices.findMany({
    where: (invoices, { and, eq, ne }) =>
      and(
        eq(invoices.organizationId, organizationId),
        ne(invoices.status, "paid"),
        ne(invoices.status, "void")
      ),
    with: { customer: true },
  });

  return unpaidInvoices.map((invoice) => {
    const balanceDue = parseFloat(invoice.total) - parseFloat(invoice.amountPaid);
    const daysOverdue = daysBetween(invoice.dueDate, asOf);

    return {
      id: invoice.id,
      number: invoice.invoiceNumber,
      partyName: invoice.customer.name,
      dueDate: invoice.dueDate,
      balanceDue,
      daysOverdue,
      bucket: bucketFor(daysOverdue),
    };
  });
}

export async function getApAging(
  organizationId: string,
  asOf: Date = new Date()
): Promise<AgingRow[]> {
  const unpaidBills = await db.query.bills.findMany({
    where: (bills, { and, eq, ne }) =>
      and(
        eq(bills.organizationId, organizationId),
        ne(bills.status, "paid"),
        ne(bills.status, "void")
      ),
    with: { vendor: true },
  });

  return unpaidBills.map((bill) => {
    const balanceDue = parseFloat(bill.total) - parseFloat(bill.amountPaid);
    const daysOverdue = daysBetween(bill.dueDate, asOf);

    return {
      id: bill.id,
      number: bill.billNumber,
      partyName: bill.vendor.name,
      dueDate: bill.dueDate,
      balanceDue,
      daysOverdue,
      bucket: bucketFor(daysOverdue),
    };
  });
}
```

Now the page itself:

**`src/app/reports/aging/page.tsx`**
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import { getArAging, getApAging, type AgingRow } from "@/lib/aging";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

const BUCKET_LABELS: Record<string, string> = {
  current: "Current",
  "1-30": "1–30 Days",
  "31-60": "31–60 Days",
  "61-90": "61–90 Days",
  "90+": "90+ Days",
};
const BUCKET_ORDER = ["current", "1-30", "31-60", "61-90", "90+"] as const;

function summarizeByBucket(rows: AgingRow[]) {
  const totals: Record<string, number> = {
    current: 0,
    "1-30": 0,
    "31-60": 0,
    "61-90": 0,
    "90+": 0,
  };
  for (const row of rows) {
    totals[row.bucket] += row.balanceDue;
  }
  return totals;
}

function AgingTable({ title, rows }: { title: string; rows: AgingRow[] }) {
  const totals = summarizeByBucket(rows);
  const grandTotal = rows.reduce((sum, r) => sum + r.balanceDue, 0);

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-6">
      <h2 className="font-semibold text-gray-800">{title}</h2>

      <div className="mt-3 grid grid-cols-5 gap-2 text-center text-xs">
        {BUCKET_ORDER.map((bucket) => (
          <div key={bucket} className="rounded bg-gray-50 p-2">
            <div className="text-gray-500">{BUCKET_LABELS[bucket]}</div>
            <div className="mt-1 font-semibold text-gray-900">
              ${totals[bucket].toFixed(2)}
            </div>
          </div>
        ))}
      </div>

      <table className="mt-4 w-full text-left text-sm">
        <thead className="border-b border-gray-200 text-gray-500">
          <tr>
            <th className="py-2 font-medium">#</th>
            <th className="py-2 font-medium">Party</th>
            <th className="py-2 font-medium">Due Date</th>
            <th className="py-2 font-medium">Days Overdue</th>
            <th className="py-2 font-medium">Bucket</th>
            <th className="py-2 text-right font-medium">Balance Due</th>
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 && (
            <tr>
              <td colSpan={6} className="py-6 text-center text-gray-400">
                Nothing outstanding.
              </td>
            </tr>
          )}
          {rows.map((row) => (
            <tr key={row.id} className="border-b border-gray-100">
              <td className="py-1.5">{row.number}</td>
              <td className="py-1.5">{row.partyName}</td>
              <td className="py-1.5 text-gray-500">{row.dueDate}</td>
              <td className="py-1.5 text-gray-500">
                {row.daysOverdue > 0 ? `${row.daysOverdue} days` : "Not yet due"}
              </td>
              <td className="py-1.5">{BUCKET_LABELS[row.bucket]}</td>
              <td className="py-1.5 text-right">${row.balanceDue.toFixed(2)}</td>
            </tr>
          ))}
          <tr className="border-t-2 border-gray-800 font-semibold">
            <td colSpan={5} className="py-2">
              Total Outstanding
            </td>
            <td className="py-2 text-right">${grandTotal.toFixed(2)}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}

export default async function AgingPage() {
  const organizationId = await getOrCreateOrganization();

  const arRows = await getArAging(organizationId);
  const apRows = await getApAging(organizationId);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">AR / AP Aging</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-6 space-y-6">
          <AgingTable title="Accounts Receivable — Who owes me money?" rows={arRows} />
          <AgingTable title="Accounts Payable — Who am I overdue in paying?" rows={apRows} />
        </div>
      </div>
    </div>
  );
}
```

Add `/reports` to `src/proxy.ts`'s protected routes list if not already present (it was included back in Part 2's original list, so this should already be covered — just double check).

### The Verification

Visit `http://localhost:3000/reports/aging`. Based on the running example: if you fully paid off your first test invoice ($1,290.00) in Part 8, it should **not** appear here (status is "paid," filtered out). If your second test invoice ($545.00) is still unpaid, it should appear in the Accounts Receivable table, bucketed as "Current" (since its due date is 30 days out from creation, and we're testing shortly after creating it).

If you fully paid your test bill in Part 8, the Accounts Payable table should show "Nothing outstanding."

**Test the bucketing logic directly:** Create one more test invoice via `/invoices/new`, but this time manually edit its due date field in the browser to a date roughly 45 days in the past (e.g., today's date minus 45 days) before submitting. After creating it, revisit `/reports/aging` and confirm this new invoice appears in the **"31–60 Days"** bucket, with `daysOverdue` showing approximately `45 days`, and confirm the "31-60" bucket total at the top of the table now reflects this invoice's balance.

---

## Step 9.5 — Adding Navigation Between Reports

### The Target
Add a small reports navigation menu, since we now have three separate report pages that should be easy to move between.

### The Implementation

**`src/components/reports-nav.tsx`**
```tsx
import Link from "next/link";

export function ReportsNav() {
  return (
    <div className="mb-4 flex gap-4 rounded-lg border border-gray-200 bg-white p-3 text-sm">
      <Link href="/reports/profit-and-loss" className="text-blue-600 hover:underline">
        Profit &amp; Loss
      </Link>
      <Link href="/reports/balance-sheet" className="text-blue-600 hover:underline">
        Balance Sheet
      </Link>
      <Link href="/reports/aging" className="text-blue-600 hover:underline">
        AR / AP Aging
      </Link>
    </div>
  );
}
```

Add `<ReportsNav />` just below the header `<div>` in all three report pages (`profit-and-loss/page.tsx`, `balance-sheet/page.tsx`, `aging/page.tsx`) — e.g., in `profit-and-loss/page.tsx`:

```tsx
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Profit &amp; Loss</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-4">
          <ReportsNav />
        </div>
```

(Apply the same `<div className="mt-4"><ReportsNav /></div>` insertion, and the corresponding `import { ReportsNav } from "@/components/reports-nav";` import line, to the other two report pages.)

### The Verification

Visit any of the three report pages and confirm the navigation bar appears with all three links, each correctly routing to its respective report.

---

## Step 9.6 — Eighth Git Commit

### The Target
Save the completed reporting suite as a new checkpoint.

### The Implementation

```bash
git add .
git commit -m "Add Profit and Loss, Balance Sheet, and AR/AP Aging reports built on shared account balance aggregation"
```

### The Verification

```bash
git log --oneline
```

Expected output, eight lines, newest first.

---

## ✅ Checkpoint — Part 9

At this point, you should have:

- [x] `getAccountBalancesAsOf` and `getAccountBalancesForRange` — shared, trusted aggregation functions every report builds on
- [x] A working Profit & Loss statement with an adjustable date range
- [x] A working Balance Sheet with an adjustable "as of" date, correctly folding cumulative Net Income into Equity, and a live on-screen proof that Assets = Liabilities + Equity
- [x] A working AR/AP Aging report, bucketing unpaid invoices/bills by days overdue
- [x] Navigation linking all three reports together
- [x] A ninth — wait, eighth — Git commit checkpoint

---

## 📚 Reference Section: Aggregation Design, Retained Earnings, and Query Choices

*(A standalone reference — read now or return later.)*

**Why does the Balance Sheet need "all-time" Revenue/Expense totals, while the P&L only looks at the selected date range?**
These two reports are answering fundamentally different questions. The P&L answers "how did the business perform *during this specific window*?" — so it should only reflect activity within that window. The Balance Sheet answers "what does the business look like *right now, as of this instant*?" — and a business's accumulated wealth (Equity) reflects *every* profitable or unprofitable period it has ever had, not just the current one. This is precisely why real accounting systems maintain a "Retained Earnings" concept: it's the running scoreboard of all historical P&L results, folded permanently into Equity.

**Why is the "beginning of time" trick (`1970-01-01`) an acceptable approach here, rather than something more sophisticated?**
Because our reports are pure aggregation over immutable, already-posted journal lines (Part 6's guarantee), asking "sum everything from the dawn of time to today" is computationally cheap and produces an exactly correct answer — there's no meaningful difference between filtering `entryDate >= '1970-01-01'` and not filtering by a start date at all, since no real organization will ever have transactions before that date. A more "sophisticated" approach isn't actually more correct here; it would just be unnecessary complexity. This is a good general lesson: the simplest approach that produces a provably correct result is usually the right one, especially in financial software where every added layer of cleverness is another place a bug could hide.

**Why does AR/AP Aging query `invoices`/`bills` directly instead of going through `getAccountBalancesAsOf` like the other two reports?**
Because the question being asked is fundamentally different in shape. The P&L and Balance Sheet care about *account-level totals* — "what's the total balance of Accounts Receivable, as one lump sum?" AR/AP Aging cares about *individual outstanding invoices/bills* — "which specific invoices are overdue, and by how much, each one separately?" The Accounts Receivable *account balance* on the Balance Sheet and the *sum of all rows* in the AR Aging report should mathematically agree (both represent total money owed by customers) — but computing "the total" and computing "the breakdown per invoice, bucketed by age" genuinely require different underlying queries. This is worth sitting with: not every report can or should be forced into one universal query shape, even within a single well-designed system.

**Could I verify that the AR Aging report's grand total matches the Balance Sheet's Accounts Receivable balance, as an extra sanity check?**
Yes — and this is a genuinely excellent habit to build as you extend this app in Part 14 and beyond. Since both numbers are derived from the same underlying truth (unpaid invoice balances), if they ever disagree, it's a strong signal that a bug was introduced somewhere — likely in how `amountPaid` or `status` gets updated during payment recording (Part 8), since that's the one place where invoice-level and journal-level truth could theoretically drift apart if a future code change broke `recordInvoicePayment`'s atomicity.

**Why filter out `void` status invoices/bills in the aging queries, given we haven't actually built a "void" feature yet?**
This is intentionally forward-looking, connecting directly to Part 14's roadmap, which names "editing/voiding entries" as the top recommended next step precisely because it builds on this existing engine without needing any new third-party service. By already excluding `void`-status records from Aging (and by having reserved `void` as a real enum value back in Parts 7 and 8), we've left a clean, ready-made hook for that future feature to plug into, without needing to revisit this report's logic at all when that day comes.

---

## 🔧 Troubleshooting — Part 9

**"The Balance Sheet shows a red '❌ OUT OF BALANCE' banner."**
This should be structurally impossible if every transaction in your database was created through `postJournalEntry` — which, if you followed Parts 6–8 exactly, is true for every single row. The most likely cause is a manual edit made directly in Drizzle Studio during testing (e.g., manually editing a `journal_lines` amount by hand) — Drizzle Studio lets you bypass `postJournalEntry`'s guards entirely, since it talks directly to the database. If you've done any manual edits during testing, that's almost certainly the cause; otherwise, carefully re-check `getAccountBalancesAsOf`'s SQL for a typo in the `case when` logic.

**"The Profit & Loss report shows $0.00 for everything, even though I have real invoices and bills."**
Check the selected date range against your actual test data's dates — if your invoices/bills were created with an `issueDate` outside the "From"/"To" range shown in the form, they'll correctly be excluded. Widen the date range using the form.

**"TypeScript complains about the `sql<string>` template literals in `reports.ts`."**
Confirm `sql` is imported from `"drizzle-orm"` at the top of the file, and that every `${...}` interpolation references an actual imported column (e.g., `journalEntries.entryDate`, not a typo'd variable name).

**"AR/AP Aging shows an invoice as 'Not yet due' when I expected it to show a specific overdue bucket, or vice versa."**
Double check the exact due date stored on that invoice/bill in Drizzle Studio — remember `daysBetween` compares the due date against "now" (server time), so an invoice due exactly today will show `0` days overdue, correctly bucketed as "current" (since `bucketFor` treats `daysOverdue <= 0` as current) — a due date of yesterday is the first day that should tip into the "1-30" bucket.

**"The Retained Earnings line on the Balance Sheet doesn't match the Net Income figure on the P&L report for the same period."**
This is expected and correct if your P&L's date range is narrower than "all time" — remember, the Balance Sheet's Retained Earnings deliberately uses an all-time range (Step 9.3's `BEGINNING_OF_TIME` constant), while the P&L uses whatever range is selected in its own date form. They will only match exactly if you set the P&L's "From" date back to a date before any of your test data was ever created.
