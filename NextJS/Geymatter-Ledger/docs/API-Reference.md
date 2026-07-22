# API / Service Layer Reference

**Product:** GreyMatter Ledger  
**Document type:** API / Service Layer Reference  
**Version:** 1.0  
**Status:** Draft  
**Audience:** Developers, maintainers, technical reviewers  
**Scope:** Server actions, service-layer modules, domain helpers, and background job entry points  

---

# 1. Purpose

This document explains the major service-layer modules and server-side APIs in **GreyMatter Ledger**.

GreyMatter Ledger does not expose a large public REST API in the current version.

Instead, most application behavior is implemented through:

```txt
Next.js Server Actions
Service-layer functions
Route handlers
Inngest functions
```

This reference helps developers understand:

```txt
Which service does what
Where business logic lives
Which functions are safe entry points
Which functions enforce organization scope
Which functions post to the ledger
Which functions write audit logs
```

---

# 2. Architectural Position

The application generally follows this flow:

```txt
UI Component
  |
  v
Server Action
  |
  v
Service Layer
  |
  v
Domain Helpers / Journal Engine
  |
  v
Drizzle ORM
  |
  v
Postgres
```

Example:

```txt
Invoice form
  |
  v
createInvoiceAction()
  |
  v
createInvoiceForCurrentOrganization()
  |
  v
GST helper + journal validation
  |
  v
Database transaction
```

---

# 3. Service Layer Rules

All service-layer functions should follow these principles:

```txt
Do not trust browser-submitted organization IDs.
Use active server-side organization context.
Validate inputs.
Verify referenced records belong to active organization.
Use integer cents for money.
Use basis points for rates.
Post balanced journal entries.
Write audit logs for important actions.
Return typed success/error results where appropriate.
```

---

# 4. Server Actions vs Services

## Server Actions

Server actions live under:

```txt
app/**/actions.ts
```

They:

```txt
Read FormData
Call services
Revalidate paths
Redirect with status messages
```

They should be thin.

---

## Services

Services live under:

```txt
services/
```

They:

```txt
Enforce business rules
Query and mutate database
Call journal engine
Write audit logs
Send events
```

They should contain the real business logic.

---

# 5. Authentication and Organization Services

---

## 5.1 `lib/auth.ts`

### Purpose

Provides server-side helpers for current user and organization context.

---

### `getCurrentUserProfile()`

Returns a compact profile for the signed-in Clerk user.

```ts
getCurrentUserProfile(): Promise<CurrentUserProfile | null>
```

Returns:

```ts
{
  id: string;
  displayName: string;
  primaryEmail: string | null;
  imageUrl: string;
}
```

Used by:

```txt
Dashboard
Auth diagnostics
Audit-related displays
```

---

### `getCurrentOrganizationContext()`

Reads the active Clerk organization context.

```ts
getCurrentOrganizationContext(): Promise<CurrentOrganizationContext | null>
```

Returns:

```ts
{
  id: string;
  slug: string | null;
  role: string | null;
}
```

This is Clerk-side context, not the local database organization.

---

### `getCurrentWorkspaceContext()`

Returns both user and organization context.

```ts
getCurrentWorkspaceContext(): Promise<CurrentWorkspaceContext>
```

Used by:

```txt
Dashboard
Auth diagnostics
Settings
```

---

### `requireActiveOrganization()`

Requires an active Clerk organization.

Throws if none exists.

```ts
requireActiveOrganization(): Promise<CurrentOrganizationContext>
```

---

## 5.2 `services/organizations/get-or-create-organization.ts`

### Purpose

Bridges Clerk organizations to local database organizations.

---

### `findOrganizationByClerkId(clerkOrganizationId)`

Finds local organization by Clerk org ID.

```ts
findOrganizationByClerkId(clerkOrganizationId: string): Promise<Organization | null>
```

---

### `getCurrentDatabaseOrganization()`

Returns local database organization for current Clerk org if already synced.

```ts
getCurrentDatabaseOrganization(): Promise<Organization | null>
```

Does not create.

---

### `getOrCreateCurrentOrganization()`

Gets or creates local database organization for active Clerk org.

```ts
getOrCreateCurrentOrganization(): Promise<Organization | null>
```

This is the main organization sync function.

Used throughout the app.

---

### `syncCurrentOrganizationFromClerk()`

Forces refresh from Clerk into local database.

```ts
syncCurrentOrganizationFromClerk(): Promise<Organization | null>
```

---

### `requireCurrentDatabaseOrganization()`

Requires active synced database organization.

```ts
requireCurrentDatabaseOrganization(): Promise<Organization>
```

Most tenant-scoped services should call this.

---

# 6. Authorization Services

---

## 6.1 `lib/authorization.ts`

### Purpose

Provides role-based access helpers.

---

### `getCurrentOrganizationRole()`

Returns current Clerk organization role.

```ts
getCurrentOrganizationRole(): Promise<string | null>
```

---

### `isCurrentUserOrganizationAdmin()`

Returns whether current user is organization admin.

```ts
isCurrentUserOrganizationAdmin(): Promise<boolean>
```

Recognized roles:

```txt
org:admin
admin
```

---

### `requireOrganizationAdmin()`

Throws if current user is not admin.

```ts
requireOrganizationAdmin(): Promise<void>
```

Used by:

```txt
Audit log page
Journal reversal service
```

---

### `AuthorizationError`

Custom error for authorization failures.

```ts
class AuthorizationError extends Error
```

---

# 7. Account Services

---

## 7.1 `services/accounts/get-accounts.ts`

### Purpose

Tenant-scoped account queries and grouping helpers.

---

### `listCurrentOrganizationAccounts()`

Lists accounts for active organization.

```ts
listCurrentOrganizationAccounts(): Promise<{
  organizationId: string | null;
  accounts: Account[];
}>
```

---

### `countCurrentOrganizationAccounts()`

Counts accounts for active organization.

```ts
countCurrentOrganizationAccounts(): Promise<{
  organizationId: string | null;
  accountCount: number;
}>
```

---

### `groupAccountsByType(accountRows)`

Groups account rows by account type.

```ts
groupAccountsByType(accountRows: Account[]): GroupedAccounts
```

---

## 7.2 `services/accounts/seed-default-chart-of-accounts.ts`

### Purpose

Seeds Singapore-friendly chart of accounts.

---

### `seedDefaultChartOfAccountsForOrganization(organizationId)`

Seeds accounts for specific database organization.

```ts
seedDefaultChartOfAccountsForOrganization(
  organizationId: string
): Promise<SeedChartOfAccountsResult>
```

Idempotent via upsert.

---

### `seedDefaultChartOfAccountsForCurrentOrganization()`

Seeds accounts for active organization.

```ts
seedDefaultChartOfAccountsForCurrentOrganization(): Promise<SeedChartOfAccountsResult>
```

---

## 7.3 `services/accounts/mutate-accounts.ts`

### Purpose

Create and update accounts.

---

### `createAccountForCurrentOrganization(input)`

Creates custom account for active organization.

```ts
createAccountForCurrentOrganization(
  input: CreateAccountInput
): Promise<AccountMutationResult>
```

Validates:

```txt
code
name
type
duplicate code
organization scope
```

---

### `setAccountActiveStateForCurrentOrganization(accountId, isActive)`

Activates/deactivates account.

```ts
setAccountActiveStateForCurrentOrganization(
  accountId: string,
  isActive: boolean
): Promise<AccountMutationResult>
```

Tenant-scoped.

---

## 7.4 `services/accounts/get-accounts-by-code.ts`

### Purpose

Find accounts by code for active organization.

---

### `getCurrentOrganizationAccountsByCode(codes)`

Returns map of account code to account.

```ts
getCurrentOrganizationAccountsByCode(
  codes: string[]
): Promise<Map<string, Account>>
```

---

### `requireCurrentOrganizationAccountsByCode(codes)`

Requires specific account codes.

```ts
requireCurrentOrganizationAccountsByCode<TCode extends string>(
  codes: readonly TCode[]
): Promise<Record<TCode, Account>>
```

Throws `MissingRequiredAccountsError` if missing.

Used by:

```txt
Manual journal tests
Posting workflows needing known system accounts
```

---

# 8. Journal Services

---

## 8.1 `services/journal/validate-post-journal-entry.ts`

### Purpose

Pure journal input validation.

No database.

No Clerk.

No network.

---

### `validatePostJournalEntryInput(rawInput)`

Validates journal input.

```ts
validatePostJournalEntryInput(
  rawInput: PostJournalEntryInput
): JournalInputValidationResult
```

Checks:

```txt
valid date
memo required
valid source type
valid source ID
at least two lines
valid account UUIDs
integer cents
non-negative amounts
exactly one side per line
debits equal credits
total greater than zero
```

---

### `normalizePostJournalEntryInput(input)`

Normalizes strings and defaults.

```ts
normalizePostJournalEntryInput(
  input: PostJournalEntryInput
): NormalizedJournalEntryInput
```

---

### `isValidJournalDateString(value)`

Validates `YYYY-MM-DD`.

```ts
isValidJournalDateString(value: string): boolean
```

---

## 8.2 `services/journal/post-journal-entry.ts`

### Purpose

Core journal posting engine.

---

### `postJournalEntry(rawInput)`

Posts balanced journal entry for active organization.

```ts
postJournalEntry(
  rawInput: PostJournalEntryInput
): Promise<PostedJournalEntryResult>
```

Performs:

```txt
Requires active organization
Reads current user ID
Validates input
Verifies account ownership
Verifies account active state
Inserts journal entry
Inserts journal lines
Uses transaction
```

Returns:

```ts
{
  journalEntry: JournalEntry;
  journalLines: JournalLine[];
  totalDebitCents: number;
  totalCreditCents: number;
}
```

---

## 8.3 `services/journal/journal-errors.ts`

### Purpose

Custom journal validation errors.

---

### `JournalEntryValidationError`

```ts
class JournalEntryValidationError extends Error {
  readonly issues: string[];
}
```

---

### `isJournalEntryValidationError(error)`

Type guard.

```ts
isJournalEntryValidationError(error: unknown): boolean
```

---

## 8.4 `services/journal/get-journal-diagnostics.ts`

### Purpose

Journal diagnostics for active organization.

---

### `getCurrentOrganizationJournalDiagnostics()`

Returns counts and recent entries.

```ts
getCurrentOrganizationJournalDiagnostics(): Promise<JournalDiagnostics>
```

---

## 8.5 `services/journal/get-journal-entries.ts`

### Purpose

Loads recent journal entries with lines.

---

### `listRecentCurrentOrganizationJournalEntries(limit)`

```ts
listRecentCurrentOrganizationJournalEntries(
  limit?: number
): Promise<{
  organizationId: string | null;
  entries: JournalEntryWithLines[];
}>
```

---

## 8.6 `services/journal/reverse-journal-entry.ts`

### Purpose

Reverses posted journal entries.

---

### `reverseJournalEntryForCurrentOrganization(params)`

```ts
reverseJournalEntryForCurrentOrganization({
  journalEntryId,
  reason,
}): Promise<ReverseJournalEntryResult>
```

Requires:

```txt
Admin permission
Active organization
Original entry belongs to organization
Entry not already reversed
Reason provided
```

Creates reversal entry by swapping debits and credits.

Writes audit log.

---

# 9. Customer and Vendor Services

---

## 9.1 `services/customers/customer-services.ts`

### `listCurrentOrganizationCustomers()`

Lists customers for active organization.

```ts
listCurrentOrganizationCustomers(): Promise<{
  organizationId: string | null;
  customers: Customer[];
}>
```

---

### `createCustomerForCurrentOrganization(input)`

Creates customer.

```ts
createCustomerForCurrentOrganization(
  input: ContactInput
): Promise<ContactMutationResult>
```

Writes audit log.

---

## 9.2 `services/vendors/vendor-services.ts`

### `listCurrentOrganizationVendors()`

Lists vendors for active organization.

```ts
listCurrentOrganizationVendors(): Promise<{
  organizationId: string | null;
  vendors: Vendor[];
}>
```

---

### `createVendorForCurrentOrganization(input)`

Creates vendor.

```ts
createVendorForCurrentOrganization(
  input: ContactInput
): Promise<VendorMutationResult>
```

Writes audit log.

---

# 10. Invoice Services

---

## 10.1 `services/invoices/invoice-services.ts`

### Purpose

Creates GST-aware invoices and posts journal entries.

---

### `createInvoiceForCurrentOrganization(input)`

```ts
createInvoiceForCurrentOrganization(
  input: CreateInvoiceInput
): Promise<CreateInvoiceResult>
```

Performs:

```txt
Requires active organization
Validates customer ownership
Calculates GST
Generates invoice number
Creates invoice
Creates invoice line
Posts journal entry
Links journal entry
Writes audit log
Sends invoice.created Inngest event
```

Journal:

```txt
Debit  Accounts Receivable
Credit Sales Revenue
Credit GST Output Tax
```

---

### `getCurrentOrganizationInvoiceDiagnostics()`

Returns invoice counts and recent invoices.

```ts
getCurrentOrganizationInvoiceDiagnostics(): Promise<{
  organizationId: string | null;
  invoiceCount: number;
  invoiceLineCount: number;
  recentInvoices: [...]
}>
```

---

## 10.2 `services/invoices/get-invoices.ts`

### `listCurrentOrganizationInvoices()`

Lists invoices for active organization.

```ts
listCurrentOrganizationInvoices(): Promise<{
  organizationId: string | null;
  invoices: InvoiceListItem[];
}>
```

---

### `getCurrentOrganizationInvoiceDetail(invoiceId)`

Loads invoice detail, lines, customer, and linked journal entry.

```ts
getCurrentOrganizationInvoiceDetail(
  invoiceId: string
): Promise<InvoiceDetail | null>
```

Tenant-safe.

---

## 10.3 `services/invoices/overdue-invoice-services.ts`

### `listOverdueInvoicesForAllOrganizations(asOfDate)`

Used by background job.

```ts
listOverdueInvoicesForAllOrganizations(
  asOfDate: string
): Promise<OverdueInvoiceReminderItem[]>
```

Finds unpaid overdue invoices across organizations.

---

## 10.4 `services/invoices/recurring-invoice-services.ts`

### `createRecurringInvoiceForCurrentOrganization(input)`

Creates recurring invoice profile.

```ts
createRecurringInvoiceForCurrentOrganization(
  input: CreateRecurringInvoiceInput
): Promise<CreateRecurringInvoiceResult>
```

---

### `listCurrentOrganizationRecurringInvoices()`

Lists recurring profiles.

```ts
listCurrentOrganizationRecurringInvoices(): Promise<{
  organizationId: string | null;
  recurringInvoices: RecurringInvoice[];
}>
```

---

### `generateDueRecurringInvoicesForCurrentOrganization(asOfDate)`

Manually generates due recurring invoices for active organization.

```ts
generateDueRecurringInvoicesForCurrentOrganization(
  asOfDate: string
): Promise<{ generatedCount: number }>
```

---

# 11. Bill Services

---

## 11.1 `services/bills/bill-services.ts`

### `createBillForCurrentOrganization(input)`

Creates GST-aware bill and posts journal entry.

```ts
createBillForCurrentOrganization(
  input: CreateBillInput
): Promise<CreateBillResult>
```

Journal:

```txt
Debit  Purchases
Debit  GST Input Tax
Credit Accounts Payable
```

Writes audit log.

---

### `getCurrentOrganizationBillDiagnostics()`

Returns bill counts and recent bills.

```ts
getCurrentOrganizationBillDiagnostics(): Promise<{
  organizationId: string | null;
  billCount: number;
  billLineCount: number;
  recentBills: [...]
}>
```

---

## 11.2 `services/bills/get-bills.ts`

### `listCurrentOrganizationBills()`

Lists bills for active organization.

```ts
listCurrentOrganizationBills(): Promise<{
  organizationId: string | null;
  bills: BillListItem[];
}>
```

---

### `getCurrentOrganizationBillDetail(billId)`

Loads bill detail, lines, vendor, and linked journal entry.

```ts
getCurrentOrganizationBillDetail(
  billId: string
): Promise<BillDetail | null>
```

Tenant-safe.

---

# 12. Payment Services

---

## 12.1 `services/payments/customer-payment-services.ts`

### `recordCustomerPaymentForCurrentOrganization(input)`

Records full payment for invoice.

```ts
recordCustomerPaymentForCurrentOrganization(
  input: RecordCustomerPaymentInput
): Promise<RecordCustomerPaymentResult>
```

Performs:

```txt
Validates invoice ownership
Rejects paid/void invoices
Creates payment
Posts journal entry
Marks invoice paid
Writes audit log
```

Journal:

```txt
Debit  Bank
Credit Accounts Receivable
```

---

### `getCurrentOrganizationCustomerPaymentDiagnostics()`

Returns customer payment diagnostics.

```ts
getCurrentOrganizationCustomerPaymentDiagnostics(): Promise<{
  organizationId: string | null;
  paymentCount: number;
  recentPayments: [...]
}>
```

---

## 12.2 `services/payments/vendor-payment-services.ts`

### `recordVendorPaymentForCurrentOrganization(input)`

Records full payment for bill.

```ts
recordVendorPaymentForCurrentOrganization(
  input: RecordVendorPaymentInput
): Promise<RecordVendorPaymentResult>
```

Journal:

```txt
Debit  Accounts Payable
Credit Bank
```

Marks bill paid.

Writes audit log.

---

### `getCurrentOrganizationVendorPaymentDiagnostics()`

Returns vendor payment diagnostics.

```ts
getCurrentOrganizationVendorPaymentDiagnostics(): Promise<{
  organizationId: string | null;
  paymentCount: number;
  recentPayments: [...]
}>
```

---

# 13. Bank Services

---

## 13.1 `services/bank/bank-import-services.ts`

### `importBankCsvForCurrentOrganization(params)`

Imports CSV content.

```ts
importBankCsvForCurrentOrganization({
  fileName,
  content,
}): Promise<ImportBankCsvResult>
```

Creates:

```txt
bank_imports row
bank_transactions rows
```

---

### `getCurrentOrganizationBankImportDiagnostics()`

Returns bank import and transaction diagnostics.

```ts
getCurrentOrganizationBankImportDiagnostics(): Promise<{
  organizationId: string | null;
  importCount: number;
  transactionCount: number;
  recentTransactions: [...]
}>
```

---

## 13.2 `services/bank/categorize-bank-transaction.ts`

### `categorizeBankTransactionForCurrentOrganization(params)`

Categorizes imported bank transaction.

```ts
categorizeBankTransactionForCurrentOrganization({
  bankTransactionId,
  categoryAccountId,
  notes,
}): Promise<CategorizeBankTransactionResult>
```

Validates:

```txt
Transaction ownership
Account ownership
Account active state
Transaction not posted/reconciled
```

---

## 13.3 `services/bank/post-bank-transaction.ts`

### `postBankTransactionForCurrentOrganization(bankTransactionId)`

Posts categorized bank transaction to ledger.

```ts
postBankTransactionForCurrentOrganization(
  bankTransactionId: string
): Promise<PostBankTransactionResult>
```

Positive amount:

```txt
Debit Bank
Credit Category Account
```

Negative amount:

```txt
Debit Category Account
Credit Bank
```

---

## 13.4 `services/bank/reconcile-bank-transaction.ts`

### `reconcileBankTransactionForCurrentOrganization(bankTransactionId)`

Marks posted bank transaction as reconciled.

```ts
reconcileBankTransactionForCurrentOrganization(
  bankTransactionId: string
): Promise<ReconcileBankTransactionResult>
```

Requires:

```txt
Transaction belongs to active organization
Status is posted
Journal entry exists
Not already reconciled
```

---

# 14. Report Services

---

## 14.1 `services/reports/ledger-report-services.ts`

### `getLedgerAccountBalancesForCurrentOrganization(dateRange)`

Returns account balances from journal lines.

```ts
getLedgerAccountBalancesForCurrentOrganization(
  dateRange: ReportDateRange
): Promise<{
  organizationId: string | null;
  balances: AccountLedgerBalance[];
}>
```

---

### `groupBalancesByAccountType(balances)`

Groups balances by:

```txt
asset
liability
equity
income
expense
```

---

## 14.2 `services/reports/profit-and-loss-service.ts`

### `calculateProfitAndLossFromBalances(params)`

Pure calculation.

```ts
calculateProfitAndLossFromBalances(params): ProfitAndLossReport
```

---

### `getProfitAndLossReport(dateRange)`

Loads ledger balances and returns P&L.

```ts
getProfitAndLossReport(
  dateRange: ReportDateRange
): Promise<ProfitAndLossReport>
```

---

## 14.3 `services/reports/balance-sheet-service.ts`

### `calculateBalanceSheetFromBalances(params)`

Pure calculation.

```ts
calculateBalanceSheetFromBalances(params): BalanceSheetReport
```

---

### `getBalanceSheetReport(asOfDate)`

Returns Balance Sheet.

```ts
getBalanceSheetReport(asOfDate: string): Promise<BalanceSheetReport>
```

---

## 14.4 `services/reports/aging-report-services.ts`

### `getAccountsReceivableAgingReport(asOfDate)`

Returns AR aging.

```ts
getAccountsReceivableAgingReport(
  asOfDate: string
): Promise<AgingReport>
```

---

### `getAccountsPayableAgingReport(asOfDate)`

Returns AP aging.

```ts
getAccountsPayableAgingReport(
  asOfDate: string
): Promise<AgingReport>
```

---

## 14.5 `services/reports/gst-f5-service.ts`

### `calculateGstF5StyleReportFromBalances(params)`

Pure GST report calculation.

```ts
calculateGstF5StyleReportFromBalances(params): GstF5StyleReport
```

---

### `getGstF5StyleReport(dateRange)`

Returns GST F5-style report.

```ts
getGstF5StyleReport(
  dateRange: ReportDateRange
): Promise<GstF5StyleReport>
```

---

# 15. Audit Services

---

## 15.1 `services/audit/audit-log-service.ts`

### `writeAuditLog(input)`

Writes audit event.

```ts
writeAuditLog(input: WriteAuditLogInput): Promise<AuditLog>
```

Input:

```ts
{
  action: AuditAction;
  entityType: string;
  entityId?: string | null;
  message: string;
  metadata?: Record<string, unknown>;
}
```

---

### `listCurrentOrganizationAuditLogs()`

Lists recent audit logs for active organization.

```ts
listCurrentOrganizationAuditLogs(): Promise<{
  organizationId: string | null;
  logs: AuditLog[];
}>
```

---

# 16. Domain Helpers

---

## 16.1 `lib/money.ts`

### `formatMoney(amountCents)`

Formats cents as SGD.

```ts
formatMoney(10900); // S$109.00
```

---

### `dollarsToCents(value)`

Parses dollar input into cents.

```ts
dollarsToCents("109.00"); // 10900
```

---

## 16.2 `lib/accounting/gst.ts`

### `calculateGstFromExclusiveAmount(subtotalCents, rate)`

Calculates GST.

---

### `calculateInvoiceLineTotals(params)`

Calculates quantity, subtotal, GST, total.

---

### `sumInvoiceLineTotals(lines)`

Sums line calculations.

---

## 16.3 `lib/reports/balance-sign.ts`

### `calculateSignedBalanceCents(params)`

Calculates report-friendly balance based on account type.

---

## 16.4 `lib/reports/date-range.ts`

### `normalizeReportDateRange(params)`

Normalizes report date range.

---

## 16.5 `lib/bank/parse-bank-csv.ts`

### `parseBankCsv(content)`

Parses bank CSV.

Expected headers:

```txt
date,description,amount
```

---

# 17. Server Action Reference

Key server action files:

```txt
app/accounts/actions.ts
app/customers/actions.ts
app/vendors/actions.ts
app/invoices/actions.ts
app/invoices/[invoiceId]/actions.ts
app/bills/actions.ts
app/bills/[billId]/actions.ts
app/bank/actions.ts
app/settings/database/journal/actions.ts
app/settings/background-jobs/actions.ts
app/invoices/recurring/actions.ts
```

Server actions should:

```txt
Parse FormData
Call service
Revalidate paths
Redirect
```

They should not contain core accounting logic.

---

# 18. Inngest Function Reference

Files:

```txt
inngest/client.ts
inngest/events.ts
inngest/functions.ts
app/api/inngest/route.ts
```

Functions:

```txt
backgroundHealthCheck
invoiceCreatedConfirmation
dailyOverdueInvoiceReminders
dailyRecurringInvoiceScheduler
```

Events:

```txt
app/health.check
invoice.created
```

---

# 19. Error Handling Pattern

Many services return:

```ts
| { ok: true; ... }
| { ok: false; error: string }
```

Example:

```ts
const result = await createInvoiceForCurrentOrganization(input);

if (!result.ok) {
  redirect(`/invoices?status=error&message=${encodeURIComponent(result.error)}`);
}
```

Journal validation may throw:

```ts
JournalEntryValidationError
```

Authorization may throw:

```ts
AuthorizationError
```

---

# 20. Adding a New Service

Recommended pattern:

```ts
export async function doThingForCurrentOrganization(input: Input) {
  const organization = await requireCurrentDatabaseOrganization();

  // validate input
  // verify related records belong to organization
  // perform transaction if needed
  // post journal entry if accounting event
  // write audit log if important
  // return typed result
}
```

---

# 21. Service Layer Review Checklist

When reviewing or adding a service, check:

```txt
Does it require active organization?
Does it avoid trusting organization ID from the browser?
Does it validate inputs?
Does it verify referenced record ownership?
Does it use integer cents?
Does it post balanced journal entries?
Does it write audit logs where appropriate?
Does it enforce admin permission if sensitive?
Does it use transactions for multi-step writes?
Does it revalidate affected routes through server actions?
```

---

# 22. Final Service Layer Rule

The UI may ask for work.

The service layer decides whether the work is valid.

The journal engine decides whether the accounting is valid.

The database stores the result.

That separation keeps GreyMatter Ledger maintainable and safe.
