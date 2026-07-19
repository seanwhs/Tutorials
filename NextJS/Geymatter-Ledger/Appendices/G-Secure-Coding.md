# Appendix G: Secure Coding Checklist

*Corrected for the no-`src/` project structure (paths now read `app/...`, `lib/...`, `db/...`, `components/...` at the project root, with `@/*` resolving to `./*` per `tsconfig.json`).*

Appendix F asked "what could go wrong?" This appendix asks the forward-looking version: **before you ship any new feature to Greymatter Ledger, what should you personally verify?** Every item below traces back to a specific pattern already established somewhere in Parts 1–14.8 — this isn't new advice, it's the existing discipline of the course made checkable.

## G.1 — Schema Changes

Run through this whenever you add or modify a table in `db/schema.ts`.

- [ ] Does this table have an `organizationId` column with `onDelete: "cascade"` to `organizations`? (Every tenant-scoped table since Part 3 has this — a table without it cannot be safely isolated per-customer.)
- [ ] If this table's rows represent money that has already moved (an invoice, a bill, a payment, a journal line), does its foreign key to `accounts`/`customers`/`vendors` use `onDelete: "restrict"`, not `"cascade"`? (Part 6, Part 7 reference sections — historical financial rows must never silently vanish because an unrelated parent record was deleted.)
- [ ] If this table's rows have no independent meaning outside a parent (like `invoice_lines` without `invoices`), does it correctly use `"cascade"` instead? (Getting this backwards in either direction is a real bug — Appendix A.22 is the canonical reference for which is which.)
- [ ] Are money columns using `numeric(14,2)`, never `real`/`double`/`float`? (Part 6 — floating point cannot represent currency exactly.)
- [ ] If this is a new enum, is the value set genuinely small and stable (five or fewer options, rarely changing)? If not, use plain `text` instead. (Part 5 reference section.)
- [ ] Did you run `npm run db:generate` **and** `npm run db:migrate`, and inspect the generated SQL file before applying it? (Part 3, Part 5 — never skip reading what's about to run against real data.)

## G.2 — New Server Actions

Run through this for every new file in `lib/actions/`.

- [ ] Is `"use server"` the first line of the file?
- [ ] Is `getOrCreateOrganization()` (or an equivalent session-derived lookup) called, and is its return value — never a client-supplied `organizationId` — used in every subsequent query? (T1 in Appendix F — this is the entire cross-tenant isolation model.)
- [ ] Does every lookup-by-ID query use a **compound** `and(eq(table.id, id), eq(table.organizationId, organizationId))` condition, never `eq(table.id, id)` alone? (Part 7 — "never ID alone.")
- [ ] If this action reverses, deletes, or otherwise rewrites historical financial data (voiding, deactivating, completing a reconciliation), is `requireAdminRole(...)` the literal **first executable line**, before any database read? (Part 14.3 — checked before touching anything, not interspersed partway through.)
- [ ] If this action performs more than one write that must succeed or fail together, is the entire operation wrapped in a single `dbTransactional.transaction(...)` block? (Part 6, and the Part 14.2 atomicity fix — this was a real bug once; don't repeat it.)
- [ ] If this action calls another function that itself might need to join the same transaction (like `postJournalEntry` or `voidJournalEntry`), is the transaction's `tx` object passed down as an explicit executor parameter, rather than letting that function silently open its own second transaction? (Part 7, Step 7.8's composable-transaction pattern.)
- [ ] Does this action independently recompute every dollar amount from raw inputs, never trusting a total the client submitted? (Part 7 reference section.)
- [ ] Is `revalidatePath(...)` called only **after** the transaction has committed, never before, and never before an event is sent to Inngest? (Part 11.3's ordering discipline — never announce a change before it's guaranteed real.)
- [ ] Does every thrown error include a specific, human-readable reason (never a bare generic message)? (Established as a stated convention in Appendix E.3.)

## G.3 — Route & Middleware Changes

- [ ] If this is a new page requiring authentication, is its path pattern added to `isProtectedRoute` in `proxy.ts` (project root)? (Part 2, extended in Parts 7 and 12 — a forgotten route here is silently public.)
- [ ] Is `proxy.ts` confirmed sitting at the true project root — sibling to `package.json` and `app/` — and **not** accidentally nested inside `app/proxy.ts`, where Next.js would silently ignore it? (This is the one file whose exact location genuinely matters structurally, regardless of `src/` or not.)
- [ ] Does the new route rely on `proxy.ts`'s check alone for role-based restrictions, or does it (correctly) leave fine-grained permission checks to the server action itself? (Part 14.3 reference note — `proxy.ts` answers "logged in with an active org?" only; it does not and should not know about per-action roles.)
- [ ] If this is a new API route (like `app/api/inngest/route.ts`), does it verify the caller cryptographically (a signing key), rather than relying on obscurity of the URL? (Part 11.2 — Inngest's `serve()` does this already; any new webhook-style route needs its own equivalent.)

## G.4 — Client Components & Forms

- [ ] Is every void/deactivate/admin-only button's visibility gated by a server-fetched `isAdmin` boolean, computed via `isCurrentUserAdmin()`, rather than a client-side guess? (Part 14.3 — this is UX polish, not the real security boundary, but it should still be correct.)
- [ ] Does hiding a button client-side ever substitute for the corresponding server-side `requireAdminRole()` check? (It must not — G.2's checklist item is the actual boundary; this section is only ever a convenience layer on top of it.)
- [ ] Are numeric form inputs parsed defensively (`parseFloat(...) || 0`, `Number(...)` rather than `parseFloat(...)` for strict validity checks) to avoid `NaN` propagating silently into a calculation? (Part 7's live-preview logic, Part 14.2's `Number()` vs `parseFloat()` fix.)

## G.5 — Environment Variables & Secrets

- [ ] Before your **first** commit touching any new integration, does `.gitignore` already exclude the file that will hold its secret? (It should — `.env*` has covered this since Part 1 — but confirm rather than assume.)
- [ ] Before every `git push`, did you run `git status` and confirm `.env.local` is absent from the list? (Part 13.1 — mandatory, not optional.)
- [ ] If this feature introduces a new kind of stored credential (an API token, an access key — see `bank_connections.accessToken`, Part 14.8), is it stored encrypted, or is the plaintext-storage tradeoff explicitly documented as a known gap, the way Appendix A.20 and Appendix F's T5 both do? (Never silently ship plaintext secret storage without saying so somewhere.)

## G.6 — Path/Import Sanity (New — No-`src/` Structure)

- [ ] Does `tsconfig.json` read `"@/*": ["./*"]`, not `["./src/*"]`? A leftover `src/*` alias would silently break every `@/`-prefixed import the moment any file actually moved to the project root.
- [ ] Do all files genuinely sit at `app/`, `lib/`, `db/`, `components/` — project-root siblings — rather than a stray leftover `src/` folder from an earlier scaffold coexisting alongside them? Two parallel copies (one under `src/`, one at root) is a realistic outcome of a mid-project restructure and would cause confusing duplicate-definition errors.

## G.7 — The One Question to Ask Before Merging Anything

> **"If a user in Organization A tampered with every value this feature sends to the server, what is the worst thing that could happen to Organization B's data?"**

If the honest answer is "nothing — every query is scoped to a server-derived `organizationId`, every sensitive action re-checks role and ownership independently," the feature is consistent with everything this course has built. If the answer involves *any* client-supplied ID being trusted without a server-side ownership check, stop and fix it before shipping — this is the single question underlying almost every mitigation in Appendix F.
