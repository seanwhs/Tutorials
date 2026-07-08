## Part 0: Introduction — Welcome to This Course

Welcome. By the end of this series, you will have built — from an empty computer, assuming zero prior coding experience — a real, working, deployed accounting web application modeled on QuickBooks, with a genuine double-entry bookkeeping engine underneath it, hosted live on the internet for free. This part explains what you're about to build, why it's structured the way it is, and how to use this course day to day. This edition of the series includes complete, copy-typeable code in every part (nothing is just described in prose — you will always see the exact file contents to type) plus a Troubleshooting section at the end of every part covering the most common errors beginners hit at that exact step.

---

### 1. What you're going to build

A multi-tenant SaaS accounting application where:
- Each user can create or join a "company" (mirroring how QuickBooks separates each business into its own "company file")
- The company has a Chart of Accounts, tracks Customers and Vendors, and lets you create Invoices and Bills
- Every financial action — sending an invoice, receiving a bill, recording a payment — automatically produces a correct, balanced accounting entry behind the scenes, using real double-entry bookkeeping
- Three real financial/operational reports (Profit & Loss, Balance Sheet, AR/AP Aging) are computed live from that underlying ledger data
- Background jobs handle emailing invoices and sending overdue reminders automatically, including on a recurring schedule
- Bank transactions can be imported from a CSV file and categorized into the right accounts
- The whole thing is deployed on the real internet, entirely on free hosting tiers, with automatic redeployment every time you push new code

### 2. The tools you'll learn, and why each one

- **Next.js** — the web framework everything is built in
- **Clerk** — handles user login/signup and multi-tenancy (Organizations = companies)
- **Neon** — a free, hosted Postgres database
- **Drizzle ORM** — type-checked TypeScript instead of raw SQL text
- **Inngest** — background jobs and scheduled/cron jobs
- **Vercel** — free hosting, made by the creators of Next.js

Part 3 covers all of these in plain-English depth before we touch any of them.

### 3. Who this course is for

Someone with genuinely zero prior programming experience who is willing to type real code, read explanations carefully, and test things as they go. No prior accounting knowledge is assumed either — Part 8 teaches double-entry bookkeeping itself, from scratch.

### 4. How the course is structured

25 numbered parts (0 through 24), grouped into stages:

- **Orientation (0):** this part
- **Foundations (1-3):** dev environment setup, your first Next.js project, and a conceptual tour of every tool
- **Auth & Multi-Tenancy (4-5):** real login, Organizations-as-companies
- **Database Foundation (6-7):** a free real database, and a type-safe way to talk to it
- **Accounting Fundamentals (8-10):** accounting theory, Chart of Accounts, journal entry engine
- **Core Features (11-15):** customers/vendors, invoices, bills, payments
- **Reports (16-18):** Profit & Loss, Balance Sheet, AR/AP Aging
- **Automation (19-20):** background jobs and cron with Inngest
- **Bank Data (21-22):** CSV import, optional Plaid overview
- **Shipping It (23-24):** free deployment, roadmap for what's next

Every numbered part (from Part 1 onward) follows the same shape:
1. A plain-English explanation of the concept
2. Every command to run, typed out exactly
3. The full contents of every file you need to create or edit — complete code, not summarized, ready to copy in directly
4. A "Checkpoint" checklist to confirm it worked
5. A "Troubleshooting" section covering the specific errors beginners commonly hit at that step, with the exact fix

### 5. How to actually use this series

Every part is saved as its own note titled "QB Clone Tutorial - Part N: [name]". There is an INDEX note that lists every part and tracks where you left off. Just say "continue" or ask for a specific part number at any time, in any future conversation.

### 6. A note on pace

Part 8 (accounting theory) and Part 10 (the journal entry engine) are worth slowing down on. Everything else moves at a steady, hands-on pace with real code at every step.

### 7. Ready?

Move on to Part 1: Setting Up Your Computer.

---

### Troubleshooting (general, applies throughout the course)

**"I don't know which folder my terminal is in"** — Run `pwd` (Mac) to print your current folder path. On Windows Command Prompt, run `cd` with no arguments to print it.

**"I typed a command and got a wall of red text"** — Don't panic. Scroll up to the FIRST red line, not the last — the first error is usually the real cause; everything after it is often just consequences of that first problem. Copy the first few lines of red text and troubleshoot that specific message.

**"My terminal command isn't found / command not found / not recognized"** — Almost always means either (a) the tool isn't installed yet (revisit Part 1), or (b) you need to close and reopen your terminal/VS Code after installing something, so it picks up the new program.

**"I closed my terminal and now npm run dev isn't running anymore"** — This is expected. Every time you reopen your project, navigate back into the project folder (`cd` to it) and run `npm run dev` again to restart the local server.

---

Ready for **Part 1: Setting Up Your Computer** ?
