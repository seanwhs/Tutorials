## Part 18: AR/AP Aging Reports

Goal of this part: build the third core report — AR (Accounts Receivable) and AP (Accounts Payable) Aging — showing exactly which invoices/bills are still unpaid, grouped by how overdue they are. This report answers a very practical, everyday question real business owners ask constantly: "who owes me money, and who am I overdue in paying?"

Prerequisite: Parts 1-17 completed.

---

### 1. What an aging report actually shows, and why it's different from Parts 16/17

The P&L (Part 16) and Balance Sheet (Part 17) are both built purely from `journal_lines` — pure ledger data, account balances. An aging report is different: it's built from the invoices/bills tables themselves (their status and due dates), not from journal_lines directly, because we need to know about SPECIFIC unpaid documents, not just an aggregate account balance. AR as an aggregate number tells you "customers owe you $12,000 total" — the aging report tells you "Jane owes $2,000, due 15 days ago; Tom owes $10,000, due in 5 days" — the operational detail behind the summary number.

This is a good moment to notice: not every report in a real accounting system is a pure `journal_lines` rollup. The rule from Part 8 ("reports should read from journal_lines") applies specifically to the FINANCIAL reports (P&L, Balance Sheet) where correctness of dollar totals is paramount. Operational reports like aging need document-level detail that the ledger alone doesn't carry (a journal entry knows AR went up by $500, but doesn't inherently know due dates or which specific invoice).

### 2. Aging buckets

Standard aging buckets, universally used in accounting:
- Current (not yet due)
- 1-30 days overdue
- 31-60 days overdue
- 61-90 days overdue
- 90+ days overdue

For simplicity we'll use four buckets: Current, 1-30, 31-60, 61+.

### 3. Write the AR aging query

Create `src/lib/reports/ar-aging.ts`:

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

Important caveat to notice, and to be honest about: this treats an invoice's `totalCents` as fully outstanding if its status is "sent" or "partially_paid" — it does NOT subtract out any partial payments already applied (recall Part 15's `payment_applications` table tracks exactly how much has been paid). For a course-accurate simplified version this is acceptable, but a real system should compute remaining balance as `totalCents` minus `SUM(payment_applications.amountCents` for this invoice). This is an excellent, very achievable stretch exercise now that you understand both tables involved — try adding a subquery or a second query that sums applications per invoice and subtracts it before bucketing.

### 4. Write the AP aging query (the mirror)

Create `src/lib/reports/ap-aging.ts`, mirroring the function above closely: query bills joined with vendors, where status is in `["open", "partially_paid"]`, compute days past due against each bill's `dueDate`, and bucket the same way. Same caveat about not netting out partial `bill_payment_applications` applies, and is an equally good exercise for later.

### 5. Build the AR aging report page

Create `src/app/dashboard/reports/ar-aging/page.tsx`:

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

### 6. Build the AP aging report page

Create `src/app/dashboard/reports/ap-aging/page.tsx`, mirroring the AR page above using `getApAging`, showing vendor name instead of customer name, and bill number instead of invoice number.

### 7. Test both reports

Since your test invoices/bills from earlier parts likely have due dates already in the past or near today, you should immediately see some rows land in a "1-30" or similar bucket. If you want to see all four buckets populated realistically, go back to `/dashboard/invoices/new` and `/dashboard/bills/new` and create a few more test invoices/bills with due dates deliberately spread across different points in the past and future (e.g. one due date 45 days ago, one due 10 days ago, one due in 15 days), so you can watch them land in different buckets.

Cross-check: the sum of the AR aging report's total across all buckets should roughly match your Accounts Receivable balance on the Balance Sheet (Part 17) — "roughly" because of the partial-payment caveat from step 3. This kind of cross-report sanity-checking is exactly what real bookkeepers do to catch bugs, and it's a great habit to build now.

### 8. Add report links

Add "AR Aging" and "AP Aging" links to your Reports navigation.

### 9. Commit your progress

```
git add .
git commit -m "Add AR and AP aging reports with due-date bucketing"
```

---

### Checkpoint — confirm before moving on

- [ ] `getArAging` and `getApAging` both correctly bucket open invoices/bills by days overdue
- [ ] Both report pages display correctly with an as-of date control
- [ ] You understand why this report reads from invoices/bills directly rather than purely from `journal_lines`, unlike Parts 16-17
- [ ] You understand the partial-payment caveat (`totalCents` not netted against `payment_applications`) and could describe how you'd fix it
- [ ] You cross-checked the AR aging total loosely against the Balance Sheet's Accounts Receivable balance

---

### Troubleshooting

**Every invoice shows up in the "Current" bucket, even ones you expect to be overdue**
Check the `asOfDate` you're testing against — if it defaults to today and your test invoices have due dates in the future, that's actually correct behavior. Go back to `/dashboard/invoices/new` and create a test invoice with a due date deliberately set in the past (e.g. 20 days ago) to see the aging logic actually bucket something as overdue.

**daysOverdue calculation seems off by one day, or by a lot**
Confirm both `dueDate` and `asOfDate` strings are in the same format (`YYYY-MM-DD`) — mixing a full ISO timestamp string with a plain date string can shift the calculation due to timezone differences. The `.toISOString().slice(0, 10)` pattern used throughout this course keeps things consistent; if you introduced a different date format anywhere in this function, that's the likely culprit.

**getApAging is undefined or "not a function" when imported**
Confirm you actually created `src/lib/reports/ap-aging.ts` (Part 18 step 4 describes mirroring `ar-aging.ts`, but does not show every line — you need to write out the full function yourself, following the same structure as `getArAging` but querying bills/vendors and using bill-specific field names like `billNumber` and `dueDate`). If you skipped writing this file expecting it to already exist, that's the issue.

**Totals by bucket don't add up to what you'd expect by eyeballing the table rows**
Confirm the `totals[r.bucket as keyof typeof totals] += r.totalCents;` line is using `totalCents` (already in cents) consistently, and that you're not accidentally adding a dollar-formatted string to it elsewhere — always keep raw cent integers in your calculations, and only convert to dollars at the very last step when displaying via `formatCents`.

**Cross-checking against the Balance Sheet's Accounts Receivable shows a meaningfully large mismatch, not just a small rounding difference**
Re-read the partial-payment caveat in step 3 — if you have several partially-paid invoices, the aging report currently counts their FULL original total as outstanding rather than the true remaining balance, which can create a larger-than-expected gap versus the Balance Sheet's real AR balance (which correctly reflects actual payments applied via journal entries). This is the known, flagged limitation — not a bug in your code.

**Page shows an error about invoices.dueDate or similar column not existing**
Confirm you're referencing the exact camelCase property names Drizzle exposes in your code (`dueDate`, `invoiceNumber`, `totalCents`) rather than the snake_case database column names (`due_date`, `invoice_number`, `total_cents`) — this mixing-up is a common typo when moving between looking at Neon's SQL Editor (snake_case) and writing TypeScript (camelCase).

---

✅ **Part 18 is now complete in full**, including the Troubleshooting Addendum merged in above.

### What's next
With all three core reports built, we've completed the entire "MVP" accounting core described in our original project plan. Part 19: Your First Background Job — we finally bring Inngest into the project, starting with something simple and satisfying: sending an invoice email in the background instead of making the user wait for it.
