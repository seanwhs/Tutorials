# Part 0: Introduction

Welcome to **GreyMatter Ledger** — a hands-on tutorial series where we will build a modern, Singapore-ready double-entry accounting web application from the ground up.

This is not a toy “CRUD app.” By the end of the series, GreyMatter Ledger will behave like the foundation of a real accounting SaaS product for small businesses, accountants, and finance teams.

We will start with an empty folder and progressively build a complete application that supports authentication, company workspaces, accounting ledgers, invoicing, GST-aware transactions, reports, reconciliation, background automation, and production deployment.

---

## What We Are Building

GreyMatter Ledger is a full-stack accounting application designed around one core rule:

> Every financial transaction must be recorded using double-entry accounting.

In simple terms, double-entry accounting means every money movement has at least two sides.

For example, if a customer pays you S$100:

- Your bank balance increases by S$100.
- Your customer no longer owes you S$100.

In accounting language:

```txt
Debit  Bank                  S$100
Credit Accounts Receivable   S$100
```

The total debits and total credits must always match.

That one rule is what gives accounting software its reliability. It prevents “mystery money” from appearing or disappearing.

GreyMatter Ledger will enforce that rule in code.

---

## Final Application Preview

By the end of the series, the app will include the following major capabilities.

### 1. Public Landing Page

A professional marketing-style landing page for the application.

It will introduce GreyMatter Ledger, explain the value proposition, and provide sign-in/sign-up entry points.

---

### 2. Authentication

Users will be able to:

- Sign up
- Sign in
- Sign out
- Access protected pages only after authentication

We will use **Clerk** for authentication.

Think of Clerk as the secure front door of the application. Instead of writing password storage, login forms, session cookies, and user security ourselves, we delegate that responsibility to a battle-tested authentication provider.

---

### 3. Company / Organization Workspaces

Accounting data belongs to a company, not merely to an individual user.

A single user may work with several companies, such as:

- Their own business
- A client company
- A side project
- A test organization

We will use **Clerk Organizations** to model companies.

This lets a user switch between different company workspaces while keeping each company’s accounting records isolated.

This is called **multi-tenancy**.

A tenant is one isolated customer or organization inside a shared application.

A useful analogy is an office building:

- The building is the application.
- Each office unit is one company.
- Tenants share the same building infrastructure.
- But each tenant’s documents stay inside their own locked office.

---

### 4. Database-Backed Multi-Tenant Accounting

We will use **Neon Postgres** as our database and **Drizzle ORM** as our type-safe database toolkit.

Every business table will include an organization identifier so data stays scoped to the active company.

For example:

```txt
organizations
accounts
customers
vendors
invoices
bills
journal_entries
journal_lines
payments
audit_logs
bank_transactions
```

When a user is viewing Company A, they must never see Company B’s records.

That isolation will be enforced at the application level by carefully filtering every query with the current organization ID.

---

### 5. Chart of Accounts

The **chart of accounts** is the master list of financial categories used by the business.

Examples include:

```txt
1000 Bank
1100 Accounts Receivable
2000 Accounts Payable
2100 GST Payable
4000 Sales Revenue
5000 Cost of Goods Sold
6000 Rent Expense
```

Think of the chart of accounts like labeled drawers in a filing cabinet.

Every transaction must be filed into the correct drawer.

We will build a Singapore-friendly starter chart of accounts that supports common small business accounting needs, including GST-related accounts.

---

### 6. Journal Engine

The journal engine is the heart of the application.

It will provide a function similar to this:

```ts
await postJournalEntry({
  organizationId,
  date,
  memo,
  lines: [
    {
      accountId: bankAccountId,
      debit: 10000,
      credit: 0,
    },
    {
      accountId: salesRevenueAccountId,
      debit: 0,
      credit: 10000,
    },
  ],
});
```

We will store money in cents, not floating-point dollars.

So S$100.00 becomes:

```txt
10000
```

This avoids decimal rounding bugs.

The journal engine will reject invalid entries, such as:

```txt
Debit  Bank       S$100
Credit Revenue    S$90
```

Because:

```txt
S$100 debit ≠ S$90 credit
```

Financial software must be strict. A friendly user interface is good, but the accounting core must behave like a security checkpoint.

---

### 7. Customers, Vendors, Invoices, and Bills

We will model real business documents.

Customers represent people or businesses who buy from us.

Vendors represent people or businesses we buy from.

Invoices represent money customers owe us.

Bills represent money we owe vendors.

For example, when we issue an invoice for S$109.00 including 9% GST, the accounting entry is:

```txt
Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Payable           S$9.00
```

That means:

- The customer owes us S$109.
- We earned S$100 in revenue.
- We owe S$9 to IRAS as GST collected.

We will encode this logic directly in the application.

---

### 8. Payments

When a customer pays an invoice, we do not create revenue again.

Revenue was already recognized when the invoice was issued.

Instead, payment moves value from receivables into the bank account:

```txt
Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

Similarly, when we pay a vendor bill:

```txt
Debit  Accounts Payable      S$109.00
Credit Bank                  S$109.00
```

This distinction is extremely important in accounting software.

Payments settle balances. They do not recreate the original sale or expense.

---

### 9. Financial Reports

We will build practical financial reports, including:

- Profit & Loss report
- Balance Sheet report
- Accounts Receivable aging
- Accounts Payable aging
- GST F5-style report

Reports are not separate accounting data. They are views derived from journal entries.

That means if the journal engine is correct, reports become trustworthy.

A useful analogy:

- Journal entries are the raw ingredients.
- Reports are the plated meals.
- Bad ingredients create bad meals.

So we will focus heavily on getting the ledger right.

---

### 10. Auditability and Permissions

Accounting systems need accountability.

We will add an audit log system that records important actions such as:

- Invoice created
- Journal entry posted
- Entry reversed
- Bank transaction categorized
- User changed a setting

We will also add role-based access control.

For example:

- Admins can manage settings.
- Members can create invoices.
- Viewers can read reports but not post entries.

This matters because finance systems are sensitive. Not everyone should be able to change historical records.

---

### 11. Bank Import and Reconciliation

We will support importing bank CSV files.

A user will be able to:

- Upload a CSV statement
- Parse transactions
- Review imported rows
- Categorize transactions
- Post accounting entries
- Reconcile transactions against the bank account

Bank reconciliation means checking that the app’s bank ledger agrees with the real bank statement.

Think of it like matching your app’s diary against the bank’s diary.

If both diaries tell the same story, the account is reconciled.

---

### 12. Background Jobs and Automation

We will use **Inngest** for background jobs.

Background jobs are tasks that happen outside a normal page request.

Examples:

- Send overdue invoice reminders every morning
- Generate recurring invoices
- React to invoice confirmation events
- Schedule automated accounting workflows

A normal web request is like ordering coffee at a counter.

A background job is like asking the café to bake tomorrow morning’s pastries overnight.

It happens reliably later, without keeping the user waiting.

---

### 13. Deployment

We will deploy the application to **Vercel**.

We will configure:

- Production environment variables
- Clerk production keys
- Neon database URL
- Drizzle migrations
- Inngest production endpoint
- Security checklist
- Operational best practices

The goal is not merely to “make it work locally.”

The goal is to build something that can be responsibly deployed.

---

### 14. Singapore Advanced Modules

Because GreyMatter Ledger is designed with Singapore businesses in mind, we will also build advanced modules for:

- Multi-currency support
- CPF payroll estimates
- Corporate tax estimates
- GST F5-style reporting

These modules will be practical but educational.

They are not a replacement for a qualified accountant or official tax advice, but they will teach how real accounting systems structure this kind of logic.

---

## Technology Stack

We will use the following stack.

---

### Next.js 16

**Next.js** is a full-stack React framework.

React helps us build user interfaces. Next.js adds routing, server rendering, backend endpoints, server actions, and deployment-friendly structure.

We will use the **App Router**, which organizes pages using the `app/` directory.

Example:

```txt
app/
  page.tsx              Public homepage
  dashboard/page.tsx    Dashboard page
  invoices/page.tsx     Invoice list page
```

Each folder maps to a URL route.

---

### TypeScript

**TypeScript** is JavaScript with types.

Types let us describe the shape of data before the app runs.

For example:

```ts
type InvoiceStatus = "draft" | "sent" | "paid" | "void";

type Invoice = {
  id: string;
  invoiceNumber: string;
  status: InvoiceStatus;
  totalCents: number;
};
```

This helps catch mistakes earlier.

If plain JavaScript is like writing notes on blank paper, TypeScript is like using a form with labeled fields. It guides you into entering the right kind of information.

---

### Tailwind CSS

**Tailwind CSS** is a utility-first styling framework.

Instead of writing separate CSS classes for every component, we compose small utility classes directly in our markup.

Example:

```tsx
<div className="rounded-xl border bg-white p-6 shadow-sm">
  <h2 className="text-xl font-semibold">Dashboard</h2>
</div>
```

This lets us build modern responsive interfaces quickly without leaving the component file.

---

### Clerk

**Clerk** handles authentication and organization management.

We will use it for:

- Sign up
- Sign in
- Session management
- Protected routes
- Organization switching
- Organization roles

This lets us focus on our business logic instead of reinventing authentication security.

---

### Neon Postgres

**Neon** is a serverless Postgres database platform.

Postgres is a reliable relational database. Relational means data is stored in tables with relationships between them.

Accounting data fits relational databases very well because we need consistency, constraints, and trustworthy records.

---

### Drizzle ORM

**Drizzle ORM** gives us type-safe database queries and migrations.

ORM stands for **Object-Relational Mapper**.

In everyday language, it is a bridge between TypeScript code and database tables.

Instead of scattering raw SQL strings everywhere, we define tables in TypeScript and query them safely.

---

### Inngest

**Inngest** helps us run background jobs and scheduled workflows.

We will use it for reminders and recurring invoice automation.

---

### Vercel

**Vercel** is a hosting platform optimized for Next.js.

It will run our web app, server actions, API routes, and production deployment pipeline.

---

## Target Audience

This series is designed for:

- Intermediate developers who want a serious full-stack portfolio project
- Developers interested in fintech or SaaS applications
- Entrepreneurs who want to understand accounting software architecture
- Engineers who want to practice secure multi-tenant application design
- Developers who know some React or TypeScript and want to go deeper

You do **not** need prior accounting experience.

We will explain accounting concepts from first principles.

However, this is a real engineering project, so you should be comfortable with:

- Running terminal commands
- Editing code files
- Installing npm packages
- Reading TypeScript
- Following step-by-step instructions carefully

---

## Engineering Principles We Will Follow

Throughout the series, we will follow several important engineering rules.

---

### 1. Store Money as Integers

We will store money in cents.

Instead of this:

```ts
const amount = 109.99;
```

We will store this:

```ts
const amountCents = 10999;
```

Why?

Because computers can represent decimal numbers in surprising ways.

For example:

```ts
0.1 + 0.2
```

In JavaScript, this produces:

```txt
0.30000000000000004
```

That tiny error is unacceptable in accounting software.

Integers avoid this problem.

---

### 2. Validate at the Boundaries

A boundary is any place where outside data enters the system.

Examples:

- A form submission
- An API request
- A CSV upload
- A webhook event
- A background job payload

We will validate data before trusting it.

This is like checking someone’s ID at a building entrance before letting them inside.

---

### 3. Keep Tenant Data Isolated

Every major database query must be scoped to the active organization.

Bad:

```ts
await db.select().from(invoices);
```

Better:

```ts
await db
  .select()
  .from(invoices)
  .where(eq(invoices.organizationId, organizationId));
```

In a multi-tenant app, forgetting this rule can expose one company’s data to another company.

That is one of the most serious bugs a SaaS product can have.

---

### 4. Make the Ledger Immutable

Immutable means “not changed after creation.”

In accounting systems, posted journal entries should not be casually edited.

If we need to correct something, we create a reversing entry.

For example, if this was posted incorrectly:

```txt
Debit  Rent Expense   S$500
Credit Bank           S$500
```

We reverse it with:

```txt
Debit  Bank           S$500
Credit Rent Expense   S$500
```

This keeps history honest.

Think of it like using a pen in a legal notebook. You do not erase the past. You add a correction.

---

### 5. Separate Business Logic from UI

The accounting engine should not live inside button click handlers or page components.

Instead, we will create service functions such as:

```ts
postJournalEntry()
createInvoice()
recordCustomerPayment()
generateProfitAndLoss()
```

The UI will call these functions, but the rules live in reusable server-side modules.

This makes the application easier to test and safer to maintain.

---

### 6. Prefer Explicit Code

In financial software, clever code is not always good code.

We will prefer code that is:

- Clear
- Typed
- Validated
- Testable
- Easy to audit

A future developer should be able to read our accounting logic and understand why money moved.

---

## What “Beginner-Friendly Outside, Expert Inside” Means

The explanations will be beginner-friendly.

We will use plain language and analogies.

But the implementation will still follow serious engineering practices:

- Environment variables instead of hardcoded secrets
- Type-safe schemas
- Database migrations
- Server-side authorization checks
- Transactional journal posting
- Validation with clear errors
- Testable accounting services
- Production deployment awareness

The goal is not to teach shortcuts.

The goal is to make professional patterns understandable.

---

## The Hands-On Journey Ahead

Here is the complete path we will follow.

---

## Phase 1 — Project Foundation

We will create the Next.js application, configure TypeScript and Tailwind CSS, and build the first version of the landing page and app shell.

Parts:

1. Course Overview and Final App Preview
2. Create the Next.js 16 App + TypeScript + Tailwind CSS
3. Build the Landing Page and Professional App Shell

---

## Phase 2 — Authentication and Organizations

We will add Clerk authentication and organization support.

Parts:

4. Add Clerk Authentication
5. Implement Company / Organization Switching

---

## Phase 3 — Database and Multi-Tenancy

We will connect to Neon Postgres with Drizzle ORM and sync Clerk organizations into our own database.

Parts:

6. Set Up Neon Postgres and Drizzle ORM
7. Sync Clerk Organizations to Database

---

## Phase 4 — Accounting Foundations

We will learn core double-entry accounting concepts, create the chart of accounts schema, seed default Singapore-friendly accounts, and build the accounts UI.

Parts:

8. Double-Entry Accounting for Developers
9. Build the Chart of Accounts Schema
10. Seed a Singapore-Friendly Chart of Accounts
11. Build the Chart of Accounts Page

---

## Phase 5 — The Journal Engine

We will build the accounting engine that enforces balanced entries.

Parts:

12. Create Journal Entry Tables
13. Build the Core `postJournalEntry()` Function
14. Manual Testing of the Journal Engine
15. Automated Tests for the Journal Engine

---

## Phase 6 — Customers, Vendors, Invoices & Bills

We will add customers, vendors, invoice accounting, GST logic, bill accounting, and detail/list pages.

Parts:

16. Build Customers and Vendors
17. Build Invoice Tables and GST Logic
18. Create GST-Aware Invoices with Journal Posting
19. Invoice List and Detail Pages
20. Build Bills and Vendor Management
21. Bill List and Detail Pages

---

## Phase 7 — Payments

We will record customer payments and vendor payments correctly through the ledger.

Parts:

22. Record Customer Payments
23. Record Vendor Payments

---

## Phase 8 — Reports

We will generate useful reports directly from journal lines.

Parts:

24. Build Reusable Report Helpers
25. Profit & Loss Report
26. Balance Sheet Report
27. AR/AP Aging Reports
28. GST F5-Style Report

---

## Phase 9 — Auditability and Permissions

We will implement corrections, reversals, audit logs, and role-based access control.

Parts:

29. Voiding and Reversing Entries
30. Audit Log System
31. Role-Based Access Control

---

## Phase 10 — Bank Import and Reconciliation

We will parse bank CSV files, categorize transactions, post them to the ledger, and reconcile bank activity.

Parts:

32. Upload and Parse Bank CSV Files
33. Review and Categorize Imported Transactions
34. Post Imported Transactions to the Ledger
35. Bank Reconciliation System

---

## Phase 11 — Background Jobs with Inngest

We will install Inngest and build automation workflows.

Parts:

36. Install and Configure Inngest
37. Invoice Confirmation Events
38. Daily Overdue Invoice Reminders
39. Recurring Invoices System

---

## Phase 12 — Deployment

We will deploy the application and review production best practices.

Parts:

40. Deploy to Vercel
41. Production Checklist and Best Practices

---

## Phase 13 — Singapore Advanced Modules

We will build Singapore-focused accounting helpers.

Parts:

42. Multi-Currency Support
43. CPF Payroll Estimate Module
44. Corporate Tax Estimate Report

---

## Phase 14 — Final Capstone

We will review the full system and identify future improvements.

Part:

45. Final Review, Production Readiness Audit & Future Improvements

---

## Important Disclaimer

GreyMatter Ledger is an educational project.

It is designed to teach accounting software architecture and full-stack application development.

Although we will implement realistic Singapore-oriented accounting workflows, this tutorial is not legal, tax, or accounting advice.

Before using any accounting system in production for real statutory reporting, you should consult qualified accounting and tax professionals and verify compliance with current IRAS, ACRA, CPF Board, and other applicable requirements.

---

## Development Expectations

When we begin the technical build in Part 1, each implementation step will follow this format:

1. **The Target** — What we are building right now.
2. **The Concept** — The idea behind it, explained simply.
3. **The Implementation** — Complete file contents and exact commands.
4. **The Verification** — How to confirm this step works before moving on.

We will avoid vague instructions like:

```ts
// TODO: implement this later
```

Instead, the series will provide complete, copy-pasteable implementation steps.

---

## Final Mental Model

Before we write code, remember this:

GreyMatter Ledger is not just a collection of screens.

It is a layered accounting system.

```txt
User Interface
  |
  v
Server Actions and Route Handlers
  |
  v
Validation and Authorization
  |
  v
Business Services
  |
  v
Double-Entry Journal Engine
  |
  v
Postgres Database
```

The user interface helps people work comfortably.

The service layer protects business rules.

The journal engine protects accounting correctness.

The database preserves the truth.

If we keep those layers clean, the application will remain understandable, testable, and extendable as it grows.
