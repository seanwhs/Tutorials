# Part 6: Inngest Background Processing and Reliable Response Storage

In Part 5, the participant API accepted valid submissions and attempted to send an event named:

```text
feedback/submitted
```

In this part, we will configure Inngest to receive that event and process it in the background.

The workflow will become:

```text
Participant submits feedback
        ↓
POST /api/feedback validates the request
        ↓
Inngest receives feedback/submitted
        ↓
Background function saves the response and answers in Neon
        ↓
Participant sees fast confirmation
```

This architecture keeps the participant experience fast. Database writes can be retried safely by Inngest if a temporary failure occurs.

By the end of this part, GreyMatter Feedback will:

- Run Inngest locally.
- Expose the `/api/inngest` function endpoint.
- Process `feedback/submitted` events.
- Save responses and answers to Neon.
- Prevent duplicate responses when jobs are retried.
- Preserve the exact submitted form version.
- Use a stable client submission ID so network retries do not create duplicate responses.

---

## Step 6.1 — Correct client submission IDs for retry safety

### The Target

Update local draft storage so each unfinished feedback draft has one stable submission ID.

### The Concept

A participant might press **Submit**, lose connectivity before seeing the result, and press **Submit** again.

If the browser creates a new ID every time, the application may treat the second attempt as a completely new response.

Instead, GreyMatter Feedback creates one UUID—Universally Unique Identifier—for the draft:

```text
Draft begins
    ↓
Create submission ID
    ↓
Save submission ID with local draft
    ↓
Retry uses the same submission ID
    ↓
Background worker recognizes duplicate work safely
```

This ID is the submission’s receipt number.

### The Implementation

Replace the complete contents of this file.

### `src/lib/participant-draft.ts`

```ts
"use client";

export type ParticipantAnswerValue = number | string;

export type ParticipantDraft = {
  answers: Record<string, ParticipantAnswerValue>;
  submissionId?: string;
  updatedAt: string;
};

function getDraftKey(sessionId: string, formVersionId: string): string {
  return `greymatter-feedback:draft:${sessionId}:${formVersionId}`;
}

export function loadParticipantDraft(
  sessionId: string,
  formVersionId: string,
): ParticipantDraft | null {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const storedValue = window.localStorage.getItem(
      getDraftKey(sessionId, formVersionId),
    );

    if (!storedValue) {
      return null;
    }

    const parsedValue = JSON.parse(storedValue) as ParticipantDraft;

    if (
      !parsedValue ||
      typeof parsedValue !== "object" ||
      !parsedValue.answers ||
      typeof parsedValue.answers !== "object" ||
      typeof parsedValue.updatedAt !== "string"
    ) {
      return null;
    }

    return parsedValue;
  } catch {
    // A broken local draft must never prevent the feedback form from loading.
    return null;
  }
}

export function saveParticipantDraft(
  sessionId: string,
  formVersionId: string,
  answers: Record<string, ParticipantAnswerValue>,
  submissionId: string,
): void {
  if (typeof window === "undefined") {
    return;
  }

  const draft: ParticipantDraft = {
    answers,
    submissionId,
    updatedAt: new Date().toISOString(),
  };

  window.localStorage.setItem(
    getDraftKey(sessionId, formVersionId),
    JSON.stringify(draft),
  );
}

export function clearParticipantDraft(
  sessionId: string,
  formVersionId: string,
): void {
  if (typeof window === "undefined") {
    return;
  }

  window.localStorage.removeItem(getDraftKey(sessionId, formVersionId));
}
```

Replace the complete contents of the participant form component.

### `src/components/participant/feedback-form.tsx`

```tsx
"use client";

import { useEffect, useRef, useState } from "react";
import { QuestionInput } from "@/components/participant/question-input";
import {
  clearParticipantDraft,
  loadParticipantDraft,
  saveParticipantDraft,
  type ParticipantAnswerValue,
} from "@/lib/participant-draft";
import type { ParticipantQuestion } from "@/types/forms";

type FeedbackFormProps = {
  sessionId: string;
  formVersionId: string;
  questions: ParticipantQuestion[];
};

type ValidationErrors = Record<string, string>;

type SubmissionState =
  | {
      kind: "idle";
    }
  | {
      kind: "submitting";
    }
  | {
      kind: "success";
    }
  | {
      kind: "error";
      message: string;
    };

function isAnswered(value: ParticipantAnswerValue | undefined): boolean {
  if (typeof value === "number") {
    return true;
  }

  return typeof value === "string" && value.trim().length > 0;
}

function getScreenMetadata() {
  if (typeof window === "undefined") {
    return undefined;
  }

  return {
    source: new URLSearchParams(window.location.search).get("src") ?? undefined,
    screenWidth: window.screen.width,
    screenHeight: window.screen.height,
  };
}

function createSubmissionId(): string {
  return crypto.randomUUID();
}

export function FeedbackForm({
  sessionId,
  formVersionId,
  questions,
}: FeedbackFormProps) {
  const [answers, setAnswers] = useState<Record<string, ParticipantAnswerValue>>(
    {},
  );
  const [errors, setErrors] = useState<ValidationErrors>({});
  const [draftRestored, setDraftRestored] = useState(false);
  const [submissionState, setSubmissionState] = useState<SubmissionState>({
    kind: "idle",
  });

  /**
   * A ref avoids waiting for React state updates when an answer is selected
   * and immediately persisted to localStorage.
   */
  const submissionIdRef = useRef<string | null>(null);

  function getOrCreateSubmissionId(): string {
    if (!submissionIdRef.current) {
      submissionIdRef.current = createSubmissionId();
    }

    return submissionIdRef.current;
  }

  useEffect(() => {
    const storedDraft = loadParticipantDraft(sessionId, formVersionId);

    if (storedDraft) {
      submissionIdRef.current = storedDraft.submissionId ?? createSubmissionId();
      setAnswers(storedDraft.answers);
      setDraftRestored(true);

      /**
       * Older drafts from Part 5 did not have a submission ID.
       * Saving here upgrades them without losing existing answers.
       */
      saveParticipantDraft(
        sessionId,
        formVersionId,
        storedDraft.answers,
        submissionIdRef.current,
      );

      return;
    }

    submissionIdRef.current = createSubmissionId();
  }, [formVersionId, sessionId]);

  function updateAnswer(questionId: string, value: ParticipantAnswerValue) {
    setSubmissionState({ kind: "idle" });

    setAnswers((currentAnswers) => {
      const nextAnswers = {
        ...currentAnswers,
        [questionId]: value,
      };

      saveParticipantDraft(
        sessionId,
        formVersionId,
        nextAnswers,
        getOrCreateSubmissionId(),
      );

      return nextAnswers;
    });

    setErrors((currentErrors) => {
      const nextErrors = { ...currentErrors };
      delete nextErrors[questionId];
      return nextErrors;
    });
  }

  function validateForm(): ValidationErrors {
    const nextErrors: ValidationErrors = {};

    for (const question of questions) {
      if (question.isRequired && !isAnswered(answers[question.id])) {
        nextErrors[question.id] = "This question requires an answer.";
      }
    }

    return nextErrors;
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const validationErrors = validateForm();
    setErrors(validationErrors);

    if (Object.keys(validationErrors).length > 0) {
      const firstInvalidQuestionId = Object.keys(validationErrors)[0];

      document
        .getElementById(firstInvalidQuestionId ?? "")
        ?.scrollIntoView({ behavior: "smooth", block: "center" });

      return;
    }

    setSubmissionState({ kind: "submitting" });

    const submittedAnswers = Object.entries(answers)
      .filter(([, value]) => isAnswered(value))
      .map(([questionId, value]) => ({
        questionId,
        value: typeof value === "string" ? value.trim() : value,
      }));

    const submissionId = getOrCreateSubmissionId();

    try {
      const response = await fetch("/api/feedback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          submissionId,
          sessionId,
          formVersionId,
          answers: submittedAnswers,
          metadata: getScreenMetadata(),
        }),
      });

      const responseBody = (await response.json()) as {
        accepted?: boolean;
        error?: string;
      };

      if (!response.ok || !responseBody.accepted) {
        setSubmissionState({
          kind: "error",
          message:
            responseBody.error ??
            "We could not submit your feedback. Please try again.",
        });

        return;
      }

      clearParticipantDraft(sessionId, formVersionId);
      submissionIdRef.current = null;
      setDraftRestored(false);
      setSubmissionState({ kind: "success" });
    } catch {
      setSubmissionState({
        kind: "error",
        message:
          "Your device could not reach the feedback service. Your draft is still saved, so please try again when you have a connection.",
      });
    }
  }

  function discardDraft() {
    clearParticipantDraft(sessionId, formVersionId);
    submissionIdRef.current = createSubmissionId();
    setAnswers({});
    setErrors({});
    setDraftRestored(false);
    setSubmissionState({ kind: "idle" });
  }

  if (submissionState.kind === "success") {
    return (
      <section
        aria-live="polite"
        className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6 text-center shadow-sm sm:p-8"
      >
        <p className="text-sm font-semibold uppercase tracking-wide text-emerald-800">
          Feedback received
        </p>

        <h2 className="mt-3 text-2xl font-bold tracking-tight text-emerald-950">
          Thank you for your feedback.
        </h2>

        <p className="mt-3 leading-7 text-emerald-900">
          Your response was accepted and is being processed securely.
        </p>
      </section>
    );
  }

  return (
    <form onSubmit={handleSubmit}>
      {draftRestored ? (
        <div className="mb-6 rounded-xl border border-indigo-200 bg-indigo-50 p-4 text-sm leading-6 text-indigo-950">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <p>
              <strong>Draft restored.</strong> Your previous answers were
              recovered from this browser.
            </p>

            <button
              className="min-h-10 rounded-lg px-3 py-2 font-semibold text-indigo-800 underline decoration-indigo-300 underline-offset-4 hover:text-indigo-950"
              onClick={discardDraft}
              type="button"
            >
              Discard draft
            </button>
          </div>
        </div>
      ) : null}

      <div className="space-y-5">
        {questions.map((question) => (
          <div id={question.id} key={question.id}>
            <QuestionInput
              error={errors[question.id]}
              onChange={updateAnswer}
              question={question}
              value={answers[question.id]}
            />
          </div>
        ))}
      </div>

      {submissionState.kind === "error" ? (
        <div
          aria-live="polite"
          className="mt-6 rounded-2xl border border-red-200 bg-red-50 p-5 text-red-950"
        >
          <h2 className="font-bold">Your feedback was not submitted.</h2>
          <p className="mt-2 text-sm leading-6">{submissionState.message}</p>
          <p className="mt-2 text-sm leading-6">
            Your answers remain saved on this device.
          </p>
        </div>
      ) : null}

      <button
        className="mt-6 inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-indigo-400"
        disabled={submissionState.kind === "submitting"}
        type="submit"
      >
        {submissionState.kind === "submitting"
          ? "Submitting feedback…"
          : "Submit feedback"}
      </button>

      <p className="mt-4 text-center text-sm leading-6 text-slate-500">
        Your draft is saved on this device until your submission is accepted.
      </p>
    </form>
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

Both commands should complete successfully.

---

## Step 6.2 — Add Inngest local-development configuration

### The Target

Add the local configuration required to run Inngest without production credentials.

### The Concept

The Inngest Dev Server is a local version of the event system.

During development:

```text
Next.js application         → http://localhost:3000
Inngest Dev Server          → http://localhost:8288
Inngest function endpoint   → http://localhost:3000/api/inngest
```

The Dev Server receives events, discovers registered functions, runs jobs, and shows logs in a browser dashboard.

### The Implementation

Add this variable to `.env.example`.

### `.env.example`

```dotenv
# Set to "1" during local development so the Inngest SDK uses the local
# Inngest Dev Server instead of attempting to use the production platform.
INNGEST_DEV="1"
```

Add the same value to your private environment file.

### `.env`

```dotenv
INNGEST_DEV="1"
```

Update the environment schema.

### `src/lib/env.ts`

Add this optional field inside `environmentSchema`:

```ts
INNGEST_DEV: z.enum(["0", "1"]).optional(),
```

Add this value inside the `safeParse` object:

```ts
INNGEST_DEV: process.env.INNGEST_DEV,
```

The relevant portion should now look like this:

```ts
  INNGEST_EVENT_KEY: z.string().optional(),
  INNGEST_SIGNING_KEY: z.string().optional(),
  INNGEST_DEV: z.enum(["0", "1"]).optional(),
```

Update the Inngest client so empty production keys become `undefined`.

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

Add the following script to the existing `scripts` section of `package.json`.

### `package.json`

```json
{
  "scripts": {
    "inngest:dev": "npx inngest-cli@latest dev -u http://localhost:3000/api/inngest"
  }
}
```

Keep all existing scripts unchanged.

### The Verification

Run:

```bash
npm run lint
```

The command should complete successfully.

---

## Step 6.3 — Create a retry-safe response persistence service

### The Target

Create server-side code that writes one response and its answers to Neon.

### The Concept

Inngest can retry a function when a database connection or network request temporarily fails.

Retries are useful, but they create an important requirement:

> Retrying the same background job must not create duplicate feedback.

We solve this using the unique `Response.eventId` column.

The browser creates `submissionId`, the API includes it in the Inngest event, and the worker stores it as `eventId`.

```text
Submission ID: 5c6721c3-...
       ↓
Response.eventId: 5c6721c3-...
       ↓
Unique database constraint prevents duplicates
```

### The Implementation

Create this file.

### `src/lib/save-feedback-response.ts`

```ts
import "server-only";

import { Prisma } from "@prisma/client";
import { prisma } from "@/lib/prisma";
import type { FeedbackSubmissionEventData } from "@/lib/feedback-submission";

type SaveFeedbackResponseResult = {
  responseId: string;
  duplicate: boolean;
};

/**
 * Saves a feedback submission exactly once.
 *
 * The API already validates answers against the active published form before
 * sending the event. This function performs an additional ownership check:
 * the stored form version and submitted questions must belong to the expected
 * session. That protects the database if an event is ever sent incorrectly.
 */
export async function saveFeedbackResponse(
  submission: FeedbackSubmissionEventData,
): Promise<SaveFeedbackResponseResult> {
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

  const formVersion = await prisma.formVersion.findFirst({
    where: {
      id: submission.formVersionId,
      sessionId: submission.sessionId,
    },
    include: {
      questions: {
        select: {
          id: true,
        },
      },
    },
  });

  if (!formVersion) {
    throw new Error(
      "The submitted form version does not belong to the specified session.",
    );
  }

  const validQuestionIds = new Set(
    formVersion.questions.map((question) => question.id),
  );

  for (const answer of submission.answers) {
    if (!validQuestionIds.has(answer.questionId)) {
      throw new Error(
        `The submitted answer references a question outside form version ${submission.formVersionId}.`,
      );
    }
  }

  try {
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
      select: {
        id: true,
      },
    });

    return {
      responseId: response.id,
      duplicate: false,
    };
  } catch (error) {
    /**
     * A duplicate can occur if two worker invocations race to save the same
     * event. The unique eventId constraint is the final safety net.
     */
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === "P2002"
    ) {
      const duplicateResponse = await prisma.response.findUnique({
        where: {
          eventId: submission.submissionId,
        },
        select: {
          id: true,
        },
      });

      if (duplicateResponse) {
        return {
          responseId: duplicateResponse.id,
          duplicate: true,
        };
      }
    }

    throw error;
  }
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

## Step 6.4 — Create the Inngest feedback-processing function

### The Target

Create a background function that reacts to the `feedback/submitted` event.

### The Concept

An Inngest function is like a reliable back-office worker.

The API does not wait for the worker to finish. Instead, it sends the worker a job ticket:

```text
feedback/submitted
```

The worker then:

1. Receives the event.
2. Runs the database persistence step.
3. Retries if that step temporarily fails.
4. Records a clear outcome in the Inngest dashboard.

`step.run()` is important because Inngest tracks the step independently. If the job needs a retry, Inngest can resume intelligently instead of treating the whole workflow as an opaque block.

### The Implementation

Create this file.

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

    /**
     * Part 7 calculates dashboard analytics directly from the authoritative
     * response records. This deliberately avoids maintaining fragile duplicate
     * aggregate tables during the first implementation.
     */
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

Create an index that exports every registered Inngest function.

### `src/inngest/functions/index.ts`

```ts
import { processFeedbackSubmission } from "./process-feedback-submission";

export const inngestFunctions = [processFeedbackSubmission];
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

Both commands should complete successfully.

---

## Step 6.5 — Create the Inngest function endpoint

### The Target

Expose the Next.js route Inngest uses to discover and invoke GreyMatter Feedback background functions.

### The Concept

The Inngest Dev Server and production Inngest platform need one known route where they can ask:

```text
Which functions does this application provide?
```

For GreyMatter Feedback, that route is:

```text
/api/inngest
```

It is a server-only integration endpoint, not a participant-facing API.

### The Implementation

Create the directory:

```bash
mkdir -p src/app/api/inngest
```

Create this file.

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

### The Verification

Start the Next.js development server in one terminal:

```bash
npm run dev
```

In a second terminal, start the Inngest Dev Server:

```bash
npm run inngest:dev
```

The terminal should display output similar to:

```text
Inngest Dev Server running at http://localhost:8288
```

Open:

```text
http://localhost:8288
```

In the Inngest dashboard, open **Functions**.

You should see:

```text
process-feedback-submission
```

If it does not appear:

1. Confirm Next.js is running at `http://localhost:3000`.
2. Open this URL directly:

   ```text
   http://localhost:3000/api/inngest
   ```

3. Confirm `INNGEST_DEV="1"` is present in `.env`.
4. Restart both terminal processes after changing environment values.

---

## Step 6.6 — Submit real feedback and inspect the completed Inngest job

### The Target

Submit feedback from the participant page and confirm that Inngest saves it to Neon.

### The Concept

This is the first full end-to-end participant submission:

```text
Phone or browser form
       ↓
Secure API
       ↓
Inngest event
       ↓
Background function
       ↓
Neon response and answer records
```

### The Implementation

Keep both processes running:

Terminal one:

```bash
npm run dev
```

Terminal two:

```bash
npm run inngest:dev
```

Open the sample participant form:

```text
http://localhost:3000/e/REACT-2026-Q3?src=qr
```

Fill in the form with example values:

```text
How useful was this workshop?                  5
How likely are you to recommend it?            9
Which topic was most valuable?                 Server Components
What should we improve?                        Add more time for the hands-on exercises.
```

Click:

```text
Submit feedback
```

### The Verification

The participant page should display:

```text
Feedback received
Thank you for your feedback.
```

Open the local Inngest dashboard:

```text
http://localhost:8288
```

Open **Runs** and locate the latest run for:

```text
process-feedback-submission
```

Confirm these steps succeeded:

```text
save-response-and-answers
record-processing-complete
```

Then inspect Neon with Prisma Studio:

```bash
npx prisma studio
```

Verify the following.

### `Response` table

You should see one new response with:

- A generated UUID `id`.
- The session ID `REACT-2026-Q3`.
- The form version ID used by the participant page.
- A 64-character `clientIpHash`.
- Metadata containing source, screen size, and user agent.
- A unique `eventId`.

### `Answer` table

You should see four answers linked to that response:

| Question type | Stored field |
|---|---|
| Rating | `numericValue = 5` |
| NPS | `numericValue = 9` |
| Choice | `textValue = "Server Components"` |
| Text | `textValue = "Add more time for the hands-on exercises."` |

Stop Prisma Studio when finished:

```bash
Ctrl+C
```

---

## Step 6.7 — Verify idempotency manually

### The Target

Prove that processing the same submission ID more than once does not create duplicate responses.

### The Concept

Reliable systems assume that retries happen.

A job may retry because of:

- A temporary Neon connection issue.
- A network timeout.
- A function restart.
- An Inngest delivery retry.

The unique database constraint on `Response.eventId` ensures that only one response is created for a submission ID.

### The Implementation

Open the Inngest dashboard:

```text
http://localhost:8288
```

1. Open the successful `process-feedback-submission` run created in Step 6.6.
2. Use the dashboard’s **Replay** or **Retry** control.
3. Wait for the replayed run to complete.

### The Verification

The replayed run should complete successfully.

Open Prisma Studio again:

```bash
npx prisma studio
```

Check the `Response` table.

There should still be only **one** response record with the original `eventId`.

In the replayed Inngest run logs, the output should include:

```text
duplicate: true
```

This proves the response-save operation is idempotent.

---

## Step 6.8 — Test participant rate limiting

### The Target

Confirm that the same device cannot submit repeatedly to the same session within the configured five-minute window.

### The Concept

Rate limiting is the system’s anti-spam gate.

The current development configuration allows:

```text
1 submission per client IP hash per session every 5 minutes
```

Because local development uses `unknown-client` when no forwarding headers are available, all local browser requests share one development identity.

That behavior is acceptable for testing. Production platforms such as Vercel, Cloudflare, or a reverse proxy normally provide the true client IP through forwarded headers.

### The Implementation

With the development server and Inngest Dev Server still running:

1. Refresh the participant form:

   ```text
   http://localhost:3000/e/REACT-2026-Q3
   ```

2. Fill in required answers again.

3. Submit another response from the same browser.

### The Verification

You should see an error similar to:

```text
Too many feedback submissions were received from this device. Please try again later.
```

To reset the local development fallback rate limiter, stop and restart the Next.js server:

```bash
Ctrl+C
npm run dev
```

> In production, rate-limit data lives in Upstash Redis and does not disappear when one application process restarts.

---

## Step 6.9 — Create a production Inngest project

### The Target

Prepare the production configuration required when you deploy GreyMatter Feedback.

### The Concept

The local Dev Server is only for development. In production, the hosted Inngest platform receives events and invokes your deployed `/api/inngest` endpoint.

### The Implementation

1. Visit:

   ```text
   https://www.inngest.com
   ```

2. Create an account or sign in.

3. Create an app named:

   ```text
   greymatter-feedback
   ```

4. Copy the values Inngest provides for:

   ```text
   INNGEST_EVENT_KEY
   INNGEST_SIGNING_KEY
   ```

5. Add them to your deployment platform’s environment variables.

6. In production, set:

   ```dotenv
   INNGEST_DEV="0"
   ```

7. Configure the Inngest app’s sync URL to point to your deployed route:

   ```text
   https://your-domain.example/api/inngest
   ```

Do not set production secrets in `.env.example`.

### The Verification

After deployment, Inngest should display the deployed function:

```text
process-feedback-submission
```

A production submission should appear as a successful run in the Inngest dashboard and a new response in Neon.

---

## Part 6 Completion Check

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

Then complete this end-to-end test:

1. Start Next.js:

   ```bash
   npm run dev
   ```

2. Start Inngest:

   ```bash
   npm run inngest:dev
   ```

3. Open:

   ```text
   http://localhost:3000/e/REACT-2026-Q3
   ```

4. Submit valid feedback.

5. Confirm participant success.

6. Confirm a successful Inngest run at:

   ```text
   http://localhost:8288
   ```

7. Confirm one new `Response` and linked `Answer` records in Prisma Studio.

---

## Part 6 Reference: Submission Architecture

GreyMatter Feedback now processes submissions with this complete workflow:

```text
Participant feedback form
        ↓
Local browser draft with stable submission ID
        ↓
POST /api/feedback
        ↓
Zod validation
        ↓
IP hashing and rate limiting
        ↓
Published form and answer validation
        ↓
Inngest feedback/submitted event
        ↓
process-feedback-submission function
        ↓
Idempotent Neon Response + Answer writes
```

Important files added in this part:

```text
src/
├── app/
│   └── api/
│       └── inngest/
│           └── route.ts
├── inngest/
│   ├── client.ts
│   └── functions/
│       ├── index.ts
│       └── process-feedback-submission.ts
└── lib/
    └── save-feedback-response.ts
```
