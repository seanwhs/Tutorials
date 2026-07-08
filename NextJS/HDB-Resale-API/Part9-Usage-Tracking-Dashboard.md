# Part 9: Usage Tracking Dashboard

Goal: record every successful API call per key per day, and show it as a bar chart on the dashboard.

---

## 1. Usage helpers

Create `src/lib/usage/usage.ts`:

```ts
import { redis } from "@/lib/redis";

export type UsageDay = {
  date: string;
  count: number;
};

function yyyyMmDd(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

export function usageKey(apiKeyId: string, date = yyyyMmDd()) {
  return `usage:${apiKeyId}:${date}`;
}

export async function recordUsage(apiKeyId: string) {
  const key = usageKey(apiKeyId);
  const value = await redis.incr(key);
  await redis.expire(key, 60 * 60 * 24 * 90);
  return value;
}

export async function getUsageForKey(apiKeyId: string, days = 14): Promise<UsageDay[]> {
  const results: UsageDay[] = [];

  for (let i = days - 1; i >= 0; i--) {
    const date = new Date();
    date.setUTCDate(date.getUTCDate() - i);
    const label = yyyyMmDd(date);
    const count = (await redis.get<number>(usageKey(apiKeyId, label))) ?? 0;
    results.push({ date: label, count });
  }

  return results;
}
```

---

## 2. Record usage in the public API route

Open `src/app/api/v1/resale-prices/route.ts` and add the import:

```ts
import { recordUsage } from "@/lib/usage/usage";
```

Then update the success path inside the `try` block to record usage right after a successful fetch, before returning the response:

```ts
try {
  const result = await fetchHdbResalePrices(parsed.data);
  await recordUsage(apiKey.id);

  return Response.json(
    {
      data: result.records,
      meta: {
        count: result.records.length,
        total: result.total,
        limit: parsed.data.limit,
        offset: parsed.data.offset,
        cached: result.cached,
      },
    },
    { headers },
  );
} catch (error) {
  console.error(error);
  return Response.json(
    { error: { message: "Unable to fetch HDB resale data right now.", status: 502 } },
    { status: 502, headers },
  );
}
```

We deliberately only record usage on success — 401s, 400s, and 429s don't count against a key's usage stats.

---

## 3. Usage dashboard page

Create `src/app/dashboard/usage/page.tsx`:

```tsx
import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth/session";
import { listApiKeys } from "@/lib/api-keys/api-keys";
import { getUsageForKey } from "@/lib/usage/usage";
import { Card, CardDescription, CardTitle } from "@/components/ui/card";

export default async function UsagePage() {
  const user = await getCurrentUser();
  if (!user) redirect("/login");

  const keys = await listApiKeys(user.email);
  const usageByKey = await Promise.all(
    keys.map(async (key) => ({
      key,
      usage: await getUsageForKey(key.id, 14),
    })),
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Usage</h1>
        <p className="mt-2 text-slate-600">API calls over the last 14 days.</p>
      </div>

      {usageByKey.map(({ key, usage }) => {
        const total = usage.reduce((sum, day) => sum + day.count, 0);
        const max = Math.max(...usage.map((day) => day.count), 1);

        return (
          <Card key={key.id}>
            <CardTitle>{key.name}</CardTitle>
            <CardDescription>{key.prefix}... · {total} calls in 14 days</CardDescription>
            <div className="mt-6 flex h-40 items-end gap-2">
              {usage.map((day) => (
                <div key={day.date} className="flex flex-1 flex-col items-center gap-2">
                  <div
                    className="w-full rounded-t bg-emerald-500"
                    style={{ height: `${Math.max((day.count / max) * 100, day.count > 0 ? 8 : 0)}%` }}
                    title={`${day.date}: ${day.count}`}
                  />
                  <span className="-rotate-45 text-[10px] text-slate-500">{day.date.slice(5)}</span>
                </div>
              ))}
            </div>
          </Card>
        );
      })}

      {usageByKey.length === 0 ? (
        <Card>
          <CardTitle>No API keys yet</CardTitle>
          <CardDescription>Create an API key first, then make requests to see usage.</CardDescription>
        </Card>
      ) : null}
    </div>
  );
}
```

---

## 4. Test it

Make a few calls:

```bash
curl "http://localhost:3000/api/v1/resale-prices?limit=1" \
  -H "x-api-key: paste_your_key_here"
```

Then visit `http://localhost:3000/dashboard/usage` — today's bar should reflect your call count.

---

## Checkpoint

- [ ] Successful calls increment today's usage counter.
- [ ] Failed calls (401/400/429) do not increment usage.
- [ ] The usage page shows a 14-day bar chart per key.
- [ ] Multiple keys show independent usage counts.

---

## Troubleshooting

**Usage stays at zero after several calls**
Make sure you're hitting `/api/v1/resale-prices` with a valid, active key — check the terminal for logged errors.

**Bars all look the same height**
That's expected if all days have zero calls except today — the chart scales relative to the highest single-day count (`max`).

**Counts look stale after making new calls**
This page is server-rendered on each request; simply refresh the browser tab.

---

Ready for **Part 10 — Documentation with Fumadocs**?
