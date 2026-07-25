# Appendix F: Accessibility and Mobile Experience Guidelines

GreyMatter Feedback is frequently used on phones, often while participants are standing, moving between sessions, or trying to respond quickly before an event ends.

A good feedback form must work for:

- People using small screens.
- People using keyboards.
- People using screen readers.
- People with limited dexterity.
- People with low vision.
- People using slow or unreliable networks.
- People who are distracted or short on time.

This appendix explains the accessibility and mobile design decisions in GreyMatter Feedback and provides a practical testing checklist.

---

## F.1 Accessibility is a product requirement

Accessibility means designing software so people with different abilities can use it.

It is not a separate “special mode.” It is part of normal product quality.

For GreyMatter Feedback, accessibility is especially important because the application is intended for broad event audiences. A participant should not be excluded from providing feedback because:

- Buttons are too small.
- Text has low contrast.
- A keyboard cannot reach a control.
- A screen reader cannot identify a question.
- Error messages are unclear.
- The form relies only on color.
- A phone input zooms unexpectedly.
- A QR code is the only way to access the form.

---

## F.2 Provide a non-QR access path

QR codes are convenient, but they should not be the only method of accessing feedback.

Some participants may not have:

- A phone camera.
- A compatible phone.
- Enough battery.
- Permission to use a phone at the event.
- The ability to scan a QR code.

Whenever an organizer displays a QR code, they should also display the short participant URL.

Example:

```text
Scan the QR code or visit:

feedback.example.com/e/REACT-2026-Q3
```

For slides, show both:

```text
[ QR CODE ]

feedback.example.com/e/REACT-2026-Q3
```

For printed materials, use a large readable URL.

---

## F.3 Touch target requirements

Mobile controls should be easy to tap without requiring precision.

GreyMatter Feedback uses:

```text
min-h-12
```

In Tailwind CSS, this creates a minimum height of:

```text
48 pixels
```

This meets a practical minimum for touch targets.

Example rating button:

```tsx
<button
  className="min-h-12 rounded-xl border px-4 py-3 font-semibold"
  type="button"
>
  5
</button>
```

Avoid tiny controls like:

```tsx
<button className="h-6 w-6">5</button>
```

Small controls are difficult for users with tremor, limited dexterity, or large fingers on small screens.

---

## F.4 Avoid browser auto-zoom on iPhone

Mobile Safari may zoom into an input when its font size is below 16 pixels.

GreyMatter Feedback uses:

```tsx
className="text-base"
```

In Tailwind, `text-base` is normally:

```text
16px
```

For example:

```tsx
<textarea
  className="min-h-32 w-full rounded-xl border px-4 py-3 text-base"
  rows={5}
/>
```

This avoids unwanted zoom behavior when participants tap into a text field.

---

## F.5 Use semantic form controls

Semantic HTML gives browsers and assistive technologies useful meaning.

For example:

```tsx
<label htmlFor="password">Administrator password</label>

<input
  id="password"
  name="password"
  type="password"
/>
```

The `label` tells screen readers what the input means and allows users to tap the label to focus the input.

For rating controls that behave like one selection from a group, GreyMatter Feedback uses:

```tsx
role="radiogroup"
```

and:

```tsx
role="radio"
aria-checked={selected}
```

Example:

```tsx
<div role="radiogroup" aria-label="How useful was this workshop?">
  <button
    aria-checked={selected}
    role="radio"
    type="button"
  >
    5
  </button>
</div>
```

This communicates that the controls are mutually exclusive choices.

---

## F.6 Never rely only on color

Selected answers use color differences:

```text
Unselected: white background and slate border
Selected: indigo background and white text
```

However, color is not the only indicator.

A selected choice also includes:

```text
aria-checked="true"
```

And choice controls visually include a filled radio indicator:

```tsx
<span
  className={`flex h-5 w-5 items-center justify-center rounded-full border ${
    selected ? "border-indigo-600 bg-indigo-600" : "border-slate-400"
  }`}
>
  {selected ? <span className="h-2 w-2 rounded-full bg-white" /> : null}
</span>
```

This helps participants distinguish state without depending only on color perception.

---

## F.7 Accessible error messages

When a participant submits a form without answering a required question, the application displays an error message near that question.

Example:

```tsx
<p
  className="mt-3 text-sm font-medium text-red-700"
  id={`${question.id}-error`}
  role="alert"
>
  This question requires an answer.
</p>
```

The question control references the error:

```tsx
aria-describedby={`${question.id}-error`}
```

This helps screen-reader users understand why a question requires attention.

The form also scrolls to the first invalid question:

```tsx
document
  .getElementById(firstInvalidQuestionId ?? "")
  ?.scrollIntoView({
    behavior: "smooth",
    block: "center",
  });
```

For a stronger accessibility enhancement, move keyboard focus to the first invalid question after scrolling.

Example future improvement:

```tsx
document
  .querySelector<HTMLElement>(
    `#${CSS.escape(firstInvalidQuestionId)} button, #${CSS.escape(
      firstInvalidQuestionId,
    )} textarea`,
  )
  ?.focus();
```

This should be tested carefully because rating, choice, and text questions use different control structures.

---

## F.8 Announce asynchronous status changes

Screen readers do not automatically announce visible text that appears after a background operation.

GreyMatter Feedback uses:

```tsx
aria-live="polite"
```

for status messages.

Example submission success state:

```tsx
<section
  aria-live="polite"
  className="rounded-2xl border border-emerald-200 bg-emerald-50 p-6"
>
  <h2>Thank you for your feedback.</h2>
  <p>Your response was accepted and is being processed securely.</p>
</section>
```

`polite` means:

> Announce this update when the screen reader is not busy reading something else.

Use `role="alert"` for important validation errors that should be announced immediately.

---

## F.9 Keyboard testing

Every participant and administrator flow should work with a keyboard alone.

Test using:

```text
Tab
Shift + Tab
Enter
Space
Escape
```

### Participant form test

1. Open a feedback session.
2. Press `Tab`.
3. Confirm each interactive control receives a visible focus indicator.
4. Press `Enter` or `Space` on rating buttons.
5. Confirm a rating is selected.
6. Continue through NPS, choice, and text controls.
7. Submit the form without answering required questions.
8. Confirm errors are visible and understandable.
9. Complete the required answers.
10. Submit successfully.

### Admin portal test

1. Sign in.
2. Navigate with `Tab`.
3. Create an event.
4. Create a session.
5. Create a draft form.
6. Add questions.
7. Move questions up and down.
8. Publish a version.
9. Open analytics.
10. Download CSV and PDF reports.

---

## F.10 Visible focus indicators

Keyboard users need to see where they are on the page.

GreyMatter Feedback includes this global style:

### `src/app/globals.css`

```css
:focus-visible {
  outline: 3px solid #4f46e5;
  outline-offset: 3px;
}
```

This is better than removing focus outlines.

Avoid:

```css
button:focus {
  outline: none;
}
```

Removing focus styling makes keyboard navigation difficult or impossible.

If custom focus styles are needed, preserve equal or better visibility:

```tsx
className="focus-visible:outline focus-visible:outline-3 focus-visible:outline-indigo-600 focus-visible:outline-offset-3"
```

---

## F.11 Color contrast

Text and controls should have enough contrast against their backgrounds.

Examples used in GreyMatter Feedback:

```text
Slate-950 on white
Indigo-700 on indigo-50
White on indigo-600
Red-700 on red-50
Emerald-800 on emerald-100
```

When introducing new colors, test them with a contrast checker.

Useful tools:

```text
WebAIM Contrast Checker
https://webaim.org/resources/contrastchecker/
```

For typical text, target at least:

```text
4.5:1 contrast ratio
```

For large text, target at least:

```text
3:1 contrast ratio
```

---

## F.12 Text size and zoom

Participants should be able to zoom text to 200% without the layout becoming unusable.

Test:

1. Open a participant form on desktop.
2. Set browser zoom to 200%.
3. Confirm:
   - No text overlaps.
   - Buttons remain visible.
   - Horizontal scrolling is minimized.
   - The submit button remains usable.
   - Error messages remain readable.

The layout uses responsive classes such as:

```tsx
className="grid grid-cols-6 gap-2 sm:grid-cols-11"
```

This means an NPS scale uses a compact six-column layout on narrow screens and expands to eleven columns on larger screens.

---

## F.13 Motion and haptic feedback

GreyMatter Feedback uses a small vibration for rating and NPS selection:

```ts
navigator.vibrate(10);
```

This is optional enhancement feedback.

Important rules:

```text
[ ] The form must work when vibration is unavailable.
[ ] Vibration must not be required to understand selection state.
[ ] Do not use long or repeated vibration patterns.
[ ] Avoid unnecessary animated movement.
```

The application already checks support:

```ts
if (typeof navigator !== "undefined" && "vibrate" in navigator) {
  navigator.vibrate(10);
}
```

For users who prefer reduced motion, avoid adding large animated transitions.

A future CSS improvement:

### `src/app/globals.css`

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    transition-duration: 0.01ms !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
```

---

## F.14 Screen-reader testing tools

Test with at least one screen reader before production.

| Platform | Screen reader | Browser |
|---|---|---|
| macOS and iPhone | VoiceOver | Safari |
| Windows | NVDA | Firefox or Chrome |
| Windows | JAWS | Chrome or Edge |
| Android | TalkBack | Chrome |

### Basic VoiceOver test on macOS

1. Open **System Settings**.
2. Open **Accessibility**.
3. Open **VoiceOver**.
4. Enable VoiceOver.
5. Open a participant form.
6. Navigate through headings, questions, controls, errors, and submit status.

Confirm that VoiceOver announces:

```text
Question number
Question prompt
Required or optional status
Current selected score
Available choice options
Validation errors
Submission success or failure
```

---

## F.15 Mobile testing checklist

Test participant forms on real devices whenever possible.

### iPhone test

```text
[ ] Safari opens the QR URL.
[ ] Inputs do not auto-zoom.
[ ] Rating buttons are easy to tap.
[ ] NPS buttons fit without awkward horizontal scrolling.
[ ] Draft restores after refresh.
[ ] Haptic feedback works if supported.
[ ] Submit button remains visible.
[ ] Form works on mobile data.
```

### Android test

```text
[ ] Chrome opens the QR URL.
[ ] Rating buttons are easy to tap.
[ ] NPS controls remain readable.
[ ] Draft restores after refresh.
[ ] Vibration behavior is acceptable.
[ ] Offline retry behavior works.
```

### Low bandwidth test

In browser developer tools:

1. Open **Network**.
2. Select a slow network profile, such as:

   ```text
   Fast 3G
   ```

3. Open the participant form.
4. Confirm the page remains usable.
5. Submit feedback.
6. Confirm the application gives a useful error if the request cannot complete.

---

## F.16 Admin accessibility considerations

The administrator interface also needs accessibility.

Important admin features include:

```text
[ ] Form labels for every input.
[ ] Clear labels for question movement buttons.
[ ] Buttons with accessible names.
[ ] Status badges that include text, not only colors.
[ ] Keyboard-accessible event and session navigation.
[ ] Visible focus styles.
[ ] Error messages near forms.
[ ] Clear confirmation after publishing.
```

For example, the question-ordering controls use accessible labels:

```tsx
<button
  aria-label={`Move question ${question.orderIndex} up`}
  type="submit"
>
  ↑
</button>
```

Without `aria-label`, a screen reader might only announce:

```text
Button, up arrow
```

The label adds useful context.

---

## F.17 Accessibility acceptance checklist

Before production launch, verify:

```text
[ ] Participant form works with keyboard only.
[ ] Participant form works with a screen reader.
[ ] Required questions announce errors clearly.
[ ] Focus is always visible.
[ ] Rating and choice controls expose selected state.
[ ] No essential information depends only on color.
[ ] Controls have at least 48px touch targets.
[ ] Text inputs use at least 16px font size.
[ ] The form works at 200% browser zoom.
[ ] QR codes have a typed URL alternative.
[ ] Mobile form works on iPhone and Android.
[ ] Admin authoring controls have labels and accessible names.
[ ] PDF reports use readable typography and sufficient contrast.
```

Accessibility improvements benefit every participant. Clear labels, large controls, strong contrast, direct error messages, and responsive layouts make GreyMatter Feedback easier to use in busy real-world event environments.
