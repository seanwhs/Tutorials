# QB Clone: Core Features - Customers, Vendors, Invoices, Bills, Payments

File 5 of 8. Covers Customers and Vendors, Invoices (creation, list, detail), wiring invoices into the journal engine, Bills (creation, list, detail), and Payments (customer and bill payments, with UI forms). See file "00 Master Overview and Architecture" for the big picture.

---

## PART A: Customers and Vendors

### Add the schema

Open src/lib/db/schema.ts. Add these two tables at the end (keep everything already there from file 04):

```ts
export const customers = pgTable("customers", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  email: text("email"),
  phone: text("phone"),
  billingAddress: text("billing_address"),
  notes: text("notes"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const vendors = pgTable("vendors", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  email: text("email"),
  phone: text("phone"),
  billingAddress: text("billing_address"),
  notes: text("notes"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});
```

Run:
```
npm run db:generate
npm run db:migrate
```

### Create the customers Server Action

Create folder src/app/dashboard/customers/, inside it actions.ts:

```ts
"use server";

import { db } from "@/lib/db";
import { customers } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function createCustomer(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const name = formData.get("name") as string;
  const email = formData.get("email") as string | null;
  const phone = formData.get("phone") as string | null;

  if (!name || name.trim() === "") {
    throw new Error("Customer name is required");
  }

  await db.insert(customers).values({
    orgId,
    name,
    email: email || null,
    phone: phone || null,
  });

  revalidatePath("/dashboard/customers");
  redirect("/dashboard/customers");
}
```

### Build the customer list + form page

Same folder, page.tsx:

```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { customers } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { createCustomer } from "./actions";

export default async function CustomersPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allCustomers = await db
    .select()
    .from(customers)
    .where(eq(customers.orgId, orgId))
    .orderBy(customers.name);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Customers</h1>

      <form action={createCustomer} style={{ marginBottom: "2rem" }}>
        <input name="name" placeholder="Customer name" required />
        <input name="email" placeholder="Email (optional)" type="email" />
        <input name="phone" placeholder="Phone (optional)" />
        <button type="submit">Add Customer</button>
      </form>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Phone</th>
          </tr>
        </thead>
        <tbody>
          {allCustomers.map((c) => (
            <tr key={c.id}>
              <td>{c.name}</td>
              <td>{c.email ?? "-"}</td>
              <td>{c.phone ?? "-"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

### Repeat the same pattern for Vendors

Create src/app/dashboard/vendors/actions.ts:
```ts
"use server";

import { db } from "@/lib/db";
import { vendors } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function createVendor(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const name = formData.get("name") as string;
  const email = formData.get("email") as string | null;
  const phone = formData.get("phone") as string | null;

  if (!name || name.trim() === "") {
    throw new Error("Vendor name is required");
  }

  await db.insert(vendors).values({
    orgId,
    name,
    email: email || null,
    phone: phone || null,
  });

  revalidatePath("/dashboard/vendors");
  redirect("/dashboard/vendors");
}
```

And src/app/dashboard/vendors/page.tsx:
```tsx
import { auth } from "@clerk/nextjs/server";
import { redirect } from "next/navigation";
import { db } from "@/lib/db";
import { vendors } from "@/lib/db/schema";
import { eq } from "drizzle-orm";
import { createVendor } from "./actions";

export default async function VendorsPage() {
  const { orgId } = await auth();
  if (!orgId) redirect("/");

  const allVendors = await db
    .select()
    .from(vendors)
    .where(eq(vendors.orgId, orgId))
    .orderBy(vendors.name);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>Vendors</h1>

      <form action={createVendor} style={{ marginBottom: "2rem" }}>
        <input name="name" placeholder="Vendor name" required />
        <input name="email" placeholder="Email (optional)" type="email" />
        <input name="phone" placeholder="Phone (optional)" />
        <button type="submit">Add Vendor</button>
      </form>

      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Phone</th>
          </tr>
        </thead>
        <tbody>
          {allVendors.map((v) => (
            <tr key={v.id}>
              <td>{v.name}</td>
              <td>{v.email ?? "-"}</td>
              <td>{v.phone ?? "-"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
```

### Add navigation

Open src/app/dashboard/page.tsx, add `import Link from "next/link";` at the top, and inside the returned JSX below the welcome paragraph:
```tsx
<nav style={{ marginTop: "1rem", display: "flex", gap: "1rem" }}>
  <Link href="/dashboard/accounts">Chart of Accounts</Link>
  <Link href="/dashboard/customers">Customers</Link>
  <Link href="/dashboard/vendors">Vendors</Link>
</nav>
```

### Commit

```
git add .
git commit -m "Add Customers and Vendors CRUD using Server Actions"
```

### Checkpoint A
- [ ] customers and vendors tables exist
- [ ] /dashboard/customers lets you add and immediately see a customer
- [ ] /dashboard/vendors works the same way
- [ ] Dashboard has working nav links to all three pages

### Troubleshooting A

**Clicking "Add Customer" does nothing visible** - Check the terminal running npm run dev for a red error message. Most common cause: empty name field despite `required` on the input.

**New customer doesn't appear after submitting** - Confirm revalidatePath("/dashboard/customers") is present before the redirect line.

**"orgId is possibly null" (TypeScript)** - This is why we check `if (!orgId) throw new Error(...)` in the action and `if (!orgId) redirect("/")` in the page - both narrow the type. Confirm both guards are present.

**Both Customers and Vendors pages show the same data** - You likely copy-pasted files for vendors but forgot to change `customers` to `vendors` somewhere (import, table name, variable names). Re-check every occurrence.

**"Module not found: Can't resolve './actions'"** - Confirm actions.ts and page.tsx are in the exact same folder, and the import path is correct.

---
```

Now PART B (Building Invoices) — schema + creation action, then the continued note with form/list/detail pages.
```markdown
## PART B: Building Invoices

### Add the schema

Open src/lib/db/schema.ts. Add this enum near your other pgEnum definitions:

```ts
export const invoiceStatusEnum = pgEnum("invoice_status", [
  "draft",
  "sent",
  "paid",
  "partially_paid",
  "void",
]);
```

Add these two tables at the end:

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

Confirm your import line at the top of schema.ts includes integer and date:
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

### Build the invoice creation Server Action

Create folder src/app/dashboard/invoices/, inside it actions.ts. Note: this is the version BEFORE ledger wiring - it gets upgraded in the next section (PART C) to post a journal entry atomically. Type this version first:

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

### Build the invoice creation form page

Create subfolder src/app/dashboard/invoices/new/, inside it page.tsx:

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
If you don't have any customers yet, add one at /dashboard/customers first.

### Build the invoice list page

In src/app/dashboard/invoices/ (alongside actions.ts), create page.tsx:

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

### Build the invoice detail page

Create subfolder src/app/dashboard/invoices/[id]/, inside it page.tsx. The square-bracket folder name [id] means whatever appears in that part of the URL becomes available as a prop called params.

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

Continuing exactly from where it cut off — this completes the invoice detail page, testing steps, checkpoint, and troubleshooting for PART B:

```markdown
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

Notice params is a Promise you must await - the modern Next.js App Router convention. Notice invoice.orgId !== orgId is checked before rendering, and notFound() is called if it fails - this stops one organization from viewing another organization's invoice by guessing/editing the URL's id value.

### Test the whole flow

Visit /dashboard/invoices/new, pick a customer, fill in an invoice number, dates, and a couple of line items, submit. Confirm you land on /dashboard/invoices with the correct total, and clicking through shows the detail page correctly.

Add a nav link: `<Link href="/dashboard/invoices">Invoices</Link>` alongside your existing dashboard nav links.

### Commit

```
git add .
git commit -m "Add invoices and invoice_lines with create form, list, and detail pages"
```

### Checkpoint B
- [ ] invoices and invoice_lines tables exist
- [ ] Can create an invoice against a real customer with multiple line items
- [ ] Invoice list page shows all invoices with correct totals
- [ ] Invoice detail page (dynamic [id] route) shows full line item detail
- [ ] Understand what the [id] folder syntax does
- [ ] Understand why invoice.orgId !== orgId is checked before rendering
- [ ] NOTE: at this point invoice creation does NOT yet touch the ledger - that's the next section (PART C)

### Troubleshooting B

**Customer dropdown empty on the new invoice page** - Create a customer first at /dashboard/customers.

**Submitting does nothing / unhandled error** - Check terminal for the thrown error. Common cause: all three line item rows left empty (need at least one valid line).

**Invoice total shows 0.00 despite entering line items** - Confirm a Unit Price value and Qty greater than 0 for at least one row - zero/missing rows are silently skipped by design.

**Clicking an invoice number leads to 404** - Confirm the folder is named exactly [id] (with brackets) inside src/app/dashboard/invoices/, with page.tsx directly inside it.

**TypeScript error about params being a Promise** - Confirm both `params: Promise<{ id: string }>` in the signature AND `const { id } = await params;` in the body are present together.

**Invoice list shows invoices from a different organization** - Confirm `.where(eq(invoices.orgId, orgId))` is present in the list query.

**"relation invoice_lines does not exist"** - Migration didn't run; re-run npm run db:migrate and check for errors.

---
```

**PART B is now complete** — append this to the growing `04-core-features.md` file, right after PART A.

Now PART C — Turning Invoices into Journal Entries, the payoff moment where invoice creation gets wired atomically into the ledger.
```markdown
## PART C: Turning Invoices into Journal Entries

This is the payoff moment: invoice creation gets wired into postJournalEntry (from file 03), atomically.

### Update createInvoice to post a journal entry atomically

Open src/app/dashboard/invoices/actions.ts. Replace its ENTIRE contents:

```ts
"use server";

import { db } from "@/lib/db";
import { invoices, invoiceLines } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { postJournalEntry } from "@/lib/accounting/post-journal-entry";
import { findAccountBySubtype } from "@/lib/accounting/find-account";

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

  revalidatePath("/dashboard/invoices");
  redirect("/dashboard/invoices");
}
```

What changed: AR and Income accounts are looked up BEFORE opening the transaction (fail fast if missing). Everything - invoice insert, invoice line inserts, journal entry - is wrapped in one db.transaction. Status changed from "draft" to "sent". `tx` is passed as postJournalEntry's second argument so it joins the same transaction - if the journal entry fails to balance, the ENTIRE operation (including the invoice itself) rolls back.

### Test it

Create a new invoice. Check Neon:
```sql
SELECT * FROM journal_entries ORDER BY created_at DESC LIMIT 1;
```
Copy the id, then:
```sql
SELECT * FROM journal_lines WHERE entry_id = 'PASTE_THE_ID_HERE';
```
Expected: exactly two lines - debit Accounts Receivable, credit Income, both equal to the invoice total.

### Prove the safety net works at the feature level

Temporarily change this line in actions.ts:
```ts
{ accountId: incomeAccount.id, creditCents: totalCents },
```
to:
```ts
{ accountId: incomeAccount.id, creditCents: totalCents - 100 },
```
Save, try creating another invoice - expect a thrown error containing "Journal entry is unbalanced". Check:
```sql
SELECT * FROM invoices ORDER BY created_at DESC LIMIT 1;
```
Confirm the broken invoice was NOT saved either - the transaction rolled back everything. Revert the deliberate bug.

### Commit

```
git add .
git commit -m "Wire invoice creation to postJournalEntry atomically, posting AR debit / Income credit"
```

### Checkpoint C
- [ ] postJournalEntry accepts an optional existing transaction and uses it when provided
- [ ] createInvoice wraps invoice + invoice_lines + journal entry in one db.transaction
- [ ] Creating an invoice produces debit AR / credit Income, both equal to the invoice total
- [ ] Deliberately broke the balance once and confirmed BOTH the invoice and journal entry failed to save together
- [ ] Understand why invoice creation and journal posting must be atomic together, not just each individually safe

### Troubleshooting C

**"No account found with subtype accounts_receivable for this organization"** - Chart of Accounts wasn't seeded for this org, or you're testing a different org than the one you seeded (file 03, PART B). Re-run the seed script for the currently active organization.

**Invoice saves but no journal entry appears** - Confirm you replaced the ENTIRE actions.ts file with this version, not just added imports on top of the old function body.

**"invoiceId is not defined" or invoice is undefined inside the transaction** - Confirm .returning() is present immediately after .insert(invoices).values({...}).

**The deliberate unbalance test still saved a broken invoice** - Confirm you edited the credit line (not the debit line) and saved the file, and that you're looking inside the db.transaction block.

**TypeScript error about the tx parameter type** - Confirm post-journal-entry.ts's signature matches exactly: `tx?: typeof db` as the second parameter, called as `postJournalEntry({...}, tx)`.

---
```

**PART C is now complete** — append this to `04-core-features.md`, right after PART B.

Now PART D — Bills and Expenses, the mirror image of invoices for money owed to vendors.
```markdown
## PART D: Bills and Expenses

Bills are invoices in reverse: money owed to vendors instead of owed by customers. Recorded at RECEIPT (accrual), not payment: debit Expense, credit Accounts Payable.

### Add the schema

Open src/lib/db/schema.ts. Add this enum:
```ts
export const billStatusEnum = pgEnum("bill_status", [
  "open",
  "paid",
  "partially_paid",
  "void",
]);
```

Add these two tables at the end:
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

### Build createBill (atomic, wired to the ledger from the start)

Create folder src/app/dashboard/bills/, inside it actions.ts:

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

Notice the expense account is re-validated server-side (belongs to this org, is really type "expense") - never trust a client-submitted dropdown value.

### Build the bill creation form page

Create subfolder src/app/dashboard/bills/new/, inside it page.tsx:

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
Add a vendor at /dashboard/vendors first if you don't have one.

### Build the bill list page

Create src/app/dashboard/bills/page.tsx:

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

### Build the bill detail page

Create subfolder src/app/dashboard/bills/[id]/, inside it page.tsx:

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

### Test the whole flow

Create a bill against a vendor with an expense account chosen. Confirm the list shows it, and check Neon:
```sql
SELECT * FROM journal_entries WHERE source_type = 'bill' ORDER BY created_at DESC LIMIT 1;
```
Expected: debit to the chosen expense account, credit to Accounts Payable, both equal to the bill total.

Add a nav link for Bills alongside your other dashboard links.

### Commit

```
git add .
git commit -m "Add Bills with expense account selection, wired atomically to postJournalEntry"
```

### Checkpoint D
- [ ] bills and bill_lines tables exist
- [ ] Can create a bill against a real vendor, choosing an expense account
- [ ] Creating a bill produces debit chosen Expense / credit Accounts Payable
- [ ] Bill list and detail pages both work
- [ ] Server action re-validates the submitted expense account server-side

### Troubleshooting D

**"Invalid expense account selected"** - Confirm the account picked really has type "expense" and belongs to the currently active org.

**Bill saves but no journal entry appears** - Confirm postJournalEntry is inside the same db.transaction as the bills/billLines inserts.

**Vendor or Expense Account dropdown empty** - Create a vendor at /dashboard/vendors; confirm expense accounts were seeded (file 03, PART B).

**"relation bill_lines does not exist"** - Re-run npm run db:migrate.

**Clicking a bill leads to 404** - Confirm the [id] folder (with brackets) exists with page.tsx directly inside.

**Bill list shows bills from a different organization** - Confirm `.where(eq(bills.orgId, orgId))` is present.

---
```

**PART D is now complete** — append this to `04-core-features.md`, right after PART C.

Now PART E — Recording Payments, the final piece of `04-core-features.md`.
```markdown
## PART E: Recording Payments

Records the moment cash actually moves. Invoice payment: debit Checking / credit Accounts Receivable (income was already recorded when the invoice was sent). Bill payment: debit Accounts Payable / credit Checking.

### Add the schema

Open src/lib/db/schema.ts. Add these four tables at the end:

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

This course keeps the UI simple (one payment applies to exactly one invoice/bill at a time), but the "applications" join tables support the fuller multi-invoice case as a stretch exercise.

Run:
```
npm run db:generate
npm run db:migrate
```

### Build recordCustomerPayment and recordBillPayment

Create folder src/app/dashboard/payments/, inside it actions.ts:

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

Notice both functions re-fetch the invoice/bill server-side and reject overpayment - never trust a client-submitted total. Notice the direction reverses between the two: customer payment debits Checking (cash comes in) and credits AR (owed less); bill payment debits AP (owe less) and credits Checking (cash goes out). This version supports one payment per invoice/bill for simplicity - summing all prior payment_applications to compute the true remaining balance is a good stretch exercise.

### Add a payment form to the invoice detail page

Open src/app/dashboard/invoices/[id]/page.tsx. Add this import:
```tsx
import { recordCustomerPayment } from "@/app/dashboard/payments/actions";
```
Add this inside the returned JSX, after the line items table and total, shown only if not already fully paid:
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

### Add a payment form to the bill detail page

Open src/app/dashboard/bills/[id]/page.tsx. Add this import:
```tsx
import { recordBillPayment } from "@/app/dashboard/payments/actions";
```
Add this after the bill's line items table and total:
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

### Test both flows

Full payment: pick a sent invoice, pay the full amount, confirm status becomes "paid", and check Neon:
```sql
SELECT * FROM journal_entries WHERE source_type = 'payment_received' ORDER BY created_at DESC LIMIT 1;
```
Expected: debit Checking, credit Accounts Receivable, both equal to the payment.

Partial payment: pay less than the total on a different invoice, confirm status becomes "partially_paid".

Repeat both (full and partial) for a bill via recordBillPayment - expect source_type 'payment_made', debit Accounts Payable, credit Checking.

### A sanity check across the whole ledger so far

```sql
SELECT
  SUM(jl.debit_cents) AS total_debits,
  SUM(jl.credit_cents) AS total_credits
FROM journal_lines jl
JOIN accounts a ON a.id = jl.account_id
WHERE a.subtype = 'bank' AND a.org_id = 'PASTE_YOUR_ORG_ID_HERE';
```
For an Asset account like Checking, its true balance = total_debits minus total_credits. This is exactly the calculation the Profit and Loss and Balance Sheet reports (file 05) perform automatically.

### Commit

```
git add .
git commit -m "Add customer and bill payments with journal posting and invoice/bill status updates"
```

### Checkpoint E
- [ ] payments/payment_applications and bill_payments/bill_payment_applications tables exist
- [ ] Full customer payment marks invoice "paid", posts debit Checking / credit AR
- [ ] Partial customer payment marks invoice "partially_paid"
- [ ] Bill payment marks bill "paid" or "partially_paid", posts debit AP / credit Checking
- [ ] Payment amount validated server-side against actual total, never trusted from the form
- [ ] Ran the manual SUM query and understood how it relates to an account's real balance

### Troubleshooting E

**"No account found with subtype bank for this organization"** - Chart of Accounts wasn't seeded correctly, or "Checking Account" doesn't have subtype exactly "bank". Check: `SELECT * FROM accounts WHERE subtype = 'bank'`.

**"Payment cannot exceed the invoice total"** - Expected behavior if you tried entering more than the total - the overpayment guard working correctly.

**Payment form doesn't appear** - Confirm status isn't already "paid", and confirm the import at the top of the detail page file is correct.

**"recordCustomerPayment is not a function"** - Confirm the import path is exactly @/app/dashboard/payments/actions and the function is exported.

**Status changes but no journal entry appears** - Confirm postJournalEntry is inside the same db.transaction as the payments/paymentApplications (or billPayments/billPaymentApplications) inserts.

**Recording a second smaller payment against an already partially_paid invoice lets you overpay in total** - Known, intentionally-flagged simplification: only the new payment amount is checked against the invoice's full total, not against what remains after prior payments. Summing existing payment_applications before comparing is the correct fix and a good exercise.

**TypeScript complains billPayments or paymentApplications is not exported** - Confirm all four new tables were added with the export const keyword and the file was saved before migrating.

---

This completes file 5 of 8 (Core Features: Customers, Vendors, Invoices, Bills, Payments). Proceed to file "05 Reports - Profit and Loss, Balance Sheet, AR/AP Aging" next.
```

