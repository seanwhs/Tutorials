# GreyMatter Feedback Release Notes

## Version 1.0.0

**Release Type:** Initial Production Release  
**Release Status:** General Availability  
**Product:** GreyMatter Feedback  
**Release Date:** 2026-07-25

---

## Overview

GreyMatter Feedback 1.0.0 introduces a complete QR-code feedback platform for events, workshops, courses, conferences, and training sessions.

Administrators can create session-specific feedback forms, publish versioned forms, generate QR codes, monitor analytics, export CSV data, and request PDF reports.

Participants can scan a QR code, complete a mobile-friendly form, save local drafts, and submit anonymous feedback without creating an account.

---

# New Features

## Participant Feedback Experience

### QR-first participant access

Participants can access feedback forms through session-specific URLs:

```text
/e/[sessionId]
```

Example:

```text
/e/REACT-2026-Q3?src=qr
```

### Mobile-first feedback forms

Participant forms support:

```text
Rating questions
NPS questions
Choice questions
Written feedback questions
```

Participant experience includes:

```text
Large touch targets
Responsive layouts
Required-field validation
Clear selected states
Mobile-friendly text inputs
Optional haptic feedback on supported devices
```

### Local draft persistence

Unfinished participant answers are saved in browser localStorage.

Participants can:

```text
Refresh page without losing answers
Return to unfinished feedback later
Discard saved draft manually
```

### Offline submission outbox

If the browser cannot reach the feedback API:

```text
Completed submission is saved locally
Submission retries when device reconnects
Stable submission ID prevents duplicate responses
```

---

## Form Authoring

### Events and courses

Administrators can create parent containers for:

```text
Courses
Conferences
Workshops
Training programs
Internal events
```

### Sessions

Administrators can create individual feedback sessions with readable QR-friendly IDs.

Example:

```text
Session title:
Advanced React Patterns

Session ID:
REACT-2026-Q3
```

### Versioned forms

Forms support the following lifecycle:

```text
DRAFT
PUBLISHED
ARCHIVED
```

Administrators can:

```text
Create draft forms
Clone an existing form into a new draft
Add questions
Delete questions
Reorder questions
Preview participant form
Publish a form version
Close or reopen feedback sessions
```

### Historical reporting protection

Every participant response stores the exact form version used at submission time.

This ensures that:

```text
Published questions remain historically accurate
New form versions do not alter old reports
Analytics preserve original question wording and options
```

---

## Security and Privacy

### Server-side validation

Participant submissions are validated against:

```text
Session status
Published form version
Question ownership
Question type
Rating range
NPS range
Choice options
Text length
Required question rules
```

### Rate limiting

The platform supports:

```text
Per-client, per-session submission limits
Per-session submission safety limits
Upstash Redis distributed rate limiting in production
In-memory development fallback
```

### Privacy-aware IP handling

GreyMatter Feedback does not store raw IP addresses.

Instead, it stores a daily salted SHA-256 hash used for rate limiting and abuse prevention.

### Administrator sessions

Administrator access uses:

```text
Signed session tokens
HTTP-only cookies
SameSite=Lax cookies
Secure cookies in production
Session expiration
```

---

## Background Processing

### Inngest feedback processing

Participant submissions use the event:

```text
feedback/submitted
```

The background worker:

```text
Saves Response records
Saves Answer records
Retries temporary failures
Prevents duplicate responses
```

### Idempotent submissions

Each participant draft uses a stable submission ID.

This protects against duplicate persistence when:

```text
Network requests retry
Inngest jobs replay
Participant retries after connection interruption
```

---

## Analytics Dashboard

Administrators can view session analytics at:

```text
/admin/sessions/[sessionId]
```

Dashboard features include:

```text
Total response count
Average rating
NPS score
Promoter, passive, and detractor counts
Rating score distributions
Choice option distributions
Written feedback comments
Latest submission time
Automatic dashboard refresh
```

---

## QR Code Support

Administrators can:

```text
Generate QR code from participant session URL
Download QR code as PNG
Copy participant URL
Use QR code in slides, posters, handouts, and event signage
```

---

## CSV Export

Administrators can download answer-level CSV exports.

Exports include:

```text
Event
Session ID
Session title
Response ID
Submission timestamp
Form version
Question text
Question type
Numeric answer
Text answer
```

Security improvements include:

```text
Admin authentication required
No-store cache headers
CSV escaping
Spreadsheet formula injection mitigation
No raw IP hashes in standard export
No user-agent metadata in standard export
```

---

## PDF Reports

Administrators can request asynchronous PDF executive reports.

Report states:

```text
QUEUED
PROCESSING
COMPLETE
FAILED
```

Reports include:

```text
Event and session information
Total response count
Average rating
NPS
Rating distributions
Choice distributions
Written feedback
Report generation timestamp
```

Development storage:

```text
public/reports
```

Production storage:

```text
S3-compatible storage
Amazon S3
Cloudflare R2
Backblaze B2
MinIO
Other compatible providers
```

---

# Technical Stack

```text
Next.js 16
React 19
TypeScript
Tailwind CSS
Neon PostgreSQL
Prisma
Inngest
Zod
Upstash Redis
QRCode
React PDF
S3-compatible object storage
Vitest
```

---

# Key Routes

| Route | Purpose |
|---|---|
| `/` | GreyMatter Feedback landing page |
| `/e/[sessionId]` | Public participant feedback form |
| `/admin/login` | Administrator sign-in |
| `/admin/events` | Event and course management |
| `/admin/events/[eventId]` | Session management |
| `/admin/sessions/[sessionId]/edit` | Form authoring |
| `/admin/sessions/[sessionId]` | Analytics dashboard |
| `POST /api/feedback` | Participant feedback submission |
| `/api/inngest` | Inngest integration endpoint |
| `/api/admin/export/[sessionId]` | CSV export |
| `/api/admin/reports/[sessionId]` | PDF report management |

---

# Database Model

GreyMatter Feedback 1.0.0 includes:

```text
Event
  └── Session
        ├── FormVersion
        │     └── Question
        │
        ├── Response
        │     └── Answer
        │
        └── Report
```

Core integrity features:

```text
Unique session IDs
Unique form version numbers per session
Unique question order per form version
Unique submission event IDs
One answer per response per question
Form-version-linked responses
```

---

# Known Limitations

## Single shared administrator password

Version 1.0.0 uses one administrator password configured through:

```dotenv
ADMIN_PASSWORD
```

Recommended future enhancement:

```text
Named administrator accounts
Password hashing
Multi-factor authentication
Role-based access control
Audit logging
```

---

## Basic local development rate limiting

Without Upstash Redis configured, local development uses an in-memory rate limiter.

This means:

```text
Rate limits reset when Next.js restarts
Local requests may share unknown-client identity
```

Production must use Upstash Redis.

---

## Public report URL risk in simplified storage configuration

Local reports are publicly available through:

```text
/reports/[filename].pdf
```

For production, reports containing written feedback should use:

```text
Private object storage
Authenticated report download endpoint
Short-lived signed URLs
```

---

## Dashboard polling

The dashboard refreshes approximately every 15 seconds.

Version 1.0.0 does not include:

```text
WebSocket-based live updates
Server-sent events
Push notifications
```

---

## Limited advanced authoring

Baseline authoring does not yet include:

```text
Form templates
Question library
Conditional logic
Sections
Question helper text
Reporting tags
Multi-language forms
```

---

# Upgrade Notes

## Required Production Configuration

Before deploying version 1.0.0, configure:

```dotenv
DATABASE_URL
DIRECT_URL
IP_HASH_SECRET
ADMIN_SESSION_SECRET
ADMIN_PASSWORD
NEXT_PUBLIC_APP_URL
INNGEST_EVENT_KEY
INNGEST_SIGNING_KEY
INNGEST_DEV=0
UPSTASH_REDIS_REST_URL
UPSTASH_REDIS_REST_TOKEN
S3_REGION
S3_BUCKET
S3_ACCESS_KEY_ID
S3_SECRET_ACCESS_KEY
S3_ENDPOINT
```

## Required Commands

```bash
npx prisma validate
```

```bash
npx prisma migrate deploy
```

```bash
npx prisma generate
```

```bash
npm test
```

```bash
npm run lint
```

```bash
npm run build
```

---

# Recommended Post-Release Checks

```text
[ ] Participant form opens from production QR URL.
[ ] Participant form works on iPhone and Android.
[ ] Admin login works.
[ ] Session authoring works.
[ ] Form publishing works.
[ ] Feedback submission returns HTTP 202.
[ ] Inngest submission worker succeeds.
[ ] Response and Answer records appear in Neon.
[ ] Dashboard updates.
[ ] CSV export downloads.
[ ] PDF report completes.
[ ] Report download is protected.
[ ] Rate limiting works.
[ ] Monitoring and alerts are active.
```

---

# Planned Future Releases

## Version 1.1

```text
Protected signed PDF downloads
Admin login rate limiting
Report completion email notifications
Improved report download auditability
Data-retention cleanup job
```

## Version 1.2

```text
Form templates
Question library
Question helper text
CSV event/session import
Slack notifications
Enhanced analytics filtering
```

## Version 2.0

```text
Named administrator accounts
Role-based permissions
Multi-factor authentication
Organization tenancy
Audit logs
Organization branding
Multi-organization dashboard
```
