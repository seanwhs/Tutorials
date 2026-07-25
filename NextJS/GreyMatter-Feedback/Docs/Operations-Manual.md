# GreyMatter Feedback Operations Manual

**Version:** 1.0  
**Audience:** Event operators, administrators, technical operators, support staff, platform owners  
**Purpose:** Run GreyMatter Feedback reliably before, during, and after live events, courses, workshops, and training sessions.

---

# 1. Operating Model

GreyMatter Feedback operates through this workflow:

```text
Administrator authors form
        ↓
Administrator publishes form version
        ↓
Operator displays QR code
        ↓
Participant scans and submits feedback
        ↓
API validates submission
        ↓
Inngest processes feedback
        ↓
Neon stores response and answers
        ↓
Dashboard updates
        ↓
Administrator exports CSV or requests PDF report
```

The operational goal is:

```text
Participants:
Scan → Answer → Submit → Done

Operators:
Prepare → Monitor → Troubleshoot → Close → Report
```

---

# 2. Roles and Responsibilities

| Role | Responsibilities |
|---|---|
| Event Owner | Approves feedback goals, questions, and final reporting |
| Administrator | Creates events, sessions, forms, QR codes, exports, and reports |
| Facilitator | Displays QR code, announces feedback request, provides fallback URL |
| Technical Operator | Monitors application, Inngest, Neon, rate limiting, and incident response |
| Analyst | Reviews dashboard, CSV, PDF reports, and improvement actions |
| Platform Owner | Manages deployment, credentials, backups, monitoring, and security controls |

For small events, one person may perform several roles.

For large events, assign named owners before the event starts.

---

# 3. Key Operational URLs

Replace the domain with the production GreyMatter Feedback domain.

| Area | URL |
|---|---|
| Landing page | `https://feedback.example.com/` |
| Admin login | `https://feedback.example.com/admin/login` |
| Event list | `https://feedback.example.com/admin/events` |
| Session editor | `https://feedback.example.com/admin/sessions/[sessionId]/edit` |
| Session analytics | `https://feedback.example.com/admin/sessions/[sessionId]` |
| Participant form | `https://feedback.example.com/e/[sessionId]?src=qr` |
| Inngest endpoint | `https://feedback.example.com/api/inngest` |
| Local Inngest dashboard | `http://localhost:8288` |
| Prisma Studio, local only | `http://localhost:5555` |

---

# 4. Pre-Event Operations

## 4.1 One Week Before Event

Complete the following tasks.

```text
[ ] Confirm event owner.
[ ] Confirm administrator access.
[ ] Create event or course.
[ ] Create planned sessions.
[ ] Define session IDs.
[ ] Draft feedback questions.
[ ] Review privacy and retention requirements.
[ ] Decide required versus optional questions.
[ ] Confirm reporting requirements.
[ ] Confirm who receives CSV and PDF reports.
[ ] Confirm production environment is operational.
```

### Session ID Naming Guidance

Use readable, stable, QR-friendly identifiers.

Good:

```text
REACT-2026-KEYNOTE
REACT-2026-Q3
TYPESCRIPT-MODULE-1
LEADERSHIP-WEEK-2
```

Avoid:

```text
Session 1
Workshop / React
My Session!
react workshop
```

---

## 4.2 One Day Before Event

```text
[ ] Create draft form versions.
[ ] Add and order questions.
[ ] Review question wording.
[ ] Review rating scale labels.
[ ] Review choice options.
[ ] Preview forms on desktop.
[ ] Preview forms on mobile.
[ ] Publish correct form versions.
[ ] Verify active participant URLs.
[ ] Download QR-code PNG files.
[ ] Add QR codes to slides or print materials.
[ ] Display fallback typed URLs.
[ ] Submit test responses.
[ ] Confirm dashboard updates.
[ ] Export test CSV.
[ ] Generate test PDF report.
```

---

## 4.3 Thirty Minutes Before Event

```text
[ ] Confirm event and session title.
[ ] Confirm correct session ID.
[ ] Confirm session is active.
[ ] Confirm correct form version is published.
[ ] Confirm QR code scans correctly.
[ ] Confirm typed fallback URL works.
[ ] Test on mobile data.
[ ] Test on venue Wi-Fi.
[ ] Open session dashboard.
[ ] Confirm Inngest production functions are healthy.
[ ] Confirm report storage is available.
[ ] Confirm technical operator contact is reachable.
```

---

# 5. Creating an Event and Session

## 5.1 Create Event

1. Sign in:

   ```text
   /admin/login
   ```

2. Open:

   ```text
   /admin/events
   ```

3. Select:

   ```text
   Create event or course
   ```

4. Enter event title.

Example:

```text
React Summit 2026
```

5. Select:

```text
Create event or course
```

---

## 5.2 Create Session

1. Open the event.
2. Select or locate:

   ```text
   Create a session
   ```

3. Enter session title.

Example:

```text
Advanced React Patterns
```

4. Enter session ID.

Example:

```text
REACT-2026-Q3
```

5. Select:

```text
Create session
```

6. Confirm the form editor opens.

---

# 6. Form Authoring Operations

## 6.1 Create Draft Form Version

From the session editor:

```text
/admin/sessions/REACT-2026-Q3/edit
```

Select:

```text
Create draft form version
```

If the session has no prior form, the draft starts empty.

If a previous version exists, the latest version is copied into a new draft.

---

## 6.2 Recommended Standard Workshop Form

```text
Question 1
Type: Rating
Prompt: How useful was this workshop?
Scale: 1–5
Minimum label: Not useful
Maximum label: Extremely useful
Required: Yes
```

```text
Question 2
Type: NPS
Prompt: How likely are you to recommend this workshop to a colleague?
Scale: 0–10
Required: Yes
```

```text
Question 3
Type: Text
Prompt: What was the most valuable part of the workshop?
Required: No
```

```text
Question 4
Type: Text
Prompt: What should we improve for the next workshop?
Required: No
```

---

## 6.3 Form Quality Check

Before publishing:

```text
[ ] Question wording is specific.
[ ] Questions are neutral.
[ ] No question asks two unrelated things.
[ ] Rating labels explain low and high scores.
[ ] Choice options are clear and distinct.
[ ] Required questions are limited.
[ ] Text questions are optional unless essential.
[ ] Form can be completed in under two minutes.
[ ] Question order makes sense.
[ ] Mobile preview is readable.
```

---

# 7. Publishing Operations

## 7.1 Publish a Form

1. Open the session editor.
2. Review the draft.
3. Confirm there is at least one question.
4. Confirm choice questions have at least two options.
5. Select:

```text
Publish version [number]
```

Publishing changes form states:

```text
Old published form:
PUBLISHED → ARCHIVED

New draft form:
DRAFT → PUBLISHED

Session:
activeFormVersionId → New published version ID
```

---

## 7.2 Post-Publishing Verification

After publishing:

```text
[ ] Open participant preview.
[ ] Confirm event title.
[ ] Confirm session title.
[ ] Confirm question order.
[ ] Confirm required labels.
[ ] Confirm rating scale.
[ ] Confirm NPS control layout.
[ ] Confirm choice options.
[ ] Confirm text placeholder.
[ ] Confirm submission button is visible.
```

---

## 7.3 Publishing Safety Rule

Do not change a published form directly.

If a change is needed:

```text
Create new draft version
        ↓
Make changes
        ↓
Preview
        ↓
Publish new version
```

This protects historical analytics.

---

# 8. QR-Code Operations

## 8.1 Generate QR Code

1. Open session analytics:

   ```text
   /admin/sessions/REACT-2026-Q3
   ```

2. Find:

```text
Session QR code
```

3. Select:

```text
Download PNG
```

4. Save using a clear filename.

Recommended format:

```text
greymatter-feedback-REACT-2026-Q3.png
```

---

## 8.2 QR-Code Display Standards

Every QR display must include a typed fallback URL.

Recommended slide:

```text
Share your feedback

[ LARGE QR CODE ]

feedback.example.com/e/REACT-2026-Q3
```

### QR Requirements

```text
[ ] High contrast.
[ ] White or light background.
[ ] Large enough for expected viewing distance.
[ ] No distortion.
[ ] No low-resolution screenshot.
[ ] Production URL, not localhost.
[ ] Tested with at least two phones.
```

---

## 8.3 Recommended Minimum Sizes

| Context | Minimum Suggested Size |
|---|---:|
| Presentation slide | 350 × 350 pixels |
| Phone display | 250 × 250 pixels |
| Printed handout | 5 cm × 5 cm |
| Poster | 8 cm × 8 cm or larger |
| Large auditorium screen | Test from back rows |

---

# 9. Live Event Operations

## 9.1 Facilitator Script

Use a short instruction:

> “Please take one minute to share feedback before you leave. Scan the QR code on screen, or use the typed link below it. Your feedback helps us improve future sessions.”

For anonymous feedback:

> “You do not need to sign in. Please avoid entering sensitive personal or confidential information in written comments.”

---

## 9.2 Dashboard Monitoring

Open:

```text
/admin/sessions/[sessionId]
```

Monitor:

```text
Total response count
Latest submission time
Average rating
NPS
Rating distributions
Choice distributions
Written comments
Report status
```

The dashboard refreshes automatically.

---

## 9.3 Normal Response Pattern

```text
QR code appears
        ↓
Participants scan
        ↓
Responses begin appearing
        ↓
Response total rises
        ↓
Latest submission time remains recent
```

---

## 9.4 Warning Signs

| Symptom | Possible Cause |
|---|---|
| No responses after QR display | Wrong QR code, closed session, unpublished form, poor network |
| Participant sees unavailable form | No active published form version |
| Participant sees closed form | Session `isActive` is false |
| Many submission errors | Inngest, API, rate limit, or network issue |
| Dashboard not updating | Background worker failure or page refresh issue |
| PDF report stuck | Inngest or storage failure |

---

# 10. Live Troubleshooting Procedures

## 10.1 No One Can Open the Form

### Check

```text
[ ] QR code scans to expected URL.
[ ] Typed URL opens.
[ ] Domain is available.
[ ] Session ID is correct.
[ ] Session is active.
[ ] Published form is active.
```

### Immediate Fallback

```text
Display the typed participant URL.
Share the URL in event chat.
Ask facilitator to read URL aloud if necessary.
Use an approved backup feedback process if outage continues.
```

---

## 10.2 Participants Can Open Form but Cannot Submit

### Check Browser Response

Inspect the participant request:

```text
POST /api/feedback
```

Common HTTP statuses:

| Status | Meaning |
|---:|---|
| `202` | Submission accepted |
| `400` | Invalid request or invalid answer |
| `404` | Session not found |
| `409` | Closed or stale form version |
| `429` | Rate limited |
| `503` | Background dependency unavailable |

### Operational Actions

```text
[ ] Confirm session is active.
[ ] Confirm form is published.
[ ] Check Inngest dashboard.
[ ] Check deployment logs.
[ ] Check Upstash Redis configuration.
[ ] Test a different network.
[ ] Verify rate-limit settings are appropriate.
```

---

## 10.3 Dashboard Does Not Update

### Check Sequence

```text
Participant sees success
        ↓
API should return 202
        ↓
Inngest run should exist
        ↓
process-feedback-submission should succeed
        ↓
Response should exist in Neon
        ↓
Dashboard refresh should show new count
```

### Actions

```text
[ ] Open Inngest dashboard.
[ ] Check latest process-feedback-submission run.
[ ] Inspect failed step if present.
[ ] Check Neon connectivity.
[ ] Refresh dashboard manually.
[ ] Check dashboard session ID.
```

---

## 10.4 Rate Limit Blocks Legitimate Test Submission

Local development often uses the fallback identity:

```text
unknown-client
```

This means all local browser tests may appear to originate from the same identity.

### Local Reset

Restart Next.js:

```bash
Ctrl+C
npm run dev
```

### Production Check

```text
[ ] Confirm Upstash Redis is configured.
[ ] Confirm forwarded client IP headers are trusted.
[ ] Confirm rate limit is appropriate for event size.
```

---

## 10.5 PDF Report Is Stuck

### Check Report Status

```text
QUEUED
PROCESSING
COMPLETE
FAILED
```

### Actions

```text
[ ] Open Inngest dashboard.
[ ] Find generate-pdf-report run.
[ ] Inspect failed step.
[ ] Confirm report storage configuration.
[ ] Confirm storage credentials.
[ ] Confirm report output directory exists locally.
[ ] Confirm Neon is available.
```

### Local Storage Check

Generated local PDFs should appear under:

```text
public/reports/
```

---

# 11. Closing a Session

## 11.1 When to Close

Close a session when:

```text
Feedback collection period has ended.
Event has finished.
Organizer wants to prevent late submissions.
A new session version should not receive old traffic.
```

---

## 11.2 How to Close

1. Open session editor:

   ```text
   /admin/sessions/[sessionId]/edit
   ```

2. Select:

```text
Close feedback session
```

Participants then see:

```text
Feedback is closed
```

---

## 11.3 After Closing

```text
[ ] Confirm participant route shows closed state.
[ ] Review dashboard.
[ ] Export CSV if needed.
[ ] Generate PDF report.
[ ] Archive report according to policy.
[ ] Record improvement actions.
```

---

# 12. Reporting Operations

## 12.1 CSV Export

Use CSV export for:

```text
Spreadsheet analysis
Data archive
Custom charts
Business intelligence tools
Data sharing with authorized analysts
```

### Procedure

1. Open session dashboard.
2. Select:

```text
Export CSV
```

3. Save the file in an approved location.

### Security Controls

```text
[ ] Do not upload CSV to public storage.
[ ] Do not share unrestricted links.
[ ] Review written comments before broad distribution.
[ ] Follow retention policy.
```

---

## 12.2 PDF Report Generation

### Procedure

1. Open session dashboard.
2. Locate:

```text
PDF executive report
```

3. Select:

```text
Generate PDF report
```

4. Wait for status:

```text
QUEUED → PROCESSING → COMPLETE
```

5. Select:

```text
Download PDF
```

---

## 12.3 Report Review Template

```text
Session:
[Session title]

Response count:
[Number]

Average rating:
[Number]

NPS:
[Number]

Positive themes:
1. [Theme]
2. [Theme]
3. [Theme]

Improvement themes:
1. [Theme]
2. [Theme]
3. [Theme]

Actions:
1. [Action] — Owner — Due date
2. [Action] — Owner — Due date
3. [Action] — Owner — Due date
```

---

# 13. Platform Operations

## 13.1 Local Development Startup

Terminal 1:

```bash
npm run dev
```

Terminal 2:

```bash
npm run inngest:dev
```

Optional Terminal 3:

```bash
npx prisma studio
```

Useful local URLs:

```text
Next.js:
http://localhost:3000

Inngest:
http://localhost:8288

Prisma Studio:
http://localhost:5555
```

---

## 13.2 Required Environment Variables

```dotenv
DATABASE_URL="..."
DIRECT_URL="..."

IP_HASH_SECRET="..."
ADMIN_SESSION_SECRET="..."
ADMIN_PASSWORD="..."

NEXT_PUBLIC_APP_URL="..."

INNGEST_EVENT_KEY=""
INNGEST_SIGNING_KEY=""
INNGEST_DEV="1"

UPSTASH_REDIS_REST_URL=""
UPSTASH_REDIS_REST_TOKEN=""

S3_REGION=""
S3_BUCKET=""
S3_ACCESS_KEY_ID=""
S3_SECRET_ACCESS_KEY=""
S3_ENDPOINT=""
```

---

## 13.3 Production Environment Requirements

```text
[ ] DATABASE_URL uses Neon pooled URL.
[ ] DIRECT_URL uses Neon direct URL.
[ ] INNGEST_DEV is set to 0.
[ ] Inngest keys are configured.
[ ] Upstash Redis is configured.
[ ] S3-compatible storage is configured.
[ ] NEXT_PUBLIC_APP_URL uses final HTTPS domain.
[ ] Admin secret values are strong and unique.
[ ] Reports are private or protected by signed URLs.
```

---

# 14. Monitoring and Alerting

## 14.1 Monitor These Areas

| System | What to Monitor |
|---|---|
| Next.js host | API errors, route failures, latency |
| Inngest | Failed runs, retries, queue backlog |
| Neon | Database connectivity, slow queries, storage |
| Upstash | Rate-limit activity, Redis failures |
| Storage | Upload failures, access errors |
| Admin portal | Login failures, export failures |
| Participant API | `400`, `409`, `429`, `503` trends |

---

## 14.2 Recommended Alerts

```text
[ ] More than 5 feedback API 503 responses in 5 minutes.
[ ] Inngest feedback job failure rate above 2%.
[ ] PDF report generation failure.
[ ] Neon connection failures.
[ ] Storage upload failures.
[ ] Large unexpected spike in 429 rate-limit responses.
[ ] Unexpected administrator login failure spike.
```

---

# 15. Incident Response

## 15.1 Incident Severity

| Severity | Description | Example |
|---|---|---|
| Critical | Participant feedback unavailable during live major event | API or deployment outage |
| High | Submissions accepted but not stored | Inngest or Neon failure |
| Medium | Dashboard or report unavailable | Analytics or storage issue |
| Low | QR download issue or non-critical layout defect | Admin UI issue |

---

## 15.2 Incident Response Steps

```text
1. Identify issue.
2. Record time and affected session.
3. Confirm participant impact.
4. Check application logs.
5. Check Inngest dashboard.
6. Check Neon connectivity.
7. Check rate-limit infrastructure.
8. Apply approved workaround.
9. Communicate status.
10. Document root cause and corrective action.
```

---

## 15.3 Participant-Facing Outage Message

> “The feedback form is temporarily unavailable. Please try again in a few minutes or use the alternative link provided by the facilitator. Thank you for your patience.”

---

## 15.4 Internal Incident Template

```text
Incident Title:
[Short description]

Start Time:
[UTC timestamp]

Affected Event:
[Event name]

Affected Session:
[Session ID]

Impact:
[Participant / Admin / Reporting / Platform]

Observed Behavior:
[Description]

Current Status:
[Investigating / Mitigating / Resolved]

Checks Completed:
[ ] Application logs
[ ] Inngest dashboard
[ ] Neon dashboard
[ ] Upstash dashboard
[ ] Storage configuration
[ ] Participant URL

Workaround:
[Description]

Owner:
[Name]

Next Update:
[UTC timestamp]
```

---

# 16. Backup and Recovery Operations

## 16.1 Required Backup Areas

```text
Neon PostgreSQL data
Prisma migration history
Source code repository
Report object storage
Environment variable inventory
Deployment configuration
Operational documentation
```

---

## 16.2 Recovery Testing

Perform recovery testing at least quarterly.

```text
[ ] Create Neon recovery branch.
[ ] Connect staging app.
[ ] Verify event count.
[ ] Verify session count.
[ ] Verify response count.
[ ] Verify answer count.
[ ] Verify report records.
[ ] Confirm report files can be recovered or regenerated.
[ ] Record recovery duration.
```

---

# 17. Post-Event Review

Within one or two business days:

```text
[ ] Close all completed sessions.
[ ] Generate PDF reports.
[ ] Archive CSV exports securely.
[ ] Review written feedback.
[ ] Identify repeated themes.
[ ] Create improvement actions.
[ ] Assign owners.
[ ] Set due dates.
[ ] Archive or delete reports based on retention policy.
[ ] Remove temporary test sessions.
```

---

# 18. Final Operations Checklist

## Before Event

```text
[ ] Form published.
[ ] Session active.
[ ] QR code tested.
[ ] Typed URL available.
[ ] Participant test submitted.
[ ] Dashboard confirmed.
[ ] CSV confirmed.
[ ] PDF confirmed.
```

## During Event

```text
[ ] QR displayed.
[ ] Fallback URL displayed.
[ ] Dashboard monitored.
[ ] Technical operator available.
[ ] Inngest monitored if required.
```

## After Event

```text
[ ] Session closed.
[ ] Analytics reviewed.
[ ] CSV exported.
[ ] PDF generated.
[ ] Improvement actions documented.
[ ] Retention policy applied.
```

---

# 19. Final Operational Principle

GreyMatter Feedback should be operationally simple for participants and controlled for administrators.

```text
Participants:
Scan → Answer → Submit → Leave

Operators:
Prepare → Publish → Monitor → Close → Report → Improve
```
