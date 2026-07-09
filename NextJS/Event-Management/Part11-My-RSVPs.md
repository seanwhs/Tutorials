# **Part 11: Attendee Dashboard (My RSVPs)**:

---

# Part 11: Attendee Dashboard (My RSVPs)

A page listing every event the attendee has RSVPed to, using Drizzle's relational query API. Introduces another dynamic `[id]` route (ticket page) — `params` awaited as usual.

## 1. "My RSVPs" page

`src/app/my-rsvps/page.tsx`:
```tsx
import Link from "next/link";
import { db } from "@/db";
import { rsvps } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { eq, and, ne } from "drizzle-orm";

export default async function MyRsvpsPage() {
  const user = await getOrCreateCurrentUser();
  if (!user) return null;

  const myRsvps = await db.query.rsvps.findMany({
    where: and(eq(rsvps.userId, user.id), ne(rsvps.status, "cancelled")),
    with: { event: true },
  });

  myRsvps.sort((a, b) => new Date(a.event.startsAt).getTime() - new Date(b.event.startsAt).getTime());

  return (
    <main className="mx-auto max-w-3xl px-4 py-12">
      <h1 className="text-2xl font-bold text-gray-900">My RSVPs</h1>
      {myRsvps.length === 0 ? (
        <p className="mt-8 text-gray-600">
          You haven&apos;t RSVPed to any events yet. <Link href="/events" className="underline">Browse events</Link>.
        </p>
      ) : (
        <ul className="mt-8 divide-y divide-gray-200">
          {myRsvps.map((rsvp) => (
            <li key={rsvp.id} className="py-4">
              <div className="flex items-center justify-between">
                <div>
                  <Link href={`/events/${rsvp.event.id}`} className="text-lg font-medium text-gray-900 hover:underline">
                    {rsvp.event.title}
                  </Link>
                  <p className="text-sm text-gray-600">
                    {new Date(rsvp.event.startsAt).toLocaleString()} · {rsvp.event.location}
                  </p>
                  <p className="mt-1 text-xs font-mono text-gray-500">Ticket: {rsvp.ticketCode}</p>
                </div>
                <Link href={`/my-rsvps/${rsvp.id}`} className="rounded-md border border-gray-300 px-3 py-1.5 text-sm hover:bg-gray-50">
                  View ticket
                </Link>
              </div>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
```
Uses `db.query.rsvps.findMany({ with: { event: true } })` — Drizzle's relational API (from Part 7's `relations()` definitions), cleaner than a manual join. No route params here.

## 2. Placeholder ticket view page

Dynamic `[id]` route — `params: Promise<{ id: string }>`, awaited.

`src/app/my-rsvps/[id]/page.tsx`:
```tsx
import { db } from "@/db";
import { rsvps } from "@/db/schema";
import { eq } from "drizzle-orm";
import { notFound } from "next/navigation";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";

export default async function TicketPage({
  params,
}: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await getOrCreateCurrentUser();
  if (!user) return null;

  const rsvp = await db.query.rsvps.findFirst({ where: eq(rsvps.id, id), with: { event: true } });

  if (!rsvp) notFound();
  if (rsvp.userId !== user.id) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-12">
        <p className="text-red-600">This ticket does not belong to you.</p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-md px-4 py-12">
      <h1 className="text-xl font-bold text-gray-900">{rsvp.event.title}</h1>
      <p className="mt-1 text-sm text-gray-600">{new Date(rsvp.event.startsAt).toLocaleString()}</p>
      <div className="mt-6 rounded-lg border border-gray-200 p-6 text-center">
        <p className="text-sm text-gray-500">QR code ticket coming in Part 12</p>
        <p className="mt-2 font-mono text-lg">{rsvp.ticketCode}</p>
      </div>
    </main>
  );
}
```

## 3. Try it out
RSVP to 1–2 events → `/my-rsvps` lists them soonest-first → "View ticket" shows placeholder page → confirm `/my-rsvps` requires login (redirects when signed out).

## Checkpoint
- [ ] `/my-rsvps` lists only current user's non-cancelled RSVPs, soonest first
- [ ] Ticket links show correct code
- [ ] Someone else's ticket ID shows "does not belong to you," not the real ticket
- [ ] `params` typed `Promise<{ id: string }>` and awaited

**Next: Part 12 — QR Code Ticket Generation**
