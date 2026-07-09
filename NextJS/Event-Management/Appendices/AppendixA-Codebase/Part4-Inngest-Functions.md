# Appendix A Part 4: Inngest Functions

The Clerk webhook route uses `headers()` from `next/headers`, async in Next.js 16, awaited accordingly.

## src/inngest/client.ts
```ts
import { Inngest } from "inngest";
export const inngest = new Inngest({ id: "eventhub" });
```

## src/inngest/functions/hello-world.ts
```ts
import { inngest } from "@/inngest/client";

export const helloWorld = inngest.createFunction(
  { id: "hello-world" },
  { event: "test/hello" },
  async ({ event, step }) => {
    await step.run("log-greeting", async () => { console.log(`Hello, ${event.data.name ?? "world"}!`); });
    return { message: `Hello, ${event.data.name ?? "world"}!` };
  }
);
```

## src/inngest/functions/send-rsvp-confirmation.ts (final, with idempotency key)
```ts
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import { rsvps } from "@/db/schema";
import { eq } from "drizzle-orm";
import { generateTicketQrDataUrl } from "@/lib/qrcode";
import { sendEmail } from "@/lib/email";

export const sendRsvpConfirmation = inngest.createFunction(
  { id: "send-rsvp-confirmation", retries: 3 },
  { event: "event/rsvp.created" },
  async ({ event, step }) => {
    const rsvpId = event.data.rsvpId as string;

    const rsvp = await step.run("fetch-rsvp", async () => {
      const found = await db.query.rsvps.findFirst({ where: eq(rsvps.id, rsvpId), with: { user: true, event: true } });
      if (!found) throw new Error(`RSVP ${rsvpId} not found`);
      return found;
    });

    const qrDataUrl = await step.run("generate-qr-code", async () => generateTicketQrDataUrl({ rsvpId: rsvp.id, code: rsvp.ticketCode }));

    await step.run("send-email", async () => {
      const base64 = qrDataUrl.split(",")[1];
      const startsAtFormatted = new Date(rsvp.event.startsAt).toLocaleString();
      await sendEmail({
        to: rsvp.user.email,
        subject: `You're going to ${rsvp.event.title}!`,
        html: `<div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
          <h2>You're confirmed for ${rsvp.event.title}</h2>
          <p><strong>When:</strong> ${startsAtFormatted}</p>
          <p><strong>Where:</strong> ${rsvp.event.location}</p>
          <p>Your ticket code: <strong>${rsvp.ticketCode}</strong></p>
          <p>Show the attached QR code at check-in, or give the organizer your ticket code.</p></div>`,
        attachments: [{ filename: "ticket-qr-code.png", content: base64 }],
        idempotencyKey: `rsvp-confirmation-${rsvp.id}`,
      });
    });

    return { emailedTo: rsvp.user.email };
  }
);
```

## src/inngest/functions/send-event-reminders.ts (final, idempotency key + rate-limit pause)
```ts
import { inngest } from "@/inngest/client";
import { db } from "@/db";
import { events, rsvps } from "@/db/schema";
import { and, gte, lte, isNull, eq } from "drizzle-orm";
import { sendEmail } from "@/lib/email";

export const sendEventReminders = inngest.createFunction(
  { id: "send-event-reminders", retries: 2 },
  { cron: "0 * * * *" },
  async ({ step }) => {
    const now = new Date();
    const in24Hours = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const upcomingEvents = await step.run("find-events-needing-reminders", async () =>
      db.select().from(events).where(and(gte(events.startsAt, now), lte(events.startsAt, in24Hours), isNull(events.reminderSentAt)))
    );

    for (const evt of upcomingEvents) {
      await step.run(`remind-for-event-${evt.id}`, async () => {
        const attendees = await db.query.rsvps.findMany({ where: and(eq(rsvps.eventId, evt.id), eq(rsvps.status, "confirmed")), with: { user: true } });
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
            idempotencyKey: `event-reminder-${evt.id}-${attendee.id}`,
          });
          await new Promise((resolve) => setTimeout(resolve, 600));
        }

        await db.update(events).set({ reminderSentAt: new Date() }).where(eq(events.id, evt.id));
      });
    }

    return { eventsProcessed: upcomingEvents.length };
  }
);
```

## src/app/api/inngest/route.ts
```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { helloWorld } from "@/inngest/functions/hello-world";
import { sendRsvpConfirmation } from "@/inngest/functions/send-rsvp-confirmation";
import { sendEventReminders } from "@/inngest/functions/send-event-reminders";

export const { GET, POST, PUT } = serve({ client: inngest, functions: [helloWorld, sendRsvpConfirmation, sendEventReminders] });
```

## src/app/api/webhooks/clerk/route.ts (uses Next.js 16's async headers())
```ts
import { Webhook } from "svix";
import { headers } from "next/headers";
import { db } from "@/db";
import { users } from "@/db/schema";
import { eq } from "drizzle-orm";

export async function POST(req: Request) {
  const webhookSecret = process.env.CLERK_WEBHOOK_SECRET;
  if (!webhookSecret) return new Response("Missing CLERK_WEBHOOK_SECRET", { status: 500 });

  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");
  if (!svixId || !svixTimestamp || !svixSignature) return new Response("Missing svix headers", { status: 400 });

  const body = await req.text();
  const wh = new Webhook(webhookSecret);
  let event: any;
  try {
    event = wh.verify(body, { "svix-id": svixId, "svix-timestamp": svixTimestamp, "svix-signature": svixSignature });
  } catch (err) {
    console.error("Clerk webhook verification failed:", err);
    return new Response("Invalid signature", { status: 400 });
  }

  const eventType = event.type;
  if (eventType === "user.created" || eventType === "user.updated") {
    const { id, email_addresses, first_name, last_name, image_url } = event.data;
    const primaryEmail = email_addresses?.[0]?.email_address ?? "unknown@example.com";
    const name = [first_name, last_name].filter(Boolean).join(" ").trim() || "Anonymous";
    const existing = await db.select().from(users).where(eq(users.clerkId, id)).limit(1);
    if (existing.length === 0) {
      await db.insert(users).values({ clerkId: id, email: primaryEmail, name, imageUrl: image_url ?? null });
    } else {
      await db.update(users).set({ email: primaryEmail, name, imageUrl: image_url ?? null }).where(eq(users.clerkId, id));
    }
  }
  if (eventType === "user.deleted") {
    const { id } = event.data;
    if (id) await db.delete(users).where(eq(users.clerkId, id));
  }
  return new Response("OK", { status: 200 });
}
```

**Next: Appendix A Part 5 — Pages and Components**
