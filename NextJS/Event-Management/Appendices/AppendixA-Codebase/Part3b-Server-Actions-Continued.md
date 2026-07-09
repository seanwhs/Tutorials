# **Appendix A Part 3b: Server Actions (continued)**:

---

# Appendix A Part 3b: Server Actions (continued)

## src/lib/actions/events.ts
```ts
"use server";

import { db } from "@/db";
import { events } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";

export async function createEvent(formData: FormData) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new Error("You must be signed in to create an event.");

  const title = String(formData.get("title") ?? "").trim();
  const description = String(formData.get("description") ?? "").trim();
  const location = String(formData.get("location") ?? "").trim();
  const startsAtRaw = String(formData.get("startsAt") ?? "");
  const endsAtRaw = String(formData.get("endsAt") ?? "");
  const capacityRaw = String(formData.get("capacity") ?? "100");

  if (!title || !location || !startsAtRaw || !endsAtRaw) throw new Error("Title, location, start time, and end time are required.");

  const startsAt = new Date(startsAtRaw);
  const endsAt = new Date(endsAtRaw);
  const capacity = Math.max(1, parseInt(capacityRaw, 10) || 100);

  if (isNaN(startsAt.getTime()) || isNaN(endsAt.getTime())) throw new Error("Invalid date provided.");
  if (endsAt <= startsAt) throw new Error("End time must be after start time.");

  const [created] = await db.insert(events).values({ organizerId: user.id, title, description, location, startsAt, endsAt, capacity }).returning();

  revalidatePath("/dashboard");
  revalidatePath("/events");
  redirect(`/dashboard/${created.id}`);
}
```

## src/lib/actions/rsvps.ts (final — Part 19 waitlist + Part 22 useActionState signature)
```ts
"use server";

import { db } from "@/db";
import { events, rsvps } from "@/db/schema";
import { getOrCreateCurrentUser } from "@/lib/get-current-user";
import { generateTicketCode } from "@/lib/ticket-code";
import { decideRsvpStatus } from "@/lib/rsvp-rules";
import { inngest } from "@/inngest/client";
import { and, eq, count, asc } from "drizzle-orm";
import { revalidatePath } from "next/cache";

export async function rsvpToEvent(
  _prevState: { error: string | null },
  formData: FormData
): Promise<{ error: string | null }> {
  const user = await getOrCreateCurrentUser();
  if (!user) return { error: "You must be signed in to RSVP." };

  const eventId = String(formData.get("eventId") ?? "");
  const [event] = await db.select().from(events).where(eq(events.id, eventId)).limit(1);
  if (!event) return { error: "Event not found." };

  const [existing] = await db.select().from(rsvps)
    .where(and(eq(rsvps.eventId, eventId), eq(rsvps.userId, user.id))).limit(1);
  if (existing && existing.status !== "cancelled") return { error: "You have already RSVPed to this event." };

  const [{ value: confirmedCount }] = await db.select({ value: count() }).from(rsvps)
    .where(and(eq(rsvps.eventId, eventId), eq(rsvps.status, "confirmed")));
  const newStatus = decideRsvpStatus(confirmedCount, event.capacity);

  let rsvpId: string;
  if (existing && existing.status === "cancelled") {
    await db.update(rsvps).set({ status: newStatus, ticketCode: generateTicketCode() }).where(eq(rsvps.id, existing.id));
    rsvpId = existing.id;
  } else {
    const [created] = await db.insert(rsvps).values({ eventId, userId: user.id, ticketCode: generateTicketCode(), status: newStatus }).returning();
    rsvpId = created.id;
  }

  if (newStatus === "confirmed") await inngest.send({ name: "event/rsvp.created", data: { rsvpId } });

  revalidatePath(`/events/${eventId}`);
  revalidatePath("/my-rsvps");
  return { error: null };
}

export async function cancelRsvp(rsvpId: string) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new Error("You must be signed in.");

  const [rsvp] = await db.select().from(rsvps).where(eq(rsvps.id, rsvpId)).limit(1);
  if (!rsvp) throw new Error("RSVP not found.");
  if (rsvp.userId !== user.id) throw new Error("Not your RSVP.");

  const wasConfirmed = rsvp.status === "confirmed";
  await db.update(rsvps).set({ status: "cancelled" }).where(eq(rsvps.id, rsvpId));

  if (wasConfirmed) {
    const [nextInLine] = await db.select().from(rsvps)
      .where(and(eq(rsvps.eventId, rsvp.eventId), eq(rsvps.status, "waitlisted")))
      .orderBy(asc(rsvps.createdAt)).limit(1);

    if (nextInLine) {
      await db.update(rsvps).set({ status: "confirmed" }).where(eq(rsvps.id, nextInLine.id));
      await inngest.send({ name: "event/rsvp.created", data: { rsvpId: nextInLine.id } });
    }
  }

  revalidatePath(`/events/${rsvp.eventId}`);
  revalidatePath("/my-rsvps");
}
```

## src/lib/actions/checkin.ts (final, using requireEventOwner)
```ts
"use server";

import { db } from "@/db";
import { rsvps, checkIns } from "@/db/schema";
import { requireEventOwner } from "@/lib/authz";
import { eq } from "drizzle-orm";
import { revalidatePath } from "next/cache";

type CheckInResult = { ok: true; attendeeName: string; eventTitle: string } | { ok: false; message: string };

export async function checkInByCode(rawInput: string, eventId: string): Promise<CheckInResult> {
  let event; let organizer;
  try {
    ({ event, user: organizer } = await requireEventOwner(eventId));
  } catch (err) {
    return { ok: false, message: err instanceof Error ? err.message : "Not authorized." };
  }

  let ticketCode = rawInput.trim();
  let rsvpIdHint: string | null = null;
  try {
    const parsed = JSON.parse(rawInput);
    if (parsed && typeof parsed.code === "string") {
      ticketCode = parsed.code;
      rsvpIdHint = typeof parsed.rsvpId === "string" ? parsed.rsvpId : null;
    }
  } catch { /* not JSON — plain code */ }

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

export async function getEventAttendeeStats(eventId: string) {
  const { event } = await requireEventOwner(eventId);
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

**Next: Appendix A Part 4 — Inngest Functions**
