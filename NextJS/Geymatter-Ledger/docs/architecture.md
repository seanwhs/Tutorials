# architecture.md

## Greymatter Ledger — System Architecture

This document describes the technical architecture of Greymatter Ledger for engineers joining the project, reviewing a pull request, or planning an extension. It assumes familiarity with the codebase's *behavior* (see the User Guide and Test Plan) and instead focuses on *why the system is shaped the way it is*.

---

## 1. High-Level System Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                            BROWSER                                │
│        Next.js pages (Server Components) + Client Components      │
│           Tailwind CSS · React 19 · useActionState hooks          │
└───────────────────────────┬────────────────────────────────────────┘
                            │ Server Actions ("use server")
                            │ + a small number of Route Handlers
┌───────────────────────────▼────────────────────────────────────────┐
│                     NEXT.JS 16 APPLICATION SERVER                  │
│                                                                     │
│  proxy.ts  ── Clerk auth gate, runs before every matched request   │
│                                                                     │
│  lib/actions/*.ts  ── Server Actions (the only write surface)      │
│  lib/*.ts          ── Shared business logic (journal, reports,     │
│                        aging, gst, tax, reconciliation, permissions)│
│  app/api/inngest/route.ts ── Inngest function registry endpoint    │
└────────┬───────────────────────────┬──────────────────┬────────────┘
         │                           │                  │
┌────────▼────────┐        ┌─────────▼─────────┐  ┌─────▼──────────┐
│      CLERK       │        │      INNGEST        │  │  BANK AGGREGATOR │
│ Auth + Org roles  │        │ background/scheduled │  │ (Brankas/Finverse,│
│ (JWT session)     │        │ job execution         │  │  stretch goal)    │
└──────────────────┘        └──────────────────────┘  └─────────────────┘
         │
┌────────▼─────────────────────────────────────────────────────────┐
│                  NEON POSTGRES (via Drizzle ORM)                  │
│                                                                    │
│   Two connection modes, deliberately different:                   │
│   • db  (neon-http)         — simple reads/writes, HTTP-based     │
│   • dbTransactional (neon-serverless / WebSocket) — for real       │
│     multi-statement transactions via db.transaction(...)          │
│                                                                    │
│   20 tables, organized around one center of gravity:               │
│   journal_entries / journal_lines                                  │
└────────────────────────────────────────────────────────────────────┘
```

---

## 2. Architectural Principles (In Priority Order)

These aren't arbitrary preferences — each one directly enabled a specific capability elsewhere in the system, and violating any of them would break something concrete, not just "best practice."

### 2.1 — One Write Path for Money

**Principle:** Every operation that changes an account's balance passes through exactly one function: `postJournalEntry` (or its composable wrapper, `voidJournalEntry`).

**Why:** This is the foundational bet of the entire system. Instead of scattering balance-affecting logic across invoices, bills, payroll, and bank imports independently (each with its own chance to introduce a subtle bug), all of that logic is centralized into one small, heavily-guarded function. Every feature built afterward — four financial reports, a GST return, a tax estimate — becomes pure aggregation over data it can *trust*, because that data was mathematically forced to balance the moment it was written.

**What this actually buys you, concretely:** the Balance Sheet's "✅ Balanced" banner is not a display trick — it's a live, computed proof that holds *only* because nothing has ever bypassed `postJournalEntry`. If a future feature ever writes directly to `journal_lines`, this guarantee silently breaks.

### 2.2 — Immutable Ledger, Additive Correction

**Principle:** A posted `journal_entries` row is never edited or deleted. Corrections are always a *new*, offsetting entry (`voidJournalEntry`), with the original flagged (`isVoided`), never altered.

**Why:** Real accounting requires an audit trail where mistakes are visibly corrected, not silently erased. This principle cascades into schema design: every foreign key from a historical table (journal_lines, invoices, bills, payments) back to `accounts`/`customers`/`vendors` uses `onDelete: "restrict"`, never `"cascade"` — the database itself refuses to let a parent record vanish out from under posted history.

### 2.3 — Multi-Tenancy at the Application Layer, Enforced by Convention

**Principle:** Every table carries an `organizationId` column; every query filters on it, derived server-side from the authenticated session, never from client input.

**Why:** This is the cheapest correct way to build multi-tenancy for a project of this scope, and it's honestly documented (Appendix F, T1) as *not* database-enforced — there is no Postgres Row-Level Security layer backing this up. The isolation is a discipline (checked in `lib/permissions.ts`'s sibling checklist, Appendix G.2), not a structural guarantee. This is a deliberate scope decision, not an oversight, but it's the single highest-leverage hardening step for anyone taking this system further.

### 2.4 — Two Database Clients, One Schema

**Principle:** `db` (HTTP-based, `drizzle-orm/neon-http`) handles simple reads/writes. `dbTransactional` (WebSocket-based, `drizzle-orm/neon-serverless`) exists solely to support real, multi-statement `.transaction()` calls.

**Why:** Serverless environments (Vercel) favor short-lived HTTP connections for most work, but a genuine database transaction requires holding one connection open across several statements — something the HTTP client cannot do. Rather than pay the WebSocket connection cost everywhere, the app uses the lightweight client by default and reaches for the heavier one only where atomicity is actually required.

### 2.5 — Composable Transactions via an Executor Parameter

**Principle:** Functions that need to write inside a larger, caller-defined transaction accept an optional `executor` parameter, defaulting to opening their own transaction if none is provided.

**Why:** Without this, combining "post a journal entry" with "also update an invoice's status" as one atomic unit would require either duplicating validation logic in the caller, or accepting two separate, non-atomic transactions (the exact bug found and fixed in the Part 14.2 rewrite). This pattern — `postJournalEntry(input, executor)`, `voidJournalEntry(..., executor)` — is the single mechanism that lets every subsequent feature (payments, payroll, bank import, voiding) compose cleanly with the core engine without copy-pasting its guard clauses.

### 2.6 — Server Actions as the Only Write Surface

**Principle:** All mutations happen through `"use server"` functions in `lib/actions/`, called directly from forms or client components — no separate REST/GraphQL API layer exists for internal writes.

**Why:** This collapses an entire category of duplicate validation logic (client-side + server-side + API-layer) into one place, and keeps the trust boundary singular and auditable — every write's authorization check lives in exactly one function, checkable via Appendix G's line-item checklist.

---

## 3. The Database, Structurally

Twenty tables, but they cluster into five functional groups:

| Group | Tables | Role |
|---|---|---|
| **Identity & COA** | `organizations`, `accounts`, `customers`, `vendors`, `employees` | Who and what the ledger references |
| **The Ledger Itself** | `journal_entries`, `journal_lines` | The single source of financial truth |
| **AR / AP Documents** | `invoices`, `invoice_lines`, `bills`, `bill_lines`, `payments` | Documents that *produce* journal entries |
| **Operational Extensions** | `recurring_invoice_templates`, `imported_transactions`, `reconciliations`, `reconciliation_items`, `pay_runs`, `bank_connections` | Automate or stage the creation of journal entries |
| **Advisory / Non-Ledger** | `tax_adjustments` | Deliberately *outside* the ledger — tax-law reclassifications, never posted as journal entries |

**The one structural fact worth internalizing:** almost every table in this schema exists to eventually produce exactly one row in `journal_entries`. Reading the schema as "what feeds the ledger" rather than "a flat list of 20 tables" is the fastest way to understand the system.

---

## 4. Request Lifecycle: A Concrete Trace

Tracing `createInvoice` end-to-end shows every architectural principle above in one flow:

1. **Browser** — user submits `<InvoiceForm />`, a Client Component, computing a live preview client-side (never trusted server-side).
2. **`proxy.ts`** — already passed, since this happened before the page even rendered; confirms an active Clerk session and organization.
3. **`lib/actions/invoices.ts` → `createInvoice`** — calls `getOrCreateOrganization()` (never trusts a client-supplied org ID), independently recalculates every line total in integer cents (never trusts the client's preview numbers).
4. **`dbTransactional.transaction(async (tx) => {...})`** opens — everything inside must succeed together.
5. Inserts `invoices` and `invoice_lines` using `tx`.
6. Calls `postJournalEntry(..., tx)` — passing the transaction down (Principle 2.5) rather than letting it open a second, separate transaction.
7. `postJournalEntry` runs its four guard clauses (line count, no hybrid lines, debit=credit, account ownership) — all before writing anything.
8. Writes `journal_entries` + `journal_lines`, still inside `tx`.
9. Transaction commits — **only now** is `inngest.send({ name: "invoice/created", ... })` called (Principle: never announce a change before it's guaranteed real).
10. `revalidatePath("/invoices")`, then `redirect()` to the new invoice's detail page.

Every one of Parts 6 through 14.2's design decisions shows up somewhere in this single trace.

---

## 5. External Service Boundaries

| Service | What it owns | What we store locally | Trust model |
|---|---|---|---|
| **Clerk** | User identity, sessions, organization membership, roles | A local `organizations` mirror row (`clerkOrgId`), never passwords or session internals | We trust its signed JWTs completely; see Appendix K |
| **Neon (Postgres)** | All application data | N/A — it *is* the data store | Fully trusted infrastructure; not modeled as adversarial |
| **Inngest** | Background/scheduled job execution | Nothing persistent — it calls back into our own DB | Verified via signing key on every inbound request |
| **Vercel** | Hosting, deployment, environment variables | N/A | Trusted infrastructure |
| **Bank aggregator (stretch goal)** | Real bank transaction history | `bank_connections.accessToken` (plaintext — a known, documented gap) | Semi-trusted, tokened; see Appendix F, T5 |

---

## 6. Known Architectural Debt

Named directly, not buried:

1. **No database-level tenant isolation (RLS).** The `organizationId` filtering pattern is entirely application-level.
2. **No database-level balance constraint.** `postJournalEntry`'s guard clauses are the only thing preventing an unbalanced entry — a direct SQL write bypasses them entirely.
3. **No row-level locking on payment writes.** A theoretical race condition exists between reading an invoice's remaining balance and writing a new payment against it.
4. **Plaintext credential storage** for `bank_connections.accessToken`.
5. **No FX gain/loss recognition** when a foreign-currency invoice is settled at a different exchange rate than it was issued at.
6. **No schema-level input validation layer** (e.g., Zod) — individual server actions validate inconsistently rather than through one shared, enforced contract.
7. **`imported_transactions` has no `void` status** — a bank-import-sourced journal entry can be reversed via `voidJournalEntry` directly, but the staging row itself has no way to reflect that, leaving it stale.
8. **`voidPayment` recomputes invoice/bill status from scratch on every call** rather than maintaining a running ledger of payment history — correct today, but worth revisiting if payment volume per document grows large enough that this recomputation becomes a real cost.

Each of these is cross-referenced in Appendix F (Threat Model) and Appendix A's "Known Gaps" sections — this document doesn't duplicate the full reasoning, only flags *that* the debt exists and where to read more.

---

## 7. Extension Points (Where to Add Things)

For anyone extending this system, here's where new work actually plugs in, by category:

| If you're adding... | It plugs into |
|---|---|
| A new report | `lib/reports.ts`'s `getAccountBalancesAsOf`/`getAccountBalancesForRange` — almost never needs new SQL, just new filtering/grouping over existing account balances |
| A new document type that affects the ledger (e.g., credit notes) | Mirror the `invoices`/`bills` pattern: a header table + line table + a server action that computes totals and calls `postJournalEntry` inside one transaction |
| A new background/scheduled job | `lib/inngest/functions/`, registered in `app/api/inngest/route.ts`'s `functions` array |
| A new admin-only action | Call `requireAdminRole("description of the action")` as the literal first line, per Appendix G.2 |
| A new "undo" capability for a table that doesn't have one yet (e.g., `imported_transactions`) | Follow the `voidPayment`/`voidInvoice` pattern exactly: add `isVoided`/`voidedAt` columns, wrap the reversal + status update in one `dbTransactional.transaction()` |
| A new external integration needing a stored credential | Store it encrypted at the application layer from day one — do not repeat the `bank_connections.accessToken` plaintext gap |

---

## 8. Why Certain "Obvious" Alternatives Were Rejected

Worth stating explicitly, since these come up in code review:

- **"Why not a single `amount` column with a sign, instead of separate `debitAmount`/`creditAmount`?"** — A signed single column makes every future query a silent trap (`SUM(amount)` requires the reader to remember the sign convention). Two always-non-negative columns make every query self-evidently correct.
- **"Why not enforce the balance rule with a Postgres `CHECK` constraint instead of application code?"** — This is a legitimate hardening step (see Section 6, item 2) not yet built, not a rejected idea. Application-level enforcement was chosen for this course/project's scope because it's more approachable to reason about and modify; a `CHECK` constraint or trigger is the natural next hardening layer for a team taking this to real production scale.
- **"Why not one shared `contacts` table instead of separate `customers`/`vendors`?"** — They drive opposite sides of the ledger (AR vs. AP); keeping them separate keeps every query unambiguous about which direction money flows, at the cost of some structural duplication.
- **"Why not derive `normalBalance` from `accountType` at query time instead of storing it?"** — It's fully derivable, but storing it explicitly simplifies every downstream query and leaves room for future exceptions (contra-accounts) without restructuring the table.

---

## 9. Document Map

For deeper detail on any area touched above, see:

| Topic | Document |
|---|---|
| Full column-by-column schema | Appendix A |
| Environment configuration | Appendix B |
| Command reference | Appendix C |
| Complete route listing | Appendix D |
| Terminology | Appendix E |
| Attack surface and residual risk | Appendix F |
| Pre-merge security checklist | Appendix G |
| Incident response steps | Appendix H |
| Third-party dependency risk | Appendix I |
| Personal data / retention | Appendix J |
| Auth/session internals | Appendix K |
| End-user behavior | User Guide |
| First-day onboarding | Quick-Start Card |
| QA test cases | Test Plan |

**[END OF architecture.md]**
