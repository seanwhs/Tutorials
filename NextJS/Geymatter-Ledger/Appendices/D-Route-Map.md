# Appendix D: Full Route Map

Every route in Greymatter Ledger, what renders there, which server actions/queries it calls, its protection status, and how data flows through it. Use this as the map when you're trying to trace "where does this piece of data actually get read or written."

## D.1 — Public Routes (No Authentication Required)

| Route | File | Purpose |
|---|---|---|
| `/` | `src/app/page.tsx` | Default Next.js homepage (scaffolded in Part 1, never customized further in this course — a natural place to eventually add real marketing content) |
| `/sign-in/[[...sign-in]]` | `src/app/sign-in/[[...sign-in]]/page.tsx` | Renders Clerk's `<SignIn />` component | 
| `/sign-up/[[...sign-up]]` | `src/app/sign-up/[[...sign-up]]/page.tsx` | Renders Clerk's `<SignUp />` component |

These three are deliberately excluded from `src/proxy.ts`'s protected route matcher (Part 2) — a signed-out visitor must be able to reach them, or no one could ever sign up in the first place.

---

## D.2 — System / Infrastructure Routes

| Route | File | Purpose |
|---|---|---|
| `/api/inngest` | `src/app/api/inngest/route.ts` | Exposes `GET`/`POST`/`PUT` handlers via Inngest's `serve()` helper. `GET` lets Inngest's dashboard discover registered functions; `POST` is how Inngest actually invokes a function; `PUT` is used during initial sync (Part 11.2, Part 13.7) |

This route is not meant for humans to browse casually — it exists purely for Inngest's cloud service (or local dev server) to communicate with your app. It is intentionally reachable without Clerk authentication, since Inngest itself authenticates requests via `INNGEST_SIGNING_KEY`, not via a logged-in user session.

---

## D.3 — Core Application Routes (Protected)

Every route below requires an active Clerk session **and**, for all but `/dashboard`'s own guard logic, an active organization — enforced centrally in `src/proxy.ts`.

### `/dashboard`
**File:** `src/app/dashboard/page.tsx`
**Reads:** `currentUser()`, `auth()` (Clerk); calls `getOrCreateOrganization()` (Part 3/5) which may **write** a new `organizations` row + seed the Chart of Accounts on first visit for a brand-new org.
**Renders:** Welcome message, `<OrganizationSwitcher />`, `<UserButton />`, and either a green "org active" panel or a yellow "no organization" warning.
**Special behavior:** This is the *only* route where organization auto-provisioning happens — every other route assumes `getOrCreateOrganization()` has already run at least once.

### `/accounts`
**File:** `src/app/accounts/page.tsx`
**Reads:** `db.select().from(accounts).where(eq(accounts.organizationId, ...))`, grouped client-side by `accountType`.
**Writes:** None directly — this is a pure read/view page. (Accounts are only ever written via `seedDefaultChartOfAccounts`.)
**Renders:** Five grouped tables (Assets, Liabilities, Equity, Revenue, Expenses).

### `/customers`
**File:** `src/app/customers/page.tsx`
**Server actions called:** `getCustomers()`, `createCustomer()` (via `<CustomerForm />`'s `useActionState`), `deactivateCustomer()` (inline server action in the table).
**Renders:** Add-customer form + list table with Active/Inactive badges.

### `/vendors`
**File:** `src/app/vendors/page.tsx`
**Server actions called:** `getVendors()`, `createVendor()`, `deactivateVendor()`.
**Renders:** Mirror of `/customers`.

### `/invoices`
**File:** `src/app/invoices/page.tsx`
**Server actions called:** `getInvoices()` (returns invoices `with: { customer: true }`).
**Renders:** List table with status badges, linking to `/invoices/[id]`.

### `/invoices/new`
**File:** `src/app/invoices/new/page.tsx`
**Server actions called:** `getCustomers()` on load (redirects to `/customers` if empty); `createInvoice()` on submit (via `<InvoiceForm />`).
**Writes on submit:** `invoices` row, `invoice_lines` rows, a full `journal_entries`+`journal_lines` set (via `postJournalEntry`), and sends an `invoice/created` Inngest event (Part 11).
**Redirects to:** `/invoices/[id]` on success.

### `/invoices/[id]`
**File:** `src/app/invoices/[id]/page.tsx`
**Server actions called:** `getInvoiceById(id)` (returns `with: { customer: true, lines: true }`); `recordInvoicePayment()` (via `<RecordPaymentForm kind="invoice" />`, only rendered if a balance remains).
**Writes on payment submit:** `payments` row, another `journal_entries`+`journal_lines` set, and updates `invoices.amountPaid`/`status`.
**404s if:** invoice not found, or belongs to a different organization than the currently active one.

### `/bills`, `/bills/new`, `/bills/[id]`
**Files:** `src/app/bills/page.tsx`, `src/app/bills/new/page.tsx`, `src/app/bills/[id]/page.tsx`
**Structurally identical route shape to invoices**, with these differences:
- `/bills/new` additionally queries `accounts` filtered to `accountType = "expense"`, to populate each line's expense-account dropdown.
- `createBill()` groups lines by distinct `expenseAccountId` before posting (Part 8) rather than posting one flat revenue line.
- `recordBillPayment()` posts the reverse journal shape (debit AP, credit Cash) compared to invoice payments.

### `/reports/profit-and-loss`
**File:** `src/app/reports/profit-and-loss/page.tsx`
**Reads:** `getAccountBalancesForRange(organizationId, startDate, endDate)` — filters to `revenue`/`expense` account types.
**URL params:** `?start=YYYY-MM-DD&end=YYYY-MM-DD` (defaults to first-day-of-month → today).
**No writes.**

### `/reports/balance-sheet`
**File:** `src/app/reports/balance-sheet/page.tsx`
**Reads:** `getAccountBalancesAsOf(organizationId, asOfDate)` (asset/liability/equity accounts) **plus** `getAccountBalancesForRange(organizationId, "1970-01-01", asOfDate)` (to compute cumulative Retained Earnings).
**URL params:** `?asOf=YYYY-MM-DD` (defaults to today).
**Notable output:** the live "✅ balanced" / "❌ out of balance" proof banner.
**No writes.**

### `/reports/aging`
**File:** `src/app/reports/aging/page.tsx`
**Reads:** `getArAging(organizationId)`, `getApAging(organizationId)` — query `invoices`/`bills` directly (not `journal_lines`), filtered to non-paid/non-void, bucketed by days overdue.
**No writes, no URL params** (always "as of now").

### `/reports/gst-f5`
**File:** `src/app/reports/gst-f5/page.tsx`
**Reads:** `getGstF5Summary(organizationId, periodStart, periodEnd)` — combines `invoice_lines`/`bill_lines` grouped by `gstRate`, plus `getAccountBalancesForRange` for the `1200`/`2100` account balances.
**URL params:** `?start=YYYY-MM-DD` (auto-computes a 3-month period end).
**No writes.**

### `/bank-import`
**File:** `src/app/bank-import/page.tsx`
**Server actions called:** `getImportedTransactions()`, `uploadBankCsv()` (via `<BankCsvUploadForm />`), and per-row: `categorizeImportedTransaction()`, `postImportedTransaction()`, `ignoreImportedTransaction()` (via `<ImportedTransactionRow />`).
**Writes:** `imported_transactions` rows on upload; status transitions + eventual `journal_entries`/`journal_lines` on posting.

---

## D.4 — Route → Server Action → Table Traceability Matrix

A condensed view of exactly which tables each route can **write** to — useful when debugging "where did this row come from?"

| Route | Writes to |
|---|---|
| `/dashboard` | `organizations`, `accounts` (seed, first visit only) |
| `/customers` | `customers` |
| `/vendors` | `vendors` |
| `/invoices/new` | `invoices`, `invoice_lines`, `journal_entries`, `journal_lines` |
| `/invoices/[id]` | `payments`, `journal_entries`, `journal_lines`, `invoices` (amountPaid/status) |
| `/bills/new` | `bills`, `bill_lines`, `journal_entries`, `journal_lines` |
| `/bills/[id]` | `payments`, `journal_entries`, `journal_lines`, `bills` (amountPaid/status) |
| `/reports/*` | *(none — read-only)* |
| `/bank-import` | `imported_transactions`, and on posting: `journal_entries`, `journal_lines` |
| *(Inngest jobs, no dedicated route)* | `recurring_invoice_templates` (nextRunDate), `invoices` (via generated `createInvoice` calls) |

**The one row every write-path in this table ultimately shares:** every single writable route that touches money produces (directly or indirectly) a `journal_entries`/`journal_lines` pair through `postJournalEntry` — the only two exceptions being `/customers`, `/vendors`, and `/dashboard`'s org/account seeding, none of which represent a financial transaction.

---

## D.5 — `src/proxy.ts` Matcher, Fully Reproduced

For quick reference, the complete, final protected-route list built incrementally across Parts 2, 7, and 12:

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

Note `/settings(.*)` has been reserved in the matcher since Part 2 but was never built out with an actual page in this course — a natural, ready-made hook for a future settings/preferences feature (e.g., organization name editing, default GST rate configuration) without needing any `proxy.ts` changes at all.
