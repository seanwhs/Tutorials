# Part 0: Introduction

## Welcome

Imagine you've never touched a keyboard for programming before, but you've decided you're going to build something real: a working piece of accounting software — the kind of thing companies pay $30/month for — and you're going to build it from a completely empty computer, understand every line of it, and put it on the live internet for free.

That's what this series is. Not a toy. Not a "todo app with extra steps." A genuine double-entry bookkeeping engine — the same fundamental design QuickBooks, Xero, and every real accounting system in the world uses — wrapped in a modern web application called **Greymatter Ledger**, built for a Singapore-flavored small business (GST-aware, SGD-denominated).

Think of this Part 0 as the trail map you look at before a long hike. You won't take a single step yet — but by the end of it, you'll know exactly what mountain you're climbing, why each leg of the trail exists, and what gear you need in your pack.

## Who This Is For

You need:
- A computer (Windows, Mac, or Linux) you can install software on.
- Willingness to type real code yourself, character by character, into real files — not just read about it.
- No prior programming experience required.
- **No prior accounting experience required.** We teach double-entry bookkeeping from absolute zero in Part 4, before a single line of code is allowed to enforce it.

You do **not** need: a computer science degree, prior JavaScript experience, or an accounting certification. If you can follow a recipe — "chop the onion, then heat the oil, then add the onion" — you can follow this course. Programming, like cooking, is just doing precise things in the right order, one step depending on the last.

This series is written for someone with genuinely zero prior programming experience, who is willing to type real code and test things as they go.

## The Analogy for the Whole Course

Picture a restaurant. The **dining room** is what your customers see — the web pages, the buttons, the forms (this is the "frontend"). The **kitchen** is where the real work happens — validating orders, making sure nothing leaves the kitchen half-cooked (this is the "backend": server logic and the database). And the **ledger book** the restaurant's accountant keeps in the back office — recording every dollar in and out so the owner always knows exactly how much money the business has and owes — that ledger book is the accounting engine at the heart of this app.

Most tutorials teach you how to build the dining room. This course teaches you to build the dining room, the kitchen, *and* a ledger book that never lets the numbers go out of balance — because that's the actual hard, valuable part of accounting software, and it's the part almost every clone tutorial skips entirely.

## What You Will Have Built By The End

By the final part, Greymatter Ledger will have:

- **Real user accounts and multi-company support** — each business ("organization") is its own isolated tenant, with sign-up/sign-in handled by Clerk.
- **A real Postgres database** hosted on Neon, with a schema for accounts, journal entries, customers, vendors, invoices, bills, and payments.
- **A double-entry journal engine** — the non-negotiable core of the whole app: every financial event posts as a balanced journal entry (debits equal credits, always, enforced in code, inside a real database transaction).
- **A full Chart of Accounts**, including two Singapore-specific additions: GST Output Tax Payable and GST Input Tax Receivable.
- **Invoicing and billing**, with multi-line items, a GST rate per line, and automatic, atomic posting to the ledger.
- **Payment recording** against both invoices and bills, with correct status updates.
- **Real financial reports** generated live from the ledger: Profit & Loss, Balance Sheet, AR/AP Aging, and a Singapore GST F5 return summary.
- **Background and scheduled jobs** via Inngest — invoice confirmation emails, daily overdue reminders, and recurring invoice generation.
- **Bank statement import** — upload a CSV export from any bank, review and categorize each transaction, and post it straight into the ledger as a real journal entry.
- **A live deployment** on Vercel, connected to free-tier Neon, Clerk, and Inngest — a real URL you can send to a friend, with no credit card used anywhere.

## The Architecture, At a Glance

```
┌─────────────────────────────────────────────────────────────┐
│                         BROWSER                              │
│         (Next.js 16 pages, React components, Tailwind)       │
└───────────────────────────┬───────────────────────────────────┘
                            │  Server Actions / Route Handlers
┌───────────────────────────▼───────────────────────────────────┐
│                    NEXT.JS 16 SERVER                          │
│   src/proxy.ts   →  Clerk auth check on every request         │
│   Server Actions →  createInvoice(), postJournalEntry(), etc. │
│   Route Handlers →  /api/inngest, CSV upload endpoint          │
└───────┬─────────────────────────────┬─────────────────────────┘
        │                             │
┌───────▼────────┐          ┌─────────▼──────────┐
│     CLERK       │          │      INNGEST         │
│ auth + orgs      │          │ background/scheduled │
└─────────────────┘          │       jobs            │
                              └─────────────────────┘
┌─────────────────────────────▼───────────────────────────────┐
│                    NEON POSTGRES (via Drizzle ORM)           │
│  organizations, accounts, journal_entries, journal_lines,    │
│  customers, vendors, invoices, invoice_lines, bills,         │
│  bill_lines, payments, imported_transactions                │
└───────────────────────────────────────────────────────────────┘
```

Every arrow in that diagram is something you will build with your own hands, one file at a time, starting in Part 1.

## The Toolbox (Named Now, Explained Fully Later)

You'll hear these five names constantly throughout the series. Here's the one-sentence version of each, so nothing feels alien later — Parts 4 through 7 build directly on these ideas without re-explaining them from scratch:

- **Next.js 16** — the framework that lets one project contain both your web pages and your server logic, so you don't need two separate applications talking to each other. Notably, Next.js 16 renames the old `middleware.ts` file to `src/proxy.ts` — you'll see this exact file in Part 2.
- **Tailwind CSS** — a way to style your pages by writing small utility labels directly in your markup, instead of maintaining separate stylesheet files.
- **Clerk** — a hosted service that handles sign-up, sign-in, and "which company am I working in right now" (called Organizations), so you never have to write your own password-handling or session security code from scratch.
- **Neon** — a Postgres database that lives in the cloud, free to start, that stores every piece of data your app cares about — customers, invoices, journal entries, everything.
- **Drizzle** — a toolkit that lets you describe your database tables using plain TypeScript code instead of raw SQL, and query them safely with real type-checking that catches mistakes before they ever run.
- **Inngest** — a service for "do this later, or do this on a schedule, and retry it automatically if it fails" — used in this course for background emails and recurring jobs.

## How to Use This Series

This is delivered as a saved reference. You can ask for a specific part by number at any time (e.g., "give me Part 6"), or just say "continue" to move to the next part in sequence. Nothing here needs to be memorized — it's meant to be a reference you build from, indefinitely, long after the series ends.

One rule holds for the entire series: **every code block is complete and copy-pasteable.** You will never see `// ...rest of the code` or `// implement this yourself` as a stand-in for real logic. If a file is shown, the *entire* file is shown, exactly as it should exist on your disk.

Each part will end with a **Checkpoint** (a plain statement of what should be true and working right now) and **Troubleshooting** (the most common ways people get stuck at that exact step, and how to get unstuck) — so you always know whether you're safe to move forward.

Let's build.
