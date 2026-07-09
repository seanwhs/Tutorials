# Appendix A Part 2: Database Layer

Unaffected by the Next.js 16 upgrade — no dynamic APIs involved.

## src/db/index.ts
```ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "./schema";

const sql = neon(process.env.DATABASE_URL!);
export const db = drizzle(sql, { schema });
```

## src/db/schema.ts (final, complete — includes reminderSentAt and isAdmin)
```ts
import { pgTable, text, timestamp, integer, uuid, pgEnum, boolean } from "drizzle-orm/pg-core";
import { relations, sql } from "drizzle-orm";

export const rsvpStatusEnum = pgEnum("rsvp_status", ["confirmed", "waitlisted", "cancelled"]);

export const users = pgTable("users", {
  id: uuid("id").primaryKey().default(sql`gen_random_uuid()`),
  clerkId: text("clerk_id").notNull().unique(),
  email: text("email").notNull(),
  name: text("name").notNull(),
  imageUrl: text("image_url"),
  isAdmin: boolean("is_admin").notNull().default(false),
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
  reminderSentAt: timestamp("reminder_sent_at", { withTimezone: true }),
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

export const usersRelations = relations(users, ({ many }) => ({ organizedEvents: many(events), rsvps: many(rsvps) }));
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

## Optional: drizzle/0003_add_search_indexes.sql (hand-written, run manually)
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS events_title_trgm_idx ON events USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS events_location_trgm_idx ON events USING gin (location gin_trgm_ops);
```

**Next: Appendix A Part 3 — Lib and Server Actions**
