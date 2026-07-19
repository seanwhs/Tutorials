# Greymatter Ledger: Test Plan

A systematic QA test plan covering every feature built across the full course (Parts 1–14.8). Organized so it can be run top-to-bottom on a fresh deployment, or filtered down to just the area you're changing. Each test case includes a specific expected result — not just "check it works," but the exact number, status, or banner you should see, since this app's whole premise is that the numbers must be *exactly* right.

---

## 1. Scope & Objectives

**In scope:** authentication, multi-tenancy isolation, the Chart of Accounts, the journal engine, invoicing, billing, payments, all reports, GST F5, background/scheduled jobs, bank CSV import, voiding/reversal, role-based permissions, bank reconciliation, payroll, tax estimation, multi-currency, and deployment configuration.

**Out of scope:** load/performance testing at scale, penetration testing (see Appendix F for the threat model instead), and validation of Part 14.8's bank-feed integration against a real aggregator sandbox (that requires live provider credentials not covered here).

**Exit criteria:** every test case in Sections 2–15 passes, with Section 16 (Regression Suite) re-run clean after any code change.

---

## 2. Test Environment Setup

| Item | Requirement |
|---|---|
| Two test organizations | e.g. "Acme Test Co", "Second Test Co" — for isolation testing |
| Two test user accounts | One Admin, one Member (per Part 14.3) — for permission testing |
| A seeded Chart of Accounts | Confirmed present on every test org before starting (Part 5) |
| Database inspection access | Drizzle Studio (`npm run db:studio`) or Neon's SQL editor |
| Inngest local dev server running | `npx inngest-cli@latest dev`, for Sections 10 and 12 |
| A sample bank CSV file | `Date,Description,Amount` format, at least 5 rows, mixing positive and negative amounts |

---

## 3. Authentication & Multi-Tenancy (Parts 2–3)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| AUTH-01 | Sign-up flow | Visit `/sign-up`, complete registration | Redirected to `/dashboard`; user greeted by name |
| AUTH-02 | Sign-out and re-sign-in | Sign out via `<UserButton />`, then sign back in | Lands back on `/dashboard` with same org context |
| AUTH-03 | Protected route redirect | While signed out, visit `/invoices` directly | Redirected to `/sign-in`, not a raw 404 |
| AUTH-04 | No-org guard | Sign in with a brand-new account, no org created yet | Yellow "No organization selected" warning shown, not real data |
| AUTH-05 | Org auto-seeding | Create a brand-new organization, visit `/accounts` | Exactly 18 accounts appear (15 original + CPF Payable, Employer CPF Expense, Salary Expense from 14.5) |
| AUTH-06 | Org switching isolation | Create Org A and Org B under the same user; add a customer to Org A only | Switch to Org B → customer list is empty; switch back to Org A → customer reappears |
| AUTH-07 | Cross-tenant ID guess | Note an invoice ID from Org A; while Org B is active, manually visit `/invoices/<Org-A-invoice-id>` | 404 — not the invoice, not an error leaking its existence |

---

## 4. Chart of Accounts (Part 5)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| COA-01 | Default seed correctness | View `/accounts` on a fresh org | All 5 categories present (Assets, Liabilities, Equity, Revenue, Expenses), each account under the correct category |
| COA-02 | Deactivate as Member | Sign in as Member, visit `/accounts` | No "Deactivate" link visible on any row |
| COA-03 | Deactivate as Admin | Sign in as Admin, deactivate "Bank Fees Expense" | Status badge flips to "Inactive"; account no longer appears in bank-import categorization dropdown |
| COA-04 | Re-seeding guard | Attempt to trigger seeding twice for the same org (e.g. revisit backfill logic if present) | Account count remains unchanged — no duplicates created |

---

## 5. The Journal Engine (Part 6)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| JRN-01 | Valid balanced entry | Post a manual entry: debit Cash $500, credit Owner's Equity $500 | Succeeds; both lines appear in `journal_lines` |
| JRN-02 | Unbalanced entry rejected | Attempt debit Cash $500, credit Equity $400 | Throws: "Journal entry does not balance..."; **zero** rows written to `journal_entries` or `journal_lines` |
| JRN-03 | Single-line entry rejected | Attempt one line only | Throws: "must have at least two lines"; nothing saved |
| JRN-04 | Hybrid debit+credit line rejected | Attempt one line with both `debit: 100` and `credit: 50` set | Throws immediately; nothing saved |
| JRN-05 | Cross-org account rejected | Attempt to post using an `accountId` belonging to a different organization | Throws: accounts do not belong to the specified organization; nothing saved |
| JRN-06 | Atomicity under failure | Force an error partway through a multi-step transaction (e.g. simulated throw after `voidJournalEntry` but before a status update) | **Neither** the reversal nor the status update persists — verify via Drizzle Studio |

---

## 6. Invoicing (Part 7)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| INV-01 | Single-rate invoice | 10 hrs × $100, 9% GST | Subtotal $1,000.00, GST $90.00, Total $1,090.00 |
| INV-02 | Mixed-rate invoice | Add a second line at 0% GST, $200 | Subtotal updates to $1,200.00, GST stays $90.00, Total $1,290.00 |
| INV-03 | Journal posting correctness | After INV-02, inspect `journal_lines` | Debit AR $1,290.00 = Credit Revenue $1,200.00 + Credit GST Output $90.00 |
| INV-04 | No customers guard | Visit `/invoices/new` on an org with zero customers | Redirected to `/customers` with a reason param |
| INV-05 | Detail page accuracy | Open the created invoice | Line items, subtotal, GST, total all match the creation form's preview exactly |

---

## 7. Bills & Payments (Part 8)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| BILL-01 | Multi-account bill | Two lines: Rent Expense $2,000, Software Expense $100, both 9% GST | Total $2,289.00; `journal_lines` shows **4** rows (2 expense debits + GST Input debit + AP credit) |
| PAY-01 | Partial invoice payment | Pay $500 of a $1,290 invoice | Status → "partially_paid"; Balance Due → $790.00; payment form still visible |
| PAY-02 | Full invoice payment | Pay remaining $790 | Status → "paid"; Balance Due → $0.00; payment form disappears |
| PAY-03 | Overpayment rejected | Attempt to pay $1,000 against a $790 remaining balance | Throws; balance and status unchanged; no new `payments` row created |
| PAY-04 | Bill payment journal shape | Fully pay a bill | Debit AP = Credit Cash, both equal to the bill total |

---

## 8. Reports (Part 9)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| RPT-01 | P&L date range | Set a date range covering known test invoices/bills | Total Revenue and Total Expenses match manually-summed test data exactly |
| RPT-02 | Balance Sheet banner | Visit `/reports/balance-sheet` with real data | Green "✅ Balanced" banner shown |
| RPT-03 | Balance Sheet at zero | Set "As of" date before any test data existed | All figures $0.00; banner still green (0 = 0) |
| RPT-04 | AR Aging bucketing | Create an invoice with a due date ~45 days in the past | Appears in the "31–60 Days" bucket with correct days-overdue count |
| RPT-05 | Paid invoice excluded from Aging | Fully pay an invoice | No longer appears in AR Aging list |

---

## 9. GST F5 (Part 10)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| GST-01 | Box 4 cross-check | Compare GST F5's "Total Supplies" against P&L's "Total Revenue" for the identical date range | Figures match exactly |
| GST-02 | Box 5 cross-check | Compare "Total Taxable Purchases" against P&L's "Total Expenses" for the same range | Match, **unless** a bill line posted to a non-expense account (e.g. Office Equipment) — in which case a documented, expected discrepancy |
| GST-03 | Net payable sign | With Input Tax > Output Tax | Displays "Net GST Refundable by IRAS" in green, not "Payable" in red |

---

## 10. Background & Scheduled Jobs (Part 11)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| JOB-01 | Invoice confirmation event | Create an invoice | `invoice/created` event appears in Inngest local dashboard; function run shows "Completed" with both steps executed |
| JOB-02 | Overdue reminder trigger | Manually invoke `send-overdue-invoice-reminders` in Inngest dashboard | One log line per genuinely overdue invoice across all test orgs |
| JOB-03 | Recurring invoice generation | Create a template due today, manually trigger `generate-recurring-invoices` | New invoice created; template's `nextRunDate` advances |
| JOB-04 | Recurring invoice idempotency | Trigger the same job a second time immediately | **No** second invoice generated |

---

## 11. Bank CSV Import (Part 12)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| BANK-01 | Standard upload | Upload sample CSV with 5 rows | "Imported 5, Skipped 0 duplicate(s)" |
| BANK-02 | Duplicate detection | Upload the identical file again | "Imported 0, Skipped 5 duplicate(s)"; table still shows only 5 rows total |
| BANK-03 | Categorize → Post | Categorize a money-in row against Accounts Receivable, post it | Status → "posted"; journal entry: Debit Cash / Credit AR |
| BANK-04 | Categorize → Post (money out) | Categorize a negative-amount row against Bank Fees Expense, post it | Status → "posted"; journal entry: Debit Bank Fees Expense / Credit Cash |
| BANK-05 | Ignore action | Click "Ignore" on a pending row | Status → "ignored"; no journal entry created; row no longer shows action buttons |
| BANK-06 | Missing column rejection | Upload a CSV missing the "Amount" column | Clear error naming the missing column; nothing inserted |
| BANK-07 | Malformed row skip | Upload a CSV with one blank row mixed among valid ones | Valid rows imported normally; blank row silently skipped, not counted as an error |

---

## 12. Voiding & Reversal (Part 14.2)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| VOID-01 | Void an unpaid invoice | Void a fresh invoice with $0 paid, admin account | Status → "void"; original journal entry `isVoided = true`; new reversal entry exists with mirrored debit/credit lines |
| VOID-02 | Double-void rejected | Attempt to void the same invoice again | Throws: "already been voided"; no second reversal created |
| VOID-03 | Void blocked by payment | Attempt to void an invoice with `amountPaid > 0` | Throws: instructs to void the payment first; nothing changes |
| VOID-04 | Void a payment | Void a $500 partial payment on a $1,290 invoice | Payment `isVoided = true`; invoice `amountPaid` returns to $0.00; status reverts to "sent" (not stuck at "partially_paid") |
| VOID-05 | Full-payment void edge case | Fully pay an invoice, then void that single payment | `amountPaid` returns to exactly $0.00; status reverts to "sent", not left at "paid" or a negative balance |
| VOID-06 | Full lifecycle | Pay fully → void payment → void invoice | 4 total `journal_entries` rows exist for this invoice, all permanently visible; none deleted |
| VOID-07 | Atomicity under forced failure | Temporarily inject a thrown error between the reversal and the status update inside the transaction | Neither the reversal nor the status change persists — confirms the Part 14.2 atomicity fix holds |
| VOID-08 | Balance Sheet integrity post-void | Void an invoice, revisit `/reports/balance-sheet` | Still shows green "✅ Balanced" |
| VOID-09 | Aging exclusion post-void | Void an overdue invoice, revisit `/reports/aging` | No longer appears in the AR Aging list |

---

## 13. Role-Based Permissions (Part 14.3)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| PERM-01 | Member blocked from voiding | Sign in as Member, attempt to call the void action on an invoice | Throws: "Only an organization admin can void an invoice..."; nothing changes in the database |
| PERM-02 | Void UI hidden for Member | Sign in as Member, view an unpaid invoice's detail page | No "Void this record" button rendered at all |
| PERM-03 | Admin unaffected | Sign in as Admin, void the same invoice | Succeeds normally |
| PERM-04 | Payroll gated | Sign in as Member, visit `/payroll` | "Add Employee" form and "Run Payroll" buttons absent |
| PERM-05 | Reconciliation completion gated | Sign in as Member, attempt to complete a reconciliation | Throws; action blocked |
| PERM-06 | Tax adjustment gated | Sign in as Member, visit `/reports/tax-estimate` | Report visible (read access fine); "Add" adjustment form absent |

---

## 14. Bank Reconciliation, Payroll, Tax Estimate, Multi-Currency (Parts 14.4–14.7)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| RECON-01 | Start a session | Enter a real bank statement balance for a chosen date | Session created; unreconciled Cash lines listed |
| RECON-02 | Checklist running total | Check off lines one by one | Running total updates live; "✅ Matched" appears once equal to statement balance |
| RECON-03 | Completion guard | Attempt to complete before the total matches | "Complete Reconciliation" button remains disabled |
| RECON-04 | Server-side re-verification | Attempt to force-complete via a crafted request with a mismatched total | Throws — server recomputes the total independently, never trusts the client |
| RECON-05 | Prior-period exclusion | Complete a session, then start a new one for a later date | Previously-checked-off lines do not reappear in the new session's list |
| PAYROLL-01 | Standard pay run | Employee: $3,000 wage, 20%/17% CPF rates, run payroll | `pay_runs`: gross $3,000.00, employee CPF $600.00, employer CPF $510.00, net pay $2,400.00 |
| PAYROLL-02 | Journal balance | Inspect the resulting journal entry | Debits ($3,510.00: wage + employer CPF) = Credits ($3,510.00: net pay + total CPF payable) |
| PAYROLL-03 | P&L impact | Visit P&L for the pay period | Salary Expense and Employer CPF Contribution Expense both appear, reducing Net Income |
| TAX-01 | Net income cross-check | Compare Tax Estimate's "Accounting Net Income" against P&L for the identical period | Match exactly |
| TAX-02 | Add-back adjustment | Add a $500 non-deductible add-back | Estimated Chargeable Income increases by $500; illustrative tax increases by $85.00 (17%) |
| TAX-03 | Deduction adjustment | Add a $1,200 capital allowance | Chargeable Income decreases correspondingly |
| FX-01 | Foreign currency invoice | Create a USD invoice: $1,635 USD total at 1.35 SGD/USD | Invoice displays "$1,635.00 USD"; `journal_lines` shows SGD debit of $2,207.25, with `original_currency = "USD"` and `exchange_rate_to_sgd = 1.350000` |
| FX-02 | Balance check in SGD | Inspect the FX-01 journal entry | Debits equal credits in SGD, regardless of original currency |
| FX-03 | Mixed-currency Balance Sheet | Have both SGD and USD invoices posted | Balance Sheet still shows green "✅ Balanced", aggregating both correctly |

---

## 15. Deployment & Configuration (Part 13)

| ID | Test | Steps | Expected Result |
|---|---|---|---|
| DEPLOY-01 | Secrets check | Run `git log --all --full-history -- .env.local` | Empty result |
| DEPLOY-02 | Pooled connection in production | Check Vercel's `DATABASE_URL` env var | Hostname contains `-pooler` |
| DEPLOY-03 | Production Clerk domain | Sign up on the live deployed URL | Succeeds identically to local testing |
| DEPLOY-04 | Inngest production sync | Create an invoice on the live URL | Real `invoice/created` event and successful function run appear in Inngest's dashboard |
| DEPLOY-05 | Continuous deployment | Push a commit to `main` | New Vercel deployment triggers automatically within seconds |

---

## 16. Regression Suite (Run After Any Code Change)

The minimum set of tests to re-run after touching *any* part of the codebase, since so much of this app shares the journal engine:

1. JRN-01, JRN-02 (balance enforcement still works)
2. INV-01, BILL-01 (core posting shapes unchanged)
3. PAY-01, PAY-02 (payment lifecycle unchanged)
4. RPT-02 (Balance Sheet still balances)
5. VOID-01, VOID-07 (voiding and its atomicity still hold)
6. PERM-01 (permission gating still enforced)
7. AUTH-06 (tenant isolation still holds)

If all seven pass, the core financial integrity of the app is intact; expand to the full suite before a production release.

---

## 17. Defect Reporting Template

For any failed test case, capture:

```
Test ID: 
Organization used: 
Steps to reproduce: 
Expected result: 
Actual result: 
Relevant table(s) checked in Drizzle Studio: 
Screenshot/error message: 
```

**[END OF TEST PLAN]**
