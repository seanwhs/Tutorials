# Phase 1 — Project Foundation

# Part 1 — Course Overview and Final App Preview

In this part, we will not create the app yet. That begins in **Part 2**.

Instead, we will prepare our mental model, inspect the final system we are building, define the development prerequisites, and verify that your machine is ready for the hands-on build.

Think of this part as checking the map, packing the tools, and understanding the destination before we start the road trip.

---

# 1. The Final Destination

## The Target

We are defining what GreyMatter Ledger will become by the end of the series.

By the end, the application will support:

- Public marketing landing page
- Authentication
- Company/organization switching
- Multi-tenant accounting data
- Chart of accounts
- Double-entry journal engine
- Customers and vendors
- GST-aware invoices
- Vendor bills
- Customer payments
- Vendor payments
- Profit & Loss report
- Balance Sheet report
- AR/AP aging
- GST F5-style report
- Audit logs
- Role-based permissions
- Bank CSV import
- Bank reconciliation
- Background jobs with Inngest
- Recurring invoices
- Production deployment to Vercel
- Singapore-focused advanced modules

---

## The Concept

A serious accounting app is not just a set of forms.

It is a system of layers.

A helpful analogy is a well-run office:

```txt
Reception desk       = User interface
Security guard       = Authentication and authorization
Department folders   = Company/organization workspaces
Accounting clerk     = Business services
Chief accountant     = Journal engine
Archive room         = Database
```

Each layer has a job.

The user interface should be pleasant.

The authentication layer should know who the user is.

The organization layer should know which company the user is working in.

The business services should understand workflows like “create invoice” or “record payment.”

The journal engine should enforce accounting correctness.

The database should preserve the truth.

The most important part is that these layers stay separated.

Bad architecture puts everything directly inside page components.

Good architecture creates reusable, testable server-side business functions.

For example, eventually our UI might call a server action like this:

```ts
await createInvoiceAction(formData);
```

But that action should delegate to a deeper business service:

```ts
await createInvoice({
  organizationId,
  customerId,
  invoiceDate,
  dueDate,
  lines,
});
```

And that service should eventually call the accounting engine:

```ts
await postJournalEntry({
  organizationId,
  date: invoiceDate,
  memo: "Invoice INV-0001",
  lines: [
    {
      accountId: accountsReceivableAccountId,
      debitCents: totalCents,
      creditCents: 0,
    },
    {
      accountId: salesRevenueAccountId,
      debitCents: 0,
      creditCents: revenueCents,
    },
    {
      accountId: gstPayableAccountId,
      debitCents: 0,
      creditCents: gstCents,
    },
  ],
});
```

That layered design is what makes the app maintainable.

---

## The Implementation

No project files are created in this section yet.

Instead, here is the high-level architecture we will build.

```txt
greymatter-ledger
  |
  |-- app/
  |     |
  |     |-- page.tsx
  |     |-- layout.tsx
  |     |-- dashboard/
  |     |-- accounts/
  |     |-- customers/
  |     |-- vendors/
  |     |-- invoices/
  |     |-- bills/
  |     |-- payments/
  |     |-- reports/
  |     |-- bank/
  |     |-- settings/
  |
  |-- components/
  |     |
  |     |-- app-sidebar.tsx
  |     |-- app-header.tsx
  |     |-- empty-state.tsx
  |     |-- money.tsx
  |
  |-- db/
  |     |
  |     |-- index.ts
  |     |-- schema.ts
  |     |-- migrations/
  |
  |-- lib/
  |     |
  |     |-- auth.ts
  |     |-- money.ts
  |     |-- dates.ts
  |     |-- validations/
  |
  |-- services/
  |     |
  |     |-- accounting/
  |     |     |
  |     |     |-- post-journal-entry.ts
  |     |     |-- reverse-journal-entry.ts
  |     |
  |     |-- invoices/
  |     |-- bills/
  |     |-- payments/
  |     |-- reports/
  |
  |-- inngest/
  |     |
  |     |-- client.ts
  |     |-- functions.ts
  |
  |-- drizzle.config.ts
  |-- middleware.ts
  |-- package.json
  |-- tsconfig.json
  |-- next.config.ts
```

Do not create this manually yet. Next.js and our commands will generate the first project files in Part 2.

For now, the important idea is this:

```txt
UI pages call actions.
Actions call services.
Services call the journal engine.
The journal engine writes to the database.
Reports read from the journal lines.
```

---

## The Verification

You should be able to explain the final application in one sentence:

> GreyMatter Ledger is a multi-company accounting web app where business actions like invoices, bills, and payments are converted into balanced double-entry journal entries, then used to generate trustworthy reports.

If that sentence makes sense, you are ready to continue.

---

# 2. Core Accounting Preview

## The Target

We are previewing the accounting rules that will guide the entire application.

---

## The Concept

Accounting software needs a source of truth.

In GreyMatter Ledger, the source of truth is the **journal**.

A journal is a chronological list of financial events.

Each journal entry contains one or more journal lines.

Every journal entry must balance:

```txt
Total debits = total credits
```

A simple sale might look like this:

```txt
Invoice issued for S$109.00 including 9% GST

Debit  Accounts Receivable   S$109.00
Credit Sales Revenue         S$100.00
Credit GST Payable           S$9.00
```

This says:

- The customer owes us S$109.00.
- We earned S$100.00 in sales revenue.
- We owe S$9.00 GST to IRAS.

Then, when the customer pays:

```txt
Payment received for S$109.00

Debit  Bank                  S$109.00
Credit Accounts Receivable   S$109.00
```

This says:

- Our bank increased.
- The customer no longer owes us.

Notice that payment does **not** credit sales revenue again.

Revenue was already recorded when the invoice was issued.

This distinction is one of the most important ideas in the series.

---

## The Implementation

Eventually, our journal engine will reject entries like this:

```ts
const invalidEntry = {
  memo: "Bad entry",
  lines: [
    {
      accountName: "Bank",
      debitCents: 10000,
      creditCents: 0,
    },
    {
      accountName: "Sales Revenue",
      debitCents: 0,
      creditCents: 9000,
    },
  ],
};
```

Why?

Because the total debit is S$100.00, but the total credit is S$90.00.

```txt
Debit total:  10000 cents
Credit total:  9000 cents
Difference:    1000 cents
```

That entry is unbalanced.

The correct version would be:

```ts
const validEntry = {
  memo: "Valid sale",
  lines: [
    {
      accountName: "Bank",
      debitCents: 10000,
      creditCents: 0,
    },
    {
      accountName: "Sales Revenue",
      debitCents: 0,
      creditCents: 10000,
    },
  ],
};
```

This balances:

```txt
Debit total:  10000 cents
Credit total: 10000 cents
Difference:       0 cents
```

In later parts, we will turn this idea into production-grade database-backed TypeScript code.

---

## The Verification

Make sure these two statements are clear:

```txt
An invoice creates revenue and receivable balances.
A payment settles receivable balances and increases the bank balance.
```

And:

```txt
A journal entry is valid only when total debits equal total credits.
```

If both ideas make sense, you understand the accounting foundation we will build on.

---

# 3. Technical Stack Preview

## The Target

We are reviewing each major tool and why it belongs in the system.

---

## The Concept

Each tool has a specific responsibility.

Do not think of the tech stack as a random list of popular packages.

Think of it like a construction crew:

```txt
Next.js       = building frame
React         = rooms and furniture
TypeScript    = measuring tape
Tailwind CSS  = interior design system
Clerk         = secure entry system
Neon Postgres = document archive
Drizzle ORM   = database translator
Inngest       = automation scheduler
Vercel        = production building site
```

---

## The Implementation

Here is what each technology will do.

| Technology | Responsibility |
|---|---|
| Next.js 16 | Full-stack application framework |
| React | Interactive user interface |
| TypeScript | Type-safe application code |
| Tailwind CSS | Styling and layout |
| Clerk | Authentication and organizations |
| Neon Postgres | Production database |
| Drizzle ORM | Schema, migrations, and type-safe queries |
| Inngest | Background jobs and scheduled workflows |
| Vercel | Hosting and deployment |

We will keep secrets outside code using environment variables.

Example environment variables later in the project will include:

```bash
DATABASE_URL="postgresql://..."
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
CLERK_SECRET_KEY="sk_test_..."
INNGEST_EVENT_KEY="..."
INNGEST_SIGNING_KEY="..."
```

Environment variables are values your app reads from the operating environment instead of hardcoding them into source code.

That matters because credentials must not be committed to Git.

---

## The Verification

You should understand this basic separation:

```txt
Next.js renders the app.
Clerk identifies the user and organization.
Drizzle talks to Postgres.
The journal engine enforces accounting rules.
Inngest runs background jobs.
Vercel hosts the production app.
```

---

# 4. Local Development Requirements

## The Target

We are checking that your computer has the required tools installed before creating the project.

You will need:

- Node.js
- npm, pnpm, or another package manager
- Git
- A code editor such as VS Code
- A terminal

For this series, we will use **pnpm**.

pnpm is a fast JavaScript package manager. It installs dependencies like npm, but is usually faster and more disk-efficient.

---

## The Concept

Before building a house, you check that your tools are available.

Before building a web app, we check that the command line can run the tools we need.

The most important tool is Node.js because Next.js runs on Node during development.

---

## The Implementation

Open your terminal and run:

```bash
node --version
```

You should see something like:

```txt
v20.11.0
```

or newer.

Next, check npm:

```bash
npm --version
```

You should see a version number, for example:

```txt
10.2.4
```

Next, check Git:

```bash
git --version
```

You should see something like:

```txt
git version 2.43.0
```

Now install pnpm globally if you do not already have it:

```bash
npm install --global pnpm
```

Check pnpm:

```bash
pnpm --version
```

You should see a version number, for example:

```txt
9.15.0
```

If you prefer using Corepack, you can enable pnpm like this:

```bash
corepack enable
corepack prepare pnpm@latest --activate
pnpm --version
```

Either approach is fine. The tutorial commands will use `pnpm`.

---

## The Verification

Run all of these commands:

```bash
node --version
npm --version
pnpm --version
git --version
```

A healthy setup prints four version numbers.

Example:

```txt
v20.11.0
10.2.4
9.15.0
git version 2.43.0
```

If you see command-not-found errors, install the missing tool before continuing.

Recommended versions:

```txt
Node.js: 20 or newer
pnpm: 9 or newer
Git: any modern version
```

---

# 5. Recommended Accounts to Create

## The Target

We are identifying external services you will need later in the series.

You do not need to configure them yet, but creating accounts early will make later parts smoother.

---

## The Concept

Modern production applications often depend on managed services.

A managed service is a platform that handles a difficult operational responsibility for us.

For example:

- Clerk handles authentication security.
- Neon handles database hosting.
- Vercel handles deployment.
- Inngest handles background job execution.

Instead of manually operating everything ourselves, we use specialized platforms.

---

## The Implementation

Create free accounts for the following services when convenient:

| Service | URL | Used For |
|---|---|---|
| Clerk | `https://clerk.com` | Authentication and organizations |
| Neon | `https://neon.tech` | Postgres database |
| Vercel | `https://vercel.com` | Deployment |
| Inngest | `https://www.inngest.com` | Background jobs |

Do not create API keys yet unless you want to.

We will do that at the exact moment we need them.

---

## The Verification

You are ready if you either:

- Already have accounts with these providers, or
- Know where to create them when the relevant part arrives.

No code verification is required for this step.

---

# 6. Development Style We Will Use

## The Target

We are setting expectations for how code will be introduced throughout the series.

---

## The Concept

Every technical part will follow the same rhythm:

```txt
Target       What are we building?
Concept      Why does it work this way?
Implementation  What exact code do we write?
Verification How do we prove it worked?
```

This matters because professional software is not built by randomly pasting code.

Every file should have a reason to exist.

Every package should solve a known problem.

Every verification step should increase confidence.

---

## The Implementation

When we create or edit files, the tutorial will label them clearly.

For example:

```tsx
// app/page.tsx

export default function HomePage() {
  return <main>Hello GreyMatter Ledger</main>;
}
```

Commands will also be copy-pasteable:

```bash
pnpm dev
```

When environment variables are needed, we will use a local `.env.local` file.

Example:

```bash
DATABASE_URL="postgresql://user:password@host/database"
```

We will not hardcode secrets inside TypeScript files.

Bad:

```ts
const databaseUrl = "postgresql://real-production-password-here";
```

Good:

```ts
const databaseUrl = process.env.DATABASE_URL;
```

---

## The Verification

You should be comfortable with the idea that each future part will include:

- Exact files
- Exact code
- Exact commands
- Exact test steps

That is the working style for the rest of the project.

---

# 7. Final App User Journey Preview

## The Target

We are walking through how a real user will experience the finished app.

---

## The Concept

A user journey is the story of how someone moves through the application to complete their work.

For accounting software, the journey usually begins with company setup and ends with reports.

---

## The Implementation

A typical finished GreyMatter Ledger flow will look like this:

```txt
1. User visits the landing page.
2. User signs up with Clerk.
3. User creates or joins a company organization.
4. App creates that company in our database.
5. App seeds a default Singapore-friendly chart of accounts.
6. User creates a customer.
7. User creates an invoice with GST.
8. App posts a balanced journal entry.
9. Customer pays the invoice.
10. App posts a payment journal entry.
11. User views Profit & Loss.
12. User views Balance Sheet.
13. User imports bank CSV transactions.
14. User reconciles the bank account.
15. Background jobs send overdue invoice reminders.
```

A simplified diagram:

```txt
Customer Invoice
      |
      v
Invoice Service
      |
      v
Journal Entry
      |
      v
Journal Lines
      |
      v
Reports
```

This is the central pattern of the whole application.

Business documents are useful for humans.

Journal entries are useful for accounting truth.

Reports are generated from accounting truth.

---

## The Verification

You should understand this key design choice:

> Invoices, bills, and payments are business documents, but journal entries are the accounting source of truth.

That means an invoice page may show the invoice, but the Profit & Loss report should come from journal lines, not from invoice rows directly.

---

# 8. What We Will Build First

## The Target

We are preparing for Part 2, where we will create the actual Next.js project.

---

## The Concept

A strong foundation matters.

Before we add authentication, databases, and accounting rules, we need a clean web application that can:

- Start locally
- Render a page
- Use TypeScript
- Use Tailwind CSS
- Follow a predictable folder structure

That is exactly what Part 2 will create.

---

## The Implementation

In Part 2, we will run a command similar to this:

```bash
pnpm create next-app@latest greymatter-ledger
```

We will choose options for:

```txt
TypeScript: Yes
ESLint: Yes
Tailwind CSS: Yes
App Router: Yes
src directory: No
Turbopack: Yes
Import alias: Yes
```

Then we will run:

```bash
cd greymatter-ledger
pnpm dev
```

And open:

```txt
http://localhost:3000
```

That will confirm our base application works.

Do not run this yet if you are following part-by-part strictly. We will do it together in Part 2.

---

## The Verification

Before moving to Part 2, confirm:

```txt
Node.js works.
pnpm works.
Git works.
You understand the final application goal.
You understand that journal entries are the accounting source of truth.
You understand that every company’s data must be isolated.
```

If yes, you are ready for the first real build step.

---

# Common Errors and Fixes

## Error: `node: command not found`

Node.js is not installed or not available in your terminal path.

Install Node.js from:

```txt
https://nodejs.org
```

Then close and reopen your terminal.

Verify:

```bash
node --version
```

---

## Error: `pnpm: command not found`

Install pnpm:

```bash
npm install --global pnpm
```

Then verify:

```bash
pnpm --version
```

If that fails, use Corepack:

```bash
corepack enable
corepack prepare pnpm@latest --activate
pnpm --version
```

---

## Error: `git: command not found`

Install Git from:

```txt
https://git-scm.com
```

Then verify:

```bash
git --version
```

---

## Error: Node version is too old

If your Node version is older than Node 20, upgrade Node.

Recommended options:

- Install the latest LTS from `https://nodejs.org`
- Use `nvm` on macOS/Linux
- Use `nvm-windows` on Windows

Verify again:

```bash
node --version
```

---

# Phase 1 Reference — Architecture Vocabulary

## Application Layer

The application layer is the part users interact with directly.

In our app, this includes pages like:

```txt
/dashboard
/invoices
/reports/profit-and-loss
```

---

## Service Layer

The service layer contains business logic.

Example service names:

```txt
createInvoice()
recordCustomerPayment()
generateBalanceSheet()
```

Services should not care much about button styles or page layouts.

They care about rules.

---

## Journal Engine

The journal engine is the accounting core.

Its job is to accept only valid balanced journal entries.

It protects the ledger from incorrect financial data.

---

## Multi-Tenancy

Multi-tenancy means one application serves multiple organizations while keeping each organization’s data isolated.

In GreyMatter Ledger, every company is a tenant.

---

## Organization

An organization represents a company workspace.

A user can belong to one or more organizations.

---

## Chart of Accounts

The chart of accounts is the list of accounting categories used by a company.

Examples:

```txt
Bank
Accounts Receivable
Accounts Payable
Sales Revenue
GST Payable
Rent Expense
```

---

## Ledger

The ledger is the complete accounting record.

In our database, the ledger will be represented mainly by:

```txt
journal_entries
journal_lines
```

---

## Debit and Credit

Debit and credit are accounting directions.

They are not the same as “good” and “bad.”

Their meaning depends on the account type.

For now, remember only this:

```txt
Every journal entry must have equal total debits and credits.
```

We will explain the deeper rules when we build the accounting foundation.

---

# Part 1 Completion Checklist

You are ready for Part 2 if:

- [ ] Node.js 20 or newer is installed
- [ ] pnpm is installed
- [ ] Git is installed
- [ ] You understand the final application goal
- [ ] You understand that every business action eventually posts to the journal
- [ ] You understand that reports are generated from journal entries
- [ ] You understand that company data must be isolated by organization

---

[GENERATED: Phase 1, Part 1 — Course Overview and Final App Preview]  
[READY: Phase 1, Part 2 — Create the Next.js 16 App + TypeScript + Tailwind CSS]
