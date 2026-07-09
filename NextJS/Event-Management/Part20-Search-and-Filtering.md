# **Part 20: Search, Filtering, and Pagination for Events**:

---

# Part 20: Search, Filtering, and Pagination for Events

First use of `searchParams` — exactly like `params`, it's a **Promise in Next.js 16** and must be awaited.

## 1. Update events page

`src/app/events/page.tsx`:
```tsx
import Link from "next/link";
import { db } from "@/db";
import { events } from "@/db/schema";
import { and, gte, ilike, asc, count } from "drizzle-orm";

const PAGE_SIZE = 9;

export default async function EventsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string; location?: string; page?: string }>;
}) {
  const params = await searchParams; // Next.js 16: always await
  const q = params.q?.trim() ?? "";
  const location = params.location?.trim() ?? "";
  const page = Math.max(1, parseInt(params.page ?? "1", 10) || 1);

  const now = new Date();
  const conditions = [gte(events.startsAt, now)];
  if (q) conditions.push(ilike(events.title, `%${q}%`));
  if (location) conditions.push(ilike(events.location, `%${location}%`));
  const whereClause = and(...conditions);

  const [{ value: totalCount }] = await db.select({ value: count() }).from(events).where(whereClause);
  const totalPages = Math.max(1, Math.ceil(totalCount / PAGE_SIZE));

  const results = await db.select().from(events).where(whereClause)
    .orderBy(asc(events.startsAt)).limit(PAGE_SIZE).offset((page - 1) * PAGE_SIZE);

  function pageLink(targetPage: number) {
    const sp = new URLSearchParams();
    if (q) sp.set("q", q);
    if (location) sp.set("location", location);
    sp.set("page", String(targetPage));
    return `/events?${sp.toString()}`;
  }

  return (
    <main className="mx-auto max-w-4xl px-4 py-12">
      <h1 className="text-3xl font-bold text-gray-900">Upcoming events</h1>
      <form className="mt-6 flex flex-wrap gap-3" action="/events">
        <input type="text" name="q" defaultValue={q} placeholder="Search by title..." className="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm" />
        <input type="text" name="location" defaultValue={location} placeholder="Filter by location..." className="flex-1 rounded-md border border-gray-300 px-3 py-2 text-sm" />
        <button type="submit" className="rounded-md bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700">Search</button>
      </form>
      {results.length === 0 ? (
        <p className="mt-8 text-gray-600">No events match your search. Try different terms, or <Link href="/events" className="underline">clear filters</Link>.</p>
      ) : (
        <>
          <ul className="mt-8 grid gap-4 sm:grid-cols-2">
            {results.map((event) => (
              <li key={event.id} className="rounded-lg border border-gray-200 p-5 hover:shadow-sm">
                <Link href={`/events/${event.id}`}>
                  <h2 className="text-lg font-semibold text-gray-900">{event.title}</h2>
                  <p className="mt-1 text-sm text-gray-600">{new Date(event.startsAt).toLocaleString()}</p>
                  <p className="text-sm text-gray-600">{event.location}</p>
                </Link>
              </li>
            ))}
          </ul>
          <div className="mt-8 flex items-center justify-between text-sm">
            <span className="text-gray-500">Page {page} of {totalPages} ({totalCount} events)</span>
            <div className="flex gap-2">
              {page > 1 && <Link href={pageLink(page - 1)} className="rounded-md border border-gray-300 px-3 py-1.5 hover:bg-gray-50">Previous</Link>}
              {page < totalPages && <Link href={pageLink(page + 1)} className="rounded-md border border-gray-300 px-3 py-1.5 hover:bg-gray-50">Next</Link>}
            </div>
          </div>
        </>
      )}
    </main>
  );
}
```

Key points: `searchParams` is a Promise — TypeScript will flag a missed `await`; `ilike` gives case-insensitive substring search (fine at small/medium scale — `tsvector`/`tsquery` for real full-text search later); plain `<form action="/events">` (GET) means no client JS needed, just a URL like `/events?q=meetup&location=nyc`; pagination links preserve active filters.

## 2. Optional: search performance index
Hand-written SQL migration (Drizzle Kit doesn't generate extension/trigram indexes):
```sql
-- drizzle/0003_add_search_indexes.sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS events_title_trgm_idx ON events USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS events_location_trgm_idx ON events USING gin (location gin_trgm_ops);
```
Run via Neon's dashboard SQL editor or `psql`. Skip if your event list is small.

## 3. Try it out
Create varied test events → search by title substring → add location filter (AND logic) → create 10+ events, confirm pagination preserves search terms in the URL.

## Checkpoint
- [ ] Title search returns only matches, case-insensitive
- [ ] Title + location filters combine correctly
- [ ] Pagination shows correct counts, preserves filters
- [ ] Clearing filters shows all upcoming events
- [ ] `searchParams` typed `Promise<{...}>`, awaited

**Next: Part 21 — Authorization and Roles with Clerk**
