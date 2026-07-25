# Appendix B: Form Versioning, Publishing, and Historical Reporting

GreyMatter Feedback allows each event, course, and session to have a different feedback form. That flexibility is useful, but it creates an important reporting challenge:

> What happens when an administrator changes a question after participants have already answered it?

This appendix explains why GreyMatter Feedback uses versioned forms, how publishing works, and how to safely evolve forms without corrupting historical analytics.

---

## B.1 The problem with editing a live form

Imagine a workshop has this question:

```text
How useful was this workshop?
```

Participants submit 80 responses.

Later, an administrator changes the question to:

```text
How useful were the hands-on exercises?
```

If the system simply edits the existing question, the old answers are now displayed under the new wording.

That creates misleading analytics:

```text
Old answers measured:
Overall workshop usefulness

New label says:
Hands-on exercise usefulness
```

The rating average would no longer mean what the dashboard claims it means.

This is why GreyMatter Feedback does not treat a published form as a normal editable document.

---

## B.2 The GreyMatter Feedback versioning model

GreyMatter Feedback uses this hierarchy:

```text
Event or Course
  └── Session
        ├── Form Version 1
        │     └── Questions
        │
        ├── Form Version 2
        │     └── Questions
        │
        └── Responses
              └── Answers
```

Each response records the exact form version used by the participant:

```text
Response
├── sessionId
├── formVersionId
├── submittedAt
└── answers
```

This means GreyMatter Feedback can always identify:

- The form version shown to the participant.
- The wording of each question.
- The available choice options.
- The rating scale.
- Whether a question was required.
- The order in which questions appeared.

---

## B.3 Form version lifecycle

A form version uses one of three statuses.

| Status | Meaning | Editable? | Visible to participants? |
|---|---|---:|---:|
| `DRAFT` | Work in progress | Yes | No |
| `PUBLISHED` | Live participant form | No | Yes |
| `ARCHIVED` | Historical form retained for reporting | No | No |

The normal lifecycle is:

```text
DRAFT
  ↓ publish
PUBLISHED
  ↓ replaced by a later version
ARCHIVED
```

For example:

```text
Session: Advanced React Patterns

Version 1
Status: ARCHIVED
Questions: 4
Used by: 125 responses

Version 2
Status: PUBLISHED
Questions: 5
Used by: 48 responses
```

The session has one active published form version at a time.

---

## B.4 Publishing workflow

The administrator workflow is designed to prevent accidental public changes.

```text
1. Create session
2. Create draft form version
3. Add questions
4. Configure scales, options, and required fields
5. Preview form
6. Publish version
7. Share QR code
8. Collect responses
```

When a version is published, GreyMatter Feedback performs these operations together:

```text
Archive current published version, if one exists
        ↓
Mark selected draft as PUBLISHED
        ↓
Set published timestamp
        ↓
Set session.activeFormVersionId
        ↓
Keep session active
```

This occurs in one database transaction.

A **transaction** is an all-or-nothing database operation. It is like moving money between two bank accounts: either every related update succeeds, or none of them do.

That prevents inconsistent states such as:

```text
Two versions both marked PUBLISHED
```

or:

```text
A published version exists, but the session points to a different version
```

---

## B.5 What participants see

Participant QR codes use a stable session URL:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

The QR code does not contain a form version number.

Instead, the participant page performs this lookup:

```text
Session ID from QR URL
        ↓
Find session
        ↓
Check session is active
        ↓
Find activeFormVersionId
        ↓
Confirm active form is PUBLISHED
        ↓
Render questions from that version
```

This lets the same QR URL continue working after a new form version is published.

For example:

```text
/e/REACT-2026-Q3
```

may initially load Version 1. After the administrator publishes Version 2, the same URL loads Version 2 for future participants.

Older responses remain connected to Version 1.

---

## B.6 When to create a new version

Create a new form version whenever you change something that affects meaning, analysis, or participant behavior.

Examples:

```text
Change question wording
Change question type
Change rating scale
Change required status
Add or remove a question
Change choice options
Change question order
Change text maximum length
```

For example, create a new version when changing:

```text
Version 1:
How would you rate this session?
Rating scale: 1–5
```

to:

```text
Version 2:
How useful was this session for your day-to-day work?
Rating scale: 1–10
```

Even though both are rating questions, they measure different things and use different scales.

---

## B.7 When a new version may not be necessary

Some changes do not affect participant meaning and can be made outside the form definition.

Examples:

```text
Changing the session title shown in the admin portal
Changing internal administrator notes
Changing report branding
Changing a QR-code poster design
Changing the event description
```

However, be cautious with session title changes if reports use the title as historical context.

A safe practice is:

```text
Keep the session title stable after responses begin.
```

If a correction is necessary, document it in internal administrator notes rather than rewriting historical context.

---

## B.8 Cloning a form into a new draft

GreyMatter Feedback creates new drafts by copying the latest form version.

For example:

```text
Version 1 — Published
├── Question 1: How useful was this workshop?
├── Question 2: How likely are you to recommend it?
└── Question 3: What should we improve?

Create Draft Version 2
        ↓

Version 2 — Draft
├── Question 1: How useful was this workshop?
├── Question 2: How likely are you to recommend it?
└── Question 3: What should we improve?
```

The administrator can then add a new question:

```text
Question 4: How useful was the hands-on exercise?
```

The two versions are independent.

```text
Version 1 question IDs ≠ Version 2 question IDs
```

This is important. A copied question may have the same wording, but it belongs to a different form snapshot.

---

## B.9 Why questions are not shared across versions

At first, it may seem more efficient to reuse one `Question` record across multiple form versions.

For reporting, that is risky.

Consider:

```text
Version 1:
How clear was the session?

Version 2:
How clear was the session content?
```

The wording change is small, but it may affect how participants interpret the question.

By creating independent question records per version, GreyMatter Feedback can accurately preserve:

```text
Question wording
Question type
Required status
Rating settings
Choice options
Display order
```

This makes reports defensible and easier to understand later.

---

## B.10 Reporting across multiple versions

A session may collect answers from more than one form version.

For example:

```text
Session: Leadership Module 1

Version 1
Published: January
Responses: 50

Version 2
Published: February
Responses: 40
```

GreyMatter Feedback groups analytics by question and form version.

The dashboard may display:

```text
Form version 1
How useful was this module?
Average: 4.2 / 5
Responses: 50

Form version 2
How useful was this module?
Average: 4.6 / 5
Responses: 40
```

Even if the wording is identical, keeping version boundaries visible helps administrators understand whether a change in results may relate to:

- Different cohorts.
- Different instructors.
- Different session formats.
- Updated question wording.
- Changed choice options.
- A new rating scale.

---

## B.11 Recommended publishing rules

For reliable operations, use these rules.

### Rule 1: Never expose drafts

A draft form should not be visible to participants.

```text
DRAFT → Admin only
PUBLISHED → Participant route may display it
```

### Rule 2: Publish deliberately

Before publishing, verify:

```text
[ ] Every required question is intentional.
[ ] Choice questions have at least two options.
[ ] Rating scales have accurate labels.
[ ] Question order makes sense.
[ ] Mobile preview looks correct.
[ ] Session QR URL is correct.
```

### Rule 3: Do not edit published forms

If a change is needed:

```text
Create new draft
        ↓
Make changes
        ↓
Preview
        ↓
Publish new version
```

### Rule 4: Keep old versions

Do not delete archived versions with answers. They are required for:

- Historical analytics.
- CSV exports.
- PDF reports.
- Audit trails.
- Explaining result changes over time.

### Rule 5: Close feedback explicitly

When feedback collection should stop:

```text
Session isActive = false
```

This closes the participant route without deleting the form, responses, or reports.

---

## B.12 Example: workshop form evolution

Here is a safe form evolution example.

### Initial version

```text
Session: TypeScript Module 1

Version 1 — Published

1. How clear was the module?
   Rating, 1–5

2. How likely are you to recommend this module?
   NPS, 0–10

3. What should we improve?
   Text
```

After reviewing feedback, organizers want more specific insight into practical work.

### New draft

```text
Version 2 — Draft

1. How clear was the module?
   Rating, 1–5

2. How useful were the coding exercises?
   Rating, 1–5

3. How likely are you to recommend this module?
   NPS, 0–10

4. What should we improve?
   Text
```

After testing the form, Version 2 is published.

```text
Version 1 → ARCHIVED
Version 2 → PUBLISHED
```

New responses use Version 2. Existing responses remain tied to Version 1.

---

## B.13 Database relationship summary

The key relationships are:

```text
Session
├── activeFormVersionId
├── formVersions[]
├── responses[]
└── reports[]

FormVersion
├── sessionId
├── versionNumber
├── status
├── questions[]
└── responses[]

Response
├── sessionId
├── formVersionId
└── answers[]

Answer
├── responseId
└── questionId
```

The most important reporting link is:

```text
Response.formVersionId
```

Without it, the system could not reliably determine which form version produced a response.

---

## B.14 Practical checklist for administrators

Before publishing a form:

```text
[ ] The session title is correct.
[ ] The QR session ID is correct.
[ ] The questions are short and understandable.
[ ] Each rating scale has meaningful labels.
[ ] Choice options are complete and mutually understandable.
[ ] Required questions are limited to essential information.
[ ] The mobile preview has been reviewed.
[ ] The participant URL opens the expected form after publishing.
```

After responses begin:

```text
[ ] Do not edit the published form.
[ ] Create a new draft for future changes.
[ ] Keep archived versions for reporting.
[ ] Close the session when response collection ends.
[ ] Export CSV and generate a PDF report before major changes.
```
