# GreyMatter LMS — Product Roadmap

**Document type:** Product Roadmap
**Product:** GreyMatter LMS
**Version:** 1.0 (baseline, post-v1.0.0 GA)
**Status:** Approved for planning
**Location:** `docs/ROADMAP.md`
**Companion documents:** `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/THREAT_MODEL.md`, `docs/RELEASE_NOTES.md`

---

## 1. Purpose and How to Read This Roadmap

This roadmap defines the planned evolution of GreyMatter LMS beyond its v1.0.0 general availability release. It is organized around **three inputs, each traceable to an existing document**, rather than invented from scratch:

1. **Documented, deliberate gaps** — every item in `docs/RELEASE_NOTES.md` Section 4 (Known Issues and Limitations) and `docs/ARCHITECTURE.md` §11 is a candidate roadmap item by construction, since each was explicitly scoped out of v1.0.0 rather than overlooked.
2. **Threat model residual risks** — every "Medium" or higher residual-risk item in `docs/THREAT_MODEL.md` §4's summary matrix represents a security-hardening roadmap candidate, prioritized by the remediation order already established in that document's §5.
3. **New product capability** — genuinely new functionality not implied by an existing gap, sourced from the product goals in `docs/PRD.md` that v1.0.0 intentionally left for a later phase (e.g., paid enrollment).

This roadmap uses horizon-based planning (Now / Next / Later) rather than fixed calendar dates, since committing this document to specific quarters would misrepresent certainty this early past GA. Each item includes its **source document**, its **priority rationale**, and its **dependency chain** — because, consistent with the entire GreyMatter build philosophy, almost nothing here can be built out of order without first building its prerequisite.

---

## 2. Roadmap at a Glance

```text
NOW (v1.1 – v1.2)          NEXT (v1.3 – v2.0)             LATER (v2.x+)
─────────────────           ──────────────────              ───────────────
Admin UI                    Paid enrollment                  Multi-tenancy
CI secret scanning          True fan-out workflows            Certificate verification
Postgres RLS evaluation     Real code execution sandbox         Internationalization
Audit log coverage extension Third-party penetration test        Native mobile
Rate-limit monitoring alert   Cross-tenant instructor tooling
Instructor-link verification
```

---

## 3. NOW — Immediate Post-GA Priorities

These items address the highest-residual-risk and lowest-implementation-cost gaps identified at GA. They are sequenced first specifically because several of them are **security-hardening items with no functional dependency on anything else being built first** — they can begin immediately in parallel with any other roadmap work.

### 3.1 Automated CI Secret Scanning

**Source:** `docs/RELEASE_NOTES.md` GAP-008; `docs/THREAT_MODEL.md` T-I-04
**Priority rationale:** Currently, secret-exposure prevention depends entirely on a human remembering to run `git log --all --full-history -- .env.local` before every release (`docs/DEVSECOPS_ONBOARDING.md` §2.2). This is a procedural control with no technical backstop — the single highest-leverage, lowest-effort hardening item on this entire roadmap.
**Scope:** Integrate an automated secret-pattern scanner into the CI pipeline (Step 3.1 of `docs/DEVSECOPS_ONBOARDING.md`'s pipeline diagram), blocking any commit or PR containing a plausible credential pattern.
**Dependencies:** None. Can begin immediately.
**Definition of done:** A CI job fails automatically on a deliberately-committed test secret in a scratch branch; `docs/DEVSECOPS_ONBOARDING.md` §4.1 updated to reflect the check is now automated, not purely manual.

### 3.2 Instructor-Link Verification Step

**Source:** `docs/THREAT_MODEL.md` T-S-03
**Priority rationale:** The manual instructor-role-linking process (`docs/USER_MANUAL.md` §5.1) currently has no confirmation step, meaning a data-entry error by an administrator could silently grant the wrong account instructor visibility into a course.
**Scope:** Add a confirmation UI step (even a minimal one) to the manual promotion process, displaying the resolved target account's email back to the administrator before the `instructor.userId` link is finalized.
**Dependencies:** None — this can be built as a small, standalone internal tool without depending on the broader Admin UI (Section 3.3) landing first, though it is a natural candidate to fold into that UI once it exists.
**Definition of done:** `docs/THREAT_MODEL.md` T-S-03 residual risk downgraded from Medium to Low upon completion.

### 3.3 Minimal Admin UI (Role Management Only)

**Source:** `docs/RELEASE_NOTES.md` GAP-001; `docs/ARCHITECTURE.md` §11 item 1; `docs/PRD.md` FR-4.1
**Priority rationale:** The `ADMIN` role and its route-protection primitive (`requireRole("ADMIN")`) already exist and are fully tested — this is the single largest gap between "capability implemented" and "capability usable without direct database/script access."
**Scope:** A self-service screen under a new `/admin` route group allowing role changes, gated behind `requireRole("ADMIN")`, following the identical route-level + resource-level authorization pattern used everywhere else in the system.
**Dependencies:** None technically, but **must incorporate `docs/THREAT_MODEL.md` T-E-01's explicit warning** before release: any self-service role-management interface must independently re-verify that a user can never set their own role, rather than relying solely on the interface's navigation structure to prevent it. This threat re-analysis is a required, not optional, part of this item's definition of done.
**Definition of done:** Role changes performable without script access; `docs/THREAT_MODEL.md` §3.6 (Elevation of Privilege) re-analyzed and updated per its own flagged requirement; `docs/ARCHITECTURE.md` §11 item 1 removed from the known-gaps list.

### 3.4 Audit Log Coverage Extension

**Source:** `docs/THREAT_MODEL.md` T-R-01
**Priority rationale:** Module attempts are comprehensively audit-logged; enrollment creation and certificate issuance currently are not, despite being comparably sensitive actions.
**Scope:** Extend `recordAuditLog` calls to enrollment creation (`enrollInCourse`) and certificate issuance (`issue-certificate`), following the exact pattern already established for module attempts.
**Dependencies:** None.
**Definition of done:** `docs/THREAT_MODEL.md` T-R-01 downgraded from Medium to Low; `docs/DATA_DICTIONARY.md` §2.9 updated to reflect the expanded set of `action` values.

### 3.5 Rate-Limit Configuration Monitoring

**Source:** `docs/RELEASE_NOTES.md` GAP-002; `docs/THREAT_MODEL.md` T-D-01
**Priority rationale:** Rate limiting fails open silently if Upstash credentials are absent in production — currently caught only by a manual, recurring check (`docs/DEVSECOPS_ONBOARDING.md` §4.1). An automated alert closes this gap without changing the underlying fail-open design decision, which remains intentional for local development.
**Scope:** An automated startup/health check confirming rate-limiting credentials are present specifically in the production environment, alerting the on-call rotation if absent.
**Dependencies:** None.
**Definition of done:** `docs/THREAT_MODEL.md` T-D-01 rating clarified as consistently Medium (not conditionally High) once monitoring is confirmed in place.

### 3.6 Postgres Row-Level Security — Evaluation Spike

**Source:** `docs/RELEASE_NOTES.md` GAP-009; `docs/THREAT_MODEL.md` T-I-03
**Priority rationale:** Currently, per-user data scoping is a *convention*, not a database-enforced guarantee. This item is scoped as an **evaluation spike**, not a committed implementation, because RLS adoption has real trade-offs (query complexity, Drizzle ORM compatibility considerations) that should be assessed deliberately rather than assumed straightforward.
**Scope:** Time-boxed technical spike: prototype RLS policies against `module_attempts`, `enrollments`, and `notifications` in a non-production branch; assess compatibility with the existing Drizzle query layer and connection-pooling model (recall the pooled, HTTP-driver-based connection from `docs/ARCHITECTURE.md` §4.3, which may have specific interaction considerations with RLS's session-context requirements).
**Dependencies:** None to begin the spike; a decision to proceed to full implementation depends on the spike's findings.
**Definition of done:** A written recommendation (adopt / defer / reject) added to this roadmap's next revision, with rationale.

---

## 4. NEXT — Planned Following Successful NOW-Horizon Delivery

These items represent genuine new capability or larger architectural investments. Each has a real dependency on either NOW-horizon work or on operational maturity signals (e.g., real user scale) that don't yet exist at GA.

### 4.1 Paid Enrollment

**Source:** `docs/RELEASE_NOTES.md` GAP-003; `docs/PRD.md` §4.3 (explicitly out of scope for v1.0.0, not a future promise until now)
**Priority rationale:** The single most significant *product* capability gap, as distinct from the security-hardening focus of the NOW horizon. Represents genuine new business capability rather than closing a documented technical gap.
**Scope:** Payment provider integration; an enrollment-flow redesign accommodating a payment step between "course exists and is published" (already verified server-side per `docs/SRD.md` REQ-ENR-001) and "enrollment record created."
**Dependencies:** This is a **major** architectural addition, not a small extension. It requires:
- A new trust boundary analysis in `docs/THREAT_MODEL.md` (payment data is a materially different risk class than anything currently handled — likely warrants delegating to a specialist payment provider the same way identity was delegated to Clerk, per the pattern established in `docs/ARCHITECTURE.md` §12).
- A new schema addition to `docs/DATA_DICTIONARY.md` (payment/transaction records) with its own idempotency and constraint analysis, following the exact discipline applied to `enrollments` and `certificates` (`docs/ARCHITECTURE.md` §7.4).
- Updated `docs/SRD.md` requirements (new REQ-ENR-* entries) before implementation begins, consistent with this project's requirements-first discipline.
**Definition of done:** Full requirements, threat model, and test plan sections added *before* implementation, mirroring how every other subsystem in this system was specified ahead of being built.

### 4.2 True Fan-Out for Scheduled Workflows

**Source:** `docs/RELEASE_NOTES.md` GAP-005; Appendix E §E.8
**Priority rationale:** Currently appropriate at documented scale ("moderate operational scale" per `docs/PRD.md` §12); this becomes urgent, not optional, once real user growth approaches the thresholds Appendix E §E.8 already anticipates. This is explicitly a **scale-triggered** roadmap item, not a calendar-triggered one.
**Scope:** Migrate `send-inactivity-reminders` and `send-weekly-digest` from single-function sequential fan-out to the two-function, event-per-candidate pattern already documented (not just theorized) in Appendix E §E.8.
**Dependencies:** None technically — the target pattern is already fully specified with runnable example code in Appendix E. The trigger for *scheduling* this work is operational: monitor actual batch-processing duration in production (per `docs/DEVSECOPS_ONBOARDING.md` §4.2's monitoring table) and initiate this migration once execution time trends meaningfully toward the boundary of acceptable scheduled-job duration, rather than waiting until it becomes a live incident.
**Definition of done:** Batch workflows migrated to true fan-out; Appendix E updated to reflect the pattern as implemented, not just as a documented option; `docs/ARCHITECTURE.md` §11 item 3 removed from known gaps.

### 4.3 Real Code Execution Sandbox

**Source:** `docs/RELEASE_NOTES.md` GAP-004; `docs/PRD.md` §4.3
**Priority rationale:** Keyword-matching grading for code exercises is a genuine, acknowledged product limitation, not a security gap — students can write correct code that happens not to match expected keywords, or write code containing expected keywords that is not actually functionally correct.
**Scope:** Integrate a sandboxed code execution environment for the `codeExerciseBlock` module type, replacing (or supplementing) keyword matching with actual execution against test cases.
**Dependencies:** This carries a **significant** new threat surface that must be modeled explicitly before implementation — executing arbitrary user-submitted code is categorically different from every other trust boundary currently documented in `docs/THREAT_MODEL.md`, and deserves the same level of dedicated, deliberate scrutiny this project gave the assessment-integrity vulnerability. This item should not proceed to implementation without a new, dedicated threat model section specifically for code execution, reviewed independently before any code is written — following the same "specify the threat before building the mitigation" discipline that shaped Parts 10–11 of the original implementation.
**Definition of done:** Dedicated threat model section added and reviewed; sandboxed execution implemented with the same security rigor documented for the rest of the assessment system; `docs/RELEASE_NOTES.md` GAP-004 closed.

### 4.4 Third-Party Penetration Test

**Source:** `docs/RELEASE_NOTES.md` GAP-010; `docs/TEST_PLAN.md` §9; `docs/THREAT_MODEL.md` §6
**Priority rationale:** Internal review (this entire documentation suite) is thorough but not a substitute for independent, adversarial external validation — explicitly flagged as a scope gap in `docs/TEST_PLAN.md` from the outset, not a newly-discovered need.
**Scope:** Engage a qualified third-party security firm for a scoped penetration test, with particular attention directed at the assessment-integrity boundary (given its documented history) and any subsystem completed since GA under the NEXT horizon (particularly payment integration, if 4.1 has landed by this point).
**Dependencies:** Best scheduled *after* Section 4.1 (Paid Enrollment) if that work is underway, since a payment-handling system meaningfully expands the scope worth testing.
**Definition of done:** Findings triaged per `docs/INCIDENT_RESPONSE.md` classification conventions (even though sourced externally, not from a live incident); `docs/THREAT_MODEL.md` updated to reflect any newly-identified threats; `docs/RELEASE_NOTES.md` GAP-010 closed.

### 4.5 Cross-Instructor / Cross-Course Reporting for Administrators

**Source:** `docs/ARCHITECTURE.md` §11 item 1 (broader administrative tooling, beyond just role management)
**Priority rationale:** Once the minimal Admin UI (Section 3.3) exists for role management, extending it to platform-wide enrollment/completion visibility and workflow-retry tooling is a natural, lower-risk follow-on rather than a new foundational capability.
**Scope:** Platform-wide dashboards reusing the aggregation query patterns already established for instructor analytics (`docs/API_REFERENCE.md` §4, Appendix B §B.7), scoped to `ADMIN` rather than per-course ownership.
**Dependencies:** Requires Section 3.3 (Minimal Admin UI) to exist first, since this extends that same route group and authorization pattern.
**Definition of done:** `docs/ARCHITECTURE.md` §11 item 1 fully closed (both the role-management and broader oversight aspects).

---

## 5. LATER — Larger Horizon, Contingent on Business Direction

These items are directionally identified but deliberately not scoped in detail, since committing detailed requirements this far out would misrepresent certainty. Each is included because it maps to an explicit, named limitation already on record — not invented for this document.

### 5.1 Multi-Tenant Content and Data Isolation

**Source:** `docs/RELEASE_NOTES.md` GAP-006; `docs/ARCHITECTURE.md` §11 item 4; `docs/PRD.md` §12 (assumption of single-tenant operation, stated explicitly)
**Trigger for prioritization:** A genuine business need to serve multiple isolated customer organizations from one deployment, rather than one deployment per customer.
**Why this is LATER, not NEXT:** This is a foundational architectural change touching both the Sanity content model (Appendix C) and the Neon schema (every table would need a tenant-scoping dimension), not an additive feature — it warrants its own dedicated architecture design phase, comparable in scope to the original Part 5 schema design, before any implementation begins.

### 5.2 Third-Party Certificate Verification

**Source:** `docs/THREAT_MODEL.md` T-R-03
**Trigger for prioritization:** A genuine business need for external parties (employers, other institutions) to independently verify a presented certificate's authenticity, beyond the platform's own internal record.
**Likely shape (directional only):** A public, unauthenticated verification endpoint accepting a certificate number and returning whether it was genuinely issued — deliberately excluding any PII beyond what's already intentionally public-facing on the certificate itself, following the same minimal-disclosure discipline applied throughout this system's design.

### 5.3 Internationalization

**Source:** `docs/ARCHITECTURE.md` §12 (English-only assumption, stated explicitly as a design constraint, not an oversight)
**Trigger for prioritization:** A genuine business need to serve non-English-speaking learner populations.
**Why this is LATER:** Touches nearly every layer of the system — Sanity content model (localized fields), UI copy, email templates, and PDF certificate generation — making it one of the largest cross-cutting efforts on this roadmap.

### 5.4 Native Mobile Applications

**Source:** `docs/PRD.md` §4.3 (explicitly out of scope)
**Trigger for prioritization:** A genuine business need beyond what the existing responsive web application (down to 320px viewport width, per `docs/SRD.md` §4.1) adequately serves.
**Why this is LATER:** No current signal in any existing document suggests this is imminent; included here only for completeness against the PRD's explicit non-goals list, to be revisited if that business assumption changes.

---

## 6. Explicitly Not Planned

For clarity, the following are **not** on this roadmap at any horizon, and should not be assumed to be implicitly forthcoming:

- Live/synchronous instruction — remains an explicit non-goal per `docs/PRD.md` §4.3, with no roadmap signal suggesting reconsideration.
- Peer-to-peer social/discussion features — same status.
- Any weakening of the server-exclusive grading model (Section 2.5 of `docs/RELEASE_NOTES.md`) under any circumstance, including performance optimization pressure — this is a permanent architectural invariant, not a candidate for future revisitation.

---

## 7. Roadmap Governance

### 7.1 How Items Move Between Horizons

An item moves from **LATER** to **NEXT** when a concrete business trigger (stated in that item's own entry) materializes. An item moves from **NEXT** to **NOW** when its stated dependencies are satisfied and it becomes the next-highest-priority item by the ordering established in `docs/THREAT_MODEL.md` §5 (for security items) or genuine business urgency (for product items).

### 7.2 Mandatory Documentation Updates on Roadmap Execution

Consistent with `docs/ONBOARDING.md`'s Documentation Obligations table, **no roadmap item is considered complete until its originating gap is formally closed** in the source document that named it:

| If this roadmap item ships... | ...this must be updated |
|---|---|
| 3.1 (CI secret scanning) | `docs/DEVSECOPS_ONBOARDING.md` §4.1, `docs/THREAT_MODEL.md` T-I-04 |
| 3.2 (Instructor-link verification) | `docs/THREAT_MODEL.md` T-S-03 |
| 3.3 (Minimal Admin UI) | `docs/RELEASE_NOTES.md` GAP-001, `docs/ARCHITECTURE.md` §11, `docs/THREAT_MODEL.md` §3.6 |
| 3.4 (Audit log extension) | `docs/THREAT_MODEL.md` T-R-01, `docs/DATA_DICTIONARY.md` §2.9 |
| 3.5 (Rate-limit monitoring) | `docs/THREAT_MODEL.md` T-D-01 |
| 3.6 (RLS spike) | This roadmap document, with the spike's recommendation |
| 4.1 (Paid enrollment) | `docs/PRD.md`, `docs/SRD.md`, `docs/DATA_DICTIONARY.md`, `docs/THREAT_MODEL.md` — new sections, not just edits |
| 4.2 (True fan-out) | `docs/RELEASE_NOTES.md` GAP-005, `docs/ARCHITECTURE.md` §11, Appendix E |
| 4.3 (Code execution sandbox) | `docs/RELEASE_NOTES.md` GAP-004, new dedicated `docs/THREAT_MODEL.md` section |
| 4.4 (Penetration test) | `docs/RELEASE_NOTES.md` GAP-010, `docs/THREAT_MODEL.md` |
| 4.5 (Admin reporting) | `docs/ARCHITECTURE.md` §11 |
| 5.1–5.3 | Respective source documents, in full, before implementation begins — not retroactively |

### 7.3 Review Cadence

This roadmap is reviewed:
- At every roadmap item's completion (per 7.2's linkage table).
- Quarterly, alongside the credential and known-gap review already mandated in `docs/DEVSECOPS_ONBOARDING.md` §4.3.
- Immediately following any SEV-1 incident whose post-incident review (`docs/INCIDENT_RESPONSE.md` §8) identifies a new threat not currently reflected in a NOW-horizon item — a SEV-1 root cause should always be checked against this roadmap to confirm its remediation is tracked here, not just fixed in isolation and forgotten.
