# GreyMatter LMS — Incident Response Plan

**Document type:** Incident Response Plan (IRP)
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Location:** `docs/INCIDENT_RESPONSE.md`
**Companion documents:** `docs/DISASTER_RECOVERY.md`, `docs/THREAT_MODEL.md`, `docs/DEVSECOPS_ONBOARDING.md`, `docs/TEST_PLAN.md`, Appendix F, Appendix G

---

## 1. Purpose and Relationship to Other Documents

This Incident Response Plan (IRP) governs the detection, triage, containment, eradication, recovery, and review of **security and operational incidents** in GreyMatter LMS — the day-to-day operational discipline that sits between routine troubleshooting and full disaster response.

It is important to place this document precisely relative to its two closest companions, because the boundary between them is a real, actionable decision point during a live event, not just a filing distinction:

```text
docs/DEVSECOPS_ONBOARDING.md §5 (Runbooks)
  → Known, bounded incident classes with a documented, mostly
    mechanical resolution path (a stuck workflow, a duplicate row,
    a provider outage). Executed by an individual on-call engineer,
    typically without escalation.
        │
        │  escalates when: scope is unclear, containment fails,
        │  evidence of actual compromise/misuse appears, or the
        │  incident exceeds a single engineer's authority to resolve
        ▼
THIS DOCUMENT — Incident Response Plan
  → The structured PROCESS governing classification, roles,
    communication, and evidence handling for any incident serious
    enough that "just run the runbook" is not sufficient on its own.
        │
        │  escalates when: RTO/RPO targets are threatened, data
        │  integrity is confirmed compromised, or the event meets
        │  the "disaster" bar
        ▼
docs/DISASTER_RECOVERY.md
  → Recovery PROCEDURES for catastrophic, business-continuity-level
    events, with defined recovery objectives and formal declaration
    authority.
```

If you are ever unsure which document governs your current situation, default to **this document** — it explicitly defines the criteria for both stepping down to a runbook-only response (Section 4) and stepping up to full disaster declaration (Section 5).

---

## 2. Incident Classification

### 2.1 Severity Levels

| Severity | Definition | Examples in this system | Response time target |
|---|---|---|---|
| **SEV-1 (Critical)** | Confirmed security compromise, confirmed data integrity violation, or total unavailability of a core user journey | Confirmed exploitation of assessment-integrity tampering (T-T-01/T-I-01 in `docs/THREAT_MODEL.md`); confirmed duplicate certificate/enrollment in production; enrollment or lesson-access completely broken for all users | Immediate — page on-call, begin response within 15 minutes |
| **SEV-2 (High)** | Significant functional degradation, suspected (not yet confirmed) security issue, or a single subsystem fully down | Instructor dashboard entirely inaccessible; certificate issuance workflow stuck failing for all users; a suspected but unconfirmed secret exposure | Within 1 hour |
| **SEV-3 (Medium)** | Partial degradation with a workaround, or an isolated defect affecting a bounded set of users | CSV export failing; a single course's analytics page erroring; reminder emails delayed but not lost | Within 1 business day |
| **SEV-4 (Low)** | Cosmetic or non-blocking issue, or a "Should"-priority requirement gap | An accessibility scan advisory; a minor UI inconsistency | Next planned work cycle |

### 2.2 Classification Decision Tree

```text
Is there CONFIRMED evidence (not just suspicion) that a client-
supplied value influenced a graded outcome, OR that more than one
record exists for an "at most one" business rule (enrollment,
certificate), OR that unauthorized access to production data occurred?
        │
       Yes ──► SEV-1. Proceed directly to Section 3. Do not wait for
        │       further confirmation before beginning response.
        No
        │
        ▼
Is a core user journey (sign-up, enrollment, lesson access, assessment
submission, certificate download) completely unavailable for ALL
users, OR is there a credible, evidenced SUSPICION (not yet confirmed)
of the above SEV-1 conditions?
        │
       Yes ──► SEV-2. Begin response; escalate to SEV-1 immediately
        │       upon confirmation.
        No
        │
        ▼
Is the issue isolated to a specific feature, a specific subset of
users, or does a reasonable workaround exist?
        │
       Yes ──► SEV-3
        No
        │
        ▼
                SEV-4
```

---

## 3. Incident Response Lifecycle

```text
┌────────────┐   ┌────────────┐   ┌─────────────┐   ┌─────────────┐   ┌────────────┐   ┌────────────┐
│ Detection    │──►│ Triage &     │──►│ Containment   │──►│ Eradication   │──►│ Recovery     │──►│ Post-        │
│              │   │ Classification│   │               │   │               │   │              │   │ Incident     │
└────────────┘   └────────────┘   └─────────────┘   └─────────────┘   └────────────┘   │ Review       │
                                                                                          └────────────┘
```

### 3.1 Phase: Detection

**Sources of detection**, mapped to what they can reveal (per `docs/DEVSECOPS_ONBOARDING.md` §4.2):

| Source | Detects |
|---|---|
| Application error rate monitoring | Availability degradation, deployment regressions |
| `workflow_events.status = 'FAILED'` rows | Stuck or failing background workflows |
| Automated regression test failure in CI (esp. `grading-security.test.ts`) | A code change reintroducing the assessment-integrity vulnerability class — this should ideally **never** reach production, since CI blocks the merge, but its failure in CI is itself logged here as the earliest possible detection point |
| Clerk/Inngest/Neon/Sanity vendor status pages | Third-party service disruption |
| User report (support channel, instructor report) | Any user-visible defect, including ones not yet caught by automated monitoring |
| Manual adversarial testing (`docs/TEST_PLAN.md` §6.1) | Assessment-integrity regressions not caught by automated tests |
| `git log --all --full-history -- .env.local` (pre-release check) | Secret exposure, before it becomes a live incident |
| Anomalous data pattern (e.g., duplicate row despite a constraint, unexpected `audit_logs` entries) | Confirmed exploitation or a constraint-enforcement gap |

**Action upon detection:** the detecting party (automated system or individual) creates an incident record immediately, even before classification is certain — an incident record can always be downgraded or closed as a non-issue; a real incident that was never recorded cannot be reconstructed after the fact.

### 3.2 Phase: Triage and Classification

**Within the response time target for the suspected severity (Section 2.1):**

1. Assign an **Incident Lead** — for SEV-1/SEV-2, this defaults to the on-call DevSecOps engineer unless explicitly reassigned; for SEV-3/SEV-4, the assigned engineer for the affected area.
2. Apply the classification decision tree (Section 2.2) using currently available evidence — classify based on the **worst plausible interpretation** of available evidence, not the most charitable one. It is always acceptable to downgrade a SEV-1 to SEV-2 once evidence clarifies the scope; it is not acceptable to under-classify and discover the true scope late.
3. Open the incident communication channel (Section 6) immediately for SEV-1/SEV-2.
4. Begin the evidence preservation steps in Section 3.4 **before** any remediating action, for any incident where security compromise is plausible — this ordering is non-negotiable and is the single most common mistake made under time pressure.

### 3.3 Phase: Containment

**Objective:** stop the incident from causing further harm, without yet necessarily understanding or fixing the root cause.

| Incident type | Containment action |
|---|---|
| Confirmed or suspected assessment-integrity compromise | Follow `docs/DEVSECOPS_ONBOARDING.md` §5.1 in full — this runbook **is** the containment procedure for this specific class |
| Confirmed or suspected secret exposure | Rotate the specific credential immediately, per `docs/DEVSECOPS_ONBOARDING.md` §2.4, before further investigation |
| Confirmed duplicate enrollment/certificate | Verify the relevant unique constraint is genuinely present in production; if missing, this itself is the containment priority — apply the missing constraint via the standard migration procedure before addressing any already-existing duplicate data |
| Suspected unauthorized data access | Consider forcing session invalidation for implicated accounts via Clerk's dashboard; do not delete or modify potentially-relevant data yet (see Section 3.4) |
| Availability degradation with an identified bad deployment | Roll back immediately via Vercel's standard mechanism (`docs/DEVSECOPS_ONBOARDING.md` §3.4) — containment here **is** the rollback, executed before root-cause analysis |
| Stuck/failing background workflow | Do not manually force-retry until the underlying cause is at least partially understood (per `docs/DEVSECOPS_ONBOARDING.md` §5.3) — a blind retry can compound a genuine defect |

**General principle:** containment favors stopping harm over preserving convenience. A rollback, a forced session invalidation, or a temporarily disabled feature is always preferable to "leaving it running while we investigate" once SEV-1/SEV-2 status is confirmed.

### 3.4 Phase: Evidence Preservation (mandatory for any suspected security incident, before remediation)

This phase is inserted explicitly between containment and eradication because it is the step most often skipped under pressure, and the one whose omission is least recoverable afterward.

```text
1. Export the relevant rows from audit_logs, webhook_events, and
   workflow_events covering the suspected incident window, BEFORE
   any corrective data changes are made.

2. Preserve application/deployment logs (Vercel) covering the same
   window, in a location independent of the log retention window
   that would otherwise eventually roll them off.

3. If the incident involves a specific commit/deployment, record the
   exact commit hash and deployment timestamp before any rollback or
   fix-forward action potentially obscures which version was live
   during the incident.

4. If the incident involves specific user accounts, record which
   accounts, and their relevant record IDs (enrollment IDs, attempt
   IDs, certificate IDs), before any remediation touches that data.

5. Timestamp every action taken from this point forward, by whom —
   this becomes the incident timeline for the post-incident review
   (Section 8).
```

**Why this ordering is non-negotiable:** a remediation applied before evidence is preserved may inadvertently destroy the only record of what actually happened — this is precisely the ordering mistake called out explicitly in `docs/DEVSECOPS_ONBOARDING.md` §5.1's runbook ("Do NOT attempt to 'quietly fix' the specific student's record first") and is restated here as a general principle applying to every incident class, not just that one.

### 3.5 Phase: Eradication

**Objective:** remove the root cause, not just its symptom.

1. Identify root cause with reference to `docs/THREAT_MODEL.md` if the incident maps to a documented threat — confirm whether an existing, documented mitigation failed, was bypassed, or was never actually in place as assumed.
2. Fix via the standard development pipeline (`docs/DEVSECOPS_ONBOARDING.md` §3), with the pre-deploy gate applied **in full** — an incident-driven fix is never exempt from the gate; if anything, it warrants closer scrutiny given the demonstrated failure mode.
3. Add a permanent automated regression test encoding the specific incident scenario, per `docs/TEST_PLAN.md` §8.3, as a mandatory (not optional) condition of considering eradication complete — an incident that is fixed without a corresponding regression test is not considered closed.
4. For incidents involving a data-integrity gap (e.g., a missing constraint discovered in production), confirm the same gap does not exist in any other environment (development, any preview branches) before closing.

### 3.6 Phase: Recovery

1. Confirm the fix is deployed and verified via the full post-deploy smoke test (`docs/DEVSECOPS_ONBOARDING.md` §3.4).
2. Confirm any evidence-preserved data (Section 3.4) shows the incident's actual scope — identify every affected record/user precisely, not by approximation.
3. Remediate affected data where appropriate (e.g., correcting an incorrectly-issued certificate, reversing a duplicate record) **only after** eradication is confirmed complete — never remediate data while the root cause remains live, since new incorrect data could otherwise be created by the same still-active defect.
4. Resume normal traffic/communicate resolution (Section 6) once verification is complete.

---

## 4. Runbook Reference — When to Use `docs/DEVSECOPS_ONBOARDING.md` Directly

For the following incident types, the referenced runbook **is** the complete containment and eradication procedure — this IRP's role for these specific, well-understood classes is limited to classification (Section 2), evidence preservation ordering (Section 3.4), and post-incident review (Section 8), not re-specifying technical steps already documented elsewhere:

| Incident type | Runbook | Typical severity |
|---|---|---|
| Suspected assessment-integrity compromise | `docs/DEVSECOPS_ONBOARDING.md` §5.1 | SEV-1 |
| Duplicate enrollment or certificate discovered | `docs/DEVSECOPS_ONBOARDING.md` §5.2 | SEV-1 or SEV-2, depending on whether the constraint itself is confirmed missing |
| Background workflow stuck failing | `docs/DEVSECOPS_ONBOARDING.md` §5.3 | SEV-2 or SEV-3, depending on which workflow and user-visible impact |
| External service outage | `docs/DEVSECOPS_ONBOARDING.md` §5.4 | SEV-1 through SEV-3, per the blast-radius table in §1.1 of that document |

**When a runbook-governed incident escalates beyond this document's scope:** if evidence during response reveals a scale, integrity impact, or recovery-time risk matching `docs/DISASTER_RECOVERY.md` Section 3's scenario definitions (e.g., a "stuck workflow" turns out to be caused by underlying database corruption), the Incident Lead escalates to Disaster Recovery declaration authority (`docs/DISASTER_RECOVERY.md` §4) immediately — do not continue working the runbook in isolation once this threshold is crossed.

---

## 5. Escalation to Disaster Recovery

Escalate from this Incident Response Plan to full `docs/DISASTER_RECOVERY.md` procedure when **any** of the following hold:

- Data loss or corruption is confirmed (not merely an availability issue).
- The affected system's RTO (per `docs/DISASTER_RECOVERY.md` §2.1) is genuinely at risk of being exceeded.
- A confirmed security breach involves actual PII exposure to an unauthorized party (not merely a theoretical exposure risk).
- The incident spans multiple external dependencies simultaneously in a way suggesting a broad, non-application-specific cause.
- The Incident Lead determines that normal change-approval authority is insufficient for the response required (this itself is the trigger for Disaster Recovery's formal declaration-authority mechanism).

**Escalation is a decision, not an automatic threshold-crossing** — the Incident Lead makes this call explicitly and documents the reasoning, consistent with `docs/DISASTER_RECOVERY.md` §4's declaration authority structure.

---

## 6. Communication During an Incident

### 6.1 Internal Communication

| Severity | Channel | Cadence of updates |
|---|---|---|
| SEV-1 | Dedicated real-time incident channel; all relevant roles paged | Every 15–30 minutes until contained, then every hour until resolved |
| SEV-2 | Real-time incident channel | Every hour until contained |
| SEV-3 | Standard ticketing/tracking system | At significant status changes |
| SEV-4 | Standard ticketing/tracking system | At resolution |

### 6.2 External Communication

Governed by the same principles and audience table as `docs/DISASTER_RECOVERY.md` §7, applied at the SEV-1/SEV-2 threshold for incidents that are user-visible but do not (yet, or ever) escalate to formal disaster status:

- Communicate what is currently known to be true.
- Communicate uncertainty honestly rather than speculating on resolution time.
- Never disclose specific technical vulnerability detail publicly before remediation is confirmed deployed and verified.
- Any communication implicating confirmed PII exposure is routed through legal/compliance per the same authority structure as `docs/DISASTER_RECOVERY.md` §4 and §7 — engineering does not unilaterally draft or send breach notifications.

---

## 7. Roles and Responsibilities During an Incident

| Role | Responsibility |
|---|---|
| **Incident Lead** | Owns classification, coordinates response, makes containment decisions, decides on escalation to Disaster Recovery, owns the post-incident review |
| **Responding engineer(s)** | Execute technical containment/eradication steps under the Incident Lead's coordination |
| **Communications owner** | Drafts and sends internal/external updates per Section 6, under the Incident Lead's direction; for PII-involving incidents, coordinates directly with legal/compliance |
| **Engineering lead** | Approves any deviation from documented procedure; sign-off authority for resuming normal traffic on SEV-1 incidents |
| **On-call DevSecOps engineer** (if not already the Incident Lead) | Executes the specific runbook referenced in Section 4; owns evidence preservation (Section 3.4) |

**Note on role overlap with Disaster Recovery:** these roles are deliberately the same individuals/rotation as `docs/DISASTER_RECOVERY.md` §4 and §8 — this plan does not introduce a separate on-call structure, only a distinct *process* appropriate to incidents below the disaster threshold.

---

## 8. Post-Incident Review

**Required for every SEV-1 and SEV-2 incident**, within 5 business days of resolution. Optional but encouraged for recurring SEV-3 patterns.

### 8.1 Review Structure

```text
1. Timeline: detection time, classification time, containment time,
   eradication time, recovery time — each timestamped, each with
   who acted.

2. Classification accuracy: was the initial severity classification
   correct in hindsight? If under-classified, why, and what signal
   was missed that should trigger correct classification sooner next
   time?

3. Root cause: the actual underlying cause — reference the specific
   docs/THREAT_MODEL.md threat ID if applicable, noting whether this
   was a previously-identified residual risk (per that document's
   Section 4 summary matrix) materializing, or a genuinely novel
   threat not previously modeled.

4. Evidence preservation compliance: was Section 3.4 followed BEFORE
   remediation began? If not, document what was lost and whether
   scope determination was consequently impaired.

5. Mitigation effectiveness: did existing controls (per the Threat
   Model's mitigation descriptions) work as designed, fail entirely,
   or partially work in an unexpected way?

6. Corrective actions: specific, assigned, dated. MANDATORY items:
   - A new automated regression test (per docs/TEST_PLAN.md §8.3) for
     any SEV-1/SEV-2 caused by a code defect.
   - An update to docs/THREAT_MODEL.md if the incident reveals a new
     threat, an incorrectly-rated existing threat, or a mitigation
     that did not perform as documented.
   - An update to this document (docs/INCIDENT_RESPONSE.md) if the
     response process itself revealed a gap.

7. Communication effectiveness: were internal and external updates
   (Section 6) timely and accurate in hindsight?
```

### 8.2 The Non-Negotiable Linkage to the Threat Model

Every post-incident review for a security-relevant SEV-1/SEV-2 **must** explicitly reconcile against `docs/THREAT_MODEL.md`:

- If the incident matches an existing threat ID: update that threat's "Residual risk" and "Rating" fields if the incident demonstrates the actual risk was higher than previously assessed.
- If the incident does **not** match any existing threat: add a new threat entry before closing the review — an incident with no corresponding threat model entry represents an actual gap in the model's coverage, and closing the incident without updating the model means the same class of gap remains undocumented for the next occurrence.

This linkage exists specifically because of this system's own history: the assessment-integrity vulnerability (T-T-01/T-I-01) was **deliberately built and studied**, which is a highly unusual level of institutional knowledge about one specific threat. Every other threat in the model deserves the same rigor when a real incident provides the opportunity to test whether the documented mitigation and rating were actually accurate — a post-incident review that doesn't feed back into the threat model wastes the single best source of ground-truth validation the team has.

---

## 9. Incident Record Template

```text
Incident ID:              [sequential identifier]
Severity:                 SEV-1 / SEV-2 / SEV-3 / SEV-4
Detected at:               [timestamp]
Detected by:                [source — see Section 3.1]
Incident Lead:               [name]
Classification rationale:     [why this severity, per Section 2.2]

Timeline:
  [timestamp] — [action taken] — [by whom]
  ...

Evidence preserved:
  [ ] audit_logs export (window: ___)
  [ ] webhook_events / workflow_events export (window: ___)
  [ ] Application logs preserved (window: ___)
  [ ] Affected commit/deployment recorded: ___
  [ ] Affected user/record IDs recorded: ___

Containment action:        [description, timestamp]
Root cause:                 [description]
Related Threat Model ID:      [T-XX-XX, or "NEW — added as T-XX-XX"]
Eradication action:          [description, deployment reference]
Regression test added:        [file, test name]
Recovery verified:            [post-deploy smoke test result, timestamp]

Communication log:
  [timestamp] — [audience] — [message summary]

Post-incident review completed: [date]
Corrective actions:
  [ ] [action] — assigned to [name] — due [date]
  ...
Documents updated as a result:
  [ ] docs/THREAT_MODEL.md
  [ ] docs/INCIDENT_RESPONSE.md
  [ ] docs/DATA_DICTIONARY.md / docs/SRD.md (if applicable)

Status: Open / Contained / Resolved / Closed
```

---

## 10. Plan Maintenance

This IRP is reviewed and re-approved:

- After every SEV-1 incident, mandatorily, per Section 8's linkage requirement.
- Annually, alongside the `docs/DISASTER_RECOVERY.md` tabletop drill (see that document's §6.3) — a portion of that same drill should specifically rehearse the Section 2.2 classification decision tree using a simulated ambiguous scenario, since correctly distinguishing SEV-1 from SEV-2 under real time pressure is the skill most valuable to rehearse before it's needed for real.
- Whenever `docs/THREAT_MODEL.md` is updated with a new or re-rated threat, to confirm this plan's classification examples (Section 2.1) remain representative and current.

**Document owner:** the DevSecOps role defined in `docs/DEVSECOPS_ONBOARDING.md`, with mandatory engineering-lead co-approval on any revision to Section 2 (severity classification) or Section 7 (roles).
