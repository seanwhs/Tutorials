# Appendix A3: Component Files

## A.9 `src/app/layout.tsx`

```tsx
import "./globals.css";
import type { Metadata } from "next";
import { Sidebar } from "@/components/Sidebar";
import { Topbar } from "@/components/Topbar";

export const metadata: Metadata = {
  title: "PulseBoard",
  description: "Analytics dashboard built with Next.js 16, React 19, Tailwind CSS v4",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html:
              "(function() { const stored = localStorage.getItem('theme'); const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches; const isDark = stored === 'dark' || (!stored && prefersDark); document.documentElement.classList.toggle('dark', isDark); })();",
          }}
        />
      </head>
      <body className="font-sans antialiased">
        <div className="flex min-h-screen">
          <Sidebar />
          <div className="flex flex-1 flex-col">
            <Topbar />
            <main className="flex-1 space-y-6 p-6">{children}</main>
          </div>
        </div>
      </body>
    </html>
  );
}
```

## A.10 `src/app/page.tsx`

```tsx
import { StatGrid } from "@/components/StatGrid";
import { RevenueChartCard } from "@/components/RevenueChartCard";
import { RecentActivityFeed } from "@/components/RecentActivityFeed";
import { PlanUsagePanel } from "@/components/PlanUsagePanel";

export default function DashboardPage() {
  return (
    <>
      <StatGrid />
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <RevenueChartCard />
        </div>
        <PlanUsagePanel />
      </div>
      <RecentActivityFeed />
    </>
  );
}
```

## A.11 `src/components/ui/Card.tsx`

```tsx
import { cn } from "@/lib/cn";

export function Card({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn(
        "animate-fade-in rounded-2xl border border-slate-200 bg-white shadow-soft dark:border-slate-800 dark:bg-slate-900",
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

## A.12 `src/components/ui/Button.tsx`

```tsx
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
        className,
      )}
      {...props}
    />
  );
}
```

## A.13 `src/components/ui/Badge.tsx`

```tsx
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/cn";

const badgeVariants = cva(
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
    defaultVariants: { intent: "neutral", size: "md" },
  },
);

type BadgeProps = React.HTMLAttributes<HTMLSpanElement> & VariantProps<typeof badgeVariants>;

export function Badge({ intent, size, className, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ intent, size }), className)} {...props} />;
}
```

## A.14 `src/components/ui/Alert.tsx`

```tsx
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

const icons = { info: Info, success: CheckCircle2, warning: AlertTriangle, danger: XCircle } as const;

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

## A.15 `src/components/ThemeToggle.tsx`

```tsx
"use client";

import { useState, useEffect } from "react";
import { Moon, Sun } from "lucide-react";

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(
    () => typeof document !== "undefined" && document.documentElement.classList.contains("dark"),
  );

  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDark);
    localStorage.setItem("theme", isDark ? "dark" : "light");
  }, [isDark]);

  return (
    <button
      onClick={() => setIsDark((prev) => !prev)}
      aria-label="Toggle dark mode"
      className="rounded-full border border-slate-200 p-2 text-slate-700 transition-colors hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
    >
      {isDark ? <Sun className="size-5" /> : <Moon className="size-5" />}
    </button>
  );
}
```

## A.16 `src/components/Sidebar.tsx`

```tsx
import { LayoutDashboard, Users, CreditCard, Settings } from "lucide-react";
import { cn } from "@/lib/cn";

const navItems = [
  { label: "Overview", icon: LayoutDashboard, active: true },
  { label: "Team", icon: Users, active: false },
  { label: "Billing", icon: CreditCard, active: false },
  { label: "Settings", icon: Settings, active: false },
];

export function Sidebar() {
  return (
    <aside className="hidden w-64 shrink-0 border-r border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900 lg:block">
      <div className="mb-8 flex items-center gap-2 px-2">
        <div className="size-8 rounded-lg bg-brand-500" />
        <span className="font-display text-lg font-bold">PulseBoard</span>
      </div>
      <nav className="space-y-1">
        {navItems.map(({ label, icon: Icon, active }) => (
          <a
            key={label}
            href="#"
            className={cn(
              "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
              active
                ? "bg-brand-50 text-brand-700 dark:bg-brand-900/40 dark:text-brand-100"
                : "text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800",
            )}
          >
            <Icon className="size-4" />
            {label}
          </a>
        ))}
      </nav>
    </aside>
  );
}
```

## A.17 `src/components/Topbar.tsx`

```tsx
import { ThemeToggle } from "@/components/ThemeToggle";

export function Topbar() {
  return (
    <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-4 dark:border-slate-800 dark:bg-slate-900">
      <div>
        <h1 className="font-display text-xl font-bold">Overview</h1>
        <p className="text-sm text-slate-500 dark:text-slate-400">
          Welcome back, here is what's happening today.
        </p>
      </div>
      <div className="flex items-center gap-3">
        <ThemeToggle />
        <div className="size-9 rounded-full bg-brand-500" />
      </div>
    </header>
  );
}
```

---

*Next: Tailwind v4 Mastery - Appendix A (part 3): Dashboard Widget Files*
