## Part 14: Bills and Expenses

Goal: build `bills` and `bill_lines` (the mirror of invoices, for money owed to vendors), and wire bill creation into `postJournalEntry` as debit Expense / credit Accounts Payable.

Prerequisite: Parts 1-13 completed.

---

### 1. Bills are invoices in reverse

An invoice is sent (you are owed money). A bill is received (you owe money). A bill is recorded the moment you receive it (accrual), not when you pay it:

| Account | Debit | Credit |
|---|---|---|
| Utilities Expense (Expense) | 200 | |
| Accounts Payable (Liability) | | 200 |

### 2. Add the schema

Open `src/lib/db/schema.ts`. Add this enum near your other enums:

```ts
export const billStatusEnum = pgEnum("bill_status", [
  "open",
  "paid",
  "partially_paid",
  "void",
]);
```

Add these two tables at the end of the file:

```ts
export const bills = pgTable("bills", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  vendorId: uuid("vendor_id")
    .notNull()
    .references(() => vendors.id),
  billNumber: text("bill_number").notNull(),
  billDate: date("bill_date").notNull(),
  dueDate: date("due_date").notNull(),
  status: billStatusEnum("status").notNull().default("open"),
  memo: text("memo"),
  totalCents: bigint("total_cents", { mode: "number" }).notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const billLines = pgTable("bill_lines", {
  id: uuid("id").primaryKey().defaultRandom(),
  billId: uuid("bill_id")
    .notNull()
    .references(() => bills.id, { onDelete: "cascade" }),
  description: text("description").notNull(),
  quantity: integer("quantity").notNull().default(1),
  unitPriceCents: bigint("unit_price_cents", { mode: "number" }).notNull(),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Run:
```
npm run db:generate
npm run db:migrate
```

Confirm in Neon's dashboard that both `bills` and `bill_lines` now exist.

### 3. Build the createBill Server Action

Create the folder `src/app/dashboard/bills/`. Inside it, create `actions.ts`:

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

Notice the validation confirming `expenseAccountId` truly belongs to this org and is really type "expense" — never trust a client-submitted dropdown value.

### 4. Build the bill creation form page

Create the subfolder `src/app/dashboard/bills/new/`, and inside it, `page.tsx`:

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

If you don't have any vendors yet, go to `/dashboard/vendors` (Part 11) and add one before continuing.

### 5. Build the bill list and detail pages

Create `src/app/dashboard/bills/page.tsx`:

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

Create the subfolder `src/app/dashboard/bills/[id]/`, and inside it, `page.tsx`:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect, notFound } from "next/navigation";
import { db } from "@/lib/db";
import { bills, billLines, vendors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

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
    </main>
  );
}
```

Notice `bill.orgId !== orgId` is checked before rendering, and `notFound()` is called if it fails — this stops one organization from viewing another organization's bill just by guessing or changing the URL's id value.

### 6. Test the whole flow

Visit `/dashboard/bills/new`, pick a vendor, choose an expense account, fill in a couple of line items, and submit. Confirm you land on the bill list with the correct total, then click into the bill to see its detail page. Check Neon's SQL Editor:

```sql
SELECT * FROM journal_entries WHERE source_type = 'bill' ORDER BY created_at DESC LIMIT 1;
```

Copy the `id` from that row, then:

```sql
SELECT * FROM journal_lines WHERE entry_id = 'PASTE_THE_ID_HERE';
```

Expected: exactly two lines, one debiting your chosen expense account for the full bill total, one crediting Accounts Payable for the same amount.

### 7. Add a nav link

Open `src/app/dashboard/page.tsx` and add a link to Bills alongside your existing links to Chart of Accounts, Customers, and Vendors:

```tsx
<nav style={{ marginTop: "1rem", display: "flex", gap: "1rem" }}>
  <Link href="/dashboard/accounts">Chart of Accounts</Link>
  <Link href="/dashboard/customers">Customers</Link>
  <Link href="/dashboard/vendors">Vendors</Link>
  <Link href="/dashboard/bills">Bills</Link>
</nav>
```

### 8. Commit your progress

```
git add .
git commit -m "Add Bills with expense account selection, wired atomically to postJournalEntry"
```

---

### Checkpoint

- [ ] `bills` and `bill_lines` tables exist in Neon
- [ ] You can create a bill against a real vendor, choosing an expense account
- [ ] Creating a bill produces a correct journal entry: debit the chosen Expense account, credit Accounts Payable, both equal to the bill total
- [ ] The bill list and detail pages both display correctly
- [ ] The server action re-validates that the submitted expense account really belongs to the org and is really expense type
- [ ] You understand why `bill.orgId !== orgId` is checked on the detail page before rendering

---

### Troubleshooting

**Error: "Invalid expense account selected"**
Confirm the account you picked in the dropdown actually has `type "expense"` in the database (check Neon's accounts table), and that it belongs to the same organization currently active in Clerk's organization switcher. If you seeded default accounts in Part 9 for a different test organization than the one you are using now, switch organizations or re-run the seed script for this one.

**Bill saves but no journal entry appears in Neon**
Confirm the `postJournalEntry` call is inside the same `db.transaction` block as the `bills` and `billLines` inserts, using `tx` as the second argument, not called separately after the transaction closes.

**Vendor dropdown or Expense Account dropdown is empty**
For vendors: go create one first at `/dashboard/vendors`. For expense accounts: confirm Part 9's `seedDefaultAccounts` ran successfully for this organization — query `SELECT * FROM accounts WHERE type = 'expense'` in Neon's SQL Editor to check.

**TypeScript error mentioning "billLines" or "bills" is not exported from schema**
Confirm you added `export const bills = pgTable(...)` and `export const billLines = pgTable(...)` with the `export` keyword present, and that the file saved before running `npm run db:generate`.

**Error: "relation bill_lines does not exist" when visiting a bill's detail page**
This means the migration did not run successfully. Re-run `npm run db:migrate` and check the terminal output for errors — a common cause is a typo in the schema that produced invalid SQL in the generated migration file.

**Clicking a bill number on the list page leads to a 404 / Not Found page**
Confirm the folder is named exactly `[id]` (including the square brackets) inside `src/app/dashboard/bills/`, and that `page.tsx` is directly inside that folder, not inside a further subfolder.

**The bill list shows bills belonging to a different organization**
Double check the `.where(eq(bills.orgId, orgId))` clause is present on the query in `page.tsx` — without it, the list would show every organization's bills, which is exactly the kind of data leak the `org_id` column exists to prevent.
