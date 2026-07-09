# Part 16: RSVP Confirmation Emails with Resend and Inngest

Wires up real email sending: confirmation with QR ticket, triggered on RSVP. No route params here — nothing new Next.js 16-wise.

## 1. Set up Resend
```bash
# .env.local
RESEND_API_KEY=re_xxxxxxxxxxxx
```
Free tier lets you send from `onboarding@resend.dev` immediately; a verified custom domain is optional (needed for a polished "From" address).

## 2. Resend client wrapper
```ts
// src/lib/email.ts
import { Resend } from "resend";

const resend = new Resend(process.env.RESEND_API_KEY);
const FROM_ADDRESS = "EventHub <onboarding@resend.dev>";

export async function sendEmail(options: {
  to: string; subject: string; html: string;
  attachments?: { filename: string; content: string }[];
}) {
  const result = await resend.emails.send({
    from: FROM_ADDRESS, to: options.to, subject: options.subject,
    html: options.html, attachments: options.attachments,
  });
  if (result.error) throw new Error(`Failed to send email: ${result.error.message}`);
  return result;
}
```

## 3. Fire an Inngest event from RSVP action
In `src/lib/actions/rsvps.ts`, add import and, right before the `revalidatePath` calls in `rsvpToEvent`:
```ts
await inngest.send({ name: "event/rsvp.created", data: { rsvpId } });
```
Deliberately sends just `rsvpId` — the handler re-fetches fresh data itself, avoiding stale-data issues.

## 4. The Inngest function: send-rsvp-confirmation
```ts
// src/inngest/functions/send-rsvp-confirmation.ts
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

    const qrDataUrl = await step.run("generate-qr-code", async () =>
      generateTicketQrDataUrl({ rsvpId: rsvp.id, code: rsvp.ticketCode })
    );

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
          <p>Show the attached QR code at check-in, or give the organizer your ticket code.</p>
        </div>`,
        attachments: [{ filename: "ticket-qr-code.png", content: base64 }],
      });
    });

    return { emailedTo: rsvp.user.email };
  }
);
```
Each step (`fetch-rsvp`, `generate-qr-code`, `send-email`) is individually retried/cached — a failed email send doesn't redo already-successful steps.

## 5. Register the function
```ts
// src/app/api/inngest/route.ts
import { sendRsvpConfirmation } from "@/inngest/functions/send-rsvp-confirmation";
export const { GET, POST, PUT } = serve({ client: inngest, functions: [helloWorld, sendRsvpConfirmation] });
```

## 6. Try it out
RSVP with a real email address → Inngest Dev Server's **Runs** tab shows all 3 steps succeeding → check inbox for confirmation + QR PNG attachment. Try breaking `RESEND_API_KEY` temporarily to see a failed run + automatic retry.

## Checkpoint
- [ ] RSVPing sends `event/rsvp.created` to Inngest
- [ ] `send-rsvp-confirmation` completes all 3 steps
- [ ] Real email arrives with correct details + QR attachment

**Next: Part 17 — Scheduled Reminder Emails via Inngest Cron**
