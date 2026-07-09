# **Part 7: Building the Data Model, Migrations, and Clerk User Sync**:

---

# Part 7: Building the Data Model, Migrations, and Clerk User Sync

The webhook route below uses `headers()` from `next/headers`, async in Next.js 16 — must be awaited.

## 1. Full schema.ts
Replace `src/db/schema.ts` entirely:
```ts
import { pgTable, text, timestamp, integer, uuid, pgEnum } from "drizzle-orm/pg-core";
import { relations, sql } from "drizzle-orm";

export const rsvpStatusEnum = pgEnum("rsvp_status", ["confirmed", "waitlisted", "cancelled"]);

export const users = pgTable("users", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  clerkId: text("clerk_id").notNull().unique(),
  email: text("email").notNull(),
  name: text("name").notNull(),
  imageUrl: text("image_url"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const events = pgTable("events", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  organizerId: uuid("organizer_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  title: text("title").notNull(),
  description: text("description").notNull().default(""),
  location: text("location").notNull(),
  startsAt: timestamp("starts_at", { withTimezone: true }).notNull(),
  endsAt: timestamp("ends_at", { withTimezone: true }).notNull(),
  capacity: integer("capacity").notNull().default(100),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const rsvps = pgTable("rsvps", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  eventId: uuid("event_id").notNull().references(() => events.id, { onDelete: "cascade" }),
  userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  ticketCode: text("ticket_code").notNull().unique(),
  status: rsvpStatusEnum("status").notNull().default("confirmed"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().default(sql`now()`),
});

export const checkIns = pgTable("check_ins", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  rsvpId: uuid("rsvp_id").notNull().unique().references(() => rsvps.id, { onDelete: "cascade" }),
  checkedInAt: timestamp("checked_in_at", { withTimezone: true }).notNull().default(sql`now()`),
  checkedInBy: uuid("checked_in_by").notNull().references(() => users.id),
});

export const usersRelations = relations(users, ({ many }) => ({
  organizedEvents: many(events), rsvps: many(rsvps),
}));
export const eventsRelations = relations(events, ({ one, many }) => ({
  organizer: one(users, { fields: [events.organizerId], references: [users.id] }), rsvps: many(rsvps),
}));
export const rsvpsRelations = relations(rsvps, ({ one }) => ({
  event: one(events, { fields: [rsvps.eventId], references: [events.id] }),
  user: one(users, { fields: [rsvps.userId], references: [users.id] }),
  checkIn: one(checkIns, { fields: [rsvps.id], references: [checkIns.rsvpId] }),
}));
export const checkInsRelations = relations(checkIns, ({ one }) => ({
  rsvp: one(rsvps, { fields: [checkIns.rsvpId], references: [rsvps.id] }),
  checkedInByUser: one(users, { fields: [checkIns.checkedInBy], references: [users.id] }),
}));
```

## 2. Generate + run migration
```bash
pnpm db:generate
pnpm db:migrate
pnpm db:studio   # verify all 4 tables exist, _placeholder gone
```

## 3. Why sync Clerk → our DB?
`events.organizerId`/`rsvps.userId` are FKs into our own `users` table. A **Clerk webhook** keeps it in sync automatically on `user.created`/`updated`/`deleted`.

## 4. Install webhook verification lib
```bash
pnpm add svix
```

## 5. Create the webhook route
`src/app/api/webhooks/clerk/route.ts` — verifies Svix signature headers (note `await headers()`), then upserts/deletes rows in `users` based on event type `user.created`/`user.updated`/`user.deleted`. Full source uses `wh.verify(body, {...})` from `svix`, and Drizzle `select`/`insert`/`update`/`delete` against `users`.

## 6. Register webhook locally (ngrok)
```bash
ngrok http 3000
```
Clerk dashboard → **Webhooks** → Add Endpoint → `https://xxxx.ngrok-free.app/api/webhooks/clerk` → subscribe to `user.created`, `user.updated`, `user.deleted` → copy Signing Secret.
```bash
CLERK_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
```
(Production gets its own separate webhook endpoint + secret in Part 23.)

## 7. Test it
Sign up/update profile → check Clerk's **Message Attempts** for `200` → check Drizzle Studio for the new `users` row. (If your account predates the webhook, re-save your profile to trigger `user.updated`.)

## Checkpoint
- [ ] All 4 tables exist in Neon
- [ ] Webhook shows successful deliveries
- [ ] Sign up/profile update creates/updates local `users` row

**Next: Part 8 — Event Creation UI (Organizer Dashboard)**
