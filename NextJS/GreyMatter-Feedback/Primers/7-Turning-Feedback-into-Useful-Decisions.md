# Primer 7: Turning Feedback into Useful Decisions

Collecting feedback is only the first half of the job.

The real purpose of GreyMatter Feedback is to help organizers answer questions such as:

```text
Did participants find the session useful?
Was the session clear?
Would participants recommend it?
Which topic was most valuable?
What should change next time?
```

This primer explains how GreyMatter Feedback turns individual participant answers into analytics, CSV exports, and PDF reports.

---

## 1. Raw Feedback vs Analytics

A participant submission is raw data.

For example:

```text
Participant 1
Usefulness rating: 5
NPS: 9
Most valuable topic: Server Components
Comment: More hands-on time would help.

Participant 2
Usefulness rating: 4
NPS: 8
Most valuable topic: Data fetching patterns
Comment: Clear examples.
```

Raw data is useful, but it is difficult to interpret when there are many responses.

Analytics summarizes raw data:

```text
Total responses: 142
Average usefulness rating: 4.6 / 5
NPS: +68
Most selected topic: Server Components
Common improvement request: More hands-on exercises
```

GreyMatter Feedback stores raw answers in Neon, then calculates analytics from those records.

---

## 2. The Analytics Data Flow

The reporting flow looks like this:

```text
Participant submits feedback
        ↓
Response and answers saved in Neon
        ↓
Admin dashboard loads responses and answers
        ↓
Analytics helper calculates metrics
        ↓
Dashboard displays results
        ↓
Administrator exports CSV or requests PDF
```

The important principle is:

> Reports are generated from authoritative stored response data.

GreyMatter Feedback does not treat browser state as the source of truth. Once a response is processed, Neon becomes the source of truth.

---

## 3. Total Response Count

The simplest metric is total responses.

```text
Total responses = number of Response records for a session
```

Example:

```text
Session: Advanced React Patterns
Responses: 142
```

This helps organizers understand participation.

However, response count alone does not indicate quality.

For example:

```text
142 responses
Average rating: 2.1 / 5
```

is very different from:

```text
142 responses
Average rating: 4.8 / 5
```

---

## 4. Rating Averages

A rating average summarizes numeric rating answers.

Example answers:

```text
5, 4, 5, 3, 4
```

Calculation:

```text
(5 + 4 + 5 + 3 + 4) / 5 = 4.2
```

GreyMatter Feedback displays:

```text
Average rating: 4.2 / 5
```

The helper concept is:

```ts
export function calculateAverage(values: number[]): number | null {
  if (values.length === 0) {
    return null;
  }

  return values.reduce((sum, value) => sum + value, 0) / values.length;
}
```

If no one answered the question, the result is:

```text
No responses
```

rather than:

```text
0
```

A score of `0` would incorrectly suggest people gave a very low rating.

---

## 5. Rating Distributions

An average is useful, but it can hide important differences.

Consider these two sets of 1–5 ratings.

### Example A

```text
4, 4, 4, 4, 4
Average: 4.0
```

### Example B

```text
1, 1, 4, 5, 5, 4
Average: 3.3
```

Now consider:

### Example C

```text
1, 5, 5, 5, 4
Average: 4.0
```

Example A and Example C have the same average, but Example C includes one very dissatisfied participant.

That is why GreyMatter Feedback shows score distributions.

```text
How useful was this workshop?

Score 1: 1
Score 2: 0
Score 3: 3
Score 4: 28
Score 5: 110
```

This lets organizers see whether feedback is:

```text
Consistently positive
Mixed
Polarized
Mostly neutral
```

---

## 6. Net Promoter Score

**Net Promoter Score**, or NPS, measures recommendation likelihood.

Participants answer from `0` to `10`.

```text
How likely are you to recommend this session to a colleague?
```

GreyMatter Feedback groups responses into three categories.

| Score range | Group | Meaning |
|---:|---|---|
| 9–10 | Promoters | Highly likely to recommend |
| 7–8 | Passives | Generally satisfied but not strongly enthusiastic |
| 0–6 | Detractors | Unlikely to recommend |

The formula is:

```text
NPS = percentage of promoters - percentage of detractors
```

NPS ranges from:

```text
-100 to +100
```

---

## 7. NPS Calculation Example

Imagine 10 participants answer an NPS question.

```text
10, 9, 9, 8, 8, 7, 6, 5, 4, 0
```

Group the scores:

```text
Promoters:
10, 9, 9
Count: 3

Passives:
8, 8, 7
Count: 3

Detractors:
6, 5, 4, 0
Count: 4
```

Calculate percentages:

```text
Promoters:
3 / 10 = 30%

Detractors:
4 / 10 = 40%
```

Calculate NPS:

```text
30 - 40 = -10
```

Result:

```text
NPS: -10
```

A negative score does not automatically mean the session failed. It means organizers should investigate the underlying feedback and context.

---

## 8. Interpreting NPS Carefully

NPS is useful, but it should not become the only metric.

For example:

```text
NPS: +70
```

is encouraging, but organizers should still inspect:

```text
Response count
Rating averages
Written feedback
Choice distributions
Different form versions
Session context
```

A small sample can be misleading.

```text
Two responses:
10 and 10

NPS:
+100
```

That result is mathematically correct, but it does not represent a large audience.

Always show NPS alongside response count.

---

## 9. Choice Question Analytics

Choice questions help identify preferences and priorities.

Example:

```text
Which topic was most valuable?

- Server Components
- Data fetching patterns
- Performance optimization
- Testing strategies
```

Responses might produce:

```text
Server Components: 54
Data fetching patterns: 31
Performance optimization: 22
Testing strategies: 15
```

This can guide future sessions.

For example:

```text
Most participants selected Server Components.
Action:
Keep this topic prominent in future workshops.
```

Or:

```text
Few participants selected Testing strategies.
Action:
Review whether the section needs better framing, more time, or removal.
```

Choice counts are descriptive, not automatically causal. They show what participants selected, not necessarily why.

---

## 10. Written Feedback

Text responses provide detail that numeric scores cannot capture.

Example question:

```text
What should we improve for the next workshop?
```

Possible answers:

```text
More time for hands-on exercises.

The caching section moved too quickly.

Please share the sample repository afterward.
```

Written comments often explain rating patterns.

For example:

```text
Average rating: 3.8 / 5

Common comments:
- Too much content for one session.
- Exercises needed more time.
- Examples were useful but rushed.
```

The action may become:

```text
Reduce topic scope.
Add 20 minutes for exercises.
Share reference material before the workshop.
```

---

## 11. Treat Text Feedback Carefully

Written feedback can be valuable, but it may also include:

```text
Personal names
Sensitive information
Unfair criticism
Strong language
Private operational details
```

Administrators should:

```text
Read comments respectfully.
Avoid publishing raw comments publicly without review.
Avoid attempting to identify anonymous participants.
Focus on recurring themes, not one isolated comment.
Follow data retention policy.
```

GreyMatter Feedback renders comments as escaped plain text so participant input is not executed as HTML or JavaScript.

---

## 12. Form Version Context in Analytics

A session may use more than one form version over time.

Example:

```text
Version 1:
How useful was this workshop?

Version 2:
How useful were the hands-on exercises?
```

These answers should not be combined as if they measured the same thing.

GreyMatter Feedback groups analytics by:

```text
Question ID
Form version number
Question wording
Question type
```

The dashboard can show:

```text
Form version 1
How useful was this workshop?
Average: 4.3 / 5
Responses: 50

Form version 2
How useful were the hands-on exercises?
Average: 4.7 / 5
Responses: 42
```

This preserves historical meaning.

---

## 13. Why CSV Exports Use One Answer Per Row

GreyMatter Feedback exports CSV in a flexible “long” format.

Example:

```csv
"Session ID","Response ID","Form Version","Question","Question Type","Numeric Value","Text Value"
"REACT-2026-Q3","response-1","1","How useful was this workshop?","RATING","5",""
"REACT-2026-Q3","response-1","1","What should we improve?","TEXT","","More exercise time."
```

Each row represents one answer.

This structure works well because:

```text
Different forms have different questions.
Questions can change across form versions.
Some answers are numeric.
Some answers are text.
Some questions are optional.
```

A spreadsheet can later transform this format into a wide table or pivot report if needed.

---

## 14. CSV Export Use Cases

CSV exports are useful for:

```text
Custom analysis in Excel or Google Sheets
Importing into business intelligence tools
Archiving raw response data
Sharing data with analysts
Comparing sessions
Building custom charts
```

Example spreadsheet analysis:

```text
Question:
How useful was this workshop?

Average:
4.6

Minimum:
2

Maximum:
5

Number of answers:
142
```

For choice questions, a spreadsheet pivot table can show:

```text
Server Components: 54
Data fetching: 31
Performance: 22
Testing: 15
```

---

## 15. PDF Executive Reports

CSV exports contain raw answer-level data.

PDF reports contain an executive summary.

A PDF report is useful when an organizer needs a readable document for:

```text
Leadership review
Course review meeting
Client summary
Post-event debrief
Project archive
Email attachment
```

A GreyMatter Feedback PDF report includes:

```text
Event and session title
Report generation date
Total responses
Average rating
NPS
Rating distributions
NPS distributions
Choice distributions
Written feedback
```

The PDF should answer:

```text
What happened?
What worked?
What should improve?
What evidence supports those conclusions?
```

---

## 16. Why PDF Reports Are Asynchronous

PDF rendering is heavier than displaying a web page.

The system may need to:

```text
Load many responses
Calculate analytics
Render page layout
Render text comments
Create PDF binary data
Upload PDF to storage
Update report status
```

The admin browser should not wait for all of this inside one request.

Instead:

```text
Admin clicks Generate PDF report
        ↓
Report record becomes QUEUED
        ↓
Inngest worker starts
        ↓
Report becomes PROCESSING
        ↓
PDF is generated and stored
        ↓
Report becomes COMPLETE
        ↓
Admin downloads PDF
```

This is more reliable and avoids browser request timeouts.

---

## 17. Report Statuses

GreyMatter Feedback uses four report states.

| Status | Meaning |
|---|---|
| `QUEUED` | Report was requested and is waiting for worker processing |
| `PROCESSING` | Worker is generating and storing the PDF |
| `COMPLETE` | PDF is ready and has a download URL |
| `FAILED` | Something went wrong; error details are recorded safely |

Example administrator experience:

```text
PDF executive report

[ Generate PDF report ]

Latest report:
PROCESSING
Requested July 25, 2026, 10:45 AM
```

Later:

```text
Latest report:
COMPLETE
[ Download PDF ]
```

---

## 18. Reporting Should Lead to Action

Analytics are not the final goal.

A useful review process is:

```text
Observe metric
        ↓
Understand likely cause
        ↓
Identify improvement action
        ↓
Assign owner
        ↓
Review result in future feedback
```

Example:

```text
Observation:
Workshop pace average: 2.8 / 5

Written comments:
- Too fast after lunch.
- Needed more time for exercises.
- Caching explanation moved quickly.

Action:
Add 30 minutes to the workshop.
Move caching to a separate follow-up session.
Add a guided exercise after each topic.

Owner:
Training team

Review:
Compare next session results.
```

---

## 19. Avoid Overreacting to One Metric

One metric can be misleading.

Examples:

```text
High average rating
but low response count

High NPS
but many critical written comments

Low score
but response occurred during a technical outage

Different score
because form wording changed between versions
```

Use several signals together:

```text
Response count
Rating averages
Score distributions
NPS
Choice answers
Written comments
Session context
Form version
```

A good dashboard supports judgment. It does not replace it.

---

## 20. Primer Summary

GreyMatter Feedback turns answers into useful reporting through this flow:

```text
Responses and answers in Neon
        ↓
Analytics calculations
        ↓
Dashboard metrics and distributions
        ↓
CSV export for detailed analysis
        ↓
Asynchronous PDF report for executive summary
```

The key reporting concepts are:

```text
Average
  = summary of numeric rating answers

Distribution
  = count for each possible score or option

NPS
  = promoters minus detractors

CSV
  = detailed answer-level export

PDF report
  = printable executive summary

Form version context
  = preserves historical meaning

Written feedback
  = explanation and improvement detail
```

The goal is not merely to collect scores. The goal is to turn participant feedback into informed, measurable improvements for future events and courses.
