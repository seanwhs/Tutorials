# Appendix G: Testing Strategy and Quality Assurance

GreyMatter Feedback contains several connected systems:

```text
Participant form
        ↓
Feedback API
        ↓
Rate limiting and validation
        ↓
Inngest background jobs
        ↓
Neon PostgreSQL
        ↓
Admin analytics, CSV, and PDF reports
```

A change in one layer can affect another layer. For example:

```text
Change question validation
        ↓
Participant submission fails
        ↓
No Inngest event is sent
        ↓
Dashboard no longer receives responses
```

Testing reduces the chance of discovering these problems during a live workshop or event.

This appendix explains a practical testing strategy for GreyMatter Feedback.

---

## G.1 Testing layers

A good application uses several forms of testing.

| Test type | What it checks | Example |
|---|---|---|
| Unit test | Small isolated logic | NPS calculation |
| Integration test | Multiple application pieces | API validation plus Prisma database writes |
| End-to-end test | Full user workflow in browser | Create form, submit feedback, view dashboard |
| Manual exploratory test | Real device and human behavior | Scan QR code on a phone |
| Production smoke test | Critical behavior after deployment | Submit one test response in production |

No single test type is enough.

For example:

- Unit tests can prove that NPS math works.
- They cannot prove that a QR code opens the right session.
- End-to-end tests can prove the QR workflow works.
- They cannot fully replace testing on real phones with slow network connections.

---

## G.2 Minimum quality gate

Before merging or deploying changes, run:

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

These commands verify different things.

| Command | Checks |
|---|---|
| `npx prisma validate` | Prisma schema syntax and model validity |
| `npm run db:test` | Neon connection availability |
| `npm test` | Automated unit tests |
| `npm run lint` | Code style and common mistakes |
| `npm run build` | Production compilation and route generation |

A successful production build is especially important. It catches many issues that may not appear while using `npm run dev`.

---

## G.3 Unit-test candidates

Unit tests are best for pure logic: functions that receive values and return values without depending on a browser, database, or network.

Good candidates include:

```text
NPS calculation
Average calculation
CSV escaping
Choice option normalization
Question settings parsing
Session ID validation
Filename sanitization
Form version numbering rules
```

Poor initial candidates include:

```text
Direct Prisma queries
Inngest execution
QR scanning
S3 uploads
Browser localStorage behavior
```

Those require integration or end-to-end tests.

---

## G.4 Test NPS calculation

GreyMatter Feedback calculates NPS using:

```text
Promoters: 9–10
Passives: 7–8
Detractors: 0–6

NPS = ((promoters - detractors) / total responses) × 100
```

Example input:

```text
Scores:
10, 9, 8, 7, 6, 0
```

Expected groups:

```text
Promoters: 2
Passives: 2
Detractors: 2
NPS: 0
```

The existing test demonstrates this:

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

Run it:

```bash
npm test
```

---

## G.5 Add tests for choice-option normalization

Choice options are entered by administrators as lines of text.

For example:

```text
Hands-on exercises
Presentation

Hands-on exercises
Discussion
```

The application should normalize that into:

```ts
[
  "Hands-on exercises",
  "Presentation",
  "Discussion",
]
```

Create this test file.

### `src/lib/authoring.test.ts`

```ts
import { describe, expect, it } from "vitest";
import { normalizeChoiceOptions } from "./authoring";

describe("normalizeChoiceOptions", () => {
  it("removes blank values and duplicate options", () => {
    expect(
      normalizeChoiceOptions(
        "Hands-on exercises\nPresentation\n\nHands-on exercises\nDiscussion\n",
      ),
    ).toEqual([
      "Hands-on exercises",
      "Presentation",
      "Discussion",
    ]);
  });

  it("trims surrounding whitespace", () => {
    expect(
      normalizeChoiceOptions("  First option  \n Second option "),
    ).toEqual([
      "First option",
      "Second option",
    ]);
  });

  it("returns an empty array for empty input", () => {
    expect(normalizeChoiceOptions(" \n \n")).toEqual([]);
  });
});
```

### Verification

Run:

```bash
npm test
```

Expected result:

```text
All tests passed.
```

> If Vitest cannot import `src/lib/authoring.ts` because it contains `server-only`, move `normalizeChoiceOptions` into a separate pure module such as `src/lib/form-utils.ts`, then import it from both the authoring module and test file.

---

## G.6 Add tests for CSV escaping

CSV exports must handle commas, quotes, and spreadsheet formula-like values safely.

The tutorial CSV route already quotes values. For production, strengthen it against spreadsheet formula injection.

Create a reusable utility.

### `src/lib/csv.ts`

```ts
export function protectSpreadsheetFormula(value: string): string {
  return /^[=+\-@]/.test(value) ? `'${value}` : value;
}

export function escapeCsvValue(
  value: string | number | null | undefined,
): string {
  const normalizedValue =
    value === null || value === undefined
      ? ""
      : protectSpreadsheetFormula(String(value));

  return `"${normalizedValue.replaceAll('"', '""')}"`;
}
```

Create tests.

### `src/lib/csv.test.ts`

```ts
import { describe, expect, it } from "vitest";
import { escapeCsvValue } from "./csv";

describe("escapeCsvValue", () => {
  it("quotes ordinary text", () => {
    expect(escapeCsvValue("GreyMatter Feedback")).toBe(
      "\"GreyMatter Feedback\"",
    );
  });

  it("escapes embedded quotes", () => {
    expect(escapeCsvValue('She said "helpful"')).toBe(
      "\"She said \"\"helpful\"\"\"",
    );
  });

  it("handles missing values", () => {
    expect(escapeCsvValue(null)).toBe("\"\"");
    expect(escapeCsvValue(undefined)).toBe("\"\"");
  });

  it("protects spreadsheet formula-like values", () => {
    expect(escapeCsvValue("=SUM(A1:A10)")).toBe(
      "\"'=SUM(A1:A10)\"",
    );
  });
});
```

Update the CSV export route.

### `src/app/api/admin/export/[sessionId]/route.ts`

Add this import:

```ts
import { escapeCsvValue } from "@/lib/csv";
```

Delete the local `escapeCsvValue` function from the route.

The rest of the route can remain unchanged.

### Verification

Run:

```bash
npm test
```

Then verify the export manually:

1. Submit a text response beginning with:

   ```text
   =SUM(A1:A10)
   ```

2. Export CSV.

3. Open it in a text editor.

4. Confirm the exported value begins with:

   ```text
   '=SUM(A1:A10)
   ```

This prevents spreadsheet applications from interpreting the participant comment as a formula.

---

## G.7 Manual participant workflow test

Run this test before a live event.

### Preparation

Start the application:

```bash
npm run dev
```

Start Inngest:

```bash
npm run inngest:dev
```

Open the participant URL:

```text
http://localhost:3000/e/REACT-2026-Q3?src=manual-test
```

### Workflow

```text
[ ] Form title and event title are correct.
[ ] Every question appears in the expected order.
[ ] Required labels are accurate.
[ ] Rating controls select one score.
[ ] NPS controls select one score.
[ ] Choice controls select one option.
[ ] Text input accepts and counts characters.
[ ] Draft restores after refresh.
[ ] Discard draft removes saved answers.
[ ] Missing required answers show errors.
[ ] Error messages are understandable.
[ ] Valid submission shows success.
[ ] A new Response appears in Prisma Studio.
[ ] Answers appear with correct values.
[ ] Inngest run completes successfully.
```

---

## G.8 Manual authoring workflow test

Test form creation before giving access to administrators.

### Workflow

```text
[ ] Sign in with admin password.
[ ] Create an event or course.
[ ] Create a session with a unique QR-friendly ID.
[ ] Create a draft form version.
[ ] Add one rating question.
[ ] Add one NPS question.
[ ] Add one choice question.
[ ] Add one text question.
[ ] Reorder questions.
[ ] Delete a draft question.
[ ] Confirm deleted question disappears.
[ ] Add it again.
[ ] Publish the form.
[ ] Open participant preview.
[ ] Create a second draft version.
[ ] Confirm questions were cloned.
[ ] Make a change.
[ ] Publish the second version.
[ ] Confirm the first version is archived.
```

---

## G.9 Manual reporting workflow test

After submitting at least one response, verify reporting.

### Workflow

```text
[ ] Open session analytics dashboard.
[ ] Total response count matches Neon.
[ ] Rating average is correct.
[ ] NPS value is correct.
[ ] Promoter, passive, and detractor counts are correct.
[ ] Choice distribution counts are correct.
[ ] Written feedback is shown as text, not HTML.
[ ] Dashboard refreshes after a new submission.
[ ] QR code downloads as PNG.
[ ] Export CSV downloads successfully.
[ ] CSV contains expected rows.
[ ] Generate PDF report.
[ ] Inngest PDF report run succeeds.
[ ] Completed PDF link works.
[ ] PDF contains expected session name and metrics.
```

---

## G.10 End-to-end test roadmap

The next major testing improvement is browser automation with Playwright.

Install Playwright:

```bash
npm install --save-dev @playwright/test
npx playwright install
```

Initialize Playwright:

```bash
npx playwright install --with-deps
```

> On macOS and Windows, the browser dependency command may differ. Follow the Playwright installation output if needed.

A future test should verify this high-value path:

```text
Administrator signs in
        ↓
Administrator creates event
        ↓
Administrator creates session
        ↓
Administrator creates draft
        ↓
Administrator adds question
        ↓
Administrator publishes form
        ↓
Participant opens session URL
        ↓
Participant submits response
        ↓
Administrator sees analytics
```

Because this workflow depends on Neon and Inngest, use a dedicated test database branch and a test event namespace.

For example:

```text
Event title: E2E Test Event
Session ID: E2E-TEST-SESSION
```

Never run destructive automated tests against production data.

---

## G.11 Testing Inngest functions

Inngest functions should be tested for:

```text
[ ] Successful event processing.
[ ] Retry-safe response storage.
[ ] Duplicate event handling.
[ ] Failed report storage.
[ ] Report status transitions.
```

At a minimum, manually verify idempotency:

1. Submit feedback once.
2. Find the successful Inngest run.
3. Replay it from the Inngest dashboard.
4. Confirm only one `Response` exists with the same `eventId`.

For report generation:

1. Request a PDF.
2. Find the report record in Neon.
3. Confirm the lifecycle:

   ```text
   QUEUED → PROCESSING → COMPLETE
   ```

4. Intentionally misconfigure local S3 credentials or remove write permission.
5. Confirm the report becomes:

   ```text
   FAILED
   ```

6. Confirm the dashboard shows a meaningful error without exposing secrets.

---

## G.12 Regression test checklist

A **regression** is a bug where a previously working feature breaks after a change.

Before a release, test features most likely to regress:

```text
[ ] Database connection
[ ] Admin login
[ ] Event creation
[ ] Session creation
[ ] Draft creation
[ ] Question authoring
[ ] Form publishing
[ ] Participant form rendering
[ ] Required-field validation
[ ] Draft persistence
[ ] Feedback submission
[ ] Inngest processing
[ ] Dashboard metrics
[ ] CSV export
[ ] QR generation
[ ] PDF generation
[ ] Report download
```

This list can become a release checklist or a GitHub pull-request template.

---

## G.13 Test data strategy

Use clearly named test data.

Good test records:

```text
Event: QA Test — Do Not Use
Session ID: QA-SESSION-001
Session title: QA Test Session
```

Avoid test data that looks like a real event:

```text
Leadership Training
Workshop Feedback
Conference 2026
```

Clear naming prevents accidental QR sharing or reporting confusion.

For more reliable testing, create separate Neon branches:

```text
main branch       → production
staging branch    → staging deployment
development branch → local development
test branch       → automated tests
```

Each environment should have its own:

```text
DATABASE_URL
DIRECT_URL
INNGEST app or environment
Upstash database
S3 bucket or storage prefix
```

---

## G.14 Suggested CI pipeline

A continuous integration, or **CI**, pipeline automatically checks code changes before merging.

A practical GitHub Actions workflow would run:

```text
Install dependencies
        ↓
Generate Prisma client
        ↓
Validate Prisma schema
        ↓
Run unit tests
        ↓
Run lint
        ↓
Run production build
```

Example workflow file:

### `.github/workflows/quality.yml`

```yaml
name: Quality Checks

on:
  pull_request:
  push:
    branches:
      - main

jobs:
  quality:
    runs-on: ubuntu-latest

    steps:
      - name: Check out source code
        uses: actions/checkout@v4

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Generate Prisma client
        run: npx prisma generate
        env:
          DATABASE_URL: postgresql://placeholder:placeholder@localhost:5432/placeholder
          DIRECT_URL: postgresql://placeholder:placeholder@localhost:5432/placeholder

      - name: Validate Prisma schema
        run: npx prisma validate
        env:
          DATABASE_URL: postgresql://placeholder:placeholder@localhost:5432/placeholder
          DIRECT_URL: postgresql://placeholder:placeholder@localhost:5432/placeholder

      - name: Run unit tests
        run: npm test

      - name: Run lint
        run: npm run lint

      - name: Build application
        run: npm run build
        env:
          DATABASE_URL: postgresql://placeholder:placeholder@localhost:5432/placeholder
          DIRECT_URL: postgresql://placeholder:placeholder@localhost:5432/placeholder
          IP_HASH_SECRET: 0123456789abcdef0123456789abcdef
          ADMIN_SESSION_SECRET: fedcba9876543210fedcba9876543210
          ADMIN_PASSWORD: secure-development-password
          NEXT_PUBLIC_APP_URL: http://localhost:3000
          INNGEST_DEV: "1"
          UPSTASH_REDIS_REST_URL: ""
          UPSTASH_REDIS_REST_TOKEN: ""
          S3_ENDPOINT: ""
```

### Verification

Create the workflow file and run:

```bash
git add .github/workflows/quality.yml
git commit -m "Add application quality checks"
git push
```

Open the repository’s **Actions** tab in GitHub.

Confirm the workflow completes successfully.

> If your project’s build process attempts a real database connection, use a dedicated Neon CI branch or modify build-time code so database access occurs only during requests, not during static build evaluation.

---

## G.15 Final QA checklist for a live event

Run this checklist shortly before opening a QR code to participants.

```text
[ ] The event name is correct.
[ ] The session title is correct.
[ ] The session is active.
[ ] The correct form version is published.
[ ] Participant form works on a phone.
[ ] QR code scans successfully.
[ ] Typed fallback URL works.
[ ] At least one test response was submitted.
[ ] Test response appears in dashboard.
[ ] CSV export works.
[ ] PDF generation works.
[ ] Report download permissions are correct.
[ ] Inngest production dashboard shows active functions.
[ ] Upstash rate limiting is configured.
[ ] Administrator can sign in.
[ ] A second administrator or organizer knows how to access the dashboard.
[ ] Emergency contact and rollback process are documented.
```

A feedback platform is most valuable when it is reliable at the exact moment participants are ready to respond. Testing before the event keeps GreyMatter Feedback dependable when it matters.
