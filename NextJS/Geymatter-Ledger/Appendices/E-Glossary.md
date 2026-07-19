# Appendix E: Consolidated Glossary

Every term introduced across all fourteen parts, in one alphabetized reference — both the accounting vocabulary (taught from scratch in Part 4) and the technical vocabulary (introduced as needed from Part 1 onward). Each entry notes which part first introduced it, so you can jump back for the full explanation and worked examples if a definition alone isn't enough.

## E.1 — Accounting & Business Terms

**Accounts Payable (AP)** — Money owed *by* the business to its vendors/suppliers; a Liability account (code `2000`). *(Part 4, 5, 8)*

**Accounts Receivable (AR)** — Money owed *to* the business by its customers; an Asset account (code `1100`). *(Part 4, 5, 7)*

**Accrual Accounting** — Recognizing revenue/expenses when they're *earned or incurred*, not necessarily when cash physically moves. The opposite is cash-basis accounting. Greymatter Ledger implements accrual accounting throughout — revenue is recognized when an invoice is issued, not when it's paid. *(Part 4)*

**Aging (AR/AP Aging)** — A report bucketing unpaid invoices/bills by how many days overdue they are (Current, 1–30, 31–60, 61–90, 90+ days). Answers "who owes me money, and who am I overdue in paying?" *(Part 4, 9)*

**Assets** — Things the business owns that have value (Cash, Accounts Receivable, Equipment). One of the five fundamental categories. Debit-normal. *(Part 4)*

**Balance Sheet** — A report showing Assets, Liabilities, and Equity as of a single point in time, proving the equation `Assets = Liabilities + Equity`. *(Part 4, 9)*

**Balance Sheet Equation** — `Assets = Liabilities + Equity`. Must hold true for every business, at every moment, without exception. The foundation the entire course is built on. *(Part 4)*

**Chart of Accounts** — The complete, personalized list of every account (bucket) a specific business tracks. *(Part 4, 5)*

**Credit** — Simply "the right side" of a journal line. Increases Liabilities, Equity, and Revenue; decreases Assets and Expenses. *(Part 4)*

**Debit** — Simply "the left side" of a journal line. Increases Assets and Expenses; decreases Liabilities, Equity, and Revenue. *(Part 4)*

**Double-Entry Bookkeeping** — The discipline that every transaction touches at least two accounts, and total debits must always equal total credits. *(Part 4)*

**Equity** — The owner's stake in the business (Assets minus Liabilities). One of the five fundamental categories. Credit-normal. *(Part 4)*

**Expenses** — Money spent to run the business (rent, supplies, wages). One of the five fundamental categories. Debit-normal. *(Part 4)*

**Fiscal Period** — A defined date range (month, quarter, year) used to bound reports like the P&L. *(Part 4)*

**General Ledger** — A report showing, for one specific account, every journal line ever posted to it, with a running balance. *(Part 4)*

**GST (Goods and Services Tax)** — Singapore's consumption tax (9% standard rate as of this course). Conceptually equivalent to VAT elsewhere. *(Part 4, 5, 7, 8, 10)*

**GST F5** — Singapore's quarterly GST filing return, summarizing output tax collected, input tax claimed, and the net amount owed to or refundable by IRAS. *(Part 10)*

**GST Input Tax (Receivable)** — GST paid to vendors on purchases, reclaimable from IRAS; an Asset account (code `1200`), debit-normal. *(Part 4, 5, 8, 10)*

**GST Output Tax (Payable)** — GST collected from customers on sales, owed to IRAS; a Liability account (code `2100`), credit-normal. *(Part 4, 5, 7, 10)*

**IRAS** — The Inland Revenue Authority of Singapore; the government body GST and corporate tax are filed with. *(Part 4, 10, 14)*

**Journal Entry** — One complete financial event — the "envelope" containing a group of journal lines that must balance internally. *(Part 4, 6)*

**Journal Line** — One single debit or credit within a journal entry. *(Part 4, 6)*

**Ledger** — The complete, permanent collection of every posted journal entry, forever — the master record every report derives from. *(Part 4, 6)*

**Liabilities** — Things the business owes to others (Accounts Payable, loans, taxes owed). One of the five fundamental categories. Credit-normal. *(Part 4)*

**Normal Balance** — The debit/credit side that *increases* a given account, based on its category. Stored explicitly as a column on `accounts`. *(Part 4, 5)*

**Posting** — The act of permanently saving a journal entry into the ledger; treated as historical fact once posted. *(Part 4, 6, 14)*

**Profit & Loss (P&L) / Income Statement** — A report showing total Revenue minus total Expenses over a date range. *(Part 4, 9)*

**Reconciliation** — Comparing internal records (the ledger) against an external source of truth (a bank statement) to confirm they match. *(Part 4, 12, 14)*

**Retained Earnings** — Cumulative historical Net Income, folded into Equity for Balance Sheet purposes. *(Part 5, 9)*

**Revenue** — Money earned from doing business. One of the five fundamental categories. Credit-normal. *(Part 4)*

**Subtype** — A finer-grained classification within an `accountType` (e.g., "bank," "fixed_asset," "gst_output_tax"). *(Part 5)*

**Trial Balance** — An internal sanity-check report confirming total debits across the entire ledger equal total credits. *(Part 4)*

---

## E.2 — Technical & Architectural Terms

**App Router** — The modern Next.js convention for organizing pages and server logic (as opposed to the older Pages Router), used throughout this course. *(Part 1)*

**Atomic / Atomicity** — A guarantee that a group of operations either *all* succeed together or *all* fail together, with no partial, half-completed state possible. Achieved via database transactions. *(Part 6)*

**Client Component** — A React component explicitly marked `"use client"`, which runs in the browser and can hold interactive state (`useState`, event handlers). Used for forms requiring dynamic interactivity (invoice line items, the bank CSV review table). *(Part 7)*

**Clerk** — The hosted authentication service handling sign-up, sign-in, sessions, and Organizations. *(Part 1, 2)*

**Connection String (Pooled vs. Unpooled)** — A single string packaging a database's address and credentials. Pooled (`-pooler` hostname) shares a smaller number of real connections across many callers, suited to serverless environments; unpooled gives each caller a dedicated connection, suited to one-off operations like migrations. *(Part 3)*

**Continuous Deployment** — Vercel's behavior of automatically triggering a new production deployment every time you `git push` to `main`. *(Part 13)*

**Cron / Cron Schedule** — A syntax (`minute hour day month weekday`) describing a recurring time-based trigger, used by Inngest for scheduled (non-event-driven) functions. *(Part 11)*

**CRUD** — Create, Read, Update, Delete — the four basic data operations. *(Part 7)*

**Database Transaction** — A group of statements that either all commit permanently or are all automatically rolled back together if any one fails. The mechanism underlying `postJournalEntry`'s atomicity guarantee. *(Part 6)*

**Denormalization** — Deliberately storing a value (like an invoice's `total`) that could technically be derived from other data, for read performance/simplicity — at the cost of needing discipline to keep it in sync. *(Part 7)*

**Drizzle (ORM)** — The toolkit translating TypeScript schema definitions and queries into real Postgres operations, with compile-time type-checking. *(Part 1, 3)*

**Drizzle Studio** — A visual, browser-based tool (`npm run db:studio`) for inspecting real database contents during development. *(Part 3)*

**Enum (Postgres Enum)** — A database-enforced "multiple choice" column type, rejecting any value outside a fixed, predefined list (e.g., `account_type`). *(Part 5)*

**Environment Variable** — A configuration value (often a secret) stored outside your code, read at runtime, kept out of Git via `.gitignore`. *(Part 2)*

**Event (Inngest)** — An announcement that "something happened" (e.g., `"invoice/created"`), carrying data, with no logic of its own — something else *listens* for it. *(Part 11)*

**Executor (pattern)** — A function parameter accepting either a top-level transactional client or a nested `tx` object, letting `postJournalEntry` participate in a caller's larger transaction without duplicating its own validation logic. *(Part 7)*

**Foreign Key** — A column that references another table's (or, self-referentially, the same table's) row, enforced by the database. *(Part 3, 5)*

**Function (Inngest)** — A worker that listens for a specific event or runs on a schedule, doing background/async work outside the request-response cycle. *(Part 11)*

**Get-or-Create (pattern)** — Look for an existing matching row first; only insert a new one if none exists — prevents duplicate rows on repeated calls. *(Part 3)*

**Idempotent** — An operation that produces the same end result no matter how many times it's triggered under the same starting conditions — critical for scheduled jobs, which may occasionally fire more than once. *(Part 11)*

**Inngest** — The service handling background and scheduled jobs via events and functions. *(Part 1, 11)*

**Middleware / `proxy.ts`** — Next.js 16's renamed replacement for `middleware.ts`; a file intercepting every request to enforce route protection before any page renders. *(Part 2)*

**Neon** — The hosted, serverless Postgres database provider used throughout this course. *(Part 1, 3)*

**Node.js** — The runtime letting JavaScript/TypeScript execute outside the browser, directly on a server or your own machine. *(Part 1)*

**Numeric (Postgres type)** — An exact decimal storage type (as opposed to floating point), used for every money-related column to avoid rounding errors. *(Part 6)*

**ORM (Object-Relational Mapper)** — A toolkit (Drizzle, in this course) that lets you interact with a database using code objects/functions instead of raw SQL strings. *(Part 3)*

**Postgres** — The specific relational database system used, hosted by Neon. *(Part 1, 3)*

**Relational Query API (Drizzle)** — Drizzle's `db.query.table.findMany({ with: {...} })` style, used for fetching related rows across tables (e.g., an invoice with its customer and lines) more readably than manual joins. *(Part 7)*

**`revalidatePath`** — A Next.js function telling the framework "the data behind this path has changed — discard any cached version and regenerate it fresh." *(Part 7)*

**Route Handler** — A file (`route.ts`) exposing raw HTTP methods (`GET`, `POST`, etc.) at a given path, used here specifically for `/api/inngest`. *(Part 11)*

**Seeding** — Populating a database with initial, known-good starter data (the default Chart of Accounts) automatically, typically at record-creation time. *(Part 5)*

**Server Action** — A plain async function marked `"use server"`, callable directly from a form or client code, that runs exclusively on the server — Next.js handles the network plumbing invisibly. Used for every create/update/delete operation in this course (`createInvoice`, `recordInvoicePayment`, etc.). *(Part 7)*

**Server Component** — The default kind of React component in the App Router (no `"use client"` needed), which runs only on the server and can directly query the database (e.g., every `page.tsx` that calls a `get...()` function). *(Part 7)*

**`src/` Directory** — The convention of nesting all application code (including `app/`) inside a `src/` folder, kept separate from root-level config files; required for Next.js 16's `src/proxy.ts` placement. *(Part 1)*

**SSR (Server-Side Rendering)** — Implicit throughout this course via Server Components: pages are rendered on the server, with data already fetched, before being sent to the browser.

**Step (`step.run()`, Inngest)** — A wrapped unit of work inside an Inngest function, letting Inngest retry just that one step (not the whole function) if it fails, and giving each step its own entry in the execution log. *(Part 11)*

**Tailwind CSS** — The utility-class-based styling approach used throughout this course (`class="bg-blue-500 text-white rounded"` instead of separate stylesheets). *(Part 1)*

**TypeScript** — JavaScript with an added static type-checking layer, catching data-shape mistakes before code ever runs — chosen throughout this course specifically for the safety it adds to money-handling logic. *(Part 1)*

**`useActionState`** — A React hook pairing a Server Action with a form's submission lifecycle, tracking pending/error/success state without manual fetch code. *(Part 7)*

**Vercel** — The hosting platform (built by the Next.js team) used for production deployment, offering native, zero-config support for Server Actions, the App Router, and serverless functions. *(Part 1, 13)*

**WebSocket / Pool Client (`drizzle-orm/neon-serverless`)** — The database client variant capable of holding one continuous connection open across multiple statements, required specifically for real multi-statement transactions (`db.transaction()`), as opposed to the plain HTTP client used for simple one-shot queries. *(Part 6)*

---

## E.3 — Course-Specific Naming Conventions

A few patterns that recur by name across the entire codebase, worth recognizing on sight:

| Pattern | Example | Meaning |
|---|---|---|
| `getOrCreateX()` | `getOrCreateOrganization()` | Look up an existing row; create it only if missing |
| `create X()` (server action) | `createInvoice()`, `createBill()` | Full atomic write: header + lines + journal entry, in one transaction |
| `get X()` (server action) | `getInvoices()`, `getCustomers()` | Read-only, always scoped to the current organization |
| `X ByID()` | `getInvoiceById()`, `getBillById()` | Single-row fetch, scoped to both the ID **and** the organization (never ID alone) |
| `record X Payment()` | `recordInvoicePayment()`, `recordBillPayment()` | Payment + journal entry + status/amountPaid update, atomically |
| `postX()` | `postJournalEntry()`, `postImportedTransaction()` | The moment something becomes a permanent, balanced ledger fact |
| `X reasons` in error messages | `"Journal entry does not balance: ..."` | Every thrown error in this course explains *why*, never a bare generic failure |

---

## E.4 — The One Idea That Ties Every Term Together

If you remember nothing else from this glossary, remember this: **every technical term in Section E.2 exists in service of enforcing every accounting term in Section E.1.** The `numeric` type exists so debits and credits are exact. The database transaction exists so an entry is never half-saved. The executor pattern exists so a bill's expense lines and its journal entry commit as one unit. `postJournalEntry` exists because Part 4's one rule — debits must equal credits — has to be true, always, with no exceptions, and code is how that promise gets kept.
