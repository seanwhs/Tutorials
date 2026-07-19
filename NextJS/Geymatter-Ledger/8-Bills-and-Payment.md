# Part 8: Bills & Payments

Part 7 built the "money coming in" side of the business: invoices. This part builds its mirror image — bills, representing "money going out" — and then closes the loop on both sides with payment recording. By the end of this part, Greymatter Ledger will handle the complete cash lifecycle: earn revenue, incur expenses, and record real cash movement against both.

## Step 8.1 — Designing `bills` and `bill_lines`

### The Target
Add `bills` and `bill_lines` tables — structurally the mirror image of `invoices`/`invoice_lines` from Part 7.

### The Concept
Recall Part 4's vocabulary: an invoice increases Accounts Receivable (money owed *to* you); a bill increases Accounts Payable (money you owe to a vendor). Where an invoice's journal entry was **debit Accounts Receivable / credit Revenue (+ credit GST Output Tax)**, a bill's journal entry will be the reverse in spirit: **debit Expense / credit Accounts Payable (+ debit GST Input Tax)**.

Notice something worth pausing on: GST appears on *both* sides of the ledger, but in opposite roles. When Greymatter Ledger *collects* GST from a customer (Part 7), that GST is a Liability — money the business owes to IRAS. When Greymatter Ledger *pays* GST to a vendor (this part), that GST is an Asset — money the business can *reclaim* from IRAS. This exact asymmetry is why Part 5 seeded two separate GST accounts (Output Tax Payable, a Liability; Input Tax Receivable, an Asset) instead of one shared "GST" account — and it's precisely what Part 10's GST F5 return will net against each other to calculate what's actually owed to or reclaimable from IRAS.

### The Implementation

Add to `src/db/schema.ts` (below the `invoiceLines` table and its relations block — but before the `relations` import block at the very bottom, which we'll extend further):

**`src/db/schema.ts`** (new additions)
```typescript
export const billStatusEnum = pgEnum("bill_status", [
  "draft",
  "received",
  "partially_paid",
  "paid",
  "overdue",
  "void",
]);

// bills is the "envelope" — one bill received from one vendor, mirroring
// invoices exactly in shape, but representing the opposite direction of
// money flow (Accounts Payable, not Accounts Receivable).
export const bills = pgTable("bills", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  vendorId: uuid("vendor_id")
    .notNull()
    .references(() => vendors.id, { onDelete: "restrict" }),

  billNumber: text("bill_number").notNull(),

  issueDate: date("issue_date").notNull(),
  dueDate: date("due_date").notNull(),

  status: billStatusEnum("status").notNull().default("received"),

  subtotal: numeric("subtotal", { precision: 14, scale: 2 }).notNull(),
  gstTotal: numeric("gst_total", { precision: 14, scale: 2 }).notNull(),
  total: numeric("total", { precision: 14, scale: 2 }).notNull(),

  amountPaid: numeric("amount_paid", { precision: 14, scale: 2 })
    .notNull()
    .default("0"),

  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
    onDelete: "set null",
  }),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const billLines = pgTable("bill_lines", {
  id: uuid("id").primaryKey().defaultRandom(),

  billId: uuid("bill_id")
    .notNull()
    .references(() => bills.id, { onDelete: "cascade" }),

  description: text("description").notNull(),
  quantity: numeric("quantity", { precision: 10, scale: 2 }).notNull(),
  unitPrice: numeric("unit_price", { precision: 14, scale: 2 }).notNull(),
  gstRate: numeric("gst_rate", { precision: 5, scale: 2 }).notNull().default("9.00"),
  lineTotal: numeric("line_total", { precision: 14, scale: 2 }).notNull(),

  // Which Expense account this line item should post against, e.g. "Rent
  // Expense" or "Office Supplies Expense". Unlike invoice lines (which
  // always post to the single, fixed "Sales Revenue" account), bill lines
  // can reasonably represent very different kinds of spending within the
  // same bill — so each line needs its own expense account selection.
  expenseAccountId: uuid("expense_account_id")
    .notNull()
    .references(() => accounts.id, { onDelete: "restrict" }),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

Now extend the relations block at the bottom of `schema.ts`:

**`src/db/schema.ts`** (extend the existing relations section)
```typescript
export const billsRelations = relations(bills, ({ one, many }) => ({
  vendor: one(vendors, {
    fields: [bills.vendorId],
    references: [vendors.id],
  }),
  lines: many(billLines),
}));

export const billLinesRelations = relations(billLines, ({ one }) => ({
  bill: one(bills, {
    fields: [billLines.billId],
    references: [bills.id],
  }),
  expenseAccount: one(accounts, {
    fields: [billLines.expenseAccountId],
    references: [accounts.id],
  }),
}));
```

### The Verification

Save the file, confirm no TypeScript errors. Then migrate:

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention the new `bill_status` enum and the `bills`/`bill_lines` tables, followed by `[✓] migrations applied successfully!`. Run `npm run db:studio` and confirm both tables appear, currently empty.

---

## Step 8.2 — The Bill Creation Server Action

### The Target
Write `createBill`, mirroring `createInvoice` from Part 7, but posting the opposite journal entry shape: debit Expense (per line's chosen account) / debit GST Input Tax / credit Accounts Payable.

### The Concept
There's one meaningful structural difference from invoices worth calling out before the code: because each bill line can target a *different* expense account (unlike invoices, where every line always credits the same Sales Revenue account), we need to post **one journal line per distinct expense account used**, not just one flat "Expense" line. If a bill has a "Rent Expense" line and an "Office Supplies Expense" line, the journal entry needs two separate debit lines — one per account — for the reports in Part 9 to correctly attribute spending to the right expense category.

### The Implementation

**`src/lib/actions/bills.ts`**
```typescript
"use server";

import { dbTransactional, db } from "@/db";
import { bills, billLines, accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { postJournalEntry, type ProposedJournalLine } from "@/lib/journal";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export type BillLineInput = {
  description: string;
  quantity: number;
  unitPrice: number;
  gstRate: number;
  expenseAccountId: string;
};

export type CreateBillInput = {
  vendorId: string;
  issueDate: string;
  dueDate: string;
  lines: BillLineInput[];
};

export async function createBill(input: CreateBillInput) {
  const organizationId = await getOrCreateOrganization();

  if (input.lines.length === 0) {
    throw new Error("A bill must have at least one line item.");
  }

  const orgAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const apAccount = orgAccounts.find((a) => a.code === "2000");
  const gstInputAccount = orgAccounts.find((a) => a.code === "1200");

  if (!apAccount || !gstInputAccount) {
    throw new Error(
      "Required accounts (2000 Accounts Payable, 1200 GST Input Tax Receivable) are missing from this organization's Chart of Accounts."
    );
  }

  let subtotalCents = 0;
  let gstTotalCents = 0;

  // We accumulate expense totals PER expense account, using a Map keyed
  // by account ID — this is exactly what lets us post one distinct debit
  // journal line per expense category, rather than a single flattened
  // "Expense" line, per the reasoning above.
  const expenseTotalsByAccount = new Map<string, number>();

  const computedLines = input.lines.map((line) => {
    const lineTotalCents = Math.round(line.quantity * line.unitPrice * 100);
    const lineGstCents = Math.round(lineTotalCents * (line.gstRate / 100));

    subtotalCents += lineTotalCents;
    gstTotalCents += lineGstCents;

    const existing = expenseTotalsByAccount.get(line.expenseAccountId) ?? 0;
    expenseTotalsByAccount.set(line.expenseAccountId, existing + lineTotalCents);

    return {
      description: line.description,
      quantity: line.quantity.toFixed(2),
      unitPrice: line.unitPrice.toFixed(2),
      gstRate: line.gstRate.toFixed(2),
      lineTotal: (lineTotalCents / 100).toFixed(2),
      expenseAccountId: line.expenseAccountId,
    };
  });

  const totalCents = subtotalCents + gstTotalCents;
  const billNumber = `BILL-${Date.now()}`;

  const result = await dbTransactional.transaction(async (tx) => {
    const [bill] = await tx
      .insert(bills)
      .values({
        organizationId,
        vendorId: input.vendorId,
        billNumber,
        issueDate: input.issueDate,
        dueDate: input.dueDate,
        status: "received",
        subtotal: (subtotalCents / 100).toFixed(2),
        gstTotal: (gstTotalCents / 100).toFixed(2),
        total: (totalCents / 100).toFixed(2),
      })
      .returning();

    await tx.insert(billLines).values(
      computedLines.map((line) => ({
        billId: bill.id,
        description: line.description,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        gstRate: line.gstRate,
        lineTotal: line.lineTotal,
        expenseAccountId: line.expenseAccountId,
      }))
    );

    // Build one debit journal line per distinct expense account, plus
    // the GST Input Tax debit (if any), plus the single Accounts Payable
    // credit for the grand total. This is the mirror image of an
    // invoice's [debit AR, credit Revenue, credit GST Output] shape.
    const expenseLines: ProposedJournalLine[] = Array.from(
      expenseTotalsByAccount.entries()
    ).map(([accountId, cents]) => ({
      accountId,
      debit: cents / 100,
    }));

    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: input.issueDate,
        description: `Bill ${billNumber}`,
        sourceType: "bill",
        sourceId: bill.id,
        lines: [
          ...expenseLines,
          ...(gstTotalCents > 0
            ? [{ accountId: gstInputAccount.id, debit: gstTotalCents / 100 }]
            : []),
          { accountId: apAccount.id, credit: totalCents / 100 },
        ],
      },
      tx
    );

    await tx
      .update(bills)
      .set({ journalEntryId: journalResult.entry.id })
      .where(eq(bills.id, bill.id));

    return bill;
  });

  revalidatePath("/bills");
  redirect(`/bills/${result.id}`);
}

export async function getBills() {
  const organizationId = await getOrCreateOrganization();

  return db.query.bills.findMany({
    where: (bills, { eq }) => eq(bills.organizationId, organizationId),
    with: { vendor: true },
    orderBy: (bills, { desc }) => desc(bills.issueDate),
  });
}

export async function getBillById(billId: string) {
  const organizationId = await getOrCreateOrganization();

  return db.query.bills.findFirst({
    where: (bills, { and, eq }) =>
      and(eq(bills.id, billId), eq(bills.organizationId, organizationId)),
    with: { vendor: true, lines: { with: { expenseAccount: true } } },
  });
}
```

### The Verification

No visible output yet — we'll build the form and pages next, then test the full flow together.

---

## Step 8.3 — Building the Bill Creation Form and Pages

### The Target
Create `/bills/new`, `/bills`, and `/bills/[id]`, mirroring Part 7's invoice pages, but with a per-line expense account dropdown instead of a fixed GST-only line.

### The Implementation

**`src/components/bill-form.tsx`**
```tsx
"use client";

import { useState } from "react";
import { createBill, type BillLineInput } from "@/lib/actions/bills";

type Vendor = { id: string; name: string };
type ExpenseAccount = { id: string; code: string; name: string };

export function BillForm({
  vendors,
  expenseAccounts,
}: {
  vendors: Vendor[];
  expenseAccounts: ExpenseAccount[];
}) {
  const [vendorId, setVendorId] = useState(vendors[0]?.id ?? "");
  const [issueDate, setIssueDate] = useState(
    new Date().toISOString().split("T")[0]
  );
  const [dueDate, setDueDate] = useState(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  );
  const [lines, setLines] = useState<BillLineInput[]>([
    {
      description: "",
      quantity: 1,
      unitPrice: 0,
      gstRate: 9,
      expenseAccountId: expenseAccounts[0]?.id ?? "",
    },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function updateLine(index: number, patch: Partial<BillLineInput>) {
    setLines((prev) =>
      prev.map((line, i) => (i === index ? { ...line, ...patch } : line))
    );
  }

  function addLine() {
    setLines((prev) => [
      ...prev,
      {
        description: "",
        quantity: 1,
        unitPrice: 0,
        gstRate: 9,
        expenseAccountId: expenseAccounts[0]?.id ?? "",
      },
    ]);
  }

  function removeLine(index: number) {
    setLines((prev) => prev.filter((_, i) => i !== index));
  }

  const subtotal = lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0);
  const gstTotal = lines.reduce(
    (sum, l) => sum + l.quantity * l.unitPrice * (l.gstRate / 100),
    0
  );
  const total = subtotal + gstTotal;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!vendorId) {
      setError("Please select a vendor.");
      return;
    }
    if (lines.some((l) => !l.description.trim() || l.unitPrice <= 0)) {
      setError("Every line needs a description and a unit price greater than zero.");
      return;
    }

    setSubmitting(true);
    try {
      await createBill({ vendorId, issueDate, dueDate, lines });
    } catch (err) {
      const message = (err as Error)?.message ?? "";
      if (!message.includes("NEXT_REDIRECT")) {
        setError(message || "Failed to create bill.");
        setSubmitting(false);
      }
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 rounded-lg border border-gray-200 bg-white p-6">
      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Vendor</label>
          <select
            value={vendorId}
            onChange={(e) => setVendorId(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          >
            {vendors.map((v) => (
              <option key={v.id} value={v.id}>
                {v.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Issue Date</label>
          <input
            type="date"
            value={issueDate}
            onChange={(e) => setIssueDate(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-700">Due Date</label>
          <input
            type="date"
            value={dueDate}
            onChange={(e) => setDueDate(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          />
        </div>
      </div>

      <div>
        <h3 className="font-semibold text-gray-800">Line Items</h3>
        <div className="mt-2 space-y-2">
          {lines.map((line, index) => (
            <div key={index} className="grid grid-cols-12 gap-2 items-center">
              <input
                type="text"
                placeholder="Description"
                value={line.description}
                onChange={(e) => updateLine(index, { description: e.target.value })}
                className="col-span-4 rounded border border-gray-300 px-2 py-1 text-sm"
              />
              <select
                value={line.expenseAccountId}
                onChange={(e) =>
                  updateLine(index, { expenseAccountId: e.target.value })
                }
                className="col-span-3 rounded border border-gray-300 px-2 py-1 text-sm"
              >
                {expenseAccounts.map((a) => (
                  <option key={a.id} value={a.id}>
                    {a.code} {a.name}
                  </option>
                ))}
              </select>
              <input
                type="number"
                min="0"
                step="0.01"
                placeholder="Qty"
                value={line.quantity}
                onChange={(e) =>
                  updateLine(index, { quantity: parseFloat(e.target.value) || 0 })
                }
                className="col-span-1 rounded border border-gray-300 px-2 py-1 text-sm"
              />
              <input
                type="number"
                min="0"
                step="0.01"
                placeholder="Unit Price"
                value={line.unitPrice}
                onChange={(e) =>
                  updateLine(index, { unitPrice: parseFloat(e.target.value) || 0 })
                }
                className="col-span-2 rounded border border-gray-300 px-2 py-1 text-sm"
              />
              <select
                value={line.gstRate}
                onChange={(e) =>
                  updateLine(index, { gstRate: parseFloat(e.target.value) })
                }
                className="col-span-1 rounded border border-gray-300 px-2 py-1 text-sm"
              >
                <option value={9}>9%</option>
                <option value={0}>0%</option>
              </select>
              <button
                type="button"
                onClick={() => removeLine(index)}
                disabled={lines.length === 1}
                className="col-span-1 text-xs text-red-600 hover:underline disabled:opacity-30"
              >
                Remove
              </button>
            </div>
          ))}
        </div>
        <button
          type="button"
          onClick={addLine}
          className="mt-2 text-sm text-blue-600 hover:underline"
        >
          + Add line item
        </button>
      </div>

      <div className="flex justify-end">
        <div className="w-64 space-y-1 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-600">Subtotal</span>
            <span>${subtotal.toFixed(2)}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-600">GST</span>
            <span>${gstTotal.toFixed(2)}</span>
          </div>
          <div className="flex justify-between border-t border-gray-200 pt-1 font-semibold">
            <span>Total</span>
            <span>${total.toFixed(2)}</span>
          </div>
        </div>
      </div>

      {error && <p className="text-sm text-red-600">{error}</p>}

      <button
        type="submit"
        disabled={submitting}
        className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
      >
        {submitting ? "Recording Bill..." : "Record Bill"}
      </button>
    </form>
  );
}
```

**`src/app/bills/new/page.tsx`**
```tsx
import { getVendors } from "@/lib/actions/vendors";
import { db } from "@/db";
import { accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { eq, and } from "drizzle-orm";
import { BillForm } from "@/components/bill-form";
import { redirect } from "next/navigation";

export default async function NewBillPage() {
  const vendors = await getVendors();
  const organizationId = await getOrCreateOrganization();

  if (vendors.length === 0) {
    redirect("/vendors?reason=need-vendor-for-bill");
  }

  // Only Expense-type accounts make sense as a destination for a bill
  // line — showing Assets or Liabilities here would let a user
  // accidentally miscategorize spending, so we filter down at the query
  // level rather than relying on the user to pick correctly from a
  // full unfiltered list.
  const expenseAccounts = await db
    .select()
    .from(accounts)
    .where(
      and(eq(accounts.organizationId, organizationId), eq(accounts.accountType, "expense"))
    );

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-2xl font-bold text-gray-900">New Bill</h1>
        <div className="mt-6">
          <BillForm vendors={vendors} expenseAccounts={expenseAccounts} />
        </div>
      </div>
    </div>
  );
}
```

**`src/app/bills/page.tsx`**
```tsx
import { getBills } from "@/lib/actions/bills";
import Link from "next/link";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

const STATUS_COLORS: Record<string, string> = {
  draft: "bg-gray-100 text-gray-600",
  received: "bg-blue-100 text-blue-800",
  partially_paid: "bg-yellow-100 text-yellow-800",
  paid: "bg-green-100 text-green-800",
  overdue: "bg-red-100 text-red-800",
  void: "bg-gray-100 text-gray-400 line-through",
};

export default async function BillsPage() {
  const billList = await getBills();

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Bills</h1>
          <div className="flex items-center gap-4">
            <Link
              href="/bills/new"
              className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white"
            >
              + New Bill
            </Link>
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100 text-gray-600">
              <tr>
                <th className="px-4 py-2 font-medium">Bill #</th>
                <th className="px-4 py-2 font-medium">Vendor</th>
                <th className="px-4 py-2 font-medium">Issue Date</th>
                <th className="px-4 py-2 font-medium">Due Date</th>
                <th className="px-4 py-2 font-medium">Total</th>
                <th className="px-4 py-2 font-medium">Status</th>
              </tr>
            </thead>
            <tbody>
              {billList.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-6 text-center text-gray-400">
                    No bills yet.
                  </td>
                </tr>
              )}
              {billList.map((bill) => (
                <tr key={bill.id} className="border-t border-gray-100">
                  <td className="px-4 py-2">
                    <Link
                      href={`/bills/${bill.id}`}
                      className="text-blue-600 hover:underline"
                    >
                      {bill.billNumber}
                    </Link>
                  </td>
                  <td className="px-4 py-2 text-gray-900">{bill.vendor.name}</td>
                  <td className="px-4 py-2 text-gray-500">{bill.issueDate}</td>
                  <td className="px-4 py-2 text-gray-500">{bill.dueDate}</td>
                  <td className="px-4 py-2 text-gray-900">${bill.total}</td>
                  <td className="px-4 py-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs ${STATUS_COLORS[bill.status]}`}
                    >
                      {bill.status.replace("_", " ")}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
```

**`src/app/bills/[id]/page.tsx`**
```tsx
import { getBillById } from "@/lib/actions/bills";
import { notFound } from "next/navigation";

export default async function BillDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const bill = await getBillById(id);

  if (!bill) {
    notFound();
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl rounded-lg border border-gray-200 bg-white p-8">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">
              Bill {bill.billNumber}
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              From: {bill.vendor.name}
            </p>
          </div>
          <span className="rounded-full bg-blue-100 px-3 py-1 text-xs text-blue-800">
            {bill.status.replace("_", " ")}
          </span>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-4 text-sm text-gray-600">
          <div>Issue Date: {bill.issueDate}</div>
          <div>Due Date: {bill.dueDate}</div>
        </div>

        <table className="mt-6 w-full text-left text-sm">
          <thead className="border-b border-gray-200 text-gray-500">
            <tr>
              <th className="py-2 font-medium">Description</th>
              <th className="py-2 font-medium">Expense Account</th>
              <th className="py-2 font-medium">Qty</th>
              <th className="py-2 font-medium">Unit Price</th>
              <th className="py-2 font-medium">GST</th>
              <th className="py-2 text-right font-medium">Line Total</th>
            </tr>
          </thead>
          <tbody>
            {bill.lines.map((line) => (
              <tr key={line.id} className="border-b border-gray-100">
                <td className="py-2">{line.description}</td>
                <td className="py-2 text-gray-500">
                  {line.expenseAccount.code} {line.expenseAccount.name}
                </td>
                <td className="py-2">{line.quantity}</td>
                <td className="py-2">${line.unitPrice}</td>
                <td className="py-2">{line.gstRate}%</td>
                <td className="py-2 text-right">${line.lineTotal}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="mt-4 flex justify-end">
          <div className="w-64 space-y-1 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Subtotal</span>
              <span>${bill.subtotal}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">GST</span>
              <span>${bill.gstTotal}</span>
            </div>
            <div className="flex justify-between border-t border-gray-200 pt-1 font-semibold">
              <span>Total</span>
              <span>${bill.total}</span>
            </div>
            <div className="flex justify-between text-gray-500">
              <span>Amount Paid</span>
              <span>${bill.amountPaid}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
```

Update `src/proxy.ts` — `/bills` is already in the protected list from Part 2, so no change needed there. Confirm it's still present.

### The Verification

First, create a test vendor (via `/vendors`, from Part 7's mirrored implementation) if you haven't already — e.g., "Singtel" or "WeWork Singapore."

Visit `http://localhost:3000/bills/new`. Fill in:
- Vendor: your test vendor
- Line 1: description "Monthly office rent", expense account "5100 Rent Expense", quantity 1, unit price 2000, GST 9%

Confirm the preview shows Subtotal $2,000.00, GST $180.00, Total $2,180.00. Add a second line: description "Internet subscription", expense account "5300 Software & Subscriptions Expense", quantity 1, unit price 100, GST 9%. Confirm the preview updates to Subtotal $2,100.00, GST $189.00, Total $2,289.00.

Click **Record Bill**. You should be redirected to `/bills/[id]`, showing both lines with their correct expense account labels, and the subtotal/GST/total summary matching the preview.

Verify in Drizzle Studio (`npm run db:studio`):
- `bills` — one row, `total = 2289.00`, `status = received`, non-null `journal_entry_id`.
- `bill_lines` — two rows, correctly linked, each with the right `expense_account_id`.
- `journal_entries` — one new entry, description `"Bill BILL-..."`, `source_type = bill`.
- `journal_lines` — **four** lines: a debit of `2000.00` to Rent Expense, a debit of `100.00` to Software & Subscriptions Expense, a debit of `189.00` to GST Input Tax Receivable, and a credit of `2289.00` to Accounts Payable. Confirm debits (2000 + 100 + 189 = 2289.00) equal credits (2289.00). ✅

---

## Step 8.4 — Designing the `payments` Table

### The Target
Add a single `payments` table capable of recording payment against *either* an invoice (money received from a customer) or a bill (money paid to a vendor).

### The Concept
At first glance, "payment received" and "payment made" might seem to deserve two separate tables, mirroring how we split invoices and bills. But a payment itself is a simpler concept than an invoice or bill — it doesn't have multiple line items, GST calculations, or a Chart of Accounts breakdown; it's just "this much cash moved, on this date, against this specific invoice or bill." We model this as **one shared table**, with two optional foreign keys (`invoiceId`, `billId`) — exactly one of which will be filled in for any given payment row, similar in spirit to how a journal line has exactly one of debit/credit filled in.

### The Implementation

Add to `src/db/schema.ts`:

**`src/db/schema.ts`** (new addition)
```typescript
export const paymentMethodEnum = pgEnum("payment_method", [
  "bank_transfer",
  "cash",
  "credit_card",
  "cheque",
  "other",
]);

// payments records a single cash movement against EITHER an invoice
// (money coming in from a customer) OR a bill (money going out to a
// vendor) — never both on the same row. Exactly one of invoiceId/billId
// will be set, matching the "exactly one of two options" pattern we've
//used before with journal lines' debit/credit split.

export const payments = pgTable("payments", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  // Nullable — exactly one of invoiceId/billId will be set per row.
  invoiceId: uuid("invoice_id").references(() => invoices.id, {
    onDelete: "restrict",
  }),
  billId: uuid("bill_id").references(() => bills.id, {
    onDelete: "restrict",
  }),

  amount: numeric("amount", { precision: 14, scale: 2 }).notNull(),
  paymentDate: date("payment_date").notNull(),
  method: paymentMethodEnum("method").notNull().default("bank_transfer"),

  // Which real-world cash/bank account this payment moved through, e.g.
  // "1000 Cash". This is the account we debit (for a payment received)
  // or credit (for a payment made) in the resulting journal entry.
  bankAccountId: uuid("bank_account_id")
    .notNull()
    .references(() => accounts.id, { onDelete: "restrict" }),

  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
    onDelete: "set null",
  }),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const paymentsRelations = relations(payments, ({ one }) => ({
  invoice: one(invoices, {
    fields: [payments.invoiceId],
    references: [invoices.id],
  }),
  bill: one(bills, {
    fields: [payments.billId],
    references: [bills.id],
  }),
  bankAccount: one(accounts, {
    fields: [payments.bankAccountId],
    references: [accounts.id],
  }),
}));
```

### The Verification

Save and migrate:

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention the new `payment_method` enum and `payments` table. Confirm in Drizzle Studio.

---

## Step 8.5 — The Payment Recording Server Action

### The Target
Write `recordInvoicePayment` and `recordBillPayment` — two focused functions that record a payment, update the parent invoice/bill's `amountPaid` and `status`, and post the correct journal entry.

### The Concept
Recall Part 4's Step 4.8 worked example: when a customer pays an invoice, we post **debit Cash / credit Accounts Receivable**. The reverse happens for a bill payment: **debit Accounts Payable / credit Cash**. In both cases, we also need to update the parent record's `amountPaid` and recalculate its `status` — "partially_paid" if the payment doesn't cover the full total, or "paid" if it does (or overpays, though we'll guard against overpayment entirely, since paying more than an invoice is worth doesn't make sense in this simplified model).

### The Implementation

**`src/lib/actions/payments.ts`**
```typescript
"use server";

import { dbTransactional, db } from "@/db";
import { payments, invoices, bills, accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { postJournalEntry } from "@/lib/journal";
import { eq, and } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export type RecordInvoicePaymentInput = {
  invoiceId: string;
  amount: number;
  paymentDate: string;
  method: "bank_transfer" | "cash" | "credit_card" | "cheque" | "other";
};

export type RecordBillPaymentInput = {
  billId: string;
  amount: number;
  paymentDate: string;
  method: "bank_transfer" | "cash" | "credit_card" | "cheque" | "other";
};

export async function recordInvoicePayment(input: RecordInvoicePaymentInput) {
  const organizationId = await getOrCreateOrganization();

  const orgAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const cashAccount = orgAccounts.find((a) => a.code === "1000");
  const arAccount = orgAccounts.find((a) => a.code === "1100");

  if (!cashAccount || !arAccount) {
    throw new Error(
      "Required accounts (1000 Cash, 1100 Accounts Receivable) are missing."
    );
  }

  const invoice = await db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, input.invoiceId), eq(invoices.organizationId, organizationId)),
  });

  if (!invoice) {
    throw new Error("Invoice not found for this organization.");
  }

  const currentPaid = parseFloat(invoice.amountPaid);
  const total = parseFloat(invoice.total);
  const newAmountPaid = currentPaid + input.amount;

  // Guard against overpayment — paying more than the invoice's total
  // doesn't have a sensible meaning in this simplified model (a real
  // system might model this as an overpayment credit; Part 14's roadmap
  // is a natural place to consider that extension).
  if (newAmountPaid > total + 0.001) {
    throw new Error(
      `Payment of $${input.amount.toFixed(2)} would exceed the invoice's remaining balance of $${(total - currentPaid).toFixed(2)}.`
    );
  }

  const newStatus = newAmountPaid >= total - 0.001 ? "paid" : "partially_paid";

  await dbTransactional.transaction(async (tx) => {
    const [payment] = await tx
      .insert(payments)
      .values({
        organizationId,
        invoiceId: input.invoiceId,
        amount: input.amount.toFixed(2),
        paymentDate: input.paymentDate,
        method: input.method,
        bankAccountId: cashAccount.id,
      })
      .returning();

    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: input.paymentDate,
        description: `Payment received for Invoice ${invoice.invoiceNumber}`,
        sourceType: "payment",
        sourceId: payment.id,
        lines: [
          { accountId: cashAccount.id, debit: input.amount },
          { accountId: arAccount.id, credit: input.amount },
        ],
      },
      tx
    );

    await tx
      .update(payments)
      .set({ journalEntryId: journalResult.entry.id })
      .where(eq(payments.id, payment.id));

    await tx
      .update(invoices)
      .set({
        amountPaid: newAmountPaid.toFixed(2),
        status: newStatus,
      })
      .where(eq(invoices.id, input.invoiceId));
  });

  revalidatePath("/invoices");
  revalidatePath(`/invoices/${input.invoiceId}`);
}

export async function recordBillPayment(input: RecordBillPaymentInput) {
  const organizationId = await getOrCreateOrganization();

  const orgAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const cashAccount = orgAccounts.find((a) => a.code === "1000");
  const apAccount = orgAccounts.find((a) => a.code === "2000");

  if (!cashAccount || !apAccount) {
    throw new Error(
      "Required accounts (1000 Cash, 2000 Accounts Payable) are missing."
    );
  }

  const bill = await db.query.bills.findFirst({
    where: (bills, { and, eq }) =>
      and(eq(bills.id, input.billId), eq(bills.organizationId, organizationId)),
  });

  if (!bill) {
    throw new Error("Bill not found for this organization.");
  }

  const currentPaid = parseFloat(bill.amountPaid);
  const total = parseFloat(bill.total);
  const newAmountPaid = currentPaid + input.amount;

  if (newAmountPaid > total + 0.001) {
    throw new Error(
      `Payment of $${input.amount.toFixed(2)} would exceed the bill's remaining balance of $${(total - currentPaid).toFixed(2)}.`
    );
  }

  const newStatus = newAmountPaid >= total - 0.001 ? "paid" : "partially_paid";

  await dbTransactional.transaction(async (tx) => {
    const [payment] = await tx
      .insert(payments)
      .values({
        organizationId,
        billId: input.billId,
        amount: input.amount.toFixed(2),
        paymentDate: input.paymentDate,
        method: input.method,
        bankAccountId: cashAccount.id,
      })
      .returning();

    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: input.paymentDate,
        description: `Payment made for Bill ${bill.billNumber}`,
        sourceType: "payment",
        sourceId: payment.id,
        lines: [
          { accountId: apAccount.id, debit: input.amount },
          { accountId: cashAccount.id, credit: input.amount },
        ],
      },
      tx
    );

    await tx
      .update(payments)
      .set({ journalEntryId: journalResult.entry.id })
      .where(eq(payments.id, payment.id));

    await tx
      .update(bills)
      .set({
        amountPaid: newAmountPaid.toFixed(2),
        status: newStatus,
      })
      .where(eq(bills.id, input.billId));
  });

  revalidatePath("/bills");
  revalidatePath(`/bills/${input.billId}`);
}
```

### The Verification

No visible output yet — we need a UI to trigger these. Let's build a small payment form directly on each detail page next.

---

## Step 8.6 — Adding Payment Forms to Invoice and Bill Detail Pages

### The Target
Add a small "Record Payment" form to both `/invoices/[id]` and `/bills/[id]`, visible only when the invoice/bill isn't already fully paid.

### The Implementation

**`src/components/record-payment-form.tsx`**
```tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  recordInvoicePayment,
  recordBillPayment,
} from "@/lib/actions/payments";

type Props =
  | { kind: "invoice"; targetId: string; remainingBalance: number }
  | { kind: "bill"; targetId: string; remainingBalance: number };

export function RecordPaymentForm(props: Props) {
  const router = useRouter();
  const [amount, setAmount] = useState(props.remainingBalance.toFixed(2));
  const [paymentDate, setPaymentDate] = useState(
    new Date().toISOString().split("T")[0]
  );
  const [method, setMethod] = useState<
    "bank_transfer" | "cash" | "credit_card" | "cheque" | "other"
  >("bank_transfer");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const parsedAmount = parseFloat(amount);
    if (!parsedAmount || parsedAmount <= 0) {
      setError("Enter a valid payment amount greater than zero.");
      return;
    }

    setSubmitting(true);
    try {
      if (props.kind === "invoice") {
        await recordInvoicePayment({
          invoiceId: props.targetId,
          amount: parsedAmount,
          paymentDate,
          method,
        });
      } else {
        await recordBillPayment({
          billId: props.targetId,
          amount: parsedAmount,
          paymentDate,
          method,
        });
      }
      // Unlike createInvoice/createBill, these actions don't redirect —
      // they just update data in place, so we manually refresh the
      // current page's server-rendered content to reflect the new
      // amountPaid/status values.
      router.refresh();
      setAmount("0.00");
    } catch (err) {
      setError((err as Error).message || "Failed to record payment.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mt-6 space-y-3 rounded-lg border border-gray-200 bg-gray-50 p-4"
    >
      <h3 className="font-semibold text-gray-800">Record a Payment</h3>
      <div className="grid grid-cols-3 gap-3">
        <div>
          <label className="block text-xs font-medium text-gray-600">Amount</label>
          <input
            type="number"
            min="0"
            step="0.01"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-2 py-1 text-sm"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-600">Date</label>
          <input
            type="date"
            value={paymentDate}
            onChange={(e) => setPaymentDate(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-2 py-1 text-sm"
          />
        </div>
        <div>
          <label className="block text-xs font-medium text-gray-600">Method</label>
          <select
            value={method}
            onChange={(e) => setMethod(e.target.value as typeof method)}
            className="mt-1 w-full rounded border border-gray-300 px-2 py-1 text-sm"
          >
            <option value="bank_transfer">Bank Transfer</option>
            <option value="cash">Cash</option>
            <option value="credit_card">Credit Card</option>
            <option value="cheque">Cheque</option>
            <option value="other">Other</option>
          </select>
        </div>
      </div>
      {error && <p className="text-sm text-red-600">{error}</p>}
      <button
        type="submit"
        disabled={submitting}
        className="rounded bg-green-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
      >
        {submitting ? "Recording..." : "Record Payment"}
      </button>
    </form>
  );
}
```

Now update both detail pages to include this form, conditionally shown only when there's a remaining balance:

**`src/app/invoices/[id]/page.tsx`** (full updated file)
```tsx
import { getInvoiceById } from "@/lib/actions/invoices";
import { notFound } from "next/navigation";
import { RecordPaymentForm } from "@/components/record-payment-form";

export default async function InvoiceDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const invoice = await getInvoiceById(id);

  if (!invoice) {
    notFound();
  }

  const remainingBalance =
    parseFloat(invoice.total) - parseFloat(invoice.amountPaid);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl rounded-lg border border-gray-200 bg-white p-8">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">
              Invoice {invoice.invoiceNumber}
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              Billed to: {invoice.customer.name}
            </p>
          </div>
          <span className="rounded-full bg-blue-100 px-3 py-1 text-xs text-blue-800">
            {invoice.status.replace("_", " ")}
          </span>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-4 text-sm text-gray-600">
          <div>Issue Date: {invoice.issueDate}</div>
          <div>Due Date: {invoice.dueDate}</div>
        </div>

        <table className="mt-6 w-full text-left text-sm">
          <thead className="border-b border-gray-200 text-gray-500">
            <tr>
              <th className="py-2 font-medium">Description</th>
              <th className="py-2 font-medium">Qty</th>
              <th className="py-2 font-medium">Unit Price</th>
              <th className="py-2 font-medium">GST</th>
              <th className="py-2 text-right font-medium">Line Total</th>
            </tr>
          </thead>
          <tbody>
            {invoice.lines.map((line) => (
              <tr key={line.id} className="border-b border-gray-100">
                <td className="py-2">{line.description}</td>
                <td className="py-2">{line.quantity}</td>
                <td className="py-2">${line.unitPrice}</td>
                <td className="py-2">{line.gstRate}%</td>
                <td className="py-2 text-right">${line.lineTotal}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="mt-4 flex justify-end">
          <div className="w-64 space-y-1 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Subtotal</span>
              <span>${invoice.subtotal}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">GST</span>
              <span>${invoice.gstTotal}</span>
            </div>
            <div className="flex justify-between border-t border-gray-200 pt-1 font-semibold">
              <span>Total</span>
              <span>${invoice.total}</span>
            </div>
            <div className="flex justify-between text-gray-500">
              <span>Amount Paid</span>
              <span>${invoice.amountPaid}</span>
            </div>
            <div className="flex justify-between font-semibold text-gray-800">
              <span>Balance Due</span>
              <span>${remainingBalance.toFixed(2)}</span>
            </div>
          </div>
        </div>

        {remainingBalance > 0.001 && (
          <RecordPaymentForm
            kind="invoice"
            targetId={invoice.id}
            remainingBalance={remainingBalance}
          />
        )}
      </div>
    </div>
  );
}
```

**`src/app/bills/[id]/page.tsx`** (full updated file)
```tsx
import { getBillById } from "@/lib/actions/bills";
import { notFound } from "next/navigation";
import { RecordPaymentForm } from "@/components/record-payment-form";

export default async function BillDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const bill = await getBillById(id);

  if (!bill) {
    notFound();
  }

  const remainingBalance = parseFloat(bill.total) - parseFloat(bill.amountPaid);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-2xl rounded-lg border border-gray-200 bg-white p-8">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">
              Bill {bill.billNumber}
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              From: {bill.vendor.name}
            </p>
          </div>
          <span className="rounded-full bg-blue-100 px-3 py-1 text-xs text-blue-800">
            {bill.status.replace("_", " ")}
          </span>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-4 text-sm text-gray-600">
          <div>Issue Date: {bill.issueDate}</div>
          <div>Due Date: {bill.dueDate}</div>
        </div>

        <table className="mt-6 w-full text-left text-sm">
          <thead className="border-b border-gray-200 text-gray-500">
            <tr>
              <th className="py-2 font-medium">Description</th>
              <th className="py-2 font-medium">Expense Account</th>
              <th className="py-2 font-medium">Qty</th>
              <th className="py-2 font-medium">Unit Price</th>
              <th className="py-2 font-medium">GST</th>
              <th className="py-2 text-right font-medium">Line Total</th>
            </tr>
          </thead>
          <tbody>
            {bill.lines.map((line) => (
              <tr key={line.id} className="border-b border-gray-100">
                <td className="py-2">{line.description}</td>
                <td className="py-2 text-gray-500">
                  {line.expenseAccount.code} {line.expenseAccount.name}
                </td>
                <td className="py-2">{line.quantity}</td>
                <td className="py-2">${line.unitPrice}</td>
                <td className="py-2">{line.gstRate}%</td>
                <td className="py-2 text-right">${line.lineTotal}</td>
              </tr>
            ))}
          </tbody>
        </table>

        <div className="mt-4 flex justify-end">
          <div className="w-64 space-y-1 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-600">Subtotal</span>
              <span>${bill.subtotal}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-600">GST</span>
              <span>${bill.gstTotal}</span>
            </div>
            <div className="flex justify-between border-t border-gray-200 pt-1 font-semibold">
              <span>Total</span>
              <span>${bill.total}</span>
            </div>
            <div className="flex justify-between text-gray-500">
              <span>Amount Paid</span>
              <span>${bill.amountPaid}</span>
            </div>
            <div className="flex justify-between font-semibold text-gray-800">
              <span>Balance Due</span>
              <span>${remainingBalance.toFixed(2)}</span>
            </div>
          </div>
        </div>

        {remainingBalance > 0.001 && (
          <RecordPaymentForm
            kind="bill"
            targetId={bill.id}
            remainingBalance={remainingBalance}
          />
        )}
      </div>
    </div>
  );
}
```

### The Verification

Visit your test invoice from Part 7 (total $1,290.00). Confirm a "Record a Payment" form now appears below the summary, pre-filled with amount `1290.00`. 
Change the amount to `500.00` (a partial payment) and click **Record Payment**. Confirm the page refreshes and now shows:
- Status badge: `partially paid`
- Amount Paid: `$500.00`
- Balance Due: `$790.00`
- The payment form still visible, now pre-filled with `790.00`

Now submit the remaining `$790.00`. Confirm the page refreshes and shows:
- Status badge: `paid`
- Amount Paid: `$1290.00`
- Balance Due: `$0.00`
- The payment form has disappeared entirely (since `remainingBalance > 0.001` is now false)

Try navigating back and re-submitting a payment on this now-fully-paid invoice by manually re-triggering the form (this shouldn't be possible through the UI anymore, which is itself part of the verification — confirm the form is genuinely gone, not just hidden with remaining functionality).

Repeat the same test on your test bill from Step 8.3 (total $2,289.00) — pay it in one single full payment this time, and confirm the status flips directly from `received` to `paid`, Amount Paid shows `$2289.00`, and Balance Due shows `$0.00`.

**Cross-check in Drizzle Studio:**
- Open `payments` — confirm three rows total (two partial payments against the invoice, one full payment against the bill), each with the correct `amount`, `invoice_id`/`bill_id` (exactly one set per row, the other null), and a non-null `journal_entry_id`.
- Open `journal_entries` — confirm three new entries exist, with descriptions like `"Payment received for Invoice INV-..."` (×2) and `"Payment made for Bill BILL-..."` (×1).
- Open `journal_lines` — for the first invoice payment ($500), confirm a debit of `500.00` to Cash and a credit of `500.00` to Accounts Receivable. For the bill payment ($2,289.00), confirm a debit of `2289.00` to Accounts Payable and a credit of `2289.00` to Cash.

**Test the overpayment guard:** Try to record a payment on any already-fully-paid invoice or bill by temporarily editing the URL/logic, or simply attempt to submit a payment amount larger than a remaining balance on a partially-paid one (e.g., try to pay `$1000.00` against an invoice with only `$790.00` remaining). Confirm you see the red error message: `"Payment of $1000.00 would exceed the invoice's remaining balance of $790.00."` and confirm in Drizzle Studio that **no new rows** were created in `payments` or `journal_entries` as a result of this rejected attempt.

---

## Step 8.7 — Seventh Git Commit

### The Target
Save the completed bills and payments feature as a new checkpoint.

### The Implementation

```bash
git add .
git commit -m "Add bills, per-line expense accounts, and invoice/bill payment recording with correct journal posting"
```

### The Verification

```bash
git log --oneline
```

Expected output, seven lines, newest first — confirming this and all six prior checkpoints remain intact.

---

## ✅ Checkpoint — Part 8

At this point, you should have:

- [x] `bills` and `bill_lines` tables, mirroring invoices but posting the opposite journal shape (debit Expense/GST Input, credit Accounts Payable)
- [x] `createBill` correctly grouping multiple line items by distinct expense account into separate journal debit lines
- [x] Working `/bills`, `/bills/new`, and `/bills/[id]` pages
- [x] A shared `payments` table modeling exactly one of `invoiceId`/`billId` per row
- [x] `recordInvoicePayment` and `recordBillPayment`, both posting correct journal entries and updating `amountPaid`/`status` atomically
- [x] Overpayment protection, verified to reject cleanly with zero side effects
- [x] Payment forms wired into both detail pages, correctly appearing/disappearing based on remaining balance
- [x] Hands-on, Drizzle-Studio-verified proof of every journal entry balancing correctly across partial payments, full payments, and bill payments
- [x] A seventh Git commit checkpoint

---

## 📚 Reference Section: Status Transitions, Overpayment, and Design Symmetry

*(A standalone reference — read now or return later.)*

**Why is GST Input Tax debited on a bill but GST Output Tax credited on an invoice — walk through the intuition once more.**
Debits increase Assets; credits increase Liabilities (Part 4, Section 4.4). GST Input Tax Receivable is an Asset (a refund claim against IRAS), so receiving more of it — i.e., paying GST to a vendor — is a debit. GST Output Tax Payable is a Liability (money owed to IRAS), so accumulating more of it — i.e., collecting GST from a customer — is a credit. The two accounts, and their opposite debit/credit treatment, are the direct mechanical consequence of one being an Asset and the other being a Liability.

**Why didn't we build a single generic "line item" table shared between invoices and bills, given how similar `invoice_lines` and `bill_lines` are?**
It's a reasonable question, and a valid alternative design exists. We kept them separate for two reasons specific to this course: first, `bill_lines` needs an `expenseAccountId` column that has no equivalent meaning on `invoice_lines` (which always implicitly targets Sales Revenue) — a shared table would need this column to be nullable and conditionally required, which is a subtler and more error-prone constraint to enforce than simply not having the column at all on one of the two tables. Second, keeping them separate keeps every query about "invoice lines" or "bill lines" unambiguous without an extra `WHERE type = ...` filter — a small but meaningful simplicity win for a beginner-focused codebase.

**Why use a floating-point-style `0.001` tolerance when comparing `newAmountPaid` to `total`, instead of comparing the exact strings or integer cents?**
This is a slight, deliberate simplification for readability at this stage in the course — `parseFloat` on `numeric` columns returns a JavaScript floating point number, and after several additions, tiny representation errors (e.g., `1290.0000000001`) can theoretically creep in. A `0.001` tolerance comfortably absorbs any such drift for currency amounts using at most 2 decimal places, without producing a false "not fully paid" or false "overpayment" result. For extra rigor, you could refactor this to use the same integer-cents comparison technique from `postJournalEntry` (Part 6) — a good exercise to try on your own, and a natural extension mentioned again in Part 14's roadmap discussion of hardening the engine further.

**Why does `RecordPaymentForm` call `router.refresh()` instead of `redirect()` like `createInvoice`/`createBill` do?**
`createInvoice` and `createBill` create a *brand-new* record and need to navigate the user to its new detail page — a genuine change of location. Recording a payment, by contrast, happens on a page the user is already looking at (the invoice/bill detail page) — there's no new location to navigate to, we just need the *existing* page's server-rendered data (like `amountPaid` and `status`) to refresh and reflect the just-recorded payment. `router.refresh()` is the right tool specifically for "re-run this Server Component's data fetching without changing the URL or losing client-side state."

---

## 🔧 Troubleshooting — Part 8

**"`createBill` throws 'Required accounts (2000 Accounts Payable, 1200 GST Input Tax Receivable) are missing.'"**
Same root cause as Part 7's equivalent error — the active organization's Chart of Accounts wasn't seeded. Revisit Part 5's backfill page if needed.

**"The bill detail page shows the wrong expense account name, or throws an error about `expenseAccount` being undefined."**
Confirm `getBillById`'s `with` clause includes the nested `lines: { with: { expenseAccount: true } }` exactly as shown in Step 8.2 — a common typo is writing `with: { expenseAccount: true }` at the wrong nesting level (alongside `lines`, rather than inside it).

**"Recording a payment succeeds but the invoice/bill's status and amount don't visually update on the page."**
Confirm `RecordPaymentForm` is calling `router.refresh()` inside its `try` block, after the `await recordInvoicePayment(...)` / `await recordBillPayment(...)` call succeeds, and that the component is correctly marked `"use client"` at the top of the file (required for `useRouter` to work at all).

**"The overpayment guard doesn't trigger, and I can pay more than an invoice's total."**
Double-check the exact comparison `newAmountPaid > total + 0.001` — if this was accidentally written as `newAmountPaid > total` without any tolerance, in rare cases involving floating point representation it could behave inconsistently; but the more common cause of this specific bug is accidentally comparing `input.amount` (this single payment) against `total`, instead of `newAmountPaid` (this payment PLUS everything already paid before it) against `total`.

**"Drizzle Studio shows a payment row, but its `journal_entry_id` is null."**
This indicates the `tx.update(payments).set({ journalEntryId: ... })` line either wasn't reached (an error occurred before it) or targeted the wrong `payment.id`. Re-check the exact sequence in `recordInvoicePayment`/`recordBillPayment` against Step 8.5 — the update must reference the `payment` object returned from the initial insert, using its real `.id`.
