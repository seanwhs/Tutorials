# Part 2 — Building the GreyMatter Design System

## The goal

By the end of this part, GreyMatter LMS will have a small, reusable library of visual building blocks — buttons, inputs, cards, badges, alerts, progress bars, skeleton loaders, and empty states — all built from a shared set of design tokens (colors, spacing, typography defined once and reused everywhere). We'll also build a `/design-system` demonstration page showing every component and variant, and rebuild the homepage from Part 1 into a proper responsive marketing layout using these new pieces.

## Why it exists

Imagine a construction crew where every carpenter cuts their own custom-sized doorframe by eye. Nothing lines up, every room looks slightly different, and fixing one door means re-measuring every other one. A **design system** is the alternative: a fixed catalog of standard-sized doors, windows, and hinges that every room in the building uses. Once it exists, building an actual dashboard (Part 7), a course catalog (Part 4), or an instructor analytics page (Part 15) becomes an assembly job — snapping together pre-built, pre-tested pieces — rather than a fresh design exercise every single time.

There's a second, more subtle reason we build this *now*, before any real feature: if we wait until Part 7 to decide "what does a button look like," we'll end up with three slightly different buttons across three different pages, built under three different time pressures. Building the system first, deliberately, with no feature deadline attached, produces something consistent.

## The data flow

Nothing here talks to a database yet. Instead, think of the "data" flowing through this part as **design decisions**, flowing from one central source outward:

```text
Design tokens (colors, spacing, radius, fonts)
        │  defined once, in app/globals.css
        ▼
Reusable primitives (Button, Input, Card, Badge, Alert, ...)
        │  built once, in components/ui/
        ▼
Real application screens (dashboard, course pages, forms)
        │  assembled from primitives, starting Part 7 onward
```

Every later part will import from `components/ui/` instead of writing raw `<button className="...">` markup. This is the entire point of this part.

---

## Step 1 — Defining design tokens in `globals.css`

### The Target
Replacing the default Tailwind CSS starter styles with a deliberate set of **design tokens** — named, reusable values for color, spacing, and radius — that every component will reference instead of hardcoding raw values.

### The Concept
A design token is a name that stands in for a value, the same way a recipe says "add the seasoning blend" instead of listing out "2g salt, 1g pepper, 0.5g paprika" every single time. If you ever want to adjust the seasoning blend, you change it in **one place**, and every recipe using it updates automatically. Without tokens, changing GreyMatter's primary brand color later would mean hunting through dozens of files for every hardcoded `bg-indigo-600`.

Tailwind CSS v4 (which we installed in Part 1) defines tokens using an `@theme` block written directly in CSS, rather than a separate JavaScript config file like older Tailwind versions used. We'll also support **light and dark surfaces** — two color themes — by defining our tokens as CSS custom properties (variables) that change value depending on whether a `.dark` class is present on the `<html>` element, and then mapping Tailwind's theme to those variables.

### The Implementation

#### `app/globals.css`

```css
@import "tailwindcss";

/*
  ── Design tokens: the raw values ──────────────────────────────────
  These are plain CSS custom properties (variables). We define them once,
  as light-mode defaults, then override the same variable names inside a
  ".dark" selector below. Every component will reference the token NAMES
  (via Tailwind classes further down), never these raw hex values directly.
*/
:root {
  /* Surfaces — the "paper" our UI sits on, lightest to darkest */
  --color-surface: #ffffff;
  --color-surface-muted: #f8fafc;
  --color-surface-inset: #f1f5f9;

  /* Text */
  --color-text-primary: #0f172a;
  --color-text-secondary: #475569;
  --color-text-muted: #94a3b8;

  /* Borders */
  --color-border: #e2e8f0;
  --color-border-strong: #cbd5e1;

  /* Brand — GreyMatter's primary accent color, used for buttons, links,
     focus rings, and anything that should draw the eye as "actionable" */
  --color-brand: #4f46e5;
  --color-brand-hover: #4338ca;
  --color-brand-contrast: #ffffff;

  /* Semantic colors — meaning-carrying colors used in alerts and badges */
  --color-success: #16a34a;
  --color-success-surface: #f0fdf4;
  --color-warning: #d97706;
  --color-warning-surface: #fffbeb;
  --color-danger: #dc2626;
  --color-danger-surface: #fef2f2;
  --color-info: #2563eb;
  --color-info-surface: #eff6ff;

  /* Radius and spacing tokens — reused sizing decisions */
  --radius-control: 0.5rem;   /* buttons, inputs, small cards */
  --radius-panel: 0.75rem;    /* larger cards, panels, modals */
}

/*
  Dark mode overrides the exact same variable names with different values.
  Because every component below references the variable, not a hardcoded
  color, dark mode support requires zero changes to component code later —
  only this one block.
*/
.dark {
  --color-surface: #0f172a;
  --color-surface-muted: #1e293b;
  --color-surface-inset: #1e293b;

  --color-text-primary: #f8fafc;
  --color-text-secondary: #cbd5e1;
  --color-text-muted: #64748b;

  --color-border: #334155;
  --color-border-strong: #475569;

  --color-brand: #6366f1;
  --color-brand-hover: #818cf8;
  --color-brand-contrast: #0f172a;

  --color-success: #4ade80;
  --color-success-surface: #052e16;
  --color-warning: #fbbf24;
  --color-warning-surface: #451a03;
  --color-danger: #f87171;
  --color-danger-surface: #450a0a;
  --color-info: #60a5fa;
  --color-info-surface: #172554;
}

/*
  ── Tailwind theme mapping ──────────────────────────────────────────
  Tailwind v4's @theme block maps our raw CSS variables above to actual
  Tailwind utility classes. This is what makes "bg-surface" or
  "text-text-primary" valid Tailwind class names throughout the project.
*/
@theme {
  --color-surface: var(--color-surface);
  --color-surface-muted: var(--color-surface-muted);
  --color-surface-inset: var(--color-surface-inset);

  --color-text-primary: var(--color-text-primary);
  --color-text-secondary: var(--color-text-secondary);
  --color-text-muted: var(--color-text-muted);

  --color-border: var(--color-border);
  --color-border-strong: var(--color-border-strong);

  --color-brand: var(--color-brand);
  --color-brand-hover: var(--color-brand-hover);
  --color-brand-contrast: var(--color-brand-contrast);

  --color-success: var(--color-success);
  --color-success-surface: var(--color-success-surface);
  --color-warning: var(--color-warning);
  --color-warning-surface: var(--color-warning-surface);
  --color-danger: var(--color-danger);
  --color-danger-surface: var(--color-danger-surface);
  --color-info: var(--color-info);
  --color-info-surface: var(--color-info-surface);

  --radius-control: var(--radius-control);
  --radius-panel: var(--radius-panel);

  --font-sans: "Inter", ui-sans-serif, system-ui, -apple-system, sans-serif;
}

/*
  ── Base element defaults ────────────────────────────────────────────
  A small set of sane defaults so raw HTML elements look intentional
  even before any component class is applied.
*/
body {
  background-color: var(--color-surface);
  color: var(--color-text-primary);
  font-family: var(--font-sans);
}

/* Accessible focus styling — every interactive element gets a visible,
   consistent focus ring rather than relying on (or removing) browser
   defaults, which vary wildly between browsers. */
:focus-visible {
  outline: 2px solid var(--color-brand);
  outline-offset: 2px;
}
```

**Code walkthrough:**

- We separate **raw tokens** (`:root` and `.dark`, plain CSS variables) from the **Tailwind mapping** (`@theme`). This two-layer setup is what lets `.dark` swap every color at once — Tailwind classes like `bg-surface` always point at the *variable*, and the variable's actual value depends on whether `.dark` is present on an ancestor element.
- `:focus-visible` (rather than plain `:focus`) means the focus ring only appears for keyboard navigation (Tab key), not for mouse clicks — this is the modern accessible default, avoiding the common complaint of "ugly blue outlines" appearing on every mouse click while still fully supporting keyboard and screen-reader users.
- We're intentionally *not* installing a font package yet — `--font-sans` falls back gracefully to system fonts. Adding a custom web font is a valid later enhancement, not a foundational requirement.

### The Verification

Restart the dev server (Tailwind's `@theme` block requires a fresh compile) and confirm nothing is broken:

```bash
npm run dev
```

Visit `http://localhost:3000` — the page should render exactly as it did at the end of Part 1 (we haven't changed any component usage yet, just defined new tokens that nothing consumes yet). Then test that a token-based class actually works by temporarily adding `className="bg-surface-muted"` to any element and confirming it renders a light gray background — then remove that test class, since we'll wire real components to these tokens next.

---

## Step 2 — Building the `Button` component

### The Target
`components/ui/button.tsx` — a single, flexible button component supporting multiple visual variants (`primary`, `secondary`, `outline`, `ghost`, `danger`) and sizes, used everywhere in the app from this point forward.

### The Concept
Think about light switches in a well-designed house: every switch, regardless of which room it's in, has the same shape, click feel, and placement height. You never have to relearn how to use a light switch room to room. A single `Button` component is that same guarantee for our UI — a "primary" action always looks and behaves identically whether it's "Enroll Now" on a course page or "Save Changes" in account settings.

We'll build this using a small, well-established pattern: a `variant` prop mapped to a lookup object of class strings, combined with a `cn()` helper for merging class names safely (avoiding duplicate or conflicting Tailwind classes when a caller wants to add their own).

### The Implementation

First, we need the `cn()` utility itself. It combines two small libraries: `clsx` (conditionally joins class name strings) and `tailwind-merge` (resolves conflicts when two Tailwind classes target the same CSS property, e.g. `px-2` and `px-4` both being passed).

```bash
npm install clsx tailwind-merge
```

#### `lib/cn.ts`

```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

// cn() = "class names". It accepts any mix of strings, conditionals, and
// arrays (via clsx), then runs the result through twMerge so that if two
// conflicting Tailwind classes are present (e.g. a default "px-4" and a
// caller-supplied override "px-2"), the LAST one wins cleanly instead of
// both being applied and the browser picking one unpredictably.
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

Now the button itself:

#### `components/ui/button.tsx`

```tsx
import { cn } from "@/lib/cn";
import type { ButtonHTMLAttributes } from "react";

// We extend the native <button> element's props so our component accepts
// everything a real <button> accepts (onClick, type, disabled, etc.) plus
// our own two additions: "variant" and "size". This means callers never
// lose access to standard HTML button behavior by using our wrapper.
export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "outline" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
}

// A lookup object mapping each variant name to its class string. This
// pattern — rather than a long if/else chain — keeps every visual option
// visible at a glance and easy to extend later (e.g. adding a "success"
// variant is a one-line addition).
const variantClasses: Record<NonNullable<ButtonProps["variant"]>, string> = {
  primary:
    "bg-brand text-brand-contrast hover:bg-brand-hover shadow-sm",
  secondary:
    "bg-surface-inset text-text-primary hover:bg-border",
  outline:
    "border border-border-strong bg-transparent text-text-primary hover:bg-surface-muted",
  ghost:
    "bg-transparent text-text-primary hover:bg-surface-muted",
  danger:
    "bg-danger text-white hover:opacity-90 shadow-sm",
};

const sizeClasses: Record<NonNullable<ButtonProps["size"]>, string> = {
  sm: "h-8 px-3 text-sm",
  md: "h-10 px-4 text-sm",
  lg: "h-12 px-6 text-base",
};

export function Button({
  variant = "primary",
  size = "md",
  className,
  disabled,
  ...props // captures every remaining native <button> prop (onClick, type, aria-*, etc.)
}: ButtonProps) {
  return (
    <button
      // The "disabled" styling is applied via a Tailwind data/aria selector
      // pattern here through plain conditional classes for simplicity —
      // disabled buttons should never look interactive or clickable.
      className={cn(
        "inline-flex items-center justify-center gap-2 rounded-[var(--radius-control)] font-medium transition-colors duration-150",
        "disabled:cursor-not-allowed disabled:opacity-50",
        variantClasses[variant],
        sizeClasses[size],
        className // caller-supplied classes are merged LAST so they can override defaults via cn()'s twMerge behavior
      )}
      disabled={disabled}
      {...props}
    >
      {props.children}
    </button>
  );
}
```

**Code walkthrough:**

- `extends ButtonHTMLAttributes<HTMLButtonElement>` — this is a TypeScript technique that "inherits" every prop a real HTML `<button>` supports. Without this, callers couldn't pass `type="submit"` or `onClick` without us manually re-declaring every single one.
- The `variantClasses` and `sizeClasses` lookup objects are typed with `Record<NonNullable<ButtonProps["variant"]>, string>` — this is TypeScript enforcing that if we ever add a new variant name to the `ButtonProps` union (say, `"success"`), TypeScript will immediately error here until we also add a matching entry to `variantClasses`. This is a small but valuable guardrail: it makes it *impossible* to forget styling a new variant.
- `{...props}` spread at the end passes through anything else the caller supplied (`onClick`, `type`, `aria-label`, `disabled`, etc.) directly onto the real `<button>` element — our component is a thin, well-styled wrapper, not a replacement for native button behavior.
- `className` is deliberately destructured out separately and merged via `cn()` rather than spread — this guarantees our own classes and the caller's classes are combined intelligently (with `tailwind-merge` resolving conflicts) instead of the caller's `className` prop silently overwriting ours entirely.

### The Verification

We'll verify this visually once the demonstration page exists in Step 9 — but you can do a quick sanity check right now by temporarily dropping this into `app/page.tsx` above the existing content:

```tsx
import { Button } from "@/components/ui/button";
// ...
<Button variant="primary">Test Button</Button>
```

Confirm it renders a dark indigo, rounded button. Remove this test snippet once confirmed — the real demonstration page in Step 9 will showcase every variant properly.

---

## Step 3 — Building the `Input` and `Textarea` components

### The Target
`components/ui/input.tsx` and `components/ui/textarea.tsx` — styled, accessible form controls that will be used everywhere from the Part 6 sign-in forms to the Part 15 instructor tools.

### The Concept
A good form input is like a well-labeled mailbox slot: it should be obvious what goes in it, obvious when something's wrong (mail rejected, slot too small), and consistent no matter which house you're standing in front of. We'll build in support for an associated `label`, a `hint` (helper text), and an `error` state from the very beginning — retrofitting error states onto a form library later, after dozens of forms already exist, is exactly the kind of rework a design system exists to prevent.

### The Implementation

#### `components/ui/input.tsx`

```tsx
import { cn } from "@/lib/cn";
import { useId, type InputHTMLAttributes } from "react";

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  hint?: string;
  error?: string;
}

export function Input({
  label,
  hint,
  error,
  className,
  id,
  ...props
}: InputProps) {
  // useId() generates a stable, unique ID per component instance — this is
  // what lets us wire the <label> to the <input> correctly (via htmlFor/id)
  // even when a caller doesn't manually supply an id prop. Screen readers
  // rely on this connection to announce "Email address, edit text" instead
  // of just "edit text".
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const hintId = hint ? `${inputId}-hint` : undefined;
  const errorId = error ? `${inputId}-error` : undefined;

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={inputId} className="text-sm font-medium text-text-primary">
          {label}
        </label>
      )}
      <input
        id={inputId}
        // aria-invalid tells assistive technology this field currently
        // fails validation — paired with aria-describedby pointing at the
        // actual error message so a screen reader announces WHY it's invalid.
        aria-invalid={Boolean(error)}
        aria-describedby={cn(hintId, errorId) || undefined}
        className={cn(
          "h-10 w-full rounded-[var(--radius-control)] border bg-surface px-3 text-sm text-text-primary placeholder:text-text-muted",
          "border-border focus-visible:border-brand",
          error && "border-danger focus-visible:outline-danger",
          "disabled:cursor-not-allowed disabled:bg-surface-inset disabled:opacity-60",
          className
        )}
        {...props}
      />
      {hint && !error && (
        <p id={hintId} className="text-xs text-text-secondary">
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} className="text-xs font-medium text-danger" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
```

#### `components/ui/textarea.tsx`

```tsx
import { cn } from "@/lib/cn";
import { useId, type TextareaHTMLAttributes } from "react";

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  hint?: string;
  error?: string;
}

export function Textarea({
  label,
  hint,
  error,
  className,
  id,
  rows = 4,
  ...props
}: TextareaProps) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const hintId = hint ? `${inputId}-hint` : undefined;
  const errorId = error ? `${inputId}-error` : undefined;

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={inputId} className="text-sm font-medium text-text-primary">
          {label}
        </label>
      )}
      <textarea
        id={inputId}
        rows={rows}
        aria-invalid={Boolean(error)}
        aria-describedby={cn(hintId, errorId) || undefined}
        className={cn(
          "w-full resize-y rounded-[var(--radius-control)] border bg-surface px-3 py-2 text-sm text-text-primary placeholder:text-text-muted",
          "border-border focus-visible:border-brand",
          error && "border-danger focus-visible:outline-danger",
          "disabled:cursor-not-allowed disabled:bg-surface-inset disabled:opacity-60",
          className
        )}
        {...props}
      />
      {hint && !error && (
        <p id={hintId} className="text-xs text-text-secondary">
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} className="text-xs font-medium text-danger" role="alert">
          {error}
        </p>
      )}
    </div>
  );
}
```

**Code walkthrough:**

- `useId()` is a React 19 Hook that solves a subtle but real problem: if we hardcoded `id="input-field"` inside the component, rendering two `<Input>` components on the same page would produce two elements with the *same* `id`, which is invalid HTML and breaks label association for the second one. `useId()` guarantees a unique value per rendered instance automatically.
- `aria-describedby={cn(hintId, errorId) || undefined}` — we're reusing our `cn()` class-merging helper for a slightly unusual purpose here: joining two possibly-undefined ID strings with a space, exactly the format `aria-describedby` expects when pointing at multiple elements. If both `hintId` and `errorId` are `undefined`, `cn()` returns an empty string, and `|| undefined` converts that empty string into an actual `undefined` so React omits the attribute entirely rather than rendering `aria-describedby=""`.
- Both components accept **every** native prop (`InputHTMLAttributes`/`TextareaHTMLAttributes`), so `onChange`, `value`, `required`, `maxLength`, `name`, etc. all work exactly as they would on a raw `<input>` or `<textarea>` — we've added label/hint/error on top, not replaced anything.

### The Verification

Deferred to the demonstration page in Step 9, where we'll render both an empty and an error-state input side by side.

---

## Step 4 — Building the `Card` component

### The Target
`components/ui/card.tsx` — a container primitive used for course tiles, dashboard panels, and settings sections throughout the rest of the series.

### The Concept
A card is a picture frame: it doesn't dictate what's inside (a photo, a certificate, a receipt), only that whatever *is* inside gets a consistent border, padding, and background so it reads as "one distinct unit" on a busy page. We'll build it as a small family of sub-components (`Card`, `CardHeader`, `CardTitle`, `CardContent`, `CardFooter`) rather than one rigid component with a dozen props — this is a common, flexible pattern called **composition**, where the caller assembles pieces rather than configuring one giant component through props.

### The Implementation

#### `components/ui/card.tsx`

```tsx
import { cn } from "@/lib/cn";
import type { HTMLAttributes } from "react";

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "rounded-[var(--radius-panel)] border border-border bg-surface shadow-sm",
        className
      )}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("flex flex-col gap-1 border-b border-border px-5 py-4", className)}
      {...props}
    />
  );
}

export function CardTitle({ className, ...props }: HTMLAttributes<HTMLHeadingElement>) {
  return (
    <h3
      className={cn("text-base font-semibold text-text-primary", className)}
      {...props}
    />
  );
}

export function CardDescription({ className, ...props }: HTMLAttributes<HTMLParagraphElement>) {
  return (
    <p className={cn("text-sm text-text-secondary", className)} {...props} />
  );
}

export function CardContent({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("px-5 py-4", className)} {...props} />;
}

export function CardFooter({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("flex items-center gap-3 border-t border-border px-5 py-4", className)}
      {...props}
    />
  );
}
```

**Code walkthrough:**

- Every sub-component simply extends `HTMLAttributes<HTMLDivElement>` (or the appropriate element type) and spreads `...props` — this means every card piece still behaves like a normal `div`/`h3`/`p` (accepting `onClick`, `id`, `data-*` attributes, etc.), we're purely layering default styling on top.
- Splitting into `CardHeader`/`CardContent`/`CardFooter` rather than one component with a `header`/`footer`/`children` prop means callers can freely omit any section, reorder them, or nest arbitrary custom markup inside any one of them — composition over configuration.

### The Verification

Deferred to Step 9.

---

## Step 5 — Building `Badge` and `Alert` components

### The Target
`components/ui/badge.tsx` (small status labels — "Published," "Draft," "Instructor") and `components/ui/alert.tsx` (larger inline messages — success confirmations, warnings, errors) — both built on the same semantic color tokens (`success`, `warning`, `danger`, `info`) defined in Step 1.

### The Concept
Think of a badge as a name tag at a conference — small, glanceable, telling you one fact at a glance ("Speaker," "Staff," "VIP"). An alert is more like a printed notice taped to a door — bigger, meant to be read fully, often explaining *why* something happened, not just labeling it. Both use the same underlying color vocabulary (green = good, amber = caution, red = problem
Both use the same underlying color vocabulary (green = good, amber = caution, red = problem, blue = neutral information) so that a student never has to relearn what a color means depending on which part of the screen it appears in.

### The Implementation

#### `components/ui/badge.tsx`

```tsx
import { cn } from "@/lib/cn";
import type { HTMLAttributes } from "react";

export interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant?: "neutral" | "success" | "warning" | "danger" | "info" | "brand";
}

const variantClasses: Record<NonNullable<BadgeProps["variant"]>, string> = {
  neutral: "bg-surface-inset text-text-secondary",
  success: "bg-success-surface text-success",
  warning: "bg-warning-surface text-warning",
  danger: "bg-danger-surface text-danger",
  info: "bg-info-surface text-info",
  brand: "bg-brand text-brand-contrast",
};

export function Badge({ variant = "neutral", className, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        variantClasses[variant],
        className
      )}
      {...props}
    />
  );
}
```

#### `components/ui/alert.tsx`

```tsx
import { cn } from "@/lib/cn";
import type { HTMLAttributes } from "react";

export interface AlertProps extends HTMLAttributes<HTMLDivElement> {
  variant?: "neutral" | "success" | "warning" | "danger" | "info";
  title?: string;
}

const variantClasses: Record<NonNullable<AlertProps["variant"]>, string> = {
  neutral: "bg-surface-inset border-border text-text-primary",
  success: "bg-success-surface border-success/30 text-success",
  warning: "bg-warning-surface border-warning/30 text-warning",
  danger: "bg-danger-surface border-danger/30 text-danger",
  info: "bg-info-surface border-info/30 text-info",
};

export function Alert({
  variant = "neutral",
  title,
  className,
  children,
  ...props
}: AlertProps) {
  return (
    <div
      // role="alert" tells assistive technology to announce this content
      // immediately when it appears, without the user needing to navigate
      // to it manually — appropriate for form errors and important status
      // changes, but should NOT be used for large static blocks of text,
      // since that would interrupt screen reader users unnecessarily.
      role="alert"
      className={cn(
        "rounded-[var(--radius-panel)] border px-4 py-3 text-sm",
        variantClasses[variant],
        className
      )}
      {...props}
    >
      {title && <p className="mb-1 font-semibold">{title}</p>}
      <div className="text-text-secondary [&:not(:first-child)]:text-inherit">
        {children}
      </div>
    </div>
  );
}
```

**Code walkthrough:**

- Both components share the exact same variant-name vocabulary (`success`, `warning`, `danger`, `info`, plus `neutral`) as deliberate design consistency — a green `Badge` and a green `Alert` always mean the same thing on any screen in the app.
- `border-success/30` uses Tailwind's color-opacity shorthand — `/30` means "30% opacity of this color" — giving alert borders a softer tint than the solid text/background colors, a common refinement for making colored boxes feel less harsh.
- `role="alert"` is a meaningful accessibility decision, not decoration: screen readers treat elements with this role as "live regions" that get announced the moment they appear in the DOM, which matters enormously for things like form validation errors later in the series.

### The Verification

Deferred to Step 9.

---

## Step 6 — Building the `ProgressBar` component

### The Target
`components/ui/progress-bar.tsx` — a horizontal progress indicator that will show course-completion percentage throughout the student dashboard (Part 7 onward).

### The Concept
A progress bar is the fuel gauge in a car: a single glance tells you "mostly full," "about half," or "almost empty," without needing to read an exact number. We'll build ours to accept a `value` (0–100) and always render it accessibly, using the `role="progressbar"` ARIA pattern, so screen reader users get the same "mostly full" signal that sighted users get visually.

### The Implementation

#### `components/ui/progress-bar.tsx`

```tsx
import { cn } from "@/lib/cn";

export interface ProgressBarProps {
  value: number; // expected range: 0–100
  label?: string;
  className?: string;
}

export function ProgressBar({ value, label, className }: ProgressBarProps) {
  // Clamp the value defensively — a caller passing 130 or -10 (e.g. from a
  // buggy percentage calculation upstream) should never visually break out
  // of the track or render a nonsensical ARIA value.
  const safeValue = Math.min(100, Math.max(0, Math.round(value)));

  return (
    <div className={cn("flex flex-col gap-1.5", className)}>
      {label && (
        <div className="flex items-center justify-between text-xs text-text-secondary">
          <span>{label}</span>
          <span>{safeValue}%</span>
        </div>
      )}
      <div
        role="progressbar"
        aria-valuenow={safeValue}
        aria-valuemin={0}
        aria-valuemax={100}
        aria-label={label ?? "Progress"}
        className="h-2 w-full overflow-hidden rounded-full bg-surface-inset"
      >
        <div
          className="h-full rounded-full bg-brand transition-[width] duration-300 ease-out"
          style={{ width: `${safeValue}%` }}
        />
      </div>
    </div>
  );
}
```

**Code walkthrough:**

- `Math.min(100, Math.max(0, Math.round(value)))` is a "clamp" — a very common defensive pattern worth recognizing anywhere in this series: it guarantees the final number can never fall outside `[0, 100]` regardless of what garbage value comes in, which matters because this component will eventually receive values computed from real (and occasionally messy) database data in Part 13.
- `role="progressbar"` with `aria-valuenow`/`aria-valuemin`/`aria-valuemax` is the standard accessible pattern for any custom (non-`<progress>` tag) progress indicator — it lets assistive technology announce "42 percent" even though the visual bar is just two `<div>`s and a CSS width.
- We use inline `style={{ width: ... }}` rather than a Tailwind class here deliberately — Tailwind's utility classes are fixed at build time (`w-1/2`, `w-3/4`, etc.), but our percentage is a dynamic runtime value that could be *any* number 0–100, which inline styles handle correctly and utility classes cannot.

### The Verification

Deferred to Step 9.

---

## Step 7 — Building `Skeleton` loading placeholders

### The Target
`components/ui/skeleton.tsx` — a simple animated placeholder block used to indicate "content is loading" before real data arrives, which we'll pair with React's `<Suspense>` boundaries starting in Part 4.

### The Concept
Think of a skeleton loader as the "reserved" place-card at a wedding banquet table — it shows you the exact shape and size of what's coming (a name card, roughly business-card sized) before the actual guest arrives. This is a deliberate improvement over a blank white screen or a generic spinner: it tells the user *where* content will appear and roughly *how much*, reducing the jarring "layout jump" that happens when content suddenly pops in.

### The Implementation

#### `components/ui/skeleton.tsx`

```tsx
import { cn } from "@/lib/cn";
import type { HTMLAttributes } from "react";

export function Skeleton({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      // aria-hidden because a skeleton is purely a visual loading cue —
      // screen readers should skip it entirely rather than announcing an
      // empty gray box, which would be meaningless noise to a non-sighted user.
      aria-hidden="true"
      className={cn(
        "animate-pulse rounded-[var(--radius-control)] bg-surface-inset",
        className
      )}
      {...props}
    />
  );
}
```

**Code walkthrough:**

- `animate-pulse` is a Tailwind built-in animation utility — no custom CSS keyframes needed, it fades opacity in and out on a loop automatically.
- `aria-hidden="true"` is a small but important accessibility detail: without it, a screen reader might announce something like "blank, blank, blank" for every loading skeleton on a page, which is unhelpful noise. Real loading state announcements (e.g., "Loading courses...") should instead be handled with a proper `aria-live` region elsewhere, which we'll add when we build actual `<Suspense>` fallbacks in Part 4.
- Because `Skeleton` is just a styled `div` accepting `className` and any other `div` prop, callers can shape it into anything — a text-line placeholder (`className="h-4 w-3/4"`), an avatar circle (`className="h-10 w-10 rounded-full"`), or a full card outline — by simply changing the className, without needing separate `SkeletonText`, `SkeletonAvatar`, etc. components.

### The Verification

Deferred to Step 9.

---

## Step 8 — Building the `EmptyState` component

### The Target
`components/ui/empty-state.tsx` — a friendly placeholder shown when a list has zero items (no enrolled courses yet, no students yet, no notifications yet), which we will reuse in Part 7's dashboard, Part 14's notification center, and Part 15's instructor tools.

### The Concept
An empty state is the difference between walking into a library where a shelf is simply bare — confusing, looks broken, like something's missing — versus walking into a shelf with a small sign saying "New arrivals coming soon — browse our catalog in the meantime." Both show zero books, but only one of them tells the visitor what's going on and what to do next. Without a deliberate `EmptyState` component, "zero items" tends to accidentally render as a blank, broken-looking gap in the UI — this component exists specifically to prevent that.

### The Implementation

#### `components/ui/empty-state.tsx`

```tsx
import { cn } from "@/lib/cn";
import type { ReactNode } from "react";

export interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}

export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center gap-3 rounded-[var(--radius-panel)] border border-dashed border-border bg-surface-muted px-6 py-12 text-center",
        className
      )}
    >
      {icon && (
        <div className="text-text-muted" aria-hidden="true">
          {icon}
        </div>
      )}
      <div className="flex flex-col gap-1">
        <p className="text-sm font-semibold text-text-primary">{title}</p>
        {description && (
          <p className="max-w-sm text-sm text-text-secondary">{description}</p>
        )}
      </div>
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}
```

**Code walkthrough:**

- `border-dashed` is a deliberate visual signal distinguishing an empty state from a normal `Card` (which uses a solid border) — the dashed line communicates "this is a placeholder area," similar to how architectural blueprints use dashed lines for planned-but-not-yet-built structures.
- `icon`, `action`, and `description` are all optional — a caller can render a bare-minimum empty state with just a `title` ("No courses yet") or a fully decorated one with an icon and a `<Button>` as the `action` (e.g., "Browse the catalog" in Part 7). This keeps the component useful in both simple and rich contexts without needing two separate components.
- `aria-hidden="true"` on the icon wrapper follows the same reasoning as `Skeleton` — decorative icons shouldn't be individually announced by a screen reader when the adjacent `title` text already conveys the same meaning in words.

### The Verification

Deferred to Step 9 — now let's actually build that page.

---

## Step 9 — Building the `/design-system` demonstration page

### The Target
`app/design-system/page.tsx` — a single page rendering every component and variant we just built, so we can visually confirm the entire library at once, in one browser tab, before using any of it in a real feature.

### The Concept
This is the same idea as a paint store's sample wall — every available color and finish displayed side-by-side under the same lighting, so you can compare options directly rather than judging one paint chip at a time under different conditions. We'll never link to this page from the public site; it exists purely as an internal development tool.

### The Implementation

#### `app/design-system/page.tsx`

```tsx
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { Input } from "@/components/ui/input";
import { ProgressBar } from "@/components/ui/progress-bar";
import { Skeleton } from "@/components/ui/skeleton";
import { Textarea } from "@/components/ui/textarea";

// A small local layout helper for this page only — groups a section title
// with its demo content. Not exported, not part of the design system itself.
function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="flex flex-col gap-4">
      <h2 className="text-lg font-semibold text-text-primary">{title}</h2>
      <div className="flex flex-wrap items-start gap-4">{children}</div>
    </section>
  );
}

export default function DesignSystemPage() {
  return (
    <main className="mx-auto flex max-w-4xl flex-col gap-12 px-6 py-12">
      <div>
        <h1 className="text-3xl font-bold text-text-primary">GreyMatter Design System</h1>
        <p className="mt-2 text-text-secondary">
          Internal reference page. Not linked from the public site.
        </p>
      </div>

      <Section title="Buttons">
        <Button variant="primary">Primary</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="outline">Outline</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="danger">Danger</Button>
        <Button variant="primary" disabled>
          Disabled
        </Button>
        <Button variant="primary" size="sm">
          Small
        </Button>
        <Button variant="primary" size="lg">
          Large
        </Button>
      </Section>

      <Section title="Badges">
        <Badge variant="neutral">Neutral</Badge>
        <Badge variant="brand">Brand</Badge>
        <Badge variant="success">Published</Badge>
        <Badge variant="warning">Draft</Badge>
        <Badge variant="danger">Archived</Badge>
        <Badge variant="info">Info</Badge>
      </Section>

      <Section title="Alerts">
        <div className="flex w-full flex-col gap-3">
          <Alert variant="success" title="Enrollment confirmed">
            You have successfully enrolled in this course.
          </Alert>
          <Alert variant="warning" title="Attempt limit approaching">
            You have 1 attempt remaining on this assessment.
          </Alert>
          <Alert variant="danger" title="Submission failed">
            We could not verify your enrollment for this lesson.
          </Alert>
          <Alert variant="info" title="Heads up">
            New content was published to this course.
          </Alert>
        </div>
      </Section>

      <Section title="Inputs">
        <div className="flex w-full max-w-sm flex-col gap-4">
          <Input label="Email address" placeholder="you@example.com" />
          <Input
            label="Course title"
            defaultValue="Intro to Databases"
            error="This title is already in use."
          />
          <Textarea label="Course description" placeholder="Describe your course..." />
        </div>
      </Section>

      <Section title="Progress bars">
        <div className="flex w-full max-w-sm flex-col gap-4">
          <ProgressBar value={12} label="Getting Started with SQL" />
          <ProgressBar value={68} label="React Fundamentals" />
          <ProgressBar value={100} label="HTML Basics" />
        </div>
      </Section>

      <Section title="Skeletons">
        <div className="flex w-full max-w-sm flex-col gap-3">
          <Skeleton className="h-4 w-3/4" />
          <Skeleton className="h-4 w-1/2" />
          <Skeleton className="h-24 w-full" />
        </div>
      </Section>

      <Section title="Empty state">
        <EmptyState
          title="No courses yet"
          description="You haven't enrolled in any courses. Browse the catalog to get started."
          action={<Button variant="primary">Browse Catalog</Button>}
        />
      </Section>

      <Section title="Card">
        <Card className="w-full max-w-sm">
          <CardHeader>
            <CardTitle>React Fundamentals</CardTitle>
            <CardDescription>
              Learn the building blocks of modern React applications.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <ProgressBar value={45} label="Your progress" />
          </CardContent>
          <CardFooter>
            <Button variant="primary" size="sm">
              Continue Learning
            </Button>
            <Button variant="ghost" size="sm">
              View Details
            </Button>
          </CardFooter>
        </Card>
      </Section>
    </main>
  );
}
```

### The Verification

```bash
npm run dev
```

Visit **http://localhost:3000/design-system**. You should see every section rendered: five button variants plus disabled/small/large states, six badge colors, four colored alerts, two inputs (one showing an error state in red) plus a textarea, three progress bars at different fill levels, a set of pulsing gray skeleton blocks, a dashed-border empty state with a button inside it, and finally a fully assembled course card combining `Card`, `ProgressBar`, and `Button` together.

Resize your browser window narrower (or open DevTools' device toolbar) and confirm the button and badge rows wrap naturally onto new lines rather than overflowing horizontally — this is `flex-wrap` from the `Section` helper doing its job.

Run the full verification suite to confirm nothing regressed:

```bash
npm run lint
npm run typecheck
npm run build
```

All three should complete without errors.

---

## Step 10 — Rebuilding the homepage as a responsive marketing layout

### The Target
Replacing Part 1's minimal homepage with a proper marketing layout — hero section, feature highlights, and a call to action — built entirely from the `components/ui/` primitives we just created, proving the design system holds up under a real (if still simple) page.

### The Concept
This step is the "dress rehearsal" — we're not adding any new components, only *assembling* existing ones into a real page, the way a furniture designer's real test isn't the individual chair, but whether four chairs and a table actually work together around a room.

### The Implementation

#### `app/page.tsx`

```tsx
import { HealthCheckButton } from "@/components/health-check-button";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getAppInfo } from "@/lib/get-app-info";

const features = [
  {
    title: "Author once, teach everyone",
    description:
      "Courses, chapters, and lessons are authored in Sanity Studio and published instantly to every enrolled student.",
  },
  {
    title: "Progress you can trust",
    description:
      "Every quiz and exercise is graded on the server — never in the student's browser — so results are always authoritative.",
  },
  {
    title: "Built for real classrooms",
    description:
      "Role-based access for students, instructors, and administrators, backed by a production-grade PostgreSQL database.",
  },
];

export default function HomePage() {
  const info = getAppInfo();

  return (
    <main className="flex flex-col">
      {/* Hero section */}
      <section className="mx-auto flex max-w-3xl flex-col items-center gap-6 px-6 py-24 text-center">
        <Badge variant="brand">{info.environment} build</Badge>
        <h1 className="text-4xl font-bold tracking-tight text-text-primary sm:text-5xl">
          {info.name}
        </h1>
        <p className="max-w-xl text-lg text-text-secondary">
          A full-stack learning platform, built from an empty folder to a
          production deployment — one part at a time.
        </p>
        <div className="flex flex-wrap items-center justify-center gap-3">
          <Button variant="primary" size="lg">
            Browse Courses
          </Button>
          <Button variant="outline" size="lg">
            Sign In
          </Button>
        </div>
      </section>

      {/* Feature grid — responsive: single column on mobile, three columns
          on larger screens. This is the layout's real test of responsiveness. */}
      <section className="mx-auto grid w-full max-w-5xl grid-cols-1 gap-6 px-6 pb-24 sm:grid-cols-3">
        {features.map((feature) => (
          <Card key={feature.title}>
            <CardHeader>
              <CardTitle>{feature.title}</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-text-secondary">{feature.description}</p>
            </CardContent>
          </Card>
        ))}
      </section>

      {/* Development-only diagnostic, carried over from Part 1. We'll
          remove this section entirely once real authentication and
          navigation exist in Part 6–7. */}
      <section className="mx-auto flex w-full max-w-3xl flex-col items-center gap-3 border-t border-border px-6 py-10 text-center">
        <p className="text-xs font-medium uppercase tracking-wide text-text-muted">
          Developer diagnostic
        </p>
        <HealthCheckButton />
      </section>
    </main>
  );
}
```

**Code walkthrough:**

- `features.map(...)` renders the three `Card`s from a plain array of data rather than hand-writing three near-identical JSX blocks — a small habit worth building early, since it means adding a fourth feature later is a one-line array edit, not a copy-paste-and-modify operation prone to drift.
- `grid-cols-1 sm:grid-cols-3` is Tailwind's mobile-first responsive syntax: the base (unprefixed) class applies at all screen sizes, and `sm:` (small breakpoint, 640px and up) *overrides* it only at that width or wider. We default to single-column stacking on mobile, which is almost always the correct default for card grids — three cramped columns on a phone screen is a common beginner mistake this pattern avoids automatically.
- We intentionally kept the Part 1 `HealthCheckButton` diagnostic on the page for now, but visually demoted it (small uppercase label, border separator) — it's still useful for our own testing but no longer competing visually with the real marketing content above it.

### The Verification

```bash
npm run dev
```

Visit `http://localhost:3000` and confirm:

1. A centered hero section with a brand-colored "development build" badge, heading, subtext, and two buttons (primary "Browse Courses" and outline "Sign In").
2. Below it, three feature cards. Resize the browser narrower than 640px and confirm they stack into a single column; widen past 640px and confirm they arrange into three columns side by side.
3. At the bottom, the diagnostic health-check button still functions exactly as it did in Part 1 — click it and confirm the same `✅ ok` response appears.

Run the full check suite one more time:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **`bg-surface`, `text-text-primary`, etc. are not recognized / render as no styling** — Usually means the dev server needs a full restart after editing `app/globals.css`, since Tailwind's `@theme` block is processed at build/startup time, not always hot-reloaded reliably for brand-new token names. Stop and rerun `npm run dev`.
- **Dark mode variables don't seem to do anything** — Expected at this stage: nothing yet toggles the `.dark` class onto `<html>`. We've only *defined* the dark palette; wiring up an actual theme toggle is an optional enhancement, not required by any later part, since GreyMatter's tutorial screens are all designed and verified against the light theme.
- **`cn()` import errors: "Cannot find module 'clsx'"** — Means `npm install clsx tailwind-merge` from Step 2 wasn't run, or was run in the wrong directory. Confirm you're at the project root and rerun the install.
- **Focus ring color looks wrong or invisible** — Confirm `:focus-visible` in `globals.css` wasn't accidentally overwritten; also note some browsers only show `:focus-visible` styling on keyboard Tab navigation, not mouse clicks — this is expected, correct behavior, not a bug.
- **TypeScript error: "Property 'children' does not exist"** on a component using `HTMLAttributes<...>` — Make sure you're spreading `...props` *after* destructuring `className`, and that the component's return statement actually renders `{props.children}` or spreads `{...props}` onto the root element; omitting either will silently drop children at runtime even if TypeScript doesn't complain.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see the new files: `app/globals.css` (modified), `lib/cn.ts`, `components/ui/button.tsx`, `components/ui/input.tsx`, `components/ui/textarea.tsx`, `components/ui/card.tsx`, `components/ui/badge.tsx`, `components/ui/alert.tsx`, `components/ui/progress-bar.tsx`, `components/ui/skeleton.tsx`, `components/ui/empty-state.tsx`, `app/design-system/page.tsx`, and `app/page.tsx` (modified).

```bash
git commit -m "Part 2: GreyMatter design system — tokens, UI primitives, design-system demo page, marketing homepage"
```

---

## Reference: component API summary

A quick lookup table for every primitive built in this part — keep this handy, since every remaining part in the series will reference these components by name without re-explaining their props.

| Component | Key props | Notes |
|---|---|---|
| `Button` | `variant` (`primary`\|`secondary`\|`outline`\|`ghost`\|`danger`), `size` (`sm`\|`md`\|`lg`), plus all native `<button>` props | Defaults: `variant="primary"`, `size="md"` |
| `Input` | `label`, `hint`, `error`, plus all native `<input>` props | Auto-generates accessible `id`/`aria-describedby` via `useId()` |
| `Textarea` | `label`, `hint`, `error`, `rows`, plus all native `<textarea>` props | Same accessibility wiring as `Input` |
| `Card` / `CardHeader` / `CardTitle` / `CardDescription` / `CardContent` / `CardFooter` | All accept native `div`/`h3`/`p` props + `className` | Composable — omit or reorder any section freely |
| `Badge` | `variant` (`neutral`\|`success`\|`warning`\|`danger`\|`info`\|`brand`) | Small inline status label |
| `Alert` | `variant` (`neutral`\|`success`\|`warning`\|`danger`\|`info`), `title` | `role="alert"` — announced immediately by screen readers |
| `ProgressBar` | `value` (0–100, clamped automatically), `label` | Accessible `role="progressbar"` with live value announcement |
| `Skeleton` | `className` to control shape/size | `aria-hidden` — purely visual loading placeholder |
| `EmptyState` | `icon`, `title`, `description`, `action` | Only `title` is required |

---

## Reference: design token cheat sheet

| Token | Usage |
|---|---|
| `bg-surface` / `text-text-primary` | Default page/card background and primary text |
| `bg-surface-muted` / `bg-surface-inset` | Slightly recessed backgrounds (page sections, disabled inputs, skeletons) |
| `border-border` / `border-border-strong` | Default and emphasized borders |
| `bg-brand` / `bg-brand-hover` / `text-brand-contrast` | Primary actionable color (buttons, links, focus rings) |
| `*-success` / `*-warning` / `*-danger` / `*-info` (`*-surface` variants included) | Semantic meaning — always paired the same way across badges and alerts |
| `rounded-[var(--radius-control)]` | Small controls: buttons, inputs, badges |
| `rounded-[var(--radius-panel)]` | Larger containers: cards, alerts, empty states |

---

## What's next

Part 3 leaves the frontend entirely and moves into content modeling: we'll create a real Sanity project, embed Sanity Studio directly inside our Next.js app at `/studio`, and design the full course → chapter → lesson → content-block schema hierarchy that every later part's course pages, lesson player, and interactive modules will be built on top of.
