# Appendix I: Operations Runbook for Live Events

GreyMatter Feedback is often used in time-sensitive situations:

- A workshop ends in five minutes.
- A speaker asks participants to scan a QR code before leaving.
- A course facilitator needs live feedback before the next module.
- An event organizer needs an executive report shortly after a session closes.

This appendix provides a practical operational runbook for preparing, running, and closing a live feedback session.

---

## I.1 Roles during a live event

For small events, one person may perform every role. For larger events, assign clear responsibilities.

| Role | Responsibility |
|---|---|
| Event owner | Owns the overall feedback goal and final reporting |
| Form editor | Creates and publishes the feedback form |
| Session facilitator | Displays the QR code and encourages participation |
| Technical operator | Monitors the dashboard, Inngest, and submission health |
| Analyst | Reviews responses and prepares exports or reports |

For a large event, avoid relying on one person who is also presenting.

---

## I.2 Pre-event preparation timeline

A reliable process starts before participants arrive.

## One week before the event

```text
[ ] Create the event or course.
[ ] Create every planned session.
[ ] Decide which sessions need separate feedback forms.
[ ] Draft questions.
[ ] Review questions for clarity and neutrality.
[ ] Confirm which questions are required.
[ ] Confirm whether NPS is needed.
[ ] Define who can access analytics and exports.
[ ] Confirm retention and privacy messaging.
```

## One day before the event

```text
[ ] Create and publish each form version.
[ ] Open each participant URL on desktop and mobile.
[ ] Submit one test response per session.
[ ] Confirm dashboard metrics appear.
[ ] Export a test CSV.
[ ] Generate a test PDF report.
[ ] Download QR codes.
[ ] Add QR codes to slides, posters, or printed cards.
[ ] Confirm typed fallback URLs are displayed.
[ ] Confirm administrator login works.
```

## Thirty minutes before the event

```text
[ ] Confirm the session is active.
[ ] Confirm the correct form version is published.
[ ] Confirm the displayed QR code matches the intended session.
[ ] Open the admin dashboard in a separate browser tab.
[ ] Check the deployed application is available from a phone using mobile data.
[ ] Confirm Inngest functions are healthy.
[ ] Confirm report storage is available.
```

---

## I.3 Session readiness checklist

Before participants scan a QR code, verify these exact items.

```text
Session:
[ ] Correct event name
[ ] Correct session title
[ ] Correct session ID
[ ] isActive = true
[ ] Published form is active
[ ] Questions appear in correct order
[ ] Required settings are correct

Participant experience:
[ ] QR code scans successfully
[ ] Fallback URL is visible
[ ] Form works on a phone
[ ] Submit button is visible without layout problems
[ ] One test submission succeeds

Administrator experience:
[ ] Dashboard opens
[ ] QR image downloads
[ ] CSV export works
[ ] PDF report generation works
```

---

## I.4 How to display a QR code effectively

A QR code should be easy to scan from a normal audience distance.

Recommended slide layout:

```text
Thank you for attending

Please share your feedback

[ Large QR code ]

feedback.example.com/e/REACT-2026-Q3
```

Avoid a cluttered slide such as:

```text
Small QR code in a corner
Tiny URL
Busy background image
Low contrast text
Multiple unrelated QR codes
```

### Practical display guidance

| Situation | Recommended behavior |
|---|---|
| In-person workshop | Display QR code during final 3–5 minutes |
| Conference talk | Keep QR code on closing slide |
| Course module | Display QR code after final exercise |
| Hybrid session | Put QR URL in chat and slides |
| Printed material | Include QR code and short typed URL |
| Large venue | Use a large high-contrast QR code on projector screen |

---

## I.5 Participant instruction script

A facilitator can use this short script:

> “Please take one minute to share feedback before you leave. Scan the QR code on screen, or type the URL below it. Your responses help us improve future sessions.”

For anonymous feedback, add:

> “You do not need to sign in. Please avoid including private or sensitive information in written comments.”

For a short deadline:

> “The form will remain open until the end of the day.”

Avoid pressuring participants with language such as:

```text
Everyone must complete this immediately.
```

Feedback quality improves when participants feel free to respond honestly.

---

## I.6 Monitoring live response flow

During a session, open the dashboard:

```text
/admin/sessions/YOUR-SESSION-ID
```

Watch:

```text
Total responses
Latest submission time
Rating distributions
NPS score
Written comments
```

The dashboard refreshes automatically.

### What normal activity looks like

```text
QR code displayed
        ↓
Responses begin appearing
        ↓
Total count rises steadily
        ↓
Latest submission time remains recent
```

### What may indicate a problem

```text
QR code displayed for several minutes
        ↓
No responses
```

Possible causes:

```text
Wrong QR code
Inactive session
Unpublished form
Poor venue internet
Participants have not noticed the request
QR code too small
Fallback URL missing
```

---

## I.7 Fast troubleshooting during an event

## Problem: no participants can open the form

Check the participant URL manually:

```text
https://feedback.your-domain.example/e/YOUR-SESSION-ID
```

Confirm:

```text
[ ] The domain loads.
[ ] The session ID is correct.
[ ] The session is active.
[ ] The form has a published version.
[ ] The participant page does not show “Feedback is closed.”
```

If the QR code is wrong but the typed URL is correct:

```text
Display the typed URL immediately.
Regenerate the QR code after the event.
```

## Problem: participants can open the form but cannot submit

Check:

```text
[ ] Inngest is operational.
[ ] Rate limiting is not overly strict.
[ ] The feedback API returns 202.
[ ] The session is still active.
[ ] The active form version has not changed.
```

Ask one participant to describe the visible error message or send a screenshot without including private answers.

## Problem: dashboard count does not update

Check:

```text
[ ] The participant saw a success confirmation.
[ ] An Inngest run exists for feedback/submitted.
[ ] process-feedback-submission completed.
[ ] A Response exists in Neon.
[ ] The dashboard has refreshed.
```

---

## I.8 Closing a feedback session

When feedback collection should end, close the session from the form editor:

```text
/admin/sessions/YOUR-SESSION-ID/edit
```

Click:

```text
Close feedback session
```

This changes:

```text
Session.isActive = false
```

Participants visiting the QR URL then see:

```text
Feedback is closed
```

The application retains:

```text
Published form versions
Responses
Answers
Analytics
CSV exports
PDF reports
```

Closing a session does not delete data.

---

## I.9 End-of-event reporting workflow

After closing the session:

```text
1. Open the analytics dashboard.
2. Review total response count.
3. Review rating averages.
4. Review NPS.
5. Read written feedback.
6. Export CSV.
7. Generate PDF executive report.
8. Download and archive the PDF.
9. Record key findings and follow-up actions.
```

A useful reporting note format is:

```text
Session:
Advanced React Patterns

Response count:
142

Strengths:
- Average usefulness score: 4.7 / 5
- Strong NPS: +72
- Participants valued Server Components examples

Improvement opportunities:
- More hands-on exercise time
- Slower walkthrough of caching examples
- Share reference materials after session

Owner:
Engineering Education Team

Follow-up deadline:
2026-08-15
```

The dashboard provides evidence; the operational note turns evidence into action.

---

## I.10 Handling accidental publication or wrong QR codes

## Wrong form published

If a form is published by mistake:

1. Create or identify the correct draft.
2. Publish the correct form version.
3. Confirm the participant URL shows the correct questions.
4. Archive the accidental version through the normal publishing workflow.
5. Record what happened in an internal operational note.

Do not edit a published form directly.

## Wrong QR code printed

If a QR code points to the wrong session:

1. Remove or cover the incorrect printed code if possible.
2. Display the correct typed URL immediately.
3. Replace the slide or poster.
4. Generate a new QR image.
5. Confirm it scans on at least two devices.

## Session accidentally closed

1. Open the session editor.
2. Click:

   ```text
   Reopen feedback session
   ```

3. Verify the participant URL loads.
4. Confirm the intended published version remains active.

---

## I.11 Recommended event-day dashboard layout

For an event operator, keep these tabs open:

```text
Tab 1:
Administrator dashboard for current session

Tab 2:
Participant URL for current session

Tab 3:
Inngest production dashboard

Tab 4:
Neon dashboard or Prisma Studio only if needed
```

Avoid editing forms directly while participants are actively responding unless there is a critical problem.

If a form change is necessary:

```text
Create a new draft version
        ↓
Make changes
        ↓
Test preview
        ↓
Publish deliberately
```

Remember that publishing a new version changes the participant form for future visits to the stable QR URL.

---

## I.12 Post-event review checklist

Within one or two business days after an event:

```text
[ ] Close all sessions that should no longer accept feedback.
[ ] Generate and archive PDF reports.
[ ] Export raw CSV data if needed.
[ ] Review written feedback for urgent concerns.
[ ] Summarize findings.
[ ] Assign improvement actions.
[ ] Record decisions made from feedback.
[ ] Apply retention policy to reports and metadata.
[ ] Archive unused drafts.
[ ] Confirm no temporary test sessions remain publicly active.
```

---

## I.13 Incident communication template

If a feedback outage occurs during an event, use clear communication.

### Participant-facing message

> “The feedback form is temporarily unavailable. Please try again in a few minutes, or use the alternative link provided by the facilitator. We appreciate your patience.”

### Internal operator message

```text
Incident:
Participant feedback form unavailable.

Session:
[SESSION ID]

Started:
[UTC timestamp]

Observed behavior:
[Error message or page behavior]

Initial checks:
[ ] Participant URL tested
[ ] Session active status checked
[ ] Form published status checked
[ ] Inngest checked
[ ] Deployment status checked

Current owner:
[Name or role]

Next update:
[Time]
```

Avoid sharing internal credentials, database errors, or participant data in event chat channels.

---

## I.14 Final operational principle

A QR feedback system succeeds when the participant experience is effortless:

```text
See QR code
        ↓
Scan
        ↓
Answer
        ↓
Submit
        ↓
Leave with confidence
```

The administrator experience should be equally clear:

```text
Author
        ↓
Publish
        ↓
Monitor
        ↓
Analyze
        ↓
Improve
```

The technical platform supports that process, but careful preparation, clear ownership, and a simple event-day checklist are what make GreyMatter Feedback dependable in real use.
