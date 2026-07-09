## Part 21: Importing Bank Transactions from CSV

Goal of this part: let a user upload a CSV export from their bank, parse it, store each row as a reviewable bank transaction, and build a simple screen to categorize each one against the Chart of Accounts — turning raw bank data into real journal entries.

Prerequisite: Parts 1-20 completed.

---

### 1. Why bank import matters, and why CSV first

Recall our project plan: real bank feeds (Plaid, Part 22) are Phase 2 and require a paid/approved API integration. CSV import is the universal fallback nearly every accounting product supports — virtually every bank lets a user export their transaction history as a CSV file (a plain text file with comma-separated values, one row per transaction), so this feature works today, for any bank, with zero external API dependency.

### 2. The workflow we're building

1. User exports a CSV from their bank's website (we won't build this part — it's external to our app)
2. User uploads that CSV into our app
3. We parse it and store each row as an uncategorized `bank_transactions` row
4. User reviews each transaction and assigns it to a Chart of Accounts category (e.g. "Office Supplies", "Utilities")
5. Categorizing a transaction posts a journal entry, exactly like invoices/bills do — this is the moment raw bank data becomes real accounting

### 3. Add the schema

Add to `src/lib/db/schema.ts`:

`bank_transactions`:
- id (uuid, primary key, default random)
- orgId (text, references organizations.id)
- bankAccountId — for simplicity in this course, skip a separate bank_accounts table and just reference the Checking account directly via accounts.id (a real system would model multiple bank accounts; one is enough to learn the pattern)
- transactionDate (date, required)
- description (text, required) — the raw description from the bank, e.g. "AMAZON.COM PURCHASE"
- amountCents (bigint, not null) — positive for money in, negative for money out
- status (text, default "uncategorized") — "uncategorized" or "categorized"
- categorizedAccountId (uuid, optional, references accounts.id) — which account it was matched to once categorized
- journalEntryId (uuid, optional, references journal_entries.id) — the entry created once categorized
- createdAt (timestamp)

Run `npm run db:generate` and `npm run db:migrate`.

### 4. Build the CSV upload and parsing action

Real bank CSVs vary in column names/order, but a common shape is: Date, Description, Amount. We'll assume that simple shape for this course (a robust version would let the user map columns, a good stretch exercise).

Install a small CSV parsing helper: `npm install papaparse` and `npm install -D @types/papaparse`.

Create `src/app/dashboard/bank-import/actions.ts`:

```ts
"use server";

import { db } from "@/lib/db";
import { bankTransactions } from "@/lib/db/schema";
import { auth } from "@clerk/nextjs/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import Papa from "papaparse";
import { findAccountBySubtype } from "@/lib/accounting/find-account";

export async function importCsv(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const file = formData.get("csvFile") as File;
  if (!file || file.size === 0) throw new Error("Please choose a CSV file");

  const text = await file.text();
  const parsed = Papa.parse<{ Date: string; Description: string; Amount: string }>(text, {
    header: true,
    skipEmptyLines: true,
  });

  const bankAccount = await findAccountBySubtype(orgId, "bank");

  const rows = parsed.data
    .filter((r) => r.Date && r.Description && r.Amount)
    .map((r) => ({
      orgId,
      bankAccountId: bankAccount.id,
      transactionDate: r.Date,
      description: r.Description,
      amountCents: Math.round(Number(r.Amount) * 100),
      status: "uncategorized" as const,
    }));

  if (rows.length === 0) {
    throw new Error("No valid rows found in that CSV file");
  }

  await db.insert(bankTransactions).values(rows);

  revalidatePath("/dashboard/bank-import");
  redirect("/dashboard/bank-import");
}
```

What's new: `formData.get("csvFile") as File` gives us the uploaded file object directly (Next.js Server Actions support file uploads via FormData natively). `file.text()` reads its full text content. `Papa.parse` turns CSV text into an array of row objects, using the header row to name each field — this saves us from manually splitting text on commas ourselves, which gets surprisingly tricky with quoted fields, embedded commas, etc.

### 5. Build the upload form and review list page

Create `src/app/dashboard/bank-import/page.tsx`: an upload form with `<input type="file" name="csvFile" accept=".csv">` and a submit button pointed at `importCsv` (note: file upload forms need `encType="multipart/form-data"` set — Next.js handles this automatically when your form action is a Server Action, so no manual configuration needed), followed by a table listing all `bank_transactions` for the org with status "uncategorized", each row showing date/description/amount and a small dropdown (populated with all the org's accounts) plus a "Categorize" button.

### 6. Build the categorization Server Action

Add to the same `actions.ts` file:

```ts
export async function categorizeBankTransaction(formData: FormData) {
  const { orgId } = await auth();
  if (!orgId) throw new Error("No active organization");

  const transactionId = formData.get("transactionId") as string;
  const accountId = formData.get("accountId") as string;

  const [txn] = await db.select().from(bankTransactions).where(eq(bankTransactions.id, transactionId)).limit(1);
  if (!txn || txn.orgId !== orgId) throw new Error("Invalid transaction");

  const [chosenAccount] = await db.select().from(accounts).where(eq(accounts.id, accountId)).limit(1);
  if (!chosenAccount || chosenAccount.orgId !== orgId) throw new Error("Invalid account");

  const amountCents = Math.abs(txn.amountCents);
  const isMoneyIn = txn.amountCents > 0;

  await db.transaction(async (tx) => {
    const lines = isMoneyIn
      ? [
          { accountId: txn.bankAccountId, debitCents: amountCents },
          { accountId: chosenAccount.id, creditCents: amountCents },
        ]
      : [
          { accountId: chosenAccount.id, debitCents: amountCents },
          { accountId: txn.bankAccountId, creditCents: amountCents },
        ];

    const entry = await postJournalEntry(
      {
        orgId,
        date: new Date(txn.transactionDate),
        memo: `Bank: ${txn.description}`,
        sourceType: "bank_transaction",
        sourceId: txn.id,
        lines,
      },
      tx
    );

    await tx
      .update(bankTransactions)
      .set({ status: "categorized", categorizedAccountId: chosenAccount.id, journalEntryId: entry.id })
      .where(eq(bankTransactions.id, txn.id));
  });

  revalidatePath("/dashboard/bank-import");
}
```

Notice the `isMoneyIn` branch: money coming into the bank account means the bank account (an Asset) is debited and whatever category it's coming from is credited (e.g. a customer payment received in cash outside our invoice flow would credit Income). Money going out means the category account is debited (e.g. an expense) and the bank account is credited. This is exactly Part 8's rules, just decided dynamically based on the sign of the imported amount rather than being fixed like our invoice/bill functions.

### 7. Test the whole flow

Create a small test CSV file yourself (in any text editor, save as `test-transactions.csv`):
```
Date,Description,Amount
2025-01-05,OFFICE DEPOT,-45.99
2025-01-06,CLIENT PAYMENT,500.00
2025-01-07,ELECTRIC COMPANY,-120.00
```
Upload it via `/dashboard/bank-import`, confirm three uncategorized rows appear, then categorize each one (Office Depot to an Office Supplies expense account, Client Payment to an Income account, Electric Company to a Utilities expense account) and confirm each produces a correct journal entry — check Neon for `source_type = 'bank_transaction'` entries.

### 8. Add a nav link and commit

Add "Bank Import" to your dashboard navigation.

```
git add .
git commit -m "Add CSV bank transaction import and categorization posting journal entries"
```

---

### Checkpoint — confirm before moving on

- [ ] `bank_transactions` table exists
- [ ] Uploading a CSV correctly parses rows and stores them as uncategorized
- [ ] Categorizing a transaction posts a correct journal entry, with debit/credit direction depending on money in vs out
- [ ] You understand why the direction of debit/credit flips based on the sign of the transaction amount, unlike invoices/bills which always post the same direction
- [ ] You can describe, roughly, how a more robust version would let users map arbitrary CSV column names

---

### Troubleshooting

**Error: "Please choose a CSV file" even though you selected one**
Confirm your form's file input is named exactly `csvFile` (matching `formData.get("csvFile")` in the action), and that the form itself doesn't have a typo preventing the file from actually being included in the submission.

**Uploading the CSV succeeds but zero rows appear on the review page**
Open your CSV file in a plain text editor and confirm the header row is spelled EXACTLY `Date,Description,Amount` (case-sensitive, no extra spaces) — Papa.parse uses the header row to name fields, and a mismatched header name (like "date" lowercase, or "Transaction Date") means `r.Date`, `r.Description`, `r.Amount` will all be undefined, causing every row to be filtered out.

**Error: "No valid rows found in that CSV file"**
Same root cause as above — double check the header row spelling, and confirm there's at least one data row below it with values in all three columns.

**Amounts import correctly but are 100x too large or too small**
Confirm `Math.round(Number(r.Amount) * 100)` is present exactly as shown — if you're seeing amounts too large, you may have accidentally multiplied twice somewhere; if too small, confirm the multiplication by 100 wasn't accidentally removed.

**Categorizing a transaction throws "Invalid account selected"**
Confirm the account you picked really belongs to the currently active organization — this check exists specifically to prevent cross-organization data leaks, so it's doing its job correctly if triggered by genuinely mismatched data, but double check you're not accidentally testing against accounts from a different seeded organization.

**A transaction's debit/credit direction seems backwards after categorizing (e.g., an expense shows as a credit instead of debit)**
Re-check the sign of the original CSV amount for that row — negative amounts are treated as money OUT (debiting the category, crediting the bank), positive amounts as money IN (debiting the bank, crediting the category). If your bank's CSV export uses the opposite convention (some banks show expenses as positive numbers with a separate "type" column), you'll need to adjust the `isMoneyIn` logic or pre-process the CSV to match this course's assumed convention (negative = money out).

**File upload seems to hang or the page times out on a large CSV**
This course's simple implementation reads the whole file into memory in one Server Action call — for very large files (thousands of rows), consider processing in smaller batches as a stretch improvement. For typical personal bank statement exports (dozens to a few hundred rows), this should not be an issue.

**"Module not found: Can't resolve 'papaparse'" or missing type errors**
Confirm both `npm install papaparse` and `npm install -D @types/papaparse` were run successfully — check `package.json`'s dependencies and devDependencies sections for both entries.

**Categorized transactions still show up in the "uncategorized" list**
Confirm the update to `bankTransactions` (setting status to "categorized") is inside the same `db.transaction` as the `postJournalEntry` call, and that your review-list page's query actually filters `WHERE status = 'uncategorized'` — if that filter is missing, all transactions (categorized or not) will always show.

---

### What's next
Part 22 (optional, Phase 2 preview): Connecting Real Banks with Plaid — a conceptual and lightly-coded look at how automatic bank feeds work, so you understand the next step beyond CSV import even if you don't fully build it out in this course.
