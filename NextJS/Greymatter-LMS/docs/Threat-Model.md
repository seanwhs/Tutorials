# GreyMatter LMS — Threat Model

**Document type:** Threat Model
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Methodology:** STRIDE (per-component), supplemented with data-flow-based trust boundary analysis
**Location:** `docs/THREAT_MODEL.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/SRD.md`, `docs/DISASTER_RECOVERY.md`, Appendix F, Appendix G

---

## 1. Purpose and Methodology

This document systematically identifies threats against GreyMatter LMS, evaluates them, and maps each to an existing mitigation or an accepted residual risk. It uses **STRIDE** (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) applied against each trust boundary in the system, following the data flow diagram in `docs/ARCHITECTURE.md` §2.

Unlike a generic threat model template, this document is written **against a system that has already had one confirmed, deliberately-demonstrated vulnerability class** (the Part 10 client-side grading flaw, fixed in Part 11) — that history is treated throughout this document not as a footnote, but as the calibrating example for how seriously every other threat here must be taken. If a threat in this document feels abstract, recall that the assessment-integrity threat was not abstract; it was built, exploited by the system's own creators as a teaching exercise, and only then fixed. Every threat below deserves the same level of concrete scrutiny.

### 1.1 Risk Rating Scale

| Rating | Likelihood × Impact |
|---|---|
| **Critical** | High impact, and either already demonstrated exploitable or trivially so |
| **High** | High impact, moderate likelihood, or moderate impact with high likelihood |
| **Medium** | Moderate impact and likelihood |
| **Low** | Low impact, or high impact but requiring an already-compromised precondition |

### 1.2 Scope

In scope: the Next.js application, its Server Actions and Route Handlers, its data stores (Neon, Sanity), its identity integration (Clerk), its workflow engine (Inngest), and its supporting services (Resend, Upstash). Out of scope: the internal security posture of the vendor services themselves (Clerk's own infrastructure security, Neon's own infrastructure security) — these are treated as trusted third parties per the delegation decisions in `docs/ARCHITECTURE.md` §12, with GreyMatter's own responsibility limited to correct integration, not vendor infrastructure audit.

---

## 2. System Decomposition and Trust Boundaries

```text
                         TRUST BOUNDARY 1
                         (Internet ↔ Application)
┌────────────┐                │
│  Browser     │◄──────────────┤
│  (untrusted) │                │
└────────────┘                │
                              ▼
                    ┌───────────────────┐
                    │  Next.js Application │
                    │  (trusted, but every  │
                    │   input from TB1 must  │
                    │   be treated as hostile)│
                    └──────────┬─────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │      TRUST BOUNDARY 2 │  TRUST BOUNDARY 3     │
        │      (App ↔ Content)  │  (App ↔ Transactional) │
        ▼                      ▼                        ▼
┌───────────────┐    ┌───────────────────┐    ┌───────────────┐
│    Sanity        │    │  Neon PostgreSQL    │    │     Clerk        │
│ (semi-trusted —   │    │  (fully trusted —    │    │ TRUST BOUNDARY 4 │
│  editor-authored,  │    │   application-owned   │    │ (App ↔ Identity)  │
│  not user-authored)│    │   schema and access)   │    │                  │
└───────────────┘    └───────────────────┘    └───────────────┘
                               │
                    TRUST BOUNDARY 5
                    (App ↔ Workflow Engine)
                               ▼
                    ┌───────────────────┐
                    │      Inngest         │
                    └───────────────────┘
```

**The single governing principle of this entire threat model**, stated once here and referenced throughout: **anything crossing Trust Boundary 1 (from the browser) is hostile until proven otherwise by server-side verification. Nothing crossing any other boundary is assumed correct by default either — every boundary crossing requires an explicit verification appropriate to what that boundary actually guarantees** (per `docs/ARCHITECTURE.md` §5.1's "two-system principle" and §7.3's cross-system verification rule).

---

## 3. Threats by STRIDE Category

### 3.1 Spoofing (Identity)

#### T-S-01: Session forgery / credential-less impersonation

**Description:** An attacker attempts to access authenticated functionality without a genuine, verified session.

**Trust boundary:** TB1 (Browser ↔ Application)

**Attack scenario:** An attacker crafts a request to a dashboard route or Server Action without a valid Clerk session token, or with a forged/expired one.

**Mitigation:** Session validity is verified by Clerk's SDK at every protected route via `requireUser()`/`requireRole()` (`docs/SRD.md` REQ-AUTH-005, REQ-AUTH-006). Session tokens are issued and cryptographically validated entirely by Clerk; the application never implements its own session mechanism.

**Residual risk:** Low. Fully delegated to a specialist identity provider per `docs/ARCHITECTURE.md` §12's stated rationale.

**Rating:** Low (well-mitigated)

---

#### T-S-02: Webhook sender impersonation

**Description:** An attacker sends a forged request to `/api/webhooks/clerk` claiming to be Clerk, attempting to create, modify, or delete user accounts.

**Trust boundary:** TB1 (Internet ↔ Application, specifically the webhook endpoint)

**Attack scenario:** An attacker who discovers the webhook URL (not inherently secret — webhook URLs are not designed to be confidential) sends a fabricated `user.created` or `user.deleted` payload.

**Mitigation:** Cryptographic signature verification (Svix) over the exact, unmodified request body, using a secret shared only with Clerk (`docs/SRD.md` REQ-AUTH-002; `docs/API_REFERENCE.md` §3.2). Requests lacking valid signature headers or failing verification are rejected with `400` before any processing occurs.

**Residual risk:** Low, contingent on the signing secret itself remaining confidential (see T-I-04, Information Disclosure, for the secret-exposure threat this depends on).

**Rating:** Low (well-mitigated, with a documented dependency)

---

#### T-S-03: Instructor identity spoofing via unlinked/mislinked profile

**Description:** A user attempts to gain instructor-level access to a course they do not actually author, by exploiting a misconfiguration in the `instructor.userId` linkage.

**Trust boundary:** TB2 (App ↔ Content) combined with TB3 (App ↔ Transactional)

**Attack scenario:** Because `instructor.userId` is a manually-set, application-unenforced field (no foreign key can exist across systems — `docs/ARCHITECTURE.md` §7.3), an administrator error (linking the wrong `userId`) or a race during onboarding could grant instructor visibility to the wrong account.

**Mitigation:** `verifyCourseOwnership` re-checks this linkage on every instructor-scoped request (`docs/SRD.md` REQ-INS-001). However, the mitigation depends entirely on the **correctness of manual data entry** at link-creation time — there is no automated verification that a given `userId` value genuinely corresponds to the intended person.

**Residual risk:** Medium. This is a genuine gap: the system correctly enforces *whatever* linkage exists, but has no mechanism to detect an *incorrect* linkage created by human error during the manual promotion process (`docs/USER_MANUAL.md` §5.1).

**Rating:** Medium — recommend adding a confirmation step (e.g., displaying the linked account's email back to the administrator at link-creation time) as a compensating control; tracked as a residual finding, not currently remediated.

---

### 3.2 Tampering (Data Integrity)

#### T-T-01: Client-side falsification of assessment correctness — THE CALIBRATING THREAT

**Description:** A malicious or curious learner modifies a network request to claim a submitted answer was correct, attempting to obtain a passing grade, completion status, or certificate without genuinely answering correctly.

**Trust boundary:** TB1 (Browser ↔ Application), specifically the assessment submission path.

**Attack scenario (confirmed, historically demonstrated within this system's own construction — see Part 10/11 of the implementation record):**
```text
1. Attacker submits a wrong answer via the UI.
2. Attacker intercepts the outgoing network request via browser
   DevTools.
3. Attacker modifies the request body to include a field claiming
   correctness (e.g., "clientComputedIsCorrect": true).
4. Attacker resends the modified request.
```
This was not a hypothetical during this system's development — it was built, demonstrated to work, and then fixed. See `docs/ARCHITECTURE.md` §7.2 for the full narrative.

**Mitigation:** Complete removal of any answer-key data or correctness field from every browser-facing query and every accepted Server Action input. Grading is performed exclusively server-side, via `gradeSubmission`, against a freshly-retrieved, never-client-supplied answer key, scoped through an independently-verified course→lesson→module chain (`docs/SRD.md` REQ-ASM-002, REQ-ASM-003, REQ-ASM-005).

**Verification of mitigation:** Permanent automated regression tests (`tests/unit/grading-security.test.ts`) assert the answer-key fields can never reappear in the relevant Zod schemas; `docs/TEST_PLAN.md` §6.1 mandates a manual adversarial re-test of this exact scenario before every release.

**Residual risk:** Low, but **only because of the specific, deliberate, tested mitigation** — this threat is the highest-consequence item in this entire threat model if the mitigation were ever silently weakened. Treat any change to `lib/modules/`, `sanity/lib/queries.ts`, or the grading Server Action as automatically requiring re-verification of this specific threat, per `docs/ONBOARDING.md`'s Code Review Standards §2.

**Rating:** Critical if unmitigated; Low as currently implemented — but classified here as the model's **reference threat** precisely because its mitigation must never be assumed permanent without re-verification.

---

#### T-T-02: Enrollment/certificate duplication via race condition

**Description:** An attacker (or simply an impatient double-clicking user) fires concurrent requests attempting to create two enrollment or certificate records for the same user/resource pair, potentially to exploit downstream logic that assumes uniqueness.

**Trust boundary:** TB1 combined with TB3 (concurrent requests reaching the transactional data layer)

**Attack scenario:** Two near-simultaneous enrollment or completion-triggering requests, each independently passing an application-level "does this exist?" check before either has written its result.

**Mitigation:** Database-level unique constraints (`enrollments_user_course_unique`, `certificates_user_course_unique`) make duplication structurally impossible regardless of timing, independent of any application-level check (`docs/SRD.md` REQ-ENR-002, REQ-CRT-002). Proven under real concurrent load via dedicated test scripts (`docs/TEST_PLAN.md` §6.2).

**Residual risk:** Low. This is a strong, database-enforced guarantee, not merely a coding convention.

**Rating:** Low (well-mitigated)

---

#### T-T-03: Cross-course/lesson/module confusion via identifier substitution

**Description:** An attacker substitutes a valid identifier belonging to a *different* course, lesson, or module into a request, attempting to access or grade content outside their actual enrollment scope.

**Trust boundary:** TB1 combined with TB2 (content identifiers crossing into transactional operations)

**Attack scenario:** A student enrolled in Course A discovers (via URL inspection, guessing, or a leaked reference) a valid lesson or module identifier belonging to Course B, and attempts to substitute it into a request while keeping Course A's identifier elsewhere in the same request.

**Mitigation:** Every lesson and module lookup is scoped through a query proving the full course→chapter→lesson(→content) chain, never accepting a bare identifier in isolation (`docs/SRD.md` REQ-LSN-002, REQ-ASM-005). A mismatched chain yields an identical "not found" result to a genuinely nonexistent identifier.

**Residual risk:** Low, contingent on **every** future content-scoped query following this same pattern — this is a convention enforced by code review discipline (`docs/ONBOARDING.md` Code Review Standards §1), not a structural database guarantee, since Neon cannot enforce a foreign key into Sanity.

**Rating:** Low currently, but flagged as **convention-dependent** rather than structurally guaranteed — a new engineer unaware of this pattern could plausibly introduce a regression here without realizing it.

---

#### T-T-04: Webhook payload tampering in transit

**Description:** An attacker intercepts and modifies a genuine webhook payload between Clerk and the application.

**Trust boundary:** TB1 (network transit to the webhook endpoint)

**Mitigation:** Signature verification (T-S-02's mitigation) inherently also detects tampering — any modification to the payload after signing invalidates the signature. HTTPS additionally protects against passive interception, though the signature is the actual integrity guarantee, not transport encryption alone.

**Rating:** Low (well-mitigated)

---

### 3.3 Repudiation (Accountability)

#### T-R-01: Denial of having performed a graded submission or enrollment action

**Description:** A user (or an instructor investigating a dispute) claims an action did not occur as recorded, with no way to independently verify what actually happened.

**Mitigation:** `audit_logs` records both successful and rejected assessment-submission attempts with structured metadata (`docs/SRD.md` NFR-MAINT — traceability); `module_attempts` and `enrollments` themselves serve as the primary transactional record, timestamped and immutable once written.

**Residual risk:** Medium. Audit logging currently covers module-attempt events explicitly, but is not uniformly applied to every sensitive action across the system (e.g., enrollment creation itself does not currently write a dedicated audit log entry beyond the enrollment record's own existence and timestamp — the enrollment row *is* the record, but a dedicated audit entry alongside it is not consistently present the way it is for module attempts).

**Rating:** Medium — recommend extending audit logging consistency to enrollment and certificate-issuance events explicitly, as a defense-in-depth improvement beyond current coverage.

---

#### T-R-02: Instructor denying a manual reminder was sent, or a student denying receipt

**Mitigation:** `notifications` records every dispatched notification with an `emailSent` flag and a `metadata.manual` flag distinguishing instructor-triggered from automated dispatches (`docs/SRD.md` REQ-INS-006). This provides a reasonable accountability trail for this specific action class.

**Rating:** Low (adequately mitigated for the action's actual sensitivity level)

---

#### T-R-03: Certificate authenticity repudiation

**Description:** A dispute over whether a specific certificate was genuinely issued by the platform, or whether its stated content (course, date, recipient) is accurate.

**Mitigation:** Certificates are database-recorded with an immutable, snapshotted course title and recipient email, and a globally unique, sequentially-generated certificate number (`docs/DATA_DICTIONARY.md` §2.6). The certificate number's sequence-based generation (rather than a client-suppliable value) prevents forgery of a plausible-looking certificate number that wasn't genuinely issued.

**Residual risk:** Low, though note the PDF itself contains no independent cryptographic verification mechanism (e.g., a digital signature or QR-code-based verification link) — a sufficiently motivated party could visually alter a downloaded PDF file itself. The *database record* remains authoritative and unaltered regardless, but the system currently offers no self-service way for a third party (an employer, for instance) to independently verify a presented PDF's authenticity against the platform.

**Rating:** Low for internal purposes; **Medium** if third-party certificate verification becomes a genuine business requirement — currently out of scope per `docs/PRD.md` §4.3, flagged here as a threat-model-relevant gap should that scope ever expand.

---

### 3.4 Information Disclosure (Confidentiality)

#### T-I-01: Assessment answer-key exposure — see T-T-01

Cross-referenced rather than duplicated: the disclosure half of the assessment-integrity threat (an answer key being *visible* to the client) is the necessary precondition for the tampering threat described in T-T-01. The mitigation is identical and is documented there in full. This entry exists so that a STRIDE-category audit of "Information Disclosure" specifically surfaces this threat even if a reviewer is scanning by category rather than reading the full document linearly.

**Rating:** Critical if unmitigated; Low as currently implemented (identical rationale to T-T-01).

---

#### T-I-02: Resource existence disclosure via differential error responses

**Description:** An attacker probes whether a specific course, certificate, or other resource exists by observing whether the system's error response differs between "doesn't exist" and "exists but you're not authorized."

**Trust boundary:** TB1

**Mitigation:** Every resource-scoped endpoint deliberately returns an identical response (HTTP 404, or an equivalent generic rejection) for both conditions, across every subsystem: course dashboard access, lesson access, certificate download, instructor course ownership (`docs/SRD.md` REQ-ENR-003, REQ-CRT-004, REQ-INS-001; Appendix F §F.3.2).

**Residual risk:** Low, but — as with T-T-03 — this is a **convention** applied consistently by design, not a framework-level guarantee. Any new resource-scoped feature must deliberately implement this pattern; it is not automatic.

**Rating:** Low currently, convention-dependent for future features.

---

#### T-I-03: Cross-user data leakage via improperly scoped queries

**Description:** A query intended to be scoped to "the current user's own data" is accidentally written without a `WHERE user_id = ...` (or equivalent) filter, exposing one user's data to another.

**Trust boundary:** TB3 (Application ↔ Transactional data)

**Attack scenario:** A new or modified query (e.g., a future analytics feature, a new notification query) omits the user-scoping filter, either through a coding error or a copy-paste mistake from an intentionally platform-wide query (like an instructor's roster query, which is legitimately scoped to a *course*, not a *user*, and could be miscopied for a user-scoped context).

**Mitigation:** Every current query handling per-user data (notifications, progress, attempts, certificates) explicitly filters by the resolved internal `user_id`, resolved server-side from the verified session — never from a client-suppliable parameter (`docs/DATA_DICTIONARY.md` §2, consistently across every relevant table).

**Residual risk:** Medium. This is a **pattern**, not a structural guarantee — Postgres row-level security (RLS) is not currently employed as a defense-in-depth backstop; correctness depends entirely on every query author remembering to scope correctly. This is a legitimate future hardening candidate.

**Rating:** Medium — recommend evaluating Postgres RLS as a defense-in-depth layer for user-scoped tables, particularly as the query surface grows with future features (e.g., a future `/admin` interface per the known gap in `docs/ARCHITECTURE.md` §11).

---

#### T-I-04: Secret exposure via version control or logging

**Description:** A credential (`DATABASE_URL`, Clerk secret key, webhook signing secret) is accidentally committed to Git, logged in plaintext, or otherwise exposed outside its intended access boundary.

**Trust boundary:** Development/operational process, not a runtime trust boundary per se, but with severe runtime consequences.

**Mitigation:** `.gitignore` excludes `.env*.local` from the project's inception (Appendix F §F.9.1); the `git log --all --full-history -- .env.local` verification is a mandatory, recurring, pre-release check (`docs/DEVSECOPS_ONBOARDING.md` §2.2, §4.1); production and development secrets are provisioned independently (§F.9.4), limiting blast radius even if a development-scoped credential were exposed.

**Residual risk:** Medium. The mitigation is procedural and disciplinary (a required check, consistently run) rather than technically enforced (e.g., no server-side pre-commit hook or CI-level secret scanner currently blocks a commit containing a plausible secret pattern automatically).

**Rating:** Medium — recommend adding automated secret-scanning to the CI pipeline (`docs/DEVSECOPS_ONBOARDING.md` §3.1) as a technical backstop to the current manual/procedural check, reducing reliance on an engineer remembering to run the verification command.

---

#### T-I-05: Raw error detail disclosure

**Description:** A stack trace, database error message, or internal implementation detail is returned in an API or Server Action response, aiding an attacker's reconnaissance.

**Mitigation:** Every Server Action and Route Handler returns hand-authored, generic error messages; raw exceptions are logged server-side only (`docs/SRD.md` NFR-SEC-006; Appendix F §F.8.1).

**Residual risk:** Low, verified via `grep`-based inspection as part of the release gate (`docs/DEVSECOPS_ONBOARDING.md` §3.2).

**Rating:** Low (well-mitigated)

---

### 3.5 Denial of Service

#### T-D-01: Assessment submission flooding

**Description:** An attacker (or a runaway client-side bug) submits assessment attempts at high frequency, either to exhaust attempt limits maliciously against another user's account (requires a separate compromise to act as that user) or to generate excessive load/cost.

**Mitigation:** Per-user sliding-window rate limiting on `submitModuleAttempt` (`docs/API_REFERENCE.md` §7), combined with the independent attempt-limit business rule (`docs/SRD.md` REQ-ASM-004).

**Residual risk:** Medium. Rate limiting is **fail-open** in the absence of configured Upstash credentials — a deliberate trade-off (Appendix F §F.7.2), meaning this specific control's effectiveness is entirely contingent on correct production configuration, not a guarantee of the architecture itself.

**Rating:** Medium — directly dependent on the operational discipline documented in `docs/DEVSECOPS_ONBOARDING.md` §4.1's continuous verification that Upstash credentials are genuinely configured in production. Treat as **High** in any environment where this configuration has not been explicitly confirmed.

---

#### T-D-02: Large-payload submission exhausting storage/processing resources

**Description:** An attacker submits an assessment answer or other user-generated content field with an extremely large payload, attempting to waste storage or degrade performance.

**Mitigation:** Explicit size limits enforced via Zod validation before persistence (`docs/SRD.md` REQ-ASM-007; Appendix F §F.4.2).

**Rating:** Low (well-mitigated)

---

#### T-D-03: Batch/scheduled workflow resource exhaustion at scale

**Description:** As the platform's user base grows, the sequential, per-item fan-out pattern used for inactivity reminders and weekly digests (`docs/ARCHITECTURE.md` §8.3) could take an increasingly long time to complete, potentially exceeding practical execution windows or delaying legitimate notification delivery.

**Trust boundary:** Not an adversarial threat in the traditional sense, but a genuine availability/scalability risk explicitly acknowledged in the system's own architecture documentation.

**Mitigation:** None currently beyond the documented, deliberate scope limitation (`docs/ARCHITECTURE.md` §11, Appendix E §E.8) — this is an accepted, monitored limitation, not a resolved threat.

**Rating:** Low at current documented scale ("moderate operational scale" per `docs/PRD.md` §12); **escalates to Medium-High** if user growth approaches the thresholds noted in Appendix E §E.8 without the corresponding architectural migration to true parallel fan-out.

---

#### T-D-04: Concurrency-limited workflow starvation

**Description:** The deliberate `concurrency: { limit: 1 }` setting on scheduled reminder/digest functions (chosen specifically to prevent duplicate-effect races) could, under a pathological scenario (a stuck or extremely long-running execution), delay or starve subsequent legitimate scheduled runs.

**Mitigation:** Inngest's own timeout and retry behavior governs recovery from a stuck execution; `workflow_events` provides observability into a stuck run for manual intervention (`docs/DEVSECOPS_ONBOARDING.md` §5.3's runbook).

**Rating:** Low — the trade-off (favoring correctness over throughput, per `docs/ARCHITECTURE.md` §8.3) is deliberate and monitored, with a documented recovery runbook.

---

### 3.6 Elevation of Privilege

#### T-E-01: Role escalation via Server Action parameter manipulation

**Description:** An attacker attempts to elevate their own role (e.g., from `STUDENT` to `ADMIN`) by manipulating a request to a Server Action or Route Handler.

**Trust boundary:** TB1 combined with TB3

**Mitigation:** No client-facing Server Action or Route Handler accepts a `role` parameter for the *current* user's own account under any circumstance. Role changes occur exclusively via a manually-executed, out-of-band administrative script (`docs/USER_MANUAL.md` §5.1) operating directly against the database, entirely outside the application's own request-handling surface.

**Residual risk:** Low, specifically **because** no self-service role-change endpoint exists at all — this is a case where a documented feature gap (no `/admin` UI, per `docs/ARCHITECTURE.md` §11) is also, incidentally, a strong security control by virtue of minimizing attack surface. This should be weighed carefully if a future `/admin` UI is built: any self-service role-management interface must re-derive this same guarantee (a `STUDENT` must never be able to set their own role) through explicit, resource-level authorization, not merely through the interface's own navigation structure.

**Rating:** Low currently; **flagged as a threat requiring explicit re-analysis** at the time any future admin role-management UI is built (see `docs/ARCHITECTURE.md` §11, item 1).

---

#### T-E-02: Instructor accessing another instructor's course data

**Description:** Covered structurally under T-S-03 (spoofing via linkage) and mitigated by the same `verifyCourseOwnership` check described there — included here under Elevation of Privilege because the *effect* is a privilege boundary violation (viewing data outside one's authorized scope) even when the *cause* is not identity spoofing but a legitimate instructor attempting to view a course they don't own.

**Attack scenario:** A legitimate, authenticated instructor directly manipulates a URL (`/instructor/courses/[courseId]/...`) to reference a `courseId` they do not own.

**Mitigation:** `requireCourseOwnership`, applied before any data is returned (`docs/SRD.md` REQ-INS-001).

**Rating:** Low (well-mitigated)

---

#### T-E-03: Privilege escalation via cross-system trust confusion

**Description:** An attacker exploits the fact that Sanity and Neon have no mutual referential integrity to construct a request where the two systems' independent notions of "who owns what" are made to disagree, potentially by manipulating which of the two systems is consulted for a given authorization decision.

**Trust boundary:** TB2/TB3 seam

**Attack scenario (theoretical, not currently demonstrated):** if any future code path were to trust a *client-supplied* claim about content ownership (e.g., accepting an `instructorUserId` value directly from a request instead of re-deriving it from Sanity), this would reopen a variant of the exact T-T-01 pattern, applied to authorization instead of grading.

**Mitigation:** Every current ownership check re-derives the authoritative relationship from Sanity directly (`verifyCourseOwnership`), never accepting a client-supplied ownership claim.

**Residual risk:** Low currently, but this is the general *pattern* underlying T-T-01, T-T-03, and T-S-03 — worth stating explicitly as its own entry because it represents a **class** of threat (trusting a client-supplied claim about a relationship that should instead be independently re-derived), not just the specific instances already covered. Any future feature should be evaluated against this general pattern, not just checked against the specific existing threats.

**Rating:** Low currently; this entry exists primarily as a **standing review heuristic** for future feature development, not as a currently-exploitable finding.

---

## 4. Threat Summary Matrix

| ID | Threat | STRIDE | Rating | Status |
|---|---|---|---|---|
| T-S-01 | Session forgery | Spoofing | Low | Mitigated |
| T-S-02 | Webhook sender impersonation | Spoofing | Low | Mitigated |
| T-S-03 | Instructor identity mislinkage | Spoofing | **Medium** | Partially mitigated — manual process gap |
| T-T-01 | Client-side grading falsification | Tampering | Low (Critical if unmitigated) | Mitigated, reference threat |
| T-T-02 | Enrollment/certificate duplication | Tampering | Low | Mitigated |
| T-T-03 | Cross-course identifier confusion | Tampering | Low | Mitigated, convention-dependent |
| T-T-04 | Webhook payload tampering | Tampering | Low | Mitigated |
| T-R-01 | Action repudiation (incomplete audit coverage) | Repudiation | **Medium** | Partially mitigated |
| T-R-02 | Manual reminder repudiation | Repudiation | Low | Mitigated |
| T-R-03 | Certificate authenticity dispute | Repudiation | Low / Medium (scope-dependent) | Accepted, scope-bounded |
| T-I-01 | Answer-key disclosure | Info. Disclosure | Low (Critical if unmitigated) | Mitigated, reference threat |
| T-I-02 | Resource existence disclosure | Info. Disclosure | Low | Mitigated, convention-dependent |
| T-I-03 | Cross-user data leakage via query error | Info. Disclosure | **Medium** | Mitigated by convention only — RLS not employed |
| T-I-04 | Secret exposure | Info. Disclosure | **Medium** | Procedurally mitigated, not technically enforced |
| T-I-05 | Raw error disclosure | Info. Disclosure | Low | Mitigated |
| T-D-01 | Submission flooding | DoS | **Medium (High if misconfigured)** | Conditionally mitigated |
| T-D-02 | Large-payload submission | DoS | Low | Mitigated |
| T-D-03 | Batch workflow scale limits | DoS | Low (scale-dependent) | Accepted, documented |
| T-D-04 | Concurrency-limited starvation | DoS | Low | Accepted, monitored |
| T-E-01 | Role escalation via request manipulation | Elevation of Privilege | Low | Mitigated by absence of self-service surface |
| T-E-02 | Cross-instructor data access | Elevation of Privilege | Low | Mitigated |
| T-E-03 | Cross-system trust confusion (general pattern) | Elevation of Privilege | Low | Mitigated currently; standing review heuristic |

---

## 5. Prioritized Remediation Recommendations

Ordered by rating, then by ease of remediation:

1. **T-I-04 (Secret exposure — Medium):** Add automated CI-level secret scanning as a technical backstop to the current manual verification. Low implementation cost, meaningfully reduces reliance on human discipline alone.
2. **T-D-01 (Submission flooding — Medium/High):** Add an automated, monitored alert specifically confirming Upstash rate-limiting credentials are present in the production environment, rather than relying solely on the manual quarterly-ish check in `docs/DEVSECOPS_ONBOARDING.md` §4.1.
3. **T-I-03 (Cross-user data leakage — Medium):** Evaluate Postgres Row-Level Security as a defense-in-depth backstop for every user-scoped table, independent of application-level query correctness.
4. **T-R-01 (Incomplete audit coverage — Medium):** Extend audit logging to enrollment creation and certificate issuance events explicitly, matching the coverage already present for module attempts.
5. **T-S-03 (Instructor mislinkage — Medium):** Add a confirmation/verification step to the manual instructor-linking process (e.g., displaying the target account's resolved email back to the administrator before the link is finalized).
6. **T-T-03 / T-I-02 (Convention-dependent mitigations):** Formalize the "course-scoped query" and "identical response for nonexistent vs. unauthorized" patterns as a checked, ideally lint-enforced or code-review-checklist-enforced rule, rather than relying solely on documented convention — reducing the risk of an unaware future contributor introducing a regression.

---

## 6. Assumptions and Limitations of This Threat Model

- This model assumes the vendor services themselves (Clerk, Neon, Sanity, Inngest, Vercel) are not independently compromised at their own infrastructure layer — that risk is accepted as a delegated trust decision per `docs/ARCHITECTURE.md` §12, not re-analyzed here.
- This model does not include a formal penetration test's findings, since none has been performed as of this document's baseline — recommended explicitly in `docs/TEST_PLAN.md` §9 as a scope gap, not silently assumed covered.
- This model should be revisited whenever a new external dependency is added, a new resource-scoped feature is built (per the T-E-03 standing review heuristic), or the currently-deferred `/admin` interface (`docs/ARCHITECTURE.md` §11) is implemented — that specific addition warrants a full re-analysis of Section 3.6 before release, not an incremental patch to this document.
