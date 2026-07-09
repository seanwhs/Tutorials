# Part 6: State Variants & Advanced Selectors

## 6.1 Basic Interaction States

```tsx
<button
  className="bg-brand-500 text-white
             hover:bg-brand-600
             active:bg-brand-700
             focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-500
             disabled:cursor-not-allowed disabled:opacity-50"
  disabled={false}
>
  Hover, active, and keyboard-focus states, plus disabled styling
</button>
```

| Variant | Trigger |
|---|---|
| `hover:` | Mouse hover (correctly suppressed on touch devices in v4 via `@media (hover: hover)`) |
| `focus:` | Any focus (mouse or keyboard) |
| `focus-visible:` | Keyboard-only focus — prefer this for focus rings to avoid mouse-click outline flashes |
| `active:` | Mouse-down / touch-down |
| `disabled:` | Element has `disabled` attribute |
| `visited:` | Visited links |
| `first:` / `last:` / `odd:` / `even:` | Structural (`:first-child`, `:nth-child(odd)`, etc.) |
| `not-*:` | New in v4 — negation, e.g. `not-first:mt-4` (all but the first child) |

## 6.2 `group` — Style a Child Based on a Parent's State

```tsx
// src/components/HoverCard.tsx
export function HoverCard() {
  return (
    // "group" marks this element as the state-source for descendants
    <div className="group rounded-xl border border-slate-200 p-6 transition-shadow hover:shadow-lg">
      <h3 className="text-slate-900 group-hover:text-brand-600">
        Title changes color when the PARENT card is hovered, not the title itself
      </h3>
      <p className="text-slate-500 opacity-0 transition-opacity group-hover:opacity-100">
        This description fades in only when the parent card is hovered
      </p>
    </div>
  );
}
```

```tsx
// Named groups: essential for nested groups (e.g. a card inside a list item,
// each with its own independent hover state)
<ul>
  {items.map((item) => (
    <li key={item.id} className="group/item rounded-lg p-4 hover:bg-slate-50">
      <button className="opacity-0 group-hover/item:opacity-100">
        {/* Only reacts to THIS li's hover, not any ancestor group */}
        Delete
      </button>
    </li>
  ))}
</ul>
```

## 6.3 `peer` — Style an Element Based on a Sibling's State

Classic use case: form validation styling and custom checkbox/toggle UIs.

```tsx
// src/components/ValidatedInput.tsx
export function ValidatedInput() {
  return (
    <div>
      <input
        type="email"
        required
        // "peer" marks this element; styles react to ITS state, applied on a sibling
        className="peer rounded-lg border border-slate-300 px-3 py-2 invalid:border-danger"
        placeholder="you@example.com"
      />
      {/* peer-invalid only shows this message once the peer input is :invalid AND touched */}
      <p className="mt-1 hidden text-sm text-danger peer-invalid:peer-[&:not(:placeholder-shown)]:block">
        Please enter a valid email address.
      </p>
    </div>
  );
}
```

```tsx
// Custom toggle switch built entirely with peer — a very common real-world pattern
export function ToggleSwitch({ label }: { label: string }) {
  return (
    <label className="flex cursor-pointer items-center gap-3">
      <input type="checkbox" className="peer sr-only" />
      <div
        className="h-6 w-11 rounded-full bg-slate-300 transition-colors
                   peer-checked:bg-brand-500
                   peer-focus-visible:ring-2 peer-focus-visible:ring-brand-500 peer-focus-visible:ring-offset-2"
      >
        <div
          className="h-5 w-5 translate-x-0.5 translate-y-0.5 rounded-full bg-white
                     shadow-sm transition-transform peer-checked:translate-x-5"
        />
      </div>
      <span className="text-sm text-slate-700">{label}</span>
    </label>
  );
}
```

## 6.4 `has-*` — Style a Parent Based on a Descendant (New Core Feature in v4)

This is a genuine CSS `:has()` selector wrapper — no JS, no `peer`/`group` marker classes needed on the child.

```tsx
// src/components/SelectableCard.tsx
export function SelectableCard() {
  return (
    // has-[:checked] applies when ANY descendant matches :checked — no "peer" needed
    <label
      className="flex items-center gap-3 rounded-xl border-2 border-slate-200 p-4
                 has-[:checked]:border-brand-500 has-[:checked]:bg-brand-50"
    >
      <input type="radio" name="plan" className="accent-brand-500" />
      <span>Pro Plan — $19/mo</span>
    </label>
  );
}
```

```tsx
// has-* also composes with arbitrary attribute selectors, e.g. styling a form
// container differently when it contains an invalid field
<form className="has-[:invalid]:border-danger rounded-xl border p-6">
  <input required className="border p-2" />
</form>
```

| Selector | Meaning |
|---|---|
| `group-*` | Parent has a class marker (`.group`), child reacts to parent's state |
| `peer-*` | Sibling has a class marker (`.peer`), a later sibling reacts to its state |
| `has-*` | Element reacts to ANY descendant matching a selector — no marker class required |
| `in-*` (v4 addition) | Similar to `has-*` but for reacting based on ancestor context without needing `group` |

## 6.5 `aria-*` and `data-*` Attribute Variants

Directly target ARIA/data attributes — extremely useful with headless UI libraries (Radix, React Aria) that manage state via attributes rather than classes.

```tsx
// Works with any component library that toggles aria-selected / aria-expanded / data-state
<button
  aria-expanded={isOpen}
  className="rounded-lg p-2 aria-expanded:bg-brand-100 aria-expanded:text-brand-700"
>
  Toggle
</button>

<div
  data-state={isOpen ? "open" : "closed"}
  className="data-[state=open]:animate-in data-[state=closed]:animate-out"
>
  Radix/React-Aria style data-attribute driven animation hook
</div>
```

## 6.6 `not-*` — Negation Variant (New in v4)

```tsx
<ul className="divide-y divide-slate-200">
  {items.map((item) => (
    <li key={item.id} className="not-last:pb-4 not-first:pt-4">
      {/* Adds padding-bottom to all but the last item, padding-top to all but the first */}
      {item.label}
    </li>
  ))}
</ul>

<input className="not-focus:text-slate-400" placeholder="Grayed out unless focused" />
```

## 6.7 Custom Variants with `@custom-variant`

You already used this in Part 5 for class-based dark mode. It generalizes to any selector logic:

```css
@import "tailwindcss";

/* Custom variant for a "loading" state driven by a data attribute on a wrapping element */
@custom-variant loading (&:where([data-loading="true"], [data-loading="true"] *));

/* Custom variant targeting a specific descendant combinator, e.g. direct children only */
@custom-variant direct-children (& > *);
```

```tsx
<div data-loading={isLoading} className="loading:animate-pulse loading:opacity-60">
  {/* Applies pulse + reduced opacity while data-loading="true" anywhere up the tree */}
  <Content />
</div>

<div className="direct-children:border-b direct-children:border-slate-100">
  {/* Only DIRECT children get the border, not deeply nested descendants */}
</div>
```

## 6.8 Exercise Challenge

Build a `<FAQItem>` accordion row using **only** `has-*` (no JS state, no `peer`) where clicking a hidden checkbox rotates a chevron icon and reveals the answer.

## 6.9 Solution

```tsx
// src/components/FAQItem.tsx
import { ChevronDown } from "lucide-react";

export function FAQItem({ question, answer }: { question: string; answer: string }) {
  return (
    <div className="group/faq rounded-xl border border-slate-200 has-[:checked]:border-brand-300">
      <label className="flex cursor-pointer items-center justify-between p-4">
        <span className="font-medium text-slate-900">{question}</span>
        <input type="checkbox" className="peer sr-only" />
        <ChevronDown className="size-5 text-slate-400 transition-transform peer-checked:rotate-180" />
      </label>
      {/* grid-rows trick: animatable height for "auto" content using a CSS grid track */}
      <div className="grid grid-rows-[0fr] transition-[grid-template-rows] duration-300 has-[:checked]:grid-rows-[1fr]">
        <div className="overflow-hidden px-4 has-[:checked]:pb-4">
          <p className="text-sm text-slate-500">{answer}</p>
        </div>
      </div>
    </div>
  );
}
```

Note: the outer `has-[:checked]` reacts to the checkbox nested two levels deep, demonstrating that `has-*` (unlike `peer-*`) needs no marker class on the checkbox itself and works through the DOM tree, not just adjacent siblings.

---

*Next: Tailwind v4 Mastery - Part 7: Component Patterns in React 19*
