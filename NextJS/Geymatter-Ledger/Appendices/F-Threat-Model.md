# Appendix F: Threat Model

A threat model asks one question, systematically: *for this specific application, what could go wrong, who could make it go wrong, and what did we actually build to stop them?* This appendix walks through Greymatter Ledger's real attack surface — not generic security advice, but a concrete accounting of every trust boundary crossed across Parts 1–14.8, what protects each one today, and what honestly remains a gap.

## F.1 — Actors and Trust Boundaries

Before listing threats, name who's actually interacting with the system, and where the boundaries between them sit.

| Actor | Trust level | Boundary crossed |
|---|---|---|
| Anonymous internet visitor | Untrusted | `/`, `/sign-in`, `/sign-up` — the only routes reachable with zero credentials |
| Authenticated user, no active org | Low trust | Passed Clerk's identity check, but `getOrCreateOrganization()` (Part 3) has nothing to scope data to yet |
| Authenticated user, `member` role | Medium trust | Can read/write routine business data within their org, cannot void, run payroll, or add tax adjustments (Part 14.3) |
| Authenticated user, `admin` role | High trust | Can additionally void entries, run payroll, deactivate accounts, complete reconciliations, add tax adjustments |
| Inngest (external service) | Semi-trusted, keyed | Reaches `/api/inngest` with a signing key (Part 11); can trigger any registered function |
| A bank-feed aggregator (Brankas/Finverse) | Semi-trusted, tokened | Holds a long-lived `accessToken` (Part 14.8) capable of reading real bank transaction history |
| The database itself (Neon) | Trusted infrastructure | Assumed honest; not modeled as an adversary, though its credentials are a protected asset |

The single most important boundary in the entire app, crossed on almost every request: **`organizationId` scoping**. Every table from Part 3 onward carries an `organizationId` column, and every query is expected to filter on it. This is the actual perimeter fence around each customer's data — not the network, not the database, but a `WHERE organizationId = ...` clause that has to be present on every single query, everywhere, forever.

## F.2 — Assets Worth Protecting, Ranked

1. **The integrity of the ledger** (`journal_entries`/`journal_lines`) — if this can be silently corrupted or made to not balance, every report built on it (Parts 9, 10, 14.6) becomes actively misleading, which is worse than an outage.
2. **Cross-tenant data isolation** — one organization ever seeing or modifying another's invoices, accounts, or ledger.
3. **Authentication secrets** — Clerk's `CLERK_SECRET_KEY`, Neon's connection strings, Inngest's signing key, and (as of Part 14.8) bank aggregator access tokens.
4. **The ability to void/reverse history** (Part 14.2) — since this is precisely the operation capable of quietly rewriting what the books say happened.
5. **Availability** — a business genuinely cannot invoice, get paid, or file GST if the app is down, though this ranks below integrity, since a wrong number is worse than a slow page.

## F.3 — Threat Walkthrough by Attack Surface

### T1 — Cross-Tenant Data Leakage

**The threat:** A user belonging to Organization A somehow reads or writes data belonging to Organization B.

**Where this could go wrong, concretely:** any server action or query that omits the `eq(table.organizationId, organizationId)` filter, or filters on a record's own ID alone (e.g., `eq(invoices.id, invoiceId)` without also checking `organizationId`).

**What's actually built to stop it:**
- Every server action across Parts 7, 8, 12, 14.2–14.7 calls `getOrCreateOrganization()` first, deriving `organizationId` from the *server-side session*, never from client-supplied input — a user cannot pass `organizationId` as a form field and have it trusted.
- Every lookup-by-ID query (`getInvoiceById`, `voidInvoice`, `voidPayment`, etc.) is written with a **compound `and(eq(id, ...), eq(organizationId, ...))** condition — Part 7's reference section calls this out explicitly as "never ID alone."
- `postJournalEntry` (Part 6) independently re-verifies every referenced `accountId` actually belongs to the calling organization, even though every caller should already guarantee this — the "don't trust the caller" defense-in-depth principle.

**Residual risk:** this protection is a *pattern*, not a database constraint — Postgres itself has no row-level security policy enforcing it (this course never builds Postgres RLS). A future engineer adding a new query who forgets the `organizationId` filter would introduce a real leak with nothing at the database layer to catch it. This is worth naming plainly: the isolation model is disciplined application code, not defense at the data layer.

### T2 — Ledger Corruption / Unbalanced Entries

**The threat:** A journal entry gets saved where debits don't equal credits, silently breaking every report's correctness (Part 4's core promise).

**What's built to stop it:**
- `postJournalEntry`'s four guard clauses (Part 6) run before any write: minimum two lines, no line with both debit and credit set, integer-cents comparison of total debits vs. credits, and account-ownership verification.
- The entire insert is wrapped in a real database transaction (`dbTransactional.transaction`) — a crash mid-write cannot leave a partial, unbalanced entry behind.
- Every single money-moving feature across the entire app — invoices, bills, payments, payroll, bank import, voiding — routes through this one function. There is no second path to insert a `journal_lines` row.

**Residual risk:** Drizzle Studio (or any direct SQL access to Neon) bypasses `postJournalEntry` entirely. Part 9's troubleshooting section already names this directly: a manual edit in Drizzle Studio during testing is the most likely cause of a false "out of balance" reading. In production, this means **anyone with direct database credentials can corrupt the ledger** — the guard clauses live in application code, not a Postgres `CHECK` constraint. A stricter design would add a database trigger enforcing balance on `journal_lines` directly; this course deliberately keeps that logic in TypeScript for readability, at the cost of this residual gap.

### T3 — Unauthorized Voiding (Ledger Rewriting)

**The threat:** A low-trust user reverses a journal entry, invoice, bill, or payment they shouldn't be able to touch — effectively rewriting financial history.

**What's built to stop it:** `requireAdminRole()` (Part 14.3) is the *first line* of `voidInvoice`, `voidBill`, and `voidPayment` — checked before any database read, let alone write. The check reads `orgRole` from Clerk's server-side session (`auth()`), never from client input, so it cannot be spoofed by a tampered request body.

**Residual risk:** this is a two-role model only (`admin`/`member`) — there's no finer-grained "can void but cannot run payroll" tier. A business wanting separation of duties (e.g., a bookkeeper who can enter data and see reports, but only a controller can void) would need Clerk custom roles and a corresponding expansion of `permissions.ts` — not built in this course.

### T4 — Secret Exposure via Git History

**The threat:** A Clerk secret key, Neon connection string, or Inngest signing key ends up permanently embedded in a public or leaked Git repository.

**What's built to stop it:**
- `.env.local` is excluded via `.gitignore`'s `.env*` pattern from the very first commit (Part 1).
- Part 13.1 makes this an explicit, mandatory pre-flight check before ever pushing to GitHub: `git status` must never show `.env.local`, and `git log --all --full-history -- .env.local` must return completely empty — checked *before* the repository is even created on GitHub.
- Appendix B's security checklist repeats this as a standing habit, not a one-time step.

**Residual risk:** this protects against *accidental* commits, not against a compromised developer machine, a leaked screenshot, or a maliciously shared `.env.local`. No secret rotation schedule is built or enforced — Part 13's troubleshooting section only tells you to rotate keys *after* a suspected leak, reactively, not on any proactive cadence.

### T5 — Compromised Bank Aggregator Token (Part 14.8)

**The threat:** `bank_connections.accessToken` is read by an attacker with database access, and used to pull a real bank account's full transaction history from Brankas/Finverse directly.

**What's built to stop it:** Honestly — very little, and this is stated plainly in both Part 14.8 and Appendix A.20: the token is stored as **plain text**, with an explicit code comment stating a real deployment must add application-layer encryption before this table ever holds a genuine credential. This is the single most consequential unresolved item in this entire threat model, precisely because Part 14.8 is a stretch goal that was built out for completeness but never hardened to production standard.

**What a real fix would require (not built here):** encrypt `accessToken` at the application layer (e.g., AES-256-GCM with a key held outside the database, such as a KMS-managed key or a Vercel encrypted environment variable), decrypting only transiently in memory when `syncBankFeeds` actually calls the provider.

### T6 — Inngest Function Invocation Spoofing

**The threat:** Someone other than the real Inngest service calls `/api/inngest`'s `POST` handler directly, attempting to trigger `voidJournalEntry`-adjacent logic, payroll runs, or recurring invoice generation on demand.

**What's built to stop it:** Inngest's `serve()` helper (Part 11.2) verifies incoming requests against `INNGEST_SIGNING_KEY` — a request without a valid signature is rejected before any of our function code ever runs. This is infrastructure Inngest provides, not something built by hand in this course, but it's correctly wired in.

**Residual risk:** if `INNGEST_SIGNING_KEY` itself leaks (see T4), this protection is void — signature verification is only as strong as the secret behind it.

### T7 — Overpayment / Double-Posting Race Conditions

**The threat:** Two simultaneous payment submissions against the same invoice both read the same "remaining balance" before either write completes, both pass the overpayment guard, and together overpay the invoice.

**What's built to stop it:** Partially. `recordInvoicePayment`/`recordBillPayment` (Part 8) check `newAmountPaid > total` using a value read *before* the transaction begins, then write inside a transaction — but the read-then-transact pattern is not itself protected by a row-level lock (`SELECT ... FOR UPDATE`) or a database-level `CHECK` constraint preventing `amountPaid > total`. Under genuinely concurrent requests (two browser tabs submitting near-simultaneously), a race is theoretically possible.

**Residual risk, stated plainly:** this is a real, unresolved gap. A production-grade fix would either wrap the balance check and the insert in a single transaction that locks the invoice row first (`SELECT ... FOR UPDATE` inside the same `dbTransactional.transaction` block), or add a database-level `CHECK (amountPaid <= total)` constraint as a last-resort backstop. Neither was built in this course — the overpayment guard is application-level only, checked against a value that could theoretically be stale by the time the write actually lands.

### T8 — Duplicate Bank Transaction Injection

**The threat:** The same bank transaction gets posted to the ledger twice — either by uploading overlapping CSV exports (Part 12) or by a live feed sync re-fetching transactions it already imported (Part 14.8).

**What's built to stop it:** `duplicateCheckHash` (`sha256(date|description|amount)`), computed identically by both the CSV upload path and the live-sync path, checked against every existing hash for the organization before any insert. This is a genuinely shared defense — both import mechanisms write into the same `imported_transactions` table and are protected by the same check.

**Residual risk:** the hash is content-based, not a true unique transaction ID from the bank — Part 12's own reference section already names this honestly: two genuinely different same-day, same-description, same-amount transactions (e.g., two identical $10 coffee purchases) would collide and the second would be incorrectly treated as a duplicate and silently dropped. This is a deliberate, acknowledged tradeoff, not an oversight, but it means a small number of real transactions could theoretically go unrecorded without any error surfaced to the user.

### T9 — Reconciliation Bypass

**The threat:** A user marks a period "reconciled" without the ledger actually matching the bank statement, undermining the entire point of Part 14.4's feature.

**What's built to stop it:** `completeReconciliation` recomputes the checked-off total from the *actual* `journal_lines` amounts server-side, and refuses to complete unless that computed total matches `statementEndingBalance` within one cent — it never trusts a client-supplied "yes, it matches" flag. The completion action is also admin-gated (Part 14.3).

**Residual risk:** nothing prevents an admin from checking off the *wrong* transactions that happen to sum to the right total (e.g., omitting a real item and including an unrelated one that coincidentally makes the math work). The system verifies arithmetic, not that the *right* transactions were selected — that judgment call is left entirely to the human doing the reconciliation, which is arguably correct (a machine can't know which transactions the bank statement actually shows), but worth naming as a limit of what this feature actually guarantees.

### T10 — Client-Side Trust (Forms, Totals, Validation)

**The threat:** A user tampers with client-side JavaScript or submits a crafted request directly, bypassing form validation to submit invalid data (negative quantities, a fabricated total, a spoofed `organizationId`).

**What's built to stop it:** Every server action independently recalculates totals from raw inputs (`quantity × unitPrice`, GST math) rather than trusting any total computed in the browser — stated explicitly in Part 7's reference section ("never trust any total the browser might have sent"). `organizationId` is never accepted as client input anywhere in the app; it's always derived server-side from the authenticated session via `getOrCreateOrganization()`.

**Residual risk:** input *type* validation (e.g., rejecting a negative `quantity` or an absurd `gstRate` like 500%) is inconsistently enforced — some server actions check for empty strings and non-positive prices (Part 7's invoice form), but no comprehensive schema-validation layer (e.g., Zod) was built across every action. A determined user crafting a raw request could likely submit a negative quantity on an invoice line and have it silently accepted, producing a nonsensical but "balanced" journal entry.

## F.4 — Summary Table: Protected vs. Genuinely Open

| Threat | Status |
|---|---|
| Cross-tenant data leakage | Mitigated by consistent application-level pattern; no database-level enforcement (RLS) |
| Unbalanced ledger entries | Strongly mitigated — enforced in one centralized, transactional function |
| Unauthorized voiding | Mitigated — server-side role check, first line of every void action |
| Secrets in Git history | Mitigated — mandatory pre-flight check before every push |
| Bank aggregator token exposure | **Open** — stored as plain text, explicitly flagged as needing encryption |
| Inngest request spoofing | Mitigated by Inngest's own signing-key verification |
| Payment race conditions | **Open** — no row-level locking or database-level CHECK constraint |
| Duplicate bank transactions | Mitigated, with an acknowledged, narrow false-positive edge case |
| Reconciliation bypass | Mitigated for arithmetic; not mitigated against selecting the wrong line items |
| Client-side input tampering | Partially mitigated — totals always recalculated server-side; type/range validation inconsistent |

## F.5 — What a Genuinely Production-Hardened Version Would Add

None of the following exist anywhere in this course, and all of them are legitimate next steps beyond Part 14's roadmap for anyone taking Greymatter Ledger toward real, unattended production use with real money:

1. **Postgres Row-Level Security (RLS)** policies on every table, keyed to `organizationId`, as a database-enforced backstop behind the application-level filtering pattern (closes T1's residual risk).
2. **A database trigger or `CHECK` constraint** enforcing `SUM(debitAmount) = SUM(creditAmount)` per `journalEntryId` directly in Postgres, independent of application code ever calling `postJournalEntry` correctly (closes T2's residual risk).
3. **Application-layer encryption** for `bank_connections.accessToken`, with the encryption key held outside the database (closes T5).
4. **Row-level locking** (`SELECT ... FOR UPDATE`) inside `recordInvoicePayment`/`recordBillPayment`'s transaction, or a `CHECK (amountPaid <= total)` constraint as a backstop (closes T7).
5. **A schema-validation layer** (e.g., Zod) applied uniformly across every server action's inputs, rejecting malformed data before it reaches business logic (closes T10).
6. **A secret rotation schedule and audit log**, rather than reactive-only rotation after a suspected leak (hardens T4).
7. **Finer-grained roles** beyond admin/member, for real separation-of-duties requirements (hardens T3).

## F.6 — The One-Sentence Summary

Greymatter Ledger's security model is genuinely strong at the one thing this entire course was built to teach — **the ledger cannot become mathematically inconsistent through the application's own code paths** — and genuinely incomplete at the things a production security review would flag next: database-level tenant isolation, credential encryption at rest, and concurrency safety under real simultaneous load. Both halves of that sentence are equally honest, and knowing exactly where the line sits is the actual point of writing a threat model at all.

