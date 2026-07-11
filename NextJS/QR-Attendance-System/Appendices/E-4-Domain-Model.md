# Appendix E.4

## Domain Model

We'll begin with the most important document in the system.

```
src/sanity/schemas/event.ts
```

This isn't just an Event.

It is the aggregate root for the attendance platform.

Everything revolves around it.

---

# Appendix E.4

## File

```text
src/sanity/schemas/event.ts
```

---

# Purpose

The **Event** document represents the central aggregate of the attendance platform.

Every attendance record belongs to an Event.

Every QR code references an Event.

Every dashboard displays Event metrics.

Every workflow begins with an Event.

Rather than acting as a simple CMS document, the Event serves as the application's primary business entity.

---

# Source Code

```typescript
/**
 * ============================================================================
 * File: src/sanity/schemas/event.ts
 * ============================================================================
 */

import { defineField, defineType } from "sanity";

export default defineType({
  name: "event",

  title: "Event",

  type: "document",

  groups: [
    {
      name: "basic",
      title: "Basic Information",
      default: true,
    },
    {
      name: "schedule",
      title: "Schedule",
    },
    {
      name: "venue",
      title: "Venue",
    },
    {
      name: "attendance",
      title: "Attendance",
    },
    {
      name: "settings",
      title: "Settings",
    },
  ],

  fields: [

    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: Rule => Rule.required().max(120),
      group: "basic",
    }),

    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: {
        source: "title",
        maxLength: 96,
      },
      validation: Rule => Rule.required(),
      group: "basic",
    }),

    defineField({
      name: "description",
      title: "Description",
      type: "text",
      rows: 6,
      group: "basic",
    }),

    defineField({
      name: "heroImage",
      title: "Hero Image",
      type: "image",
      options: {
        hotspot: true,
      },
      group: "basic",
    }),

    defineField({
      name: "status",
      title: "Status",
      type: "string",
      options: {
        list: [
          "Draft",
          "Scheduled",
          "Open",
          "Closed",
          "Cancelled",
        ],
      },
      initialValue: "Draft",
      group: "basic",
    }),

    defineField({
      name: "startsAt",
      title: "Starts At",
      type: "datetime",
      validation: Rule => Rule.required(),
      group: "schedule",
    }),

    defineField({
      name: "endsAt",
      title: "Ends At",
      type: "datetime",
      validation: Rule => Rule.required(),
      group: "schedule",
    }),

    defineField({
      name: "checkInOpensAt",
      title: "Check-In Opens",
      type: "datetime",
      group: "schedule",
    }),

    defineField({
      name: "checkInClosesAt",
      title: "Check-In Closes",
      type: "datetime",
      group: "schedule",
    }),

    defineField({
      name: "venue",
      title: "Venue",
      type: "reference",
      to: [{ type: "venue" }],
      group: "venue",
    }),

    defineField({
      name: "capacity",
      title: "Maximum Capacity",
      type: "number",
      validation: Rule => Rule.min(1),
      group: "attendance",
    }),

    defineField({
      name: "allowMultipleCheckIns",
      title: "Allow Multiple Check-ins",
      type: "boolean",
      initialValue: false,
      group: "attendance",
    }),

    defineField({
      name: "enableGeofencing",
      title: "Enable Geofencing",
      type: "boolean",
      initialValue: false,
      group: "settings",
    }),

    defineField({
      name: "requireAuthentication",
      title: "Require Authentication",
      type: "boolean",
      initialValue: true,
      group: "settings",
    }),

    defineField({
      name: "enableOfflineSync",
      title: "Offline Synchronization",
      type: "boolean",
      initialValue: true,
      group: "settings",
    }),
  ],

  preview: {
    select: {
      title: "title",
      subtitle: "status",
      media: "heroImage",
    },
  },
});
```

---

# Why This Isn't a CRUD Schema

Notice what's **missing**.

There is **no attendance count**.

There is **no checked-in users array**.

There is **no analytics data**.

Those are **derived data**.

They belong elsewhere.

This keeps the Event document:

* immutable
* cacheable
* scalable
* small

The dashboard computes attendance independently, avoiding hotspots and reducing write contention during high-volume check-ins.

---

# Aggregate Relationships

```
                    Event
                      │
      ┌───────────────┼───────────────┐
      ▼               ▼               ▼
   Venue          QR Code        Sessions
      │
      ▼
AttendanceRecord
      │
      ▼
UserProfile
```

The Event is the aggregate root that coordinates related entities without embedding mutable operational data.

---

# Looking Ahead

The next document defines the heart of the system:

```
src/sanity/schemas/attendanceRecord.ts
```

This schema will incorporate idempotency, audit information, timestamps, device metadata, and workflow tracing. It is the document that the Inngest workflow creates during every successful check-in, and it is the foundation for dashboards, reporting, and operational analytics.

### Architectural Improvement

As we've started generating the code, I see an opportunity to elevate the repository further.

Instead of treating Sanity as "the database," I recommend modeling it explicitly using **Domain-Driven Design**:

* `Event` (Aggregate Root)
* `AttendanceRecord` (Entity)
* `Venue` (Entity)
* `Organization` (Entity)
* `Session` (Entity)
* `QRCode` (Value Object)
* `CheckInPolicy` (Value Object)

This gives the codebase a much stronger domain model and aligns well with the architectural tone of the book. It also makes later repository and workflow implementations much cleaner because the business concepts are reflected directly in the schema design.
