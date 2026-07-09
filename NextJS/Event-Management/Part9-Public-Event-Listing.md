# **Part 9: Public Event Listing and Detail Pages**:

---

# Part 9: Public Event Listing and Detail Pages

Anyone — logged in or not — can browse upcoming events. Includes another dynamic `[id]` route awaiting `params`.

## 1. Public events list

`src/app/events/page.tsx`:
```tsx
import Link from "next/link";
import { db } from "@/db";
import { events } from "@/db/schema";
import { gte, asc } from "drizzle-orm";

export default async function EventsPage() {
  const now = new Date();

  const upcoming = await db
    .select()
    .from(events)
    .where(gte(events.startsAt, now))
    .orderBy(asc(events.startsAt));

  return (
    <main className="mx-auto max-w-4xl px-4 py-12">
      <h1 className="text-3xl font-bold text-gray-900">Upcoming events</h1>
      {upcoming.length === 0 ? (
        <p className="mt-8 text-gray-600">No upcoming events right now. Check back soon, or create your own!</p>
      ) : (
        <ul className="mt-8 grid gap-4 sm:grid-cols-2">
          {upcoming.map((event) => (
            <li key={event.id} className="rounded-lg border border-gray-200 p-5 hover:shadow-sm">
              <Link href={`/events/${event.id}`}>
                <h2 className="text-lg font-semibold text-gray-900">{event.title}</h2>
                <p className="mt-1 text-sm text-gray-600">{new Date(event.startsAt).toLocaleString()}</p>
                <p className="text-sm text-gray-600">{event.location}</p>
              </Link>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```
`gte(events.startsAt, now)` filters out past events. No route params here — nothing to await. (Search/pagination with `searchParams` — also a Promise — comes in Part 20.)

## 2. Public event detail page

Another dynamic `[id]` route — `params` awaited the same way.

`src/app/events/[id]/page.tsx`:
```tsx
import { db } from "@/db";
import { events } from "@/db/schema";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";

export default async function EventDetailPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);
  if (!event) notFound();

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-3xl font-bold text-gray-900">{event.title}</h1>
      <p className="mt-2 text-gray-600">
        {new Date(event.startsAt).toLocaleString()} – {new Date(event.endsAt).toLocaleString()}
      </p>
      <p className="text-gray-600">{event.location}</p>
      <div className="prose mt-6 max-w-none text-gray-800"><p>{event.description}</p></div>
      <div className="mt-8 rounded-lg border border-gray-200 p-6">
        <p className="text-sm text-gray-600">RSVP functionality is added in Part 10 of this tutorial.</p>
      </div>
    </main>
  );
}
```

## 3. Update home page
`src/app/page.tsx` — add a "Browse events" link to `/events`.

## 4. Try it out
Visit `/events` signed out → see event(s) from Part 8. Click through → full detail + placeholder box. Confirm no login required (only `/dashboard`/`/my-rsvps` are protected).

## Checkpoint
- [ ] `/events` publicly lists only upcoming events, soonest first
- [ ] `/events/[id]` shows details for anyone, awaits `params` correctly
- [ ] Past events don't appear in the list

**Next: Part 10 — Free RSVP Flow (Server Actions)**
