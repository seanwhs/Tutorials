## Part 13: Turning Invoices into Journal Entries

Goal: wire invoice creation into `postJournalEntry` from Part 10, so every invoice produces a correct, balanced accounting entry automatically, atomically alongside the invoice itself.

Prerequisite: Parts 1-12 completed.

---

### 1. Which accounts does an invoice touch?

Recall Part 8's Worked Example 2: sending a $500 invoice debits Accounts Receivable (Asset up) and credits Income. We look up these accounts by subtype rather than hardcoding IDs, since IDs differ per organization.

### 2. Write a helper to find accounts by subtype

Create `src/lib/accounting/find-account.ts`:

```ts
import { db } from "@/lib/db";
import { accounts } from "@/lib/db/schema";
import { and, eq } from "drizzle-orm";

export async function findAccountBySubtype(orgId: string, subtype: string) {
  const [account] = await db
    .select()
    .from(accounts)
    .where(and(eq(accounts.orgId, orgId), eq(accounts.subtype, subtype)))
    .limit(1);

  if (!account) {
    throw new Error(`No account found with subtype "${subtype}" for this organization`);
  }

  return account;
}
```

### 3. Make postJournalEntry transaction-aware

Open `src/lib/accounting/post-journal-entry.ts` from Part 10. Replace its entire contents with:

```ts
import { db } from "@/lib/db";
import { journalEntries, journalLines } from "@/lib/db/schema";

type JournalLineInput = {
  accountId: string;
  debitCents?: number;
  creditCents?: number;
};

type PostJournalEntryParams = {
  orgId: string;
  date: Date;
  memo?: string;
  sourceType:
    | "manual"
    | "invoice"
    | "bill"
    | "payment_received"
    | "payment_made"
    | "opening_balance"
    | "bank_transaction"
    | "reversal";
  sourceId?: string;
  lines: JournalLineInput[];
};

export async function postJournalEntry(
  params: PostJournalEntryParams,
  tx?: typeof db
) {
  const { orgId, date, memo, sourceType, sourceId, lines } = params;

  if (lines.length < 2) {
    throw new Error("A journal entry needs at least two lines");
  }

  const totalDebits = lines.reduce((sum, l) => sum + (l.debitCents ?? 0), 0);
  const totalCredits = lines.reduce((sum, l) => sum + (l.creditCents ?? 0), 0);

  if (totalDebits !== totalCredits) {
    throw new Error(
      `Journal entry is unbalanced: debits ${totalDebits} !== credits ${totalCredits}`
    );
  }

  async function runPosting(activeTx: typeof db) {
    const [entry] = await activeTx
      .insert(journalEntries)
      .values({
        orgId,
        date: date.toISOString().slice(0, 10),
        memo,
        sourceType,
        sourceId,
      })
      .returning();

    await activeTx.insert(journalLines).values(
      lines.map((l) => ({
        entryId: entry.id,
        accountId: l.accountId,
        debitCents: l.debitCents ?? 0,
        creditCents: l.creditCents ?? 0,
      }))
    );

    return entry;
  }

  if (tx) {
    return runPosting(tx);
  }
  return db.transaction(async (innerTx) => runPosting(innerTx));
}
```

The only change from Part 10: it now accepts an optional second argument, `tx`. If provided, it uses that transaction instead of opening a new one — letting it join a larger atomic operation.

### 4. Update createInvoice to post a journal entry atomically

Open `src/app/dashboard/invoices/actions.ts`. Replace its entire contents with:

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

What changed from Part 12: we look up the AR and Income accounts before opening the transaction. Everything — invoice insert, invoice line inserts, and the journal entry — is wrapped in one `db.transaction`. Status changed from `draft` to `sent`. We pass `tx` as the second argument to `postJournalEntry` so it joins the same transaction.

### 5. Test it

Create a new invoice through `/dashboard/invoices/new`. Check Neon's SQL Editor:
```sql
SELECT * FROM journal_entries ORDER BY created_at DESC LIMIT 1;
```
Copy the `id` from that row, then:
```sql
SELECT * FROM journal_lines WHERE entry_id = 'PASTE_THE_ID_HERE';
```
Expected: exactly two lines, one debiting Accounts Receivable for the full invoice total, one crediting your Income account for the same amount.

### 6. Prove the safety net works at the feature level

In `src/app/dashboard/invoices/actions.ts`, temporarily change this line:
```ts
{ accountId: incomeAccount.id, creditCents: totalCents },
```
to:
```ts
{ accountId: incomeAccount.id, creditCents: totalCents - 100 },
```
Save, and try creating another invoice. Expected: the whole operation fails with an error in your terminal containing "Journal entry is unbalanced". Then check:
```sql
SELECT * FROM invoices ORDER BY created_at DESC LIMIT 1;
```
Confirm the broken invoice was NOT saved — only your previous good invoices appear. Revert the line back to `creditCents: totalCents` once confirmed.

### 7. Commit

```
git add .
git commit -m "Wire invoice creation to postJournalEntry atomically, posting AR debit / Income credit"
```

---

### Checkpoint

- [ ] postJournalEntry accepts an optional existing transaction
- [ ] createInvoice wraps invoice + invoice_lines + journal entry in one db.transaction
- [ ] Creating an invoice produces debit AR / credit Income, both equal to the invoice total
- [ ] You deliberately broke the balance once and confirmed BOTH the invoice and journal entry failed to save together

---

### Troubleshooting

**Error: "No account found with subtype accounts_receivable for this organization"**
Your organization was not seeded with default accounts (Part 9), or you are testing against a different organization than the one you seeded. Re-run Part 9's seed script for the organization currently active in your app.

**Invoice saves successfully but no journal entry appears**
Confirm you replaced the ENTIRE `actions.ts` file with the version in this part, not just added the new import lines — a common mistake is keeping Part 12's old function body while adding the new imports, which silently skips the `postJournalEntry` call.

**Error: "invoiceId" is not defined, or invoice is undefined inside the transaction**
Confirm the `.returning()` call is present immediately after `.insert(invoices).values({...})` — without it, `invoice` will be undefined, since Drizzle needs to be told explicitly to return the inserted row.

**The deliberate unbalance test still saved a broken invoice**
Double-check you edited the correct line (the credit line, not the debit line) and saved the file. Also confirm you are looking inside the `db.transaction` block, not some other unrelated part of the file.

**TypeScript error: "Argument of type '{...}' is not assignable to parameter of type 'typeof db'"**
This usually means the `tx` parameter type is being inferred incorrectly. Confirm `post-journal-entry.ts`'s function signature matches exactly: `tx?: typeof db` as the second parameter, and that you are calling `postJournalEntry({...}, tx)` with `tx` as a plain second argument, not wrapped in another object.

**Error mentions "relation actions does not exist" or similar odd path error**
Confirm `actions.ts` is still in `src/app/dashboard/invoices/` (same location as Part 12) — this part only edits the file's contents, it does not move it.
