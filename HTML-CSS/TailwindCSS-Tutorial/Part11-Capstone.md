# Part 11: Capstone Project — Analytics Dashboard (Next.js 16 + React 19 + Tailwind v4)

## 11.1 Overview

This capstone combines every concept from Parts 1-10 into one cohesive project: **PulseBoard**, a fake-data SaaS analytics dashboard. It reuses primitives from Part 7 (Card, Badge, Button, Alert), theme tokens from Part 3, container queries and dark mode from Part 5, state variants from Part 6, and animations from Part 8 — unmodified.

Project tree (built on top of the tw4-mastery Next.js 16 project from Part 2):

```text
src/
  app/
    layout.tsx
    globals.css
    page.tsx
  components/
    ui/
      Card.tsx
      Button.tsx
      Badge.tsx
      Alert.tsx
    ThemeToggle.tsx
    Sidebar.tsx
    Topbar.tsx
    StatGrid.tsx
    RevenueChartCard.tsx
    RecentActivityFeed.tsx
    PlanUsagePanel.tsx
  lib/
    cn.ts
    fake-data.ts
```

No backend/database required — all data comes from lib/fake-data.ts.

## 11.2 Fake Data Source

```ts
export type ActivityItem = {
  id: string;
  user: string;
  action: string;
  timestamp: string;
};

export const stats = [
  { label: "MRR", value: "$42,900", trend: "up" as const },
  { label: "Active Users", value: "8,120", trend: "up" as const },
  { label: "Churn Rate", value: "1.8%", trend: "down" as const },
  { label: "Avg. Session", value: "6m 12s", trend: "up" as const },
];

export const revenueByMonth = [
  { month: "Jan", value: 28 },
  { month: "Feb", value: 32 },
  { month: "Mar", value: 30 },
  { month: "Apr", value: 38 },
  { month: "May", value: 41 },
  { month: "Jun", value: 47 },
];

export const recentActivity: ActivityItem[] = [
  { id: "1", user: "Ava Chen", action: "upgraded to Pro plan", timestamp: "2m ago" },
  { id: "2", user: "Marcus Lee", action: "invited 3 teammates", timestamp: "18m ago" },
  { id: "3", user: "Priya Nair", action: "created a new workspace", timestamp: "1h ago" },
  { id: "4", user: "Diego Ruiz", action: "cancelled subscription", timestamp: "3h ago" },
];

export const planUsage = {
  plan: "Pro",
  documentsUsed: 420,
  documentsLimit: 1000,
  messagesUsed: 3200,
  messagesLimit: 5000,
};
```

## 11.3 Global Theme (globals.css)

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-brand-50:  oklch(0.97 0.02 265);
  --color-brand-100: oklch(0.93 0.05 265);
  --color-brand-500: oklch(0.58 0.22 265);
  --color-brand-600: oklch(0.50 0.22 265);
  --color-brand-700: oklch(0.42 0.20 265);
  --color-brand-900: oklch(0.28 0.14 265);
  --color-success: oklch(0.6 0.16 150);
  --color-warning: oklch(0.75 0.18 80);
  --color-danger:  oklch(0.55 0.22 25);

  --font-display: "Geist", ui-sans-serif, system-ui, sans-serif;
  --font-mono: "Geist Mono", ui-monospace, monospace;

  --radius-xl: 1rem;
  --radius-2xl: 1.5rem;
  --shadow-soft: 0 2px 10px rgb(0 0 0 / 0.06), 0 8px 24px rgb(0 0 0 / 0.08);
  --ease-snappy: cubic-bezier(0.2, 0, 0, 1);
  --animate-fade-in: fade-in 0.4s ease-out;
}

@keyframes fade-in {
  from { opacity: 0; transform: translateY(0.5rem); }
  to { opacity: 1; transform: translateY(0); }
}

body {
  @apply bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-100;
}
```

## 11.4 Root Layout

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
            __html: "(function() { const stored = localStorage.getItem('theme'); const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches; const isDark = stored === 'dark' || (!stored && prefersDark); document.documentElement.classList.toggle('dark', isDark); })();",
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

## 11.5 Sidebar

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

## 11.6 Topbar and ThemeToggle

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

*Next: Tailwind v4 Mastery - Part 11 (continued): Dashboard Components & Wrap-up*
