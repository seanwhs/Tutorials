# Appendix A Part 5b: Pages (continued)

Every dynamic route below types `params`/`searchParams` as `Promise<{...}>` and awaits — Next.js 16 requirements.

## src/app/page.tsx
```tsx
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-5xl px-4 py-16">
      <h1 className="text-4xl font-bold tracking-tight text-gray-900">EventHub</h1>
      <p className="mt-4 text-lg text-gray-600">Discover events, RSVP for free, and manage check-ins — all in one place.</p>
      <Link href="/events" className="mt-8 inline-block rounded-md bg-gray-900 px-5 py-3 text-white hover:bg-gray-700">Browse events</Link>
    </main>
  );
}
```

## src/app/sign-in/[[...sign-in]]/page.tsx
```tsx
import { SignIn } from "@clerk/nextjs";
export default function Page() {
  return <div className="flex min-h-screen items-center justify-center"><SignIn /></div>;
}
```

## src/app/sign-up/[[...sign-up]]/page.tsx
```tsx
import { SignUp } from "@clerk/nextjs";
export default function Page() {
  return <div className="flex min-h-screen items-center justify-center"><SignUp /></div>;
}
```

## src/app/events/page.tsx (final, searchParams awaited)
```tsx
import Link from "next/link";
import { db } from "@/db";
import { events } from "@/db/schema";
import { and, gte, ilike, asc, count } from "drizzle-orm";

const PAGE_SIZE = 9;

export default async function EventsPage({
  searchParams,
}: { searchParams: Promise<{ q?: string; location?: string; page?: string }> }) {
  const params = await searchParams;
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

## src/app/events/[id]/page.tsx (final, waitlist UI + RsvpForm — params awaited)
```tsx
import { db } from "@/db";
import { events, rsvps } from "@/db/schema";
import { and, eq, count } from "drizzle-orm";
import { notFound } from "next/navigation";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { cancelRsvp } from "@/lib/actions/rsvps";
import { RsvpForm } from "@/components/rsvp-form";
import Link from "next/link";

export default async function EventDetailPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);
  if (!event) notFound();

  const user = await getOrCreateCurrentUser();

  const [{ value: confirmedCount }] = await db.select({ value: count() }).from(rsvps)
    .where(and(eq(rsvps.eventId, id), eq(rsvps.status, "confirmed")));

  let myRsvp = null;
  if (user) {
    const [existing] = await db.select().from(rsvps)
      .where(and(eq(rsvps.eventId, id), eq(rsvps.userId, user.id))).limit(1);
    if (existing && existing.status !== "cancelled") myRsvp = existing;
  }

  const spotsLeft = event.capacity - confirmedCount;

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-3xl font-bold text-gray-900">{event.title}</h1>
      <p className="mt-2 text-gray-600">{new Date(event.startsAt).toLocaleString()} – {new Date(event.endsAt).toLocaleString()}</p>
      <p className="text-gray-600">{event.location}</p>
      <p className="mt-1 text-sm text-gray-500">{spotsLeft > 0 ? `${spotsLeft} spot(s) left` : "This event is full"}</p>
      <div className="prose mt-6 max-w-none text-gray-800"><p>{event.description}</p></div>
      <div className="mt-8 rounded-lg border border-gray-200 p-6">
        {!user && <p className="text-gray-700"><Link href="/sign-in" className="underline">Sign in</Link> to RSVP for this event.</p>}
        {user && myRsvp && myRsvp.status === "confirmed" && (
          <div>
            <p className="font-medium text-green-700">You&apos;re going! Your ticket code is <span className="font-mono">{myRsvp.ticketCode}</span>.</p>
            <form action={async () => { "use server"; await cancelRsvp(myRsvp!.id); }} className="mt-3">
              <button className="rounded-md border border-red-300 px-4 py-2 text-sm text-red-700 hover:bg-red-50">Cancel RSVP</button>
            </form>
          </div>
        )}
        {user && myRsvp && myRsvp.status === "waitlisted" && (
          <div>
            <p className="font-medium text-amber-700">This event is full. You&apos;re on the waitlist — we&apos;ll email you automatically if a spot opens up.</p>
            <form action={async () => { "use server"; await cancelRsvp(myRsvp!.id); }} className="mt-3">
              <button className="rounded-md border border-red-300 px-4 py-2 text-sm text-red-700 hover:bg-red-50">Leave waitlist</button>
            </form>
          </div>
        )}
        {user && !myRsvp && <RsvpForm eventId={event.id} disabled={spotsLeft <= 0} />}
      </div>
    </main>
  );
}
```

**Next: Appendix A Part 5c (Dashboard and My-RSVPs Pages)**
