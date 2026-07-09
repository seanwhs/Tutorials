# **Part 14: Organizer Check-In Dashboard and Live Stats**:

---

# Part 14: Organizer Check-In Dashboard and Live Stats

A dashboard showing the full attendee list, checked-in status, and a live-updating count. Continues editing the same `/dashboard/[id]/checkin` route — `params` handling unchanged.

## 1. Server action to fetch attendee/check-in data

Add to `src/lib/actions/checkin.ts`:
```ts
export async function getEventAttendeeStats(eventId: string) {
  const organizer = await getOrCreateCurrentUser();
  if (!organizer) throw new Error("Not signed in.");

  const [event] = await db.select().from(events).where(eq(events.id, eventId)).limit(1);
  if (!event) throw new Error("Event not found.");
  if (event.organizerId !== organizer.id) throw new Error("Not your event.");

  const attendees = await db.query.rsvps.findMany({ where: eq(rsvps.eventId, eventId), with: { user: true, checkIn: true } });
  const confirmed = attendees.filter((a) => a.status === "confirmed");
  const checkedIn = confirmed.filter((a) => a.checkIn);

  return {
    event,
    attendees: confirmed.sort((a, b) => a.user.name.localeCompare(b.user.name)),
    totalConfirmed: confirmed.length,
    totalCheckedIn: checkedIn.length,
  };
}
```

## 2. Update check-in page to add the live dashboard

`src/app/dashboard/[id]/checkin/page.tsx` (same file, `params` still `Promise<{ id: string }>`):
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
  try {
    stats = await getEventAttendeeStats(id);
  } catch {
    notFound();
  }

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

## 3. Live-updating attendee list

`src/components/attendee-list.tsx` — client component, polls `getEventAttendeeStats` every 4s via `useEffect`/`setInterval` (simple, dependency-free "live" updates, no WebSockets needed). Takes plain props (`eventId`, `initialStats`), not route params. Renders a checked-in/total count, progress bar (%), and a scrollable attendee list with "Checked in"/"Not yet" badges.

## 4. Link from event management page
Add to `src/app/dashboard/[id]/page.tsx`'s existing button row:
```tsx
<Link href={`/dashboard/${event.id}/checkin`} className="rounded-md bg-gray-900 px-4 py-2 text-sm text-white hover:bg-gray-700">
  Open check-in dashboard
</Link>
```

## 5. Try it out
RSVP 2 test accounts (different browsers/incognito) → open check-in dashboard as organizer → see scanner + attendee list (all "Not yet", 0%) → check one in manually → within ~4s, list updates automatically to "Checked in" with updated %.

## Checkpoint
- [ ] Attendee list shows every confirmed RSVP with correct status
- [ ] Checking someone in updates the live view automatically within seconds
- [ ] Percentage/progress bar update correctly

This wraps up the core event/RSVP/check-in feature set. Next: background jobs.

**Next: Part 15 — Setting Up Inngest**
