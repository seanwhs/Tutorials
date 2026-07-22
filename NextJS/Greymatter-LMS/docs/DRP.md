# GreyMatter LMS — Disaster Recovery Plan

**Document type:** Disaster Recovery Plan (DRP)
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Location:** `docs/DISASTER_RECOVERY.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/DEVSECOPS_ONBOARDING.md`, `docs/DATA_DICTIONARY.md`, Appendix F, Appendix G

---

## 1. Purpose and Scope

This Disaster Recovery Plan defines how GreyMatter LMS responds to, recovers from, and learns from events that threaten the availability, integrity, or confidentiality of the system beyond what routine incident response (`docs/DEVSECOPS_ONBOARDING.md` §5) can resolve through normal operational procedure. Where the DevSecOps Onboarding Guide's runbooks address **known, bounded incident classes** (a stuck workflow, a duplicate row, a provider outage), this document addresses **disaster-scale events**: total data loss, prolonged multi-service outages, confirmed security breaches, and catastrophic deployment failures — situations where the normal runbooks are insufficient and a structured recovery process, with defined authority and defined recovery targets, is required.

This plan covers the six external systems GreyMatter depends on (Vercel, Neon, Sanity, Clerk, Inngest, and the optional Resend/Upstash pair), the data these systems hold, and the procedures to restore service and data integrity after a disruption to any of them.

---

## 2. Recovery Objectives

### 2.1 Recovery Time Objective (RTO) and Recovery Point Objective (RPO), by system

| System | Data/service at risk | RTO (target time to restore service) | RPO (maximum tolerable data loss) | Rationale |
|---|---|---|---|---|
| Neon PostgreSQL (production branch) | All transactional state: users, enrollments, progress, attempts, certificates, notifications, audit trail | 4 hours | 5 minutes | This is the system of record for every per-user fact the platform holds; Neon's point-in-time recovery capability governs the achievable RPO |
| Sanity (content dataset) | All authored course content | 8 hours | 24 hours | Content changes infrequently (Section 5.1's own architectural premise); a day's authoring work is a bounded, re-creatable loss in the worst case |
| Vercel (application deployment) | The application itself | 1 hour | 0 (stateless — redeploy from source control) | The application holds no state of its own; recovery is a redeploy of a known-good commit |
| Clerk (identity) | User credentials, session state | N/A (vendor-managed; no GreyMatter-side backup exists or is needed) | N/A | Fully delegated; GreyMatter's own recovery obligation is limited to re-establishing webhook connectivity, not credential recovery |
| Inngest (workflow state) | In-flight and queued background workflow executions | 2 hours | Best-effort — see Section 6.4 | Workflow *definitions* are redeployed with the application; in-flight execution state is vendor-managed |
| Resend / Upstash | Email delivery, rate-limit state | 1 hour | N/A — both are stateless from GreyMatter's perspective | Neither holds data whose loss constitutes a recovery scenario; both degrade gracefully by design (`docs/ARCHITECTURE.md` §11) |

### 2.2 Priority Order for Restoration

If multiple systems are disrupted simultaneously (e.g., a broad cloud-provider incident), restore in this order, reflecting the dependency chain established in `docs/ARCHITECTURE.md` §2:

```text
1. Neon PostgreSQL (production branch)  — nothing authenticated works without it
2. Clerk connectivity                    — no one can sign in without it
3. Vercel application deployment          — the interface itself
4. Sanity content system                  — public content degrades gracefully
                                             longer than transactional failure
5. Inngest workflow engine                 — background effects can queue/delay
                                             without blocking core learning flows
6. Resend / Upstash                          — both already fail gracefully by
                                                 design; lowest restoration priority
```

---

## 3. Disaster Scenarios and Response Procedures

### 3.1 Scenario: Total Neon Database Loss or Corruption

**Definition of disaster (not routine incident):** the production database is unreachable for longer than 30 minutes with no resolution in sight from Neon's status page, or data integrity is confirmed compromised (e.g., a bulk-delete or corrupting migration executed against production in error).

**Detection:** Application error rate spike on every authenticated route; `docs/DEVSECOPS_ONBOARDING.md` §4.2 monitoring signals (database connection errors) sustained beyond the threshold that would normally self-resolve per Appendix G §G.4.

**Response procedure:**

```text
1. DECLARE the incident as a disaster (not a routine outage) if:
   - Neon's status page confirms an incident affecting the production
     branch specifically, AND
   - No resolution ETA is provided, OR the incident has already
     exceeded 30 minutes.

2. NOTIFY: escalate to the full incident response group (Section 8),
   not just the on-call DevSecOps engineer.

3. ASSESS scope:
   - Is this an availability issue (database unreachable, data intact)
     or an integrity issue (data corrupted or deleted)?
   - If availability only: proceed to step 4a.
   - If integrity compromised: proceed to step 4b.

4a. AVAILABILITY RECOVERY:
   - Monitor Neon's own recovery; Neon's serverless architecture
     typically self-heals availability incidents faster than a
     manual failover would achieve.
   - If Neon's own recovery exceeds the 4-hour RTO with no ETA,
     escalate to Neon support directly, referencing the production
     branch and project identifiers.
   - Communicate a degraded-service notice (Section 7) if the outage
     is customer-visible and exceeds 1 hour.

4b. INTEGRITY RECOVERY (data corruption/loss):
   - IMMEDIATELY stop any process writing to the affected branch to
     prevent compounding the damage.
   - Use Neon's point-in-time recovery (PITR) capability to restore
     the production branch to the last known-good timestamp, PRIOR
     to the corrupting event.
   - Cross-reference the restoration timestamp against workflow_events
     and audit_logs (if recoverable) to identify exactly what
     transactional activity occurred between the restore point and
     the incident, so affected users can be identified and, where
     appropriate, notified or manually reconciled.
   - Re-run npm run db:migrate against the restored branch to confirm
     schema state matches the current application version before
     resuming traffic.

5. VERIFY before resuming traffic:
   - Run the full post-deploy smoke test
     (docs/DEVSECOPS_ONBOARDING.md §3.4).
   - Specifically re-verify every unique constraint listed in
     Appendix B §B.4 is present and enforced on the restored branch —
     a restore operation is a plausible way for a constraint to be
     inadvertently missing if the restore predates a migration.
   - Confirm enrollment, module submission, and certificate download
     each work end to end using a known test account before declaring
     recovery complete.

6. DOCUMENT via the post-incident review process (Section 9).
```

**Recovery point achievable:** Neon's PITR capability is the governing constraint on RPO. Confirm, as a standing operational requirement independent of any active incident, that the production branch's PITR retention window is configured to meet or exceed the 5-minute RPO target in Section 2.1 — this is a setting to verify quarterly (`docs/DEVSECOPS_ONBOARDING.md` §4.3), not something to discover during an actual incident.

---

### 3.2 Scenario: Sanity Content Loss or Corruption

**Definition of disaster:** the production content dataset is found to be missing documents, containing corrupted documents (e.g., broken references across a large portion of the course catalog), or is unreachable for an extended period with no vendor-side resolution.

**Response procedure:**

```text
1. ASSESS scope: is this a Sanity-platform outage (data intact,
   temporarily unreachable) or a data-loss/corruption event
   (accidental bulk deletion, a bad migration script run against
   Studio's dataset)?

2. IF PLATFORM OUTAGE:
   - Recall the architectural fact from docs/ARCHITECTURE.md §9:
     public content pages use time-based revalidation with a bounded
     cache window. Recently-cached pages may continue serving stale
     but VALID content for a short period even during a Sanity outage,
     depending on Vercel's own caching behavior — this is not a
     guaranteed mitigation and should not be relied upon as a
     substitute for restoration, but it may reduce customer-visible
     impact during the initial minutes of an incident.
   - Monitor Sanity's status page; escalate to Sanity support if
     the incident exceeds the 8-hour RTO with no resolution ETA.

3. IF DATA LOSS/CORRUPTION:
   - Sanity retains a document history/revision log for published
     content by default; the FIRST recovery action is to attempt
     restoration of affected documents via Sanity's own document
     history feature, document by document, before considering any
     broader dataset-level restoration.
   - If loss is broad enough that document-by-document restoration is
     impractical, escalate to Sanity support for dataset-level
     restoration options appropriate to the project's plan tier.
   - Cross-reference the last known-good state against the content
     model documented in Appendix C — after any restoration, manually
     verify the course → chapter → lesson reference chain is intact
     for at least the highest-traffic courses before resuming public
     traffic assumptions.

4. VERIFY:
   - Confirm the public catalog and at least one full course detail
     page render correctly.
   - Confirm the CORS origins configuration (docs/ARCHITECTURE.md §10)
     survived restoration intact — this is a project-level setting
     that could plausibly be affected by certain restoration paths and
     should always be explicitly re-checked, not assumed.

5. DOCUMENT via Section 9.
```

**Recovery point achievable:** 24-hour RPO reflects the assumption that Sanity's own revision history provides practical recoverability within that window for typical authoring cadence; this should be reassessed if the content editing team's cadence changes materially (e.g., during a large content migration project, temporarily tighten monitoring and consider more frequent manual export snapshots, per Section 6.2).

---

### 3.3 Scenario: Confirmed Security Breach

**Definition of disaster:** any of the following are confirmed, not merely suspected:
- Unauthorized access to production data (Neon or Sanity)
- A leaked secret has been used maliciously (not merely exposed — see distinction below)
- The assessment-integrity vulnerability class (Appendix F §F.5) is confirmed exploited at scale, not just theoretically reintroduced

**Note on severity distinction:** a secret being *exposed* (e.g., briefly visible in a misconfigured log) without evidence of *misuse* is handled per `docs/DEVSECOPS_ONBOARDING.md` §2.4 (rotate, verify, document) — that is an incident, not necessarily a disaster. This section governs the escalated case where misuse is confirmed or reasonably suspected based on evidence.

**Response procedure:**

```text
1. CONTAIN first, investigate second:
   - Rotate every credential plausibly connected to the breach
     IMMEDIATELY, per docs/DEVSECOPS_ONBOARDING.md §2.1's full
     inventory — do not wait for full root-cause understanding before
     containing.
   - If the breach involves a specific user account or set of
     accounts (e.g., evidence of session hijacking), consider
     forcing a session invalidation for affected accounts via Clerk's
     dashboard.
   - If the breach involves the assessment-integrity vulnerability
     class specifically, follow docs/DEVSECOPS_ONBOARDING.md §5.1's
     runbook in full — that runbook IS the appropriate first-response
     procedure for this specific disaster class; this document's role
     is to escalate its severity classification and notification
     requirements, not replace its technical steps.

2. PRESERVE evidence before remediating data:
   - Export relevant audit_logs, webhook_events, and workflow_events
     rows covering the suspected exposure window BEFORE any
     remediating data changes (deletions, corrections) are made.
   - Preserve Vercel/application logs covering the same window.

3. ASSESS scope and impact:
   - Which specific users, courses, or records are affected?
   - Was any PII (email addresses — the only PII this system stores
     per docs/DATA_DICTIONARY.md §2.1, §2.6) exposed to an
     unauthorized party?

4. REMEDIATE:
   - Fix the underlying vulnerability following the standard pipeline
     (docs/DEVSECOPS_ONBOARDING.md §3), with the pre-deploy gate
     applied in full — a security-fix deployment does not skip the
     gate; if anything, it warrants MORE scrutiny, not less.
   - Add a permanent regression test encoding the specific exploited
     condition (docs/TEST_PLAN.md §8.3), non-negotiably.

5. NOTIFY, per Section 8 — a confirmed breach involving user PII
   triggers the external notification obligations described there,
   which may include legal/compliance escalation beyond the
   engineering team's own authority to decide unilaterally.

6. DOCUMENT via Section 9's post-incident review, with this scenario
   class specifically requiring sign-off from a role beyond the
   engineer who executed the remediation.
```

**Recovery objective note:** there is no meaningful "RTO/RPO" framing for a breach in the same sense as an availability incident — the objective here is *contained, evidenced, remediated, and disclosed appropriately*, on a timeline governed by the severity of impact rather than a fixed target.

---

### 3.4 Scenario: Catastrophic Deployment Failure

**Definition of disaster:** a production deployment renders the application unusable (not merely degraded) and either cannot be rolled back through Vercel's standard mechanism, or the rollback itself fails.

**Response procedure:**

```text
1. Attempt standard Vercel rollback to the last known-good deployment
   IMMEDIATELY — this resolves the overwhelming majority of
   deployment-failure scenarios and should always be attempted first,
   before any deeper investigation.

2. IF rollback succeeds: this is a routine incident, not a disaster —
   proceed to standard post-incident review (Section 9) at reduced
   urgency, and separately investigate why the pre-deploy gate
   (docs/DEVSECOPS_ONBOARDING.md §3.2) did not catch the defect
   before release.

3. IF rollback fails or a corresponding DATABASE MIGRATION was applied
   as part of the failed deployment and is not safely reversible:
   - This is now a genuine disaster scenario requiring coordinated
     response, since application code and database schema may now be
     mismatched.
   - Assess whether the migration is additive-only (new columns/
     tables, safe to leave in place with an older application version
     temporarily redeployed) or destructive (dropped/renamed columns,
     NOT safe to pair with a rolled-back application version).
   - If additive-only: redeploy the last known-good application
     commit; the newer schema is forward-compatible and can remain
     until a proper fix-forward deployment is ready.
   - If destructive: this requires a coordinated schema rollback
     (restoring from PITR per Section 3.1's procedure) BEFORE the
     application rollback, since deploying old application code
     against a schema missing expected columns will fail outright.

4. VERIFY via the full post-deploy smoke test before considering the
   incident resolved.

5. DOCUMENT via Section 9, with mandatory root-cause analysis of why
   the pre-deploy gate did not prevent this from reaching production.
```

**Preventive note, stated as a standing policy:** this exact scenario is the reason `docs/ARCHITECTURE.md` §10 and `docs/DEVSECOPS_ONBOARDING.md` §3.3 treat migrations as a deliberate, manual, separately-reviewed step rather than an automatic part of the deploy pipeline — a destructive migration should never be paired with an application deployment in a way that makes rollback of one without the other unsafe. Any migration classified as destructive at authoring time should be flagged explicitly in its pull request per the Documentation Obligations table in `docs/ONBOARDING.md`.

---

### 3.5 Scenario: Extended Multi-Service Outage (Broad Cloud Incident)

**Definition of disaster:** a broad incident (e.g., a major cloud provider region outage) affects multiple dependencies simultaneously — for instance, Vercel and Neon both hosted in an affected region concurrently.

**Response procedure:**

```text
1. Confirm scope across ALL SIX services in Section 1's inventory
   individually — do not assume uniform impact; different vendors
   may use different underlying regions/providers.

2. Apply the Section 2.2 priority order for restoration verification
   as each service recovers independently.

3. Communicate proactively (Section 7) given the likely extended
   duration and multi-system nature of this scenario class — this is
   the scenario most likely to require SUSTAINED status
   communication rather than a single incident notice.

4. Resist the urge to take unilateral remediating action against any
   ONE system in isolation until the full scope across all affected
   systems is understood — a fix applied to one system in isolation
   during a broad incident can create additional inconsistency once
   other systems recover on their own independent timelines.
```

---

## 4. Roles and Authority

| Role | Authority during a declared disaster |
|---|---|
| Incident Commander (rotates; typically the on-call DevSecOps engineer at time of declaration) | Declares disaster status; coordinates response; is the single point of decision authority during active response, superseding normal change-approval process for the duration of the incident only |
| DevSecOps engineer(s) | Executes technical recovery procedures per Section 3 |
| Engineering lead | Approves any deviation from documented procedure; approves resumption of normal traffic after verification |
| Content lead | Consulted for Sanity-specific recovery decisions (Section 3.2); approves acceptable content-loss scope if full restoration is not achievable |
| Legal/compliance (external escalation) | Sole authority on external breach notification decisions (Section 3.3, Section 8) — engineering does not unilaterally decide notification scope or timing for confirmed PII exposure |

**Declaration authority:** any engineer may *propose* declaring a disaster; only the on-call DevSecOps engineer or engineering lead may formally *declare* one, which triggers the notification and authority changes in this section. This distinction exists so that genuine disasters are escalated without hesitation, while avoiding the operational cost of full disaster-response mode for events better handled by the standard runbooks in `docs/DEVSECOPS_ONBOARDING.md` §5.

---

## 5. Backup Strategy Summary

| Data | Backup mechanism | Verified how often |
|---|---|---|
| Neon production database | Continuous WAL-based point-in-time recovery (vendor-managed); retention window configured to meet the 5-minute RPO | Quarterly restoration drill (Section 6.1) |
| Sanity content | Vendor-managed document revision history; no separate GreyMatter-side export by default | Semi-annual manual export snapshot as a supplementary safeguard (Section 6.2) |
| Application source code | Git repository, distributed by nature across every contributor's clone plus the hosted remote | N/A — inherently redundant; no separate backup needed |
| Environment variable / secrets configuration | Vercel's own environment variable storage, plus the organization's secrets manager as the authoritative source | Reviewed at every credential rotation (per `docs/DEVSECOPS_ONBOARDING.md` §2) |
| Infrastructure configuration (CORS origins, webhook endpoints, Inngest environment settings) | Manually documented in `docs/ARCHITECTURE.md` §10; **not currently version-controlled as infrastructure-as-code** | Manually re-verified during every disaster recovery drill (Section 6) — flagged as a known gap below |

**Known gap, stated explicitly:** provider-side configuration (Sanity CORS origins, Clerk webhook registrations, Inngest environment setup) is currently managed manually through each vendor's dashboard, not as version-controlled infrastructure-as-code. This means recovery of these specific settings after, for example, an accidental project deletion, depends on institutional knowledge and this document's own written procedures rather than a redeployable configuration artifact. This is an accepted, documented limitation consistent with the "known gaps" pattern established in `docs/ARCHITECTURE.md` §11 — a candidate for future improvement, not an oversight to silently work around.

---

## 6. Testing and Validation of This Plan

A disaster recovery plan that has never been rehearsed is a document, not a capability. The following drills are mandatory, not optional.

### 6.1 Quarterly: Neon Point-in-Time Recovery Drill

```text
1. In a NON-PRODUCTION context (create a temporary Neon branch from
   a production snapshot, never test destructive recovery against
   the live production branch itself), perform an actual PITR
   restoration to a timestamp of your choosing.
2. Run npm run db:migrate against the restored branch; confirm it
   completes without error.
3. Run the full automated test suite (npm run test:unit,
   npm run test:e2e) against the restored branch's connection string.
4. Confirm every unique constraint from Appendix B §B.4 is present.
5. Document the actual time taken end to end; compare against the
   4-hour RTO target; investigate and address any material gap.
6. Delete the temporary test branch when finished.
```

### 6.2 Semi-Annual: Sanity Content Export Drill

```text
1. Perform a manual export of the production Sanity dataset using
   Sanity's own export tooling.
2. Confirm the export completes successfully and produces a
   non-empty, structurally valid archive.
3. Store the export in a location separate from the primary Sanity
   project (per your organization's backup storage policy).
4. This export serves as a supplementary safeguard beyond Sanity's
   own revision history — it is not itself the primary recovery
   mechanism (Section 3.2's procedure remains the primary path), but
   provides an additional recovery option in a worst-case scenario
   where Sanity's own history is itself unavailable.
```

### 6.3 Annual: Full Tabletop Disaster Simulation

```text
1. Select one scenario from Section 3 (rotate which one each year,
   covering all five over a multi-year cycle).
2. Assemble the full incident response group (Section 8) for a
   simulated response — no actual production systems are touched.
3. Walk the ENTIRE documented procedure verbally, step by step,
   timing each phase.
4. Identify any step that is unclear, outdated, or assumes access/
   knowledge that has since changed (e.g., a team member referenced
   in Section 8 who has since left the team).
5. Update this document based on findings BEFORE closing the drill —
   a tabletop exercise that doesn't result in a document update
   found nothing worth improving, which should itself be treated as
   a surprising and worth-double-checking outcome.
```

### 6.4 Inngest-Specific Note on Testability

Unlike Neon and Sanity, Inngest's in-flight execution state during a genuine platform-level disaster is not independently testable by GreyMatter's own team — recovery in that specific case depends on Inngest's own vendor-side resilience. The practical, testable component within GreyMatter's control is confirming that **function definitions and event schemas** (Appendix E, `docs/API_REFERENCE.md` §6) redeploy correctly and are correctly re-registered (via the `PUT /api/inngest` handshake) after any application redeployment — this is implicitly exercised by every normal deployment and does not require a dedicated disaster drill beyond the standard post-deploy smoke test (Section 3.4, step verifying Inngest sync status).

---

## 7. Communication Plan

| Audience | Trigger for notification | Channel | Owner |
|---|---|---|---|
| Internal engineering team | Any declared disaster | Real-time incident channel | Incident Commander |
| Instructors / content editors | Sanity-related disaster exceeding 2 hours, or any disaster affecting content availability | Direct communication (email or platform notice) | Content lead |
| Students | Any disaster affecting core learning functionality (enrollment, lesson access, assessment submission) exceeding 1 hour | In-app or status-page notice | Incident Commander, with engineering lead sign-off on messaging |
| Affected individuals (confirmed PII exposure) | Confirmed security breach involving PII, per Section 3.3 | As directed by legal/compliance | Legal/compliance |
| Regulatory bodies (if applicable to your jurisdiction) | As required by applicable law for confirmed PII breach | As directed by legal/compliance | Legal/compliance |

**Principle governing all external communication during a disaster:** communicate what is known to be true, communicate uncertainty honestly rather than guessing at resolution timelines, and never disclose specific technical vulnerability detail in a public-facing notice before remediation is confirmed complete.

---

## 8. Incident Response Group

| Role | Responsibility in a disaster |
|---|---|
| Incident Commander (on-call DevSecOps rotation) | Overall coordination and declaration authority |
| Primary DevSecOps engineer | Technical execution of recovery procedures |
| Engineering lead | Approval authority for procedure deviations; final sign-off on service restoration |
| Content lead | Sanity-specific decisions and content-facing communication |
| Legal/compliance contact | Breach notification decisions (Section 3.3, Section 7) |

*(Maintain the actual current names/contact information for each role in your organization's incident-response tooling or on-call system, kept separate from this document so that personnel changes don't require a document revision — but review this table's role structure itself during every annual tabletop drill, per Section 6.3.)*

---

## 9. Post-Incident Review

Every disaster-classified event (Section 3, or any incident escalated per Section 4's declaration authority) requires a documented post-incident review, completed within 5 business days of resolution, covering:

```text
1. Timeline: when detected, when declared, when contained, when
   resolved, when verified.
2. Root cause: the underlying technical or process cause, not just
   the immediate trigger.
3. What worked: which parts of this plan executed as documented and
   were effective.
4. What didn't: any step that was unclear, missing, or actively
   counterproductive during real execution.
5. Data/scope impact: precisely what was affected, referencing the
   evidence preserved per Section 3.3 step 2 where applicable.
6. Corrective actions: specific, assigned, dated follow-up items —
   including, where applicable, a new automated regression test
   (per docs/TEST_PLAN.md §8.3) and/or a revision to this document.
7. Document revision: this DRP itself is updated in the same review
   cycle if the incident revealed any gap in it — a disaster that
   doesn't result in a plan update should be treated as a signal the
   review was incomplete, not that the plan was already perfect.
```

---

## 10. Plan Maintenance

This document is reviewed and re-approved:

- At every annual tabletop drill (Section 6.3), unconditionally
- Immediately following any disaster-classified incident (Section 9)
- Whenever a material architectural change occurs (a new external dependency added, a data store migrated, a change to the RTO/RPO targets' underlying assumptions)
- Whenever personnel referenced in Section 8's role structure change, even if the role structure itself is unchanged

**Document owner:** the DevSecOps role defined in `docs/DEVSECOPS_ONBOARDING.md`, with mandatory engineering-lead co-approval on any revision to Section 2 (recovery objectives) or Section 4 (authority).
