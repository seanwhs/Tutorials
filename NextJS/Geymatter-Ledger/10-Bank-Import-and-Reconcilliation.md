# Part 32 — Upload and Parse Bank CSV Files

In Phase 9, we added auditability and role-based access control.

Now we begin bank workflows.

Bank import is the first step toward reconciliation.

By the end of this part, you will have:

- Bank import database tables
- CSV parsing helpers
- Bank CSV upload page
- Server action for upload
- Parsed bank transaction rows saved to Postgres
- Bank import diagnostics
- Tests for CSV parsing
- Neon SQL verification

We will **not** categorize or post imported transactions yet.

That comes in later parts.

---

# 1. Understand Bank Import

## The Target

We are importing bank statement CSV files.

---

## The Concept

A bank statement contains real-world bank activity.

Example CSV:

```csv
date,description,amount
2026-01-05,Customer payment from Merlion Trading,109.00
2026-01-06,Cloud Hosting SG,-109.00
```

Positive amount:

```txt
Money came into the bank
```

Negative amount:

```txt
Money left the bank
```

Bank import lets us compare what the bank says happened with what our ledger says happened.

---

# 2. Add Bank Import Tables

## The Target

We are updating:

```txt
db/schema.ts
```

to add:

```txt
bank_imports
bank_transactions
```

---

## The Concept

A bank import is one uploaded file.

A bank transaction is one row parsed from that file.

---

## The Implementation

Open:

```txt
db/schema.ts
```

Add enum:

```ts
export const bankTransactionStatusEnum = pgEnum("bank_transaction_status", [
  "imported",
  "categorized",
  "posted",
  "reconciled",
  "ignored",
]);
```

Add tables:

```ts
export const bankImports = pgTable(
  "bank_imports",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    fileName: text("file_name").notNull(),

    rowCount: integer("row_count").default(0).notNull(),

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("bank_imports_organization_id_idx").on(table.organizationId),
  ],
);

export const bankTransactions = pgTable(
  "bank_transactions",
  {
    id: uuid("id").defaultRandom().primaryKey(),

    organizationId: uuid("organization_id")
      .notNull()
      .references(() => organizations.id, { onDelete: "cascade" }),

    bankImportId: uuid("bank_import_id")
      .notNull()
      .references(() => bankImports.id, { onDelete: "cascade" }),

    transactionDate: date("transaction_date").notNull(),

    description: text("description").notNull(),

    amountCents: bigint("amount_cents", { mode: "number" }).notNull(),

    status: bankTransactionStatusEnum("status").default("imported").notNull(),

    journalEntryId: uuid("journal_entry_id").references(() => journalEntries.id, {
      onDelete: "set null",
    }),

    createdAt: timestamp("created_at", { withTimezone: true })
      .defaultNow()
      .notNull(),
  },
  (table) => [
    index("bank_transactions_organization_id_idx").on(table.organizationId),
    index("bank_transactions_organization_id_status_idx").on(
      table.organizationId,
      table.status,
    ),
    index("bank_transactions_bank_import_id_idx").on(table.bankImportId),
  ],
);
```

Add types:

```ts
export type BankImport = typeof bankImports.$inferSelect;
export type NewBankImport = typeof bankImports.$inferInsert;

export type BankTransaction = typeof bankTransactions.$inferSelect;
export type NewBankTransaction = typeof bankTransactions.$inferInsert;
```

---

## The Verification

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

Verify:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

You should see:

```txt
bank_imports
bank_transactions
```

---

# 3. Create CSV Parsing Helper

## The Target

We are creating:

```txt
lib/bank/parse-bank-csv.ts
```

---

## The Concept

We will support a simple CSV format:

```csv
date,description,amount
2026-01-05,Customer payment,109.00
2026-01-06,Vendor payment,-25.50
```

We will parse:

```txt
date -> YYYY-MM-DD
description -> text
amount -> cents
```

---

## The Implementation

Create:

```bash
mkdir -p lib/bank
```

Create:

```txt
lib/bank/parse-bank-csv.ts
```

Add:

```ts
// lib/bank/parse-bank-csv.ts

import { dollarsToCents } from "@/lib/money";
import { isValidReportDate } from "@/lib/reports/date-range";

export type ParsedBankCsvRow = {
  transactionDate: string;
  description: string;
  amountCents: number;
};

export type ParseBankCsvResult =
  | {
      ok: true;
      rows: ParsedBankCsvRow[];
    }
  | {
      ok: false;
      errors: string[];
    };

function splitCsvLine(line: string): string[] {
  const values: string[] = [];
  let current = "";
  let insideQuotes = false;

  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];

    if (character === '"') {
      insideQuotes = !insideQuotes;
      continue;
    }

    if (character === "," && !insideQuotes) {
      values.push(current.trim());
      current = "";
      continue;
    }

    current += character;
  }

  values.push(current.trim());

  return values;
}

/**
 * Parses simple bank CSV content.
 *
 * Required headers:
 * - date
 * - description
 * - amount
 */
export function parseBankCsv(content: string): ParseBankCsvResult {
  const errors: string[] = [];

  const lines = content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);

  if (lines.length < 2) {
    return {
      ok: false,
      errors: ["CSV must contain a header row and at least one transaction row."],
    };
  }

  const headers = splitCsvLine(lines[0]!).map((header) =>
    header.toLowerCase(),
  );

  const dateIndex = headers.indexOf("date");
  const descriptionIndex = headers.indexOf("description");
  const amountIndex = headers.indexOf("amount");

  if (dateIndex === -1) {
    errors.push("CSV header must include 'date'.");
  }

  if (descriptionIndex === -1) {
    errors.push("CSV header must include 'description'.");
  }

  if (amountIndex === -1) {
    errors.push("CSV header must include 'amount'.");
  }

  if (errors.length > 0) {
    return {
      ok: false,
      errors,
    };
  }

  const rows: ParsedBankCsvRow[] = [];

  lines.slice(1).forEach((line, rowIndex) => {
    const rowNumber = rowIndex + 2;
    const columns = splitCsvLine(line);

    const transactionDate = columns[dateIndex]?.trim() ?? "";
    const description = columns[descriptionIndex]?.trim() ?? "";
    const amount = columns[amountIndex]?.trim() ?? "";

    if (!isValidReportDate(transactionDate)) {
      errors.push(`Row ${rowNumber}: date must be YYYY-MM-DD.`);
    }

    if (!description) {
      errors.push(`Row ${rowNumber}: description is required.`);
    }

    let amountCents = 0;

    try {
      amountCents = dollarsToCents(amount);
    } catch {
      errors.push(`Row ${rowNumber}: amount is invalid.`);
    }

    if (amountCents === 0) {
      errors.push(`Row ${rowNumber}: amount cannot be zero.`);
    }

    rows.push({
      transactionDate,
      description,
      amountCents,
    });
  });

  if (errors.length > 0) {
    return {
      ok: false,
      errors,
    };
  }

  return {
    ok: true,
    rows,
  };
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 4. Add CSV Parser Tests

## The Target

We are creating:

```txt
tests/bank-csv.test.ts
```

---

## The Implementation

Create:

```txt
tests/bank-csv.test.ts
```

Add:

```ts
// tests/bank-csv.test.ts

import { describe, expect, it } from "vitest";
import { parseBankCsv } from "@/lib/bank/parse-bank-csv";

describe("parseBankCsv", () => {
  it("parses valid bank CSV", () => {
    const result = parseBankCsv(`date,description,amount
2026-01-05,Customer payment,109.00
2026-01-06,Vendor payment,-25.50`);

    expect(result.ok).toBe(true);

    if (result.ok) {
      expect(result.rows).toEqual([
        {
          transactionDate: "2026-01-05",
          description: "Customer payment",
          amountCents: 10900,
        },
        {
          transactionDate: "2026-01-06",
          description: "Vendor payment",
          amountCents: -2550,
        },
      ]);
    }
  });

  it("supports quoted descriptions containing commas", () => {
    const result = parseBankCsv(`date,description,amount
2026-01-05,"Customer payment, Merlion Trading",109.00`);

    expect(result.ok).toBe(true);

    if (result.ok) {
      expect(result.rows[0]?.description).toBe(
        "Customer payment, Merlion Trading",
      );
    }
  });

  it("rejects missing headers", () => {
    const result = parseBankCsv(`date,memo,value
2026-01-05,Customer payment,109.00`);

    expect(result.ok).toBe(false);

    if (!result.ok) {
      expect(result.errors).toContain("CSV header must include 'description'.");
      expect(result.errors).toContain("CSV header must include 'amount'.");
    }
  });

  it("rejects invalid rows", () => {
    const result = parseBankCsv(`date,description,amount
not-a-date,,abc`);

    expect(result.ok).toBe(false);

    if (!result.ok) {
      expect(result.errors).toContain("Row 2: date must be YYYY-MM-DD.");
      expect(result.errors).toContain("Row 2: description is required.");
      expect(result.errors).toContain("Row 2: amount is invalid.");
    }
  });
});
```

---

## The Verification

Run:

```bash
pnpm test
```

---

# 5. Create Bank Import Service

## The Target

We are creating:

```txt
services/bank/bank-import-services.ts
```

---

## The Concept

The service will:

1. Require active organization.
2. Parse CSV content.
3. Insert a bank import row.
4. Insert parsed bank transaction rows.
5. Return result.

---

## The Implementation

Create:

```bash
mkdir -p services/bank
```

Create:

```txt
services/bank/bank-import-services.ts
```

Add:

```ts
// services/bank/bank-import-services.ts

import { count, desc, eq } from "drizzle-orm";
import { db } from "@/db";
import { bankImports, bankTransactions } from "@/db/schema";
import { parseBankCsv } from "@/lib/bank/parse-bank-csv";
import { requireCurrentDatabaseOrganization } from "@/services/organizations/get-or-create-organization";

export type ImportBankCsvResult =
  | {
      ok: true;
      bankImportId: string;
      rowCount: number;
    }
  | {
      ok: false;
      error: string;
    };

export async function importBankCsvForCurrentOrganization(params: {
  fileName: string;
  content: string;
}): Promise<ImportBankCsvResult> {
  const organization = await requireCurrentDatabaseOrganization();

  const parsed = parseBankCsv(params.content);

  if (!parsed.ok) {
    return {
      ok: false,
      error: parsed.errors.join(" "),
    };
  }

  const now = new Date();

  const result = await db.transaction(async (tx) => {
    const [createdImport] = await tx
      .insert(bankImports)
      .values({
        organizationId: organization.id,
        fileName: params.fileName,
        rowCount: parsed.rows.length,
        createdAt: now,
      })
      .returning();

    if (!createdImport) {
      throw new Error("Bank import could not be created.");
    }

    await tx.insert(bankTransactions).values(
      parsed.rows.map((row) => ({
        organizationId: organization.id,
        bankImportId: createdImport.id,
        transactionDate: row.transactionDate,
        description: row.description,
        amountCents: row.amountCents,
        status: "imported",
        createdAt: now,
      })),
    );

    return createdImport;
  });

  return {
    ok: true,
    bankImportId: result.id,
    rowCount: parsed.rows.length,
  };
}

export async function getCurrentOrganizationBankImportDiagnostics(): Promise<{
  organizationId: string | null;
  importCount: number;
  transactionCount: number;
  recentTransactions: Array<{
    id: string;
    transactionDate: string;
    description: string;
    amountCents: number;
    status: string;
  }>;
}> {
  const organization = await requireCurrentDatabaseOrganization().catch(
    () => null,
  );

  if (!organization) {
    return {
      organizationId: null,
      importCount: 0,
      transactionCount: 0,
      recentTransactions: [],
    };
  }

  const [importCountRow] = await db
    .select({ value: count() })
    .from(bankImports)
    .where(eq(bankImports.organizationId, organization.id));

  const [transactionCountRow] = await db
    .select({ value: count() })
    .from(bankTransactions)
    .where(eq(bankTransactions.organizationId, organization.id));

  const recentTransactions = await db
    .select({
      id: bankTransactions.id,
      transactionDate: bankTransactions.transactionDate,
      description: bankTransactions.description,
      amountCents: bankTransactions.amountCents,
      status: bankTransactions.status,
    })
    .from(bankTransactions)
    .where(eq(bankTransactions.organizationId, organization.id))
    .orderBy(desc(bankTransactions.createdAt))
    .limit(20);

  return {
    organizationId: organization.id,
    importCount: importCountRow?.value ?? 0,
    transactionCount: transactionCountRow?.value ?? 0,
    recentTransactions,
  };
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 6. Create Bank Upload Server Action

## The Target

We are creating:

```txt
app/bank/actions.ts
```

---

## The Implementation

Create:

```txt
app/bank/actions.ts
```

Add:

```ts
// app/bank/actions.ts

"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { importBankCsvForCurrentOrganization } from "@/services/bank/bank-import-services";

export async function uploadBankCsvAction(formData: FormData) {
  const file = formData.get("file");

  if (!(file instanceof File)) {
    redirect("/bank?status=error&message=CSV file is required.");
  }

  const content = await file.text();

  const result = await importBankCsvForCurrentOrganization({
    fileName: file.name,
    content,
  });

  revalidatePath("/bank");
  revalidatePath("/settings/database");

  if (!result.ok) {
    redirect(`/bank?status=error&message=${encodeURIComponent(result.error)}`);
  }

  redirect(`/bank?status=imported&rows=${result.rowCount}`);
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 7. Create Bank Import Status Banner

## The Target

We are creating:

```txt
components/bank-import-status-banner.tsx
```

---

## The Implementation

Create:

```txt
components/bank-import-status-banner.tsx
```

Add:

```tsx
// components/bank-import-status-banner.tsx

type BankImportStatusBannerProps = {
  status?: string;
  message?: string;
  rows?: string;
};

export function BankImportStatusBanner({
  status,
  message,
  rows,
}: BankImportStatusBannerProps) {
  if (!status) {
    return null;
  }

  if (status === "imported") {
    return (
      <section className="rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-800">
        <p className="text-sm font-semibold">
          Bank CSV imported successfully.
        </p>

        <p className="mt-2 text-sm leading-6">
          Imported {rows ?? "0"} transaction row{rows === "1" ? "" : "s"}.
        </p>
      </section>
    );
  }

  if (status === "error") {
    return (
      <section className="rounded-2xl border border-rose-200 bg-rose-50 p-5 text-rose-800">
        <p className="text-sm font-semibold">Bank CSV import failed.</p>
        {message ? <p className="mt-2 text-sm leading-6">{message}</p> : null}
      </section>
    );
  }

  return null;
}
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 8. Update Bank Page

## The Target

We are replacing:

```txt
app/bank/page.tsx
```

---

## The Implementation

Open:

```txt
app/bank/page.tsx
```

Replace it with:

```tsx
// app/bank/page.tsx

import { AppLayout } from "@/components/app-layout";
import { BankImportStatusBanner } from "@/components/bank-import-status-banner";
import { formatMoney } from "@/lib/money";
import { uploadBankCsvAction } from "@/app/bank/actions";
import { getCurrentOrganizationBankImportDiagnostics } from "@/services/bank/bank-import-services";

export const dynamic = "force-dynamic";

type BankPageProps = {
  searchParams?: Promise<{
    status?: string;
    message?: string;
    rows?: string;
  }>;
};

export default async function BankPage({ searchParams }: BankPageProps) {
  const resolvedSearchParams = searchParams ? await searchParams : {};
  const diagnostics = await getCurrentOrganizationBankImportDiagnostics();

  return (
    <AppLayout
      title="Bank"
      description="Bank workflows help import, categorize, post, and reconcile bank transactions."
    >
      <div className="space-y-6">
        <BankImportStatusBanner
          status={resolvedSearchParams.status}
          message={resolvedSearchParams.message}
          rows={resolvedSearchParams.rows}
        />

        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-emerald-600">
            Upload bank CSV
          </p>

          <h2 className="mt-3 text-xl font-bold tracking-tight text-slate-950">
            Import statement transactions
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">
            Upload a CSV with headers <code>date</code>,{" "}
            <code>description</code>, and <code>amount</code>. Positive amounts
            are inflows. Negative amounts are outflows.
          </p>

          <form action={uploadBankCsvAction} className="mt-6 grid gap-4">
            <input
              name="file"
              type="file"
              accept=".csv,text/csv"
              required
              className="block w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm text-slate-950 file:mr-4 file:rounded-lg file:border-0 file:bg-slate-950 file:px-3 file:py-2 file:text-sm file:font-semibold file:text-white"
            />

            <button
              type="submit"
              className="w-fit rounded-xl bg-slate-950 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-slate-800"
            >
              Upload CSV
            </button>
          </form>

          <div className="mt-6 rounded-xl bg-slate-50 p-4">
            <p className="text-sm font-semibold text-slate-700">
              Example CSV
            </p>

            <pre className="mt-2 overflow-x-auto text-xs leading-6 text-slate-600">
{`date,description,amount
2026-01-05,Customer payment from Merlion Trading,109.00
2026-01-06,Cloud Hosting SG,-109.00`}
            </pre>
          </div>
        </section>

        <section className="grid gap-4 md:grid-cols-2">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">Imports</p>
            <p className="mt-2 text-3xl font-bold text-slate-950">
              {diagnostics.importCount}
            </p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <p className="text-sm font-semibold text-slate-500">
              Imported transactions
            </p>
            <p className="mt-2 text-3xl font-bold text-slate-950">
              {diagnostics.transactionCount}
            </p>
          </div>
        </section>

        {diagnostics.recentTransactions.length > 0 ? (
          <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <div className="border-b border-slate-200 bg-slate-50 px-6 py-4">
              <h2 className="text-lg font-semibold text-slate-950">
                Recent imported transactions
              </h2>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full border-collapse text-left text-sm">
                <thead className="bg-white text-xs uppercase tracking-wide text-slate-500">
                  <tr>
                    <th className="px-6 py-3 font-semibold">Date</th>
                    <th className="px-6 py-3 font-semibold">Description</th>
                    <th className="px-6 py-3 font-semibold">Status</th>
                    <th className="px-6 py-3 text-right font-semibold">
                      Amount
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-200">
                  {diagnostics.recentTransactions.map((transaction) => (
                    <tr key={transaction.id}>
                      <td className="px-6 py-4 text-slate-600">
                        {transaction.transactionDate}
                      </td>

                      <td className="px-6 py-4 font-medium text-slate-950">
                        {transaction.description}
                      </td>

                      <td className="px-6 py-4">
                        <span className="rounded-full bg-sky-50 px-2 py-1 text-xs font-semibold text-sky-700">
                          {transaction.status}
                        </span>
                      </td>

                      <td className="px-6 py-4 text-right font-semibold text-slate-950">
                        {formatMoney(transaction.amountCents)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        ) : (
          <section className="rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center">
            <h2 className="text-lg font-semibold text-slate-950">
              No bank transactions imported yet
            </h2>

            <p className="mx-auto mt-2 max-w-2xl text-sm leading-6 text-slate-500">
              Upload a CSV file to begin bank import and reconciliation
              workflows.
            </p>
          </section>
        )}
      </div>
    </AppLayout>
  );
}
```

---

## The Verification

Open:

```txt
http://localhost:3000/bank
```

You should see an upload form and sample CSV.

---

# 9. Update Database Health

## The Target

We are updating:

```txt
lib/database-health.ts
```

to include bank import counts.

---

## The Implementation

Import:

```ts
bankImports,
bankTransactions,
```

Add to success type:

```ts
bankImportCount: number;
bankTransactionCount: number;
```

In function:

```ts
const [bankImportRow] = await db.select({ value: count() }).from(bankImports);

const [bankTransactionRow] = await db
  .select({ value: count() })
  .from(bankTransactions);
```

Return:

```ts
bankImportCount: bankImportRow?.value ?? 0,
bankTransactionCount: bankTransactionRow?.value ?? 0,
```

---

## The Verification

Run:

```bash
pnpm build
```

---

# 10. Upload a Test CSV

## The Target

We are testing upload and parsing.

---

## The Implementation

Create a local file:

```txt
sample-bank.csv
```

Use:

```csv
date,description,amount
2026-01-05,Customer payment from Merlion Trading,109.00
2026-01-06,Cloud Hosting SG,-109.00
```

Open:

```txt
/bank
```

Upload the file.

---

## The Verification

You should see:

```txt
Bank CSV imported successfully.
Imported 2 transaction rows.
```

The transactions should appear in the table.

---

# 11. Verify in Neon SQL

## The Target

We are checking bank import data directly.

---

## The Implementation

Run:

```sql
select
  file_name,
  row_count,
  created_at
from bank_imports
order by created_at desc;
```

Run:

```sql
select
  transaction_date,
  description,
  amount_cents,
  status
from bank_transactions
order by created_at desc;
```

---

## The Verification

You should see:

```txt
10900
-10900
```

for the sample CSV amounts.

---

# 12. Run Full Project Check

## The Target

We are verifying everything still passes.

---

## The Implementation

Run:

```bash
pnpm check
```

---

## The Verification

The command should pass.

---

# 13. Commit Bank CSV Import

## The Target

We are saving this milestone.

---

## The Implementation

Run:

```bash
git status
git add .
git commit -m "Upload and parse bank CSV files"
```

---

## The Verification

Run:

```bash
git status
```

You should see:

```txt
nothing to commit, working tree clean
```

---

# Common Errors and Fixes

## Error: `relation "bank_imports" does not exist`

Run:

```bash
pnpm db:generate
pnpm db:migrate
```

---

## Error: CSV header missing

The CSV must include:

```txt
date,description,amount
```

---

## Error: Amount invalid

Use normal money values:

```txt
109.00
-25.50
```

---

## Error: Upload says file required

Make sure your browser selected a `.csv` file before submitting.

---

# Phase 10 Reference — Bank Import

## Bank Import

One uploaded statement file.

---

## Bank Transaction

One row parsed from a bank statement.

---

## Positive Amount

Money into the bank.

---

## Negative Amount

Money out of the bank.

---

# Part 32 Completion Checklist

You are ready for Part 33 if:

- [ ] `bank_imports` table exists
- [ ] `bank_transactions` table exists
- [ ] CSV parser exists
- [ ] CSV parser tests pass
- [ ] Bank import service exists
- [ ] `/bank` upload form exists
- [ ] Test CSV uploads successfully
- [ ] Bank transaction rows appear in UI
- [ ] Neon SQL confirms imported transactions
- [ ] `pnpm check` succeeds
- [ ] Changes are committed with Git
