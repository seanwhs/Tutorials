# Part 3: Administrator Authentication and the Form Authoring Environment

This part builds the protected administrator area where organizers can:

- Sign in securely.
- Create events and courses.
- Create feedback sessions.
- Create draft form versions.
- Add questions to a draft.
- Configure rating, NPS, choice, and text questions.
- Move questions up and down.
- Publish a form version.
- View the participant QR URL.

By the end of this part, you will no longer need Prisma Studio to create or manage forms.

---

## Step 3.1 — Create signed administrator authentication

### The Target

Create a password-protected administrator session using a signed HTTP-only cookie.

### The Concept

The administrator password is checked on the server. When it is correct, the server creates a short-lived signed token and stores it in an **HTTP-only cookie**.

An HTTP-only cookie is like a sealed staff badge:

- The browser carries it automatically when requesting protected pages.
- Browser JavaScript cannot read it.
- The server verifies that the badge has not been forged or expired.

For this tutorial, there is one administrator password stored in:

```dotenv
ADMIN_PASSWORD="your-strong-password"
```

A future production version could replace this with multiple users, password hashes, and role-based permissions.

### The Implementation

Create this file.

### `src/lib/admin-auth.ts`

```ts
import "server-only";

import { createHmac, timingSafeEqual } from "node:crypto";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { env } from "@/lib/env";

const ADMIN_SESSION_COOKIE_NAME = "greymatter_admin_session";
const SESSION_DURATION_SECONDS = 60 * 60 * 8;

type AdminSessionPayload = {
  expiresAt: number;
  role: "admin";
};

function encodeBase64Url(value: string): string {
  return Buffer.from(value, "utf8").toString("base64url");
}

function decodeBase64Url(value: string): string | null {
  try {
    return Buffer.from(value, "base64url").toString("utf8");
  } catch {
    return null;
  }
}

function signPayload(encodedPayload: string): string {
  return createHmac("sha256", env.ADMIN_SESSION_SECRET)
    .update(encodedPayload)
    .digest("base64url");
}

function safelyCompare(left: string, right: string): boolean {
  const leftBuffer = Buffer.from(left, "utf8");
  const rightBuffer = Buffer.from(right, "utf8");

  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }

  return timingSafeEqual(leftBuffer, rightBuffer);
}

function createSessionToken(): string {
  const payload: AdminSessionPayload = {
    expiresAt: Math.floor(Date.now() / 1000) + SESSION_DURATION_SECONDS,
    role: "admin",
  };

  const encodedPayload = encodeBase64Url(JSON.stringify(payload));
  const signature = signPayload(encodedPayload);

  return `${encodedPayload}.${signature}`;
}

function verifySessionToken(token: string | undefined): boolean {
  if (!token) {
    return false;
  }

  const [encodedPayload, receivedSignature, ...unexpectedParts] = token.split(".");

  if (
    !encodedPayload ||
    !receivedSignature ||
    unexpectedParts.length > 0 ||
    !safelyCompare(signPayload(encodedPayload), receivedSignature)
  ) {
    return false;
  }

  const decodedPayload = decodeBase64Url(encodedPayload);

  if (!decodedPayload) {
    return false;
  }

  try {
    const payload = JSON.parse(decodedPayload) as AdminSessionPayload;

    return (
      payload.role === "admin" &&
      Number.isInteger(payload.expiresAt) &&
      payload.expiresAt > Math.floor(Date.now() / 1000)
    );
  } catch {
    return false;
  }
}

export function verifyAdminPassword(password: string): boolean {
  return safelyCompare(password, env.ADMIN_PASSWORD);
}

export async function createAdminSession(): Promise<void> {
  const cookieStore = await cookies();

  cookieStore.set({
    name: ADMIN_SESSION_COOKIE_NAME,
    value: createSessionToken(),
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: SESSION_DURATION_SECONDS,
  });
}

export async function destroyAdminSession(): Promise<void> {
  const cookieStore = await cookies();

  cookieStore.set({
    name: ADMIN_SESSION_COOKIE_NAME,
    value: "",
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    path: "/",
    maxAge: 0,
  });
}

export async function isAdminAuthenticated(): Promise<boolean> {
  const cookieStore = await cookies();
  const token = cookieStore.get(ADMIN_SESSION_COOKIE_NAME)?.value;

  return verifySessionToken(token);
}

export async function requireAdmin(): Promise<void> {
  if (!(await isAdminAuthenticated())) {
    redirect("/admin/login");
  }
}
```

Create login server actions.

### `src/app/admin/login/actions.ts`

```ts
"use server";

import { redirect } from "next/navigation";
import {
  createAdminSession,
  verifyAdminPassword,
} from "@/lib/admin-auth";

export type LoginActionState = {
  error?: string;
};

export async function loginAction(
  _previousState: LoginActionState,
  formData: FormData,
): Promise<LoginActionState> {
  const passwordValue = formData.get("password");

  if (typeof passwordValue !== "string" || passwordValue.length === 0) {
    return {
      error: "Enter the administrator password.",
    };
  }

  if (!verifyAdminPassword(passwordValue)) {
    return {
      error: "The administrator password is incorrect.",
    };
  }

  await createAdminSession();
  redirect("/admin/events");
}
```

Create the login form as a Client Component because it uses React 19’s `useActionState`.

### `src/app/admin/login/login-form.tsx`

```tsx
"use client";

import { useActionState } from "react";
import { loginAction, type LoginActionState } from "./actions";

const initialState: LoginActionState = {};

export function LoginForm() {
  const [state, formAction, isPending] = useActionState(
    loginAction,
    initialState,
  );

  return (
    <form action={formAction} className="mt-8 space-y-5">
      <div>
        <label
          className="block text-sm font-semibold text-slate-800"
          htmlFor="password"
        >
          Administrator password
        </label>

        <input
          autoComplete="current-password"
          className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-base text-slate-950 shadow-sm placeholder:text-slate-400 focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
          id="password"
          name="password"
          placeholder="Enter your password"
          required
          type="password"
        />
      </div>

      {state.error ? (
        <p
          aria-live="polite"
          className="rounded-xl bg-red-50 p-4 text-sm font-medium text-red-800"
        >
          {state.error}
        </p>
      ) : null}

      <button
        className="inline-flex min-h-12 w-full items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:bg-indigo-400"
        disabled={isPending}
        type="submit"
      >
        {isPending ? "Signing in…" : "Sign in"}
      </button>
    </form>
  );
}
```

Replace the login page.

### `src/app/admin/login/page.tsx`

```tsx
import { redirect } from "next/navigation";
import { isAdminAuthenticated } from "@/lib/admin-auth";
import { LoginForm } from "./login-form";

export const metadata = {
  title: "Administrator Sign In",
};

export default async function AdminLoginPage() {
  if (await isAdminAuthenticated()) {
    redirect("/admin/events");
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-6 py-12">
      <section className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
        <p className="text-sm font-semibold uppercase tracking-wide text-indigo-700">
          GreyMatter Feedback
        </p>

        <h1 className="mt-3 text-3xl font-bold tracking-tight text-slate-950">
          Administrator sign in
        </h1>

        <p className="mt-3 leading-7 text-slate-600">
          Sign in to create sessions, author forms, publish QR feedback links,
          and review reporting.
        </p>

        <LoginForm />
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
http://localhost:3000/admin/login
```

Test these outcomes:

1. Submit the form empty. You should see:

   ```text
   Enter the administrator password.
   ```

2. Submit a wrong password. You should see:

   ```text
   The administrator password is incorrect.
   ```

3. Submit the password configured as `ADMIN_PASSWORD` in `.env`.

You will be redirected to `/admin/events`, which does not exist yet. A 404 is expected at this exact stage.

---

## Step 3.2 — Create the protected admin layout and navigation

### The Target

Create a shared layout that protects administrator routes and provides navigation.

### The Concept

All protected routes will live under this route group:

```text
src/app/(admin)/admin/
```

The parentheses create a **route group**. It helps organize files without adding `(admin)` to the URL.

Therefore:

```text
src/app/(admin)/admin/events/page.tsx
```

still becomes:

```text
/admin/events
```

The admin layout acts like a secure staff-only entrance. Every route inside it checks the administrator cookie before rendering.

### The Implementation

Create directories:

```bash
mkdir -p \
  "src/app/(admin)/admin/events/new" \
  "src/app/(admin)/admin/events/[eventId]" \
  "src/app/(admin)/admin/sessions/[sessionId]/edit"
```

Create a sign-out action.

### `src/app/(admin)/admin/actions.ts`

```ts
"use server";

import { redirect } from "next/navigation";
import { destroyAdminSession } from "@/lib/admin-auth";

export async function logoutAction(): Promise<void> {
  await destroyAdminSession();
  redirect("/admin/login");
}
```

Create the admin layout.

### `src/app/(admin)/admin/layout.tsx`

```tsx
import Link from "next/link";
import { requireAdmin } from "@/lib/admin-auth";
import { logoutAction } from "./actions";

export default async function AdminLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  await requireAdmin();

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex min-h-16 max-w-7xl items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
          <Link
            className="font-bold tracking-tight text-slate-950"
            href="/admin/events"
          >
            GreyMatter <span className="text-indigo-600">Feedback</span>
          </Link>

          <nav aria-label="Administrator navigation" className="flex items-center gap-3">
            <Link
              className="rounded-lg px-3 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-100"
              href="/admin/events"
            >
              Events and courses
            </Link>

            <form action={logoutAction}>
              <button
                className="min-h-10 rounded-lg px-3 py-2 text-sm font-semibold text-slate-700 transition hover:bg-slate-100"
                type="submit"
              >
                Sign out
              </button>
            </form>
          </nav>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
}
```

### The Verification

Visit:

```text
http://localhost:3000/admin/events
```

While signed in, you should now see the header and a 404 body because the page does not exist yet.

Sign out by visiting the browser developer tools and deleting the `greymatter_admin_session` cookie, or restart with a private/incognito browser window.

Then revisit:

```text
http://localhost:3000/admin/events
```

You should be redirected to:

```text
http://localhost:3000/admin/login
```

---

## Step 3.3 — Create authoring validation and shared form helpers

### The Target

Create one shared location for validating event, session, form-version, and question authoring input.

### The Concept

Administrator forms are friendlier than raw database editing, but they still accept untrusted browser data.

For example, a user could modify a request and send:

```text
maxLength=-500
```

or:

```text
questionType=NOT_A_REAL_TYPE
```

Zod validates every incoming value before a server action writes to Neon.

### The Implementation

Create this file.

### `src/lib/authoring.ts`

```ts
import "server-only";

import { QuestionType } from "@prisma/client";
import { z } from "zod";

export const eventInputSchema = z.object({
  title: z.string().trim().min(3).max(255),
});

export const sessionInputSchema = z.object({
  id: z
    .string()
    .trim()
    .toUpperCase()
    .min(3)
    .max(64)
    .regex(
      /^[A-Z0-9-]+$/,
      "Use uppercase letters, numbers, and hyphens only.",
    ),
  title: z.string().trim().min(3).max(255),
});

export const questionInputSchema = z
  .object({
    questionText: z.string().trim().min(3).max(2000),
    questionType: z.nativeEnum(QuestionType),
    isRequired: z.boolean(),
    ratingMin: z.coerce.number().int().min(1).max(10),
    ratingMax: z.coerce.number().int().min(2).max(10),
    ratingMinLabel: z.string().trim().max(100),
    ratingMaxLabel: z.string().trim().max(100),
    textMaxLength: z.coerce.number().int().min(1).max(5000),
    textPlaceholder: z.string().trim().max(250),
    choiceOptions: z.string().max(5000),
  })
  .superRefine((value, context) => {
    if (
      value.questionType === QuestionType.RATING &&
      value.ratingMax <= value.ratingMin
    ) {
      context.addIssue({
        code: z.ZodIssueCode.custom,
        message: "The maximum rating must be greater than the minimum rating.",
        path: ["ratingMax"],
      });
    }

    if (value.questionType === QuestionType.CHOICE) {
      const options = normalizeChoiceOptions(value.choiceOptions);

      if (options.length < 2) {
        context.addIssue({
          code: z.ZodIssueCode.custom,
          message: "A choice question needs at least two options.",
          path: ["choiceOptions"],
        });
      }
    }
  });

export function normalizeChoiceOptions(rawOptions: string): string[] {
  const uniqueOptions = new Set<string>();

  for (const rawOption of rawOptions.split("\n")) {
    const option = rawOption.trim();

    if (option.length > 0 && option.length <= 250) {
      uniqueOptions.add(option);
    }
  }

  return [...uniqueOptions];
}

export function getQuestionStorageValues(input: z.infer<typeof questionInputSchema>) {
  switch (input.questionType) {
    case QuestionType.RATING:
      return {
        settings: {
          min: input.ratingMin,
          max: input.ratingMax,
          minLabel: input.ratingMinLabel || undefined,
          maxLabel: input.ratingMaxLabel || undefined,
        },
        options: [],
      };

    case QuestionType.NPS:
      return {
        settings: {
          minLabel: input.ratingMinLabel || "Not at all likely",
          maxLabel: input.ratingMaxLabel || "Extremely likely",
        },
        options: [],
      };

    case QuestionType.TEXT:
      return {
        settings: {
          maxLength: input.textMaxLength,
          placeholder: input.textPlaceholder || undefined,
        },
        options: [],
      };

    case QuestionType.CHOICE:
      return {
        settings: {},
        options: normalizeChoiceOptions(input.choiceOptions),
      };
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

Both commands should pass.

---

## Step 3.4 — Create event and course management

### The Target

Create an administrator page that lists events and courses, plus a page for creating them.

### The Concept

In GreyMatter Feedback, an event is the parent container for sessions.

An event can represent:

```text
A conference
A course
A workshop series
A training program
A company event
```

The database intentionally uses the neutral name `Event`, but the admin interface can call these “events and courses.”

### The Implementation

Create event server actions.

### `src/app/(admin)/admin/events/actions.ts`

```ts
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { eventInputSchema } from "@/lib/authoring";
import { prisma } from "@/lib/prisma";

export type EventActionState = {
  error?: string;
};

export async function createEventAction(
  _previousState: EventActionState,
  formData: FormData,
): Promise<EventActionState> {
  const parsedInput = eventInputSchema.safeParse({
    title: formData.get("title"),
  });

  if (!parsedInput.success) {
    return {
      error: "Enter an event or course name between 3 and 255 characters.",
    };
  }

  const event = await prisma.event.create({
    data: {
      title: parsedInput.data.title,
    },
    select: {
      id: true,
    },
  });

  revalidatePath("/admin/events");
  redirect(`/admin/events/${event.id}`);
}
```

Create an event creation form.

### `src/app/(admin)/admin/events/new/event-form.tsx`

```tsx
"use client";

import { useActionState } from "react";
import {
  createEventAction,
  type EventActionState,
} from "../actions";

const initialState: EventActionState = {};

export function EventForm() {
  const [state, formAction, isPending] = useActionState(
    createEventAction,
    initialState,
  );

  return (
    <form action={formAction} className="space-y-5">
      <div>
        <label
          className="block text-sm font-semibold text-slate-800"
          htmlFor="title"
        >
          Event or course name
        </label>

        <input
          className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base shadow-sm focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
          id="title"
          maxLength={255}
          name="title"
          placeholder="For example: Leadership Essentials"
          required
        />
      </div>

      {state.error ? (
        <p
          aria-live="polite"
          className="rounded-xl bg-red-50 p-4 text-sm text-red-800"
        >
          {state.error}
        </p>
      ) : null}

      <button
        className="inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:bg-indigo-400"
        disabled={isPending}
        type="submit"
      >
        {isPending ? "Creating…" : "Create event or course"}
      </button>
    </form>
  );
}
```

Create the new event page.

### `src/app/(admin)/admin/events/new/page.tsx`

```tsx
import Link from "next/link";
import { EventForm } from "./event-form";

export const metadata = {
  title: "Create Event or Course",
};

export default function NewEventPage() {
  return (
    <section className="mx-auto max-w-2xl">
      <Link
        className="text-sm font-semibold text-indigo-700 hover:text-indigo-900"
        href="/admin/events"
      >
        ← Back to events and courses
      </Link>

      <h1 className="mt-5 text-3xl font-bold tracking-tight text-slate-950">
        Create an event or course
      </h1>

      <p className="mt-3 leading-7 text-slate-600">
        Events are the parent containers for individual feedback sessions.
        A single course, conference, or training program can contain many
        sessions.
      </p>

      <div className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <EventForm />
      </div>
    </section>
  );
}
```

Create the event list page.

### `src/app/(admin)/admin/events/page.tsx`

```tsx
import Link from "next/link";
import { prisma } from "@/lib/prisma";

export const metadata = {
  title: "Events and Courses",
};

export default async function EventsPage() {
  const events = await prisma.event.findMany({
    include: {
      _count: {
        select: {
          sessions: true,
        },
      },
    },
    orderBy: {
      createdAt: "desc",
    },
  });

  return (
    <section>
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight text-slate-950">
            Events and courses
          </h1>
          <p className="mt-2 leading-7 text-slate-600">
            Create a parent event, then add sessions and their versioned
            feedback forms.
          </p>
        </div>

        <Link
          className="inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700"
          href="/admin/events/new"
        >
          Create event or course
        </Link>
      </div>

      {events.length === 0 ? (
        <div className="mt-8 rounded-2xl border border-dashed border-slate-300 bg-white p-8 text-center">
          <h2 className="text-xl font-bold text-slate-950">
            No events yet
          </h2>
          <p className="mt-3 text-slate-600">
            Create your first event or course to begin authoring feedback
            sessions.
          </p>
        </div>
      ) : (
        <div className="mt-8 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {events.map((event) => (
            <Link
              className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:border-indigo-300 hover:shadow-md"
              href={`/admin/events/${event.id}`}
              key={event.id}
            >
              <h2 className="text-xl font-bold text-slate-950">
                {event.title}
              </h2>

              <p className="mt-3 text-sm text-slate-600">
                {event._count.sessions}{" "}
                {event._count.sessions === 1 ? "session" : "sessions"}
              </p>

              <p className="mt-6 text-sm font-semibold text-indigo-700">
                Manage sessions →
              </p>
            </Link>
          ))}
        </div>
      )}
    </section>
  );
}
```

### The Verification

1. Sign in at:

   ```text
   http://localhost:3000/admin/login
   ```

2. Open:

   ```text
   http://localhost:3000/admin/events
   ```

3. Click **Create event or course**.

4. Create:

   ```text
   TypeScript Foundations
   ```

5. You will be redirected to an event detail URL that does not exist yet. A 404 is expected until the next step.

6. Go back to:

   ```text
   http://localhost:3000/admin/events
   ```

You should see both:

- `React Summit 2026` from the seed script.
- `TypeScript Foundations` from the admin form.

---

## Step 3.5 — Create session management

### The Target

Create an event detail page where administrators can create and view sessions.

### The Concept

A session is the item that receives:

- A QR-code URL.
- One active published form.
- Participant responses.
- Analytics and reports.

For a course, a session may be a module or final evaluation. For a conference, it may be a keynote, panel, or workshop.

### The Implementation

Create session creation action.

### `src/app/(admin)/admin/events/[eventId]/actions.ts`

```ts
"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { sessionInputSchema } from "@/lib/authoring";
import { prisma } from "@/lib/prisma";

export type SessionActionState = {
  error?: string;
};

export async function createSessionAction(
  eventId: string,
  _previousState: SessionActionState,
  formData: FormData,
): Promise<SessionActionState> {
  const parsedInput = sessionInputSchema.safeParse({
    id: formData.get("id"),
    title: formData.get("title"),
  });

  if (!parsedInput.success) {
    return {
      error:
        "Enter a valid title and an ID using 3–64 uppercase letters, numbers, or hyphens.",
    };
  }

  const event = await prisma.event.findUnique({
    where: {
      id: eventId,
    },
    select: {
      id: true,
    },
  });

  if (!event) {
    return {
      error: "The selected event or course no longer exists.",
    };
  }

  const existingSession = await prisma.session.findUnique({
    where: {
      id: parsedInput.data.id,
    },
    select: {
      id: true,
    },
  });

  if (existingSession) {
    return {
      error:
        "That session ID is already in use. Choose a unique ID for the QR URL.",
    };
  }

  const session = await prisma.session.create({
    data: {
      id: parsedInput.data.id,
      title: parsedInput.data.title,
      eventId: event.id,
    },
    select: {
      id: true,
    },
  });

  revalidatePath(`/admin/events/${eventId}`);
  revalidatePath("/admin/events");
  redirect(`/admin/sessions/${session.id}/edit`);
}
```

Create the session form.

### `src/app/(admin)/admin/events/[eventId]/session-form.tsx`

```tsx
"use client";

import { useActionState } from "react";
import {
  createSessionAction,
  type SessionActionState,
} from "./actions";

const initialState: SessionActionState = {};

export function SessionForm({ eventId }: { eventId: string }) {
  const action = createSessionAction.bind(null, eventId);

  const [state, formAction, isPending] = useActionState(
    action,
    initialState,
  );

  return (
    <form action={formAction} className="grid gap-5 md:grid-cols-2">
      <div>
        <label
          className="block text-sm font-semibold text-slate-800"
          htmlFor="title"
        >
          Session title
        </label>

        <input
          className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base shadow-sm focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
          id="title"
          maxLength={255}
          name="title"
          placeholder="For example: Module 1 — Components"
          required
        />
      </div>

      <div>
        <label
          className="block text-sm font-semibold text-slate-800"
          htmlFor="id"
        >
          QR session ID
        </label>

        <input
          className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 font-mono text-base uppercase shadow-sm focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
          id="id"
          maxLength={64}
          name="id"
          pattern="[A-Za-z0-9-]+"
          placeholder="TYPESCRIPT-MODULE-1"
          required
        />

        <p className="mt-2 text-sm leading-6 text-slate-500">
          This becomes part of the feedback URL. Use letters, numbers, and
          hyphens only.
        </p>
      </div>

      {state.error ? (
        <p
          aria-live="polite"
          className="rounded-xl bg-red-50 p-4 text-sm text-red-800 md:col-span-2"
        >
          {state.error}
        </p>
      ) : null}

      <div className="md:col-span-2">
        <button
          className="inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:bg-indigo-400"
          disabled={isPending}
          type="submit"
        >
          {isPending ? "Creating session…" : "Create session"}
        </button>
      </div>
    </form>
  );
}
```

Create the event detail page.

### `src/app/(admin)/admin/events/[eventId]/page.tsx`

```tsx
import Link from "next/link";
import { notFound } from "next/navigation";
import { prisma } from "@/lib/prisma";
import { SessionForm } from "./session-form";

type EventDetailPageProps = {
  params: Promise<{
    eventId: string;
  }>;
};

export const metadata = {
  title: "Manage Event",
};

export default async function EventDetailPage({
  params,
}: EventDetailPageProps) {
  const { eventId } = await params;

  const event = await prisma.event.findUnique({
    where: {
      id: eventId,
    },
    include: {
      sessions: {
        include: {
          activeFormVersion: {
            select: {
              status: true,
              versionNumber: true,
            },
          },
          _count: {
            select: {
              responses: true,
            },
          },
        },
        orderBy: {
          createdAt: "desc",
        },
      },
    },
  });

  if (!event) {
    notFound();
  }

  return (
    <section>
      <Link
        className="text-sm font-semibold text-indigo-700 hover:text-indigo-900"
        href="/admin/events"
      >
        ← Back to events and courses
      </Link>

      <h1 className="mt-5 text-3xl font-bold tracking-tight text-slate-950">
        {event.title}
      </h1>

      <p className="mt-2 leading-7 text-slate-600">
        Add sessions for individual talks, modules, workshops, or end-of-course
        evaluations.
      </p>

      <section className="mt-8 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-xl font-bold text-slate-950">Create a session</h2>
        <p className="mt-2 text-sm leading-6 text-slate-600">
          Every session receives an independent QR URL and versioned feedback
          form.
        </p>

        <div className="mt-6">
          <SessionForm eventId={event.id} />
        </div>
      </section>

      <section className="mt-10">
        <h2 className="text-2xl font-bold tracking-tight text-slate-950">
          Sessions
        </h2>

        {event.sessions.length === 0 ? (
          <div className="mt-4 rounded-2xl border border-dashed border-slate-300 bg-white p-8 text-center text-slate-600">
            No sessions have been created yet.
          </div>
        ) : (
          <div className="mt-4 overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <ul className="divide-y divide-slate-200">
              {event.sessions.map((session) => (
                <li key={session.id}>
                  <Link
                    className="flex flex-col gap-3 p-5 transition hover:bg-slate-50 sm:flex-row sm:items-center sm:justify-between"
                    href={`/admin/sessions/${session.id}/edit`}
                  >
                    <div>
                      <h3 className="font-bold text-slate-950">
                        {session.title}
                      </h3>
                      <p className="mt-1 font-mono text-sm text-slate-500">
                        {session.id}
                      </p>
                    </div>

                    <div className="flex flex-wrap gap-2 text-sm">
                      <span
                        className={`rounded-full px-3 py-1 font-semibold ${
                          session.isActive
                            ? "bg-emerald-100 text-emerald-800"
                            : "bg-slate-200 text-slate-700"
                        }`}
                      >
                        {session.isActive ? "Active" : "Closed"}
                      </span>

                      <span className="rounded-full bg-indigo-100 px-3 py-1 font-semibold text-indigo-800">
                        {session.activeFormVersion
                          ? `Version ${session.activeFormVersion.versionNumber}`
                          : "No published form"}
                      </span>

                      <span className="rounded-full bg-slate-100 px-3 py-1 font-semibold text-slate-700">
                        {session._count.responses} responses
                      </span>
                    </div>
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>
    </section>
  );
}
```

### The Verification

1. Open one event, such as:

   ```text
   http://localhost:3000/admin/events
   ```

2. Open **TypeScript Foundations**.

3. Create this session:

   ```text
   Session title: Module 1 — Type Basics
   QR session ID: TYPESCRIPT-MODULE-1
   ```

4. You should be redirected to:

   ```text
   /admin/sessions/TYPESCRIPT-MODULE-1/edit
   ```

A 404 is expected until the next step creates the form editor.

---

## Step 3.6 — Create draft version, question, publishing, and ordering actions

### The Target

Create the server-side operations needed by the form authoring interface.

### The Concept

A form authoring screen needs safe operations, not direct database access from the browser.

The browser sends a request such as:

```text
Create draft version
Add question
Move question down
Publish this version
```

The server validates the request, runs the database operation, refreshes relevant pages, and returns the updated state.

Publishing is especially important. It must happen inside a database transaction so the following changes occur together:

1. Archive the old published form, if one exists.
2. Mark the new version as published.
3. Set it as the session’s active version.

### The Implementation

Create this file.

### `src/app/(admin)/admin/sessions/[sessionId]/edit/actions.ts`

```ts
"use server";

import {
  FormVersionStatus,
  Prisma,
  QuestionType,
} from "@prisma/client";
import { revalidatePath } from "next/cache";
import {
  getQuestionStorageValues,
  questionInputSchema,
} from "@/lib/authoring";
import { prisma } from "@/lib/prisma";

export type AuthoringActionState = {
  error?: string;
  success?: string;
};

function editorPath(sessionId: string): string {
  return `/admin/sessions/${sessionId}/edit`;
}

async function getOwnedFormVersion(sessionId: string, formVersionId: string) {
  return prisma.formVersion.findFirst({
    where: {
      id: formVersionId,
      sessionId,
    },
    select: {
      id: true,
      sessionId: true,
      status: true,
    },
  });
}

export async function createDraftVersionAction(
  sessionId: string,
): Promise<void> {
  const session = await prisma.session.findUnique({
    where: {
      id: sessionId,
    },
    include: {
      formVersions: {
        include: {
          questions: {
            orderBy: {
              orderIndex: "asc",
            },
          },
        },
        orderBy: {
          versionNumber: "desc",
        },
        take: 1,
      },
    },
  });

  if (!session) {
    throw new Error("Session not found.");
  }

  const newestVersion = session.formVersions[0];
  const nextVersionNumber = (newestVersion?.versionNumber ?? 0) + 1;

  await prisma.formVersion.create({
    data: {
      sessionId: session.id,
      versionNumber: nextVersionNumber,
      status: FormVersionStatus.DRAFT,
      questions: newestVersion
        ? {
            create: newestVersion.questions.map((question) => ({
              orderIndex: question.orderIndex,
              questionText: question.questionText,
              questionType: question.questionType,
              isRequired: question.isRequired,
              settings: question.settings,
              options: question.options,
            })),
          }
        : undefined,
    },
  });

  revalidatePath(editorPath(sessionId));
}

export async function addQuestionAction(
  sessionId: string,
  formVersionId: string,
  _previousState: AuthoringActionState,
  formData: FormData,
): Promise<AuthoringActionState> {
  const parsedInput = questionInputSchema.safeParse({
    questionText: formData.get("questionText"),
    questionType: formData.get("questionType"),
    isRequired: formData.get("isRequired") === "on",
    ratingMin: formData.get("ratingMin") ?? "1",
    ratingMax: formData.get("ratingMax") ?? "5",
    ratingMinLabel: formData.get("ratingMinLabel") ?? "",
    ratingMaxLabel: formData.get("ratingMaxLabel") ?? "",
    textMaxLength: formData.get("textMaxLength") ?? "1500",
    textPlaceholder: formData.get("textPlaceholder") ?? "",
    choiceOptions: formData.get("choiceOptions") ?? "",
  });

  if (!parsedInput.success) {
    return {
      error: parsedInput.error.issues[0]?.message ?? "Check the question fields.",
    };
  }

  const formVersion = await getOwnedFormVersion(sessionId, formVersionId);

  if (!formVersion) {
    return {
      error: "The selected form version does not exist.",
    };
  }

  if (formVersion.status !== FormVersionStatus.DRAFT) {
    return {
      error: "Only draft form versions can be edited.",
    };
  }

  const latestQuestion = await prisma.question.findFirst({
    where: {
      formVersionId,
    },
    orderBy: {
      orderIndex: "desc",
    },
    select: {
      orderIndex: true,
    },
  });

  const storageValues = getQuestionStorageValues(parsedInput.data);

  await prisma.question.create({
    data: {
      formVersionId,
      orderIndex: (latestQuestion?.orderIndex ?? 0) + 1,
      questionText: parsedInput.data.questionText,
      questionType: parsedInput.data.questionType,
      isRequired: parsedInput.data.isRequired,
      settings: storageValues.settings,
      options: storageValues.options,
    },
  });

  revalidatePath(editorPath(sessionId));

  return {
    success: "Question added to the draft.",
  };
}

export async function deleteQuestionAction(
  sessionId: string,
  formVersionId: string,
  questionId: string,
): Promise<void> {
  const formVersion = await getOwnedFormVersion(sessionId, formVersionId);

  if (!formVersion || formVersion.status !== FormVersionStatus.DRAFT) {
    throw new Error("Only questions in a draft form can be deleted.");
  }

  const question = await prisma.question.findFirst({
    where: {
      id: questionId,
      formVersionId,
    },
    select: {
      id: true,
      orderIndex: true,
    },
  });

  if (!question) {
    throw new Error("Question not found.");
  }

  await prisma.$transaction(async (transaction) => {
    await transaction.question.delete({
      where: {
        id: question.id,
      },
    });

    await transaction.question.updateMany({
      where: {
        formVersionId,
        orderIndex: {
          gt: question.orderIndex,
        },
      },
      data: {
        orderIndex: {
          decrement: 1,
        },
      },
    });
  });

  revalidatePath(editorPath(sessionId));
}

export async function moveQuestionAction(
  sessionId: string,
  formVersionId: string,
  questionId: string,
  direction: "up" | "down",
): Promise<void> {
  const formVersion = await getOwnedFormVersion(sessionId, formVersionId);

  if (!formVersion || formVersion.status !== FormVersionStatus.DRAFT) {
    throw new Error("Only questions in a draft form can be reordered.");
  }

  const question = await prisma.question.findFirst({
    where: {
      id: questionId,
      formVersionId,
    },
    select: {
      id: true,
      orderIndex: true,
    },
  });

  if (!question) {
    throw new Error("Question not found.");
  }

  const neighborOrder =
    direction === "up" ? question.orderIndex - 1 : question.orderIndex + 1;

  const neighbor = await prisma.question.findFirst({
    where: {
      formVersionId,
      orderIndex: neighborOrder,
    },
    select: {
      id: true,
      orderIndex: true,
    },
  });

  if (!neighbor) {
    return;
  }

  /**
   * PostgreSQL enforces unique(formVersionId, orderIndex). We temporarily
   * move the selected question to an impossible negative index, swap the
   * neighbor, then assign the selected question its final position.
   */
  await prisma.$transaction(async (transaction) => {
    await transaction.question.update({
      where: {
        id: question.id,
      },
      data: {
        orderIndex: -question.orderIndex,
      },
    });

    await transaction.question.update({
      where: {
        id: neighbor.id,
      },
      data: {
        orderIndex: question.orderIndex,
      },
    });

    await transaction.question.update({
      where: {
        id: question.id,
      },
      data: {
        orderIndex: neighbor.orderIndex,
      },
    });
  });

  revalidatePath(editorPath(sessionId));
}

export async function publishFormVersionAction(
  sessionId: string,
  formVersionId: string,
): Promise<void> {
  const formVersion = await prisma.formVersion.findFirst({
    where: {
      id: formVersionId,
      sessionId,
      status: FormVersionStatus.DRAFT,
    },
    include: {
      questions: {
        orderBy: {
          orderIndex: "asc",
        },
      },
    },
  });

  if (!formVersion) {
    throw new Error("Only a draft form version can be published.");
  }

  if (formVersion.questions.length === 0) {
    throw new Error("Add at least one question before publishing.");
  }

  const invalidChoiceQuestion = formVersion.questions.find(
    (question) =>
      question.questionType === QuestionType.CHOICE &&
      (!Array.isArray(question.options) || question.options.length < 2),
  );

  if (invalidChoiceQuestion) {
    throw new Error(
      "Every choice question must contain at least two configured options.",
    );
  }

  await prisma.$transaction(
    async (transaction) => {
      const currentlyPublished = await transaction.formVersion.findFirst({
        where: {
          sessionId,
          status: FormVersionStatus.PUBLISHED,
        },
        select: {
          id: true,
        },
      });

      if (currentlyPublished) {
        await transaction.formVersion.update({
          where: {
            id: currentlyPublished.id,
          },
          data: {
            status: FormVersionStatus.ARCHIVED,
          },
        });
      }

      await transaction.formVersion.update({
        where: {
          id: formVersion.id,
        },
        data: {
          status: FormVersionStatus.PUBLISHED,
          publishedAt: new Date(),
        },
      });

      await transaction.session.update({
        where: {
          id: sessionId,
        },
        data: {
          activeFormVersionId: formVersion.id,
          isActive: true,
        },
      });
    },
    {
      isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
    },
  );

  revalidatePath(editorPath(sessionId));
  revalidatePath(`/e/${sessionId}`);
  revalidatePath("/admin/events");
}

export async function setSessionActiveAction(
  sessionId: string,
  isActive: boolean,
): Promise<void> {
  await prisma.session.update({
    where: {
      id: sessionId,
    },
    data: {
      isActive,
    },
  });

  revalidatePath(editorPath(sessionId));
  revalidatePath(`/e/${sessionId}`);
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

Both commands should pass before we attach the actions to the interface.

---

## Step 3.7 — Build the form authoring interface

### The Target

Create the session editor page and reusable question authoring form.

### The Concept

The session editor presents the form lifecycle visually:

```text
No form yet
   ↓
Create draft
   ↓
Add/reorder questions
   ↓
Publish
   ↓
Participants can use the QR URL
   ↓
Create a new draft when changes are needed
```

Published forms are intentionally not editable. To make changes, an administrator creates a new draft version, which begins as a copy of the latest version.

### The Implementation

Create the question creation form.

### `src/app/(admin)/admin/sessions/[sessionId]/edit/question-form.tsx`

```tsx
"use client";

import { QuestionType } from "@prisma/client";
import { useActionState, useState } from "react";
import {
  addQuestionAction,
  type AuthoringActionState,
} from "./actions";

const initialState: AuthoringActionState = {};

export function QuestionForm({
  formVersionId,
  sessionId,
}: {
  formVersionId: string;
  sessionId: string;
}) {
  const action = addQuestionAction.bind(null, sessionId, formVersionId);

  const [state, formAction, isPending] = useActionState(
    action,
    initialState,
  );

  const [questionType, setQuestionType] = useState<QuestionType>(
    QuestionType.RATING,
  );

  return (
    <form action={formAction} className="space-y-5">
      <div>
        <label
          className="block text-sm font-semibold text-slate-800"
          htmlFor="questionText"
        >
          Question prompt
        </label>

        <textarea
          className="mt-2 min-h-28 w-full rounded-xl border border-slate-300 px-4 py-3 text-base shadow-sm focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
          id="questionText"
          maxLength={2000}
          name="questionText"
          placeholder="For example: How useful was this session?"
          required
          rows={4}
        />
      </div>

      <div>
        <label
          className="block text-sm font-semibold text-slate-800"
          htmlFor="questionType"
        >
          Question type
        </label>

        <select
          className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-base shadow-sm focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
          id="questionType"
          name="questionType"
          onChange={(event) =>
            setQuestionType(event.target.value as QuestionType)
          }
          value={questionType}
        >
          <option value={QuestionType.RATING}>Rating</option>
          <option value={QuestionType.NPS}>Recommendation score (NPS)</option>
          <option value={QuestionType.CHOICE}>Choice</option>
          <option value={QuestionType.TEXT}>Written response</option>
        </select>
      </div>

      <label className="flex min-h-12 items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-slate-800">
        <input name="isRequired" type="checkbox" />
        <span className="font-medium">Participants must answer this question</span>
      </label>

      {questionType === QuestionType.RATING ? (
        <fieldset className="rounded-xl border border-slate-200 p-4">
          <legend className="px-1 text-sm font-semibold text-slate-800">
            Rating scale
          </legend>

          <div className="mt-3 grid gap-4 sm:grid-cols-2">
            <label className="text-sm font-medium text-slate-700">
              Minimum score
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="1"
                max="10"
                min="1"
                name="ratingMin"
                type="number"
              />
            </label>

            <label className="text-sm font-medium text-slate-700">
              Maximum score
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="5"
                max="10"
                min="2"
                name="ratingMax"
                type="number"
              />
            </label>

            <label className="text-sm font-medium text-slate-700">
              Minimum label
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="Not useful"
                maxLength={100}
                name="ratingMinLabel"
              />
            </label>

            <label className="text-sm font-medium text-slate-700">
              Maximum label
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="Extremely useful"
                maxLength={100}
                name="ratingMaxLabel"
              />
            </label>
          </div>
        </fieldset>
      ) : null}

      {questionType === QuestionType.NPS ? (
        <fieldset className="rounded-xl border border-slate-200 p-4">
          <legend className="px-1 text-sm font-semibold text-slate-800">
            NPS labels
          </legend>

          <p className="mt-2 text-sm leading-6 text-slate-600">
            NPS always uses a score from 0 to 10.
          </p>

          <div className="mt-3 grid gap-4 sm:grid-cols-2">
            <label className="text-sm font-medium text-slate-700">
              Label for score 0
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="Not at all likely"
                maxLength={100}
                name="ratingMinLabel"
              />
            </label>

            <label className="text-sm font-medium text-slate-700">
              Label for score 10
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="Extremely likely"
                maxLength={100}
                name="ratingMaxLabel"
              />
            </label>
          </div>
        </fieldset>
      ) : null}

      {questionType === QuestionType.CHOICE ? (
        <div>
          <label
            className="block text-sm font-semibold text-slate-800"
            htmlFor="choiceOptions"
          >
            Choice options
          </label>

          <textarea
            className="mt-2 min-h-32 w-full rounded-xl border border-slate-300 px-4 py-3 text-base shadow-sm focus:border-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-200"
            id="choiceOptions"
            name="choiceOptions"
            placeholder={"One option per line\nFor example:\nHands-on exercises\nPresentation\nGroup discussion"}
            rows={6}
          />

          <p className="mt-2 text-sm text-slate-500">
            Enter one option per line. Choice questions require at least two
            options.
          </p>
        </div>
      ) : null}

      {questionType === QuestionType.TEXT ? (
        <fieldset className="rounded-xl border border-slate-200 p-4">
          <legend className="px-1 text-sm font-semibold text-slate-800">
            Written response settings
          </legend>

          <div className="mt-3 grid gap-4 sm:grid-cols-2">
            <label className="text-sm font-medium text-slate-700">
              Maximum characters
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                defaultValue="1500"
                max="5000"
                min="1"
                name="textMaxLength"
                type="number"
              />
            </label>

            <label className="text-sm font-medium text-slate-700">
              Placeholder text
              <input
                className="mt-2 min-h-12 w-full rounded-xl border border-slate-300 px-4 py-3 text-base"
                maxLength={250}
                name="textPlaceholder"
                placeholder="Share your thoughts"
              />
            </label>
          </div>
        </fieldset>
      ) : null}

      {state.error ? (
        <p
          aria-live="polite"
          className="rounded-xl bg-red-50 p-4 text-sm font-medium text-red-800"
        >
          {state.error}
        </p>
      ) : null}

      {state.success ? (
        <p
          aria-live="polite"
          className="rounded-xl bg-emerald-50 p-4 text-sm font-medium text-emerald-800"
        >
          {state.success}
        </p>
      ) : null}

      <button
        className="inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700 disabled:bg-indigo-400"
        disabled={isPending}
        type="submit"
      >
        {isPending ? "Adding question…" : "Add question"}
      </button>
    </form>
  );
}
```

Create the editor page.

### `src/app/(admin)/admin/sessions/[sessionId]/edit/page.tsx`

```tsx
import Link from "next/link";
import { FormVersionStatus, QuestionType } from "@prisma/client";
import { notFound } from "next/navigation";
import {
  createDraftVersionAction,
  deleteQuestionAction,
  moveQuestionAction,
  publishFormVersionAction,
  setSessionActiveAction,
} from "./actions";
import { QuestionForm } from "./question-form";
import { prisma } from "@/lib/prisma";

type SessionEditorPageProps = {
  params: Promise<{
    sessionId: string;
  }>;
};

function questionTypeLabel(questionType: QuestionType): string {
  switch (questionType) {
    case QuestionType.RATING:
      return "Rating";
    case QuestionType.NPS:
      return "NPS";
    case QuestionType.CHOICE:
      return "Choice";
    case QuestionType.TEXT:
      return "Written response";
  }
}

export const metadata = {
  title: "Edit Feedback Form",
};

export default async function SessionEditorPage({
  params,
}: SessionEditorPageProps) {
  const { sessionId } = await params;

  const session = await prisma.session.findUnique({
    where: {
      id: sessionId,
    },
    include: {
      event: {
        select: {
          id: true,
          title: true,
        },
      },
      activeFormVersion: {
        select: {
          id: true,
          versionNumber: true,
        },
      },
      formVersions: {
        include: {
          questions: {
            orderBy: {
              orderIndex: "asc",
            },
          },
        },
        orderBy: {
          versionNumber: "desc",
        },
      },
      _count: {
        select: {
          responses: true,
        },
      },
    },
  });

  if (!session) {
    notFound();
  }

  const draftVersion = session.formVersions.find(
    (version) => version.status === FormVersionStatus.DRAFT,
  );

  const publishedVersions = session.formVersions.filter(
    (version) => version.status === FormVersionStatus.PUBLISHED,
  );

  const participantUrl = `${process.env.NEXT_PUBLIC_APP_URL}/e/${session.id}?src=qr`;

  return (
    <section>
      <Link
        className="text-sm font-semibold text-indigo-700 hover:text-indigo-900"
        href={`/admin/events/${session.event.id}`}
      >
        ← Back to {session.event.title}
      </Link>

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

        <form
          action={setSessionActiveAction.bind(null, session.id, !session.isActive)}
        >
          <button
            className={`inline-flex min-h-12 items-center justify-center rounded-xl px-5 py-3 font-semibold transition ${
              session.isActive
                ? "bg-slate-800 text-white hover:bg-slate-950"
                : "bg-emerald-600 text-white hover:bg-emerald-700"
            }`}
            type="submit"
          >
            {session.isActive ? "Close feedback session" : "Reopen feedback session"}
          </button>
        </form>
      </div>

      <div className="mt-8 grid gap-4 md:grid-cols-3">
        <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm font-semibold text-slate-500">Session status</p>
          <p className="mt-2 text-xl font-bold text-slate-950">
            {session.isActive ? "Active" : "Closed"}
          </p>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm font-semibold text-slate-500">Responses</p>
          <p className="mt-2 text-xl font-bold text-slate-950">
            {session._count.responses}
          </p>
        </article>

        <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm font-semibold text-slate-500">
            Active published form
          </p>
          <p className="mt-2 text-xl font-bold text-slate-950">
            {session.activeFormVersion
              ? `Version ${session.activeFormVersion.versionNumber}`
              : "None"}
          </p>
        </article>
      </div>

      <section className="mt-8 rounded-2xl border border-indigo-200 bg-indigo-50 p-5 sm:p-6">
        <h2 className="text-lg font-bold text-indigo-950">Participant QR URL</h2>
        <p className="mt-2 text-sm leading-6 text-indigo-900">
          QR-code generation is added in Part 7. This is the stable URL that
          the future QR code will encode.
        </p>

        <code className="mt-4 block overflow-x-auto rounded-xl bg-white p-4 text-sm text-slate-800">
          {participantUrl}
        </code>

        {session.activeFormVersion && session.isActive ? (
          <Link
            className="mt-4 inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700"
            href={`/e/${session.id}?src=admin-preview`}
            target="_blank"
          >
            Open participant preview
          </Link>
        ) : null}
      </section>

      {draftVersion ? (
        <section className="mt-10 grid gap-8 xl:grid-cols-[1.1fr_0.9fr]">
          <div>
            <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <h2 className="text-2xl font-bold tracking-tight text-slate-950">
                  Draft form version {draftVersion.versionNumber}
                </h2>
                <p className="mt-2 leading-7 text-slate-600">
                  Add and reorder questions. This draft is not visible to
                  participants until you publish it.
                </p>
              </div>

              <form
                action={publishFormVersionAction.bind(
                  null,
                  session.id,
                  draftVersion.id,
                )}
              >
                <button
                  className="inline-flex min-h-12 items-center justify-center rounded-xl bg-emerald-600 px-5 py-3 font-semibold text-white transition hover:bg-emerald-700"
                  type="submit"
                >
                  Publish version {draftVersion.versionNumber}
                </button>
              </form>
            </div>

            {draftVersion.questions.length === 0 ? (
              <div className="mt-6 rounded-2xl border border-dashed border-slate-300 bg-white p-8 text-center text-slate-600">
                This draft has no questions yet. Add the first question using
                the form on the right.
              </div>
            ) : (
              <ol className="mt-6 space-y-4">
                {draftVersion.questions.map((question, index) => (
                  <li
                    className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
                    key={question.id}
                  >
                    <div className="flex flex-col justify-between gap-4 sm:flex-row">
                      <div>
                        <div className="flex flex-wrap gap-2">
                          <span className="rounded-full bg-indigo-100 px-3 py-1 text-xs font-bold text-indigo-800">
                            Question {question.orderIndex}
                          </span>

                          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-700">
                            {questionTypeLabel(question.questionType)}
                          </span>

                          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-bold text-slate-700">
                            {question.isRequired ? "Required" : "Optional"}
                          </span>
                        </div>

                        <h3 className="mt-3 font-semibold leading-7 text-slate-950">
                          {question.questionText}
                        </h3>

                        {question.questionType === QuestionType.CHOICE ? (
                          <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-slate-600">
                            {Array.isArray(question.options)
                              ? question.options.map((option) => (
                                  <li key={String(option)}>{String(option)}</li>
                                ))
                              : null}
                          </ul>
                        ) : null}
                      </div>

                      <div className="flex flex-wrap gap-2">
                        <form
                          action={moveQuestionAction.bind(
                            null,
                            session.id,
                            draftVersion.id,
                            question.id,
                            "up",
                          )}
                        >
                          <button
                            aria-label={`Move question ${question.orderIndex} up`}
                            className="min-h-12 rounded-xl border border-slate-300 px-4 py-3 text-sm font-semibold text-slate-700 disabled:cursor-not-allowed disabled:opacity-40"
                            disabled={index === 0}
                            type="submit"
                          >
                            ↑
                          </button>
                        </form>

                        <form
                          action={moveQuestionAction.bind(
                            null,
                            session.id,
                            draftVersion.id,
                            question.id,
                            "down",
                          )}
                        >
                          <button
                            aria-label={`Move question ${question.orderIndex} down`}
                            className="min-h-12 rounded-xl border border-slate-300 px-4 py-3 text-sm font-semibold text-slate-700 disabled:cursor-not-allowed disabled:opacity-40"
                            disabled={index === draftVersion.questions.length - 1}
                            type="submit"
                          >
                            ↓
                          </button>
                        </form>

                        <form
                          action={deleteQuestionAction.bind(
                            null,
                            session.id,
                            draftVersion.id,
                            question.id,
                          )}
                        >
                          <button
                            className="min-h-12 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700 transition hover:bg-red-100"
                            type="submit"
                          >
                            Delete
                          </button>
                        </form>
                      </div>
                    </div>
                  </li>
                ))}
              </ol>
            )}
          </div>

          <aside className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <h2 className="text-xl font-bold text-slate-950">Add a question</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">
              Choose the question type first. The editor will show only the
              relevant configuration options.
            </p>

            <div className="mt-6">
              <QuestionForm
                formVersionId={draftVersion.id}
                sessionId={session.id}
              />
            </div>
          </aside>
        </section>
      ) : (
        <section className="mt-10 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-2xl font-bold tracking-tight text-slate-950">
            Create a draft form
          </h2>

          <p className="mt-3 max-w-2xl leading-7 text-slate-600">
            {session.formVersions.length === 0
              ? "This session does not have a form yet. Create a draft, add questions, then publish it when it is ready."
              : "Create a new draft version to safely revise the current form. The latest form is copied into the draft so historical reporting remains protected."}
          </p>

          <form action={createDraftVersionAction.bind(null, session.id)}>
            <button
              className="mt-6 inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-5 py-3 font-semibold text-white transition hover:bg-indigo-700"
              type="submit"
            >
              Create draft form version
            </button>
          </form>
        </section>
      )}

      {publishedVersions.length > 0 ? (
        <section className="mt-10">
          <h2 className="text-xl font-bold text-slate-950">
            Published form history
          </h2>

          <div className="mt-4 space-y-3">
            {publishedVersions.map((version) => (
              <article
                className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
                key={version.id}
              >
                <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                  <div>
                    <h3 className="font-bold text-slate-950">
                      Version {version.versionNumber}
                    </h3>
                    <p className="mt-1 text-sm text-slate-600">
                      Published{" "}
                      {version.publishedAt
                        ? version.publishedAt.toLocaleString()
                        : "at an unknown time"}
                      {" · "}
                      {version.questions.length} questions
                    </p>
                  </div>

                  {session.activeFormVersion?.id === version.id ? (
                    <span className="w-fit rounded-full bg-emerald-100 px-3 py-1 text-sm font-bold text-emerald-800">
                      Active
                    </span>
                  ) : null}
                </div>
              </article>
            ))}
          </div>
        </section>
      ) : null}
    </section>
  );
}
```

### The Verification

Open the new session editor:

```text
http://localhost:3000/admin/sessions/TYPESCRIPT-MODULE-1/edit
```

Then complete this workflow.

1. Click:

   ```text
   Create draft form version
   ```

2. Add this rating question:

   ```text
   Prompt: How clear was the TypeScript basics module?
   Type: Rating
   Required: checked
   Minimum: 1
   Maximum: 5
   Minimum label: Not clear
   Maximum label: Extremely clear
   ```

3. Add this NPS question:

   ```text
   Prompt: How likely are you to recommend this module to a colleague?
   Type: Recommendation score (NPS)
   Required: checked
   ```

4. Add this choice question:

   ```text
   Prompt: Which topic needs more explanation?
   Type: Choice
   Required: unchecked

   Options:
   Type annotations
   Interfaces
   Unions
   Generics
   ```

5. Add this text question:

   ```text
   Prompt: What was the most useful part of this module?
   Type: Written response
   Required: unchecked
   Maximum characters: 1500
   ```

6. Use the up and down buttons to verify that ordering works.

7. Click:

   ```text
   Publish version 1
   ```

8. Confirm that:
   - The draft editor disappears.
   - The session now shows `Active published form: Version 1`.
   - The participant preview button becomes available.

9. Click **Open participant preview**.

You should see the form at:

```text
http://localhost:3000/e/TYPESCRIPT-MODULE-1?src=admin-preview
```

The participant page should render your four custom questions from Neon.

---

## Step 3.8 — Verify safe form versioning

### The Target

Confirm that publishing a new form version preserves the existing published version.

### The Concept

Forms should evolve safely.

For example, after one course module ends, an organizer may want to add a question for the next cohort. They should not edit the form that existing responses already use.

Instead:

```text
Version 1 — published and historically protected
Version 2 — editable draft copied from version 1
Version 2 — published when ready
Version 1 — archived automatically
```

### The Implementation

On the editor page for `TYPESCRIPT-MODULE-1`:

1. Click:

   ```text
   Create draft form version
   ```

2. Verify that the draft contains copies of the four questions from Version 1.

3. Add one new question:

   ```text
   Prompt: Would you like more hands-on coding exercises?
   Type: Choice

   Options:
   Yes
   No
   ```

4. Publish the draft.

### The Verification

After publishing, confirm:

- The active published version is now Version 2.
- The participant preview displays the new question.
- The Published form history section lists Version 2.
- Version 1 is no longer the active published version.

To confirm the archived state, open Prisma Studio:

```bash
npx prisma studio
```

In `FormVersion`, locate the session’s versions. You should find:

```text
Version 1: ARCHIVED
Version 2: PUBLISHED
```

This is the critical historical-safety behavior that prevents future authoring changes from corrupting past reports.

---

## Step 3.9 — Run the complete Part 3 verification

### The Target

Confirm that authentication, authoring, form publishing, and participant rendering all work together.

### The Concept

A complete check proves the full workflow works as a connected system:

```text
Sign in
→ Create event
→ Create session
→ Create draft
→ Add questions
→ Publish
→ Open participant URL
```

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

### The Verification

All commands should complete successfully.

Then test this browser workflow:

1. Open:

   ```text
   http://localhost:3000/admin/login
   ```

2. Sign in.

3. Create an event or course.

4. Create a session with a unique session ID.

5. Create a draft form.

6. Add at least one question.

7. Publish the form.

8. Open:

   ```text
   http://localhost:3000/e/YOUR-SESSION-ID
   ```

9. Confirm the participant page shows the published form.

10. Sign out and attempt to open:

   ```text
   http://localhost:3000/admin/events
   ```

11. Confirm you are redirected to:

   ```text
   /admin/login
   ```

---

## Part 3 Reference: Files Added

```text
src/
├── app/
│   ├── admin/
│   │   └── login/
│   │       ├── actions.ts
│   │       ├── login-form.tsx
│   │       └── page.tsx
│   │
│   └── (admin)/
│       └── admin/
│           ├── actions.ts
│           ├── layout.tsx
│           ├── events/
│           │   ├── actions.ts
│           │   ├── page.tsx
│           │   ├── new/
│           │   │   ├── event-form.tsx
│           │   │   └── page.tsx
│           │   └── [eventId]/
│           │       ├── actions.ts
│           │       ├── page.tsx
│           │       └── session-form.tsx
│           │
│           └── sessions/
│               └── [sessionId]/
│                   └── edit/
│                       ├── actions.ts
│                       ├── page.tsx
│                       └── question-form.tsx
│
└── lib/
    ├── admin-auth.ts
    └── authoring.ts
```

GreyMatter Feedback now has a protected form authoring environment backed by Neon and Prisma.

Administrators can create different feedback forms for every event, course, or session, while versioning ensures that published forms remain historically trustworthy.
