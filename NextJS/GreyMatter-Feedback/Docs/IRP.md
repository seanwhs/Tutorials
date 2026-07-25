# GreyMatter Feedback Incident Response Plan

**Version:** 1.0  
**Audience:** Platform owners, technical operators, administrators, security owners, event operations staff  
**Purpose:** Detect, contain, investigate, communicate, recover from, and learn from security and operational incidents affecting GreyMatter Feedback.

---

## 1. Purpose and Scope

This plan covers incidents involving:

```text
Participant feedback forms
Administrator authentication
QR-code links
Next.js application routes and APIs
Neon PostgreSQL
Prisma migrations
Inngest background processing
Upstash Redis rate limiting
PDF reports
S3-compatible object storage
Environment variables and secrets
CSV exports
Participant privacy and data exposure
```

This plan complements the Disaster Recovery Plan.

```text
Incident Response Plan
→ Detect, contain, investigate, communicate, and remediate incidents.

Disaster Recovery Plan
→ Restore systems, data, and service availability after disruption.
```

---

## 2. Incident Response Objectives

GreyMatter Feedback incident response must prioritize:

| Priority | Objective |
|---:|---|
| 1 | Protect participant data and administrator credentials |
| 2 | Stop ongoing unauthorized access or harmful activity |
| 3 | Preserve evidence for investigation |
| 4 | Restore participant feedback availability |
| 5 | Preserve response integrity and historical accuracy |
| 6 | Communicate clearly with stakeholders |
| 7 | Prevent recurrence through corrective actions |

---

## 3. Incident Response Principles

```text
Do not guess.
Do not conceal incidents.
Do not delete evidence.
Do not expose secrets in tickets or chat.
Do not make destructive production changes without approval.
Do not claim data is safe until investigation supports that conclusion.
Do restore participant-facing service as quickly as safely possible.
```

---

## 4. Incident Response Roles

| Role | Responsibilities |
|---|---|
| Incident Commander | Coordinates response, assigns tasks, approves major decisions |
| Technical Operator | Investigates application, Inngest, Neon, Redis, storage, and deployment issues |
| Security Owner | Handles credential exposure, unauthorized access, data exposure, and security review |
| Database Owner | Handles Neon access, recovery branches, migrations, and data integrity |
| Event Operations Lead | Coordinates participant and facilitator communication during live events |
| Communications Owner | Approves external and stakeholder communication |
| Scribe | Records timeline, actions, decisions, evidence, and follow-up items |

For small teams, one person may hold multiple roles. The Incident Commander role must still be assigned explicitly.

---

## 5. Incident Severity Classification

| Severity | Definition | Example |
|---|---|---|
| **SEV-1 Critical** | Confirmed data breach, active credential compromise, or participant feedback unavailable during major live event | Public PDF report exposure; leaked database URL; complete platform outage |
| **SEV-2 High** | Major function unavailable or data processing failure with meaningful operational impact | Feedback accepted but not saved; admin session bypass; Inngest jobs failing |
| **SEV-3 Medium** | Partial feature failure with workaround available | PDF reports fail but CSV export works |
| **SEV-4 Low** | Minor defect with limited impact | QR download button layout issue; non-critical dashboard display error |

---

## 6. Severity Response Targets

| Severity | Acknowledge | Initial Assessment | Stakeholder Update | Post-Incident Review |
|---|---:|---:|---:|---:|
| SEV-1 | 15 minutes | 30 minutes | Every 30 minutes | Required within 5 business days |
| SEV-2 | 30 minutes | 1 hour | Every 2 hours | Required within 10 business days |
| SEV-3 | 4 business hours | 1 business day | Daily if unresolved | Recommended |
| SEV-4 | 2 business days | 5 business days | As needed | Optional |

---

# 7. Incident Lifecycle

```text
Detection
   ↓
Triage
   ↓
Containment
   ↓
Investigation
   ↓
Eradication
   ↓
Recovery
   ↓
Communication
   ↓
Post-Incident Review
```

---

## 7.1 Detection

Incidents may be detected through:

```text
Participant reports
Administrator reports
Event facilitator reports
Application logs
Hosting-platform alerts
Inngest failed-run alerts
Neon database alerts
Upstash rate-limit alerts
Object storage alerts
Security monitoring
Dependency or provider notifications
```

Examples:

```text
Participants report QR forms will not load.
Admin sees report status stuck on FAILED.
Monitoring detects many API 503 responses.
GitHub secret scanner reports leaked database URL.
S3 audit logs show unexpected report downloads.
```

---

## 7.2 Triage

The responder should collect the minimum facts needed to classify the incident.

```text
What happened?
When did it start?
Which sessions are affected?
Are participants currently affected?
Is data exposed, altered, lost, or unavailable?
Is the incident ongoing?
Which systems are involved?
What changed recently?
```

### Initial Triage Checklist

```text
[ ] Record UTC detection time.
[ ] Record reporter and communication channel.
[ ] Record affected event/session IDs.
[ ] Identify active live event status.
[ ] Check recent deployments.
[ ] Check application logs.
[ ] Check Inngest dashboard.
[ ] Check Neon status.
[ ] Check Upstash status.
[ ] Check report storage status.
[ ] Assign severity.
[ ] Assign Incident Commander.
```

---

## 7.3 Containment

Containment stops the incident from getting worse.

Examples:

| Incident | Immediate Containment |
|---|---|
| Leaked database URL | Rotate database credentials immediately |
| Leaked admin session secret | Rotate secret; invalidate all sessions |
| Public report exposure | Make bucket private; disable public URL access |
| Spam flood | Tighten rate limits; activate WAF rules |
| Wrong QR code | Remove or cover QR; display correct typed URL |
| Broken form version | Close session or publish corrected version |
| Bad deployment | Roll back to last known-good deployment |

Containment must be documented.

```text
Action taken:
Disabled public report access.

Time:
2026-07-25T14:10:00Z

Owner:
Security Owner

Expected effect:
Prevent further unauthorized report downloads.
```

---

## 7.4 Investigation

Investigation determines:

```text
Root cause
Scope
Affected data
Affected users
Timeline
Attack path, if applicable
Whether incident is ongoing
```

Preserve evidence.

Do not:

```text
Delete logs.
Delete suspicious data.
Overwrite object storage records.
Reset database.
Rotate all systems before recording needed evidence.
```

Collect:

```text
Request IDs
Session IDs
Response IDs
Report IDs
Inngest run IDs
Deployment IDs
UTC timestamps
Relevant safe error logs
Provider audit events
Storage access events
Git commit hashes
```

Avoid collecting or sharing raw participant comments unless necessary and authorized.

---

## 7.5 Eradication

Eradication removes the underlying cause.

Examples:

| Root Cause | Eradication Action |
|---|---|
| Exposed secret | Rotate credential; remove source exposure; review access |
| Validation bug | Patch API validation; add regression test |
| Vulnerable dependency | Update or remove dependency; rebuild and deploy |
| Public storage policy | Set bucket private; use signed download route |
| Missing authorization check | Add server-side auth and ownership validation |
| Inngest configuration error | Correct signing key, sync URL, or function registration |
| Bad migration | Create corrective migration and test on Neon branch |

---

## 7.6 Recovery

Recovery restores normal operation.

```text
Restore application service.
Verify participant route.
Verify feedback submission.
Verify background processing.
Verify dashboard.
Verify CSV export.
Verify PDF reporting.
Monitor for recurrence.
```

Use the Disaster Recovery Plan for detailed service restoration procedures.

---

# 8. Incident Playbooks

## 8.1 Playbook: Participant Feedback Form Unavailable

### Symptoms

```text
/e/[sessionId] returns error.
Participants see blank page.
Participants see “Feedback is unavailable” unexpectedly.
QR code resolves to broken destination.
```

### Severity Guidance

```text
SEV-1:
Live major event is affected.

SEV-2:
Multiple sessions unavailable without immediate major event impact.

SEV-3:
Single non-live session unavailable.
```

### Immediate Actions

```text
[ ] Test participant URL from mobile data.
[ ] Test participant URL from venue Wi-Fi.
[ ] Confirm correct session ID.
[ ] Check Session.isActive.
[ ] Check activeFormVersionId.
[ ] Confirm active form status is PUBLISHED.
[ ] Check hosting provider status.
[ ] Check latest deployment.
[ ] Display fallback typed URL if QR is incorrect.
```

### Containment Options

```text
Rollback faulty deployment.
Close broken session temporarily.
Publish corrected form version.
Display alternative form link.
Use event fallback feedback process.
```

### Recovery Validation

```text
[ ] QR URL loads.
[ ] Correct session title appears.
[ ] Correct questions appear.
[ ] Required controls work.
[ ] Test submission returns 202.
[ ] Inngest stores test response.
```

---

## 8.2 Playbook: Participant Submissions Accepted but Not Stored

### Symptoms

```text
Participant receives success confirmation.
API returns 202.
Dashboard count does not increase.
No Response record appears in Neon.
```

### Likely Cause Areas

```text
Inngest function failure.
Inngest sync issue.
Neon connection issue.
Prisma persistence failure.
Invalid event contract.
Worker queue backlog.
```

### Immediate Actions

```text
[ ] Open Inngest dashboard.
[ ] Locate feedback/submitted run.
[ ] Inspect process-feedback-submission function.
[ ] Inspect save-response-and-answers step.
[ ] Check Neon status.
[ ] Check deployment logs.
[ ] Verify /api/inngest endpoint is reachable.
```

### Containment

```text
Do not disable idempotency checks.
Do not manually insert duplicate responses.
Keep participant drafts available on failed API paths.
Pause report generation if Neon is unstable.
```

### Recovery

```text
[ ] Resolve dependency failure.
[ ] Submit controlled test feedback.
[ ] Confirm Response and Answer records appear.
[ ] Replay failed runs if safe.
[ ] Confirm replay does not duplicate existing responses.
[ ] Compare accepted submissions against persisted responses.
```

---

## 8.3 Playbook: Rate Limiting Failure or Spam Attack

### Symptoms

```text
Unexpected surge in feedback requests.
High 429 response count.
High API latency.
Abnormal response count increase.
Upstash errors.
```

### Immediate Actions

```text
[ ] Identify affected session IDs.
[ ] Check Upstash dashboard.
[ ] Check API request logs.
[ ] Check request rate by session.
[ ] Determine whether traffic is legitimate event activity.
[ ] Confirm x-forwarded-for handling is trusted.
```

### Containment Options

```text
Increase strictness of per-client limit.
Reduce session-wide request threshold.
Close affected session temporarily.
Add edge or WAF rule.
Block abusive source at infrastructure layer.
Require challenge/CAPTCHA for high-risk form.
```

### Recovery Validation

```text
[ ] Normal participants can submit.
[ ] Abusive requests are limited.
[ ] Dashboard response totals are reviewed for suspicious entries.
[ ] Rate-limit configuration is documented.
```

---

## 8.4 Playbook: Administrator Account or Session Compromise

### Symptoms

```text
Unexpected form publishing.
Unexpected CSV exports.
Unexpected session closures.
Unknown report generation.
Suspicious admin access logs.
Leaked administrator password or session secret.
```

### Immediate Actions

```text
[ ] Declare SEV-1 or SEV-2 based on confirmed scope.
[ ] Rotate ADMIN_PASSWORD immediately.
[ ] Rotate ADMIN_SESSION_SECRET if session compromise is possible.
[ ] Redeploy application with new secrets.
[ ] Invalidate existing admin sessions.
[ ] Review recent admin actions.
[ ] Preserve logs and timestamps.
```

### Containment

```text
Disable admin access temporarily if necessary.
Restrict deployment credentials.
Restrict Neon and storage access.
Suspend report downloads if data exposure suspected.
```

### Recovery

```text
[ ] Confirm old cookies no longer work.
[ ] Confirm new login works.
[ ] Review form version history.
[ ] Review session open/close state.
[ ] Review export and report activity.
[ ] Notify affected stakeholders if data may have been accessed.
```

### Corrective Actions

```text
Implement named users.
Implement password hashing.
Implement MFA.
Implement admin audit logging.
Implement login rate limiting.
```

---

## 8.5 Playbook: Secret Exposure

### Possible Exposed Secrets

```text
DATABASE_URL
DIRECT_URL
ADMIN_PASSWORD
ADMIN_SESSION_SECRET
IP_HASH_SECRET
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
UPSTASH_REDIS_REST_TOKEN
S3_SECRET_ACCESS_KEY
```

### Immediate Actions

```text
[ ] Record where secret was exposed.
[ ] Remove public exposure if possible.
[ ] Rotate affected secret.
[ ] Redeploy affected services.
[ ] Review access logs.
[ ] Search source history, logs, tickets, and build output.
[ ] Assess whether data access occurred.
```

### Secret Rotation Matrix

| Secret | Required Rotation Action |
|---|---|
| `DATABASE_URL` / `DIRECT_URL` | Rotate Neon role password or create replacement role |
| `ADMIN_PASSWORD` | Change production admin password |
| `ADMIN_SESSION_SECRET` | Rotate and invalidate all admin sessions |
| `IP_HASH_SECRET` | Rotate; rate-limit identity continuity resets |
| Inngest event/signing key | Rotate through Inngest and deployment platform |
| Upstash token | Rotate Redis token |
| S3 credentials | Disable old key; create restricted replacement credentials |

---

## 8.6 Playbook: Public PDF Report Exposure

### Symptoms

```text
Report URL indexed publicly.
Report URL shared with unauthorized person.
Storage bucket accidentally public.
Unexpected report downloads.
```

### Severity

```text
SEV-1 if participant comments or sensitive feedback is exposed.
SEV-2 if report is low sensitivity but unauthorized access is confirmed.
```

### Immediate Actions

```text
[ ] Make storage bucket private.
[ ] Disable public object access.
[ ] Remove exposed report URL from application.
[ ] Preserve storage access logs.
[ ] Identify affected report IDs.
[ ] Determine whether reports contained sensitive comments.
```

### Recovery

```text
[ ] Implement authenticated report download endpoint.
[ ] Generate short-lived signed URLs.
[ ] Update Report records if URLs changed.
[ ] Revoke or rotate storage credentials if compromise is possible.
[ ] Notify affected stakeholders as required.
```

---

## 8.7 Playbook: CSV Export Data Exposure

### Symptoms

```text
CSV sent to incorrect recipient.
Public sharing link created.
Unauthorized export route access.
Spreadsheet file contains sensitive written comments.
```

### Immediate Actions

```text
[ ] Revoke shared link or access immediately.
[ ] Identify exported session and report scope.
[ ] Identify recipient list.
[ ] Preserve audit and download records.
[ ] Determine whether comments contain sensitive data.
```

### Recovery

```text
[ ] Rotate access links.
[ ] Restrict export permissions.
[ ] Add export audit logging.
[ ] Review CSV formula protection.
[ ] Notify stakeholders where required.
```

---

## 8.8 Playbook: Bad Form Published

### Symptoms

```text
Wrong questions appear.
Wrong session form appears.
Draft content is exposed.
Incorrect choice options appear.
Required status is wrong.
```

### Immediate Actions

```text
[ ] Stop sharing incorrect QR code.
[ ] Close session if necessary.
[ ] Identify correct draft or prior published version.
[ ] Publish corrected version.
[ ] Verify participant URL.
[ ] Inform facilitator of correction.
```

### Data Integrity Consideration

Responses submitted to the incorrect published version remain valid historical records for that version.

Do not relabel them as responses to the corrected form.

---

## 8.9 Playbook: Database Corruption or Accidental Deletion

### Immediate Actions

```text
[ ] Stop destructive operations.
[ ] Record incident time in UTC.
[ ] Identify affected records.
[ ] Do not run database reset.
[ ] Do not apply unrelated migrations.
[ ] Create Neon recovery branch before remediation.
```

### Recovery

```text
[ ] Use Neon recovery point or branch.
[ ] Validate affected event/session/form/response data.
[ ] Prefer targeted restoration.
[ ] Use corrective migration for schema problems.
[ ] Validate all participant and admin workflows after recovery.
```

---

## 8.10 Playbook: Inngest or Provider Outage

### Symptoms

```text
API returns 503.
Events are not dispatched.
Runs remain queued.
Functions fail repeatedly.
```

### Immediate Actions

```text
[ ] Check Inngest status page.
[ ] Check function sync status.
[ ] Check event keys and signing keys.
[ ] Check /api/inngest availability.
[ ] Check recent deployment changes.
```

### Participant Protection

```text
Do not show false success if event dispatch fails.
Keep browser draft intact.
Use offline outbox where applicable.
Provide participant-friendly retry message.
```

### Recovery

```text
[ ] Restore Inngest connectivity.
[ ] Send controlled test event.
[ ] Confirm function execution.
[ ] Replay failed runs as appropriate.
[ ] Monitor queue backlog.
```

---

# 9. Evidence Handling

## 9.1 Preserve

```text
UTC timestamps
Request IDs
Response IDs
Report IDs
Session IDs
Form version IDs
Inngest run IDs
Deployment IDs
Provider incident URLs
Safe log excerpts
Storage access events
Git commit hashes
```

## 9.2 Do Not Include in Broad Incident Channels

```text
Raw participant comments
Raw IP addresses
Database URLs
Cookies
Authorization headers
Passwords
Storage secrets
Inngest keys
Full stack traces containing secrets
```

## 9.3 Evidence Storage

Store incident evidence in an access-controlled location:

```text
Restricted incident ticket
Security case management system
Private incident document repository
Approved encrypted storage
```

---

# 10. Communication Plan

## 10.1 Internal Communication

Use one designated incident channel.

Include:

```text
Incident severity
Current impact
Affected sessions
Current mitigation
Owner
Next update time
```

Example:

```text
SEV-2: Feedback submissions are accepted but not being persisted.

Impact:
Participants may see accepted confirmation, but dashboard counts are delayed.

Affected:
REACT-2026-Q3 and TYPESCRIPT-MODULE-1.

Current action:
Investigating failed Inngest persistence runs.

Owner:
Technical Operator.

Next update:
14:30 UTC.
```

---

## 10.2 Participant Communication

Keep messages brief and actionable.

Example:

> “The feedback service is temporarily unavailable. Your draft remains saved on this device. Please try again shortly or use the alternate feedback link provided by the facilitator.”

Do not mention:

```text
Database vendor outage details.
Secret rotation.
Internal error codes.
Security investigation specifics.
```

---

## 10.3 Stakeholder Communication

For a confirmed data exposure, communication should include:

```text
What happened.
When it happened.
What data may have been affected.
What containment action was taken.
What recipients should do.
Where to ask questions.
```

Legal, privacy, and communications owners should approve external notification wording.

---

# 11. Post-Incident Review

A post-incident review is required for SEV-1 and SEV-2 incidents.

## 11.1 Review Timeline

```text
SEV-1:
Within 5 business days.

SEV-2:
Within 10 business days.
```

## 11.2 Required Review Sections

```text
Incident summary
Customer and participant impact
Timeline in UTC
Detection method
Root cause
Contributing factors
What worked well
What did not work
Containment actions
Recovery actions
Data impact
Corrective actions
Owners and deadlines
```

---

## 11.3 Post-Incident Template

```text
Incident Title:
[Short descriptive title]

Severity:
[SEV-1 / SEV-2]

Incident Start:
[UTC timestamp]

Incident End:
[UTC timestamp]

Duration:
[Duration]

Affected Systems:
[Systems]

Affected Sessions:
[Session IDs]

Impact:
[Participant, admin, data, reporting impact]

Detection:
[How detected]

Root Cause:
[Technical and operational cause]

Timeline:
[UTC events]

Containment:
[Actions]

Recovery:
[Actions]

Data Exposure or Loss:
[None / details]

Corrective Actions:
1. [Action] — Owner — Due Date
2. [Action] — Owner — Due Date
3. [Action] — Owner — Due Date

Review Approved By:
[Name]
```

---

# 12. Incident Response Exercises

Run tabletop exercises regularly.

## Exercise 1 — Public Report Exposure

Scenario:

```text
A PDF report containing written feedback is discovered through a public URL.
```

Test:

```text
[ ] Who declares incident?
[ ] Who makes bucket private?
[ ] How are affected reports identified?
[ ] How are signed URLs implemented?
[ ] Who approves notification?
```

---

## Exercise 2 — Live Event Submission Failure

Scenario:

```text
Participants can open forms but all submissions return 503.
```

Test:

```text
[ ] Can operator identify failed dependency?
[ ] Is fallback URL or alternate form ready?
[ ] Does participant draft remain intact?
[ ] Can team communicate with facilitator?
[ ] Can service be restored within event RTO?
```

---

## Exercise 3 — Leaked Database Credential

Scenario:

```text
DATABASE_URL is committed to a public repository.
```

Test:

```text
[ ] Rotate Neon credential.
[ ] Redeploy application.
[ ] Review access logs.
[ ] Remove secret from repository history where appropriate.
[ ] Confirm old credential no longer works.
```

---

# 13. Final Incident Response Checklist

```text
[ ] Incident Commander assigned.
[ ] Severity assigned.
[ ] UTC timeline started.
[ ] Affected sessions identified.
[ ] Evidence preserved.
[ ] Containment performed.
[ ] Stakeholders informed.
[ ] Recovery validated.
[ ] Monitoring confirms stability.
[ ] Post-incident review scheduled if required.
[ ] Corrective actions assigned.
```

---

# 14. Final Principle

GreyMatter Feedback incidents should be handled with the following order of priorities:

```text
Protect people and participant data
        ↓
Stop ongoing harm
        ↓
Preserve evidence
        ↓
Restore reliable feedback collection
        ↓
Validate data integrity
        ↓
Communicate clearly
        ↓
Learn and improve
```
