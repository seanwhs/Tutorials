# Primer 6: Designing Mobile-First Feedback Forms

GreyMatter Feedback is designed around a common real-world situation:

```text
Participant is standing near the exit
        ↓
Sees a QR code on a slide
        ↓
Scans it with a phone
        ↓
Has less than two minutes to respond
```

That context matters.

A feedback form that works well on a large desktop screen may feel slow, crowded, or frustrating on a phone. This primer explains the mobile-first design principles used by GreyMatter Feedback.

---

## 1. What “Mobile-First” Means

Mobile-first does not mean:

```text
Build desktop version first
        ↓
Make everything smaller
```

It means:

```text
Start with the smallest screen
        ↓
Prioritize essential content
        ↓
Make touch controls easy to use
        ↓
Enhance layout for larger screens
```

For GreyMatter Feedback, the essential participant experience is:

```text
Session title
Question
Answer controls
Submit button
```

Everything else is secondary.

---

## 2. Design for the Participant’s Real Context

Participants may be:

```text
Standing
Walking
Holding a bag or drink
Using one hand
On weak venue Wi-Fi
Using a small phone
Distracted by the next session
```

A participant form should therefore be:

```text
Short
High contrast
Easy to tap
Easy to understand
Fast to load
Forgiving of refreshes and network interruptions
```

Avoid requiring participants to:

```text
Create an account
Enter an email
Remember a password
Install an app
Read long instructions
Navigate through many pages
```

---

## 3. Keep the Form Short

The best participant form is usually not the most detailed form.

A practical target is:

```text
3 to 5 questions for a talk or workshop
4 to 8 questions for a course module
6 to 12 questions for end-of-course feedback
```

Every additional question increases the chance that a participant stops before submitting.

A useful question set for a short workshop:

```text
1. How useful was this workshop?
   Rating: 1–5

2. How likely are you to recommend it?
   NPS: 0–10

3. What was the most valuable part?
   Text: optional

4. What should we improve?
   Text: optional
```

This gives organizers measurable data and qualitative context without creating a long survey.

---

## 4. Use Large Touch Targets

A touch target is the area a participant taps.

GreyMatter Feedback uses:

```text
min-h-12
```

In Tailwind CSS, this means:

```text
Minimum height: 48 pixels
```

Example:

```tsx
<button
  className="min-h-12 rounded-xl border px-4 py-3 font-semibold"
  type="button"
>
  5
</button>
```

Why 48 pixels?

Because people do not tap with a precise mouse cursor. They tap with fingers of different sizes while moving and holding devices at different angles.

Avoid small controls:

```tsx
<button className="h-6 w-6">5</button>
```

A small button may technically work, but it creates avoidable errors and frustration.

---

## 5. Use Clear Visual States

Participants need to know immediately which answer they selected.

For a rating question, GreyMatter Feedback uses different styles.

Unselected:

```text
White background
Slate border
Dark text
```

Selected:

```text
Indigo background
Indigo border
White text
```

Example:

```tsx
className={`min-h-12 rounded-xl border px-4 py-3 font-semibold transition ${
  selected
    ? "border-indigo-600 bg-indigo-600 text-white"
    : "border-slate-300 bg-white text-slate-700 hover:border-indigo-400 hover:bg-indigo-50"
}`}
```

The selected state should remain visible after the participant taps a control.

Do not rely only on a brief animation or vibration. A participant must be able to look at the form and understand the current answer.

---

## 6. Rating Questions

A rating question usually measures quality, usefulness, clarity, or satisfaction.

Example:

```text
How useful was this workshop?

1  2  3  4  5

Not useful          Extremely useful
```

A good rating question includes:

```text
Specific topic
Consistent score range
Clear low-end label
Clear high-end label
```

Good example:

```text
How clear was the explanation of Server Components?

1 2 3 4 5

Not clear           Extremely clear
```

Weak example:

```text
Was it good?
```

The participant may not know whether “it” means the instructor, venue, exercises, or overall session.

---

## 7. NPS Questions

An NPS question measures recommendation likelihood.

Standard NPS range:

```text
0 through 10
```

Example:

```text
How likely are you to recommend this workshop to a colleague?

0 1 2 3 4 5 6 7 8 9 10

Not at all likely          Extremely likely
```

NPS controls can be challenging on narrow screens because there are eleven values.

GreyMatter Feedback uses a responsive grid:

```tsx
className="grid grid-cols-6 gap-2 sm:grid-cols-11"
```

On small screens:

```text
0  1  2  3  4  5
6  7  8  9  10
```

On larger screens:

```text
0 1 2 3 4 5 6 7 8 9 10
```

This keeps every button large enough to tap.

---

## 8. Choice Questions

A choice question asks a participant to select one known option.

Example:

```text
Which part of the workshop was most valuable?

○ Server Components
○ Data fetching
○ Performance optimization
○ Testing strategies
```

Choice questions are useful when administrators need to compare categories.

Good practices:

```text
Use short option labels.
Use one concept per option.
Avoid overlapping choices.
Avoid too many choices.
Include “Other” only when a follow-up text field exists.
```

Avoid options such as:

```text
- Everything
- Nothing
- Maybe
- Other things
```

unless they are genuinely meaningful for the question.

---

## 9. Text Questions

Text questions collect details that structured scores cannot predict.

Example:

```text
What should we improve for the next workshop?
```

Text questions should usually be optional.

Why?

```text
Some participants have no additional comment.
Some participants are in a hurry.
Some participants do not want to write feedback.
```

A text field should include:

```text
Clear question
Helpful placeholder
Character limit
Visible character count
Comfortable height
16px or larger font
```

Example:

```tsx
<textarea
  className="min-h-32 w-full resize-y rounded-xl border px-4 py-3 text-base"
  maxLength={1500}
  placeholder="Share any suggestions, missing topics, or areas that need more explanation."
  rows={5}
/>
```

The `text-base` class helps avoid unwanted mobile-browser zoom.

---

## 10. Prevent Mobile Input Zoom

Mobile Safari may zoom into an input field when the font size is below 16 pixels.

GreyMatter Feedback uses:

```text
text-base
```

which normally means:

```text
16px
```

Example:

```tsx
<input
  className="min-h-12 w-full rounded-xl border px-4 py-3 text-base"
/>
```

Avoid styling form inputs with very small text:

```tsx
className="text-xs"
```

Small input text often creates an awkward zoom jump when a participant taps into the field.

---

## 11. Local Draft Persistence

Participants can lose progress for ordinary reasons:

```text
Accidental refresh
Phone lock
Browser dismissal
Weak signal
Opening another application
```

GreyMatter Feedback saves drafts in browser localStorage.

The flow is:

```text
Participant selects answer
        ↓
Answer saved in localStorage
        ↓
Page refreshes
        ↓
Draft is restored
```

The draft key includes both:

```text
Session ID
Form version ID
```

Example key:

```text
greymatter-feedback:draft:REACT-2026-Q3:c39c3d46-3d35-4c25-b889-80e437f526e4
```

This prevents an old draft from appearing in a newly published form version.

---

## 12. Why Drafts Must Be Cleared After Submission

Once the server accepts a submission, the draft should be removed.

```text
Participant submits
        ↓
API returns 202 Accepted
        ↓
Clear local draft
        ↓
Show thank-you state
```

If the draft were retained, the participant could refresh later and see old answers, possibly believing the form was not submitted.

The important rule is:

> Clear the draft only after the server accepts the request.

Do not clear it before the request completes. If the network fails, the participant needs the draft to retry.

---

## 13. Offline Submission Outbox

A local draft stores unfinished answers.

An outbox stores a completed submission that could not be sent.

```text
Participant completes form
        ↓
Participant taps Submit
        ↓
Network unavailable
        ↓
Submission payload saved in outbox
        ↓
Browser reconnects
        ↓
Payload retried
```

This is especially useful in venues with unreliable Wi-Fi.

The outbox depends on a stable submission ID:

```text
Same completed submission
        ↓
Same submission ID
        ↓
Retry-safe background processing
```

Without a stable ID, retries could produce duplicate responses.

---

## 14. Haptic Feedback

Some phones support vibration through the Web Vibration API.

GreyMatter Feedback uses a short vibration when a participant chooses a rating or NPS score:

```ts
navigator.vibrate(10);
```

The `10` represents approximately ten milliseconds.

This is optional feedback. It gives participants a small physical confirmation that their tap was registered.

The application checks whether vibration exists:

```ts
if (typeof navigator !== "undefined" && "vibrate" in navigator) {
  navigator.vibrate(10);
}
```

Never make vibration necessary for the form to work.

Some devices, browsers, accessibility settings, and battery-saving modes may ignore it.

---

## 15. Required Questions

Required questions should be limited to essential information.

A good default:

```text
Required:
- Overall usefulness rating
- One recommendation or NPS question

Optional:
- Written comments
- Detailed suggestions
- Nonessential preference questions
```

Too many required fields increase drop-off.

When a required answer is missing, GreyMatter Feedback should:

```text
Show clear error near the question
Scroll to first invalid question
Keep existing answers
Avoid losing draft
```

Example error:

```text
This question requires an answer.
```

Avoid unclear messages:

```text
Invalid input.
```

or:

```text
Error code 400.
```

---

## 16. Make Errors Easy to Fix

A useful form error has three qualities:

```text
Specific
Near the problem
Actionable
```

Good:

```text
This question requires an answer.
```

Better for a constrained field:

```text
Choose one of the available options.
```

Good text length error:

```text
Your response must be 1,500 characters or fewer.
```

Poor:

```text
Submission failed.
```

A general submission failure is still useful when the cause is network or server availability, but field-level validation should identify the actual question that needs attention.

---

## 17. Use Progressive Disclosure Carefully

**Progressive disclosure** means showing information only when it is useful.

For example:

```text
Participant selects:
Other

Then show:
Please describe the other topic.
```

This can reduce clutter.

However, do not hide essential information unnecessarily.

Avoid:

```text
Multiple pages
Unexpected hidden required fields
Complex branching logic
Questions that appear and disappear without explanation
```

For most session feedback forms, a short visible list of questions is easier than a complicated multi-step survey.

---

## 18. Submission Button Design

The submission button should be:

```text
Easy to find
Large enough to tap
Clearly labeled
Disabled only when necessary
```

Good label:

```text
Submit feedback
```

Weak label:

```text
Continue
```

or:

```text
OK
```

During submission, show progress:

```text
Submitting feedback…
```

After acceptance, show a clear confirmation:

```text
Thank you for your feedback.
Your response was accepted and is being processed securely.
```

Avoid leaving participants on the same form with no visible result.

---

## 19. Participant Form Checklist

Before publishing a form, review it on a real phone.

```text
[ ] Form opens quickly.
[ ] Session title is correct.
[ ] Questions are short and clear.
[ ] Required questions are limited.
[ ] Rating labels explain the scale.
[ ] NPS labels are visible.
[ ] Choice options are readable.
[ ] Buttons are easy to tap.
[ ] Text inputs do not trigger browser zoom.
[ ] Text fields have useful placeholders.
[ ] Error messages are understandable.
[ ] Draft restores after refresh.
[ ] Submit button is easy to find.
[ ] Success confirmation is clear.
[ ] QR code and fallback URL both work.
```

---

## 20. Primer Summary

A mobile-first GreyMatter Feedback form should feel like this:

```text
Scan QR code
        ↓
See correct session immediately
        ↓
Understand each question quickly
        ↓
Tap large answer controls
        ↓
Keep progress if interrupted
        ↓
Submit confidently
        ↓
Receive clear confirmation
```

The key design principles are:

```text
Short forms
Large touch targets
Clear selected states
16px input text
Meaningful labels
Limited required questions
Local draft persistence
Offline retry support
Accessible errors
Fast confirmation
```

When participant feedback is easy to provide, organizers receive more responses, more useful responses, and better evidence for improving future events.
