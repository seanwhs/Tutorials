[System: Empty message content sanitised to satisfy protocol]
# Appendix A Part 4: Invoices, Final State

## src/app/dashboard/invoices/actions.ts (FINAL state — includes ledger posting + Inngest event)

```ts
"use server";

import { db } from "@/lib/db";
import { invoices, invoiceLines } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { findAccountBySubtype } from "@/lib/accounting/find-account";
import { inngest } from "@/lib/inngest/client";

export async function createInvoice(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const customerId = formData.get("customerId") as string;
  const invoiceNumber = formData.get("invoiceNumber") as string;
  const issueDate = formData.get("issueDate") as string;
  const dueDate = formData.get("dueDate") as string;

  if (!customerId || !invoiceNumber || !issueDate || !dueDate) {
    throw new Error("Missing required invoice fields");
  }

  const lines: { description: string; quantity: number; unitPriceCents: number; amountCents: number }[] = [];
  let i = 0;
  while (formData.has(`description_${i}`)) {
    const description = formData.get(`description_${i}`) as string;
    const quantity = Number(formData.get(`quantity_${i}`));
    const unitPrice = Number(formData.get(`unitPrice_${i}`));
    if (description && quantity > 0 && unitPrice >= 0) {
      const unitPriceCents = Math.round(unitPrice * 100);
      const amountCents = quantity * unitPriceCents;
      lines.push({ description, quantity, unitPriceCents, amountCents });
    }
    i++;
  }

  if (lines.length === 0) {
    throw new Error("An invoice needs at least one line item");
  }

  const totalCents = lines.reduce((sum, l) => sum + l.amountCents, 0);

  const arAccount = await findAccountBySubtype(orgId, "accounts_receivable");
  const incomeAccount = await findAccountBySubtype(orgId, "income");

  let createdInvoiceId: string = "";

  await db.transaction(async (tx) => {
    const [invoice] = await tx
      .insert(invoices)
      .values({
        orgId,
        customerId,
        invoiceNumber,
        issueDate,
        dueDate,
        totalCents,
        status: "sent",
      })
      .returning();

    createdInvoiceId = invoice.id;

    await tx.insert(invoiceLines).values(
      lines.map((l) => ({
        invoiceId: invoice.id,
        description: l.description,
        quantity: l.quantity,
        unitPriceCents: l.unitPriceCents,
        amountCents: l.amountCents,
      }))
    );

    await postJournalEntry(
      {
        orgId,
        date: new Date(issueDate),
        memo: `Invoice ${invoiceNumber}`,
        sourceType: "invoice",
        sourceId: invoice.id,
        lines: [
          { accountId: arAccount.id, debitCents: totalCents },
          { accountId: incomeAccount.id, creditCents: totalCents },
        ],
      },
      tx
    );
  });

  // Send the background email event only after the transaction has committed successfully
  await inngest.send({
    name: "invoice/created",
    data: { invoiceId: createdInvoiceId, orgId },
  });

  revalidatePath("/dashboard/invoices");
  redirect("/dashboard/invoices");
}
```

## src/app/dashboard/invoices/new/page.tsx

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { createInvoice } from "../actions";

export default async function NewInvoicePage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allCustomers = await db
    .select()
    .from(customers)
    .where(eq(customers.orgId, orgId))
    .orderBy(customers.name);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>New Invoice</h1>
      <form action={createInvoice}>
        <div>
          <label>Customer: </label>
          <select name="customerId" required>
            <option value="">Select a customer</option>
            {allCustomers.map((c) => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </select>
        </div>
        <div>
          <label>Invoice Number: </label>
          <input name="invoiceNumber" placeholder="INV-1001" required />
        </div>
        <div>
          <label>Issue Date: </label>
          <input type="date" name="issueDate" required />
        </div>
        <div>
          <label>Due Date: </label>
          <input type="date" name="dueDate" required />
        </div>

        <h3>Line Items</h3>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{ display: "flex", gap: "0.5rem", marginBottom: "0.5rem" }}>
            <input name={`description_${i}`} placeholder="Description" />
            <input name={`quantity_${i}`} type="number" placeholder="Qty" defaultValue={1} />
            <input name={`unitPrice_${i}`} type="number" step="0.01" placeholder="Unit Price" />
          </div>
        ))}

        <button type="submit">Create Invoice</button>
      </form>
    </main>
  );
}
```

## src/app/dashboard/invoices/page.tsx

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { invoices, customers } from "@/lib/db/schema";
import { eq, desc } from "drizzle-orm";
import Link from "next/link";

export default async function InvoicesPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allInvoices = await db
    .select({
      id: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      issueDate: invoices.issueDate,
      dueDate: invoices.dueDate,
      totalCents: invoices.totalCents,
      status: invoices.status,
      customerName: customers.name,
    })
    .from(invoices)
    .innerJoin(customers, eq(customers.id, invoices.customerId))
    .where(eq(invoices.orgId, orgId))
    .orderBy(desc(invoices.issueDate));

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Invoices</h1>
      <p><Link href="/dashboard/invoices/new">+ New Invoice</Link></p>
      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Invoice #</th>
            <th>Customer</th>
            <th>Issue Date</th>
            <th>Due Date</th>
            <th>Total</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {allInvoices.map((inv) => (
            <tr key={inv.id}>
              <td><Link href={`/dashboard/invoices/${inv.id}`}>{inv.invoiceNumber}</Link></td>
              <td>{inv.customerName}</td>
              <td>{inv.issueDate}</td>
              <td>{inv.dueDate}</td>
              <td>{(inv.totalCents / 100).toFixed(2)}</td>
              <td>{inv.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

---

[System: Empty message content sanitised to satisfy protocol]
# Appendix A Part 4b: Invoice Detail with Payment Form, Final State

## src/app/dashboard/invoices/[id]/page.tsx (FINAL state — includes the payment form added in Part 15)

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect, notFound } from "next/navigation";
import { db } from "@/lib/db";
import { invoices, invoiceLines, customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { recordCustomerPayment } from "@/app/dashboard/payments/actions";

export default async function InvoiceDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const { id } = await params;

  const [invoice] = await db
    .select({
      id: invoices.id,
      invoiceNumber: invoices.invoiceNumber,
      issueDate: invoices.issueDate,
      dueDate: invoices.dueDate,
      totalCents: invoices.totalCents,
      status: invoices.status,
      orgId: invoices.orgId,
      customerName: customers.name,
    })
    .from(invoices)
    .innerJoin(customers, eq(customers.id, invoices.customerId))
    .where(eq(invoices.id, id))
    .limit(1);

  if (!invoice || invoice.orgId !== orgId) {
    notFound();
  }

  const lines = await db
    .select()
    .from(invoiceLines)
    .where(eq(invoiceLines.invoiceId, id));

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Invoice {invoice.invoiceNumber}</h1>
      <p>Customer: {invoice.customerName}</p>
      <p>Issue Date: {invoice.issueDate}</p>
      <p>Due Date: {invoice.dueDate}</p>
      <p>Status: {invoice.status}</p>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Description</th>
            <th>Qty</th>
            <th>Unit Price</th>
            <th>Amount</th>
          </tr>
        </thead>
        <tbody>
          {lines.map((l) => (
            <tr key={l.id}>
              <td>{l.description}</td>
              <td>{l.quantity}</td>
              <td>{(l.unitPriceCents / 100).toFixed(2)}</td>
              <td>{(l.amountCents / 100).toFixed(2)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h3>Total: {(invoice.totalCents / 100).toFixed(2)}</h3>

      {invoice.status !== "paid" && (
        <div style={{ marginTop: "2rem", borderTop: "1px solid #ccc", paddingTop: "1rem" }}>
          <h3>Record a Payment</h3>
          <form action={recordCustomerPayment}>
            <input type="hidden" name="invoiceId" value={invoice.id} />
            <div>
              <label>Payment Date: </label>
              <input type="date" name="paymentDate" required />
            </div>
            <div>
              <label>Amount: </label>
              <input type="number" name="amount" step="0.01" required />
            </div>
            <div>
              <label>Method: </label>
              <input name="method" placeholder="check, cash, card..." />
            </div>
            <button type="submit">Record Payment</button>
          </form>
        </div>
      )}
    </main>
  );
}
```

---

This completes the Invoices folder in its final, accumulated state.

# Appendix A Part 4c: Bills, Final State

## src/app/dashboard/bills/actions.ts (final state)

```ts
"use server";

import { db } from "@/lib/db";
import { bills, billLines, accounts } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { findAccountBySubtype } from "@/lib/accounting/find-account";
import { eq } from "drizzle-orm";

export async function createBill(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const vendorId = formData.get("vendorId") as string;
  const billNumber = formData.get("billNumber") as string;
  const billDate = formData.get("billDate") as string;
  const dueDate = formData.get("dueDate") as string;
  const expenseAccountId = formData.get("expenseAccountId") as string;

  if (!vendorId || !billNumber || !billDate || !dueDate || !expenseAccountId) {
    throw new Error("Missing required bill fields");
  }

  const lines: { description: string; quantity: number; unitPriceCents: number; amountCents: number }[] = [];
  let i = 0;
  while (formData.has(`description_${i}`)) {
    const description = formData.get(`description_${i}`) as string;
    const quantity = Number(formData.get(`quantity_${i}`));
    const unitPrice = Number(formData.get(`unitPrice_${i}`));
    if (description && quantity > 0 && unitPrice >= 0) {
      const unitPriceCents = Math.round(unitPrice * 100);
      const amountCents = quantity * unitPriceCents;
      lines.push({ description, quantity, unitPriceCents, amountCents });
    }
    i++;
  }

  if (lines.length === 0) {
    throw new Error("A bill needs at least one line item");
  }

  const totalCents = lines.reduce((sum, l) => sum + l.amountCents, 0);

  const apAccount = await findAccountBySubtype(orgId, "accounts_payable");

  const [expenseAccount] = await db
    .select()
    .from(accounts)
    .where(eq(accounts.id, expenseAccountId))
    .limit(1);
  if (!expenseAccount || expenseAccount.orgId !== orgId || expenseAccount.type !== "expense") {
    throw new Error("Invalid expense account selected");
  }

  await db.transaction(async (tx) => {
    const [bill] = await tx
      .insert(bills)
      .values({
        orgId,
        vendorId,
        billNumber,
        billDate,
        dueDate,
        totalCents,
        status: "open",
      })
      .returning();

    await tx.insert(billLines).values(
      lines.map((l) => ({
        billId: bill.id,
        description: l.description,
        quantity: l.quantity,
        unitPriceCents: l.unitPriceCents,
        amountCents: l.amountCents,
      }))
    );

    await postJournalEntry(
      {
        orgId,
        date: new Date(billDate),
        memo: `Bill ${billNumber}`,
        sourceType: "bill",
        sourceId: bill.id,
        lines: [
          { accountId: expenseAccount.id, debitCents: totalCents },
          { accountId: apAccount.id, creditCents: totalCents },
        ],
      },
      tx
    );
  });

  revalidatePath("/dashboard/bills");
  redirect("/dashboard/bills");
}
```

## src/app/dashboard/bills/new/page.tsx

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { vendors, accounts } from "@/lib/db/schema";
import { eq, and } from "drizzle-orm";
import { createBill } from "../actions";

export default async function NewBillPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allVendors = await db
    .select()
    .from(vendors)
    .where(eq(vendors.orgId, orgId))
    .orderBy(vendors.name);

  const expenseAccounts = await db
    .select()
    .from(accounts)
    .where(and(eq(accounts.orgId, orgId), eq(accounts.type, "expense")))
    .orderBy(accounts.code);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>New Bill</h1>
      <form action={createBill}>
        <div>
          <label>Vendor: </label>
          <select name="vendorId" required>
            <option value="">Select a vendor</option>
            {allVendors.map((v) => (
              <option key={v.id} value={v.id}>{v.name}</option>
            ))}
          </select>
        </div>
        <div>
          <label>Bill Number: </label>
          <input name="billNumber" placeholder="BILL-1001" required />
        </div>
        <div>
          <label>Bill Date: </label>
          <input type="date" name="billDate" required />
        </div>
        <div>
          <label>Due Date: </label>
          <input type="date" name="dueDate" required />
        </div>
        <div>
          <label>Expense Account: </label>
          <select name="expenseAccountId" required>
            <option value="">Select an expense account</option>
            {expenseAccounts.map((a) => (
              <option key={a.id} value={a.id}>{a.name}</option>
            ))}
          </select>
        </div>

        <h3>Line Items</h3>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{ display: "flex", gap: "0.5rem", marginBottom: "0.5rem" }}>
            <input name={`description_${i}`} placeholder="Description" />
            <input name={`quantity_${i}`} type="number" placeholder="Qty" defaultValue={1} />
            <input name={`unitPrice_${i}`} type="number" step="0.01" placeholder="Unit Price" />
          </div>
        ))}

        <button type="submit">Create Bill</button>
      </form>
    </main>
  );
}
```

## src/app/dashboard/bills/page.tsx

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { bills, vendors } from "@/lib/db/schema";
import { eq, desc } from "drizzle-orm";
import Link from "next/link";

export default async function BillsPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allBills = await db
    .select({
      id: bills.id,
      billNumber: bills.billNumber,
      billDate: bills.billDate,
      dueDate: bills.dueDate,
      totalCents: bills.totalCents,
      status: bills.status,
      vendorName: vendors.name,
    })
    .from(bills)
    .innerJoin(vendors, eq(vendors.id, bills.vendorId))
    .where(eq(bills.orgId, orgId))
    .orderBy(desc(bills.billDate));

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Bills</h1>
      <p><Link href="/dashboard/bills/new">+ New Bill</Link></p>
      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Bill #</th>
            <th>Vendor</th>
            <th>Bill Date</th>
            <th>Due Date</th>
            <th>Total</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {allBills.map((b) => (
            <tr key={b.id}>
              <td><Link href={`/dashboard/bills/${b.id}`}>{b.billNumber}</Link></td>
              <td>{b.vendorName}</td>
              <td>{b.billDate}</td>
              <td>{b.dueDate}</td>
              <td>{(b.totalCents / 100).toFixed(2)}</td>
              <td>{b.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

---

[System: Empty message content sanitised to satisfy protocol]
# Appendix A Part 4d: Bill Detail with Payment Form, Final State

## src/app/dashboard/bills/[id]/page.tsx (FINAL state — includes the payment form added in Part 15)

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect, notFound } from "next/navigation";
import { db } from "@/lib/db";
import { bills, billLines, vendors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { recordBillPayment } from "@/app/dashboard/payments/actions";

export default async function BillDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const { id } = await params;

  const [bill] = await db
    .select({
      id: bills.id,
      billNumber: bills.billNumber,
      billDate: bills.billDate,
      dueDate: bills.dueDate,
      totalCents: bills.totalCents,
      status: bills.status,
      orgId: bills.orgId,
      vendorName: vendors.name,
    })
    .from(bills)
    .innerJoin(vendors, eq(vendors.id, bills.vendorId))
    .where(eq(bills.id, id))
    .limit(1);

  if (!bill || bill.orgId !== orgId) {
    notFound();
  }

  const lines = await db
    .select()
    .from(billLines)
    .where(eq(billLines.billId, id));

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Bill {bill.billNumber}</h1>
      <p>Vendor: {bill.vendorName}</p>
      <p>Bill Date: {bill.billDate}</p>
      <p>Due Date: {bill.dueDate}</p>
      <p>Status: {bill.status}</p>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Description</th>
            <th>Qty</th>
            <th>Unit Price</th>
            <th>Amount</th>
          </tr>
        </thead>
        <tbody>
          {lines.map((l) => (
            <tr key={l.id}>
              <td>{l.description}</td>
              <td>{l.quantity}</td>
              <td>{(l.unitPriceCents / 100).toFixed(2)}</td>
              <td>{(l.amountCents / 100).toFixed(2)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h3>Total: {(bill.totalCents / 100).toFixed(2)}</h3>

      {bill.status !== "paid" && (
        <div style={{ marginTop: "2rem", borderTop: "1px solid #ccc", paddingTop: "1rem" }}>
          <h3>Record a Payment</h3>
          <form action={recordBillPayment}>
            <input type="hidden" name="billId" value={bill.id} />
            <div>
              <label>Payment Date: </label>
              <input type="date" name="paymentDate" required />
            </div>
            <div>
              <label>Amount: </label>
              <input type="number" name="amount" step="0.01" required />
            </div>
            <div>
              <label>Method: </label>
              <input name="method" placeholder="check, cash, card..." />
            </div>
            <button type="submit">Record Payment</button>
          </form>
        </div>
      )}
    </main>
  );
}
```

---

This completes Appendix A Part 4 (Invoices and Bills in full, final, accumulated state).

