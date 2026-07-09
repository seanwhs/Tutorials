# Part 7: Component Patterns in React 19

## 7.1 Concept Explanation

This part covers how to structure Tailwind styling inside real React 19 components without letting className strings become unmaintainable. Three tools: the `cn()` helper (clsx + tailwind-merge), `class-variance-authority` (CVA) for variant-driven components, and `@apply` for the rare cases where extracting to real CSS is justified. It also covers Server vs Client Component styling boundaries in Next.js 16.

## 7.2 The `cn()` Helper — Conditional Classes Done Right

```bash
npm install clsx tailwind-merge
```

```ts
// src/lib/cn.ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

// clsx handles conditional joining (booleans, objects, arrays).
// twMerge resolves CONFLICTING Tailwind classes by keeping the LAST one
// (e.g. cn("p-2", "p-4") -> "p-4", not "p-2 p-4" which would be invalid/ambiguous).
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

```tsx
// src/components/Button.tsx
import { cn } from "@/lib/cn";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "ghost";
  className?: string;
};

export function Button({ variant = "primary", className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        "rounded-lg px-4 py-2 text-sm font-medium transition-colors",
        variant === "primary" && "bg-brand-500 text-white hover:bg-brand-600",
        variant === "ghost" && "bg-transparent text-brand-600 hover:bg-brand-50",
        className, // consumer overrides always win last, and twMerge resolves conflicts correctly
      )}
      {...props}
    />
  );
}
```

```tsx
// Usage: consumer can safely override without specificity fights
<Button variant="primary" className="w-full rounded-full">
  {/* twMerge correctly drops the base "rounded-lg" in favor of "rounded-full" */}
  Full-width, pill-shaped
</Button>
```

## 7.3 Class-Variance-Authority (CVA) — Type-Safe Variant Components

```bash
npm install class-variance-authority
```

```tsx
// src/components/Badge.tsx
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/cn";

const badgeVariants = cva(
  // base classes applied to every variant
  "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold",
  {
    variants: {
      intent: {
        neutral: "bg-slate-100 text-slate-700",
        success: "bg-success/10 text-success",
        warning: "bg-warning/10 text-warning",
        danger: "bg-danger/10 text-danger",
      },
      size: {
        sm: "text-[10px] px-2 py-0.5",
        md: "text-xs px-2.5 py-0.5",
        lg: "text-sm px-3 py-1",
      },
    },
    // compoundVariants let you target a SPECIFIC combination of two variants
    compoundVariants: [
      { intent: "danger", size: "lg", class: "font-bold uppercase tracking-wide" },
    ],
    defaultVariants: {
      intent: "neutral",
      size: "md",
    },
  },
);

// VariantProps auto-derives a TS type from the cva config — no manual union types needed
type BadgeProps = React.HTMLAttributes<HTMLSpanElement> & VariantProps<typeof badgeVariants>;

export function Badge({ intent, size, className, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ intent, size }), className)} {...props} />;
}
```

```tsx
// Fully type-checked usage — invalid intent/size values are TS compile errors
<Badge intent="success" size="lg">Active</Badge>
<Badge intent="danger">Failed</Badge>
<Badge>Default neutral/md</Badge>
```

## 7.4 `@apply` — When (and When Not) to Use It

`@apply` lets you compose utilities into a real, named CSS class. In v4 it works inside any CSS file, and can reference your `@theme` tokens directly.

```css
/* src/app/globals.css */
@import "tailwindcss";

/* Good use case: a class needed by markdown-rendered content (e.g. MDX/CMS output)
   where you have NO JSX to attach individual utility classNames to. */
@layer components {
  .prose-cta-button {
    @apply inline-flex items-center gap-2 rounded-full bg-brand-500 px-5 py-2.5
           font-semibold text-white transition-colors hover:bg-brand-600;
  }
}
```

```tsx
// Consumed in raw HTML/MDX where you can't map props to conditional classNames
const html = `<a href="/pricing" class="prose-cta-button">See Pricing</a>`;
```

> **When NOT to use `@apply`:** for ordinary React components. Prefer keeping utilities directly in JSX + `cn()`/CVA — it keeps styling colocated with markup (better "locality of behavior"), avoids inventing a parallel CSS naming scheme, and keeps hover/dark/responsive variants trivially discoverable in the same line. Reserve `@apply` for content you don't control via JSX (CMS/MDX output, email templates, third-party widget overrides).

## 7.5 Server Components vs Client Components — Styling Boundary (Next.js 16)

Tailwind classes are just strings — they work identically in Server and Client Components, with **zero client JS cost**, because Tailwind's output is static CSS shipped once, not per-component runtime style injection (unlike CSS-in-JS).

```tsx
// src/components/PriceTag.tsx — a Server Component (default, no "use client")
// Pure presentational styling needs ZERO client JS — this ships 0 bytes of JS to the browser.
export function PriceTag({ amount }: { amount: number }) {
  return (
    <span className="rounded-full bg-brand-50 px-3 py-1 font-mono text-lg font-bold text-brand-700">
      ${amount.toFixed(2)}
    </span>
  );
}
```

```tsx
// src/components/ExpandableSection.tsx — needs "use client" ONLY because of useState,
// NOT because of Tailwind classes. This is the correct mental model: Tailwind classes
// never force a component to become a Client Component.
"use client";

import { useState } from "react";
import { cn } from "@/lib/cn";

export function ExpandableSection({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  const [open, setOpen] = useState(false);

  return (
    <div className="rounded-xl border border-slate-200">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex w-full items-center justify-between p-4 text-left font-medium"
      >
        {title}
        <span className={cn("transition-transform", open && "rotate-180")}>▾</span>
      </button>
      {open && <div className="border-t border-slate-100 p-4 text-slate-600">{children}</div>}
    </div>
  );
}
```

## 7.6 Reusable Primitive Components Library (Pattern Used in Part 11 Capstone)

```tsx
// src/components/ui/Card.tsx
import { cn } from "@/lib/cn";

export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "rounded-2xl border border-slate-200 bg-white shadow-soft dark:border-slate-800 dark:bg-slate-900",
        className,
      )}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("flex items-center justify-between p-6 pb-0", className)} {...props} />;
}

export function CardContent({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn("p-6", className)} {...props} />;
}
```

```tsx
// Composed usage — this exact primitive set is reused unmodified in Part 11
import { Card, CardHeader, CardContent } from "@/components/ui/Card";

export function RevenueCard() {
  return (
    <Card>
      <CardHeader>
        <h3 className="font-display font-semibold">Revenue</h3>
      </CardHeader>
      <CardContent>
        <p className="text-3xl font-bold text-slate-900 dark:text-white">$42,900</p>
      </CardContent>
    </Card>
  );
}
```

## 7.7 Exercise Challenge

Build an `<Alert>` component using CVA with `intent: "info" | "success" | "warning" | "danger"` variants, each with a matching `lucide-react` icon rendered automatically based on `intent`.

## 7.8 Solution

```tsx
// src/components/Alert.tsx
import { cva, type VariantProps } from "class-variance-authority";
import { Info, CheckCircle2, AlertTriangle, XCircle } from "lucide-react";
import { cn } from "@/lib/cn";

const alertVariants = cva("flex items-start gap-3 rounded-xl border p-4 text-sm", {
  variants: {
    intent: {
      info: "border-blue-200 bg-blue-50 text-blue-800",
      success: "border-success/30 bg-success/10 text-success",
      warning: "border-warning/30 bg-warning/10 text-warning",
      danger: "border-danger/30 bg-danger/10 text-danger",
    },
  },
  defaultVariants: { intent: "info" },
});

const icons = {
  info: Info,
  success: CheckCircle2,
  warning: AlertTriangle,
  danger: XCircle,
} as const;

type AlertProps = React.HTMLAttributes<HTMLDivElement> &
  VariantProps<typeof alertVariants> & { title: string };

export function Alert({ intent = "info", title, className, children, ...props }: AlertProps) {
  const Icon = icons[intent!];
  return (
    <div className={cn(alertVariants({ intent }), className)} {...props}>
      <Icon className="mt-0.5 size-5 shrink-0" />
      <div>
        <p className="font-semibold">{title}</p>
        {children && <p className="mt-1 opacity-90">{children}</p>}
      </div>
    </div>
  );
}
```

---

*Next: Tailwind v4 Mastery - Part 8: Animations & Transitions*
