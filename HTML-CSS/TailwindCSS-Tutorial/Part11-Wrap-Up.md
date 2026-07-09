# Part 11 (continued): Dashboard Components & Wrap-up

## 11.7 UI Primitives (Reused Unmodified from Part 7)

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

```ts
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## 11.8 StatGrid (Container Queries from Part 5 + StatBadge pattern from Part 4)

```tsx
import { ArrowUp, ArrowDown } from "lucide-react";
import { stats } from "@/lib/fake-data";
import { Card } from "@/components/ui/Card";

export function StatGrid() {
  return (
    <div className="@container">
      <div className="grid grid-cols-1 gap-4 @md:grid-cols-2 @2xl:grid-cols-4">
        {stats.map((stat) => {
          const isUp = stat.trend === "up";
          return (
            <Card key={stat.label} className="p-4">
              <p className="text-xs font-medium uppercase tracking-wide text-slate-400 dark:text-slate-500">
                {stat.label}
              </p>
              <div className="mt-1 flex items-end justify-between">
                <span className="text-2xl font-bold text-slate-900 dark:text-white">
                  {stat.value}
                </span>
                <span
                  className={
                    isUp
                      ? "flex items-center gap-1 rounded-full bg-success/10 px-2 py-1 text-xs font-semibold text-success"
                      : "flex items-center gap-1 rounded-full bg-danger/10 px-2 py-1 text-xs font-semibold text-danger"
                  }
                >
                  {isUp ? <ArrowUp className="size-3" /> : <ArrowDown className="size-3" />}
                </span>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
```

## 11.9 RevenueChartCard (CSS-only bar chart using arbitrary values from Part 9)

```tsx
import { Card, CardHeader, CardContent } from "@/components/ui/Card";
import { revenueByMonth } from "@/lib/fake-data";

export function RevenueChartCard() {
  const max = Math.max(...revenueByMonth.map((d) => d.value));

  return (
    <Card>
      <CardHeader>
        <h3 className="font-display font-semibold">Revenue (last 6 months)</h3>
      </CardHeader>
      <CardContent>
        <div className="flex h-40 items-end gap-3">
          {revenueByMonth.map((d) => (
            <div key={d.month} className="flex flex-1 flex-col items-center gap-2">
              <div
                className="w-full rounded-t-md bg-brand-500 transition-all duration-500 ease-snappy hover:bg-brand-600"
                style={{ height: (d.value / max) * 100 + "%" }}
              />
              <span className="text-xs text-slate-400 dark:text-slate-500">{d.month}</span>
            </div>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
```

## 11.10 RecentActivityFeed (not-last from Part 6, group hover from Part 6)

```tsx
import { Card, CardHeader, CardContent } from "@/components/ui/Card";
import { recentActivity } from "@/lib/fake-data";

export function RecentActivityFeed() {
  return (
    <Card>
      <CardHeader>
        <h3 className="font-display font-semibold">Recent Activity</h3>
      </CardHeader>
      <CardContent className="pt-4">
        <ul>
          {recentActivity.map((item) => (
            <li
              key={item.id}
              className="group flex items-center gap-3 py-3 not-last:border-b not-last:border-slate-100 dark:not-last:border-slate-800"
            >
              <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-brand-100 font-semibold text-brand-700 dark:bg-brand-900/40 dark:text-brand-200">
                {item.user.charAt(0)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm text-slate-700 dark:text-slate-200">
                  <span className="font-semibold">{item.user}</span> {item.action}
                </p>
              </div>
              <span className="shrink-0 text-xs text-slate-400 group-hover:text-brand-500 dark:text-slate-500">
                {item.timestamp}
              </span>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  );
}
```

## 11.11 PlanUsagePanel (has-checked pattern + progress bars)

```tsx
import { Card, CardHeader, CardContent } from "@/components/ui/Card";
import { planUsage } from "@/lib/fake-data";

function UsageBar({ label, used, limit }: { label: string; used: number; limit: number }) {
  const pct = Math.min(100, Math.round((used / limit) * 100));
  const isNearLimit = pct >= 80;

  return (
    <div>
      <div className="mb-1 flex justify-between text-xs text-slate-500 dark:text-slate-400">
        <span>{label}</span>
        <span>
          {used.toLocaleString()} / {limit.toLocaleString()}
        </span>
      </div>
      <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
        <div
          className={
            isNearLimit
              ? "h-full rounded-full bg-warning transition-all duration-500"
              : "h-full rounded-full bg-brand-500 transition-all duration-500"
          }
          style={{ width: pct + "%" }}
        />
      </div>
    </div>
  );
}

export function PlanUsagePanel() {
  return (
    <Card>
      <CardHeader>
        <h3 className="font-display font-semibold">Plan Usage</h3>
        <span className="rounded-full bg-brand-50 px-2 py-1 text-xs font-semibold text-brand-700 dark:bg-brand-900/40 dark:text-brand-200">
          {planUsage.plan}
        </span>
      </CardHeader>
      <CardContent className="space-y-4">
        <UsageBar label="Documents" used={planUsage.documentsUsed} limit={planUsage.documentsLimit} />
        <UsageBar label="Messages" used={planUsage.messagesUsed} limit={planUsage.messagesLimit} />
      </CardContent>
    </Card>
  );
}
```

## 11.12 Dashboard Home Page (Composing Everything)

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

## 11.13 What This Capstone Demonstrates (Traceability Table)

| Feature used | Sourced from |
|---|---|
| `@import "tailwindcss"` single-line config | Part 1, 2 |
| `@theme` brand/semantic color ramp, custom radii/shadows/easing | Part 3 |
| `@custom-variant dark` class-based dark mode | Part 5 |
| `@container` / `@md:` / `@2xl:` responsive stat grid | Part 5 |
| `group`, `not-last:` state variants | Part 6 |
| `cn()` + `Card` primitive component pattern | Part 7 |
| Server Components by default; `"use client"` only on `ThemeToggle` | Part 7 |
| `--animate-fade-in` custom keyframe on Card mount | Part 3, 8 |
| `transition-all duration-500 ease-snappy` on chart bars & progress bars | Part 8 |
| Arbitrary inline `style` height percentages (chart bars) | Part 9 |

## 11.14 Run It

```bash
npm run dev
# http://localhost:3000 — toggle dark mode, resize the window to see the
# @container-driven StatGrid reflow independently of the viewport breakpoint
```

---

*Next: Tailwind v4 Mastery - Appendix A: Full Codebase Reference*
