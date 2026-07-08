# Part 3: Styling and Shared UI

Goal: set up Tailwind CSS v4 globals and build the small set of reusable UI pieces (Button, Card, Badge, dashboard nav/layout) used throughout the rest of the course.

---

## 1. Replace global styles

Open `src/app/globals.css` and replace it with:

```css
@import "tailwindcss";

:root {
  color-scheme: light;
}

body {
  margin: 0;
  background: #f8fafc;
  color: #0f172a;
}

code,
pre {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}
```

This is the Tailwind v4 CSS-first import style (no `tailwind.config.js` needed for our purposes).

---

## 2. A tiny classname helper

Create `src/lib/cn.ts`:

```ts
export function cn(...classes: Array<string | false | null | undefined>) {
  return classes.filter(Boolean).join(" ");
}
```

---

## 3. Button component

Create `src/components/ui/button.tsx`:

```tsx
import Link from "next/link";
import { cn } from "@/lib/cn";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary" | "danger";
};

const variants = {
  primary: "bg-emerald-600 text-white hover:bg-emerald-700",
  secondary: "border border-slate-300 bg-white text-slate-900 hover:bg-slate-50",
  danger: "bg-red-600 text-white hover:bg-red-700",
};

export function Button({ className, variant = "primary", ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-50",
        variants[variant],
        className,
      )}
      {...props}
    />
  );
}

export function ButtonLink({
  href,
  children,
  variant = "primary",
}: {
  href: string;
  children: React.ReactNode;
  variant?: keyof typeof variants;
}) {
  return (
    <Link
      href={href}
      className={cn(
        "inline-flex items-center justify-center rounded-lg px-4 py-2 text-sm font-semibold transition",
        variants[variant],
      )}
    >
      {children}
    </Link>
  );
}
```

---

## 4. Card component

Create `src/components/ui/card.tsx`:

```tsx
import { cn } from "@/lib/cn";

export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn("rounded-2xl border border-slate-200 bg-white p-6 shadow-sm", className)}
      {...props}
    />
  );
}

export function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return <h2 className={cn("text-lg font-semibold text-slate-950", className)} {...props} />;
}

export function CardDescription({ className, ...props }: React.HTMLAttributes<HTMLParagraphElement>) {
  return <p className={cn("mt-1 text-sm text-slate-600", className)} {...props} />;
}
```

---

## 5. Badge component

Create `src/components/ui/badge.tsx`:

```tsx
import { cn } from "@/lib/cn";

export function Badge({
  className,
  tone = "neutral",
  ...props
}: React.HTMLAttributes<HTMLSpanElement> & { tone?: "neutral" | "success" | "danger" }) {
  const tones = {
    neutral: "bg-slate-100 text-slate-700",
    success: "bg-emerald-100 text-emerald-700",
    danger: "bg-red-100 text-red-700",
  };

  return (
    <span
      className={cn("inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium", tones[tone], className)}
      {...props}
    />
  );
}
```

---

## 6. Dashboard navigation

Create `src/components/dashboard-nav.tsx`:

```tsx
import Link from "next/link";

export function DashboardNav() {
  return (
    <header className="border-b border-slate-200 bg-white">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/dashboard" className="font-bold text-slate-950">
          HDB Resale API
        </Link>
        <nav className="flex items-center gap-4 text-sm">
          <Link href="/dashboard/keys" className="text-slate-700 hover:text-slate-950">API Keys</Link>
          <Link href="/dashboard/usage" className="text-slate-700 hover:text-slate-950">Usage</Link>
          <Link href="/docs" className="text-slate-700 hover:text-slate-950">Docs</Link>
          <form action="/api/auth/logout" method="post">
            <button className="text-slate-700 hover:text-slate-950">Logout</button>
          </form>
        </nav>
      </div>
    </header>
  );
}
```

---

## 7. Dashboard layout

Create `src/app/dashboard/layout.tsx`:

```tsx
import { DashboardNav } from "@/components/dashboard-nav";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-slate-50">
      <DashboardNav />
      <div className="mx-auto max-w-6xl px-6 py-8">{children}</div>
    </div>
  );
}
```

---

## Checkpoint

- [ ] `Button`, `ButtonLink`, `Card`, `CardTitle`, `CardDescription`, `Badge` all compile without errors.
- [ ] `src/app/dashboard/layout.tsx` renders a nav bar wrapping child content.
- [ ] Tailwind utility classes visibly style these components once used.

---

## Troubleshooting

**TypeScript complains about `React` namespace in prop types**
Make sure `@types/react` and `@types/react-dom` are installed (they are by default with `create-next-app --typescript`). If missing: `npm install -D @types/react @types/react-dom`.

**`ButtonLink` variant type error**
`variant` must be exactly one of `"primary" | "secondary" | "danger"` — check for typos.

**Styles don't show up**
Confirm the component file actually uses Tailwind class strings (not CSS Modules) and that `globals.css` is imported in the root layout.

---

Ready for **Part 4 — Lightweight Signed-Cookie Login**?
