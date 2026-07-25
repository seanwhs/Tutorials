# Primer 3: Neon PostgreSQL, Prisma, and the GreyMatter Feedback Data Model

GreyMatter Feedback needs to remember information long after a browser tab closes.

It must store:

- Events and courses.
- Sessions.
- Published and draft forms.
- Questions.
- Participant responses.
- Individual answers.
- Generated report records.

This primer explains how **Neon PostgreSQL** and **Prisma** work together to store that information safely.

---

## 1. What Is a Database?

A database is an organized system for storing information.

Think of it as a filing system:

```text
Event folder
  └── Session folder
        └── Form version folder
              └── Question documents

Response folder
  └── Individual answer documents
```

Without a database, GreyMatter Feedback would lose everything whenever the server restarts.

A database lets the application answer questions such as:

```text
Which form should this QR code display?
How many people responded to a session?
What was the average rating?
Which NPS scores were submitted?
What written feedback did participants provide?
Which PDF reports were generated?
```

---

## 2. Why PostgreSQL?

GreyMatter Feedback uses **PostgreSQL**, a relational database.

A relational database stores information in connected tables.

For example:

```text
events
sessions
form_versions
questions
responses
answers
reports
```

The word **relational** means records can be connected.

For example:

```text
One event
  has many sessions

One session
  has many form versions

One form version
  has many questions

One response
  has many answers
```

Those relationships let the application keep data organized and prevent invalid combinations.

---

## 3. Why Neon?

**Neon** is a managed serverless PostgreSQL provider.

Instead of installing PostgreSQL on a local server and maintaining it yourself, Neon provides hosted PostgreSQL.

Neon handles infrastructure responsibilities such as:

```text
Database server operation
SSL database connections
Storage management
Managed backups and recovery capabilities
Database branching
Serverless-friendly connection pooling
```

GreyMatter Feedback uses Neon because it is compatible with PostgreSQL and works well with Next.js deployment environments.

---

## 4. Pooled and Direct Database Connections

Neon commonly provides two connection URLs.

```text
DATABASE_URL
DIRECT_URL
```

They have different jobs.

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Application requests through the Neon connection pooler |
| `DIRECT_URL` | Prisma migrations and direct database management |

### Pooled application connection

A pooled URL often contains:

```text
-pooler
```

Example shape:

```text
postgresql://user:password@ep-example-pooler.us-east-2.aws.neon.tech/greymatter?sslmode=require
```

The pooler helps manage many short-lived serverless connections efficiently.

### Direct migration connection

A direct URL usually does not contain `-pooler`:

```text
postgresql://user:password@ep-example.us-east-2.aws.neon.tech/greymatter?sslmode=require
```

Prisma uses the direct connection for migrations because schema changes need more direct database control.

---

## 5. What Prisma Does

**Prisma** is a toolkit that sits between TypeScript code and PostgreSQL.

Without Prisma, code often sends raw SQL:

```sql
SELECT * FROM sessions WHERE id = 'REACT-2026-Q3';
```

With Prisma, GreyMatter Feedback uses typed TypeScript:

```ts
const session = await prisma.session.findUnique({
  where: {
    id: "REACT-2026-Q3",
  },
});
```

Prisma provides:

```text
Schema modeling
Migration generation
Type-safe query methods
Relationship support
Development database tools
```

A useful analogy:

```text
PostgreSQL
  = the records room

Prisma
  = the trained records clerk

TypeScript application
  = the staff requesting information
```

---

## 6. Prisma Schema Basics

The Prisma schema lives here:

```text
prisma/schema.prisma
```

It defines:

```text
Database models
Fields
Field types
Relationships
Indexes
Enums
Table names
Column names
```

A simple model looks like this:

```prisma
model Event {
  id        String   @id @default(uuid()) @db.Uuid
  title     String   @db.VarChar(255)
  createdAt DateTime @default(now()) @map("created_at")

  sessions  Session[]

  @@map("events")
}
```

This means:

| Schema line | Meaning |
|---|---|
| `model Event` | Define an Event model |
| `id` | Unique primary identifier |
| `@default(uuid())` | Automatically generate UUID value |
| `title` | Event name |
| `createdAt` | Creation timestamp |
| `sessions Session[]` | One event can have many sessions |
| `@@map("events")` | PostgreSQL table is named `events` |

---

## 7. UUIDs

GreyMatter Feedback uses UUIDs for most internal database IDs.

A UUID looks like:

```text
6b9f6b86-8fc0-4e54-b064-2b60b848ac31
```

UUID stands for **Universally Unique Identifier**.

UUIDs are useful because they are difficult to guess and can be generated independently.

GreyMatter Feedback uses UUIDs for:

```text
Event IDs
Form version IDs
Question IDs
Response IDs
Answer IDs
Report IDs
```

However, session IDs are intentionally readable:

```text
REACT-2026-Q3
TYPESCRIPT-MODULE-1
LEADERSHIP-WEEK-2
```

These IDs appear in QR URLs, so readable values are more convenient for administrators.

---

## 8. The GreyMatter Feedback Data Model

The core data structure is:

```text
Event
  └── Session
        ├── FormVersion
        │     └── Question
        │
        ├── Response
        │     └── Answer
        │
        └── Report
```

Here is what each model represents.

| Model | Meaning |
|---|---|
| `Event` | A course, conference, workshop series, or event |
| `Session` | A specific talk, lesson, module, workshop, or survey target |
| `FormVersion` | A draft, published, or archived snapshot of a form |
| `Question` | One configured participant question |
| `Response` | One completed participant submission |
| `Answer` | One answer within a response |
| `Report` | A PDF report request and its status |

---

## 9. Events

An event is the top-level organizational container.

Example:

```text
Event:
React Summit 2026
```

It may contain several sessions:

```text
React Summit 2026
├── Opening Keynote
├── Server Components Workshop
├── Advanced React Patterns
└── Closing Panel
```

Prisma relationship:

```prisma
model Event {
  id       String    @id @default(uuid()) @db.Uuid
  title    String    @db.VarChar(255)
  sessions Session[]
}
```

One event can have many sessions.

---

## 10. Sessions

A session is one QR-addressable feedback target.

Example:

```text
Session title:
Advanced React Patterns

Session ID:
REACT-2026-Q3
```

Participant URL:

```text
/e/REACT-2026-Q3
```

A session stores:

```text
Readable QR ID
Event relationship
Session title
Active/closed state
Current active published form version
Creation time
```

Simplified Prisma model:

```prisma
model Session {
  id                  String    @id @db.VarChar(64)
  eventId             String    @db.Uuid
  title               String    @db.VarChar(255)
  isActive            Boolean   @default(true)
  activeFormVersionId String?   @unique @db.Uuid

  event               Event     @relation(fields: [eventId], references: [id])
  formVersions        FormVersion[]
  responses           Response[]
  reports             Report[]
}
```

The important field is:

```text
activeFormVersionId
```

It tells the participant route which published form to display.

---

## 11. Form Versions

A form version is a versioned snapshot of a session’s feedback form.

A session may have:

```text
Version 1 — Archived
Version 2 — Published
Version 3 — Draft
```

The status is represented by this enum:

```prisma
enum FormVersionStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}
```

The model contains:

```prisma
model FormVersion {
  id            String            @id @default(uuid()) @db.Uuid
  sessionId     String            @db.VarChar(64)
  versionNumber Int
  status        FormVersionStatus @default(DRAFT)
  publishedAt   DateTime?

  questions     Question[]
  responses     Response[]
}
```

The combination of session and version number must be unique:

```prisma
@@unique([sessionId, versionNumber])
```

That prevents a session from having two Version 2 records.

---

## 12. Questions

A question belongs to one form version.

It contains:

```text
Question text
Question type
Display order
Required setting
Question-specific settings
Choice options
```

Example rating question:

```text
How useful was this workshop?
```

Example database representation:

```json
{
  "questionText": "How useful was this workshop?",
  "questionType": "RATING",
  "isRequired": true,
  "settings": {
    "min": 1,
    "max": 5,
    "minLabel": "Not useful",
    "maxLabel": "Extremely useful"
  },
  "options": []
}
```

Example choice question:

```json
{
  "questionText": "Which topic was most valuable?",
  "questionType": "CHOICE",
  "isRequired": false,
  "settings": {},
  "options": [
    "Server Components",
    "Data fetching patterns",
    "Performance optimization"
  ]
}
```

---

## 13. Question Types

GreyMatter Feedback supports four question types.

```prisma
enum QuestionType {
  RATING
  NPS
  TEXT
  CHOICE
}
```

| Type | Stored answer | Example |
|---|---|---|
| `RATING` | `numericValue` | 1–5 usefulness score |
| `NPS` | `numericValue` | 0–10 recommendation score |
| `TEXT` | `textValue` | Improvement comment |
| `CHOICE` | `textValue` | Selected option |

---

## 14. Why `settings` and `options` Use JSON

Not every question needs the same configuration.

A rating question needs:

```json
{
  "min": 1,
  "max": 5,
  "minLabel": "Not useful",
  "maxLabel": "Extremely useful"
}
```

A text question needs:

```json
{
  "maxLength": 1500,
  "placeholder": "Share your suggestions"
}
```

An NPS question needs:

```json
{
  "minLabel": "Not at all likely",
  "maxLabel": "Extremely likely"
}
```

A choice question needs selectable values:

```json
[
  "Presentation",
  "Hands-on exercises",
  "Discussion"
]
```

Using JSON gives the model flexibility.

However, JSON must be validated. That is why GreyMatter Feedback uses Zod when loading question settings and when processing form authoring input.

---

## 15. Responses

A response represents one submitted participant form.

Example:

```text
Participant scans:
 /e/REACT-2026-Q3

Participant completes:
 Four questions

Participant submits:
 One response record created
```

A response stores:

```text
Session ID
Form version ID
Submission timestamp
Submission event ID
Privacy-preserving IP hash
Safe metadata
Linked answers
```

Simplified model:

```prisma
model Response {
  id            String   @id @default(uuid()) @db.Uuid
  eventId       String   @unique @db.VarChar(128)
  sessionId     String   @db.VarChar(64)
  formVersionId String   @db.Uuid
  submittedAt   DateTime @default(now())
  clientIpHash  String?  @db.VarChar(64)
  metadata      Json     @default("{}")

  answers       Answer[]
}
```

The `eventId` field is especially important for reliable retries.

---

## 16. Why a Response Stores `formVersionId`

A response must record the exact form version the participant saw.

Example:

```text
Version 1:
How useful was this workshop?

Version 2:
How useful were the practical exercises?
```

If a participant answered Version 1, their response must remain associated with Version 1.

```text
Response
  └── formVersionId → Version 1
```

Without this field, historical reports could apply newer wording to older answers.

---

## 17. Answers

An answer belongs to one response and one question.

Example:

```text
Response:
Participant submission from 10:30 UTC

Question:
How useful was this workshop?

Answer:
5
```

The model supports two answer fields:

```prisma
numericValue Int?
textValue    String?
```

Only one should normally be populated:

| Question type | `numericValue` | `textValue` |
|---|---:|---|
| Rating | Yes | No |
| NPS | Yes | No |
| Choice | No | Yes |
| Text | No | Yes |

The database includes this unique rule:

```prisma
@@unique([responseId, questionId])
```

That means one participant response cannot contain two answers for the same question.

---

## 18. Reports

A report record tracks asynchronous PDF generation.

A report begins like this:

```text
QUEUED
```

Then becomes:

```text
PROCESSING
```

Then either:

```text
COMPLETE
```

or:

```text
FAILED
```

The model stores:

```prisma
model Report {
  id        String       @id @default(uuid()) @db.Uuid
  sessionId String       @db.VarChar(64)
  status    ReportStatus @default(QUEUED)
  url       String?
  error     String?
  createdAt DateTime     @default(now())
  updatedAt DateTime     @updatedAt
}
```

A completed report has a URL:

```text
/reports/REACT-2026-Q3-report-id.pdf
```

In production, this should usually be a protected or signed object-storage URL.

---

## 19. Relationships and Foreign Keys

A **foreign key** is a field that points to a related record.

For example:

```text
Session.eventId
  points to
Event.id
```

This creates a relationship:

```text
One Event
  → Many Sessions
```

Another example:

```text
Answer.responseId
  points to
Response.id
```

This creates:

```text
One Response
  → Many Answers
```

Foreign keys prevent invalid data.

For example, PostgreSQL should not allow an answer to reference a response that does not exist.

---

## 20. Cascade Deletes

Some relationships use:

```text
onDelete: Cascade
```

This means deleting a parent also deletes related records.

Example:

```text
Delete event
  ↓
Delete sessions
  ↓
Delete form versions
  ↓
Delete questions
  ↓
Delete responses
  ↓
Delete answers
```

This can be useful for development, but it is powerful and potentially dangerous in production.

For production systems with important historical data, consider:

```text
Soft deletion
Administrator confirmation dialogs
Audit logs
Restricted deletion permissions
Recovery procedures
```

---

## 21. Indexes

An index helps the database find records faster.

Think of an index like the index at the back of a textbook.

Without an index, PostgreSQL may need to inspect many rows.

GreyMatter Feedback uses indexes for common lookups.

Example:

```prisma
@@index([sessionId, submittedAt])
```

This helps queries such as:

```text
Find all responses for one session,
ordered by submission time.
```

Another example:

```prisma
@@index([formVersionId])
```

This helps find responses for one specific form version.

Indexes improve reads but add some overhead to writes, so add them based on real query patterns.

---

## 22. Prisma Queries

Prisma provides methods that match common database operations.

### Create

```ts
const event = await prisma.event.create({
  data: {
    title: "React Summit 2026",
  },
});
```

### Find one record

```ts
const session = await prisma.session.findUnique({
  where: {
    id: "REACT-2026-Q3",
  },
});
```

### Find many records

```ts
const sessions = await prisma.session.findMany({
  where: {
    eventId: event.id,
  },
  orderBy: {
    createdAt: "desc",
  },
});
```

### Update

```ts
await prisma.session.update({
  where: {
    id: "REACT-2026-Q3",
  },
  data: {
    isActive: false,
  },
});
```

### Delete

```ts
await prisma.session.delete({
  where: {
    id: "REACT-2026-Q3",
  },
});
```

Delete operations should be used carefully in production.

---

## 23. Prisma Relations in Queries

Prisma can load related records.

For example, load a session with its event and questions:

```ts
const session = await prisma.session.findUnique({
  where: {
    id: "REACT-2026-Q3",
  },
  include: {
    event: true,
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
```

This creates a nested data structure like:

```text
Session
├── Event
└── Active Form Version
      └── Questions
```

GreyMatter Feedback uses this pattern to load participant form configuration.

---

## 24. Transactions

A transaction groups related database operations.

Either all operations succeed, or all are undone.

Publishing a form version is a good example.

```text
Archive old published version
        ↓
Publish new version
        ↓
Update session activeFormVersionId
```

Those updates should happen together.

Simplified code:

```ts
await prisma.$transaction(async (transaction) => {
  await transaction.formVersion.update({
    where: {
      id: oldVersionId,
    },
    data: {
      status: "ARCHIVED",
    },
  });

  await transaction.formVersion.update({
    where: {
      id: newVersionId,
    },
    data: {
      status: "PUBLISHED",
      publishedAt: new Date(),
    },
  });

  await transaction.session.update({
    where: {
      id: sessionId,
    },
    data: {
      activeFormVersionId: newVersionId,
    },
  });
});
```

Without a transaction, a failure halfway through could leave inconsistent data.

---

## 25. Migrations

A migration changes database structure over time.

Example:

```text
Initial schema:
Questions have text and type

Later migration:
Questions also have helper text
```

The workflow is:

```bash
npx prisma migrate dev --name add_question_helper_text
```

Prisma creates a migration file under:

```text
prisma/migrations/
```

For production, apply existing migrations with:

```bash
npx prisma migrate deploy
```

Do not use `migrate dev` against production.

---

## 26. Prisma Studio

Prisma Studio is a browser-based database viewer.

Start it with:

```bash
npx prisma studio
```

It usually opens at:

```text
http://localhost:5555
```

It is useful for development tasks such as:

```text
Inspecting seed data
Checking active form version IDs
Confirming saved responses
Reviewing answer values
Testing session active states
```

It should not become the normal production authoring interface. GreyMatter Feedback’s admin portal is the safer and more user-friendly authoring environment.

---

## 27. Seed Data

Seed data is demonstration data inserted into a development database.

GreyMatter Feedback seed data creates a sample:

```text
Event:
React Summit 2026

Session:
Advanced React Patterns

Session ID:
REACT-2026-Q3

Form:
One published version with rating, NPS, choice, and text questions
```

Run it with:

```bash
npm run db:seed
```

Seed scripts should not run against production databases.

---

## 28. Database Safety Rules

Use these rules while working with Neon and Prisma.

```text
[ ] Keep DATABASE_URL private.
[ ] Keep DIRECT_URL private.
[ ] Use pooled URL for app runtime.
[ ] Use direct URL for Prisma migrations.
[ ] Commit migrations to Git.
[ ] Test migrations on Neon branches.
[ ] Do not run prisma migrate reset against production.
[ ] Do not manually edit production data unless necessary and approved.
[ ] Do not edit published forms directly.
[ ] Use form versioning for all participant-facing changes.
[ ] Back up and test recovery procedures.
```

---

## 29. Primer Summary

The key database model is:

```text
Event
  └── Session
        ├── FormVersion
        │     └── Question
        │
        ├── Response
        │     └── Answer
        │
        └── Report
```

The key technology responsibilities are:

```text
Neon
  = hosted PostgreSQL database

Prisma
  = schema, migrations, and typed queries

FormVersion
  = protects historical form accuracy

Response.formVersionId
  = records the exact form a participant saw

Response.eventId
  = prevents duplicate responses during retries

Indexes
  = keep common lookups fast

Transactions
  = keep multi-step updates consistent
```

With this model, GreyMatter Feedback can support many events and courses, each with different versioned feedback forms, while preserving trustworthy analytics over time.
