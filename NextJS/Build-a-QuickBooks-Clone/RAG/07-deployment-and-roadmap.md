# QB Clone: Deployment and Roadmap - Free Vercel Hosting, Phase 2/3 Plan

File 8 of 8 (final file). Covers deploying to Vercel entirely for free, and the Phase 2/3 roadmap. See file "00 Master Overview and Architecture" for the big picture.

---

## PART A: Deploying to Vercel for Free

Vercel (made by the creators of Next.js) offers a free "Hobby" tier requiring no credit card, usable indefinitely for a real side project, not just a trial.

### Push your project to GitHub

1. https://github.com, "New repository", name it qb-clone, do NOT initialize with a README, "Create Repository"
2. In your terminal, inside the project folder:
```
git remote add origin https://github.com/YOUR_USERNAME/qb-clone.git
git branch -M main
git push -u origin main
```
3. CRITICAL: confirm .env.local was never pushed - check your files on GitHub. If it's there, stop, remove it, and rotate every secret in it immediately.

### Create a free Vercel account and import the project

1. https://vercel.com, sign up via "Continue with GitHub" (no credit card requested)
2. "Add New..." -> "Project", find qb-clone, "Import"
3. Vercel auto-detects Next.js settings correctly

### Add every environment variable

Before clicking Deploy, add every line from .env.local into Vercel's Environment Variables section:
- NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY
- CLERK_SECRET_KEY
- DATABASE_URL
- DATABASE_URL_UNPOOLED
- Any Inngest-related keys (added below)

Consider (optional, more important once real users are involved): a separate Clerk application and Neon database branch/project for production vs development - Neon's branching feature is designed for exactly this.

Click Deploy. Get a real URL like qb-clone-yourname.vercel.app - your app is live, free.

### Fix Clerk redirect URLs for production

In Clerk's dashboard, confirm your Vercel URL is in allowed redirect/origin URLs. Test sign-up/sign-in on the live URL.

### Wire up the real Clerk webhook

Resolves the local-testing deferral from the Chart of Accounts seeding (file 03):
1. Clerk dashboard -> Configure -> Webhooks -> Add Endpoint
2. URL: `https://your-vercel-url.vercel.app/api/webhooks/clerk`
3. Subscribe to organization.created
4. Add the shown signing secret to Vercel as CLERK_WEBHOOK_SECRET, redeploy
5. Test: create a new organization on the live app, confirm seedDefaultAccounts ran automatically (check Neon)

(Note: this requires having built an actual /api/webhooks/clerk route handler that verifies the webhook signature via svix and calls seedDefaultAccounts on organization.created - build this route now if you haven't already, following Clerk's webhook verification documentation, since earlier files in this set deferred it pending a public URL.)

### Connect Inngest to production

1. https://app.inngest.com, find "Sync"/"Add app" for a production URL
2. Enter `https://your-vercel-url.vercel.app/api/inngest`
3. Confirm all three functions (sendInvoiceEmail, sendOverdueReminders, generateRecurringInvoices) sync
4. If prompted, generate an INNGEST_SIGNING_KEY, add to Vercel, redeploy

Test by creating an invoice on the live app and confirming (via Inngest Cloud's dashboard) the event fires correctly against production.

### Confirm Neon works under real serverless load

Confirm src/lib/db/index.ts uses DATABASE_URL (pooled), and only drizzle.config.ts uses DATABASE_URL_UNPOOLED. This matters more under real concurrent Vercel traffic than during solo local testing.

### Running migrations against production

Vercel's build does NOT auto-run npm run db:migrate. Run migrations manually from your own machine, pointed at production's DATABASE_URL_UNPOOLED (swap .env.local temporarily or use a separate .env.production.local file), then switch back.

### Free subdomain vs optional custom domain

The free `your-project-name.vercel.app` subdomain is genuinely fine, no cost. A real custom domain costs money from a registrar (optional, not required).

### Staying within free tier limits long term

- Vercel Hobby: generous for personal projects; watch fair-use policy if this becomes a real paid product
- Neon free tier: storage cap + scale-to-zero; fine for low-traffic apps
- Clerk free tier: monthly active user cap; plenty for demo use
- Inngest free tier: monthly function run cap; cron jobs count as runs too

### Commit and wrap up

```
git add .
git commit -m "Deployment notes and any production-related fixes"
git push
```
Every future git push to main auto-triggers a new Vercel deployment (continuous deployment).

### Checkpoint
- [ ] Project pushed to GitHub, .env.local confirmed absent
- [ ] App deployed on Vercel with a real public URL, no credit card
- [ ] All environment variables set, sign-up/sign-in works live
- [ ] Clerk organization.created webhook wired to production, auto-seeds Chart of Accounts
- [ ] Inngest Cloud shows the production app and its functions, confirmed an event fires correctly
- [ ] Understand why DATABASE_URL (pooled) is for the app, DATABASE_URL_UNPOOLED only for migrations
- [ ] Understand git push now auto-deploys

### Troubleshooting

**Vercel build fails with a TS/lint error not seen locally** - Run `npm run build` locally first before pushing; Vercel's build is stricter than npm run dev.

**Build succeeds but deployed site shows 500/blank** - Missing/misspelled environment variable - compare every name against .env.local carefully.

**Sign-in works locally but fails on the deployed URL** - Confirm Vercel URL added to Clerk's allowed origins, and you're using the correct Clerk app's keys.

**DB connection errors only under real traffic** - Classic pooled-vs-unpooled symptom - confirm src/lib/db/index.ts uses the pooled DATABASE_URL.

**Clerk webhook doesn't fire on a new live org** - Confirm the endpoint URL exactly matches your deployed domain plus /api/webhooks/clerk, CLERK_WEBHOOK_SECRET is set, and you redeployed after adding it.

**Webhook returns 400/signature verification error** - CLERK_WEBHOOK_SECRET doesn't match the one shown for that specific endpoint in Clerk's dashboard.

**Inngest Cloud can't find your functions** - Confirm the URL entered is your real deployed Vercel URL (not localhost) plus /api/inngest; visit it directly in a browser first to confirm it's live.

**Migrations don't seem applied to production** - Confirm you genuinely pointed db:migrate at production's DATABASE_URL_UNPOOLED, not your local database again.

**git push doesn't trigger a new deployment** - Confirm Vercel's project is connected to the correct GitHub repo/branch (Project Settings -> Git).

**Accidentally committed .env.local to GitHub** - Rotate every secret in it immediately (Clerk secret key, Neon password/connection string, etc.) in each service's dashboard - simply deleting the file from a future commit does not undo an already-public exposure on a public repo.

---
```

Now PART B — What's Next (Phase 2/3 Roadmap), the final piece of the entire RAG set.
```markdown
## PART B: What's Next - Phase 2 and 3 Roadmap

This is the final section of the entire 8-file set. At this point you have a real, deployed, working QuickBooks-style accounting application with a correct double-entry ledger underneath everything - genuinely the hard part most clones skip or get wrong.

### What was built (recap)

Authentication and multi-tenant organizations (Clerk); a Postgres database with real schema and migrations (Neon + Drizzle); a from-scratch double-entry accounting engine enforcing debits=credits atomically (postJournalEntry); a full Chart of Accounts; Customers/Vendors; Invoices and Bills that correctly post journal entries; Payments that correctly close out both; three real reports (P&L, Balance Sheet, AR/AP Aging) computed live from the ledger; background jobs and scheduled automation (Inngest); CSV bank import with categorization; a live deployment on free infrastructure with continuous deployment from GitHub.

### Phase 2 roadmap, roughly in priority order

**a. Recurring billing / subscriptions polish** - The recurring invoice generator (file 06) is monthly-only. A fuller version supports weekly/quarterly/annual schedules, automatic price changes, and pausing/canceling mid-cycle.

**b. Stripe for customer payments** - Currently payments are manually recorded. A real product lets customers pay invoices online via a Stripe-hosted checkout link, with a webhook (same pattern as Clerk's webhook) automatically calling recordCustomerPayment logic when Stripe confirms a successful charge.

**c. Role-based permissions** - Clerk's organization roles (Admin/Member) exist but custom permission checks were never built. Define roles like Owner, Accountant, Bookkeeper, Employee, and gate specific actions using Clerk's `has({ permission: "..." })` checks in Server Actions and middleware.

**d. Bank reconciliation** - Formal process of comparing recorded transactions against a real bank statement for a period, marking things "reconciled," flagging discrepancies. Builds directly on the bank_transactions table.

**e. Multi-currency support** - Add a currency field to transactions/accounts and exchange-rate handling. Meaningful added complexity - a good project once everything else feels solid.

**f. Editing and voiding** - This build deliberately never implemented edit/delete for invoices, bills, or journal entries (never destroy financial history). The correct pattern is a "void"/"reversal" journal entry (the `reversal` value already exists, unused, in journalSourceTypeEnum from file 03) that cancels an incorrect entry by posting its exact opposite, preserving a full audit trail while letting users "undo" mistakes.

**g. Full Plaid integration** - File 06's Part D gave the conceptual map and a sandbox starting point; turning that into a production-ready bank feed is a substantial but achievable next project.

### Phase 3 roadmap (bigger undertakings, tackle only once Phase 2 feels solid)

- **Payroll** - genuinely complex (tax withholding rules, filing requirements); consider integrating a payroll-as-a-service API rather than building tax logic from scratch
- **Tax forms (1099s, sales tax)** - jurisdiction-specific rules, another strong candidate for a specialized third-party API
- **Inventory tracking** - quantity on hand, cost of goods sold calculations (FIFO/LIFO/average cost), tied into the existing Chart of Accounts
- **Multi-entity consolidated reporting** - rolling up reports across multiple organizations a user manages

### Good engineering habits to build in now

- **Automated tests around the ledger engine specifically** - postJournalEntry (file 03) is the single highest-value thing to have real automated tests for (balanced entries succeed, unbalanced ones throw, single-line entries are rejected). Consider a real test suite with Vitest.
- **Splitting environments properly** - separate Clerk apps and Neon database branches for development vs production becomes much more important once real user data is involved.
- **Monitoring and error tracking** - once deployed for real users, a tool like Sentry catches and alerts on production errors you won't be watching your terminal for.
- **Rate limiting and abuse prevention** - especially once file uploads (CSV import) and public-facing forms are live on the internet.

### How to keep growing this project

Pick ONE item from the Phase 2 list (editing/voiding is a great next choice - conceptually rich, builds directly on the journal engine, no new third-party service required) and build it the same way this whole set was built: understand the concept first, design the schema, write the server logic with the same rigor (atomic transactions, server-side re-validation, never trust client input), then build the UI last.

The actual hard part of building an accounting system - the ledger discipline - has now been internalized. Everything else from here is applying that same discipline to new features, one at a time.

---

This is the final file in the 8-file consolidated set (00 through 07). Together, files 00-07 contain the complete, code-heavy, beginner-friendly path from an empty computer to a live, deployed, working double-entry accounting SaaS application, plus a roadmap for continued development beyond this point.
```

**`07-deployment-and-roadmap.md` is now complete** — PART A and PART B both appended.

---

## 🎉 All 8 stage files are done!

You now have the complete set:
1. `00-master-overview.md`
2. `01-foundations.md`
3. `02-auth-and-database-foundation.md`
4. `03-accounting-core.md`
5. `04-core-features.md`
6. `05-reports.md`
7. `06-automation-and-bank-data.md`
8. `07-deployment-and-roadmap.md`

## What's left in the RAG set (2 more groups)

Per the original structure, there are two more pieces you can still get as `.md` files:
- **`appendix-a-full-codebase.md`** — the complete final-state codebase reference (18 source notes, config files through API routes) — this is the largest remaining piece
- **Accounting primer (Appendices B–H)** — either one combined file or split into 7 separate files (fundamentals, Chart of Accounts, transaction cookbook, financial statements, glossary, mistakes/close, accrual vs cash)

