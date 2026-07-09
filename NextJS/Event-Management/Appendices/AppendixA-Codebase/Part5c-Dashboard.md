# **Appendix A Part 5c: Dashboard and My-RSVPs Pages**:

---

# Appendix A Part 5c: Dashboard and My-RSVPs Pages

Both dynamic routes below type `params` as `Promise<{ id: string }>` and await it.

## src/app/dashboard/page.tsx
```tsx
import Link from "next/link";
import { db } from "@/db";
import { events } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { eq, desc } from "drizzle-orm";

export default async function DashboardPage() {
  const user = await getOrCreateCurrentUser();
  if (!user) return null;

  const myEvents = await db.select().from(events).where(eq(events.organizerId, user.id)).orderBy(desc(events.startsAt));

  return (
    <main className="mx-auto max-w-4xl px-4 py-12">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">My events</h1>
        <Link href="/dashboard/new" className="rounded-md bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700">+ Create event</Link>
      </div>
      {myEvents.length === 0 ? (
        <p className="mt-8 text-gray-600">You haven&apos;t created any events yet.</p>
      ) : (
        <ul className="mt-8 divide-y divide-gray-200">
          {myEvents.map((event) => (
            <li key={event.id} className="py-4">
              <Link href={`/dashboard/${event.id}`} className="text-lg font-medium text-gray-900 hover:underline">{event.title}</Link>
              <p className="text-sm text-gray-600">{new Date(event.startsAt).toLocaleString()} · {event.location}</p>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```

## src/app/dashboard/new/page.tsx
```tsx
import { createEvent } from "@/lib/actions/events";

export default function NewEventPage() {
  return (
    <main className="mx-auto max-w-2xl px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-900">Create an event</h1>
      <p className="mt-2 text-gray-600">Fill in the details below. You will be able to edit this later.</p>
      <form action={createEvent} className="mt-8 space-y-6">
        <div><label className="block text-sm font-medium text-gray-700">Title</label>
          <input name="title" required className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" placeholder="Summer Tech Meetup" /></div>
        <div><label className="block text-sm font-medium text-gray-700">Description</label>
          <textarea name="description" rows={4} className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" placeholder="Tell attendees what to expect..." /></div>
        <div><label className="block text-sm font-medium text-gray-700">Location</label>
          <input name="location" required className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" placeholder="123 Main St, or a video call link" /></div>
        <div className="grid grid-cols-2 gap-4">
          <div><label className="block text-sm font-medium text-gray-700">Starts at</label>
            <input type="datetime-local" name="startsAt" required className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" /></div>
          <div><label className="block text-sm font-medium text-gray-700">Ends at</label>
            <input type="datetime-local" name="endsAt" required className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" /></div>
        </div>
        <div><label className="block text-sm font-medium text-gray-700">Capacity</label>
          <input type="number" name="capacity" min={1} defaultValue={100} className="mt-1 w-full rounded-md border border-gray-300 px-3 py-2" /></div>
        <button type="submit" className="rounded-md bg-gray-900 px-4 py-2 text-white hover:bg-gray-700">Create event</button>
      </form>
    </main>
  );
}
```

## src/app/dashboard/[id]/page.tsx (final, uses requireEventOwner)
```tsx
import { requireEventOwner, AuthorizationError } from "@/lib/authz";
import { notFound } from "next/navigation";
import Link from "next/link";

export default async function ManageEventPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let event;
  try {
    ({ event } = await requireEventOwner(id));
  } catch (err) {
    if (err instanceof AuthorizationError) {
      return <main className="mx-auto max-w-2xl px-4 py-12"><p className="text-red-600">{err.message}</p></main>;
    }
    notFound();
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-900">{event.title}</h1>
      <p className="mt-2 text-gray-600">{event.description}</p>
      <dl className="mt-6 grid grid-cols-2 gap-4 text-sm">
        <div><dt className="font-medium text-gray-500">Location</dt><dd className="text-gray-900">{event.location}</dd></div>
        <div><dt className="font-medium text-gray-500">Capacity</dt><dd className="text-gray-900">{event.capacity}</dd></div>
        <div><dt className="font-medium text-gray-500">Starts</dt><dd className="text-gray-900">{new Date(event.startsAt).toLocaleString()}</dd></div>
        <div><dt className="font-medium text-gray-500">Ends</dt><dd className="text-gray-900">{new Date(event.endsAt).toLocaleString()}</dd></div>
      </dl>
      <div className="mt-8 flex gap-3">
        <Link href={`/events/${event.id}`} className="rounded-md border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50">View public page</Link>
        <Link href={`/dashboard/${event.id}/checkin`} className="rounded-md bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700">Open check-in dashboard</Link>
      </div>
    </main>
  );
}
```

## src/app/dashboard/[id]/checkin/page.tsx (final)
```tsx
import { getEventAttendeeStats } from "@/lib/actions/checkin";
import { CheckInScanner } from "@/components/checkin-scanner";
import { AttendeeList } from "@/components/attendee-list";
import { notFound } from "next/navigation";

export default async function CheckInPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  let stats;
  try { stats = await getEventAttendeeStats(id); } catch { notFound(); }

  return (
    <main className="mx-auto max-w-4xl px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-900">Check in: {stats.event.title}</h1>
      <p className="mt-2 text-sm text-gray-600">Scan an attendee&apos;s QR code, or type their ticket code manually below.</p>
      <div className="mt-6 grid gap-8 md:grid-cols-2">
        <div><CheckInScanner eventId={stats.event.id} /></div>
        <div><AttendeeList eventId={stats.event.id} initialStats={stats} /></div>
      </div>
    </main>
  );
}
```

**Next: Appendix A Part 5d (My-RSVPs and Admin Pages)**
