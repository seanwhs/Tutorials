# Appendix A3: Dashboard Widget Files

## A.18 `src/components/StatGrid.tsx`

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

## A.19 `src/components/RevenueChartCard.tsx`

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

## A.20 `src/components/RecentActivityFeed.tsx`

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

## A.21 `src/components/PlanUsagePanel.tsx`

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

## A.22 Setup Commands (Recap, End-to-End)

```bash
npx create-next-app@latest tw4-mastery --typescript --eslint --app --src-dir --import-alias "@/*"
cd tw4-mastery
npm install clsx tailwind-merge class-variance-authority lucide-react
npm install -D prettier prettier-plugin-tailwindcss eslint-plugin-tailwindcss
# Copy every file above into the matching path, then:
npm run dev
```

This is the complete, self-contained reference for the entire capstone project — every file needed to run PulseBoard locally is captured across Appendix A, A (continued), and A (part 3).

---

*Next: Tailwind v4 Mastery - Appendix B: v3 to v4 Migration Guide*
