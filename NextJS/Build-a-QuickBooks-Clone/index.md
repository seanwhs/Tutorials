# QB Clone Tutorial — INDEX (Start Here)

**Build a QuickBooks Clone with Next.js 16, Clerk, Inngest & Neon**

Targets **Next.js 16** throughout (Node.js 20.9+/22 LTS, Turbopack default, async `params`/`searchParams`, Tailwind CSS v4, and `src/proxy.ts` in place of the older `src/middleware.ts`).

### How to use this series
Each part is its own saved note. Just ask for a part by number ("show me Part 9") or say "continue." Some parts split across two notes ("continued") — read both. Several parts have a separate Troubleshooting Addendum note — read it alongside the main part.

### Full Part List

| Part | Title | Notes |
|---|---|---|
| 0 | Introduction | Orientation, no code |
| 1 | Setting Up Your Computer | Node.js 20.9+/22 LTS, VS Code, Git, GitHub |
| 2 | Your First Next.js Project | create-next-app, Turbopack, Tailwind v4, routing |
| 3 | Understanding Our Toolbox | Conceptual, no code |
| 4 | Adding Login with Clerk | ClerkProvider, `src/proxy.ts`, protected dashboard |
| 5 | Organizations = Companies | OrganizationSwitcher, org-required guard |
| 6 | Getting a Free Database with Neon | Account, connection strings, SQL Editor |
| 7 | Talking to the DB with Drizzle ORM | Schema, migrations, test insert |
| 8 | Debits, Credits & Double-Entry Accounting | Conceptual, worked examples |
| 9 | Building the Chart of Accounts | Extended schema, seed function |
| 10 | Building the Journal Entry Engine | `postJournalEntry`, balanced/unbalanced tests |
| 11 | Customers and Vendors | Server Actions CRUD pattern |
| 12 | Building Invoices | **2 notes** — main + continued (sections 3-6) |
| 13 | Invoices → Journal Entries | Atomic invoice + ledger posting |
| 14 | Bills and Expenses | **2 notes** — main + continued (sections 5-10) |
| 15 | Recording Payments | **2 notes** — main + continued (sections 5-9) |
| 16 | Profit & Loss Report | + separate Troubleshooting Addendum |
| 17 | Balance Sheet | + separate Troubleshooting Addendum |
| 18 | AR/AP Aging Reports | + separate Troubleshooting Addendum |
| 19 | Your First Background Job (Inngest) | + separate Troubleshooting Addendum |
| 20 | Scheduled Jobs / Cron | + separate Troubleshooting Addendum |
| 21 | CSV Bank Transaction Import | + separate Troubleshooting Addendum |
| 22 | Connecting Real Banks with Plaid (optional) | + separate Troubleshooting Addendum |
| 23 | Deploying to Vercel for Free | + separate Troubleshooting Addendum |
| 24 | What's Next | Phase 2/3 roadmap, no code |

### Appendix A: Full Codebase Reference
Complete, final, accumulated state of every project file — lives in the **"QB Clone RAG - Appendix A ..."** note set (18 notes: INDEX + Parts 1/1b/1c/2/2b/2c/3/3b/3c/4/4b/4c/4d/5/5b/5c/6/6b). Start at *"QB Clone RAG - Appendix A INDEX (Full Codebase Reference)"*.

### Accounting/Bookkeeping Primer
Also in the "QB Clone RAG" note set: **Appendices B–H** (9 notes) — fundamentals, Chart of Accounts in depth, a 34-example transaction cookbook, reading financial statements, glossary, common mistakes, and accrual vs cash basis.
