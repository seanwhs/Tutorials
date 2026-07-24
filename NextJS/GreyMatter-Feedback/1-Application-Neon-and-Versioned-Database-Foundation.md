# Part 1: Application, Neon, and Versioned Database Foundation

This part creates the technical foundation for GreyMatter Feedback.

By the end, you will have:

- A Next.js 16 application using TypeScript, React 19, and Tailwind CSS.
- A Neon-hosted PostgreSQL database.
- Secure environment-variable configuration.
- Prisma connected to Neon.
- A version-aware schema for events, sessions, forms, questions, responses, answers, and reports.
- A reusable Prisma client.
- A GreyMatter Feedback landing page.

---

## Step 1.1 — Create the Next.js application

### The Target

Create the initial GreyMatter Feedback application.

### The Concept

Next.js is the application’s building framework. It provides a structured location for pages, API endpoints, layouts, and server-side code.

Later, a participant route such as:

```text
/e/REACT-2026-Q3
```

will be implemented with this file:

```text
src/app/e/[sessionId]/page.tsx
```

The `[sessionId]` folder is a dynamic route segment. It means one reusable page can serve many session URLs.

### The Implementation

Run:

```bash
npx create-next-app@latest greymatter-feedback
```

Use these selections when prompted:

```text
Would you like to use TypeScript? Yes
Which linter would you like to use? ESLint
Would you like to use React Compiler? Yes
Would you like to use Tailwind CSS? Yes
Would you like your code inside a `src/` directory? Yes
Would you like to use App Router? Yes
Would you like to use Turbopack for `next dev`? Yes
Would you like to customize the import alias? No
```

Move into the project:

```bash
cd greymatter-feedback
```

Install application dependencies:

```bash
npm install \
  @aws-sdk/client-s3 \
  @aws-sdk/s3-request-presigner \
  @react-pdf/renderer \
  inngest \
  qrcode \
  zod
```

Install Prisma version 6 explicitly. This keeps the schema and migration workflow used in this tutorial stable:

```bash
npm install \
  @prisma/client@6 \
  prisma@6
```

Install development dependencies:

```bash
npm install --save-dev \
  @types/qrcode \
  tsx
```

Create the initial directories:

```bash
mkdir -p \
  prisma \
  scripts \
  src/lib \
  src/types \
  src/inngest/functions \
  src/components/ui \
  src/components/admin \
  src/components/participant
```

### The Verification

Start the development server:

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

You should see the default Next.js page.

Stop the server:

```bash
Ctrl+C
```

---

## Step 1.2 — Create the Neon PostgreSQL project

### The Target

Create the hosted PostgreSQL database that will store all GreyMatter Feedback data.

### The Concept

A database is the application’s long-term record system. Neon hosts PostgreSQL for us, so we do not need to install and operate a database server locally.

Neon supplies two useful database connection strings:

| Connection | Used for |
|---|---|
| Pooled URL | The deployed Next.js application |
| Direct URL | Prisma migrations and administrative schema changes |

The pooled URL is particularly useful for serverless applications because it manages many short-lived connections efficiently.

### The Implementation

1. Visit:

   ```text
   https://neon.tech
   ```

2. Create an account or sign in.

3. Create a project using these values:

   ```text
   Project name: greymatter-feedback
   Database name: greymatter
   Role name: greymatter_owner
   Region: closest to your expected users
   ```

4. In the Neon dashboard, open the project and select **Connect**.

5. Copy the **pooled** connection string. It normally contains `-pooler` in its hostname:

   ```text
   postgresql://greymatter_owner:password@ep-example-pooler.us-east-2.aws.neon.tech/greymatter?sslmode=require
   ```

6. Copy the **direct** connection string, which does not contain `-pooler`:

   ```text
   postgresql://greymatter_owner:password@ep-example.us-east-2.aws.neon.tech/greymatter?sslmode=require
   ```

Do not publish either connection string. Both include database credentials.

### The Verification

In Neon, confirm all of the following:

- The project is named `greymatter-feedback`.
- The `main` branch exists.
- The database is named `greymatter`.
- The connection dialog displays both pooled and direct connection options.

---

## Step 1.3 — Create environment configuration

### The Target

Create a private environment file for database credentials, cryptographic secrets, and external service configuration.

### The Concept

Environment variables are values stored outside source code. They are like a secure key ring: application code knows which key it needs, but the secret itself is not written into the codebase.

### The Implementation

Create this shareable template.

### `.env.example`

```dotenv
# Neon pooled connection URL, used by the running application.
DATABASE_URL="postgresql://username:password@your-neon-host-pooler.neon.tech/greymatter?sslmode=require"

# Neon direct connection URL, used by Prisma migrations.
DIRECT_URL="postgresql://username:password@your-neon-host.neon.tech/greymatter?sslmode=require"

# Generate with: openssl rand -hex 32
# Used for privacy-preserving daily IP hashing.
IP_HASH_SECRET="replace-with-a-long-random-value"

# Generate with: openssl rand -hex 32
# Used to sign administrator session cookies.
ADMIN_SESSION_SECRET="replace-with-a-different-long-random-value"

# Initial administrator password for local development.
ADMIN_PASSWORD="replace-with-a-strong-password"

# Application URL with no trailing slash.
NEXT_PUBLIC_APP_URL="http://localhost:3000"

# Inngest values remain empty during local development.
INNGEST_EVENT_KEY=""
INNGEST_SIGNING_KEY=""

# Optional S3-compatible report storage configuration.
S3_REGION=""
S3_BUCKET=""
S3_ACCESS_KEY_ID=""
S3_SECRET_ACCESS_KEY=""
S3_ENDPOINT=""
```

Create your private local environment file:

```bash
cp .env.example .env
```

Generate the two secrets:

```bash
openssl rand -hex 32
openssl rand -hex 32
```

Update `.env` with:

- Your Neon pooled URL as `DATABASE_URL`.
- Your Neon direct URL as `DIRECT_URL`.
- The first generated value as `IP_HASH_SECRET`.
- The second generated value as `ADMIN_SESSION_SECRET`.
- A password of at least 12 characters as `ADMIN_PASSWORD`.

Ensure `.gitignore` contains these lines:

### `.gitignore`

```gitignore
.env
.env.local
.env.*.local
```

### The Verification

Run:

```bash
git status
```

`.env.example` may appear as an untracked file.

`.env` must **not** appear. If it does, fix `.gitignore` before continuing.

---

## Step 1.4 — Initialize Prisma with the versioned GreyMatter schema

### The Target

Define the database structure for versioned feedback forms and participant responses.

### The Concept

A form needs to be editable before publication but historically stable after participants use it.

The database therefore separates:

```text
Session
  ├── Form version 1 — published
  └── Form version 2 — draft
```

A response records the exact `formVersionId` that the participant saw. This prevents later draft edits from changing old analytics.

### The Implementation

Initialize Prisma:

```bash
npx prisma init --datasource-provider postgresql
```

Replace the generated schema with this complete version.

### `prisma/schema.prisma`

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

model Event {
  id        String    @id @default(uuid()) @db.Uuid
  title     String    @db.VarChar(255)
  createdAt DateTime  @default(now()) @map("created_at")

  sessions  Session[]

  @@map("events")
}

model Session {
  // Human-readable IDs are suitable for QR URLs, for example REACT-2026-Q3.
  id        String    @id @db.VarChar(64)
  eventId   String    @map("event_id") @db.Uuid
  title     String    @db.VarChar(255)
  isActive  Boolean   @default(true) @map("is_active")
  createdAt DateTime  @default(now()) @map("created_at")

  // This identifies the version participants currently receive.
  activeFormVersionId String? @unique @map("active_form_version_id") @db.Uuid

  event             Event        @relation(fields: [eventId], references: [id], onDelete: Cascade)
  formVersions      FormVersion[] @relation("SessionFormVersions")
  activeFormVersion FormVersion?  @relation("ActiveFormVersion", fields: [activeFormVersionId], references: [id], onDelete: SetNull)
  responses         Response[]
  reports           Report[]

  @@index([eventId])
  @@map("sessions")
}

enum FormVersionStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}

model FormVersion {
  id            String            @id @default(uuid()) @db.Uuid
  sessionId     String            @map("session_id") @db.VarChar(64)
  versionNumber Int               @map("version_number")
  status        FormVersionStatus @default(DRAFT)
  publishedAt   DateTime?         @map("published_at")
  createdAt     DateTime          @default(now()) @map("created_at")
  updatedAt     DateTime          @updatedAt @map("updated_at")

  session       Session           @relation("SessionFormVersions", fields: [sessionId], references: [id], onDelete: Cascade)
  activeFor     Session?          @relation("ActiveFormVersion")
  questions     Question[]
  responses     Response[]

  @@unique([sessionId, versionNumber])
  @@index([sessionId, status])
  @@map("form_versions")
}

enum QuestionType {
  RATING
  NPS
  TEXT
  CHOICE
}

model Question {
  id            String       @id @default(uuid()) @db.Uuid
  formVersionId String       @map("form_version_id") @db.Uuid
  orderIndex    Int          @map("order_index")
  questionText  String       @map("question_text") @db.Text
  questionType  QuestionType @map("question_type")
  isRequired    Boolean      @default(false) @map("is_required")

  // Settings hold type-specific values, such as rating min/max and text limits.
  settings      Json         @default("{}")

  // Choice questions store their selectable values here.
  options       Json         @default("[]")

  formVersion   FormVersion  @relation(fields: [formVersionId], references: [id], onDelete: Cascade)
  answers       Answer[]

  @@unique([formVersionId, orderIndex])
  @@index([formVersionId])
  @@map("questions")
}

model Response {
  id            String   @id @default(uuid()) @db.Uuid

  // Used to make retrying an Inngest event safe.
  eventId       String   @unique @map("event_id") @db.VarChar(128)

  sessionId     String   @map("session_id") @db.VarChar(64)
  formVersionId String   @map("form_version_id") @db.Uuid
  submittedAt   DateTime @default(now()) @map("submitted_at")

  // This will be a daily salted SHA-256 hash, not a raw IP address.
  clientIpHash  String?  @map("client_ip_hash") @db.VarChar(64)

  // Stores safe contextual details, such as a truncated user agent.
  metadata      Json     @default("{}")

  session       Session     @relation(fields: [sessionId], references: [id], onDelete: Cascade)
  formVersion   FormVersion @relation(fields: [formVersionId], references: [id], onDelete: Restrict)
  answers       Answer[]

  @@index([sessionId, submittedAt])
  @@index([formVersionId])
  @@map("responses")
}

model Answer {
  id           String   @id @default(uuid()) @db.Uuid
  responseId   String   @map("response_id") @db.Uuid
  questionId   String   @map("question_id") @db.Uuid
  numericValue Int?     @map("numeric_value")
  textValue    String?  @map("text_value") @db.Text

  response     Response @relation(fields: [responseId], references: [id], onDelete: Cascade)
  question     Question @relation(fields: [questionId], references: [id], onDelete: Restrict)

  @@unique([responseId, questionId])
  @@index([questionId])
  @@map("answers")
}

enum ReportStatus {
  QUEUED
  PROCESSING
  COMPLETE
  FAILED
}

model Report {
  id        String       @id @default(uuid()) @db.Uuid
  sessionId String       @map("session_id") @db.VarChar(64)
  status    ReportStatus @default(QUEUED)
  url       String?      @db.Text
  error     String?      @db.Text
  createdAt DateTime     @default(now()) @map("created_at")
  updatedAt DateTime     @updatedAt @map("updated_at")

  session   Session      @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  @@index([sessionId, createdAt])
  @@map("reports")
}
```

Create and apply the initial migration:

```bash
npx prisma migrate dev --name initial_schema
```

Generate the Prisma client:

```bash
npx prisma generate
```

### The Verification

Validate the schema:

```bash
npx prisma validate
```

Then inspect the Neon database visually:

```bash
npx prisma studio
```

Open the local URL Prisma displays, normally:

```text
http://localhost:5555
```

Confirm these models appear:

```text
Event
Session
FormVersion
Question
Response
Answer
Report
```

Close Prisma Studio:

```bash
Ctrl+C
```

---

## Step 1.5 — Add a shared Prisma client

### The Target

Create one reusable Prisma client for all server-side database access.

### The Concept

During development, Next.js reloads modules often. Creating a new database client after every reload can create too many connections.

We keep one development client on `globalThis`, like keeping one receptionist at the database desk instead of hiring a new one every time a file changes.

### The Implementation

### `src/lib/prisma.ts`

```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
```

Create a database test script.

### `scripts/test-database.ts`

```ts
import { prisma } from "../src/lib/prisma";

async function main() {
  const result =
    await prisma.$queryRaw<Array<{ now: Date }>>`SELECT NOW() AS now`;

  console.log("Successfully connected to Neon PostgreSQL.");
  console.log(`Database time: ${result[0]?.now.toISOString()}`);
}

main()
  .catch((error: unknown) => {
    console.error("Unable to connect to Neon PostgreSQL.");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

Add the test command to `package.json` inside the existing `scripts` object:

### `package.json`

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "db:test": "tsx scripts/test-database.ts"
  }
}
```

### The Verification

Run:

```bash
npm run db:test
```

Expected output:

```text
Successfully connected to Neon PostgreSQL.
Database time: 2026-...
```

---

## Step 1.6 — Replace the starter screen

### The Target

Create the GreyMatter Feedback landing page and global application metadata.

### The Concept

The root layout is the shared outer frame for every route. It defines metadata, fonts, and global styles.

### The Implementation

### `src/app/layout.tsx`

```tsx
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: {
    default: "GreyMatter Feedback",
    template: "%s | GreyMatter Feedback",
  },
  description:
    "QR-first feedback forms, analytics, exports, and asynchronous reports.",
  robots: {
    index: false,
    follow: false,
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body
        className={`${geistSans.variable} ${geistMono.variable} min-h-screen bg-slate-50 font-sans text-slate-950 antialiased`}
      >
        {children}
      </body>
    </html>
  );
}
```

### `src/app/page.tsx`

```tsx
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="min-h-screen bg-gradient-to-b from-indigo-50 via-slate-50 to-white">
      <section className="mx-auto flex min-h-screen max-w-6xl flex-col justify-center px-6 py-16">
        <p className="w-fit rounded-full bg-indigo-100 px-4 py-2 text-sm font-semibold text-indigo-800">
          QR-first event and course feedback
        </p>

        <h1 className="mt-6 text-4xl font-bold tracking-tight sm:text-6xl">
          GreyMatter Feedback
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-700">
          Create versioned feedback forms, publish QR codes, collect
          participant responses, and turn feedback into useful reports.
        </p>

        <div className="mt-10 flex flex-col gap-4 sm:flex-row">
          <Link
            className="inline-flex min-h-12 items-center justify-center rounded-xl bg-indigo-600 px-6 py-3 font-semibold text-white transition hover:bg-indigo-700"
            href="/admin/login"
          >
            Open administrator portal
          </Link>

          <a
            className="inline-flex min-h-12 items-center justify-center rounded-xl border border-slate-300 bg-white px-6 py-3 font-semibold text-slate-800 transition hover:bg-slate-100"
            href="#workflow"
          >
            See the workflow
          </a>
        </div>

        <section className="mt-16 grid gap-5 md:grid-cols-3" id="workflow">
          {[
            ["Author", "Create draft forms with questions tailored to each session."],
            ["Publish", "Publish a protected form version and share its QR code."],
            ["Improve", "Review analytics, exports, written feedback, and reports."],
          ].map(([title, description]) => (
            <article
              className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
              key={title}
            >
              <h2 className="text-lg font-bold">{title}</h2>
              <p className="mt-3 leading-7 text-slate-600">{description}</p>
            </article>
          ))}
        </section>
      </section>
    </main>
  );
}
```

### The Verification

Run:

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

You should see the GreyMatter Feedback landing page.

The administrator link will return a 404 for now. That is expected; authentication and authoring routes are created in later parts.

---

## Part 1 Completion Check

Run these commands:

```bash
npx prisma validate
npm run db:test
npm run lint
npm run build
```

All should complete successfully.

You now have a Neon-backed, version-aware database foundation. In Part 2, we will create seed data, form lifecycle helpers, and the first dynamic participant route that loads a session’s active published form.
