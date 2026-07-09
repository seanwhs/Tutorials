# **Part 6: Database Schema Design**:

---

# Part 6: Database Schema Design

Purely conceptual — unaffected by the Next.js 16 upgrade.

## Entities

1. **users** — Clerk owns auth entirely; we keep a local mirror row per Clerk user (synced via webhook in Part 7) so we can join events/RSVPs to a local ID.
2. **events** — title, description, location, start/end time, capacity, `organizerId`.
3. **rsvps** — links a user to an event. Unique `ticketCode` (for QR/check-in). Status: `confirmed`, `waitlisted`, or `cancelled`.
4. **check_ins** — records when an RSVP's ticket was scanned. Separate table (not just a field on `rsvps`) for flexibility (e.g., future re-entry tracking).

## Relationships
- One `user` → many `events` (organizer)
- One `user` → many `rsvps` (attendee)
- One `event` → many `rsvps`
- One `rsvp` → zero or one `check_in`

## ER sketch
```
users            events                 rsvps                check_ins
------           ------                 -----                ---------
id (pk)          id (pk)                id (pk)              id (pk)
clerkId (uniq)   organizerId -> users.id eventId -> events.id rsvpId -> rsvps.id (uniq)
email            title                  userId -> users.id   checkedInAt
name             description            ticketCode (uniq)    checkedInBy -> users.id
createdAt        location               status
                 startsAt               createdAt
                 endsAt
                 capacity
                 createdAt
```

## Why a separate `users` table if Clerk already has users?
1. **Foreign keys** — Postgres FKs need a row in *our* DB, not Clerk's remote system
2. **Joins** — simple SQL joins without calling Clerk's API per page load
3. **Resilience** — our reads keep working even during a Clerk outage

Clerk stays the auth source of truth; our table is a lightweight mirror.

## Status field
`rsvps.status`: `"confirmed" | "waitlisted" | "cancelled"` — waitlist logic added in Part 19; Parts 8–11 only create `"confirmed"` rows.

## IDs
Postgres `uuid` (via `gen_random_uuid()`) for all primary keys, including `users.id` — kept separate from Clerk's own ID (`clerkId`, text, unique). Decouples internal IDs from any specific auth provider.

## Ticket codes
`rsvps.ticketCode` — short, unique, URL-safe random string, generated at RSVP creation, embedded in the QR code and used for check-in lookup. Kept separate from the RSVP's UUID for a shorter, more scan-friendly value (details in Part 12).

## Timestamps
All tables get `createdAt` (default `now()`). Use `timestamp with time zone` throughout — critical for unambiguous `startsAt`/`endsAt` across timezones. Store everything in UTC, format client-side later. (The `datetime-local` → UTC conversion in Part 8b works identically regardless of Next.js version — standard JS `Date` handling, not framework-specific.)

## Checkpoint
No code yet — re-read the ER sketch until it clicks. Part 7 turns this into real Drizzle schema + migration.

**Next: Part 7 — Building the Events Data Model and Migrations**
