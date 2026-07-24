# Part 2: Seed Data, Form Lifecycle Helpers, and the Dynamic Participant Session Route

In this part, we will make the database useful by adding a sample event, session, published form version, and questions.

We will then build the first participant route:

```text
/e/REACT-2026-Q3
```

This route will read the session’s active published form from Neon and display it safely.

By the end of Part 2, you will have:

- Development seed data in Neon.
- Typed helpers for form question settings.
- A server-side query for public participant forms.
- A dynamic participant session route.
- Friendly pages for missing, inactive, and unpublished sessions.
- A visible form preview based entirely on database configuration.

> The participant form will become interactive, persist drafts, and submit answers in Part 4. In this part, we are building the secure server-rendered shell that finds and displays the correct published form.

---

## Step 2.1 — Add server environment validation

### The Target

Create a reusable module that validates required environment variables before server code relies on them.

### The Concept

A missing environment variable can cause confusing failures later.

For example, if `DATABASE_URL` is missing, it is better to stop with a clear configuration error than wait until a participant scans a QR code and receives a generic server error.

This module acts like a pre-flight checklist before an airplane takes off.

### The Implementation

Create this file.

### `src/lib/env.ts`

```ts
import { z } from "zod";

const environmentSchema = z.object({
  DATABASE_URL: z.string().url(),
  DIRECT_URL: z.string().url(),

  // Both secrets must be long enough to make guessing impractical.
  IP_HASH_SECRET: z.string().min(32),
  ADMIN_SESSION_SECRET: z.string().min(32),

  // This will be used when we build administrator authentication.
  ADMIN_PASSWORD: z.string().min(12),

  NEXT_PUBLIC_APP_URL: z.string().url(),

  INNGEST_EVENT_KEY: z.string().optional(),
  INNGEST_SIGNING_KEY: z.string().optional(),

  S3_REGION: z.string().optional(),
  S3_BUCKET: z.string().optional(),
  S3_ACCESS_KEY_ID: z.string().optional(),
  S3_SECRET_ACCESS_KEY: z.string().optional(),

  // An empty value is valid because S3 storage is optional in development.
  S3_ENDPOINT: z.string().url().or(z.literal("")).optional(),
});

const parsedEnvironment = environmentSchema.safeParse({
  DATABASE_URL: process.env.DATABASE_URL,
  DIRECT_URL: process.env.DIRECT_URL,
  IP_HASH_SECRET: process.env.IP_HASH_SECRET,
  ADMIN_SESSION_SECRET: process.env.ADMIN_SESSION_SECRET,
  ADMIN_PASSWORD: process.env.ADMIN_PASSWORD,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
  INNGEST_EVENT_KEY: process.env.INNGEST_EVENT_KEY,
  INNGEST_SIGNING_KEY: process.env.INNGEST_SIGNING_KEY,
  S3_REGION: process.env.S3_REGION,
  S3_BUCKET: process.env.S3_BUCKET,
  S3_ACCESS_KEY_ID: process.env.S3_ACCESS_KEY_ID,
  S3_SECRET_ACCESS_KEY: process.env.S3_SECRET_ACCESS_KEY,
  S3_ENDPOINT: process.env.S3_ENDPOINT,
});

if (!parsedEnvironment.success) {
  console.error(
    "Invalid GreyMatter Feedback environment configuration:",
    parsedEnvironment.error.flatten().fieldErrors,
  );

  throw new Error(
    "Invalid environment configuration. Check the server logs for details.",
  );
}

export const env = parsedEnvironment.data;
```

Update the Prisma client so server code validates configuration before opening a database connection.

### `src/lib/prisma.ts`

```ts
import "./env";
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

/**
 * Next.js reloads modules frequently during development.
 * Reusing one Prisma client prevents unnecessary database connections.
 */
export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
```

### The Verification

Run:

```bash
npm run db:test
```

You should receive:

```text
Successfully connected to Neon PostgreSQL.
```

To verify validation, temporarily change this value in `.env`:

```dotenv
ADMIN_PASSWORD="short"
```

Run:

```bash
npm run db:test
```

The command should fail with an invalid environment configuration error.

Restore a password with at least 12 characters, then run:

```bash
npm run db:test
```

The command should succeed again.

---

## Step 2.2 — Define shared form types and question settings

### The Target

Create TypeScript types and validators for question settings stored in the database.

### The Concept

Different question types need different settings.

For example:

- A rating question needs a minimum and maximum score.
- A text question needs a maximum character count.
- An NPS question always uses the familiar 0–10 scale.
- A choice question needs at least two options.

The `settings` column is JSON because its contents vary by question type. However, JSON is flexible enough to contain invalid data. We will use Zod to check that data before rendering it.

Think of JSON as a box with a label. Zod opens the box and checks that the contents actually match the label.

### The Implementation

Create this file.

### `src/types/forms.ts`

```ts
import { QuestionType } from "@prisma/client";
import { z } from "zod";

/**
 * Rating questions use a configurable inclusive numeric range.
 * GreyMatter Feedback currently supports scales from 1–10.
 */
export const ratingSettingsSchema = z.object({
  min: z.number().int().min(1).max(10).default(1),
  max: z.number().int().min(2).max(10).default(5),
  minLabel: z.string().trim().max(100).optional(),
  maxLabel: z.string().trim().max(100).optional(),
});

/**
 * Text questions use a character limit. This protects the database,
 * reporting system, and participant interface from excessively large input.
 */
export const textSettingsSchema = z.object({
  maxLength: z.number().int().min(1).max(5000).default(1500),
  placeholder: z.string().trim().max(250).optional(),
});

/**
 * NPS has a standardized 0–10 range, but labels can be customized.
 */
export const npsSettingsSchema = z.object({
  minLabel: z.string().trim().max(100).default("Not at all likely"),
  maxLabel: z.string().trim().max(100).default("Extremely likely"),
});

/**
 * Choice questions do not currently need settings beyond their options.
 * Keeping this schema provides a consistent shape across all question types.
 */
export const choiceSettingsSchema = z.object({});

export type RatingSettings = z.infer<typeof ratingSettingsSchema>;
export type TextSettings = z.infer<typeof textSettingsSchema>;
export type NpsSettings = z.infer<typeof npsSettingsSchema>;
export type ChoiceSettings = z.infer<typeof choiceSettingsSchema>;

export type QuestionSettings =
  | RatingSettings
  | TextSettings
  | NpsSettings
  | ChoiceSettings;

export type ParticipantQuestion = {
  id: string;
  orderIndex: number;
  questionText: string;
  questionType: QuestionType;
  isRequired: boolean;
  settings: QuestionSettings;
  options: string[];
};

/**
 * Converts untrusted database JSON into safe typed settings.
 * If old or malformed data exists, safe defaults are used rather than
 * allowing a participant page to fail.
 */
export function parseQuestionSettings(
  questionType: QuestionType,
  value: unknown,
): QuestionSettings {
  switch (questionType) {
    case QuestionType.RATING:
      return ratingSettingsSchema.parse(value);
    case QuestionType.TEXT:
      return textSettingsSchema.parse(value);
    case QuestionType.NPS:
      return npsSettingsSchema.parse(value);
    case QuestionType.CHOICE:
      return choiceSettingsSchema.parse(value);
  }
}

/**
 * Choice options are normalized before they reach the participant UI.
 * Empty values and duplicate values are removed.
 */
export function parseChoiceOptions(value: unknown): string[] {
  const parsedOptions = z.array(z.string().trim().min(1).max(250)).safeParse(value);

  if (!parsedOptions.success) {
    return [];
  }

  return [...new Set(parsedOptions.data)];
}

/**
 * Returns a readable label used in administrator and participant interfaces.
 */
export function getQuestionTypeLabel(questionType: QuestionType): string {
  switch (questionType) {
    case QuestionType.RATING:
      return "Rating";
    case QuestionType.NPS:
      return "Recommendation score";
    case QuestionType.TEXT:
      return "Written response";
    case QuestionType.CHOICE:
      return "Choice";
  }
}
```

### The Verification

Run TypeScript and lint checks:

```bash
npm run lint
```

Then create a production build:

```bash
npm run build
```

Both commands should finish successfully.

---

## Step 2.3 — Create development seed data

### The Target

Create a repeatable seed script that inserts one realistic event, one session, one published form version, and several questions.

### The Concept

Seed data is realistic sample data inserted into a development database.

It is like furnishing a model home: it lets us test routes and user interfaces before an administrator creates real content.

Our sample session will be:

```text
Event: React Summit 2026
Session: Advanced React Patterns
Session ID: REACT-2026-Q3
```

It will contain:

1. A required 1–5 rating question.
2. A required 0–10 NPS question.
3. An optional choice question.
4. An optional text question.

The seed script is designed to be safe to rerun. It checks whether the fixture session already exists before creating it.

> Do not run this script against a production database. It intentionally creates development demonstration data.

### The Implementation

Create this file.

### `prisma/seed.ts`

```ts
import {
  FormVersionStatus,
  PrismaClient,
  QuestionType,
} from "@prisma/client";

const prisma = new PrismaClient();

const SAMPLE_EVENT_TITLE = "React Summit 2026";
const SAMPLE_SESSION_ID = "REACT-2026-Q3";
const SAMPLE_SESSION_TITLE = "Advanced React Patterns";

async function main() {
  if (process.env.NODE_ENV === "production") {
    throw new Error("The development seed script must not run in production.");
  }

  const event = await prisma.event.upsert({
    where: {
      // Prisma does not currently have a unique constraint on title, so this
      // lookup is performed before creating the demonstration event.
      id: (
        await prisma.event.findFirst({
          where: { title: SAMPLE_EVENT_TITLE },
          select: { id: true },
        })
      )?.id ?? "00000000-0000-0000-0000-000000000000",
    },
    update: {},
    create: {
      title: SAMPLE_EVENT_TITLE,
    },
  });

  const session = await prisma.session.upsert({
    where: {
      id: SAMPLE_SESSION_ID,
    },
    update: {
      title: SAMPLE_SESSION_TITLE,
      isActive: true,
    },
    create: {
      id: SAMPLE_SESSION_ID,
      eventId: event.id,
      title: SAMPLE_SESSION_TITLE,
      isActive: true,
    },
  });

  const existingPublishedForm = await prisma.formVersion.findFirst({
    where: {
      sessionId: session.id,
      status: FormVersionStatus.PUBLISHED,
    },
    orderBy: {
      versionNumber: "desc",
    },
  });

  if (existingPublishedForm) {
    console.log(
      `Seed data already exists. Session ${SAMPLE_SESSION_ID} uses published form version ${existingPublishedForm.versionNumber}.`,
    );
    return;
  }

  const formVersion = await prisma.$transaction(async (transaction) => {
    const newestVersion = await transaction.formVersion.findFirst({
      where: {
        sessionId: session.id,
      },
      orderBy: {
        versionNumber: "desc",
      },
      select: {
        versionNumber: true,
      },
    });

    const nextVersionNumber = (newestVersion?.versionNumber ?? 0) + 1;

    const createdFormVersion = await transaction.formVersion.create({
      data: {
        sessionId: session.id,
        versionNumber: nextVersionNumber,
        status: FormVersionStatus.PUBLISHED,
        publishedAt: new Date(),
        questions: {
          create: [
            {
              orderIndex: 1,
              questionText: "How useful was this workshop?",
              questionType: QuestionType.RATING,
              isRequired: true,
              settings: {
                min: 1,
                max: 5,
                minLabel: "Not useful",
                maxLabel: "Extremely useful",
              },
              options: [],
            },
            {
              orderIndex: 2,
              questionText:
                "How likely are you to recommend this workshop to a colleague?",
              questionType: QuestionType.NPS,
              isRequired: true,
              settings: {
                minLabel: "Not at all likely",
                maxLabel: "Extremely likely",
              },
              options: [],
            },
            {
              orderIndex: 3,
              questionText: "Which topic was most valuable?",
              questionType: QuestionType.CHOICE,
              isRequired: false,
              settings: {},
              options: [
                "Server Components",
                "Data fetching patterns",
                "Performance optimization",
                "Testing strategies",
              ],
            },
            {
              orderIndex: 4,
              questionText: "What should we improve for the next workshop?",
              questionType: QuestionType.TEXT,
              isRequired: false,
              settings: {
                maxLength: 1500,
                placeholder:
                  "Share any suggestions, missing topics, or areas that need more explanation.",
              },
              options: [],
            },
          ],
        },
      },
      select: {
        id: true,
        versionNumber: true,
      },
    });

    await transaction.session.update({
      where: {
        id: session.id,
      },
      data: {
        activeFormVersionId: createdFormVersion.id,
      },
    });

    return createdFormVersion;
  });

  console.log("Created GreyMatter Feedback development data:");
  console.log(`Event: ${SAMPLE_EVENT_TITLE}`);
  console.log(`Session: ${SAMPLE_SESSION_TITLE}`);
  console.log(`Session ID: ${SAMPLE_SESSION_ID}`);
  console.log(`Published form version: ${formVersion.versionNumber}`);
  console.log(
    `Participant URL: http://localhost:3000/e/${SAMPLE_SESSION_ID}?src=qr`,
  );
}

main()
  .catch((error: unknown) => {
    console.error("Unable to seed the development database.");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Update `package.json` by adding the Prisma seed configuration and a script.

### `package.json`

Add the following top-level `"prisma"` object:

```json
{
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

Add `db:seed` inside the existing `"scripts"` object:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "db:test": "tsx scripts/test-database.ts",
    "db:seed": "prisma db seed"
  }
}
```

Your complete `package.json` will contain additional fields created by Next.js and npm. Keep those existing fields unchanged.

### The Verification

Run the seed script:

```bash
npm run db:seed
```

Expected output:

```text
Created GreyMatter Feedback development data:
Event: React Summit 2026
Session: Advanced React Patterns
Session ID: REACT-2026-Q3
Published form version: 1
Participant URL: http://localhost:3000/e/REACT-2026-Q3?src=qr
```

Run it a second time:

```bash
npm run db:seed
```

Expected output:

```text
Seed data already exists. Session REACT-2026-Q3 uses published form version 1.
```

Inspect the result in Prisma Studio:

```bash
npx prisma studio
```

Verify:

1. There is one event named `React Summit 2026`.
2. There is one session with ID `REACT-2026-Q3`.
3. The session has an `activeFormVersionId`.
4. There is one `FormVersion` with status `PUBLISHED`.
5. The form version has four questions.

Stop Prisma Studio when finished:

```bash
Ctrl+C
```

---

## Step 2.4 — Create participant-form database queries

### The Target

Create a database query that safely finds the active published form for a participant session URL.

### The Concept

The participant route must only reveal a form when all conditions are true:

1. The session exists.
2. The session is active.
3. The session has an active form version.
4. The active form version is actually published.

This is important because an administrator might create a draft form but not publish it yet. Participants must never see unfinished drafts simply because they know a session URL.

### The Implementation

Create this file.

### `src/lib/participant-session.ts`

```ts
import { FormVersionStatus } from "@prisma/client";
import { cache } from "react";
import { z } from "zod";
import {
  parseChoiceOptions,
  parseQuestionSettings,
  type ParticipantQuestion,
} from "@/types/forms";
import { prisma } from "@/lib/prisma";

/**
 * Session IDs are designed for readable QR URLs.
 * The pattern allows uppercase/lowercase letters, numbers, and hyphens.
 */
const sessionIdSchema = z
  .string()
  .trim()
  .min(3)
  .max(64)
  .regex(
    /^[A-Za-z0-9-]+$/,
    "Session IDs may contain only letters, numbers, and hyphens.",
  );

export type ParticipantSessionState =
  | {
      kind: "ready";
      session: {
        id: string;
        title: string;
        eventTitle: string;
        formVersionId: string;
        formVersionNumber: number;
        questions: ParticipantQuestion[];
      };
    }
  | {
      kind: "not-found";
    }
  | {
      kind: "inactive";
      sessionTitle: string;
    }
  | {
      kind: "not-published";
      sessionTitle: string;
    };

/**
 * React cache deduplicates this server-side query during one render request.
 * If the page and its metadata both need session data, Prisma is not asked
 * for the same record twice in that request.
 */
export const getParticipantSession = cache(
  async (rawSessionId: string): Promise<ParticipantSessionState> => {
    const parsedSessionId = sessionIdSchema.safeParse(rawSessionId);

    if (!parsedSessionId.success) {
      return { kind: "not-found" };
    }

    const sessionId = parsedSessionId.data;

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
          include: {
            questions: {
              orderBy: {
                orderIndex: "asc",
              },
            },
          },
        },
      },
    });

    if (!session) {
      return { kind: "not-found" };
    }

    if (!session.isActive) {
      return {
        kind: "inactive",
        sessionTitle: session.title,
      };
    }

    if (
      !session.activeFormVersion ||
      session.activeFormVersion.status !== FormVersionStatus.PUBLISHED
    ) {
      return {
        kind: "not-published",
        sessionTitle: session.title,
      };
    }

    const questions = session.activeFormVersion.questions.map((question) => ({
      id: question.id,
      orderIndex: question.orderIndex,
      questionText: question.questionText,
      questionType: question.questionType,
      isRequired: question.isRequired,
      settings: parseQuestionSettings(question.questionType, question.settings),
      options: parseChoiceOptions(question.options),
    }));

    return {
      kind: "ready",
      session: {
        id: session.id,
        title: session.title,
        eventTitle: session.event.title,
        formVersionId: session.activeFormVersion.id,
        formVersionNumber: session.activeFormVersion.versionNumber,
        questions,
      },
    };
  },
);
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

Both commands should finish successfully.

---

## Step 2.5 — Build reusable participant question preview components

### The Target

Create server-rendered components that display each supported question type.

### The Concept

The participant route needs one reusable renderer that can display different question types from the database.

This is like a receptionist reading different event instructions:

- If the instruction says “rating,” show rating buttons.
- If it says “NPS,” show 0–10 buttons.
- If it says “choice,” show selectable options.
- If it says “text,” show a text area.

In this part, the fields are intentionally disabled. They prove that dynamic form configuration works. In Part 4, we will replace the disabled preview with a client-side interactive form that saves drafts and submits responses.

### The Implementation

Create this file.

### `src/components/participant/question-preview.tsx` 

```tsx
import { QuestionType } from "@prisma/client";
import type {
  NpsSettings,
  ParticipantQuestion,
  RatingSettings,
  TextSettings,
} from "@/types/forms";

type QuestionPreviewProps = {
  question: ParticipantQuestion;
};

function QuestionHeader({
  question,
}: {
  question: ParticipantQuestion;
}) {
  return (
    <div className="mb-4">
      <p className="text-sm font-semibold text-indigo-700">
        Question {question.orderIndex}
        {question.isRequired ? " · Required" : " · Optional"}
      </p>

      <h2 className="mt-1 text-lg font-semibold leading-7 text-slate-950">
        {question.questionText}
      </h2>
    </div>
  );
}

function RatingQuestionPreview({
  question,
}: {
  question: ParticipantQuestion;
}) {
  const settings = question.settings as RatingSettings;
  const scoreValues = Array.from(
    { length: settings.max - settings.min + 1 },
    (_, index) => settings.min + index,
  );

  return (
    <>
      <div
        aria-label={`${question.questionText} rating scale`}
        className="grid grid-cols-5 gap-2 sm:flex sm:flex-wrap"
      >
        {scoreValues.map((score) => (
          <button
            aria-label={`Rate ${score}`}
            className="min-h-12 rounded-xl border border-slate-300 bg-white px-4 py-3 font-semibold text-slate-700 opacity-60"
            disabled
            key={score}
            type="button"
          >
            {score}
          </button>
        ))}
      </div>

      <div className="mt-3 flex justify-between gap-4 text-sm text-slate-500">
        <span>{settings.minLabel}</span>
        <span>{settings.maxLabel}</span>
      </div>
    </>
  );
}

function NpsQuestionPreview({
  question,
}: {
  question: ParticipantQuestion;
}) {
  const settings = question.settings as NpsSettings;
  const scores = Array.from({ length: 11 }, (_, index) => index);

  return (
    <>
      <div
        aria-label={`${question.questionText} recommendation score`}
        className="grid grid-cols-6 gap-2 sm:grid-cols-11"
      >
        {scores.map((score) => (
          <button
            aria-label={`Recommendation score ${score}`}
            className="min-h-12 rounded-xl border border-slate-300 bg-white px-3 py-3 font-semibold text-slate-700 opacity-60"
            disabled
            key={score}
            type="button"
          >
            {score}
          </button>
        ))}
      </div>

      <div className="mt-3 flex justify-between gap-4 text-sm text-slate-500">
        <span>{settings.minLabel}</span>
        <span className="text-right">{settings.maxLabel}</span>
      </div>
    </>
  );
}

function ChoiceQuestionPreview({
  question,
}: {
  question: ParticipantQuestion;
}) {
  if (question.options.length === 0) {
    return (
      <p className="rounded-xl bg-amber-50 p-4 text-sm text-amber-900">
        This choice question has no configured options. An administrator must
        add options before publishing the form.
      </p>
    );
  }

  return (
    <div className="space-y-3">
      {question.options.map((option) => (
        <label
          className="flex min-h-12 items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-700 opacity-60"
          key={option}
        >
          <input disabled name={question.id} type="radio" value={option} />
          <span>{option}</span>
        </label>
      ))}
    </div>
  );
}

function TextQuestionPreview({
  question,
}: {
  question: ParticipantQuestion;
}) {
  const settings = question.settings as TextSettings;

  return (
    <textarea
      className="min-h-32 w-full resize-y rounded-xl border border-slate-300 bg-white px-4 py-3 text-base text-slate-700 placeholder:text-slate-400 opacity-60"
      disabled
      maxLength={settings.maxLength}
      placeholder={settings.placeholder ?? "Write your feedback here."}
      rows={5}
    />
  );
}

export function QuestionPreview({ question }: QuestionPreviewProps) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <QuestionHeader question={question} />

      {question.questionType === QuestionType.RATING ? (
        <RatingQuestionPreview question={question} />
      ) : null}

      {question.questionType === QuestionType.NPS ? (
        <NpsQuestionPreview question={question} />
      ) : null}

      {question.questionType === QuestionType.CHOICE ? (
        <ChoiceQuestionPreview question={question} />
      ) : null}

      {question.questionType === QuestionType.TEXT ? (
        <TextQuestionPreview question={question} />
      ) : null}
    </section>
  );
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

## Step 2.6 — Create reusable unavailable-session pages

### The Target

Create clear participant-facing screens for these three conditions:

1. The QR code points to a session that does not exist.
2. The session exists but has been closed.
3. The session exists but no form has been published.

### The Concept

A participant should never see raw technical errors such as “record not found” or “database query failed.”

Instead, the application should explain the situation in plain language, much like a sign on a venue door:

```text
This room is closed.
Please contact the event organizer.
```

### The Implementation

Create this file.

### `src/components/participant/session-unavailable.tsx`

```tsx
import Link from "next/link";

type SessionUnavailableProps = {
  title: string;
  message: string;
  sessionTitle?: string;
};

export function SessionUnavailable({
  title,
  message,
  sessionTitle,
}: SessionUnavailableProps) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-6 py-12">
      <section className="w-full max-w-lg rounded-2xl border border-slate-200 bg-white p-6 text-center shadow-sm sm:p-8">
        <p className="text-sm font-semibold uppercase tracking-wide text-indigo-700">
          GreyMatter Feedback
        </p>

        <h1 className="mt-4 text-2xl font-bold tracking-tight text-slate-950">
          {title}
        </h1>

        {sessionTitle ? (
          <p className="mt-3 font-medium text-slate-800">{sessionTitle}</p>
        ) : null}

        <p className="mt-4 leading-7 text-slate-600">{message}</p>

        <Link
          className="mt-8 inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700"
          href="/"
        >
          Return to GreyMatter Feedback
        </Link>
      </section>
    </main>
  );
}
```

### The Verification

Run:

```bash
npm run lint
```

The command should complete without errors.

---

## Step 2.7 — Build the dynamic participant session route

### The Target

Create the dynamic route that loads the active published form for a session.

The finished route will support this URL:

```text
/e/REACT-2026-Q3
```

### The Concept

Dynamic routing lets one page file serve many QR-code session URLs.

The page receives the `sessionId` from the URL, queries Neon through Prisma, and chooses one of four outcomes:

```text
Session does not exist        → Not found screen
Session is inactive           → Feedback closed screen
No published form is present  → Form unavailable screen
Published form exists         → Render the participant form preview
```

This route is a **Server Component**. That means it runs on the server and can query the database without exposing database credentials to participant browsers.

### The Implementation

Create the folders:

```bash
mkdir -p "src/app/e/[sessionId]"
```

Create this file.

### `src/app/e/[sessionId]/page.tsx`

```tsx
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { QuestionPreview } from "@/components/participant/question-preview";
import { SessionUnavailable } from "@/components/participant/session-unavailable";
import { getParticipantSession } from "@/lib/participant-session";

type ParticipantSessionPageProps = {
  params: Promise<{
    sessionId: string;
  }>;
};

/**
 * Dynamic metadata makes browser titles useful when a participant opens
 * a QR-code session link.
 */
export async function generateMetadata({
  params,
}: ParticipantSessionPageProps): Promise<Metadata> {
  const { sessionId } = await params;
  const state = await getParticipantSession(sessionId);

  if (state.kind !== "ready") {
    return {
      title: "Feedback",
    };
  }

  return {
    title: `${state.session.title} Feedback`,
    description: `Share feedback for ${state.session.title}.`,
  };
}

export default async function ParticipantSessionPage({
  params,
}: ParticipantSessionPageProps) {
  const { sessionId } = await params;
  const state = await getParticipantSession(sessionId);

  if (state.kind === "not-found") {
    notFound();
  }

  if (state.kind === "inactive") {
    return (
      <SessionUnavailable
        message="This feedback session is no longer accepting responses. Please contact the event organizer if you believe this is a mistake."
        sessionTitle={state.sessionTitle}
        title="Feedback is closed"
      />
    );
  }

  if (state.kind === "not-published") {
    return (
      <SessionUnavailable
        message="This feedback form is not available yet. Please ask the event organizer for the correct QR code or try again later."
        sessionTitle={state.sessionTitle}
        title="Feedback is not available"
      />
    );
  }

  return (
    <main className="min-h-screen bg-slate-50 px-4 py-8 sm:px-6 sm:py-12">
      <section className="mx-auto w-full max-w-2xl">
        <header className="mb-8 rounded-2xl bg-indigo-700 p-6 text-white shadow-sm sm:p-8">
          <p className="text-sm font-semibold text-indigo-100">
            {state.session.eventTitle}
          </p>

          <h1 className="mt-2 text-3xl font-bold tracking-tight">
            {state.session.title}
          </h1>

          <p className="mt-4 leading-7 text-indigo-100">
            Thank you for taking a moment to share your feedback. Your answers
            help us improve future sessions.
          </p>
        </header>

        <div className="mb-6 rounded-xl border border-indigo-100 bg-indigo-50 p-4 text-sm leading-6 text-indigo-950">
          <strong>Form preview:</strong> The questions below are loaded from
          the published form configuration in Neon. In Part 4, these controls
          become interactive and can be submitted.
        </div>

        <div className="space-y-5">
          {state.session.questions.map((question) => (
            <QuestionPreview key={question.id} question={question} />
          ))}
        </div>

        <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 text-sm leading-6 text-slate-600 shadow-sm">
          <p>
            This form is currently version{" "}
            <strong>{state.session.formVersionNumber}</strong>. GreyMatter
            Feedback records the form version with each submitted response so
            future edits cannot change historical reporting.
          </p>
        </section>
      </section>
    </main>
  );
}
```

Create a custom not-found page for participant session links.

### `src/app/e/[sessionId]/not-found.tsx`

```tsx
import { SessionUnavailable } from "@/components/participant/session-unavailable";

export default function ParticipantSessionNotFound() {
  return (
    <SessionUnavailable
      message="We could not find a feedback session for this QR code. Please check that you scanned the correct code or ask the event organizer for help."
      title="Feedback session not found"
    />
  );
}
```

### The Verification

Start the application:

```bash
npm run dev
```

Open this URL:

```text
http://localhost:3000/e/REACT-2026-Q3?src=qr
```

You should see:

- `React Summit 2026`
- `Advanced React Patterns`
- Four questions loaded from Neon:
  - Rating
  - NPS
  - Choice
  - Text
- A notice explaining that this is a preview.
- A displayed form version number.

Also test a missing session:

```text
http://localhost:3000/e/DOES-NOT-EXIST
```

You should see:

```text
Feedback session not found
```

---

## Step 2.8 — Test inactive session behavior

### The Target

Confirm that GreyMatter Feedback does not accept or display active feedback forms for closed sessions.

### The Concept

An organizer may want to stop collecting feedback after a workshop ends. Setting `isActive` to `false` is the system’s “close the feedback box” switch.

The session remains in the database for reporting, but participants see a polite closed message.

### The Implementation

Open Prisma Studio:

```bash
npx prisma studio
```

In the `Session` table:

1. Find `REACT-2026-Q3`.
2. Change `isActive` from `true` to `false`.
3. Save the change.

### The Verification

With the Next.js development server still running, refresh:

```text
http://localhost:3000/e/REACT-2026-Q3
```

You should see:

```text
Feedback is closed
```

Return to Prisma Studio and change `isActive` back to `true`.

Refresh the participant URL again:

```text
http://localhost:3000/e/REACT-2026-Q3
```

The form preview should return.

Stop Prisma Studio when finished:

```bash
Ctrl+C
```

---

## Step 2.9 — Test unpublished form behavior

### The Target

Confirm that an unfinished draft cannot accidentally appear through a participant QR URL.

### The Concept

A QR code should only serve a form after the organizer explicitly publishes it.

The participant route checks both:

```text
Session has an active form version
AND
That active form version has status PUBLISHED
```

This prevents draft forms from becoming publicly visible by accident.

### The Implementation

Open Prisma Studio:

```bash
npx prisma studio
```

In the `FormVersion` table:

1. Find the version attached to session `REACT-2026-Q3`.
2. Change `status` from `PUBLISHED` to `DRAFT`.
3. Save the change.

### The Verification

Refresh:

```text
http://localhost:3000/e/REACT-2026-Q3
```

You should see:

```text
Feedback is not available
```

Return to Prisma Studio and restore the status to:

```text
PUBLISHED
```

Refresh the participant URL again. The preview should return.

> Do not change published form status manually in production. In Part 3, we will build controlled authoring and publishing actions that enforce the correct lifecycle rules.

Stop Prisma Studio:

```bash
Ctrl+C
```

---

## Step 2.10 — Run the complete Part 2 check

### The Target

Confirm that the new participant route, database queries, shared types, and seed data all work together.

### The Concept

A full verification checks that the pieces are connected—not merely that individual files compile.

### The Implementation

Run:

```bash
npx prisma validate
```

```bash
npm run db:test
```

```bash
npm run db:seed
```

```bash
npm run lint
```

```bash
npm run build
```

### The Verification

All commands should complete successfully.

Finally, open:

```text
http://localhost:3000/e/REACT-2026-Q3?src=qr
```

You should see a database-driven form preview for the sample session.

---

## Part 2 Reference: Files Added

Your important additions in this part are:

```text
prisma/
└── seed.ts

src/
├── app/
│   └── e/
│       └── [sessionId]/
│           ├── not-found.tsx
│           └── page.tsx
├── components/
│   └── participant/
│       ├── question-preview.tsx
│       └── session-unavailable.tsx
├── lib/
│   ├── env.ts
│   └── participant-session.ts
└── types/
    └── forms.ts
```

The participant route now dynamically reads a session’s active, published, versioned form from Neon.

In the next part, we will build the protected administrator login and form-authoring workflow, allowing an organizer to create events, sessions, draft versions, and questions without editing the database manually.
