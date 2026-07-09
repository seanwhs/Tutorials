# Part 10: Free RSVP Flow (Server Actions)

The heart of the app: letting a signed-in user RSVP for free.

## 1. Ticket code helper
```ts
// src/lib/ticket-code.ts
import { randomBytes } from "crypto";

export function generateTicketCode(): string {
  return randomBytes(8).toString("hex"); // 16 hex chars, URL-safe
}
```

## 2. RSVP/cancel server actions

`src/lib/actions/rsvps.ts`:
```ts
"use server";

import { db } from "@/db";
import { events, rsvps } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { generateTicketCode } from "@/lib/ticket-code";
import { and, eq, count } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export async function rsvpToEvent(eventId: string) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new Error("You must be signed in to RSVP.");

  const [event] = await db.select().from(events).where(eq(events.id, eventId)).limit(1);
  if (!event) throw new Error("Event not found.");

  const [existing] = await db
    .select().from(rsvps)
    .where(and(eq(rsvps.eventId, eventId), eq(rsvps.userId, user.id)))
    .limit(1);

  if (existing && existing.status !== "cancelled") {
    throw new Error("You have already RSVPed to this event.");
  }

  const [{ value: confirmedCount }] = await db
    .select({ value: count() }).from(rsvps)
    .where(and(eq(rsvps.eventId, eventId), eq(rsvps.status, "confirmed")));

  if (confirmedCount >= event.capacity) throw new Error("This event is at full capacity.");

  let rsvpId: string;
  if (existing && existing.status === "cancelled") {
    await db.update(rsvps).set({ status: "confirmed", ticketCode: generateTicketCode() }).where(eq(rsvps.id, existing.id));
    rsvpId = existing.id;
  } else {
    const [created] = await db.insert(rsvps).values({ eventId, userId: user.id, ticketCode: generateTicketCode(), status: "confirmed" }).returning();
    rsvpId = created.id;
  }

  // Part 16 adds an Inngest event/rsvp.created send here

  revalidatePath(`/events/${eventId}`);
  revalidatePath("/my-rsvps");
  return { rsvpId };
}

export async function cancelRsvp(rsvpId: string) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new Error("You must be signed in.");

  const [rsvp] = await db.select().from(rsvps).where(eq(rsvps.id, rsvpId)).limit(1);
  if (!rsvp) throw new Error("RSVP not found.");
  if (rsvp.userId !== user.id) throw new Error("Not your RSVP.");

  await db.update(rsvps).set({ status: "cancelled" }).where(eq(rsvps.id, rsvpId));
  revalidatePath(`/events/${rsvp.eventId}`);
  revalidatePath("/my-rsvps");
}
```
Design notes: checks for existing non-cancelled RSVP (no duplicates); reactivates a cancelled row with a fresh ticket code rather than inserting a new one; capacity is a hard block for now (Part 19 adds waitlisting).

## 3. Wire RSVP button into event detail page

Update `src/app/events/[id]/page.tsx` (same `Promise<{ id: string }>` params pattern from Part 9) — adds spots-left count, and conditionally renders: sign-in prompt (logged out), "You're going!" + Cancel RSVP (has RSVP), or RSVP/Event-full button (no RSVP yet). Uses inline server actions (`action={async () => { "use server"; ... }}`) for Cancel/RSVP form submissions.

## 4. Try it out
Sign in → RSVP → see ticket code → Cancel → RSVP again (new code) → sign out (see sign-in prompt) → test capacity=1 in Drizzle Studio with two accounts (second sees "Event full", disabled).

## Checkpoint
- [ ] RSVP creates a `confirmed` row with unique `ticketCode`
- [ ] Cancel sets status to `cancelled`, doesn't delete
- [ ] Re-RSVP reuses the row with a fresh code
- [ ] Capacity enforced — button disables at full

**Next: Part 11 — Attendee Dashboard (My RSVPs)**
