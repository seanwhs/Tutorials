# GreyMatter Feedback Trainer Guide

**Audience:** Instructors, facilitators, workshop leaders, course trainers, event speakers  
**Purpose:** Help trainers use GreyMatter Feedback effectively before, during, and after a learning session.

---

# 1. Trainer Role

As a trainer, you are responsible for helping participants understand that feedback is:

```text
Quick
Optional unless your organization states otherwise
Respectful
Useful for improving future sessions
```

Your role is to:

```text
Prepare the correct feedback form
Display the QR code clearly
Provide a typed fallback link
Give participants time to respond
Review results constructively
Turn feedback into improvements
```

---

# 2. Before the Session

## 2.1 Confirm Session Setup

Before participants arrive, confirm:

```text
[ ] Event or course title is correct.
[ ] Session title is correct.
[ ] Session ID is correct.
[ ] Session is active.
[ ] Correct form version is published.
[ ] QR code was downloaded.
[ ] Typed fallback URL is available.
[ ] Participant form was tested on a phone.
[ ] Test submission reached the dashboard.
```

Example:

```text
Course:
TypeScript Foundations

Session:
Module 1 — Type Basics

Session ID:
TYPESCRIPT-MODULE-1

Participant URL:
https://feedback.example.com/e/TYPESCRIPT-MODULE-1?src=qr
```

---

## 2.2 Choose Appropriate Questions

Use questions that support a decision.

### Recommended short workshop form

```text
1. How useful was this workshop?
   Rating: 1–5
   Required: Yes

2. How clear was the explanation?
   Rating: 1–5
   Required: Yes

3. How likely are you to recommend this workshop to a colleague?
   NPS: 0–10
   Required: Yes

4. What was the most valuable part?
   Text: Optional

5. What should we improve next time?
   Text: Optional
```

### Recommended course module form

```text
1. How clear was this module?
   Rating: 1–5

2. Was the pace appropriate?
   Choice:
   - Too slow
   - About right
   - Too fast

3. How useful were the examples or exercises?
   Rating: 1–5

4. Which topic needs more explanation?
   Choice

5. What should we improve before the next module?
   Text
```

---

# 3. During the Session

## 3.1 When to Ask for Feedback

Best times:

```text
Final 3–5 minutes of a workshop
Immediately after a course module
After a major exercise
At the end of a conference talk
Before participants leave the room
```

Avoid asking too early. Participants need enough experience to answer meaningfully.

---

## 3.2 Display the QR Code Clearly

Use a final slide or poster with:

```text
Thank you for attending

Please share your feedback

[ Large QR Code ]

feedback.example.com/e/TYPESCRIPT-MODULE-1
```

Always include the typed URL.

Some participants may not be able to scan QR codes because of:

```text
No camera access
Low battery
Device restrictions
Accessibility needs
Personal preference
```

---

## 3.3 Suggested Trainer Script

Use this short script:

> “Before you leave, please take one minute to share feedback. Scan the QR code on screen or use the web address below it. Your feedback helps improve future sessions.”

For a course setting:

> “Please be honest and specific. I am especially interested in clarity, pace, exercises, and topics that need more explanation.”

For anonymous feedback:

> “You do not need to sign in. Please avoid including private or sensitive personal information in written comments.”

---

## 3.4 Give Participants Enough Time

Allow at least:

| Session Type | Suggested Feedback Time |
|---|---:|
| Short talk | 1–2 minutes |
| Workshop | 2–3 minutes |
| Course module | 2–4 minutes |
| End-of-course evaluation | 5–10 minutes |

Keep the QR code displayed while participants complete the form.

Do not immediately switch to another slide.

---

# 4. Helping Participants Use the Form

Participants may see:

```text
Rating questions
Recommendation scores
Choice questions
Written feedback fields
```

Explain only if needed.

Example:

> “The first questions use a 1–5 rating. The recommendation question uses a 0–10 score. The final written questions are optional, but specific comments are especially helpful.”

---

# 5. Handling Common Participant Questions

| Participant Question | Suggested Trainer Response |
|---|---|
| “Do I need to sign in?” | “No, not for this feedback form.” |
| “Is this anonymous?” | “The form does not ask for your name. Please avoid entering identifying or sensitive information in comments.” |
| “The QR code does not scan.” | “Please use the typed link on the screen.” |
| “The form says feedback is closed.” | “Please let me know; I will check the session status.” |
| “I refreshed the page.” | “Your draft may restore automatically in the same browser.” |
| “I cannot submit.” | “Check your connection and required questions. Your draft should remain saved.” |
| “What should I write?” | “Tell us what was helpful, what was unclear, and one improvement that would help future learners.” |

---

# 6. During-Event Monitoring

Open the analytics dashboard in a separate browser tab:

```text
/admin/sessions/[sessionId]
```

Monitor:

```text
Total responses
Latest submissions
Average ratings
NPS
Choice distributions
Written feedback
```

Do not display private dashboard content publicly unless it has been reviewed and approved.

---

## 6.1 What to Do if No Responses Appear

Check:

```text
[ ] Is the QR code correct?
[ ] Is the typed URL correct?
[ ] Is the session active?
[ ] Is a form version published?
[ ] Does the participant URL work on your phone?
[ ] Is venue internet available?
```

Immediate fallback:

```text
Display the typed URL.
Share the link in course chat.
Share the link by email after the session.
Use a backup feedback method if necessary.
```

---

# 7. After the Session

## 7.1 Close the Feedback Session

When feedback collection should end:

1. Open:

   ```text
   /admin/sessions/[sessionId]/edit
   ```

2. Select:

```text
Close feedback session
```

Participants then see:

```text
Feedback is closed
```

Closing a session preserves:

```text
Responses
Answers
Form versions
Analytics
CSV exports
PDF reports
```

---

## 7.2 Review Feedback Constructively

Review:

```text
Response count
Average ratings
NPS
Rating distributions
Choice selections
Written comments
```

Use a balanced approach.

```text
Look for repeated themes.
Consider response count.
Compare scores with written comments.
Avoid overreacting to one comment.
Identify practical changes.
```

---

## 7.3 Example Feedback Interpretation

### Example dashboard results

```text
Total responses:
84

Average usefulness:
4.6 / 5

NPS:
+61

Pace question:
Too slow: 3
About right: 59
Too fast: 22

Common comments:
- More time needed for hands-on exercises.
- Generics explanation moved too quickly.
- Code examples were useful.
```

### Possible trainer actions

```text
Keep:
Live coding examples.

Improve:
Add more guided exercise time.

Change:
Split generics into a follow-up lesson or slower walkthrough.

Follow-up:
Share practice repository before next session.
```

---

# 8. Feedback Review Template

```text
Session:
[Session title]

Response count:
[Number]

What worked:
1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

What needs improvement:
1. ___________________________________________
2. ___________________________________________
3. ___________________________________________

Action:
_______________________________________________

Owner:
_______________________________________________

Due date:
_______________________________________________
```

---

# 9. Trainer Best Practices

## Do

```text
Ask for feedback at a natural stopping point.
Keep forms short.
Explain why feedback matters.
Display QR and typed URL together.
Give participants enough time.
Thank participants for honest feedback.
Review recurring themes.
Make visible improvements over time.
```

## Avoid

```text
Forcing participants to submit feedback publicly.
Reading raw comments aloud without review.
Asking for personal information unnecessarily.
Changing published questions after responses begin.
Using overly long forms after a short session.
Reacting defensively to criticism.
Treating a single score as the whole story.
```

---

# 10. Recommended Follow-Up Message

After reviewing feedback, consider sharing a brief follow-up with participants.

Example:

> “Thank you for your feedback on Module 1. Many of you found the examples useful and asked for more exercise time. In the next module, we will include a longer guided practice section and share the code repository earlier.”

This helps participants see that feedback leads to action.

---

# 11. Trainer Quick Checklist

## Before Session

```text
[ ] Form published.
[ ] Session active.
[ ] QR code tested.
[ ] Typed URL displayed.
[ ] Participant test submitted.
[ ] Dashboard available.
```

## During Session

```text
[ ] Feedback request announced.
[ ] QR code remains visible.
[ ] Typed URL remains visible.
[ ] Participants have enough time.
[ ] Dashboard monitored if appropriate.
```

## After Session

```text
[ ] Feedback session closed.
[ ] Analytics reviewed.
[ ] CSV exported if needed.
[ ] PDF report generated if needed.
[ ] Improvement actions documented.
[ ] Follow-up communication prepared.
```

---

# 12. Final Trainer Principle

GreyMatter Feedback is most useful when participants understand that their feedback has a purpose.

```text
Ask clearly
        ↓
Listen respectfully
        ↓
Review carefully
        ↓
Act visibly
        ↓
Improve future learning experiences
```
