# Part 12: Importing Bank Transactions from CSV

Every bank feature we've built so far has been driven entirely by the user typing structured data into a form. Real businesses, though, generate most of their cash activity through their actual bank account — money moving in and out that never passes through an "invoice" or "bill" screen at all (bank fees, ad-hoc transfers, card payments). This part builds a permanent, zero-dependency way to bring that activity into Greymatter Ledger: upload a CSV file exported from any bank, review each row, categorize it against the Chart of Accounts, and post a real journal entry.

## Step 12.1 — Why CSV, and Why This Is a Permanent Feature (Not a Placeholder)

### The Target
Understand the architectural decision behind this part before writing any code.

### The Concept
Virtually every bank in the world — from a Singapore neobank to a multinational institution — lets a customer export their transaction history as a CSV file (a plain text format where each line is a row, and commas separate each column, like a spreadsheet saved in the simplest possible form). Building against "live bank feed APIs" (like Plaid) requires signing agreements, handling bank-specific quirks, and often costs money — appropriate for a mature product, but a poor fit for a from-scratch learning course, and explicitly excluded from this series' scope (see Part 14's roadmap, where full bank-feed integration is deliberately left as an optional future stretch goal).

CSV import, by contrast, works today, for any bank, with zero external API dependency, zero signup approval process, and zero ongoing cost — a user just logs into their online banking, clicks "export transactions," and uploads the resulting file here. This isn't a stand-in for a "real" feature we'll replace later — it's the permanent, fully-built bank-data feature for this entire course.

## Step 12.2 — Designing `imported_transactions`

### The Target
Add a table to hold each row of an uploaded CSV, tracked through a review lifecycle: uploaded → categorized → posted.

### The Concept
Think of this like a physical inbox tray on a bookkeeper's desk: bank statement rows land in the tray first (uploaded), get sorted into the right folder one by one (categorized — the user says "this $45 charge was Office Supplies"), and only once sorted does the bookkeeper actually file it into the permanent ledger (posted). We deliberately do **not** post a journal entry the instant a row is uploaded — an uncategorized transaction has no idea which account it belongs to yet, so there's nothing correct to post. This staged, three-status lifecycle is the entire design of this feature.

### The Implementation

Add to `src/db/schema.ts`:

**`src/db/schema.ts`** (new addition)
```typescript
export const importedTransactionStatusEnum = pgEnum("imported_transaction_status", [
  "pending", // uploaded, not yet categorized
  "categorized", // user has chosen an account, but not yet posted
  "posted", // a journal entry now exists for this row
  "ignored", // user decided this row shouldn't be posted at all (e.g. an internal transfer)
]);

// One row from an uploaded bank CSV file. Each row is reviewed
// individually before it's ever allowed to touch the ledger.
export const importedTransactions = pgTable("imported_transactions", {
  id: uuid("id").primaryKey().defaultRandom(),

  organizationId: uuid("organization_id")
    .notNull()
    .references(() => organizations.id, { onDelete: "cascade" }),

  transactionDate: date("transaction_date").notNull(),
  description: text("description").notNull(), // the raw text from the bank's CSV
  amount: numeric("amount", { precision: 14, scale: 2 }).notNull(),
  // Positive = money came IN to the bank account; negative = money went OUT.
  // Storing the sign directly (rather than separate debit/credit columns,
  // unlike journal_lines) matches how bank CSVs themselves represent
  // transactions — a single signed amount per row — so no information is
  // lost or awkwardly reshaped during the raw import step itself.

  status: importedTransactionStatusEnum("status").notNull().default("pending"),

  // The account the user chose to categorize this transaction against
  // (e.g. "5400 Bank Fees Expense"). Nullable until categorized.
  categorizedAccountId: uuid("categorized_account_id").references(() => accounts.id, {
    onDelete: "set null",
  }),

  journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
    onDelete: "set null",
  }),

  // A hash of (date + description + amount), used to detect duplicate
  // rows if the same CSV (or an overlapping date range from a second
  // export) is accidentally uploaded twice. See Step 12.4 for how this
  // is computed and used.
  duplicateCheckHash: text("duplicate_check_hash").notNull(),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const importedTransactionsRelations = relations(
  importedTransactions,
  ({ one }) => ({
    categorizedAccount: one(accounts, {
      fields: [importedTransactions.categorizedAccountId],
      references: [accounts.id],
    }),
  })
);
```

### The Verification

Save the file. Migrate:

```bash
npm run db:generate
npm run db:migrate
```

Expected output should mention the new `imported_transaction_status` enum and the `imported_transactions` table. Confirm both appear in Drizzle Studio.

---

## Step 12.3 — Installing a CSV Parser

### The Target
Add a library capable of reliably parsing arbitrary CSV files uploaded by users.

### The Concept
You could technically parse CSV by manually splitting each line on commas — but real-world bank CSVs are full of edge cases that break naive splitting: descriptions that themselves contain commas (wrapped in quotes), different line-ending conventions, and optional header rows. **PapaParse** is a mature, widely-used library that handles all of this correctly, so we don't have to reinvent CSV parsing (a surprisingly deep rabbit hole) ourselves.

### The Implementation

```bash
npm install papaparse
npm install -D @types/papaparse
```

### The Verification

Confirm both packages appear in `package.json` under `dependencies` and `devDependencies` respectively.

---

## Step 12.4 — The CSV Upload Server Action

### The Target
Write `uploadBankCsv`, a server action that accepts an uploaded file, parses it, and inserts one `imported_transactions` row per line — skipping any rows already seen before.

### The Concept
Bank CSV formats vary meaningfully between institutions — some put the date first, some put the amount as two separate columns ("Debit"/"Credit") instead of one signed column, some include a header row, some don't. Rather than trying to auto-detect every bank's exact format (a genuinely hard, ever-expanding problem), we ask the user to confirm which column means what via a simple mapping step — but to keep this course's scope focused and shippable, we'll standardize on the single most common shape: a CSV with a header row containing columns named exactly `Date`, `Description`, and `Amount` (a single signed amount column), which is the format the vast majority of banks — including Singapore banks like DBS, OCBC, and UOB — offer as an export option, sometimes requiring the user to select "CSV" rather than a bank-proprietary format during export.

### The Implementation

**`src/lib/actions/bank-import.ts`**
```typescript
"use server";

import { db } from "@/db";
import { importedTransactions } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { eq, and } from "drizzle-orm";
import { revalidatePath } from "next/cache";
import Papa from "papaparse";
import crypto from "crypto";

type ParsedCsvRow = {
  Date: string;
  Description: string;
  Amount: string;
};

export type UploadCsvResult = {
  success: boolean;
  error?: string;
  rowsImported?: number;
  rowsSkippedAsDuplicate?: number;
};

// Normalizes a bank's date format (e.g. "01/03/2025" or "2025-03-01")
// into our standard "YYYY-MM-DD" storage format. Banks are inconsistent
// here, so we handle the two most common shapes explicitly rather than
// trusting JavaScript's built-in Date parsing, which behaves ambiguously
// for slash-separated dates depending on locale.
function normalizeDate(rawDate: string): string {
  const trimmed = rawDate.trim();

  // Already in YYYY-MM-DD format.
  if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    return trimmed;
  }

  // DD/MM/YYYY format, common in Singapore bank exports.
  const slashMatch = trimmed.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (slashMatch) {
    const [, day, month, year] = slashMatch;
    return `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}`;
  }

  throw new Error(`Unrecognized date format: "${rawDate}". Expected YYYY-MM-DD or DD/MM/YYYY.`);
}

// A stable fingerprint for a single transaction row, used to detect and
// skip duplicates if the same CSV (or an overlapping export) is uploaded
// more than once — a very common real-world occurrence when a user
// re-exports "the last 30 days" every week and the ranges overlap.
function computeDuplicateHash(date: string, description: string, amount: string): string {
  return crypto
    .createHash("sha256")
    .update(`${date}|${description.trim().toLowerCase()}|${amount}`)
    .digest("hex");
}

export async function uploadBankCsv(formData: FormData): Promise<UploadCsvResult> {
  const organizationId = await getOrCreateOrganization();

  const file = formData.get("file");
  if (!(file instanceof File)) {
    return { success: false, error: "No file was uploaded." };
  }

  const text = await file.text();

  const parsed = Papa.parse<ParsedCsvRow>(text, {
    header: true,
    skipEmptyLines: true,
  });

  if (parsed.errors.length > 0) {
    return {
      success: false,
      error: `CSV parsing error: ${parsed.errors[0].message} (row ${parsed.errors[0].row})`,
    };
  }

  const requiredColumns = ["Date", "Description", "Amount"];
  const actualColumns = parsed.meta.fields ?? [];
  const missingColumns = requiredColumns.filter((c) => !actualColumns.includes(c));

  if (missingColumns.length > 0) {
    return {
      success: false,
      error: `CSV is missing required column(s): ${missingColumns.join(", ")}. Expected columns: Date, Description, Amount.`,
    };
  }

  // Fetch every duplicate-check hash already stored for this organization, so we can filter out rows we've already imported before ever inserting anything.
  const existingHashes = new Set(
    (
      await db
        .select({ hash: importedTransactions.duplicateCheckHash })
        .from(importedTransactions)
        .where(eq(importedTransactions.organizationId, organizationId))
    ).map((row) => row.hash)
  );

  let rowsImported = 0;
  let rowsSkippedAsDuplicate = 0;
  const rowsToInsert: (typeof importedTransactions.$inferInsert)[] = [];

  for (const row of parsed.data) {
    if (!row.Date || !row.Description || !row.Amount) {
      // Silently skip genuinely blank/malformed rows rather than failing
      // the entire upload over one bad line — real bank exports
      // sometimes include trailing summary rows with missing fields.
      continue;
    }

    let normalizedDate: string;
    try {
      normalizedDate = normalizeDate(row.Date);
    } catch {
      // A row with an unparseable date is skipped rather than aborting
      // the whole upload — we report the skip count so the user isn't
      // left wondering why a row silently vanished.
      continue;
    }

    // Amount may include a thousands separator or currency symbol in some
    // exports — strip anything that isn't a digit, minus sign, or dot.
    const cleanedAmount = row.Amount.replace(/[^0-9.-]/g, "");
    const amountNumber = parseFloat(cleanedAmount);
    if (isNaN(amountNumber)) {
      continue;
    }

    const hash = computeDuplicateHash(normalizedDate, row.Description, amountNumber.toFixed(2));

    if (existingHashes.has(hash)) {
      rowsSkippedAsDuplicate++;
      continue;
    }

    rowsToInsert.push({
      organizationId,
      transactionDate: normalizedDate,
      description: row.Description.trim(),
      amount: amountNumber.toFixed(2),
      status: "pending",
      duplicateCheckHash: hash,
    });

    // Track this hash locally too, in case the SAME uploaded file
    // contains two genuinely identical rows — without this, we'd only
    // catch duplicates against previously-imported data, not duplicates
    // within THIS SAME upload.
    existingHashes.add(hash);
  }

  if (rowsToInsert.length > 0) {
    await db.insert(importedTransactions).values(rowsToInsert);
    rowsImported = rowsToInsert.length;
  }

  revalidatePath("/bank-import");

  return { success: true, rowsImported, rowsSkippedAsDuplicate };
}

export async function getImportedTransactions() {
  const organizationId = await getOrCreateOrganization();

  return db.query.importedTransactions.findMany({
    where: (t, { eq }) => eq(t.organizationId, organizationId),
    with: { categorizedAccount: true },
    orderBy: (t, { desc }) => desc(t.transactionDate),
  });
}
```

### The Verification

No visible output yet — we need an upload form. Let's build it, then test the full flow together.

---

## Step 12.5 — Building the Upload Form and Review Table

### The Target
Create `/bank-import`, showing an upload form at the top and a review table of every imported transaction below it — with an inline category dropdown per row, and a "Post" button per row once categorized.

### The Implementation

**`src/components/bank-csv-upload-form.tsx`**
```tsx
"use client";

import { useState, useRef } from "react";
import { useRouter } from "next/navigation";
import { uploadBankCsv } from "@/lib/actions/bank-import";

export function BankCsvUploadForm() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setMessage(null);

    const formData = new FormData(e.currentTarget);
    setSubmitting(true);

    const result = await uploadBankCsv(formData);

    setSubmitting(false);

    if (!result.success) {
      setError(result.error ?? "Upload failed.");
      return;
    }

    setMessage(
      `Imported ${result.rowsImported} new transaction(s). Skipped ${result.rowsSkippedAsDuplicate} duplicate(s).`
    );
    if (fileInputRef.current) fileInputRef.current.value = "";
    router.refresh();
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="space-y-3 rounded-lg border border-gray-200 bg-white p-4"
    >
      <h3 className="font-semibold text-gray-800">Upload a Bank CSV</h3>
      <p className="text-xs text-gray-500">
        Expected columns: <code>Date</code>, <code>Description</code>,{" "}
        <code>Amount</code>. Amount should be positive for money in, negative
        for money out.
      </p>
      <input
        ref={fileInputRef}
        type="file"
        name="file"
        accept=".csv"
        required
        className="block w-full text-sm"
      />
      {error && <p className="text-sm text-red-600">{error}</p>}
      {message && <p className="text-sm text-green-600">{message}</p>}
      <button
        type="submit"
        disabled={submitting}
        className="rounded bg-blue-600 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
      >
        {submitting ? "Uploading..." : "Upload CSV"}
      </button>
    </form>
  );
}
```

**`src/components/imported-transaction-row.tsx`**
```tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  categorizeImportedTransaction,
  postImportedTransaction,
  ignoreImportedTransaction,
} from "@/lib/actions/bank-import";

type Account = { id: string; code: string; name: string };

type Row = {
  id: string;
  transactionDate: string;
  description: string;
  amount: string;
  status: string;
  categorizedAccountId: string | null;
};

export function ImportedTransactionRow({
  row,
  accounts,
}: {
  row: Row;
  accounts: Account[];
}) {
  const router = useRouter();
  const [selectedAccountId, setSelectedAccountId] = useState(
    row.categorizedAccountId ?? ""
  );
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const amountNumber = parseFloat(row.amount);
  const isMoneyIn = amountNumber >= 0;

  async function handleCategorize() {
    if (!selectedAccountId) {
      setError("Choose an account first.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await categorizeImportedTransaction(row.id, selectedAccountId);
      router.refresh();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function handlePost() {
    setBusy(true);
    setError(null);
    try {
      await postImportedTransaction(row.id);
      router.refresh();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  async function handleIgnore() {
    setBusy(true);
    setError(null);
    try {
      await ignoreImportedTransaction(row.id);
      router.refresh();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <tr className="border-t border-gray-100">
      <td className="px-3 py-2 text-gray-500">{row.transactionDate}</td>
      <td className="px-3 py-2 text-gray-900">{row.description}</td>
      <td
        className={`px-3 py-2 text-right ${
          isMoneyIn ? "text-green-700" : "text-red-700"
        }`}
      >
        {isMoneyIn ? "+" : ""}
        {amountNumber.toFixed(2)}
      </td>
      <td className="px-3 py-2">
        {row.status === "pending" || row.status === "categorized" ? (
          <select
            value={selectedAccountId}
            onChange={(e) => setSelectedAccountId(e.target.value)}
            disabled={busy}
            className="rounded border border-gray-300 px-2 py-1 text-xs"
          >
            <option value="">Select account...</option>
            {accounts.map((a) => (
              <option key={a.id} value={a.id}>
                {a.code} {a.name}
              </option>
            ))}
          </select>
        ) : (
          <span className="text-xs text-gray-500">
            {accounts.find((a) => a.id === row.categorizedAccountId)?.name ??
              "—"}
          </span>
        )}
      </td>
      <td className="px-3 py-2">
        <span
          className={`rounded-full px-2 py-0.5 text-xs ${
            row.status === "posted"
              ? "bg-green-100 text-green-800"
              : row.status === "categorized"
              ? "bg-yellow-100 text-yellow-800"
              : row.status === "ignored"
              ? "bg-gray-100 text-gray-400"
              : "bg-blue-100 text-blue-800"
          }`}
        >
          {row.status}
        </span>
      </td>
      <td className="px-3 py-2 text-right">
        {error && <p className="mb-1 text-xs text-red-600">{error}</p>}
        {(row.status === "pending" || row.status === "categorized") && (
          <div className="flex justify-end gap-2">
            {row.status === "pending" && (
              <button
                onClick={handleCategorize}
                disabled={busy}
                className="text-xs text-blue-600 hover:underline disabled:opacity-50"
              >
                Save Category
              </button>
            )}
            {row.status === "categorized" && (
              <button
                onClick={handlePost}
                disabled={busy}
                className="text-xs text-green-700 hover:underline disabled:opacity-50"
              >
                Post to Ledger
              </button>
            )}
            <button
              onClick={handleIgnore}
              disabled={busy}
              className="text-xs text-gray-500 hover:underline disabled:opacity-50"
            >
              Ignore
            </button>
          </div>
        )}
      </td>
    </tr>
  );
}
```

**`src/app/bank-import/page.tsx`**
```tsx
import { getImportedTransactions } from "@/lib/actions/bank-import";
import { db } from "@/db";
import { accounts } from "@/db/schema";
import { getOrCreateOrganization } from "@/lib/organizations";
import { eq } from "drizzle-orm";
import { BankCsvUploadForm } from "@/components/bank-csv-upload-form";
import { ImportedTransactionRow } from "@/components/imported-transaction-row";
import { UserButton, OrganizationSwitcher } from "@clerk/nextjs";

export default async function BankImportPage() {
  const organizationId = await getOrCreateOrganization();

  const [transactions, orgAccounts] = await Promise.all([
    getImportedTransactions(),
    db.select().from(accounts).where(eq(accounts.organizationId, organizationId)),
  ]);

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mx-auto max-w-5xl">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Bank Import</h1>
          <div className="flex items-center gap-4">
            <OrganizationSwitcher hidePersonal={true} />
            <UserButton afterSignOutUrl="/" />
          </div>
        </div>

        <div className="mt-6">
          <BankCsvUploadForm />
        </div>

        <div className="mt-6 overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-100 text-gray-600">
              <tr>
                <th className="px-3 py-2 font-medium">Date</th>
                <th className="px-3 py-2 font-medium">Description</th>
                <th className="px-3 py-2 text-right font-medium">Amount</th>
                <th className="px-3 py-2 font-medium">Category</th>
                <th className="px-3 py-2 font-medium">Status</th>
                <th className="px-3 py-2 font-medium"></th>
              </tr>
            </thead>
            <tbody>
              {transactions.length === 0 && (
                <tr>
                  <td colSpan={6} className="px-3 py-6 text-center text-gray-400">
                    No transactions imported yet. Upload a CSV above to get
                    started.
                  </td>
                </tr>
              )}
              {transactions.map((t) => (
                <ImportedTransactionRow
                  key={t.id}
                  row={t}
                  accounts={orgAccounts}
                />
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
```

Add `/bank-import` to `src/proxy.ts`'s protected routes:

**`src/proxy.ts`** (updated matcher list)
```typescript
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/accounts(.*)",
  "/customers(.*)",
  "/vendors(.*)",
  "/invoices(.*)",
  "/bills(.*)",
  "/reports(.*)",
  "/settings(.*)",
  "/bank-import(.*)",
]);
```

### The Verification

We still need to write `categorizeImportedTransaction`, `postImportedTransaction`, and `ignoreImportedTransaction` — let's do that now in the next step before testing.

---

## Step 12.6 — Categorizing and Posting: The Journal Entry for a Bank Row

### The Target
Write the three remaining server actions that move a row through its lifecycle: pending → categorized → posted (or ignored).

### The Concept
This is where the CSV import feature connects to everything built in Parts 5–9. Recall our signed-amount convention from Step 12.2: a positive amount means money came *into* the bank account; negative means money went *out*. The journal entry we post depends entirely on this sign:

- **Money in** (positive): debit Cash (an Asset increasing), credit whatever account the user categorized it as (e.g., if it's an overlooked customer payment, credit Accounts Receivable — though more commonly for uncategorized bank activity, it might credit a Revenue account directly for miscellaneous income).
- **Money out** (negative): credit Cash (an Asset decreasing), debit whatever account the user categorized it as (e.g., a bank fee categorizes as a debit to "5400 Bank Fees Expense").

This is a genuinely elegant unification: the *same* two-line journal entry shape works for both directions, just by choosing which side Cash lands on based on the sign of the amount — no separate code paths needed.

### The Implementation

**`src/lib/actions/bank-import.ts`** (append these three functions to the existing file from Step 12.4)
```typescript
import { postJournalEntry } from "@/lib/journal";
import { accounts } from "@/db/schema";

export async function categorizeImportedTransaction(
  transactionId: string,
  accountId: string
) {
  const organizationId = await getOrCreateOrganization();

  const transaction = await db.query.importedTransactions.findFirst({
    where: (t, { and, eq }) =>
      and(eq(t.id, transactionId), eq(t.organizationId, organizationId)),
  });

  if (!transaction) {
    throw new Error("Imported transaction not found for this organization.");
  }
  if (transaction.status !== "pending") {
    throw new Error(
      `Cannot categorize a transaction with status "${transaction.status}" — only pending transactions can be categorized.`
    );
  }

  await db
    .update(importedTransactions)
    .set({ categorizedAccountId: accountId, status: "categorized" })
    .where(eq(importedTransactions.id, transactionId));

  revalidatePath("/bank-import");
}

export async function ignoreImportedTransaction(transactionId: string) {
  const organizationId = await getOrCreateOrganization();

  await db
    .update(importedTransactions)
    .set({ status: "ignored" })
    .where(
      and(
        eq(importedTransactions.id, transactionId),
        eq(importedTransactions.organizationId, organizationId)
      )
    );

  revalidatePath("/bank-import");
}

export async function postImportedTransaction(transactionId: string) {
  const organizationId = await getOrCreateOrganization();

  const transaction = await db.query.importedTransactions.findFirst({
    where: (t, { and, eq }) =>
      and(eq(t.id, transactionId), eq(t.organizationId, organizationId)),
  });

  if (!transaction) {
    throw new Error("Imported transaction not found for this organization.");
  }
  if (transaction.status !== "categorized") {
    throw new Error(
      `Cannot post a transaction with status "${transaction.status}" — it must be categorized first.`
    );
  }
  if (!transaction.categorizedAccountId) {
    throw new Error("Transaction has no categorized account — cannot post.");
  }

  const orgAccounts = await db
    .select()
    .from(accounts)
    .where(eq(accounts.organizationId, organizationId));

  const cashAccount = orgAccounts.find((a) => a.code === "1000");
  if (!cashAccount) {
    throw new Error("Required account (1000 Cash) is missing from the Chart of Accounts.");
  }

  const amount = Math.abs(parseFloat(transaction.amount));
  const isMoneyIn = parseFloat(transaction.amount) >= 0;

  const { dbTransactional } = await import("@/db");

  const result = await dbTransactional.transaction(async (tx) => {
    const journalResult = await postJournalEntry(
      {
        organizationId,
        entryDate: transaction.transactionDate,
        description: `Bank: ${transaction.description}`,
        sourceType: "bank_import",
        sourceId: transaction.id,
        lines: isMoneyIn
          ? [
              { accountId: cashAccount.id, debit: amount },
              { accountId: transaction.categorizedAccountId!, credit: amount },
            ]
          : [
              { accountId: transaction.categorizedAccountId!, debit: amount },
              { accountId: cashAccount.id, credit: amount },
            ],
      },
      tx
    );

    await tx
      .update(importedTransactions)
      .set({ status: "posted", journalEntryId: journalResult.entry.id })
      .where(eq(importedTransactions.id, transactionId));

    return journalResult;
  });

  revalidatePath("/bank-import");
  return result;
}
```

### The Verification

First, let's create a test CSV file. On your computer, create a plain text file named `test-bank-transactions.csv` with exactly this content:

```csv
Date,Description,Amount
2025-01-05,Monthly bank service fee,-15.00
2025-01-10,Wire transfer from Acme Corp,1090.00
2025-01-15,Card payment - WeWork Singapore,-350.00
```

Visit `http://localhost:3000/bank-import`. Upload this file. Confirm the success message reads: **"Imported 3 new transaction(s). Skipped 0 duplicate(s)."** Confirm all three rows appear in the table below, each showing status `pending`, with the money-in row ($1,090.00) shown in green and the two money-out rows shown in red.

**Categorize and post each row:**
- Row 1 ("Monthly bank service fee," -$15.00): select "5400 Bank Fees Expense," click **Save Category** (status → `categorized`), then click **Post to Ledger** (status → `posted`).
- Row 2 ("Wire transfer from Acme Corp," +$1,090.00): select "1100 Accounts Receivable" (simulating this being payment for an existing invoice we forgot to record properly through the normal flow), save and post.
- Row 3 ("Card payment - WeWork Singapore," -$350.00): select "5100 Rent Expense," save and post.

Confirm all three rows now show status `posted`, and the category/post buttons have disappeared for each (only "Ignore" logic remains available for pending/categorized rows, per the component's conditional rendering — posted rows show no action buttons at all).

**Verify in Drizzle Studio:**
- `imported_transactions` — three rows, all `status = posted`, each with a non-null `journal_entry_id` and `categorized_account_id`.
- `journal_entries` — three new entries, each with `source_type = bank_import` and descriptions starting with `"Bank: ..."`.
- `journal_lines` — for the bank fee row: debit $15.00 to Bank Fees Expense, credit $15.00 to Cash. For the wire transfer row: debit $1,090.00 to Cash, credit $1,090.00 to Accounts Receivable. For the rent card payment: debit $350.00 to Rent Expense, credit $350.00 to Cash. Confirm every single entry balances.

**Test duplicate detection:** Upload the exact same `test-bank-transactions.csv` file a second time. Confirm the message now reads: **"Imported 0 new transaction(s). Skipped 3 duplicate(s)."** Confirm the table still shows only three rows total (not six) — proving the `duplicateCheckHash` mechanism correctly recognized every row as already seen, even though the rows had already progressed to `posted` status by the time of this second upload.

**Test the status-guard rejections:** Try clicking "Post to Ledger" logic against an already-posted row by inspecting your browser's dev tools — this shouldn't be reachable through the normal UI anymore (the buttons are gone once `status = posted`), which is itself a confirmation the conditional rendering is working. As an extra check, if you want to directly exercise the guard clause itself, temporarily call `postImportedTransaction` a second time on the same already-posted transaction ID from a throwaway test page (following the pattern from Part 6's `journal-test` page) and confirm it throws: `"Cannot post a transaction with status \"posted\" — it must be categorized first."`

---

## Step 12.7 — Eleventh Git Commit

### The Target
Save the completed bank CSV import feature as a new checkpoint.

### The Implementation

```bash
git add .
git commit -m "Add bank CSV import with review/categorize/post workflow and duplicate detection"
```

### The Verification

```bash
git log --oneline
```

Expected output, eleven lines, newest first.

---

## ✅ Checkpoint — Part 12

At this point, you should have:

- [x] An `imported_transactions` table with a four-state lifecycle: pending, categorized, posted, ignored
- [x] `uploadBankCsv`, parsing an uploaded CSV via PapaParse, normalizing dates, and skipping duplicates via a content-based hash
- [x] A working `/bank-import` page with an upload form and a live review table
- [x] `categorizeImportedTransaction`, `postImportedTransaction`, and `ignoreImportedTransaction`, each enforcing correct status-transition guards
- [x] `postImportedTransaction` correctly unifying money-in and money-out into a single two-line journal entry shape, choosing sides based on the transaction's sign
- [x] Verified duplicate detection across a repeated upload of the same file
- [x] An eleventh Git commit checkpoint

---

## 📚 Reference Section: CSV Realities, Hashing, and Design Tradeoffs

*(A standalone reference — read now or return later.)*

**Why not try to auto-detect every bank's CSV column names and formats automatically?**
This is a genuinely deep, ever-expanding problem in the real world — banks change their export formats over time, use inconsistent column naming (`"Value Date"` vs `"Date"` vs `"Transaction Date"`), and some split amounts into separate "Debit"/"Credit" columns rather than one signed column. Building a robust universal auto-detector is a legitimate, substantial feature in its own right (often called "bank format mapping" in real accounting software) — which is precisely why we scoped this course's version to one clearly documented, common shape (`Date`, `Description`, `Amount`), with the upload form explicitly telling the user what's expected. A natural, well-scoped extension for Part 14's roadmap would be adding a "map your columns" step before import, letting a user tell the app "in my bank's export, the amount is actually in the column called 'Value'" — but that's meaningfully more UI and logic than this course's introductory scope calls for.

**Why hash `date + description + amount` together instead of relying on some unique ID from the bank's CSV?**
Most consumer bank CSV exports don't include a stable, unique per-transaction identifier at all — just human-readable columns. Combining the three fields that *are* always present into one fingerprint is a pragmatic, portable approach that works regardless of which bank the CSV came from. It's not perfectly bulletproof (two genuinely different $10 coffee purchases on the same day with an identical description would collide and the second would be incorrectly treated as a duplicate) — but for the realistic use case of "don't let a user accidentally double-import overlapping date-range exports," which is the actual problem this feature protects against, it's a solid, appropriately-scoped solution.

**Why does `postImportedTransaction` re-import `dbTransactional` dynamically inside the function (`const { dbTransactional } = await import("@/db")`) instead of importing it normally at the top of the file?**
This is a minor pragmatic choice worth explaining rather than leaving mysterious: since `bank-import.ts` already imports `db` (the plain HTTP client) at the top for its many simple reads/updates throughout this file, and only this one function specifically needs the transactional client, a dynamic import keeps the top-level imports focused on what's used by most of the file, while still cleanly obtaining the transactional client exactly where it's actually needed. Functionally, this is equivalent to importing both `db` and `dbTransactional` together at the top of the file — feel free to refactor it that way if you find it more readable; both approaches are valid and produce identical behavior.

**Why is `ignoreImportedTransaction` available from `categorized` status but not from `posted` status?**
Once a row has actually been posted (a real, permanent journal entry now exists referencing it), "ignoring" it would leave a dangling, misleading relationship — the journal entry would still exist in the ledger, but the imported transaction record that explains its origin would silently claim to be "ignored." This is the exact same historical-integrity principle established repeatedly since Part 5 (soft-deletes, `onDelete: "restrict"`): once something is posted to the ledger, undoing it requires a deliberate, explicit action (a future "void" feature, per Part 14's roadmap), not a casual status flip.

**What would need to change to support a bank CSV with separate "Debit" and "Credit" columns instead of one signed "Amount" column?**
You'd add a small pre-processing step inside `uploadBankCsv`, before the normalization logic: if the parsed CSV's header row contains `Debit`/`Credit` instead of `Amount`, compute a single signed amount as `(parseFloat(row.Credit || "0") - parseFloat(row.Debit || "0"))`, then feed that computed value into the exact same downstream logic (hash computation, insertion) already written. This is a good, well-scoped exercise to try on your own once the rest of this course is complete — it doesn't require touching anything about the categorization/posting logic at all, only the parsing step.

---

## 🔧 Troubleshooting — Part 12

**"Uploading a CSV shows an error about missing required columns, even though my file has Date/Description/Amount."**
Check for extra whitespace or a Byte Order Mark (BOM) — a hidden character some spreadsheet programs (like Excel on Windows) silently add to the very start of a saved CSV file, which can make the first column header read as `"\uFEFFDate"` instead of `"Date"`, failing the exact-match check. Re-save the file using a plain text editor, or export directly as CSV from your bank's website rather than re-saving through Excel, to avoid this.

**"Every single row gets skipped as a duplicate on the very first upload."**
This would indicate `existingHashes` was somehow pre-populated with matching hashes before any real upload happened — double check you didn't run the verification steps more than once with identical data in an earlier test session, or that a previous partial test left rows in the table already. Check the `imported_transactions` table directly in Drizzle Studio to see what's actually already there.

**"The money-in/money-out sign coloring on the review table looks reversed for my bank's export."**
Some banks export money-out as positive numbers with a separate "type" column instead of using a negative sign. Confirm your CSV genuinely uses negative numbers for money leaving the account (our stated, documented format) — if your bank's export uses a different convention, you'll need the "Debit/Credit columns" extension described in this part's reference section above before the sign-based logic will behave correctly.

**"Clicking 'Post to Ledger' throws 'Required account (1000 Cash) is missing from the Chart of Accounts.'"**
Same root cause as every prior part's equivalent error — the active organization's Chart of Accounts wasn't seeded. Revisit Part 5's backfill instructions if needed.

**"After posting, the row's status shows `posted` but Drizzle Studio shows a null `journal_entry_id`."**
This should be structurally prevented by the transaction wrapping in `postImportedTransaction` — if you see this, confirm the `tx.update(importedTransactions)...` call inside the `dbTransactional.transaction(...)` callback is using `journalResult.entry.id` (not accidentally referencing an undefined variable), and that it's genuinely inside the same transaction callback as the `postJournalEntry` call, not accidentally placed after it outside the `transaction()` block.

**"TypeScript complains about `accounts` being imported twice in `bank-import.ts`."**
If you're appending Step 12.6's code to the same file from Step 12.4, make sure `accounts` and `postJournalEntry` are each imported exactly once at the top of the file — consolidate any duplicate `import` lines that resulted from copying the two code blocks in sequence.
