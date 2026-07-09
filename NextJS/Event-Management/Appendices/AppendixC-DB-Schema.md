# **Appendix C: Database Schema Reference**:

---

# Appendix C: Database Schema Reference

Entirely independent of Next.js version — unchanged by the regeneration.

## users
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK, `gen_random_uuid()` |
| clerk_id | text | not null, unique |
| email | text | not null |
| name | text | not null |
| image_url | text | nullable |
| is_admin | boolean | not null, default `false` (Part 21) |
| created_at | timestamptz | not null, default `now()` |

Synced via Clerk webhook (Part 7). `is_admin` manually toggled in Drizzle Studio — no self-service UI, by design.

## events
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| organizer_id | uuid | not null, → `users.id` cascade |
| title | text | not null |
| description | text | not null, default `''` |
| location | text | not null |
| starts_at | timestamptz | not null |
| ends_at | timestamptz | not null |
| capacity | integer | not null, default `100` |
| reminder_sent_at | timestamptz | nullable (Part 17) |
| created_at | timestamptz | not null, default `now()` |

`reminder_sent_at IS NULL` = reminder batch not yet sent; the cron function (Part 17) sets it as an idempotency guard.

## rsvps
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| event_id | uuid | not null, → `events.id` cascade |
| user_id | uuid | not null, → `users.id` cascade |
| ticket_code | text | not null, unique |
| status | rsvp_status enum | not null, default `'confirmed'` |
| created_at | timestamptz | not null, default `now()` |

**rsvp_status values:** `confirmed` (valid ticket), `waitlisted` (auto-promoted per Part 19), `cancelled` (row kept, reused on re-RSVP).

One row per (event, user) is enforced in application code (Part 10), not a DB constraint — since status legitimately transitions over time and we reuse the row.

## check_ins
| Column | Type | Constraints |
|---|---|---|
| id | uuid | PK |
| rsvp_id | uuid | not null, **unique**, → `rsvps.id` cascade |
| checked_in_at | timestamptz | not null, default `now()` |
| checked_in_by | uuid | not null, → `users.id` |

The unique constraint on `rsvp_id` backstops the application-level (Part 13) "already checked in" guard against race conditions.

## Entity relationship summary
```
users 1---* events        (organizer_id)
users 1---* rsvps         (user_id)
events 1---* rsvps        (event_id)
rsvps 1---0..1 check_ins  (rsvp_id, unique)
users 1---* check_ins     (checked_in_by)
```

## Migrations history
1. Initial (Part 7) — `rsvp_status` enum, `users`, `events`, `rsvps`, `check_ins`
2. Part 17 — adds `events.reminder_sent_at`
3. Part 20 (optional, hand-written) — `pg_trgm` extension + trigram indexes
4. Part 21 — adds `users.is_admin`

Your local migration file order doesn't need to match exactly — what matters is your final `schema.ts` matches Appendix A Part 2.

**Next: Appendix D — Inngest Functions Reference.**
