# Appendix D: Full Route Map

*Corrected for the no-`src/` project structure — every file path now reads `app/...`, `lib/...`, `db/...`, `components/...` at the project root, with `proxy.ts` sitting as a root-level sibling to `app/`.*

Every route in Greymatter Ledger, what renders there, which server actions/queries it calls, its protection status, and how data flows through it. Use this as the map when you're trying to trace "where does this piece of data actually get read or written." This version includes every route added across the original 14 parts plus extensions 14.2–14.8.

## D.1 — Public Routes (No Authentication Required)

| Route | File | Purpose |
|---|---|---|
| `/` | `app/page.tsx` | Default Next.js homepage |
| `/sign-in/[[...sign-in]]` | `app/sign-in/[[...sign-in]]/page.tsx` | Renders Clerk's `<SignIn />` component |
| `/sign-up/[[...sign-up]]` | `app/sign-up/[[...sign-up]]/page.tsx` | Renders Clerk's `<SignUp />` component |

These three are deliberately excluded from `proxy.ts`'s protected route matcher (Part 2) — a signed-out visitor must be able to reach them, or no one could ever sign up in the first place.

---

## D.2 — System / Infrastructure Routes

| Route | File | Purpose |
|---|---|---|
| `/api/inngest` | `app/api/inngest/route.ts` | Exposes `GET`/`POST`/`PUT` via Inngest's `serve()` helper. `GET` lets Inngest's dashboard discover registered functions; `POST` is how Inngest actually invokes one; `PUT` is used during initial sync (Part 11.2, Part 13.7) |

Reachable without Clerk authentication by design — Inngest authenticates requests itself via `INNGEST_SIGNING_KEY` verification inside `serve()`, not via a logged-in user session (see Appendix F, T6).

---

## D.3 — Core Application Routes (Protected)

Every route below requires an active Clerk session **and** an active organization, enforced centrally in `proxy.ts`.

### `/dashboard`
**File:** `app/dashboard/page.tsx`
**Reads:** `currentUser()`, `auth()` (Clerk); calls `getOrCreateOrganization()` (`lib/organizations.ts`), which may **write** a new `organizations` row + seed the Chart of Accounts on first visit.
**Renders:** Welcome message, `<OrganizationSwitcher />`, `<UserButton />`, org-active/no-org panel.
**Special behavior:** The only route where organization auto-provisioning happens.

### `/accounts`
**File:** `app/accounts/page.tsx`
**Server actions called:** reads via `db.select().from(accounts)`; `deactivateAccount()` (`lib/actions/accounts.ts`, Part 14.3) — admin-gated.
**Renders:** Five grouped tables (Assets, Liabilities, Equity, Revenue, Expenses); a "Deactivate" link per row, visible only when `isCurrentUserAdmin()` is true.

### `/customers`
**File:** `app/customers/page.tsx`
**Server actions called:** `getCustomers()`, `createCustomer()`, `deactivateCustomer()` (`lib/actions/customers.ts`).
**Renders:** Add-customer form + list table with Active/Inactive badges.

### `/vendors`
**File:** `app/vendors/page.tsx`
**Server actions called:** `getVendors()`, `createVendor()`, `deactivateVendor()` (`lib/actions/vendors.ts`).
**Renders:** Mirror of `/customers`.

### `/invoices`
**File:** `app/invoices/page.tsx`
**Server actions called:** `getInvoices()` (`lib/actions/invoices.ts`).
**Renders:** List table with status badges, linking to `/invoices/[id]`.

### `/invoices/new`
**File:** `app/invoices/new/page.tsx`
**Server actions called:** `getCustomers()` on load (redirects to `/customers` if empty); `createInvoice()` on submit.
**Writes on submit:** `invoices`, `invoice_lines`, `journal_entries`+`journal_lines` (via `postJournalEntry`, `lib/journal.ts`), and sends an `invoice/created` Inngest event.
**Redirects to:** `/invoices/[id]` on success.

### `/invoices/[id]`
**File:** `app/invoices/[id]/page.tsx`
**Server actions called:** `getInvoiceById(id)` (now also fetches `payments`, per Part 14.2); `recordInvoicePayment()`; `voidInvoice()` (Part 14.2, admin-gated per Part 14.3); `voidPayment()` per row in `<PaymentHistory />` (Part 14.2).
**Writes:** `payments`, `journal_entries`+`journal_lines`, `invoices.amountPaid`/`status`; on void, an additional reversal `journal_entries` row plus `invoices.status = void`.
**404s if:** invoice not found, or belongs to a different organization.

### `/bills`, `/bills/new`, `/bills/[id]`
**Files:** `app/bills/page.tsx`, `app/bills/new/page.tsx`, `app/bills/[id]/page.tsx`
Structurally identical to the invoice routes, using `lib/actions/bills.ts`. `/bills/new` additionally queries `accounts` filtered to `accountType = "expense"` for the per-line expense-account dropdown. `voidBill()`/`voidPayment()` mirror the invoice-side void flow exactly.

### `/reports/profit-and-loss`
**File:** `app/reports/profit-and-loss/page.tsx`
**Reads:** `getAccountBalancesForRange()` (`lib/reports.ts`) — filters to `revenue`/`expense` account types.
**URL params:** `?start=YYYY-MM-DD&end=YYYY-MM-DD`.
**No writes.**

### `/reports/balance-sheet`
**File:** `app/reports/balance-sheet/page.tsx`
**Reads:** `getAccountBalancesAsOf()` plus `getAccountBalancesForRange()` from `1970-01-01` (cumulative Retained Earnings).
**URL params:** `?asOf=YYYY-MM-DD`.
**Notable output:** the live "✅ balanced" proof banner.
**No writes.**

### `/reports/aging`
**File:** `app/reports/aging/page.tsx`
**Reads:** `getArAging()`, `getApAging()` (`lib/aging.ts`) — query `invoices`/`bills` directly, filtered to non-paid/non-void, bucketed by days overdue.
**No writes, no URL params.**

### `/reports/gst-f5`
**File:** `app/reports/gst-f5/page.tsx`
**Reads:** `getGstF5Summary()` (`lib/gst.ts`) — combines `invoice_lines`/`bill_lines` grouped by `gstRate` with account balances for `1200`/`2100`.
**URL params:** `?start=YYYY-MM-DD` (auto-computes a 3-month period).
**No writes.**

### `/reports/tax-estimate`
**File:** `app/reports/tax-estimate/page.tsx` *(Part 14.6)*
**Reads:** `getTaxEstimate()` (`lib/tax.ts`) — combines `getAccountBalancesForRange()` with manually-entered `tax_adjustments`.
**Server actions called:** `addTaxAdjustment()` — admin-gated.
**URL params:** `?start=YYYY-MM-DD&end=YYYY-MM-DD` (defaults to calendar year).
**Writes:** `tax_adjustments` (admin only).

### `/bank-import`
**File:** `app/bank-import/page.tsx`
**Server actions called:** `getImportedTransactions()`, `uploadBankCsv()`, `categorizeImportedTransaction()`, `postImportedTransaction()`, `ignoreImportedTransaction()` (`lib/actions/bank-import.ts`).
**Writes:** `imported_transactions` on upload; status transitions + `journal_entries`/`journal_lines` on posting.

### `/reconciliation`
**File:** `app/reconciliation/page.tsx` *(Part 14.4)*
**Server actions called:** `startReconciliation()`, `toggleReconciliationItem()`, `completeReconciliation()` (admin-gated) — all in `lib/actions/reconciliation.ts`.
**Reads:** `getUnreconciledCashLines()` (`lib/reconciliation.ts`), reusing `getAccountBalancesAsOf()` from Part 9.
**URL params:** `?reconciliationId=...`.
**Writes:** `reconciliations`, `reconciliation_items`.

### `/payroll`
**File:** `app/payroll/page.tsx` *(Part 14.5)*
**Server actions called:** `getEmployees()`, `createEmployee()` (admin-gated), `runPayroll()` (admin-gated), `getPayRuns()` — all in `lib/actions/payroll.ts`.
**Writes:** `employees`, `pay_runs`, `journal_entries`+`journal_lines` (four-line CPF-aware entry).

---

## D.4 — Route → Server Action → Table Traceability Matrix

| Route | Writes to |
|---|---|
| `/dashboard` | `organizations`, `accounts` (seed, first visit only) |
| `/customers` | `customers` |
| `/vendors` | `vendors` |
| `/invoices/new` | `invoices`, `invoice_lines`, `journal_entries`, `journal_lines` |
| `/invoices/[id]` | `payments`, `journal_entries`, `journal_lines`, `invoices` (amountPaid/status/void) |
| `/bills/new` | `bills`, `bill_lines`, `journal_entries`, `journal_lines` |
| `/bills/[id]` | `payments`, `journal_entries`, `journal_lines`, `bills` (amountPaid/status/void) |
| `/accounts` | `accounts` (isActive, admin only) |
| `/reports/*` (P&L, Balance Sheet, Aging, GST F5) | *(none — read-only)* |
| `/reports/tax-estimate` | `tax_adjustments` (admin only) |
| `/bank-import` | `imported_transactions`, and on posting: `journal_entries`, `journal_lines` |
| `/reconciliation` | `reconciliations`, `reconciliation_items` |
| `/payroll` | `employees`, `pay_runs`, `journal_entries`, `journal_lines` |
| *(Inngest jobs, no dedicated route)* | `recurring_invoice_templates` (nextRunDate), `invoices` (via generated `createInvoice` calls), `imported_transactions` (via `syncBankFeeds`, Part 14.8) |

**The one row every write-path in this table ultimately shares:** every writable route that touches money produces, directly or indirectly, a `journal_entries`/`journal_lines` pair through `postJournalEntry` (or its composable wrapper `voidJournalEntry`) — the only exceptions being `/customers`, `/vendors`, `/accounts`'s deactivate action, `/dashboard`'s org/account seeding, and `/reports/tax-estimate`'s adjustment entries, none of which represent a ledger-affecting financial transaction.

---

## D.5 — `proxy.ts`, Fully Reproduced

For quick reference, the complete, final protected-route matcher, at the project root (sibling to `app/`, **not** nested inside it), built incrementally across Parts 2, 7, 12, and extensions 14.4–14.5:

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
  "/bank-import(.*)",
  "/reconciliation(.*)",
  "/payroll(.*)",
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

**File location, confirmed:** `proxy.ts` sits at the project root — a direct sibling of `app/`, `package.json`, `next.config.ts`, and `tsconfig.json`. This is the one file whose exact placement genuinely matters structurally, regardless of whether the rest of the project uses `src/` or not; a copy accidentally placed at `app/proxy.ts` is silently ignored by Next.js.

Note `/settings(.*)` remains reserved in the matcher since Part 2 but was never built out with an actual page across any part of this course — still a ready-made hook for a future settings/preferences feature (organization name editing, default GST rate configuration, default CPF rates) without requiring any `proxy.ts` changes at all.

---

## D.6 — Full Directory Structure Reference (No `src/`)

For a quick sanity check against Appendix G.6's checklist item, here's the complete top-level layout this route map assumes:

```
greymatter-ledger/
├── app/
│   ├── page.tsx
│   ├── layout.tsx
│   ├── sign-in/[[...sign-in]]/page.tsx
│   ├── sign-up/[[...sign-up]]/page.tsx
│   ├── dashboard/page.tsx
│   ├── accounts/page.tsx
│   ├── customers/page.tsx
│   ├── vendors/page.tsx
│   ├── invoices/
│   │   ├── page.tsx
│   │   ├── new/page.tsx
│   │   └── [id]/page.tsx
│   ├── bills/ (same shape as invoices/)
│   ├── reports/
│   │   ├── profit-and-loss/page.tsx
│   │   ├── balance-sheet/page.tsx
│   │   ├── aging/page.tsx
│   │   ├── gst-f5/page.tsx
│   │   └── tax-estimate/page.tsx
│   ├── bank-import/page.tsx
│   ├── reconciliation/page.tsx
│   ├── payroll/page.tsx
│   └── api/inngest/route.ts
├── components/
│   ├── customer-form.tsx
│   ├── vendor-form.tsx
│   ├── invoice-form.tsx
│   ├── bill-form.tsx
│   ├── record-payment-form.tsx
│   ├── void-button.tsx
│   ├── payment-history.tsx
│   ├── reports-nav.tsx
│   ├── bank-csv-upload-form.tsx
│   ├── imported-transaction-row.tsx
│   └── reconciliation-checklist.tsx
├── lib/
│   ├── organizations.ts
│   ├── journal.ts
│   ├── permissions.ts
│   ├── reports.ts
│   ├── aging.ts
│   ├── gst.ts
│   ├── tax.ts
│   ├── reconciliation.ts
│   ├── recurring-dates.ts
│   ├── seed-accounts.ts
│   ├── actions/
│   │   ├── customers.ts
│   │   ├── vendors.ts
│   │   ├── invoices.ts
│   │   ├── bills.ts
│   │   ├── payments.ts
│   │   ├── accounts.ts
│   │   ├── recurring-invoices.ts
│   │   ├── bank-import.ts
│   │   ├── reconciliation.ts
│   │   └── payroll.ts
│   ├── inngest/
│   │   ├── client.ts
│   │   └── functions/
│   │       ├── send-invoice-email.ts
│   │       ├── overdue-reminders.ts
│   │       ├── recurring-invoices.ts
│   │       └── sync-bank-feeds.ts
│   └── bank-feed/
│       ├── types.ts
│       └── providers/brankas.ts
├── db/
│   ├── schema.ts
│   └── index.ts
├── drizzle/ (generated migration files)
├── proxy.ts
├── drizzle.config.ts
├── next.config.ts
├── tsconfig.json
├── package.json
└── .env.local (never committed)
```
