# Part 18: Email Deliverability, Idempotency, and Avoiding Duplicate Sends

Hardening emails against real-world issues: spam flags, duplicate sends, rate limits. No route params here.

## 1. Domain verification (optional, recommended)
`onboarding@resend.dev` works but is more spam-prone than a verified domain. If you own one:
1. Resend dashboard → **Domains** → **Add Domain**
2. Add DNS records (SPF, DKIM, DMARC) at your registrar — free
3. Update `FROM_ADDRESS`:
```ts
const FROM_ADDRESS = "EventHub <tickets@yourdomain.com>";
```
No domain? `onboarding@resend.dev` is fine for dev and small launches.

## 2. Preventing duplicate confirmation emails on retry
Add an idempotency key so Resend itself dedupes even accidental repeat calls.

`src/lib/email.ts`:
```ts
export async function sendEmail(options: {
  to: string; subject: string; html: string;
  attachments?: { filename: string; content: string }[];
  idempotencyKey?: string;
}) {
  const result = await resend.emails.send(
    { from: FROM_ADDRESS, to: options.to, subject: options.subject, html: options.html, attachments: options.attachments },
    options.idempotencyKey ? { idempotencyKey: options.idempotencyKey } : undefined
  );
  if (result.error) throw new Error(`Failed to send email: ${result.error.message}`);
  return result;
}
```

In `send-rsvp-confirmation.ts`, add to the `sendEmail({...})` call:
```ts
idempotencyKey: `rsvp-confirmation-${rsvp.id}`,
```

In `send-event-reminders.ts`:
```ts
idempotencyKey: `event-reminder-${evt.id}-${attendee.id}`,
```

## 3. Respect rate limits
Resend free tier: 100/day, ~2 req/sec. Add a pause in the reminder loop:
```ts
for (const attendee of attendees) {
  await sendEmail({ /* ...as before, plus idempotencyKey */ });
  await new Promise((resolve) => setTimeout(resolve, 600));
}
```
600ms pause keeps well under 2 req/sec.

## 4. Exceeding the free tier
If you hit 100/day, further sends fail until next day. Since sends live inside `step.run(...)`, Inngest retries per its `retries` config, and idempotency keys ensure no duplicates once you're back under the limit.

## Checkpoint
- [ ] `sendEmail` accepts/forwards `idempotencyKey`
- [ ] Both functions pass stable, unique keys
- [ ] Reminder loop pauses between sends
- [ ] (Optional) Domain verified, `FROM_ADDRESS` updated

**Next: Part 19 — Event Capacity, Waitlist, and Cancellations**
