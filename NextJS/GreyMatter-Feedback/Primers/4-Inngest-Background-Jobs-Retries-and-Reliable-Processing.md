# Primer 4: Inngest, Background Jobs, Retries, and Reliable Processing

GreyMatter Feedback needs to perform some work immediately and some work later.

For example, when a participant submits feedback, the application must quickly tell them:

```text
Thank you. Your feedback was received.
```

At the same time, the application may need to:

- Save the response and answers.
- Retry a temporary database failure.
- Update reporting data.
- Generate a PDF report.
- Upload a report to storage.
- Send a notification.

These tasks should not all run while the participant waits on their phone.

GreyMatter Feedback uses **Inngest** to coordinate this background work.

---

## 1. What Is a Background Job?

A background job is work that happens outside the immediate browser request.

Think of a restaurant.

At the counter:

```text
Customer places order.
Cashier confirms the order.
Customer receives confirmation quickly.
```

Behind the counter:

```text
Kitchen prepares food.
Kitchen handles preparation steps.
Kitchen resolves temporary delays.
```

In GreyMatter Feedback:

```text
Participant submits feedback.
API confirms the submission was accepted.
Inngest processes the background work.
```

The participant should not need to wait for the database worker, analytics system, or report-generation process to finish.

---

## 2. Why Not Save Everything Directly in the API Route?

A simple application might save responses directly in:

```text
POST /api/feedback
```

That approach can work for small systems:

```text
Participant submits
   ↓
API writes response to database
   ↓
API writes answers to database
   ↓
API returns success
```

However, it has weaknesses.

### Temporary database failure

```text
Participant submits
   ↓
Neon connection temporarily fails
   ↓
API returns error
   ↓
Participant may need to submit again
```

### Slow operations

```text
Participant submits
   ↓
Database is slow
   ↓
Browser waits
   ↓
Participant wonders whether submission worked
```

### Heavy report generation

```text
Administrator requests PDF
   ↓
Browser waits while report renders
   ↓
Browser waits while file uploads
   ↓
Request may time out
```

A background job system separates quick acceptance from slower processing.

---

## 3. The GreyMatter Feedback Submission Flow

The participant submission flow is:

```text
Participant browser
        ↓
POST /api/feedback
        ↓
Validate request shape with Zod
        ↓
Validate session, form version, and answers
        ↓
Hash IP address
        ↓
Check rate limit
        ↓
Send feedback/submitted event to Inngest
        ↓
Return 202 Accepted to participant
        ↓
Inngest saves Response and Answer records in Neon
```

The key response is:

```http
HTTP/1.1 202 Accepted
```

`202 Accepted` means:

> “The server accepted this request for asynchronous processing.”

It does not necessarily mean every background step has completed already.

---

## 4. What Is an Event?

An event is a named message that says something happened.

GreyMatter Feedback uses events such as:

```text
feedback/submitted
report/generate.pdf
```

A feedback event contains structured information.

Example:

```ts
{
  name: "feedback/submitted",
  data: {
    submissionId: "6b9f6b86-8fc0-4e54-b064-2b60b848ac31",
    sessionId: "REACT-2026-Q3",
    formVersionId: "c39c3d46-3d35-4c25-b889-80e437f526e4",
    clientIpHash: "8e785da3b7105e13a10e99a0f51d1979...",
    metadata: {
      source: "qr",
      screenWidth: 390,
      screenHeight: 844,
      userAgent: "Mozilla/5.0 ..."
    },
    answers: [
      {
        questionId: "dc3ad31c-fd95-49ec-a8c8-0d6ef363be10",
        numericValue: 5,
        textValue: null
      }
    ]
  }
}
```

The event does not contain database credentials or participant browser secrets.

---

## 5. The Inngest Client

The Inngest client defines the application’s event contract.

### `src/inngest/client.ts`

```ts
import { Inngest } from "inngest";
import type { FeedbackSubmissionEventData } from "@/lib/feedback-submission";

type GreyMatterEvents = {
  "feedback/submitted": {
    data: FeedbackSubmissionEventData;
  };

  "report/generate.pdf": {
    data: {
      reportId: string;
      sessionId: string;
      requestedBy: string;
    };
  };
};

export const inngest = new Inngest({
  id: "greymatter-feedback",
  eventKey: process.env.INNGEST_EVENT_KEY || undefined,
  signingKey: process.env.INNGEST_SIGNING_KEY || undefined,
  schemas: new Inngest.EventSchemas().fromRecord<GreyMatterEvents>(),
});
```

This file provides two important benefits.

### Typed event data

TypeScript can catch mistakes.

For example, this is valid:

```ts
await inngest.send({
  name: "feedback/submitted",
  data: {
    submissionId,
    sessionId,
    formVersionId,
    clientIpHash,
    metadata,
    answers,
  },
});
```

But this should fail TypeScript checking because the event name is wrong:

```ts
await inngest.send({
  name: "feedback.submit",
  data: {},
});
```

### One place for event definitions

All background event names are documented in one file.

That helps prevent mismatches such as:

```text
API sends:
feedback-submitted

Worker listens for:
feedback/submitted
```

Those are different names. A typed event contract makes this kind of error easier to catch.

---

## 6. Inngest Functions

An Inngest function listens for an event and performs work.

GreyMatter Feedback has a feedback-processing function.

### `src/inngest/functions/process-feedback-submission.ts`

```ts
import { inngest } from "@/inngest/client";
import { saveFeedbackResponse } from "@/lib/save-feedback-response";

export const processFeedbackSubmission = inngest.createFunction(
  {
    id: "process-feedback-submission",
    retries: 3,
    concurrency: 10,
  },
  {
    event: "feedback/submitted",
  },
  async ({ event, step }) => {
    const saveResult = await step.run("save-response-and-answers", async () => {
      return saveFeedbackResponse(event.data);
    });

    await step.run("record-processing-complete", async () => {
      console.info("GreyMatter feedback submission processed.", {
        submissionId: event.data.submissionId,
        responseId: saveResult.responseId,
        duplicate: saveResult.duplicate,
        sessionId: event.data.sessionId,
      });

      return {
        processed: true,
      };
    });

    return {
      status: saveResult.duplicate ? "duplicate" : "saved",
      responseId: saveResult.responseId,
    };
  },
);
```

The important parts are:

| Option or value | Meaning |
|---|---|
| `id` | Stable unique name for the function |
| `retries: 3` | Inngest can retry temporary failures |
| `concurrency: 10` | Up to ten jobs can process concurrently |
| `event` | Event name that triggers the function |
| `step.run()` | Named, tracked background operation |

---

## 7. Why `step.run()` Matters

Inngest steps divide a larger workflow into meaningful units.

Example:

```text
generate-and-store-pdf-report
record-report-completion
```

For feedback submissions:

```text
save-response-and-answers
record-processing-complete
```

This is useful because Inngest can show each step in its dashboard.

```text
Function run
├── save-response-and-answers      ✓
└── record-processing-complete     ✓
```

If a step fails:

```text
Function run
├── save-response-and-answers      ✗
└── record-processing-complete     not started
```

This makes failures easier to diagnose.

---

## 8. Retries

A retry is another attempt after a temporary failure.

Temporary failures happen in normal distributed systems:

```text
Database network timeout
Cloud provider maintenance
Object-storage temporary failure
DNS issue
Inngest delivery interruption
Function runtime restart
```

Without retries:

```text
Temporary problem
   ↓
Participant response is lost
```

With retries:

```text
Temporary problem
   ↓
Inngest retries background step
   ↓
Operation succeeds later
```

GreyMatter Feedback configures:

```ts
retries: 3
```

This means Inngest may attempt the function again after a failure.

---

## 9. Why Retries Can Create Duplicates

Retries are useful, but they create a risk.

Imagine this sequence:

```text
Worker begins database write
        ↓
Database creates response successfully
        ↓
Worker loses connection before receiving confirmation
        ↓
Inngest retries worker
        ↓
Worker tries to create same response again
```

If the application is not designed carefully, one participant submission could become two responses.

GreyMatter Feedback prevents this through **idempotency**.

---

## 10. Idempotency

An operation is **idempotent** when running it multiple times produces the same final result as running it once.

For feedback submission:

```text
Same submission ID processed once
        ↓
One response exists

Same submission ID processed five times
        ↓
Still one response exists
```

GreyMatter Feedback uses a stable `submissionId`.

```text
Browser draft
  └── submissionId

API request
  └── submissionId

Inngest event
  └── submissionId

Neon Response.eventId
  └── submissionId
```

The database schema requires `eventId` to be unique:

```prisma
model Response {
  id      String @id @default(uuid()) @db.Uuid
  eventId String @unique @map("event_id") @db.VarChar(128)

  // Other fields omitted.
}
```

That database rule is the final safety net.

---

## 11. Idempotent Response Saving

The response persistence helper first checks whether the submission already exists.

### `src/lib/save-feedback-response.ts`

```ts
const existingResponse = await prisma.response.findUnique({
  where: {
    eventId: submission.submissionId,
  },
  select: {
    id: true,
  },
});

if (existingResponse) {
  return {
    responseId: existingResponse.id,
    duplicate: true,
  };
}
```

If no response exists, it creates one.

```ts
const response = await prisma.response.create({
  data: {
    eventId: submission.submissionId,
    sessionId: submission.sessionId,
    formVersionId: submission.formVersionId,
    clientIpHash: submission.clientIpHash,
    metadata: submission.metadata,
    answers: {
      create: submission.answers.map((answer) => ({
        questionId: answer.questionId,
        numericValue: answer.numericValue,
        textValue: answer.textValue,
      })),
    },
  },
});
```

A race can still happen if two workers check at nearly the same moment. That is why the database unique constraint remains necessary.

If Prisma reports a unique constraint error, the helper performs another lookup and treats the result as a duplicate instead of a failure.

---

## 12. Concurrency

**Concurrency** means more than one background job can run at the same time.

GreyMatter Feedback sets:

```ts
concurrency: 10
```

for feedback processing.

That means up to ten feedback submissions can be processed simultaneously by the function.

This helps when many participants submit at once:

```text
100 participants submit after a keynote
        ↓
Jobs enter queue
        ↓
Up to 10 process concurrently
        ↓
Remaining jobs wait briefly
        ↓
All jobs eventually complete
```

More concurrency is not always better.

Too much concurrency can overload:

```text
Neon database
Object storage
External APIs
Email providers
```

Choose limits based on real traffic and monitoring.

---

## 13. Why PDF Generation Uses Lower Concurrency

PDF generation is heavier than response storage.

It may:

```text
Load analytics
Render document layout
Create PDF buffer
Upload file
Update report record
```

GreyMatter Feedback uses lower concurrency:

```ts
concurrency: 2
```

for report generation.

This reduces the chance that many simultaneous reports consume too much memory or overload storage.

```text
Many PDF requests
        ↓
Two reports generate at once
        ↓
Others wait in queue
        ↓
System remains stable
```

---

## 14. Local Inngest Development

During local development, GreyMatter Feedback runs two processes.

Terminal one:

```bash
npm run dev
```

This starts Next.js:

```text
http://localhost:3000
```

Terminal two:

```bash
npm run inngest:dev
```

This starts the Inngest Dev Server:

```text
http://localhost:8288
```

The local integration looks like this:

```text
Next.js application
  http://localhost:3000
        ↓
Inngest endpoint
  http://localhost:3000/api/inngest
        ↓
Inngest Dev Server
  http://localhost:8288
```

Open the Inngest dashboard:

```text
http://localhost:8288
```

You should see registered functions:

```text
process-feedback-submission
generate-pdf-report
```

---

## 15. The Inngest Endpoint

The application exposes registered functions through:

```text
/api/inngest
```

### `src/app/api/inngest/route.ts`

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { inngestFunctions } from "@/inngest/functions";

export const runtime = "nodejs";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: inngestFunctions,
});
```

This route lets Inngest:

```text
Discover available functions
Verify function definitions
Invoke functions
Deliver events
Track function runs
```

It is not a regular participant-facing endpoint.

---

## 16. Inngest Function Registration

GreyMatter Feedback exports functions from one central index.

### `src/inngest/functions/index.ts`

```ts
import { generatePdfReport } from "./generate-pdf-report";
import { processFeedbackSubmission } from "./process-feedback-submission";

export const inngestFunctions = [
  processFeedbackSubmission,
  generatePdfReport,
];
```

When you add a new function, do both:

```text
1. Create function file.
2. Add function to inngestFunctions array.
```

If you forget the second step, Inngest cannot discover the function.

---

## 17. Report Generation Workflow

The PDF report flow is:

```text
Administrator clicks Generate PDF report
        ↓
POST /api/admin/reports/[sessionId]
        ↓
Create Report record with QUEUED status
        ↓
Send report/generate.pdf event
        ↓
Inngest starts generate-pdf-report
        ↓
Report record becomes PROCESSING
        ↓
Load session analytics
        ↓
Render PDF
        ↓
Store file
        ↓
Report record becomes COMPLETE
        ↓
Admin dashboard displays download link
```

The database report record acts like a work order.

```text
Report status:
QUEUED
PROCESSING
COMPLETE
FAILED
```

The administrator does not need to keep the browser tab open for the report worker to continue.

---

## 18. Handling Background Failures

A background job can fail for many reasons.

```text
Neon unavailable
Storage upload rejected
PDF rendering error
Invalid report record
Temporary network interruption
Provider timeout
```

A good background workflow should:

```text
Retry temporary failures
Record useful safe errors
Avoid duplicate writes
Expose status to administrators
Avoid exposing secrets to users
```

The report generator updates the report record on failure:

```ts
await prisma.report.update({
  where: {
    id: report.id,
  },
  data: {
    status: ReportStatus.FAILED,
    error: message,
  },
});
```

The admin report panel then displays the failed status.

---

## 19. What Should Run in the Background?

Good background-job candidates are tasks that are:

```text
Slow
Retryable
Not required before immediate browser response
Potentially dependent on external services
Resource-intensive
```

Good GreyMatter Feedback examples:

```text
Save feedback response after API acceptance
Generate PDF report
Upload PDF report
Send report-ready email
Send Slack notification
Export large data file
Clean old IP hashes
Generate scheduled daily summary
Import event schedule from external service
Deliver signed webhooks
```

Poor background-job candidates:

```text
Render the participant form
Show validation error for missing required field
Select a rating button
Save local browser draft
Display a currently loaded dashboard card
```

Those actions need immediate browser feedback.

---

## 20. Event Payload Design Rules

Keep background event data focused and safe.

Good event data:

```text
Submission ID
Session ID
Form version ID
Question IDs
Validated answer values
Safe metadata
Report ID
Requested-by identifier
```

Avoid event data containing:

```text
Database connection strings
Admin session cookies
Raw request headers
Raw IP addresses
Secrets
Large binary files
Unnecessary full database records
```

A useful rule:

> Put identifiers and validated business data into events, not credentials or oversized documents.

---

## 21. Primer Summary

The background-job model is:

```text
Fast browser request
        ↓
Validated event
        ↓
Reliable Inngest workflow
        ↓
Retry-safe Neon persistence or report generation
```

The most important concepts are:

```text
Event
  = named message that something happened

Inngest function
  = worker triggered by an event

step.run()
  = tracked, retryable workflow step

Retry
  = another attempt after temporary failure

Idempotency
  = repeated processing creates one final result

submissionId
  = stable receipt number used to prevent duplicates

Concurrency
  = number of jobs allowed to run at the same time
```

For GreyMatter Feedback, Inngest keeps participant submission fast while ensuring response persistence and report generation remain reliable—even when temporary failures occur.
