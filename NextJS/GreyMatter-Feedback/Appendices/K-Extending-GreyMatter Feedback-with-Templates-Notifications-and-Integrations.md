# Appendix K: Extending GreyMatter Feedback with Templates, Notifications, and Integrations

The core GreyMatter Feedback application supports custom, versioned forms for every session.

As usage grows, organizations often need additional workflow features:

- Reusable feedback form templates.
- Automatic email or Slack notifications.
- Scheduled reporting.
- Integration with learning-management systems.
- Webhooks for external analytics tools.
- Importing event and course schedules.
- Branded forms per organization.

This appendix explains how to add those features without weakening the core design:

```text
Neon + Prisma remains the source of truth
        ↓
Versioned session forms remain immutable after publication
        ↓
Inngest handles asynchronous integrations
```

---

## K.1 Recommended extension principle

When adding a feature, preserve these rules:

```text
[ ] Participant submission remains fast.
[ ] Form versions remain historically accurate.
[ ] External systems do not become required for participant page rendering.
[ ] Integrations run asynchronously when possible.
[ ] Every outbound integration is retry-safe.
[ ] Secrets stay in environment variables.
[ ] Organization boundaries remain enforced in multi-tenant deployments.
```

For example, do not make participant form loading depend on an external learning-management system:

```text
Participant opens QR URL
        ↓
Wait for external LMS API
        ↓
Render feedback form
```

That creates an unnecessary point of failure.

Prefer:

```text
Administrator imports course data
        ↓
GreyMatter stores required session data in Neon
        ↓
Participant page loads directly from Neon
```

---

# K.2 Reusable form templates

A form template is a reusable starting point for new sessions.

For example, an organization may repeatedly use:

```text
Standard workshop feedback
Standard course module feedback
End-of-course evaluation
Conference talk feedback
Instructor evaluation
```

Instead of creating the same questions manually every time, an administrator selects a template.

```text
Choose template
        ↓
Copy template questions into a new session draft
        ↓
Customize draft if needed
        ↓
Publish session-specific form version
```

The important distinction is:

> A template is not the live participant form.

A template only creates a starting draft. Once copied into a session, the session form is independent.

---

## K.3 Template data model

A future schema can add these models.

### `prisma/schema.prisma`

```prisma
model FormTemplate {
  id          String             @id @default(uuid()) @db.Uuid
  name        String             @db.VarChar(255)
  description String?            @db.Text
  createdAt   DateTime           @default(now()) @map("created_at")
  updatedAt   DateTime           @updatedAt @map("updated_at")

  questions   TemplateQuestion[]

  @@map("form_templates")
}

model TemplateQuestion {
  id           String       @id @default(uuid()) @db.Uuid
  templateId   String       @map("template_id") @db.Uuid
  orderIndex   Int          @map("order_index")
  questionText String       @map("question_text") @db.Text
  questionType QuestionType @map("question_type")
  isRequired   Boolean      @default(false) @map("is_required")
  settings     Json         @default("{}")
  options      Json         @default("[]")

  template     FormTemplate @relation(fields: [templateId], references: [id], onDelete: Cascade)

  @@unique([templateId, orderIndex])
  @@index([templateId])
  @@map("template_questions")
}
```

For a multi-organization product, add:

```prisma
organizationId String @map("organization_id") @db.Uuid
```

to `FormTemplate` so each organization owns its own templates.

---

## K.4 Example: standard workshop template

A standard workshop template may contain:

```text
Template name:
Standard Workshop Feedback

Question 1:
How useful was this workshop?
Type: Rating
Scale: 1–5
Required: Yes

Question 2:
How likely are you to recommend this workshop to a colleague?
Type: NPS
Scale: 0–10
Required: Yes

Question 3:
What was the most valuable part of the workshop?
Type: Text
Required: No

Question 4:
What is one thing we should improve?
Type: Text
Required: No
```

An administrator creates a session:

```text
Session:
React Performance Workshop

Session ID:
REACT-PERF-2026
```

Then selects:

```text
Use template:
Standard Workshop Feedback
```

GreyMatter Feedback creates:

```text
React Performance Workshop
└── Draft Form Version 1
    ├── Copied Question 1
    ├── Copied Question 2
    ├── Copied Question 3
    └── Copied Question 4
```

The copied questions receive new IDs. Editing them does not modify the original template.

---

## K.5 Template-to-draft copy action

A server action can copy template questions into a new form draft.

### `src/lib/create-form-from-template.ts`

```ts
import "server-only";

import { FormVersionStatus } from "@prisma/client";
import { prisma } from "@/lib/prisma";

export async function createDraftFromTemplate(
  sessionId: string,
  templateId: string,
): Promise<string> {
  const [session, template, latestVersion] = await Promise.all([
    prisma.session.findUnique({
      where: {
        id: sessionId,
      },
      select: {
        id: true,
      },
    }),
    prisma.formTemplate.findUnique({
      where: {
        id: templateId,
      },
      include: {
        questions: {
          orderBy: {
            orderIndex: "asc",
          },
        },
      },
    }),
    prisma.formVersion.findFirst({
      where: {
        sessionId,
      },
      orderBy: {
        versionNumber: "desc",
      },
      select: {
        versionNumber: true,
      },
    }),
  ]);

  if (!session) {
    throw new Error("The selected session does not exist.");
  }

  if (!template) {
    throw new Error("The selected form template does not exist.");
  }

  const newFormVersion = await prisma.formVersion.create({
    data: {
      sessionId,
      versionNumber: (latestVersion?.versionNumber ?? 0) + 1,
      status: FormVersionStatus.DRAFT,
      questions: {
        create: template.questions.map((question) => ({
          orderIndex: question.orderIndex,
          questionText: question.questionText,
          questionType: question.questionType,
          isRequired: question.isRequired,
          settings: question.settings,
          options: question.options,
        })),
      },
    },
    select: {
      id: true,
    },
  });

  return newFormVersion.id;
}
```

This function does not publish the form. It only creates an editable draft.

### Verification

After adding template models and running a migration:

```bash
npx prisma migrate dev --name add_form_templates
```

Create a template and questions using Prisma Studio.

Then call the helper from an admin action and confirm:

```text
[ ] A new session draft is created.
[ ] Draft questions match the template.
[ ] Draft question IDs differ from template question IDs.
[ ] Editing the draft does not alter the template.
[ ] The draft is not visible through the participant QR route until published.
```

---

# K.6 Email notifications

Email notifications can help administrators know when:

```text
A feedback session receives a response threshold.
A PDF report finishes.
A session is closed.
A form version is published.
A report generation job fails.
```

Email is asynchronous work, so it belongs in Inngest.

```text
Event occurs
        ↓
Inngest function runs
        ↓
Email provider API called
        ↓
Delivery result logged
```

Do not send email directly inside a participant submission request.

---

## K.7 Report-ready email workflow

A useful report workflow is:

```text
Admin requests PDF
        ↓
Report record created
        ↓
Inngest generates PDF
        ↓
PDF stored
        ↓
Report marked COMPLETE
        ↓
Email notification sent
```

Add an email field to the report event contract.

### `src/inngest/client.ts`

```ts
type GreyMatterEvents = {
  "feedback/submitted": {
    data: FeedbackSubmissionEventData;
  };

  "report/generate.pdf": {
    data: {
      reportId: string;
      sessionId: string;
      requestedBy: string;
      notificationEmail?: string;
    };
  };
};
```

A separate notification step in the PDF function could look like:

### `src/inngest/functions/generate-pdf-report.ts`

```ts
await step.run("send-report-ready-notification", async () => {
  if (!event.data.notificationEmail) {
    return {
      sent: false,
      reason: "No notification email was requested.",
    };
  }

  await sendReportReadyEmail({
    recipientEmail: event.data.notificationEmail,
    reportUrl: result.url,
    sessionId: event.data.sessionId,
  });

  return {
    sent: true,
  };
});
```

---

## K.8 Email provider abstraction

Use a small service wrapper so the rest of the application is not tied directly to one provider.

### `src/lib/email.ts`

```ts
import "server-only";

type ReportReadyEmailInput = {
  recipientEmail: string;
  reportUrl: string;
  sessionId: string;
};

export async function sendReportReadyEmail(
  input: ReportReadyEmailInput,
): Promise<void> {
  /**
   * Replace this implementation with a provider such as Resend, Postmark,
   * Amazon SES, or another transactional email service.
   *
   * Keep provider-specific code in this one module.
   */
  console.info("Report-ready email would be sent.", {
    recipientEmail: input.recipientEmail,
    reportUrl: input.reportUrl,
    sessionId: input.sessionId,
  });
}
```

A production implementation using Resend might use:

```bash
npm install resend
```

Then:

### `src/lib/email.ts`

```ts
import "server-only";

import { Resend } from "resend";
import { env } from "@/lib/env";

const resend = new Resend(env.RESEND_API_KEY);

type ReportReadyEmailInput = {
  recipientEmail: string;
  reportUrl: string;
  sessionId: string;
};

export async function sendReportReadyEmail(
  input: ReportReadyEmailInput,
): Promise<void> {
  const result = await resend.emails.send({
    from: "GreyMatter Feedback <reports@your-domain.example>",
    to: input.recipientEmail,
    subject: `Your GreyMatter Feedback report is ready: ${input.sessionId}`,
    text: [
      "Your PDF feedback report is ready.",
      "",
      `Session: ${input.sessionId}`,
      `Download report: ${input.reportUrl}`,
    ].join("\n"),
  });

  if (result.error) {
    throw new Error(`Email provider rejected the request: ${result.error.message}`);
  }
}
```

Add the secret only to private environments:

### `.env`

```dotenv
RESEND_API_KEY="re_..."
```

Never add the actual value to `.env.example`.

---

# K.9 Slack or Microsoft Teams notifications

Many internal organizations prefer operational notifications in Slack or Microsoft Teams.

A useful notification could be sent when a session reaches a response threshold:

```text
Session:
Advanced React Patterns

Responses:
50

Average rating:
4.7 / 5

NPS:
+72
```

The workflow should avoid sending one message for every individual response.

Prefer thresholds:

```text
First response
10 responses
25 responses
50 responses
100 responses
Session closes
```

This reduces noise.

---

## K.10 Slack webhook example

Store an incoming webhook URL privately:

### `.env`

```dotenv
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

Create a helper.

### `src/lib/slack.ts`

```ts
import "server-only";

import { env } from "@/lib/env";

type SlackMessageInput = {
  text: string;
};

export async function sendSlackMessage(
  input: SlackMessageInput,
): Promise<void> {
  if (!env.SLACK_WEBHOOK_URL) {
    return;
  }

  const response = await fetch(env.SLACK_WEBHOOK_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      text: input.text,
    }),
  });

  if (!response.ok) {
    throw new Error(
      `Slack webhook request failed with status ${response.status}.`,
    );
  }
}
```

Add the optional environment variable schema field:

### `src/lib/env.ts`

```ts
SLACK_WEBHOOK_URL: z.string().url().or(z.literal("")).optional(),
```

And add it to the parsed environment values:

```ts
SLACK_WEBHOOK_URL: process.env.SLACK_WEBHOOK_URL,
```

### Verification

Use a test Slack channel and webhook.

Run a small controlled function or call the helper from a protected admin test action.

Confirm:

```text
[ ] Message arrives in expected channel.
[ ] No participant text appears in notification.
[ ] Webhook URL is not visible in browser code or logs.
```

---

# K.11 Webhooks for external systems

A webhook is an HTTP request sent automatically when an event occurs.

Organizations may want to send GreyMatter Feedback events to:

```text
CRM systems
Data warehouses
Learning-management systems
Business intelligence tools
Automation platforms
Internal dashboards
```

Example outbound event:

```json
{
  "event": "feedback.response.created",
  "occurredAt": "2026-07-25T10:30:00.000Z",
  "sessionId": "REACT-2026-Q3",
  "responseId": "d7c5f8c8-6b89-4ea3-a2d6-4054f43d981d",
  "formVersionId": "4b89d719-49bd-4e6c-9ec8-13079d0a5b09"
}
```

Avoid sending raw answers by default. An external system may not have the same privacy controls as GreyMatter Feedback.

---

## K.12 Sign outbound webhook payloads

External receivers need a way to verify that a webhook really came from GreyMatter Feedback.

Use an HMAC signature.

```text
JSON payload
        +
Webhook secret
        ↓
HMAC SHA-256 signature
        ↓
X-GreyMatter-Signature header
```

### `src/lib/outbound-webhook.ts`

```ts
import "server-only";

import { createHmac } from "node:crypto";

type SendWebhookInput = {
  url: string;
  secret: string;
  payload: Record<string, unknown>;
};

export async function sendSignedWebhook(
  input: SendWebhookInput,
): Promise<void> {
  const payloadJson = JSON.stringify(input.payload);

  const signature = createHmac("sha256", input.secret)
    .update(payloadJson)
    .digest("hex");

  const response = await fetch(input.url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-GreyMatter-Signature": signature,
      "X-GreyMatter-Event": String(input.payload.event ?? "unknown"),
    },
    body: payloadJson,
  });

  if (!response.ok) {
    throw new Error(
      `Webhook receiver returned status ${response.status}.`,
    );
  }
}
```

The receiver recalculates the signature using the shared secret and compares it safely before trusting the event.

---

## K.13 Outbound webhook retry rules

Webhooks fail for normal reasons:

```text
Receiver temporarily offline
Network timeout
Receiver deployment in progress
Invalid DNS
Rate limiting
```

Send webhooks from an Inngest function so failed deliveries retry.

Recommended retry policy:

```text
Retries: 3 to 5
Timeout: 10 seconds
Payload: Small and privacy-minimized
Idempotency key: Event or response ID
```

A receiver should treat repeated event IDs as duplicates.

Example payload addition:

```json
{
  "eventId": "feedback-response-d7c5f8c8-6b89-4ea3-a2d6-4054f43d981d",
  "event": "feedback.response.created"
}
```

---

# K.14 Learning-management system integration

Courses often live in learning-management systems, or LMS platforms.

Examples include:

```text
Canvas
Moodle
Blackboard
Google Classroom
TalentLMS
Docebo
Cornerstone
```

GreyMatter Feedback can integrate in several ways.

## Option 1: Link-only integration

The LMS stores the participant URL:

```text
https://feedback.example.com/e/TYPESCRIPT-MODULE-1?src=lms
```

Advantages:

```text
Simple
Fast to implement
No API synchronization required
```

The `src=lms` parameter helps identify the source.

## Option 2: Session import

An administrator imports course and module information from the LMS.

```text
LMS course
        ↓
GreyMatter event
        ↓
LMS module
        ↓
GreyMatter session
```

Advantages:

```text
Less manual event setup
Consistent naming
Potentially automatic scheduling
```

## Option 3: Gradebook or completion integration

After a participant submits feedback, the LMS receives a completion signal.

This should be considered carefully because anonymous feedback and participant completion tracking can conflict.

If feedback must remain anonymous:

```text
Do not send participant identity with the feedback response.
```

Instead, consider separate mechanisms:

```text
Anonymous feedback form
        +
Independent LMS completion acknowledgement
```

---

# K.15 Calendar and event-platform imports

For conference or training schedules, administrators may want to import sessions from:

```text
Google Calendar
Microsoft Outlook Calendar
Eventbrite
Cvent
Sessionize
Custom CSV schedule
```

A practical initial feature is CSV import.

Example schedule CSV:

```csv
session_id,title,event_title
REACT-2026-Q1,Opening Keynote,React Summit 2026
REACT-2026-Q2,Server Components Workshop,React Summit 2026
REACT-2026-Q3,Advanced React Patterns,React Summit 2026
```

Import workflow:

```text
Administrator uploads CSV
        ↓
Server validates rows
        ↓
Preview valid and invalid entries
        ↓
Administrator confirms import
        ↓
Events and sessions created in Neon
        ↓
Administrator creates or applies form templates
```

Important validation rules:

```text
[ ] Session IDs must be unique.
[ ] Titles must not be empty.
[ ] Event title must map to a known or newly created event.
[ ] Import must report row-level errors.
[ ] Import should use a transaction where practical.
[ ] Import should not publish forms automatically without confirmation.
```

---

# K.16 Branding and organization customization

Organizations may want their own visual identity on participant forms and reports.

Potential custom settings:

```text
Organization display name
Logo
Primary color
Secondary color
Support contact URL
Privacy notice URL
Report footer text
```

A future `OrganizationBranding` model could look like:

```prisma
model OrganizationBranding {
  id                String       @id @default(uuid()) @db.Uuid
  organizationId    String       @unique @map("organization_id") @db.Uuid
  logoUrl           String?      @map("logo_url") @db.Text
  primaryColor      String       @default("#4f46e5") @map("primary_color")
  secondaryColor    String       @default("#0f172a") @map("secondary_color")
  privacyNoticeUrl  String?      @map("privacy_notice_url") @db.Text
  supportUrl        String?      @map("support_url") @db.Text
  reportFooterText  String?      @map("report_footer_text") @db.Text
  updatedAt         DateTime     @updatedAt @map("updated_at")

  @@map("organization_branding")
}
```

Validate color input carefully.

A safe starting pattern:

```ts
const hexColorSchema = /^#[0-9A-Fa-f]{6}$/;
```

Avoid accepting arbitrary CSS from administrators. Arbitrary CSS can create layout, accessibility, and security problems.

---

# K.17 Feature prioritization matrix

Not every extension should be built immediately.

| Feature | Value | Complexity | Recommended timing |
|---|---:|---:|---|
| Form templates | High | Medium | Early |
| Report-ready email | Medium | Low | Early |
| CSV session import | Medium | Medium | Early |
| Slack notifications | Medium | Low | When operations team requests it |
| LMS deep integration | High | High | After validating customer demand |
| Multi-organization roles | High | High | Before SaaS rollout |
| Branding | Medium | Medium | After multi-tenancy |
| Outbound webhooks | Medium | Medium | After core APIs stabilize |
| Live websocket analytics | Low to medium | High | Only after measured need |
| AI comment summaries | Medium | Medium to high | Optional, privacy-reviewed feature |

---

# K.18 AI-assisted feedback summaries

A future optional feature could summarize qualitative text feedback.

Example administrator request:

```text
Summarize the main themes in written feedback.
```

Possible output:

```text
Positive themes:
- Participants appreciated practical examples.
- Server Components content was especially valuable.

Improvement themes:
- More time requested for exercises.
- Caching examples were considered too fast.
```

Important privacy rules:

```text
[ ] Make AI analysis opt-in.
[ ] Tell administrators what data is sent to the AI provider.
[ ] Do not send raw IP hashes or metadata.
[ ] Consider redacting names, email addresses, and identifiers first.
[ ] Use a provider agreement appropriate for participant data.
[ ] Keep generated summaries separate from raw source feedback.
[ ] Let administrators review summaries before sharing them.
```

AI summaries should support human judgment, not replace it.

---

## K.19 Extension checklist

Before launching a new GreyMatter Feedback integration, confirm:

```text
[ ] The integration has a clear user need.
[ ] The participant form does not depend on the external service.
[ ] Secrets are server-only environment variables.
[ ] Outbound actions run through Inngest where retry behavior matters.
[ ] Events include stable IDs for deduplication.
[ ] Payloads exclude unnecessary participant data.
[ ] Errors are monitored.
[ ] Retry behavior is tested.
[ ] Organization authorization is enforced.
[ ] Integration can be disabled safely.
[ ] Documentation explains setup and failure behavior.
```

The core strength of GreyMatter Feedback is its reliable, versioned feedback workflow. Templates, notifications, imports, and integrations should enhance that workflow without making it fragile.
