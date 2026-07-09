## Part 12: Building Invoices

Goal: build the `invoices` and `invoice_lines` tables, a form to create an invoice against a real customer with multiple line items, and pages to view them.

Prerequisite: Parts 1-11 completed.

---

### 1. Add the schema

Open `src/lib/db/schema.ts`. Add this enum near the top with your other `pgEnum` definitions:

```ts
export const invoiceStatusEnum = pgEnum("invoice_status", [
  "draft",
  "sent",
  "paid",
  "partially_paid",
  "void",
]);
```

Add these two tables at the end of the file:

```ts
export const invoices = pgTable("invoices", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  customerId: uuid("customer_id")
    .notNull()
    .references(() => customers.id),
  invoiceNumber: text("invoice_number").notNull(),
  issueDate: date("issue_date").notNull(),
  dueDate: date("due_date").notNull(),
  status: invoiceStatusEnum("status").notNull().default("draft"),
  memo: text("memo"),
  totalCents: bigint("total_cents", { mode: "number" }).notNull().default(0),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const invoiceLines = pgTable("invoice_lines", {
  id: uuid("id").primaryKey().defaultRandom(),
  invoiceId: uuid("invoice_id")
    .notNull()
    .references(() => invoices.id, { onDelete: "cascade" }),
  description: text("description").notNull(),
  quantity: integer("quantity").notNull().default(1),
  unitPriceCents: bigint("unit_price_cents", { mode: "number" }).notNull(),
  amountCents: bigint("amount_cents", { mode: "number" }).notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Add `integer` and `date` to your existing import line at the top of `schema.ts` if they are not already there:

```ts
import {
  pgTable,
  pgEnum,
  text,
  uuid,
  bigint,
  boolean,
  integer,
  timestamp,
  date,
  jsonb,
} from "drizzle-orm/pg-core";
```

Run:
```
npm run db:generate
npm run db:migrate
```

### 2. Build the invoice creation Server Action

Create the folder `src/app/dashboard/invoices/`. Inside it, create `actions.ts`:

```ts
"use server";

import { db } from "@/lib/db";
import { invoices, invoiceLines } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

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

  const [invoice] = await db
    .insert(invoices)
    .values({
      orgId,
      customerId,
      invoiceNumber,
      issueDate,
      dueDate,
      totalCents,
      status: "draft",
    })
    .returning();

  await db.insert(invoiceLines).values(
    lines.map((l) => ({
      invoiceId: invoice.id,
      description: l.description,
      quantity: l.quantity,
      unitPriceCents: l.unitPriceCents,
      amountCents: l.amountCents,
    }))
  );

  revalidatePath("/dashboard/invoices");
  redirect("/dashboard/invoices");
}
```

### 3. Build the invoice creation form page

Create the subfolder `src/app/dashboard/invoices/new/`, and inside it, `page.tsx`:

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

If you don't have any customers yet, go to /dashboard/customers (Part 11) and add one before continuing — the customer dropdown will be empty otherwise and you won't be able to submit the form.

### 4. Build the invoice list page

In the `src/app/dashboard/invoices/` folder (alongside `actions.ts`), create `page.tsx`:

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

### 5. Build the invoice detail page

Create the subfolder `src/app/dashboard/invoices/[id]/`, and inside it, `page.tsx`. This introduces Next.js's dynamic route segments: the square-bracket folder name `[id]` means whatever value appears in that part of the URL becomes available to your page as a prop called `params`.

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect, notFound } from "next/navigation";
import { db } from "@/lib/db";
import { invoices, invoiceLines, customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";

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
    </main>
  );
}
```

Notice `params` is a Promise you must `await` — this is the modern Next.js App Router convention (Next.js 16). Notice also `invoice.orgId !== orgId` is checked before rendering, and `notFound()` is called if it fails — this stops one organization from viewing another organization's invoice just by guessing or changing the URL's id value.

### 6. Test the whole flow

Visit `/dashboard/invoices/new`, pick a customer, fill in an invoice number, issue date, due date, and a couple of line items, then submit. Confirm you land back on `/dashboard/invoices` and see it listed with the correct total. Click the invoice number to open its detail page and confirm the line items and total display correctly.

Add a nav link: open `src/app/dashboard/page.tsx` and add `<Link href="/dashboard/invoices">Invoices</Link>` alongside your existing nav links.

### 7. Commit your progress

```
git add .
git commit -m "Add invoices and invoice_lines with create form, list, and detail pages"
```

---

### Checkpoint

- [ ] invoices and invoice_lines tables exist in Neon
- [ ] You can create an invoice against a real customer with multiple line items
- [ ] The invoice list page shows all invoices with correct totals
- [ ] The invoice detail page (using a dynamic `[id]` route) shows full line item detail
- [ ] You understand what the `[id]` folder syntax does and how `params` gives you that value in code
- [ ] You understand why `invoice.orgId !== orgId` is checked before rendering the detail page

---

### Troubleshooting

**Customer dropdown on the new invoice page is empty**
Go create a customer first at `/dashboard/customers` (Part 11) — you cannot create an invoice without at least one customer to attach it to.

**Submitting the form does nothing, or an unhandled error appears**
Check your terminal running `npm run dev` for the actual thrown error message. A common cause is leaving all three line item rows completely empty — the action requires at least one valid line (a description with a quantity greater than 0 and a non-negative unit price).

**Invoice total shows as 0.00 even though you entered line items**
Confirm you entered a value in the "Unit Price" field for at least one row, and that the "Qty" field is greater than 0 — rows with a missing or zero quantity/price are silently skipped by the parsing loop, by design.

**Clicking an invoice number on the list leads to a 404 / Not Found page**
Confirm the folder is named exactly `[id]` (including the square brackets) inside `src/app/dashboard/invoices/`, and that `page.tsx` sits directly inside that folder.

**TypeScript error: "Property 'id' does not exist on type Promise<...>" or similar around params**
Confirm you wrote `params: Promise<{ id: string }>` in the function's type signature AND used `const { id } = await params;` inside the function body — both parts are required together in Next.js 16.

**The invoice list shows invoices belonging to a different organization**
Double check the `.where(eq(invoices.orgId, orgId))` clause is present in the list page's query — without it, you would see every organization's invoices mixed together, which is exactly the kind of data leak the `org_id` column exists to prevent.

**Error: "relation invoice_lines does not exist"**
The migration did not run successfully. Re-run `npm run db:migrate` and check the terminal output carefully for the actual error — a common cause is a typo in the schema producing invalid SQL.
