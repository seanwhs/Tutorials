## Part 15: Recording Payments

Goal: record the moment cash actually moves — a customer paying an invoice, and the business paying a bill — each producing its own journal entry, and correctly updating the invoice/bill's status.

Prerequisite: Parts 1-14 completed.

---

### 1. Recap: what's missing right now

Right now, invoices are always created with status "sent" and bills with status "open" — nothing ever marks them paid, and no cash account ever actually changes. Recall Part 8's Worked Example 3: when a customer pays, Accounts Receivable goes DOWN (credit) and Checking goes UP (debit) — income was already recorded when the invoice was sent, so it is not touched again. Bill payments are the mirror: Accounts Payable goes down (debit) and Checking goes down (credit).

### 2. Add the schema

Open `src/lib/db/schema.ts`. Add these four tables at the end of the file:

```ts
export const payments = pgTable("payments", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customers.id),
  paymentDate: date("payment_date").notNull(),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
  method: text("method"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const paymentApplications = pgTable("payment_applications", {
  id: uuid("id").primaryKey().defaultRandom(),
  paymentId: uuid("payment_id")
    .notNull()
    .references(() => payments.id, { onDelete: "cascade" }),
  invoiceId: uuid("invoice_id")
    .notNull()
    .references(() => invoices.id),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
});

export const billPayments = pgTable("bill_payments", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  vendorId: uuid("vendor_id")
    .notNull()
    .references(() => vendors.id),
  paymentDate: date("payment_date").notNull(),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
  method: text("method"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const billPaymentApplications = pgTable("bill_payment_applications", {
  id: uuid("id").primaryKey().defaultRandom(),
  billPaymentId: uuid("bill_payment_id")
    .notNull()
    .references(() => billPayments.id, { onDelete: "cascade" }),
  billId: uuid("bill_id")
    .notNull()
    .references(() => bills.id),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
});
```

Notice the pattern: `payments`/`bill_payments` hold the actual cash event, and their "applications" tables are a join, letting one payment cover multiple invoices/bills. This course keeps the UI simple (one payment applies to exactly one invoice at a time), but the schema is ready for the fuller version as a stretch exercise.

Run:
```
npm run db:generate
npm run db:migrate
```

Confirm all four new tables exist in Neon.

### 3. Build recordCustomerPayment

Create the folder `src/app/dashboard/payments/` and inside it, `actions.ts`:

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
```

Notice several important checks before we touch the database: we re-fetch the invoice from the database (never trust a client-submitted total), confirm it really belongs to this org, and reject any payment amount greater than what is actually owed. This version supports one payment per invoice for simplicity — a fuller version would sum all prior `payment_applications` for this invoice to compute what is truly still owed before comparing.

### 4. Build recordBillPayment (the mirror)

Add this second function to the same `src/app/dashboard/payments/actions.ts` file, below `recordCustomerPayment`:

```ts
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

Notice the direction is reversed compared to `recordCustomerPayment`: here Accounts Payable is debited (it goes down, since we owe less) and Checking is credited (it goes down, since cash left the business).

### 5. Add a payment form to the invoice detail page

Open `src/app/dashboard/invoices/[id]/page.tsx` (from Parts 12/13). Add this import at the top:

```tsx
import { recordCustomerPayment } from "@/app/dashboard/payments/actions";
```

Then, inside the returned JSX, after the line items table and total, add a payment form that only shows if the invoice is not already fully paid:

```tsx
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
```

### 6. Add a payment form to the bill detail page

Open `src/app/dashboard/bills/[id]/page.tsx` (from Part 14). Add this import at the top:

```tsx
import { recordBillPayment } from "@/app/dashboard/payments/actions";
```

Then, inside the returned JSX, after the line items table and total, add the mirrored form:

```tsx
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
```

### 7. Test both flows

Pick an existing sent invoice, open its detail page, fill in the payment form with the full invoice amount, and submit. Confirm the invoice's status now shows "paid". Check Neon's SQL Editor:

```sql
SELECT * FROM journal_entries WHERE source_type = 'payment_received' ORDER BY created_at DESC LIMIT 1;
```

Copy the `id`, then:

```sql
SELECT * FROM journal_lines WHERE entry_id = 'PASTE_THE_ID_HERE';
```

Expected: a debit to Checking and a credit to Accounts Receivable, both equal to the payment amount.

Then try a partial payment on a different invoice (enter less than the full total) and confirm its status becomes "partially_paid" instead of "paid".

Repeat both tests (full and partial payment) for a bill using the bill detail page's payment form, and confirm the journal entry has `source_type` equal to `'payment_made'`, debiting Accounts Payable and crediting Checking.

### 8. A sanity check across the whole ledger so far

Run this in Neon's SQL Editor, replacing the placeholder with your real organization id (visible on your dashboard page, or in Clerk's dashboard):

```sql
SELECT
  SUM(jl.debit_cents) AS total_debits,
  SUM(jl.credit_cents) AS total_credits
FROM journal_lines jl
JOIN accounts a ON a.id = jl.account_id
WHERE a.subtype = 'bank' AND a.org_id = 'PASTE_YOUR_ORG_ID_HERE';
```

For an Asset account like Checking, its true balance is `total_debits` minus `total_credits` (matching Part 8's normal balance table). This is exactly the calculation Part 16's Profit and Loss report and Part 17's Balance Sheet will perform automatically — you are previewing that logic manually right now.

### 9. Commit your progress

```
git add .
git commit -m "Add customer and bill payments with journal posting and invoice/bill status updates"
```

---

### Checkpoint

- [ ] payments/payment_applications and bill_payments/bill_payment_applications tables all exist in Neon
- [ ] Recording a full customer payment marks the invoice "paid" and posts debit Checking / credit Accounts Receivable
- [ ] Recording a partial customer payment marks the invoice "partially_paid"
- [ ] Recording a bill payment marks the bill "paid" or "partially_paid" and posts debit Accounts Payable / credit Checking
- [ ] The payment amount is validated server-side against the actual invoice/bill total, never trusted from the form alone
- [ ] You ran the manual SUM query against journal_lines and understood how it relates to an account's real balance

---

### Troubleshooting

**Error: "No account found with subtype bank for this organization"**
Your Chart of Accounts was not seeded correctly in Part 9, or the "Checking Account" row does not have `subtype` set to exactly "bank". Check with `SELECT * FROM accounts WHERE subtype = 'bank'` in Neon's SQL Editor.

**Error: "Payment cannot exceed the invoice total"**
This is expected behavior if you tried entering more than the invoice's total — it is the overpayment guard working correctly, not a bug. Enter an amount at or below the invoice total.

**Payment form does not appear on the invoice or bill detail page**
Confirm the invoice/bill's status is not already "paid" — the form is conditionally hidden once status equals "paid". Also confirm you added the import for `recordCustomerPayment` or `recordBillPayment` at the top of the file.

**Error: "recordCustomerPayment is not a function" or similar import error**
Confirm the import path exactly matches where you created the file: `@/app/dashboard/payments/actions`. Confirm the function is exported with the `export` keyword in `actions.ts`.

**Invoice status changes but no journal entry appears in Neon**
Confirm the `postJournalEntry` call is inside the same `db.transaction` block as the `payments` and `paymentApplications` inserts (or `billPayments` and `billPaymentApplications` for bill payments), not called after the transaction closes.

**Recording a second, smaller payment against an already `partially_paid` invoice lets you overpay in total**
This is a known, intentionally-flagged simplification in this course version — it only checks the new payment amount against the invoice's full total, not against what remains after prior payments. Summing existing `payment_applications` for the invoice before comparing is the correct fix, and a good exercise once you are comfortable with the pattern.

**TypeScript complains that billPayments or paymentApplications is not exported from schema**
Confirm all four new tables from step 2 were added with the `export const` keyword, and that the file was saved before running `npm run db:generate`.
