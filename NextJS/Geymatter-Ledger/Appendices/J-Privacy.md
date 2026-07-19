# Appendix J: Data Privacy & Retention Notes

Every table built across this course stores real information about real people — customer names and addresses, employee wages, bank transaction descriptions. This appendix inventories exactly what personal data Greymatter Ledger holds, how long it's kept (the honest answer, for most of it, is *forever*, by design), and what a real Singapore business would need to think through under the **PDPA** (Personal Data Protection Act) — a natural, locally-relevant companion to Part 10's GST and Part 14.6's tax disclaimers, using the same "internal reference, not legal advice" framing established there.

## J.1 — Why Retention Is "Forever" By Design, and Why That's a Deliberate Choice

Recall the soft-delete pattern established in Part 5 and repeated in every subsequent part: `isActive` flags on accounts, customers, and vendors; `isVoided` flags on journal entries and payments (Part 14.2); nothing in this entire schema ever executes a real `DELETE`. This was chosen for a specific, defensible reason — accounting records need to survive audits, disputes, and multi-year historical reporting, and the entire architecture (Part 4, Part 6) is built around the premise that posted history is permanent fact.

The privacy tension this creates is real and worth naming directly: **PDPA and similar personal data laws generally expect an organization to have a defined retention period and a genuine deletion capability**, not indefinite storage by default. This course's "never delete" accounting discipline and a real privacy law's "don't keep data forever" expectation are in direct tension, and this appendix doesn't pretend otherwise — it names exactly where that tension lives in the schema, so you know precisely what would need to change to reconcile the two.

## J.2 — Personal Data Inventory, Table by Table

| Table | Personal data held | Whose data | Retention today |
|---|---|---|---|
| `customers` | Name, email, address | The business's customers | Forever — soft-deleted only, `isActive = false` |
| `vendors` | Name, email, address | The business's suppliers | Forever — soft-deleted only |
| `employees` | Name, monthly wage, CPF rates | The business's own staff | Forever — soft-deleted only |
| `invoices` / `invoice_lines` | Line-item descriptions (can contain client-identifying project details) | Customers, indirectly | Forever — even `void` status keeps the row |
| `payments` | Payment method, amount, date | Customers/vendors, indirectly | Forever — even `isVoided` keeps the row |
| `imported_transactions` | Raw bank statement description text (often contains merchant names, sometimes personal references in memo fields) | The business itself, and whoever it transacted with | Forever — even `ignored` status keeps the row |
| `pay_runs` | Gross wage, CPF amounts, net pay per employee per cycle | Employees | Forever |
| `journal_entries.description` | Free-text, can reference customer/vendor/employee names directly (e.g., `"Payroll: Jane Tan"`, Part 14.5) | Whoever is named in the description | Forever, by the core design principle of Parts 4 and 6 |
| `bank_connections.accessToken` | Not personal data itself, but a credential granting access to real bank transaction history | The business's own bank account | Until manually revoked/rotated (Part 14.8, Appendix H.6) |

**The one row worth sitting with:** `journal_entries.description` is free text, populated automatically by nearly every server action (`"Invoice INV-..."`, `"Payment received for Invoice..."`, `"Payroll: Jane Tan"`). Because this column feeds every report in Parts 9, 10, and 14.6, and because Part 14.2 makes it structurally impossible to ever edit a posted entry's description, **a personal name once written into a journal entry description is permanent for the life of the business's books**, by the architecture's own design.

## J.3 — What PDPA-Style Obligations Would Actually Require (Not Legal Advice)

Consistent with the exact same disclaimer pattern used for Part 10's GST F5 report and Part 14.6's tax estimate: what follows is an educational summary of the *categories* of obligation a real business would need to address, not a compliance checklist, and not a substitute for actual legal counsel. PDPA (and similar regimes) generally organize around a few recurring themes:

- **Consent and purpose limitation** — data should be collected for a stated purpose and not silently reused for another. Greymatter Ledger's customer/vendor/employee records are collected for the stated purpose of running the books — using that same data for, say, unsolicited marketing would be a separate purpose requiring its own basis.
- **Retention limitation** — data should not be kept indefinitely "just in case." As Section J.1 makes explicit, this course's architecture keeps everything forever by design, which is a real gap against this specific principle, not an oversight to be dismissed.
- **Access and correction rights** — an individual (a customer, a vendor, an employee) generally has a right to know what data is held about them and to request correction of inaccuracies. Nothing in this course builds a self-service "what data do you have about me" or correction-request flow.
- **Data breach notification** — many regimes require notifying affected individuals and/or a regulator within a defined window after a confirmed breach. Appendix H's incident response runbook covers the *technical* response (rotate keys, contain, remediate) but does not cover the *notification* obligation, which is a legal/business process decision, not a code change.
- **Cross-border transfer restrictions** — some regimes restrict transferring personal data outside the country without safeguards. Neon, Clerk, Vercel, and Inngest are all US-headquartered infrastructure providers (Part 1, Part 13) — a real Singapore business handling PDPA-covered data should confirm each provider's actual data residency/hosting region and transfer safeguards, which varies by provider and by the specific region selected during setup (recall Part 3, Step 3.1's region choice for Neon).

## J.4 — What a Real Deletion Capability Would Require

If a real business needed to honor an actual deletion request (as opposed to the soft-delete pattern this course builds), it would collide directly with the "posted entries are permanent" principle at the heart of Parts 4 and 6. A defensible approach, not built anywhere in this course, would be:

1. **Distinguish "delete the person's identifying details" from "delete the financial fact."** A journal entry's *existence* and *dollar amounts* may need to remain for audit/tax retention requirements even after a customer requests their personal data be removed — but the *name* in a free-text description could potentially be redacted or replaced with a stable reference ID.
2. **Add an explicit retention policy field** — e.g., a `retentionExpiresAt` timestamp on `customers`/`vendors`/`employees`, reflecting each jurisdiction's actual statutory retention period for accounting records (commonly 5–7 years in many jurisdictions, though the exact figure requires real legal confirmation, not a course-provided default).
3. **Build a genuine anonymization path**, distinct from the `isActive`/`isVoided` soft-delete flags already built — one that overwrites `name`/`email`/`address` with placeholder values while leaving the numeric ledger facts (which don't inherently identify a person) intact.

None of this is built in this course, and this appendix says so directly rather than implying otherwise.

## J.5 — Data Minimization Check Against What Was Actually Built

Worth asking plainly: does every personal-data column across Parts 1–14.8 earn its place?

- `customers.address`, `vendors.address` (Part 7) — collected but never actually used by any report or feature built in this course. A real minimization review would ask whether this field is genuinely necessary or was added by habit ("every contact form has an address field") rather than because any downstream feature (invoicing, GST F5, tax estimate) actually consumes it.
- `employees.monthlyWage`, `employeeCpfRate`, `employerCpfRate` (Part 14.5) — all directly necessary for the stated purpose (running payroll), and appropriately scoped.
- `imported_transactions.description` (Part 12) — necessarily broad, since it's raw bank statement text the user doesn't control the format of; this is an inherent property of the CSV import approach, not a design choice that could be minimized without breaking the feature.

## J.6 — The One-Sentence Summary

Greymatter Ledger's "never delete, only soft-delete or reverse" architecture is exactly correct for accounting integrity (Parts 4 and 6's core promise) and simultaneously incomplete for real personal-data-protection obligations (PDPA-style retention limitation and deletion rights) — reconciling the two would require adding an explicit retention/anonymization layer that distinguishes "the financial fact that must survive" from "the personal identifier that may need to be removed," a genuine architectural extension this course never builds, named here so it isn't mistaken for an oversight.
