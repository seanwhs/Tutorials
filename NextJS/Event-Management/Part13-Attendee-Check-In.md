# **Part 13: Attendee Check-In Flow**:

---

# Part 13: Attendee Check-In Flow

Organizer-facing scanner/manual-code check-in flow. New dynamic route `/dashboard/[id]/checkin` — `params` again awaited.

## 1. Install QR scanning library
```bash
pnpm add html5-qrcode
```
Free, open-source (Apache-2.0), decodes QR codes via browser camera.

## 2. Server action to check someone in

`src/lib/actions/checkin.ts`:
```ts
"use server";

import { db } from "@/db";
import { rsvps, checkIns, events } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";

type CheckInResult = { ok: true; attendeeName: string; eventTitle: string } | { ok: false; message: string };

export async function checkInByCode(rawInput: string, eventId: string): Promise<CheckInResult> {
  const organizer = await getOrCreateCurrentUser();
  if (!organizer) return { ok: false, message: "You must be signed in." };

  const [event] = await db.select().from(events).where(eq(events.id, eventId)).limit(1);
  if (!event) return { ok: false, message: "Event not found." };
  if (event.organizerId !== organizer.id) return { ok: false, message: "You do not manage this event." };

  let ticketCode = rawInput.trim();
  let rsvpIdHint: string | null = null;
  try {
    const parsed = JSON.parse(rawInput);
    if (parsed && typeof parsed.code === "string") {
      ticketCode = parsed.code;
      rsvpIdHint = typeof parsed.rsvpId === "string" ? parsed.rsvpId : null;
    }
  } catch { /* not JSON — treat as plain code */ }

  const rsvp = await db.query.rsvps.findFirst({ where: eq(rsvps.ticketCode, ticketCode), with: { user: true, checkIn: true } });

  if (!rsvp) return { ok: false, message: "No ticket found with that code." };
  if (rsvpIdHint && rsvp.id !== rsvpIdHint) return { ok: false, message: "Ticket code mismatch. Possible tampering." };
  if (rsvp.eventId !== eventId) return { ok: false, message: "This ticket is for a different event." };
  if (rsvp.status === "cancelled") return { ok: false, message: "This RSVP was cancelled." };
  if (rsvp.checkIn) return { ok: false, message: `Already checked in at ${new Date(rsvp.checkIn.checkedInAt).toLocaleTimeString()}.` };

  await db.insert(checkIns).values({ rsvpId: rsvp.id, checkedInBy: organizer.id });
  revalidatePath(`/dashboard/${eventId}/checkin`);
  return { ok: true, attendeeName: rsvp.user.name, eventTitle: event.title };
}
```
Accepts scanned JSON or manual code, validates event match/status/not-already-used, confirms caller owns the event.

## 3. Check-in page + scanner component

`src/app/dashboard/[id]/checkin/page.tsx` — server component, awaits `params`, verifies ownership, renders `<CheckInScanner eventId={event.id} />`.

`src/components/checkin-scanner.tsx` — client component (`"use client"`), receives plain `eventId` prop (not route params, so unaffected by the async change). Dynamically `import("html5-qrcode")` inside `startScanner()` (client-only, never in server bundle). Has a "Start camera scanner" button + manual code input form, shows green/red status message. Pauses scanner 2s after a successful scan to avoid re-scanning the same code repeatedly.

Note: camera requires HTTPS or `localhost` — works locally and on Vercel automatically, not over plain HTTP on a LAN IP.

## 4. Try it out
Visit `/dashboard/[id]/checkin` → start scanner or paste a ticket code from Drizzle Studio → green success → re-check same code → "Already checked in" → visit `/my-rsvps/[id]` → shows "Checked in at..." from Part 12.

## Checkpoint
- [ ] Manual code check-in works for a fresh ticket
- [ ] Re-checking shows "already checked in," no duplicate
- [ ] Camera scanner starts and decodes a real QR code
- [ ] Non-organizer blocked from another organizer's check-in page
- [ ] `params` typed `Promise<{ id: string }>`, awaited

**Next: Part 14 — Organizer Check-In Dashboard and Live Stats**
