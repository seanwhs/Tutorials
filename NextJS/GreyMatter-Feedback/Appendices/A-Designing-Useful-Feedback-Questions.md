# Appendix A: Designing Useful Feedback Questions

A feedback platform is only as useful as the questions it asks. Good questions produce clear, actionable answers. Weak questions produce vague responses that are difficult to analyze.

This appendix helps administrators create effective questions in GreyMatter Feedback.

---

## A.1 Start with the decision you need to make

Before adding a question, ask:

> “What decision will we make differently depending on the answer?”

For example:

```text
Weak question:
Did you like the workshop?

Better question:
How useful were the hands-on exercises in helping you understand the topic?
```

The first question is broad. A low score does not explain what should change.

The second question identifies a specific part of the experience: hands-on exercises. If scores are low, the organizer has a clearer improvement path.

---

## A.2 Match the question type to the answer you need

GreyMatter Feedback supports four question types.

| Type | Best for | Example |
|---|---|---|
| Rating | Measuring quality or satisfaction | “How clear was the instructor’s explanation?” |
| NPS | Measuring willingness to recommend | “How likely are you to recommend this course to a colleague?” |
| Choice | Identifying a preference or priority | “Which section was most valuable?” |
| Text | Collecting context and suggestions | “What is one improvement we should make?” |

### Rating question example

```text
Question type: Rating
Question: How clear was the explanation of TypeScript generics?
Scale: 1–5
Minimum label: Not clear
Maximum label: Extremely clear
Required: Yes
```

Use rating questions when you want a measurable score that can be averaged and compared over time.

### NPS question example

```text
Question type: NPS
Question: How likely are you to recommend this workshop to a colleague?
Scale: 0–10
Minimum label: Not at all likely
Maximum label: Extremely likely
Required: Yes
```

Use NPS sparingly. Usually, one NPS question per session or course is enough.

### Choice question example

```text
Question type: Choice
Question: Which part of the workshop was most valuable?
Options:
- Live demonstration
- Hands-on exercises
- Group discussion
- Reference materials
Required: No
```

Use choice questions when you need respondents to select from known categories.

### Text question example

```text
Question type: Text
Question: What is one thing we should improve before the next session?
Maximum length: 1,500
Required: No
```

Use text questions to capture details that structured questions cannot predict.

---

## A.3 Recommended question sets

## Short workshop feedback form

Use this when participants have limited time, such as immediately after a 30–90 minute session.

```text
1. How useful was this workshop?
   Type: Rating
   Scale: 1–5
   Required: Yes

2. How likely are you to recommend this workshop to a colleague?
   Type: NPS
   Scale: 0–10
   Required: Yes

3. What was the most valuable part of the workshop?
   Type: Text
   Required: No

4. What is one thing we should improve?
   Type: Text
   Required: No
```

## Course module feedback form

Use this after one lesson or module in a longer course.

```text
1. How clear was this module?
   Type: Rating
   Scale: 1–5
   Required: Yes

2. How useful were the examples and exercises?
   Type: Rating
   Scale: 1–5
   Required: Yes

3. Was the pace of the module appropriate?
   Type: Choice
   Options:
   - Too slow
   - About right
   - Too fast
   Required: Yes

4. Which topic needs more explanation?
   Type: Choice
   Options:
   - Core concepts
   - Practical examples
   - Exercises
   - Advanced topics
   Required: No

5. What should we improve for the next module?
   Type: Text
   Required: No
```

## End-of-course evaluation form

Use this after a full program, course, or multi-session event.

```text
1. How would you rate the course overall?
   Type: Rating
   Scale: 1–5
   Required: Yes

2. How would you rate the instructor’s clarity?
   Type: Rating
   Scale: 1–5
   Required: Yes

3. How would you rate the practical usefulness of the course?
   Type: Rating
   Scale: 1–5
   Required: Yes

4. How likely are you to recommend this course to a colleague?
   Type: NPS
   Scale: 0–10
   Required: Yes

5. Which element was most valuable?
   Type: Choice
   Options:
   - Instructor explanations
   - Practical exercises
   - Course materials
   - Discussions with other participants
   Required: No

6. What should we keep doing?
   Type: Text
   Required: No

7. What should we improve next time?
   Type: Text
   Required: No
```

---

## A.4 Examples of weak and improved questions

| Avoid | Prefer | Why |
|---|---|---|
| “Was it good?” | “How useful was the hands-on exercise?” | Identifies the subject being rated |
| “Did you understand?” | “How clear was the explanation of async/await?” | Identifies the topic |
| “What did you think?” | “What is one thing we should improve?” | Requests actionable feedback |
| “Was the speaker nice?” | “How clear and well-paced was the presentation?” | Focuses on event quality, not personality |
| “Would you come again?” | “How likely are you to recommend this session to a colleague?” | Uses a standard recommendation measure |
| “Which was best?” | “Which section was most valuable for your work?” | Defines “best” in a useful way |

---

## A.5 Keep forms short

Every extra question increases the chance that participants abandon the form.

A practical rule:

| Situation | Recommended question count |
|---|---:|
| Short talk or presentation | 3–5 |
| Workshop | 4–7 |
| Course module | 4–8 |
| End-of-course evaluation | 6–12 |
| Long conference survey | 8–15 |

For QR-code feedback, aim for completion in under two minutes whenever possible.

A short form often produces more responses and better-quality answers than a long form.

---

## A.6 Avoid double-barreled questions

A **double-barreled question** asks about two separate things but permits only one answer.

Avoid:

```text
How clear and engaging was the instructor?
```

A participant may think the instructor was clear but not engaging. A single 1–5 answer cannot represent both opinions.

Prefer two separate questions:

```text
How clear was the instructor’s explanation?

How engaging was the instructor’s delivery?
```

---

## A.7 Use neutral wording

Questions should not pressure participants into a positive answer.

Avoid:

```text
How excellent was this workshop?
```

Prefer:

```text
How would you rate this workshop?
```

Avoid:

```text
What did you love most about the course?
```

Prefer:

```text
What was the most valuable part of the course?
```

Neutral wording produces more trustworthy feedback.

---

## A.8 Use required questions carefully

Required questions improve response completeness, but too many required fields can frustrate participants.

A good default is:

```text
Required:
- Overall rating
- NPS or recommendation score
- One key quality measure

Optional:
- Choice questions
- Written comments
- Demographic or contextual questions
```

Written feedback should usually be optional. Participants may have nothing to add, may be short on time, or may not wish to provide detailed comments.

---

## A.9 Preserve published questions

Once a form receives responses, do not edit the published version.

Instead:

```text
Published Version 1
   ↓
Create Draft Version 2
   ↓
Make changes in Version 2
   ↓
Publish Version 2 when appropriate
```

This is why GreyMatter Feedback uses form versioning. It preserves the exact wording, options, scales, and ordering that participants saw when they submitted their responses.

For example, these must be treated as different historical questions:

```text
Version 1:
How clear was the instructor?

Version 2:
How useful were the hands-on exercises?
```

Even if both questions use a 1–5 rating scale, they measure different things.

---

## A.10 A practical default form

If an administrator does not know where to start, use this five-question template:

```text
1. How useful was this session?
   Type: Rating
   Scale: 1–5
   Required: Yes

2. How clear was the content?
   Type: Rating
   Scale: 1–5
   Required: Yes

3. How likely are you to recommend this session to a colleague?
   Type: NPS
   Scale: 0–10
   Required: Yes

4. Which part was most valuable?
   Type: Text
   Required: No

5. What is one improvement we should make?
   Type: Text
   Required: No
```

This form gives administrators:

- An overall usefulness measure.
- A content clarity measure.
- A standardized recommendation score.
- Positive qualitative insight.
- Actionable improvement feedback.
