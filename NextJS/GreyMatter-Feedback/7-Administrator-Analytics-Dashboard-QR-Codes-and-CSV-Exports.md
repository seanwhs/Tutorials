# Part 7: Build the Administrator Analytics Dashboard, QR Codes, and CSV Exports

GreyMatter Feedback can now accept participant responses and safely store them in Neon through Inngest.

In this part, we will build the administrator reporting experience.

Administrators will be able to:

- Open a session analytics dashboard.
- View total submitted responses.
- View average rating scores.
- View Net Promoter Score, or NPS.
- View question-level response distributions.
- Read qualitative written feedback.
- Generate a QR-code image for a session URL.
- Download response data as a CSV file.
- Automatically refresh dashboard data while it is open.

By the end of this part, a completed participant response will become useful reporting information for the event organizer.

---

## Step 7.1 — Create analytics types and calculation helpers

### The Target

Create shared server-side helpers that calculate session metrics from responses and answers.

### The Concept

Raw feedback records are like individual paper feedback slips in a box. Analytics summarize those slips into useful answers:

```text
How many people responded?
What was the average rating?
Would people recommend the session?
What did people write?
```

We will calculate analytics from the authoritative response and answer records in Neon.

This is intentionally simple and trustworthy:

```text
Neon responses and answers
        ↓
Analytics calculation helper
        ↓
Admin dashboard
```

For early and moderate traffic, calculating directly from stored answers is a strong default. At very high volume, you could later add pre-calculated aggregate tables, but that adds synchronization complexity.

### The Implementation

Create this file.

### `src/lib/session-analytics.ts`

```ts
import "server-only";

import { QuestionType } from "@prisma/client";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import {
  parseChoiceOptions,
  parseQuestionSettings,
  type RatingSettings,
} from "@/types/forms";

type NumericDistribution = Array<{
  value: number;
  count: number;
}>;

export type RatingQuestionAnalytics = {
  id: string;
  formVersionNumber: number;
  questionText: string;
  questionType: QuestionType.RATING;
  responseCount: number;
  average: number | null;
  minimum: number;
  maximum: number;
  distribution: NumericDistribution;
};

export type NpsQuestionAnalytics = {
  id: string;
  formVersionNumber: number;
  questionText: string;
  questionType: QuestionType.NPS;
  responseCount: number;
  promoters: number;
  passives: number;
  detractors: number;
  score: number | null;
  distribution: NumericDistribution;
};

export type ChoiceQuestionAnalytics = {
  id: string;
  formVersionNumber: number;
  questionText: string;
  questionType: QuestionType.CHOICE;
  responseCount: number;
  distribution: Array<{
    option: string;
    count: number;
  }>;
};

export type TextQuestionAnalytics = {
  id: string;
  formVersionNumber: number;
  questionText: string;
  questionType: QuestionType.TEXT;
  responseCount: number;
  comments: Array<{
    responseId: string;
    submittedAt: Date;
    value: string;
  }>;
};

export type SessionAnalytics = {
  session: {
    id: string;
    title: string;
    eventTitle: string;
    isActive: boolean;
    activeFormVersionNumber: number | null;
  };
  overview: {
    totalResponses: number;
    averageRating: number | null;
    primaryNps: number | null;
    latestSubmissionAt: Date | null;
  };
  ratingQuestions: RatingQuestionAnalytics[];
  npsQuestions: NpsQuestionAnalytics[];
  choiceQuestions: ChoiceQuestionAnalytics[];
  textQuestions: TextQuestionAnalytics[];
};

function createNumericDistribution(
  values: number[],
  minimum: number,
  maximum: number,
): NumericDistribution {
  return Array.from(
    { length: maximum - minimum + 1 },
    (_, index) => minimum + index,
  ).map((value) => ({
    value,
    count: values.filter((submittedValue) => submittedValue === value).length,
  }));
}

function calculateAverage(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }

  const total = values.reduce((sum, value) => sum + value, 0);

  return total / values.length;
}

function calculateNps(values: number[]) {
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

/**
 * Retrieves all current session analytics from the normalized response data.
 *
 * Questions are deliberately grouped by question ID and form version. This
 * means historical form versions remain truthful even if a later version has
 * different question wording or different options.
 */
export async function getSessionAnalytics(
  sessionId: string,
): Promise<SessionAnalytics> {
  const session = await prisma.session.findUnique({
    where: {
      id: sessionId,
    },
    include: {
      event: {
        select: {
          title: true,
        },
      },
      activeFormVersion: {
        select: {
          versionNumber: true,
        },
      },
      responses: {
        orderBy: {
          submittedAt: "desc",
        },
        include: {
          formVersion: {
            select: {
              versionNumber: true,
            },
          },
          answers: {
            include: {
              question: true,
            },
          },
        },
      },
    },
  });

  if (!session) {
    notFound();
  }

  const ratingQuestions = new Map<
    string,
    {
      questionText: string;
      formVersionNumber: number;
      settings: RatingSettings;
      values: number[];
    }
  >();

  const npsQuestions = new Map<
    string,
    {
      questionText: string;
      formVersionNumber: number;
      values: number[];
    }
  >();

  const choiceQuestions = new Map<
    string,
    {
      questionText: string;
      formVersionNumber: number;
      options: string[];
      values: string[];
    }
  >();

  const textQuestions = new Map<
    string,
    {
      questionText: string;
      formVersionNumber: number;
      comments: Array<{
        responseId: string;
        submittedAt: Date;
        value: string;
      }>;
    }
  >();

  for (const response of session.responses) {
    for (const answer of response.answers) {
      const question = answer.question;

      if (
        question.questionType === QuestionType.RATING &&
        answer.numericValue !== null
      ) {
        const existing = ratingQuestions.get(question.id);
        const settings = parseQuestionSettings(
          question.questionType,
          question.settings,
        ) as RatingSettings;

        if (existing) {
          existing.values.push(answer.numericValue);
        } else {
          ratingQuestions.set(question.id, {
            questionText: question.questionText,
            formVersionNumber: response.formVersion.versionNumber,
            settings,
            values: [answer.numericValue],
          });
        }
      }

      if (
        question.questionType === QuestionType.NPS &&
        answer.numericValue !== null
      ) {
        const existing = npsQuestions.get(question.id);

        if (existing) {
          existing.values.push(answer.numericValue);
        } else {
          npsQuestions.set(question.id, {
            questionText: question.questionText,
            formVersionNumber: response.formVersion.versionNumber,
            values: [answer.numericValue],
          });
        }
      }

      if (
        question.questionType === QuestionType.CHOICE &&
        answer.textValue !== null
      ) {
        const existing = choiceQuestions.get(question.id);

        if (existing) {
          existing.values.push(answer.textValue);
        } else {
          choiceQuestions.set(question.id, {
            questionText: question.questionText,
            formVersionNumber: response.formVersion.versionNumber,
            options: parseChoiceOptions(question.options),
            values: [answer.textValue],
          });
        }
      }

      if (
        question.questionType === QuestionType.TEXT &&
        answer.textValue !== null
      ) {
        const existing = textQuestions.get(question.id);
        const comment = {
          responseId: response.id,
          submittedAt: response.submittedAt,
          value: answer.textValue,
        };

        if (existing) {
          existing.comments.push(comment);
        } else {
          textQuestions.set(question.id, {
            questionText: question.questionText,
            formVersionNumber: response.formVersion.versionNumber,
            comments: [comment],
          });
        }
      }
    }
  }

  const ratingAnalytics: RatingQuestionAnalytics[] = Array.from(
    ratingQuestions.entries(),
  ).map(([id, question]) => ({
    id,
    formVersionNumber: question.formVersionNumber,
    questionText: question.questionText,
    questionType: QuestionType.RATING,
    responseCount: question.values.length,
    average: calculateAverage(question.values),
    minimum: question.settings.min,
    maximum: question.settings.max,
    distribution: createNumericDistribution(
      question.values,
      question.settings.min,
      question.settings.max,
    ),
  }));

  const npsAnalytics: NpsQuestionAnalytics[] = Array.from(
    npsQuestions.entries(),
  ).map(([id, question]) => {
    const result = calculateNps(question.values);

    return {
      id,
      formVersionNumber: question.formVersionNumber,
      questionText: question.questionText,
      questionType: QuestionType.NPS,
      responseCount: question.values.length,
      promoters: result.promoters,
      passives: result.passives,
      detractors: result.detractors,
      score: result.score,
      distribution: createNumericDistribution(question.values, 0, 10),
    };
  });

  const choiceAnalytics: ChoiceQuestionAnalytics[] = Array.from(
    choiceQuestions.entries(),
  ).map(([id, question]) => ({
    id,
    formVersionNumber: question.formVersionNumber,
    questionText: question.questionText,
    questionType: QuestionType.CHOICE,
    responseCount: question.values.length,
    distribution: question.options.map((option) => ({
      option,
      count: question.values.filter((value) => value === option).length,
    })),
  }));

  const textAnalytics: TextQuestionAnalytics[] = Array.from(
    textQuestions.entries(),
  ).map(([id, question]) => ({
    id,
    formVersionNumber: question.formVersionNumber,
    questionText: question.questionText,
    questionType: QuestionType.TEXT,
    responseCount: question.comments.length,
    comments: question.comments,
  }));

  const allRatingValues = ratingAnalytics.flatMap((question) =>
    question.distribution.flatMap(({ value, count }) =>
      Array.from({ length: count }, () => value),
    ),
  );

  return {
    session: {
      id: session.id,
      title: session.title,
      eventTitle: session.event.title,
      isActive: session.isActive,
      activeFormVersionNumber:
        session.activeFormVersion?.versionNumber ?? null,
    },
    overview: {
      totalResponses: session.responses.length,
      averageRating: calculateAverage(allRatingValues),
      primaryNps: npsAnalytics[0]?.score ?? null,
      latestSubmissionAt: session.responses[0]?.submittedAt ?? null,
    },
    ratingQuestions: ratingAnalytics,
    npsQuestions: npsAnalytics,
    choiceQuestions: choiceAnalytics,
    textQuestions: textAnalytics,
  };
}
```

### The Verification

Run:

```bash
npm run lint
```

Then run:

```bash
npm run build
```

Both commands should complete successfully.

---

## Step 7.2 — Create dashboard display helpers

### The Target

Create small reusable components for metrics, score bars, and automatic dashboard refreshes.

### The Concept

A dashboard should make information easy to scan.

Instead of presenting raw database values, we will use:

- **Metric cards** for important totals.
- **Distribution bars** for ratings and choice counts.
- **A refresh helper** that checks for new responses every 15 seconds.

The automatic refresh is lightweight polling. It is not a permanent socket connection. This is a practical approach for an admin dashboard where updates every few seconds are sufficient.

### The Implementation

Create this Client Component.

### `src/components/admin/analytics-auto-refresh.tsx`

```tsx
"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";

export function AnalyticsAutoRefresh({
  intervalMilliseconds = 15_000,
}: {
  intervalMilliseconds?: number;
}) {
  const router = useRouter();

  useEffect(() => {
    const intervalId = window.setInterval(() => {
      router.refresh();
    }, intervalMilliseconds);

    return () => {
      window.clearInterval(intervalId);
    };
  }, [intervalMilliseconds, router]);

  return (
    <p className="text-sm text-slate-500">
      Dashboard refreshes automatically every 15 seconds.
    </p>
  );
}
```

Create the metric card component.

### `src/components/admin/metric-card.tsx`

```tsx
type MetricCardProps = {
  label: string;
  value: string;
  description: string;
  tone?: "indigo" | "emerald" | "slate";
};

const toneClasses = {
  indigo: "border-indigo-200 bg-indigo-50 text-indigo-950",
  emerald: "border-emerald-200 bg-emerald-50 text-emerald-950",
  slate: "border-slate-200 bg-white text-slate-950",
};

export function MetricCard({
  label,
  value,
  description,
  tone = "slate",
}: MetricCardProps) {
  return (
    <article className={`rounded-2xl border p-5 shadow-sm ${toneClasses[tone]}`}>
      <p className="text-sm font-semibold opacity-70">{label}</p>
      <p className="mt-2 text-3xl font-bold tracking-tight">{value}</p>
      <p className="mt-2 text-sm leading-6 opacity-80">{description}</p>
    </article>
  );
}
```

Create a distribution bar component.

### `src/components/admin/distribution-bar.tsx`

```tsx
type DistributionBarProps = {
  label: string;
  count: number;
  maximumCount: number;
  colorClassName?: string;
};

export function DistributionBar({
  label,
  count,
  maximumCount,
  colorClassName = "bg-indigo-600",
}: DistributionBarProps) {
  const widthPercentage =
    maximumCount === 0 ? 0 : Math.round((count / maximumCount) * 100);

  return (
    <div className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-x-4 gap-y-2">
      <p className="truncate text-sm font-medium text-slate-700">{label}</p>
      <p className="text-sm font-semibold text-slate-950">{count}</p>

      <div
        aria-label={`${label}: ${count} responses`}
        className="col-span-2 h-3 overflow-hidden rounded-full bg-slate-100"
      >
        <div
          className={`h-full rounded-full transition-all ${colorClassName}`}
          style={{ width: `${widthPercentage}%` }}
        />
      </div>
    </div>
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

## Step 7.3 — Create the QR-code download component

### The Target

Create an administrator component that turns a participant session URL into a downloadable QR-code image.

### The Concept

A QR code is simply a machine-readable version of a URL.

For this session URL:

```text
https://your-domain.example/e/REACT-2026-Q3?src=qr
```

the QR image lets participants open the correct feedback form by scanning it with a phone camera.

We generate the image in the administrator’s browser. This means:

- No public QR generation API endpoint is needed.
- The generated QR contains exactly the displayed URL.
- Administrators can download a PNG immediately.

### The Implementation

Create this file.

### `src/components/admin/qr-code-card.tsx`

```tsx
"use client";

import { useEffect, useState } from "react";
import QRCode from "qrcode";

type QrCodeCardProps = {
  sessionId: string;
  participantUrl: string;
};

export function QrCodeCard({
  sessionId,
  participantUrl,
}: QrCodeCardProps) {
  const [imageUrl, setImageUrl] = useState<string>("");
  const [error, setError] = useState<string>("");

  useEffect(() => {
    let active = true;

    async function generateQrCode() {
      try {
        const generatedImageUrl = await QRCode.toDataURL(participantUrl, {
          errorCorrectionLevel: "M",
          margin: 2,
          width: 720,
          color: {
            dark: "#0f172a",
            light: "#ffffff",
          },
        });

        if (active) {
          setImageUrl(generatedImageUrl);
        }
      } catch {
        if (active) {
          setError("GreyMatter Feedback could not generate this QR code.");
        }
      }
    }

    void generateQrCode();

    return () => {
      active = false;
    };
  }, [participantUrl]);

  function downloadQrCode() {
    if (!imageUrl) {
      return;
    }

    const link = document.createElement("a");
    link.href = imageUrl;
    link.download = `greymatter-feedback-${sessionId}.png`;
    document.body.appendChild(link);
    link.click();
    link.remove();
  }

  async function copyParticipantUrl() {
    try {
      await navigator.clipboard.writeText(participantUrl);
      window.alert("Participant URL copied to your clipboard.");
    } catch {
      window.prompt("Copy this participant URL:", participantUrl);
    }
  }

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <h2 className="text-xl font-bold text-slate-950">Session QR code</h2>
      <p className="mt-2 text-sm leading-6 text-slate-600">
        Download this image for slides, posters, name cards, or printed event
        materials.
      </p>

      {error ? (
        <p className="mt-4 rounded-xl bg-red-50 p-4 text-sm text-red-800">
          {error}
        </p>
      ) : null}

      {imageUrl ? (
        <img
          alt={`QR code for GreyMatter Feedback session ${sessionId}`}
          className="mx-auto mt-6 aspect-square w-full max-w-xs rounded-xl border border-slate-200 bg-white p-3"
          src={imageUrl}
        />
      ) : (
        <div className="mx-auto mt-6 aspect-square w-full max-w-xs animate-pulse rounded-xl bg-slate-100" />
      )}

      <code className="mt-6 block overflow-x-auto rounded-xl bg-slate-100 p-3 text-xs text-slate-700">
        {participantUrl}
      </code>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <button
          className="min-h-12 rounded-xl bg-indigo-600 px-4 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:bg-indigo-300"
          disabled={!imageUrl}
          onClick={downloadQrCode}
          type="button"
        >
          Download PNG
        </button>

        <button
          className="min-h-12 rounded-xl border border-slate-300 bg-white px-4 py-3 font-semibold text-slate-800 transition hover:bg-slate-100"
          onClick={() => void copyParticipantUrl()}
          type="button"
        >
          Copy URL
        </button>
      </div>
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

Both commands should complete successfully.

---

## Step 7.4 — Create a protected CSV export endpoint

### The Target

Create an administrator-only route that downloads all session answers as a CSV file.

### The Concept

CSV stands for **Comma-Separated Values**. It is a plain-text spreadsheet format supported by Excel, Google Sheets, LibreOffice, and data-analysis tools.

Each row in our export represents one answer:

```text
Response ID, Submitted At, Form Version, Question, Question Type, Numeric Value, Text Value
```

This “one answer per row” layout is flexible because forms can vary between versions and sessions.

The CSV endpoint must confirm the administrator is signed in before returning feedback data.

### The Implementation

Create the folders:

```bash
mkdir -p "src/app/api/admin/export/[sessionId]"
```

Create this file.

### `src/app/api/admin/export/[sessionId]/route.ts`

```ts
import { NextResponse } from "next/server";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";

type ExportRouteContext = {
  params: Promise<{
    sessionId: string;
  }>;
};

function escapeCsvValue(value: string | number | null | undefined): string {
  const normalizedValue = value === null || value === undefined ? "" : String(value);

  return `"${normalizedValue.replaceAll('"', '""')}"`;
}

function createCsvFileName(sessionId: string): string {
  const date = new Date().toISOString().slice(0, 10);
  const safeSessionId = sessionId.replaceAll(/[^A-Za-z0-9-]/g, "-");

  return `greymatter-feedback-${safeSessionId}-${date}.csv`;
}

export async function GET(
  _request: Request,
  context: ExportRouteContext,
): Promise<NextResponse> {
  if (!(await isAdminAuthenticated())) {
    return NextResponse.json(
      {
        error: "Administrator authentication is required.",
      },
      {
        status: 401,
      },
    );
  }

  const { sessionId } = await context.params;

  const session = await prisma.session.findUnique({
    where: {
      id: sessionId,
    },
    include: {
      event: {
        select: {
          title: true,
        },
      },
      responses: {
        orderBy: {
          submittedAt: "asc",
        },
        include: {
          formVersion: {
            select: {
              versionNumber: true,
            },
          },
          answers: {
            include: {
              question: {
                select: {
                  questionText: true,
                  questionType: true,
                },
              },
            },
          },
        },
      },
    },
  });

  if (!session) {
    return NextResponse.json(
      {
        error: "Feedback session not found.",
      },
      {
        status: 404,
      },
    );
  }

  const rows = [
    [
      "Event",
      "Session ID",
      "Session Title",
      "Response ID",
      "Submitted At (UTC)",
      "Form Version",
      "Question",
      "Question Type",
      "Numeric Value",
      "Text Value",
    ],
    ...session.responses.flatMap((response) =>
      response.answers.map((answer) => [
        session.event.title,
        session.id,
        session.title,
        response.id,
        response.submittedAt.toISOString(),
        response.formVersion.versionNumber,
        answer.question.questionText,
        answer.question.questionType,
        answer.numericValue,
        answer.textValue,
      ]),
    ),
  ];

  const csv = `${rows
    .map((row) => row.map((value) => escapeCsvValue(value)).join(","))
    .join("\n")}\n`;

  return new NextResponse(csv, {
    headers: {
      "Content-Disposition": `attachment; filename="${createCsvFileName(session.id)}"`,
      "Content-Type": "text/csv; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}
```

### The Verification

Start the development server:

```bash
npm run dev
```

While signed in as an administrator, open:

```text
http://localhost:3000/api/admin/export/REACT-2026-Q3
```

Your browser should download a file similar to:

```text
greymatter-feedback-REACT-2026-Q3-2026-07-25.csv
```

Open it in a text editor or spreadsheet application.

You should see headers similar to:

```text
Event,Session ID,Session Title,Response ID,Submitted At (UTC),Form Version,...
```

Then test in a private/incognito browser window without signing in:

```text
http://localhost:3000/api/admin/export/REACT-2026-Q3
```

Expected response:

```json
{
  "error": "Administrator authentication is required."
}
```

with HTTP status `401`.

---

## Step 7.5 — Create the analytics dashboard page

### The Target

Create the protected session dashboard at:

```text
/admin/sessions/[sessionId]
```

### The Concept

The dashboard combines the tools built in this part:

```text
Neon response data
        ↓
Analytics helper
        ↓
Metric cards, distributions, comments
        ↓
CSV export and QR-code controls
```

The dashboard remains a Server Component so data is fetched securely on the server. The small QR and auto-refresh features are Client Components inside the server-rendered page.

### The Implementation

Create this file.

### `src/app/(admin)/admin/sessions/[sessionId]/page.tsx`

```tsx
import Link from "next/link";
import { notFound } from "next/navigation";
import { AnalyticsAutoRefresh } from "@/components/admin/analytics-auto-refresh";
import { DistributionBar } from "@/components/admin/distribution-bar";
import { MetricCard } from "@/components/admin/metric-card";
import { QrCodeCard } from "@/components/admin/qr-code-card";
import { prisma } from "@/lib/prisma";
import { getSessionAnalytics } from "@/lib/session-analytics";

type SessionDashboardPageProps = {
  params: Promise<{
    sessionId: string;
  }>;
};

export const dynamic = "force-dynamic";

function formatAverage(value: number | null): string {
  return value === null ? "—" : value.toFixed(1);
}

function formatNps(value: number | null): string {
  if (value === null) {
    return "—";
  }

  return value > 0 ? `+${value}` : String(value);
}

function formatDateTime(value: Date | null): string {
  if (!value) {
    return "No submissions yet";
  }

  return new Intl.DateTimeFormat("en", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(value);
}

export const metadata = {
  title: "Session Analytics",
};

export default async function SessionDashboardPage({
  params,
}: SessionDashboardPageProps) {
  const { sessionId } = await params;

  const sessionExists = await prisma.session.findUnique({
    where: {
      id: sessionId,
    },
    select: {
      id: true,
    },
  });

  if (!sessionExists) {
    notFound();
  }

  const analytics = await getSessionAnalytics(sessionId);

  const participantUrl = `${process.env.NEXT_PUBLIC_APP_URL}/e/${analytics.session.id}?src=qr`;

  return (
    <section>
      <div className="flex flex-col justify-between gap-5 xl:flex-row xl:items-start">
        <div>
          <Link
            className="text-sm font-semibold text-indigo-700 hover:text-indigo-900"
            href={`/admin/sessions/${analytics.session.id}/edit`}
          >
            ← Edit form
          </Link>

          <p className="mt-5 text-sm font-semibold text-indigo-700">
            {analytics.session.eventTitle}
          </p>

          <h1 className="mt-2 text-3xl font-bold tracking-tight text-slate-950">
            {analytics.session.title}
          </h1>

          <p className="mt-2 font-mono text-sm text-slate-500">
            {analytics.session.id}
          </p>
        </div>

        <div className="flex flex-col items-start gap-3 xl:items-end">
          <a
            className="inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700"
            href={`/api/admin/export/${analytics.session.id}`}
          >
            Export CSV
          </a>

          <AnalyticsAutoRefresh />
        </div>
      </div>

      <section className="mt-8 grid gap-4 md:grid-cols-3">
        <MetricCard
          description={`Latest response: ${formatDateTime(
            analytics.overview.latestSubmissionAt,
          )}`}
          label="Total responses"
          tone="indigo"
          value={String(analytics.overview.totalResponses)}
        />

        <MetricCard
          description="Average across all rating-question answers."
          label="Average rating"
          tone="emerald"
          value={formatAverage(analytics.overview.averageRating)}
        />

        <MetricCard
          description="Promoters minus detractors for the first NPS question."
          label="Net Promoter Score"
          value={formatNps(analytics.overview.primaryNps)}
        />
      </section>

      <section className="mt-10 grid gap-8 xl:grid-cols-[minmax(0,1fr)_360px]">
        <div className="space-y-8">
          <section>
            <h2 className="text-2xl font-bold tracking-tight text-slate-950">
              Rating questions
            </h2>

            {analytics.ratingQuestions.length === 0 ? (
              <p className="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-slate-600">
                No rating answers have been submitted yet.
              </p>
            ) : (
              <div className="mt-4 space-y-5">
                {analytics.ratingQuestions.map((question) => {
                  const maximumCount = Math.max(
                    ...question.distribution.map((item) => item.count),
                    0,
                  );

                  return (
                    <article
                      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
                      key={question.id}
                    >
                      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
                        <div>
                          <p className="text-sm font-semibold text-indigo-700">
                            Form version {question.formVersionNumber}
                          </p>
                          <h3 className="mt-1 text-lg font-bold text-slate-950">
                            {question.questionText}
                          </h3>
                        </div>

                        <div className="rounded-xl bg-indigo-50 px-4 py-3 text-center">
                          <p className="text-xs font-semibold uppercase tracking-wide text-indigo-700">
                            Average
                          </p>
                          <p className="mt-1 text-2xl font-bold text-indigo-950">
                            {formatAverage(question.average)} / {question.maximum}
                          </p>
                        </div>
                      </div>

                      <p className="mt-4 text-sm text-slate-600">
                        {question.responseCount}{" "}
                        {question.responseCount === 1 ? "answer" : "answers"}
                      </p>

                      <div className="mt-5 space-y-4">
                        {question.distribution.map((item) => (
                          <DistributionBar
                            count={item.count}
                            key={item.value}
                            label={`Score ${item.value}`}
                            maximumCount={maximumCount}
                          />
                        ))}
                      </div>
                    </article>
                  );
                })}
              </div>
            )}
          </section>

          <section>
            <h2 className="text-2xl font-bold tracking-tight text-slate-950">
              Recommendation scores
            </h2>

            {analytics.npsQuestions.length === 0 ? (
              <p className="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-slate-600">
                No NPS answers have been submitted yet.
              </p>
            ) : (
              <div className="mt-4 space-y-5">
                {analytics.npsQuestions.map((question) => {
                  const maximumCount = Math.max(
                    ...question.distribution.map((item) => item.count),
                    0,
                  );

                  return (
                    <article
                      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
                      key={question.id}
                    >
                      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-start">
                        <div>
                          <p className="text-sm font-semibold text-indigo-700">
                            Form version {question.formVersionNumber}
                          </p>
                          <h3 className="mt-1 text-lg font-bold text-slate-950">
                            {question.questionText}
                          </h3>
                        </div>

                        <div className="rounded-xl bg-emerald-50 px-4 py-3 text-center">
                          <p className="text-xs font-semibold uppercase tracking-wide text-emerald-700">
                            NPS
                          </p>
                          <p className="mt-1 text-2xl font-bold text-emerald-950">
                            {formatNps(question.score)}
                          </p>
                        </div>
                      </div>

                      <div className="mt-5 grid gap-3 sm:grid-cols-3">
                        <div className="rounded-xl bg-emerald-50 p-4">
                          <p className="text-sm font-semibold text-emerald-800">
                            Promoters
                          </p>
                          <p className="mt-1 text-2xl font-bold text-emerald-950">
                            {question.promoters}
                          </p>
                        </div>

                        <div className="rounded-xl bg-amber-50 p-4">
                          <p className="text-sm font-semibold text-amber-800">
                            Passives
                          </p>
                          <p className="mt-1 text-2xl font-bold text-amber-950">
                            {question.passives}
                          </p>
                        </div>

                        <div className="rounded-xl bg-red-50 p-4">
                          <p className="text-sm font-semibold text-red-800">
                            Detractors
                          </p>
                          <p className="mt-1 text-2xl font-bold text-red-950">
                            {question.detractors}
                          </p>
                        </div>
                      </div>

                      <div className="mt-5 space-y-4">
                        {question.distribution.map((item) => (
                          <DistributionBar
                            colorClassName={
                              item.value >= 9
                                ? "bg-emerald-600"
                                : item.value >= 7
                                  ? "bg-amber-500"
                                  : "bg-red-500"
                            }
                            count={item.count}
                            key={item.value}
                            label={`Score ${item.value}`}
                            maximumCount={maximumCount}
                          />
                        ))}
                      </div>
                    </article>
                  );
                })}
              </div>
            )}
          </section>

          <section>
            <h2 className="text-2xl font-bold tracking-tight text-slate-950">
              Choice questions
            </h2>

            {analytics.choiceQuestions.length === 0 ? (
              <p className="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-slate-600">
                No choice answers have been submitted yet.
              </p>
            ) : (
              <div className="mt-4 space-y-5">
                {analytics.choiceQuestions.map((question) => {
                  const maximumCount = Math.max(
                    ...question.distribution.map((item) => item.count),
                    0,
                  );

                  return (
                    <article
                      className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
                      key={question.id}
                    >
                      <p className="text-sm font-semibold text-indigo-700">
                        Form version {question.formVersionNumber}
                      </p>
                      <h3 className="mt-1 text-lg font-bold text-slate-950">
                        {question.questionText}
                      </h3>

                      <p className="mt-4 text-sm text-slate-600">
                        {question.responseCount}{" "}
                        {question.responseCount === 1 ? "answer" : "answers"}
                      </p>

                      <div className="mt-5 space-y-4">
                        {question.distribution.map((item) => (
                          <DistributionBar
                            count={item.count}
                            key={item.option}
                            label={item.option}
                            maximumCount={maximumCount}
                          />
                        ))}
                      </div>
                    </article>
                  );
                })}
              </div>
            )}
          </section>

          <section>
            <h2 className="text-2xl font-bold tracking-tight text-slate-950">
              Written feedback
            </h2>

            {analytics.textQuestions.length === 0 ? (
              <p className="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-slate-600">
                No written feedback has been submitted yet.
              </p>
            ) : (
              <div className="mt-4 space-y-5">
                {analytics.textQuestions.map((question) => (
                  <article
                    className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6"
                    key={question.id}
                  >
                    <p className="text-sm font-semibold text-indigo-700">
                      Form version {question.formVersionNumber}
                    </p>
                    <h3 className="mt-1 text-lg font-bold text-slate-950">
                      {question.questionText}
                    </h3>

                    <p className="mt-4 text-sm text-slate-600">
                      {question.responseCount}{" "}
                      {question.responseCount === 1 ? "comment" : "comments"}
                    </p>

                    <div className="mt-5 space-y-3">
                      {question.comments.map((comment) => (
                        <blockquote
                          className="rounded-xl bg-slate-50 p-4 text-slate-700"
                          key={comment.responseId}
                        >
                          <p className="whitespace-pre-wrap leading-7">
                            “{comment.value}”
                          </p>
                          <footer className="mt-3 text-xs text-slate-500">
                            Submitted {formatDateTime(comment.submittedAt)}
                          </footer>
                        </blockquote>
                      ))}
                    </div>
                  </article>
                ))}
              </div>
            )}
          </section>
        </div>

        <aside>
          <QrCodeCard
            participantUrl={participantUrl}
            sessionId={analytics.session.id}
          />

          <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <h2 className="text-xl font-bold text-slate-950">Session details</h2>

            <dl className="mt-5 space-y-4 text-sm">
              <div>
                <dt className="font-semibold text-slate-500">Feedback status</dt>
                <dd className="mt-1 font-semibold text-slate-950">
                  {analytics.session.isActive ? "Accepting responses" : "Closed"}
                </dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-500">
                  Active published form
                </dt>
                <dd className="mt-1 font-semibold text-slate-950">
                  {analytics.session.activeFormVersionNumber
                    ? `Version ${analytics.session.activeFormVersionNumber}`
                    : "No published form"}
                </dd>
              </div>

              <div>
                <dt className="font-semibold text-slate-500">Participant URL</dt>
                <dd className="mt-1 break-all font-mono text-xs text-slate-700">
                  {participantUrl}
                </dd>
              </div>
            </dl>
          </section>
        </aside>
      </section>
    </section>
  );
}
```

### The Verification

Start the application:

```bash
npm run dev
```

Sign in at:

```text
http://localhost:3000/admin/login
```

Then open:

```text
http://localhost:3000/admin/sessions/REACT-2026-Q3
```

You should see:

- Total response count.
- Average rating.
- NPS.
- Score distributions.
- Choice response distribution.
- Written feedback.
- A generated QR code.
- An **Export CSV** button.
- Automatic-refresh information.

If you have not submitted responses yet, the dashboard should still work and show friendly empty states.

---

## Step 7.6 — Add dashboard navigation from the form editor

### The Target

Add a direct link from the session form editor to the analytics dashboard.

### The Concept

Administrators should be able to move naturally between authoring and reporting:

```text
Edit form ←→ View analytics
```

### The Implementation

Open this file:

### `src/app/(admin)/admin/sessions/[sessionId]/edit/page.tsx`

Find this section:

```tsx
<div className="mt-5 flex flex-col justify-between gap-5 lg:flex-row lg:items-start">
```

Replace the complete `div` with this version:

```tsx
<div className="mt-5 flex flex-col justify-between gap-5 lg:flex-row lg:items-start">
  <div>
    <p className="text-sm font-semibold text-indigo-700">
      {session.event.title}
    </p>

    <h1 className="mt-2 text-3xl font-bold tracking-tight text-slate-950">
      {session.title}
    </h1>

    <p className="mt-2 font-mono text-sm text-slate-500">{session.id}</p>
  </div>

  <div className="flex flex-col gap-3 sm:flex-row">
    <Link
      className="inline-flex min-h-12 items-center justify-center rounded-xl border border-indigo-200 bg-indigo-50 px-5 py-3 font-semibold text-indigo-800 transition hover:bg-indigo-100"
      href={`/admin/sessions/${session.id}`}
    >
      View analytics
    </Link>

    <form
      action={setSessionActiveAction.bind(null, session.id, !session.isActive)}
    >
      <button
        className={`inline-flex min-h-12 w-full items-center justify-center rounded-xl px-5 py-3 font-semibold transition ${
          session.isActive
            ? "bg-slate-800 text-white hover:bg-slate-950"
            : "bg-emerald-600 text-white hover:bg-emerald-700"
        }`}
        type="submit"
      >
        {session.isActive
          ? "Close feedback session"
          : "Reopen feedback session"}
      </button>
    </form>
  </div>
</div>
```

`Link` is already imported at the top of this file, so no new import is needed.

### The Verification

Open:

```text
http://localhost:3000/admin/sessions/REACT-2026-Q3/edit
```

You should now see:

```text
View analytics
```

Click it and verify that it opens:

```text
/admin/sessions/REACT-2026-Q3
```

---

## Step 7.7 — Verify dashboard auto-refresh

### The Target

Confirm that a newly submitted response appears in the admin dashboard without manually reloading the page.

### The Concept

The dashboard refresh helper calls `router.refresh()` every 15 seconds. Next.js then re-renders the server dashboard with fresh Neon data.

### The Implementation

Keep three browser contexts available:

1. Administrator dashboard:

   ```text
   http://localhost:3000/admin/sessions/REACT-2026-Q3
   ```

2. Participant form in a private/incognito browser window:

   ```text
   http://localhost:3000/e/REACT-2026-Q3?src=qr
   ```

3. Inngest dashboard:

   ```text
   http://localhost:8288
   ```

Keep the development services running:

```bash
npm run dev
```

```bash
npm run inngest:dev
```

Submit a new feedback response from the private participant window.

### The Verification

1. Confirm the participant sees the success message.
2. Confirm the Inngest job completes successfully.
3. Wait up to 15 seconds on the admin dashboard.
4. Confirm the total response count increases.
5. Confirm the relevant rating, NPS, choice, and text analytics update.

---

## Step 7.8 — Run the complete Part 7 verification

### The Target

Confirm that feedback collection, background storage, analytics, QR generation, and CSV export work as one system.

### The Implementation

Run:

```bash
npx prisma validate
```

```bash
npm run db:test
```

```bash
npm run lint
```

```bash
npm run build
```

Then complete this practical workflow:

1. Start Next.js:

   ```bash
   npm run dev
   ```

2. Start Inngest:

   ```bash
   npm run inngest:dev
   ```

3. Sign in:

   ```text
   http://localhost:3000/admin/login
   ```

4. Open the dashboard:

   ```text
   http://localhost:3000/admin/sessions/REACT-2026-Q3
   ```

5. Download the QR code.

6. Export the CSV file.

7. Submit a participant response from:

   ```text
   http://localhost:3000/e/REACT-2026-Q3?src=qr
   ```

8. Confirm the background job completes.

9. Wait for the dashboard to refresh.

10. Confirm the new response appears in:
    - Total response count.
    - Question distribution.
    - CSV export.

### The Verification

At the end of the workflow, GreyMatter Feedback should provide an end-to-end feedback loop:

```text
Administrator publishes form
        ↓
Administrator downloads QR code
        ↓
Participant scans and submits feedback
        ↓
Inngest safely stores response in Neon
        ↓
Administrator dashboard updates
        ↓
Administrator exports CSV data
```
