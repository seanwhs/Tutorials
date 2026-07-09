# **Part 17: Scheduled Reminder Emails via Inngest Cron**:

---

# Part 17: Scheduled Reminder Emails via Inngest Cron

The second background job type: runs on a schedule (cron), not in reaction to an event. No route params here — nothing new Next.js 16-wise.

## 1. How cron functions work
Use `{ cron: "..." }` as the trigger instead of `{ event: "..." }`. Inngest's cloud service calls your function on schedule — no server-side timer needed.

## 2. Design
Every hour: find events starting within ~24h that haven't been reminded → email confirmed attendees → mark reminded.

## 3. Add reminderSentAt column
```ts
// src/db/schema.ts — add to events, after capacity, before createdAt
reminderSentAt: timestamp("reminder_sent_at", { withTimezone: true }),
```
```bash
pnpm db:generate
pnpm db:migrate
```

## 4. The cron function
```ts
// src/inngest/functions/send-event-reminders.ts
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import { events, rsvps } from "@/db/schema";
import { and, gte, lte, isNull, eq } from "drizzle-orm";
import { sendEmail } from "@/lib/email";

export const sendEventReminders = inngest.createFunction(
  { id: "send-event-reminders", retries: 2 },
  { cron: "0 * * * *" }, // every hour on the hour
  async ({ step }) => {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const upcomingEvents = await step.run("find-events-needing-reminders", async () =>
      db.select().from(events).where(
        and(gte(events.startsAt, now), lte(events.startsAt, in24Hours), isNull(events.reminderSentAt))
      )
    );

    for (const evt of upcomingEvents) {
      await step.run(`remind-for-event-${evt.id}`, async () => {
        const attendees = await db.query.rsvps.findMany({
          where: and(eq(rsvps.eventId, evt.id), eq(rsvps.status, "confirmed")),
          with: { user: true },
        });
        const startsAtFormatted = new Date(evt.startsAt).toLocaleString();

        for (const attendee of attendees) {
          await sendEmail({
            to: attendee.user.email,
            subject: `Reminder: ${evt.title} is coming up soon`,
            html: `<div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
              <h2>Don't forget: ${evt.title}</h2>
              <p><strong>When:</strong> ${startsAtFormatted}</p>
              <p><strong>Where:</strong> ${evt.location}</p>
              <p>Your ticket code: <strong>${attendee.ticketCode}</strong></p>
              <p>See you there!</p></div>`,
          });
        }

        await db.update(events).set({ reminderSentAt: new Date() }).where(eq(events.id, evt.id));
      });
    }

    return { eventsProcessed: upcomingEvents.length };
  }
);
```
Idempotency: `isNull(reminderSentAt)` filter + setting it after sending guarantees no double-emailing. Per-event `step.run` isolates retries.

## 5. Register the function
Add `sendEventReminders` to the `functions` array in `src/app/api/inngest/route.ts`.

## 6. Test locally without waiting an hour
Create a test event ~12h out with a confirmed RSVP → Dev Server → **Functions** → `send-event-reminders` → **Invoke** (empty payload) → check **Runs**, then attendee's inbox → invoke again to confirm idempotency (no re-send).

## Checkpoint
- [ ] `reminderSentAt` column exists
- [ ] Manual invoke finds & emails upcoming events' attendees
- [ ] Second invoke doesn't re-send
- [ ] Function registered, schedule visible in Dev Server

**Next: Part 18 — Email Deliverability, Idempotency, and Avoiding Duplicate Sends**
