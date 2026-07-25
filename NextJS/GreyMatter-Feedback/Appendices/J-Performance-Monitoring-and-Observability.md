# Appendix J: Performance, Monitoring, and Observability

GreyMatter Feedback is designed for moments when many people may open the same QR-code link at once.

For example:

```text
A presenter displays a QR code
        ↓
200 participants scan it within one minute
        ↓
Many phones load the same feedback form
        ↓
Participants submit responses near the same time
```

The application must remain fast, understandable, and observable.

**Observability** means being able to understand what the system is doing by looking at logs, metrics, traces, dashboards, and alerts.

This appendix explains how to monitor GreyMatter Feedback, identify slow areas, and prepare for response spikes.

---

## J.1 Performance goals

Use measurable goals rather than vague goals such as:

```text
The application should feel fast.
```

Recommended goals for GreyMatter Feedback:

| Area | Target |
|---|---|
| Participant form initial load | Under 1 second on a typical 4G connection |
| First Contentful Paint | Under 0.8 seconds where possible |
| Rating or choice selection | Under 16 milliseconds of visible UI delay |
| API acceptance response | Under 500 milliseconds under normal conditions |
| Feedback persistence | Background processing through Inngest |
| Admin dashboard refresh | New response visible within 15 seconds |
| PDF report generation | Usually under 30 seconds for moderate response volume |

The exact result depends on:

- User location.
- Deployment region.
- Neon database region.
- Number of responses.
- Form complexity.
- Network quality.
- Object storage provider.
- Inngest queue activity.

---

## J.2 Keep participant pages lightweight

The participant route is the most important page for performance:

```text
/e/[sessionId]
```

A participant should not download administrator features such as:

```text
Analytics charts
PDF report components
QR download library
CSV export logic
Admin form editor
```

GreyMatter Feedback naturally supports this separation because Next.js App Router creates route-level bundles.

Participant code should focus on:

```text
Session title
Question configuration
Question controls
Draft persistence
Validation
Submission
```

Admin-only code should stay in:

```text
src/app/(admin)/admin/
src/components/admin/
```

Do not import admin components into participant pages.

---

## J.3 Use Server Components for database reads

The participant page loads session configuration from Neon in a Server Component.

```tsx
export default async function ParticipantSessionPage({
  params,
}: ParticipantSessionPageProps) {
  const { sessionId } = await params;
  const state = await getParticipantSession(sessionId);

  // Render participant UI.
}
```

This is efficient because:

```text
Database query happens on server
        ↓
Only safe form data is sent to browser
        ↓
Database credentials remain private
        ↓
Browser receives rendered HTML quickly
```

Avoid sending unnecessary database fields to the participant browser.

Do not send:

```text
Response records
Admin report URLs
Internal metadata
IP hashes
Other sessions
Draft form versions
```

---

## J.4 Monitor the participant submission funnel

The participant submission funnel is:

```text
Participant opens form
        ↓
Participant completes answers
        ↓
POST /api/feedback
        ↓
202 Accepted
        ↓
Inngest function runs
        ↓
Response saved in Neon
```

Useful metrics include:

| Metric | Why it matters |
|---|---|
| Participant page views | Indicates QR scan activity |
| Submission attempts | Indicates form completion intent |
| `202 Accepted` count | Indicates submissions accepted by API |
| `400` count | May indicate validation problems |
| `409` count | May indicate forms changed while participants were responding |
| `429` count | Indicates rate limiting or possible spam |
| `503` count | Indicates Inngest or dependency availability problem |
| Inngest success rate | Indicates background workflow reliability |
| Inngest retry count | Indicates temporary infrastructure trouble |
| Response records created | Indicates confirmed persisted feedback |

A useful operational comparison is:

```text
API accepted submissions
versus
Saved Neon responses
```

These values should usually converge after Inngest processing finishes.

If they do not, investigate failed Inngest runs.

---

## J.5 Add structured application logs

A structured log is a log entry with predictable named fields.

Avoid vague logs like:

```ts
console.log("Something happened");
```

Prefer:

```ts
console.info("Feedback submission processed.", {
  submissionId: event.data.submissionId,
  responseId: saveResult.responseId,
  sessionId: event.data.sessionId,
  duplicate: saveResult.duplicate,
});
```

Useful structured fields include:

```text
sessionId
formVersionId
submissionId
responseId
reportId
eventName
status
durationMilliseconds
errorCode
```

Avoid logging:

```text
Raw participant answers
Text comments
Raw IP addresses
Database URLs
Authorization headers
Session cookies
Administrator passwords
```

---

## J.6 Add request timing for feedback submissions

A response-time log helps identify slow API behavior.

Create a timer around key server operations.

### `src/app/api/feedback/route.ts`

A future enhancement can add timing like this:

```ts
const startedAt = performance.now();

try {
  // Validate request, rate limit, validate form, send Inngest event.
} finally {
  console.info("Feedback API request completed.", {
    durationMilliseconds: Math.round(performance.now() - startedAt),
    sessionId: parsedSubmission.data.sessionId,
  });
}
```

A more complete safe pattern is:

```ts
const startedAt = performance.now();
let statusCode = 500;
let sessionId: string | undefined;

try {
  // Parse and validate request.
  sessionId = parsedSubmission.data.sessionId;

  // Perform request work.
  statusCode = 202;

  return NextResponse.json(
    {
      accepted: true,
      submissionId: eventData.submissionId,
    },
    {
      status: statusCode,
    },
  );
} catch (error) {
  console.error("Unexpected feedback API error.", {
    error: error instanceof Error ? error.message : "Unknown error",
    sessionId,
  });

  return NextResponse.json(
    {
      error: "We could not accept your feedback right now.",
    },
    {
      status: statusCode,
    },
  );
} finally {
  console.info("Feedback API request completed.", {
    durationMilliseconds: Math.round(performance.now() - startedAt),
    sessionId,
    statusCode,
  });
}
```

Do not add raw request bodies to the log.

---

## J.7 Monitor Inngest functions

Inngest provides function-level visibility for:

```text
process-feedback-submission
generate-pdf-report
```

Monitor:

```text
Run status
Step status
Retries
Duration
Failure reason
Concurrency
Queue backlog
```

### Submission worker health

For:

```text
process-feedback-submission
```

watch for:

```text
Increasing failures
Repeated retries
Long save-response-and-answers durations
Unexpected duplicate rates
Queue backlog after a session ends
```

### PDF worker health

For:

```text
generate-pdf-report
```

watch for:

```text
Long render times
Storage upload failures
Repeated report failures
Reports stuck in PROCESSING
High report queue depth
```

A report that remains in `PROCESSING` for an unusually long time may indicate:

- A stalled function run.
- A PDF rendering issue.
- Storage provider timeout.
- Insufficient function timeout.
- A query processing too much response data.

---

## J.8 Monitor Neon PostgreSQL

Neon provides database monitoring and query insights.

Watch for:

```text
Connection errors
Slow queries
High database CPU
High read volume
High write volume
Unexpected connection counts
Storage growth
```

The most important queries in GreyMatter Feedback are:

```text
Load active participant form
Validate form on submission
Save response and answers
Load analytics dashboard
Export CSV
Generate PDF analytics
```

As response volume grows, the analytics query is likely to become more expensive because it reads many answers.

Use PostgreSQL query analysis before optimizing.

Example:

```sql
EXPLAIN ANALYZE
SELECT
  responses.id,
  responses.submitted_at
FROM responses
WHERE responses.session_id = 'REACT-2026-Q3'
ORDER BY responses.submitted_at DESC;
```

Run query analysis only with care and preferably against a non-production environment when testing complex queries.

---

## J.9 Database connection management

Serverless applications may create many short-lived processes. If each process creates too many direct database connections, the database can become overloaded.

GreyMatter Feedback uses:

```dotenv
DATABASE_URL="pooled Neon connection string"
DIRECT_URL="direct Neon connection string"
```

Use them correctly:

| Variable | Use |
|---|---|
| `DATABASE_URL` | Running Next.js application through Neon pooler |
| `DIRECT_URL` | Prisma migrations and schema management |

The reusable Prisma client also prevents unnecessary connections during Next.js development reloads:

```ts
const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient();
```

Do not create a new `PrismaClient` inside every route handler.

Avoid this:

```ts
export async function POST() {
  const prisma = new PrismaClient();

  // This creates unnecessary clients.
}
```

Prefer the shared client:

```ts
import { prisma } from "@/lib/prisma";
```

---

## J.10 Dashboard refresh trade-offs

The admin dashboard refreshes every 15 seconds:

```tsx
setInterval(() => {
  router.refresh();
}, 15_000);
```

This is appropriate for many event dashboards.

Advantages:

```text
Simple
Reliable
No persistent websocket connection
Works well with server-rendered data
Easy to understand
```

Trade-offs:

```text
Each open dashboard performs a query every 15 seconds.
Many simultaneous administrators increase database reads.
Updates are not instant.
```

For example:

```text
10 dashboard viewers
× 4 refreshes per minute
= 40 dashboard refreshes per minute
```

That is usually manageable for small deployments.

For larger deployments, consider:

```text
Longer refresh interval
Manual refresh control
Conditional refresh only when tab is visible
Server-sent events
WebSocket provider
Cached analytics summary
```

A simple visibility-aware improvement:

```tsx
useEffect(() => {
  const intervalId = window.setInterval(() => {
    if (document.visibilityState === "visible") {
      router.refresh();
    }
  }, 15_000);

  return () => window.clearInterval(intervalId);
}, [router]);
```

This avoids refreshing dashboards in hidden browser tabs.

---

## J.11 Add error monitoring

Console logs are useful, but production applications need centralized error monitoring.

Common providers include:

```text
Sentry
Axiom
Better Stack
Datadog
New Relic
OpenTelemetry-compatible platforms
```

An error-monitoring service should capture:

```text
Unhandled server errors
API failures
Inngest function failures
Slow requests
Deployment versions
Environment name
Safe request context
```

It should not capture:

```text
Participant answer text
Raw IP addresses
Authorization headers
Cookies
Database URLs
Administrator passwords
```

### Recommended error metadata

For feedback API errors:

```text
Route: /api/feedback
Session ID
Form version ID
HTTP status
Error category
Deployment version
```

For report generation errors:

```text
Report ID
Session ID
Report status
Storage provider type
Inngest run ID
```

---

## J.12 Define alert thresholds

An alert should indicate something requiring attention.

Avoid alerting on every minor error. Too many alerts create alert fatigue.

Recommended initial alerts:

| Condition | Suggested alert |
|---|---|
| Feedback API `503` rate spikes | Alert technical operator |
| Inngest submission failure rate above 2% | Alert technical operator |
| PDF report failures | Alert administrator or technical operator |
| Inngest queue backlog above expected event volume | Alert technical operator |
| Neon connection failures | Alert technical operator |
| Database storage close to provider limit | Alert platform owner |
| Administrator login failures spike | Alert security owner |

Example rule:

```text
Alert when more than 5 feedback API 503 errors occur within 5 minutes.
```

Another example:

```text
Alert when generate-pdf-report fails 2 times in 15 minutes.
```

---

## J.13 Performance testing before a large event

Before a major event, simulate expected traffic.

For example:

```text
Expected attendees: 500
Expected scan window: 10 minutes
Expected peak: 100 concurrent participants
```

Test:

```text
Participant page loading
Feedback API requests
Inngest queue processing
Neon write throughput
Dashboard query performance
```

Useful load-testing tools include:

```text
k6
Artillery
Apache JMeter
Locust
```

A simplified k6 example for a public participant page:

### `load-tests/participant-page.js`

```js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 20,
  duration: "30s",
};

export default function () {
  const response = http.get(
    "https://feedback.your-domain.example/e/REACT-2026-Q3?src=load-test",
  );

  check(response, {
    "participant page returns 200": (result) => result.status === 200,
  });

  sleep(1);
}
```

Run:

```bash
k6 run load-tests/participant-page.js
```

Do not run aggressive load tests against production without approval. Test against staging or a dedicated Neon branch.

---

## J.14 Caching guidance

Do not cache participant form data carelessly.

A published form may change when an administrator publishes a new version. The participant route should reflect the active version promptly.

Safe caching guidance:

| Resource | Recommended behavior |
|---|---|
| Participant session page | Dynamic server rendering or short controlled revalidation |
| Admin dashboard | Dynamic, no stale sensitive data |
| CSV export | `Cache-Control: no-store` |
| Report status API | `Cache-Control: no-store` |
| QR-code image in admin browser | Local component state |
| Static assets | Browser and CDN caching |
| PDF report | Private storage or protected signed URL |

The tutorial uses dynamic rendering for the dashboard:

```ts
export const dynamic = "force-dynamic";
```

This prevents stale analytics being served from a static build.

---

## J.15 Keep PDF reports bounded

PDF reports can become slow if they include thousands of written comments.

A report with:

```text
20 comments
```

is manageable.

A report with:

```text
50,000 comments
```

may produce a huge PDF, exceed runtime limits, and be difficult for an administrator to read.

Set a practical report limit.

For example, include:

```text
All numeric distributions
All choice distributions
First 200 written comments
Comment count summary
CSV export link for full raw data
```

A future report query can limit comments:

```ts
const comments = question.comments.slice(0, 200);
```

Then include a PDF note:

```text
Showing the first 200 comments. Export CSV for all responses.
```

This protects performance and produces a more usable report.

---

## J.16 Operational metrics dashboard

A future internal technical dashboard can show:

```text
Feedback submissions accepted in last hour
Inngest submission success rate
Inngest queue depth
Average feedback API duration
Average report generation duration
Rate-limited requests
Neon query errors
Latest deployment version
```

This is separate from the event organizer dashboard.

Organizer dashboard:

```text
Response count
Ratings
NPS
Comments
Reports
```

Technical operations dashboard:

```text
System health
Errors
Latency
Queues
Dependencies
```

Keeping these separate prevents technical implementation details from confusing event administrators.

---

## J.17 Performance optimization order

When the application feels slow, do not optimize randomly.

Use this order:

```text
1. Measure the slow operation.
2. Identify whether it is browser, network, server, database, queue, or storage.
3. Fix the largest measured bottleneck.
4. Test again.
5. Repeat only if needed.
```

Examples:

| Symptom | Likely first investigation |
|---|---|
| Participant page loads slowly | Route server timing, Neon query, deployment region |
| Submit button waits too long | Feedback API timing, rate-limit provider, Inngest send |
| Dashboard is slow | Analytics query volume and indexes |
| PDF reports fail or time out | Comment volume, PDF render time, storage latency |
| Many `429` responses | Rate-limit policy and identity handling |
| Many `409` responses | Form publishing process during active sessions |

Avoid premature complexity such as aggregate tables, websockets, or custom caching until measurement shows they are necessary.

---

## J.18 Final observability checklist

Before a live production event, verify:

```text
[ ] Next.js host provides request logs.
[ ] Inngest dashboard is accessible to technical operators.
[ ] Neon dashboard is accessible to platform owners.
[ ] Error monitoring is configured.
[ ] Alerts exist for submission and report failures.
[ ] Logs exclude participant text and raw identifiers.
[ ] Rate-limit activity can be monitored.
[ ] Dashboard refresh behavior is understood.
[ ] PDF generation has a timeout and failure path.
[ ] A technical operator knows where to investigate failures.
[ ] A staging environment exists for safe performance testing.
```

Fast software is important. Observable software is what allows a team to keep it fast and reliable when real participants begin scanning QR codes at the same time.
