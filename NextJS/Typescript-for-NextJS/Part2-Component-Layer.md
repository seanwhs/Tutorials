# Type-Safe Horizons — Part 2: The Component Layer

*Series: Type-Safe Horizons. Prerequisite: Part 1 (Beyond Basics — Task type, discriminated unions, utility types).*

## Safety Check: The Anti-Pattern

```tsx
interface ButtonProps {
  children: JSX.Element;
  className: string;
  onClick: any;
}

function Button({ children, className, onClick }: ButtonProps) {
  return (
    <button className={className} onClick={onClick}>
      {children}
    </button>
  );
}

// Usage:
<Button className="primary" onClick={() => {}}>
  Click me
</Button>
```

This looks reasonable and even compiles in some configs, but it's broken in three separate ways:

1. `children: JSX.Element` rejects perfectly valid React children — a plain string (`"Click me"` above), a number, an array of elements, or `null`. All of those are valid things to put between `<Button>` tags, and none of them are a `JSX.Element`.
2. `onClick: any` throws away all type-checking on the handler signature — pass `onClick={handleSubmit}` where `handleSubmit` expects a form event instead of a mouse event, and you find out at runtime, not compile time.
3. There's no `disabled`, no `type`, no `aria-*` — every native `<button>` attribute a consumer might reasonably want has to be re-declared by hand, and inevitably someone forgets one and reaches for `any` to bypass it, or spreads `{...rest}` untyped.

## Type Logic

- **`React.ReactNode` vs `JSX.Element` vs `React.ReactElement`** — these are not interchangeable, and the difference is exactly the bug above:
  - `JSX.Element` = the result of evaluating one specific JSX tag (`<div />`). Narrow, rarely what you want for `children` or return types.
  - `React.ReactElement` = generic version of the same idea, optionally parameterized by prop type — useful when you need to say "specifically an element, and I need to inspect its props," e.g. `React.cloneElement` scenarios.
  - `React.ReactNode` = the true "anything renderable" union: `ReactElement | string | number | Iterable<ReactNode> | boolean | null | undefined` (React 19 also folds in `bigint` and Promise-based nodes for the `use` hook). **This is what `children` should almost always be typed as.**
- **`forwardRef` typing** — `forwardRef<RefType, PropsType>` takes the ref type *first*, props *second* — the reverse order of how you'd naturally write `(props, ref)`. Getting this backwards is the single most common `forwardRef` mistake. In React 19, `ref` became a regular prop that function components can accept directly — `forwardRef` is no longer required for new code, but you will maintain `forwardRef` components for years, so both patterns matter.
- **`ComponentPropsWithoutRef<'element'>`** — instead of manually re-declaring every native attribute a `<button>` or `<input>` accepts, extract them straight from React's own DOM typings. `ComponentPropsWithoutRef` gives you the full native attribute set *without* the `ref` field pre-mixed in (you add your own `ref` typing when using `forwardRef`, since the native ref type and your component's exposed ref type aren't always identical).

## Refactored Solution

### 1. `children` as `ReactNode`, extending native props

```tsx
// components/button.tsx
import type { ComponentPropsWithoutRef } from "react";

interface ButtonProps extends ComponentPropsWithoutRef<"button"> {
  variant?: "primary" | "secondary" | "destructive";
}

function Button({ variant = "primary", className, children, ...rest }: ButtonProps) {
  return (
    <button className={`btn btn-${variant} ${className ?? ""}`} {...rest}>
      {children}
    </button>
  );
}

export { Button };
```

`extends ComponentPropsWithoutRef<"button">` means `Button` now accepts `disabled`, `type`, `onClick` (correctly typed as `MouseEventHandler<HTMLButtonElement>`, not `any`), `aria-label`, `data-*` attributes — everything the real `<button>` element supports — for free, forever, even as React's own DOM typings evolve. `children` is inherited from that same native type as `ReactNode`, so strings, numbers, arrays, and elements are all valid.

### 2. `forwardRef`, typed correctly (legacy/library pattern)

```tsx
// components/text-input.tsx
import { forwardRef, type ComponentPropsWithoutRef } from "react";

interface TextInputProps extends ComponentPropsWithoutRef<"input"> {
  label: string;
  error?: string;
}

const TextInput = forwardRef<HTMLInputElement, TextInputProps>(
  ({ label, error, id, ...rest }, ref) => {
    return (
      <div>
        <label htmlFor={id}>{label}</label>
        <input ref={ref} id={id} {...rest} />
        {error && <p role="alert">{error}</p>}
      </div>
    );
  }
);

TextInput.displayName = "TextInput";

export { TextInput };
```

Read the generic order carefully: `forwardRef<HTMLInputElement, TextInputProps>` — **ref type first** (`HTMLInputElement`, matching the DOM node `ref` will point at), **props type second**. Reverse those and TypeScript will report confusing errors deep inside the render function instead of at the declaration.

### 3. React 19 alternative — `ref` as a plain prop

React 19 lets function components accept `ref` directly, no `forwardRef` wrapper needed:

```tsx
// components/text-input-r19.tsx
import type { ComponentPropsWithoutRef, Ref } from "react";

interface TextInputProps extends ComponentPropsWithoutRef<"input"> {
  label: string;
  error?: string;
  ref?: Ref<HTMLInputElement>;
}

function TextInput({ label, error, id, ref, ...rest }: TextInputProps) {
  return (
    <div>
      <label htmlFor={id}>{label}</label>
      <input ref={ref} id={id} {...rest} />
      {error && <p role="alert">{error}</p>}
    </div>
  );
}

export { TextInput };
```

Same external API, no `forwardRef`, no `displayName` boilerplate, and `ref` shows up in your props type explicitly instead of being a special second function argument. For new Next.js 16 / React 19 components, prefer this pattern — reserve the `forwardRef` pattern above for maintaining existing code or authoring a library that must also support React 18 consumers.

### 4. `ReactNode` for polymorphic "slot" content

This directly extends Part 1's discriminated-union thinking to component composition:

```tsx
import type { ReactNode } from "react";

interface CardProps {
  title: ReactNode; // not just `string` — allows a badge + text, an icon, etc.
  children: ReactNode;
  footer?: ReactNode;
}

function Card({ title, children, footer }: CardProps) {
  return (
    <div className="card">
      <div className="card-title">{title}</div>
      <div className="card-body">{children}</div>
      {footer && <div className="card-footer">{footer}</div>}
    </div>
  );
}

// Both of these are valid — a plain string, and a composed element:
<Card title="Simple">Body text</Card>;
<Card title={<><StatusDot color="green" /> Active Task</>}>
  Body text
</Card>;
```

## Exercise Challenge

Build a simple `IconButton` component that:
1. Extends all native `<button>` attributes.
2. Accepts an `icon: ReactNode` prop and an optional `label?: string` for accessibility (rendered as visually-hidden text, not a visible label).
3. Supports a `ref` in the React 19 plain-prop style (no `forwardRef`).

## Solution

```tsx
import type { ComponentPropsWithoutRef, ReactNode, Ref } from "react";

interface IconButtonProps extends ComponentPropsWithoutRef<"button"> {
  icon: ReactNode;
  label?: string;
  ref?: Ref<HTMLButtonElement>;
}

function IconButton({ icon, label, ref, className, ...rest }: IconButtonProps) {
  return (
    <button ref={ref} className={`icon-btn ${className ?? ""}`} {...rest}>
      {icon}
      {label && <span className="sr-only">{label}</span>}
    </button>
  );
}

export { IconButton };
```

Because `IconButtonProps` extends `ComponentPropsWithoutRef<"button">`, `disabled`, `onClick`, `type="submit"`, and every other native attribute work with zero extra typing — exactly the problem the anti-pattern at the top of this lesson failed to solve.

## TypeScript Tip: `ComponentProps` vs `ComponentPropsWithoutRef` vs `ComponentPropsWithRef`

- `ComponentProps<'input'>` — includes `ref`, typed loosely (fine for read-only inspection, not for `forwardRef` component definitions).
- `ComponentPropsWithoutRef<'input'>` — excludes `ref` entirely. **Use this as the base for any component you're about to attach your own `ref` typing to** (both the `forwardRef` pattern and the React 19 plain-prop pattern above use this one).
- `ComponentPropsWithRef<'input'>` — includes `ref` typed precisely for that element. Rarely needed directly; mostly used internally by `forwardRef`'s own type definitions.

Default to `ComponentPropsWithoutRef` unless you have a specific reason not to — it's the one that prevents the "conflicting `ref` type" errors that otherwise show up the first time you compose a `forwardRef` component inside another `forwardRef` component.

---
**Previous:** Part 1: Beyond Basics — Interfaces, Discriminated Unions, Utility Types
**Next:** Part 3: The Data Boundary — typing Server Components, Server Actions, and Prisma/Drizzle models.
