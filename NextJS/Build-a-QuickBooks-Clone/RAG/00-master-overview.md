## 📄 FILE: `00-master-overview.md`
```markdown
# QB Clone: Master Overview and Architecture

This document is file 1 of 8 in a consolidated reference for building a QuickBooks-style double-entry accounting SaaS application from scratch, using **Next.js 16**, Clerk, Neon (Postgres), Drizzle ORM, and Inngest, deployed for free on Vercel. The other 7 files each cover one stage of the build in full, with complete copy-typeable code and troubleshooting. Read this file first for orientation and the full architecture, then proceed through files 2-8 in order.

**Version note:** this build targets **Next.js 16** (App Router, React 19, Turbopack as the default bundler), requiring **Node.js 20.9+ (Node 22 LTS recommended)**. Two conventions carried through every file in this set: (1) `params`/`searchParams` are `Promise`-based and must be `await`-ed; (2) the request-interception file is named **`src/proxy.ts`**, not the older `src/middleware.ts` (Next.js 16 renamed it; the Clerk API inside, `clerkMiddleware`, is unchanged).

## Companion files in this set

1. 00 Master Overview and Architecture (this file)
2. 01 Foundations - Environment, Next.js, Toolbox Concepts (covers original Parts 1-3)
3. 02 Auth and Database Foundation - Clerk, Organizations, Neon, Drizzle (covers original Parts 4-7)
4. 03 Accounting Core - Double-Entry Theory, Chart of Accounts, Journal Engine (covers original Parts 8-10)
5. 04 Core Features - Customers, Vendors, Invoices, Bills, Payments (covers original Parts 11-15)
6. 05 Reports - Profit and Loss, Balance Sheet, AR/AP Aging (covers original Parts 16-18)
7. 06 Automation and Bank Data - Inngest Jobs, Cron, CSV Import, Plaid Overview (covers original Parts 19-22)
8. 07 Deployment and Roadmap - Free Vercel Hosting, Phase 2/3 Plan (covers original Parts 23-24)

Each file is self-contained: it includes the plain-English concept explanation, every command to run, the complete contents of every file to create or edit, testing steps, a checkpoint, and troubleshooting - merged together rather than split across multiple notes, specifically so this set can be handed to another LLM (or read end to end) as compact, complete context.

## What you are building

A multi-tenant SaaS accounting application where:
- Each user creates or joins a "company" (a Clerk Organization = one company file, exactly like QuickBooks separates each business into its own company file)
- Each company has a Chart of Accounts, Customers, Vendors, Invoices, and Bills
- Every financial action (sending an invoice, receiving a bill, recording a payment) automatically produces a correct, balanced double-entry accounting journal entry behind the scenes
- Three real reports (Profit & Loss, Balance Sheet, AR/AP Aging) are computed live, entirely from the underlying ledger data
- Background jobs handle emailing invoices and sending overdue reminders, including on a recurring schedule, via Inngest
- Bank transactions can be imported from a CSV file and categorized into the right accounts, producing journal entries
- The whole application deploys to the real internet for free (Vercel + Neon + Clerk + Inngest free tiers, no credit card anywhere)

## The full stack and why each piece exists

- **Next.js 16 (App Router)** - the web framework. Provides file-based routing, Server Components (render on the server, can talk directly to the database), Server Actions (form submissions handled by plain server-side functions with no separate API route needed), and API routes when needed. Turbopack is the default dev/build bundler; dynamic request data (`params`, `searchParams`, `cookies()`, `headers()`) is `Promise`-based and must be awaited.
- **Clerk** - hosted authentication (sign up/sign in/sessions) plus a built-in **Organizations** feature used as the multi-tenancy mechanism: **1 Clerk Organization = 1 company file**. Every database row belonging to a company carries an `org_id` referencing this. Route protection is wired through `src/proxy.ts` (Next.js 16's renamed `middleware.ts`).
- **Neon** - free, serverless-friendly hosted Postgres. Provides both a **pooled** connection string (`-pooler` in the hostname, used by the running app, since serverless functions may open many concurrent short-lived connections) and an **unpooled/direct** connection string (used only for schema migrations, run from your own machine).
- **Drizzle ORM** - define database tables as TypeScript, query with type-checked function calls instead of raw SQL strings, and manage schema changes via generated migration files (`drizzle-kit`).
- **Inngest** - background job and scheduled/cron job runner. Two patterns: **event-triggered functions** (react to something that happened, e.g. `invoice/created`) and **cron-triggered functions** (run on a timer with nobody present, e.g. daily overdue reminders). Functions are broken into named `step.run(...)` stages for automatic, safe retries.
- **Vercel** - free hosting for the deployed app, made by the creators of Next.js. Deploying is near one-click, and `git push` to the main branch auto-triggers a new deployment (continuous deployment).

## The one non-negotiable architectural rule

**Every financial feature must post through one shared, transaction-safe journal posting function (`postJournalEntry`), and every report must read only from the ledger tables (`journal_entries` / `journal_lines`), never compute totals directly from `invoices`, `bills`, or any other feature table.**

This is the actual hard part of building real accounting software (most "QuickBooks clone" tutorials skip it and just build pretty invoice forms with no real books behind them). Everything else in this build - the schema design, the Server Action patterns, the report queries - exists in service of this one rule.

## Double-entry accounting in one paragraph (full detail in file 03)

Every transaction has two or more lines; total debits must always equal total credits, with no exceptions, on every single entry. Five account types exist: Asset, Liability, Equity, Income, Expense. Asset and Expense accounts are "debit-normal" (a debit increases them). Liability, Equity, and Income accounts are "credit-normal" (a credit increases them). A Balance Sheet's fundamental equation, Assets = Liabilities + Equity, must always hold if every entry posted through the system was correctly balanced - this makes report correctness a live integrity check on the whole ledger.

## Full data model (all tables across the whole build, for reference)

- `organizations` - mirrors a Clerk Organization; id is the Clerk org id (text, starts with `org_`)
- `accounts` - Chart of Accounts: id, orgId, code, name, type (enum: asset/liability/equity/income/expense), subtype (text: bank/accounts_receivable/accounts_payable/income/expense/etc), normalBalance (enum: debit/credit), parentId, isActive
- `journal_entries` - id, orgId, date, memo, status (enum: posted/void), sourceType (enum: manual/invoice/bill/payment_received/payment_made/opening_balance/bank_transaction/reversal), sourceId
- `journal_lines` - id, entryId, accountId, debitCents (bigint), creditCents (bigint) - money is ALWAYS integer cents, never floating point
- `customers` / `vendors` - id, orgId, name, email, phone, billingAddress, notes, isActive
- `invoices` - id, orgId, customerId, invoiceNumber, issueDate, dueDate, status (enum: draft/sent/paid/partially_paid/void), totalCents
- `invoice_lines` - id, invoiceId, description, quantity, unitPriceCents, amountCents
- `bills` - id, orgId, vendorId, billNumber, billDate, dueDate, status (enum: open/paid/partially_paid/void), totalCents
- `bill_lines` - id, billId, description, quantity, unitPriceCents, amountCents
- `payments` / `payment_applications` - customer payments and which invoice(s) they were applied to
- `bill_payments` / `bill_payment_applications` - vendor payments and which bill(s) they were applied to
- `recurring_invoice_templates` - id, orgId, customerId, description, amountCents, dayOfMonth, isActive, lastGeneratedDate
- `bank_transactions` - id, orgId, bankAccountId, transactionDate, description, amountCents (signed: positive=in, negative=out), status (uncategorized/categorized), categorizedAccountId, journalEntryId

## Build order (why this order, briefly)

1. Environment + Next.js skeleton (nothing works without this)
2. Auth + multi-tenancy (every later feature needs to know who/which company)
3. Database + ORM (nothing persists without this)
4. Accounting theory + Chart of Accounts + journal engine (the core rule everything else obeys)
5. Customers/Vendors/Invoices/Bills/Payments (real features, all wired into the journal engine)
6. Reports (the payoff - computed purely from ledger data built in step 5)
7. Automation (background/scheduled jobs reacting to real events that now exist)
8. Bank data (CSV import, optional Plaid) - another way data enters the same ledger
9. Deployment (put it on the real internet, free)
10. Roadmap (Phase 2/3: Stripe, roles/permissions, editing/voiding via reversal entries, payroll, etc)

## Conventions used consistently across every code file in this series

- Money is always stored as integer cents (`bigint` columns named like `totalCents`, `amountCents`, `debitCents`, `creditCents`). Convert dollars-to-cents only at the boundary where a human types a dollar amount into a form: `Math.round(dollarValue * 100)`.
- Every Server Action re-checks `const { orgId } = await auth();` and throws if missing, even on routes already protected by `src/proxy.ts` - never trust that a request reaching a mutation was already validated elsewhere.
- Every Server Action that accepts a foreign-key style ID from a form (e.g. a chosen account, customer, or invoice) re-fetches that row from the database and verifies `row.orgId === orgId` before using it - never trust a client-submitted ID belongs to the right organization.
- Any operation that must be all-or-nothing (e.g. "create an invoice AND post its journal entry") is wrapped in one `db.transaction(async (tx) => {...})` block, with every insert/update inside using `tx` instead of `db`.
- Every dynamic route uses Next.js's `[id]` folder convention with `params: Promise<{ id: string }>` (awaited, per Next.js 16 convention), and every detail page checks that the fetched row's `orgId` matches the current session's `orgId`, calling `notFound()` if not - this prevents one organization from viewing another's data by guessing/editing a URL.

Proceed to file "01 Foundations - Environment, Next.js, Toolbox Concepts" to begin the hands-on build.
```
