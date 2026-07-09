## Part 16: Building the Profit & Loss Report

Goal of this part: build the first real report — a Profit & Loss statement (also called an Income Statement) — computed entirely from `journal_lines` over a date range. This is where the discipline of always posting through `postJournalEntry` (Parts 10, 13, 14, 15) pays off visibly: the report requires almost no special-case logic, just correct aggregation.

Prerequisite: Parts 1-15 completed.

---

### 1. What a Profit & Loss report actually shows

A P&L answers one question: "Over this period of time (e.g. this month, this quarter, this year), did the business make or lose money, and on what?" It lists all Income accounts with their totals for the period, all Expense accounts with their totals for the period, and a final Net Profit (or Loss) = Total Income - Total Expenses.

Notice the phrase "over this period of time" — a P&L is always for a date RANGE (unlike the Balance Sheet in Part 17, which is a snapshot at a single point in time). This distinction matters and trips up a lot of people building their first accounting reports.

### 2. Recall the math from Part 8 and Part 15

Income accounts are credit-normal (increase with credit). Expense accounts are debit-normal (increase with debit). So:
- An income account's balance for a period = SUM(credits) - SUM(debits) within that date range
- An expense account's balance for a period = SUM(debits) - SUM(credits) within that date range

This is the exact same pattern as the manual SQL query you ran at the end of Part 15, just applied to Income/Expense accounts instead of a bank account, and constrained to a date range instead of all-time.

### 3. Write the report query

Create `src/lib/reports/profit-and-loss.ts`:

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
    .leftJoin(journalEntries, eq(journalEntries.id, journalLines.entryId))
    .where(
      and(
        eq(accounts.orgId, orgId),
        inArray(accounts.type, ["income", "expense"]),
        // only count lines whose entry falls in our date range
        // (entries with no matching line still show up thanks to the leftJoin, with 0 totals)
      )
    )
    .groupBy(accounts.id, accounts.name, accounts.type);

  // Note: filtering the date range inside a LEFT JOIN's ON clause (not WHERE) avoids
  // accidentally excluding accounts with zero activity in this period - see step 4 for the fix.

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

### 4. Fixing the date range filter properly

The comment in step 3 flags a real, common bug: if you filter by date using a normal WHERE clause on a LEFT JOIN, accounts with zero matching journal lines in that range can accidentally get excluded entirely, when what we actually want is to show them with a $0 balance. The correct fix is to move the date condition into the JOIN's ON clause instead of WHERE. Update the query:

```ts
.leftJoin(
  journalLines,
  eq(journalLines.accountId, accounts.id)
)
.leftJoin(
  journalEntries,
  and(
    eq(journalEntries.id, journalLines.entryId),
    gte(journalEntries.date, startDate),
    lte(journalEntries.date, endDate)
  )
)
```

Now an account with no activity in the given range still appears in the results (with `totalDebitCents`/`totalCreditCents` both 0, thanks to COALESCE), rather than disappearing from the report — which matters because a real P&L should show all income/expense accounts an org has used at some point, with $0 for ones with no activity this period, not silently omit them.

This kind of subtlety — LEFT JOIN filtering conditions belonging in ON versus WHERE — is a genuinely common source of report bugs in any system, not just accounting ones. Good to have hit it here, in a safe learning context, rather than in a real report later.

### 5. Build the report page

Create `src/app/dashboard/reports/profit-and-loss/page.tsx`. It should accept `startDate` and `endDate` as URL search params (so the date range is bookmarkable/shareable), default to the current month if none provided, call `getProfitAndLoss`, and render a simple report layout:

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

Notice `searchParams` is how a Server Component reads the current URL's query string (e.g. `?start=2025-01-01&end=2025-01-31`) — a plain HTML form with GET (the default) naturally produces URLs like this without any JavaScript, which is why the date-picker form above needs no `action`/Server Action at all, just default browser behavior.

### 6. Test it

Visit `/dashboard/reports/profit-and-loss`. You should see your Sales/Service Income accounts (from invoices you sent in Part 13) and your Expense accounts (from bills in Part 14), with correct totals, and a net profit/loss figure. Try changing the date range to something before you created any transactions — you should see all accounts listed with $0 balances, confirming the LEFT JOIN fix from step 4 is working (rather than an empty report).

Cross-check one number by hand: pick one Income account, and manually verify its total against your invoices — e.g. if you sent two invoices whose income both hit "Service Income" for $500 and $300, the P&L should show Service Income at $800 for a range covering both.

### 7. Add a report link to the dashboard

Add a "Reports" or "Profit & Loss" link to `src/app/dashboard/page.tsx` alongside your other nav links.

### 8. Commit your progress

```
git add .
git commit -m "Add Profit and Loss report computed from journal_lines with date range filtering"
```

---

### Checkpoint — confirm before moving on

- [ ] `getProfitAndLoss` correctly sums income (credits - debits) and expenses (debits - credits) per account
- [ ] The date range filter is in the JOIN's ON clause, not a WHERE clause, so zero-activity accounts still show with $0 rather than disappearing
- [ ] The report page reads start/end from URL search params and defaults sensibly to the current month
- [ ] You manually cross-checked at least one account's total against real invoices/bills you created
- [ ] You understand why a P&L is for a date range, unlike the Balance Sheet coming up next

---

### Troubleshooting

**Report page shows a blank Income and Expenses section, even though you have invoices/bills**
Almost always means the date range filter is still in a WHERE clause instead of the JOIN's ON clause (step 4). Double check your `leftJoin` for `journalEntries` has the date conditions (`gte`/`lte`) inside its second argument (the `and(...)` block), not in a separate `.where(...)` call.

**Error: "Cannot read properties of undefined (reading 'totalDebitCents')" or similar**
This usually means the `sql` template import is missing or misspelled. Confirm you have `import { and, eq, gte, lte, inArray } from "drizzle-orm";` AND a separate `import { sql } from "drizzle-orm";` line (or combined into one import statement) at the top of `profit-and-loss.ts`.

**Numbers look right but are off by exactly a factor of 100**
This means you forgot to divide by 100 somewhere when displaying (dollars vs cents confusion). Check that `formatCents` divides by 100 before calling `toLocaleString`, and that you're not accidentally double-converting anywhere.

**The date picker form reloads the page but the numbers never change**
Confirm your form does NOT have an `action` or `onSubmit` handler pointing at a Server Action — it should be a plain form relying on default GET behavior, which naturally updates the URL's query string (`?start=...&end=...`) and triggers Next.js to re-render the page with new `searchParams`.

**TypeScript error: "Property 'start' does not exist on type..."**
Confirm the page's function signature exactly matches: `searchParams: Promise<{ start?: string; end?: string }>` and that you `await searchParams` before destructuring — both the Promise wrapper and the await are required in Next.js 16.

**Total Income and Total Expenses show correct numbers, but Net Profit/Loss is wrong**
Check the sign: `netProfitCents` should be `totalIncomeCents` minus `totalExpenseCents` (not the reverse), and the JSX ternary checking `report.netProfitCents >= 0 ? "Profit" : "Loss"` should use `Math.abs()` when displaying so a loss doesn't show as a confusing negative currency value.

**Report shows accounts with $0 balance that you don't expect to see, like unused expense categories from Part 9's seed**
This is expected and correct behavior after the ON-clause fix — all income/expense accounts an org has ever had (even with zero activity) will show, deliberately, so nothing is silently hidden. If you'd rather hide zero-balance rows, that's a reasonable customization: add a `.filter(r => r.balanceCents !== 0)` before rendering, but note real accounting software typically still shows all accounts for auditability.

---

✅ **Part 16 is now complete in full**, including its Troubleshooting Addendum content merged in above.

### What's next
Part 17: Building the Balance Sheet — the second core report, but a snapshot AS OF a single date rather than a range, showing Assets, Liabilities, and Equity — and proving the fundamental accounting equation (Assets = Liabilities + Equity) always holds, live, from your own data.
