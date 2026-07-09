# Appendix D: Inngest Functions Reference

Full source in Appendix A Part 4. Inngest works identically under Next.js 16/Turbopack — nothing needed to change here.

## hello-world
- **Trigger:** event `test/hello`
- **Purpose:** proves wiring works (Part 15); not used by the real app
- **Steps:** `log-greeting`
- **Idempotency:** none needed

## send-rsvp-confirmation
- **Trigger:** `event/rsvp.created`, sent from `rsvpToEvent`/`cancelRsvp`
- **Purpose:** emails confirmation + QR ticket when RSVP becomes `confirmed`
- **Config:** `retries: 3`
- **Steps:** `fetch-rsvp` → `generate-qr-code` → `send-email`
- **Idempotency:** `idempotencyKey: rsvp-confirmation-${rsvp.id}`
- **Payload:** `{ rsvpId: string }` — minimal, re-fetches fresh data

## send-event-reminders
- **Trigger:** cron `0 * * * *` (hourly)
- **Purpose:** finds events starting in next 24h without reminders sent, emails confirmed attendees, marks reminded
- **Config:** `retries: 2`
- **Steps:** `find-events-needing-reminders` → per-event `remind-for-event-${evt.id}`
- **Idempotency:** two layers — `reminder_sent_at IS NULL` filter + `idempotencyKey: event-reminder-${evt.id}-${attendee.id}`

## General patterns
- **`step.run(id, fn)`** wraps side effects — only failed steps retry, not the whole function
- **Small event payloads** — just an ID, re-fetch fresh data
- **Idempotency keys** derived from stable identifiers (never timestamps) on any email-sending step

## Registering new functions
Add to the `functions` array in `src/app/api/inngest/route.ts` — the one place Inngest's `serve()` discovers functions, locally and in production.

## Clerk webhook note (adjacent, not an Inngest function)
`src/app/api/webhooks/clerk/route.ts` uses Next.js 16's async `headers()` — `const headerPayload = await headers();` — before verifying the Svix signature.

## Local testing reminder
- Dev Server: `npx inngest-cli@latest dev`, dashboard at http://localhost:8288
- Manually invoke any function from **Functions** tab
- Check **Runs** tab for step-by-step history, failures, and retries

**Next: Appendix E — Troubleshooting Guide.**
