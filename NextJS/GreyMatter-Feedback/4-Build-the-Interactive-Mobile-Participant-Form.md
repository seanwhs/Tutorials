# Part 4: Build the Interactive Mobile Participant Form

In Part 2, the participant route displayed a read-only preview of the published form. In this part, we will replace that preview with a real interactive form.

The form will:

- Render all four question types dynamically.
- Save answers in browser localStorage.
- Restore a draft after refresh or accidental browser dismissal.
- Use touch-friendly controls.
- Trigger short haptic feedback on supported phones.
- Validate required fields in the browser before attempting submission.
- Show a clear “ready to submit” state.

> The actual secure API submission endpoint, IP hashing, rate limiting, and Inngest processing are built in Part 5 and Part 6. For now, this form collects, validates, and persists answers locally.

---

## Step 4.1 — Define participant answer types and draft storage

### The Target

Create a browser-safe local draft store for participant answers.

### The Concept

A form draft is like writing answers in pencil before placing the final form in a feedback box.

If a participant accidentally closes the browser, refreshes the page, or loses their place, GreyMatter Feedback can restore their unfinished answers from `localStorage`.

`localStorage` is browser storage that remains available after a page refresh. It is suitable for temporary, non-sensitive drafts. We will not store identity data, passwords, or secrets there.

Each draft key includes:

- The session ID.
- The form version ID.

This matters because a new published form version must not accidentally reuse answers from an old version.

### The Implementation

Create this file.

### `src/lib/participant-draft.ts`

```ts
"use client";

export type ParticipantAnswerValue = number | string;

export type ParticipantDraft = {
  answers: Record<string, ParticipantAnswerValue>;
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
    // A corrupted local draft should never prevent the form from loading.
    return null;
  }
}

export function saveParticipantDraft(
  sessionId: string,
  formVersionId: string,
  answers: Record<string, ParticipantAnswerValue>,
): void {
  if (typeof window === "undefined") {
    return;
  }

  const draft: ParticipantDraft = {
    answers,
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

### The Verification

Run:

```bash
npm run lint
```

You should receive no lint errors.

---

## Step 4.2 — Create the interactive dynamic question controls

### The Target

Create reusable interactive controls for rating, NPS, choice, and text questions.

### The Concept

The form receives question configuration from Neon. The question type tells the UI which control to show:

```text
RATING → numeric score buttons
NPS    → buttons from 0 through 10
CHOICE → radio options
TEXT   → text area
```

The controls do not know about a particular event or course. They only know how to render one configured question. This makes them reusable for every future form.

### The Implementation

Create this file.

### `src/components/participant/question-input.tsx`

```tsx
"use client";

import { QuestionType } from "@prisma/client";
import type {
  NpsSettings,
  ParticipantQuestion,
  RatingSettings,
  TextSettings,
} from "@/types/forms";
import type { ParticipantAnswerValue } from "@/lib/participant-draft";

type QuestionInputProps = {
  question: ParticipantQuestion;
  value: ParticipantAnswerValue | undefined;
  error?: string;
  onChange: (questionId: string, value: ParticipantAnswerValue) => void;
};

function vibrateBriefly(): void {
  if (typeof navigator !== "undefined" && "vibrate" in navigator) {
    navigator.vibrate(10);
  }
}

function QuestionHeading({ question }: { question: ParticipantQuestion }) {
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

export function QuestionInput({
  question,
  value,
  error,
  onChange,
}: QuestionInputProps) {
  const describedBy = error ? `${question.id}-error` : undefined;

  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
      <QuestionHeading question={question} />

      {question.questionType === QuestionType.RATING ? (
        <RatingInput
          describedBy={describedBy}
          onChange={onChange}
          question={question}
          value={value}
        />
      ) : null}

      {question.questionType === QuestionType.NPS ? (
        <NpsInput
          describedBy={describedBy}
          onChange={onChange}
          question={question}
          value={value}
        />
      ) : null}

      {question.questionType === QuestionType.CHOICE ? (
        <ChoiceInput
          describedBy={describedBy}
          onChange={onChange}
          question={question}
          value={value}
        />
      ) : null}

      {question.questionType === QuestionType.TEXT ? (
        <TextInput onChange={onChange} question={question} value={value} />
      ) : null}

      {error ? (
        <p
          className="mt-3 text-sm font-medium text-red-700"
          id={`${question.id}-error`}
          role="alert"
        >
          {error}
        </p>
      ) : null}
    </section>
  );
}

function RatingInput({
  question,
  value,
  onChange,
  describedBy,
}: Omit<QuestionInputProps, "error"> & { describedBy?: string }) {
  const settings = question.settings as RatingSettings;
  const scores = Array.from(
    { length: settings.max - settings.min + 1 },
    (_, index) => settings.min + index,
  );

  return (
    <>
      <div
        aria-describedby={describedBy}
        aria-label={`${question.questionText} rating`}
        className="grid grid-cols-5 gap-2 sm:flex sm:flex-wrap"
        role="radiogroup"
      >
        {scores.map((score) => {
          const selected = value === score;

          return (
            <button
              aria-checked={selected}
              className={`min-h-12 rounded-xl border px-4 py-3 font-semibold transition ${
                selected
                  ? "border-indigo-600 bg-indigo-600 text-white"
                  : "border-slate-300 bg-white text-slate-700 hover:border-indigo-400 hover:bg-indigo-50"
              }`}
              key={score}
              onClick={() => {
                vibrateBriefly();
                onChange(question.id, score);
              }}
              role="radio"
              type="button"
            >
              {score}
            </button>
          );
        })}
      </div>

      <div className="mt-3 flex justify-between gap-4 text-sm text-slate-500">
        <span>{settings.minLabel}</span>
        <span className="text-right">{settings.maxLabel}</span>
      </div>
    </>
  );
}

function NpsInput({
  question,
  value,
  onChange,
  describedBy,
}: Omit<QuestionInputProps, "error"> & { describedBy?: string }) {
  const settings = question.settings as NpsSettings;

  return (
    <>
      <div
        aria-describedby={describedBy}
        aria-label={`${question.questionText} score`}
        className="grid grid-cols-6 gap-2 sm:grid-cols-11"
        role="radiogroup"
      >
        {Array.from({ length: 11 }, (_, index) => index).map((score) => {
          const selected = value === score;

          return (
            <button
              aria-checked={selected}
              className={`min-h-12 rounded-xl border px-3 py-3 font-semibold transition ${
                selected
                  ? "border-indigo-600 bg-indigo-600 text-white"
                  : "border-slate-300 bg-white text-slate-700 hover:border-indigo-400 hover:bg-indigo-50"
              }`}
              key={score}
              onClick={() => {
                vibrateBriefly();
                onChange(question.id, score);
              }}
              role="radio"
              type="button"
            >
              {score}
            </button>
          );
        })}
      </div>

      <div className="mt-3 flex justify-between gap-4 text-sm text-slate-500">
        <span>{settings.minLabel}</span>
        <span className="text-right">{settings.maxLabel}</span>
      </div>
    </>
  );
}

function ChoiceInput({
  question,
  value,
  onChange,
  describedBy,
}: Omit<QuestionInputProps, "error"> & { describedBy?: string }) {
  return (
    <div aria-describedby={describedBy} className="space-y-3" role="radiogroup">
      {question.options.map((option) => {
        const selected = value === option;

        return (
          <button
            aria-checked={selected}
            className={`flex min-h-12 w-full items-center gap-3 rounded-xl border px-4 py-3 text-left transition ${
              selected
                ? "border-indigo-600 bg-indigo-50 text-indigo-950"
                : "border-slate-300 bg-white text-slate-700 hover:border-indigo-400"
            }`}
            key={option}
            onClick={() => onChange(question.id, option)}
            role="radio"
            type="button"
          >
            <span
              aria-hidden="true"
              className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full border ${
                selected ? "border-indigo-600 bg-indigo-600" : "border-slate-400"
              }`}
            >
              {selected ? <span className="h-2 w-2 rounded-full bg-white" /> : null}
            </span>
            <span>{option}</span>
          </button>
        );
      })}
    </div>
  );
}

function TextInput({
  question,
  value,
  onChange,
}: Omit<QuestionInputProps, "error">) {
  const settings = question.settings as TextSettings;
  const textValue = typeof value === "string" ? value : "";

  return (
    <div>
      <textarea
        className="min-h-32 w-full resize-y rounded-xl border border-slate-300 bg-white px-4 py-3 text-base text-slate-950 placeholder:text-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
        maxLength={settings.maxLength}
        onChange={(event) => onChange(question.id, event.target.value)}
        placeholder={settings.placeholder ?? "Write your feedback here."}
        rows={5}
        value={textValue}
      />

      <p className="mt-2 text-right text-sm text-slate-500">
        {textValue.length}/{settings.maxLength}
      </p>
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

Both commands should succeed.

---

## Step 4.3 — Create the participant form client component

### The Target

Create the component that manages answers, restores drafts, validates required fields, and displays submission readiness.

### The Concept

This component is the participant’s clipboard. It holds answers while the page is open, writes them to browser storage, and checks that required questions are answered.

React state updates immediately, so interactions feel responsive. Saving a draft happens after each answer change, which means accidental refreshes are recoverable.

### The Implementation

Create this file.

### `src/components/participant/feedback-form.tsx`

```tsx
"use client";

import { useEffect, useState } from "react";
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

function isAnswered(value: ParticipantAnswerValue | undefined): boolean {
  if (typeof value === "number") {
    return true;
  }

  return typeof value === "string" && value.trim().length > 0;
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
  const [readyForSubmission, setReadyForSubmission] = useState(false);

  useEffect(() => {
    const storedDraft = loadParticipantDraft(sessionId, formVersionId);

    if (storedDraft) {
      setAnswers(storedDraft.answers);
      setDraftRestored(true);
    }
  }, [formVersionId, sessionId]);

  function updateAnswer(questionId: string, value: ParticipantAnswerValue) {
    setReadyForSubmission(false);

    setAnswers((currentAnswers) => {
      const nextAnswers = {
        ...currentAnswers,
        [questionId]: value,
      };

      saveParticipantDraft(sessionId, formVersionId, nextAnswers);

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

  function handleReview(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const validationErrors = validateForm();
    setErrors(validationErrors);

    if (Object.keys(validationErrors).length > 0) {
      setReadyForSubmission(false);

      const firstInvalidQuestionId = Object.keys(validationErrors)[0];

      document
        .getElementById(firstInvalidQuestionId ?? "")
        ?.scrollIntoView({ behavior: "smooth", block: "center" });

      return;
    }

    setReadyForSubmission(true);
  }

  function discardDraft() {
    clearParticipantDraft(sessionId, formVersionId);
    setAnswers({});
    setErrors({});
    setDraftRestored(false);
    setReadyForSubmission(false);
  }

  return (
    <form onSubmit={handleReview}>
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

      {readyForSubmission ? (
        <div
          aria-live="polite"
          className="mt-6 rounded-2xl border border-emerald-200 bg-emerald-50 p-5 text-emerald-950"
        >
          <h2 className="font-bold">Your feedback is ready to submit.</h2>
          <p className="mt-2 text-sm leading-6">
            The secure submission API is added in Part 5. Your answers are
            currently saved as a local draft in this browser.
          </p>
        </div>
      ) : null}

      <button
        className="mt-6 inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700"
        type="submit"
      >
        Review feedback
      </button>

      <p className="mt-4 text-center text-sm leading-6 text-slate-500">
        Your draft is saved on this device until you submit or discard it.
      </p>
    </form>
  );
}
```

### The Verification

Run:

```bash
npm run lint
npm run build
```

Both should complete successfully.

---

## Step 4.4 — Replace the read-only preview with the interactive form

### The Target

Update the participant page to render `FeedbackForm`.

### The Concept

The route remains a Server Component because it securely loads the form configuration from Neon. It then passes only safe participant-facing data to the Client Component.

This keeps database credentials on the server while allowing the phone interface to respond instantly.

### The Implementation

Replace the complete contents of this file.

### `src/app/e/[sessionId]/page.tsx`

```tsx
import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { FeedbackForm } from "@/components/participant/feedback-form";
import { SessionUnavailable } from "@/components/participant/session-unavailable";
import { getParticipantSession } from "@/lib/participant-session";

type ParticipantSessionPageProps = {
  params: Promise<{
    sessionId: string;
  }>;
};

export async function generateMetadata({
  params,
}: ParticipantSessionPageProps): Promise<Metadata> {
  const { sessionId } = await params;
  const state = await getParticipantSession(sessionId);

  if (state.kind !== "ready") {
    return { title: "Feedback" };
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

        <FeedbackForm
          formVersionId={state.session.formVersionId}
          questions={state.session.questions}
          sessionId={state.session.id}
        />

        <p className="mt-6 text-center text-xs text-slate-400">
          Form version {state.session.formVersionNumber}
        </p>
      </section>
    </main>
  );
}
```

### The Verification

Start the application:

```bash
npm run dev
```

Open:

```text
http://localhost:3000/e/REACT-2026-Q3?src=qr
```

Verify all of the following:

1. Rating buttons can be selected.
2. NPS buttons can be selected.
3. Choice options can be selected.
4. Text can be entered.
5. Clicking a rating or NPS score causes a short vibration on supported phones.
6. Clicking **Review feedback** without answering required questions displays validation errors.
7. Answer all required questions, then click **Review feedback**.
8. You should see:

   ```text
   Your feedback is ready to submit.
   ```

9. Refresh the page.
10. You should see:

   ```text
   Draft restored.
   ```

11. Click **Discard draft**.
12. Refresh again and confirm the old answers no longer appear.

---

## Part 4 Completion Check

Run:

```bash
npm run lint
npm run build
```

Then test the form on a narrow browser window or a real phone.

Confirm that:

- Every button remains easy to tap.
- Inputs use 16px text to prevent mobile auto-zoom.
- Drafts restore after refresh.
- Form validation works.
- The participant page still blocks inactive or unpublished sessions.
