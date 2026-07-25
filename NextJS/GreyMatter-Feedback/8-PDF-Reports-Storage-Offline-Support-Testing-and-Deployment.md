# Part 8: PDF Reports, Storage, Offline Support, Testing, and Deployment

This final part adds the production layer around GreyMatter Feedback.

Administrators will be able to request a PDF report without waiting for it to generate. Inngest will create the report in the background, store it locally during development or in S3-compatible storage in production, and update the report status in Neon.

We will also add:

- A retry-friendly browser outbox for offline submissions.
- A basic service worker for static offline caching.
- Automated unit tests for key analytics logic.
- Production deployment configuration.

By the end of this part, GreyMatter Feedback will support this full reporting workflow:

```text
Administrator requests report
        ↓
Report record created in Neon
        ↓
Inngest report/generate.pdf event
        ↓
Background worker calculates analytics
        ↓
React PDF renders report
        ↓
PDF stored locally or in S3-compatible storage
        ↓
Report URL saved in Neon
        ↓
Admin dashboard shows completed download link
```

---

## Step 8.1 — Create PDF report data helpers

### The Target

Create reusable helpers that convert session analytics into report-friendly values.

### The Concept

The dashboard already displays analytics in HTML. A PDF needs the same information in a printable format.

Instead of writing analytics calculations again, the report generator will reuse:

```text
getSessionAnalytics(sessionId)
```

This keeps the dashboard and PDF consistent. They both read from the same authoritative response data in Neon.

### The Implementation

Create this file.

### `src/lib/report-formatting.ts`

```ts
import "server-only";

export function formatAverage(value: number | null): string {
  return value === null ? "No responses" : value.toFixed(1);
}

export function formatNps(value: number | null): string {
  if (value === null) {
    return "No responses";
  }

  return value > 0 ? `+${value}` : String(value);
}

export function formatReportDate(value: Date): string {
  return new Intl.DateTimeFormat("en", {
    dateStyle: "long",
    timeStyle: "short",
  }).format(value);
}

export function getMaximumDistributionCount(
  distribution: Array<{ count: number }>,
): number {
  return Math.max(...distribution.map((item) => item.count), 1);
}
```

### The Verification

Run:

```bash
npm run lint
```

Expected result:

```text
No ESLint errors.
```

---

## Step 8.2 — Create the PDF document component

### The Target

Create a branded PDF report using `@react-pdf/renderer`.

### The Concept

React PDF uses React components, but it renders them into a PDF document instead of browser HTML.

Think of it as using the same design mindset as React pages, but printing onto virtual paper.

The PDF will include:

- Event and session details.
- Total response count.
- Average rating.
- NPS.
- Rating distributions.
- NPS breakdown.
- Choice result counts.
- Written comments.

### The Implementation

Create this file.

### `src/components/admin/session-report-document.tsx`

```tsx
import {
  Document,
  Page,
  StyleSheet,
  Text,
  View,
} from "@react-pdf/renderer";
import type { SessionAnalytics } from "@/lib/session-analytics";
import {
  formatAverage,
  formatNps,
  formatReportDate,
  getMaximumDistributionCount,
} from "@/lib/report-formatting";

const styles = StyleSheet.create({
  page: {
    backgroundColor: "#f8fafc",
    color: "#0f172a",
    fontFamily: "Helvetica",
    fontSize: 10,
    padding: 36,
  },
  header: {
    backgroundColor: "#4338ca",
    borderRadius: 10,
    color: "#ffffff",
    marginBottom: 20,
    padding: 20,
  },
  eyebrow: {
    color: "#c7d2fe",
    fontSize: 9,
    marginBottom: 6,
  },
  title: {
    fontSize: 22,
    fontWeight: 700,
  },
  subtitle: {
    color: "#e0e7ff",
    fontSize: 10,
    marginTop: 8,
  },
  section: {
    backgroundColor: "#ffffff",
    borderColor: "#e2e8f0",
    borderRadius: 10,
    borderWidth: 1,
    marginBottom: 16,
    padding: 16,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: 700,
    marginBottom: 12,
  },
  metricGrid: {
    flexDirection: "row",
    gap: 10,
  },
  metricCard: {
    backgroundColor: "#eef2ff",
    borderRadius: 8,
    flexGrow: 1,
    padding: 12,
  },
  metricLabel: {
    color: "#475569",
    fontSize: 8,
  },
  metricValue: {
    color: "#1e1b4b",
    fontSize: 22,
    fontWeight: 700,
    marginTop: 6,
  },
  metricDescription: {
    color: "#475569",
    fontSize: 8,
    marginTop: 4,
  },
  questionTitle: {
    fontSize: 11,
    fontWeight: 700,
    marginBottom: 4,
  },
  questionMeta: {
    color: "#64748b",
    fontSize: 8,
    marginBottom: 10,
  },
  questionBlock: {
    borderBottomColor: "#e2e8f0",
    borderBottomWidth: 1,
    marginBottom: 14,
    paddingBottom: 14,
  },
  distributionRow: {
    alignItems: "center",
    flexDirection: "row",
    marginTop: 5,
  },
  distributionLabel: {
    color: "#334155",
    width: 110,
  },
  distributionTrack: {
    backgroundColor: "#e2e8f0",
    borderRadius: 4,
    flexGrow: 1,
    height: 8,
    overflow: "hidden",
  },
  distributionFill: {
    backgroundColor: "#4f46e5",
    height: 8,
  },
  distributionCount: {
    marginLeft: 8,
    textAlign: "right",
    width: 24,
  },
  npsPromoter: {
    backgroundColor: "#059669",
  },
  npsPassive: {
    backgroundColor: "#d97706",
  },
  npsDetractor: {
    backgroundColor: "#dc2626",
  },
  comment: {
    backgroundColor: "#f8fafc",
    borderRadius: 6,
    color: "#334155",
    marginTop: 8,
    padding: 10,
  },
  footer: {
    color: "#64748b",
    fontSize: 8,
    marginTop: 8,
    textAlign: "center",
  },
});

type DistributionItem = {
  label: string;
  count: number;
  color?: "indigo" | "promoter" | "passive" | "detractor";
};

function DistributionRows({ items }: { items: DistributionItem[] }) {
  const maximumCount = getMaximumDistributionCount(items);

  function getFillStyle(color: DistributionItem["color"]) {
    if (color === "promoter") {
      return [styles.distributionFill, styles.npsPromoter];
    }

    if (color === "passive") {
      return [styles.distributionFill, styles.npsPassive];
    }

    if (color === "detractor") {
      return [styles.distributionFill, styles.npsDetractor];
    }

    return styles.distributionFill;
  }

  return (
    <View>
      {items.map((item) => (
        <View key={item.label} style={styles.distributionRow}>
          <Text style={styles.distributionLabel}>{item.label}</Text>

          <View style={styles.distributionTrack}>
            <View
              style={[
                getFillStyle(item.color),
                {
                  width: `${Math.round((item.count / maximumCount) * 100)}%`,
                },
              ]}
            />
          </View>

          <Text style={styles.distributionCount}>{item.count}</Text>
        </View>
      ))}
    </View>
  );
}

export function SessionReportDocument({
  analytics,
  generatedAt,
}: {
  analytics: SessionAnalytics;
  generatedAt: Date;
}) {
  return (
    <Document
      author="GreyMatter Feedback"
      creator="GreyMatter Feedback"
      title={`${analytics.session.title} Feedback Report`}
    >
      <Page size="A4" style={styles.page}>
        <View style={styles.header}>
          <Text style={styles.eyebrow}>{analytics.session.eventTitle}</Text>
          <Text style={styles.title}>{analytics.session.title}</Text>
          <Text style={styles.subtitle}>
            GreyMatter Feedback executive summary · Generated{" "}
            {formatReportDate(generatedAt)}
          </Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Overview</Text>

          <View style={styles.metricGrid}>
            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>TOTAL RESPONSES</Text>
              <Text style={styles.metricValue}>
                {analytics.overview.totalResponses}
              </Text>
              <Text style={styles.metricDescription}>
                Submitted participant feedback forms
              </Text>
            </View>

            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>AVERAGE RATING</Text>
              <Text style={styles.metricValue}>
                {formatAverage(analytics.overview.averageRating)}
              </Text>
              <Text style={styles.metricDescription}>
                Across all rating answers
              </Text>
            </View>

            <View style={styles.metricCard}>
              <Text style={styles.metricLabel}>NET PROMOTER SCORE</Text>
              <Text style={styles.metricValue}>
                {formatNps(analytics.overview.primaryNps)}
              </Text>
              <Text style={styles.metricDescription}>
                First configured NPS question
              </Text>
            </View>
          </View>
        </View>

        {analytics.ratingQuestions.length > 0 ? (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Rating questions</Text>

            {analytics.ratingQuestions.map((question) => (
              <View key={question.id} style={styles.questionBlock}>
                <Text style={styles.questionTitle}>{question.questionText}</Text>
                <Text style={styles.questionMeta}>
                  Form version {question.formVersionNumber} ·{" "}
                  {question.responseCount} answers · Average{" "}
                  {formatAverage(question.average)} / {question.maximum}
                </Text>

                <DistributionRows
                  items={question.distribution.map((item) => ({
                    label: `Score ${item.value}`,
                    count: item.count,
                  }))}
                />
              </View>
            ))}
          </View>
        ) : null}

        {analytics.npsQuestions.length > 0 ? (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Recommendation scores</Text>

            {analytics.npsQuestions.map((question) => (
              <View key={question.id} style={styles.questionBlock}>
                <Text style={styles.questionTitle}>{question.questionText}</Text>
                <Text style={styles.questionMeta}>
                  Form version {question.formVersionNumber} ·{" "}
                  {question.responseCount} answers · NPS{" "}
                  {formatNps(question.score)}
                </Text>

                <View style={styles.metricGrid}>
                  <View style={styles.metricCard}>
                    <Text style={styles.metricLabel}>PROMOTERS</Text>
                    <Text style={styles.metricValue}>{question.promoters}</Text>
                  </View>

                  <View style={styles.metricCard}>
                    <Text style={styles.metricLabel}>PASSIVES</Text>
                    <Text style={styles.metricValue}>{question.passives}</Text>
                  </View>

                  <View style={styles.metricCard}>
                    <Text style={styles.metricLabel}>DETRACTORS</Text>
                    <Text style={styles.metricValue}>{question.detractors}</Text>
                  </View>
                </View>

                <View style={{ marginTop: 10 }}>
                  <DistributionRows
                    items={question.distribution.map((item) => ({
                      label: `Score ${item.value}`,
                      count: item.count,
                      color:
                        item.value >= 9
                          ? "promoter"
                          : item.value >= 7
                            ? "passive"
                            : "detractor",
                    }))}
                  />
                </View>
              </View>
            ))}
          </View>
        ) : null}

        {analytics.choiceQuestions.length > 0 ? (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Choice questions</Text>

            {analytics.choiceQuestions.map((question) => (
              <View key={question.id} style={styles.questionBlock}>
                <Text style={styles.questionTitle}>{question.questionText}</Text>
                <Text style={styles.questionMeta}>
                  Form version {question.formVersionNumber} ·{" "}
                  {question.responseCount} answers
                </Text>

                <DistributionRows
                  items={question.distribution.map((item) => ({
                    label: item.option,
                    count: item.count,
                  }))}
                />
              </View>
            ))}
          </View>
        ) : null}

        {analytics.textQuestions.length > 0 ? (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Written feedback</Text>

            {analytics.textQuestions.map((question) => (
              <View key={question.id} style={styles.questionBlock}>
                <Text style={styles.questionTitle}>{question.questionText}</Text>
                <Text style={styles.questionMeta}>
                  Form version {question.formVersionNumber} ·{" "}
                  {question.responseCount} comments
                </Text>

                {question.comments.map((comment) => (
                  <View key={comment.responseId} style={styles.comment}>
                    <Text>{comment.value}</Text>
                  </View>
                ))}
              </View>
            ))}
          </View>
        ) : null}

        <Text style={styles.footer}>
          Generated by GreyMatter Feedback. Responses are tied to their
          original published form version for historical accuracy.
        </Text>
      </Page>
    </Document>
  );
}
```

### The Verification

Run:

```bash
npm run lint
```

Then:

```bash
npm run build
```

Both commands should succeed.

---

## Step 8.3 — Create local and S3-compatible report storage

### The Target

Create one storage layer that works in two modes:

1. **Local development:** saves reports into `public/reports`.
2. **Production:** uploads reports to an S3-compatible provider such as Amazon S3, Cloudflare R2, Backblaze B2, or MinIO.

### The Concept

The report-generation worker should not care where the finished PDF goes.

It should simply say:

```text
Store this PDF using this filename.
```

The storage helper decides whether to write it to the local filesystem or upload it to object storage.

This is an example of an **abstraction**: one consistent interface hiding different implementation details.

### The Implementation

Create this file.

### `src/lib/report-storage.ts`

```ts
import "server-only";

import { PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { env } from "@/lib/env";

type ReportStorageResult = {
  url: string;
};

function isS3Configured(): boolean {
  return Boolean(
    env.S3_REGION &&
      env.S3_BUCKET &&
      env.S3_ACCESS_KEY_ID &&
      env.S3_SECRET_ACCESS_KEY,
  );
}

function getS3Client(): S3Client {
  return new S3Client({
    region: env.S3_REGION,
    endpoint: env.S3_ENDPOINT || undefined,
    forcePathStyle: Boolean(env.S3_ENDPOINT),
    credentials: {
      accessKeyId: env.S3_ACCESS_KEY_ID ?? "",
      secretAccessKey: env.S3_SECRET_ACCESS_KEY ?? "",
    },
  });
}

function safePathSegment(value: string): string {
  return value.replaceAll(/[^A-Za-z0-9-]/g, "-");
}

export async function storeReportPdf(
  reportId: string,
  sessionId: string,
  pdfBuffer: Buffer,
): Promise<ReportStorageResult> {
  const fileName = `${safePathSegment(sessionId)}-${safePathSegment(reportId)}.pdf`;

  if (isS3Configured()) {
    const objectKey = `reports/${fileName}`;
    const s3Client = getS3Client();

    await s3Client.send(
      new PutObjectCommand({
        Bucket: env.S3_BUCKET,
        Key: objectKey,
        Body: pdfBuffer,
        ContentType: "application/pdf",
        ContentDisposition: `attachment; filename="${fileName}"`,
      }),
    );

    /**
     * In production, use a public CDN domain or a protected download endpoint.
     * The public endpoint convention below works with S3-compatible providers
     * that expose a bucket through a configured public endpoint.
     */
    const baseUrl = env.S3_ENDPOINT
      ? `${env.S3_ENDPOINT.replace(/\/$/, "")}/${env.S3_BUCKET}`
      : `https://${env.S3_BUCKET}.s3.${env.S3_REGION}.amazonaws.com`;

    return {
      url: `${baseUrl}/${objectKey}`,
    };
  }

  const reportsDirectory = path.join(process.cwd(), "public", "reports");

  await mkdir(reportsDirectory, {
    recursive: true,
  });

  const filePath = path.join(reportsDirectory, fileName);

  await writeFile(filePath, pdfBuffer);

  return {
    url: `/reports/${fileName}`,
  };
}
```

Create the local reports directory:

```bash
mkdir -p public/reports
```

Add this line to `.gitignore` so generated local PDF files are not committed:

### `.gitignore`

```gitignore
/public/reports/*.pdf
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should complete successfully.

---

## Step 8.4 — Create PDF rendering and report-generation service

### The Target

Create a service that:

1. Reads analytics from Neon.
2. Renders a PDF buffer.
3. Stores the report.
4. Updates report status in Neon.

### The Concept

This service is the report factory.

The report record acts like a work order:

```text
QUEUED
  ↓
PROCESSING
  ↓
COMPLETE
```

If something fails, the work order becomes:

```text
FAILED
```

with a safe error message stored for administrators.

### The Implementation

Create this file.

### `src/lib/generate-session-report.ts`

```ts
import "server-only";

import { renderToBuffer } from "@react-pdf/renderer";
import { ReportStatus } from "@prisma/client";
import { SessionReportDocument } from "@/components/admin/session-report-document";
import { prisma } from "@/lib/prisma";
import { storeReportPdf } from "@/lib/report-storage";
import { getSessionAnalytics } from "@/lib/session-analytics";

export async function generateSessionReport(reportId: string): Promise<{
  url: string;
}> {
  const report = await prisma.report.findUnique({
    where: {
      id: reportId,
    },
    select: {
      id: true,
      sessionId: true,
    },
  });

  if (!report) {
    throw new Error("The requested report record does not exist.");
  }

  await prisma.report.update({
    where: {
      id: report.id,
    },
    data: {
      status: ReportStatus.PROCESSING,
      error: null,
    },
  });

  try {
    const analytics = await getSessionAnalytics(report.sessionId);

    const pdfBuffer = await renderToBuffer(
      <SessionReportDocument analytics={analytics} generatedAt={new Date()} />,
    );

    const storedReport = await storeReportPdf(
      report.id,
      report.sessionId,
      pdfBuffer,
    );

    await prisma.report.update({
      where: {
        id: report.id,
      },
      data: {
        status: ReportStatus.COMPLETE,
        url: storedReport.url,
        error: null,
      },
    });

    return {
      url: storedReport.url,
    };
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message.slice(0, 1000)
        : "An unknown report-generation error occurred.";

    await prisma.report.update({
      where: {
        id: report.id,
      },
      data: {
        status: ReportStatus.FAILED,
        error: message,
      },
    });

    throw error;
  }
}
```

> Because this file contains JSX, rename it to `.tsx`.

The final file path must be:

### `src/lib/generate-session-report.tsx`

Delete any `.ts` file with the same name if you created it first.

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should complete successfully.

---

## Step 8.5 — Create the Inngest PDF generation function

### The Target

Add a new Inngest worker for `report/generate.pdf`.

### The Concept

PDF rendering can take longer than a participant or administrator should wait in a browser request.

The browser should receive a quick answer:

```text
Your report request was queued.
```

Then Inngest handles the slower work in the background.

### The Implementation

Create this file.

### `src/inngest/functions/generate-pdf-report.ts`

```ts
import { inngest } from "@/inngest/client";
import { generateSessionReport } from "@/lib/generate-session-report";

export const generatePdfReport = inngest.createFunction(
  {
    id: "generate-pdf-report",
    retries: 3,
    concurrency: 2,
  },
  {
    event: "report/generate.pdf",
  },
  async ({ event, step }) => {
    const result = await step.run("generate-and-store-pdf-report", async () => {
      return generateSessionReport(event.data.reportId);
    });

    await step.run("record-report-completion", async () => {
      console.info("GreyMatter PDF report generated.", {
        reportId: event.data.reportId,
        sessionId: event.data.sessionId,
        requestedBy: event.data.requestedBy,
        url: result.url,
      });

      return {
        completed: true,
      };
    });

    return {
      status: "complete",
      url: result.url,
    };
  },
);
```

Replace the complete contents of the function index.

### `src/inngest/functions/index.ts`

```ts
import { generatePdfReport } from "./generate-pdf-report";
import { processFeedbackSubmission } from "./process-feedback-submission";

export const inngestFunctions = [
  processFeedbackSubmission,
  generatePdfReport,
];
```

### The Verification

Restart both development processes.

Terminal one:

```bash
npm run dev
```

Terminal two:

```bash
npm run inngest:dev
```

Open:

```text
http://localhost:8288
```

Under **Functions**, verify both functions appear:

```text
process-feedback-submission
generate-pdf-report
```

---

## Step 8.6 — Create the protected report request API

### The Target

Create an administrator-only API endpoint that creates a report record and queues the background job.

### The Concept

The API creates the database work order before it sends the Inngest event.

This order matters:

```text
Create Report record in Neon
        ↓
Send Inngest event with report ID
```

The report record provides a reliable status that the dashboard can display while the background job runs.

### The Implementation

Create the folders:

```bash
mkdir -p "src/app/api/admin/reports/[sessionId]"
```

Create this file.

### `src/app/api/admin/reports/[sessionId]/route.ts`

```ts
import { NextResponse } from "next/server";
import { ReportStatus } from "@prisma/client";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { inngest } from "@/inngest/client";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";

type ReportRouteContext = {
  params: Promise<{
    sessionId: string;
  }>;
};

export async function GET(
  _request: Request,
  context: ReportRouteContext,
): Promise<NextResponse> {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: "Administrator authentication is required." },
      { status: 401 },
    );
  }

  const { sessionId } = await context.params;

  const reports = await prisma.report.findMany({
    where: {
      sessionId,
    },
    orderBy: {
      createdAt: "desc",
    },
    take: 10,
    select: {
      id: true,
      status: true,
      url: true,
      error: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  return NextResponse.json({
    reports,
  });
}

export async function POST(
  _request: Request,
  context: ReportRouteContext,
): Promise<NextResponse> {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      { error: "Administrator authentication is required." },
      { status: 401 },
    );
  }

  const { sessionId } = await context.params;

  const session = await prisma.session.findUnique({
    where: {
      id: sessionId,
    },
    select: {
      id: true,
    },
  });

  if (!session) {
    return NextResponse.json(
      { error: "Feedback session not found." },
      { status: 404 },
    );
  }

  const activeReport = await prisma.report.findFirst({
    where: {
      sessionId,
      status: {
        in: [ReportStatus.QUEUED, ReportStatus.PROCESSING],
      },
    },
    orderBy: {
      createdAt: "desc",
    },
    select: {
      id: true,
      status: true,
    },
  });

  if (activeReport) {
    return NextResponse.json(
      {
        error: "A report is already being generated for this session.",
        reportId: activeReport.id,
        status: activeReport.status,
      },
      { status: 409 },
    );
  }

  const report = await prisma.report.create({
    data: {
      sessionId,
      status: ReportStatus.QUEUED,
    },
    select: {
      id: true,
    },
  });

  try {
    await inngest.send({
      name: "report/generate.pdf",
      data: {
        reportId: report.id,
        sessionId,
        requestedBy: "administrator",
      },
    });
  } catch (error) {
    console.error("Unable to queue PDF report generation.", error);

    await prisma.report.update({
      where: {
        id: report.id,
      },
      data: {
        status: ReportStatus.FAILED,
        error: "The report could not be queued for generation.",
      },
    });

    return NextResponse.json(
      {
        error: "The report could not be queued. Please try again.",
      },
      { status: 503 },
    );
  }

  return NextResponse.json(
    {
      reportId: report.id,
      status: ReportStatus.QUEUED,
    },
    {
      status: 202,
    },
  );
}
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should complete successfully.

---

## Step 8.7 — Create the admin report panel

### The Target

Create a dashboard panel where administrators can request and download reports.

### The Concept

The report panel polls its protected API endpoint every five seconds while it is open.

It displays each report as one of these states:

```text
QUEUED      → waiting for worker
PROCESSING  → PDF is being generated
COMPLETE    → download available
FAILED      → error shown and retry possible
```

### The Implementation

Create this file.

### `src/components/admin/report-panel.tsx`

```tsx
"use client";

import { useCallback, useEffect, useState } from "react";

type ReportStatus = "QUEUED" | "PROCESSING" | "COMPLETE" | "FAILED";

type Report = {
  id: string;
  status: ReportStatus;
  url: string | null;
  error: string | null;
  createdAt: string;
  updatedAt: string;
};

type ReportsResponse = {
  reports: Report[];
};

function formatDate(value: string): string {
  return new Intl.DateTimeFormat("en", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

function statusClasses(status: ReportStatus): string {
  switch (status) {
    case "COMPLETE":
      return "bg-emerald-100 text-emerald-800";
    case "FAILED":
      return "bg-red-100 text-red-800";
    case "PROCESSING":
      return "bg-indigo-100 text-indigo-800";
    case "QUEUED":
      return "bg-amber-100 text-amber-800";
  }
}

export function ReportPanel({ sessionId }: { sessionId: string }) {
  const [reports, setReports] = useState<Report[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRequesting, setIsRequesting] = useState(false);
  const [message, setMessage] = useState<string>("");

  const loadReports = useCallback(async () => {
    try {
      const response = await fetch(`/api/admin/reports/${sessionId}`, {
        cache: "no-store",
      });

      if (!response.ok) {
        throw new Error("Unable to load report history.");
      }

      const body = (await response.json()) as ReportsResponse;
      setReports(body.reports);
    } catch {
      setMessage("Could not load report history. Refresh the page to retry.");
    } finally {
      setIsLoading(false);
    }
  }, [sessionId]);

  useEffect(() => {
    void loadReports();

    const intervalId = window.setInterval(() => {
      void loadReports();
    }, 5_000);

    return () => window.clearInterval(intervalId);
  }, [loadReports]);

  async function requestReport() {
    setIsRequesting(true);
    setMessage("");

    try {
      const response = await fetch(`/api/admin/reports/${sessionId}`, {
        method: "POST",
      });

      const body = (await response.json()) as {
        error?: string;
      };

      if (!response.ok) {
        setMessage(body.error ?? "Could not queue the report.");
        return;
      }

      setMessage("Report queued. This panel will update when it is ready.");
      await loadReports();
    } catch {
      setMessage("Could not contact the report service. Please try again.");
    } finally {
      setIsRequesting(false);
    }
  }

  const hasActiveReport = reports.some(
    (report) =>
      report.status === "QUEUED" || report.status === "PROCESSING",
  );

  return (
    <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-xl font-bold text-slate-950">PDF executive report</h2>

      <p className="mt-2 text-sm leading-6 text-slate-600">
        Generate a branded PDF summary containing response totals, scores,
        distributions, and written feedback.
      </p>

      <button
        className="mt-5 inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-slate-950 px-4 py-3 font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:bg-slate-400"
        disabled={isRequesting || hasActiveReport}
        onClick={() => void requestReport()}
        type="button"
      >
        {isRequesting
          ? "Queueing report…"
          : hasActiveReport
            ? "Report generation in progress"
            : "Generate PDF report"}
      </button>

      {message ? (
        <p
          aria-live="polite"
          className="mt-4 rounded-xl bg-slate-100 p-3 text-sm text-slate-700"
        >
          {message}
        </p>
      ) : null}

      {isLoading ? (
        <p className="mt-5 text-sm text-slate-500">Loading report history…</p>
      ) : reports.length === 0 ? (
        <p className="mt-5 text-sm text-slate-500">
          No PDF reports have been requested yet.
        </p>
      ) : (
        <ul className="mt-5 space-y-3">
          {reports.map((report) => (
            <li
              className="rounded-xl border border-slate-200 p-4"
              key={report.id}
            >
              <div className="flex flex-wrap items-center justify-between gap-3">
                <span
                  className={`rounded-full px-3 py-1 text-xs font-bold ${statusClasses(
                    report.status,
                  )}`}
                >
                  {report.status}
                </span>

                <span className="text-xs text-slate-500">
                  Requested {formatDate(report.createdAt)}
                </span>
              </div>

              {report.status === "COMPLETE" && report.url ? (
                <a
                  className="mt-4 inline-flex min-h-10 items-center rounded-lg bg-indigo-600 px-4 py-2 text-sm font-semibold text-white transition hover:bg-indigo-700"
                  href={report.url}
                  rel="noreferrer"
                  target="_blank"
                >
                  Download PDF
                </a>
              ) : null}

              {report.status === "FAILED" && report.error ? (
                <p className="mt-3 text-sm leading-6 text-red-700">
                  {report.error}
                </p>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both commands should succeed.

---

## Step 8.8 — Add the report panel to the session dashboard

### The Target

Display the report panel beside the QR-code and session details controls.

### The Concept

The dashboard already contains the operational controls for a session. PDF reporting belongs in the same administrator workspace.

### The Implementation

Open:

### `src/app/(admin)/admin/sessions/[sessionId]/page.tsx`

Add this import with the other component imports:

```tsx
import { ReportPanel } from "@/components/admin/report-panel";
```

Find this existing section near the bottom of the `<aside>`:

```tsx
<section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
```

After that complete session-details section closes, add:

```tsx
<ReportPanel sessionId={analytics.session.id} />
```

The final `<aside>` structure should resemble:

```tsx
<aside>
  <QrCodeCard
    participantUrl={participantUrl}
    sessionId={analytics.session.id}
  />

  <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
    {/* Existing session details content remains unchanged. */}
  </section>

  <ReportPanel sessionId={analytics.session.id} />
</aside>
```

### The Verification

Open:

```text
http://localhost:3000/admin/sessions/REACT-2026-Q3
```

You should see a new panel titled:

```text
PDF executive report
```

Click:

```text
Generate PDF report
```

Then open the Inngest dashboard:

```text
http://localhost:8288
```

Verify a run begins for:

```text
generate-pdf-report
```

Wait for completion.

The report panel should automatically update to:

```text
COMPLETE
```

Click:

```text
Download PDF
```

During local development, the browser should open a URL similar to:

```text
http://localhost:3000/reports/REACT-2026-Q3-<report-id>.pdf
```

Confirm the PDF contains session analytics and written feedback.

---

## Step 8.9 — Add a retry-friendly offline submission outbox

### The Target

Create a browser outbox that stores failed submission requests and retries them when the device reconnects.

### The Concept

A local draft protects unfinished form answers. An outbox protects a completed submission that could not reach the server.

Think of it as an envelope waiting in an outbox:

```text
Participant presses Submit
        ↓
Network unavailable
        ↓
Submission envelope saved locally
        ↓
Browser regains connection
        ↓
Submission retried automatically
```

The submission ID remains stable, so retries remain idempotent.

### The Implementation

Create this file.

### `src/lib/submission-outbox.ts`

```ts
"use client";

import type { FeedbackSubmissionInput } from "@/lib/feedback-submission";

const OUTBOX_STORAGE_KEY = "greymatter-feedback:submission-outbox";

type OutboxItem = {
  payload: FeedbackSubmissionInput;
  createdAt: string;
};

function loadOutbox(): OutboxItem[] {
  try {
    const storedValue = window.localStorage.getItem(OUTBOX_STORAGE_KEY);

    if (!storedValue) {
      return [];
    }

    const parsedValue = JSON.parse(storedValue) as unknown;

    return Array.isArray(parsedValue) ? (parsedValue as OutboxItem[]) : [];
  } catch {
    return [];
  }
}

function saveOutbox(items: OutboxItem[]): void {
  window.localStorage.setItem(OUTBOX_STORAGE_KEY, JSON.stringify(items));
}

export function enqueueSubmission(payload: FeedbackSubmissionInput): void {
  const outbox = loadOutbox();

  const alreadyQueued = outbox.some(
    (item) => item.payload.submissionId === payload.submissionId,
  );

  if (!alreadyQueued) {
    outbox.push({
      payload,
      createdAt: new Date().toISOString(),
    });

    saveOutbox(outbox);
  }
}

export async function flushSubmissionOutbox(): Promise<number> {
  if (!navigator.onLine) {
    return 0;
  }

  const outbox = loadOutbox();
  const remainingItems: OutboxItem[] = [];
  let submittedCount = 0;

  for (const item of outbox) {
    try {
      const response = await fetch("/api/feedback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(item.payload),
      });

      /**
       * A 202 means the server accepted the item.
       * A 409 can happen after an accepted submission is retried after the
       * form changes; retain it so the participant can review the draft.
       */
      if (response.status === 202) {
        submittedCount += 1;
      } else {
        remainingItems.push(item);
      }
    } catch {
      remainingItems.push(item);
    }
  }

  saveOutbox(remainingItems);

  return submittedCount;
}
```

Now update the participant form.

Open:

### `src/components/participant/feedback-form.tsx`

Add this import:

```tsx
import {
  enqueueSubmission,
  flushSubmissionOutbox,
} from "@/lib/submission-outbox";
```

Add this effect inside the component, after the existing draft restoration `useEffect`:

```tsx
useEffect(() => {
  async function retryQueuedSubmissions() {
    const submittedCount = await flushSubmissionOutbox();

    if (submittedCount > 0) {
      console.info(
        `GreyMatter Feedback submitted ${submittedCount} queued response(s).`,
      );
    }
  }

  function handleOnline() {
    void retryQueuedSubmissions();
  }

  window.addEventListener("online", handleOnline);
  void retryQueuedSubmissions();

  return () => {
    window.removeEventListener("online", handleOnline);
  };
}, []);
```

Inside `handleSubmit`, replace the existing `try` block’s `catch` section:

```tsx
    } catch {
      setSubmissionState({
        kind: "error",
        message:
          "Your device could not reach the feedback service. Your draft is still saved, so please try again when you have a connection.",
      });
    }
```

with this complete version:

```tsx
    } catch {
      enqueueSubmission({
        submissionId,
        sessionId,
        formVersionId,
        answers: submittedAnswers,
        metadata: getScreenMetadata(),
      });

      setSubmissionState({
        kind: "error",
        message:
          "Your device is offline. Your completed feedback was saved securely on this device and will retry automatically when you reconnect.",
      });
    }
```

### The Verification

1. Start the application:

   ```bash
   npm run dev
   ```

2. Open a participant form:

   ```text
   http://localhost:3000/e/REACT-2026-Q3
   ```

3. Complete the required questions.

4. In browser developer tools, open the **Network** panel and select:

   ```text
   Offline
   ```

5. Submit the form.

6. Confirm you see the offline message.

7. In browser developer tools, inspect local storage. You should see:

   ```text
   greymatter-feedback:submission-outbox
   ```

8. Turn network connectivity back on.

9. Wait a few seconds.

10. Open the Inngest dashboard and confirm the queued feedback submission is processed.

> The current page does not automatically switch to the success screen after an outbox retry. The submission is safely delivered in the background. Refreshing the participant page will show the cleared draft after successful delivery in a future enhancement.

---

## Step 8.10 — Add a basic service worker

### The Target

Cache core static assets so the application shell remains more resilient when connectivity is interrupted.

### The Concept

A service worker is a small browser-side network helper.

It can store selected resources locally. When the network is unavailable, the browser can still load previously cached static files.

This tutorial uses a conservative strategy:

- Cache only successful `GET` requests for same-origin static assets.
- Never cache feedback API requests.
- Never cache admin API responses.
- Let the submission outbox handle failed POST requests.

### The Implementation

Create this file.

### `public/sw.js`

```js
const CACHE_NAME = "greymatter-feedback-static-v1";

self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    self.clients.claim(),
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  const url = new URL(request.url);

  if (
    request.method !== "GET" ||
    url.origin !== self.location.origin ||
    url.pathname.startsWith("/api/")
  ) {
    return;
  }

  event.respondWith(
    caches.match(request).then(async (cachedResponse) => {
      const networkResponsePromise = fetch(request)
        .then((networkResponse) => {
          if (networkResponse.ok && request.destination !== "document") {
            const responseCopy = networkResponse.clone();

            void caches.open(CACHE_NAME).then((cache) => {
              void cache.put(request, responseCopy);
            });
          }

          return networkResponse;
        })
        .catch(() => cachedResponse);

      return cachedResponse ?? networkResponsePromise;
    }),
  );
});
```

Create a registration component.

### `src/components/service-worker-registration.tsx`

```tsx
"use client";

import { useEffect } from "react";

export function ServiceWorkerRegistration() {
  useEffect(() => {
    if (
      process.env.NODE_ENV === "development" ||
      !("serviceWorker" in navigator)
    ) {
      return;
    }

    void navigator.serviceWorker.register("/sw.js").catch((error: unknown) => {
      console.error("Unable to register GreyMatter service worker.", error);
    });
  }, []);

  return null;
}
```

Update the root layout.

### `src/app/layout.tsx`

Add this import:

```tsx
import { ServiceWorkerRegistration } from "@/components/service-worker-registration";
```

Then add the component inside `<body>`, before `{children}`:

```tsx
<ServiceWorkerRegistration />
{children}
```

The relevant section becomes:

```tsx
<body
  className={`${geistSans.variable} ${geistMono.variable} min-h-screen bg-slate-50 font-sans text-slate-950 antialiased`}
>
  <ServiceWorkerRegistration />
  {children}
</body>
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

For production-like service worker testing:

```bash
npm run build
npm run start
```

Open:

```text
http://localhost:3000
```

In browser developer tools:

1. Open **Application**.
2. Open **Service Workers**.
3. Confirm `/sw.js` is registered.
4. Visit a participant page once.
5. Switch Network to offline.
6. Refresh the page.

Previously loaded static assets should remain available. Dynamic Neon-backed pages still need network access to fetch fresh server-rendered data, which is expected.

---

## Step 8.11 — Add automated unit tests

### The Target

Add a test runner and unit tests for critical analytics calculations.

### The Concept

Automated tests are repeatable checks. They help prevent a future code change from silently breaking a core business rule such as NPS calculation.

### The Implementation

Install Vitest:

```bash
npm install --save-dev vitest
```

Add this script to `package.json`:

```json
{
  "scripts": {
    "test": "vitest run"
  }
}
```

Create a pure analytics utility.

### `src/lib/analytics-math.ts`

```ts
export function calculateAverage(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }

  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

export function calculateNps(values: number[]) {
  if (values.length === 0) {
    return {
      score: null,
      promoters: 0,
      passives: 0,
      detractors: 0,
    };
  }

  const promoters = values.filter((value) => value >= 9).length;
  const passives = values.filter((value) => value >= 7 && value <= 8).length;
  const detractors = values.filter((value) => value <= 6).length;

  return {
    score: Math.round(((promoters - detractors) / values.length) * 100),
    promoters,
    passives,
    detractors,
  };
}
```

Create the test file.

### `src/lib/analytics-math.test.ts`

```ts
import { describe, expect, it } from "vitest";
import { calculateAverage, calculateNps } from "./analytics-math";

describe("calculateAverage", () => {
  it("returns null for no values", () => {
    expect(calculateAverage([])).toBeNull();
  });

  it("calculates a numeric average", () => {
    expect(calculateAverage([3, 4, 5])).toBe(4);
  });
});

describe("calculateNps", () => {
  it("returns null for no NPS values", () => {
    expect(calculateNps([])).toEqual({
      score: null,
      promoters: 0,
      passives: 0,
      detractors: 0,
    });
  });

  it("calculates promoters, passives, detractors, and NPS", () => {
    expect(calculateNps([10, 9, 8, 7, 6, 0])).toEqual({
      score: 0,
      promoters: 2,
      passives: 2,
      detractors: 2,
    });
  });

  it("calculates a positive NPS", () => {
    expect(calculateNps([10, 10, 9, 8, 6])).toEqual({
      score: 40,
      promoters: 3,
      passives: 1,
      detractors: 1,
    });
  });
});
```

Now update `src/lib/session-analytics.ts`.

Add this import:

```ts
import { calculateAverage, calculateNps } from "@/lib/analytics-math";
```

Delete the existing local functions:

```ts
function calculateAverage(...)
```

and:

```ts
function calculateNps(...)
```

The analytics file should now use the imported tested functions.

### The Verification

Run:

```bash
npm test
```

Expected output includes:

```text
3 passed
```

Then run:

```bash
npm run lint
npm run build
```

Both commands should succeed.

---

## Step 8.12 — Production deployment checklist

### The Target

Prepare GreyMatter Feedback for production deployment.

### The Concept

A production deployment is not merely “upload the application.” It is the process of connecting secure infrastructure, environment variables, URLs, background workers, and storage.

The recommended deployment architecture is:

```text
Vercel or similar Next.js host
        ↓
Neon PostgreSQL
        ↓
Inngest hosted service
        ↓
Upstash Redis
        ↓
S3-compatible object storage
```

### The Implementation

## 1. Deploy the Next.js application

A Vercel deployment is a natural fit for Next.js.

1. Push the project to a private Git repository.
2. Visit:

   ```text
   https://vercel.com
   ```

3. Import the repository.
4. Set the production environment variables listed below.
5. Deploy.

## 2. Configure production environment variables

Set these values in your deployment platform:

```dotenv
DATABASE_URL="your-neon-pooled-connection-url"
DIRECT_URL="your-neon-direct-connection-url"

IP_HASH_SECRET="long-random-secret"
ADMIN_SESSION_SECRET="different-long-random-secret"
ADMIN_PASSWORD="strong-production-admin-password"

NEXT_PUBLIC_APP_URL="https://feedback.your-domain.example"

INNGEST_EVENT_KEY="production-inngest-event-key"
INNGEST_SIGNING_KEY="production-inngest-signing-key"
INNGEST_DEV="0"

UPSTASH_REDIS_REST_URL="https://..."
UPSTASH_REDIS_REST_TOKEN="..."

S3_REGION="auto-or-your-region"
S3_BUCKET="greymatter-feedback-reports"
S3_ACCESS_KEY_ID="..."
S3_SECRET_ACCESS_KEY="..."
S3_ENDPOINT="https://your-s3-compatible-endpoint"
```

## 3. Configure Neon

Use the Neon pooled connection URL for:

```dotenv
DATABASE_URL
```

Use the direct Neon connection URL for:

```dotenv
DIRECT_URL
```

Run migrations against production only through a controlled deployment process:

```bash
npx prisma migrate deploy
```

Do not use this in production:

```bash
npx prisma migrate dev
```

`migrate dev` is for development because it can create new migrations.

## 4. Configure Inngest

In your Inngest application settings, sync this production URL:

```text
https://feedback.your-domain.example/api/inngest
```

Confirm these functions appear:

```text
process-feedback-submission
generate-pdf-report
```

## 5. Configure report storage

For Amazon S3, use a private bucket and expose report downloads through a protected endpoint or signed URLs in a hardened production implementation.

For Cloudflare R2 or another S3-compatible provider, use the corresponding endpoint and credentials.

> The tutorial’s direct object URL approach is appropriate only when reports are safe to expose publicly. Feedback reports often contain sensitive written comments, so production deployments should prefer private storage and signed administrator-only download URLs.

## 6. Configure a custom domain

Set:

```text
feedback.your-domain.example
```

Then update:

```dotenv
NEXT_PUBLIC_APP_URL="https://feedback.your-domain.example"
```

Redeploy after changing it.

This matters because QR codes must contain the final public URL, not:

```text
http://localhost:3000
```

### The Verification

After deployment:

1. Open the public landing page.
2. Sign in to the administrator portal.
3. Create a test event and session.
4. Publish a test form.
5. Open the participant QR URL on a phone.
6. Submit feedback.
7. Confirm an Inngest submission run completes.
8. Confirm the dashboard updates.
9. Export CSV.
10. Generate and download a PDF report.
11. Confirm a second submission from the same device is rate-limited according to your Upstash configuration.

---

# Part 8 Reference: Production Security Checklist

Before real-world use, verify all of the following.

```text
[ ] .env is not committed to Git.
[ ] Production uses a strong, unique ADMIN_PASSWORD.
[ ] ADMIN_SESSION_SECRET is random and at least 32 characters.
[ ] IP_HASH_SECRET is random and at least 32 characters.
[ ] Neon uses SSL-enabled connection URLs.
[ ] Upstash Redis is configured in production.
[ ] INNGEST_DEV is set to 0 in production.
[ ] Inngest sync URL uses HTTPS.
[ ] Admin routes require valid signed sessions.
[ ] CSV export requires administrator authentication.
[ ] PDF report access is protected if reports contain sensitive information.
[ ] Published forms are never edited directly.
[ ] New form changes occur through versioned drafts.
[ ] Error monitoring and uptime monitoring are configured.
[ ] Privacy, retention, and deletion policies are documented.
```

---

# GreyMatter Feedback: Completed Architecture

You have now built GreyMatter Feedback as a complete QR-first feedback system.

```text
Administrator
   │
   ├── Creates event or course
   ├── Creates session
   ├── Authors versioned form draft
   ├── Publishes form
   ├── Downloads QR code
   ├── Reviews analytics
   ├── Exports CSV
   └── Requests PDF report
          │
          ▼
      Next.js 16 + React 19
          │
          ├── Neon PostgreSQL + Prisma
          │     ├── Events
          │     ├── Sessions
          │     ├── Form versions
          │     ├── Questions
          │     ├── Responses
          │     ├── Answers
          │     └── Reports
          │
          └── Inngest
                ├── feedback/submitted
                └── report/generate.pdf

Participant
   │
   ├── Scans QR code
   ├── Opens mobile form
   ├── Restores local draft if needed
   ├── Receives haptic feedback on supported devices
   ├── Submits securely
   └── Gets confirmation while Inngest processes work
```

# Final Verification Commands

Run all final checks:

```bash
npx prisma validate
```

```bash
npm run db:test
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

For complete local testing, run:

```bash
npm run dev
```

In another terminal:

```bash
npm run inngest:dev
```

Then test:

```text
Participant form:
http://localhost:3000/e/REACT-2026-Q3?src=qr

Administrator login:
http://localhost:3000/admin/login

Administrator dashboard:
http://localhost:3000/admin/sessions/REACT-2026-Q3

Inngest dashboard:
http://localhost:8288
```
