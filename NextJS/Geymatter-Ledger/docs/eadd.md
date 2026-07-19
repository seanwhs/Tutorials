# Greymatter Ledger
## Enterprise Architecture Design Document (EADD)

**Document Type:** Architecture Design Document
**System:** Greymatter Ledger — Multi-Tenant Double-Entry Accounting Platform
**Classification:** Internal Engineering Reference
**Status:** Living Document — supersedes `architecture.md`

---

# Table of Contents

1. Executive Summary
2. Document Purpose, Audience & Conventions
3. Business Context & Drivers
4. Architectural Goals, Constraints & Non-Goals
5. Quality Attribute Requirements (NFRs)
6. Stakeholder Concerns
7. Architectural Views (C4-Style)
   - 7.1 Context View
   - 7.2 Container View
   - 7.3 Component View
   - 7.4 Code/Class View (Key Modules)
8. Data Architecture
9. Runtime / Process Views
10. Deployment View
11. Security Architecture
12. Architecture Decision Records (ADRs)
13. Cross-Cutting Concerns
14. Quality Attribute Scenarios & Tactics
15. Risk Register & Technical Debt Ledger
16. Capacity, Scaling & Performance Model
17. Observability & Operations
18. Extension & Evolution Roadmap
19. Compliance & Regulatory Mapping
20. Glossary & Traceability Matrix
21. Appendix Cross-Reference Index

---

# 1. Executive Summary

Greymatter Ledger is a multi-tenant, double-entry accounting platform built on Next.js 16, Postgres (via Neon), Clerk, Drizzle ORM, and Inngest. Its architecture is organized around a single, non-negotiable invariant: **every financial fact in the system is expressed as a balanced journal entry, and exactly one code path is permitted to create one.**

This single invariant is the load-bearing wall of the entire system. Every subsystem documented in this EADD — invoicing, billing, payroll, bank reconciliation, GST filing support, multi-currency, tax estimation — is, from an architectural standpoint, a *producer* of journal entries or a *consumer* (reporting layer) reading them. The system was deliberately designed so that correctness of the whole depends on correctness of one small, heavily-guarded function (`postJournalEntry`) rather than on the correctness of every feature independently.

This document formalizes what was previously captured informally across the tutorial series and `architecture.md` into a structured Enterprise Architecture Design Document: goals and constraints, quality attributes with measurable scenarios, architecture views at multiple levels of abstraction, a decision log (ADRs) explaining *why* each major structural choice was made and what alternatives were rejected, a consolidated risk register, and a compliance mapping relevant to the system's Singapore-market context (GST, CPF, PDPA).

**Architecture maturity assessment (self-declared, not audited):** Level 2/4 — "Defined and Documented." Core financial integrity guarantees are strong and structurally enforced within the application layer. Database-level defense-in-depth (row-level security, balance-check constraints), formal capacity/load testing, and a hardened secrets-management layer for third-party credentials remain open work, catalogued in Section 15.

---

# 2. Document Purpose, Audience & Conventions

## 2.1 Purpose

This EADD exists to answer four questions for any reader, regardless of how deeply they know the codebase:

1. **What is this system for, and what does it explicitly refuse to be?** (Sections 3–4)
2. **What must be true of this system at all times, and how do we know?** (Sections 5, 14)
3. **How is it actually built, at every level from "what talks to what" down to "what does this one function do"?** (Sections 7–10)
4. **Why is it built this way, and what did we deliberately choose not to do?** (Section 12, ADRs)

## 2.2 Audience

| Audience | Primary sections |
|---|---|
| New engineer onboarding | 3, 4, 7, 12 |
| Security reviewer / auditor | 5, 11, 15, 19 |
| Product/business stakeholder | 1, 3, 19 |
| Engineer planning an extension | 7.3, 12, 18, 21 |
| Incident responder | 11, 15, Appendix H (external) |
| Compliance/legal reviewer | 19, Appendix J (external) |

## 2.3 Conventions Used in This Document

- **MUST / SHOULD / MAY** are used per RFC 2119 conventions — a MUST is enforced in code today; a SHOULD is a strong recommendation not yet enforced; a MAY is a legitimate option left to implementer discretion.
- **ADR-NNN** references point to Section 12's decision log.
- **QA-NNN** references point to Section 14's quality attribute scenarios.
- **RISK-NNN** references point to Section 15's risk register.
- Diagrams are rendered in ASCII/text form to remain version-controllable alongside code, per this project's own documentation philosophy established across the tutorial series.

---

# 3. Business Context & Drivers

## 3.1 Problem Statement

Small and medium Singapore-based businesses need accounting software that (a) enforces real double-entry bookkeeping discipline rather than ad-hoc spreadsheet tracking, (b) natively understands Singapore-specific obligations — GST (9% standard rate), CPF contributions, ACRA/Corporate Income Tax filing prep — and (c) is affordable to run, ideally on free/low-cost infrastructure tiers for an early-stage business.

## 3.2 Business Drivers

| Driver | Architectural consequence |
|---|---|
| Multiple businesses (or one accountant serving several clients) need isolated books | Multi-tenancy via Clerk Organizations + `organizationId` scoping (ADR-003) |
| Small businesses cannot absorb software licensing costs early on | Entire stack chosen for genuinely functional free tiers (Vercel, Neon, Clerk, Inngest) |
| Singapore GST filing is quarterly and mandatory for registered businesses | GST-aware invoicing/billing (dual GST accounts) and a GST F5 summary report built directly into the ledger model, not bolted on |
| CPF is Singapore's payroll-equivalent statutory obligation | A CPF-aware payroll subsystem replaces a US-style payroll/withholding model entirely |
| Trust in financial software requires an audit trail, not silent edits | Immutable ledger + additive voiding (ADR-006) |
| Small teams need simple access control, not enterprise RBAC complexity | Two-tier role model (Admin/Member) via Clerk Organization roles, not a custom permissions engine |

## 3.3 Explicit Non-Goals

Stated directly, since an EADD without stated non-goals invites scope creep:

- This system is **not** a general-purpose ERP. It has no inventory management, no manufacturing/BOM tracking, no multi-warehouse logic.
- This system is **not** a payroll-tax-filing system of record. CPF calculations are illustrative; real filings require IRAS/CPF Board's authoritative current rate tables.
- This system is **not** a certified tax preparation product. GST F5 and Corporate Tax Estimate outputs are internal planning aids, explicitly disclaimed as such in the UI itself.
- This system does **not** currently commit to real-time bank-feed connectivity as a supported, hardened capability — Section 18 documents this as a stretch-goal extension point, not a shipped guarantee.

---

# 4. Architectural Goals, Constraints & Non-Goals

## 4.1 Primary Architectural Goals (Ranked)

1. **Ledger Integrity Above All Else.** No feature, however convenient, may create a path to an unbalanced or partially-written financial fact.
2. **Auditability.** Every financial record's full history (including corrections) must remain permanently inspectable.
3. **Tenant Isolation.** One organization's financial data must never be readable or writable by another, under any code path.
4. **Comprehensibility Over Cleverness.** Given this system's origin as a teaching artifact as much as a production one, architectural choices favor patterns a mid-level engineer can read and extend correctly, over marginally more "elegant" abstractions that raise the bar for safe modification.
5. **Operate on Free/Low-Cost Infrastructure.** Architecture must function correctly within Vercel/Neon/Clerk/Inngest free tiers for a small business's real transaction volume.

## 4.2 Constraints

| Constraint | Type | Source |
|---|---|---|
| Must run as a single Next.js application (no separate backend service) | Technical | Deployment simplicity goal (Goal 5) |
| Must use Postgres specifically (not a NoSQL store) | Technical | Double-entry integrity requires relational transactions and exact numeric types |
| Must use `numeric(14,2)`, never floating-point, for any monetary value | Technical | Goal 1 |
| Must never store a client-supplied `organizationId` as trusted input | Technical | Goal 3 |
| Authentication must not be built in-house | Technical/Risk | Session security is high-consequence, specialist-domain work (ADR-001) |
| GST rate logic must be per-line, not per-document | Business | Singapore invoices commonly mix standard and zero-rated items |

## 4.3 Assumptions

- Neon, Clerk, Vercel, and Inngest are trusted infrastructure providers; their internal security postures are out of scope for this document (see Appendix F for the boundary of what *is* modeled).
- Deployments target a single geographic region initially; no multi-region active-active requirement exists today.
- Transaction volume for the target customer segment (small SG businesses) is assumed to be low enough that the identified concurrency gaps (RISK-004) are tolerable at current scale, but must be revisited before onboarding a high-volume customer.

---

# 5. Quality Attribute Requirements (Non-Functional Requirements)

Expressed as measurable or verifiable statements, not vague adjectives, per architecture documentation best practice.

| ID | Attribute | Requirement | Verification Method | Status |
|---|---|---|---|---|
| NFR-01 | Correctness (Ledger) | 100% of posted journal entries have `SUM(debit) = SUM(credit)` | Automated: query in Appendix H.3; enforced structurally by `postJournalEntry` | ✅ Enforced (app-layer) |
| NFR-02 | Correctness (Reports) | Balance Sheet `Assets = Liabilities + Equity` for any `asOfDate`, to the cent | Live UI banner (Part 9); Test Plan RPT-02/03 | ✅ Enforced |
| NFR-03 | Tenant Isolation | No query may return rows from `organizationId` B while operating in org A's session context | Manual + Test Plan AUTH-06/07 | ⚠️ App-layer only, no DB-layer enforcement (RISK-001) |
| NFR-04 | Auditability | No posted `journal_entries` row may be altered or deleted after creation | Schema constraint (no UPDATE path exists for core fields; `onDelete: restrict` throughout) | ✅ Enforced |
| NFR-05 | Availability | Core invoicing/billing/payment flows must remain usable if Inngest is unreachable | Design: `inngest.send()` failures never block the underlying transaction (Part 11.3 ordering) | ✅ Enforced |
| NFR-06 | Atomicity | Any multi-write operation (invoice+journal, void+status update, payment+recompute) must be all-or-nothing | `dbTransactional.transaction()` wrapping; verified in Test Plan JRN-06, VOID-07 | ✅ Enforced |
| NFR-07 | Authorization | Voiding, payroll, tax adjustments, and reconciliation completion must be unreachable by non-admin roles, server-side | `requireAdminRole()` as first line of each action; Test Plan PERM-01 through PERM-06 | ✅ Enforced |
| NFR-08 | Cost Efficiency | System must operate within free tiers of Vercel/Neon/Clerk/Inngest for a small business's realistic transaction volume | Manual cost review at deployment (Part 13) | ✅ Verified at course-scale |
| NFR-09 | Currency Precision | No monetary calculation may exhibit floating-point rounding error | Integer-cents arithmetic in `postJournalEntry`, `createInvoice`, `createBill` | ✅ Enforced |
| NFR-10 | Concurrency Safety | Two simultaneous payment submissions against the same invoice must never jointly overpay it | Row-level locking or DB constraint | ❌ Not implemented (RISK-004) |
| NFR-11 | Secret Confidentiality | No credential may persist in Git history | Mandatory pre-push check (Part 13.1) | ✅ Process-enforced, not tooling-enforced |
| NFR-12 | Credential-at-Rest Protection | Third-party access tokens must be encrypted before storage | `bank_connections.accessToken` | ❌ Not implemented (RISK-002) |
| NFR-13 | Data Minimization | No personal data field should exist without a consuming feature | Manual review (Appendix J.5) | ⚠️ Partial — `customers.address`/`vendors.address` unused by any built feature |

---

# 6. Stakeholder Concerns

| Stakeholder | Primary Concern | Where Addressed |
|---|---|---|
| Business owner (end user) | "Can I trust the numbers?" | Section 5 (NFR-01/02), Section 11 |
| Bookkeeper (end user) | "Can I do my daily work without breaking anything?" | Section 4.1 Goal 4, User Guide (external doc) |
| Engineer extending the system | "Where do I safely add a new feature?" | Section 18, Section 21 |
| Security reviewer | "What's the actual attack surface?" | Section 11, Appendix F (external) |
| Compliance officer | "Does this meet PDPA/GST/CPF obligations?" | Section 19 |
| Infrastructure/ops | "What happens when a dependency goes down?" | Section 17, NFR-05 |
| Future maintainer (post-course) | "What technical debt am I inheriting?" | Section 15 |

---

# 7. Architectural Views (C4-Style)

## 7.1 Context View

```
                    ┌─────────────────────────┐
                    │   Business Owner /      │
                    │   Bookkeeper / Admin     │
                    └────────────┬─────────────┘
                                 │ HTTPS
                    ┌────────────▼─────────────┐
                    │                            │
                    │     GREYMATTER LEDGER      │
                    │  (this system, in scope)   │
                    │                            │
                    └───┬─────┬──────┬───────┬───┘
                        │     │      │       │
              ┌─────────▼┐ ┌──▼───┐ ┌▼─────┐ ┌▼──────────────┐
              │  Clerk    │ │ Neon │ │Inngest│ │ Bank Aggregator│
              │ (Identity)│ │ (DB) │ │ (Jobs)│ │ (stretch goal) │
              └───────────┘ └──────┘ └───────┘ └────────────────┘
                                                        │
                                          ┌─────────────▼──────────┐
                                          │  Real Bank (via API)     │
                                          │  (out of scope)          │
                                          └──────────────────────────┘
```

**System boundary statement:** Greymatter Ledger's in-scope boundary ends at the four external service integrations shown above. IRAS, ACRA, and CPF Board are *conceptual* targets the system's outputs are designed to be *useful preparation for*, but the system has zero live integration with any government system — every filing-adjacent report (GST F5, Tax Estimate) is explicitly disclaimed as an internal estimate, not a submission mechanism.

## 7.2 Container View

```
┌────────────────────────────────────────────────────────────────┐
│                    Next.js 16 Application                       │
│                    (single deployable unit)                     │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐│
│  │  Presentation      │  │  Application      │  │  Infrastructure ││
│  │  Layer             │  │  Logic Layer       │  │  Layer          ││
│  │                    │  │                    │  │                ││
│  │  app/**/page.tsx   │  │  lib/actions/*.ts  │  │  db/index.ts    ││
│  │  components/*.tsx  │  │  lib/journal.ts    │  │  drizzle.config ││
│  │  (Server + Client  │  │  lib/reports.ts    │  │  proxy.ts       ││
│  │   Components)      │  │  lib/permissions.ts│  │  app/api/inngest││
│  └──────────────────┘  │  lib/aging.ts       │  └────────────────┘│
│                          │  lib/gst.ts         │                    │
│                          │  lib/tax.ts         │                    │
│                          │  lib/reconciliation │                    │
│                          │  lib/inngest/*      │                    │
│                          └──────────────────────┘                    │
└────────────────────────────────────────────────────────────────┘
```

There is deliberately **one container**, not a distributed set of services. This is ADR-002 (Section 12) — a monolithic Next.js deployment was chosen over a split frontend/backend or microservices architecture, given the system's actual scale requirements and the goal of comprehensibility (Section 4.1, Goal 4).

## 7.3 Component View — The Application Logic Layer, Expanded

This is the most important view in this document, since it's where NFR-01 through NFR-07 are actually implemented.

```
                    ┌───────────────────────────────┐
                    │   lib/journal.ts               │
                    │                                 │
                    │   postJournalEntry(input, tx?)  │◄──── the ONE write path
                    │   voidJournalEntry(..., tx?)     │      for all financial facts
                    │                                 │
                    │   Guards (in order):            │
                    │   1. min 2 lines                │
                    │   2. no hybrid debit+credit line │
                    │   3. debits === credits (cents)  │
                    │   4. accounts belong to org       │
                    └───────────┬─────────────────────┘
                                │ called by, always passing `tx`
        ┌───────────┬───────────┼───────────┬───────────────┬──────────────┐
        │           │           │           │               │              │
┌───────▼──┐ ┌──────▼───┐ ┌─────▼────┐ ┌────▼─────┐ ┌───────▼──────┐ ┌────▼──────┐
│ invoices  │ │  bills    │ │ payments  │ │ bank-    │ │  payroll      │ │ voiding    │
│  .ts      │ │  .ts      │ │  .ts      │ │ import.ts│ │  .ts (14.5)   │ │ (14.2, via │
│           │ │           │ │           │ │ (Part 12)│ │               │ │  same fn)  │
└───────────┘ └───────────┘ └───────────┘ └──────────┘ └───────────────┘ └────────────┘
        │           │           │           │               │              │
        └───────────┴───────────┴───────────┴───────────────┴──────────────┘
                                        │
                          ┌─────────────▼──────────────┐
                          │  lib/permissions.ts          │
                          │  requireAdminRole()          │◄── gates voiding, payroll,
                          │  isCurrentUserAdmin()         │    tax adjustments, recon
                          └───────────────────────────────┘
                                        │
                          ┌─────────────▼──────────────┐
                          │  Reporting Layer (read-only)  │
                          │  lib/reports.ts               │
                          │  lib/aging.ts                 │
                          │  lib/gst.ts                   │
                          │  lib/tax.ts                   │
                          └────────────────────────────────┘
```

**Component responsibility table:**

| Component | Responsibility | May write to `journal_entries`? |
|---|---|---|
| `lib/journal.ts` | The engine itself — validation + atomic write | Yes — the only one |
| `lib/actions/invoices.ts` | Compute invoice totals, call the engine | Indirectly, via the engine |
| `lib/actions/bills.ts` | Compute multi-account bill totals, call the engine | Indirectly |
| `lib/actions/payments.ts` | Compute payment reversal amounts, recompute parent status | Indirectly (both post and void paths) |
| `lib/actions/bank-import.ts` | Stage, categorize, then post bank transactions | Indirectly, on posting only |
| `lib/actions/payroll.ts` | Compute CPF splits, call the engine | Indirectly |
| `lib/actions/reconciliation.ts` | Never writes journal entries — reads and cross-checks only | No — read-only consumer |
| `lib/reports.ts`, `lib/aging.ts`, `lib/gst.ts`, `lib/tax.ts` | Pure aggregation over existing ledger data | No — read-only |
| `lib/permissions.ts` | Authorization gate, called by mutating actions | No — orthogonal concern |

## 7.4 Code/Class View — `postJournalEntry` Internals

Since this function is the system's single most important artifact, its internal control flow is documented at the finest grain:

```
postJournalEntry(input, executor = dbTransactional):
  │
  ├─ GUARD 1: input.lines.length >= 2
  │     └─ throw if violated, before any DB access
  │
  ├─ GUARD 2: for each line, exactly one of {debit, credit} > 0
  │     └─ throw if violated
  │
  ├─ GUARD 3: sum(debit * 100) === sum(credit * 100)  [integer cents]
  │     └─ throw if violated — THE core invariant
  │
  ├─ GUARD 4: query accounts WHERE id IN (line accountIds)
  │            AND organizationId = input.organizationId
  │     └─ throw if count mismatch (an account doesn't belong here)
  │
  ├─ decide: executor === dbTransactional (top-level call)?
  │     ├─ YES → open new transaction, run doInsert(tx) inside it
  │     └─ NO  → executor is already a `tx` from a caller;
  │              run doInsert(executor) directly, joining
  │              the CALLER's transaction (composability, ADR-005)
  │
  └─ doInsert(tx):
        ├─ INSERT journal_entries (one row) → returns entry
        ├─ INSERT journal_lines (N rows, referencing entry.id)
        └─ return { entry, lines }
```

**Design property worth naming explicitly:** guards 1–4 execute identically regardless of whether this is a top-level or nested call. The composability decision (executor parameter) only affects *where the write lands*, never *what gets validated*. This separation — validation logic is transaction-topology-agnostic — is what makes the function safe to reuse across every calling context in Section 7.3's component diagram without duplicating a single guard clause.

---

# 8. Data Architecture

## 8.1 Conceptual Data Model

At the conceptual level, the schema reduces to three concerns:

1. **Who** — `organizations`, `customers`, `vendors`, `employees` (identity/parties)
2. **What buckets exist** — `accounts` (the Chart of Accounts, self-referencing for hierarchy)
3. **What happened** — `journal_entries`/`journal_lines` (the ledger), with every other table (`invoices`, `bills`, `payments`, `pay_runs`, `imported_transactions`) existing purely to *produce* or *stage* a row in category 3

## 8.2 Logical Data Model — Full Table Inventory

Twenty tables total. Full column-level detail is maintained in **Appendix A** (external document) as the single source of truth; this section summarizes structural categorization only, to avoid document drift between two competing "authoritative" schema references.

| Category | Tables | Notes |
|---|---|---|
| Tenancy root | `organizations` | Every other table's isolation anchor |
| Chart of Accounts | `accounts` | Self-referencing (`parentId`) for hierarchy |
| Parties | `customers`, `vendors`, `employees` | Soft-delete only (`isActive`) |
| The Ledger | `journal_entries`, `journal_lines` | Immutable once posted; `isVoided`/`reversalOfEntryId` support additive correction |
| AR documents | `invoices`, `invoice_lines` | Denormalized totals for read performance |
| AP documents | `bills`, `bill_lines` | Mirror of AR, with per-line expense account targeting |
| Cash movement | `payments` | Single table, exactly one of `invoiceId`/`billId` set |
| Automation staging | `recurring_invoice_templates`, `imported_transactions` | Produce real documents/postings on a schedule or after human review |
| Reconciliation | `reconciliations`, `reconciliation_items` | Cross-checks ledger against external bank statement truth |
| Payroll | `pay_runs` | Produces a 4-line CPF-aware journal entry per cycle |
| Tax planning | `tax_adjustments` | Deliberately outside the ledger — never posted |
| External integration | `bank_connections` | Stretch-goal scaffolding; holds a sensitive credential (RISK-002) |

## 8.3 Data Integrity Enforcement Matrix

| Integrity rule | Enforced at | Enforcement mechanism |
|---|---|---|
| Debits = Credits per entry | Application | `postJournalEntry` Guard 3 |
| Account belongs to organization | Application | `postJournalEntry` Guard 4 |
| Historical rows never orphaned | Database | `onDelete: "restrict"` FKs |
| Line items deleted with parent document | Database | `onDelete: "cascade"` FKs |
| No cross-org data leakage | Application (convention) | `and(eq(id,...), eq(organizationId,...))` pattern — **not DB-enforced (RISK-001)** |
| No duplicate bank transaction | Application | SHA-256 content hash (`date|description|amount`) |
| Monetary precision | Database (type) + Application (arithmetic) | `numeric(14,2)` columns + integer-cents math before writing |

## 8.4 Data Lifecycle

Every table in this system follows one of two lifecycle patterns:

**Pattern A — Soft Delete (never truly removed):** `accounts`, `customers`, `vendors`, `employees` use an `isActive` boolean. A "deleted" record is filtered out of active-use dropdowns but remains permanently queryable and remains valid for historical foreign key references.

**Pattern B — Immutable + Additive Correction:** `journal_entries`, `payments` use `isVoided`/`voidedAt`. A "corrected" record is never altered — a new, offsetting record is created, and both remain permanently visible.

**No table in this schema uses Pattern C (hard delete)** for anything that has ever represented a real financial or business fact. This is a structural property, not a convention followers might forget — verified by the `onDelete: "restrict"` constraints in Section 8.3.

---

# 9. Runtime / Process Views

## 9.1 Sequence: Invoice Creation → Journal Posting (Detailed)

```
User (Browser)     InvoiceForm       createInvoice()      postJournalEntry()    Postgres      Inngest
     │                  │                    │                     │                │             │
     │──submit form────►│                    │                     │                │             │
     │                  │──call action──────►│                     │                │             │
     │                  │                    │──getOrCreateOrg────►│... (session)   │             │
     │                  │                    │◄───organizationId───│                │             │
     │                  │                    │──recompute totals   │                │             │
     │                  │                    │  (integer cents,    │                │             │
     │                  │                    │   never trust       │                │             │
     │                  │                    │   client preview)   │                │             │
     │                  │                    │──BEGIN TRANSACTION─────────────────►│             │
     │                  │                    │──INSERT invoices──────────────────►│             │
     │                  │                    │──INSERT invoice_lines──────────────►│             │
     │                  │                    │──call postJournalEntry(input, tx)──►│             │
     │                  │                    │                     │──Guard 1-4    │             │
     │                  │                    │                     │──INSERT je────►│            │
     │                  │                    │                     │──INSERT jl────►│            │
     │                  │                    │◄────{entry, lines}──│                │             │
     │                  │                    │──UPDATE invoices.journalEntryId────►│             │
     │                  │                    │──COMMIT TRANSACTION─────────────────►│             │
     │                  │                    │──inngest.send("invoice/created")──────────────────►│
     │                  │                    │──revalidatePath()   │                │             │
     │                  │◄──redirect─────────│                     │                │             │
     │◄──new page───────│                    │                     │                │             │
```

**Critical ordering property, called out explicitly:** the Inngest event fires *strictly after* `COMMIT`. This is not an implementation detail — it is a designed guarantee (NFR-05's underlying mechanism) that no background side effect (a confirmation email) can ever reference a financial fact that didn't actually get durably persisted.

## 9.2 Sequence: Voiding an Invoice With an Existing Payment (Multi-Step Correction Flow)

```
Admin User         voidPayment()         voidJournalEntry()      voidInvoice()
     │                    │                       │                     │
     │──void payment─────►│                       │                     │
     │                    │──requireAdminRole()───│                     │
     │                    │──BEGIN TX─────────────│                     │
     │                    │──call voidJournalEntry(paymentJE, tx)──────►│
     │                    │                       │──build mirror lines│
     │                    │                       │──postJournalEntry──│(reversal)
     │                    │                       │──mark original     │
     │                    │                       │  isVoided=true     │
     │                    │◄──{reversalEntryId}───│                     │
     │                    │──mark payment voided──│                     │
     │                    │──recompute invoice    │                     │
     │                    │  amountPaid/status    │                     │
     │                    │  FROM SCRATCH          │                     │
     │                    │──COMMIT TX────────────│                     │
     │◄──success──────────│                       │                     │
     │                                                                   │
     │──void invoice (now that amountPaid = 0)───────────────────────────►│
     │                                             │requireAdminRole()   │
     │                                             │BEGIN TX             │
     │                                             │call voidJournalEntry│(invoice JE)
     │                                             │mark invoice status  │
     │                                             │= "void"             │
     │                                             │COMMIT TX            │
     │◄────────────────────────────────────────────success──────────────│
```

**Note on "recompute FROM SCRATCH":** this is a deliberate architectural choice (ADR-007) — rather than naively decrementing `amountPaid` by the voided payment's amount, the system recomputes the invoice's paid total and status independently after the void. This correctly handles edge cases (e.g., voiding the *only* payment should return status all the way to "sent," not leave it in an inconsistent intermediate state) that a naive decrement would get wrong.

---

# 10. Deployment View

## 10.1 Physical Deployment Topology

```
┌─────────────────────────────────────────────────────────────┐
│                         VERCEL                                │
│   ┌──────────────────────────────────────────────────────┐   │
│   │  Serverless Function Instances (N, auto-scaled)        │   │
│   │  Each instance: full Next.js app, stateless             │   │
│   └────────┬─────────────────────────────────────┬──────────┘   │
└────────────┼─────────────────────────────────────┼──────────────┘
             │ HTTP (neon-http)                     │ WebSocket
             │ simple reads/writes                  │ (neon-serverless,
             │                                       │  for db.transaction())
┌────────────▼───────────────────────────────────────▼──────────────┐
│                          NEON (Postgres)                            │
│           Pooled connection endpoint (used by BOTH clients          │
│           in production, per ADR-004 and ADR-008)                   │
└──────────────────────────────────────────────────────────────────┘
```

**Critical topology note (ADR-008):** in production, **both** `DATABASE_URL` and any transaction-capable connection must resolve through Neon's **pooled** endpoint (hostname containing `-pooler`). The unpooled/direct connection string is reserved exclusively for the one-off, non-concurrent migration process (`drizzle-kit migrate`), executed outside the request path entirely. Using the unpooled string for the live application would exhaust Postgres's connection limit under any real concurrent load — this was a load-bearing decision made in Part 3/13 of the system's build history and is re-stated here because it is easy to get backwards.

## 10.2 Environment Topology

| Environment | Database | Clerk instance | Inngest | Purpose |
|---|---|---|---|---|
| Local development | Same Neon project (typical) or a separate dev project | Development instance | Local CLI dev server (`inngest-cli dev`) | Iteration, testing new features |
| Production (Vercel) | Neon project, pooled connection | Production instance | Real Inngest cloud, synced via `/api/inngest` | Live customer use |

**Environment parity gap, stated directly:** this system, as built, does not maintain a genuinely separate "Preview" environment with its own isolated database branch — Vercel's Preview deployments (auto-created per Git branch/PR) currently share the same environment variable values as Production for simplicity (Section 10.2 does not list a distinct Preview row for exactly this reason). This is documented as **RISK-006** in Section 15 — a Preview deployment testing a risky schema migration or a destructive server action currently has the ability to affect real production data, since there is no database branching or credential separation between the two. Neon's branching feature is the natural remediation and is not yet adopted.

## 10.3 Configuration Management

All environment-specific values are managed as environment variables, never hardcoded. The canonical, fully-annotated inventory (ten variables across Clerk, Neon, and Inngest) lives in **Appendix B** (external document) and is not duplicated here to avoid two sources of truth drifting apart — this section instead documents the *policy* governing them:

- **Policy 1:** No environment variable value may ever appear as a fallback/default literal inside application code (Appendix G.5).
- **Policy 2:** `.env.local` is excluded from version control from the project's very first commit; `git log --all --full-history` against it must return empty before any push (Appendix H.2 governs the remediation path if this policy is ever violated).
- **Policy 3:** The pooled vs. unpooled Neon connection string distinction (Section 10.1) must be respected in every environment — a misconfiguration here is silent until real concurrent load exposes it.

## 10.4 Deployment Pipeline

```
Developer → git push → GitHub (main branch)
                            │
                            ▼
                     Vercel webhook trigger
                            │
                            ▼
                  Automatic build + deploy
                     (continuous deployment,
                      no manual approval gate)
                            │
                            ▼
                     Live production URL
```

**Note on the absence of a deployment gate:** this pipeline has no manual approval, staging soak period, or automated pre-deploy test suite gating the `main → production` transition. This is an accepted tradeoff for the system's current scale and audience (documented as **RISK-007**) — a small business's Greymatter Ledger deployment prioritizes fast iteration by a single maintainer over the process overhead a larger team/regulated environment would require. Section 18 identifies adding a CI-run subset of the Test Plan's Regression Suite (Section 16 of the Test Plan document) as a gating check as a natural next step before this system serves a larger or more regulated customer base.

---

# 11. Security Architecture

This section summarizes the security posture; the full threat model, secure coding checklist, incident runbook, dependency analysis, privacy notes, and authentication deep-dive are maintained as dedicated external appendices (F through K) to keep this document's length manageable while preserving depth where it belongs.

## 11.1 Trust Boundary Summary

| Boundary | Enforcement mechanism | Residual risk |
|---|---|---|
| Anonymous → Authenticated | Clerk-issued, cryptographically signed JWT, verified by `proxy.ts` on every matched request | Low — delegated to specialist infrastructure (ADR-001) |
| Authenticated → Tenant-scoped | Application-level `organizationId` filtering, derived server-side only | **Medium — no DB-level backstop (RISK-001)** |
| Member → Admin-only actions | `requireAdminRole()`, checked first-line in every sensitive action | Low — server-side, unspoofable via client tampering |
| Application → Database | Neon connection string (pooled), TLS-encrypted (`sslmode=require`) | Low, assuming credential confidentiality (see NFR-11) |
| Application → Inngest | Signed request verification (`INNGEST_SIGNING_KEY`) | Low, contingent on signing key confidentiality |
| Application → Bank Aggregator | Bearer token (`bank_connections.accessToken`) | **High — plaintext storage (RISK-002)** |

## 11.2 Security Architecture Principles

1. **Delegate identity, never build it.** (ADR-001)
2. **Authorization checks execute server-side, first, before any read.** No exceptions across any of the seven admin-gated actions in this system.
3. **Client input is never trusted for identity or totals.** Every dollar amount and every `organizationId` is either recomputed or re-derived server-side on every write.
4. **Corrections are additive, never destructive.** Applies uniformly to financial and (partially) to non-financial data.
5. **Secrets are excluded from version control by policy and by tooling** (`.gitignore` + mandatory pre-push verification), though not by an automated pre-commit hook (a gap — see Section 15).

## 11.3 Known Security Debt (Cross-Referenced to Risk Register)

See Section 15 for full detail. Summarized here for at-a-glance review: RISK-001 (no RLS), RISK-002 (plaintext bank token), RISK-003 (no DB-level balance constraint), RISK-004 (payment race condition), RISK-005 (no schema-level input validation layer).

---

# 12. Architecture Decision Records (ADRs)

Each ADR follows: Context → Decision → Alternatives Considered → Consequences.

### ADR-001: Delegate Authentication to Clerk

**Context:** The system requires sign-up, sign-in, session management, and organization/multi-tenancy primitives.
**Decision:** Use Clerk as a fully managed identity provider rather than building session handling in-house.
**Alternatives Considered:** Roll a custom auth system with `bcrypt` + JWT; use NextAuth/Auth.js with a self-managed session store.
**Consequences:** (+) Eliminates an entire class of high-consequence security bugs (session fixation, password storage mistakes, token replay). (+) Organization/role primitives (used throughout Section 7.3 and Section 11) come free. (−) Introduces a hard external dependency; a Clerk outage is a full application outage (NFR-05 partially mitigates this for background jobs only, not for auth itself — this is an accepted, undocumented-elsewhere gap worth flagging: **RISK-008**, no auth-layer graceful degradation exists).

### ADR-002: Monolithic Next.js Deployment (No Microservices)

**Context:** Choice between a single Next.js application (Server Actions + Server Components) versus a split frontend/backend or service-oriented architecture.
**Decision:** Single deployable Next.js application.
**Alternatives Considered:** Separate Express/Fastify API + a decoupled SPA frontend; a services-per-domain microservice split (invoicing service, ledger service, reporting service).
**Consequences:** (+) Matches Goal 4 (comprehensibility). (+) Eliminates inter-service network calls and their associated failure modes for the core write path (Section 9.1's sequence has zero network hops between "compute totals" and "write the ledger"). (−) All logic scales as one unit; a hypothetical future need to scale the reporting workload independently of the write workload would require a genuine re-architecture, not a configuration change.

### ADR-003: Application-Level Multi-Tenancy (No Postgres RLS)

**Context:** Every table must be strictly isolated per organization.
**Decision:** Enforce isolation via a consistent `organizationId` filtering pattern in application code, checked via a peer-reviewable checklist (Appendix G.2), rather than Postgres Row-Level Security policies.
**Alternatives Considered:** Postgres RLS with session-variable-based policies; separate database-per-tenant.
**Consequences:** (+) Simpler mental model, faster to implement correctly for a small engineering team. (+) No per-tenant infrastructure overhead. (−) A single missed filter in a new query is a real, structurally-unguarded data leak (RISK-001) — this is the most significant open architectural risk in the entire system and is flagged as such repeatedly across this document intentionally, not by accident.

### ADR-004: Two Database Clients — HTTP for Reads, WebSocket for Transactions

**Context:** Serverless deployment (Vercel) plus a genuine need for multi-statement atomic transactions.
**Decision:** Maintain `db` (`drizzle-orm/neon-http`) for simple queries and `dbTransactional` (`drizzle-orm/neon-serverless`) exclusively for `.transaction()` calls.
**Alternatives Considered:** Use only the WebSocket client everywhere (simpler mental model, worse latency/connection overhead for the majority-case simple reads); use only the HTTP client and simulate atomicity with manual compensating writes (rejected — genuinely unsafe, reintroduces the exact partial-write risk transactions exist to prevent).
**Consequences:** (+) Correct performance/safety tradeoff for each access pattern. (−) Two clients sharing one schema is a slightly unusual pattern a new engineer must learn (documented here specifically to shorten that ramp-up).

### ADR-005: Composable Transactions via Optional Executor Parameter

**Context:** Multiple features (invoice creation, voiding, payroll) need to combine a journal posting with additional writes as one atomic unit.
**Decision:** `postJournalEntry` and `voidJournalEntry` accept an optional `executor` parameter; when supplied, the function joins the caller's existing transaction instead of opening its own.
**Alternatives Considered:** Duplicate the engine's validation logic inline in every calling feature (rejected — violates DRY and reintroduces exactly the kind of scattered logic the engine was built to centralize); always require the caller to pass a transaction, with no standalone-call convenience (rejected — breaks the engine's usability for simple, one-off manual postings and for testing).
**Consequences:** (+) Every feature composes correctly with zero duplicated guard logic. (−) Requires disciplined understanding by any engineer adding a new feature — the composability is opt-in via a parameter, not automatic; forgetting to pass `tx` re-introduces the exact non-atomicity bug found and fixed during this system's own development history (see the process note in Section 12's closing remark below).

### ADR-006: Immutable Ledger with Additive Voiding

**Context:** Financial records must never be silently editable, yet users need a way to correct genuine mistakes.
**Decision:** No UPDATE or DELETE path exists for core journal entry fields once posted. Corrections are new, offsetting entries (`voidJournalEntry`), with the original flagged `isVoided`, never altered.
**Alternatives Considered:** Allow direct editing of posted entries with an audit-log side table recording the change (rejected — creates two competing sources of truth, the "current" edited value and the audit trail, versus this system's single-source-of-truth ledger); allow hard deletion with a separate "reason for deletion" log (rejected — destroys the actual before/after numbers, making later reconciliation and audit meaningfully harder).
**Consequences:** (+) A complete, tamper-evident history always exists. (+) Reports built on `journal_entries` never need special-case logic for "was this edited" — they simply exclude `isVoided = true` rows and include reversal rows, which are structurally identical to any other entry. (−) The ledger grows monotonically; no space-reclamation/archival strategy exists yet for a very long-lived, high-volume tenant (a capacity concern noted in Section 16, not yet a real-world-observed problem at this system's current scale).

### ADR-007: Recompute-From-Scratch for Payment Voiding State

**Context:** Voiding a payment must correctly update the parent invoice/bill's `amountPaid` and `status`.
**Decision:** Recompute the parent's paid total and derived status fresh from remaining active payments, rather than naively decrementing the previous stored value.
**Alternatives Considered:** Simple decrement (`amountPaid -= voidedPayment.amount`) — rejected because it produces correct arithmetic but requires separately re-deriving status with identical care anyway, and is more fragile to a future bug where the decrement and the status logic drift out of sync with each other over time.
**Consequences:** (+) Correctly handles the edge case of voiding the *only* payment on a document, returning status cleanly to its pre-payment state rather than leaving it in an inconsistent intermediate value. (−) Marginally more database work per void (a fresh lookup rather than an in-place decrement) — judged an acceptable tradeoff given voiding is an infrequent, admin-gated action, not a hot path.

### ADR-008: Pooled Connection String Mandatory in Production

**Context:** Vercel's serverless execution model can spin up many concurrent function instances, each potentially opening its own database connection.
**Decision:** `DATABASE_URL` in every deployed environment must resolve through Neon's pooled endpoint; the unpooled/direct connection is reserved exclusively for the migration tool, run outside the request path.
**Alternatives Considered:** Use the unpooled connection everywhere for simplicity (rejected — verified to exhaust Postgres's connection limit under realistic concurrent serverless load, a failure mode that is silent at low traffic and only manifests once real usage grows); provision a dedicated always-on connection-pooling proxy (e.g., PgBouncer) independently of Neon's built-in pooling (rejected as unnecessary — Neon's native pooler already solves this problem at the exact layer needed, without additional infrastructure to operate).
**Consequences:** (+) Correct behavior under concurrent serverless load without additional operational overhead. (−) Requires every engineer configuring a new environment to correctly distinguish the two connection string variants — an easy detail to get backwards, which is precisely why this ADR exists as a standing reference.

**Process note on this ADR log's own provenance:** ADR-005's stated consequence — "forgetting to pass `tx` re-introduces the exact non-atomicity bug" — is not a hypothetical. During this system's own development, `voidInvoice` was originally implemented calling `voidJournalEntry` and a separate `invoices` status update as two sequential, un-transactioned writes, exactly the failure mode ADR-005 warns against. It was caught, root-caused, and corrected by extending `voidJournalEntry` to accept the same executor pattern already used by `postJournalEntry`. This ADR log intentionally retains that history rather than presenting the corrected design as though it were arrived at cleanly the first time — an accurate decision log is more useful to a future maintainer than a tidied one.

---

# 13. Cross-Cutting Concerns

## 13.1 Error Handling Convention

Every thrown error across every server action includes a specific, human-readable reason (e.g., "Cannot void an invoice that still has payments recorded against it. Void each payment individually first, then void the invoice.") rather than a bare generic message. This is a deliberate convention, not an accident of individual authorship — it exists because financial software's error messages are frequently the *only* signal an operator has when something didn't go as expected, and a vague error forces a support/debugging cycle that a specific one avoids entirely.

## 13.2 Logging & Traceability

Every financial write carries forward a `sourceType`/`sourceId` pair on its `journal_entries` row, pointing back to the originating document (an invoice, a bill, a payment, a pay run, a bank import row, or a void reversal). This is the system's de facto traceability mechanism — there is no separate, centralized audit-log table; the ledger's own `sourceType`/`sourceId` columns serve this purpose by design, avoiding a second source of truth that could drift from the first.

## 13.3 Idempotency

Scheduled jobs (recurring invoice generation, overdue reminders) are designed to be idempotent by construction: the recurring invoice job advances `nextRunDate` *before* it could plausibly be triggered again for the same cycle, and re-evaluates "is this due?" fresh on every invocation rather than relying on any external at-most-once delivery guarantee from the job scheduler. This is a deliberate defensive choice, since cron-based systems occasionally fire more than once around a trigger boundary due to infrastructure retries.

## 13.4 Internationalization / Localization

Out of scope as a general capability. The system has one hardcoded locale assumption baked into its business logic: Singapore GST (9%) and CPF contribution mechanics. Multi-currency support (Section 18) addresses *transaction* currency flexibility, not UI localization — all interface text remains English-only, and no locale-aware number/date formatting layer exists.

---

# 14. Quality Attribute Scenarios & Tactics

Expressed in the standard stimulus/response format for architecturally significant requirements.

### QA-001: Ledger Integrity Under Malformed Input

**Stimulus:** A server action attempts to post a journal entry where total debits ($500.00) do not equal total credits ($499.99), due to a rounding bug elsewhere in the calling code.
**Environment:** Normal operation, any tenant.
**Response:** `postJournalEntry`'s Guard 3 detects the mismatch (using integer-cents comparison, immune to floating-point representation error) and throws before any database write occurs.
**Response Measure:** Zero rows written to `journal_entries` or `journal_lines`; the calling transaction rolls back entirely if nested.
**Tactic Used:** Guard clause validation before resource commitment; integer arithmetic instead of floating point.

### QA-002: Tenant Isolation Under a Guessed Resource ID

**Stimulus:** An authenticated user of Organization A manually navigates to `/invoices/<Organization-B-invoice-id>`.
**Response:** The compound `and(eq(id,...), eq(organizationId,...))` query pattern returns no matching row; the page renders a 404.
**Response Measure:** No data from Organization B is ever included in the HTTP response, not even an error message confirming the ID's existence.
**Tactic Used:** Consistent query-scoping convention (application-level access control); explicit checklist enforcement (Appendix G.2) at code-review time.
**Tactic Gap:** No architectural tactic exists at the *database* layer as a second line of defense (RISK-001) — this scenario's guarantee depends entirely on every such query being written correctly, with no structural backstop if one is not.

### QA-003: Atomicity Under Mid-Transaction Failure

**Stimulus:** During a `voidInvoice` operation, the database connection drops immediately after the reversal journal entry is written but before the invoice's `status` field is updated.
**Response:** The enclosing `dbTransactional.transaction()` block automatically rolls back the entire operation.
**Response Measure:** Neither the reversal entry nor the `isVoided` flag nor the status update persists — verified directly in Test Plan VOID-07.
**Tactic Used:** ACID transaction boundary aligned exactly with the unit of business-logic atomicity required (ADR-005's executor pattern makes this alignment possible across function boundaries).

### QA-004: Authorization Bypass Attempt

**Stimulus:** A Member-role user crafts a direct request to the `voidInvoice` server action, bypassing the UI's hidden void button entirely.
**Response:** `requireAdminRole()`, executed as the function's first line, reads the user's `orgRole` from the server-side-verified session and throws before any database access occurs.
**Response Measure:** Zero database reads or writes occur; the thrown error is specific ("Only an organization admin can void an invoice...").
**Tactic Used:** Authorization enforcement at the resource/action layer, independent of and never substituted by UI-layer control hiding (explicitly documented as a non-substitutable distinction in Appendix G.4).

### QA-005: Concurrent Payment Submission (Negative Scenario — Currently Unmet)

**Stimulus:** Two browser tabs, both showing a $790 remaining balance on the same invoice, each submit an $800 payment within milliseconds of each other.
**Expected Response (target, not current):** The second submission should be rejected once the first commits, since it would overpay the invoice.
**Actual Current Response:** Both submissions may read the same stale $790 remaining balance before either write completes, and — depending on timing — both could pass the overpayment guard, jointly overpaying the invoice.
**Status:** **Unmet — RISK-004.** This scenario is included specifically because a quality attribute scenario documenting a *known gap* is more valuable to a future maintainer than silence on the topic.
**Remediation Path:** Row-level locking (`SELECT ... FOR UPDATE`) on the invoice row inside the payment transaction, or a database-level `CHECK (amountPaid <= total)` constraint as a backstop.

---

# 15. Risk Register & Technical Debt Ledger

| ID | Risk | Likelihood | Impact | Current Mitigation | Residual Exposure | Remediation |
|---|---|---|---|---|---|---|
| RISK-001 | Cross-tenant data leak via a missed `organizationId` filter in a future query | Medium (grows with codebase size/team size) | Critical | Code-review checklist (Appendix G.2) | High | Implement Postgres Row-Level Security as a structural backstop |
| RISK-002 | Bank aggregator access token compromise via database access | Low (requires DB credential compromise first) | Critical | None — stored as plaintext | High | Application-layer encryption (e.g., AES-256-GCM, key held outside the database) |
| RISK-003 | Unbalanced ledger entry via direct SQL access bypassing `postJournalEntry` | Low (requires direct DB credential access) | Critical | None at DB layer; application guards only | Medium | Database `CHECK` constraint or trigger enforcing `SUM(debit)=SUM(credit)` per entry |
| RISK-004 | Payment race condition causing invoice overpayment | Low (requires near-simultaneous submission) | Medium | Application-level guard using a pre-transaction balance read | Medium | Row-level locking or DB-level `CHECK` constraint |
| RISK-005 | Malformed input (negative quantity, extreme GST rate) accepted due to inconsistent validation | Medium | Medium | Ad hoc per-action checks, not uniform | Medium | Adopt a shared schema-validation layer (e.g., Zod) across every server action |
| RISK-006 | Preview deployments share production-equivalent credentials/database | Medium | High | None | High | Adopt Neon database branching per Preview deployment |
| RISK-007 | No automated test gate before production deployment | Medium | Medium | Manual regression testing (Test Plan Section 16) | Medium | CI pipeline running the Regression Suite before merge to `main` |
| RISK-008 | No graceful degradation if Clerk is unreachable | Low | High | None — full dependency | High | Out of scope at current maturity level; would require a fundamentally different auth architecture to mitigate meaningfully |
| RISK-009 | `imported_transactions` has no `void` status, leaving it stale relative to a directly-reversed ledger entry | Low | Low | Documented gap only | Low | Add a `void` enum value and a `voidImportedTransaction()` action mirroring existing void functions |
| RISK-010 | No FX gain/loss recognition on multi-currency settlement | Medium (for businesses actually invoicing in foreign currency) | Medium | None — payments must be entered pre-converted | Medium | Dedicated FX Gain/Loss P&L account and settlement-date rate comparison logic |

**Risk Register Governance Note:** this register should be reviewed and re-scored at each major release, not treated as a static, one-time artifact. Likelihood/impact scoring above reflects the system's assessed maturity at time of writing and will shift as real usage patterns emerge.

---

# 16. Capacity, Scaling & Performance Model

## 16.1 Assumed Load Profile

This system has not undergone formal load testing. The following is a *design assumption*, not a measured benchmark:

- Target tenant profile: a single small-to-medium business, tens to low hundreds of invoices/bills per month, a handful of concurrent users at any given time (owner, one or two bookkeepers).
- Bank CSV imports: batches of tens to low hundreds of rows per upload, infrequent (weekly/monthly), not a high-frequency streaming workload.
- Reporting queries (P&L, Balance Sheet, Aging, GST F5, Tax Estimate) are read-heavy aggregations over a Chart of Accounts of roughly 15–20 accounts and a ledger that, even at several years of activity for a small business, remains in the low tens of thousands of `journal_lines` rows — well within the range Postgres handles efficiently with straightforward indexing.

## 16.2 Scaling Dimensions

| Dimension | Current approach | Scaling ceiling (assessed, not measured) |
|---|---|---|
| Concurrent users per tenant | Serverless auto-scaling (Vercel), pooled DB connections (ADR-008) | Effectively unbounded for the target profile; genuine concern only emerges at hundreds of concurrent writers per tenant, which is well outside the intended customer segment |
| Number of tenants | Single shared Postgres database, `organizationId`-scoped | Bounded eventually by single-database storage/IOPS limits; no sharding or per-tenant database strategy exists. Acceptable for the platform's current scale; would need revisiting for a multi-thousand-tenant SaaS ambition |
| Ledger size per tenant | Unbounded growth, no archival strategy (ADR-006's consequence) | No immediate concern at assumed load profile (Section 16.1); a genuinely old, high-volume tenant (many years, high transaction frequency) would eventually warrant a partitioning or archival strategy for `journal_lines`, not yet needed |
| Reporting query cost | Full-table aggregation via `getAccountBalancesAsOf`/`getAccountBalancesForRange`, no materialized views or caching | Acceptable at assumed scale; a future high-volume tenant might need either database indexes explicitly tuned for `(organizationId, entryDate)` range scans, or a periodic materialized summary table, neither of which is currently implemented |

## 16.3 Known Performance Gaps

- **No caching layer** exists anywhere in the system — every report recomputes its aggregation on every page load. Acceptable at assumed scale (Section 16.1); would be the first thing to address if reporting latency became a measured, real complaint.
- **No database query performance monitoring** is configured beyond Neon's own dashboard-level metrics — no application-level slow-query logging or APM instrumentation exists.
- **No explicit indexes beyond primary keys and foreign keys** are documented as having been deliberately added for query performance (e.g., a composite index on `journal_lines(accountId, journalEntryId)` to accelerate the account-balance aggregation queries) — Drizzle/Postgres defaults are relied upon as sufficient at current scale, unverified by an actual query plan review (`EXPLAIN ANALYZE`).

---

# 17. Observability & Operations

## 17.1 Current Observability Posture

| Signal | Current mechanism | Gap |
|---|---|---|
| Application errors | Vercel Runtime Logs (Appendix H's incident runbook references this directly) | No structured error aggregation service (e.g., Sentry) configured |
| Background job execution | Inngest's own dashboard (event history, function run logs, per-step execution detail) | Sufficient for this workload; no additional instrumentation layered on top |
| Database health | Neon's own dashboard (connection counts, query monitoring) | No custom alerting configured on top of Neon's native tooling |
| Ledger integrity (business-level health) | Manual SQL query (Appendix H.3) to detect any unbalanced entry | **Not automated** — this is a reactive, manual check performed only when a problem is already suspected, not a proactive, scheduled health check |

## 17.2 Recommended Operational Improvements (Not Yet Implemented)

1. **A scheduled Inngest function that runs Appendix H.3's unbalanced-entry detection query proactively** (e.g., nightly), alerting if any row is ever found — converting a reactive incident-response step into a proactive health check. This is a genuinely low-effort, high-value addition given the Inngest infrastructure already exists in the system.
2. **Structured logging** for every server action's entry/exit, correlated by a request ID, to make Vercel Runtime Log review during an incident (Appendix H) faster than grep-searching unstructured console output.
3. **A status/health-check endpoint** confirming database connectivity and Clerk/Inngest reachability, useful both for uptime monitoring and for quickly distinguishing "the whole app is down" from "one specific feature is misbehaving" during an incident.

## 17.3 Runbook Cross-Reference

Detailed, step-by-step incident procedures for the specific failure modes most relevant to this system (leaked secret, unbalanced ledger, cross-tenant leak, unauthorized void, compromised bank token, duplicate transactions, payment race condition) are maintained in **Appendix H** and are not duplicated here.

---

# 18. Extension & Evolution Roadmap

This section catalogs where the architecture is designed to *accept* future change cleanly, versus where an extension would require genuine re-architecture.

## 18.1 Extensions That Fit the Existing Architecture Cleanly

| Extension | Why it fits cleanly |
|---|---|
| A new report | `lib/reports.ts`'s account-balance aggregation functions are already general-purpose; a new report is almost always new filtering/grouping over existing data, not new SQL infrastructure |
| A new document type affecting the ledger (e.g., credit notes) | Follows the established header-table + line-table + `postJournalEntry`-inside-one-transaction pattern exactly |
| A new scheduled/background job | Registers into the existing `app/api/inngest/route.ts` function array with zero changes to any other part of the system |
| A new "undo" capability for a table lacking one (e.g., `imported_transactions`, RISK-009) | Directly follows the `voidPayment`/`voidInvoice` template: add `isVoided`/`voidedAt`, wrap in one transaction |
| Additional admin-gated actions | `requireAdminRole()` is already a general-purpose, reusable gate |

## 18.2 Extensions Requiring Genuine Architectural Change

| Extension | Why it doesn't fit cleanly today |
|---|---|
| Finer-grained roles beyond Admin/Member (separation of duties) | Requires Clerk custom roles *and* a corresponding expansion of `lib/permissions.ts` beyond its current binary check — a real design task, not a drop-in addition |
| True production-hardened bank-feed integration | Section 7.1's stated non-goal; requires OAuth token refresh flows, webhook signature verification, and (critically) resolving RISK-002 before any real credential is safely stored — explicitly scoped as a stretch goal, not a natural next increment |
| FX gain/loss recognition (RISK-010) | Requires a new P&L account category and settlement-date rate-comparison logic threaded through the payment-recording path — a genuine new capability, not a parameter addition |
| Multi-region / multi-database-per-tenant scaling | Would require re-examining ADR-003's single-shared-database assumption entirely |
| Database-level RLS (closing RISK-001) | Requires a full audit of every existing query for compatibility with session-variable-based policies — a significant, valuable, but non-trivial retrofit, not a quick patch |

## 18.3 Prioritized Roadmap (Risk-Weighted)

Given Section 15's risk register, the recommended order of investment for a team taking this system toward a larger or more regulated customer base:

1. **RISK-001** (Postgres RLS) — highest-impact structural gap; closes the single largest residual attack surface.
2. **RISK-002** (encrypt `bank_connections.accessToken`) — must be closed before any real bank-feed connection is used in production, non-negotiable given the credential's sensitivity.
3. **RISK-004** (payment concurrency) — closes a genuine, if narrow, correctness gap.
4. **RISK-007** (CI test gate) — process improvement, low cost, meaningfully reduces regression risk for a growing team.
5. **RISK-006** (Preview environment isolation via Neon branching) — protects production data integrity during active development.
6. Remaining items (RISK-003, 005, 008, 009, 010) — lower urgency, addressed opportunistically alongside feature work that naturally touches the same code.

---

# 19. Compliance & Regulatory Mapping

Provided as an educational reference for architectural planning purposes only — **not legal advice**, consistent with every in-product disclaimer already present on the GST F5 and Tax Estimate reports themselves.

| Regulatory Area | System's Current Posture | Gap |
|---|---|---|
| **GST (Singapore)** | GST F5 summary report models output/input tax mechanics correctly at the ledger level | Excludes reverse-charge scenarios, special GST schemes, bad debt relief — explicitly disclaimed in-product |
| **CPF (Singapore)** | Payroll subsystem correctly models the employee/employer contribution split and posts a balanced journal entry | Uses flat, manually-configured rates rather than IRAS/CPF Board's authoritative real-time age-banded tables |
| **Corporate Income Tax / ACRA** | Tax Estimate report provides a simplified chargeable-income calculation at a flat rate | Excludes partial tax exemption tiering and loss carry-forward mechanics — explicitly disclaimed in-product |
| **PDPA (Personal Data Protection)** | Consistent, disciplined handling of personal data fields (customer/vendor/employee names, addresses, wages) | The system's core "never truly delete" architectural principle (ADR-006, applied by extension to non-ledger tables) is in direct, acknowledged tension with PDPA-style retention-limitation expectations — no retention-expiry or anonymization mechanism exists today (full analysis in Appendix J) |
| **Data residency** | Dependent entirely on the hosting region selected for Neon/Vercel/Clerk at deployment time | Not architecturally enforced or verified; a compliance reviewer must confirm each provider's actual region and any relevant data transfer safeguards independently |

---

# 20. Glossary & Traceability Matrix

## 20.1 Glossary

A full, alphabetized glossary of both accounting terminology (Assets, Liabilities, Debit, Credit, Journal Entry, etc.) and technical terminology (Server Action, Executor Pattern, Idempotent, ORM, etc.) is maintained as **Appendix E** and referenced here rather than reproduced, to avoid this document and that appendix drifting out of sync with each other over time.

## 20.2 Requirement-to-Architecture Traceability Matrix

| Business Driver (Sec. 3.2) | Architectural Goal (Sec. 4.1) | NFR (Sec. 5) | ADR (Sec. 12) | Verified By |
|---|---|---|---|---|
| Isolated books per business | Tenant Isolation | NFR-03 | ADR-003 | QA-002, Test Plan AUTH-06/07 |
| GST-registered business obligations | Ledger Integrity | NFR-01, NFR-02 | ADR-006 | QA-001, Test Plan GST-01/02/03 |
| CPF payroll obligation | Comprehensibility | — | (fits ADR-002's monolith cleanly) | Test Plan PAYROLL-01/02/03 |
| Trust requires an audit trail | Auditability | NFR-04 | ADR-006 | QA-003, Test Plan VOID-01 through VOID-09 |
| Simple access control for small teams | — | NFR-07 | (permissions layered on ADR-001) | QA-004, Test Plan PERM-01 through PERM-06 |
| Free/low-cost infrastructure | Operate on Free/Low-Cost Infrastructure | NFR-08 | ADR-002, ADR-004, ADR-008 | Manual cost review, Part 13 deployment verification |

---

# 21. Appendix Cross-Reference Index

This EADD is intentionally not self-contained — it is the top-level architectural narrative, while depth on specific concerns lives in dedicated companion documents to keep each document focused and independently maintainable. The full document set:

| Document | Scope | Relationship to this EADD |
|---|---|---|
| **Appendix A — Complete Database Schema Reference** | Full column-by-column, table-by-table schema, every enum, every `onDelete` behavior, every journal shape | Authoritative source for Section 8's data architecture; this EADD summarizes, Appendix A enumerates |
| **Appendix B — Environment Variables Reference** | All ten environment variables, per-service setup notes, diagnostic table | Authoritative source for Section 10.3's configuration policy |
| **Appendix C — Command Cheat Sheet** | Every terminal command used across the system's build history, with expected outputs | Operational reference, not architectural, but useful during Section 17's operations activities |
| **Appendix D — Full Route Map** | Every route, its file, its server actions, its writes | Authoritative source for Section 7.3's component-to-route mapping |
| **Appendix E — Consolidated Glossary** | Every accounting and technical term used across the system | Referenced by Section 20.1 rather than duplicated |
| **Appendix F — Threat Model** | Full actor/asset/threat walkthrough (T1–T10), mitigation status | Authoritative source for Section 11's security architecture summary; this EADD summarizes, Appendix F enumerates |
| **Appendix G — Secure Coding Checklist** | Per-layer checklist for schema changes, server actions, routes, client components, secrets | Operationalizes Section 11's principles into a pre-merge checklist |
| **Appendix H — Incident Response Runbook** | Detect/Contain/Investigate/Remediate/Prevent steps for eight specific incident types | Authoritative source for Section 17.3's operational response procedures |
| **Appendix I — Dependency & Supply Chain Security** | Full dependency inventory with blast-radius analysis, `npm audit`/Dependabot guidance | Extends Section 11 into the software supply chain, a concern not otherwise covered in this EADD |
| **Appendix J — Data Privacy & Retention Notes** | Personal data inventory, PDPA-style obligation categories, retention-vs-immutability tension analysis | Authoritative source for Section 19's PDPA row |
| **Appendix K — Authentication & Session Security Deep Dive** | JWT contents, token lifecycle, expiry behavior, role-check trust chain | Extends ADR-001 and Section 11.1's first trust boundary in full mechanical detail |
| **User Guide** | End-user, feature-by-feature operational documentation | Section 4's Goal 4 (comprehensibility) extended to the non-engineering audience |
| **Quick-Start Card** | One-page first-day onboarding | Companion to the User Guide |
| **Test Plan** | Full QA test case catalog (17 sections, ~90 test cases) with a defined Regression Suite | Authoritative source for every "Verified By" cell in Section 20.2's traceability matrix, and the basis for RISK-007's proposed CI gate |

**Document maintenance policy:** this EADD and its companion appendices are living documents. Any change to an ADR's underlying decision (Section 12), any newly discovered risk (Section 15), or any structural schema change (Appendix A) should be reflected here at the same time the corresponding code change ships — an architecture document that drifts from the system it describes is worse than no document at all, since it actively misleads rather than simply being silent.

---

**[END OF ENTERPRISE ARCHITECTURE DESIGN DOCUMENT]**

**Document Control**
Version: 1.0 (expanded from `architecture.md`)
Supersedes: `architecture.md` (retained as a condensed executive-summary companion, not deleted)
Next scheduled review: upon any ADR-affecting change, or at next major feature milestone (per Section 21's closing maintenance policy)

