# Appendix L: Advanced Form Authoring

The core GreyMatter Feedback form authoring environment supports:

- Rating questions.
- NPS questions.
- Choice questions.
- Text questions.
- Required and optional answers.
- Question ordering.
- Draft and published form versions.

That foundation is sufficient for many events and courses.

As forms become more sophisticated, administrators may want additional authoring features:

- Group questions into sections.
- Show follow-up questions only when relevant.
- Reuse approved questions from a shared library.
- Add helper text.
- Add question-level reporting tags.
- Add “Other” options to choice questions.
- Limit one response to a particular audience segment.

This appendix explains how to add these features while preserving the most important GreyMatter Feedback rule:

> A published form version must remain an accurate historical record of what participants saw.

---

## L.1 Keep the participant experience simple

Advanced authoring features can make forms more powerful, but they can also make forms confusing.

A participant QR feedback form should generally remain:

```text
Short
Mobile-friendly
Easy to understand
Quick to complete
```

Before adding complexity, ask:

```text
Does this feature improve the quality of feedback?
Or does it make the form harder to complete?
```

For example, a conditional follow-up question can be useful:

```text
Question:
How would you rate the session?

If score is 1 or 2:
What could we improve?
```

But five layers of branching logic can create a confusing experience:

```text
If A, show B
If B, show C
If C, hide D
If D, require E
```

For most event feedback forms, use conditional logic sparingly.

---

# L.2 Add form sections

A section groups related questions under a heading.

For example, an end-of-course form may include:

```text
Section 1: Course Content
- How useful was the course?
- How clear were the explanations?

Section 2: Delivery
- How would you rate the instructor?
- Was the pace appropriate?

Section 3: Future Improvements
- What should we improve?
```

Sections make longer forms easier to scan and help participants understand why groups of questions exist.

---

## L.3 Section data model

The current schema stores `orderIndex` directly on questions.

To support sections, introduce a `FormSection` model.

### `prisma/schema.prisma`

```prisma
model FormSection {
  id            String      @id @default(uuid()) @db.Uuid
  formVersionId String      @map("form_version_id") @db.Uuid
  orderIndex    Int         @map("order_index")
  title         String      @db.VarChar(255)
  description   String?     @db.Text

  formVersion   FormVersion @relation(fields: [formVersionId], references: [id], onDelete: Cascade)
  questions     Question[]

  @@unique([formVersionId, orderIndex])
  @@map("form_sections")
}
```

Update the `FormVersion` model:

```prisma
model FormVersion {
  // Existing fields remain unchanged.

  sections      FormSection[]
  questions     Question[]
}
```

Update the `Question` model:

```prisma
model Question {
  // Existing fields remain unchanged.

  sectionId     String?      @map("section_id") @db.Uuid
  section       FormSection? @relation(fields: [sectionId], references: [id], onDelete: SetNull)
}
```

Create and apply the migration:

```bash
npx prisma migrate dev --name add_form_sections
```

Generate the client:

```bash
npx prisma generate
```

---

## L.4 Section rendering example

A participant form can render sections like this.

### `src/components/participant/feedback-form.tsx`

```tsx
type ParticipantSection = {
  id: string;
  title: string;
  description: string | null;
  questions: ParticipantQuestion[];
};

type FeedbackFormProps = {
  sessionId: string;
  formVersionId: string;
  sections: ParticipantSection[];
};
```

Render each section:

```tsx
<div className="space-y-10">
  {sections.map((section) => (
    <section key={section.id}>
      <header className="mb-5">
        <h2 className="text-2xl font-bold tracking-tight text-slate-950">
          {section.title}
        </h2>

        {section.description ? (
          <p className="mt-2 leading-7 text-slate-600">
            {section.description}
          </p>
        ) : null}
      </header>

      <div className="space-y-5">
        {section.questions.map((question) => (
          <QuestionInput
            error={errors[question.id]}
            key={question.id}
            onChange={updateAnswer}
            question={question}
            value={answers[question.id]}
          />
        ))}
      </div>
    </section>
  ))}
</div>
```

For forms without sections, create one implicit section:

```text
Section title:
Feedback

Questions:
All questions in order
```

This allows the application to support both simple and advanced forms.

---

# L.5 Add helper text to questions

Some questions need clarification.

Example:

```text
Question:
How useful was this session?

Helper text:
Consider how useful the content will be in your day-to-day work.
```

This reduces ambiguity without making the question title overly long.

Add a nullable helper text column.

### `prisma/schema.prisma`

```prisma
model Question {
  id            String       @id @default(uuid()) @db.Uuid
  formVersionId String       @map("form_version_id") @db.Uuid
  orderIndex    Int          @map("order_index")
  questionText  String       @map("question_text") @db.Text
  helperText    String?      @map("helper_text") @db.Text
  questionType  QuestionType @map("question_type")
  isRequired    Boolean      @default(false) @map("is_required")
  settings      Json         @default("{}")
  options       Json         @default("[]")

  // Existing relationships remain unchanged.
}
```

Create the migration:

```bash
npx prisma migrate dev --name add_question_helper_text
```

Render the helper text:

### `src/components/participant/question-input.tsx`

```tsx
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

      {question.helperText ? (
        <p className="mt-2 text-sm leading-6 text-slate-600">
          {question.helperText}
        </p>
      ) : null}
    </div>
  );
}
```

---

# L.6 Conditional question logic

Conditional logic determines whether a question is visible based on an earlier answer.

Example:

```text
Question 1:
How would you rate this session?
Type: Rating

Question 2:
What could we improve?
Type: Text

Display Question 2 only when:
Question 1 score is 1 or 2
```

This can improve feedback quality because participants only see follow-up questions relevant to their experience.

---

## L.7 Recommended scope for conditional logic

Start with simple rules.

Recommended first version:

```text
One condition per question
One source question
Equals / does not equal / includes / numeric less-than-or-equal
```

Examples:

```text
Show “What could we improve?”
when rating <= 2

Show “Which topic should we cover next?”
when choice = "Other"

Show “What made the session valuable?”
when NPS >= 9
```

Avoid initially supporting:

```text
Nested condition groups
AND / OR trees with many levels
Cross-section hidden dependencies
Rules based on calculated metrics
Rules based on external data
```

These features increase authoring complexity and make testing more difficult.

---

## L.8 Conditional logic schema

Store visibility rules as JSON on a question.

### `prisma/schema.prisma`

```prisma
model Question {
  id               String       @id @default(uuid()) @db.Uuid
  formVersionId    String       @map("form_version_id") @db.Uuid
  orderIndex       Int          @map("order_index")
  questionText     String       @map("question_text") @db.Text
  questionType     QuestionType @map("question_type")
  isRequired       Boolean      @default(false) @map("is_required")
  settings         Json         @default("{}")
  options          Json         @default("[]")

  // Null means the question is always visible.
  visibilityRule   Json?        @map("visibility_rule")

  formVersion      FormVersion  @relation(fields: [formVersionId], references: [id], onDelete: Cascade)
  answers          Answer[]

  @@unique([formVersionId, orderIndex])
  @@index([formVersionId])
  @@map("questions")
}
```

A rule could look like this:

```json
{
  "sourceQuestionId": "a508ec72-8f2c-40ad-b1e3-47e2c33bea03",
  "operator": "LESS_THAN_OR_EQUAL",
  "value": 2
}
```

For a choice answer:

```json
{
  "sourceQuestionId": "10a2cf74-a8aa-45a4-b7b2-d157f11d2c35",
  "operator": "EQUALS",
  "value": "Other"
}
```

---

## L.9 Validate visibility rules

Do not trust authoring input blindly.

Create a validation schema.

### `src/lib/visibility-rules.ts`

```ts
import { z } from "zod";

export const visibilityOperatorSchema = z.enum([
  "EQUALS",
  "NOT_EQUALS",
  "LESS_THAN_OR_EQUAL",
  "GREATER_THAN_OR_EQUAL",
]);

export const visibilityRuleSchema = z.object({
  sourceQuestionId: z.string().uuid(),
  operator: visibilityOperatorSchema,
  value: z.union([z.string().trim().max(5000), z.number().int()]),
});

export type VisibilityRule = z.infer<typeof visibilityRuleSchema>;

export function parseVisibilityRule(value: unknown): VisibilityRule | null {
  if (!value) {
    return null;
  }

  const result = visibilityRuleSchema.safeParse(value);

  return result.success ? result.data : null;
}
```

The authoring server action should confirm:

```text
[ ] Source question belongs to same form version.
[ ] Source question appears earlier in order.
[ ] Numeric operators are used only with Rating or NPS source questions.
[ ] String operators are used only with Choice source questions.
[ ] The rule value is valid for the source question.
```

---

## L.10 Evaluate visibility on the participant form

Create a visibility evaluation helper.

### `src/lib/evaluate-visibility.ts`

```ts
import type { ParticipantAnswerValue } from "@/lib/participant-draft";
import type { VisibilityRule } from "@/lib/visibility-rules";

export function isQuestionVisible(
  rule: VisibilityRule | null,
  answers: Record<string, ParticipantAnswerValue>,
): boolean {
  if (!rule) {
    return true;
  }

  const sourceAnswer = answers[rule.sourceQuestionId];

  /**
   * Keep a dependent question hidden until its source question has an answer.
   */
  if (sourceAnswer === undefined) {
    return false;
  }

  switch (rule.operator) {
    case "EQUALS":
      return sourceAnswer === rule.value;

    case "NOT_EQUALS":
      return sourceAnswer !== rule.value;

    case "LESS_THAN_OR_EQUAL":
      return (
        typeof sourceAnswer === "number" &&
        typeof rule.value === "number" &&
        sourceAnswer <= rule.value
      );

    case "GREATER_THAN_OR_EQUAL":
      return (
        typeof sourceAnswer === "number" &&
        typeof rule.value === "number" &&
        sourceAnswer >= rule.value
      );
  }
}
```

Use it in the feedback form:

### `src/components/participant/feedback-form.tsx`

```tsx
const visibleQuestions = questions.filter((question) =>
  isQuestionVisible(question.visibilityRule, answers),
);
```

Then render:

```tsx
<div className="space-y-5">
  {visibleQuestions.map((question) => (
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
```

---

## L.11 Validate only visible required questions

Conditional questions create an important validation rule.

This is incorrect:

```text
Require every required question,
even if the participant never saw it.
```

This is correct:

```text
Require only required questions that are currently visible.
```

Update client validation:

### `src/components/participant/feedback-form.tsx`

```tsx
function validateForm(): ValidationErrors {
  const nextErrors: ValidationErrors = {};

  for (const question of questions) {
    const visible = isQuestionVisible(question.visibilityRule, answers);

    if (
      visible &&
      question.isRequired &&
      !isAnswered(answers[question.id])
    ) {
      nextErrors[question.id] = "This question requires an answer.";
    }
  }

  return nextErrors;
}
```

The server API must also evaluate the same visibility rules. Browser validation improves experience; server validation provides security and correctness.

---

## L.12 Clear hidden answers

Suppose a participant answers:

```text
How would you rate this session?
1

What could we improve?
More practical examples.
```

Then changes the rating to:

```text
5
```

The improvement question becomes hidden.

You must decide whether to keep or clear its answer.

Recommended behavior:

```text
Clear the hidden answer.
```

Why?

The participant may no longer intend to submit it, and the final form state should match the visible form.

Example helper:

```tsx
function removeHiddenAnswers(
  currentAnswers: Record<string, ParticipantAnswerValue>,
  questions: ParticipantQuestion[],
): Record<string, ParticipantAnswerValue> {
  const nextAnswers = { ...currentAnswers };

  for (const question of questions) {
    if (!isQuestionVisible(question.visibilityRule, nextAnswers)) {
      delete nextAnswers[question.id];
    }
  }

  return nextAnswers;
}
```

After updating a source answer:

```tsx
setAnswers((currentAnswers) => {
  const updatedAnswers = {
    ...currentAnswers,
    [questionId]: value,
  };

  const cleanedAnswers = removeHiddenAnswers(updatedAnswers, questions);

  saveParticipantDraft(
    sessionId,
    formVersionId,
    cleanedAnswers,
    getOrCreateSubmissionId(),
  );

  return cleanedAnswers;
});
```

---

# L.13 Add an “Other” choice option

Choice questions often need an option that is not known in advance.

Example:

```text
Which topic was most valuable?

- Server Components
- Data Fetching
- Performance
- Other
```

If the participant selects `Other`, show a text field:

```text
Please describe the topic:
```

The safest model is not to treat `Other` as a normal unvalidated arbitrary choice.

Instead:

```text
Choice question:
"What topic was most valuable?"
Answer:
"Other"

Follow-up text question:
"Please describe the other topic."
Visible when:
Choice answer = "Other"
```

This preserves clean choice analytics:

```text
Server Components: 34
Data Fetching: 22
Performance: 18
Other: 7
```

while retaining the detail in a separate text question.

---

# L.14 Add a question library

A question library is different from a full form template.

A template provides an entire starting form:

```text
Standard Workshop Feedback
```

A question library provides individual approved questions that administrators can add one at a time.

Example library categories:

```text
Overall satisfaction
Instructor quality
Course pacing
Practical usefulness
Facilities
Accessibility
Recommendation
Open-ended improvement
```

This helps organizations maintain consistency across sessions.

---

## L.15 Question library schema

### `prisma/schema.prisma`

```prisma
model QuestionLibraryItem {
  id           String       @id @default(uuid()) @db.Uuid
  category     String?      @db.VarChar(100)
  label        String       @db.VarChar(255)
  questionText String       @map("question_text") @db.Text
  questionType QuestionType @map("question_type")
  isRequired   Boolean      @default(false) @map("is_required")
  settings     Json         @default("{}")
  options      Json         @default("[]")
  createdAt    DateTime     @default(now()) @map("created_at")
  updatedAt    DateTime     @updatedAt @map("updated_at")

  @@index([category])
  @@map("question_library_items")
}
```

For a multi-organization product, attach each library item to an organization:

```prisma
organizationId String @map("organization_id") @db.Uuid
```

---

## L.16 Example question library entries

```text
Category: Overall Satisfaction
Label: Session usefulness
Question: How useful was this session?
Type: Rating
Scale: 1–5
Required: Yes

Category: Recommendation
Label: Session recommendation
Question: How likely are you to recommend this session to a colleague?
Type: NPS
Scale: 0–10
Required: Yes

Category: Instructor Quality
Label: Instructor clarity
Question: How clear was the instructor’s explanation?
Type: Rating
Scale: 1–5
Required: Yes

Category: Course Design
Label: Session pace
Question: Was the pace of this session appropriate?
Type: Choice
Options:
- Too slow
- About right
- Too fast
Required: Yes

Category: Improvement
Label: Improvement suggestion
Question: What is one thing we should improve?
Type: Text
Required: No
```

---

# L.17 Add reporting tags

A reporting tag helps group similar questions across different sessions.

For example, two sessions may use slightly different wording:

```text
How clear was the workshop?
How clear was the course module?
```

Both can share a reporting tag:

```text
INSTRUCTOR_CLARITY
```

Another example:

```text
How useful was this workshop?
How useful was this module?
```

Both can use:

```text
CONTENT_USEFULNESS
```

This allows higher-level reports across multiple sessions.

---

## L.18 Reporting tag schema

Add an optional tag:

### `prisma/schema.prisma`

```prisma
model Question {
  // Existing fields remain unchanged.

  reportingTag String? @map("reporting_tag") @db.VarChar(100)

  @@index([reportingTag])
}
```

Example values:

```text
OVERALL_SATISFACTION
CONTENT_USEFULNESS
INSTRUCTOR_CLARITY
SESSION_PACE
PRACTICAL_APPLICATION
RECOMMENDATION
VENUE_QUALITY
MATERIAL_QUALITY
```

Important rule:

> Reporting tags should group only genuinely comparable questions.

Do not group these under one tag:

```text
How useful was the workshop?
How engaging was the speaker?
```

Both may be positive experience measures, but they are not the same metric.

---

# L.19 Publishing validation for advanced forms

Before publishing a form with sections and conditional rules, validate:

```text
[ ] At least one question exists.
[ ] Every choice question has at least two options.
[ ] Every visibility rule references a question in the same version.
[ ] A source question appears before its dependent question.
[ ] No visibility rule references itself.
[ ] No circular dependency exists.
[ ] Required conditional questions are validated only when visible.
[ ] Question sections have valid order indexes.
[ ] Every question belongs to a valid section or the default section.
```

A circular dependency looks like this:

```text
Question A visible when Question B = Yes
Question B visible when Question A = Yes
```

Neither question can become visible. Reject this configuration during authoring.

---

# L.20 Advanced authoring acceptance checklist

Before enabling advanced form features in production:

```text
[ ] Existing published forms remain unchanged.
[ ] Draft forms can use new sections and rules.
[ ] Participant forms render sections correctly on mobile.
[ ] Conditional questions appear and disappear correctly.
[ ] Hidden conditional answers are removed.
[ ] Server validation matches client visibility rules.
[ ] Required hidden questions do not block submission.
[ ] CSV exports preserve form-version context.
[ ] PDF reports remain readable with sectioned forms.
[ ] Form versioning captures all advanced settings.
[ ] Authoring UI clearly explains conditional rules.
[ ] Administrators can preview the exact published participant experience.
```

Advanced authoring can make GreyMatter Feedback more expressive, but the best forms remain focused. Use sections for clarity, conditional questions for relevant follow-up, templates for consistency, and versioning for historical accuracy.
