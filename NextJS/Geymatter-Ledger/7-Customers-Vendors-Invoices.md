# Part 7: Customers, Vendors & Invoices

We now have a bulletproof journal engine sitting idle, with nothing yet calling it. This part changes that. We're going to build our first real business feature — customers, vendors, and invoicing — and by the end, creating an invoice will *automatically* produce a correct, GST-aware, perfectly balanced journal entry, with zero manual bookkeeping steps required from the user.

## Step 7.1 — Designing the Customer & Vendor Tables

### The Target
Add `customers` and `vendors` tables to our schema.

### The Concept
A **customer** is who you invoice (they owe you money). A **vendor** is who bills you (you owe them money). Structurally, they're nearly identical — both are just "a business or person we have a financial relationship with" — but we deliberately keep them as two separate tables rather than one shared "contacts" table. Think of it like keeping separate address books for "people I send money requests to" versus "people who send me bills" — even if the contact fields look similar, the *role* each plays in the accounting flow is fundamentally different (one drives Accounts Receivable, the other Accounts Payable), and keeping them separate keeps every future query unambiguous about which direction money flows.

### The Implementation

Add to `src/db/schema.ts` (below the `journalLines` table from Part 6):

**`src/db/schema.ts`** (new additions — append these to the existing file)
```typescript
// customers are who we invoice — they owe Greymatter Ledger money.
export const customers = pgTable("customers", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  name: text("name").notNull(),
  email: text("email"),
  address: text("address"),

  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

// vendors are who bills us — we owe them money.
export const vendors = pgTable("vendors", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  name: text("name").notNull(),
  email: text("email"),
  address: text("address"),

  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

### The Verification

Save the file, confirm no TypeScript errors. We'll migrate this together with the invoice tables shortly, to minimize the number of separate migration runs.

---

## Step 7.2 — Server Actions: What They Are and Why We Use Them

### The Target
Understand the pattern we're about to use for every single "create/update/delete" operation for the rest of this course, before writing our first one.

### The Concept
In many web frameworks, if you want a button click to save data, you need to build a separate API endpoint (a URL the browser calls), write code to parse the incoming request, and write separate client-side code to call that URL and handle the response — two files, two languages of thinking, glued together by fetch calls.

**Server Actions** are a Next.js feature that collapses this entirely. You write one plain async function, marked with the special `"use server"` directive, and you can call it *directly* from a form or button in your React code — Next.js automatically handles turning that into a secure network call behind the scenes. Think of it like a restaurant where, instead of writing an order on paper and walking it to the kitchen window yourself, you simply say the order out loud and the kitchen already hears you — the "how does this message get to the kitchen" plumbing is handled invisibly.

We use Server Actions for every write operation in this course because they run *only* on the server (never shipped to the browser, so no risk of exposing sensitive logic or direct database access to a user's browser), and because they integrate naturally with React forms.

---

## Step 7.3 — Customer CRUD via Server Actions

### The Target
Build create, read, update, and "soft delete" (deactivate) functionality for customers.

### The Concept
"CRUD" stands for Create, Read, Update, Delete — the four basic operations almost every data-driven feature needs. We use "soft delete" (setting `isActive: false`) rather than a real `DELETE` from the database, for the same historical-integrity reason established in Part 5 and Part 6: if a customer has ever been invoiced, permanently erasing their record would corrupt historical reports referencing them.

### The Implementation

**`src/lib/actions/customers.ts`**
```typescript
"use server";

import { db } from "@/db";
import { customers } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { eq, and, asc } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export type CustomerFormState = {
  error?: string;
  success?: boolean;
};

/**
 * Creates a new customer for the current organization.
 * Called directly from a <form action={createCustomer}> element.
 */
export async function createCustomer(
  _prevState: CustomerFormState,
  formData: FormData
): Promise<CustomerFormState> {
  const organizationId = await getOrCreateOrganization();

  const name = formData.get("name")?.toString().trim();
  const email = formData.get("email")?.toString().trim() || null;
  const address = formData.get("address")?.toString().trim() || null;

  // Basic server-side validation. We never trust client-side validation
  // alone — a malicious or buggy client could submit a form with the
  // required attribute stripped out, so the real check must happen here.
  if (!name) {
    return { error: "Customer name is required." };
  }

  await db.insert(customers).values({
    organizationId,
    name,
    email,
    address,
  });

  // revalidatePath tells Next.js "the data behind this page has changed —
  // throw away any cached version and regenerate it fresh next time it's
  // requested." Without this, the customer list page might keep showing
  // stale data after a new customer is added.
  revalidatePath("/customers");

  return { success: true };
}

export async function updateCustomer(
  customerId: string,
  _prevState: CustomerFormState,
  formData: FormData
): Promise<CustomerFormState> {
  const organizationId = await getOrCreateOrganization();

  const name = formData.get("name")?.toString().trim();
  const email = formData.get("email")?.toString().trim() || null;
  const address = formData.get("address")?.toString().trim() || null;

  if (!name) {
    return { error: "Customer name is required." };
  }

  await db
    .update(customers)
    .set({ name, email, address })
    .where(
      // Both conditions matter: matching the ID AND the organization.
      // Without the organizationId check, a user could theoretically
      // guess another company's customer ID and edit their data —
      // this is the same multi-tenancy discipline from Part 2/6.
      and(eq(customers.id, customerId), eq(customers.organizationId, organizationId))
    );

  revalidatePath("/customers");
  return { success: true };
}

export async function deactivateCustomer(customerId: string) {
  const organizationId = await getOrCreateOrganization();

  await db
    .update(customers)
    .set({ isActive: false })
    .where(
      and(eq(customers.id, customerId), eq(customers.organizationId, organizationId))
    );

  revalidatePath("/customers");
}

export async function getCustomers() {
  const organizationId = await getOrCreateOrganization();

  return db
    .select()
    .from(customers)
    .where(eq(customers.organizationId, organizationId))
    .orderBy(asc(customers.name));
}
```

### The Verification

No visible output yet — we'll build the actual page next, then test everything together.

---

## Step 7.4 — Vendor CRUD via Server Actions

### The Target
Build the mirror-image version of Step 7.3, for vendors.

### The Implementation

**`src/lib/actions/vendors.ts`**
```typescript
"use server";

import { db } from "@/db";
import { vendors } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { eq, and, asc } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export type VendorFormState = {
  error?: string;
  success?: boolean;
};

export async function createVendor(
  _prevState: VendorFormState,
  formData: FormData
): Promise<VendorFormState> {
  const organizationId = await getOrCreateOrganization();

  const name = formData.get("name")?.toString().trim();
  const email = formData.get("email")?.toString().trim() || null;
  const address = formData.get("address")?.toString().trim() || null;

  if (!name) {
    return { error: "Vendor name is required." };
  }

  await db.insert(vendors).values({ organizationId, name, email, address });

  revalidatePath("/vendors");
  return { success: true };
}

export async function updateVendor(
  vendorId: string,
  _prevState: VendorFormState,
  formData: FormData
): Promise<VendorFormState> {
  const organizationId = await getOrCreateOrganization();

  const name = formData.get("name")?.toString().trim();
  const email = formData.get("email")?.toString().trim() || null;
  const address = formData.get("address")?.toString().trim() || null;

  if (!name) {
    return { error: "Vendor name is required." };
  }

  await db
    .update(vendors)
    .set({ name, email, address })
    .where(and(eq(vendors.id, vendorId), eq(vendors.organizationId, organizationId)));

  revalidatePath("/vendors");
  return { success: true };
}

export async function deactivateVendor(vendorId: string) {
  const organizationId = await getOrCreateOrganization();

  await db
    .update(vendors)
    .set({ isActive: false })
    .where(and(eq(vendors.id, vendorId), eq(vendors.organizationId, organizationId)));

  revalidatePath("/vendors");
}

export async function getVendors() {
  const organizationId = await getOrCreateOrganization();

  return db
    .select()
    .from(vendors)
    .where(eq(vendors.organizationId, organizationId))
    .orderBy(asc(vendors.name));
}
```

### The Verification

Same as above — we'll test this together with the pages next.

---

## Step 7.5 — Building the Customers Page

### The Target
Create `/customers`, a page listing existing customers with an inline "add new customer" form.

### The Concept
This is our first real interactive form using a Server Action. We'll use React's `useActionState` hook (built specifically to pair with Server Actions), which tracks the pending/error/success state of a form submission without us writing any manual fetch or state-management code ourselves.

### The Implementation

Because `useActionState` requires interactivity (re-rendering based on form submission state), the form itself needs to be a **Client Component** — a small, explicitly marked piece of the page that runs in the browser rather than purely on the server. We'll split this into two files: a server page that fetches data, and a client component that renders the interactive form.

**`src/components/customer-form.tsx`**
```tsx
"use client";

import { useActionState } from "react";
import { createCustomer, type CustomerFormState } from "@/lib/actions/customers";

const initialState: CustomerFormState = {};

export function CustomerForm() {
  // useActionState wires our Server Action directly to this form's
  // submission lifecycle: `state` reflects whatever the action last
  // returned (success or error), and `pending` is true while the
  // action is running on the server — letting us disable the button
  // and show a spinner-like state without any manual fetch/loading code.
  const [state, formAction, pending] = useActionState(
    createCustomer,
    initialState
  );

  return (
    <form action={formAction} className="space-y-3 rounded-lg border border-gray-200 bg-white p-4">
      <h3 className="font-semibold text-gray-800">Add a new customer</h3>

      <div>
        <label className="block text-sm font-medium text-gray-700">
          Name <span className="text-red-500">*</span>
        </label>
        <input
          type="text"
          name="name"
          required
          className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          placeholder="Acme Corp"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Email</label>
        <input
          type="email"
          name="email"
          className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          placeholder="billing@acmecorp.com"
        />
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700">Address</label>
        <textarea
          name="address"
          className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          rows={2}
          placeholder="1 Raffles Place, Singapore 048616"
        />
      </div>

      {state.error && (
        <p className="text-sm text-red-600">{state.error}</p>
      )}
      {state.success && (
        <p className="text-sm text-green-600">Customer added successfully.</p>
      )}

      <button
        type="submit"
        disabled={pending}
        className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
      >
        {pending ? "Saving..." : "Add Customer"}
      </button>
    </form>
  );
}
```

**`src/app/customers/page.tsx`**
```tsx
import { getCustomers, deactivateCustomer } from "@/lib/actions/customers";
import { CustomerForm } from "@/components/customer-form";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

export default async function CustomersPage() {
  const customerList = await getCustomers();

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Customers</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-6">
          <CustomerForm />
        </div>

        <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100 text-gray-600">
              <tr>
                <th className="px-4 py-2 font-medium">Name</th>
                <th className="px-4 py-2 font-medium">Email</th>
                <th className="px-4 py-2 font-medium">Address</th>
                <th className="px-4 py-2 font-medium">Status</th>
                <th className="px-4 py-2 font-medium"></th>
              </tr>
            </thead>
            <tbody>
              {customerList.length === 0 && (
                <tr>
                  <td colSpan={5} className="px-4 py-6 text-center text-gray-400">
                    No customers yet. Add your first one above.
                  </td>
                </tr>
              )}
              {customerList.map((c) => (
                <tr key={c.id} className="border-t border-gray-100">
                  <td className="px-4 py-2 text-gray-900">{c.name}</td>
                  <td className="px-4 py-2 text-gray-500">{c.email ?? "—"}</td>
                  <td className="px-4 py-2 text-gray-500">{c.address ?? "—"}</td>
                  <td className="px-4 py-2">
                    <span
                      className={
                        c.isActive
                          ? "rounded-full bg-green-100 px-2 py-0.5 text-xs text-green-800"
                          : "rounded-full bg-gray-100 px-2 py-0.5 text-xs text-gray-600"
                      }
                    >
                      {c.isActive ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td className="px-4 py-2 text-right">
                    {c.isActive && (
                      <form
                        action={async () => {
                          "use server";
                          await deactivateCustomer(c.id);
                        }}
                      >
                        <button className="text-xs text-red-600 hover:underline">
                          Deactivate
                        </button>
                      </form>
                    )}
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

Add `/customers` and `/vendors` to the protected routes list in `src/proxy.ts`:

**`src/proxy.ts`** (update the `isProtectedRoute` matcher list)
```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/accounts(.*)",
  "/customers(.*)",
  "/vendors(.*)",
  "/invoices(.*)",
  "/bills(.*)",
  "/reports(.*)",
  "/settings(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

### The Verification

We haven't run the migration for `customers`/`vendors` yet — let's do that now before testing the page. In your terminal:

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention two new tables (`customers`, `vendors`) being created, followed by `[✓] migrations applied successfully!`.

Now, while signed in with an active organization, visit `http://localhost:3000/customers`. You should see an empty table with "No customers yet," and the add-customer form above it. Fill in a name (e.g., "Acme Corp"), an email, and an address, then click **Add Customer**. The page should refresh and show the new customer in the table below, marked "Active." Click **Deactivate** on that row and confirm the status badge changes to "Inactive" and the Deactivate button disappears for that row.

Build and verify `/vendors` the same way, following the identical pattern (create `src/components/vendor-form.tsx` mirroring `customer-form.tsx`, and `src/app/vendors/page.tsx` mirroring `customers/page.tsx`, swapping every `customer`-related name for `vendor`). Confirm it behaves identically.

---

## Step 7.6 — Designing `invoices` and `invoice_lines`

### The Target
Add the tables that represent an actual invoice — a header row plus multiple line items.

### The Concept
Recall the journal entry/journal line pattern from Part 6 — one envelope, many line items inside. An invoice follows the exact same shape: **`invoices`** is the envelope (customer, invoice number, dates, status), and **`invoice_lines`** are the individual billable items inside it (e.g., "10 hours consulting @ $100/hr," "1 software license @ $50"), each with its own GST rate per the blueprint's Singapore-specific requirement.

We also need an **invoice status** — tracking whether an invoice is still a draft, has been sent, is partially paid, fully paid, or overdue. This will become essential in Part 8 (payments) and Part 9 (AR Aging).

### The Implementation

Add to `src/db/schema.ts`:

**`src/db/schema.ts`** (new additions — append below `vendors`)
```typescript
export const invoiceStatusEnum = pgEnum("invoice_status", [
  "draft",
  "sent",
  "partially_paid",
  "paid",
  "overdue",
  "void",
]);

// invoices is the "envelope" — one bill sent to one customer.
export const invoices = pgTable("invoices", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  customerId: uuid("customer_id")
    .notNull()
    .references(() => customers.id, { onDelete: "restrict" }),
  // restrict, not cascade: we never want deleting a customer record to
  // silently wipe out historical invoices tied to real revenue.

  invoiceNumber: text("invoice_number").notNull(),

  issueDate: date("issue_date").notNull(),
  dueDate: date("due_date").notNull(),

  status: invoiceStatusEnum("status").notNull().default("draft"),

  // Denormalized total fields, calculated and stored at save time from the
  // invoice_lines beneath this invoice. Storing these (rather than always
  // recalculating from lines on every read) makes list pages and reports
  // dramatically faster, since they avoid a join+sum on every single row
  // just to show a total. We accept the small tradeoff that these must be
  // kept in sync manually whenever lines change — handled entirely inside
  // one server action (Step 7.8), so there's exactly one place this can
  // ever go wrong.
  subtotal: numeric("subtotal", { precision: 14, scale: 2 }).notNull(),
  gstTotal: numeric("gst_total", { precision: 14, scale: 2 }).notNull(),
  total: numeric("total", { precision: 14, scale: 2 }).notNull(),

  // How much of `total` has been received so far via payments (Part 8).
  amountPaid: numeric("amount_paid", { precision: 14, scale: 2 })
    .notNull()
    .default("0"),

  // Links this invoice to the journal entry it produced, so we can always
  // trace "which ledger entry did this invoice create" — useful for
  // debugging and for Part 14's roadmap item on voiding entries safely.
  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
    onDelete: "set null",
  }),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

// invoiceLines are the individual billable items within one invoice.
export const invoiceLines = pgTable("invoice_lines", {
  id: uuid("id").primaryKey().defaultRandom(),

  invoiceId: uuid("invoice_id")
    .notNull()
    .references(() => invoices.id, { onDelete: "cascade" }),
  // cascade here IS correct, unlike accounts/customers above — invoice
  // lines have no independent existence or meaning outside their parent
  // invoice, so deleting the invoice should delete its lines too.

  description: text("description").notNull(),
  quantity: numeric("quantity", { precision: 10, scale: 2 }).notNull(),
  unitPrice: numeric("unit_price", { precision:14, scale: 2 }).notNull(),

  // GST rate as a percentage, e.g. "9.00" for Singapore's 9% standard
  // rate, or "0.00" for zero-rated/exempt items. Stored per-line (not
  // per-invoice) because a single invoice can legitimately mix taxable
  // and zero-rated items — e.g. a consulting invoice that also resells
  // an exported good at 0% GST.
  gstRate: numeric("gst_rate", { precision: 5, scale: 2 }).notNull().default("9.00"),

  // lineTotal = quantity * unitPrice, stored to avoid recalculating on
  // every read, following the same denormalization reasoning as the
  // invoice header's subtotal/gstTotal/total above.
  lineTotal: numeric("line_total", { precision: 14, scale: 2 }).notNull(),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

### The Verification

Save the file. Confirm no TypeScript errors — check especially that `customers` and `journalEntries` are already defined earlier in the file (they must be, since we reference them here), and that every `numeric(...)` call has matching parentheses.

---

## Step 7.7 — Migrating the Invoice Tables

### The Target
Apply `invoices` and `invoice_lines`, plus the new `invoice_status` enum, to Neon.

### The Implementation

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention the new enum and two new tables, followed by `[✓] migrations applied successfully!`.

### The Verification

```bash
npm run db:studio
```

Confirm `invoices` and `invoice_lines` both appear, with all the columns described above, currently empty.

---

## Step 7.8 — The Invoice Creation Server Action: Wiring Into `postJournalEntry`

### The Target
Write `createInvoice` — a single server action that saves the invoice header, its line items, calculates GST per Singapore rules, and posts a perfectly balanced journal entry, all atomically.

### The Concept
This is where Part 4's worked example (Step 4.8) and Part 6's engine finally meet real user input. Recall the pattern: an invoice for $1,000 of services plus 9% GST produces a three-line journal entry — debit Accounts Receivable $1,090, credit Sales Revenue $1,000, credit GST Output Tax Payable $90. Except now, since an invoice can have *multiple* lines, each potentially with its *own* GST rate, we need to compute this correctly across an arbitrary number of lines — summing all line totals into one Accounts Receivable debit, and summing GST separately per distinct rate isn't strictly necessary for the journal entry (all GST output tax lands in the same single account regardless of rate), but we do need to track subtotal vs. GST total separately for the invoice header and for Part 10's GST F5 report.

Because this operation touches two brand-new database tables (`invoices`, `invoice_lines`) *and* calls `postJournalEntry` (which itself opens its own transaction), we need the whole thing — invoice header, invoice lines, and the journal posting — to succeed or fail together as one unit. If we saved the invoice successfully but the journal posting failed, we'd have an invoice sitting in our system with no corresponding ledger entry — a silent, dangerous inconsistency. We solve this by wrapping the entire operation in one outer transaction using our transactional client, and by giving `postJournalEntry` an optional way to run *inside* an existing transaction rather than always starting its own.

Let's first make a small but important adjustment to `postJournalEntry` from Part 6, so it can participate in a larger, calling transaction when needed.

### The Implementation

**`src/lib/journal.ts`** (updated — accepts an optional existing transaction)
```typescript
import { dbTransactional } from "@/db";
import { journalEntries, journalLines } from "@/db/schema";

export type ProposedJournalLine = {
  accountId: string;
  debit?: number;
  credit?: number;
};

export type PostJournalEntryInput = {
  organizationId: string;
  entryDate: string;
  description: string;
  sourceType?: string;
  sourceId?: string;
  lines: ProposedJournalLine[];
};

// A minimal type describing "something that can run queries inside a
// transaction" — either our top-level dbTransactional client, or the
// `tx` object handed to us inside someone else's transaction callback.
// This lets postJournalEntry be called standalone (Part 6's tests) OR
// nested inside a larger transaction (this part's invoice creation),
// without duplicating any of its validation logic.
type Executor = typeof dbTransactional;

export async function postJournalEntry(
  input: PostJournalEntryInput,
  executor: Executor = dbTransactional
) {
  const { organizationId, entryDate, description, sourceType, sourceId, lines } =
    input;

  if (lines.length < 2) {
    throw new Error(
      "A journal entry must have at least two lines (double-entry requires at least one debit and one credit)."
    );
  }

  for (const line of lines) {
    const hasDebit = (line.debit ?? 0) > 0;
    const hasCredit = (line.credit ?? 0) > 0;
    if (hasDebit === hasCredit) {
      throw new Error(
        `Each journal line must have exactly one of debit or credit set to a positive amount (account ${line.accountId} had debit=${line.debit ?? 0}, credit=${line.credit ?? 0}).`
      );
    }
  }

  const totalDebitCents = lines.reduce(
    (sum, line) => sum + Math.round((line.debit ?? 0) * 100),
    0
  );
  const totalCreditCents = lines.reduce(
    (sum, line) => sum + Math.round((line.credit ?? 0) * 100),
    0
  );

  if (totalDebitCents !== totalCreditCents) {
    throw new Error(
      `Journal entry does not balance: total debits (${(totalDebitCents / 100).toFixed(2)}) must equal total credits (${(totalCreditCents / 100).toFixed(2)}). This entry was rejected and nothing was saved.`
    );
  }

  const accountIds = lines.map((line) => line.accountId);
  const matchingAccounts = await executor.query.accounts.findMany({
    where: (accounts, { and, eq, inArray }) =>
      and(eq(accounts.organizationId, organizationId), inArray(accounts.id, accountIds)),
  });

  if (matchingAccounts.length !== new Set(accountIds).size) {
    throw new Error(
      "One or more accounts in this journal entry do not belong to the specified organization, or do not exist."
    );
  }

  // Helper that does the actual insert work, given whatever executor
  // (a top-level transaction or a nested `tx`) was provided.
  async function doInsert(tx: Executor) {
    const [entry] = await tx
      .insert(journalEntries)
      .values({
        organizationId,
        entryDate,
        description,
        sourceType: sourceType ?? "manual",
        sourceId: sourceId ?? null,
      })
      .returning();

    const insertedLines = await tx
      .insert(journalLines)
      .values(
        lines.map((line) => ({
          journalEntryId: entry.id,
          accountId: line.accountId,
          debitAmount: (line.debit ?? 0).toFixed(2),
          creditAmount: (line.credit ?? 0).toFixed(2),
        }))
      )
      .returning();

    return { entry, lines: insertedLines };
  }

  // If we were handed the top-level dbTransactional client (meaning this
  // call is NOT already nested inside someone else's transaction), open
  // a fresh transaction of our own — this preserves Part 6's original,
  // standalone behavior exactly. If we were instead handed an existing
  // `tx` (as createInvoice will do), just use it directly, so all the
  // work becomes part of the CALLER's transaction instead of starting
  // a second, separate one.
  if (executor === dbTransactional) {
    return executor.transaction((tx) => doInsert(tx as Executor));
  }
  return doInsert(executor);
}
```

Now, the invoice creation server action:

**`src/lib/actions/invoices.ts`**
```typescript
"use server";

import { dbTransactional } from "@/db";
import { db } from "@/db";
import { invoices, invoiceLines, accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { postJournalEntry } from "@/lib/journal";
import { eq, and } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export type InvoiceLineInput = {
  description: string;
  quantity: number;
  unitPrice: number;
  gstRate: number;
};

export type CreateInvoiceInput = {
  customerId: string;
  issueDate: string;
  dueDate: string;
  lines: InvoiceLineInput[];
};

export async function createInvoice(input: CreateInvoiceInput) {
  const organizationId = await getOrCreateOrganization();

  if (input.lines.length === 0) {
    throw new Error("An invoice must have at least one line item.");
  }

  // Look up the three accounts this invoice will need to post against:
  // Accounts Receivable (debit side), Sales Revenue (credit side), and
  // GST Output Tax Payable (credit side for the tax portion). We look
  // these up by their well-known codes from Part 5's seed data.
  const orgAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const arAccount = orgAccounts.find((a) => a.code === "1100");
  const revenueAccount = orgAccounts.find((a) => a.code === "4000");
  const gstOutputAccount = orgAccounts.find((a) => a.code === "2100");

  if (!arAccount || !revenueAccount || !gstOutputAccount) {
    throw new Error(
      "Required accounts (1100 Accounts Receivable, 4000 Sales Revenue, 2100 GST Output Tax Payable) are missing from this organization's Chart of Accounts."
    );
  }

  // Calculate every line's total and GST, in integer cents internally to
  // avoid floating point drift (same discipline as Part 6's engine),
  // then convert back to dollars only for storage/display.
  let subtotalCents = 0;
  let gstTotalCents = 0;

  const computedLines = input.lines.map((line) => {
    const lineTotalCents = Math.round(line.quantity * line.unitPrice * 100);
    const lineGstCents = Math.round(lineTotalCents * (line.gstRate / 100));

    subtotalCents += lineTotalCents;
    gstTotalCents += lineGstCents;

    return {
      description: line.description,
      quantity: line.quantity.toFixed(2),
      unitPrice: line.unitPrice.toFixed(2),
      gstRate: line.gstRate.toFixed(2),
      lineTotal: (lineTotalCents / 100).toFixed(2),
    };
  });

  const totalCents = subtotalCents + gstTotalCents;

  // Generate a simple, human-friendly sequential-looking invoice number.
  // For a beginner-friendly course, a timestamp-based number is simple,
  // collision-free, and requires no separate "next number" counter table.
  const invoiceNumber = `INV-${Date.now()}`;

  // Everything below must succeed or fail together: the invoice header,
  // its line items, AND the resulting journal entry. We use our
  // transactional client directly (not the plain postJournalEntry export)
  // so we can pass its live `tx` into postJournalEntry, nesting it into this
  // same transaction — exactly the capability we just added to `postJournalEntry` above.
  const result = await dbTransactional.transaction(async (tx) => {
    const [invoice] = await tx
      .insert(invoices)
      .values({
        organizationId,
        customerId: input.customerId,
        invoiceNumber,
        issueDate: input.issueDate,
        dueDate: input.dueDate,
        status: "sent",
        subtotal: (subtotalCents / 100).toFixed(2),
        gstTotal: (gstTotalCents / 100).toFixed(2),
        total: (totalCents / 100).toFixed(2),
      })
      .returning();

    await tx.insert(invoiceLines).values(
      computedLines.map((line) => ({
        invoiceId: invoice.id,
        description: line.description,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        gstRate: line.gstRate,
        lineTotal: line.lineTotal,
      }))
    );

    // Post the journal entry INSIDE this same transaction, by passing
    // `tx` as the executor — this is the exact mechanism the updated
    // postJournalEntry now supports. If this call throws (e.g. the
    // entry somehow doesn't balance, which it always should given our
    // arithmetic above, but we keep the guard as defense-in-depth), the
    // ENTIRE transaction rolls back — meaning the invoice header and its
    // lines we just inserted above are undone too. This is the atomicity
    // guarantee the blueprint calls for: an invoice can never exist
    // without its matching, correct journal entry, and vice versa.
    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: input.issueDate,
        description: `Invoice ${invoiceNumber}`,
        sourceType: "invoice",
        sourceId: invoice.id,
        lines: [
          { accountId: arAccount.id, debit: totalCents / 100 },
          { accountId: revenueAccount.id, credit: subtotalCents / 100 },
          ...(gstTotalCents > 0
            ? [{ accountId: gstOutputAccount.id, credit: gstTotalCents / 100 }]
            : []),
        ],
      },
      tx
    );

    // Link the invoice back to the journal entry it produced, so we can
    // always trace one to the other later (used by Part 9's reports and
    // Part 14's roadmap item on safely voiding entries).
    await tx
      .update(invoices)
      .set({ journalEntryId: journalResult.entry.id })
      .where(eq(invoices.id, invoice.id));

    return invoice;
  });

  revalidatePath("/invoices");
  redirect(`/invoices/${result.id}`);
}

export async function getInvoices() {
  const organizationId = await getOrCreateOrganization();

  return db.query.invoices.findMany({
    where: (invoices, { eq }) => eq(invoices.organizationId, organizationId),
    with: { customer: true },
    orderBy: (invoices, { desc }) => desc(invoices.issueDate),
  });
}

export async function getInvoiceById(invoiceId: string) {
  const organizationId = await getOrCreateOrganization();

  const invoice = await db.query.invoices.findFirst({
    where: (invoices, { and, eq }) =>
      and(eq(invoices.id, invoiceId), eq(invoices.organizationId, organizationId)),
    with: { customer: true, lines: true },
  });

  return invoice;
}
```

Notice the two calls (`invoices.customer` and `invoices.lines`) inside `with: {...}` — this is Drizzle's relational query API mentioned back in Part 3's reference section. For it to work, Drizzle needs to know these relationships exist, which we haven't told it yet. Let's fix that now.

**`src/db/schema.ts`** (add this relations block at the very bottom of the file)
```typescript
import { relations } from "drizzle-orm";

export const invoicesRelations = relations(invoices, ({ one, many }) => ({
  customer: one(customers, {
    fields: [invoices.customerId],
    references: [customers.id],
  }),
  lines: many(invoiceLines),
}));

export const invoiceLinesRelations = relations(invoiceLines, ({ one }) => ({
  invoice: one(invoices, {
    fields: [invoiceLines.invoiceId],
    references: [invoices.id],
  }),
}));
```

Also add `import { relations } from "drizzle-orm";` to the top import block alongside the other `drizzle-orm/pg-core` imports (it comes from the base `drizzle-orm` package, not `pg-core`).

### The Verification

Save all files. Confirm no TypeScript errors — this is a dense step, so check carefully: `dbTransactional.transaction` must be called with an `async (tx) => {...}` callback, and `postJournalEntry(...)`'s second argument must be `tx`, not `dbTransactional`.

We'll fully test this once the invoice creation form exists — next step.

---

## Step 7.9 — Building the Invoice Creation Form (Multi-Line-Item)

### The Target
Build `/invoices/new`, a page with a dynamic form letting a user add multiple line items before submitting.

### The Concept
This needs real client-side interactivity — adding and removing line item rows dynamically — which is exactly what a **Client Component** with React state is for. Unlike Steps 7.3–7.5's simple single-purpose forms, this one calls our server action directly with a plain function call (not a `<form action={...}>` binding), since we need to first assemble a structured array of line items from multiple dynamic rows before submitting.

### The Implementation

**`src/components/invoice-form.tsx`**
```tsx
"use client";

import { useState } from "react";
import { createInvoice, type InvoiceLineInput } from "@/lib/actions/invoices";

type Customer = { id: string; name: string };

export function InvoiceForm({ customers }: { customers: Customer[] }) {
  const [customerId, setCustomerId] = useState(customers[0]?.id ?? "");
  const [issueDate, setIssueDate] = useState(
    new Date().toISOString().split("T")[0]
  );
  const [dueDate, setDueDate] = useState(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  );
  const [lines, setLines] = useState<InvoiceLineInput[]>([
    { description: "", quantity: 1, unitPrice: 0, gstRate: 9 },
  ]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function updateLine(index: number, patch: Partial<InvoiceLineInput>) {
    setLines((prev) =>
      prev.map((line, i) => (i === index ? { ...line, ...patch } : line))
    );
  }

  function addLine() {
    setLines((prev) => [
      ...prev,
      { description: "", quantity: 1, unitPrice: 0, gstRate: 9 },
    ]);
  }

  function removeLine(index: number) {
    setLines((prev) => prev.filter((_, i) => i !== index));
  }

  // Live-computed totals, purely for on-screen preview before submission —
  // the REAL, authoritative calculation happens again on the server inside
  // createInvoice, since client-side numbers can never be trusted as the
  // final source of truth for money.
  const subtotal = lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0);
  const gstTotal = lines.reduce(
    (sum, l) => sum + l.quantity * l.unitPrice * (l.gstRate / 100),
    0
  );
  const total = subtotal + gstTotal;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    if (!customerId) {
      setError("Please select a customer.");
      return;
    }
    if (lines.some((l) => !l.description.trim() || l.unitPrice <= 0)) {
      setError("Every line needs a description and a unit price greater than zero.");
      return;
    }

    setSubmitting(true);
    try {
      await createInvoice({ customerId, issueDate, dueDate, lines });
      // createInvoice ends with redirect(), which throws a special
      // Next.js redirect signal internally — so if we reach code after
      // this line, something unexpected happened.
    } catch (err) {
      // Next.js's redirect() intentionally throws to interrupt execution;
      // we only want to show an error for GENUINE failures, so we check
      // the error isn't Next's internal redirect signal before displaying it.
      const message = (err as Error)?.message ?? "";
      if (!message.includes("NEXT_REDIRECT")) {
        setError(message || "Failed to create invoice.");
        setSubmitting(false);
      }
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4 rounded-lg border border-gray-200 bg-white p-6">
      <div className="grid grid-cols-3 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-700">Customer</label>
          <select
            value={customerId}
            onChange={(e) => setCustomerId(e.target.value)}
            className="mt-1 w-full rounded border border-gray-300 px-3 py-2 text-sm"
          >
            {customers.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
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
                className="col-span-5 rounded border border-gray-300 px-2 py-1 text-sm"
              />
              <input
                type="number"
                min="0"
                step="0.01"
                placeholder="Qty"
                value={line.quantity}
                onChange={(e) =>
                  updateLine(index, { quantity: parseFloat(e.target.value) || 0 })
                }
                className="col-span-2 rounded border border-gray-300 px-2 py-1 text-sm"
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
                className="col-span-2 rounded border border-gray-300 px-2 py-1 text-sm"
              >
                <option value={9}>9% GST</option>
                <option value={0}>0% (Zero-rated)</option>
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
        {submitting ? "Creating Invoice..." : "Create & Send Invoice"}
      </button>
    </form>
  );
}
```

**`src/app/invoices/new/page.tsx`**
```tsx
import { getCustomers } from "@/lib/actions/customers";
import { InvoiceForm } from "@/components/invoice-form";
import { redirect } from "next/navigation";

export default async function NewInvoicePage() {
  const customers = await getCustomers();

  if (customers.length === 0) {
    // Can't invoice anyone without at least one customer on file — send
    // the user to create one first, with a clear reason why.
    redirect("/customers?reason=need-customer-for-invoice");
  }

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-2xl font-bold text-gray-900">New Invoice</h1>
        <div className="mt-6">
          <InvoiceForm customers={customers} />
        </div>
      </div>
    </div>
  );
}
```

### The Verification

First, make sure you have at least one customer created (from Step 7.5). Visit `http://localhost:3000/invoices/new`. Fill in:
- Customer: your test customer
- Issue date / due date: leave defaults
- Line 1: description "Consulting services", quantity 10, unit price 100, GST 9%

Confirm the live preview at the bottom shows: Subtotal $1,000.00, GST $90.00, Total $1,090.00 — exactly matching Part 4's worked example.

Click **Add line item**, add a second line: description "Exported goods resale", quantity 1, unit price 200, GST 0%. Confirm the preview updates to: Subtotal $1,200.00, GST $90.00 (unchanged, since the second line is zero-rated), Total $1,290.00.

Click **Create & Send Invoice**. You should be redirected to `/invoices/[id]` — which doesn't exist as a page yet, so you'll see a 404. **This is expected** — it confirms the server action ran successfully and attempted its redirect. We'll build the detail page in the next step.

Now verify the real database state. Run `npm run db:studio`:
- Open `invoices` — confirm one row exists, with `subtotal = 1200.00`, `gst_total = 90.00`, `total = 1290.00`, `status = sent`, and a non-null `journal_entry_id`.
- Open `invoice_lines` — confirm two rows exist, correctly linked to that invoice, with the right quantities, unit prices, and GST rates.
- Open `journal_entries` — confirm one new entry exists with description `"Invoice INV-..."` and `source_type = invoice`.
- Open `journal_lines` — confirm **three** lines exist for that entry: a debit of `1290.00` to Accounts Receivable, a credit of `1200.00` to Sales Revenue, and a credit of `90.00` to GST Output Tax Payable. Confirm debits (1290.00) equal credits (1200.00 + 90.00 = 1290.00). ✅

---

## Step 7.10 — Building the Invoice List and Detail Pages

### The Target
Create `/invoices` (a list) and `/invoices/[id]` (a detail view), so invoices are actually visible and usable, not just verifiable in Drizzle Studio.

### The Implementation

**`src/app/invoices/page.tsx`**
```tsx
import { getInvoices } from "@/lib/actions/invoices";
import Link from "next/link";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

const STATUS_COLORS: Record<string, string> = {
  draft: "bg-gray-100 text-gray-600",
  sent: "bg-blue-100 text-blue-800",
  partially_paid: "bg-yellow-100 text-yellow-800",
  paid: "bg-green-100 text-green-800",
  overdue: "bg-red-100 text-red-800",
  void: "bg-gray-100 text-gray-400 line-through",
};

export default async function InvoicesPage() {
  const invoiceList = await getInvoices();

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-4xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Invoices</h1>
          <div className="flex items-center gap-4">
            <Link
              href="/invoices/new"
              className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white"
            >
              + New Invoice
            </Link>
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100 text-gray-600">
              <tr>
                <th className="px-4 py-2 font-medium">Invoice #</th>
                <th className="px-4 py-2 font-medium">Customer</th>
                <th className="px-4 py-2 font-medium">Issue Date</th>
                <th className="px-4 py-2 font-medium">Due Date</th>
                <th className="px-4 py-2 font-medium">Total</th>
                <th className="px-4 py-2 font-medium">Status</th>
              </tr>
            </thead>
            <tbody>
              {invoiceList.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-4 py-6 text-center text-gray-400">
                    No invoices yet.
                  </td>
                </tr>
              )}
              {invoiceList.map((inv) => (
                <tr key={inv.id} className="border-t border-gray-100">
                  <td className="px-4 py-2">
                    <Link
                      href={`/invoices/${inv.id}`}
                      className="text-blue-600 hover:underline"
                    >
                      {inv.invoiceNumber}
                    </Link>
                  </td>
                  <td className="px-4 py-2 text-gray-900">{inv.customer.name}</td>
                  <td className="px-4 py-2 text-gray-500">{inv.issueDate}</td>
                  <td className="px-4 py-2 text-gray-500">{inv.dueDate}</td>
                  <td className="px-4 py-2 text-gray-900">${inv.total}</td>
                  <td className="px-4 py-2">
                    <span
                      className={`rounded-full px-2 py-0.5 text-xs ${STATUS_COLORS[inv.status]}`}
                    >
                      {inv.status.replace("_", " ")}
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

**`src/app/invoices/[id]/page.tsx`**
```tsx
import { getInvoiceById } from "@/lib/actions/invoices";
import { notFound } from "next/navigation";

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
          </div>
        </div>
      </div>
    </div>
  );
}
```

### The Verification

Visit `http://localhost:3000/invoices`. Confirm your test invoice from Step 7.9 appears in the list, showing the correct invoice number, customer name, dates, total ($1,290.00), and a "sent" status badge. Click the invoice number link — you should land on `/invoices/[id]` and see the full detail view: both line items with correct quantities, unit prices, GST rates, and line totals, plus the subtotal/GST/total/amount paid summary matching exactly what you saw in the creation form's live preview.

Click **+ New Invoice** from the list page and create a second test invoice for the same or a different customer, this time with a single line item, quantity 1, unit price 500, GST 9% (Subtotal $500.00, GST $45.00, Total $545.00). Confirm it appears correctly in both the list and detail pages, and cross-check in Drizzle Studio that its journal entry also balances (debit AR $545.00 = credit Revenue $500.00 + credit GST Output Tax $45.00).

---

## Step 7.11 — Sixth Git Commit

### The Target
Save the completed customers, vendors, and invoicing feature as a new checkpoint.

### The Implementation

```bash
git add .
git commit -m "Add customers, vendors, and GST-aware invoicing wired into the journal engine"
```

### The Verification

```bash
git log --oneline
```

Expected output, six lines, newest first — confirming this and all five prior checkpoints remain intact.

---

## ✅ Checkpoint — Part 7

At this point, you should have:

- [x] `customers` and `vendors` tables, each with full CRUD via Server Actions and a "soft delete" (deactivate) pattern
- [x] Working `/customers` and `/vendors` pages with inline add forms
- [x] `invoices` and `invoice_lines` tables, including a `status` enum, denormalized totals, and a `journalEntryId` link back to the ledger
- [x] `postJournalEntry` upgraded to optionally participate in an existing, caller-provided transaction
- [x] `createInvoice` — a single server action that atomically saves an invoice header, its line items, and a correctly balanced, GST-aware journal entry (debit AR, credit Revenue, credit GST Output Tax when applicable)
- [x] A working multi-line-item invoice creation form with live client-side total previews
- [x] Working `/invoices` list and `/invoices/[id]` detail pages
- [x] Hands-on, Drizzle-Studio-verified proof that a real invoice produces a real, balanced journal entry
- [x] A sixth Git commit checkpoint

---

## 📚 Reference Section: Server Actions, Nested Transactions, and Denormalization

*(A standalone reference — read now or return later.)*

**Why does `createInvoice` call `dbTransactional.transaction()` directly instead of just calling `postJournalEntry()` and trusting it to handle everything?**
Because `postJournalEntry` only knows about *its own* three inserts (the journal entry and its lines) — it has no awareness of the invoice header or invoice lines being inserted alongside it. If we let each piece run in its own separate transaction, it would be possible (however unlikely) for the invoice to save successfully while the journal posting failed afterward, leaving an invoice with no ledger entry behind it — exactly the dangerous inconsistency described in Step 7.8. By opening one transaction in `createInvoice` and handing its `tx` down into `postJournalEntry`, every insert across both concerns becomes one indivisible unit.

**Why did we design `postJournalEntry` to detect "am I the top-level caller or a nested one" via `executor === dbTransactional`?**
This lets the exact same function serve two different calling patterns without duplicating any of its validation logic: standalone use (Part 6's tests, or any future simple "post a manual journal entry" feature) and nested use (this part's invoice creation, and every future feature — bills in Part 8, bank imports in Part 12 — that needs to combine its own inserts with a journal posting in one atomic operation). This is a common and valuable pattern once your codebase has more than one function that needs transactional composition.

**Why store `subtotal`, `gstTotal`, and `total` directly on the `invoices` row instead of always calculating them live from `invoice_lines`?**
This is called **denormalization** — deliberately storing a value that could technically be derived from other data, purely for read performance and simplicity. The `/invoices` list page, for example, needs to show a total for potentially hundreds of invoices at once; recalculating a sum-of-lines join for every single row on every single page load doesn't scale as well as simply reading one pre-computed column. The tradeoff, and the reason this pattern requires discipline, is that these stored values must always be kept perfectly in sync with the underlying lines — which is why `createInvoice` computes and writes both the lines *and* the header totals inside the very same transaction, guaranteeing they can never drift apart.

**Why generate `invoiceNumber` from `Date.now()` instead of a proper sequential counter (INV-0001, INV-0002...)?**
A true sequential counter requires either a database-level auto-incrementing sequence scoped per organization (more setup complexity than warranted at this stage of a beginner course) or careful locking to avoid two simultaneous invoice creations claiming the same number (a race condition). A timestamp-based number is guaranteed unique with zero extra infrastructure, which is the right tradeoff for this course. Part 14's roadmap is a natural place to explore a proper per-organization sequential numbering scheme as a future enhancement.

**Why does the invoice form calculate totals live in the browser, if the server recalculates everything anyway?**
Purely for user experience — instant visual feedback as someone types, with zero network round-trip delay. The comment in the code is deliberate and important: the client-side total is a *preview only*, and `createInvoice` on the server always independently recalculates every cent from the raw `quantity`/`unitPrice`/`gstRate` values submitted, never trusting any total the browser might have sent. This is the same "don't trust the caller" principle from Part 6's reference section, applied to user input specifically.

---

## 🔧 Troubleshooting — Part 7

**"`createInvoice` throws 'Required accounts... are missing from this organization's Chart of Accounts.'"**
This means the active organization wasn't seeded via Part 5's `seedDefaultChartOfAccounts` — switch to a properly seeded test organization, or revisit Part 5, Step 5.6's backfill instructions.

**"The invoice detail page 404s even though I can see the invoice in Drizzle Studio."**
Check that `getInvoiceById` is being called with the exact invoice UUID from the URL, and confirm the invoice's `organizationId` matches your *currently active* Clerk organization — switching organizations between creating and viewing an invoice will correctly 404, since invoices are strictly scoped per company.

**"TypeScript complains about `invoice.customer` or `invoice.lines` not existing on the invoice object."**
This means the `relations()` block from Step 7.8 either wasn't added, or `import { relations } from "drizzle-orm";` is missing from the top of `schema.ts`. Double-check both, save, and restart the TypeScript server in VS Code if the error persists (Command Palette → "TypeScript: Restart TS Server").

**"The live total preview in the invoice form shows `NaN`."**
This happens if `quantity` or `unitPrice` is an empty string rather than a number when multiplied. Check that `updateLine` always uses `parseFloat(e.target.value) || 0` (as shown in Step 7.9) rather than passing the raw string value through directly.

**"After submitting the invoice form, nothing happens and no error appears."**
Open your browser's developer console (F12) — since `createInvoice` ends with a `redirect()` call that Next.js implements by intentionally throwing a special internal signal, our `catch` block specifically checks for and ignores `"NEXT_REDIRECT"` in the error message; if a *different* real error is being silently swallowed, double-check that filtering logic matches exactly as written in Step 7.9, and temporarily log `err` to the console to inspect it directly.

**"Drizzle Studio shows the invoice and its lines, but zero rows in `journal_entries` for it."**
This should be structurally impossible given the transaction wrapping in Step 7.8 — if you see this, it strongly suggests `postJournalEntry`'s second argument wasn't passed as `tx`, meaning it silently opened its own separate transaction instead of joining the outer one. Re-check the exact call site in `createInvoice` against Step 7.8's code.
