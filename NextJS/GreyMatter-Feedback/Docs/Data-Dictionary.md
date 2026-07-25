# GreyMatter Feedback Data Dictionary

**Database:** Neon PostgreSQL  
**ORM:** Prisma  
**Naming convention:** Prisma uses PascalCase model names; PostgreSQL uses snake_case table and column names.

---

## 1. Entity Relationship Summary

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

---

# 2. `events`

**Purpose:** Stores a parent grouping for a conference, course, workshop series, training program, or event.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | UUID | Yes | Primary key for the event | `6b9f6b86-8fc0-4e54-b064-2b60b848ac31` |
| `title` | `title` | VARCHAR(255) | Yes | Event or course name | `React Summit 2026` |
| `created_at` | `createdAt` | TIMESTAMPTZ | Yes | Event creation timestamp | `2026-07-25T10:00:00.000Z` |

### Relationships

```text
One Event → Many Sessions
```

---

# 3. `sessions`

**Purpose:** Stores individual feedback targets. A session may be a workshop, course module, keynote, talk, lesson, or end-of-course evaluation.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | VARCHAR(64) | Yes | Primary key and QR-friendly session identifier | `REACT-2026-Q3` |
| `event_id` | `eventId` | UUID | Yes | Foreign key to `events.id` | Event UUID |
| `title` | `title` | VARCHAR(255) | Yes | Human-readable session title | `Advanced React Patterns` |
| `is_active` | `isActive` | BOOLEAN | Yes | Controls whether participant feedback is open | `true` |
| `active_form_version_id` | `activeFormVersionId` | UUID | No | Current published form version shown to participants | FormVersion UUID |
| `created_at` | `createdAt` | TIMESTAMPTZ | Yes | Session creation timestamp | `2026-07-25T10:10:00.000Z` |

### Constraints

| Constraint | Description |
|---|---|
| Primary key on `id` | Each session ID is globally unique |
| Foreign key `event_id` | Session belongs to an event |
| Unique `active_form_version_id` | A form version can be active for only one session |
| Index on `event_id` | Supports event-to-session lookups |

### Relationships

```text
One Session → One Event
One Session → Many FormVersions
One Session → Many Responses
One Session → Many Reports
One Session → Zero or One Active FormVersion
```

---

# 4. `form_versions`

**Purpose:** Stores draft, published, and archived snapshots of a session feedback form.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | UUID | Yes | Primary key for form version | FormVersion UUID |
| `session_id` | `sessionId` | VARCHAR(64) | Yes | Foreign key to `sessions.id` | `REACT-2026-Q3` |
| `version_number` | `versionNumber` | INTEGER | Yes | Sequential version number within session | `2` |
| `status` | `status` | ENUM | Yes | Form lifecycle state | `PUBLISHED` |
| `published_at` | `publishedAt` | TIMESTAMPTZ | No | Timestamp when form was published | `2026-07-25T11:00:00.000Z` |
| `created_at` | `createdAt` | TIMESTAMPTZ | Yes | Draft creation timestamp | `2026-07-25T10:30:00.000Z` |
| `updated_at` | `updatedAt` | TIMESTAMPTZ | Yes | Last modification timestamp | `2026-07-25T10:55:00.000Z` |

### Allowed `status` Values

| Value | Meaning |
|---|---|
| `DRAFT` | Editable by administrators; not visible to participants |
| `PUBLISHED` | Active or previously active participant form |
| `ARCHIVED` | Historical form retained for analytics and reporting |

### Constraints

| Constraint | Description |
|---|---|
| Unique `[session_id, version_number]` | A session cannot have two versions with the same number |
| Index `[session_id, status]` | Supports finding draft or published forms for a session |

### Relationships

```text
One FormVersion → One Session
One FormVersion → Many Questions
One FormVersion → Many Responses
```

---

# 5. `questions`

**Purpose:** Stores one question within a specific form version.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | UUID | Yes | Primary key for question | Question UUID |
| `form_version_id` | `formVersionId` | UUID | Yes | Foreign key to `form_versions.id` | FormVersion UUID |
| `order_index` | `orderIndex` | INTEGER | Yes | Display position in form | `1` |
| `question_text` | `questionText` | TEXT | Yes | Participant-visible question prompt | `How useful was this workshop?` |
| `question_type` | `questionType` | ENUM | Yes | Question control and answer type | `RATING` |
| `is_required` | `isRequired` | BOOLEAN | Yes | Whether participant must answer before submission | `true` |
| `settings` | `settings` | JSONB | Yes | Type-specific question settings | Rating range configuration |
| `options` | `options` | JSONB | Yes | Choice options for `CHOICE` questions | `["Exercises", "Discussion"]` |

### Allowed `question_type` Values

| Value | Description | Stored Answer Field |
|---|---|---|
| `RATING` | Numeric rating using configured range | `numeric_value` |
| `NPS` | Recommendation score from 0–10 | `numeric_value` |
| `TEXT` | Written feedback | `text_value` |
| `CHOICE` | One selected configured option | `text_value` |

### Example `settings` Values

#### Rating question

```json
{
  "min": 1,
  "max": 5,
  "minLabel": "Not useful",
  "maxLabel": "Extremely useful"
}
```

#### NPS question

```json
{
  "minLabel": "Not at all likely",
  "maxLabel": "Extremely likely"
}
```

#### Text question

```json
{
  "maxLength": 1500,
  "placeholder": "Share your suggestions."
}
```

#### Choice question

```json
{}
```

### Example `options` Value for Choice Question

```json
[
  "Server Components",
  "Data fetching patterns",
  "Performance optimization",
  "Testing strategies"
]
```

### Constraints

| Constraint | Description |
|---|---|
| Unique `[form_version_id, order_index]` | Two questions cannot occupy the same position in one form version |
| Index on `form_version_id` | Supports loading ordered form questions |

### Relationships

```text
One Question → One FormVersion
One Question → Many Answers
```

---

# 6. `responses`

**Purpose:** Stores one completed participant feedback submission.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | UUID | Yes | Primary key for response | Response UUID |
| `event_id` | `eventId` | VARCHAR(128) | Yes | Stable submission identifier used for idempotency | Submission UUID |
| `session_id` | `sessionId` | VARCHAR(64) | Yes | Foreign key to `sessions.id` | `REACT-2026-Q3` |
| `form_version_id` | `formVersionId` | UUID | Yes | Exact participant form version | FormVersion UUID |
| `submitted_at` | `submittedAt` | TIMESTAMPTZ | Yes | Submission timestamp | `2026-07-25T12:30:00.000Z` |
| `client_ip_hash` | `clientIpHash` | VARCHAR(64) | No | Daily salted SHA-256 hash of client IP | 64-character hash |
| `metadata` | `metadata` | JSONB | Yes | Limited safe request context | Source and screen size |

### Example `metadata`

```json
{
  "source": "qr",
  "screenWidth": 390,
  "screenHeight": 844,
  "userAgent": "Mozilla/5.0 ..."
}
```

### Privacy Notes

| Field | Privacy Treatment |
|---|---|
| `client_ip_hash` | Never expose in normal admin dashboard, CSV, or PDF |
| `metadata.userAgent` | Technical troubleshooting only; do not export by default |
| `event_id` | Internal idempotency value; not participant identity |
| `form_version_id` | Important for historical reporting accuracy |

### Constraints

| Constraint | Description |
|---|---|
| Unique `event_id` | Prevents duplicate response persistence on retries |
| Index `[session_id, submitted_at]` | Supports session response queries and dashboard timing |
| Index `form_version_id` | Supports version-specific reporting |

### Relationships

```text
One Response → One Session
One Response → One FormVersion
One Response → Many Answers
```

---

# 7. `answers`

**Purpose:** Stores one participant answer for one question.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | UUID | Yes | Primary key for answer | Answer UUID |
| `response_id` | `responseId` | UUID | Yes | Foreign key to `responses.id` | Response UUID |
| `question_id` | `questionId` | UUID | Yes | Foreign key to `questions.id` | Question UUID |
| `numeric_value` | `numericValue` | INTEGER | No | Rating or NPS score | `5` |
| `text_value` | `textValue` | TEXT | No | Choice answer or written feedback | `Server Components` |

### Value Rules

| Question Type | `numeric_value` | `text_value` |
|---|---:|---:|
| `RATING` | Required | Null |
| `NPS` | Required | Null |
| `CHOICE` | Null | Required |
| `TEXT` | Null | Required |

### Constraints

| Constraint | Description |
|---|---|
| Unique `[response_id, question_id]` | One response cannot answer one question more than once |
| Index on `question_id` | Supports question-level analytics |

### Relationships

```text
One Answer → One Response
One Answer → One Question
```

---

# 8. `reports`

**Purpose:** Tracks asynchronous PDF report requests and generated file locations.

| Database Column | Prisma Field | Type | Required | Description | Example |
|---|---|---:|:---:|---|---|
| `id` | `id` | UUID | Yes | Primary key for report | Report UUID |
| `session_id` | `sessionId` | VARCHAR(64) | Yes | Foreign key to `sessions.id` | `REACT-2026-Q3` |
| `status` | `status` | ENUM | Yes | Current report generation state | `COMPLETE` |
| `url` | `url` | TEXT | No | Generated PDF location | `/reports/REACT-2026-Q3-id.pdf` |
| `error` | `error` | TEXT | No | Safe report-generation error | `Storage upload failed` |
| `created_at` | `createdAt` | TIMESTAMPTZ | Yes | Report request timestamp | `2026-07-25T13:00:00.000Z` |
| `updated_at` | `updatedAt` | TIMESTAMPTZ | Yes | Last report state update | `2026-07-25T13:00:08.000Z` |

### Allowed `status` Values

| Value | Meaning |
|---|---|
| `QUEUED` | Report request created; waiting for worker |
| `PROCESSING` | Background job is generating report |
| `COMPLETE` | PDF stored successfully and available |
| `FAILED` | PDF generation or storage failed |

### Constraints

| Constraint | Description |
|---|---|
| Index `[session_id, created_at]` | Supports report history display |

### Relationships

```text
One Report → One Session
```

---

# 9. Enums

## 9.1 `QuestionType`

```text
RATING
NPS
TEXT
CHOICE
```

## 9.2 `FormVersionStatus`

```text
DRAFT
PUBLISHED
ARCHIVED
```

## 9.3 `ReportStatus`

```text
QUEUED
PROCESSING
COMPLETE
FAILED
```

---

# 10. Important Derived Metrics

These values are calculated from stored `responses` and `answers`; they are not stored as baseline database columns.

| Metric | Formula or Source |
|---|---|
| Total Responses | Count of `responses` for a session |
| Average Rating | Mean of `answers.numeric_value` for rating questions |
| NPS Promoters | Count of NPS answers from 9 to 10 |
| NPS Passives | Count of NPS answers from 7 to 8 |
| NPS Detractors | Count of NPS answers from 0 to 6 |
| NPS Score | `% Promoters - % Detractors` |
| Choice Distribution | Count of `answers.text_value` by configured option |
| Written Feedback Count | Count of text answers for text questions |
| Latest Submission | Most recent `responses.submitted_at` for session |

---

# 11. Data Classification

| Data Item | Classification | Notes |
|---|---|---|
| Event title | Internal | Generally non-sensitive |
| Session title | Internal | Generally non-sensitive |
| Form questions | Internal | May be publicly visible once published |
| Choice options | Internal/Public | Visible to participants for published forms |
| Numeric feedback | Sensitive operational data | Use authorized admin access |
| Written feedback | Potentially sensitive | May include personal or confidential information |
| `client_ip_hash` | Restricted technical data | Do not expose in standard exports |
| User agent metadata | Restricted technical data | Avoid exposing to ordinary admins |
| Admin password | Secret | Environment variable only |
| Database URLs | Secret | Environment variable only |
| Storage credentials | Secret | Environment variable only |

---

# 12. Retention Guidance

| Table / Data | Suggested Retention |
|---|---:|
| `events` | Long-term, based on organizational policy |
| `sessions` | Long-term, based on organizational policy |
| `form_versions` | Retain while associated responses exist |
| `questions` | Retain while associated responses exist |
| `responses` | 12–24 months, or policy requirement |
| `answers` | 12–24 months, or policy requirement |
| `client_ip_hash` | 7–30 days recommended |
| `metadata` | 30–90 days recommended |
| `reports` | 12 months recommended |
| Stored PDF files | 12 months recommended, then archive or delete |

---

# 13. Referential Integrity Rules

```text
An Event may contain many Sessions.

A Session must belong to one Event.

A FormVersion must belong to one Session.

A Question must belong to one FormVersion.

A Response must belong to one Session.

A Response must belong to one FormVersion.

An Answer must belong to one Response.

An Answer must belong to one Question.

A Report must belong to one Session.
```

---

# 14. Key Business Rules

```text
A session can have one active published form version.

A draft form cannot be shown to participants.

A published form must not be edited directly.

A participant response must record the exact published form version used.

A response event ID must be unique.

A response may contain only one answer per question.

Choice answers must match configured options.

Rating values must fall within configured range.

NPS values must be integers from 0 through 10.

Text values must not exceed configured maximum length.

CSV and PDF exports must not expose client IP hashes by default.
```
