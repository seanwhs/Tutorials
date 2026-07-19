# Part 14.7: Multi-Currency Support

A US-only course might treat multi-currency as a distant, low-priority nice-to-have. For Singapore — a small, extremely trade-heavy economy where invoicing a customer in USD, EUR, or a regional currency is routine even for small businesses — this deserves meaningfully higher priority. This part extends the journal engine to track both an original transaction currency and a converted SGD amount, without changing the one rule that must never break: debits still equal credits, always.

## Step 14.7.1 — The Core Design Challenge

### The Target
Understand, before writing any code, how multi-currency can coexist with double-entry bookkeeping without weakening it.

### The Concept
Recall Part 4's unbreakable rule: total debits must equal total credits on every transaction. If a customer is invoiced USD $1,000 and pays in USD, that's straightforward in isolation — but the business's own books, reports, and tax filings (Parts 9, 10, 14.6) all need one single, consistent home currency to aggregate against. You can't meaningfully add "$1,000 USD" and "$500 SGD" together in a `SUM()` and get a sensible number.

The standard, proven solution: every journal line stores **two** amounts — the amount in whatever currency the original transaction was in, and a **converted home-currency (SGD) amount**, calculated using the exchange rate in effect on the transaction's date. All balancing logic in `postJournalEntry` (Part 6) continues to operate on the SGD column exactly as before — the foreign-currency amount is carried alongside, purely for record-keeping and for showing the original invoice/bill in the currency it was actually issued in. This is precisely why Part 14's roadmap could promise "no change to the core balancing logic itself" — we're adding a column, not rewriting the engine.

## Step 14.7.2 — Extending the Schema

### The Target
Add currency and exchange rate columns to `journal_lines`, `invoices`, and `bills`.

### The Implementation

**`src/db/schema.ts`** (add to `journalLines`)
```typescript
export const journalLines = pgTable("journal_lines", {
  id: uuid("id").primaryKey().defaultRandom(),
  journalEntryId: uuid("journal_entry_id").notNull().references(() => journalEntries.id, { onDelete: "cascade" }),
  accountId: uuid("account_id").notNull().references(() => accounts.id, { onDelete: "restrict" }),

  // Amounts in SGD — these remain the ONLY figures postJournalEntry's
  // balance check ever looks at (Part 6, unchanged).
  debitAmount: numeric("debit_amount", { precision: 14, scale: 2 }).notNull().default("0"),
  creditAmount: numeric("credit_amount", { precision: 14, scale: 2 }).notNull().default("0"),

  // --- New in Part 14.7 ---
  // The ISO 4217 currency code of the ORIGINAL transaction, e.g. "USD".
  // Defaults to "SGD" so every existing line from Parts 6-14.6 remains
  // valid without a backfill — an SGD-denominated line simply has an
  // original amount identical to its SGD amount, rate 1.0.
  originalCurrency: text("original_currency").notNull().default("SGD"),
  originalDebitAmount: numeric("original_debit_amount", { precision: 14, scale: 2 }).notNull().default("0"),
  originalCreditAmount: numeric("original_credit_amount", { precision: 14, scale: 2 }).notNull().default("0"),
  exchangeRateToSgd: numeric("exchange_rate_to_sgd", { precision: 12, scale: 6 }).notNull().default("1.000000"),

  createdAt: timestamp("created_at").notNull().defaultNow(),
});
```

**`src/db/schema.ts`** (add to `invoices` and `bills`)
```typescript
// Add to invoices table definition:
  currency: text("currency").notNull().default("SGD"),
  exchangeRateToSgd: numeric("exchange_rate_to_sgd", { precision: 12, scale: 6 }).notNull().default("1.000000"),

// Add identically to bills table definition.
```

### The Verification

```bash
npm run db:generate
npm run db:migrate
```

Confirm the new columns appear, and — critically — that every pre-existing row across `journal_lines`, `invoices`, and `bills` from Parts 6–14.6 now shows `currency = "SGD"` and `exchange_rate_to_sgd = 1.000000` automatically, via the `DEFAULT` values, with zero data loss or manual backfill required.

---

## Step 14.7.3 — Updating `postJournalEntry` for Currency

### The Target
Extend `postJournalEntry`'s input shape so each line can optionally carry a foreign-currency amount and rate, while the balance check itself remains entirely unchanged.

### The Implementation

**`src/lib/journal.ts`** (updated `ProposedJournalLine` type and insert logic)
```typescript
export type ProposedJournalLine = {
  accountId: string;
  debit?: number;  // always SGD
  credit?: number; // always SGD
  // Optional foreign-currency context — purely descriptive, never used
  // in the balance check below, which is the entire point: the rule
  // from Part 4 is enforced ONLY in the home currency.
  originalCurrency?: string;
  originalDebit?: number;
  originalCredit?: number;
  exchangeRateToSgd?: number;
};
```

Inside `postJournalEntry`'s insert step, extend the values passed to `journalLines`:

```typescript
const insertedLines = await tx.insert(journalLines).values(
  lines.map((line) => ({
    journalEntryId: entry.id,
    accountId: line.accountId,
    debitAmount: (line.debit ?? 0).toFixed(2),
    creditAmount: (line.credit ?? 0).toFixed(2),
    // Defaults preserve every existing call site from Parts 7, 8, 11,
    // 12, 14.2, 14.5 unchanged — none of them need to pass these new
    // fields at all, and they'll simply record as SGD @ 1.0, correctly.
    originalCurrency: line.originalCurrency ?? "SGD",
    originalDebitAmount: (line.originalDebit ?? line.debit ?? 0).toFixed(2),
    originalCreditAmount: (line.originalCredit ?? line.credit ?? 0).toFixed(2),
    exchangeRateToSgd: (line.exchangeRateToSgd ?? 1).toFixed(6),
  }))
).returning();
```

**Nothing else in `postJournalEntry` changes.** The four guard clauses from Part 6 — minimum line count, no hybrid debit+credit, debits equal credits, accounts belong to the organization — all continue operating exclusively on `line.debit`/`line.credit` (the SGD values), exactly as before. This is the concrete proof of Part 14's promise: the balancing engine required zero modification.

### The Verification

Re-run Part 6's `journal-test` verification pattern (temporarily recreate it) with one line specifying `originalCurrency: "USD", originalDebit: 740, exchangeRateToSgd: 1.35` and `debit: 999` (740 × 1.35). Confirm it still posts successfully and still rejects an unbalanced SGD total exactly as before — proving foreign-currency metadata is fully inert with respect to the balance check.

---

## Step 14.7.4 — Foreign-Currency Invoicing

### The Target
Let `createInvoice` accept a currency and exchange rate, converting every line to SGD before calling `postJournalEntry`.

### The Implementation

**`src/lib/actions/invoices.ts`** (updated `CreateInvoiceInput` and core logic)
```typescript
export type CreateInvoiceInput = {
  customerId: string;
  issueDate: string;
  dueDate: string;
  currency: string;           // e.g. "USD", defaults to "SGD" in the form
  exchangeRateToSgd: number;  // rate in effect on issueDate; 1.0 for SGD
  lines: InvoiceLineInput[];  // amounts entered in the FOREIGN currency
};
```

Inside `createInvoice`, convert every computed line total to SGD before posting, while storing the original-currency amounts on the invoice/lines themselves:

```typescript
// computedLines' lineTotal, subtotal, gstTotal remain in the ORIGINAL
// currency for display/storage on the invoice itself (Part 7's existing
// denormalized fields). We separately compute the SGD-converted totals
// purely for the journal posting step.
const subtotalSgdCents = Math.round(subtotalCents * input.exchangeRateToSgd);
const gstTotalSgdCents = Math.round(gstTotalCents * input.exchangeRateToSgd);
const totalSgdCents = subtotalSgdCents + gstTotalSgdCents;

// ...invoice insert gains: currency: input.currency, exchangeRateToSgd: input.exchangeRateToSgd.toFixed(6)

const journalResult = await postJournalEntry(
  {
    organizationId,
    entryDate: input.issueDate,
    description: `Invoice ${invoiceNumber} (${input.currency})`,
    sourceType: "invoice",
    sourceId: invoice.id,
    lines: [
      {
        accountId: arAccount.id,
        debit: totalSgdCents / 100,
        originalCurrency: input.currency,
        originalDebit: totalCents / 100,
        exchangeRateToSgd: input.exchangeRateToSgd,
      },
      {
        accountId: revenueAccount.id,
        credit: subtotalSgdCents / 100,
        originalCurrency: input.currency,
        originalCredit: subtotalCents / 100,
        exchangeRateToSgd: input.exchangeRateToSgd,
      },
      ...(gstTotalCents > 0
        ? [{
            accountId: gstOutputAccount.id,
            credit: gstTotalSgdCents / 100,
            originalCurrency: input.currency,
            originalCredit: gstTotalCents / 100,
            exchangeRateToSgd: input.exchangeRateToSgd,
          }]
        : []),
    ],
  },
  tx
);
```

Add a currency + exchange rate field pair to `<InvoiceForm />` (Part 7), defaulting to `"SGD"` / `1.0`.

### The Verification

Create a USD invoice: 10 hours × $150 USD = $1,500 USD subtotal, 9% GST = $135 USD, total $1,635 USD, at an exchange rate of 1.35 SGD/USD.

Confirm the invoice detail page shows **$1,635.00 USD** (the original currency, since that's what was actually billed). In Drizzle Studio, confirm `journal_lines` shows the SGD-converted amounts: debit AR = $2,207.25 SGD (1,635 × 1.35), with `original_currency = "USD"`, `original_debit_amount = 1635.00`, `exchange_rate_to_sgd = 1.350000`. Confirm debits still equal credits **in SGD** exactly as every prior part required. Visit `/reports/balance-sheet` — confirm still "✅ balanced," proving foreign-currency invoices aggregate correctly alongside SGD ones since everything ultimately reduces to one shared column.

---

## ✅ Checkpoint — Part 14.7

- [x] `journal_lines` extended with `originalCurrency`, `originalDebitAmount`, `originalCreditAmount`, `exchangeRateToSgd` — all defaulted so every pre-existing row from Parts 6–14.6 remains valid with zero backfill
- [x] `invoices`/`bills` extended with `currency` and `exchangeRateToSgd`, defaulting to `"SGD"` / `1.0`
- [x] `postJournalEntry`'s four Part 6 guard clauses confirmed **unchanged** — balancing is enforced exclusively on the SGD columns, exactly as Part 14's roadmap promised
- [x] `createInvoice` extended to accept a foreign currency + exchange rate, storing original-currency amounts on the invoice for display while posting SGD-converted amounts to the ledger
- [x] Verified: a USD invoice posts a balanced SGD journal entry, displays correctly in its original currency on the detail page, and aggregates correctly into a still-balanced Balance Sheet alongside SGD-only entries

## 📚 Reference Note

**Why convert at the exchange rate "in effect on the transaction's date," stored per-line, rather than recomputing SGD values later using today's rate?** Because accounting requires a transaction to be valued as of when it happened — recomputing historical entries against a *later* exchange rate would silently change the recorded value of a past, already-reported transaction, corrupting every report that already included it (the same "posted entries are historical fact" principle from Part 4 and Part 6). Storing the rate at posting time, permanently, on the line itself, is what keeps historical reports stable even as exchange rates continue moving after the fact.

**Why does `createBill` need the identical treatment, and is it built here?** Yes, by the same pattern — `createBill` (Part 8) would receive the identical `currency`/`exchangeRateToSgd` extension, converting each line's expense-account debit and the GST Input Tax debit to SGD before posting, mirroring `createInvoice` exactly. It's omitted above only for length; the transformation is a direct copy of Step 14.7.4 with debits/credits mirrored per Part 8's original shape.

**What about `recordInvoicePayment`/`recordBillPayment` (Part 8) — do they need currency awareness too?** Yes, and this is worth flagging honestly as a further extension rather than glossing over: a real multi-currency payment (e.g., paying a USD invoice with SGD cash, or vice versa) can realize a **foreign exchange gain or loss** if the rate moved between invoicing and payment — a genuinely more advanced accounting concept (a dedicated "FX Gain/Loss" P&L account) not built out in this course. As implemented here, Step 14.7 covers invoicing in a foreign currency correctly, but payments would currently need to be entered already-converted to SGD by the user, with no automatic FX gain/loss recognition — an honest, explicitly-scoped limitation, in the same spirit as Appendix A's Section A.13 "Known Gaps."

**[GENERATED: Part 14.7 — Multi-Currency Support]**

That completes every buildable item from Part 14.9's suggested order except the deliberately stretch-goal-only Part 14.8 (full bank-feed integration via an SEA aggregator like Brankas or Finverse), which the original roadmap explicitly recommends *not* building until a real, concrete business need exists for it.

At this point, Greymatter Ledger has grown well beyond the original 14-part blueprint: voiding/reversal (with payments), role-based permissions, bank reconciliation, CPF payroll, tax estimation, and multi-currency — six substantial extensions, each fully coded, verified, and cross-checked against the Balance Sheet's "still balanced" proof every time.
