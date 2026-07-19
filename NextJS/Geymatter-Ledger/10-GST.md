# Part 10: GST and the GST F5 Return

Throughout Parts 7–9, we've been quietly collecting GST on invoices (a Liability, GST Output Tax Payable) and paying GST on bills (an Asset, GST Input Tax Receivable), without ever asking the obvious business question: *how much does Greymatter Ledger actually owe IRAS, or get refunded by IRAS, this quarter?* That's exactly what this part answers, by building a report modeled on Singapore's real **GST F5** quarterly filing form.

## Step 10.1 — Understanding the GST F5 Return, In Plain English

### The Target
Before writing code, understand exactly what a GST F5 return represents and why it's structured the way it is.

### The Concept
Every quarter, a GST-registered business in Singapore must tell IRAS: *"here's how much GST I collected from my customers, here's how much GST I paid to my vendors, and here's the net difference — which I either owe you, or you owe me."* Think of it like a toll booth operator who collects tolls all day on behalf of the highway authority, but also occasionally has to pay for their own booth's electricity and supplies — at the end of the day, they don't hand over *every* dollar collected; they net it against their own legitimate costs and settle up the difference.

Concretely, the two numbers we already have sitting in our ledger are:
- **Output Tax** — the balance of `2100 GST Output Tax Payable`, which is GST collected from customers (credited every time we posted an invoice in Part 7).
- **Input Tax** — the balance of `1200 GST Input Tax Receivable`, which is GST paid to vendors (debited every time we posted a bill in Part 8).

The amount owed to IRAS (or refundable, if negative) is simply:

```
GST Payable to IRAS = Output Tax − Input Tax
```

If Output Tax exceeds Input Tax, the business owes IRAS the difference. If Input Tax exceeds Output Tax (e.g., a quarter with heavy equipment purchases but few sales), the business is owed a refund. This is, once again, exactly the pattern from Part 4, Section 4.7: **a report that requires no special-case logic, just correct aggregation** — we already built the exact aggregation function (`getAccountBalancesForRange`) needed to compute both figures.

A real GST F5 form also reports total value of standard-rated supplies, zero-rated supplies, and taxable purchases (not just the tax amounts themselves) — so we'll include those too, computed from our invoice/bill *subtotals*, grouped by GST rate.

## Step 10.2 — A Helper to Classify Supplies by GST Rate

### The Target
Write a function that looks at all invoices and bills within a period and splits their subtotals into standard-rated (9%) vs. zero-rated (0%) categories — the exact breakdown a GST F5 form requires.

### The Concept
Recall from Part 7 that GST rate is set *per invoice line*, not per invoice — a single invoice can mix standard-rated and zero-rated items. So to correctly classify "how much of my total sales this quarter was standard-rated vs. zero-rated," we can't just look at invoice headers — we need to inspect every individual `invoice_line` and `bill_line`, grouping by `gstRate`.

### The Implementation

**`src/lib/gst.ts`**
```typescript
import { db } from "@/db";
import { invoiceLines, invoices, billLines, bills } from "@/db/schema";
import { and, eq, gte, lte, sql } from "drizzle-orm";
import { getAccountBalancesForRange } from "@/lib/reports";

export type GstF5Summary = {
  periodStart: string;
  periodEnd: string;

  // Box 1: total value of standard-rated supplies (sales taxed at 9%)
  standardRatedSupplies: number;
  // Box 2: total value of zero-rated supplies (sales taxed at 0%, e.g. exports)
  zeroRatedSupplies: number;
  // Box 3: total value of exempt supplies — not modeled in this simplified
  // course version, always 0, but included so the shape matches a real F5.
  exemptSupplies: number;
  // Box 4: total value of all supplies (sum of the above three)
  totalSupplies: number;

  // Box 5: total value of taxable purchases (from bills)
  totalTaxablePurchases: number;

  // Box 6: output tax due (GST collected from customers)
  outputTaxDue: number;
  // Box 7: input tax and refunds claimed (GST paid to vendors)
  inputTaxClaimed: number;

  // Box 8 (net): what's actually owed to IRAS (positive) or refundable
  // by IRAS (negative) — the entire point of this report.
  netGstPayable: number;
};

/**
 * Builds a GST F5-style summary for a given period, by combining two
 * kinds of aggregation: (1) invoice/bill LINE-level grouping by GST rate,
 * to classify supply/purchase values, and (2) ACCOUNT-level balances for
 * the two GST control accounts, to compute output/input tax and the net
 * amount payable — reusing Part 9's getAccountBalancesForRange directly,
 * since that arithmetic is already trusted and tested.
 */
export async function getGstF5Summary(
  organizationId: string,
  periodStart: string,
  periodEnd: string
): Promise<GstF5Summary> {
  // --- Classify sales (invoice lines) by GST rate, within the period,
  // using each invoice's issueDate to determine period membership.
  const salesByRate = await db
    .select({
      gstRate: invoiceLines.gstRate,
      total: sql<string>`coalesce(sum(${invoiceLines.lineTotal}), 0)`,
    })
    .from(invoiceLines)
    .innerJoin(invoices, eq(invoiceLines.invoiceId, invoices.id))
    .where(
      and(
        eq(invoices.organizationId, organizationId),
        gte(invoices.issueDate, periodStart),
        lte(invoices.issueDate, periodEnd)
      )
    )
    .groupBy(invoiceLines.gstRate);

  let standardRatedSupplies = 0;
  let zeroRatedSupplies = 0;

  for (const row of salesByRate) {
    const amount = parseFloat(row.total);
    const rate = parseFloat(row.gstRate);
    if (rate > 0) {
      standardRatedSupplies += amount;
    } else {
      zeroRatedSupplies += amount;
    }
  }

  const exemptSupplies = 0; // not modeled in this course's simplified scope
  const totalSupplies = standardRatedSupplies + zeroRatedSupplies + exemptSupplies;

  // --- Classify purchases (bill lines) — for a GST F5, we report the
  // total value of taxable purchases regardless of rate, so we sum
  // everything without needing to split by rate the way sales are split.
  const purchasesResult = await db
    .select({
      total: sql<string>`coalesce(sum(${billLines.lineTotal}), 0)`,
    })
    .from(billLines)
    .innerJoin(bills, eq(billLines.billId, bills.id))
    .where(
      and(
        eq(bills.organizationId, organizationId),
        gte(bills.issueDate, periodStart),
        lte(bills.issueDate, periodEnd)
      )
    );

  const totalTaxablePurchases = parseFloat(purchasesResult[0]?.total ?? "0");

  // --- Output/Input tax, reusing Part 9's trusted account-balance
  // aggregation directly — this is the exact "no special-case logic,
  // just correct aggregation" principle from Part 4, Section 4.7, in
  // action once again, on a brand-new report.
  const balances = await getAccountBalancesForRange(
    organizationId,
    periodStart,
    periodEnd
  );

  const gstOutputAccount = balances.find((b) => b.code === "2100");
  const gstInputAccount = balances.find((b) => b.code === "1200");

  // .balance on a Liability account is already (credit - debit), i.e.
  // the NET amount collected during this period (Part 9's convention).
  const outputTaxDue = gstOutputAccount?.balance ?? 0;
  // .balance on an Asset account is already (debit - credit), i.e. the
  // NET amount paid out during this period.
  const inputTaxClaimed = gstInputAccount?.balance ?? 0;

  const netGstPayable = outputTaxDue - inputTaxClaimed;

  return {
    periodStart,
    periodEnd,
    standardRatedSupplies,
    zeroRatedSupplies,
    exemptSupplies,
    totalSupplies,
    totalTaxablePurchases,
    outputTaxDue,
    inputTaxClaimed,
    netGstPayable,
  };
}
```

### The Verification

Save the file. Confirm no TypeScript errors. We'll validate the real numbers once the report page exists.

---

## Step 10.3 — Building the GST F5 Report Page

### The Target
Create `/reports/gst-f5`, a quarter-selectable page laid out to resemble IRAS's real GST F5 form structure.

### The Concept
Real GST F5 filings are quarterly — three-month periods aligned to a business's registered accounting period. We'll let the user pick a start date and automatically compute the end date as three months later, matching how Singapore businesses actually think about this filing.

### The Implementation

**`src/app/reports/gst-f5/page.tsx`**
```tsx
import { getOrCreateOrganization } from "@/lib/organizations";
import { getGstF5Summary } from "@/lib/gst";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";
import { ReportsNav } from "@/components/reports-nav";

function firstDayOfCurrentQuarter() {
  const now = new Date();
  const quarterStartMonth = Math.floor(now.getMonth() / 3) * 3;
  return new Date(now.getFullYear(), quarterStartMonth, 1)
    .toISOString()
    .split("T")[0];
}

function addThreeMonthsMinusOneDay(startDateStr: string) {
  const start = new Date(startDateStr);
  const end = new Date(start.getFullYear(), start.getMonth() + 3, 0);
  return end.toISOString().split("T")[0];
}

export default async function GstF5Page({
  searchParams,
}: {
  searchParams: Promise<{ start?: string }>;
}) {
  const { start } = await searchParams;
  const periodStart = start ?? firstDayOfCurrentQuarter();
  const periodEnd = addThreeMonthsMinusOneDay(periodStart);

  const organizationId = await getOrCreateOrganization();
  const summary = await getGstF5Summary(organizationId, periodStart, periodEnd);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">GST F5 Return</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-4">
          <ReportsNav />
        </div>

        <form className="mt-4 flex items-end gap-3 rounded-lg border border-gray-200 bg-white p-4">
          <div>
            <label className="block text-xs font-medium text-gray-600">
              Quarter Start Date
            </label>
            <input
              type="date"
              name="start"
              defaultValue={periodStart}
              className="mt-1 rounded border border-gray-300 px-2 py-1 text-sm"
            />
          </div>
          <button className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white">
            Update
          </button>
        </form>

        <div className="mt-6 rounded-lg border border-gray-200 bg-white p-6">
          <p className="text-sm text-gray-500">
            Accounting Period: {summary.periodStart} to {summary.periodEnd}
          </p>

          <h2 className="mt-4 font-semibold text-gray-800">
            Supplies (Sales)
          </h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">
                  Box 1: Standard-rated supplies
                </td>
                <td className="py-1.5 text-right text-gray-900">
                  ${summary.standardRatedSupplies.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">
                  Box 2: Zero-rated supplies
                </td>
                <td className="py-1.5 text-right text-gray-900">
                  ${summary.zeroRatedSupplies.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">
                  Box 3: Exempt supplies
                </td>
                <td className="py-1.5 text-right text-gray-900">
                  ${summary.exemptSupplies.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-300 font-semibold">
                <td className="py-1.5">
                  Box 4: Total supplies (1 + 2 + 3)
                </td>
                <td className="py-1.5 text-right">
                  ${summary.totalSupplies.toFixed(2)}
                </td>
              </tr>
            </tbody>
          </table>

          <h2 className="mt-6 font-semibold text-gray-800">Purchases</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              <tr className="border-t border-gray-100 font-semibold">
                <td className="py-1.5">
                  Box 5: Total value of taxable purchases
                </td>
                <td className="py-1.5 text-right">
                  ${summary.totalTaxablePurchases.toFixed(2)}
                </td>
              </tr>
            </tbody>
          </table>

          <h2 className="mt-6 font-semibold text-gray-800">GST Amounts</h2>
          <table className="mt-2 w-full text-left text-sm">
            <tbody>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">
                  Box 6: Output tax due
                </td>
                <td className="py-1.5 text-right text-gray-900">
                  ${summary.outputTaxDue.toFixed(2)}
                </td>
              </tr>
              <tr className="border-t border-gray-100">
                <td className="py-1.5 text-gray-700">
                  Box 7: Input tax and refunds claimed
                </td>
                <td className="py-1.5 text-right text-gray-900">
                  ${summary.inputTaxClaimed.toFixed(2)}
                </td>
              </tr>
            </tbody>
          </table>

          <div className="mt-6 flex justify-between border-t-2 border-gray-800 pt-3 text-lg font-bold">
            <span>
              {summary.netGstPayable >= 0
                ? "Box 8: Net GST Payable to IRAS"
                : "Box 8: Net GST Refundable by IRAS"}
            </span>
            <span
              className={
                summary.netGstPayable >= 0 ? "text-red-700" : "text-green-700"
              }
            >
              ${Math.abs(summary.netGstPayable).toFixed(2)}
            </span>
          </div>

          <p className="mt-4 text-xs text-gray-400">
            This summary is a simplified educational model of IRAS&apos;s
            GST F5 return and is not a substitute for professional tax
            advice or the official filing form.
          </p>
        </div>
      </div>
    </div>
  );
}
```

Update `src/components/reports-nav.tsx` to include a link to this new report:

**`src/components/reports-nav.tsx`** (updated)
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
      <Link href="/reports/gst-f5" className="text-blue-600 hover:underline">
        GST F5
      </Link>
    </div>
  );
}
```

### The Verification

Visit `http://localhost:3000/reports/gst-f5`. Confirm the page loads showing the current quarter's date range in the "Accounting Period" line, and the quarter start date form field pre-filled correctly.

Cross-check against your running example data from Parts 7–8 (assuming your test invoices/bills were created within the current quarter — if not, adjust the "Quarter Start Date" field back to cover them, e.g. set it to the first day of the month you actually created your test data in):

- **Box 1 (Standard-rated supplies):** should equal the sum of every invoice line's `lineTotal` where `gstRate = 9` — e.g., $1,000.00 (first invoice's standard line) + $500.00 (second invoice) = **$1,500.00**
- **Box 2 (Zero-rated supplies):** should equal the sum of every invoice line's `lineTotal` where `gstRate = 0` — e.g., $200.00 (the "Exported goods resale" line from Part 7) = **$200.00**
- **Box 4 (Total supplies):** $1,500.00 + $200.00 + $0.00 = **$1,700.00** — and this should exactly match the "Total Revenue" figure from your Profit & Loss report in Part 9, for the same date range. **This cross-check is important — perform it now.**
- **Box 5 (Total taxable purchases):** should equal the sum of every bill line's `lineTotal` — e.g., $2,000.00 + $100.00 = **$2,100.00** — and this should exactly match the "Total Expenses" figure on the P&L report for the same range.
- **Box 6 (Output tax due):** $90.00 + $45.00 = **$135.00**
- **Box 7 (Input tax claimed):** **$189.00**
- **Box 8:** $135.00 − $189.00 = **−$54.00**, meaning the business is actually **refundable $54.00** by IRAS this quarter (shown in green, since Input Tax exceeded Output Tax) — displayed as "Box 8: Net GST Refundable by IRAS: $54.00".

If any of these don't match, use the cross-check against the P&L report (Box 4 vs. Total Revenue, Box 5 vs. Total Expenses) to isolate whether the issue is in the line-level GST classification query or the account-balance query.

---

## Step 10.4 — Ninth Git Commit

### The Target
Save the completed GST F5 report as a new checkpoint.

### The Implementation

```bash
git add .
git commit -m "Add GST F5-style quarterly return summary report"
```

### The Verification

```bash
git log --oneline
```

Expected output, nine lines, newest first.

---

## ✅ Checkpoint — Part 10

At this point, you should have:

- [x] `getGstF5Summary` — combining line-level GST rate classification (for supply/purchase values) with Part 9's trusted account-balance aggregation (for output/input tax and net payable)
- [x] A working `/reports/gst-f5` page, quarter-selectable, laid out to resemble IRAS's real GST F5 boxes
- [x] Verified cross-checks confirming Box 4 matches the P&L's Total Revenue and Box 5 matches Total Expenses, for the same period
- [x] Confirmed correct sign handling — a positive net figure means GST owed to IRAS; a negative figure means a refund is due
- [x] The GST F5 report linked into the shared reports navigation
- [x] A ninth Git commit checkpoint

---

## 📚 Reference Section: GST Mechanics and Real-World Filing Notes

*(A standalone reference — read now or return later. This section includes important disclaimers about the educational scope of this feature.)*

**Why does a positive `netGstPayable` mean money is owed, while negative means a refund — walk through the sign logic once more.**
`outputTaxDue` is a Liability account's balance — recall from Part 9 that a Liability's `.balance` is computed as `(credit - debit)`, i.e., a positive number represents genuine accumulated obligation. `inputTaxClaimed` is an Asset account's balance — `(debit - credit)`, where a positive number represents a genuine, currently-unclaimed refund entitlement. Subtracting the refund entitlement from the obligation (`outputTaxDue - inputTaxClaimed`) gives the *net* obligation: if what's owed exceeds what's reclaimable, the result is positive (owe IRAS); if reclaimable exceeds owed, the result is negative (IRAS owes the business).

**Why did we compute supply/purchase classification from `issueDate`, while output/input tax used `entryDate` (via `getAccountBalancesForRange`)?**
In our data model, an invoice/bill's `issueDate` and its resulting journal entry's `entryDate` are always set to the exact same value (see `createInvoice`/`createBill` in Parts 7–8, where `entryDate: input.issueDate` is passed directly to `postJournalEntry`). So in practice, for this course's implementation, these two dates always agree — there's no actual discrepancy, just two different tables both correctly reflecting the same underlying date. This is worth noting explicitly, because if Part 14's roadmap extensions ever introduced a scenario where an invoice's issue date and its journal posting date could diverge (e.g., backdated entries), this report's two halves would need to be reconciled to use a single, consistent date field.

**Is this GST F5 report suitable for actually filing with IRAS?**
No — and this is an important, deliberate limitation to state plainly. Real GST filing involves considerably more nuance than this course covers: reverse charge mechanisms, imports under specific schemes, bad debt relief, capital goods adjustments, bad debt recovery, bespoke exemption rules, and so on — all of which are genuinely complex, frequently updated by IRAS, and require professional accounting/tax advice to handle correctly for any real business. This feature exists in Greymatter Ledger purely to teach the *conceptual mechanism* of how a GST return relates to your Chart of Accounts and ledger — exactly the kind of literacy Part 4 set out to build — not to replace an actual tax filing process. Any real business should use this report as a helpful internal estimate only, and consult a qualified accountant for actual filings.

**Why does Box 5 not split taxable purchases by rate the way Box 1/Box 2 split supplies by rate?**
This matches the real IRAS GST F5 form's actual structure — the official form asks for one combined "total taxable purchases" figure (Box 5), without a further breakdown by rate the way supplies are split across Boxes 1–3. This is a good example of a report's shape being dictated by an external, real-world requirement (the actual government form) rather than by internal code convenience — sometimes the "right" structure for a report isn't the most symmetrical one, it's the one that matches what the reader (in this case, IRAS) actually expects to see.

**What would need to change to support multiple GST rates beyond just 9% and 0% (e.g., a future rate change, or additional categories like exempt supplies)?**
The `salesByRate` query in `getGstF5Summary` already groups by the *actual* `gstRate` value stored per line, rather than hardcoding a check for exactly `9` — the current code simplifies this down to a binary "any positive rate counts as standard-rated" classification, which is accurate for Singapore's current single-standard-rate GST system. If IRAS ever introduced a second non-zero rate, or if this course's scope expanded to model exempt supplies (Box 3, currently hardcoded to `0`) as a real, trackable category, the natural extension would be adding a dedicated `isExempt` flag to relevant invoice lines and adjusting this classification loop accordingly — a good exercise to revisit once Part 14's roadmap is reached.

---

## 🔧 Troubleshooting — Part 10

**"Box 4 doesn't match my Profit & Loss report's Total Revenue for the same period."**
The most common cause is a date range mismatch — confirm you're comparing the *exact* same start and end dates on both reports. Remember the GST F5 page auto-calculates its end date as "three months after the start date," which may not exactly align with whatever custom range you manually typed into the P&L report's form. Set both reports to cover the same explicit range to get a true apples-to-apples comparison.

**"Box 5 doesn't match Total Expenses on the P&L report."**
This discrepancy can legitimately occur if any of your test bills included a line item posted to a *non-Expense* account (e.g., if you ever selected "1500 Office Equipment," an Asset, as a bill line's expense account during testing) — Box 5 sums *all* bill line totals regardless of which account they posted to, while the P&L's Total Expenses only sums `expense`-type accounts. This isn't a bug — it's a real, meaningful accounting distinction (a purchase of equipment is a taxable purchase for GST purposes, but it's not an "expense" on the P&L; it's a capitalized Asset) — but it's worth understanding rather than assuming something is broken.

**"The report shows `$0.00` everywhere despite having real invoices and bills."**
Double-check the selected quarter's date range against your test data's actual `issueDate` values — if your test invoices/bills were created outside the currently displayed quarter, adjust the "Quarter Start Date" field accordingly and click Update.

**"TypeScript complains that `gstRate` on `salesByRate` rows is a string, not a number, when I try to compare it with `> 0`."**
This is expected — Drizzle returns `numeric` columns as strings by default (the same reasoning discussed in Part 6's reference section regarding precision). Confirm the code uses `parseFloat(row.gstRate)` before comparing, exactly as shown in Step 10.2 — comparing the raw string directly against a number will produce incorrect results.

**"The sign of Box 8 seems backwards — a refund is showing as red/owed, or vice versa."**
Re-check the `netGstPayable >= 0` conditional in the page component — a value of exactly `$0.00` should display as "Net GST Payable to IRAS: $0.00" (a fully neutral quarter), which is why the comparison uses `>= 0` (payable) rather than `> 0`, ensuring an exact break-even quarter doesn't incorrectly claim a refund is owed.
