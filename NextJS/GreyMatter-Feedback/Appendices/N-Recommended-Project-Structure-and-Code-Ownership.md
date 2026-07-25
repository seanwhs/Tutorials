# Appendix N: Recommended Project Structure and Code Ownership

As GreyMatter Feedback grows, a clear project structure makes the application easier to understand, test, and extend.

A good structure answers these questions quickly:

```text
Where does participant code live?
Where does admin code live?
Where are database queries?
Where are security helpers?
Where are Inngest functions?
Where are reusable types?
Where should a new feature be added?
```

This appendix documents the recommended structure for the completed GreyMatter Feedback application and explains the responsibility of each area.

---

## N.1 High-level project structure

A mature GreyMatter Feedback project should resemble this:

```text
greymatter-feedback/
├── .env
├── .env.example
├── .gitignore
├── next.config.ts
├── package.json
├── prisma/
│   ├── migrations/
│   ├── schema.prisma
│   └── seed.ts
├── public/
│   ├── icons/
│   ├── reports/
│   └── sw.js
├── scripts/
│   └── test-database.ts
├── src/
│   ├── app/
│   ├── components/
│   ├── inngest/
│   ├── lib/
│   └── types/
└── tsconfig.json
```

The main principle is:

```text
Routes live in app/
Reusable UI lives in components/
Business and infrastructure logic lives in lib/
Background jobs live in inngest/
Database schema and migrations live in prisma/
Shared TypeScript types live in types/
```

---

## N.2 Application routes

The `src/app` directory uses the Next.js App Router.

```text
src/app/
├── page.tsx
├── layout.tsx
├── globals.css
├── e/
├── admin/
├── (admin)/
└── api/
```

### Public landing page

```text
src/app/page.tsx
```

Route:

```text
/
```

Responsibility:

```text
Explain GreyMatter Feedback.
Provide a link to administrator sign-in.
Provide product-level navigation.
```

---

## N.3 Participant routes

Participant routes belong under:

```text
src/app/e/
```

Example:

```text
src/app/e/
└── [sessionId]/
    ├── page.tsx
    └── not-found.tsx
```

Routes:

```text
/e/REACT-2026-Q3
/e/TYPESCRIPT-MODULE-1
/e/LEADERSHIP-WEEK-2
```

Responsibilities:

```text
Load active published session form.
Display inactive or unavailable states.
Pass safe form configuration to participant client components.
Never expose admin-only data.
Never expose database credentials.
```

Participant routes should not import:

```text
Admin dashboard components
CSV export logic
PDF generation logic
Administrator authentication actions
Raw response records
```

---

## N.4 Administrator routes

The application separates public login from protected administrator routes.

```text
src/app/
├── admin/
│   └── login/
│       ├── actions.ts
│       ├── login-form.tsx
│       └── page.tsx
│
└── (admin)/
    └── admin/
        ├── actions.ts
        ├── layout.tsx
        ├── events/
        └── sessions/
```

The route group:

```text
(admin)
```

does not appear in URLs. It is an organizational folder.

For example:

```text
src/app/(admin)/admin/events/page.tsx
```

becomes:

```text
/admin/events
```

The protected admin layout is responsible for:

```text
Checking authentication.
Rendering shared navigation.
Displaying the sign-out action.
Providing consistent admin page layout.
```

---

## N.5 Event and course authoring routes

Recommended structure:

```text
src/app/(admin)/admin/events/
├── actions.ts
├── page.tsx
├── new/
│   ├── event-form.tsx
│   └── page.tsx
└── [eventId]/
    ├── actions.ts
    ├── page.tsx
    └── session-form.tsx
```

Responsibilities:

| File area | Responsibility |
|---|---|
| `events/page.tsx` | List events and courses |
| `events/new/page.tsx` | Create new event or course |
| `events/actions.ts` | Server action for event creation |
| `events/[eventId]/page.tsx` | List sessions under one event |
| `events/[eventId]/actions.ts` | Server action for session creation |
| `session-form.tsx` | Client form for creating a session |

This separation keeps database writes in server actions and interactive browser behavior in Client Components.

---

## N.6 Form authoring routes

Recommended structure:

```text
src/app/(admin)/admin/sessions/
└── [sessionId]/
    └── edit/
        ├── actions.ts
        ├── page.tsx
        └── question-form.tsx
```

Responsibilities:

```text
actions.ts
├── Create draft versions
├── Clone previous versions
├── Add questions
├── Delete questions
├── Reorder questions
├── Publish form versions
└── Open or close sessions

page.tsx
├── Display session details
├── Display draft questions
├── Display published form history
├── Show participant URL
└── Link to dashboard

question-form.tsx
├── Select question type
├── Configure question settings
├── Configure choice options
└── Send authoring data through server action
```

Avoid putting Prisma database code directly inside `question-form.tsx`. It runs in the browser.

The browser component should call a server action. The server action performs validation and writes to Neon.

---

## N.7 Analytics routes

Recommended structure:

```text
src/app/(admin)/admin/sessions/
└── [sessionId]/
    └── page.tsx
```

Route:

```text
/admin/sessions/REACT-2026-Q3
```

Responsibilities:

```text
Load analytics.
Render total response metrics.
Render ratings and NPS distributions.
Render written feedback safely.
Show QR-code tool.
Link to CSV export.
Show PDF report request panel.
```

This page should remain server-rendered where possible.

Client components should be limited to browser-only features such as:

```text
Automatic refresh.
QR image generation.
Report status polling.
Clipboard access.
File downloads.
```

---

## N.8 API routes

API routes belong under:

```text
src/app/api/
```

Recommended structure:

```text
src/app/api/
├── feedback/
│   └── route.ts
├── inngest/
│   └── route.ts
└── admin/
    ├── export/
    │   └── [sessionId]/
    │       └── route.ts
    └── reports/
        └── [sessionId]/
            └── route.ts
```

### API route responsibilities

| Route | Responsibility |
|---|---|
| `/api/feedback` | Public participant submission validation and event dispatch |
| `/api/inngest` | Inngest function discovery and invocation |
| `/api/admin/export/[sessionId]` | Protected CSV export |
| `/api/admin/reports/[sessionId]` | Protected report history and report queueing |

A route handler should be small and focused:

```text
Parse request
Validate request
Authorize request if needed
Call business logic helper
Return HTTP response
```

Avoid putting large analytics calculations, PDF rendering, or complex database workflows directly in route handlers.

---

## N.9 Reusable components

Reusable components belong under:

```text
src/components/
```

Suggested structure:

```text
src/components/
├── admin/
│   ├── analytics-auto-refresh.tsx
│   ├── distribution-bar.tsx
│   ├── metric-card.tsx
│   ├── qr-code-card.tsx
│   ├── report-panel.tsx
│   └── session-report-document.tsx
├── participant/
│   ├── feedback-form.tsx
│   ├── question-input.tsx
│   ├── question-preview.tsx
│   └── session-unavailable.tsx
├── ui/
│   └── future shared generic controls
└── service-worker-registration.tsx
```

### Component ownership rules

Participant components should contain:

```text
Form controls
Local draft behavior
Mobile interactions
Accessibility behavior
Submission UI states
```

Admin components should contain:

```text
Analytics presentation
QR-code generation
Report controls
Dashboard refresh behavior
```

Generic UI components should contain:

```text
Buttons
Cards
Dialogs
Badges
Form field wrappers
Loading states
```

Do not make generic UI components depend on Prisma, Inngest, or session-specific business logic.

---

## N.10 The `lib` directory

The `src/lib` directory contains reusable business logic, server helpers, validation, and infrastructure integrations.

Suggested structure:

```text
src/lib/
├── admin-auth.ts
├── analytics-math.ts
├── authoring.ts
├── client-identity.ts
├── csv.ts
├── env.ts
├── evaluate-visibility.ts
├── feedback-submission.ts
├── generate-session-report.tsx
├── participant-draft.ts
├── participant-session.ts
├── prisma.ts
├── rate-limit.ts
├── report-formatting.ts
├── report-storage.ts
├── save-feedback-response.ts
├── session-analytics.ts
├── submission-outbox.ts
├── validate-feedback.ts
└── visibility-rules.ts
```

### Server-only modules

Files that use secrets, Prisma, Node.js APIs, or private infrastructure should begin with:

```ts
import "server-only";
```

Examples:

```text
admin-auth.ts
client-identity.ts
prisma.ts
rate-limit.ts
report-storage.ts
save-feedback-response.ts
session-analytics.ts
validate-feedback.ts
```

This prevents accidental imports into browser Client Components.

### Browser-only modules

Files that use browser APIs should begin with:

```ts
"use client";
```

Examples:

```text
participant-draft.ts
submission-outbox.ts
```

These files may safely use:

```text
window
localStorage
navigator
crypto.randomUUID()
```

They must not import:

```text
Prisma
Node crypto APIs
Server environment values
Database connection helpers
```

---

## N.11 Shared type definitions

Use:

```text
src/types/
```

for serializable shared types that both server and client code need.

Example:

```text
src/types/forms.ts
```

Responsibilities:

```text
Question setting schemas.
Participant-safe question types.
Question type labels.
Choice option parsing.
```

A participant-safe type should include only fields required by the browser.

Example:

```ts
export type ParticipantQuestion = {
  id: string;
  orderIndex: number;
  questionText: string;
  questionType: QuestionType;
  isRequired: boolean;
  settings: QuestionSettings;
  options: string[];
};
```

It should not include:

```text
Raw database metadata
Answer records
IP hashes
Administrator-only flags
Internal audit values
```

---

## N.12 Inngest directory structure

Keep background processing separate from page and API route code.

```text
src/inngest/
├── client.ts
└── functions/
    ├── generate-pdf-report.ts
    ├── index.ts
    └── process-feedback-submission.ts
```

Responsibilities:

```text
client.ts
├── Defines Inngest client
├── Defines event contracts
└── Connects event names to TypeScript types

functions/process-feedback-submission.ts
├── Listens for feedback/submitted
├── Uses step.run()
└── Saves response safely

functions/generate-pdf-report.ts
├── Listens for report/generate.pdf
├── Generates report
├── Stores report
└── Updates report status

functions/index.ts
└── Exports all registered functions
```

Do not place Inngest functions directly inside API route files.

That would mix responsibilities and make function discovery harder to manage.

---

## N.13 Prisma directory structure

The `prisma` directory is the database source of truth.

```text
prisma/
├── migrations/
│   ├── 20260725103000_initial_schema/
│   │   └── migration.sql
│   └── 20260726120000_add_question_helper_text/
│       └── migration.sql
├── schema.prisma
└── seed.ts
```

Responsibilities:

| File area | Responsibility |
|---|---|
| `schema.prisma` | Prisma models, enums, relations, indexes |
| `migrations/` | Historical database changes |
| `seed.ts` | Development sample data |

Do not edit an already-applied migration in a shared or production environment.

Create a new migration instead.

---

## N.14 Scripts directory

Use:

```text
scripts/
```

for command-line tools that do not belong in the running Next.js app.

Examples:

```text
scripts/
├── test-database.ts
├── import-sessions.ts
├── backfill-reporting-tags.ts
└── cleanup-old-metadata.ts
```

A script should:

```text
Read configuration safely.
Perform one focused task.
Log safe operational results.
Return nonzero exit code on failure.
Disconnect Prisma when complete.
```

Example script structure:

```ts
import { prisma } from "../src/lib/prisma";

async function main() {
  // Perform focused maintenance work.
}

main()
  .catch((error: unknown) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Do not use scripts to bypass normal production safety controls without review.

---

## N.15 Suggested feature-based refactor for larger codebases

As the application grows, route-based organization can become difficult to navigate.

A future feature-based structure can supplement the existing layout:

```text
src/features/
├── analytics/
│   ├── analytics-service.ts
│   ├── analytics-types.ts
│   └── analytics-math.ts
├── authoring/
│   ├── authoring-service.ts
│   ├── authoring-validation.ts
│   └── publishing-service.ts
├── feedback/
│   ├── feedback-validation.ts
│   ├── feedback-service.ts
│   └── feedback-types.ts
├── reports/
│   ├── report-service.ts
│   ├── report-storage.ts
│   └── report-document.tsx
└── sessions/
    ├── participant-session-service.ts
    └── session-types.ts
```

The `app/` directory would still define routes, but route files would call feature services.

Example:

```tsx
import { getSessionAnalytics } from "@/features/analytics/analytics-service";
```

This approach becomes useful when:

```text
Multiple developers work on the project.
Features gain several files.
Business rules are shared by routes, APIs, jobs, and scripts.
Tests need focused module boundaries.
```

Do not refactor only for appearance. Refactor when the current structure makes changes difficult or error-prone.

---

## N.16 Dependency direction

Keep dependencies flowing in one predictable direction.

Recommended direction:

```text
Routes and components
        ↓
Feature services or lib helpers
        ↓
Infrastructure adapters
        ↓
Prisma / Inngest / storage providers
```

Example:

```text
Admin dashboard page
        ↓
getSessionAnalytics()
        ↓
prisma
        ↓
Neon PostgreSQL
```

Avoid reverse dependencies such as:

```text
Prisma helper
        ↓
Imports React component
```

or:

```text
Server-side Inngest worker
        ↓
Imports browser localStorage module
```

Those dependencies blur server and browser boundaries and make testing harder.

---

## N.17 File naming conventions

Use clear file names.

Recommended conventions:

| Type | Convention | Example |
|---|---|---|
| React component | kebab-case | `feedback-form.tsx` |
| Route page | Next.js reserved name | `page.tsx` |
| Route layout | Next.js reserved name | `layout.tsx` |
| Route handler | Next.js reserved name | `route.ts` |
| Server action | `actions.ts` | `events/actions.ts` |
| Pure utility | descriptive kebab-case | `analytics-math.ts` |
| Prisma model | PascalCase in schema | `FormVersion` |
| Database table | snake_case through `@@map` | `form_versions` |
| Environment variable | UPPER_SNAKE_CASE | `DATABASE_URL` |

Good names describe intent:

```text
save-feedback-response.ts
validate-feedback.ts
generate-pdf-report.ts
participant-session.ts
```

Avoid vague names:

```text
utils.ts
helpers.ts
common.ts
data.ts
misc.ts
```

A file can be named `utils.ts` temporarily, but it tends to become an unstructured dumping ground.

---

## N.18 Code ownership checklist

When adding code, place it according to this guide.

| You are adding… | Put it in… |
|---|---|
| New public page | `src/app/` |
| New protected admin page | `src/app/(admin)/admin/` |
| New participant input control | `src/components/participant/` |
| New admin dashboard component | `src/components/admin/` |
| New generic card or button | `src/components/ui/` |
| New public API route | `src/app/api/` |
| New Inngest function | `src/inngest/functions/` |
| New Prisma query helper | `src/lib/` or `src/features/` |
| New database table | `prisma/schema.prisma` |
| New schema migration | `prisma/migrations/` |
| New development fixture | `prisma/seed.ts` |
| New command-line maintenance tool | `scripts/` |
| Shared browser/server serializable types | `src/types/` |
| Browser storage helper | Client-marked module in `src/lib/` |

---

## N.19 Final project organization checklist

```text
[ ] Public participant code is separate from administrator code.
[ ] Server-only modules cannot be imported into browser code.
[ ] Browser-only modules do not import database or server libraries.
[ ] API routes are thin and delegate business logic.
[ ] Inngest functions are separate from API routes.
[ ] Prisma schema and migrations are committed to Git.
[ ] Shared form types are safe for participant browsers.
[ ] Generated reports are ignored locally and stored safely in production.
[ ] Environment secrets are excluded from Git.
[ ] File names describe clear responsibilities.
[ ] New features have an obvious home in the project.
```

A clean project structure does not replace good engineering, but it makes good engineering easier to maintain. As GreyMatter Feedback expands, clear ownership boundaries help keep participant experiences fast, admin workflows understandable, and background processing reliable.
