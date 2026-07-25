# GreyMatter Feedback User Manual

## 1. Overview

GreyMatter Feedback is a QR-code feedback platform for events, courses, workshops, talks, training programs, and meetings.

It supports two user groups:

- **Participants** scan a QR code, complete a feedback form, and submit their answers.
- **Administrators** create events, create sessions, build forms, publish QR links, review analytics, export CSV data, and generate PDF reports.

---

# Part A — Participant User Guide

## 2. Submitting Feedback

### 2.1 Open the feedback form

You can access a feedback form in either of these ways:

1. Scan the event QR code using your phone camera.
2. Type the displayed web address into a browser.

A typical feedback URL looks like this:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

After opening the link, you should see:

```text
Event name
Session title
Feedback questions
Submit feedback button
```

Example:

```text
React Summit 2026
Advanced React Patterns

How useful was this workshop?
```

---

## 3. Answering Questions

GreyMatter Feedback supports several question types.

### 3.1 Rating questions

Rating questions ask you to select a number from a configured scale.

Example:

```text
How useful was this workshop?

1  2  3  4  5

Not useful                    Extremely useful
```

Tap one number to select your rating.

Your selected answer is highlighted.

---

### 3.2 Recommendation questions

Recommendation questions use a score from `0` to `10`.

Example:

```text
How likely are you to recommend this workshop to a colleague?

0 1 2 3 4 5 6 7 8 9 10

Not at all likely                  Extremely likely
```

Tap the score that best represents your answer.

---

### 3.3 Choice questions

Choice questions ask you to select one option.

Example:

```text
Which topic was most valuable?

○ Server Components
○ Data fetching patterns
○ Performance optimization
○ Testing strategies
```

Tap an option to select it.

---

### 3.4 Written feedback questions

Written feedback questions let you provide a comment.

Example:

```text
What should we improve for the next workshop?
```

Write your response in the text area.

A character counter may appear below the field:

```text
128 / 1500
```

This means you have entered 128 characters out of a maximum of 1,500.

---

## 4. Required and Optional Questions

Questions are labeled as either:

```text
Required
```

or:

```text
Optional
```

Required questions must be answered before you can submit the form.

If you attempt to submit without answering a required question, GreyMatter Feedback shows a message such as:

```text
This question requires an answer.
```

The page will move to the first question that needs attention.

---

## 5. Draft Recovery

GreyMatter Feedback saves unfinished answers in your browser.

If you accidentally:

```text
Refresh the page
Close the browser
Switch apps
Lose temporary connectivity
```

you may see this message when returning:

```text
Draft restored.
Your previous answers were recovered from this browser.
```

Your draft is stored only on the current device and browser.

### Discarding a draft

If you want to clear unfinished answers, select:

```text
Discard draft
```

This removes the saved answers from your current browser.

---

## 6. Submitting Feedback

After answering the required questions, select:

```text
Submit feedback
```

During submission, the button changes to:

```text
Submitting feedback…
```

If successful, you will see:

```text
Feedback received

Thank you for your feedback.

Your response was accepted and is being processed securely.
```

At this point, your browser draft is removed.

---

## 7. Offline or Connection Problems

If your device cannot reach the feedback service, GreyMatter Feedback keeps your completed information locally when possible.

You may see a message such as:

```text
Your device is offline. Your completed feedback was saved securely on this device and will retry automatically when you reconnect.
```

To improve the chance of successful submission:

1. Keep the browser page open.
2. Reconnect to Wi-Fi or mobile data.
3. Return to the form if necessary.
4. Refresh only after connectivity has returned.

Your submission uses a stable identifier, so retrying should not create duplicate responses.

---

## 8. Participant Privacy

Participants do not need an account in the standard GreyMatter Feedback flow.

The application is designed to avoid storing raw IP addresses. It uses a privacy-aware hashed identifier for anti-spam and rate-limiting purposes.

Do not include sensitive personal information in written comments unless the event organizer has explicitly requested it and provided appropriate privacy information.

Avoid including:

```text
Passwords
Payment information
Health details
Personal addresses
Private customer data
Confidential business information
```

---

# Part B — Administrator User Guide

## 9. Sign In

Open the administrator sign-in page:

```text
https://feedback.example.com/admin/login
```

Enter the administrator password and select:

```text
Sign in
```

After successful sign-in, you will be redirected to:

```text
/admin/events
```

This is the **Events and Courses** page.

To sign out, select:

```text
Sign out
```

from the administrator navigation bar.

---

## 10. Create an Event or Course

An **event** is the parent container for one or more sessions.

An event can represent:

```text
Conference
Course
Training program
Workshop series
Company event
Department meeting series
```

### Create an event

1. Open:

   ```text
   /admin/events
   ```

2. Select:

   ```text
   Create event or course
   ```

3. Enter a title.

Example:

```text
TypeScript Foundations
```

4. Select:

```text
Create event or course
```

You will be taken to the event management page.

---

## 11. Create a Session

A **session** is the individual feedback target that receives its own QR code and form.

Examples:

```text
Module 1 — Type Basics
Opening Keynote
Advanced React Patterns
End-of-course Evaluation
```

### Create a session

1. Open the event or course.
2. Find the **Create a session** section.
3. Enter:

   ```text
   Session title
   ```

4. Enter a QR-friendly session ID.

Example:

```text
TYPESCRIPT-MODULE-1
```

Session IDs should use:

```text
Uppercase letters
Numbers
Hyphens
```

Good examples:

```text
REACT-2026-Q3
TYPESCRIPT-MODULE-1
LEADERSHIP-WEEK-2
```

Avoid:

```text
Session 1
React/Workshop
my session
```

5. Select:

```text
Create session
```

You will be redirected to the form editor.

---

## 12. Understand the Form Lifecycle

Each session can have multiple form versions.

| Status | Meaning |
|---|---|
| `DRAFT` | Editable form version; participants cannot see it |
| `PUBLISHED` | Live participant form version |
| `ARCHIVED` | Historical version retained for reporting |

A session can have one active published form version at a time.

Example:

```text
Version 1 — Archived
Version 2 — Published
Version 3 — Draft
```

### Important rule

Do not edit a form version after publishing it.

Instead:

```text
Create a new draft version
        ↓
Make changes
        ↓
Publish new version
```

This keeps old reports accurate.

---

## 13. Create a Draft Form

If a session has no form yet:

1. Open:

   ```text
   /admin/sessions/YOUR-SESSION-ID/edit
   ```

2. Select:

   ```text
   Create draft form version
   ```

A new editable draft appears.

If the session already has a published form, creating a new draft copies the latest version into a new editable version.

This lets you make changes safely.

---

## 14. Add a Question

Inside the draft form section, select:

```text
Add a question
```

Complete the following settings.

### 14.1 Question prompt

Enter the question participants will see.

Example:

```text
How useful was this session?
```

Use clear, specific, neutral wording.

Good:

```text
How clear was the explanation of TypeScript generics?
```

Less useful:

```text
Was it good?
```

---

## 15. Select a Question Type

GreyMatter Feedback supports four question types.

### 15.1 Rating

Use for quality, usefulness, clarity, satisfaction, or confidence.

Example:

```text
How useful was this workshop?
```

Recommended setup:

```text
Minimum score: 1
Maximum score: 5
Minimum label: Not useful
Maximum label: Extremely useful
Required: Yes
```

---

### 15.2 Recommendation Score (NPS)

Use for recommendation likelihood.

Example:

```text
How likely are you to recommend this session to a colleague?
```

NPS always uses:

```text
0 through 10
```

Recommended labels:

```text
Score 0: Not at all likely
Score 10: Extremely likely
```

Usually use one NPS question per session or course evaluation.

---

### 15.3 Choice

Use when participants should select one known option.

Example:

```text
Which topic was most valuable?
```

Enter one option per line:

```text
Server Components
Data fetching patterns
Performance optimization
Testing strategies
```

A choice question needs at least two options.

---

### 15.4 Written Response

Use for comments, suggestions, and qualitative feedback.

Example:

```text
What should we improve for the next workshop?
```

Recommended settings:

```text
Maximum characters: 1500
Placeholder: Share your suggestions
Required: No
```

Written feedback should normally remain optional.

---

## 16. Reorder Questions

Use the question ordering controls:

```text
↑ Move up
↓ Move down
```

Questions appear to participants in the same order shown in the form editor.

A useful order is:

```text
1. Overall rating
2. Specific quality or clarity rating
3. NPS question
4. Choice question
5. Written feedback
```

Put important required questions near the beginning.

---

## 17. Delete a Draft Question

To remove a question from a draft, select:

```text
Delete
```

Deleted questions are removed from the draft.

This action is only available for draft versions.

Published and archived forms are not directly editable.

---

## 18. Publish a Form Version

When the draft is ready:

1. Review every question.
2. Confirm rating scales and labels.
3. Confirm choice options.
4. Confirm required settings.
5. Confirm question order.
6. Select:

```text
Publish version [number]
```

Publishing performs these actions:

```text
Current published form becomes archived
        ↓
Selected draft becomes published
        ↓
Session points to new active form version
        ↓
Participant QR URL serves new version
```

After publishing, the participant link becomes available.

---

## 19. Preview the Participant Form

After publishing, select:

```text
Open participant preview
```

This opens the public participant route in a new browser tab.

Check:

```text
Session title
Question wording
Question order
Rating scale labels
NPS layout
Choice options
Text placeholders
Required labels
Mobile layout
```

Use a real phone before sharing QR codes with participants.

---

## 20. Get the Participant URL

Every session has a stable participant URL.

Example:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

This URL is displayed in the session editor and analytics dashboard.

Use it for:

```text
QR codes
Slides
Posters
Email links
Course portals
Chat messages
Printed instructions
```

Do not distribute an unpublished or incorrect session URL.

---

## 21. Download a QR Code

Open the session analytics dashboard:

```text
/admin/sessions/YOUR-SESSION-ID
```

Find:

```text
Session QR code
```

You can:

```text
Download PNG
Copy URL
```

### Recommended QR usage

Display the QR code with a typed fallback URL:

```text
[ QR CODE ]

feedback.example.com/e/REACT-2026-Q3
```

Before printing or presenting the QR code:

```text
[ ] Scan it with at least two devices.
[ ] Confirm it opens the correct session.
[ ] Confirm the session is active.
[ ] Confirm the correct form is published.
[ ] Confirm the URL uses production HTTPS.
```

---

## 22. Close a Feedback Session

When feedback collection should stop:

1. Open the session editor:

   ```text
   /admin/sessions/YOUR-SESSION-ID/edit
   ```

2. Select:

```text
Close feedback session
```

Participants visiting the form then see:

```text
Feedback is closed
```

Closing a session does not delete:

```text
Responses
Answers
Form versions
Analytics
CSV exports
PDF report history
```

To reopen a session, select:

```text
Reopen feedback session
```

---

## 23. View Session Analytics

Open:

```text
/admin/sessions/YOUR-SESSION-ID
```

The dashboard displays:

```text
Total responses
Average rating
Net Promoter Score
Rating distributions
NPS distributions
Choice distributions
Written feedback
QR code
CSV export
PDF report controls
```

The dashboard refreshes automatically.

---

## 24. Understand Dashboard Metrics

### Total responses

The total number of completed participant submissions.

Example:

```text
Total responses: 142
```

---

### Average rating

The average across rating question answers.

Example:

```text
Average rating: 4.6
```

The dashboard may display rating averages by question.

```text
How useful was this workshop?
Average: 4.7 / 5
```

---

### Net Promoter Score

NPS measures recommendation likelihood.

```text
Promoters: scores 9–10
Passives: scores 7–8
Detractors: scores 0–6
```

Formula:

```text
NPS = percentage of promoters - percentage of detractors
```

Example:

```text
NPS: +72
```

Always interpret NPS alongside response count and written feedback.

---

### Distribution charts

Distribution bars show how many people selected each score or option.

Example:

```text
Score 1: 0
Score 2: 1
Score 3: 4
Score 4: 32
Score 5: 105
```

An average alone can hide mixed feedback. Review the distribution as well.

---

### Written feedback

Written feedback appears as participant comments.

Use it to identify recurring themes.

Example:

```text
More time for hands-on exercises.
The caching examples moved too quickly.
Please share the code repository after the workshop.
```

Do not assume one comment represents every participant. Look for repeated patterns.

---

## 25. Export CSV Data

From the analytics dashboard, select:

```text
Export CSV
```

GreyMatter Feedback downloads a spreadsheet-compatible file.

The export includes fields such as:

```text
Event
Session ID
Session Title
Response ID
Submitted At
Form Version
Question
Question Type
Numeric Value
Text Value
```

Each CSV row represents one answer.

This format supports forms with different questions across versions.

### Use CSV exports for

```text
Excel analysis
Google Sheets
Pivot tables
Business intelligence tools
Archiving
Custom reporting
```

### CSV privacy note

Standard exports should not include:

```text
Raw IP addresses
IP hashes
User-agent strings
Internal anti-abuse metadata
```

---

## 26. Generate a PDF Report

From the analytics dashboard, open:

```text
PDF executive report
```

Select:

```text
Generate PDF report
```

The report status may change through:

```text
QUEUED
PROCESSING
COMPLETE
FAILED
```

### Status meanings

| Status | Meaning |
|---|---|
| `QUEUED` | Report request accepted and waiting for background processing |
| `PROCESSING` | Analytics and PDF are being generated |
| `COMPLETE` | PDF is ready to download |
| `FAILED` | Report generation did not complete successfully |

When complete, select:

```text
Download PDF
```

The PDF report includes:

```text
Event and session details
Response count
Average ratings
NPS
Rating distributions
Choice distributions
Written feedback
Report generation time
```

---

## 27. Recommended Administrator Workflow

For a new event or course:

```text
1. Create event or course
2. Create session
3. Create draft form version
4. Add questions
5. Preview form
6. Publish form
7. Download QR code
8. Test QR code
9. Display QR code to participants
10. Monitor dashboard
11. Close session
12. Export CSV
13. Generate PDF report
14. Record improvement actions
```

---

# Part C — Operational Guidance

## 28. Before a Live Event

Use this checklist.

```text
[ ] Event title is correct.
[ ] Session title is correct.
[ ] Session ID is correct.
[ ] Session is active.
[ ] Correct form version is published.
[ ] QR code scans correctly.
[ ] Typed fallback URL is visible.
[ ] Participant form works on a phone.
[ ] Test submission succeeds.
[ ] Dashboard updates.
[ ] CSV export works.
[ ] PDF generation works.
```

---

## 29. During a Live Event

Open the session dashboard in a separate browser tab:

```text
/admin/sessions/YOUR-SESSION-ID
```

Monitor:

```text
Response count
Latest submissions
Rating trends
NPS
Written comments
```

If no responses appear after displaying the QR code:

```text
[ ] Confirm the QR code points to the right URL.
[ ] Confirm the session is active.
[ ] Confirm a form version is published.
[ ] Confirm participants can use mobile data or venue Wi-Fi.
[ ] Display the typed fallback URL.
```

---

## 30. After an Event

Recommended post-event workflow:

```text
1. Close the feedback session.
2. Review dashboard metrics.
3. Read written feedback.
4. Export CSV data.
5. Generate PDF report.
6. Identify strengths.
7. Identify improvement opportunities.
8. Assign action owners.
9. Record follow-up deadlines.
```

Example improvement record:

```text
Session:
Advanced React Patterns

Strength:
Participants found Server Components examples useful.

Improvement:
Participants requested more hands-on exercise time.

Action:
Add a 20-minute guided exercise block.

Owner:
Training team

Review date:
Next workshop cycle
```

---

# Part D — Troubleshooting

## 31. “Feedback session not found”

Possible causes:

```text
Incorrect QR code
Incorrect typed URL
Session ID typo
Session deleted
```

Check the session ID and ask the organizer for the correct link.

---

## 32. “Feedback is closed”

The organizer has closed the session.

Possible action:

```text
Contact the event organizer if you believe the session should still accept responses.
```

---

## 33. “Feedback is not available”

Possible causes:

```text
No form has been published yet
Form was returned to draft state
Session configuration is incomplete
```

Administrator action:

```text
Open the session editor.
Confirm a form version is PUBLISHED.
Confirm the session has an activeFormVersionId.
```

---

## 34. “Too many feedback submissions were received”

GreyMatter Feedback applies rate limits to reduce duplicate or abusive submissions.

Possible participant action:

```text
Wait and try again later.
```

Administrator action:

```text
Review rate-limit settings.
Confirm a legitimate participant is not repeatedly resubmitting due to connectivity problems.
```

---

## 35. PDF Report Stuck in Queued or Processing

Administrator checks:

```text
[ ] Inngest is running or configured.
[ ] generate-pdf-report function is visible.
[ ] Report storage is configured.
[ ] Inngest run logs show no failure.
[ ] Neon database is available.
```

For local development, verify:

```bash
npm run dev
```

and:

```bash
npm run inngest:dev
```

Then open:

```text
http://localhost:8288
```

to inspect background runs.

---

## 36. QR Code Does Not Scan

Check:

```text
[ ] QR code is large enough.
[ ] QR code has strong contrast.
[ ] QR code contains production HTTPS URL.
[ ] QR code is not pointing to localhost.
[ ] QR code is not blurry or distorted.
[ ] Typed fallback URL is available.
```

Recommended sizes:

| Use | Suggested size |
|---|---:|
| Presentation slide | 350 × 350 pixels or larger |
| Phone screen | 250 × 250 pixels or larger |
| Printed poster | At least 5 cm × 5 cm |
| Large venue display | At least 8 cm × 8 cm |

---

# Part E — Administrator Best Practices

## 37. Keep Participant Forms Short

Recommended question counts:

| Session type | Typical number of questions |
|---|---:|
| Short talk | 3–5 |
| Workshop | 4–7 |
| Course module | 4–8 |
| End-of-course evaluation | 6–12 |

Shorter forms generally produce more completed submissions.

---

## 38. Use Clear Questions

Good question:

```text
How useful were the hands-on exercises?
```

Weak question:

```text
Was it good?
```

Good question:

```text
What should we improve for the next workshop?
```

Weak question:

```text
What did you think?
```

Ask one clear thing at a time.

Avoid:

```text
How clear and engaging was the instructor?
```

Instead ask:

```text
How clear was the instructor’s explanation?

How engaging was the instructor’s delivery?
```

---

## 39. Protect Historical Reporting

Once participants have answered a published form:

```text
Do not modify the published version.
```

Create a new draft version instead.

```text
Published Version 1
        ↓
Create Draft Version 2
        ↓
Make changes
        ↓
Publish Version 2
```

This protects the meaning of existing analytics and reports.

---

## 40. Final Support Reference

| Need | Location |
|---|---|
| Sign in | `/admin/login` |
| Create event/course | `/admin/events` |
| Create session | Event detail page |
| Edit feedback form | `/admin/sessions/[sessionId]/edit` |
| View analytics | `/admin/sessions/[sessionId]` |
| Participant form | `/e/[sessionId]` |
| CSV export | Session analytics dashboard |
| PDF report | Session analytics dashboard |
| Background-job debugging | Inngest dashboard |
| Database inspection during development | Prisma Studio |

---

# Final User Journey Summary

```text
Administrator
Create event
        ↓
Create session
        ↓
Create draft form
        ↓
Publish form
        ↓
Generate QR code
        ↓
Participants scan and submit
        ↓
Dashboard updates
        ↓
Export CSV and PDF report
        ↓
Improve future sessions
```

```text
Participant
Scan QR code
        ↓
Answer questions
        ↓
Draft saves automatically
        ↓
Submit feedback
        ↓
Receive confirmation
```

# Part F — Quick Reference

## 41. Participant Quick Reference

| Task | What to do |
|---|---|
| Open feedback form | Scan the QR code or type the displayed URL |
| Select a rating | Tap one score |
| Select NPS | Tap one number from 0–10 |
| Select a choice | Tap the preferred option |
| Add a comment | Type into the written feedback field |
| Fix a required field | Follow the error message shown below the question |
| Recover unfinished answers | Reopen the form in the same browser and device |
| Remove saved answers | Select **Discard draft** |
| Submit feedback | Select **Submit feedback** |
| Submit while offline | Keep the page open or reconnect; the app retries saved submissions when possible |

---

## 42. Administrator Quick Reference

| Task | Location | Action |
|---|---|---|
| Sign in | `/admin/login` | Enter administrator password |
| View events | `/admin/events` | Select an event or course |
| Create event | `/admin/events` | Select **Create event or course** |
| Create session | Event detail page | Enter title and session ID |
| Edit form | `/admin/sessions/[sessionId]/edit` | Create or edit a draft |
| Add question | Form editor | Select question type and configure it |
| Reorder question | Form editor | Use up/down controls |
| Delete draft question | Form editor | Select **Delete** |
| Publish form | Form editor | Select **Publish version** |
| Open participant preview | Form editor | Select **Open participant preview** |
| Close feedback | Form editor | Select **Close feedback session** |
| View analytics | `/admin/sessions/[sessionId]` | Review metrics and comments |
| Download QR code | Analytics dashboard | Select **Download PNG** |
| Export CSV | Analytics dashboard | Select **Export CSV** |
| Generate PDF | Analytics dashboard | Select **Generate PDF report** |
| Sign out | Admin navigation | Select **Sign out** |

---

# Part G — Example Administrator Workflows

## 43. Example: Create a Workshop Feedback Form

### Scenario

You are running a workshop named:

```text
Advanced React Patterns
```

You want participants to provide feedback immediately after the session.

### Workflow

1. Create the parent event:

   ```text
   React Summit 2026
   ```

2. Create the session:

   ```text
   Session title:
   Advanced React Patterns

   Session ID:
   REACT-2026-Q3
   ```

3. Create Draft Form Version 1.

4. Add the following questions.

```text
Question 1
Type: Rating
Prompt: How useful was this workshop?
Scale: 1–5
Minimum label: Not useful
Maximum label: Extremely useful
Required: Yes
```

```text
Question 2
Type: NPS
Prompt: How likely are you to recommend this workshop to a colleague?
Score range: 0–10
Required: Yes
```

```text
Question 3
Type: Choice
Prompt: Which topic was most valuable?
Options:
- Server Components
- Data fetching patterns
- Performance optimization
- Testing strategies
Required: No
```

```text
Question 4
Type: Written response
Prompt: What should we improve for the next workshop?
Maximum characters: 1500
Required: No
```

5. Preview the form on a phone.

6. Publish Version 1.

7. Download the QR image.

8. Add the QR code and fallback URL to the final presentation slide.

```text
feedback.example.com/e/REACT-2026-Q3
```

---

## 44. Example: Close a Session and Create a Report

### Scenario

The workshop has ended, and you want to stop new submissions and produce a report.

### Workflow

1. Open:

   ```text
   /admin/sessions/REACT-2026-Q3/edit
   ```

2. Select:

   ```text
   Close feedback session
   ```

3. Open:

   ```text
   /admin/sessions/REACT-2026-Q3
   ```

4. Review:

   ```text
   Total responses
   Average ratings
   NPS
   Choice distributions
   Written comments
   ```

5. Select:

   ```text
   Export CSV
   ```

6. Select:

   ```text
   Generate PDF report
   ```

7. Wait for the report status to become:

   ```text
   COMPLETE
   ```

8. Select:

   ```text
   Download PDF
   ```

---

# Part H — Support Escalation Template

## 45. Technical Issue Template

Use this template when reporting an issue to the GreyMatter Feedback technical owner.

```text
GreyMatter Feedback Issue Report

Date and time:
[UTC timestamp]

Reporter:
[Name and role]

Event:
[Event name]

Session title:
[Session title]

Session ID:
[Session ID]

Affected area:
[ ] Participant form
[ ] QR code
[ ] Admin login
[ ] Form authoring
[ ] Analytics dashboard
[ ] CSV export
[ ] PDF report
[ ] Inngest processing
[ ] Other

Observed behavior:
[Describe what happened.]

Expected behavior:
[Describe what should have happened.]

Error message:
[Copy visible message exactly.]

Participant URL or admin URL:
[URL without credentials.]

Steps already taken:
[Describe checks performed.]

Screenshot available:
[Yes / No]

Urgency:
[Low / Medium / High / Critical]
```

---

## 46. Live Event Emergency Checklist

If a problem occurs while participants are actively scanning a QR code:

```text
[ ] Confirm the participant URL manually.
[ ] Confirm the session is active.
[ ] Confirm a form is published.
[ ] Confirm the QR code points to the correct session.
[ ] Display a typed fallback URL.
[ ] Test with mobile data.
[ ] Check deployment logs.
[ ] Check Inngest runs.
[ ] Check Neon connectivity.
[ ] Use a fallback form or paper feedback process if required.
[ ] Record incident details for post-event review.
```

---

# Part I — Final User Manual Summary

GreyMatter Feedback provides a complete feedback workflow:

```text
Administrator creates event
        ↓
Administrator creates session
        ↓
Administrator authors a draft form
        ↓
Administrator publishes a versioned form
        ↓
Administrator displays or prints QR code
        ↓
Participant scans QR code
        ↓
Participant completes mobile form
        ↓
Participant submits feedback
        ↓
Inngest processes submission safely
        ↓
Neon stores responses and answers
        ↓
Administrator reviews analytics
        ↓
Administrator exports CSV and PDF reports
        ↓
Organization uses feedback to improve future sessions
```

The core operating principle is:

```text
Participants should experience:
Scan → Answer → Submit → Done

Administrators should experience:
Author → Publish → Measure → Improve
```

---
# Part J — Administrator Governance and Record Keeping

## 47. Form Publishing Approval Checklist

Before publishing a feedback form, confirm:

```text
[ ] The event and session titles are correct.
[ ] The session ID is correct.
[ ] All questions use clear and neutral wording.
[ ] Rating scales have meaningful low and high labels.
[ ] Choice questions have at least two valid options.
[ ] Required questions are limited to essential questions.
[ ] Written feedback questions are appropriate and optional where possible.
[ ] The form was previewed on a mobile device.
[ ] The participant URL was tested.
[ ] The QR code was tested.
```

---

## 48. Form Change Policy

Once a form version is published, do not edit it directly.

Use this process:

```text
Published form needs change
        ↓
Create new draft version
        ↓
Make changes in draft
        ↓
Preview draft
        ↓
Publish new version
        ↓
Previous published version becomes archived
```

This ensures that old responses remain associated with the wording and options participants actually saw.

---

## 49. Feedback Review Guidance

When reviewing results:

```text
Do:
- Review response count before drawing conclusions.
- Compare ratings with written feedback.
- Look for repeated themes.
- Consider the session context.
- Record practical follow-up actions.

Do not:
- Identify or speculate about anonymous participants.
- Treat one written comment as representative of all participants.
- Compare different form versions as identical measures.
- Share raw comments publicly without review.
```

---

# Part K — Data Handling Guide

## 50. Data Export Guidance

CSV exports may include:

```text
Event title
Session ID
Session title
Response ID
Submission time
Form version
Question text
Question type
Numeric answer
Text answer
```

Before sharing an export:

```text
[ ] Confirm recipients are authorized.
[ ] Remove unnecessary fields for the audience.
[ ] Review written comments for sensitive content.
[ ] Store the file in an approved secure location.
[ ] Do not upload exports to public drives or public chat channels.
```

---

## 51. Report Distribution Guidance

PDF reports may contain written participant feedback.

Before sharing a PDF report:

```text
[ ] Confirm the report is intended for the recipient.
[ ] Confirm the download link is protected.
[ ] Review comments for personal or sensitive content.
[ ] Use private storage or signed download links in production.
[ ] Follow your organization’s retention policy.
```

---

## 52. Retention Guidance

A recommended baseline policy is:

| Data type | Suggested retention |
|---|---:|
| Feedback responses | 12–24 months |
| Written comments | 12–24 months |
| PDF reports | 12 months |
| IP hashes | 7–30 days |
| Technical metadata | 30–90 days |
| Local participant drafts | Until submission or browser clearing |

Your organization may require different retention periods.

---

# Part L — Quick End-of-Event Template

## 53. Feedback Summary Template

```text
GreyMatter Feedback Summary

Event:
[Event name]

Session:
[Session title]

Session ID:
[Session ID]

Published form version:
[Version number]

Feedback collection closed:
[Date and time]

Total responses:
[Number]

Average rating:
[Number]

NPS:
[Number]

Top positive themes:
1. [Theme]
2. [Theme]
3. [Theme]

Top improvement themes:
1. [Theme]
2. [Theme]
3. [Theme]

Actions agreed:
1. [Action] — Owner: [Name] — Due: [Date]
2. [Action] — Owner: [Name] — Due: [Date]
3. [Action] — Owner: [Name] — Due: [Date]

CSV export archived:
[Yes / No]

PDF report archived:
[Yes / No]
```

---

## 54. Final Administrator Checklist

```text
Before event:
[ ] Form is published.
[ ] QR code is tested.
[ ] Participant URL is tested.
[ ] Dashboard is accessible.

During event:
[ ] Response count is monitored.
[ ] Participant issues are handled.
[ ] Fallback URL is available.

After event:
[ ] Session is closed.
[ ] Analytics are reviewed.
[ ] CSV is exported if needed.
[ ] PDF report is generated.
[ ] Follow-up actions are recorded.
[ ] Data is retained or deleted according to policy.
```






