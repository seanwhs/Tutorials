# Part 13 — Course Completion, Certificates, and Notifications

## The goal

By the end of this part, GreyMatter LMS will have a complete, automated course-completion pipeline: when a student finishes every required lesson in a course, the system will atomically issue a uniquely-numbered certificate, generate a downloadable PDF on demand, and send a completion email — all triggered by the `course/completed` event Part 12 already emits, all idempotent and safe against duplicate or concurrent processing, and all observable through Part 5's `workflow_events` table.

## Why it exists

Part 12's `recalculate-course-progress` function already emits `course/completed` the instant a student crosses 100%. Since then, that event has had no listener — it's been quietly firing into the void. This part builds the missing piece: a workflow that reacts to that event, and — just as importantly — one that never accidentally issues two certificates for the same achievement, never crashes the whole pipeline if an email provider hiccups, and produces a certificate that remains accurate forever, even if the course is later renamed or the student's account email changes.

## The data flow

```text
course/completed event (emitted by Part 12's recalculate-course-progress)
        │
        ▼
issue-certificate Inngest function
        │
        ├── Record a workflow_events row (PENDING) — observability
        ├── Re-verify completion is genuinely 100% (never trust the event alone)
        ├── Check for an existing certificate (idempotency)
        ├── Fetch user + course, SNAPSHOT their current name/title
        ├── Atomically generate a certificate number (Postgres sequence)
        ├── Insert the certificate row
        ├── Send a completion email (or log it, in local development)
        └── Mark the workflow_events row PROCESSED
        │
        ▼
Student visits /dashboard/achievements → sees the certificate → downloads a PDF (generated on demand)
```

---

## Step 1 — Planning the completion pipeline

### The Target

No code yet — deliberately fixing three design decisions before writing anything, mirroring every "design on paper first" step earlier in this series.

### The Concept

**Decision one: a certificate is a historical record, not a live view.** Recall Part 5's `audit_logs` table was designed to outlive the user it describes. A certificate deserves the same treatment: if an instructor renames "Introduction to Databases" to "Database Fundamentals" next year, every certificate already issued for the old title should still say "Introduction to Databases" — that was genuinely the course the student completed. We'll **snapshot** the course title and recipient email directly onto the certificate row at issuance time, rather than joining live to Sanity/`users` every time a certificate is displayed.

**Decision two: certificate numbers must be generated atomically.** Recall Part 8's race-condition lesson: "check then act" application logic has a timing gap. If we computed the "next" certificate number by counting existing rows in application code, two concurrent completions could compute the same number. We'll use a **Postgres sequence** — a database-native, atomic counter — instead.

**Decision three: PDF generation happens on-demand, not at issuance time.** We have two real options: generate a PDF file once and store it somewhere (requiring a file-storage service we haven't introduced), or generate the PDF fresh, in memory, every time a student clicks "Download." Because Decision One already guarantees every fact needed to render a certificate is permanently snapshotted on the row itself, on-demand generation is simpler, requires no new infrastructure, and is exactly as fast — this is the approach we'll take.

### The Verification

No code — but before proceeding, make sure you can explain why joining live to Sanity for a certificate's course title would be a genuine bug waiting to happen, not just a stylistic choice.

---

## Step 2 — Schema additions: certificate snapshots and atomic numbering

### The Target

Adding `courseTitle` and `recipientEmail` snapshot columns to `certificates`, plus a Postgres sequence for certificate numbering.

### The Implementation

#### `db/schema/certificates.ts` (updated)

```ts
import { pgSequence, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { users } from "./users";

// A Postgres SEQUENCE — a database-native, atomic auto-incrementing
// counter. Unlike computing "the next number" by reading and
// incrementing a value in application code (which has the exact
// race-condition problem from Part 8), Postgres guarantees two
// concurrent nextval() calls can NEVER return the same number, no
// matter how many requests arrive at the same instant.
export const certificateNumberSeq = pgSequence("certificate_number_seq", {
  startWith: 1,
  incrementBy: 1,
});

export const certificates = pgTable(
  "certificates",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    courseId: text("course_id").notNull(),
    certificateNumber: text("certificate_number").notNull().unique(),

    // SNAPSHOT fields — captured once, at issuance, per Step 1's first
    // design decision. Never updated afterward, even if the live course
    // title or the student's email later changes.
    courseTitle: text("course_title").notNull(),
    recipientEmail: text("recipient_email").notNull(),

    issuedAt: timestamp("issued_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique("certificates_user_course_unique").on(table.userId, table.courseId)]
);
```

#### `db/schema/index.ts` (confirm this line still exists — no change needed if already present)

```ts
export * from "./certificates";
```

Generate and apply the migration:

```bash
npm run db:generate
npm run db:migrate
```

### The Verification

```bash
npm run db:studio
```

Confirm `certificates` now shows `course_title` and `recipient_email` columns, both `NOT NULL`. In Neon's console SQL editor, run:

```sql
SELECT nextval('certificate_number_seq');
```

Confirm it returns `1` the first time, and `2` if you run it again — proof the sequence is live and incrementing.

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 3 — Certificate query helpers with atomic numbering

### The Target

`db/queries/certificates.ts` — read helpers, and a `createCertificate` function that safely draws from the sequence and formats a human-readable certificate number.

### The Implementation

#### `db/queries/certificates.ts`

```ts
import { and, eq, sql } from "drizzle-orm";
import { db } from "@/db/client";
import { certificates } from "@/db/schema";
import type { DbClientOrTransaction } from "@/db/transaction-type";

export async function findCertificate(userId: string, courseId: string) {
  return db.query.certificates.findFirst({
    where: and(eq(certificates.userId, userId), eq(certificates.courseId, courseId)),
  });
}

export async function findCertificateById(certificateId: string) {
  return db.query.certificates.findFirst({
    where: eq(certificates.id, certificateId),
  });
}

export async function findCertificatesForUser(userId: string) {
  return db.query.certificates.findMany({
    where: eq(certificates.userId, userId),
    orderBy: (c, { desc }) => [desc(c.issuedAt)],
  });
}

// Formats a raw sequence number into GreyMatter's human-readable
// certificate number, e.g. "GM-2025-000042".
function formatCertificateNumber(sequenceValue: number): string {
  const year = new Date().getFullYear();
  const padded = String(sequenceValue).padStart(6, "0");
  return `GM-${year}-${padded}`;
}

export interface CreateCertificateInput {
  userId: string;
  courseId: string;
  courseTitle: string;
  recipientEmail: string;
}

export async function createCertificate(
  client: DbClientOrTransaction,
  input: CreateCertificateInput
) {
  // nextval() is the atomic operation from Step 2 — this is the ONLY
  // place in the entire application that generates a certificate
  // number, and it can never produce a duplicate under concurrent load.
  const result = await client.execute(sql`select nextval('certificate_number_seq') as val`);
  // Different Postgres drivers shape execute()'s return value slightly
  // differently — some return rows directly, others wrap them under a
  // ".rows" property. This defensive check handles either shape.
  const rows = Array.isArray(result)
    ? result
    : (result as unknown as { rows: Array<{ val: string | number }> }).rows;
  const certificateNumber = formatCertificateNumber(Number(rows[0].val));

  const [created] = await client
    .insert(certificates)
    .values({
      userId: input.userId,
      courseId: input.courseId,
      certificateNumber,
      courseTitle: input.courseTitle,
      recipientEmail: input.recipientEmail,
    })
    .returning();

  return created;
}
```

**Code walkthrough:**

- `client: DbClientOrTransaction` (from Part 11) means this function works identically whether called with the plain `db` client or from inside an active transaction — we'll call it plainly (not inside a transaction) in Step 6, since a single `INSERT` is already atomic on its own; a transaction would only be necessary if we needed multiple related writes to succeed or fail together, which isn't the case here.
- `formatCertificateNumber` embeds the *current* year at issuance time, not the course's creation year or any other date — meaning certificate numbers naturally group by the year a student actually completed the course, which is generally the more meaningful grouping for both students and administrators reviewing records later.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 4 — Workflow observability helpers

### The Target

`db/queries/workflow-events.ts` — small helpers recording a background job's lifecycle in Part 5's `workflow_events` table, giving us a durable, queryable record of every completion-pipeline run distinct from Inngest's own dashboard.

### The Concept

Inngest's dashboard (Part 12) already shows us function runs — but it's an *external* system, not something our own admin tools (built in Part 15) can query directly from Neon. Recording a parallel, minimal trail inside our own database means Part 15's future admin tooling can answer "how many completions failed last week?" with a plain SQL query, without needing to reach into Inngest's API at all.

### The Implementation

#### `db/queries/workflow-events.ts`

```ts
import { eq } from "drizzle-orm";
import { db } from "@/db/client";
import { workflowEvents } from "@/db/schema";

export async function recordWorkflowEventStart(eventName: string, payload: unknown) {
  const [row] = await db
    .insert(workflowEvents)
    .values({ eventName, payload, status: "PENDING" })
    .returning();
  return row;
}

export async function markWorkflowEventStatus(id: string, status: "PROCESSED" | "FAILED") {
  await db
    .update(workflowEvents)
    .set({ status, processedAt: new Date() })
    .where(eq(workflowEvents.id, id));
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 5 — Email sending setup, with a friendly local-development fallback

### The Target

`lib/email/client.ts`, `lib/email/send-completion-email.ts` — a Resend-based email sender that **gracefully degrades to logging** if no API key is configured, so this entire part remains fully verifiable without requiring a paid third-party signup during learning.

### The Concept

Resend is a modern, developer-friendly transactional email API — but signing up for yet another external service is a real barrier for a reader just trying to follow along. We solve this the same way we handled `useCdn` tradeoffs in Part 4: build the real, production-correct path, but add a well-labeled fallback that keeps the *rest* of the pipeline (certificate creation, workflow tracking) fully testable without it.

### The Implementation

```bash
npm install resend
```

#### `.env.example` (append)

```bash
# ── Email (added in Part 13) ───────────────────────────────────────
RESEND_API_KEY=
```

#### `lib/email/client.ts`

```ts
import { Resend } from "resend";

let cachedClient: Resend | null = null;

// Returns null if no key is configured — callers must handle this case
// explicitly (see send-completion-email.ts) rather than this function
// silently throwing, which would break local development unnecessarily.
export function getResendClient(): Resend | null {
  const apiKey = process.env.RESEND_API_KEY;
  if (!apiKey) return null;
  if (!cachedClient) {
    cachedClient = new Resend(apiKey);
  }
  return cachedClient;
}
```

#### `lib/email/send-completion-email.ts`

```ts
import { getResendClient } from "./client";

export interface CompletionEmailInput {
  toEmail: string;
  courseTitle: string;
  certificateNumber: string;
  certificateUrl: string;
}

export async function sendCourseCompletionEmail(
  input: CompletionEmailInput
): Promise<{ sent: boolean; simulated: boolean }> {
  const html = renderCompletionEmailHtml(input);
  const client = getResendClient();

  if (!client) {
    // DEV FALLBACK: no RESEND_API_KEY configured. We log the fully
    // rendered email instead of throwing — this keeps the certificate
    // pipeline entirely verifiable without a real email provider.
    console.log("─── (DEV) Would send completion email ───");
    console.log(`To: ${input.toEmail}`);
    console.log(`Subject: You completed ${input.courseTitle}!`);
    console.log(html);
    return { sent: false, simulated: true };
  }

  await client.emails.send({
    from: "GreyMatter LMS <certificates@greymatter-lms.example.com>",
    to: input.toEmail,
    subject: `You completed ${input.courseTitle}!`,
    html,
  });

  return { sent: true, simulated: false };
}

function renderCompletionEmailHtml(input: CompletionEmailInput): string {
  return `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h1 style="color:#4f46e5;">Congratulations!</h1>
      <p>You've completed <strong>${escapeHtml(input.courseTitle)}</strong>.</p>
      <p>Your certificate number is <strong>${escapeHtml(input.certificateNumber)}</strong>.</p>
      <p><a href="${escapeHtml(input.certificateUrl)}" style="color:#4f46e5;">View your certificate</a></p>
    </div>
  `;
}

// EVEN in an email template, untrusted or semi-trusted strings (here,
// a course title authored by a content editor in Sanity) should never
// be interpolated into HTML unescaped — the exact same XSS-prevention
// reasoning from Part 9's video-embed allow-list, applied here to a
// different rendering context. Part 16 covers this principle formally.
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. We'll see this actually run in Step 6's verification.

---

## Step 6 — The `issue-certificate` Inngest function

### The Target

`inngest/functions/issue-certificate.ts` — the complete, idempotent, observable completion workflow.

### The Concept

This function threads together every defensive pattern this series has built so far: Part 8's race-condition recovery (applied here to certificate creation instead of enrollment), Part 11's "never trust input at face value" (applied here to the *event* itself, not just a browser request), and Part 12's step-based durability. Read the `try`/`catch` structure carefully — it exists specifically so a failure at *any* point still leaves an honest `FAILED` record in `workflow_events`, rather than a run that silently vanishes.

### The Implementation

#### `inngest/functions/issue-certificate.ts`

```ts
import { inngest } from "@/inngest/client";
import { client as sanityClient } from "@/sanity/lib/client";
import { db } from "@/db/client";
import { findUserById } from "@/db/queries/users";
import { findCourseProgressRow } from "@/db/queries/course-progress";
import { createCertificate, findCertificate } from "@/db/queries/certificates";
import { recordWorkflowEventStart, markWorkflowEventStatus } from "@/db/queries/workflow-events";
import { sendCourseCompletionEmail } from "@/lib/email/send-completion-email";

interface CourseTitleResult {
  title: string;
}

export const issueCertificate = inngest.createFunction(
  { id: "issue-certificate" },
  { event: "course/completed" },
  async ({ event, step }) => {
    const { userId, courseId } = event.data;

    const workflowEvent = await step.run("record-workflow-start", async () => {
      const row = await recordWorkflowEventStart("course/completed", event.data);
      return { id: row.id };
    });

    try {
      // DEFENSIVE RE-CHECK: we never assume an incoming event is
      // trustworthy on its own — the exact "never trust input" principle
      // from Part 11, applied here to an internal EVENT rather than a
      // browser request. If completion somehow isn't genuinely 100%
      // (a stale event, a data inconsistency), we stop here rather than
      // issuing an incorrect certificate.
      const progress = await step.run("verify-completion", async () => {
        return findCourseProgressRow(userId, courseId);
      });

      if (!progress || progress.completionPercentage !== 100) {
        await step.run("mark-workflow-not-complete", async () => {
          await markWorkflowEventStatus(workflowEvent.id, "FAILED");
        });
        return { issued: false, reason: "not_actually_complete" };
      }

      // IDEMPOTENCY: if a certificate already exists, we're done — this
      // handles both a genuinely duplicate event AND a retry of this
      // same function after an earlier partial failure.
      const existing = await step.run("check-existing-certificate", async () => {
        return findCertificate(userId, courseId);
      });

      if (existing) {
        await step.run("mark-workflow-already-issued", async () => {
          await markWorkflowEventStatus(workflowEvent.id, "PROCESSED");
        });
        return {
          issued: false,
          reason: "already_issued",
          certificateNumber: existing.certificateNumber,
        };
      }

      const { user, course } = await step.run("fetch-user-and-course", async () => {
        const [fetchedUser, fetchedCourse] = await Promise.all([
          findUserById(userId),
          sanityClient.fetch<CourseTitleResult | null>(
            `*[_type == "course" && _id == $courseId][0]{ title }`,
            { courseId }
          ),
        ]);
        return { user: fetchedUser, course: fetchedCourse };
      });

      if (!user || !course) {
        await step.run("mark-workflow-missing-data", async () => {
          await markWorkflowEventStatus(workflowEvent.id, "FAILED");
        });
        return { issued: false, reason: "missing_user_or_course" };
      }

      const certificate = await step.run("create-certificate", async () => {
        try {
          return await createCertificate(db, {
            userId,
            courseId,
            courseTitle: course.title,
            recipientEmail: user.email,
          });
        } catch (error) {
          // RACE RECOVERY: a unique-constraint violation here means a
          // CONCURRENT execution of this same function won the race
          // between our "check-existing-certificate" step and this
          // insert — exactly Part 8's enrollment race condition,
          // applied to certificates. We recover by fetching the row the
          // winner created, rather than surfacing a false failure.
          const raced = await findCertificate(userId, courseId);
          if (raced) return raced;
          throw error;
        }
      });

      await step.run("send-completion-email", async () => {
        await sendCourseCompletionEmail({
          toEmail: certificate.recipientEmail,
          courseTitle: certificate.courseTitle,
          certificateNumber: certificate.certificateNumber,
          certificateUrl: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard/achievements`,
        });
      });

      await step.run("mark-workflow-processed", async () => {
        await markWorkflowEventStatus(workflowEvent.id, "PROCESSED");
      });

      return { issued: true, certificateNumber: certificate.certificateNumber };
    } catch (error) {
      await step.run("mark-workflow-failed", async () => {
        await markWorkflowEventStatus(workflowEvent.id, "FAILED");
      });
      // Re-throw so Inngest's own retry mechanism still gets a chance to
      // recover from genuinely transient failures (e.g. a brief Neon or
      // Sanity outage) — we only intercept the error long enough to
      // record it, never to suppress it entirely.
      throw error;
    }
  }
);
```

Register it:

#### `inngest/functions/index.ts` (final version for this part)

```ts
import { onboardUser } from "./onboard-user";
import { confirmEnrollment } from "./confirm-enrollment";
import { recalculateCourseProgress } from "./recalculate-course-progress";
import { issueCertificate } from "./issue-certificate";

export const functions = [
  onboardUser,
  confirmEnrollment,
  recalculateCourseProgress,
  issueCertificate,
];
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. Full end-to-end verification happens in Step 10, once the download route and achievements page exist.

---

## Step 7 — PDF generation strategy

### The Target

`lib/certificates/generate-certificate-pdf.ts` — a function producing a real PDF file, in memory, from a certificate's already-snapshotted data.

### The Implementation

```bash
npm install pdf-lib
```

#### `lib/certificates/generate-certificate-pdf.ts`

```ts
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";

export interface CertificatePdfInput {
  recipientEmail: string;
  courseTitle: string;
  certificateNumber: string;
  issuedAt: Date;
}

// Generates a PDF ENTIRELY from data already stored on the certificate
// row — no live Sanity or Neon lookups needed here at all, which is the
// direct payoff of Step 1's snapshot decision. This function can be
// called as many times as a student wants to re-download their
// certificate, always producing an identical, correct result.
export async function generateCertificatePdf(input: CertificatePdfInput): Promise<Uint8Array> {
  const pdfDoc = await PDFDocument.create();
  const page = pdfDoc.addPage([842, 595]); // A4 landscape, in points
  const boldFont = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const regularFont = await pdfDoc.embedFont(StandardFonts.Helvetica);
  const { width, height } = page.getSize();

  page.drawRectangle({
    x: 20,
    y: 20,
    width: width - 40,
    height: height - 40,
    borderColor: rgb(0.31, 0.27, 0.9),
    borderWidth: 3,
  });

  page.drawText("Certificate of Completion", {
    x: 60,
    y: height - 140,
    size: 32,
    font: boldFont,
    color: rgb(0.06, 0.09, 0.16),
  });

  page.drawText("This certifies that", {
    x: 60,
    y: height - 200,
    size: 14,
    font: regularFont,
    color: rgb(0.28, 0.33, 0.41),
  });

  page.drawText(input.recipientEmail, {
    x: 60,
    y: height - 230,
    size: 20,
    font: boldFont,
    color: rgb(0.31, 0.27, 0.9),
  });

  page.drawText("has successfully completed", {
    x: 60,
    y: height - 265,
    size: 14,
    font: regularFont,
    color: rgb(0.28, 0.33, 0.41),
  });

  page.drawText(input.courseTitle, {
    x: 60,
    y: height - 295,
    size: 22,
    font: boldFont,
    color: rgb(0.06, 0.09, 0.16),
  });

  page.drawText(`Certificate No. ${input.certificateNumber}`, {
    x: 60,
    y: 80,
    size: 12,
    font: regularFont,
    color: rgb(0.28, 0.33, 0.41),
  });

  page.drawText(`Issued ${input.issuedAt.toLocaleDateString()}`, {
    x: width - 220,
    y: 80,
    size: 12,
    font: regularFont,
    color: rgb(0.28, 0.33, 0.41),
  });

  return pdfDoc.save();
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. Full visual verification happens once the download route exists, next.

---

## Step 8 — The authorized certificate download route

### The Target

`app/api/certificates/[certificateId]/download/route.ts` — a Route Handler streaming a freshly-generated PDF, protected by the exact resource-level authorization pattern established since Part 7.

### The Implementation

#### `app/api/certificates/[certificateId]/download/route.ts`

```ts
import { NextResponse } from "next/server";
import { requireUser } from "@/lib/auth/require-user";
import { findCertificateById } from "@/db/queries/certificates";
import { generateCertificatePdf } from "@/lib/certificates/generate-certificate-pdf";

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ certificateId: string }> }
) {
  const user = await requireUser();
  const { certificateId } = await params;

  const certificate = await findCertificateById(certificateId);

  // RESOURCE-LEVEL AUTHORIZATION: a valid certificate ID alone is not
  // sufficient — we verify it genuinely belongs to the requesting user.
  // A 404 (not a 403) is returned for a mismatch, exactly the "don't
  // leak which case it was" principle from Part 7 — an unauthorized
  // caller learns nothing about whether this ID even exists.
  if (!certificate || certificate.userId !== user.id) {
    return NextResponse.json({ error: "Certificate not found" }, { status: 404 });
  }

  const pdfBytes = await generateCertificatePdf({
    recipientEmail: certificate.recipientEmail,
    courseTitle: certificate.courseTitle,
    certificateNumber: certificate.certificateNumber,
    issuedAt: certificate.issuedAt,
  });

  return new NextResponse(Buffer.from(pdfBytes), {
    status: 200,
    headers: {
      "Content-Type": "application/pdf",
      "Content-Disposition": `attachment; filename="${certificate.certificateNumber}.pdf"`,
    },
  });
}
```

### The Verification

We'll trigger this properly once a real certificate exists (Step 10) — for now:

```bash
npx tsc --noEmit
npm run build
```

Both should complete without errors.

---

## Step 9 — Achievements page and course-page certificate link

### The Target

Replacing Part 7's achievements placeholder with a real list of earned certificates, and adding a small "Download certificate" link to the course dashboard page once a course reaches 100%.

### The Implementation

#### `app/dashboard/achievements/page.tsx` (replaced)

```tsx
import { requireUser } from "@/lib/auth/require-user";
import { findCertificatesForUser } from "@/db/queries/certificates";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

export default async function AchievementsPage() {
  const user = await requireUser();
  const certificates = await findCertificatesForUser(user.id);

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6 px-6 py-10">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Achievements</h1>
        <p className="mt-1 text-text-secondary">Your earned certificates.</p>
      </div>

      {certificates.length === 0 ? (
        <EmptyState
          title="No certificates yet"
          description="Complete every lesson in a course to automatically earn a certificate."
        />
      ) : (
        <div className="flex flex-col gap-4">
          {certificates.map((cert) => (
            <Card key={cert.id}>
              <CardHeader>
                <div className="flex items-center justify-between">
                  <CardTitle>{cert.courseTitle}</CardTitle>
                  <Badge variant="success">Completed</Badge>
                </div>
              </CardHeader>
              <CardContent className="flex items-center justify-between">
                <div className="text-sm text-text-secondary">
                  <p>Certificate No. {cert.certificateNumber}</p>
                  <p>Issued {cert.issuedAt.toLocaleDateString()}</p>
                </div>
                <a href={`/api/certificates/${cert.id}/download`}>
                  <Button variant="primary" size="sm">
                    Download PDF
                  </Button>
                </a>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
```

#### `app/dashboard/courses/[courseSlug]/page.tsx` (add a certificate link)

```tsx
// Add this import at the top:
import { findCertificate } from "@/db/queries/certificates";

// Inside DashboardCoursePage, after fetching `course`, add:
const certificate =
  course.completionPercentage === 100 ? await findCertificate(user.id, course._id) : null;

// Inside the JSX, right after the "Your progress" Card, add:
{certificate && (
  <a href={`/api/certificates/${certificate.id}/download`}>
    <Button variant="primary" className="w-fit">
      🎓 Download your certificate
    </Button>
  </a>
)}
```

### The Verification

We verify everything together in the final step below.

---

## Step 10 — End-to-end verification, and a duplicate-safety test

### The Target

Completing a full course for real, confirming every piece of this pipeline fires correctly, and directly testing that two concurrent completion events cannot produce two certificates.

### The Implementation and Verification

With `npm run dev` and `npx inngest-cli@latest dev` both running, sign in as your enrolled test student. If you haven't already completed every interactive module across both lessons in "Introduction to Databases" during earlier parts' verification steps, do so now — visit each lesson and submit every remaining quiz, code exercise, reflection, and checkpoint.

After your final submission, check `http://localhost:8288`'s "Runs" tab. You should see, in order: `recalculate-course-progress` completing with `completionPercentage: 100`, followed automatically by an `issue-certificate` run.

Click into the `issue-certificate` run and confirm each step succeeded: `verify-completion`, `check-existing-certificate` (returning nothing, since this is the first time), `fetch-user-and-course`, `create-certificate`, `send-completion-email`, and `mark-workflow-processed`.

Check your `npm run dev` terminal — if you haven't configured `RESEND_API_KEY`, confirm you see the full "(DEV) Would send completion email" log block, including your course title and certificate number.

Open Drizzle Studio and confirm:
1. A new row in `certificates`, with a real `certificate_number` like `GM-2025-000001`, and `course_title`/`recipient_email` correctly populated.
2. A new row in `workflow_events` with `status = PROCESSED`.

Visit `http://localhost:3000/dashboard/achievements`. Confirm your course appears as a card with a green "Completed" badge, the correct certificate number and issue date, and a working "Download PDF" button. Click it — confirm a real PDF file downloads, and open it to confirm it displays your email, the course title, the certificate number, and today's date, correctly formatted inside the bordered certificate layout.

Visit `/dashboard/courses/introduction-to-databases` directly and confirm the "🎓 Download your certificate" button now appears there too.

**Now, the duplicate-safety test.** Create a small manual script, mirroring Part 8, Step 4's concurrent-enrollment test:

#### `tests/manual/duplicate-certificate-test.ts`

```ts
// Standalone script — safe to delete after running. Fill in real IDs
// from Drizzle Studio (your internal user UUID) and Sanity Vision
// (your course's real _id) before running.
import { inngest } from "@/inngest/client";

const USER_ID = "REPLACE_WITH_REAL_INTERNAL_USER_ID";
const COURSE_ID = "REPLACE_WITH_REAL_SANITY_COURSE_ID";

async function run() {
  await Promise.all([
    inngest.send({ name: "course/completed", data: { userId: USER_ID, courseId: COURSE_ID } }),
    inngest.send({ name: "course/completed", data: { userId: USER_ID, courseId: COURSE_ID } }),
  ]);
  console.log("Sent two concurrent course/completed events.");
}

run().then(() => process.exit(0));
```

```bash
npx tsx tests/manual/duplicate-certificate-test.ts
```

Check `http://localhost:8288`'s "Runs" tab — confirm **two** `issue-certificate` runs appear (both events were genuinely received and processed), but inspect their results: one should report `{ issued: false, reason: "already_issued", ... }` (or, if they raced closely enough, the race-recovery path inside `create-certificate` handled it silently). Either way, open Drizzle Studio and confirm **exactly one** row still exists in `certificates` for this user/course — proving the idempotency and race-recovery logic from Step 6 genuinely works under concurrent load, exactly mirroring Part 8's enrollment test.

Delete `tests/manual/duplicate-certificate-test.ts` once confirmed.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **`nextval('certificate_number_seq')` fails with "relation does not exist"** — Confirm `npm run db:generate` genuinely picked up the new `pgSequence` definition (check the generated migration file for a `CREATE SEQUENCE` statement) and that `npm run db:migrate` was run afterward.
- **Certificate email never logs, and no error appears either** — Confirm `sendCourseCompletionEmail` is genuinely being awaited inside a `step.run` block, and check that `RESEND_API_KEY` isn't accidentally set to an empty string (which is falsy in JS but might still pass some naive checks) rather than being fully unset.
- **PDF downloads but shows garbled or missing text** — Confirm `pdf-lib`'s `embedFont(StandardFonts.HelveticaBold)` calls succeeded; this is a built-in, dependency-free font, so failures here almost always indicate a `pdf-lib` version mismatch — reinstall with `npm install pdf-lib@latest`.
- **Download route returns 404 even for your own certificate** — Double-check `certificate.userId !== user.id` is comparing your **internal** UUID (`user.id` from `requireUser()`) and not accidentally comparing against a Clerk ID — a very easy mix-up given Part 6's dual-identity system.
- **Two `issue-certificate` runs both report success, and two certificate rows exist** — This would indicate the `unique(user_id, course_id)` constraint on `certificates` is missing from your actual database; re-run `npm run db:generate`/`npm run db:migrate` and confirm the constraint exists via Drizzle Studio.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `db/schema/certificates.ts` (modified), `db/migrations/000X_*.sql` (new), `db/queries/certificates.ts`, `db/queries/workflow-events.ts`, `lib/email/client.ts`, `lib/email/send-completion-email.ts`, `lib/certificates/generate-certificate-pdf.ts`, `inngest/functions/issue-certificate.ts`, `inngest/functions/index.ts` (modified), `app/api/certificates/[certificateId]/download/route.ts`, `app/dashboard/achievements/page.tsx` (modified), `app/dashboard/courses/[courseSlug]/page.tsx` (modified), updated `.env.example`. Confirm `tests/manual/duplicate-certificate-test.ts` was deleted.

```bash
git commit -m "Part 13: automated course completion pipeline — snapshot-based certificates, atomic sequence-based numbering, idempotent issue-certificate workflow, on-demand PDF generation, completion email with dev fallback"
```

---

## Reference: why certificates snapshot their data

| Field | Source at issuance | Why not a live join? |
|---|---|---|
| `courseTitle` | Sanity, at the moment of completion | A future course rename shouldn't rewrite history |
| `recipientEmail` | Neon `users` table, at the moment of completion | A future account email change shouldn't rewrite history |
| `certificateNumber` | Postgres sequence | Must be assigned exactly once, atomically, forever |

## Reference: the issue-certificate defense layers

| Layer | Guards against |
|---|---|
| Re-verify completion | A stale or incorrect `course/completed` event |
| Check existing certificate | A genuine duplicate event |
| Try/catch around insert | Two concurrent executions racing each other |
| Try/catch around the whole function | Any unexpected failure — recorded as `FAILED`, then re-thrown for Inngest's own retry |

---

## What's next

Part 14 builds on this part's completion machinery with scheduled, time-based workflows: an Inngest cron function detecting students inactive for seven days, a weekly progress digest, notification-preference controls, an in-app notification center, and reminder cancellation the moment a student resumes activity or completes their course.
