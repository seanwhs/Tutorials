# Appendix H: Incident Response Runbook

Appendix F told you what could go wrong. Appendix G told you how to prevent it before shipping. This appendix is for the moment prevention already failed — a specific, ordered set of steps for each realistic Greymatter Ledger incident, written so you can follow it under stress without having to reconstruct the reasoning from scratch. Each entry follows the same shape: **Detect → Contain → Investigate → Remediate → Prevent Recurrence.**

## H.1 — How to Use This Runbook

Find the section matching your symptom. Follow the steps in order — don't skip to remediation before containment, even if it feels slower. Every step references the exact command, file, or dashboard used elsewhere in this course, so nothing here requires inventing a new tool mid-incident.

---

## H.2 — Incident: Suspected Leaked Secret (Clerk key, Neon connection string, Inngest signing key)

**Trigger:** You notice `.env.local` in a `git status` output, a secret pasted into a public chat/screenshot, or a `git log --all --full-history -- .env.local` (Part 13.1) returning non-empty results.

**Detect**
1. Confirm the leak is real: run `git log --all --full-history -- .env.local` again, and separately `git log -p --all | grep -i "sk_test\|sk_live\|postgresql://"` to search the full diff history for any secret-shaped string, not just the filename.
2. Identify *which* specific secrets appeared — Clerk's `CLERK_SECRET_KEY`, Neon's connection strings, or Inngest's `INNGEST_SIGNING_KEY`/`INNGEST_EVENT_KEY`.

**Contain**
3. If already pushed to GitHub: make the repository private immediately if it isn't already (Settings → General → Danger Zone → Change visibility), even though this does not undo the exposure — assume anyone who could have cloned it already has.
4. Do **not** attempt to fix this by simply deleting the file and committing again — the secret remains permanently in Git history unless the history itself is rewritten (out of scope for a quick response; rotation is faster and safer).

**Investigate**
5. In each affected dashboard, check for signs of misuse:
   - **Clerk:** Dashboard → Users/Sessions — look for sign-ins from unfamiliar locations or a spike in new user creation.
   - **Neon:** Dashboard → Monitoring — look for unusual query volume or connection counts.
   - **Inngest:** Dashboard → Runs — look for function invocations you didn't trigger.

**Remediate**
6. Rotate every leaked secret at its source, immediately:
   - **Clerk:** Dashboard → API Keys → regenerate the secret key.
   - **Neon:** Dashboard → Connection Details → reset the database password (this changes both the pooled and unpooled connection strings).
   - **Inngest:** Dashboard → Manage → Keys → regenerate.
7. Update `.env.local` locally with every new value.
8. Update Vercel's environment variables (Project Settings → Environment Variables) with the same new values.
9. Trigger a redeploy (Vercel Deployments tab → **⋯** → Redeploy) so the live app picks up the rotated secrets.
10. Confirm the app still works end-to-end after rotation: sign in, visit `/dashboard`, confirm `/reports/balance-sheet` still loads correctly.

**Prevent Recurrence**
11. Re-run Appendix G.5's checklist. If the leak happened via a screenshot or chat paste rather than a Git commit, this is a human-process gap, not a code gap — consider redacting secrets before ever sharing terminal output or `.env.local` contents with anyone, including in support requests.

---

## H.3 — Incident: Balance Sheet Shows "❌ Out of Balance"

**Trigger:** The banner built in Part 9, Step 9.3 (`isBalanced`) flips to red in a real (non-test) organization.

**Detect**
1. Note the exact `asOfDate` used when the red banner appeared — this scopes your investigation window.
2. Confirm this isn't a testing artifact: check whether anyone has recently used Drizzle Studio to directly edit `journal_lines` (Part 9's troubleshooting section names this as the most likely cause) — ask, or check for unexplained edits if multiple people have database access.

**Contain**
3. Do not attempt any repair yet. Adding a "correcting" journal entry before understanding *what* is unbalanced risks making the actual problem harder to find.

**Investigate**
4. Run a query directly against the ledger to find any individual journal entry that doesn't balance on its own (this should be structurally impossible if `postJournalEntry` was never bypassed, so finding one is the smoking gun):
```sql
SELECT je.id, je.description, je.entry_date,
       SUM(jl.debit_amount) AS total_debit,
       SUM(jl.credit_amount) AS total_credit
FROM journal_entries je
JOIN journal_lines jl ON jl.journal_entry_id = je.id
WHERE je.organization_id = '<the affected org id>'
GROUP BY je.id, je.description, je.entry_date
HAVING SUM(jl.debit_amount) != SUM(jl.credit_amount);
```
Run this in Neon's own SQL editor (Part 3, Step 3.7's cross-check method) — not just Drizzle Studio — to rule out any client-side display quirk.
5. If a genuinely unbalanced entry is found, check `sourceType`/`sourceId` on that row to identify what feature created it, and whether it was created through `postJournalEntry` at all (a direct manual insert would also explain this).
6. If **no** unbalanced individual entry is found, the discrepancy is in the report's own aggregation logic, not the ledger — re-check `getAccountBalancesAsOf`'s SQL (Part 9, Step 9.1) for a recent, unintended edit.

**Remediate**
7. If a genuinely unbalanced entry exists in the ledger (should never happen via the app itself): do **not** delete or edit it in place — this violates the immutability principle from Part 6 and Part 14.2. Instead, manually construct a correcting journal entry via `postJournalEntry` directly (not Drizzle Studio) that brings the *account balances* back to where they should be, with a clear `description` explaining the correction and why it was needed outside the normal void/reversal flow.
8. If the issue was in report logic, fix and redeploy the code, then reload the report to confirm the banner returns to green.

**Prevent Recurrence**
9. Restrict who has direct Neon/Drizzle Studio access in a real production deployment — this incident type is only possible when someone bypasses the application layer entirely. Consider Appendix F, Section F.5, item 2 (a database-level `CHECK` constraint enforcing balance) as a genuine hardening step if this recurs.

---

## H.4 — Incident: Suspected Cross-Tenant Data Leak

**Trigger:** A user reports seeing data (an invoice, a customer name, an account) that doesn't belong to their organization.

**Detect**
1. Get the exact URL, action, or screen the user was on when they saw the unexpected data.
2. Identify both organizations involved — the affected user's real organization, and whose data appears to have leaked.

**Contain**
3. If the leak is confirmed and ongoing (not a one-time historical report), consider taking the specific affected route offline temporarily (e.g., via a Vercel redeploy of a version with that route disabled) while you investigate — better to have a broken feature than an active data leak.

**Investigate**
4. Locate the exact server action or query involved, using the reported URL and Appendix D's route-to-table traceability matrix.
5. Apply Appendix G.2's checklist directly to that code: does it call `getOrCreateOrganization()`? Does every lookup-by-ID query use the compound `and(eq(id,...), eq(organizationId,...))` pattern, or does it filter by ID alone?
6. This is very likely where the bug will be found — Appendix F's T1 names this exact failure mode as the residual risk of an application-level-only isolation pattern.

**Remediate**
7. Fix the specific query to include the missing `organizationId` filter.
8. Audit every *other* query in the same file for the identical mistake — a missing filter is rarely isolated to just one function if it was introduced by a copy-paste error.
9. Deploy the fix, then confirm directly: sign in as each affected test organization and confirm the previously-leaking route now correctly shows only that organization's own data.

**Prevent Recurrence**
10. Add this specific route to your personal regression-testing habits going forward.
11. Seriously consider Appendix F, Section F.5, item 1 (Postgres Row-Level Security) as a database-level backstop, since this incident class proves the application-level pattern alone was insufficient at least once.

---

## H.5 — Incident: Unauthorized Void of a Journal Entry, Invoice, Bill, or Payment

**Trigger:** An admin notices a voided record they didn't personally void, or a member-role user somehow triggered a void action.

**Detect**
1. Query `journal_entries` for the specific voided row and its `voidedAt` timestamp:
```sql
SELECT id, description, is_voided, voided_at, reversal_of_entry_id
FROM journal_entries
WHERE organization_id = '<org id>' AND is_voided = true
ORDER BY voided_at DESC;
```
2. Cross-reference the timestamp against your application's own logs (Vercel Runtime Logs, Part 13 troubleshooting) to identify which user session triggered it.

**Contain**
3. If this was a genuine unauthorized action (not a legitimate admin action you simply forgot about), do not attempt to "un-void" by editing `isVoided` back to `false` directly in the database — this violates the immutability principle just as directly as editing amounts would.

**Investigate**
4. Confirm whether `requireAdminRole()` (Part 14.3) was actually bypassed, or whether the acting user genuinely held admin role in Clerk at the time (check Clerk Dashboard → Organization → Members → role history if available, or ask the user directly).
5. If the guard was genuinely bypassed (e.g., a direct API call crafted outside the UI, or a bug in `requireAdminRole` itself), treat this as a code-level security incident, not just a permissions misconfiguration.

**Remediate**
6. Since the original entry's reversal already exists and is itself a permanent, correct ledger fact (per Part 14.2's design — the reversal is real even if it shouldn't have happened), the correct fix is to reverse the *reversal* — call `voidJournalEntry` again, targeting the reversal entry itself, which produces a second reversal that restores the original economic effect. This keeps the full, honest history visible: original → unauthorized reversal → correcting reversal, all three permanently in the ledger.
7. If a code-level bypass was found, patch it immediately and redeploy before doing anything else.

**Prevent Recurrence**
8. Re-verify Appendix G.2's admin-gating checklist item across `voidInvoice`, `voidBill`, and `voidPayment` specifically — confirm `requireAdminRole(...)` is genuinely the first executable line in each, with no code path that reaches the database before it.

---

## H.6 — Incident: Suspected Compromised Bank Aggregator Token (Part 14.8)

**Trigger:** Unexpected transactions appear in `imported_transactions` that don't correspond to real account activity, or the bank/aggregator itself notifies you of suspicious API access.

**Detect**
1. Check `bank_connections.lastSyncedAt` and cross-reference against your actual sync schedule (`cron: "0 * * * *"`, hourly) — an out-of-schedule sync suggests the token was used outside the app's own job.
2. Contact the aggregator (Brankas/Finverse) support/security channel directly — they can check access logs on their end for the specific `providerAccountId`, which your own database cannot see.

**Contain**
3. Immediately revoke the specific `accessToken` at the aggregator's dashboard/API (every aggregator provides a token revocation endpoint or dashboard control — consult their current documentation, since this course's Part 14.8 implementation was explicitly scaffolding, not a hardened integration).
4. Set the corresponding `bank_connections.status` to `"disconnected"` immediately, so `syncBankFeeds` (Part 14.8, Step 14.8.4) stops attempting to use the revoked token on its next hourly run:
```sql
UPDATE bank_connections
SET status = 'disconnected'
WHERE id = '<connection id>';
```

**Investigate**
5. Determine how the token was obtained. Given Appendix F's T5 and Appendix A.20 both flag `accessToken` as stored in **plain text**, the most likely vector is direct database access (a compromised Neon credential — see H.2) rather than a flaw in the aggregator's own systems.
6. If database access is the suspected vector, treat this as a subset of the H.2 (leaked secret) runbook — rotate `DATABASE_URL`/`DATABASE_URL_UNPOOLED` as well, since the same access that read the token could read every other secret and every row of financial data in the database.

**Remediate**
7. Have the customer/business re-authorize a fresh bank connection through the aggregator's normal flow, generating a brand-new `accessToken`, stored in a new `bank_connections` row.
8. Before storing the new token, this is the moment to actually implement the encryption-at-rest fix flagged as a known gap since Part 14.8 was written (Appendix F, Section F.5, item 3) — do not simply store the replacement token in plain text again.

**Prevent Recurrence**
9. This incident is a strong, concrete signal that Appendix F's T5 residual risk is not merely theoretical. Prioritize application-layer encryption for this column before reconnecting any real bank account going forward.

---

## H.7 — Incident: Duplicate Bank Transactions Posted to the Ledger

**Trigger:** The same real-world bank transaction appears twice in the Balance Sheet's Cash figure, discovered during a reconciliation session (Part 14.4) that fails to match the bank statement.

**Detect**
1. Query for `imported_transactions` rows sharing the same `duplicateCheckHash` — this should be structurally impossible given Part 12's exclusion logic, so finding one indicates the hash check itself was bypassed or a genuine hash collision occurred (Appendix F, T8's acknowledged edge case):
```sql
SELECT duplicate_check_hash, COUNT(*)
FROM imported_transactions
WHERE organization_id = '<org id>'
GROUP BY duplicate_check_hash
HAVING COUNT(*) > 1;
```

**Contain**
3. Do not delete either duplicate row yet — if either has already been posted (`status = "posted"`), it has a real `journal_entries` row backing it, which must be handled through voiding, not deletion.

**Investigate**
4. For each duplicate pair, check whether both were posted, or only one. If only one was posted, the unposted duplicate can simply be marked `ignored` via `ignoreImportedTransaction()` (Part 12) — no ledger impact exists yet.
5. If **both** were posted, you have two real, separate journal entries recording the same economic event once.

**Remediate**
6. For the genuinely duplicate *posted* entry: use `voidJournalEntry` (Part 14.2) directly against its `journalEntryId`, with a reason like "Duplicate bank transaction — reversing double-posted entry." This preserves full history (both postings and the reversal remain visible) rather than deleting anything.
7. Re-run the reconciliation session (Part 14.4) for the affected period — it should now correctly match the bank statement.

**Prevent Recurrence**
8. If this was caused by uploading overlapping CSV date ranges (the documented cause in Part 12), this is user process, not a code defect — no fix needed beyond user awareness.
9. If this was caused by a genuine hash collision (two distinct real transactions, same date/description/amount), this is the acknowledged edge case in Appendix F's T8 — no action needed unless it recurs frequently enough to justify adding a true provider-supplied transaction ID to the hash instead of just date/description/amount.

---

## H.8 — Incident: Suspected Payment Race Condition (Overpayment or Double-Posting)

**Trigger:** An invoice's `amountPaid` exceeds its `total`, or two `payments` rows appear to have been created from what the user insists was a single click.

**Detect**
1. Query the specific invoice/bill directly:
```sql
SELECT id, total, amount_paid, status FROM invoices WHERE id = '<invoice id>';
SELECT id, amount, payment_date, created_at FROM payments WHERE invoice_id = '<invoice id>' ORDER BY created_at;
```
2. Check the `createdAt` timestamps on the resulting `payments` rows — if two rows were created within milliseconds of each other, this strongly confirms the race condition flagged in Appendix F's T7, rather than two genuinely separate, intentional payments.

**Contain**
3. No immediate containment action needed beyond noting the affected invoice/bill — this is a data-correction task, not an active ongoing threat.

**Remediate**
4. Void one of the two duplicate payment rows via `voidPayment()` (Part 14.2) — this correctly reverses its journal entry and recomputes the invoice's `amountPaid`/`status` from scratch, exactly as designed for this kind of correction.
5. Confirm the invoice's `amountPaid` and `status` are now correct after the void.

**Prevent Recurrence**
6. This is the one incident type in this runbook where the actual code-level fix (Appendix F, Section F.5, item 4 — row-level locking via `SELECT ... FOR UPDATE`, or a database-level `CHECK (amountPaid <= total)` constraint) has not been built anywhere in this course. If this recurs more than once, treat it as a signal to prioritize that fix rather than continuing to manually correct each occurrence via `voidPayment()`.

---

## H.9 — General Post-Incident Checklist (Apply After Any Section Above)

- [ ] Was the root cause a **code defect**, a **process gap**, or a **credential compromise**? Categorize honestly — the fix differs for each.
- [ ] Was any data corrected using `voidJournalEntry`/`voidPayment`/`voidInvoice`/`voidBill`, preserving full history — never a direct edit or deletion of a posted row?
- [ ] Were all affected secrets rotated, if credential compromise was involved (cross-reference H.2)?
- [ ] Does Appendix F's threat model need a new entry, or an existing entry's "residual risk" status updated, based on what actually happened?
- [ ] Does Appendix G's checklist need a new line item to catch this specific mistake earlier next time?
- [ ] Has the affected organization/user been informed, if their own data or an action attributable to them was involved?
