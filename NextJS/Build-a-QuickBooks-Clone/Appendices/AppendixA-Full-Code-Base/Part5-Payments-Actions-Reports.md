## Appendix A Part 5: Payments Actions

### src/app/dashboard/payments/actions.ts (both functions, full file)

```ts
"use server";

import { db } from "@/lib/db";
import { payments, paymentApplications, invoices, billPayments, billPaymentApplications, bills } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { findAccountBySubtype } from "@/lib/accounting/find-account";
import { eq } from "drizzle-orm";

export async function recordCustomerPayment(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const invoiceId = formData.get("invoiceId") as string;
  const paymentDate = formData.get("paymentDate") as string;
  const amount = Number(formData.get("amount"));
  const method = formData.get("method") as string | null;

  if (!invoiceId || !paymentDate || !(amount > 0)) {
    throw new Error("Missing or invalid payment fields");
  }
  const amountCents = Math.round(amount * 100);

  const [invoice] = await db.select().from(invoices).where(eq(invoices.id, invoiceId)).limit(1);
  if (!invoice || invoice.orgId !== orgId) {
    throw new Error("Invalid invoice");
  }
  if (amountCents > invoice.totalCents) {
    throw new Error("Payment cannot exceed the invoice total");
  }

  const checkingAccount = await findAccountBySubtype(orgId, "bank");
  const arAccount = await findAccountBySubtype(orgId, "accounts_receivable");

  await db.transaction(async (tx) => {
    const [payment] = await tx
      .insert(payments)
      .values({ orgId, customerId: invoice.customerId, paymentDate, amountCents, method })
      .returning();

    await tx.insert(paymentApplications).values({
      paymentId: payment.id,
      invoiceId: invoice.id,
      amountCents,
    });

    const newStatus = amountCents === invoice.totalCents ? "paid" : "partially_paid";
    await tx.update(invoices).set({ status: newStatus }).where(eq(invoices.id, invoice.id));

    await postJournalEntry(
      {
        orgId,
        date: new Date(paymentDate),
        memo: `Payment received for Invoice ${invoice.invoiceNumber}`,
        sourceType: "payment_received",
        sourceId: payment.id,
        lines: [
          { accountId: checkingAccount.id, debitCents: amountCents },
          { accountId: arAccount.id, creditCents: amountCents },
        ],
      },
      tx
    );
  });

  revalidatePath("/dashboard/invoices");
  redirect(`/dashboard/invoices/${invoiceId}`);
}

export async function recordBillPayment(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const billId = formData.get("billId") as string;
  const paymentDate = formData.get("paymentDate") as string;
  const amount = Number(formData.get("amount"));
  const method = formData.get("method") as string | null;

  if (!billId || !paymentDate || !(amount > 0)) {
    throw new Error("Missing or invalid payment fields");
  }
  const amountCents = Math.round(amount * 100);

  const [bill] = await db.select().from(bills).where(eq(bills.id, billId)).limit(1);
  if (!bill || bill.orgId !== orgId) {
    throw new Error("Invalid bill");
  }
  if (amountCents > bill.totalCents) {
    throw new Error("Payment cannot exceed the bill total");
  }

  const checkingAccount = await findAccountBySubtype(orgId, "bank");
  const apAccount = await findAccountBySubtype(orgId, "accounts_payable");

  await db.transaction(async (tx) => {
    const [billPayment] = await tx
      .insert(billPayments)
      .values({ orgId, vendorId: bill.vendorId, paymentDate, amountCents, method })
      .returning();

    await tx.insert(billPaymentApplications).values({
      billPaymentId: billPayment.id,
      billId: bill.id,
      amountCents,
    });

    const newStatus = amountCents === bill.totalCents ? "paid" : "partially_paid";
    await tx.update(bills).set({ status: newStatus }).where(eq(bills.id, bill.id));

    await postJournalEntry(
      {
        orgId,
        date: new Date(paymentDate),
        memo: `Payment made for Bill ${bill.billNumber}`,
        sourceType: "payment_made",
        sourceId: billPayment.id,
        lines: [
          { accountId: apAccount.id, debitCents: amountCents },
          { accountId: checkingAccount.id, creditCents: amountCents },
        ],
      },
      tx
    );
  });

  revalidatePath("/dashboard/bills");
  redirect(`/dashboard/bills/${billId}`);
}
```

---
## Appendix A Part 5b: Profit and Loss + Balance Sheet Pages

### src/app/dashboard/reports/profit-and-loss/page.tsx

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

### src/app/dashboard/reports/balance-sheet/page.tsx

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

---
## Appendix A Part 5c: AR Aging and AP Aging Pages

### src/app/dashboard/reports/ar-aging/page.tsx

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

### src/app/dashboard/reports/ap-aging/page.tsx

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { getApAging } from "@/lib/reports/ap-aging";

function formatCents(cents: number) {
  return (cents / 100).toLocaleString("en-US", { style: "currency", currency: "USD" });
}

export default async function ApAgingPage({
  searchParams,
}: {
  searchParams: Promise<{ asOf?: string }>;
}) {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const { asOf } = await searchParams;
  const asOfDate = asOf ?? new Date().toISOString().slice(0, 10);

  const { rows, totals } = await getApAging(orgId, asOfDate);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Accounts Payable Aging</h1>
      <form style={{ marginBottom: "1rem" }}>
        <label>As of: <input type="date" name="asOf" defaultValue={asOfDate} /></label>
        <button type="submit">Update</button>
      </form>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Vendor</th>
            <th>Bill #</th>
            <th>Due Date</th>
            <th>Days Overdue</th>
            <th>Bucket</th>
            <th>Amount</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.id}>
              <td>{r.vendorName}</td>
              <td>{r.billNumber}</td>
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

This completes Appendix A Part 5 (Payments actions and all four report pages).

---

Next up is **Appendix A Part 6 (Bank Import and API Routes)** — the final part of this appendix, covering `bank-import/actions.ts`, `bank-import/page.tsx`, and both API routes (Inngest + Clerk webhook). 
