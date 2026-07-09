# Part 8c: Organizer Dashboard List and Detail Pages

Introduces our first dynamic route (`[id]`) — where Next.js 16's async `params` convention really matters.

## 4. "My events" list page

`src/app/dashboard/page.tsx` — Server Component, queries `events` where `organizerId = user.id`, ordered by `startsAt desc`. Shows "+ Create event" link, empty state message, or a list of events linking to `/dashboard/[id]`. No route params here, so nothing to await.

## 5. Single event management page — first dynamic `[id]` route

**The key Next.js 16 pattern:** `params` is typed `Promise<{ id: string }>` and must be awaited before reading `id`. Every dynamic route for the rest of the series (`/events/[id]`, `/dashboard/[id]/checkin`, `/my-rsvps/[id]`) follows this exact shape.

`src/app/dashboard/[id]/page.tsx`:
```tsx
import { db } from "@/db";
import { events } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";
import Link from "next/link";

export default async function ManageEventPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params; // Next.js 16: always await params
  const user = await getOrCreateCurrentUser();
  if (!user) return null;

  const [event] = await db.select().from(events).where(eq(events.id, id)).limit(1);

  if (!event) notFound();
  if (event.organizerId !== user.id) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-12">
        <p className="text-red-600">You do not have permission to manage this event.</p>
      </main>
    );
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
        <Link href={`/events/${event.id}`} className="rounded-md border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50">
          View public page
        </Link>
      </div>
    </main>
  );
}
```

The manual `event.organizerId !== user.id` check is a pattern repeated everywhere organizer-only access matters — Clerk's middleware only knows "logged in," not "owns this specific resource."

## 6. Try it out
```bash
pnpm dev
```
Sign in → `/dashboard` shows empty state → create event → lands on `/dashboard/[id]` → back on `/dashboard`, event is listed.

## Checkpoint
- [ ] Event creation works via form
- [ ] Event appears in dashboard list
- [ ] Another user's event page shows permission-denied
- [ ] `params` is typed `Promise<{ id: string }>` and awaited — this pattern repeats everywhere going forward

**Next: Part 9 — Public Event Listing and Detail Pages**
