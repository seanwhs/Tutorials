## Part 17: Building the Balance Sheet 

**Goal:** build the second core report — the Balance Sheet — a snapshot AS OF a single date (not a range like Part 16's P&L), showing Assets, Liabilities, and Equity, and proving live, from your own data, that the fundamental accounting equation always holds: Assets = Liabilities + Equity.

**Prerequisite:** Parts 1-16 completed.

---

### 1. Balance Sheet vs Profit & Loss — the key difference

Part 16's P&L answered "how did the business perform over this period?" The Balance Sheet answers a completely different question: "as of this exact moment, what does the business own, and what does it owe?" This is why a Balance Sheet has no start date — only an "as of" date. Every journal entry ever posted up to and including that date counts, no matter how long ago.

This distinction is the single most common point of confusion for people new to accounting reports, so pause on it: P&L = a movie (a period of activity), Balance Sheet = a photograph (a single instant).

### 2. The math, and the equation we're about to prove

Recall Part 8's normal balance table:
- Asset balance = SUM(debits) - SUM(credits), all-time up to the as-of date
- Liability balance = SUM(credits) - SUM(debits), all-time up to the as-of date
- Equity balance = SUM(credits) - SUM(debits), all-time up to the as-of date

And recall from Part 8: net profit (income minus expenses) that hasn't been formally "closed out" effectively belongs to Equity too (it's the owner's undistributed earnings). For our purposes, we'll fold current-period net income directly into the Equity section of the report as a computed line, rather than requiring a formal period-end "closing entry" process (which real accounting systems do, but which is a more advanced topic we're deliberately deferring).

The equation we're proving: Total Assets = Total Liabilities + Total Equity (including that folded-in net income). If this doesn't hold, it means something in the system posted an unbalanced entry — which Part 10's postJournalEntry should make impossible, so this report doubles as a live integrity check on your whole ledger.

### 3. Write the report query

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

Notice we reused Part 16's ON-clause date filtering fix immediately here (`lte(journalEntries.date, asOfDate)` inside the join condition) — since we want ALL accounts to appear, even ones with zero activity as of this date, not just ones with a nonzero balance. Also notice `isBalanced` — a genuinely useful sanity check field we can display prominently, and which should always be true if everything upstream (Part 10's postJournalEntry) has been doing its job.

---

### 4. Build the report page

Create src/app/dashboard/reports/balance-sheet/page.tsx, very similar in shape to Part 16's P&L page, but with a single date field (not a range) called asOf, defaulting to today:

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

### 5. Test it, and really absorb what you're seeing

Visit /dashboard/reports/balance-sheet. You should see your Checking Account and Accounts Receivable balances under Assets, Accounts Payable under Liabilities, your Owner's Equity plus the current Net Income figure under Equity — and critically, the green "Balanced" message at the bottom.

This is worth sitting with for a moment: every invoice, bill, and payment you've entered across many separate features, built across many separate parts of this course, all independently posted their own journal entries through the one shared postJournalEntry function — and yet the fundamental equation of accounting holds perfectly, automatically, with zero manual reconciliation. That is genuinely the entire point of double-entry bookkeeping, and you just built a system that enforces it correctly.

Try changing the asOf date to before you created any transactions — the report should show mostly zeros, but should still say "Balanced" (0 = 0 + 0).

### 6. Add a report link

Add "Balance Sheet" to your Reports navigation alongside Profit & Loss.

### 7. Commit your progress

```
git add .
git commit -m "Add Balance Sheet report with as-of-date snapshot and live balance verification"
```

---

### Checkpoint

- [ ] getBalanceSheet correctly computes all-time (up to asOfDate) balances for Asset, Liability, and Equity accounts
- [ ] Current period Net Income is folded into the Equity total, and you understand why (unclosed earnings belong to equity)
- [ ] The report displays isBalanced, and it reads true against your real data
- [ ] You understand, in your own words, why a Balance Sheet uses a single "as of" date while a P&L uses a range
- [ ] You can explain why isBalanced being true is actually a meaningful integrity check on the whole system, not just a report detail

---

### Troubleshooting

**isBalanced shows false, and you're not sure why**
This means Assets does not equal Liabilities + Equity, which should be mathematically impossible if every entry went through postJournalEntry (Part 10). The most likely cause: a journal entry was inserted directly into the database (via Neon's SQL Editor, or a leftover test script) bypassing postJournalEntry entirely, and it was unbalanced. Query `SELECT entry_id, SUM(debit_cents), SUM(credit_cents) FROM journal_lines GROUP BY entry_id HAVING SUM(debit_cents) != SUM(credit_cents);` in Neon's SQL Editor to find the culprit entry.

**Net Income shown on the Balance Sheet doesn't match the Profit & Loss report for what seems like the same period**
Check the date ranges carefully: the Balance Sheet's Net Income is calculated for ALL history up to the asOf date (unbounded start), while the P&L uses whatever start/end range you set on that page. If your P&L's start date isn't January 1st (or your fiscal year start) and your Balance Sheet is meant to represent the same "current period," these two numbers are answering different questions and won't match unless the date ranges truly align.

**Error: "Cannot read properties of undefined (reading 'totalDebitCents')"**
Same cause as Part 16's version of this error — confirm the `sql` import from drizzle-orm is present at the top of balance-sheet.ts.

**All accounts show $0, even ones you know have activity**
Confirm the asOfDate you're testing with is not earlier than when you actually created those transactions. Also confirm the `lte(journalEntries.date, asOfDate)` condition is inside the leftJoin's second argument, not accidentally placed in the outer `.where(...)` clause.

**TypeScript complains about the withBalance.map() callback's return type**
Confirm the `let balanceCents: number;` declaration exists before the if/else block, and that both branches of the if/else assign to it — a common typo is declaring it with `const` instead of `let`, which prevents reassignment.

**The green/red balanced message never appears, page seems to render normally otherwise**
Confirm you're checking `report.isBalanced` (a boolean) with a ternary in the JSX exactly as shown, and check your browser's console for React errors.

---

### What's next

Part 18: AR/AP Aging Reports — the last of our three core reports, showing which specific invoices/bills are still unpaid, grouped by how overdue they are (current, 1-30 days, 31-60 days, 60+ days).

