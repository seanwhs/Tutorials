# **Part 24: Roadmap and Phase 2 Ideas**:

---

# Part 24: Roadmap and Phase 2 Ideas

You now have a fully working, deployed, free event site, built against Next.js 16. Here's what to build next, by difficulty.

## Easy additions
1. **Event cover images** — `imageUrl` column on `events`, displayed on cards/detail pages
2. **Event categories/tags** — filter dropdown reusing Part 20's search pattern (new params still flow through awaited `searchParams`)
3. **"My Organized Events" stats** — more Drizzle `count()` queries on the dashboard
4. **Editing events** — mirrors the create form (Part 8b), gated by `requireEventOwner`, at a `[id]` route awaiting `params` as usual
5. **Event cancellation by organizer** — `isCancelled` flag + Inngest notification, similar shape to Part 17's reminders

## Medium additions
6. **Co-organizers** — `event_organizers` join table, update `requireEventOwner` to check membership
7. **Full-text search with ranking** — upgrade `ilike` to Postgres `tsvector`/`tsquery`
8. **iCal export** — `.ics` file download via the open-source `ics` package
9. **Public organizer profile pages** — `/organizers/[userId]`, same awaited `params` convention
10. **Rate limiting RSVP spam** — per-IP/user limits via Upstash Redis free tier (new external dependency, verify current terms)

## Larger additions
11. **Paid ticketing via Stripe** — `price` field, Checkout session, Stripe webhook (same async `headers()` pattern as Part 7's Clerk webhook), refund handling. Test mode free; production takes a per-transaction cut.
12. **Recurring events** — generate individual `events` rows via the `rrule` library
13. **Real-time updates via WebSockets** — upgrade Part 14's 4s polling to Pusher/Ably free tiers or Postgres `LISTEN`/`NOTIFY`, only once polling becomes a real limitation
14. **Multi-tenant "organizations"** — Clerk Organizations feature, `organizationId` on events, org-scoped dashboards
15. **Analytics dashboard** — Drizzle aggregate queries + a free charting library (Recharts)

## How to approach adding these
Same build order as this whole series:
1. **Concept first** (plain English, like Part 6)
2. **Schema** (Drizzle + migration)
3. **Server logic** (action or Inngest function, pure testable functions where possible)
4. **UI last** (remembering new dynamic routes/`searchParams` are always Promises to await)
5. **Checkpoint** before moving on

## Wrapping up
The core app from Parts 1–23 is genuinely complete and production-usable, built cleanly against Next.js 16's async APIs and Tailwind v4's CSS-first config throughout. Stop here or keep building — the foundation supports either.

**Next: the series Conclusion, followed by Appendices (A: full codebase, B: env vars, C: schema, D: Inngest functions, E: troubleshooting).**
