# Part 19: Event Capacity, Waitlist, and Cancellations

Upgrades the Part 10 hard-fail-at-capacity behavior into a real waitlist with automatic promotion on cancellation. Edits the same `/events/[id]` route — `params` handling unchanged.

## 1. Support waitlisting in rsvpToEvent
Replace the capacity check in `src/lib/actions/rsvps.ts`:
```ts
const [{ value: confirmedCount }] = await db
  .select({ value: count() }).from(rsvps)
  .where(and(eq(rsvps.eventId, eventId), eq(rsvps.status, "confirmed")));

const isFull = confirmedCount >= event.capacity;
const newStatus: "confirmed" | "waitlisted" = isFull ? "waitlisted" : "confirmed";
```
Use `newStatus` (not hardcoded `"confirmed"`) in both the reactivate and insert branches. Only send the confirmation email when actually confirmed:
```ts
if (newStatus === "confirmed") {
  await inngest.send({ name: "event/rsvp.created", data: { rsvpId } });
}
revalidatePath(`/events/${eventId}`);
revalidatePath("/my-rsvps");
return { rsvpId, status: newStatus };
```

## 2. Promote next waitlisted person on cancellation
Update `cancelRsvp`:
```ts
export async function cancelRsvp(rsvpId: string) {
  const user = await getOrCreateCurrentUser();
  if (!user) throw new Error("You must be signed in.");

  const [rsvp] = await db.select().from(rsvps).where(eq(rsvps.id, rsvpId)).limit(1);
  if (!rsvp) throw new Error("RSVP not found.");
  if (rsvp.userId !== user.id) throw new Error("Not your RSVP.");

  const wasConfirmed = rsvp.status === "confirmed";
  await db.update(rsvps).set({ status: "cancelled" }).where(eq(rsvps.id, rsvpId));

  if (wasConfirmed) {
    const [nextInLine] = await db
      .select().from(rsvps)
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
Add `asc` to the `drizzle-orm` import. Reuses the same `event/rsvp.created` Inngest event for the promoted attendee — no new function needed.

## 3. Update UI for waitlist status
In `src/app/events/[id]/page.tsx`, the `myRsvp` lookup now also captures `waitlisted` status (not just `confirmed`). JSX branches three ways: `confirmed` (green "You're going!" + Cancel), `waitlisted` (amber "You're on the waitlist" + Leave waitlist), or no RSVP (button labeled "RSVP for free" / "Join waitlist" depending on `spotsLeft`).

## 4. Try it out
Set capacity=1 → account A RSVPs ("You're going!") → account B RSVPs (amber waitlist message, no email yet) → cancel A → check Drizzle Studio: B is now `confirmed` → B's inbox gets the confirmation email → refresh B's page, shows "You're going!"

## Checkpoint
- [ ] Full event RSVP sets `waitlisted`, not a failure
- [ ] Waitlisted attendees get no email until promoted
- [ ] Cancelling promotes + emails the earliest waitlisted attendee
- [ ] UI distinguishes confirmed vs waitlisted correctly

**Next: Part 20 — Search, Filtering, and Pagination for Events**
