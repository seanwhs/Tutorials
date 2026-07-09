# Part 4: The Component Model

## 1. Browser Reality – Repetition in Raw HTML/CSS

Before components existed, reusing a UI pattern meant copy-pasting markup and keeping a shared class in a global stylesheet.

Raw HTML, repeated three times across a site:

```html
<div class="card">
  <h3 class="card-title">Plan A</h3>
  <p class="card-body">Basic tier.</p>
</div>

<div class="card">
  <h3 class="card-title">Plan B</h3>
  <p class="card-body">Pro tier.</p>
</div>
```

Raw global CSS, in one shared file:

```css
/* styles.css - loaded on every page */
.card { border: 1px solid #d1d5db; border-radius: 0.5rem; padding: 1rem; }
.card-title { font-weight: 700; margin-bottom: 0.5rem; }
.card-body { color: #4b5563; }
```

**The problem this creates at scale:**
1. **No enforced coupling.** Nothing stops someone from writing `<div class="card">` with a typo, a missing `card-title`, or extra unexpected children. The HTML structure and the CSS rules live in entirely separate files with no compiler checking they still match.
2. **Global namespace collisions.** If another team adds their own `.card` class for an unrelated component, one silently overrides the other — back to the specificity/cascade problems from Part 3, except now it's about *structure*, not just color.
3. **Change is expensive.** Updating "card" everywhere means finding every copy-pasted HTML block by hand.

## 2. The React Translation – Components as the Unit of Reuse

A component bundles **structure + behavior + styling** into one unit with an explicit interface (props). This is the fix for problem #1 above — the compiler (TypeScript) now enforces the contract.

```tsx
// app/components/Card.tsx
type CardProps = {
  title: string;
  children: React.ReactNode;
};

export default function Card({ title, children }: CardProps) {
  return (
    <article className="rounded-lg border border-gray-300 p-4">
      <h3 className="mb-2 font-bold">{title}</h3>
      <div className="text-gray-600">{children}</div>
    </article>
  );
}
```

```tsx
// app/page.tsx
import Card from "./components/Card";

export default function Page() {
  return (
    <div className="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
      <Card title="Plan A">Basic tier.</Card>
      <Card title="Plan B">Pro tier.</Card>
    </div>
  );
}
```

Now "what a card looks like" has exactly one source of truth. If the design changes, you edit `Card.tsx` once. TypeScript will error if a consumer forgets the required `title` prop — the old copy-paste HTML approach had no equivalent safety net.

## 3. Global CSS vs. Component-Scoped Styling

| | Global CSS (legacy) | Tailwind + React (component-scoped) |
|---|---|---|
| Where styles live | One or few shared `.css` files, separate from markup | Inline utility classes, co-located with the JSX that uses them |
| Naming | Requires a convention (BEM, etc.) to avoid collisions: `.card__title--large` | No naming needed — utilities are pre-named and globally reusable by design |
| Discoverability | Must search a separate stylesheet to know what `.card` does | Open the component file; every style is visible right there |
| Blast radius of a change | Editing `.card` in global CSS can affect every usage sitewide, including ones you forgot about | Editing `Card.tsx` only affects consumers of that component; utility classes themselves are never "edited," only recombined |
| Dead code | Old CSS rules accumulate for markup that no longer exists — hard to detect | Unused component files are easy to find and delete; Tailwind only ships CSS for classes actually found in your source |

Tailwind classes are still, technically, global CSS selectors under the hood (as shown in Part 3) — but because they are atomic and pre-defined by the framework rather than hand-named per feature, they eliminate the *naming and collision* problem while React components solve the *structure coupling* problem. The two together replace what global CSS + naming conventions used to do alone.

## 4. Building an Accessible, Responsive Component From Scratch

Goal: a `Disclosure` (accordion-style expand/collapse) component — a good test case because it requires semantic structure, keyboard accessibility, and responsive styling simultaneously.

**Step 1 – Browser reality: what accessible disclosure markup requires natively.**

```html
<button aria-expanded="false" aria-controls="panel-1" id="trigger-1">
  What is Next.js?
</button>
<div id="panel-1" role="region" aria-labelledby="trigger-1" hidden>
  <p>Next.js is a React framework.</p>
</div>
```

Key a11y facts this encodes:
- A real `<button>` gets keyboard focus and `Enter`/`Space` activation for free — a `<div onClick>` gets neither without extra `tabindex` and key handlers.
- `aria-expanded` tells assistive tech the toggle's current state.
- `aria-controls` + matching `id` links trigger to panel programmatically.
- `hidden` fully removes the panel from the accessibility tree (not just visually via CSS) when collapsed.

**Step 2 – The Next.js 16 component**, using `'use client'` because it needs interactive state:

```tsx
// app/components/Disclosure.tsx
'use client';

import { useState, useId } from "react";
import { cn } from "@/utils/cn";

type DisclosureProps = {
  title: string;
  children: React.ReactNode;
  className?: string;
};

export default function Disclosure({
  title,
  children,
  className,
}: DisclosureProps) {
  const [open, setOpen] = useState(false);
  const panelId = useId();

  return (
    <div className={cn("border-b border-gray-200", className)}>
      <button
        type="button"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={() => setOpen((prev) => !prev)}
        className="flex w-full items-center justify-between gap-4 py-3 text-left font-medium"
      >
        <span>{title}</span>
        <span aria-hidden="true">{open ? "-" : "+"}</span>
      </button>
      <div
        id={panelId}
        role="region"
        hidden={!open}
        className="pb-3 text-gray-600"
      >
        {children}
      </div>
    </div>
  );
}
```

```tsx
// app/page.tsx (Server Component parent, composing a Client Component child)
import Disclosure from "./components/Disclosure";

export default function Page() {
  return (
    <main className="mx-auto flex max-w-2xl flex-col p-4">
      <h1 className="mb-4 text-2xl font-bold">FAQ</h1>
      <Disclosure title="What is Next.js?">
        <p>Next.js is a React framework with file-based routing.</p>
      </Disclosure>
      <Disclosure title="What is Tailwind?">
        <p>A utility-first CSS framework.</p>
      </Disclosure>
    </main>
  );
}
```

**Mapping every decision back to fundamentals:**

| Line | Fundamental it traces to |
|---|---|
| `<button>` not `<div>` | Native keyboard focus + activation (Part 1's semantics point) |
| `aria-expanded={open}` | Communicates cascade-independent state to assistive tech |
| `hidden={!open}` | The `hidden` HTML attribute (not just `display: none` via a class) — fully removes from a11y tree |
| `flex w-full items-center justify-between` | Part 2's Flexbox: title left, icon right, one axis |
| `border-b border-gray-200` | Part 1's box model: border as visual separator |
| `useId()` | Guarantees the `id`/`aria-controls` pair is unique even if `Disclosure` renders many times on one page |
| `'use client'` boundary | Only the interactive piece ships JS to the browser; the parent `page.tsx` stays a zero-JS Server Component |

## Exercise Challenge

Extend `Disclosure` into an `Accordion.tsx` Server Component that renders a `<div>` wrapping multiple `Disclosure` children (composition via `children`, per Part 2's semantic-grouping lesson), where:
1. The wrapper uses a "does it need a role?" reasoning check — decide whether a wrapping `<div>` needs any ARIA role at all (hint: it doesn't, if each `Disclosure` is already self-describing).
2. Add a responsive `max-w-2xl mx-auto` container.
3. Confirm keyboard-only navigation (Tab, Enter/Space) works with zero extra JS beyond what `Disclosure` already provides.

## Solution

```tsx
// app/components/Accordion.tsx
export default function Accordion({
  children,
}: {
  children: React.ReactNode;
}) {
  return <div className="mx-auto flex max-w-2xl flex-col">{children}</div>;
}
```

```tsx
// app/page.tsx
import Accordion from "./components/Accordion";
import Disclosure from "./components/Disclosure";

export default function Page() {
  return (
    <main className="p-4">
      <Accordion>
        <Disclosure title="What is Next.js?">
          <p>A React framework with file-based routing.</p>
        </Disclosure>
        <Disclosure title="What is Tailwind?">
          <p>A utility-first CSS framework.</p>
        </Disclosure>
      </Accordion>
    </main>
  );
}
```

**Why this passes:** No ARIA role is needed on the outer `<div>` — it's purely a layout container (Part 2's Flexbox column stack), and each `Disclosure` already carries its own complete semantics (`button` + `aria-expanded` + `region`). Adding a redundant `role="group"` would only be justified if the accordion needed to announce itself as a single collective unit; for an FAQ list, independent disclosures are the correct, simpler model. This is the through-line of the whole series: every utility class and every component boundary is justified by tracing it back to what the browser already does natively — nothing in Tailwind or Next.js invents new behavior, it only automates and packages the fundamentals.
